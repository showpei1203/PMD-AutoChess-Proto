# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Team Bond Runtime v0.99.2
# 分類：隊伍羈絆／戰鬥 Runtime／Verifier／v0.15 相容橋
#
# 【用途】
# 1. 讀取 TEAM_BOND_DATA_V0992，完成正式隊伍羈絆判定與效果。
# 2. 每隊同時最多 1 個關係羈絆＋1 個戰術羈絆；同類取 priority 最高者。
# 3. 將羈絆效果以 Battle Runtime Multiplier 套入 Damage / Energy / Heal /
#    Move Speed / Status Duration，不改永久種族值、IV、Nature、Level。
# 4. 保留 v0.15 初代御三家既有 +12 Energy，避免重複計算。
# 5. 提供敵方羈絆、Form/Mega Refresh、倒下後持續與中文戰鬥提示。
#
# 【主要設定項】
# - TEAM_BOND_VERIFY_END_V0992：本版自動驗證結束 frame。
# - TEAM_BOND_VERIFY_MODE_V0992：Verifier 模式 key。
# - 正式羈絆名稱、組成、priority、效果與硬上限全部在前一支 Data 腳本。
#
# 【可調參數】
# - 平衡數值只調 TEAM_BOND_DATA_V0992 / TEAM_BOND_LIMITS_V0992。
# - 本 Runtime 不另外藏傷害、Energy、移速或狀態倍率，避免出現第二份數值來源。
# - 若只要改羈絆內容，不要改這裡的 alias／效果入口。
#
# 【主要規則／機制】
# - Battle Start 會記錄正式出戰三隻作為 basis；Summon 永不加入。
# - 某隻中途倒下，basis 不變，所以羈絆直到該場結束仍有效。
# - Mega/Form 改變時重新判定；一次性 initial_energy/start_shield 只會執行一次。
# - damage_out / damage_in 在 receive_damage 最後入口組合，包含一般與間接傷害。
# - Physical / Special / Type / Contact / Ranged 在 calculate_damage 套用。
# - indirect_damage_mult 只對 grant_energy=false 的間接傷害路徑套用。
# - status_duration_mult 只縮短 STATUS_DEFS 標記 :debuff 的狀態，不縮短 Buff。
#
# 【對外 API】
# $scene.active_team_bond_keys_v0992(:ally)
# $scene.active_team_bond_names_v0992(:ally)
# PMD_AC.active_team_bond_keys_for_v0992(units)
# PMD_AC.validate_team_bond_registry_v0992
#
# 【實際範例】
# names=$scene.active_team_bond_names_v0992(:ally)
# # => ["初代御三家", "守望陣線"]
#
# 【Verifier】
# NORMAL → S 一次 → TEAM_BOND_V0992 → Shift。
# 主要 markers：TEAM_BOND_REGISTRY_V0992、TEAM_BOND_PRIORITY_V0992、
# TEAM_BOND_RUNTIME_MODS_V0992、TEAM_BOND_FAINT_PERSIST_V0992、
# TEAM_BOND_V0992、VERIFY_FINISHED_BATTLE_RESUME。
#
# 【注意】
# - 不修改 v0.15 Movement、v0.60.2 Multi-hit、v0.75 Balance、Ability 1193/1193。
# - 驗證假單位沿用 v0.68 Presentation Isolation，不會在左上角生 VFX/SFX。
# - 避免使用新版反射寫法；維持 RGSS2 / Ruby 1.8 相容。
#==============================================================================
module PMD_AC
  TEAM_BOND_VERIFY_END_V0992=82
  TEAM_BOND_VERIFY_MODE_V0992=:team_bond_v0992

  class << self
    def team_bond_eligible_units_v0992(units)
      result=[]
      for unit in (units || [])
        next if unit==nil
        next if unit.respond_to?(:summoned?) && unit.summoned?
        next if unit.respond_to?(:counts_for_victory?) && !unit.counts_for_victory?
        result.push(unit)
      end
      result
    end

    def team_bond_role_count_v0992(units,role)
      c=0
      for unit in team_bond_eligible_units_v0992(units)
        tags=unit.respond_to?(:role_tags) ? (unit.role_tags || []) : []
        c+=1 if tags.include?(role)
      end
      c
    end

    def team_bond_tag_count_v0992(units,tag)
      c=0
      for unit in team_bond_eligible_units_v0992(units)
        tags=unit.respond_to?(:synergy_tags) ? (unit.synergy_tags || []) : []
        c+=1 if tags.include?(tag)
      end
      c
    end

    def team_bond_requirement_matches_v0992(unit,req)
      return false if unit==nil || req==nil
      type=req[:type]
      case type
      when :species
        unit.species_key==req[:key]
      when :line
        unit.evolution_line_key==req[:key]
      when :species_pool
        (req[:keys] || []).include?(unit.species_key)
      when :form
        return false if req[:species]!=nil && unit.species_key!=req[:species]
        return false if req[:line]!=nil && unit.evolution_line_key!=req[:line]
        unit.form_key==req[:form]
      else
        false
      end
    end

    def team_bond_expand_composition_v0992(composition)
      slots=[]
      gid=0
      for req in (composition || [])
        n=(req[:count] || 1).to_i
        n=1 if n<1
        i=0
        while i<n
          slots.push([req,gid])
          i+=1
        end
        gid+=1
      end
      slots
    end

    def team_bond_match_slots_v0992(units,slots,index,used,unique_species)
      return true if index>=slots.size
      req,gid=slots[index]
      for i in 0...units.size
        next if used[i]
        unit=units[i]
        next unless team_bond_requirement_matches_v0992(unit,req)
        if req[:unique]
          seen=unique_species[gid] || {}
          next if seen[unit.species_key]
        end
        used[i]=true
        old=nil
        if req[:unique]
          old=unique_species[gid]
          map=old==nil ? {} : old.dup
          map[unit.species_key]=true
          unique_species[gid]=map
        end
        return true if team_bond_match_slots_v0992(units,slots,index+1,used,unique_species)
        used[i]=false
        if req[:unique]
          if old==nil
            unique_species.delete(gid)
          else
            unique_species[gid]=old
          end
        end
      end
      false
    end

    def team_bond_composition_met_v0992?(units,composition)
      units=team_bond_eligible_units_v0992(units)
      slots=team_bond_expand_composition_v0992(composition)
      return false if slots.size>units.size
      team_bond_match_slots_v0992(units,slots,0,{}, {})
    end

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
          rt=unit.respond_to?(:role_tags) ? (unit.role_tags || []) : []
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
    end

    def team_bond_met_v0992?(units,data)
      return false if data==nil
      if data[:composition]!=nil
        return team_bond_composition_met_v0992?(units,data[:composition])
      end
      team_bond_condition_met_v0992?(units,data[:condition])
    end

    def active_team_bond_keys_for_v0992(units)
      selected=[]
      [:relationship,:tactical].each do |cat|
        candidates=[]
        TEAM_BOND_DATA_V0992.each do |key,data|
          next unless data[:category]==cat
          next unless team_bond_met_v0992?(units,data)
          candidates.push([key,data])
        end
        candidates.sort! do |a,b|
          pa=(a[1][:priority] || 0).to_i;pb=(b[1][:priority] || 0).to_i
          pa==pb ? (a[0].to_s<=>b[0].to_s) : (pb<=>pa)
        end
        selected.push(candidates[0][0]) unless candidates.empty?
      end
      selected
    end

    def active_team_bond_names_for_v0992(units)
      active_team_bond_keys_for_v0992(units).collect{|k|team_bond_name_v0992(k)}
    end

    def team_bond_scope_matches_v0992?(unit,scope)
      return true if scope==nil || scope==:team
      return false if unit==nil || !scope.is_a?(Hash)
      return unit.species_key==scope[:species] if scope[:species]!=nil
      return unit.evolution_line_key==scope[:line] if scope[:line]!=nil
      if scope[:role]!=nil
        return (unit.role_tags || []).include?(scope[:role])
      end
      if scope[:tag]!=nil
        return (unit.synergy_tags || []).include?(scope[:tag])
      end
      if scope[:species_pool]!=nil
        return (scope[:species_pool] || []).include?(unit.species_key)
      end
      true
    end

    def team_bond_effect_applies_context_v0992?(unit,effect,context)
      return false unless team_bond_scope_matches_v0992?(unit,effect[:scope])
      return true unless effect[:type]==:type_damage_mult
      wanted=effect[:move_type]
      actual=context==nil ? nil : context[:move_type]
      if wanted==:own
        return false if actual==nil
        types=unit.respond_to?(:pokemon_types) ? (unit.pokemon_types || []) : []
        return types.include?(actual)
      end
      wanted==nil || wanted==actual
    end

    def team_bond_effect_value_v0992(effect,type)
      return (effect[:amount] || 0).to_i if type==:initial_energy
      return (effect[:ratio] || 0.0).to_f if type==:start_shield
      (effect[:mult] || 1.0).to_f
    end

    def team_bond_clamp_effect_v0992(type,value)
      lim=TEAM_BOND_LIMITS_V0992[type]
      return value if lim==nil
      v=value.to_f
      v=lim[:min].to_f if v<lim[:min].to_f
      v=lim[:max].to_f if v>lim[:max].to_f
      type==:initial_energy ? v.to_i : v
    end

    def validate_team_bond_registry_v0992
      errors=[]
      species=const_defined?(:SPECIES_DB_V016) ? SPECIES_DB_V016 : {}
      lines=const_defined?(:EVOLUTION_LINES_V016) ? EVOLUTION_LINES_V016 : {}
      valid_roles={};valid_tags={}
      species.each_value do |d|
        (d[:role_tags] || []).each{|x|valid_roles[x]=true}
        (d[:synergy_tags] || []).each{|x|valid_tags[x]=true}
      end
      counts={:relationship=>0,:tactical=>0}
      TEAM_BOND_DATA_V0992.each do |key,data|
        cat=data[:category]
        counts[cat]=counts[cat].to_i+1
        errors.push('name:'+key.to_s) if data[:name].to_s.empty?
        errors.push('description:'+key.to_s) if data[:description].to_s.empty?
        errors.push('category:'+key.to_s) unless [:relationship,:tactical].include?(cat)
        errors.push('priority:'+key.to_s) if data[:priority]==nil
        if cat==:relationship
          slots=team_bond_expand_composition_v0992(data[:composition])
          errors.push('composition:'+key.to_s) if data[:composition]==nil || slots.empty?
          errors.push('over_party:'+key.to_s) if slots.size>3
          for req in (data[:composition] || [])
            case req[:type]
            when :species
              errors.push('species:'+key.to_s+':'+req[:key].to_s) unless species.has_key?(req[:key])
            when :line
              errors.push('line:'+key.to_s+':'+req[:key].to_s) unless lines.has_key?(req[:key])
            when :species_pool
              errors.push('pool_empty:'+key.to_s) if (req[:keys] || []).empty?
              for sk in (req[:keys] || [])
                errors.push('pool_species:'+key.to_s+':'+sk.to_s) unless species.has_key?(sk)
              end
              if req[:unique] && req[:count].to_i>(req[:keys] || []).uniq.size
                errors.push('pool_unique:'+key.to_s)
              end
            when :form
              sk=req[:species]
              if sk!=nil
                errors.push('form_species:'+key.to_s+':'+sk.to_s) unless species.has_key?(sk)
                if const_defined?(:FORMS_DB_V016) && FORMS_DB_V016[sk]!=nil
                  errors.push('form:'+key.to_s+':'+req[:form].to_s) unless FORMS_DB_V016[sk].has_key?(req[:form])
                end
              end
            else
              errors.push('requirement_type:'+key.to_s+':'+req[:type].to_s)
            end
          end
        else
          c=data[:condition] || {}
          (c[:required_roles] || {}).each_key{|r|errors.push('role:'+key.to_s+':'+r.to_s) unless valid_roles[r]}
          (c[:required_tags] || {}).each_key{|t|errors.push('tag:'+key.to_s+':'+t.to_s) unless valid_tags[t]}
          for p in (c[:required_role_pools] || [])
            for r in (p[:roles] || [])
              errors.push('role_pool:'+key.to_s+':'+r.to_s) unless valid_roles[r]
            end
          end
        end
        effs=data[:effects] || []
        errors.push('effects:'+key.to_s) if effs.empty?
        for e in effs
          t=e[:type]
          errors.push('effect_type:'+key.to_s+':'+t.to_s) unless TEAM_BOND_EFFECT_TYPES_V0992.include?(t)
          v=team_bond_effect_value_v0992(e,t)
          lim=TEAM_BOND_LIMITS_V0992[t]
          if lim!=nil && (v.to_f<lim[:min].to_f || v.to_f>lim[:max].to_f)
            errors.push('effect_limit:'+key.to_s+':'+t.to_s)
          end
          scope=e[:scope]
          if scope.is_a?(Hash) && scope[:species]!=nil && !species.has_key?(scope[:species])
            errors.push('scope_species:'+key.to_s+':'+scope[:species].to_s)
          end
        end
      end
      errors.push('relationship_count') unless counts[:relationship].to_i==TEAM_BOND_MANIFEST_V0992[:relationship_count].to_i
      errors.push('tactical_count') unless counts[:tactical].to_i==TEAM_BOND_MANIFEST_V0992[:tactical_count].to_i
      errors
    end
  end

  old_modes=VERIFICATION_MODES.dup
  old_labels=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:team_bond_v0992]+old_modes.reject{|x|x==:normal || x==:team_bond_v0992}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:team_bond_v0992]='TEAM_BOND_V0992'
