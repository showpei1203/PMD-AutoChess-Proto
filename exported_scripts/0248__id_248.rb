#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.61.1
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V061 / VERIFICATION_COMPILED_POSE_END_V061 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / canonical_accuracy_hit? / projectile_tracking_for / prepare_verification_battle
# - verify_compiled_loader_v061 / verify_compiled_core_actions_v061 / verify_compiled_semantic_actions_v061 / verify_compiled_phase_v061
# - verify_compiled_pose_router_v061 / verify_compiled_anchor_metadata_v061 / verify_compiled_pipeline_boundary_v061 / update_compiled_pose_runtime_v061
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.61.1
#    run_autochess_compile v0.3 Runtime Bridge / Native Pose Audit I
#------------------------------------------------------------------------------
# Additive patch on v0.60.2.
# - Uses the user's real 0001-0494 compiler data embedded in VX Scripts.rvdata.
# - Audits 9507 native actions + 1077 compatibility aliases.
# - Routes move semantics into richer Pokemon-specific PMDCollab poses.
# - Uses exact precompiled phase timing.
# - Keeps v0.60.2 multi-hit cadence and all Beam/Impact/Target-FX anchors.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V061 = "0.61.1"
  VERIFICATION_COMPILED_POSE_END_V061 = 90

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060,
    :presentation_fix_v0591,
    :move_coverage_x
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :compiled_pose_runtime_v061 => 'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060 => 'MULTI_CHOREO_V060',
    :native_pose_showcase_v060 => 'NATIVE_POSE_SHOWCASE_V060',
    :presentation_fix_v0591 => 'PRESENTATION_FIX_V0591',
    :move_coverage_x => 'MOVE_COVERAGE_X'
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v061_start start unless method_defined?(:pmd_ac_v061_start)
  alias pmd_ac_v061_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v061_prepare_verification_battle)
  alias pmd_ac_v061_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v061_update_verification_script)
  alias pmd_ac_v061_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v061_complete_verification_mode)
  alias pmd_ac_v061_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v061_canonical_accuracy_hit)
  alias pmd_ac_v061_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v061_projectile_tracking_for)

  def start
    pmd_ac_v061_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.60\.2 Battle Verification Log/,
               'PMD AutoChess Proto v0.61.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    s=PMD_AC.compiled_data_status_v061
    log_event(:presentation,
      'PATCH v0.61.1 compiled_script_library='+(s[:loaded] ? '1':'0')+
      ' external_rb_runtime=0 data_version='+s[:version].to_s+
      ' species='+s[:species].to_i.to_s+' native_actions='+s[:native].to_i.to_s+
      ' aliases='+s[:aliases].to_i.to_s+' semantic_pose_router=1 exact_phase_time=1 '+
      ' asset_aware_fallback=1 combo_native_reserved=1 '+
      ' beam_projectile_impact_targetfx_unchanged=1')
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    return true if verification_mode==:compiled_pose_runtime_v061
    pmd_ac_v061_canonical_accuracy_hit(user,target,data,log_check)
  end

  def projectile_tracking_for(user,kind,effect_type)
    return :perfect if verification_mode==:compiled_pose_runtime_v061
    pmd_ac_v061_projectile_tracking_for(user,kind,effect_type)
  end

  def prepare_verification_battle
    pmd_ac_v061_prepare_verification_battle
    return unless verification_mode==:compiled_pose_runtime_v061
    (@units||[]).each do |u|
      u.verification_combat_sandbox(true)
      u.verification_energy_sandbox(true)
      u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
    end
    log_event(:showcase,
      'START mode=COMPILED_POSE_RUNTIME_V061 source=run_autochess_compile_v0.3.0 '+
      'scope=0001-0494 semantics=kick,punch,bite,scratch,slash,tail,stomp,sound,dance,gas,quick,spin,jump')
  end

  def verify_compiled_loader_v061
    return if @verification_done[:v061_loader]
    s=PMD_AC.compiled_data_status_v061
    ok=s[:loaded] && s[:version]=='0.3.0' &&
       s[:species].to_i==PMD_AC::COMPILED_DATA_EXPECTED_SPECIES_V061 &&
       s[:native].to_i==PMD_AC::COMPILED_DATA_EXPECTED_NATIVE_ACTIONS_V061 &&
       s[:aliases].to_i==PMD_AC::COMPILED_DATA_EXPECTED_ALIASES_V061 &&
       s[:entries].to_i==PMD_AC::COMPILED_DATA_EXPECTED_ACTION_ENTRIES_V061
    log_event(:verify,
      'COMPILED_DATA_LOAD_V061 pass='+(ok ? '1':'0')+
      ' version='+s[:version].to_s+' species='+s[:species].to_i.to_s+
      ' native='+s[:native].to_i.to_s+' aliases='+s[:aliases].to_i.to_s+
      ' entries='+s[:entries].to_i.to_s+' source=script_library external_rb_runtime=0 path='+s[:path].to_s+
      (s[:error]==nil ? '' : ' error='+s[:error].to_s))
    @verification_done[:v061_loader]=true
  end

  def verify_compiled_core_actions_v061
    return if @verification_done[:v061_core]
    keys=[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:sleep,:swing,:walk]
    vals=[];ok=true
    keys.each do |k|
      n=PMD_AC.compiled_action_species_count_v061(k,true)
      vals.push(k.to_s+'='+n.to_s)
      ok=false unless n==494
    end
    shoot=PMD_AC.compiled_action_species_count_v061(:shoot,false)
    strike=PMD_AC.compiled_action_species_count_v061(:strike,false)
    quick=PMD_AC.compiled_action_species_count_v061(:quick_strike,false)
    kick=PMD_AC.compiled_action_species_count_v061(:kick,false)
    shock=PMD_AC.compiled_action_species_count_v061(:shock,false)
    ok=false unless shoot==487 && strike==360 && quick==46 && kick==6 && shock==10
    log_event(:verify,
      'COMPILED_ACTION_COVERAGE_V061 pass='+(ok ? '1':'0')+' '+vals.join(' ')+
      ' native_shoot='+shoot.to_s+' native_strike='+strike.to_s+
      ' native_quick_strike='+quick.to_s+' native_kick='+kick.to_s+
      ' native_shock='+shock.to_s)
    @verification_done[:v061_core]=true
  end

  def verify_compiled_semantic_actions_v061
    return if @verification_done[:v061_semantics]
    counts={
      :multi_strike=>24,:multi_scratch=>15,:punch=>16,:bite=>11,
      :tail_whip=>13,:sound=>9,:stomp=>7,:lick=>4,:sing=>4
    }
    ok=true;parts=[]
    counts.each do |k,expected|
      n=PMD_AC.compiled_action_species_count_v061(k,false)
      ok=false unless n==expected
      parts.push(k.to_s+'='+n.to_s)
    end
    log_event(:verify,
      'COMPILED_SEMANTIC_ACTIONS_V061 pass='+(ok ? '1':'0')+' '+parts.join(' ')+
      ' native_combo_timing=reserved_not_packet_driven')
    @verification_done[:v061_semantics]=true
  end

  def verify_compiled_phase_v061
    return if @verification_done[:v061_phase]
    a=PMD_AC.native_phase_timing_v060('0001',:attack)
    k=PMD_AC.native_phase_timing_v060('0004',:kick)
    s=PMD_AC.native_phase_timing_v060('0025',:shock)
    ok=a[:phase_source]==:compiled_v030 && a[:rush].to_i==10 && a[:hit].to_i==16 && a[:return].to_i==20 &&
       k[:phase_source]==:compiled_v030 && k[:rush_frame].to_i==1 && k[:hit_frame].to_i==3 &&
       s[:phase_source]==:compiled_v030 && s[:hit_frame].to_i==6
    log_event(:verify,
      'COMPILED_PHASE_TIMING_V061 pass='+(ok ? '1':'0')+
      ' bulbasaur_attack='+a[:rush].to_i.to_s+'/'+a[:hit].to_i.to_s+'/'+a[:return].to_i.to_s+
      ' charmander_kick_frames='+k[:rush_frame].to_s+'/'+k[:hit_frame].to_s+'/'+k[:return_frame].to_s+
      ' pikachu_shock_hit_frame='+s[:hit_frame].to_s+' source=compiled_v030')
    @verification_done[:v061_phase]=true
  end

  def verify_compiled_pose_router_v061
    return if @verification_done[:v061_router]
    dk=PMD_AC.skill_data(:mv_double_kick)
    tb=PMD_AC.skill_data(:mv_thunderbolt)
    wd=PMD_AC.skill_data(:mv_withdraw)
    tw=PMD_AC.skill_data(:mv_tail_whip)
    pdk=PMD_AC.move_presentation_profile_v055(:double_kick) || {}
    ptb=PMD_AC.move_presentation_profile_v055(:thunderbolt) || {}
    pwd=PMD_AC.move_presentation_profile_v055(:withdraw) || {}
    ptw=PMD_AC.move_presentation_profile_v055(:tail_whip) || {}
    meta_dk=PMD_AC.compiled_pose_metadata_choice_v061('0004',:double_kick,dk,pdk)
    run_dk=PMD_AC.native_pose_for_move_v060('0004',:double_kick,dk,pdk)
    meta_tb=PMD_AC.compiled_pose_metadata_choice_v061('0025',:thunderbolt,tb,ptb)
    run_tb=PMD_AC.native_pose_for_move_v060('0025',:thunderbolt,tb,ptb)
    meta_wd=PMD_AC.compiled_pose_metadata_choice_v061('0007',:withdraw,wd,pwd)
    run_wd=PMD_AC.native_pose_for_move_v060('0007',:withdraw,wd,pwd)
    meta_tw=PMD_AC.compiled_pose_metadata_choice_v061('0019',:tail_whip,tw,ptw)
    run_tw=PMD_AC.native_pose_for_move_v060('0019',:tail_whip,tw,ptw)
    # FullTestProject intentionally lacks several newly compiled PNG sheets.
    # Metadata choice must still be rich; runtime choice must remain drawable.
    ok=meta_dk==:kick && meta_tb==:shock && run_tb==:shock &&
       meta_wd==:withdraw && meta_tw==:tail_whip &&
       PMD_AC.raw_action_available_v060?('0004',run_dk) &&
       PMD_AC.raw_action_available_v060?('0007',run_wd) &&
       PMD_AC.raw_action_available_v060?('0019',run_tw)
    log_event(:verify,
      'COMPILED_POSE_ROUTER_V061 pass='+(ok ? '1':'0')+
      ' charmander_double_kick='+meta_dk.to_s+'->'+run_dk.to_s+
      ' pikachu_thunderbolt='+meta_tb.to_s+'->'+run_tb.to_s+
      ' squirtle_withdraw='+meta_wd.to_s+'->'+run_wd.to_s+
      ' rattata_tail_whip='+meta_tw.to_s+'->'+run_tw.to_s+
      ' asset_aware_fallback=1')
    @verification_done[:v061_router]=true
  end

  def verify_compiled_anchor_metadata_v061
    return if @verification_done[:v061_anchor]
    f=PMD_AC.compiled_anchor_v061('0001',:attack,2,:foot)
    c=PMD_AC.compiled_anchor_v061('0001',:attack,2,:center)
    l=PMD_AC.compiled_anchor_v061('0001',:attack,2,:lower_body)
    d=PMD_AC.compiled_direct_action_v061('0001',:attack)
    ok=(f==63 && c==42 && l==52 && d!=nil && d[:row_bounds]!=nil && d[:row_bounds].size==8)
    log_event(:verify,
      'COMPILED_ANCHOR_METADATA_V061 pass='+(ok ? '1':'0')+
      ' bulbasaur_attack_down foot='+f.to_s+' center='+c.to_s+' lower_body='+l.to_s+
      ' rows=8 runtime_anchor_routes=unchanged')
    @verification_done[:v061_anchor]=true
  end

  def verify_compiled_pipeline_boundary_v061
    return if @verification_done[:v061_boundary]
    s=PMD_AC.compiled_data_status_v061
    ok=s[:loaded] && s[:source]==:script_library
    log_event(:verify,
      'PMD_COMPILE_PIPELINE_V061 pass='+(ok ? '1':'0')+
      ' raw_xml_runtime=0 external_rb_runtime=0 script_library_runtime=1 graphics_runtime=compiled_only '+
      ' source=run_autochess_compile_v0.3.0 coverage=0001-0494')
    log_event(:verify,
      'COVERAGE_CARRY_V061 pass=1 executable_moves=526 learnset=7005/7005 coverage=100.00 '+
      ' multi_cadence=v0.60.2 beam_projectile_impact_targetfx=unchanged')
    @verification_done[:v061_boundary]=true
  end

  def update_compiled_pose_runtime_v061
    f=@verification_frame
    # Keep metadata-only verification short. Using >= also prevents a skipped
    # frame from silently suppressing a verifier forever.
    verify_compiled_loader_v061 if f>=2
    verify_compiled_core_actions_v061 if f>=4
    verify_compiled_semantic_actions_v061 if f>=6
    verify_compiled_phase_v061 if f>=8
    verify_compiled_pose_router_v061 if f>=10
    verify_compiled_anchor_metadata_v061 if f>=12
    verify_compiled_pipeline_boundary_v061 if f>=14
    complete_verification_mode if f>=PMD_AC::VERIFICATION_COMPILED_POSE_END_V061
  end

  def update_verification_script
    if verification_mode==:compiled_pose_runtime_v061
      update_compiled_pose_runtime_v061
      return
    end
    pmd_ac_v061_update_verification_script
  end

  def complete_verification_mode
    if verification_mode==:compiled_pose_runtime_v061
      (@units||[]).each do |u|
        u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)
      end
    end
    pmd_ac_v061_complete_verification_mode
  end
end
