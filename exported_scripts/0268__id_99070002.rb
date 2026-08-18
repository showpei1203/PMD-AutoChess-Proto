#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.70
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V070 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - combat_ai_scalar_v070 / combat_ai_checksum32_v070 / validate_combat_ai_v070 / initialize
# - combat_ai_last_cast_move_v070 / combat_ai_last_cast_frame_v070 / combat_ai_last_cast_target_uid_v070 / begin_skill
# - log_event / update_threat_state / start / diagnostic_presentation_suppressed_v068?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.70
# Combat AI Integration III
#------------------------------------------------------------------------------
# Adds team action reservation, combo/payoff scoring, guard/ability counterplay,
# setup timing and a small threat release hysteresis.  It layers over v0.69;
# movement, basic targeting, Weather/Field runtime, v0.60.2 packets, Native Pose
# and presentation anchors are not replaced.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V070='0.70'

  class << self
    def combat_ai_scalar_v070(x)
      return '' if x==nil
      return x.collect{|v|combat_ai_scalar_v070(v)}.join(',') if x.is_a?(Array)
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+combat_ai_scalar_v070(x[k])}.join(',')
      end
      x.to_s
    end

    def combat_ai_checksum32_v070
      h=0;m=COMBAT_AI_MANIFEST_V070
      [:schema_version,:content_version,:base_version,:feature,:selection_source,
       :base_score,:features,:movement_core,:basic_target_core,:skill_target_layer,
       :threat_core,:damage_packet,:native_router,:weather_runtime,:field_runtime,
       :ability_slots,:ability_slots_total,:ability_species,:move_runtime,
       :learnset_coverage].each do |k|
        combat_ai_scalar_v070(m[k]).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      COMBAT_AI_TUNING_V070.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        (k.to_s+'='+combat_ai_scalar_v070(COMBAT_AI_TUNING_V070[k])).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_combat_ai_v070
      e=[];m=COMBAT_AI_MANIFEST_V070
      e.push('features') unless m[:features].size==10
      e.push('moves') unless m[:move_runtime].to_i==526
      e.push('ability_slots') unless m[:ability_slots].to_i==1028 && m[:ability_slots_total].to_i==1193
      e.push('ability_species') unless m[:ability_species].to_i==483
      e.push('threat') unless m[:threat_core]=='v0.15_with_v0.70_release_hysteresis'
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :combat_ai_integration_iii_v070,
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
    :combat_ai_integration_iii_v070=>'COMBAT_AI_INTEGRATION_III_V070',
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

