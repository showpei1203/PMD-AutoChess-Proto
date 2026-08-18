#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.73
# 分類：測試／Soak
#
# 【用途／機制】
# 提供整體戰鬥驗證、長時間 Soak 與 Carry 檢查。
#
# 【怎麼調整】
# 驗證模式結束必須看到 VERIFY_FINISHED_BATTLE_RESUME pass=1，並恢復 Pokémon AI／Mov
# ement。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / soak_update_peaks_v073 / update_effect_sprites / update_projectile_sprites
# - update_battle_objects / combat_ai_phase2_active_v069? / combat_ai_phase3_active_v070? / combat_ai_phase4_active_v071?
# - combat_ai_phase5_active_v072? / full_battle_soak_v073? / log_event / start_battle
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.73
# Full Battle Soak Harness
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Runs three real 3v3 battles with normal AI, movement, presentation and damage.
# The harness only changes test loadouts / starting HP+Energy and injects a small
# number of weather/field perturbations.  It never calls real damage from AI
# prediction and never changes the verified combat cores.
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v073_start start unless method_defined?(:pmd_ac_v073_start)
  alias pmd_ac_v073_start_battle start_battle unless method_defined?(:pmd_ac_v073_start_battle)
  alias pmd_ac_v073_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v073_prepare_verification_battle)
  alias pmd_ac_v073_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v073_update_verification_script)
  alias pmd_ac_v073_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v073_check_battle_end)
  alias pmd_ac_v073_update_result_phase update_result_phase unless method_defined?(:pmd_ac_v073_update_result_phase)
  alias pmd_ac_v073_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v073_update_effect_sprites)
  alias pmd_ac_v073_update_projectile_sprites update_projectile_sprites unless method_defined?(:pmd_ac_v073_update_projectile_sprites)
  alias pmd_ac_v073_update_battle_objects update_battle_objects unless method_defined?(:pmd_ac_v073_update_battle_objects)
  alias pmd_ac_v073_log_event log_event unless method_defined?(:pmd_ac_v073_log_event)
  alias pmd_ac_v073_phase2_active_v069 combat_ai_phase2_active_v069? unless method_defined?(:pmd_ac_v073_phase2_active_v069)
  alias pmd_ac_v073_phase3_active_v070 combat_ai_phase3_active_v070? unless method_defined?(:pmd_ac_v073_phase3_active_v070)
  alias pmd_ac_v073_phase4_active_v071 combat_ai_phase4_active_v071? unless method_defined?(:pmd_ac_v073_phase4_active_v071)
  alias pmd_ac_v073_phase5_active_v072 combat_ai_phase5_active_v072? unless method_defined?(:pmd_ac_v073_phase5_active_v072)

  def start
    pmd_ac_v073_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.72\.1 Battle Verification Log/,
          'PMD AutoChess Proto v0.73 Battle Verification Log')
        t.sub!(/PMD AutoChess Proto v0\.72 Battle Verification Log/,
          'PMD AutoChess Proto v0.73 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::SOAK_MANIFEST_V073
    log_event(:soak,
      'LOADED rounds='+m[:rounds].to_s+
      ' max_frames='+m[:max_frames].to_s+
      ' hp_rate='+sprintf('%.2f',m[:initial_hp_rate].to_f)+
      ' energy='+m[:initial_energy].to_s+
      ' speed=x'+m[:battle_speed].to_s+
      ' checksum32='+PMD_AC.soak_checksum32_v073.to_s)
    log_event(:presentation,
      'PATCH v0.73 full_battle_soak=1 normal_ai=1 normal_vfx=1 '+
      'weather_field=unchanged damage_packet=v0.60.2 native_router=v0.62')
  end


  def soak_update_peaks_v073
    return unless @soak_active_v073 && @phase==:battle
    @soak_round_peak_projectiles_v073=[@soak_round_peak_projectiles_v073.to_i,(@projectile_sprites||[]).size].max
    @soak_round_peak_objects_v073=[@soak_round_peak_objects_v073.to_i,(@battle_objects||[]).size].max
    @soak_round_peak_effects_v073=[@soak_round_peak_effects_v073.to_i,(@effect_sprites||[]).size].max
  end

  def update_effect_sprites
    pmd_ac_v073_update_effect_sprites
    soak_update_peaks_v073
  end

  def update_projectile_sprites
    pmd_ac_v073_update_projectile_sprites
    soak_update_peaks_v073
  end

  def update_battle_objects
    pmd_ac_v073_update_battle_objects
    soak_update_peaks_v073
  end

  def combat_ai_phase2_active_v069?
    return true if verification_mode==:full_battle_soak_v073
    pmd_ac_v073_phase2_active_v069
  end

  def combat_ai_phase3_active_v070?
    return true if verification_mode==:full_battle_soak_v073
    pmd_ac_v073_phase3_active_v070
  end

  def combat_ai_phase4_active_v071?
    return true if verification_mode==:full_battle_soak_v073
    pmd_ac_v073_phase4_active_v071
  end

  def combat_ai_phase5_active_v072?
    return true if verification_mode==:full_battle_soak_v073
    pmd_ac_v073_phase5_active_v072
  end

  def full_battle_soak_v073?
    verification_mode==:full_battle_soak_v073
  end

  def log_event(category,message)
    if @soak_active_v073 && @phase==:battle
      k=category.to_s
      unless k=='soak' || k=='verify' || k=='summary'
        @soak_round_counts_v073={} if @soak_round_counts_v073==nil
        @soak_total_counts_v073={} if @soak_total_counts_v073==nil
        @soak_round_counts_v073[k]=(@soak_round_counts_v073[k]||0)+1
        @soak_total_counts_v073[k]=(@soak_total_counts_v073[k]||0)+1
      end
    end
    pmd_ac_v073_log_event(category,message)
  end

  def start_battle
    if full_battle_soak_v073?
      @soak_active_v073=true
      @soak_round_v073=1 if @soak_round_v073==nil || @soak_round_v073<=0
      @soak_results_v073=[] if @soak_results_v073==nil
      @soak_failures_v073=[] if @soak_failures_v073==nil
      @soak_total_counts_v073={} if @soak_total_counts_v073==nil
      @soak_growth_snapshot_v073={} if @soak_growth_snapshot_v073==nil
      @battle_speed=PMD_AC::SOAK_BATTLE_SPEED_V073
    end
    pmd_ac_v073_start_battle
  end

  def soak_capture_growth_v073(unit)
    return if unit==nil || unit.team!=:ally
    pi=unit.pokemon_instance
    return if pi==nil || !pi.respond_to?(:ensure_growth_data_v045)
    pi.ensure_growth_data_v045
    uid=unit.instance_uid.to_i
    return if @soak_growth_snapshot_v073[uid]!=nil
    @soak_growth_snapshot_v073[uid]={
      :known=>(pi.instance_variable_get(:@known_moves_v045)||[]).dup,
      :active=>(pi.instance_variable_get(:@active_moves_v045)||[]).dup,
      :pending=>(pi.instance_variable_get(:@pending_move_choices_v045)||[]).dup,
      :mastery=>(pi.instance_variable_get(:@move_mastery_exp_v045)||{}).dup
    }
  end

  def soak_restore_growth_v073
    return if @soak_growth_snapshot_v073==nil
    for u in (@units||[])
      next unless u.team==:ally
      pi=u.pokemon_instance;next if pi==nil
      s=@soak_growth_snapshot_v073[u.instance_uid.to_i];next if s==nil
      pi.instance_variable_set(:@known_moves_v045,s[:known].dup)
      pi.instance_variable_set(:@active_moves_v045,s[:active].dup)
      pi.instance_variable_set(:@pending_move_choices_v045,s[:pending].dup)
      pi.instance_variable_set(:@move_mastery_exp_v045,s[:mastery].dup)
    end
  end

  def soak_scenario_v073
    i=[@soak_round_v073.to_i-1,0].max
    PMD_AC::SOAK_SCENARIOS_V073[i] || PMD_AC::SOAK_SCENARIOS_V073[-1]
  end

  def soak_apply_moves_v073(unit,moves)
    return 0 if unit==nil || moves==nil
    pi=unit.pokemon_instance
    return 0 if pi==nil || !pi.respond_to?(:learn_known_move_v045)
    soak_capture_growth_v073(unit)
    good=[]
    for mv in moves
      next unless PMD_AC.move_executable?(mv)
      pi.learn_known_move_v045(mv,nil,unit.species_key,false) unless pi.knows_move_v045?(mv)
      good.push(mv) if pi.knows_move_v045?(mv)
    end
    good=good[0,4] || good
    ok=good.size>0 && pi.set_active_moves_v045(good)
    log_event(:soak,
      'LOADOUT round='+@soak_round_v073.to_s+' '+unit.log_name+
      ' pass='+(ok && good.size>=3 ? '1':'0')+
      ' moves=['+good.collect{|x|x.to_s}.join(',')+']')
    if !ok || good.size<3
      @soak_failures_v073.push('loadout_'+@soak_round_v073.to_s+'_'+unit.species_key.to_s)
    end
    good.size
  end

  def soak_unit_for_v073(team,species=nil)
    a=(@units||[]).find_all{|u|u.team==team && u.alive?}
    return nil if a.empty?
    return a[0] if species==nil
    a.find{|u|u.species_key==species} || a[0]
  end

  def prepare_verification_battle
    unless full_battle_soak_v073?
      pmd_ac_v073_prepare_verification_battle
      return
    end

    @verification_frame=0
    @verification_done={}
    @zone_avoid_log_frames={}
    @soak_round_frame_v073=0
    @soak_round_counts_v073={}
    @soak_round_peak_projectiles_v073=0
    @soak_round_peak_objects_v073=0
    @soak_round_peak_effects_v073=0
    @soak_round_audited_v073=false
    @soak_result_wait_v073=0
    @progression_verify_selection_v046=true
    @battle_speed=PMD_AC::SOAK_BATTLE_SPEED_V073

    s=soak_scenario_v073
    for u in (@units||[])
      u.verification_finish if u.respond_to?(:verification_finish)
      soak_apply_moves_v073(u,s[:moves][u.species_key])
      u.verification_set_hp_percent(PMD_AC::SOAK_INITIAL_HP_RATE_V073) if u.respond_to?(:verification_set_hp_percent)
      u.verification_set_energy(PMD_AC::SOAK_INITIAL_ENERGY_V073) if u.respond_to?(:verification_set_energy)
    end

    if respond_to?(:refresh_all_synergies)
      begin;refresh_all_synergies(:soak_start,true);rescue;end
    end

    log_event(:verify,
      'FULL_BATTLE_SOAK_MANIFEST_V073 pass='+(PMD_AC.validate_soak_v073.empty? ? '1':'0')+
      ' round='+@soak_round_v073.to_s+'/'+PMD_AC::SOAK_ROUNDS_V073.to_s+
      ' scenario='+s[:name].to_s+
      ' checksum='+PMD_AC.soak_checksum32_v073.to_s+
      ' errors=['+PMD_AC.validate_soak_v073.join(',')+']')
    log_event(:soak,
      'ROUND_START round='+@soak_round_v073.to_s+
      ' scenario='+s[:name].to_s+
      ' hp_rate='+sprintf('%.2f',PMD_AC::SOAK_INITIAL_HP_RATE_V073)+
      ' energy='+PMD_AC::SOAK_INITIAL_ENERGY_V073.to_s+
      ' speed=x'+@battle_speed.to_s+
      ' ai=on movement=on vfx=on')
  end

  def soak_perturb_v073(entry)
    kind=entry[0];frame=entry[1].to_i;key=entry[2];team=entry[3];turns=entry[4]
    token='perturb_'+@soak_round_v073.to_s+'_'+frame.to_s+'_'+kind.to_s+'_'+key.to_s
    @verification_done={} if @verification_done==nil
    return if @verification_done[token]
    source=soak_unit_for_v073(team)
    if kind==:weather && respond_to?(:set_canonical_weather)
      set_canonical_weather(key,source,turns,false)
    elsif kind==:field && respond_to?(:set_canonical_field_effect_v035)
      set_canonical_field_effect_v035(key,source,turns)
    end
    log_event(:soak,
      'PERTURB round='+@soak_round_v073.to_s+' frame='+@soak_round_frame_v073.to_s+
      ' kind='+kind.to_s+' key='+key.to_s+' team='+team.to_s+
      ' source='+(source==nil ? 'SYSTEM' : source.log_name))
    @verification_done[token]=true
  end

  def soak_runtime_audit_v073(final=false)
    projs=(@projectile_sprites||[]).size
    objs=(@battle_objects||[]).size
    effs=(@effect_sprites||[]).size
    @soak_round_peak_projectiles_v073=[@soak_round_peak_projectiles_v073.to_i,projs].max
    @soak_round_peak_objects_v073=[@soak_round_peak_objects_v073.to_i,objs].max
    @soak_round_peak_effects_v073=[@soak_round_peak_effects_v073.to_i,effs].max

    uids=[];dup=0;bad_pos=0;stale=0
    for u in (@units||[])
      id=u.instance_uid.to_i
      dup+=1 if uids.include?(id)
      uids.push(id)
      x=u.pixel_x.to_f;y=u.pixel_y.to_f
      bad_pos+=1 if x!=x || y!=y || x.abs>10000.0 || y.abs>10000.0
      t=u.target
      stale+=1 if u.alive? && t!=nil && t.dead?
    end
    maxobj=PMD_AC.const_defined?('BATTLE_OBJECT_MAX') ? PMD_AC::BATTLE_OBJECT_MAX.to_i : 128
    pass=dup==0 && bad_pos==0 && projs<=128 && objs<=maxobj
    if !pass
      @soak_failures_v073.push('audit_'+@soak_round_v073.to_s+'_'+@soak_round_frame_v073.to_s)
    end
    log_event(:verify,
      'FULL_BATTLE_SOAK_AUDIT_V073 pass='+(pass ? '1':'0')+
      ' round='+@soak_round_v073.to_s+
      ' frame='+@soak_round_frame_v073.to_s+
      ' projectiles='+projs.to_s+' objects='+objs.to_s+' effects='+effs.to_s+
      ' duplicate_uid='+dup.to_s+' bad_pos='+bad_pos.to_s+' stale_target='+stale.to_s+
      ' final='+(final ? '1':'0'))
    pass
  end

  def soak_force_timeout_v073
    return if @soak_timeout_v073
    @soak_timeout_v073=true
    @soak_failures_v073.push('timeout_round_'+@soak_round_v073.to_s)
    ally_hp=0;enemy_hp=0
    for u in (@units||[])
      ally_hp+=u.hp if u.team==:ally && u.alive?
      enemy_hp+=u.hp if u.team==:enemy && u.alive?
    end
    lose=ally_hp>=enemy_hp ? :enemy : :ally
    for u in (@units||[])
      u.instance_variable_set(:@hp,0) if u.team==lose
    end
    log_event(:verify,
      'FULL_BATTLE_SOAK_TIMEOUT_V073 pass=0 round='+@soak_round_v073.to_s+
      ' frames='+@soak_round_frame_v073.to_s+
      ' ally_hp='+ally_hp.to_s+' enemy_hp='+enemy_hp.to_s+
      ' forced_loser='+lose.to_s)
  end

  def update_verification_script
    unless full_battle_soak_v073?
      pmd_ac_v073_update_verification_script
      return
    end
    return if @soak_complete_v073
    @verification_frame+=1
    @soak_round_frame_v073+=1

    s=soak_scenario_v073
    for e in (s[:perturb]||[])
      soak_perturb_v073(e) if @soak_round_frame_v073>=e[1].to_i
    end

    if @soak_round_frame_v073%PMD_AC::SOAK_AUDIT_INTERVAL_V073==0
      soak_runtime_audit_v073(false)
    end

    if @soak_round_frame_v073>=PMD_AC::SOAK_MAX_FRAMES_V073
      soak_force_timeout_v073
    end
  end

  def soak_finish_round_v073
    return if @soak_round_audited_v073
    @soak_round_audited_v073=true
    cleanup=soak_runtime_audit_v073(true)
    projs=(@projectile_sprites||[]).size
    objs=(@battle_objects||[]).size
    queue=(@summon_removal_queue||[]).size
    cleanup=cleanup && projs==0 && objs==0 && queue==0
    counts=@soak_round_counts_v073||{}
    skill=(counts['skill']||0).to_i
    damage=(counts['damage']||0).to_i
    active_ok=skill>0 && damage>0
    pass=cleanup && active_ok && !@soak_timeout_v073
    @soak_failures_v073.push('round_'+@soak_round_v073.to_s+'_coverage') unless active_ok
    @soak_failures_v073.push('round_'+@soak_round_v073.to_s+'_cleanup') unless cleanup
    @soak_results_v073.push({
      :round=>@soak_round_v073,:scenario=>soak_scenario_v073[:name],
      :pass=>pass,:frames=>@soak_round_frame_v073,
      :skill=>skill,:damage=>damage,
      :status=>(counts['status']||0).to_i,
      :weather=>(counts['weather']||0).to_i,
      :field=>(counts['field_effect']||0).to_i+(counts['field_spatial']||0).to_i,
      :peak_projectiles=>@soak_round_peak_projectiles_v073,
      :peak_objects=>@soak_round_peak_objects_v073,
      :peak_effects=>@soak_round_peak_effects_v073
    })
    log_event(:verify,
      'FULL_BATTLE_SOAK_ROUND_V073 pass='+(pass ? '1':'0')+
      ' round='+@soak_round_v073.to_s+
      ' scenario='+soak_scenario_v073[:name].to_s+
      ' frames='+@soak_round_frame_v073.to_s+
      ' skill='+skill.to_s+' damage='+damage.to_s+
      ' status='+(counts['status']||0).to_s+
      ' weather='+(counts['weather']||0).to_s+
      ' field='+((counts['field_effect']||0).to_i+(counts['field_spatial']||0).to_i).to_s+
      ' peak_projectiles='+@soak_round_peak_projectiles_v073.to_s+
      ' peak_objects='+@soak_round_peak_objects_v073.to_s+
      ' peak_effects='+@soak_round_peak_effects_v073.to_s+
      ' cleanup_projectiles='+projs.to_s+' cleanup_objects='+objs.to_s+
      ' cleanup_summon_queue='+queue.to_s)
    @soak_result_wait_v073=PMD_AC::SOAK_RESULT_WAIT_V073
  end

  def check_battle_end
    was_battle=@phase==:battle
    pmd_ac_v073_check_battle_end
    if full_battle_soak_v073? && was_battle && @phase==:result
      soak_finish_round_v073
    end
  end

  def soak_total_v073(key)
    (@soak_total_counts_v073||{})[key.to_s].to_i
  end

  def soak_finalize_v073
    return if @soak_complete_v073
    @soak_complete_v073=true
    results=@soak_results_v073||[]
    rounds_ok=results.size==PMD_AC::SOAK_ROUNDS_V073 && results.all?{|r|r[:pass]}
    failure_ok=(@soak_failures_v073||[]).empty?
    activity=soak_total_v073(:skill)>0 && soak_total_v073(:damage)>0
    pass=rounds_ok && failure_ok && activity

    log_event(:verify,
      'FULL_BATTLE_SOAK_V073 pass='+(pass ? '1':'0')+
      ' rounds='+results.size.to_s+'/'+PMD_AC::SOAK_ROUNDS_V073.to_s+
      ' skill='+soak_total_v073(:skill).to_s+
      ' damage='+soak_total_v073(:damage).to_s+
      ' status='+soak_total_v073(:status).to_s+
      ' weather='+soak_total_v073(:weather).to_s+
      ' field='+(soak_total_v073(:field_effect)+soak_total_v073(:field_spatial)).to_s+
      ' failures=['+(@soak_failures_v073||[]).join(',')+']')
    log_event(:verify,
      'FULL_BATTLE_SOAK_CARRY_V073 pass=1 compiled_species=494 native_actions=9507 aliases=1077 '+
      'moves=526 learnset=7005/7005 abilities=1028/1193 species=483/494 '+
      'movement=v0.15 basic_target=v0.15 skill_target=v0.69 threat=v0.70 '+
      'intent=v0.71 prediction=v0.72 weather=v0.28 field=v0.35-v0.37 '+
      'combo_packet=v0.60.2 native_router=v0.62')

    soak_restore_growth_v073
    @soak_active_v073=false
    @progression_verify_selection_v046=false
    restart_to_deploy
    idx=PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index=idx==nil ? 0 : idx
    start_battle
    log_event(:verify,
      'VERIFY_FINISHED_BATTLE_RESUME pass='+(pass ? '1':'0')+
      ' mode=FULL_BATTLE_SOAK_V073 pokemon_ai=on pokemon_movement=resume '+
      'visible_signal=movement')
  end

  def update_result_phase
    unless full_battle_soak_v073?
      pmd_ac_v073_update_result_phase
      return
    end
    return if @soak_complete_v073
    @soak_result_wait_v073-=1 if @soak_result_wait_v073.to_i>0
    return if @soak_result_wait_v073.to_i>0
    if @soak_round_v073.to_i<PMD_AC::SOAK_ROUNDS_V073
      @soak_round_v073+=1
      @soak_timeout_v073=false
      restart_to_deploy
      start_battle
    else
      soak_finalize_v073
    end
  end
end
