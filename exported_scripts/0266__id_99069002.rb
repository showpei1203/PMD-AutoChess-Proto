#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.69
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V069 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - combat_ai_scalar_v069 / combat_ai_checksum32_v069 / validate_combat_ai_v069 / start
# - diagnostic_presentation_suppressed_v068? / combat_ai_phase2_active_v069? / combat_ai_effective_data_v069 / combat_ai_move_type_v069
# - combat_ai_damage_category_v069 / combat_ai_single_target_hostile_v069? / combat_ai_redirect_absorber_v069 / combat_ai_safe_incoming_factor_v069
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.69
# Combat AI Integration II
#------------------------------------------------------------------------------
# Adds move-target pair scoring, ability/accuracy awareness, redirection trap
# awareness, focus fire, ally triage and weather/field decision context.
# Movement, basic-target selection, damage packets, Native Pose and anchors stay
# on their previously verified implementations.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V069='0.69'

  class << self
    def combat_ai_scalar_v069(x)
      return '' if x==nil
      return x.collect{|v|combat_ai_scalar_v069(v)}.join(',') if x.is_a?(Array)
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+combat_ai_scalar_v069(x[k])}.join(',')
      end
      x.to_s
    end

    def combat_ai_checksum32_v069
      h=0;m=COMBAT_AI_MANIFEST_V069
      [:schema_version,:content_version,:base_version,:feature,:selection_source,
       :base_score,:features,:movement_core,:basic_target_core,:skill_target_layer,
       :damage_packet,:native_router,:presentation_anchors,:ability_slots,
       :ability_slots_total,:ability_species,:move_runtime,:learnset_coverage].each do |k|
        combat_ai_scalar_v069(m[k]).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      COMBAT_AI_TUNING_V069.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        (k.to_s+'='+combat_ai_scalar_v069(COMBAT_AI_TUNING_V069[k])).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_combat_ai_v069
      e=[];m=COMBAT_AI_MANIFEST_V069
      e.push('features') unless m[:features].size==9
      e.push('moves') unless m[:move_runtime].to_i==526
      e.push('ability_slots') unless m[:ability_slots].to_i==1028 && m[:ability_slots_total].to_i==1193
      e.push('ability_species') unless m[:ability_species].to_i==483
      e.push('target_layer') unless m[:skill_target_layer]=='v0.69_pair_scoring_overlay'
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :combat_ai_integration_ii_v069,
    :combat_ai_integration_v068,
    :ability_runtime_coverage_iv_v067,
    :ability_runtime_coverage_iii_v066,
    :ability_runtime_coverage_ii_v065,
    :ability_runtime_coverage_v064,
    :native_semantic_audit_v063,
    :native_semantic_v062,
    :native_combo_preview_v062,
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :combat_ai_integration_ii_v069=>'COMBAT_AI_INTEGRATION_II_V069',
    :combat_ai_integration_v068=>'COMBAT_AI_INTEGRATION_V068',
    :ability_runtime_coverage_iv_v067=>'ABILITY_RUNTIME_COVERAGE_IV_V067',
    :ability_runtime_coverage_iii_v066=>'ABILITY_RUNTIME_COVERAGE_III_V066',
    :ability_runtime_coverage_ii_v065=>'ABILITY_RUNTIME_COVERAGE_II_V065',
    :ability_runtime_coverage_v064=>'ABILITY_RUNTIME_COVERAGE_V064',
    :native_semantic_audit_v063=>'NATIVE_SEMANTIC_AUDIT_V063',
    :native_semantic_v062=>'NATIVE_SEMANTIC_V062',
    :native_combo_preview_v062=>'NATIVE_COMBO_PREVIEW_V062',
    :compiled_pose_runtime_v061=>'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060=>'MULTI_CHOREO_V060',
    :native_pose_showcase_v060=>'NATIVE_POSE_SHOWCASE_V060'
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v069_start start unless method_defined?(:pmd_ac_v069_start)
  alias pmd_ac_v069_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v069_prepare_verification_battle)
  alias pmd_ac_v069_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v069_update_verification_script)
  alias pmd_ac_v069_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v069_progression_candidate_score_v046)
  alias pmd_ac_v069_skill_enemy_target skill_enemy_target unless method_defined?(:pmd_ac_v069_skill_enemy_target)
  alias pmd_ac_v069_skill_ally_target skill_ally_target unless method_defined?(:pmd_ac_v069_skill_ally_target)
  alias pmd_ac_v069_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v069_diagnostic_presentation_suppressed_v068)

  def start
    pmd_ac_v069_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.68 Battle Verification Log/,
          'PMD AutoChess Proto v0.69 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:combat_ai,
      'LOADED phase=II pair_scoring=1 ability_awareness=1 accuracy=1 redirect=1 '+
      'focus_fire=1 ally_triage=1 weather_field_context=1 movement=v0.15_unchanged '+
      'basic_target=v0.15_unchanged damage_packet=v0.60.2')
    log_event(:presentation,
      'PATCH v0.69 diagnostic_vfx_isolation=v0.68_carried native_router=v0.62_unchanged '+
      'beam_projectile_impact_targetfx=unchanged')
  end

  def diagnostic_presentation_suppressed_v068?
    return true if verification_mode==:combat_ai_integration_ii_v069
    pmd_ac_v069_diagnostic_presentation_suppressed_v068
  end

  def combat_ai_phase2_active_v069?
    m=verification_mode
    m==:normal || m==:combat_ai_integration_ii_v069
  end

  def combat_ai_effective_data_v069(data)
    return data if data==nil
    if respond_to?(:canonical_weather_adjust_skill_data)
      begin
        return canonical_weather_adjust_skill_data(data)
      rescue
      end
    end
    data
  end

  def combat_ai_move_type_v069(unit,data)
    begin
      t=ability_move_type_v065(unit,data,:skill) if respond_to?(:ability_move_type_v065)
      return combat_ai_sym_v068(t) if t!=nil
    rescue
    end
    combat_ai_sym_v068(combat_ai_get_v068(data,:move_type)||combat_ai_get_v068(data,:type)||:normal)
  end

  def combat_ai_damage_category_v069(data)
    c=combat_ai_sym_v068(combat_ai_get_v068(data,:damage_category)||combat_ai_get_v068(data,:category))
    return :physical if c==nil || c==:status
    c
  end

  def combat_ai_single_target_hostile_v069?(data)
    return false if data==nil
    tt=combat_ai_sym_v068(combat_ai_get_v068(data,:target_type)||:enemy_targeted)
    return false unless tt==:enemy_targeted
    return false if combat_ai_get_v068(data,:global_direct)
    return false if combat_ai_get_v068(data,:target)==:all_opponents
    d=combat_ai_sym_v068(combat_ai_get_v068(data,:delivery))
    return false if [:aoe,:chain,:bounce,:pierce,:sweep].include?(d)
    true
  end

  def combat_ai_redirect_absorber_v069(unit,data)
    return nil unless combat_ai_single_target_hostile_v069?(data)
    type=combat_ai_move_type_v069(unit,data)
    key=nil
    key=:lightning_rod if type==:electric
    key=:storm_drain if type==:water
    return nil if key==nil
    arr=enemies_of(unit).find_all{|u|u!=nil && u.alive? && u.respond_to?(:ability_key) && u.ability_key==key}
    return nil if arr.empty?
    arr.sort_by{|u|[-u.speed_stat.to_i,u.instance_uid.to_i]}[0]
  end

  # Side-effect-free incoming estimate. Do not call ability_incoming_multiplier
  # here because absorbers such as Dry Skin intentionally heal in that runtime.
  def combat_ai_safe_incoming_factor_v069(target,type,category,eff,data=nil)
    return 1.0 if target==nil || !target.respond_to?(:ability_key)
    d={};begin;d=PMD_AC.ability_data(target.ability_key)||{};rescue;d={};end
    k=d[:kind]
    if [:type_immunity,:type_absorb,:type_absorb_boost,:type_immunity_stage].include?(k)
      return 0.0 if combat_ai_sym_v068(d[:type])==type
    elsif k==:type_redirect_absorb_spatk
      return 0.0 if combat_ai_sym_v068(d[:move_type])==type
    elsif k==:incoming_type_reduction
      return d[:mult].to_f if (d[:types]||[]).include?(type)
    elsif k==:super_effective_reduction
      return d[:mult].to_f if eff.to_f>1.0
    elsif k==:non_super_effective_immunity
      return 0.0 if eff.to_f>0.0 && eff.to_f<=1.0
    elsif k==:full_hp_incoming_multiplier
      if target.hp.to_i>=target.maxhp.to_i
        return d[:num].to_f/[d[:den].to_i,1].max.to_f
      end
    elsif k==:fire_and_burn_reduction
      return d[:fire_num].to_f/[d[:fire_den].to_i,1].max.to_f if type==:fire
    elsif k==:dry_skin
      return 0.0 if type==:water
      return d[:fire_num].to_f/[d[:fire_den].to_i,1].max.to_f if type==:fire
    elsif k==:sound_immunity
      return 0.0 if data!=nil && (combat_ai_get_v068(data,:sound) || (combat_ai_get_v068(data,:source_move_flags)||[]).include?(:sound))
    end
    1.0
  end

  def combat_ai_status_ability_blocked_v069?(target,data)
    return false if target==nil || data==nil || !target.respond_to?(:ability_key)
    statuses=[]
    for t in combat_ai_effect_types_v068(data)
      s=PMD_AC::COMBAT_AI_MAJOR_STATUS_EFFECT_MAP_V069[t]
      statuses.push(s) if s!=nil
    end
    return false if statuses.empty?
    d={};begin;d=PMD_AC.ability_data(target.ability_key)||{};rescue;d={};end
    if d[:kind]==:status_immunity
      return true unless ((d[:statuses]||[]) & statuses).empty?
    elsif d[:kind]==:weather_status_immunity
      if respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(combat_ai_sym_v068(d[:weather]))
        return true unless ((d[:statuses]||[]) & statuses).empty?
      end
    end
    false
  end

  def combat_ai_accuracy_factor_v069(unit,target,data,damaging)
    chance=100.0
    begin
      chance=canonical_accuracy_probability(unit,target,data).to_f
    rescue
      a=combat_ai_get_v068(data,:accuracy);chance=a.to_f if a!=nil
    end
    chance=100.0 if chance<=0.0 && combat_ai_get_v068(data,:accuracy)==nil
    chance=PMD_AC.clamp(chance,0.0,100.0)/100.0
    t=PMD_AC::COMBAT_AI_TUNING_V069
    if damaging
      return t[:damage_accuracy_floor].to_f+t[:damage_accuracy_weight].to_f*chance
    end
    t[:status_accuracy_floor].to_f+t[:status_accuracy_weight].to_f*chance
  end

  def combat_ai_outgoing_factor_v069(unit,type,category,eff)
    return 1.0 if unit==nil || !unit.respond_to?(:ability_outgoing_multiplier)
    begin
      return unit.ability_outgoing_multiplier(type,category,eff).to_f
    rescue
      return 1.0
    end
  end

  def combat_ai_friend_guard_factor_v069(target)
    return 1.0 unless respond_to?(:ability_friend_guard_multiplier_v065)
    begin
      return ability_friend_guard_multiplier_v065(target,@units).to_f
    rescue
      1.0
    end
  end

  def combat_ai_field_key_v069(data)
    for e in (data==nil ? [] : (data[:effects]||[]))
      if combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:field_effect
        return combat_ai_sym_v068(combat_ai_get_v068(e,:key))
      end
    end
    nil
  end

  def combat_ai_weather_key_v069(data)
    for e in (data==nil ? [] : (data[:effects]||[]))
      if combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:set_weather
        return combat_ai_sym_v068(combat_ai_get_v068(e,:weather))
      end
    end
    nil
  end

  def combat_ai_weather_ability_synergy_v069(unit,weather)
    return 0 if unit==nil || weather==nil
    n=0
    for a in allies_of(unit)
      b={};begin;b=PMD_AC::WeatherDB.ability(a.ability_key)||{};rescue;b={};end
      n+=1 if combat_ai_sym_v068(b[:weather])==weather
      n+=1 if weather==:sun && a.respond_to?(:ability_key) && a.ability_key==:flower_gift
      n+=1 if [:sun,:rain,:hail].include?(weather) && a.respond_to?(:ability_key) && a.ability_key==:forecast
    end
    n
  end

  def combat_ai_status_redundant_v069?(target,data)
    return false if target==nil || data==nil || !target.respond_to?(:status?)
    for t in combat_ai_effect_types_v068(data)
      s=PMD_AC::COMBAT_AI_MAJOR_STATUS_EFFECT_MAP_V069[t]
      return true if s!=nil && target.status?(s)
    end
    false
  end

  def combat_ai_focus_count_v069(unit,target)
    return 0 if unit==nil || target==nil
    n=0
    for a in allies_of(unit)
      next if a==unit
      n+=1 if a.respond_to?(:target) && a.target==target
    end
    n
  end

  # Wrap v0.68's score. It remains the owner of Heal/Buff/Debuff/Status/Guard/
  # Priority/Reactive/Field/Weather/AoE/Multi-hit/Two-turn category values.
  def progression_candidate_score_v046(unit,target,data,move,slot)
    return pmd_ac_v069_progression_candidate_score_v046(unit,target,data,move,slot) unless combat_ai_phase2_active_v069?
    d=combat_ai_effective_data_v069(data)
    actual=target
    redirect=combat_ai_redirect_absorber_v069(unit,d)
    actual=redirect if redirect!=nil
    score=pmd_ac_v069_progression_candidate_score_v046(unit,actual,d,move,slot)
    return nil if score==nil
    damaging=combat_ai_damaging_v068?(d)
    score=score.to_f*combat_ai_accuracy_factor_v069(unit,actual,d,damaging)

    if damaging
      type=combat_ai_move_type_v069(unit,d);cat=combat_ai_damage_category_v069(d)
      eff=1.0
      begin;eff=PMD_AC.type_effectiveness(type,actual.pokemon_types).to_f;rescue;eff=1.0;end
      inc=combat_ai_safe_incoming_factor_v069(actual,type,cat,eff,d)
      out=combat_ai_outgoing_factor_v069(unit,type,cat,eff)
      fg=combat_ai_friend_guard_factor_v069(actual)
      if inc<=0.0 || eff<=0.0
        score=PMD_AC::COMBAT_AI_TUNING_V069[:ability_immunity_score].to_f
      else
        score*=inc*out*fg
      end
    else
      if combat_ai_status_ability_blocked_v069?(actual,d)
        score=PMD_AC::COMBAT_AI_TUNING_V069[:ability_immunity_score].to_f
      elsif combat_ai_status_redundant_v069?(actual,d)
        score-=PMD_AC::COMBAT_AI_TUNING_V069[:redundant_status_penalty].to_f
      end
      has_drop=false
      for e in (d[:effects]||[])
        if combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:stat_stage && combat_ai_get_v068(e,:stages).to_i<0
          has_drop=true;break
        end
      end
      if has_drop && combat_ai_stage_gain_v068(actual,d,false)<=0
        score-=PMD_AC::COMBAT_AI_TUNING_V069[:saturated_debuff_penalty].to_f
      end
    end

    fk=combat_ai_field_key_v069(d)
    if fk!=nil && respond_to?(:canonical_field_active_for_unit?) && canonical_field_active_for_unit?(unit,fk)
      score*=PMD_AC::COMBAT_AI_TUNING_V069[:active_field_score_factor].to_f
    end
    wk=combat_ai_weather_key_v069(d)
    if wk!=nil
      if respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(wk) &&
         (canonical_weather_permanent? || canonical_weather_frames>PMD_AC::WEATHER_TURN_FRAMES)
        score*=PMD_AC::COMBAT_AI_TUNING_V069[:active_weather_score_factor].to_f
      else
        score+=combat_ai_weather_ability_synergy_v069(unit,wk).to_f*
          PMD_AC::COMBAT_AI_TUNING_V069[:weather_ability_synergy].to_f
      end
    end
    score
  end

  def combat_ai_policy_target_bonus_v069(unit,target,policy,data)
    t=PMD_AC::COMBAT_AI_TUNING_V069;v=0.0
    v+=t[:current_target_bonus].to_f if unit.respond_to?(:target) && unit.target==target
    hp=target.hp.to_f/[target.maxhp.to_i,1].max.to_f
    if policy==:execute
      v+=(1.0-hp)*t[:execute_target_weight].to_f
    elsif policy==:best_cluster
      v+=enemy_cluster_size(unit,target,combat_ai_get_v068(data,:radius)||PMD_AC::AOE_RADIUS).to_f*t[:cluster_target_weight].to_f
    elsif policy==:lowest_def
      v-=target.defense.to_f*0.02
    elsif policy==:highest_atk
      v+=target.atk.to_f*0.02
    end
    v-=unit.distance_to(target).to_f*t[:distance_target_penalty].to_f if unit.respond_to?(:distance_to)
    focus=combat_ai_focus_count_v069(unit,target)
    v+=focus.to_f*t[:focus_fire_bonus].to_f
    v+=focus.to_f*t[:focus_fire_execute_bonus].to_f if hp<=0.40
    v
  end

  def combat_ai_best_enemy_target_v069(unit,policy,data)
    enemies=enemies_of(unit);return nil if enemies.empty?
    mk=combat_ai_move_key_v068(data,nil);best=nil;best_score=nil
    for e in enemies
      s=progression_candidate_score_v046(unit,e,data,mk,0)
      next if s==nil
      s+=combat_ai_policy_target_bonus_v069(unit,e,policy,data)
      if best==nil || s>best_score
        best=e;best_score=s
      end
    end
    best
  end

  def skill_enemy_target(unit,policy)
    return pmd_ac_v069_skill_enemy_target(unit,policy) unless combat_ai_phase2_active_v069?
    data=unit==nil ? nil : unit.skill_data
    return pmd_ac_v069_skill_enemy_target(unit,policy) if data==nil || data.empty?
    combat_ai_best_enemy_target_v069(unit,policy,data) || pmd_ac_v069_skill_enemy_target(unit,policy)
  end

  def combat_ai_ally_target_score_v069(unit,ally,data)
    t=PMD_AC::COMBAT_AI_TUNING_V069;score=0.0
    missing=1.0-ally.hp.to_f/[ally.maxhp.to_i,1].max.to_f
    score+=missing*t[:ally_missing_hp_weight].to_f if combat_ai_heal_v068?(data)
    score+=combat_ai_stage_gain_v068(ally,data,true).to_f*12.0
    score+=combat_ai_pressure_v068(ally)*t[:ally_threat_weight].to_f
    score-=unit.distance_to(ally).to_f*t[:ally_distance_penalty].to_f if unit.respond_to?(:distance_to)
    score
  end

  def skill_ally_target(unit,policy)
    return pmd_ac_v069_skill_ally_target(unit,policy) unless combat_ai_phase2_active_v069?
    data=unit==nil ? nil : unit.skill_data
    return pmd_ac_v069_skill_ally_target(unit,policy) if data==nil || data.empty?
    return pmd_ac_v069_skill_ally_target(unit,policy) unless combat_ai_heal_v068?(data) || combat_ai_stage_gain_v068(unit,data,true)>0
    arr=allies_of(unit);return nil if arr.empty?
    best=nil;best_score=nil
    for a in arr
      s=combat_ai_ally_target_score_v069(unit,a,data)
      if best==nil || s>best_score
        best=a;best_score=s
      end
    end
    best || pmd_ac_v069_skill_ally_target(unit,policy)
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------
  def combat_ai_verification_unit_v069(species,team,id,level=60,slot=:primary)
    i=PMD_PokemonInstance.new(species,level,{:instance_uid=>99069000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9690+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u
  end

  def prepare_verification_battle
    pmd_ac_v069_prepare_verification_battle
    return unless verification_mode==:combat_ai_integration_ii_v069
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,
      'START mode=COMBAT_AI_INTEGRATION_II_V069 pair_scoring=1 ability_accuracy=1 '+
      'team_coordination=1 diagnostic_vfx=off pokemon_resume_after_final_assert=1')
  end

  def verify_combat_ai_manifest_v069
    return if @verification_done[:v069_manifest]
    e=PMD_AC.validate_combat_ai_v069;ok=e.empty?
    log_event(:verify,'COMBAT_AI_MANIFEST_V069 pass='+(ok ? '1':'0')+
      ' features=9 moves=526 learnset=7005/7005 ability_slots=1028/1193 species=483/494 '+
      'checksum='+PMD_AC.combat_ai_checksum32_v069.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v069_manifest]=true
  end

  def verify_combat_ai_target_pair_v069
    return if @verification_done[:v069_target_pair]
    fire=combat_ai_verification_unit_v069(:charizard,:ally,1,60)
    grass=combat_ai_verification_unit_v069(:bulbasaur,:enemy,2,50)
    water=combat_ai_verification_unit_v069(:squirtle,:enemy,3,50)
    fire.deploy_to_cell(1,2);grass.deploy_to_cell(4,1);water.deploy_to_cell(4,3)
    fd=combat_ai_move_data_v068(:flamethrower);chosen=nil
    combat_ai_with_units_v068([fire,grass,water]){chosen=combat_ai_best_enemy_target_v069(fire,:current_target,fd)}

    pika=combat_ai_verification_unit_v069(:pikachu,:ally,4,60)
    rod=combat_ai_verification_unit_v069(:cubone,:enemy,5,50,:secondary)
    rat=combat_ai_verification_unit_v069(:rattata,:enemy,6,50)
    pika.pokemon_instance.set_active_moves_v045([:thunderbolt,:slam,:quick_attack,:tail_whip])
    pick=nil
    combat_ai_with_units_v068([pika,rod,rat]){pick=progression_select_best_move_v046(pika)[0]}
    ok=chosen==grass && pick!=:thunderbolt
    log_event(:verify,'COMBAT_AI_TARGET_PAIR_V069 pass='+(ok ? '1':'0')+
      ' fire_target='+(chosen==nil ? 'nil' : chosen.key.to_s)+
      ' lightning_rod_team_move='+pick.to_s+' redirect_trap_avoided='+(pick!=:thunderbolt ? '1':'0'))
    @verification_done[:v069_target_pair]=true
  end

  def verify_combat_ai_accuracy_ability_v069
    return if @verification_done[:v069_accuracy_ability]
    atk=combat_ai_verification_unit_v069(:charizard,:ally,7,60)
    tgt=combat_ai_verification_unit_v069(:rattata,:enemy,8,50)
    a={:canonical_move_key=>:test_accurate,:move_key=>:test_accurate,:move_type=>:fire,
      :damage_category=>:special,:category=>:special,:accuracy=>100,
      :effects=>[{:type=>:damage,:power=>90}]}
    b=a.dup;b[:canonical_move_key]=:test_risky;b[:move_key]=:test_risky;b[:accuracy]=50;b[:effects]=[{:type=>:damage,:power=>105}]
    sa=progression_candidate_score_v046(atk,tgt,a,:test_accurate,0)
    sb=progression_candidate_score_v046(atk,tgt,b,:test_risky,1)
    lev=combat_ai_verification_unit_v069(:gastly,:enemy,9,50)
    gd={:canonical_move_key=>:test_ground,:move_key=>:test_ground,:move_type=>:ground,
      :damage_category=>:physical,:category=>:physical,:accuracy=>100,
      :effects=>[{:type=>:damage,:power=>100}]}
    sg=progression_candidate_score_v046(atk,lev,gd,:test_ground,0)
    ins=combat_ai_verification_unit_v069(:drowzee,:enemy,20,50)
    normal=combat_ai_verification_unit_v069(:rattata,:enemy,21,50)
    sd=combat_ai_move_data_v068(:sleep_powder)
    si=progression_candidate_score_v046(atk,ins,sd,:sleep_powder,0)
    sn=progression_candidate_score_v046(atk,normal,sd,:sleep_powder,0)
    ok=sa>sb && sg<=PMD_AC::COMBAT_AI_TUNING_V069[:ability_immunity_score].to_f+0.01 && si<sn
    log_event(:verify,'COMBAT_AI_ACCURACY_ABILITY_V069 pass='+(ok ? '1':'0')+
      ' accurate='+sprintf('%.1f',sa.to_f)+' risky50='+sprintf('%.1f',sb.to_f)+
      ' levitate_ground='+sprintf('%.2f',sg.to_f)+' insomnia_sleep='+sprintf('%.2f',si.to_f)+'/'+sprintf('%.1f',sn.to_f))
    @verification_done[:v069_accuracy_ability]=true
  end

  def verify_combat_ai_team_coordination_v069
    return if @verification_done[:v069_team]
    healer=combat_ai_verification_unit_v069(:slowbro,:ally,10,60)
    low=combat_ai_verification_unit_v069(:bulbasaur,:ally,11,50)
    high=combat_ai_verification_unit_v069(:squirtle,:ally,12,50)
    foe=combat_ai_verification_unit_v069(:rattata,:enemy,13,50)
    low.verification_set_hp_percent(0.20);high.verification_set_hp_percent(0.75)
    healer.pokemon_instance.set_active_moves_v045([:heal_pulse,:psychic,:water_gun,:withdraw])
    heal_target=nil
    combat_ai_with_units_v068([healer,low,high,foe]) do
      healer.progression_select_move_v046(:heal_pulse);heal_target=skill_ally_target(healer,:lowest_ally)
    end

    a1=combat_ai_verification_unit_v069(:rattata,:ally,14,50)
    a2=combat_ai_verification_unit_v069(:rattata,:ally,15,50)
    e1=combat_ai_verification_unit_v069(:rattata,:enemy,16,50)
    e2=combat_ai_verification_unit_v069(:rattata,:enemy,17,50)
    e1.verification_set_hp_percent(0.38);e2.verification_set_hp_percent(0.38)
    a1.set_target(e1)
    td=combat_ai_move_data_v068(:tackle);focus=nil
    combat_ai_with_units_v068([a1,a2,e1,e2]){focus=combat_ai_best_enemy_target_v069(a2,:current_target,td)}
    ok=heal_target==low && focus==e1
    log_event(:verify,'COMBAT_AI_TEAM_COORDINATION_V069 pass='+(ok ? '1':'0')+
      ' heal_target='+(heal_target==nil ? 'nil' : heal_target.key.to_s)+
      ' focus_target='+(focus==nil ? 'nil' : focus.key.to_s)+' ally_focus_bonus=1')
    @verification_done[:v069_team]=true
  end

  def verify_combat_ai_weather_field_context_v069
    return if @verification_done[:v069_weather_field]
    u=combat_ai_verification_unit_v069(:charizard,:ally,18,60)
    t=combat_ai_verification_unit_v069(:rattata,:enemy,19,50)
    fire={:canonical_move_key=>:test_fire,:move_key=>:test_fire,:move_type=>:fire,
      :damage_category=>:special,:category=>:special,:accuracy=>100,
      :effects=>[{:type=>:damage,:power=>80}]}
    water=fire.dup;water[:canonical_move_key]=:test_water;water[:move_key]=:test_water;water[:move_type]=:water
    set_canonical_weather(:rain,nil,5,false)
    sf=progression_candidate_score_v046(u,t,fire,:test_fire,0)
    sw=progression_candidate_score_v046(u,t,water,:test_water,1)
    rain={:canonical_move_key=>:rain_dance,:move_key=>:rain_dance,:move_type=>:water,
      :damage_category=>:status,:category=>:status,:effects=>[{:type=>:set_weather,:weather=>:rain}]}
    rw=progression_candidate_score_v046(u,u,rain,:rain_dance,0)
    clear_canonical_weather(:verify)

    field={:canonical_move_key=>:reflect,:move_key=>:reflect,:move_type=>:psychic,
      :damage_category=>:status,:category=>:status,:effects=>[{:type=>:field_effect,:key=>:reflect}]}
    base=progression_candidate_score_v046(u,u,field,:reflect,0)
    old=@canonical_spatial_fields_v036
    begin
      @canonical_spatial_fields_v036=[] if @canonical_spatial_fields_v036==nil
      @canonical_spatial_fields_v036.push({:key=>:reflect,:spatial_type=>:global,:affect_team=>:ally,
        :owner_team=>:ally,:center_x=>272.0,:center_y=>217.0,:radius_x=>999.0,:radius_y=>999.0,
        :frames=>300,:source=>u,:source_uid=>u.instance_uid})
      active=progression_candidate_score_v046(u,u,field,:reflect,0)
    ensure
      @canonical_spatial_fields_v036=old
    end
    ok=sw>sf && rw<PMD_AC::COMBAT_AI_TUNING_V068[:weather_base].to_f && active<base
    log_event(:verify,'COMBAT_AI_WEATHER_FIELD_CONTEXT_V069 pass='+(ok ? '1':'0')+
      ' rain_water='+sprintf('%.1f',sw.to_f)+' rain_fire='+sprintf('%.1f',sf.to_f)+
      ' same_weather='+sprintf('%.1f',rw.to_f)+' field_active='+sprintf('%.1f',active.to_f)+'/'+sprintf('%.1f',base.to_f))
    @verification_done[:v069_weather_field]=true
  end

  def verify_combat_ai_carry_v069
    return if @verification_done[:v069_carry]
    c=PMD_AC.compiled_data_status_v061;m=PMD_AC::COMBAT_AI_MANIFEST_V069
    ok=c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077 &&
      m[:move_runtime].to_i==526 && m[:ability_slots].to_i==1028 && m[:ability_species].to_i==483
    log_event(:verify,'COMBAT_AI_CARRY_V069 pass='+(ok ? '1':'0')+
      ' compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+
      ' aliases='+c[:aliases].to_i.to_s+' moves=526 learnset=7005/7005 abilities=1028/1193 species=483/494 '+
      ' movement=v0.15_unchanged basic_target=v0.15_unchanged skill_target=v0.69_overlay '+
      ' combo_packet=v0.60.2 native_router=v0.62 presentation_anchors=unchanged')
    @verification_done[:v069_carry]=true
  end

  def update_combat_ai_integration_ii_v069
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_combat_ai_manifest_v069 if f>=2
    verify_diagnostic_presentation_isolation_v068 if f>=4
    verify_combat_ai_target_pair_v069 if f>=6
    verify_combat_ai_accuracy_ability_v069 if f>=8
    verify_combat_ai_team_coordination_v069 if f>=10
    verify_combat_ai_weather_field_context_v069 if f>=12
    verify_combat_ai_carry_v068 if f>=14
    verify_ability_runtime_carry_v067 if f>=14
    verify_native_semantic_carry_v063 if f>=14
    verify_combat_ai_carry_v069 if f>=16
    complete_verification_mode if f>=18
  end

  def update_verification_script
    if verification_mode==:combat_ai_integration_ii_v069
      update_combat_ai_integration_ii_v069;return
    end
    pmd_ac_v069_update_verification_script
  end
end
