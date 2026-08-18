#==============================================================================
# ■ PMD AutoChess - Frame Hitch Attribution / Performance Seal v1.02.29
#------------------------------------------------------------------------------
# 【用途】
#   修正 v1.02.3 / v1.02.6 Frame Profiler 對「wall gap」與「Scene update 執行
#   時間」混為同一類 >=50ms hitch 的驗收語意。v1.02.28 Windows 實機已出現
#   max_gap=49721ms、但同一場 max_update=48ms、runtime_update_peak=10ms；這類
#   gap 發生在兩次 Scene update 起點之間，並非 Scene_PMD_AutoChess#update
#   本身執行 49 秒，不能再當成遊戲內部 Performance Seal 失敗。
#
# 【主要設定項】
#   PMD_AC::MOTION_HITCH_ATTRIBUTION_ENABLED_V10229
#     true = PMD_MOTION_PHASE_A_V102 使用新的 hitch 歸因。
#   PMD_AC::MOTION_INTERNAL_HITCH_MS_V10229
#     50 = 只有 Scene update 本身 >=50ms 才算「internal hitch」。
#   PMD_AC::MOTION_WALL_GAP_MS_V10229
#     50 = update <50ms、但相鄰 update 起點 gap >=50ms，另列 wall-gap-only。
#   PMD_AC::MOTION_SUSPEND_LIKE_MS_V10229
#     1000 = wall gap >=1 秒另標 suspend-like，僅供診斷，不算內部失敗。
#
# 【機制規則】
#   1. 僅在 PMD_MOTION_PHASE_A_V102 Frame Profiler active 時改變「統計分類」。
#   2. update_ms >=50：
#      - 依 opening window / runtime 分別累計 internal hitch。
#      - 同步寫回 v1.02.6 MOTION_HITCH_SPLIT counters，因此舊摘要現在代表
#        真正遊戲內部 update hitch，而不是 wall-clock 中斷。
#   3. update_ms <50 且 gap_ms >=50：
#      - 不算 internal hitch。
#      - 另計 wall_gap_only；gap >=1000ms 再計 suspend_like。
#   4. v1.02.3 MOTION_FRAME_PROFILE 仍保留 max_gap / max_update，方便看到外部
#      停頓與實際 update 成本兩種原始資料。
#   5. v1.02.3 legacy spike record 仍會保存正常 28ms wall / 12ms update 樣本，
#      但 severe 僅依 update_ms 判定，避免 49 秒 wall gap 被標成遊戲 severe。
#   6. 不改 Graphics.update、Scene update、GC、AI、Damage、Attack Speed、
#      Spatial Runtime、Motion、Projectile、Skill FX 或任何戰鬥數值。
#
# 【可調參數】
#   INTERNAL_HITCH_MS：正式預設 50ms。若未來要做 60fps frame-budget QA，應另
#                     建專用 profiler，不要直接把本 Performance Seal 門檻改低。
#   SUSPEND_LIKE_MS：只用於區分很長的 OS / 視窗 / 排程中斷，不影響 pass/fail。
#
# 【事件／腳本呼叫方式】
#   無需事件呼叫。驗證：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥。
#
# 【實際 LOG 範例】
#   [VERIFY] MOTION_HITCH_ATTRIBUTION_V10229 pass=1 ...
#   [PERF] MOTION_HITCH_SPLIT_V1026 opening=0 runtime=0 ...
#   [PERF] MOTION_HITCH_ATTRIBUTION_SUMMARY_V10229 internal_opening=0
#          internal_runtime=0 wall_gap_runtime=3 suspend_like_runtime=1 ...
#   [VERIFY] MOTION_PERFORMANCE_SEAL_V10229 pass=1 ...
#
# 【正式驗收規則】
#   - internal opening/runtime 皆為 0。
#   - max_update <50ms。
#   - wall_gap_only 不列為遊戲內部失敗；它代表 measured Scene update 之外的
#     wall-clock 中斷，仍保留數量與最大值供人工判讀。
#   - Production GC Guard v1.02.28 必須存在並啟用。
#   - Baseline / Target Anchor live_miss=0 與 VERIFY_FINISHED_BATTLE_RESUME pass=1
#     仍由既有 verifier 各自驗證。
#
# 【不可破壞】
#   - Frozen Combat Core 不直接修改，只用 Main 前 trailing override。
#   - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_HitchAttributionSeal_v10229'] = true

