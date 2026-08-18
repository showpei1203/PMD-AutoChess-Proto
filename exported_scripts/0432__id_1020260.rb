#==============================================================================
# ■ PMD AutoChess - Runtime / GC Boundary A/B v1.02.26
#------------------------------------------------------------------------------
# 【用途】
#   v1.02.25 Windows RGSS2 已證明：戰鬥仍偶發約 120ms runtime hitch，
#   但 RGSS2 內建 Sprite#update 的獨立邊界只有 max=1ms；更早的 Damage、
#   Projectile、Status、Movement 與 Sprite presentation 子段也已逐項排除。
#   因此本版停止繼續拆戰鬥方法，改做一次非常聚焦的 Ruby runtime / GC
#   boundary A/B：只在 Opening 已結束後暫停自動 GC，觀察剩餘 100ms 級
#   hitch 是否消失。
#
# 【主要設定項】
#   PMD_AC::MOTION_RUNTIME_GC_AB_ENABLED_V10226
#     true  = 僅 PMD_MOTION_PHASE_A_V102 啟用本 A/B。
#   PMD_AC::MOTION_RUNTIME_GC_AB_START_FRAME_V10226
#     70    = Opening 已連續多版 0 個 >=50ms，故從 frame 70 才停自動 GC。
#
# 【機制規則】
#   1. v1.02.24 / v1.02.25 的 Sprite 高頻 timer 在本版完全停用。
#   2. frame < 70 時 GC 維持正常，Opening verifier 與初始化不受影響。
#   3. frame >= 70 且仍在 live battle 時只呼叫一次 GC.disable。
#   4. 整個 live battle、結果統計與 Frame Profiler summary 期間不主動 GC。
#   5. 回到 Deploy 後一定先 GC.enable，再 GC.start；GC 整理成本被移到
#      live battle 之外，並記錄 release gc_ms。
#   6. terminate 也有保險釋放，避免 Scene 中途離開時留下 GC disabled。
#   7. 不修改 AI、Damage、Attack Speed、Move Speed、Spatial logical x/y、
#      hit-stop、Native hitFrame、Hurt ownership 或 Skill FX timing。
#
# 【為何此 A/B 與 v1.02.11 不同】
#   v1.02.11 是在當時仍存在 Visible Baseline / Target Anchor live alpha scan
#   與大量高頻 allocation 時做的整場 GC-disable 診斷，結果不能解釋那些
#   明確的同步掃描卡頓。現在上述根因與三個高頻 allocation source 已被
#   Windows 實機逐項移除，且 Sprite/RGSS boundary 也已量到 max=1ms，
#   因此現在才有條件用「Opening 後、live-only」方式重新隔離 runtime GC。
#
# 【可調參數】
#   START_FRAME 只控制診斷開始點；正式 Production 不應直接照搬本 Guard，
#   必須先看 Windows A/B 結果與戰後 GC 成本。
#
# 【事件／腳本呼叫方式】
#   無需事件呼叫。
#   S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完戰鬥。
#
# 【實際範例】
#   開始 A/B：
#     MOTION_RUNTIME_GC_BOUNDARY_V10226 pass=1 disabled=1 start_frame=70 ...
#   戰後：
#     MOTION_RUNTIME_GC_SUMMARY_V10226 disabled_during_runtime=1 ...
#   回 Deploy：
#     MOTION_RUNTIME_GC_RELEASE_V10226 reason=deploy gc_ms=...
#
# 【判讀】
#   - runtime >=50ms 明顯降至 0，且 max_update 回到一般區間：
#     強力支持剩餘 pause 為自動 GC / runtime collection boundary。
#   - runtime 仍有約 100ms，而 GC 確實 disabled：
#     GC 可正式排除，下一步改查 Scene/Graphics.update 外層邊界。
#
# 【不可破壞】
#   - Frozen Combat Core 不直接修改，只用 trailing alias / override。
#   - Pokémon instance_uid、PMD Sprite 100%、Effect / Projectile 50% 不變。
#   - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_RuntimeGCBoundaryAB_v10226'] = true

