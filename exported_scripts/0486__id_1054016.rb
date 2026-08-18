# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Batch IX Visual Harness Performance Isolation v1.04.16
#==============================================================================
# 【用途】
# v1.04.15 已讓 Batch IX Windows Visual Acceptance Harness 正確自動啟動，但
# Harness 的 74 張代表動畫會在 verifier 完成後以每 frame 2 張的方式增量載入。
# 這些 Bitmap 是「人工視覺驗收專用資源」，不屬於正式 3v3 battle runtime；然而
# v1.02.3 Frame Profiler 仍把 Harness loading 算進正式 Performance Seal，導致
# v1.04.15 Windows LOG 出現 max_update=61ms / pass=0，與 Harness 自己宣告的
# performance_acceptance_non_authoritative=1 互相矛盾。本層只修正驗收隔離。
#
# 【主要設定】
# - Harness active 時暫停 v1.02.3 Frame Profiler capture。
# - 同步使 v1.02.3 late-bitmap、v1.02.6 hitch split、v1.02.29 hitch attribution、
#   v1.03.15 max-spike forensic 不接收 Harness frame。
# - Harness 結束時只重設 profiler 的 prev-update timestamp，避免把整段人工展示時間
#   誤記成一個超長 wall gap。
# - 正式 battle 開始前、Harness 前、Harness 完成後的 battle frame 仍照常計時。
#
# 【機制規則】
# 1. 只在 motion_batchix_visual_harness_active_v10414? == true 時停用 capture。
# 2. 不改 50ms threshold，不刪除 Performance Seal，不偽造既有 counters。
# 3. Harness 的 Bitmap 仍真的載入、真的播放；只是不把這段 verifier-only 工作當成
#    正式 Combat runtime 的效能樣本。
# 4. Harness 結束後立即恢復原 v1.02.3 capture，正式戰鬥後半段繼續受 50ms Seal。
# 5. Damage / AI / Attack Speed / Energy / logical x/y / velocity / action_timer / Hitstop
#    / Hurt / Faint / Projectile / Zone / Skill Banner 全部不修改。
#
# 【可調參數】
# 無。這是 acceptance contract isolation，不提供 threshold 或 gameplay tuning。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。正常流程：
# 1. Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat 匯入素材。
# 2. PMD Motion verifier -> Shift 開戰。
# 3. verifier 完成後 Harness 自動播放 13 頁。
# 4. LOG 應看到 MOTION_BATCHIX_VISUAL_PERF_ISOLATION_V10416 pass=1。
# 5. 最後 MOTION_PERFORMANCE_SEAL_V10229 只代表正式 battle runtime。
#
# 【實際範例】
# v1.04.15 的 Scratch-Anim / Bite-Anim 在 Harness prewarm 中可各花 9~35ms，兩張同
# frame 時甚至造成 61ms update。v1.04.16 仍完整載入並展示這些圖片，但這些 frame
# 不再污染正式 3v3 battle 的 Performance Seal。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BatchIXVisualHarness_PerformanceIsolation_v10416']=true

class Scene_PMD_AutoChess
  alias pmd_ac_v10416_motion_perf_capture_active_v1023 motion_perf_capture_active_v1023 unless method_defined?(:pmd_ac_v10416_motion_perf_capture_active_v1023)
  alias pmd_ac_v10416_motion_batchix_visual_update_v10414 motion_batchix_visual_update_v10414 unless method_defined?(:pmd_ac_v10416_motion_batchix_visual_update_v10414)
  alias pmd_ac_v10416_motion_batchix_visual_finish_v10414 motion_batchix_visual_finish_v10414 unless method_defined?(:pmd_ac_v10416_motion_batchix_visual_finish_v10414)
  alias pmd_ac_v10416_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10416_motion_perf_log_summary_v1023)

  # v1.02.3 與後續所有 profiler 都以此 gate 判斷是否收集 frame / bitmap 樣本。
  # Harness 是 verifier-only 人工展示，因此 active 期間直接沿用同一 authority 關閉。
  def motion_perf_capture_active_v1023?
    if respond_to?(:motion_batchix_visual_harness_active_v10414?) &&
       motion_batchix_visual_harness_active_v10414?
      @motion_batchix_visual_perf_isolation_seen_v10416=true
      return false
    end
    pmd_ac_v10416_motion_perf_capture_active_v1023
  rescue
    pmd_ac_v10416_motion_perf_capture_active_v1023
  end

  # 每個 Harness update 只記一次 frame 數，純供 LOG 證明隔離範圍。
  def motion_batchix_visual_update_v10414
    if motion_batchix_visual_harness_active_v10414?
      @motion_batchix_visual_perf_excluded_frames_v10416=
        @motion_batchix_visual_perf_excluded_frames_v10416.to_i+1
    end
    pmd_ac_v10416_motion_batchix_visual_update_v10414
  end

  # Harness 完成時重新建立 profiler wall-time 邊界。只讀一次 Time.now，不增加
  # 高頻 profiler；下一個正式 battle frame 會從這個新邊界繼續量測。
  def motion_batchix_visual_finish_v10414(ok,reason)
    was_active=motion_batchix_visual_harness_active_v10414?
    result=pmd_ac_v10416_motion_batchix_visual_finish_v10414(ok,reason)
    if was_active
      @motion_perf_prev_update_time_v1023=Time.now.to_f
      unless @motion_batchix_visual_perf_isolation_logged_v10416
        @motion_batchix_visual_perf_isolation_logged_v10416=true
        log_event(:verify,'MOTION_BATCHIX_VISUAL_PERF_ISOLATION_V10416 pass=1'+
          ' excluded_frames='+@motion_batchix_visual_perf_excluded_frames_v10416.to_i.to_s+
          ' frame_profiler_paused=1 bitmap_profiler_paused=1 hitch_split_paused=1'+
          ' hitch_attribution_paused=1 max_spike_forensic_paused=1'+
          ' post_harness_capture_resumed=1 prev_update_boundary_reset=1'+
          ' threshold_ms=50 performance_seal_retained=1'+
          ' harness_rendering_unchanged=1 gameplay_unchanged=1')
      end
    end
    result
  rescue
    result
  end

  # 若戰鬥因其他流程結束，也留下 isolation contract marker；不修改父層 summary。
  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10416_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023 &&
       @motion_batchix_visual_perf_isolation_seen_v10416 &&
       !@motion_batchix_visual_perf_summary_v10416
      @motion_batchix_visual_perf_summary_v10416=true
      log_event(:perf,'MOTION_BATCHIX_VISUAL_PERF_ISOLATION_SUMMARY_V10416'+
        ' excluded_frames='+@motion_batchix_visual_perf_excluded_frames_v10416.to_i.to_s+
        ' harness_frames_excluded_from_formal_seal=1'+
        ' formal_runtime_frames_still_profiled=1 threshold_ms=50')
    end
    result
  rescue
    result
  end
end
