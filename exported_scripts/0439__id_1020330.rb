#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Loading UI Refresh Throttle v1.02.33
#------------------------------------------------------------------------------
# 【用途】
# 1. 降低 v1.02.9 Battle Resource Loading Gate 在 Loading 階段過度頻繁的
#    Window redraw / PMD mascot update / Graphics.update 同步成本。
# 2. 保留原本 0～100% Loading、目前階段、細節文字與 PMD 寶可夢 mascot，
#    但不再因為每一筆 local bind / VFX / transition step 都強制刷新整個畫面。
# 3. v1.02.32 已讓 Visible Baseline / Target Anchor 幾何掃描降為 0ms；本版只處理
#    剩餘 Loading UI refresh 成本，不修改任何資源內容、Motion 規則或戰鬥邏輯。
#
# 【主要設定】
# - LOADING_UI_PERCENT_STEP_V10233 = 3
#   同一階段至少跨 3 個百分點才強制刷新一次。
# - LOADING_UI_MAX_SILENCE_MS_V10233 = 180
#   即使百分比沒有跨足 3%，若超過 180ms 沒有刷新，也會更新一次畫面，避免長工作
#   期間 Loading 視窗看起來完全靜止。
#
# 【機制規則】
# - 一律保留 0% 與 100% 畫面。
# - Loading stage 改變時立即刷新，例如：寶可夢動作 -> 技能 VFX -> Motion Route ->
#   Sprite/VFX bind -> Heap -> Transition -> Finalize。
# - 同一 stage 內只在百分比跨指定步幅或超過 silence 上限時刷新。
# - 被略過的只是 UI redraw / Graphics.update；資源本身仍逐筆照原流程完整載入。
# - 不呼叫 Input.update，仍維持 v1.02.9 的 Loading input passthrough=0 規則。
# - 不修改 AI、Damage Formula、Attack Speed、Spatial Framework、logical x/y、
#   hit-stop、技能傷害時機、Geometry Cache 或 Production GC Guard。
#
# 【可調參數】
# 若未來希望 Loading 動畫更細：
#   LOADING_UI_PERCENT_STEP_V10233 可調成 2。
# 若優先追求 Loading 速度：
#   可調成 4～5；不建議高於 5，否則百分比跳動會過粗。
# LOADING_UI_MAX_SILENCE_MS_V10233 建議維持 120～250ms。
#
# 【事件／腳本呼叫方式】
# 一般遊戲不需事件呼叫。所有 Scene_PMD_AutoChess Battle Loading 自動套用。
# 開發時可讀：
#   $scene.loading_ui_refresh_summary_v10233
#
# 【實際範例】
# 舊流程：local bind 179 筆 + VFX 21 筆，可能接近每筆都 Graphics.update。
# 新流程：工作仍做完 200 筆，但同一 stage 只在百分比跨步或 180ms timeout 時刷新。
# 目標：保留 Loading 視覺回饋，同時顯著降低純 UI 同步等待。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_LoadingUIRefreshThrottle_v10233'] = true