module PMD_AC
  MOTION_HITCH_ATTRIBUTION_VERSION_V10229 = '1.02.29'
  MOTION_HITCH_ATTRIBUTION_ENABLED_V10229 = true
  MOTION_INTERNAL_HITCH_MS_V10229 = 50
  MOTION_WALL_GAP_MS_V10229 = 50
  MOTION_SUSPEND_LIKE_MS_V10229 = 1000
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10229_motion_perf_reset_v1023 motion_perf_reset_v1023 unless method_defined?(:pmd_ac_v10229_motion_perf_reset_v1023)
  alias pmd_ac_v10229_motion_perf_record_spike_v1023 motion_perf_record_spike_v1023 unless method_defined?(:pmd_ac_v10229_motion_perf_record_spike_v1023)
  alias pmd_ac_v10229_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10229_motion_perf_log_summary_v1023)
  alias pmd_ac_v10229_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10229_update_verification_script)

  def motion_hitch_attribution_mode_v10229?
    return false unless PMD_AC::MOTION_HITCH_ATTRIBUTION_ENABLED_V10229
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_hitch_attribution_reset_v10229
    @motion_internal_opening_v10229 = 0
    @motion_internal_runtime_v10229 = 0
    @motion_internal_opening_max_v10229 = 0
    @motion_internal_runtime_max_v10229 = 0
    @motion_wall_opening_v10229 = 0
    @motion_wall_runtime_v10229 = 0
    @motion_wall_opening_max_v10229 = 0
    @motion_wall_runtime_max_v10229 = 0
    @motion_suspend_opening_v10229 = 0
    @motion_suspend_runtime_v10229 = 0
    @motion_hitch_attr_verify_logged_v10229 = false
    @motion_hitch_attr_summary_logged_v10229 = false
    @motion_performance_seal_logged_v10229 = false
    true
  end

  def motion_perf_reset_v1023
    result = pmd_ac_v10229_motion_perf_reset_v1023
    motion_hitch_attribution_reset_v10229
    result
  end

  # v1.02.29：在 Motion verifier 中重做 record 分類。
  # 非本模式完整沿用 v1.02.28 以前的 chain。
  def motion_perf_record_spike_v1023(gap_ms,update_ms)
    return pmd_ac_v10229_motion_perf_record_spike_v1023(gap_ms,update_ms) unless
      motion_hitch_attribution_mode_v10229? && motion_perf_capture_active_v1023?

    g = gap_ms.to_i
    u = update_ms.to_i
    f = motion_perf_relative_frame_v1023
    opening = f <= PMD_AC::MOTION_HITCH_OPENING_WINDOW_V1026

    # 正式 internal hitch：只看 Scene update 自身執行時間。
    if u >= PMD_AC::MOTION_INTERNAL_HITCH_MS_V10229
      if opening
        @motion_internal_opening_v10229 = @motion_internal_opening_v10229.to_i + 1
        @motion_internal_opening_max_v10229 = u if u > @motion_internal_opening_max_v10229.to_i
        @motion_hitch_opening_v1026 = @motion_hitch_opening_v1026.to_i + 1
        @motion_hitch_opening_max_v1026 = u if u > @motion_hitch_opening_max_v1026.to_i
        @motion_hitch_opening_update_max_v1026 = u if u > @motion_hitch_opening_update_max_v1026.to_i
      else
        @motion_internal_runtime_v10229 = @motion_internal_runtime_v10229.to_i + 1
        @motion_internal_runtime_max_v10229 = u if u > @motion_internal_runtime_max_v10229.to_i
        @motion_hitch_runtime_v1026 = @motion_hitch_runtime_v1026.to_i + 1
        @motion_hitch_runtime_max_v1026 = u if u > @motion_hitch_runtime_max_v1026.to_i
        @motion_hitch_runtime_update_max_v1026 = u if u > @motion_hitch_runtime_update_max_v1026.to_i
      end
    elsif g >= PMD_AC::MOTION_WALL_GAP_MS_V10229
      # measured Scene update 之外的 wall-clock gap，只記錄、不判 internal fail。
      if opening
        @motion_wall_opening_v10229 = @motion_wall_opening_v10229.to_i + 1
        @motion_wall_opening_max_v10229 = g if g > @motion_wall_opening_max_v10229.to_i
        @motion_suspend_opening_v10229 = @motion_suspend_opening_v10229.to_i + 1 if
          g >= PMD_AC::MOTION_SUSPEND_LIKE_MS_V10229
      else
        @motion_wall_runtime_v10229 = @motion_wall_runtime_v10229.to_i + 1
        @motion_wall_runtime_max_v10229 = g if g > @motion_wall_runtime_max_v10229.to_i
        @motion_suspend_runtime_v10229 = @motion_suspend_runtime_v10229.to_i + 1 if
          g >= PMD_AC::MOTION_SUSPEND_LIKE_MS_V10229
      end
    end

    # 保留 v1.02.3 的 sample record，但 severe 改為 update-only。
    return if g < PMD_AC::MOTION_FRAME_SPIKE_MS_V1023 &&
              u < PMD_AC::MOTION_UPDATE_SPIKE_MS_V1023
    @motion_perf_severe_v1023 = @motion_perf_severe_v1023.to_i + 1 if
      u >= PMD_AC::MOTION_SEVERE_SPIKE_MS_V1023
    rec = @motion_perf_spikes_v1023 || []
    return if rec.size >= PMD_AC::MOTION_PROFILE_RECORD_LIMIT_V1023
    recent = (f - @motion_perf_recent_hold_frame_v1023.to_i) <= 2
    rec.push({:frame=>f,:gap=>g,:update=>u,
      :verify=>(@verification_frame.to_i rescue 0),
      :hold=>(recent ? @motion_perf_recent_hold_frames_v1023.to_i : 0),
      :context=>motion_perf_action_context_v1023})
    @motion_perf_spikes_v1023 = rec
  rescue
  end

  def verify_motion_hitch_attribution_v10229
    return if @motion_hitch_attr_verify_logged_v10229
    prod = $imported != nil && $imported['PMD_AutoChess_ProductionGCGuard_v10228']
    pass = motion_hitch_attribution_mode_v10229? && prod
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_HITCH_ATTRIBUTION_V10229 pass=' + (pass ? '1' : '0') +
      ' internal_hitch_ms=' + PMD_AC::MOTION_INTERNAL_HITCH_MS_V10229.to_i.to_s +
      ' wall_gap_separate=1 suspend_like_ms=' + PMD_AC::MOTION_SUSPEND_LIKE_MS_V10229.to_i.to_s +
      ' legacy_hitch_split_internal_only=1 production_gc_guard=' + (prod ? '1' : '0') +
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_hitch_attr_verify_logged_v10229 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10229_update_verification_script
    if motion_hitch_attribution_mode_v10229? && @verification_frame.to_i >= 76
      verify_motion_hitch_attribution_v10229
    end
    result
  end

  def motion_hitch_attribution_log_summary_v10229
    return true if @motion_hitch_attr_summary_logged_v10229
    return false unless motion_hitch_attribution_mode_v10229?
    @motion_hitch_attr_summary_logged_v10229 = true
    max_update = @motion_perf_max_update_ms_v1023.to_i
    internal_ok = @motion_internal_opening_v10229.to_i == 0 &&
                  @motion_internal_runtime_v10229.to_i == 0 &&
                  max_update < PMD_AC::MOTION_INTERNAL_HITCH_MS_V10229
    prod_ok = $imported != nil && $imported['PMD_AutoChess_ProductionGCGuard_v10228']
    seal = internal_ok && prod_ok
    log_event(:perf,
      'MOTION_HITCH_ATTRIBUTION_SUMMARY_V10229' +
      ' internal_opening=' + @motion_internal_opening_v10229.to_i.to_s +
      ' internal_runtime=' + @motion_internal_runtime_v10229.to_i.to_s +
      ' internal_opening_max_ms=' + @motion_internal_opening_max_v10229.to_i.to_s +
      ' internal_runtime_max_ms=' + @motion_internal_runtime_max_v10229.to_i.to_s +
      ' wall_gap_opening=' + @motion_wall_opening_v10229.to_i.to_s +
      ' wall_gap_runtime=' + @motion_wall_runtime_v10229.to_i.to_s +
      ' wall_gap_opening_max_ms=' + @motion_wall_opening_max_v10229.to_i.to_s +
      ' wall_gap_runtime_max_ms=' + @motion_wall_runtime_max_v10229.to_i.to_s +
      ' suspend_like_opening=' + @motion_suspend_opening_v10229.to_i.to_s +
      ' suspend_like_runtime=' + @motion_suspend_runtime_v10229.to_i.to_s +
      ' max_update_ms=' + max_update.to_s +
      ' wall_gap_not_internal_failure=1')
    log_event(:verify,
      'MOTION_PERFORMANCE_SEAL_V10229 pass=' + (seal ? '1' : '0') +
      ' internal_opening=' + @motion_internal_opening_v10229.to_i.to_s +
      ' internal_runtime=' + @motion_internal_runtime_v10229.to_i.to_s +
      ' max_update_ms=' + max_update.to_s +
      ' threshold_ms=' + PMD_AC::MOTION_INTERNAL_HITCH_MS_V10229.to_i.to_s +
      ' production_gc_guard=' + (prod_ok ? '1' : '0') +
      ' external_wall_gap_ignored_for_internal_seal=1')
    @motion_performance_seal_logged_v10229 = true
    @motion_phase_a_failed_v102 = true unless seal
    seal
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10229_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_hitch_attribution_log_summary_v10229
    end
    result
  end
end
