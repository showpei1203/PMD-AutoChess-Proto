#==============================================================================
# ■ PMD AutoChess Sprite Targeted Profiler v1.02.24
#------------------------------------------------------------------------------
# 【用途】
#   本腳本承接 v1.02.23 Windows RGSS2 實機結果，專門追查仍存在的少數
#   100ms 級 live battle hitch。v1.02.22 已關閉 Deep / Launch / Status /
#   Damage / Movement 五套高頻 profiler；v1.02.23 Visible Foot memo 又把
#   runtime >=50ms 從 3 次降至 2 次、max_update 從 130ms 降至 112ms，
#   但剩餘停頓仍存在。
#
#   v1.02.21 最後一次完整 component profiler 顯示 100ms 級時間曾落在
#   Sprite_PMDChessUnit#update，因此本版不再修改任何 Sprite 規則，也不再
#   猜測新的 cache。只在 Opening window 結束後掛一支窄範圍 profiler，量測：
#     - sprite_total
#     - sprite_refresh_bitmap
#     - sprite_animation
#     - sprite_position
#     - sprite_bar
#     - sprite_damage_popup
#     - sprite_skill_popup
#     - sprite_status_notice
#   讓下一份 Windows LOG 能直接指出 100ms 級停頓落在哪個 presentation 子段。
#
# 【主要設定項】
#   MOTION_SPRITE_PROBE_V10224_ENABLED
#     true  = PMD_MOTION_PHASE_A_V102 runtime 開啟此診斷。
#     false = 完整退回 v1.02.23 Lean Runtime。
#
#   MOTION_SPRITE_PROBE_SLOW_MS_V10224
#     4ms 以上計入 slow 統計。
#
#   MOTION_SPRITE_PROBE_HOT_MS_V10224
#     20ms 以上才建立 hot record，避免 profiler 自己大量製造 Array/String。
#
# 【機制規則】
#   1. Opening 0～64 frame 不啟用，因目前 opening >=50ms 已穩定為 0；只追
#      真正尚未封口的 runtime hitch。
#   2. 只量測既有方法執行時間。所有 wrapper 最後都呼叫 v1.02.23 以前的
#      原方法，回傳值與副作用保持不變。
#   3. 不重寫 Sprite update 流程、不改 update 順序、不略過 UI 更新。
#   4. stats 只更新既有 Array/Fixnum；hot record 僅在 >=20ms 時建立且最多 48 筆。
#   5. v1.02.22 已停用的五套 micro profiler 保持停用，不會重新一起啟動。
#
# 【可調參數】
#   本版只有 profiler threshold 可調，沒有任何遊戲平衡數值。
#
# 【事件／腳本呼叫方式】
#   無需事件呼叫。正式測試：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥
#
# 【實際範例】
#   開場預期：
#     MOTION_SPRITE_TARGETED_PROFILER_V10224 pass=1 ...
#   戰後預期：
#     MOTION_SPRITE_MICRO_SUMMARY_V10224 stats=[...]
#     MOTION_SPRITE_MICRO_HOT_V10224 frame=... kind=sprite_position ms=...
#     MOTION_HITCH_SPLIT_V1026 ...
#     VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【判讀】
#   - sprite_position 接近 sprite_total：下一版只處理 Position chain。
#   - sprite_animation 接近 sprite_total：追 frame/src_rect/Walk cadence。
#   - popup/bar/skill/status 接近 total：追 Bitmap draw / UI first-touch。
#   - sprite_total >=50ms、所有子項都很低：停頓落在未包覆的 Sprite#update
#     外層／Ruby runtime pause，停止繼續拆已量測子方法。
#
# 【不可變更】
#   - Damage Formula / Attack Speed / AI。
#   - Spatial Runtime logical x/y、Move Speed、Adaptive Close。
#   - PMD action、hitFrame、Hurt ownership、hit-stop、Skill FX handoff。
#   - Visible Baseline / Target Anchor / HP Bar Y / Sprite scale。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_SpriteTargetedProfiler_v10224'] = true