end

#==============================================================================
# ■ Game_PMDChessUnit：效果入口
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v0992_receive_damage receive_damage unless method_defined?(:pmd_ac_v0992_receive_damage)
  alias pmd_ac_v0992_calculate_damage calculate_damage unless method_defined?(:pmd_ac_v0992_calculate_damage)
  alias pmd_ac_v0992_gain_energy gain_energy unless method_defined?(:pmd_ac_v0992_gain_energy)
  alias pmd_ac_v0992_heal heal unless method_defined?(:pmd_ac_v0992_heal)
  alias pmd_ac_v0992_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v0992_effective_move_speed)
  alias pmd_ac_v0992_apply_status apply_status unless method_defined?(:pmd_ac_v0992_apply_status)

  def team_bond_multiplier_v0992(type,context=nil)
    return 1.0 if @scene==nil || !@scene.respond_to?(:team_bond_multiplier_for_unit_v0992)
    @scene.team_bond_multiplier_for_unit_v0992(self,type,context)
  end

  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    adjusted=value.to_f
    if adjusted>0.0
      if source!=nil && source.is_a?(Game_PMDChessUnit) && source.team!=@team
        adjusted*=source.team_bond_multiplier_v0992(:damage_out_mult,{:target=>self,:indirect=>!grant_energy})
        adjusted*=source.team_bond_multiplier_v0992(:indirect_damage_mult,{:target=>self}) unless grant_energy
      end
      adjusted*=team_bond_multiplier_v0992(:damage_in_mult,{:source=>source,:indirect=>!grant_energy})
    end
    final=adjusted.round
    final=1 if value.to_i>0 && final<1
    if final!=value.to_i && @scene!=nil && @scene.respond_to?(:log_event)
      @scene.log_event(:team_bond_mod,log_name+' DAMAGE '+value.to_i.to_s+'->'+final.to_s+
        ' source='+(source==nil ? 'nil' : source.log_name)+' indirect='+(!grant_energy ? '1':'0'))
    end
    pmd_ac_v0992_receive_damage(final,source,grant_energy,bypass_link,critical)
  end

  def calculate_damage(target_unit,power,category=:physical,move_type=:normal,random_percent=nil)
    base=pmd_ac_v0992_calculate_damage(target_unit,power,category,move_type,random_percent)
    return base if base.to_i<=0
    mult=1.0
    ctx={:target=>target_unit,:move_type=>move_type,:category=>category}
    mult*=team_bond_multiplier_v0992(:physical_damage_mult,ctx) if category==:physical
    mult*=team_bond_multiplier_v0992(:special_damage_mult,ctx) if category==:special
    mult*=team_bond_multiplier_v0992(:type_damage_mult,ctx)
    roles=respond_to?(:role_tags) ? (role_tags || []) : []
    if roles.include?(:melee) && !roles.include?(:ranged)
      mult*=team_bond_multiplier_v0992(:contact_damage_mult,ctx)
    elsif roles.include?(:ranged) && !roles.include?(:melee)
      mult*=team_bond_multiplier_v0992(:ranged_damage_mult,ctx)
    end
    result=(base.to_f*mult).round
    result=1 if result<1
    result
  end

  def gain_energy(value,source=nil,reason=:generic)
    v=value.to_i
    if v>0 && reason!=:team_bond_v0992 && reason!=:synergy
      v=(v.to_f*team_bond_multiplier_v0992(:energy_gain_mult,{:reason=>reason})).round
      v=1 if v<1
    end
    pmd_ac_v0992_gain_energy(v,source,reason)
  end

  def heal(value)
    v=value.to_i
    if v>0
      v=(v.to_f*team_bond_multiplier_v0992(:healing_mult,nil)).round
      v=1 if v<1
    end
    pmd_ac_v0992_heal(v)
  end

  def effective_move_speed
    pmd_ac_v0992_effective_move_speed*team_bond_multiplier_v0992(:move_speed_mult,nil)
  end

  def apply_status(key,options={},source=nil)
    opts=options==nil ? {} : options.dup
    base=PMD_AC.status_def(key)
    tags=base[:tags] || []
    if tags.include?(:debuff) && !opts[:team_bond_ignore_duration]
      duration=(opts[:duration] || 120).to_i
      mult=team_bond_multiplier_v0992(:status_duration_mult,{:status=>key,:source=>source})
      if mult!=1.0
        duration=(duration.to_f*mult).round
        duration=1 if duration<1
        opts[:duration]=duration
      end
    end
    pmd_ac_v0992_apply_status(key,opts,source)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess：狀態、判定、一次性效果、提示與 Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0992_start start unless method_defined?(:pmd_ac_v0992_start)
  alias pmd_ac_v0992_start_battle start_battle unless method_defined?(:pmd_ac_v0992_start_battle)
  alias pmd_ac_v0992_request_mega request_mega unless method_defined?(:pmd_ac_v0992_request_mega)
  alias pmd_ac_v0992_revert_all_mega_forms revert_all_mega_forms unless method_defined?(:pmd_ac_v0992_revert_all_mega_forms)
  alias pmd_ac_v0992_update update unless method_defined?(:pmd_ac_v0992_update)
  alias pmd_ac_v0992_refresh_header refresh_header unless method_defined?(:pmd_ac_v0992_refresh_header)
  alias pmd_ac_v0992_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0992_prepare_verification_battle)
  alias pmd_ac_v0992_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0992_update_verification_script)
  alias pmd_ac_v0992_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v0992_diagnostic_presentation_suppressed_v068)

  def team_bond_mode_v0992?;verification_mode==:team_bond_v0992;end

  def start
    pmd_ac_v0992_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:team_bond,
      'FLOW v0.99.2 bonds=42 relationship=34 tactical=8 limits=1+1 '+
      'basis=battle_start faint_persist=1 summon=off actor_id=off form_refresh=1 legacy_kanto=v0.15')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0992_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.2',1)
  end

  def diagnostic_presentation_suppressed_v068?
    return true if team_bond_mode_v0992?
    pmd_ac_v0992_diagnostic_presentation_suppressed_v068
  end

  def reset_team_bond_state_v0992
    @active_team_bonds_v0992={:ally=>[],:enemy=>[]}
    @team_bond_basis_units_v0992={:ally=>[],:enemy=>[]}
    @team_bond_once_v0992={:ally=>{},:enemy=>{}}
    @team_bond_notice_queue_v0992=[]
    @team_bond_notice_timer_v0992=0
  end

  def team_bond_basis_units_v0992(team)
    reset_team_bond_state_v0992 if @team_bond_basis_units_v0992==nil
    @team_bond_basis_units_v0992[team] || []
  end

  def capture_team_bond_basis_v0992
    reset_team_bond_state_v0992 if @team_bond_basis_units_v0992==nil
    [:ally,:enemy].each do |team|
      units=[]
      for u in (@units || [])
        next unless u.team==team
        next if u.respond_to?(:summoned?) && u.summoned?
        next if u.respond_to?(:counts_for_victory?) && !u.counts_for_victory?
        units.push(u)
      end
      @team_bond_basis_units_v0992[team]=units
    end
  end

  def active_team_bond_keys_v0992(team)
    reset_team_bond_state_v0992 if @active_team_bonds_v0992==nil
    (@active_team_bonds_v0992[team] || []).dup
  end

  def active_team_bond_names_v0992(team)
    active_team_bond_keys_v0992(team).collect{|k|PMD_AC.team_bond_name_v0992(k)}
  end

  def team_bond_unit_in_basis_v0992?(unit)
    return false if unit==nil
    team_bond_basis_units_v0992(unit.team).include?(unit)
  end

  def team_bond_multiplier_for_unit_v0992(unit,type,context=nil)
    return 1.0 unless PMD_AC::TEAM_BOND_EFFECT_TYPES_V0992.include?(type)
    return 1.0 unless team_bond_unit_in_basis_v0992?(unit)
    value=1.0
    for key in active_team_bond_keys_v0992(unit.team)
      data=PMD_AC::TEAM_BOND_DATA_V0992[key] || {}
      for effect in (data[:effects] || [])
        next unless effect[:type]==type
        next unless PMD_AC.team_bond_effect_applies_context_v0992?(unit,effect,context)
        value*=PMD_AC.team_bond_effect_value_v0992(effect,type).to_f
      end
    end
    PMD_AC.team_bond_clamp_effect_v0992(type,value).to_f
  end

  def team_bond_once_done_v0992?(team,key,index)
    reset_team_bond_state_v0992 if @team_bond_once_v0992==nil
    @team_bond_once_v0992[team][key.to_s+':'+index.to_s] ? true:false
  end

  def mark_team_bond_once_v0992(team,key,index)
    reset_team_bond_state_v0992 if @team_bond_once_v0992==nil
    @team_bond_once_v0992[team][key.to_s+':'+index.to_s]=true
  end

  def team_bond_effect_targets_v0992(team,effect)
    team_bond_basis_units_v0992(team).find_all{|u|PMD_AC.team_bond_scope_matches_v0992?(u,effect[:scope])}
  end

  def apply_team_bond_once_effects_v0992(team,key)
    data=PMD_AC::TEAM_BOND_DATA_V0992[key]
    return if data==nil
    effects=data[:effects] || []
    for i in 0...effects.size
      e=effects[i]
      next unless e[:once] || [:initial_energy,:start_shield].include?(e[:type])
      next if team_bond_once_done_v0992?(team,key,i)
      if e[:type]==:initial_energy
        # v0.15 已經在更早 alias chain 套用初代御三家 +12，這裡只登記一次性已完成。
        if key==:kanto_starter_trio && e[:legacy_v015] && verification_mode==:normal
          log_event(:team_bond_effect,team.to_s.upcase+' '+key.to_s+' INITIAL_ENERGY legacy_v0.15 carried=1')
        else
          amount=(e[:amount] || 0).to_i
          for u in team_bond_effect_targets_v0992(team,e)
            actual=u.gain_energy(amount,nil,:team_bond_v0992)
            log_event(:team_bond_effect,team.to_s.upcase+' '+key.to_s+' ENERGY '+u.log_name+
              ' +'+actual.to_s+' now='+u.energy.to_s+'/'+PMD_AC::MAX_ENERGY.to_s)
          end
        end
      elsif e[:type]==:start_shield
        ratio=(e[:ratio] || 0.0).to_f
        for u in team_bond_effect_targets_v0992(team,e)
          amount=(u.maxhp.to_f*ratio).round
          amount=1 if ratio>0.0 && amount<1
          u.add_shield(amount,0,nil,nil)
          log_event(:team_bond_effect,team.to_s.upcase+' '+key.to_s+' SHIELD '+u.log_name+' +'+amount.to_s)
        end
      end
      mark_team_bond_once_v0992(team,key,i)
    end
  end

  def refresh_team_bonds_v0992(team,reason=:refresh,apply_once=true)
    reset_team_bond_state_v0992 if @active_team_bonds_v0992==nil
    basis=team_bond_basis_units_v0992(team)
    old=@active_team_bonds_v0992[team] || []
    fresh=PMD_AC.active_team_bond_keys_for_v0992(basis)
    activated=fresh-old;deactivated=old-fresh
    for key in activated
      d=PMD_AC::TEAM_BOND_DATA_V0992[key]
      log_event(:team_bond,team.to_s.upcase+' ACTIVATE '+key.to_s+' name='+PMD_AC.team_bond_name_v0992(key)+
        ' category='+d[:category].to_s+' priority='+d[:priority].to_i.to_s+' reason='+reason.to_s+
        ' units=['+basis.collect{|u|u.species_key.to_s+'#'+u.instance_uid.to_s}.join(',')+']')
    end
    for key in deactivated
      log_event(:team_bond,team.to_s.upcase+' DEACTIVATE '+key.to_s+' name='+PMD_AC.team_bond_name_v0992(key)+' reason='+reason.to_s)
    end
    @active_team_bonds_v0992[team]=fresh
    for key in activated
      apply_team_bond_once_effects_v0992(team,key) if apply_once
    end
    fresh
  end

  def queue_team_bond_notices_v0992
    return unless verification_mode==:normal
    @team_bond_notice_queue_v0992=[]
    [:ally,:enemy].each do |team|
      rel=nil;tac=nil
      for key in active_team_bond_keys_v0992(team)
        d=PMD_AC::TEAM_BOND_DATA_V0992[key]
        rel=PMD_AC.team_bond_name_v0992(key) if d[:category]==:relationship
        tac=PMD_AC.team_bond_name_v0992(key) if d[:category]==:tactical
      end
      prefix=team==:ally ? '' : '敵方'
      @team_bond_notice_queue_v0992.push(prefix+'羈絆｜'+rel) if rel!=nil
      @team_bond_notice_queue_v0992.push(prefix+'戰術｜'+tac) if tac!=nil
    end
    @team_bond_notice_timer_v0992=1 unless @team_bond_notice_queue_v0992.empty?
  end

  def update_team_bond_notice_v0992
    return if @team_bond_notice_queue_v0992==nil || @team_bond_notice_queue_v0992.empty?
    @team_bond_notice_timer_v0992=@team_bond_notice_timer_v0992.to_i-1
    return if @team_bond_notice_timer_v0992>0
    text=@team_bond_notice_queue_v0992.shift
    add_center_notice_v088(text) if respond_to?(:add_center_notice_v088)
    @team_bond_notice_timer_v0992=76
  end

  def start_battle
    reset_team_bond_state_v0992
    pmd_ac_v0992_start_battle
    return unless @phase==:battle
    # 舊 Verification Modes 必須維持凍結基準；只有正式 NORMAL 與本版 Verifier 啟用羈絆。
    return unless verification_mode==:normal || team_bond_mode_v0992?
    capture_team_bond_basis_v0992
    refresh_team_bonds_v0992(:ally,:battle_start,true)
    refresh_team_bonds_v0992(:enemy,:battle_start,true)
    queue_team_bond_notices_v0992
    refresh_footer if respond_to?(:refresh_footer)
  end

  def request_mega(unit,form=nil)
    result=pmd_ac_v0992_request_mega(unit,form)
    if result && unit!=nil && @team_bond_basis_units_v0992!=nil
      refresh_team_bonds_v0992(unit.team,:form_refresh,true)
      queue_team_bond_notices_v0992
    end
    result
  end

  def revert_all_mega_forms
    pmd_ac_v0992_revert_all_mega_forms
    if @team_bond_basis_units_v0992!=nil
      refresh_team_bonds_v0992(:ally,:form_revert,false)
      refresh_team_bonds_v0992(:enemy,:form_revert,false)
    end
  end

  def update
    pmd_ac_v0992_update
    update_team_bond_notice_v0992 if @phase==:battle
  end

  #--------------------------------------------------------------------------
  # Verifier helpers
  #--------------------------------------------------------------------------
  def team_bond_test_instance_v0992(species,extra=nil)
    opts={:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary}
    if extra!=nil
      extra.each{|k,v|opts[k]=v}
    end
    PMD_PokemonInstance.new(species,50,opts)
  end

  def team_bond_test_unit_v0992(id,species,team=:ally,extra=nil)
    u=Game_PMDChessUnit.new(id,species,team,0,0,team_bond_test_instance_v0992(species,extra))
    u.scene=self
    u
  end

  def log_team_bond_verify_v0992(label,pass,detail='')
    @team_bond_verify_results_v0992={} if @team_bond_verify_results_v0992==nil
    @team_bond_verify_results_v0992[label.to_s]=pass ? true : false
    log_event(:verify,label+' pass='+(pass ? '1':'0')+(detail.to_s.empty? ? '' : ' '+detail.to_s))
  end

  def verify_team_bond_registry_v0992
    return if @verification_done[:bond_registry_v0992]
    errors=PMD_AC.validate_team_bond_registry_v0992
    m=PMD_AC::TEAM_BOND_MANIFEST_V0992
    pass=errors.empty? && PMD_AC::TEAM_BOND_DATA_V0992.size==42 && m[:relationship_count]==34 && m[:tactical_count]==8
    log_team_bond_verify_v0992('TEAM_BOND_REGISTRY_V0992',pass,
      'total=42 relationship=34 tactical=8 errors=['+errors.join(',')+']')
    @verification_done[:bond_registry_v0992]=true
  end

  def verify_team_bond_line_pool_v0992
    return if @verification_done[:bond_line_pool_v0992]
    starters=[team_bond_test_unit_v0992(99201,:venusaur),team_bond_test_unit_v0992(99202,:charmeleon),team_bond_test_unit_v0992(99203,:blastoise)]
    eevee=[team_bond_test_unit_v0992(99204,:vaporeon),team_bond_test_unit_v0992(99205,:espeon),team_bond_test_unit_v0992(99206,:glaceon)]
    a=PMD_AC.active_team_bond_keys_for_v0992(starters)
    b=PMD_AC.active_team_bond_keys_for_v0992(eevee)
    pass=a.include?(:kanto_starter_trio) && b.include?(:eevee_prismatic)
    log_team_bond_verify_v0992('TEAM_BOND_LINE_POOL_V0992',pass,'line='+a.inspect+' pool='+b.inspect)
    @verification_done[:bond_line_pool_v0992]=true
  end

  def verify_team_bond_duplicate_summon_v0992
    return if @verification_done[:bond_duplicate_summon_v0992]
    a=team_bond_test_unit_v0992(99211,:bulbasaur)
    b=team_bond_test_unit_v0992(99212,:bulbasaur)
    c=team_bond_test_unit_v0992(99213,:bulbasaur)
    dup=PMD_AC.active_team_bond_keys_for_v0992([a,b,c]).include?(:kanto_starter_trio)
    s=team_bond_test_unit_v0992(99214,:squirtle)
    s.configure_as_summon(a,{:duration=>120,:stat_scale=>1.0,:hp_scale=>1.0})
    summon=PMD_AC.active_team_bond_keys_for_v0992([a,team_bond_test_unit_v0992(99215,:charmander),s]).include?(:kanto_starter_trio)
    pass=!dup && !summon
    log_team_bond_verify_v0992('TEAM_BOND_DUPLICATE_SUMMON_V0992',pass,'duplicate_rejected='+(!dup ? '1':'0')+' summon_excluded='+(!summon ? '1':'0'))
    @verification_done[:bond_duplicate_summon_v0992]=true
  end

  def verify_team_bond_priority_v0992
    return if @verification_done[:bond_priority_v0992]
    units=[team_bond_test_unit_v0992(99221,:espeon),team_bond_test_unit_v0992(99222,:umbreon),team_bond_test_unit_v0992(99223,:vaporeon)]
    all_rel=[]
    PMD_AC::TEAM_BOND_DATA_V0992.each do |k,d|
      all_rel.push(k) if d[:category]==:relationship && PMD_AC.team_bond_met_v0992?(units,d)
    end
    active=PMD_AC.active_team_bond_keys_for_v0992(units)
    pass=all_rel.include?(:sun_moon_resonance) && all_rel.include?(:eevee_prismatic) && active.include?(:eevee_prismatic) && !active.include?(:sun_moon_resonance)
    log_team_bond_verify_v0992('TEAM_BOND_PRIORITY_V0992',pass,'candidates=['+all_rel.join(',')+'] active=['+active.join(',')+']')
    @verification_done[:bond_priority_v0992]=true
  end

  def verify_team_bond_category_limit_v0992
    return if @verification_done[:bond_category_limit_v0992]
    allies=team_bond_basis_units_v0992(:ally)
    keys=active_team_bond_keys_v0992(:ally)
    rel=keys.find_all{|k|PMD_AC::TEAM_BOND_DATA_V0992[k][:category]==:relationship}.size
    tac=keys.find_all{|k|PMD_AC::TEAM_BOND_DATA_V0992[k][:category]==:tactical}.size
    pass=allies.size==3 && rel<=1 && tac<=1 && keys.include?(:kanto_starter_trio)
    log_team_bond_verify_v0992('TEAM_BOND_CATEGORY_LIMIT_V0992',pass,'ally=['+keys.join(',')+'] relationship='+rel.to_s+' tactical='+tac.to_s+' basis='+allies.size.to_s)
    @verification_done[:bond_category_limit_v0992]=true
  end

  def verify_team_bond_initial_energy_v0992
    return if @verification_done[:bond_initial_energy_v0992]
    vals=team_bond_basis_units_v0992(:ally).collect{|u|u.energy.to_i}
    # v0.15 舊羈絆 +12 必須只出現一次；v0.99.2 不可再加成成 24。
    pass=!vals.empty? && vals.all?{|v|v==12}
    log_team_bond_verify_v0992('TEAM_BOND_INITIAL_ENERGY_V0992',pass,'energy=['+vals.join(',')+'] legacy_v015_once=1')
    @verification_done[:bond_initial_energy_v0992]=true
  end

  def with_team_bond_test_state_v0992(team,keys,basis)
    old_a=@active_team_bonds_v0992
    old_b=@team_bond_basis_units_v0992
    @active_team_bonds_v0992={:ally=>[],:enemy=>[]}
    @team_bond_basis_units_v0992={:ally=>[],:enemy=>[]}
    @active_team_bonds_v0992[team]=keys
    @team_bond_basis_units_v0992[team]=basis
    begin
      yield
    ensure
      @active_team_bonds_v0992=old_a
      @team_bond_basis_units_v0992=old_b
    end
  end

  def verify_team_bond_runtime_mods_v0992
    return if @verification_done[:bond_runtime_mods_v0992]
    attacker=team_bond_test_unit_v0992(99231,:zangoose,:ally)
    target=team_bond_test_unit_v0992(99232,:caterpie,:enemy)
    damage=0
    with_team_bond_test_state_v0992(:ally,[:rivals_united],[attacker]) do
      before=target.hp.to_i
      target.receive_damage(100,attacker,false)
      damage=before-target.hp.to_i
    end
    energy_unit=team_bond_test_unit_v0992(99233,:uxie,:ally)
    eg=0
    with_team_bond_test_state_v0992(:ally,[:lake_guardians],[energy_unit]) do
      before=energy_unit.energy.to_i;energy_unit.gain_energy(20,nil,:verify);eg=energy_unit.energy.to_i-before
    end
    heal_unit=team_bond_test_unit_v0992(99234,:manaphy,:ally)
    heal_unit.instance_variable_set(:@hp,[heal_unit.maxhp.to_i-500,1].max)
    hg=0
    with_team_bond_test_state_v0992(:ally,[:sea_royalty],[heal_unit]) do
      before=heal_unit.hp.to_i;heal_unit.heal(100);hg=heal_unit.hp.to_i-before
    end
    speed_unit=team_bond_test_unit_v0992(99235,:raikou,:ally)
    base_speed=0.0;bond_speed=0.0
    with_team_bond_test_state_v0992(:ally,[],[speed_unit]){base_speed=speed_unit.effective_move_speed}
    with_team_bond_test_state_v0992(:ally,[:legendary_beasts],[speed_unit]){bond_speed=speed_unit.effective_move_speed}
    status_unit=team_bond_test_unit_v0992(99236,:regirock,:ally)
    src=team_bond_test_unit_v0992(99237,:rattata,:enemy)
    dur=0
    with_team_bond_test_state_v0992(:ally,[:regi_trio],[status_unit]) do
      status_unit.apply_status(:fear,{:duration=>100},src)
      h=status_unit.instance_variable_get(:@statuses) || {};dur=h[:fear]==nil ? 0 : h[:fear][:duration].to_i
    end
    pass=damage==108 && eg==22 && hg==110 && bond_speed>base_speed && dur==85
    log_team_bond_verify_v0992('TEAM_BOND_RUNTIME_MODS_V0992',pass,
      'damage=100->'+damage.to_s+' energy=20->'+eg.to_s+' heal=100->'+hg.to_s+
      ' speed='+sprintf('%.2f',base_speed)+'->'+sprintf('%.2f',bond_speed)+' status=100->'+dur.to_s)
    @verification_done[:bond_runtime_mods_v0992]=true
  end

  def verify_team_bond_type_scope_v0992
    return if @verification_done[:bond_type_scope_v0992]
    gard=team_bond_test_unit_v0992(99241,:gardevoir,:ally)
    gall=team_bond_test_unit_v0992(99242,:gallade,:ally)
    spec=1.0;phys=1.0;wrong=1.0
    with_team_bond_test_state_v0992(:ally,[:blade_and_guardian],[gard,gall]) do
      spec=team_bond_multiplier_for_unit_v0992(gard,:special_damage_mult,{:move_type=>:psychic})
      phys=team_bond_multiplier_for_unit_v0992(gall,:physical_damage_mult,{:move_type=>:fighting})
      wrong=team_bond_multiplier_for_unit_v0992(gard,:physical_damage_mult,{:move_type=>:psychic})
    end
    pass=(spec-1.06).abs<0.001 && (phys-1.06).abs<0.001 && (wrong-1.0).abs<0.001
    log_team_bond_verify_v0992('TEAM_BOND_SCOPE_V0992',pass,'gardevoir_special='+sprintf('%.2f',spec)+' gallade_physical='+sprintf('%.2f',phys)+' wrong='+sprintf('%.2f',wrong))
    @verification_done[:bond_type_scope_v0992]=true
  end

  def verify_team_bond_faint_persist_v0992
    return if @verification_done[:bond_faint_persist_v0992]
    before=active_team_bond_keys_v0992(:ally)
    basis=team_bond_basis_units_v0992(:ally)
    victim=basis[0]
    old_hp=victim.hp.to_i
    victim.instance_variable_set(:@hp,0)
    refresh_team_bonds_v0992(:ally,:verify_faint,false)
    after=active_team_bond_keys_v0992(:ally)
    victim.instance_variable_set(:@hp,old_hp)
    pass=before==after && after.include?(:kanto_starter_trio)
    log_team_bond_verify_v0992('TEAM_BOND_FAINT_PERSIST_V0992',pass,'before=['+before.join(',')+'] after=['+after.join(',')+'] basis_locked=1')
    @verification_done[:bond_faint_persist_v0992]=true
  end

  def verify_team_bond_form_refresh_v0992
    return if @verification_done[:bond_form_refresh_v0992]
    unit=team_bond_test_unit_v0992(99251,:venusaur,:ally)
    req=[{:type=>:form,:species=>:venusaur,:form=>:mega}]
    normal=PMD_AC.team_bond_composition_met_v0992?([unit],req)
    unit.pokemon_instance.mega_evolve!(:mega);unit.sync_from_pokemon_instance
    mega=PMD_AC.team_bond_composition_met_v0992?([unit],req)
    unit.revert_mega_form
    reverted=PMD_AC.team_bond_composition_met_v0992?([unit],req)
    pass=!normal && mega && !reverted
    log_team_bond_verify_v0992('TEAM_BOND_FORM_REFRESH_V0992',pass,'normal='+(normal ? '1':'0')+' mega='+(mega ? '1':'0')+' reverted='+(reverted ? '1':'0'))
    @verification_done[:bond_form_refresh_v0992]=true
  end

  def verify_team_bond_enemy_compat_v0992
    return if @verification_done[:bond_enemy_compat_v0992]
    enemies=[team_bond_test_unit_v0992(99261,:regirock,:enemy),team_bond_test_unit_v0992(99262,:regice,:enemy),team_bond_test_unit_v0992(99263,:registeel,:enemy)]
    keys=PMD_AC.active_team_bond_keys_for_v0992(enemies)
    old_units=[team_bond_test_unit_v0992(99264,:bulbasaur),team_bond_test_unit_v0992(99265,:charmander),team_bond_test_unit_v0992(99266,:squirtle)]
    legacy=PMD_AC.active_synergy_keys_for(old_units)
    pass=keys.include?(:regi_trio) && legacy.include?(:kanto_starter_trio)
    log_team_bond_verify_v0992('TEAM_BOND_ENEMY_COMPAT_V0992',pass,'enemy=['+keys.join(',')+'] legacy_v015=['+legacy.join(',')+'] actor_id_unused=1')
    @verification_done[:bond_enemy_compat_v0992]=true
  end

  def prepare_verification_battle
    pmd_ac_v0992_prepare_verification_battle
    if team_bond_mode_v0992?
      for u in (@units || [])
        u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
      end
      log_event(:showcase,'START mode=TEAM_BOND_V0992 bonds=42 relationship=34 tactical=8 fake_vfx=off fake_sfx=off')
    end
  end

  def update_verification_script
    unless team_bond_mode_v0992?
      pmd_ac_v0992_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_team_bond_registry_v0992 if f>=2
    verify_team_bond_line_pool_v0992 if f>=6
    verify_team_bond_duplicate_summon_v0992 if f>=10
    verify_team_bond_priority_v0992 if f>=14
    verify_team_bond_category_limit_v0992 if f>=18
    verify_team_bond_initial_energy_v0992 if f>=22
    verify_team_bond_runtime_mods_v0992 if f>=28
    verify_team_bond_type_scope_v0992 if f>=36
    verify_team_bond_faint_persist_v0992 if f>=44
    verify_team_bond_form_refresh_v0992 if f>=52
    verify_team_bond_enemy_compat_v0992 if f>=60
    if f>=68 && !@verification_done[:bond_final_v0992]
      required=[:bond_registry_v0992,:bond_line_pool_v0992,:bond_duplicate_summon_v0992,
        :bond_priority_v0992,:bond_category_limit_v0992,:bond_initial_energy_v0992,
        :bond_runtime_mods_v0992,:bond_type_scope_v0992,:bond_faint_persist_v0992,
        :bond_form_refresh_v0992,:bond_enemy_compat_v0992]
      labels=['TEAM_BOND_REGISTRY_V0992','TEAM_BOND_LINE_POOL_V0992',
        'TEAM_BOND_DUPLICATE_SUMMON_V0992','TEAM_BOND_PRIORITY_V0992',
        'TEAM_BOND_CATEGORY_LIMIT_V0992','TEAM_BOND_INITIAL_ENERGY_V0992',
        'TEAM_BOND_RUNTIME_MODS_V0992','TEAM_BOND_SCOPE_V0992',
        'TEAM_BOND_FAINT_PERSIST_V0992','TEAM_BOND_FORM_REFRESH_V0992',
        'TEAM_BOND_ENEMY_COMPAT_V0992']
      done=required.all?{|k|@verification_done[k]}
      results=@team_bond_verify_results_v0992 || {}
      pass=done && labels.all?{|label|results[label]==true}
      log_team_bond_verify_v0992('TEAM_BOND_V0992',pass,
        'bonds=42 relationship=34 tactical=8 category_limit=1+1 faint_persist=1 legacy_v015=1 rpg_persistent=1')
      @verification_done[:bond_final_v0992]=true
    end
    complete_verification_mode if f>=PMD_AC::TEAM_BOND_VERIFY_END_V0992
  end
end
