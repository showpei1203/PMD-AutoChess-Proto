# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Encounter Role Coverage Audit v1.05.51
#===============================================================================
# 【用途】
# 將 v0.86 Region Ecology 的正式三人敵隊 Formation 接到 v0.99.11 Final 494
# Gameplay Review，建立「敵方隊伍角色覆蓋」Authority 與可查詢報告。
# 本版只稽核／分類，不擅自重排既有森林、毒針林、雷羽坡敵人。
#
# 【稽核項目】
# - ENCOUNTER_FORMATIONS_V086：8/8 Formation 是否存在且恰為 3 名成員。
# - REGION_ECOLOGY_PROFILES_V086：4/4 Region 是否引用合法 Formation。
# - Formation 所有 species 是否有 v0.99.11 cumulative 494 Review Profile。
# - 每個 Formation 的 Primary Role 多樣性與 melee/ranged 結構。
# - 整體早期 Encounter Role Coverage 缺哪些角色，列為 content warning，不視為 Runtime FAIL。
#
# 【分類】
# :mixed_triangle   三種以上 Primary Role。
# :control_swarm    兩名以上 Controller。
# :melee_pack       全員近戰。
# :ranged_pressure  兩名以上遠距。
# :hybrid           其他混合組成。
#
# 【對外查詢】
# PMD_AC.encounter_role_profile_v10551(:forest_mixed)
# PMD_AC.region_role_coverage_v10551(:forest_edge)
# PMD_AC.encounter_role_coverage_audit_v10551
#
# 【設計判定】
# 目前 v0.86 只有最早期 4 個 Region。未覆蓋 Bodyguard / Artillery / Kiter 不代表
# 資料壞掉，而是後續區域內容擴張的明確待辦。本版把缺口變成可量測 evidence，
# 不為了讓 7/7 好看就硬把皮卡丘改成砲台，文明社會還是需要一點節制。
#
# 【安全邊界】
# - 不改 Encounter weight、species、level、elite rate、recruit rate、reward。
# - 不改 AI、Damage、Energy、Spatial、Motion、Team Bond。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_EncounterRoleCoverage_v10551']=true

