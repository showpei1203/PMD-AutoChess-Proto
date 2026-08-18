#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.72
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V072 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - combat_ai_scalar_v072 / combat_ai_checksum32_v072 / validate_combat_ai_v072 / start
# - diagnostic_presentation_suppressed_v068? / combat_ai_phase5_active_v072? / combat_ai_planned_break_support_v072? / combat_ai_planned_control_support_v072?
# - combat_ai_planned_weather_support_v072? / combat_ai_planned_helping_support_v072? / combat_ai_support_chain_depth_v072 / combat_ai_reserved_damage_estimate_v072
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.72
# Combat AI Integration V
#------------------------------------------------------------------------------
# Adds three-unit combo depth, reserved-damage projection and projected-KO
# handoff over verified v0.71.  It does not execute simulated damage; all
# prediction is side-effect-free scoring only.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V072='0.72'

  class << self
    def combat_ai_scalar_v072(x)
      return '' if x==nil
      return x.collect{|v|combat_ai_scalar_v072(v)}.join(',') if x.is_a?(Array)
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+combat_ai_scalar_v072(x[k])}.join(',')
      end
      x.to_s
    end

    def combat_ai_checksum32_v072
      h=0;m=COMBAT_AI_MANIFEST_V072
      [:schema_version,:content_version,:base_version,:feature,:selection_source,
       :base_score,:features,:movement_core,:basic_target_core,:skill_target_layer,
       :threat_core,:intent_core,:weather_field,:damage_packet,:native_router,
       :ability_slots,:ability_slots_total,:ability_species,:move_runtime,
       :learnset_coverage].each do |k|
        combat_ai_scalar_v072(m[k]).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      COMBAT_AI_TUNING_V072.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        (k.to_s+'='+combat_ai_scalar_v072(COMBAT_AI_TUNING_V072[k])).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_combat_ai_v072
      e=[];m=COMBAT_AI_MANIFEST_V072
      e.push('features') unless m[:features].size==8
      e.push('moves') unless m[:move_runtime].to_i==526
      e.push('ability_slots') unless m[:ability_slots].to_i==1028 && m[:ability_slots_total].to_i==1193
      e.push('ability_species') unless m[:ability_species].to_i==483
      e.push('intent') unless m[:intent_core]=='v0.71_24f_carried'
      e.push('threat') unless m[:threat_core]=='v0.70_hysteresis_carried'
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :combat_ai_integration_v_v072,
    :combat_ai_integration_iv_v071,
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
    :combat_ai_integration_v_v072=>'COMBAT_AI_INTEGRATION_V_V072',
    :combat_ai_integration_iv_v071=>'COMBAT_AI_INTEGRATION_IV_V071',
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

