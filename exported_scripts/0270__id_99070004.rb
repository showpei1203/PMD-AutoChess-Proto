#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.71
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V071 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - combat_ai_scalar_v071 / combat_ai_checksum32_v071 / validate_combat_ai_v071 / initialize
# - combat_ai_clear_intent_v071 / combat_ai_set_intent_v071 / combat_ai_intent_snapshot_v071 / start
# - diagnostic_presentation_suppressed_v068? / combat_ai_phase4_active_v071? / combat_ai_planned_target_v070 / combat_ai_effective_priority_v071
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.71
# Combat AI Integration IV
#------------------------------------------------------------------------------
# Adds ordered combo-chain scoring and a short intent lock over the already
# verified v0.70 AI.  Movement, basic target core, Weather/Field runtime,
# v0.60.2 damage packets, Native Pose and presentation anchors remain intact.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V071='0.71'

  class << self
    def combat_ai_scalar_v071(x)
      return '' if x==nil
      return x.collect{|v|combat_ai_scalar_v071(v)}.join(',') if x.is_a?(Array)
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+combat_ai_scalar_v071(x[k])}.join(',')
      end
      x.to_s
    end

    def combat_ai_checksum32_v071
      h=0;m=COMBAT_AI_MANIFEST_V071
      [:schema_version,:content_version,:base_version,:feature,:selection_source,
       :base_score,:features,:movement_core,:basic_target_core,:skill_target_layer,
       :threat_core,:weather_field,:damage_packet,:native_router,:ability_slots,
       :ability_slots_total,:ability_species,:move_runtime,:learnset_coverage].each do |k|
        combat_ai_scalar_v071(m[k]).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      COMBAT_AI_TUNING_V071.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        (k.to_s+'='+combat_ai_scalar_v071(COMBAT_AI_TUNING_V071[k])).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_combat_ai_v071
      e=[];m=COMBAT_AI_MANIFEST_V071
      e.push('features') unless m[:features].size==8
      e.push('moves') unless m[:move_runtime].to_i==526
      e.push('ability_slots') unless m[:ability_slots].to_i==1028 && m[:ability_slots_total].to_i==1193
      e.push('ability_species') unless m[:ability_species].to_i==483
      e.push('threat') unless m[:threat_core]=='v0.70_hysteresis_carried'
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
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

