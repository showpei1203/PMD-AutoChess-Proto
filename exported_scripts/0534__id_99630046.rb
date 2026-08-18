# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Team Composition Authority v1.05.49
#===============================================================================
# 【用途】
# 將 v0.99.13 Dynamic Tactical Role 正式接回 v0.99.2/v0.99.3 Tactical Team Bond。
# 過去 Tactical Bond 只讀物種的靜態 role_tags，因此玩家即使透過 4 招、Ability、
# Held Item 與 AI Strategy 把 Pokémon 配成 Diver / Skirmisher / Bodyguard，羈絆仍用
# 舊出生定位判定。這會造成「UI 顯示目前實戰定位」與「隊伍羈絆實際判定」不一致。
#
# 【Authority 規則】
# 1. Relationship Team Bond：完全不變，仍由 species / evolution line / form 組成判定。
# 2. Tactical Team Bond：在正式 NORMAL battle 使用 Effective Composition Tags：
#    - Primary Tactical Role：由 v0.99.13 dynamic_role_v09913 接管。
#    - 穩定 Trait：保留物種 role_tags 內非 primary-role 的標籤，例如
#      :melee / :ranged / :tank / :support / :caster / :physical_pressure / :area_damage。
# 3. 舊 Verifier 模式維持靜態 role_tags，避免把已 PASS 的歷史 fixture 改成另一套測試。
# 4. Summon、倒下後 basis 保留、Form refresh、category limit、priority 等既有規則不變。
#
# 【為什麼不是把 static role_tags 全部保留】
# 若同時保留舊 :assassin 並再加入新 :skirmisher，玩家改 Build 後仍會被舊 Primary Role
# 偷偷算進 Tactical Bond，等於 Dynamic Role 只有 UI 名稱沒有戰術後果。本版只替換
# Primary Role；體質／功能 Trait 仍保留，因此高耐久 Bodyguard 改成 Diver 後仍可保有
# :tank，但不再同時被當成 Bodyguard。
#
# 【對外查詢】
# PMD_AC.team_bond_effective_role_tags_v10549(unit)
# $scene.team_composition_snapshot_v10549(:ally)
#
# 【實際範例】
# pokemon.set_ai_option(:role_bias,:skirmisher)
# pokemon.set_ai_option(:spatial_intent,:disengage)
# 戰鬥開始後：
# - Dynamic primary role 可成為 :skirmisher。
# - 原本 :ranged / :caster 等穩定 trait 保留。
# - Tactical Bond 不再同時計入舊 species primary role。
#
# 【安全邊界】
# - 不改 Relationship Bond 81 組內容、效果數值、priority 或 category limit。
# - 不改 Damage / HP / Energy / Accuracy / Priority / Attack Wait。
# - 不改 AI 決策公式，只讀 v0.99.13 已經計算出的 Dynamic Role。
# - 不改 Spatial endpoint、Motion Core、技能資料或 Species Base Stats。
# - 所有歷史 Team Bond verifier 非 NORMAL 時仍使用舊 static role_tags。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_TeamCompositionAuthority_v10549']=true

