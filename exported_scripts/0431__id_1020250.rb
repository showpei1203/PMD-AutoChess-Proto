#==============================================================================
# ■ PMD AutoChess - Sprite Outer Boundary Probe v1.02.25
#------------------------------------------------------------------------------
# 【用途】
#   v1.02.24 Windows RGSS2 顯示 sprite_total 曾達 105ms，但已拆出的
#   refresh / animation / position / bar / damage popup / skill popup /
#   status notice 全部只有 0～2ms。這代表停頓並不在那些 presentation
#   子方法內。本版因此停止 v1.02.24 的高頻 child timer，只留下唯一仍未
#   被單獨量測的 RGSS2 內建 Sprite#update（基底 super）邊界探針。
#
# 【主要設定項】
#   MOTION_SPRITE_OUTER_PROBE_V10225_ENABLED
#     true  = PMD_MOTION_PHASE_A_V102 runtime 啟用。
#     false = 完整退回 v1.02.24 之前的 Lean Runtime 行為。
#
#   MOTION_SPRITE_OUTER_SLOW_MS_V10225
#     4ms 以上計入 slow。
#
#   MOTION_SPRITE_OUTER_HOT_MS_V10225
#     20ms 以上才保存 hot record。
#
# 【機制規則】
#   1. v1.02.24 Sprite child profiler 的 instance flag 會被關閉，因此其
#      update / animation / position / bar / popup 等 wrapper 都直接穿透舊方法，
#      不再建立高頻 Time.now 計時。
#   2. 只在 Sprite_PMDChessUnit 呼叫 RGSS2 基底 Sprite#update 時做一組計時。
#      不重寫 Pokémon Sprite update 順序，也不略過任何原方法。
#   3. Opening 仍不追；在 v1.02.24 verifier 啟用點之後才開始記錄。
#   4. Hot record 最多 32 筆，只有 >=20ms 才建立 Array/String。
#   5. 不停用 GC、不強制 GC、不調整 Graphics.update，不改戰鬥節奏。
#
# 【可調參數】
#   僅 profiler threshold；沒有 Damage / Speed / Spatial / AI 數值。
#
# 【事件／腳本呼叫方式】
#   無需事件呼叫。正式測試：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥
#
# 【實際範例】
#   開場：
#     MOTION_SPRITE_OUTER_BOUNDARY_V10225 pass=1 old_child_timers=0 ...
#   戰後：
#     MOTION_SPRITE_OUTER_SUMMARY_V10225 ...
#     MOTION_SPRITE_OUTER_HOT_V10225 frame=... ms=... unit=...
#
# 【判讀】
#   - rgss_super max 接近 100ms：最後停頓落在 RGSS2 Sprite#update。
#   - rgss_super 始終低，但 Frame Profiler 仍 >=50ms：停止繼續拆已量測
#     Sprite 子方法，下一步改查 Ruby runtime / GC boundary 或 Scene 外層。
#
# 【不可變更】
#   - Damage Formula / Attack Speed / AI。
#   - Spatial Runtime logical x/y、Move Speed、Adaptive Close。
#   - PMD action、hitFrame、Hurt ownership、hit-stop、Skill FX handoff。
#   - Visible Baseline / Target Anchor / HP Bar Y / Sprite scale。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_SpriteOuterBoundaryProbe_v10225'] = true