module PMD_AC
  MOTION_SPRITE_PROBE_VERSION_V10224 = '1.02.24'
  MOTION_SPRITE_PROBE_V10224_ENABLED = true
  MOTION_SPRITE_PROBE_SLOW_MS_V10224 = 4
  MOTION_SPRITE_PROBE_HOT_MS_V10224 = 20
  MOTION_SPRITE_PROBE_MAX_RECORDS_V10224 = 48
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10224_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10224_prepare_verification_battle)
  alias pmd_ac_v10224_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10224_update_verification_script)
  alias pmd_ac_v10224_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10224_motion_perf_log_summary_v1023)

  def motion_sprite_probe_mode_v10224?
    return false unless PMD_AC::MOTION_SPRITE_PROBE_V10224_ENABLED
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_sprite_probe_reset_v10224
    @motion_sprite_probe_stats_v10224 = {}
    @motion_sprite_probe_records_v10224 = []
    @motion_sprite_probe_verify_logged_v10224 = false
    @motion_sprite_probe_summary_logged_v10224 = false
    true
  end

  def prepare_verification_battle
    result = pmd_ac_v10224_prepare_verification_battle
    motion_sprite_probe_reset_v10224 if verification_mode == :pmd_motion_phase_a_v102
    result
  end

  def motion_sprite_probe_enable_v10224
    return false unless motion_sprite_probe_mode_v10224?
    (@unit_sprites || []).each do |sp|
      next if sp == nil
      next unless sp.respond_to?(:motion_sprite_probe_enable_v10224)
      sp.motion_sprite_probe_enable_v10224(self)
    end
    true
  rescue
    false
  end

  def motion_sprite_probe_note_v10224(kind, ms, unit)
    st = @motion_sprite_probe_stats_v10224[kind]
    if st == nil
      st = [0,0,0,0]
      @motion_sprite_probe_stats_v10224[kind] = st
    end
    st[0] += 1
    st[1] += ms.to_i
    st[2] = ms.to_i if ms.to_i > st[2].to_i
    st[3] += 1 if ms.to_i >= PMD_AC::MOTION_SPRITE_PROBE_SLOW_MS_V10224
    if ms.to_i >= PMD_AC::MOTION_SPRITE_PROBE_HOT_MS_V10224 &&
       @motion_sprite_probe_records_v10224.size < PMD_AC::MOTION_SPRITE_PROBE_MAX_RECORDS_V10224
      frame = @battle_started_frame == nil ? 0 : Graphics.frame_count - @battle_started_frame
      label = unit == nil ? '-' : unit.log_name.to_s
      action = unit == nil ? '-' : unit.action.to_s + '/' + unit.visual_action.to_s
      @motion_sprite_probe_records_v10224.push([frame,kind,ms.to_i,label,action])
    end
    true
  rescue
    false
  end

  def verify_motion_sprite_probe_v10224
    return if @motion_sprite_probe_verify_logged_v10224
    enabled = motion_sprite_probe_enable_v10224
    lean = respond_to?(:motion_perf_lean_live_v10222?) && motion_perf_lean_live_v10222?
    pass = motion_sprite_probe_mode_v10224? && enabled && lean
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_SPRITE_TARGETED_PROFILER_V10224 pass=' + (pass ? '1' : '0') +
      ' opening_probe=0 runtime_probe=1 children=refresh,animation,position,bar,damage_popup,skill_popup,status_notice' +
      ' deep_profiler=0 launch_micro=0 status_micro=0 damage_micro=0 movement_micro=0' +
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_sprite_probe_verify_logged_v10224 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10224_update_verification_script
    if verification_mode == :pmd_motion_phase_a_v102 && @verification_frame.to_i >= 65
      verify_motion_sprite_probe_v10224
    end
    result
  end

  def motion_sprite_probe_log_summary_v10224
    return if @motion_sprite_probe_summary_logged_v10224
    return unless motion_sprite_probe_mode_v10224?
    @motion_sprite_probe_summary_logged_v10224 = true
    rows = []
    @motion_sprite_probe_stats_v10224.each do |kind,st|
      calls = st[0].to_i
      avg = calls <= 0 ? 0 : (st[1].to_i / calls)
      rows.push([st[2].to_i,kind.to_s + ':max' + st[2].to_i.to_s + '/avg' + avg.to_s + '/slow' + st[3].to_i.to_s + '/calls' + calls.to_s])
    end
    rows.sort!{|a,b| b[0] <=> a[0]}
    log_event(:perf,
      'MOTION_SPRITE_MICRO_SUMMARY_V10224 records=' + @motion_sprite_probe_records_v10224.size.to_s +
      ' stats=[' + rows.collect{|r|r[1]}.join(',') + ']')
    @motion_sprite_probe_records_v10224.each do |r|
      log_event(:perf,
        'MOTION_SPRITE_MICRO_HOT_V10224 frame=' + r[0].to_s +
        ' kind=' + r[1].to_s + ' ms=' + r[2].to_s +
        ' unit=' + r[3].to_s + ' action=' + r[4].to_s)
    end
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10224_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_sprite_probe_log_summary_v10224
    end
    result
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v10224_update update unless method_defined?(:pmd_ac_v10224_update)
  alias pmd_ac_v10224_refresh_action_bitmap refresh_action_bitmap unless method_defined?(:pmd_ac_v10224_refresh_action_bitmap)
  alias pmd_ac_v10224_update_animation update_animation unless method_defined?(:pmd_ac_v10224_update_animation)
  alias pmd_ac_v10224_update_position update_position unless method_defined?(:pmd_ac_v10224_update_position)
  alias pmd_ac_v10224_update_bar update_bar unless method_defined?(:pmd_ac_v10224_update_bar)
  alias pmd_ac_v10224_update_popup update_popup unless method_defined?(:pmd_ac_v10224_update_popup)
  alias pmd_ac_v10224_update_skill_popup update_skill_popup unless method_defined?(:pmd_ac_v10224_update_skill_popup)
  alias pmd_ac_v10224_update_status_debug update_status_debug unless method_defined?(:pmd_ac_v10224_update_status_debug)

  def motion_sprite_probe_enable_v10224(scene)
    @motion_sprite_probe_scene_v10224 = scene
    @motion_sprite_probe_enabled_v10224 = true
    true
  end

  def motion_sprite_probe_record_elapsed_v10224(kind, started)
    return unless @motion_sprite_probe_enabled_v10224
    s = @motion_sprite_probe_scene_v10224
    return if s == nil
    ms = ((Time.now.to_f - started.to_f) * 1000.0).round rescue 0
    s.motion_sprite_probe_note_v10224(kind,ms,@unit)
    true
  rescue
    false
  end

  def update
    return pmd_ac_v10224_update unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update
    motion_sprite_probe_record_elapsed_v10224(:sprite_total,t)
    result
  end

  def refresh_action_bitmap(force)
    return pmd_ac_v10224_refresh_action_bitmap(force) unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_refresh_action_bitmap(force)
    motion_sprite_probe_record_elapsed_v10224(:sprite_refresh_bitmap,t)
    result
  end

  def update_animation
    return pmd_ac_v10224_update_animation unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update_animation
    motion_sprite_probe_record_elapsed_v10224(:sprite_animation,t)
    result
  end

  def update_position
    return pmd_ac_v10224_update_position unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update_position
    motion_sprite_probe_record_elapsed_v10224(:sprite_position,t)
    result
  end

  def update_bar
    return pmd_ac_v10224_update_bar unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update_bar
    motion_sprite_probe_record_elapsed_v10224(:sprite_bar,t)
    result
  end

  def update_popup
    return pmd_ac_v10224_update_popup unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update_popup
    motion_sprite_probe_record_elapsed_v10224(:sprite_damage_popup,t)
    result
  end

  def update_skill_popup
    return pmd_ac_v10224_update_skill_popup unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update_skill_popup
    motion_sprite_probe_record_elapsed_v10224(:sprite_skill_popup,t)
    result
  end

  def update_status_debug
    return pmd_ac_v10224_update_status_debug unless @motion_sprite_probe_enabled_v10224
    t = Time.now.to_f
    result = pmd_ac_v10224_update_status_debug
    motion_sprite_probe_record_elapsed_v10224(:sprite_status_notice,t)
    result
  end
end