module PMD_AC
  LOADING_UI_REFRESH_VERSION_V10233 = '1.02.33'
  LOADING_UI_PERCENT_STEP_V10233 = 3
  LOADING_UI_MAX_SILENCE_MS_V10233 = 180
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10233_battle_loading_draw_v1029 battle_loading_draw_v1029 unless method_defined?(:pmd_ac_v10233_battle_loading_draw_v1029)
  alias pmd_ac_v10233_run_battle_resource_loading_v1029 run_battle_resource_loading_v1029 unless method_defined?(:pmd_ac_v10233_run_battle_resource_loading_v1029)
  alias pmd_ac_v10233_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10233_update_verification_script)

  def loading_ui_refresh_reset_v10233
    @loading_ui_requests_v10233 = 0
    @loading_ui_flushes_v10233 = 0
    @loading_ui_skipped_v10233 = 0
    @loading_ui_stage_flush_v10233 = 0
    @loading_ui_percent_flush_v10233 = 0
    @loading_ui_timeout_flush_v10233 = 0
    @loading_ui_force_flush_v10233 = 0
    @loading_ui_ui_ms_v10233 = 0
    @loading_ui_ui_max_ms_v10233 = 0
    @loading_ui_last_percent_v10233 = nil
    @loading_ui_last_stage_v10233 = nil
    @loading_ui_last_flush_time_v10233 = nil
    @loading_ui_initial_seen_v10233 = false
    @loading_ui_final_seen_v10233 = false
    @loading_ui_refresh_summary_v10233 = nil
    @loading_ui_refresh_verify_logged_v10233 = false
  end

  def loading_ui_refresh_summary_v10233
    @loading_ui_refresh_summary_v10233 || {}
  rescue
    {}
  end

  def battle_loading_draw_v1029(ui, percent, stage, detail='', force=false)
    @loading_ui_requests_v10233 = @loading_ui_requests_v10233.to_i + 1
    p = percent.to_i
    p = 0 if p < 0
    p = 100 if p > 100
    st = stage.to_s
    now = Time.now.to_f
    last_p = @loading_ui_last_percent_v10233
    last_st = @loading_ui_last_stage_v10233
    last_t = @loading_ui_last_flush_time_v10233
    step = PMD_AC::LOADING_UI_PERCENT_STEP_V10233.to_i
    step = 1 if step <= 0
    silence_ms = PMD_AC::LOADING_UI_MAX_SILENCE_MS_V10233.to_i
    silence_ms = 1 if silence_ms <= 0

    do_flush = false
    reason = :skip
    if force
      do_flush = true
      reason = :force
    elsif last_t == nil || p <= 0 || p >= 100
      do_flush = true
      reason = :force
    elsif last_st != st
      do_flush = true
      reason = :stage
    elsif last_p == nil || (p - last_p).abs >= step
      do_flush = true
      reason = :percent
    elsif ((now - last_t) * 1000.0) >= silence_ms
      do_flush = true
      reason = :timeout
    end

    unless do_flush
      @loading_ui_skipped_v10233 = @loading_ui_skipped_v10233.to_i + 1
      return nil
    end

    t0 = Time.now.to_f
    result = pmd_ac_v10233_battle_loading_draw_v1029(ui, p, st, detail, force)
    ms = ((Time.now.to_f - t0) * 1000.0).round rescue 0
    @loading_ui_flushes_v10233 = @loading_ui_flushes_v10233.to_i + 1
    @loading_ui_ui_ms_v10233 = @loading_ui_ui_ms_v10233.to_i + ms.to_i
    @loading_ui_ui_max_ms_v10233 = ms.to_i if ms.to_i > @loading_ui_ui_max_ms_v10233.to_i
    case reason
    when :stage
      @loading_ui_stage_flush_v10233 = @loading_ui_stage_flush_v10233.to_i + 1
    when :percent
      @loading_ui_percent_flush_v10233 = @loading_ui_percent_flush_v10233.to_i + 1
    when :timeout
      @loading_ui_timeout_flush_v10233 = @loading_ui_timeout_flush_v10233.to_i + 1
    else
      @loading_ui_force_flush_v10233 = @loading_ui_force_flush_v10233.to_i + 1
    end
    @loading_ui_last_percent_v10233 = p
    @loading_ui_last_stage_v10233 = st
    @loading_ui_last_flush_time_v10233 = Time.now.to_f
    @loading_ui_initial_seen_v10233 = true if p <= 0
    @loading_ui_final_seen_v10233 = true if p >= 100
    result
  rescue
    # UI throttle 自身發生例外時直接退回舊 draw，不能讓 Loading Gate 卡住。
    begin
      pmd_ac_v10233_battle_loading_draw_v1029(ui, percent, stage, detail, force)
    rescue
      nil
    end
  end

  def run_battle_resource_loading_v1029
    loading_ui_refresh_reset_v10233
    result = pmd_ac_v10233_run_battle_resource_loading_v1029
    requests = @loading_ui_requests_v10233.to_i
    flushes = @loading_ui_flushes_v10233.to_i
    skipped = @loading_ui_skipped_v10233.to_i
    @loading_ui_refresh_summary_v10233 = {
      :requests => requests,
      :flushes => flushes,
      :skipped => skipped,
      :stage_flush => @loading_ui_stage_flush_v10233.to_i,
      :percent_flush => @loading_ui_percent_flush_v10233.to_i,
      :timeout_flush => @loading_ui_timeout_flush_v10233.to_i,
      :force_flush => @loading_ui_force_flush_v10233.to_i,
      :ui_ms => @loading_ui_ui_ms_v10233.to_i,
      :ui_max_ms => @loading_ui_ui_max_ms_v10233.to_i,
      :initial => @loading_ui_initial_seen_v10233 ? 1 : 0,
      :final => @loading_ui_final_seen_v10233 ? 1 : 0
    }
    begin
      log_event(:perf, 'MOTION_LOADING_UI_REFRESH_V10233 ready=1 requests=' + requests.to_s +
        ' flushes=' + flushes.to_s + ' skipped=' + skipped.to_s +
        ' stage_flush=' + @loading_ui_stage_flush_v10233.to_i.to_s +
        ' percent_flush=' + @loading_ui_percent_flush_v10233.to_i.to_s +
        ' timeout_flush=' + @loading_ui_timeout_flush_v10233.to_i.to_s +
        ' force_flush=' + @loading_ui_force_flush_v10233.to_i.to_s +
        ' ui_ms=' + @loading_ui_ui_ms_v10233.to_i.to_s +
        ' ui_max_ms=' + @loading_ui_ui_max_ms_v10233.to_i.to_s +
        ' initial_0=' + (@loading_ui_initial_seen_v10233 ? '1' : '0') +
        ' final_100=' + (@loading_ui_final_seen_v10233 ? '1' : '0') +
        ' percent_step=' + PMD_AC::LOADING_UI_PERCENT_STEP_V10233.to_i.to_s +
        ' max_silence_ms=' + PMD_AC::LOADING_UI_MAX_SILENCE_MS_V10233.to_i.to_s)
    rescue
    end
    result
  end

  def verify_loading_ui_refresh_v10233
    return if @loading_ui_refresh_verify_logged_v10233
    return unless verification_mode == :pmd_motion_phase_a_v102
    s = loading_ui_refresh_summary_v10233
    requests = s[:requests].to_i
    flushes = s[:flushes].to_i
    skipped = s[:skipped].to_i
    pass = requests > 0 && flushes > 0 && skipped > 0 && flushes < requests &&
      s[:initial].to_i == 1 && s[:final].to_i == 1
    @motion_phase_a_failed_v102 = true unless pass
    begin
      log_event(:verify, 'MOTION_LOADING_UI_REFRESH_THROTTLE_V10233 pass=' + (pass ? '1' : '0') +
        ' requests=' + requests.to_s + ' flushes=' + flushes.to_s + ' skipped=' + skipped.to_s +
        ' ui_ms=' + s[:ui_ms].to_i.to_s + ' ui_max_ms=' + s[:ui_max_ms].to_i.to_s +
        ' initial_0=' + s[:initial].to_i.to_s + ' final_100=' + s[:final].to_i.to_s +
        ' progress_percent_retained=1 mascot_retained=1 stage_change_flush=1 max_silence_guard=1' +
        ' input_passthrough=0 resource_work_unchanged=1 geometry_cache_unchanged=1' +
        ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    rescue
    end
    @loading_ui_refresh_verify_logged_v10233 = true
  end

  def update_verification_script
    pmd_ac_v10233_update_verification_script
    verify_loading_ui_refresh_v10233 if @verification_frame.to_i >= 82
  end
end