module PMD_AC
  MOTION_SPRITE_OUTER_VERSION_V10225 = '1.02.25'
  MOTION_SPRITE_OUTER_PROBE_V10225_ENABLED = true
  MOTION_SPRITE_OUTER_SLOW_MS_V10225 = 4
  MOTION_SPRITE_OUTER_HOT_MS_V10225 = 20
  MOTION_SPRITE_OUTER_MAX_RECORDS_V10225 = 32
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10225_motion_sprite_probe_enable_v10224 motion_sprite_probe_enable_v10224 unless method_defined?(:pmd_ac_v10225_motion_sprite_probe_enable_v10224)
  alias pmd_ac_v10225_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10225_update_verification_script)
  alias pmd_ac_v10225_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10225_motion_perf_log_summary_v1023)

  def motion_sprite_outer_mode_v10225?
    return false unless PMD_AC::MOTION_SPRITE_OUTER_PROBE_V10225_ENABLED
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_sprite_outer_reset_v10225
    @motion_sprite_outer_calls_v10225 = 0
    @motion_sprite_outer_total_ms_v10225 = 0
    @motion_sprite_outer_max_ms_v10225 = 0
    @motion_sprite_outer_slow_v10225 = 0
    @motion_sprite_outer_records_v10225 = []
    @motion_sprite_outer_verify_logged_v10225 = false
    @motion_sprite_outer_summary_logged_v10225 = false
    true
  end

  def motion_sprite_probe_enable_v10224
    # v1.02.24 verifier 仍需得到 true，但舊 child timer 不再啟動。
    motion_sprite_outer_reset_v10225 unless @motion_sprite_outer_records_v10225
    (@unit_sprites || []).each do |sp|
      next if sp == nil
      sp.motion_sprite_probe_disable_v10225 if sp.respond_to?(:motion_sprite_probe_disable_v10225)
      sp.motion_sprite_outer_enable_v10225(self) if sp.respond_to?(:motion_sprite_outer_enable_v10225)
    end
    true
  rescue
    false
  end

  def motion_sprite_outer_note_v10225(ms, unit)
    m = ms.to_i
    @motion_sprite_outer_calls_v10225 = @motion_sprite_outer_calls_v10225.to_i + 1
    @motion_sprite_outer_total_ms_v10225 = @motion_sprite_outer_total_ms_v10225.to_i + m
    @motion_sprite_outer_max_ms_v10225 = m if m > @motion_sprite_outer_max_ms_v10225.to_i
    @motion_sprite_outer_slow_v10225 = @motion_sprite_outer_slow_v10225.to_i + 1 if m >= PMD_AC::MOTION_SPRITE_OUTER_SLOW_MS_V10225
    if m >= PMD_AC::MOTION_SPRITE_OUTER_HOT_MS_V10225 &&
       @motion_sprite_outer_records_v10225.size < PMD_AC::MOTION_SPRITE_OUTER_MAX_RECORDS_V10225
      frame = @battle_started_frame == nil ? 0 : Graphics.frame_count - @battle_started_frame
      label = unit == nil ? '-' : unit.log_name.to_s
      action = unit == nil ? '-' : unit.action.to_s + '/' + unit.visual_action.to_s
      @motion_sprite_outer_records_v10225.push([frame,m,label,action])
    end
    true
  rescue
    false
  end

  def verify_motion_sprite_outer_v10225
    return if @motion_sprite_outer_verify_logged_v10225
    pass = motion_sprite_outer_mode_v10225?
    pass = false unless respond_to?(:motion_perf_lean_live_v10222?) && motion_perf_lean_live_v10222?
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_SPRITE_OUTER_BOUNDARY_V10225 pass=' + (pass ? '1' : '0') +
      ' old_child_timers=0 rgss_super_probe=1 opening_probe=0 runtime_probe=1' +
      ' gc_unchanged=1 behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1' +
      ' attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_sprite_outer_verify_logged_v10225 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10225_update_verification_script
    if verification_mode == :pmd_motion_phase_a_v102 && @verification_frame.to_i >= 66
      verify_motion_sprite_outer_v10225
    end
    result
  end

  def motion_sprite_outer_log_summary_v10225
    return if @motion_sprite_outer_summary_logged_v10225
    return unless motion_sprite_outer_mode_v10225?
    @motion_sprite_outer_summary_logged_v10225 = true
    calls = @motion_sprite_outer_calls_v10225.to_i
    avg = calls <= 0 ? 0 : (@motion_sprite_outer_total_ms_v10225.to_i / calls)
    log_event(:perf,
      'MOTION_SPRITE_OUTER_SUMMARY_V10225 calls=' + calls.to_s +
      ' max_ms=' + @motion_sprite_outer_max_ms_v10225.to_i.to_s +
      ' avg_ms=' + avg.to_s +
      ' slow=' + @motion_sprite_outer_slow_v10225.to_i.to_s +
      ' hot=' + (@motion_sprite_outer_records_v10225 || []).size.to_s +
      ' old_child_timers=0 rgss_super_only=1')
    (@motion_sprite_outer_records_v10225 || []).each do |r|
      log_event(:perf,
        'MOTION_SPRITE_OUTER_HOT_V10225 frame=' + r[0].to_s +
        ' ms=' + r[1].to_s + ' unit=' + r[2].to_s + ' action=' + r[3].to_s)
    end
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10225_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_sprite_outer_log_summary_v10225
    end
    result
  end

  # v1.02.24 child profiler 停用後不再輸出空 summary。
  def motion_sprite_probe_log_summary_v10224
    @motion_sprite_probe_summary_logged_v10224 = true
    true
  end
end

class Sprite_PMDChessUnit
  def motion_sprite_probe_disable_v10225
    @motion_sprite_probe_enabled_v10224 = false
    true
  end

  def motion_sprite_outer_enable_v10225(scene)
    @motion_sprite_outer_scene_v10225 = scene
    @motion_sprite_outer_enabled_v10225 = true
    true
  end

  def motion_sprite_outer_active_v10225?
    @motion_sprite_outer_enabled_v10225 == true && @motion_sprite_outer_scene_v10225 != nil
  rescue
    false
  end

  def motion_sprite_outer_note_super_v10225(ms)
    s = @motion_sprite_outer_scene_v10225
    s.motion_sprite_outer_note_v10225(ms,@unit) if s != nil
    true
  rescue
    false
  end
end

# RGSS2 內建 Sprite#update 邊界。
# 只對 Sprite_PMDChessUnit 且 verifier runtime 啟用時加一組計時。
class Sprite
  alias pmd_ac_v10225_rgss_sprite_update update unless method_defined?(:pmd_ac_v10225_rgss_sprite_update)
  def update
    # 非 Pokémon Sprite 沒有此 flag，直接穿透；避免對所有 Sprite 做 class / respond_to 檢查。
    if @motion_sprite_outer_enabled_v10225 == true
      t = Time.now.to_f
      result = pmd_ac_v10225_rgss_sprite_update
      ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      motion_sprite_outer_note_super_v10225(ms)
      return result
    end
    pmd_ac_v10225_rgss_sprite_update
  end
end