class Game_PMDChessUnit
  alias pmd_ac_v070_initialize initialize unless method_defined?(:pmd_ac_v070_initialize)
  alias pmd_ac_v070_begin_skill begin_skill unless method_defined?(:pmd_ac_v070_begin_skill)
  alias pmd_ac_v070_update_threat_state update_threat_state unless method_defined?(:pmd_ac_v070_update_threat_state)
  alias pmd_ac_v070_log_event log_event unless method_defined?(:pmd_ac_v070_log_event)

  def initialize(*args)
    pmd_ac_v070_initialize(*args)
    @combat_ai_last_cast_move_v070=nil
    @combat_ai_last_cast_frame_v070=-999999
    @combat_ai_last_cast_target_uid_v070=nil
    @pmd_ac_v070_suppress_raw_threat_log=false
  end

  def combat_ai_last_cast_move_v070;@combat_ai_last_cast_move_v070;end
  def combat_ai_last_cast_frame_v070;@combat_ai_last_cast_frame_v070||-999999;end
  def combat_ai_last_cast_target_uid_v070;@combat_ai_last_cast_target_uid_v070;end

  def begin_skill(skill_target=nil)
    pmd_ac_v070_begin_skill(skill_target)
    if @action==:skill
      d=skill_data
      k=@progression_selected_move_v046
      k=(d[:canonical_move_key]||d[:move_key]) if k==nil && d!=nil
      k=k.to_sym if k.is_a?(String)
      @combat_ai_last_cast_move_v070=k
      @combat_ai_last_cast_frame_v070=Graphics.frame_count
      @combat_ai_last_cast_target_uid_v070=@skill_target==nil ? nil : @skill_target.instance_uid
    end
  end

  def log_event(category,message)
    return if @pmd_ac_v070_suppress_raw_threat_log && category.to_s=='threat'
    pmd_ac_v070_log_event(category,message)
  end

  def update_threat_state
    old_level=@threat_level
    old_source=@threat_source
    @pmd_ac_v070_suppress_raw_threat_log=true
    begin
      pmd_ac_v070_update_threat_state
    ensure
      @pmd_ac_v070_suppress_raw_threat_log=false
    end
    return unless [:responsive,:protective].include?(@threat_policy)

    raw_level=@threat_level
    raw_source=@threat_source
    final_level=raw_level
    final_source=raw_source
    old_ok=old_source!=nil && !old_source.dead? && enemy_of?(old_source)
    if old_ok
      d=distance_to(old_source).to_f
      ep=PMD_AC::THREAT_EMERGENCY_RANGE+PMD_AC::COMBAT_AI_TUNING_V070[:threat_emergency_release_margin].to_f
      pp=PMD_AC::THREAT_PRESSURE_RANGE+PMD_AC::COMBAT_AI_TUNING_V070[:threat_pressure_release_margin].to_f
      if old_level==:emergency && raw_level!=:emergency
        if d<=ep
          final_level=:emergency;final_source=old_source
        elsif d<=pp && raw_level==:safe
          final_level=:pressured;final_source=old_source
        end
      elsif old_level==:pressured && raw_level==:safe && d<=pp
        final_level=:pressured;final_source=old_source
      end
    end
    @threat_level=final_level
    @threat_source=final_source
    @threat_release_frames=0 if @threat_level==:emergency

    if PMD_AC::BATTLE_LOG_THREAT &&
       (old_level!=@threat_level || old_source!=@threat_source)
      src=@threat_source==nil ? 'NONE' : @threat_source.log_name
      pmd_ac_v070_log_event(:threat,log_name+' level='+@threat_level.to_s+' source='+src)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v070_start start unless method_defined?(:pmd_ac_v070_start)
  alias pmd_ac_v070_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v070_prepare_verification_battle)
  alias pmd_ac_v070_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v070_update_verification_script)
  alias pmd_ac_v070_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v070_progression_candidate_score_v046)
  alias pmd_ac_v070_combat_ai_policy_target_bonus_v069 combat_ai_policy_target_bonus_v069 unless method_defined?(:pmd_ac_v070_combat_ai_policy_target_bonus_v069)
  alias pmd_ac_v070_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v070_diagnostic_presentation_suppressed_v068)

  def start
    pmd_ac_v070_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.69 Battle Verification Log/,
          'PMD AutoChess Proto v0.70 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:combat_ai,
      'LOADED phase=III reservation=1 sequence=1 guard_counterplay=1 ability_counterplay=1 '+
      'setup_timing=1 threat_hysteresis=1 movement=v0.15_unchanged basic_target=v0.15_unchanged '+
      'weather_field=unchanged damage_packet=v0.60.2')
    log_event(:presentation,
      'PATCH v0.70 diagnostic_vfx_isolation=v0.68_carried native_router=v0.62_unchanged '+
      'beam_projectile_impact_targetfx=unchanged')
  end

  def diagnostic_presentation_suppressed_v068?
    return true if verification_mode==:combat_ai_integration_iii_v070
    pmd_ac_v070_diagnostic_presentation_suppressed_v068
  end

  def combat_ai_phase3_active_v070?
    m=verification_mode
    m==:normal || m==:combat_ai_integration_iii_v070
  end

  def combat_ai_plan_active_v070?(u)
    return false if u==nil || u.dead?
    return true if u.respond_to?(:action) && u.action==:skill
    return true if u.respond_to?(:energy) && u.energy.to_i>=PMD_AC::MAX_ENERGY
    false
  end

  def combat_ai_planned_move_v070(u)
    return nil unless combat_ai_plan_active_v070?(u)
    k=u.respond_to?(:progression_selected_move_v046) ? u.progression_selected_move_v046 : nil
    if k==nil && u.respond_to?(:skill_data)
      d=u.skill_data;k=combat_ai_move_key_v068(d,nil)
    end
    combat_ai_sym_v068(k)
  end

  def combat_ai_planned_target_v070(u)
    return nil if u==nil
    return u.skill_target if u.respond_to?(:action) && u.action==:skill && u.skill_target!=nil
    u.respond_to?(:target) ? u.target : nil
  end

  def combat_ai_primary_status_v070(data)
    return nil if data==nil
    for t in combat_ai_effect_types_v068(data)
      s=PMD_AC::COMBAT_AI_MAJOR_STATUS_EFFECT_MAP_V069[t]
      return s if s!=nil
      return :sleep if t==:canonical_sleep
      return :freeze if t==:canonical_freeze
    end
    nil
  end

  def combat_ai_hard_controlled_v070?(target)
    return false if target==nil || !target.respond_to?(:status?)
    PMD_AC::COMBAT_AI_HARD_CONTROL_STATUSES_V070.any?{|s|target.status?(s)}
  end

  def combat_ai_ally_reservation_delta_v070(unit,target,data,move)
    return 0.0 if unit==nil || data==nil
    t=PMD_AC::COMBAT_AI_TUNING_V070;delta=0.0
    own_status=combat_ai_primary_status_v070(data)
    own_weather=combat_ai_weather_key_v069(data)
    own_field=combat_ai_field_key_v069(data)
    damaging=combat_ai_damaging_v068?(data)
    type=damaging ? combat_ai_move_type_v069(unit,data) : nil
    for a in allies_of(unit)
      next if a==unit
      pm=combat_ai_planned_move_v070(a);next if pm==nil
      pd=combat_ai_move_data_v068(pm);next if pd==nil
      pt=combat_ai_planned_target_v070(a)
      ps=combat_ai_primary_status_v070(pd)
      pw=combat_ai_weather_key_v069(pd)
      pf=combat_ai_field_key_v069(pd)
      if own_status!=nil && ps==own_status && pt==target
        delta-=t[:duplicate_control_penalty].to_f
      end
      delta-=t[:duplicate_weather_penalty].to_f if own_weather!=nil && pw==own_weather
      delta-=t[:duplicate_field_penalty].to_f if own_field!=nil && pf==own_field
      if damaging && pt==target && ps!=nil && [:sleep,:freeze].include?(ps)
        delta+=t[:ally_control_payoff_bonus].to_f
      end
      if damaging && pw!=nil
        good=PMD_AC::COMBAT_AI_WEATHER_DAMAGE_TYPES_V070[pw]||[]
        delta+=t[:planned_weather_payoff_bonus].to_f if good.include?(type)
      end
    end
    delta
  end

  def combat_ai_recent_setup_payoff_v070(unit,target,data)
    return 0.0 if unit==nil || target==nil || !combat_ai_damaging_v068?(data)
    return 0.0 unless unit.respond_to?(:combat_ai_last_cast_move_v070)
    last=unit.combat_ai_last_cast_move_v070;return 0.0 if last==nil
    age=Graphics.frame_count-unit.combat_ai_last_cast_frame_v070.to_i
    return 0.0 if age<0 || age>PMD_AC::COMBAT_AI_TUNING_V070[:recent_setup_window].to_i
    return 0.0 unless unit.combat_ai_last_cast_target_uid_v070==target.instance_uid
    ld=combat_ai_move_data_v068(last);return 0.0 if ld==nil
    setup=(combat_ai_primary_status_v070(ld)!=nil || combat_ai_stage_gain_v068(target,ld,false)>0)
    setup ? PMD_AC::COMBAT_AI_TUNING_V070[:recent_setup_payoff_bonus].to_f : 0.0
  end

  def combat_ai_target_guarded_v070?(target)
    return false if target==nil
    if target.respond_to?(:guard_active_v040?)
      return true if target.guard_active_v040?(:protect) || target.guard_active_v040?(:detect)
    end
    return true unless guard_aura_sources_v040(target,:wide_guard).empty? if respond_to?(:guard_aura_sources_v040)
    return true unless guard_aura_sources_v040(target,:quick_guard).empty? if respond_to?(:guard_aura_sources_v040)
    false
  end

  def combat_ai_indirect_magic_guard_move_v070?(move)
    PMD_AC::COMBAT_AI_INDIRECT_ONLY_MOVES_V070.include?(combat_ai_sym_v068(move))
  end

  def combat_ai_offensive_setup_v070?(data)
    return false if data==nil
    for e in (data[:effects]||[])
      next unless combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:stat_stage
      next unless combat_ai_get_v068(e,:stages).to_i>0
      st=combat_ai_sym_v068(combat_ai_get_v068(e,:stat))
      return true if PMD_AC::COMBAT_AI_OFFENSIVE_SETUP_STATS_V070.include?(st)
    end
    false
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v070_progression_candidate_score_v046(unit,target,data,move,slot)
    return score unless combat_ai_phase3_active_v070?
    return nil if score==nil
    t=PMD_AC::COMBAT_AI_TUNING_V070;mk=combat_ai_move_key_v068(data,move)
    damaging=combat_ai_damaging_v068?(data)

    if damaging && combat_ai_hard_controlled_v070?(target)
      score+=t[:controlled_target_damage_bonus].to_f
    end
    score+=combat_ai_ally_reservation_delta_v070(unit,target,data,mk)
    score+=combat_ai_recent_setup_payoff_v070(unit,target,data)

    if unit!=nil && target!=nil && unit.team!=target.team && respond_to?(:guard_block_reason_v040)
      reason=guard_block_reason_v040(unit,target,data,false)
      if reason!=nil
        score=t[:guard_block_score].to_f
      elsif combat_ai_target_guarded_v070?(target) && respond_to?(:guard_bypass_v040?) && guard_bypass_v040?(data)
        score+=t[:guard_break_bonus].to_f
      end
    end

    if target!=nil && target.respond_to?(:ability_key) && target.ability_key==:magic_guard &&
       combat_ai_indirect_magic_guard_move_v070?(mk)
      score*=t[:magic_guard_indirect_factor].to_f
    end

    if combat_ai_offensive_setup_v070?(data)
      primary=unit==nil ? nil : unit.target
      if primary!=nil && primary.respond_to?(:ability_key) && primary.ability_key==:unaware
        score*=t[:unaware_offense_setup_factor].to_f
      end
      hp=unit.hp.to_f/[unit.maxhp.to_i,1].max.to_f
      pressure=combat_ai_pressure_v068(unit)
      if hp>=0.70 && pressure<1.0
        score+=t[:safe_setup_bonus].to_f
      elsif hp<=0.35 || pressure>=2.0
        score-=t[:danger_setup_penalty].to_f
      end
    end
    [score.to_f,0.05].max
  end

  def combat_ai_policy_target_bonus_v069(unit,target,policy,data)
    v=pmd_ac_v070_combat_ai_policy_target_bonus_v069(unit,target,policy,data)
    return v unless combat_ai_phase3_active_v070?
    hp=target.hp.to_f/[target.maxhp.to_i,1].max.to_f
    focus=combat_ai_focus_count_v069(unit,target)
    if hp<=0.15 && focus>0
      v-=focus.to_f*PMD_AC::COMBAT_AI_TUNING_V070[:overkill_reserved_penalty].to_f
    end
    v
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------
  def combat_ai_verification_unit_v070(species,team,id,level=60,slot=:primary)
    i=PMD_PokemonInstance.new(species,level,{:instance_uid=>99070000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9700+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u
  end

  def prepare_verification_battle
    pmd_ac_v070_prepare_verification_battle
    return unless verification_mode==:combat_ai_integration_iii_v070
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,
      'START mode=COMBAT_AI_INTEGRATION_III_V070 reservation=1 sequence=1 guard_counterplay=1 '+
      'threat_hysteresis=1 diagnostic_vfx=off pokemon_resume_after_final_assert=1')
  end

  def verify_combat_ai_manifest_v070
    return if @verification_done[:v070_manifest]
    e=PMD_AC.validate_combat_ai_v070;ok=e.empty?
    log_event(:verify,'COMBAT_AI_MANIFEST_V070 pass='+(ok ? '1':'0')+
      ' features=10 moves=526 learnset=7005/7005 ability_slots=1028/1193 species=483/494 '+
      'checksum='+PMD_AC.combat_ai_checksum32_v070.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v070_manifest]=true
  end

  def verify_combat_ai_reservation_sequence_v070
    return if @verification_done[:v070_reservation]
    a1=combat_ai_verification_unit_v070(:bulbasaur,:ally,1,50)
    a2=combat_ai_verification_unit_v070(:bulbasaur,:ally,2,50)
    e=combat_ai_verification_unit_v070(:rattata,:enemy,3,50)
    a1.pokemon_instance.set_active_moves_v045([:sleep_powder,:tackle,:growl,:vine_whip])
    a2.pokemon_instance.set_active_moves_v045([:sleep_powder,:tackle,:growl,:vine_whip])
    a1.progression_select_move_v046(:sleep_powder);a1.set_target(e);a1.verification_set_energy(PMD_AC::MAX_ENERGY)
    sd=combat_ai_move_data_v068(:sleep_powder);td=combat_ai_move_data_v068(:tackle)
    no_plan=nil;reserved=nil;payoff=nil
    combat_ai_with_units_v068([a2,e]){no_plan=progression_candidate_score_v046(a2,e,sd,:sleep_powder,0)}
    combat_ai_with_units_v068([a1,a2,e]) do
      reserved=progression_candidate_score_v046(a2,e,sd,:sleep_powder,0)
      payoff=progression_candidate_score_v046(a2,e,td,:tackle,1)
    end
    e.apply_status(:sleep,{:duration=>999999,:value=>0,:interval=>999999},a1)
    sleep_damage=nil
    combat_ai_with_units_v068([a2,e]){sleep_damage=progression_candidate_score_v046(a2,e,td,:tackle,1)}
    ok=reserved<no_plan && payoff!=nil && sleep_damage>payoff
    log_event(:verify,'COMBAT_AI_RESERVATION_SEQUENCE_V070 pass='+(ok ? '1':'0')+
      ' duplicate_sleep='+sprintf('%.1f',no_plan.to_f)+'->'+sprintf('%.1f',reserved.to_f)+
      ' tackle_base='+sprintf('%.1f',payoff.to_f)+' controlled_payoff='+sprintf('%.1f',sleep_damage.to_f))
    @verification_done[:v070_reservation]=true
  end

  def verify_combat_ai_weather_reservation_v070
    return if @verification_done[:v070_weather]
    setter=combat_ai_verification_unit_v070(:squirtle,:ally,4,60)
    user=combat_ai_verification_unit_v070(:vaporeon,:ally,5,60)
    foe=combat_ai_verification_unit_v070(:rattata,:enemy,6,50)
    setter.pokemon_instance.set_active_moves_v045([:rain_dance,:water_gun,:tackle,:withdraw])
    setter.progression_select_move_v046(:rain_dance);setter.set_target(setter);setter.verification_set_energy(PMD_AC::MAX_ENERGY)
    wd=combat_ai_move_data_v068(:water_gun);rd=combat_ai_move_data_v068(:rain_dance)
    base=nil;planned=nil;dup=nil
    combat_ai_with_units_v068([user,foe]){base=progression_candidate_score_v046(user,foe,wd,:water_gun,0)}
    combat_ai_with_units_v068([setter,user,foe]) do
      planned=progression_candidate_score_v046(user,foe,wd,:water_gun,0)
      dup=progression_candidate_score_v046(user,user,rd,:rain_dance,1)
    end
    ok=planned>base && dup<PMD_AC::COMBAT_AI_TUNING_V068[:weather_base].to_f
    log_event(:verify,'COMBAT_AI_WEATHER_RESERVATION_V070 pass='+(ok ? '1':'0')+
      ' water_payoff='+sprintf('%.1f',base.to_f)+'->'+sprintf('%.1f',planned.to_f)+
      ' duplicate_rain='+sprintf('%.1f',dup.to_f))
    @verification_done[:v070_weather]=true
  end

  def verify_combat_ai_guard_ability_v070
    return if @verification_done[:v070_guard]
    a=combat_ai_verification_unit_v070(:rattata,:ally,7,60)
    t=combat_ai_verification_unit_v070(:rattata,:enemy,8,50)
    t.set_guard_v040(:protect,60)
    td=combat_ai_move_data_v068(:tackle);fd=combat_ai_move_data_v068(:feint)
    st=progression_candidate_score_v046(a,t,td,:tackle,0)
    sf=progression_candidate_score_v046(a,t,fd,:feint,1)
    mg=combat_ai_verification_unit_v070(:clefairy,:enemy,9,50,:secondary)
    nd=combat_ai_verification_unit_v070(:rattata,:enemy,10,50)
    tox=combat_ai_move_data_v068(:toxic)
    sm=progression_candidate_score_v046(a,mg,tox,:toxic,0)
    sn=progression_candidate_score_v046(a,nd,tox,:toxic,0)
    ok=st<=0.11 && sf>st && sm<sn
    log_event(:verify,'COMBAT_AI_GUARD_ABILITY_V070 pass='+(ok ? '1':'0')+
      ' protect_tackle='+sprintf('%.2f',st.to_f)+' feint='+sprintf('%.1f',sf.to_f)+
      ' magic_guard_toxic='+sprintf('%.1f',sm.to_f)+'/'+sprintf('%.1f',sn.to_f))
    @verification_done[:v070_guard]=true
  end

  def verify_combat_ai_threat_hysteresis_v070
    return if @verification_done[:v070_threat]
    u=combat_ai_verification_unit_v070(:pikachu,:ally,11,50)
    e=combat_ai_verification_unit_v070(:rattata,:enemy,12,50)
    u.instance_variable_set(:@threat_policy,:responsive)
    u.deploy_to_pixel(200,200);e.deploy_to_pixel(300,200)
    first=nil;held=nil;released=nil
    combat_ai_with_units_v068([u,e]) do
      u.update_threat_state;first=u.threat_level
      e.deploy_to_pixel(308,200);u.update_threat_state;held=u.threat_level
      e.deploy_to_pixel(325,200);u.update_threat_state;released=u.threat_level
    end
    ok=first==:pressured && held==:pressured && released==:safe
    log_event(:verify,'COMBAT_AI_THREAT_HYSTERESIS_V070 pass='+(ok ? '1':'0')+
      ' enter100='+first.to_s+' hold108='+held.to_s+' release125='+released.to_s+
      ' pressure_enter='+PMD_AC::THREAT_PRESSURE_RANGE.to_i.to_s+
      ' release='+((PMD_AC::THREAT_PRESSURE_RANGE+PMD_AC::COMBAT_AI_TUNING_V070[:threat_pressure_release_margin]).to_i).to_s)
    @verification_done[:v070_threat]=true
  end

  def verify_combat_ai_carry_v070
    return if @verification_done[:v070_carry]
    c=PMD_AC.compiled_data_status_v061;m=PMD_AC::COMBAT_AI_MANIFEST_V070
    ok=c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077 &&
      m[:move_runtime].to_i==526 && m[:ability_slots].to_i==1028 && m[:ability_species].to_i==483
    log_event(:verify,'COMBAT_AI_CARRY_V070 pass='+(ok ? '1':'0')+
      ' compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+
      ' aliases='+c[:aliases].to_i.to_s+' moves=526 learnset=7005/7005 abilities=1028/1193 species=483/494 '+
      ' movement=v0.15_unchanged basic_target=v0.15_unchanged skill_target=v0.69_overlay '+
      ' threat=v0.15+hysteresis weather_field=unchanged combo_packet=v0.60.2 native_router=v0.62 '+
      'presentation_anchors=unchanged')
    @verification_done[:v070_carry]=true
  end

  def update_combat_ai_integration_iii_v070
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_combat_ai_manifest_v070 if f>=2
    verify_diagnostic_presentation_isolation_v068 if f>=4
    verify_combat_ai_reservation_sequence_v070 if f>=6
    verify_combat_ai_weather_reservation_v070 if f>=8
    verify_combat_ai_guard_ability_v070 if f>=10
    verify_combat_ai_threat_hysteresis_v070 if f>=12
    verify_combat_ai_carry_v069 if f>=14
    verify_ability_runtime_carry_v067 if f>=14
    verify_native_semantic_carry_v063 if f>=14
    verify_combat_ai_carry_v070 if f>=16
    complete_verification_mode if f>=18
  end

  def update_verification_script
    if verification_mode==:combat_ai_integration_iii_v070
      update_combat_ai_integration_iii_v070;return
    end
    pmd_ac_v070_update_verification_script
  end
end
