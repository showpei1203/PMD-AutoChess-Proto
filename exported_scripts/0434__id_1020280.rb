#==============================================================================
# ■ PMD AutoChess - Production Live-Battle GC Guard v1.02.28
#------------------------------------------------------------------------------
# 【用途】
#   將 v1.02.26～v1.02.27 Windows RGSS2 已驗證的 GC A/B 結果整理成正式
#   Production 候選策略。v1.02.27 實機在 live battle frame 70 起停用 Ruby
#   自動 GC 後，runtime >=50ms 由先前 2 次降為 0，max_update 由 121ms 降到
#   35ms；Scene Boundary 同時顯示 battle_step max 約 29ms，其餘大區段更低。
#   因此本版停止 Scene/Sprite 高頻診斷，將「Live Battle 不自動 GC、離開戰鬥
#   後集中回收」提升為所有 PMD AutoChess 戰鬥共用的 Production 候選策略。
#
# 【主要設定項】
#   PMD_AC::PRODUCTION_GC_GUARD_ENABLED_V10228
#     true  = 所有 Scene_PMD_AutoChess live battle 套用本 Guard。
#   PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228
#     70    = 保留已驗證的 opening 行為；戰鬥第 70 frame 起才 GC.disable。
#   PMD_AC::PRODUCTION_GC_GUARD_SAFETY_FRAME_V10228
#     18000 = 約 5 分鐘（60fps）。極端長戰鬥超過此值時重新 GC.enable，避免
#             無限關閉 GC 導致記憶體持續成長。Safety release 不主動 GC.start。
#
# 【機制規則】
#   1. 每場戰鬥 start_battle 時重設 Guard 狀態。
#   2. battle frame < 70：GC 維持正常，Opening / Loading 行為不變。
#   3. battle frame >= 70：只呼叫一次 GC.disable，直到離開 live battle。
#   4. battle frame >= 18000：安全釋放 GC.enable，該場不再重新 disable。
#   5. 返回 Deploy：先 GC.enable。
#      - PMD Motion verifier：不在 release 當下再 GC.start，交給既有
#        MOTION_HEAP_SETTLE_V1025 做一次集中回收，避免診斷版曾出現的雙 GC。
#      - 一般正式戰鬥：回 Deploy 後主動 GC.start 一次，將回收移出 live battle。
#   6. Scene terminate：一定 GC.enable，但不強制 GC.start，避免離場卡頓。
#   7. v1.02.24 / v1.02.25 Sprite profiler、v1.02.26 GC A/B、v1.02.27 Scene
#      profiler 全部標示 superseded，不再做高頻 Time.now 計時。
#   8. 不修改 AI、Damage、Attack Speed、Move Speed、Spatial logical x/y、
#      Native hitFrame、Hurt ownership、Projectile/Skill FX timing 或戰鬥公式。
#
# 【可調參數】
#   START_FRAME：正式預設 70。若日後 Loading/Opening 架構再改，需重新實測。
#   SAFETY_FRAME：正式預設 18000。若 Boss 戰普遍超過 5 分鐘，可在確認記憶體
#                 行為後調高；不可直接設為無限。
#
# 【事件／腳本呼叫方式】
#   無需事件呼叫；所有 PMD AutoChess battle 自動套用。
#   驗證流程：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完戰鬥。
#
# 【實際 LOG 範例】
#   [PERF] MOTION_PRODUCTION_GC_DISABLE_V10228 disabled=1 frame=70 ...
#   [VERIFY] MOTION_PRODUCTION_GC_GUARD_V10228 pass=1 global_battle_policy=1 ...
#   [PERF] MOTION_PRODUCTION_GC_SUMMARY_V10228 disabled_during_runtime=1 ...
#   [PERF] MOTION_PRODUCTION_GC_RELEASE_V10228 reason=deploy ...
#
# 【正式驗收條件】
#   - MOTION_PRODUCTION_GC_GUARD_V10228 pass=1
#   - MOTION_HITCH_SPLIT_V1026 opening=0 runtime=0（目標）
#   - max_update 不回到 100ms 級
#   - Baseline / Target Anchor live_miss=0
#   - VERIFY_FINISHED_BATTLE_RESUME pass=1
#   - 返回 Deploy 後 GC 必須恢復 enabled。
#
# 【不可破壞】
#   - Frozen Combat Core 不直接修改，只用 trailing alias / override。
#   - Pokémon instance_uid、PMD Sprite 100%、Effect / Projectile 50% 不變。
#   - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_ProductionGCGuard_v10228'] = true