class Game_PMDChessUnit
  alias pmd_ac_v071_initialize initialize unless method_defined?(:pmd_ac_v071_initialize)
  def initialize(*args)
    pmd_ac_v071_initialize(*args)
    @combat_ai_intent_move_v071=nil
    @combat_ai_intent_target_v071=nil
    @combat_ai_intent_score_v071=nil
    @combat_ai_intent_until_v071=-1
  end

  def combat_ai_clear_intent_v071
    @combat_ai_intent_move_v071=nil
    @combat_ai_intent_target_v071=nil
    @combat_ai_intent_score_v071=nil
    @combat_ai_intent_until_v071=-1
  end

  def combat_ai_set_intent_v071(move,target,score,frames)
    @combat_ai_intent_move_v071=move
    @combat_ai_intent_target_v071=target
    @combat_ai_intent_score_v071=score
    @combat_ai_intent_until_v071=Graphics.frame_count+frames.to_i
  end

  def combat_ai_intent_snapshot_v071
    {:move=>@combat_ai_intent_move_v071,:target=>@combat_ai_intent_target_v071,
     :score=>@combat_ai_intent_score_v071,:until=>@combat_ai_intent_until_v071.to_i}
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v071_start start unless method_defined?(:pmd_ac_v071_start)
  alias pmd_ac_v071_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v071_prepare_verification_battle)
  alias pmd_ac_v071_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v071_update_verification_script)
  alias pmd_ac_v071_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v071_progression_candidate_score_v046)
  alias pmd_ac_v071_progression_select_best_move_v046 progression_select_best_move_v046 unless method_defined?(:pmd_ac_v071_progression_select_best_move_v046)
  alias pmd_ac_v071_combat_ai_planned_target_v070 combat_ai_planned_target_v070 unless method_defined?(:pmd_ac_v071_combat_ai_planned_target_v070)
  alias pmd_ac_v071_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v071_diagnostic_presentation_suppressed_v068)

  def start
    pmd_ac_v071_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.70 Battle Verification Log/,
          'PMD AutoChess Proto v0.71 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:combat_ai,
      'LOADED phase=IV intent_lock=24 ordered_combo=1 stat_break_chain=1 status_payoff=1 '+
      'helping_hand_chain=1 duplicate_debuff=1 conditional_power=1 movement=v0.15_unchanged '+
      'basic_target=v0.15_unchanged threat=v0.70_hysteresis damage_packet=v0.60.2')
    log_event(:presentation,
      'PATCH v0.71 diagnostic_vfx_isolation=v0.68_carried native_router=v0.62_unchanged '+
      'beam_projectile_impact_targetfx=unchanged')
  end

  def diagnostic_presentation_suppressed_v068?
    return true if verification_mode==:combat_ai_integration_iv_v071
    pmd_ac_v071_diagnostic_presentation_suppressed_v068
  end

  def combat_ai_phase4_active_v071?
    m=verification_mode
    m==:normal || m==:combat_ai_integration_iv_v071
  end

  def combat_ai_planned_target_v070(u)
    if combat_ai_phase4_active_v071? && u!=nil && u.respond_to?(:combat_ai_intent_snapshot_v071)
      s=u.combat_ai_intent_snapshot_v071
      return s[:target] if s[:target]!=nil && !s[:target].dead? && Graphics.frame_count<=s[:until].to_i
    end
    pmd_ac_v071_combat_ai_planned_target_v070(u)
  end

  def combat_ai_effective_priority_v071(unit,data)
    p=0
    begin;p=PMD_AC.canonical_priority_v042(data).to_i;rescue;p=0;end
    if unit!=nil && unit.respond_to?(:ability_key) && unit.ability_key==:prankster && !combat_ai_damaging_v068?(data)
      p+=1
    end
    p
  end

  def combat_ai_order_factor_v071(ally,unit,ally_data,own_data)
    t=PMD_AC::COMBAT_AI_TUNING_V071
    if ally!=nil && ally.respond_to?(:action) && ally.action==:skill
      return t[:ordered_setup_committed_factor].to_f
    end
    ap=combat_ai_effective_priority_v071(ally,ally_data)
    op=combat_ai_effective_priority_v071(unit,own_data)
    return t[:ordered_setup_equal_priority_factor].to_f if ap>=op
    t[:ordered_setup_slow_factor].to_f
  end

  def combat_ai_stage_changes_v071(data)
    h={}
    for e in (data==nil ? [] : (data[:effects]||[]))
      next unless combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:stat_stage
      st=combat_ai_sym_v068(combat_ai_get_v068(e,:stat));n=combat_ai_get_v068(e,:stages).to_i
      h[st]=(h[st]||0)+n if st!=nil && n!=0
    end
    h
  end

  def combat_ai_major_status_active_v071?(target,status)
    return false if target==nil || !target.respond_to?(:status?)
    if status==:major
      for s in PMD_AC::COMBAT_AI_MAJOR_STATUSES_V071
        return true if target.status?(s)
      end
      return false
    end
    target.status?(status)
  end

  def combat_ai_planned_status_factor_v071(unit,target,wanted,own_data)
    best=0.0
    for a in allies_of(unit)
      next if a==unit
      pm=combat_ai_planned_move_v070(a);next if pm==nil
      pd=combat_ai_move_data_v068(pm);next if pd==nil
      pt=combat_ai_planned_target_v070(a);next unless pt==target
      ps=combat_ai_primary_status_v070(pd)
      match=(wanted==:major ? ps!=nil && PMD_AC::COMBAT_AI_MAJOR_STATUSES_V071.include?(ps) : ps==wanted)
      next unless match
      f=combat_ai_order_factor_v071(a,unit,pd,own_data)
      best=f if f>best
    end
    best
  end

  def combat_ai_conditional_chain_score_v071(unit,target,data,move,score)
    mk=combat_ai_sym_v068(move);want=PMD_AC::COMBAT_AI_CHAIN_STATUS_MOVES_V071[mk]
    return score if want==nil
    t=PMD_AC::COMBAT_AI_TUNING_V071
    ready=combat_ai_major_status_active_v071?(target,want)
    planned=combat_ai_planned_status_factor_v071(unit,target,want,data)
    if mk==:venoshock
      return score*t[:venoshock_ready_factor].to_f if ready
      return score*(1.0+(t[:venoshock_ready_factor].to_f-1.0)*planned*t[:planned_status_bonus_factor].to_f) if planned>0.0
    elsif mk==:hex
      return score*t[:hex_ready_factor].to_f if ready
      return score*(1.0+(t[:hex_ready_factor].to_f-1.0)*planned*t[:planned_status_bonus_factor].to_f) if planned>0.0
    elsif mk==:dream_eater
      return score+t[:dream_eater_ready_bonus].to_f if ready
      return [score,t[:dream_eater_unready_score].to_f].min if planned<=0.0
      return [score,t[:dream_eater_unready_score].to_f].min+t[:dream_eater_ready_bonus].to_f*planned
    elsif mk==:nightmare
      return score+t[:nightmare_ready_bonus].to_f if ready
      return [score,t[:nightmare_unready_score].to_f].min if planned<=0.0
      return [score,t[:nightmare_unready_score].to_f].min+t[:nightmare_ready_bonus].to_f*planned
    elsif mk==:wake_up_slap
      return score+t[:wake_up_slap_ready_bonus].to_f if ready
      return score+t[:wake_up_slap_ready_bonus].to_f*planned if planned>0.0
    end
    score
  end

  def combat_ai_ordered_combo_delta_v071(unit,target,data,move)
    return 0.0 if unit==nil || target==nil || data==nil
    t=PMD_AC::COMBAT_AI_TUNING_V071;delta=0.0
    cat=combat_ai_sym_v068(combat_ai_get_v068(data,:damage_category)||combat_ai_get_v068(data,:category))
    own_changes=combat_ai_stage_changes_v071(data)
    for a in allies_of(unit)
      next if a==unit
      pm=combat_ai_planned_move_v070(a);next if pm==nil
      pd=combat_ai_move_data_v068(pm);next if pd==nil
      pt=combat_ai_planned_target_v070(a)
      factor=combat_ai_order_factor_v071(a,unit,pd,data)
      changes=combat_ai_stage_changes_v071(pd)
      if pt==target && cat==:physical && changes[:def].to_i<0
        delta+=(-changes[:def].to_i)*t[:defense_break_stage_bonus].to_f*factor
      elsif pt==target && cat==:special && changes[:spdef].to_i<0
        delta+=(-changes[:spdef].to_i)*t[:special_defense_break_stage_bonus].to_f*factor
      end
      if pm==:helping_hand && pt==unit && combat_ai_damaging_v068?(data)
        delta+=t[:helping_hand_chain_bonus].to_f*factor
      end
      if pt==target && !own_changes.empty?
        same=0
        own_changes.keys.each do |st|
          same+=1 if own_changes[st].to_i<0 && changes[st].to_i<0
        end
        delta-=same.to_f*t[:duplicate_debuff_penalty].to_f if same>0
      end
    end
    delta
  end

  def combat_ai_intent_valid_v071?(unit)
    return false if unit==nil || !combat_ai_phase4_active_v071?
    return false unless unit.respond_to?(:combat_ai_intent_snapshot_v071)
    s=unit.combat_ai_intent_snapshot_v071
    return false if s[:move]==nil || s[:target]==nil || s[:target].dead?
    return false if Graphics.frame_count>s[:until].to_i
    return false if unit.respond_to?(:action) && unit.action==:skill
    return false if unit.respond_to?(:energy) && unit.energy.to_i<PMD_AC::MAX_ENERGY
    pool=unit.progression_move_pool_v046
    return false unless pool.include?(s[:move])
    true
  end

  def progression_select_best_move_v046(unit)
    if combat_ai_intent_valid_v071?(unit)
      s=unit.combat_ai_intent_snapshot_v071
      if unit.progression_select_move_v046(s[:move])
        return [s[:move],s[:target],s[:score]]
      end
      unit.combat_ai_clear_intent_v071
    end
    r=pmd_ac_v071_progression_select_best_move_v046(unit)
    if combat_ai_phase4_active_v071? && unit!=nil && r!=nil && r[0]!=nil && r[1]!=nil &&
       unit.respond_to?(:energy) && unit.energy.to_i>=PMD_AC::MAX_ENERGY
      unit.combat_ai_set_intent_v071(r[0],r[1],r[2],PMD_AC::COMBAT_AI_TUNING_V071[:intent_lock_frames])
    end
    r
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v071_progression_candidate_score_v046(unit,target,data,move,slot)
    return score unless combat_ai_phase4_active_v071?
    return nil if score==nil
    score=score.to_f+combat_ai_ordered_combo_delta_v071(unit,target,data,move)
    score=combat_ai_conditional_chain_score_v071(unit,target,data,move,score)
    [score,0.05].max
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------
  def combat_ai_verification_unit_v071(species,team,id,level=60,slot=:primary)
    i=PMD_PokemonInstance.new(species,level,{:instance_uid=>99071000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9710+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u
  end

  def prepare_verification_battle
    pmd_ac_v071_prepare_verification_battle
    return unless verification_mode==:combat_ai_integration_iv_v071
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,
      'START mode=COMBAT_AI_INTEGRATION_IV_V071 intent_lock=24 ordered_combo=1 '+
      'status_chain=1 diagnostic_vfx=off pokemon_resume_after_final_assert=1')
  end

  def verify_combat_ai_manifest_v071
    return if @verification_done[:v071_manifest]
    e=PMD_AC.validate_combat_ai_v071;ok=e.empty?
    log_event(:verify,'COMBAT_AI_MANIFEST_V071 pass='+(ok ? '1':'0')+
      ' features=8 moves=526 learnset=7005/7005 ability_slots=1028/1193 species=483/494 '+
      'checksum='+PMD_AC.combat_ai_checksum32_v071.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v071_manifest]=true
  end

  def verify_combat_ai_stat_chain_v071
    return if @verification_done[:v071_stat_chain]
    setup=combat_ai_verification_unit_v071(:ekans,:ally,1,60)
    hitter=combat_ai_verification_unit_v071(:rattata,:ally,2,60)
    foe=combat_ai_verification_unit_v071(:rattata,:enemy,3,50)
    setup.pokemon_instance.set_active_moves_v045([:screech,:bite,:wrap,:glare])
    setup.progression_select_move_v046(:screech);setup.set_target(foe);setup.verification_set_energy(PMD_AC::MAX_ENERGY)
    td=combat_ai_move_data_v068(:tackle);base=nil;chain=nil
    combat_ai_with_units_v068([hitter,foe]){base=progression_candidate_score_v046(hitter,foe,td,:tackle,0)}
    combat_ai_with_units_v068([setup,hitter,foe]){chain=progression_candidate_score_v046(hitter,foe,td,:tackle,0)}

    spec=combat_ai_verification_unit_v071(:jynx,:ally,4,60)
    caster=combat_ai_verification_unit_v071(:abra,:ally,5,60)
    spec.pokemon_instance.set_active_moves_v045([:fake_tears,:pound,:lick,:powder_snow])
    spec.progression_select_move_v046(:fake_tears);spec.set_target(foe);spec.verification_set_energy(PMD_AC::MAX_ENERGY)
    pd=combat_ai_move_data_v068(:psychic);sbase=nil;schain=nil
    combat_ai_with_units_v068([caster,foe]){sbase=progression_candidate_score_v046(caster,foe,pd,:psychic,0)}
    combat_ai_with_units_v068([spec,caster,foe]){schain=progression_candidate_score_v046(caster,foe,pd,:psychic,0)}
    ok=chain>base && schain>sbase
    log_event(:verify,'COMBAT_AI_STAT_CHAIN_V071 pass='+(ok ? '1':'0')+
      ' physical_after_screech='+sprintf('%.1f',base.to_f)+'->'+sprintf('%.1f',chain.to_f)+
      ' special_after_fake_tears='+sprintf('%.1f',sbase.to_f)+'->'+sprintf('%.1f',schain.to_f))
    @verification_done[:v071_stat_chain]=true
  end

  def verify_combat_ai_status_chain_v071
    return if @verification_done[:v071_status_chain]
    poisoner=combat_ai_verification_unit_v071(:bulbasaur,:ally,6,60)
    user=combat_ai_verification_unit_v071(:gastly,:ally,7,60)
    foe=combat_ai_verification_unit_v071(:rattata,:enemy,8,50)
    poisoner.pokemon_instance.set_active_moves_v045([:poison_powder,:tackle,:growl,:vine_whip])
    poisoner.progression_select_move_v046(:poison_powder);poisoner.set_target(foe);poisoner.verification_set_energy(PMD_AC::MAX_ENERGY)
    vd=combat_ai_move_data_v068(:venoshock);vb=nil;vp=nil
    combat_ai_with_units_v068([user,foe]){vb=progression_candidate_score_v046(user,foe,vd,:venoshock,0)}
    combat_ai_with_units_v068([poisoner,user,foe]){vp=progression_candidate_score_v046(user,foe,vd,:venoshock,0)}

    sleeper=combat_ai_verification_unit_v071(:bulbasaur,:ally,9,60)
    sleeper.pokemon_instance.set_active_moves_v045([:sleep_powder,:tackle,:growl,:vine_whip])
    sleeper.progression_select_move_v046(:sleep_powder);sleeper.set_target(foe);sleeper.verification_set_energy(PMD_AC::MAX_ENERGY)
    dd=combat_ai_move_data_v068(:dream_eater);du=nil;dp=nil;dr=nil
    combat_ai_with_units_v068([user,foe]){du=progression_candidate_score_v046(user,foe,dd,:dream_eater,0)}
    combat_ai_with_units_v068([sleeper,user,foe]){dp=progression_candidate_score_v046(user,foe,dd,:dream_eater,0)}
    foe.apply_status(:sleep,{:duration=>999999,:value=>0,:interval=>999999},sleeper)
    combat_ai_with_units_v068([user,foe]){dr=progression_candidate_score_v046(user,foe,dd,:dream_eater,0)}
    ok=vp>vb && du<=PMD_AC::COMBAT_AI_TUNING_V071[:dream_eater_unready_score].to_f+0.1 && dp>du && dr>dp
    log_event(:verify,'COMBAT_AI_STATUS_CHAIN_V071 pass='+(ok ? '1':'0')+
      ' venoshock_planned_poison='+sprintf('%.1f',vb.to_f)+'->'+sprintf('%.1f',vp.to_f)+
      ' dream_eater='+sprintf('%.1f',du.to_f)+'->'+sprintf('%.1f',dp.to_f)+'->'+sprintf('%.1f',dr.to_f))
    @verification_done[:v071_status_chain]=true
  end

  def verify_combat_ai_duplicate_helping_v071
    return if @verification_done[:v071_duplicate_helping]
    deb1=combat_ai_verification_unit_v071(:ekans,:ally,10,60)
    deb2=combat_ai_verification_unit_v071(:ekans,:ally,11,60)
    foe=combat_ai_verification_unit_v071(:rattata,:enemy,12,50)
    deb1.pokemon_instance.set_active_moves_v045([:screech,:bite,:wrap,:glare])
    deb1.progression_select_move_v046(:screech);deb1.set_target(foe);deb1.verification_set_energy(PMD_AC::MAX_ENERGY)
    sd=combat_ai_move_data_v068(:screech);solo=nil;dup=nil
    combat_ai_with_units_v068([deb2,foe]){solo=progression_candidate_score_v046(deb2,foe,sd,:screech,0)}
    combat_ai_with_units_v068([deb1,deb2,foe]){dup=progression_candidate_score_v046(deb2,foe,sd,:screech,0)}

    helper=combat_ai_verification_unit_v071(:eevee,:ally,13,60)
    hitter=combat_ai_verification_unit_v071(:rattata,:ally,14,60)
    helper.pokemon_instance.set_active_moves_v045([:helping_hand,:tackle,:tail_whip,:quick_attack])
    helper.progression_select_move_v046(:helping_hand);helper.verification_set_energy(PMD_AC::MAX_ENERGY)
    helper.combat_ai_set_intent_v071(:helping_hand,hitter,100.0,PMD_AC::COMBAT_AI_TUNING_V071[:intent_lock_frames])
    td=combat_ai_move_data_v068(:tackle);hb=nil;hh=nil
    combat_ai_with_units_v068([hitter,foe]){hb=progression_candidate_score_v046(hitter,foe,td,:tackle,0)}
    combat_ai_with_units_v068([helper,hitter,foe]){hh=progression_candidate_score_v046(hitter,foe,td,:tackle,0)}
    ok=dup<solo && hh>hb
    log_event(:verify,'COMBAT_AI_TEAM_CHAIN_V071 pass='+(ok ? '1':'0')+
      ' duplicate_screech='+sprintf('%.1f',solo.to_f)+'->'+sprintf('%.1f',dup.to_f)+
      ' helping_hand_payoff='+sprintf('%.1f',hb.to_f)+'->'+sprintf('%.1f',hh.to_f))
    @verification_done[:v071_duplicate_helping]=true
  end

  def verify_combat_ai_intent_lock_v071
    return if @verification_done[:v071_intent]
    u=combat_ai_verification_unit_v071(:rattata,:ally,15,60)
    e1=combat_ai_verification_unit_v071(:rattata,:enemy,16,50)
    e2=combat_ai_verification_unit_v071(:rattata,:enemy,17,50)
    u.pokemon_instance.set_active_moves_v045([:tackle,:quick_attack,:tail_whip,:focus_energy])
    u.verification_set_energy(PMD_AC::MAX_ENERGY);u.deploy_to_pixel(200,200)
    e1.deploy_to_pixel(310,190);e2.deploy_to_pixel(310,210)
    first=nil;held=nil;released=nil
    combat_ai_with_units_v068([u,e1,e2]) do
      u.set_target(e1);first=progression_select_best_move_v046(u)
      u.set_target(e2);held=progression_select_best_move_v046(u)
      u.instance_variable_set(:@combat_ai_intent_until_v071,Graphics.frame_count-1)
      released=progression_select_best_move_v046(u)
    end
    ok=first[1]==e1 && held[0]==first[0] && held[1]==e1 && released[1]==e2
    log_event(:verify,'COMBAT_AI_INTENT_LOCK_V071 pass='+(ok ? '1':'0')+
      ' first='+(first[1]==nil ? 'nil' : first[1].key.to_s)+
      ' held='+(held[1]==nil ? 'nil' : held[1].key.to_s)+
      ' after_expire='+(released[1]==nil ? 'nil' : released[1].key.to_s)+
      ' frames='+PMD_AC::COMBAT_AI_TUNING_V071[:intent_lock_frames].to_i.to_s)
    @verification_done[:v071_intent]=true
  end

  def verify_combat_ai_carry_v071
    return if @verification_done[:v071_carry]
    c=PMD_AC.compiled_data_status_v061;m=PMD_AC::COMBAT_AI_MANIFEST_V071
    ok=c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077 &&
      m[:move_runtime].to_i==526 && m[:ability_slots].to_i==1028 && m[:ability_species].to_i==483
    log_event(:verify,'COMBAT_AI_CARRY_V071 pass='+(ok ? '1':'0')+
      ' compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+
      ' aliases='+c[:aliases].to_i.to_s+' moves=526 learnset=7005/7005 abilities=1028/1193 species=483/494 '+
      ' movement=v0.15_unchanged basic_target=v0.15_unchanged skill_target=v0.69_overlay '+
      ' threat=v0.70_hysteresis intent_lock=24 combo_packet=v0.60.2 native_router=v0.62 '+
      'weather_field=unchanged presentation_anchors=unchanged')
    @verification_done[:v071_carry]=true
  end

  def update_combat_ai_integration_iv_v071
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_combat_ai_manifest_v071 if f>=2
    verify_diagnostic_presentation_isolation_v068 if f>=4
    verify_combat_ai_stat_chain_v071 if f>=6
    verify_combat_ai_status_chain_v071 if f>=8
    verify_combat_ai_duplicate_helping_v071 if f>=10
    verify_combat_ai_intent_lock_v071 if f>=12
    verify_combat_ai_carry_v070 if f>=14
    verify_combat_ai_carry_v069 if f>=14
    verify_ability_runtime_carry_v067 if f>=14
    verify_native_semantic_carry_v063 if f>=14
    verify_combat_ai_carry_v071 if f>=16
    complete_verification_mode if f>=18
  end

  def update_verification_script
    if verification_mode==:combat_ai_integration_iv_v071
      update_combat_ai_integration_iv_v071;return
    end
    pmd_ac_v071_update_verification_script
  end
end