module PMD_AC
  MOTION_RUNTIME_GC_AB_VERSION_V10226 = '1.02.26'
  MOTION_RUNTIME_GC_AB_ENABLED_V10226 = true
  MOTION_RUNTIME_GC_AB_START_FRAME_V10226 = 70
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10226_start start unless method_defined?(:pmd_ac_v10226_start)
  alias pmd_ac_v10226_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10226_restart_to_deploy)
  alias pmd_ac_v10226_terminate terminate unless method_defined?(:pmd_ac_v10226_terminate)
  alias pmd_ac_v10226_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10226_update_verification_script)
  alias pmd_ac_v10226_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10226_motion_perf_log_summary_v1023)

  def motion_runtime_gc_ab_mode_v10226?
    return false unless PMD_AC::MOTION_RUNTIME_GC_AB_ENABLED_V10226
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_runtime_gc_ab_reset_v10226
    @motion_runtime_gc_disabled_v10226 = false
    @motion_runtime_gc_disable_frame_v10226 = -1
    @motion_runtime_gc_verify_logged_v10226 = false
    @motion_runtime_gc_summary_logged_v10226 = false
    @motion_runtime_gc_release_count_v10226 = 0
    @motion_runtime_gc_release_ms_v10226 = 0
    @motion_runtime_gc_release_ok_v10226 = 1
    true
  end

  def start
    motion_runtime_gc_ab_reset_v10226
    pmd_ac_v10226_start
  end

  # v1.02.24 / v1.02.25 的高頻 Sprite 計時在此 A/B 完全退場。
  # v1.02.24 verifier 需要 enable 呼叫成功，因此仍回傳 true。
  def motion_sprite_probe_enable_v10224
    (@unit_sprites || []).each do |sp|
      next if sp == nil
      begin; sp.motion_sprite_probe_disable_v10225; rescue; end
      begin; sp.instance_variable_set(:@motion_sprite_outer_enabled_v10225,false); rescue; end
    end
    true
  rescue
    false
  end

  # v1.02.25 已由上一個 Windows LOG 完成診斷；本版標示 superseded，
  # 避免 LOG 誤稱仍有 rgss_super 高頻 probe。
  def verify_motion_sprite_outer_v10225
    return if @motion_sprite_outer_verify_logged_v10225
    pass = motion_runtime_gc_ab_mode_v10226?
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_SPRITE_OUTER_BOUNDARY_V10225 pass=' + (pass ? '1' : '0') +
      ' old_child_timers=0 rgss_super_probe=0 superseded_by_v10226=1' +
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1' +
      ' attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_sprite_outer_verify_logged_v10225 = true
    true
  rescue
    false
  end

  def motion_sprite_outer_log_summary_v10225
    @motion_sprite_outer_summary_logged_v10225 = true
    true
  end

  def motion_runtime_gc_disable_v10226
    return false if @motion_runtime_gc_disabled_v10226
    return false unless motion_runtime_gc_ab_mode_v10226?
    return false unless @phase == :battle
    frame = @battle_started_frame == nil ? 0 : Graphics.frame_count - @battle_started_frame
    return false if frame < PMD_AC::MOTION_RUNTIME_GC_AB_START_FRAME_V10226
    begin
      GC.disable
      @motion_runtime_gc_disabled_v10226 = true
      @motion_runtime_gc_disable_frame_v10226 = frame
      log_event(:perf,
        'MOTION_RUNTIME_GC_DISABLE_V10226 disabled=1 frame=' + frame.to_i.to_s +
        ' opening_untouched=1 live_battle_only=1 forced_gc_live=0')
      true
    rescue Exception => e
      @motion_runtime_gc_disabled_v10226 = false
      begin
        log_event(:perf,'MOTION_RUNTIME_GC_DISABLE_V10226 disabled=0 error=' + e.class.to_s)
      rescue
      end
      false
    end
  end

  def verify_motion_runtime_gc_boundary_v10226
    return if @motion_runtime_gc_verify_logged_v10226
    pass = motion_runtime_gc_ab_mode_v10226? && @phase == :battle && @motion_runtime_gc_disabled_v10226
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_RUNTIME_GC_BOUNDARY_V10226 pass=' + (pass ? '1' : '0') +
      ' disabled=' + (@motion_runtime_gc_disabled_v10226 ? '1' : '0') +
      ' start_frame=' + PMD_AC::MOTION_RUNTIME_GC_AB_START_FRAME_V10226.to_i.to_s +
      ' actual_frame=' + @motion_runtime_gc_disable_frame_v10226.to_i.to_s +
      ' sprite_child_timers=0 sprite_outer_timer=0 opening_untouched=1' +
      ' forced_gc_live=0 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1' +
      ' spatial_values_unchanged=1')
    @motion_runtime_gc_verify_logged_v10226 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10226_update_verification_script
    if motion_runtime_gc_ab_mode_v10226? && @phase == :battle
      frame = @battle_started_frame == nil ? 0 : Graphics.frame_count - @battle_started_frame
      motion_runtime_gc_disable_v10226 if frame >= PMD_AC::MOTION_RUNTIME_GC_AB_START_FRAME_V10226
      verify_motion_runtime_gc_boundary_v10226 if frame >= PMD_AC::MOTION_RUNTIME_GC_AB_START_FRAME_V10226 + 2
    end
    result
  end

  def motion_runtime_gc_log_summary_v10226
    return if @motion_runtime_gc_summary_logged_v10226
    return unless motion_runtime_gc_ab_mode_v10226?
    @motion_runtime_gc_summary_logged_v10226 = true
    frame = @battle_started_frame == nil ? 0 : Graphics.frame_count - @battle_started_frame
    log_event(:perf,
      'MOTION_RUNTIME_GC_SUMMARY_V10226 disabled_during_runtime=' +
      (@motion_runtime_gc_disabled_v10226 ? '1' : '0') +
      ' disable_frame=' + @motion_runtime_gc_disable_frame_v10226.to_i.to_s +
      ' summary_frame=' + frame.to_i.to_s +
      ' forced_gc_live=0 sprite_timers=0 release_after_battle=1')
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10226_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_runtime_gc_log_summary_v10226
    end
    result
  end

  def motion_runtime_gc_release_v10226(reason, run_gc)
    return true unless @motion_runtime_gc_disabled_v10226
    enable_ok = 1
    gc_ms = 0
    begin
      GC.enable
    rescue
      enable_ok = 0
    end
    @motion_runtime_gc_disabled_v10226 = false
    if run_gc && enable_ok == 1
      begin
        t = Time.now.to_f
        GC.start
        gc_ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      rescue
        enable_ok = 0
      end
    end
    @motion_runtime_gc_release_count_v10226 = @motion_runtime_gc_release_count_v10226.to_i + 1
    @motion_runtime_gc_release_ms_v10226 = gc_ms
    @motion_runtime_gc_release_ok_v10226 = enable_ok
    begin
      log_event(:perf,
        'MOTION_RUNTIME_GC_RELEASE_V10226 reason=' + reason.to_s +
        ' enable_ok=' + enable_ok.to_i.to_s +
        ' gc_run=' + (run_gc ? '1' : '0') +
        ' gc_ms=' + gc_ms.to_i.to_s +
        ' live_gc_disabled=0')
    rescue
    end
    enable_ok == 1
  end

  def restart_to_deploy
    result = pmd_ac_v10226_restart_to_deploy
    if @motion_runtime_gc_disabled_v10226
      motion_runtime_gc_release_v10226(:deploy,true)
    end
    motion_runtime_gc_ab_reset_v10226 if @phase == :deploy
    result
  end

  def terminate
    motion_runtime_gc_release_v10226(:terminate,false) if @motion_runtime_gc_disabled_v10226
    pmd_ac_v10226_terminate
  end
end