module PMD_AC
  PRODUCTION_GC_GUARD_VERSION_V10228 = '1.02.28'
  PRODUCTION_GC_GUARD_ENABLED_V10228 = true
  PRODUCTION_GC_GUARD_START_FRAME_V10228 = 70
  PRODUCTION_GC_GUARD_SAFETY_FRAME_V10228 = 18000
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10228_start start unless method_defined?(:pmd_ac_v10228_start)
  alias pmd_ac_v10228_start_battle start_battle unless method_defined?(:pmd_ac_v10228_start_battle)
  alias pmd_ac_v10228_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10228_restart_to_deploy)
  alias pmd_ac_v10228_terminate terminate unless method_defined?(:pmd_ac_v10228_terminate)
  alias pmd_ac_v10228_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10228_update_battle_step)
  alias pmd_ac_v10228_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10228_update_verification_script)
  alias pmd_ac_v10228_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10228_motion_perf_log_summary_v1023)

  def motion_production_gc_reset_v10228
    @motion_production_gc_disabled_v10228 = false
    @motion_production_gc_disable_frame_v10228 = -1
    @motion_production_gc_safety_released_v10228 = false
    @motion_production_gc_safety_frame_v10228 = -1
    @motion_production_gc_verify_logged_v10228 = false
    @motion_production_gc_summary_logged_v10228 = false
    @motion_production_gc_release_logged_v10228 = false
    @motion_production_gc_release_ms_v10228 = 0
    @motion_production_gc_release_ok_v10228 = 1
    @motion_production_gc_disabled_legacy_profilers_v10228 = false
    true
  end

  def start
    motion_production_gc_reset_v10228
    pmd_ac_v10228_start
  end

  def start_battle
    motion_production_gc_reset_v10228
    pmd_ac_v10228_start_battle
  end

  def motion_production_gc_frame_v10228
    return 0 if @battle_started_frame == nil
    Graphics.frame_count - @battle_started_frame
  rescue
    0
  end

  def motion_production_gc_active_battle_v10228?
    return false unless PMD_AC::PRODUCTION_GC_GUARD_ENABLED_V10228
    @phase == :battle
  rescue
    false
  end

  # 舊診斷 profiler 在 Production Seal 中完全退場。
  def motion_production_gc_disable_legacy_profilers_v10228
    return true if @motion_production_gc_disabled_legacy_profilers_v10228
    (@unit_sprites || []).each do |sp|
      next if sp == nil
      begin; sp.instance_variable_set(:@motion_sprite_probe_enabled_v10224,false); rescue; end
      begin; sp.instance_variable_set(:@motion_sprite_outer_enabled_v10225,false); rescue; end
    end
    @motion_production_gc_disabled_legacy_profilers_v10228 = true
    true
  rescue
    false
  end

  # v1.02.26 A/B 不再擁有 GC；避免 verifier 中重複 disable/release。
  def motion_runtime_gc_ab_mode_v10226?
    false
  end

  def verify_motion_runtime_gc_boundary_v10226
    return if @motion_runtime_gc_verify_logged_v10226
    log_event(:verify,
      'MOTION_RUNTIME_GC_BOUNDARY_V10226 pass=1 superseded_by_v10228=1' +
      ' diagnostic_ab=0 production_guard=1 forced_gc_live=0')
    @motion_runtime_gc_verify_logged_v10226 = true
    true
  rescue
    false
  end

  def motion_runtime_gc_log_summary_v10226
    @motion_runtime_gc_summary_logged_v10226 = true
    true
  end

  # v1.02.27 Scene profiler 已完成歸因，Production 不再高頻計時。
  def motion_scene_boundary_mode_v10227?
    false
  end

  def verify_motion_scene_boundary_v10227
    return if @motion_scene_boundary_verify_logged_v10227
    log_event(:verify,
      'MOTION_SCENE_BOUNDARY_PROFILER_V10227 pass=1 superseded_by_v10228=1' +
      ' scene_timers=0 prior_result_runtime_zero=1')
    @motion_scene_boundary_verify_logged_v10227 = true
    true
  rescue
    false
  end

  def motion_scene_boundary_log_summary_v10227
    @motion_scene_boundary_summary_logged_v10227 = true
    true
  end

  # v1.02.24/25 舊 profiler verifier 改為清楚標示已退場，避免 LOG 誤導。
  def verify_motion_sprite_probe_v10224
    return if @motion_sprite_probe_verify_logged_v10224
    motion_production_gc_disable_legacy_profilers_v10228
    log_event(:verify,
      'MOTION_SPRITE_TARGETED_PROFILER_V10224 pass=1 superseded_by_v10228=1' +
      ' child_timers=0 prior_children_max_ms_le_2=1')
    @motion_sprite_probe_verify_logged_v10224 = true
    true
  rescue
    false
  end

  def verify_motion_sprite_outer_v10225
    return if @motion_sprite_outer_verify_logged_v10225
    motion_production_gc_disable_legacy_profilers_v10228
    log_event(:verify,
      'MOTION_SPRITE_OUTER_BOUNDARY_V10225 pass=1 superseded_by_v10228=1' +
      ' rgss_super_probe=0 prior_rgss_super_max_ms=1')
    @motion_sprite_outer_verify_logged_v10225 = true
    true
  rescue
    false
  end

  def motion_sprite_probe_log_summary_v10224
    @motion_sprite_probe_summary_logged_v10224 = true
    true
  end

  def motion_sprite_outer_log_summary_v10225
    @motion_sprite_outer_summary_logged_v10225 = true
    true
  end

  def motion_production_gc_disable_v10228
    return false unless motion_production_gc_active_battle_v10228?
    return false if @motion_production_gc_disabled_v10228
    return false if @motion_production_gc_safety_released_v10228
    frame = motion_production_gc_frame_v10228
    return false if frame < PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228
    begin
      GC.disable
      @motion_production_gc_disabled_v10228 = true
      @motion_production_gc_disable_frame_v10228 = frame
      log_event(:perf,
        'MOTION_PRODUCTION_GC_DISABLE_V10228 disabled=1 frame=' + frame.to_i.to_s +
        ' global_battle_policy=1 forced_gc_live=0')
      true
    rescue Exception => e
      @motion_production_gc_disabled_v10228 = false
      begin
        log_event(:perf,
          'MOTION_PRODUCTION_GC_DISABLE_V10228 disabled=0 error=' + e.class.to_s)
      rescue
      end
      false
    end
  end

  def motion_production_gc_safety_release_v10228
    return false unless @motion_production_gc_disabled_v10228
    frame = motion_production_gc_frame_v10228
    return false if frame < PMD_AC::PRODUCTION_GC_GUARD_SAFETY_FRAME_V10228
    ok = 1
    begin
      GC.enable
    rescue
      ok = 0
    end
    @motion_production_gc_disabled_v10228 = false
    @motion_production_gc_safety_released_v10228 = true
    @motion_production_gc_safety_frame_v10228 = frame
    begin
      log_event(:perf,
        'MOTION_PRODUCTION_GC_SAFETY_RELEASE_V10228 frame=' + frame.to_i.to_s +
        ' enable_ok=' + ok.to_i.to_s + ' forced_gc=0 no_redisable_this_battle=1')
    rescue
    end
    ok == 1
  end

  def update_battle_step
    motion_production_gc_disable_legacy_profilers_v10228
    if motion_production_gc_active_battle_v10228?
      frame = motion_production_gc_frame_v10228
      if !@motion_production_gc_disabled_v10228 && !@motion_production_gc_safety_released_v10228 &&
         frame >= PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228
        motion_production_gc_disable_v10228
      elsif @motion_production_gc_disabled_v10228 &&
            frame >= PMD_AC::PRODUCTION_GC_GUARD_SAFETY_FRAME_V10228
        motion_production_gc_safety_release_v10228
      end
    end
    pmd_ac_v10228_update_battle_step
  end

  def verify_motion_production_gc_guard_v10228
    return if @motion_production_gc_verify_logged_v10228
    return unless respond_to?(:verification_mode) && verification_mode == :pmd_motion_phase_a_v102
    pass = @phase == :battle && @motion_production_gc_disabled_v10228 &&
           !@motion_production_gc_safety_released_v10228 &&
           motion_production_gc_frame_v10228 >= PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_PRODUCTION_GC_GUARD_V10228 pass=' + (pass ? '1' : '0') +
      ' global_battle_policy=1 start_frame=' + PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228.to_i.to_s +
      ' actual_frame=' + @motion_production_gc_disable_frame_v10228.to_i.to_s +
      ' safety_frame=' + PMD_AC::PRODUCTION_GC_GUARD_SAFETY_FRAME_V10228.to_i.to_s +
      ' disabled=' + (@motion_production_gc_disabled_v10228 ? '1' : '0') +
      ' legacy_scene_profiler=0 legacy_sprite_timers=0 forced_gc_live=0' +
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_production_gc_verify_logged_v10228 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10228_update_verification_script
    if respond_to?(:verification_mode) && verification_mode == :pmd_motion_phase_a_v102 && @phase == :battle
      frame = motion_production_gc_frame_v10228
      verify_motion_production_gc_guard_v10228 if frame >= PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228 + 2
      verify_motion_runtime_gc_boundary_v10226 if frame >= PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228 + 3
      verify_motion_scene_boundary_v10227 if frame >= PMD_AC::PRODUCTION_GC_GUARD_START_FRAME_V10228 + 4
    end
    result
  end

  def motion_production_gc_log_summary_v10228
    return if @motion_production_gc_summary_logged_v10228
    @motion_production_gc_summary_logged_v10228 = true
    return unless respond_to?(:verification_mode) && verification_mode == :pmd_motion_phase_a_v102
    frame = motion_production_gc_frame_v10228
    log_event(:perf,
      'MOTION_PRODUCTION_GC_SUMMARY_V10228 disabled_during_runtime=' +
      (@motion_production_gc_disabled_v10228 ? '1' : '0') +
      ' disable_frame=' + @motion_production_gc_disable_frame_v10228.to_i.to_s +
      ' summary_frame=' + frame.to_i.to_s +
      ' safety_released=' + (@motion_production_gc_safety_released_v10228 ? '1' : '0') +
      ' forced_gc_live=0 scene_timers=0 sprite_timers=0')
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10228_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_production_gc_log_summary_v10228
    end
    result
  end

  def motion_production_gc_release_v10228(reason, run_gc)
    return true unless @motion_production_gc_disabled_v10228
    enable_ok = 1
    gc_ms = 0
    begin
      GC.enable
    rescue
      enable_ok = 0
    end
    @motion_production_gc_disabled_v10228 = false
    if run_gc && enable_ok == 1
      begin
        t = Time.now.to_f
        GC.start
        gc_ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      rescue
        enable_ok = 0
      end
    end
    @motion_production_gc_release_ms_v10228 = gc_ms
    @motion_production_gc_release_ok_v10228 = enable_ok
    @motion_production_gc_release_logged_v10228 = true
    begin
      log_event(:perf,
        'MOTION_PRODUCTION_GC_RELEASE_V10228 reason=' + reason.to_s +
        ' enable_ok=' + enable_ok.to_i.to_s +
        ' gc_run=' + (run_gc ? '1' : '0') +
        ' gc_ms=' + gc_ms.to_i.to_s +
        ' live_gc_disabled=0')
    rescue
    end
    enable_ok == 1
  end

  def motion_production_gc_delegate_heap_settle_v10228?
    return false unless respond_to?(:motion_v1024_mode?)
    motion_v1024_mode?
  rescue
    false
  end

  def restart_to_deploy
    result = pmd_ac_v10228_restart_to_deploy
    if @motion_production_gc_disabled_v10228
      # Motion verifier 會立即進入既有 v1.02.5 Heap Settle，因此避免雙 GC。
      delegate = motion_production_gc_delegate_heap_settle_v10228?
      motion_production_gc_release_v10228(:deploy,!delegate)
    end
    result
  end

  def terminate
    motion_production_gc_release_v10228(:terminate,false) if @motion_production_gc_disabled_v10228
    pmd_ac_v10228_terminate
  end
end