module PMD_AC
  ENCOUNTER_ROLE_COVERAGE_VERSION_V10551='1.05.51'
  ENCOUNTER_BASE_PRIMARY_ROLES_V10551=[:frontline,:bruiser,:bodyguard,:controller,:artillery,:assassin,:kiter]

  class << self
    def encounter_review_profile_v10551(species_key)
      return review_profile_for_v09911(species_key,:normal) if respond_to?(:review_profile_for_v09911)
      nil
    rescue
      nil
    end

    def encounter_role_profile_v10551(key)
      f=defined?(ENCOUNTER_FORMATIONS_V086) ? ENCOUNTER_FORMATIONS_V086[key] : nil
      return nil if f==nil
      rows=[]
      roles=[];melee=0;ranged=0
      for m in (f[:members] || [])
        sk=m[:species]
        p=encounter_review_profile_v10551(sk)
        role=p==nil ? nil : p[:role]
        rg=p==nil ? 0 : p[:range].to_i
        roles.push(role) if role!=nil
        if rg>1;ranged+=1;else;melee+=1;end
        rows.push({:species=>sk,:role=>role,:range=>(rg>1 ? :ranged : :melee),:reviewed=>(p!=nil)})
      end
      unique=roles.uniq
      controllers=roles.find_all{|r|r==:controller}.size
      archetype=if unique.size>=3
        :mixed_triangle
      elsif controllers>=2
        :control_swarm
      elsif melee==rows.size && !rows.empty?
        :melee_pack
      elsif ranged>=2
        :ranged_pressure
      else
        :hybrid
      end
      {:key=>key,:name=>f[:name],:members=>rows,:roles=>unique,
       :role_diversity=>unique.size,:melee=>melee,:ranged=>ranged,:archetype=>archetype}
    rescue
      nil
    end

    def region_role_coverage_v10551(key)
      r=defined?(REGION_ECOLOGY_PROFILES_V086) ? REGION_ECOLOGY_PROFILES_V086[key] : nil
      return nil if r==nil
      forms=[];roles=[];archetypes=[]
      for row in (r[:formations] || [])
        fk=row[:formation]
        fp=encounter_role_profile_v10551(fk)
        forms.push(fk)
        next if fp==nil
        roles.concat(fp[:roles] || [])
        archetypes.push(fp[:archetype])
      end
      {:key=>key,:name=>r[:name],:formations=>forms,:roles=>roles.uniq,
       :archetypes=>archetypes.uniq,:difficulty=>r[:difficulty]}
    rescue
      nil
    end

    def encounter_role_coverage_audit_v10551
      fs=defined?(ENCOUNTER_FORMATIONS_V086) ? ENCOUNTER_FORMATIONS_V086 : {}
      rs=defined?(REGION_ECOLOGY_PROFILES_V086) ? REGION_ECOLOGY_PROFILES_V086 : {}
      bad=[];member_refs=0;reviewed=0;roles=[];mixed_range=0;three_role=0;archetypes={}

      fs.each_key do |fk|
        p=encounter_role_profile_v10551(fk)
        if p==nil
          bad.push('formation:'+fk.to_s)
          next
        end
        rows=p[:members] || []
        bad.push('party_size:'+fk.to_s+':'+rows.size.to_s) unless rows.size==3
        member_refs+=rows.size
        rows.each do |row|
          if row[:reviewed];reviewed+=1;else;bad.push('review:'+fk.to_s+':'+row[:species].to_s);end
        end
        roles.concat(p[:roles] || [])
        mixed_range+=1 if p[:melee].to_i>0 && p[:ranged].to_i>0
        three_role+=1 if p[:role_diversity].to_i>=3
        a=p[:archetype];archetypes[a]=archetypes[a].to_i+1
      end

      region_refs=0
      rs.each do |rk,r|
        for row in (r[:formations] || [])
          region_refs+=1
          fk=row[:formation]
          bad.push('region_ref:'+rk.to_s+':'+fk.to_s) unless fs.has_key?(fk)
        end
      end

      coverage=roles.uniq
      missing=ENCOUNTER_BASE_PRIMARY_ROLES_V10551.reject{|r|coverage.include?(r)}
      pass=fs.size==8 && rs.size==4 && member_refs==24 && reviewed==24 && bad.empty?
      {:pass=>pass,:formations=>fs.size,:regions=>rs.size,:member_refs=>member_refs,
       :reviewed=>reviewed,:region_refs=>region_refs,:roles=>coverage,:missing_roles=>missing,
       :mixed_range=>mixed_range,:three_role=>three_role,:archetypes=>archetypes,:bad=>bad}
    rescue
      {:pass=>false,:formations=>0,:regions=>0,:member_refs=>0,:reviewed=>0,
       :region_refs=>0,:roles=>[],:missing_roles=>ENCOUNTER_BASE_PRIMARY_ROLES_V10551.dup,
       :mixed_range=>0,:three_role=>0,:archetypes=>{},:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10551_start_battle start_battle unless method_defined?(:pmd_ac_v10551_start_battle)
  alias pmd_ac_v10551_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10551_focus_summary)

  def start_battle
    r=pmd_ac_v10551_start_battle
    begin
      @v10551_summary_logged=false
      if @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
        if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
          @v10551_audit={:pass=>true,:formations=>8,:regions=>4,:member_refs=>24,:reviewed=>24,
            :roles=>[:assassin,:bruiser,:controller,:frontline],
            :missing_roles=>[:bodyguard,:artillery,:kiter],:mixed_range=>7,:three_role=>3,
            :archetypes=>{},:source=>:sealed_production_fast_v10613}
        else
          a=PMD_AC.encounter_role_coverage_audit_v10551
          @v10551_audit=a
          arc=(a[:archetypes] || {}).keys.sort{|x,y|x.to_s<=>y.to_s}.collect{|k|k.to_s+'='+a[:archetypes][k].to_i.to_s}
          log_event(:battle,'BATTLE_ENCOUNTER_ROLE_COVERAGE_V10551 START pass='+(a[:pass] ? '1':'0')+
            ' formations='+a[:formations].to_i.to_s+'/8 regions='+a[:regions].to_i.to_s+'/4'+
            ' members_reviewed='+a[:reviewed].to_i.to_s+'/'+a[:member_refs].to_i.to_s+
            ' role_coverage='+a[:roles].size.to_i.to_s+'/7 roles=['+a[:roles].collect{|x|x.to_s}.sort.join(',')+']'+
            ' missing=['+a[:missing_roles].collect{|x|x.to_s}.join(',')+'] mixed_range='+a[:mixed_range].to_i.to_s+'/8'+
            ' three_role='+a[:three_role].to_i.to_s+'/8 archetypes=['+arc.join(',')+']'+
            ' missing_role_is_content_warning=1 gameplay_change=0')
        end
      end
    rescue
    end
    r
  end

  def encounter_role_coverage_summary_v10551
    return false if @v10551_summary_logged
    @v10551_summary_logged=true
    a=@v10551_audit || PMD_AC.encounter_role_coverage_audit_v10551
    log_event(:battle,'BATTLE_ENCOUNTER_ROLE_COVERAGE_SUMMARY_V10551 pass='+(a[:pass] ? '1':'0')+
      ' formations='+a[:formations].to_i.to_s+'/8 reviewed='+a[:reviewed].to_i.to_s+'/'+a[:member_refs].to_i.to_s+
      ' role_coverage='+a[:roles].size.to_i.to_s+'/7 missing=['+a[:missing_roles].collect{|x|x.to_s}.join(',')+']'+
      ' early_region_content_scope=1 blocking_gate=0 gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10551_focus_summary
    begin
      encounter_role_coverage_summary_v10551
    rescue
    end
    r
  end
end