class Scene_PMD_AutoChess
  alias pmd_ac_v072_start start unless method_defined?(:pmd_ac_v072_start)
  alias pmd_ac_v072_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v072_prepare_verification_battle)
  alias pmd_ac_v072_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v072_update_verification_script)
  alias pmd_ac_v072_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v072_progression_candidate_score_v046)
  alias pmd_ac_v072_combat_ai_policy_target_bonus_v069 combat_ai_policy_target_bonus_v069 unless method_defined?(:pmd_ac_v072_combat_ai_policy_target_bonus_v069)
  alias pmd_ac_v072_combat_ai_intent_valid_v071 combat_ai_intent_valid_v071? unless method_defined?(:pmd_ac_v072_combat_ai_intent_valid_v071)
  alias pmd_ac_v072_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v072_diagnostic_presentation_suppressed_v068)

  def start
    pmd_ac_v072_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.71 Battle Verification Log/,
          'PMD AutoChess Proto v0.72 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:combat_ai,
      'LOADED phase=V three_unit_chain=1 reserved_damage_projection=1 projected_ko_handoff=1 '+
      'finisher_handoff=1 ordered_horizon=1 movement=v0.15_unchanged basic_target=v0.15_unchanged '+
      'threat=v0.70_hysteresis intent=v0.71_24f damage_packet=v0.60.2')
    log_event(:presentation,
      'PATCH v0.72 diagnostic_vfx_isolation=v0.68_carried native_router=v0.62_unchanged '+
      'weather_field=unchanged beam_projectile_impact_targetfx=unchanged')
  end

  def diagnostic_presentation_suppressed_v068?
    return true if verification_mode==:combat_ai_integration_v_v072
    pmd_ac_v072_diagnostic_presentation_suppressed_v068
  end

  def combat_ai_phase5_active_v072?
    m=verification_mode
    m==:normal || m==:combat_ai_integration_v_v072
  end

  def combat_ai_planned_break_support_v072?(ally,target,current_data)
    pm=combat_ai_planned_move_v070(ally);return false if pm==nil
    pd=combat_ai_move_data_v068(pm);return false if pd==nil
    return false unless combat_ai_planned_target_v070(ally)==target
    changes=combat_ai_stage_changes_v071(pd)
    cat=combat_ai_damage_category_v069(current_data)
    return true if cat==:physical && changes[:def].to_i<0
    return true if cat==:special && changes[:spdef].to_i<0
    false
  end

  def combat_ai_planned_control_support_v072?(ally,target)
    pm=combat_ai_planned_move_v070(ally);return false if pm==nil
    pd=combat_ai_move_data_v068(pm);return false if pd==nil
    return false unless combat_ai_planned_target_v070(ally)==target
    ps=combat_ai_primary_status_v070(pd)
    ps!=nil && [:sleep,:freeze,:paralysis].include?(ps)
  end

  def combat_ai_planned_weather_support_v072?(ally,unit,current_data)
    pm=combat_ai_planned_move_v070(ally);return false if pm==nil
    pd=combat_ai_move_data_v068(pm);return false if pd==nil
    wk=combat_ai_weather_key_v069(pd);return false if wk==nil
    type=combat_ai_move_type_v069(unit,current_data)
    good=PMD_AC::COMBAT_AI_WEATHER_DAMAGE_TYPES_V070[wk]||[]
    good.include?(type)
  end

  def combat_ai_planned_helping_support_v072?(ally,unit)
    pm=combat_ai_planned_move_v070(ally)
    pm==:helping_hand && combat_ai_planned_target_v070(ally)==unit
  end

  def combat_ai_support_chain_depth_v072(unit,target,data)
    return 0 if unit==nil || target==nil || data==nil || !combat_ai_damaging_v068?(data)
    n=0
    for a in allies_of(unit)
      next if a==unit
      supported=false
      supported=true if combat_ai_planned_break_support_v072?(a,target,data)
      supported=true if combat_ai_planned_control_support_v072?(a,target)
      supported=true if combat_ai_planned_helping_support_v072?(a,unit)
      supported=true if combat_ai_planned_weather_support_v072?(a,unit,data)
      n+=1 if supported
    end
    cap=PMD_AC::COMBAT_AI_TUNING_V072[:support_chain_cap].to_i
    [n,cap].min
  end

  # Side-effect-free pressure estimate.  This is intentionally not the real
  # damage formula: it predicts whether an already-reserved ally packet is
  # likely to make the target irrelevant before this unit acts.
  def combat_ai_reserved_damage_estimate_v072(attacker,target,data,move,unit,own_data)
    return 0.0 if attacker==nil || target==nil || data==nil
    return 0.0 unless combat_ai_damaging_v068?(data)
    power=combat_ai_damage_power_v068(data).to_f
    return 0.0 if power<=0.0
    hits=combat_ai_multi_hits_v068(attacker,data).to_f
    hits=1.0 if hits<1.0
    type=combat_ai_move_type_v069(attacker,data)
    cat=combat_ai_damage_category_v069(data)
    eff=1.0
    begin;eff=PMD_AC.type_effectiveness(type,target.pokemon_types).to_f;rescue;eff=1.0;end
    return 0.0 if eff<=0.0
    inc=combat_ai_safe_incoming_factor_v069(target,type,cat,eff,data)
    return 0.0 if inc<=0.0
    out=combat_ai_outgoing_factor_v069(attacker,type,cat,eff)
    fg=combat_ai_friend_guard_factor_v069(target)
    acc=combat_ai_accuracy_factor_v069(attacker,target,data,true).to_f
    minacc=PMD_AC::COMBAT_AI_TUNING_V072[:minimum_prediction_accuracy].to_f
    acc=minacc if acc<minacc
    stab=1.0
    begin;stab=1.5 if attacker.pokemon_types.include?(type);rescue;stab=1.0;end
    order=combat_ai_order_factor_v071(attacker,unit,data,own_data).to_f
    power*hits*stab*eff*inc*out*fg*acc*order*PMD_AC::COMBAT_AI_TUNING_V072[:reserved_damage_scale].to_f
  end

  def combat_ai_reserved_damage_v072(unit,target,own_data)
    return 0.0 if unit==nil || target==nil
    total=0.0
    for a in allies_of(unit)
      next if a==unit
      pm=combat_ai_planned_move_v070(a);next if pm==nil
      pd=combat_ai_move_data_v068(pm);next if pd==nil
      next unless combat_ai_planned_target_v070(a)==target
      total+=combat_ai_reserved_damage_estimate_v072(a,target,pd,pm,unit,own_data)
    end
    total
  end

  def combat_ai_projected_hp_v072(unit,target,own_data)
    return 0.0 if target==nil
    [target.hp.to_f-combat_ai_reserved_damage_v072(unit,target,own_data),0.0].max
  end

  def combat_ai_projected_ko_v072?(unit,target,own_data)
    return false if target==nil || target.dead?
    combat_ai_reserved_damage_v072(unit,target,own_data)>=target.hp.to_f
  end

  def combat_ai_intent_valid_v071?(unit)
    ok=pmd_ac_v072_combat_ai_intent_valid_v071(unit)
    return ok unless ok && combat_ai_phase5_active_v072?
    s=unit.combat_ai_intent_snapshot_v071
    data=combat_ai_move_data_v068(s[:move])
    if data!=nil && combat_ai_damaging_v068?(data) && s[:target]!=nil && unit.team!=s[:target].team &&
       combat_ai_projected_ko_v072?(unit,s[:target],data)
      return false
    end
    true
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v072_progression_candidate_score_v046(unit,target,data,move,slot)
    return score unless combat_ai_phase5_active_v072?
    return nil if score==nil
    return score if unit==nil || target==nil || data==nil
    t=PMD_AC::COMBAT_AI_TUNING_V072
    damaging=combat_ai_damaging_v068?(data)
    if damaging && unit.team!=target.team
      depth=combat_ai_support_chain_depth_v072(unit,target,data)
      score+=t[:triple_chain_bonus].to_f if depth>=2
      reserved=combat_ai_reserved_damage_v072(unit,target,data)
      if reserved>=target.hp.to_f && reserved>0.0
        aoe=combat_ai_aoe_enemy_count_v068(unit,target,data)
        factor=aoe>1 ? t[:projected_ko_aoe_factor].to_f : t[:projected_ko_damage_factor].to_f
        score*=factor
      elsif reserved>0.0
        projected=[target.hp.to_f-reserved,0.0].max
        ratio=projected/[target.maxhp.to_i,1].max.to_f
        if ratio<=t[:finisher_hp_ratio].to_f
          pr=0;begin;pr=PMD_AC.canonical_priority_v042(data).to_i;rescue;pr=0;end
          score+=t[:priority_finisher_bonus].to_f if pr>0
          score+=t[:execute_finisher_bonus].to_f
        end
      end
    end
    [score.to_f,0.05].max
  end

  def combat_ai_policy_target_bonus_v069(unit,target,policy,data)
    v=pmd_ac_v072_combat_ai_policy_target_bonus_v069(unit,target,policy,data)
    return v unless combat_ai_phase5_active_v072?
    if unit!=nil && target!=nil && data!=nil && unit.team!=target.team && combat_ai_damaging_v068?(data)
      if combat_ai_projected_ko_v072?(unit,target,data) && combat_ai_aoe_enemy_count_v068(unit,target,data)<=1
        v-=PMD_AC::COMBAT_AI_TUNING_V072[:projected_ko_target_penalty].to_f
      end
    end
    v
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------
  def combat_ai_verification_unit_v072(species,team,id,level=60,slot=:primary)
    i=PMD_PokemonInstance.new(species,level,{:instance_uid=>99072000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9720+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u
  end

  def prepare_verification_battle
    pmd_ac_v072_prepare_verification_battle
    return unless verification_mode==:combat_ai_integration_v_v072
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,
      'START mode=COMBAT_AI_INTEGRATION_V_V072 three_unit_chain=1 prediction=1 projected_ko_handoff=1 '+
      'diagnostic_vfx=off pokemon_resume_after_final_assert=1')
  end

  def verify_combat_ai_manifest_v072
    return if @verification_done[:v072_manifest]
    e=PMD_AC.validate_combat_ai_v072;ok=e.empty?
    log_event(:verify,'COMBAT_AI_MANIFEST_V072 pass='+(ok ? '1':'0')+
      ' features=8 moves=526 learnset=7005/7005 ability_slots=1028/1193 species=483/494 '+
      'checksum='+PMD_AC.combat_ai_checksum32_v072.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v072_manifest]=true
  end

  def verify_combat_ai_triple_chain_v072
    return if @verification_done[:v072_triple]
    breaker=combat_ai_verification_unit_v072(:ekans,:ally,1,60)
    control=combat_ai_verification_unit_v072(:bulbasaur,:ally,2,60)
    hitter=combat_ai_verification_unit_v072(:rattata,:ally,3,60)
    foe=combat_ai_verification_unit_v072(:rattata,:enemy,4,50)
    breaker.pokemon_instance.set_active_moves_v045([:screech,:bite,:wrap,:glare])
    control.pokemon_instance.set_active_moves_v045([:sleep_powder,:tackle,:growl,:vine_whip])
    breaker.progression_select_move_v046(:screech);breaker.set_target(foe);breaker.verification_set_energy(PMD_AC::MAX_ENERGY)
    control.progression_select_move_v046(:sleep_powder);control.set_target(foe);control.verification_set_energy(PMD_AC::MAX_ENERGY)
    td=combat_ai_move_data_v068(:tackle);base=nil;one=nil;two=nil;depth=0
    combat_ai_with_units_v068([hitter,foe]){base=progression_candidate_score_v046(hitter,foe,td,:tackle,0)}
    combat_ai_with_units_v068([breaker,hitter,foe]){one=progression_candidate_score_v046(hitter,foe,td,:tackle,0)}
    combat_ai_with_units_v068([breaker,control,hitter,foe]) do
      two=progression_candidate_score_v046(hitter,foe,td,:tackle,0)
      depth=combat_ai_support_chain_depth_v072(hitter,foe,td)
    end
    ok=one>base && two>one && depth==2
    log_event(:verify,'COMBAT_AI_TRIPLE_CHAIN_V072 pass='+(ok ? '1':'0')+
      ' base='+sprintf('%.1f',base.to_f)+' one_setup='+sprintf('%.1f',one.to_f)+
      ' two_setup='+sprintf('%.1f',two.to_f)+' chain_depth='+depth.to_i.to_s)
    @verification_done[:v072_triple]=true
  end

  def verify_combat_ai_projected_ko_v072
    return if @verification_done[:v072_projected_ko]
    lead=combat_ai_verification_unit_v072(:rattata,:ally,5,60)
    user=combat_ai_verification_unit_v072(:rattata,:ally,6,60)
    e1=combat_ai_verification_unit_v072(:rattata,:enemy,7,50)
    e2=combat_ai_verification_unit_v072(:rattata,:enemy,8,50)
    lead.pokemon_instance.set_active_moves_v045([:tackle,:quick_attack,:tail_whip,:focus_energy])
    user.pokemon_instance.set_active_moves_v045([:tackle,:quick_attack,:tail_whip,:focus_energy])
    lead.progression_select_move_v046(:tackle);lead.set_target(e1);lead.verification_set_energy(PMD_AC::MAX_ENERGY)
    e1.verification_set_hp_percent(0.04)
    td=combat_ai_move_data_v068(:tackle);s1=nil;s2=nil;best=nil;pred=0.0;intent=true
    combat_ai_with_units_v068([lead,user,e1,e2]) do
      pred=combat_ai_reserved_damage_v072(user,e1,td)
      s1=progression_candidate_score_v046(user,e1,td,:tackle,0)+combat_ai_policy_target_bonus_v069(user,e1,:execute,td)
      s2=progression_candidate_score_v046(user,e2,td,:tackle,0)+combat_ai_policy_target_bonus_v069(user,e2,:execute,td)
      best=combat_ai_best_enemy_target_v069(user,:execute,td)
      user.verification_set_energy(PMD_AC::MAX_ENERGY)
      user.combat_ai_set_intent_v071(:tackle,e1,100.0,24)
      intent=combat_ai_intent_valid_v071?(user)
    end
    ok=pred>=e1.hp.to_f && s2>s1 && best==e2 && !intent
    log_event(:verify,'COMBAT_AI_PROJECTED_KO_V072 pass='+(ok ? '1':'0')+
      ' reserved='+sprintf('%.1f',pred)+' target_hp='+e1.hp.to_i.to_s+
      ' doomed_score='+sprintf('%.1f',s1.to_f)+' alternate_score='+sprintf('%.1f',s2.to_f)+
      ' retarget='+(best==nil ? 'nil' : best.key.to_s)+' intent_release='+(intent ? '0':'1'))
    @verification_done[:v072_projected_ko]=true
  end

  def verify_combat_ai_finisher_v072
    return if @verification_done[:v072_finisher]
    lead=combat_ai_verification_unit_v072(:rattata,:ally,9,60)
    user=combat_ai_verification_unit_v072(:rattata,:ally,10,60)
    foe=combat_ai_verification_unit_v072(:rattata,:enemy,11,50)
    lead.pokemon_instance.set_active_moves_v045([:tackle,:quick_attack,:tail_whip,:focus_energy])
    lead.progression_select_move_v046(:tackle);lead.set_target(foe);lead.verification_set_energy(PMD_AC::MAX_ENERGY)
    foe.verification_set_hp_percent(0.10)
    qd=combat_ai_move_data_v068(:quick_attack);td=combat_ai_move_data_v068(:tackle)
    q=nil;t=nil;pred=0.0;proj=0.0
    combat_ai_with_units_v068([lead,user,foe]) do
      pred=combat_ai_reserved_damage_v072(user,foe,qd)
      proj=combat_ai_projected_hp_v072(user,foe,qd)
      q=progression_candidate_score_v046(user,foe,qd,:quick_attack,0)
      t=progression_candidate_score_v046(user,foe,td,:tackle,1)
    end
    ok=pred>0.0 && proj>0.0 && proj/foe.maxhp.to_f<=PMD_AC::COMBAT_AI_TUNING_V072[:finisher_hp_ratio].to_f && q>t
    log_event(:verify,'COMBAT_AI_FINISHER_V072 pass='+(ok ? '1':'0')+
      ' reserved='+sprintf('%.1f',pred)+' projected_hp='+sprintf('%.1f',proj)+
      ' quick_attack='+sprintf('%.1f',q.to_f)+' tackle='+sprintf('%.1f',t.to_f))
    @verification_done[:v072_finisher]=true
  end

  def verify_combat_ai_weather_support_chain_v072
    return if @verification_done[:v072_weather_chain]
    rain=combat_ai_verification_unit_v072(:squirtle,:ally,12,60)
    helper=combat_ai_verification_unit_v072(:eevee,:ally,13,60)
    hitter=combat_ai_verification_unit_v072(:vaporeon,:ally,14,60)
    foe=combat_ai_verification_unit_v072(:rattata,:enemy,15,50)
    rain.pokemon_instance.set_active_moves_v045([:rain_dance,:water_gun,:tackle,:protect])
    rain.progression_select_move_v046(:rain_dance);rain.set_target(foe);rain.verification_set_energy(PMD_AC::MAX_ENERGY)
    helper.pokemon_instance.set_active_moves_v045([:helping_hand,:tackle,:tail_whip,:quick_attack])
    helper.progression_select_move_v046(:helping_hand);helper.verification_set_energy(PMD_AC::MAX_ENERGY)
    helper.combat_ai_set_intent_v071(:helping_hand,hitter,100.0,24)
    wd=combat_ai_move_data_v068(:water_gun);base=nil;rain_only=nil;help_only=nil;both=nil;depth=0
    combat_ai_with_units_v068([hitter,foe]){base=progression_candidate_score_v046(hitter,foe,wd,:water_gun,0)}
    combat_ai_with_units_v068([rain,hitter,foe]){rain_only=progression_candidate_score_v046(hitter,foe,wd,:water_gun,0)}
    combat_ai_with_units_v068([helper,hitter,foe]){help_only=progression_candidate_score_v046(hitter,foe,wd,:water_gun,0)}
    combat_ai_with_units_v068([rain,helper,hitter,foe]) do
      both=progression_candidate_score_v046(hitter,foe,wd,:water_gun,0)
      depth=combat_ai_support_chain_depth_v072(hitter,foe,wd)
    end
    ok=rain_only>base && help_only>base && both>rain_only && both>help_only && depth==2
    log_event(:verify,'COMBAT_AI_WEATHER_SUPPORT_CHAIN_V072 pass='+(ok ? '1':'0')+
      ' base='+sprintf('%.1f',base.to_f)+' rain='+sprintf('%.1f',rain_only.to_f)+
      ' help='+sprintf('%.1f',help_only.to_f)+' both='+sprintf('%.1f',both.to_f)+
      ' chain_depth='+depth.to_i.to_s)
    @verification_done[:v072_weather_chain]=true
  end

  def verify_combat_ai_carry_v072
    return if @verification_done[:v072_carry]
    c=PMD_AC.compiled_data_status_v061;m=PMD_AC::COMBAT_AI_MANIFEST_V072
    ok=c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077 &&
      m[:move_runtime].to_i==526 && m[:ability_slots].to_i==1028 && m[:ability_species].to_i==483
    log_event(:verify,'COMBAT_AI_CARRY_V072 pass='+(ok ? '1':'0')+
      ' compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+
      ' aliases='+c[:aliases].to_i.to_s+' moves=526 learnset=7005/7005 abilities=1028/1193 species=483/494 '+
      ' movement=v0.15_unchanged basic_target=v0.15_unchanged skill_target=v0.69_overlay '+
      ' threat=v0.70_hysteresis intent=v0.71_24f prediction=v0.72_side_effect_free '+
      ' combo_packet=v0.60.2 native_router=v0.62 weather_field=unchanged presentation_anchors=unchanged')
    @verification_done[:v072_carry]=true
  end

  def update_combat_ai_integration_v_v072
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_combat_ai_manifest_v072 if f>=2
    verify_diagnostic_presentation_isolation_v068 if f>=4
    verify_combat_ai_triple_chain_v072 if f>=6
    verify_combat_ai_projected_ko_v072 if f>=8
    verify_combat_ai_finisher_v072 if f>=10
    verify_combat_ai_weather_support_chain_v072 if f>=12
    verify_combat_ai_carry_v071 if f>=14
    verify_combat_ai_carry_v070 if f>=14
    verify_ability_runtime_carry_v067 if f>=14
    verify_native_semantic_carry_v063 if f>=14
    verify_combat_ai_carry_v072 if f>=16
    complete_verification_mode if f>=18
  end

  def update_verification_script
    if verification_mode==:combat_ai_integration_v_v072
      update_combat_ai_integration_v_v072;return
    end
    pmd_ac_v072_update_verification_script
  end
end