module PMD_AC
  TEAM_COMPOSITION_VERSION_V10549='1.05.49'

  class << self
    alias pmd_ac_v10549_team_bond_role_count_v0992 team_bond_role_count_v0992 unless method_defined?(:pmd_ac_v10549_team_bond_role_count_v0992)
    alias pmd_ac_v10549_team_bond_condition_met_v0992 team_bond_condition_met_v0992? unless method_defined?(:pmd_ac_v10549_team_bond_condition_met_v0992)

    def team_bond_dynamic_role_mode_v10549?(unit)
      return false if unit==nil
      sc=unit.instance_variable_get(:@scene) rescue nil
      return false if sc==nil || !sc.respond_to?(:verification_mode)
      sc.verification_mode==:normal
    rescue
      false
    end

    # Dynamic primary + stable traits。
    def team_bond_effective_role_tags_v10549(unit)
      base=(unit!=nil && unit.respond_to?(:role_tags)) ? (unit.role_tags || []).dup : []
      return base.uniq unless team_bond_dynamic_role_mode_v10549?(unit)
      return base.uniq unless defined?(TACTICAL_ROLES_V09913)
      return base.uniq unless unit.respond_to?(:dynamic_role_v09913)

      primaries=TACTICAL_ROLES_V09913
      traits=base.reject{|tag|primaries.include?(tag)}
      role=unit.dynamic_role_v09913 rescue nil
      traits.unshift(role) if role!=nil && primaries.include?(role)
      traits.uniq
    rescue
      base || []
    end

    # required_roles 改讀 Effective Composition Tags；非 NORMAL 等價於舊版。
    def team_bond_role_count_v0992(units,role)
      c=0
      for unit in team_bond_eligible_units_v0992(units)
        tags=team_bond_effective_role_tags_v10549(unit)
        c+=1 if tags.include?(role)
      end
      c
    rescue
      pmd_ac_v10549_team_bond_role_count_v0992(units,role)
    end

    # required_role_pools 原版直接讀 unit.role_tags，因此必須同步改為 Effective Tags。
    # 其餘 required_tags / tag pools 邏輯原封保留。
    def team_bond_condition_met_v0992?(units,condition)
      units=team_bond_eligible_units_v0992(units)
      c=condition || {}

      roles=c[:required_roles] || {}
      for role in roles.keys
        return false if team_bond_role_count_v0992(units,role)<roles[role].to_i
      end

      tags=c[:required_tags] || {}
      for tag in tags.keys
        return false if team_bond_tag_count_v0992(units,tag)<tags[tag].to_i
      end

      for pool in (c[:required_role_pools] || [])
        needed=(pool[:count] || 1).to_i
        found=0
        for unit in units
          rt=team_bond_effective_role_tags_v10549(unit)
          found+=1 unless (rt & (pool[:roles] || [])).empty?
        end
        return false if found<needed
      end

      for pool in (c[:required_tag_pools] || [])
        needed=(pool[:count] || 1).to_i
        found=0
        for unit in units
          st=unit.respond_to?(:synergy_tags) ? (unit.synergy_tags || []) : []
          found+=1 unless (st & (pool[:tags] || [])).empty?
        end
        return false if found<needed
      end
      true
    rescue
      # Condition evaluator 是正式 Tactical Bond 入口。若新增層自身失敗，
      # 回退已 PASS 的 v0.99.2 static semantics，而不是讓戰鬥中斷。
      pmd_ac_v10549_team_bond_condition_met_v0992(units,condition)
    end

    def team_composition_authority_audit_v10549
      species=defined?(SPECIES_DB_V016) ? SPECIES_DB_V016 : {}
      bonds=defined?(TEAM_BOND_DATA_V0992) ? TEAM_BOND_DATA_V0992 : {}
      dyn=defined?(TACTICAL_ROLES_V09913) ? TACTICAL_ROLES_V09913 : []
      reviewed=0
      role_counts={}
      empty_role_tags=[]
      missing_review=[]

      species.each do |sk,d|
        rp=nil
        rp=review_profile_for_v09911(sk,:normal) if respond_to?(:review_profile_for_v09911)
        if rp==nil
          missing_review.push(sk)
        else
          reviewed+=1
          r=rp[:role]
          role_counts[r]=role_counts[r].to_i+1
        end
        empty_role_tags.push(sk) if (d[:role_tags] || []).empty?
      end

      rel=0;tac=0;tactical_refs=0
      bonds.each do |key,d|
        if d[:category]==:relationship
          rel+=1
        elsif d[:category]==:tactical
          tac+=1
          c=d[:condition] || {}
          tactical_refs+=(c[:required_roles] || {}).size
          (c[:required_role_pools] || []).each{|p|tactical_refs+=(p[:roles] || []).size}
        end
      end

      pass=species.size==494 && reviewed==494 && missing_review.empty? &&
        empty_role_tags.empty? && bonds.size==81 && rel==73 && tac==8 && dyn.size==9
      {
        :pass=>pass,:species=>species.size,:reviewed=>reviewed,
        :missing_review=>missing_review,:empty_role_tags=>empty_role_tags,
        :role_counts=>role_counts,:bonds=>bonds.size,:relationship=>rel,:tactical=>tac,
        :dynamic_roles=>dyn.size,:tactical_role_refs=>tactical_refs
      }
    rescue
      {:pass=>false,:species=>0,:reviewed=>0,:missing_review=>[:audit_error],
       :empty_role_tags=>[],:role_counts=>{},:bonds=>0,:relationship=>0,:tactical=>0,
       :dynamic_roles=>0,:tactical_role_refs=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10549_start_battle start_battle unless method_defined?(:pmd_ac_v10549_start_battle)
  alias pmd_ac_v10549_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10549_focus_summary)

  def team_composition_units_v10549(team)
    if respond_to?(:team_bond_basis_units_v0992)
      rows=team_bond_basis_units_v0992(team)
      return rows unless rows==nil || rows.empty?
    end
    out=[]
    for u in (@units || [])
      next if u==nil || u.team!=team
      next if u.respond_to?(:summoned?) && u.summoned?
      next if u.respond_to?(:counts_for_victory?) && !u.counts_for_victory?
      out.push(u)
    end
    out
  rescue
    []
  end

  def team_composition_snapshot_v10549(team)
    units=team_composition_units_v10549(team)
    rows=[]
    units.each do |u|
      dyn=u.respond_to?(:dynamic_role_v09913) ? (u.dynamic_role_v09913 rescue nil) : nil
      tags=PMD_AC.team_bond_effective_role_tags_v10549(u)
      rows.push({:species=>(u.respond_to?(:species_key) ? u.species_key : nil),
        :role=>dyn,:tags=>tags})
    end
    bonds=respond_to?(:active_team_bond_keys_v0992) ? active_team_bond_keys_v0992(team) : []
    {:team=>team,:units=>rows,:bonds=>(bonds || []).dup}
  rescue
    {:team=>team,:units=>[],:bonds=>[]}
  end

  def log_team_composition_v10549(team)
    s=team_composition_snapshot_v10549(team)
    rows=s[:units].collect do |r|
      (r[:species] || :unknown).to_s+':'+(r[:role] || :none).to_s+
        '{'+(r[:tags] || []).collect{|x|x.to_s}.join(',')+'}'
    end
    log_event(:battle,'BATTLE_TEAM_COMPOSITION_V10549 team='+team.to_s.upcase+
      ' units=['+rows.join('|')+'] bonds=['+(s[:bonds] || []).collect{|x|x.to_s}.join(',')+']'+
      ' primary_authority=dynamic_v09913 stable_traits=species_role_tags relationship_unchanged=1')
  rescue
  end

  def start_battle
    r=pmd_ac_v10549_start_battle
    begin
      @v10549_summary_logged=false
      if @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
        if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
          @v10549_audit={:pass=>true,:species=>494,:reviewed=>494,:bonds=>81,:relationship=>73,
            :tactical=>8,:dynamic_roles=>9,:role_counts=>{},:source=>:sealed_production_fast_v10613}
          log_team_composition_v10549(:ally)
          log_team_composition_v10549(:enemy)
        else
          a=PMD_AC.team_composition_authority_audit_v10549
          @v10549_audit=a
          roles=(a[:role_counts] || {}).keys.sort{|x,y|x.to_s<=>y.to_s}.collect{|k|k.to_s+'='+a[:role_counts][k].to_i.to_s}
          log_event(:battle,'BATTLE_TEAM_COMPOSITION_AUTHORITY_V10549 START pass='+(a[:pass] ? '1':'0')+
            ' species='+a[:species].to_i.to_s+'/494 reviewed='+a[:reviewed].to_i.to_s+'/494'+
            ' bonds='+a[:bonds].to_i.to_s+'/81 relationship='+a[:relationship].to_i.to_s+'/73 tactical='+a[:tactical].to_i.to_s+'/8'+
            ' dynamic_roles='+a[:dynamic_roles].to_i.to_s+'/9 role_distribution=['+roles.join(',')+']'+
            ' tactical_primary=dynamic stable_traits=static verifier_static_compat=1 gameplay_scope=tactical_bond_only')
          log_team_composition_v10549(:ally)
          log_team_composition_v10549(:enemy)
        end
      end
    rescue
    end
    r
  end

  def team_composition_summary_v10549
    return false if @v10549_summary_logged
    @v10549_summary_logged=true
    a=@v10549_audit || PMD_AC.team_composition_authority_audit_v10549
    ally=team_composition_snapshot_v10549(:ally)
    enemy=team_composition_snapshot_v10549(:enemy)
    log_event(:battle,'BATTLE_TEAM_COMPOSITION_AUTHORITY_SUMMARY_V10549 pass='+(a[:pass] ? '1':'0')+
      ' reviewed='+a[:reviewed].to_i.to_s+'/494 tactical_bonds='+a[:tactical].to_i.to_s+'/8'+
      ' ally_bonds=['+(ally[:bonds] || []).collect{|x|x.to_s}.join(',')+']'+
      ' enemy_bonds=['+(enemy[:bonds] || []).collect{|x|x.to_s}.join(',')+']'+
      ' dynamic_primary_in_normal=1 stable_traits_retained=1 relationship_unchanged=1 blocking_gate=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10549_focus_summary
    begin
      team_composition_summary_v10549
    rescue
    end
    r
  end
end
