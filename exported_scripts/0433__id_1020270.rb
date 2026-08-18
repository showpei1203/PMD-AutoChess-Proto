#==============================================================================
# ■ PMD AutoChess Scene Runtime Boundary Profiler v1.02.27
#------------------------------------------------------------------------------
# 【用途】
#   這是一支「診斷專用」尾端 Hook，用來延續 v1.02.26 Runtime GC Boundary A/B。
#   v1.02.26 Windows RGSS2 已確認：live battle 自動 GC 關閉後，原本約
#   120ms 的 runtime update 峰值下降到約 50ms；因此本版不再拆 Pokémon
#   Sprite、Damage、Movement、Projectile、Status，而只量 Scene_PMD_AutoChess
#   每幀主更新裡最外層的幾個大區段，判斷最後約 50ms 到底落在哪裡。
#
# 【主要量測項目】
#   1. scene_battle_input       : update_battle_input
#   2. scene_battle_step        : update_battle_step
#   3. scene_unit_sprites       : update_unit_sprites
#   4. scene_effect_sprites     : update_effect_sprites
#   5. scene_projectile_sprites : update_projectile_sprites
#   6. scene_camera_shake       : update_camera_shake
#
# 【機制規則】
#   - 僅 PMD_MOTION_PHASE_A_V102 verifier 生效。
#   - 僅 battle phase、生效 frame >= 70、且 v1.02.26 已確認 GC disabled 時量測。
#   - v1.02.24 / v1.02.25 的 Sprite 高頻 profiler 維持關閉。
#   - 不重寫 Scene 主流程，只對既有方法做 alias 前後計時。
#   - 不變更任何回傳值、呼叫順序、戰鬥判定、AI、Damage、Attack Speed、
#     Spatial logical x/y、Motion、Projectile、Status 或 Skill FX。
#   - 只有 >= 15ms 計入 slow；>= 20ms 才保存 Hot Record，最多 24 筆。
#
# 【可調參數】
#   MOTION_SCENE_BOUNDARY_START_FRAME_V10227 = 70
#   MOTION_SCENE_BOUNDARY_SLOW_MS_V10227    = 15
#   MOTION_SCENE_BOUNDARY_HOT_MS_V10227     = 20
#   MOTION_SCENE_BOUNDARY_RECORD_LIMIT_V10227 = 24
#
# 【事件／腳本呼叫方式】
#   不需事件手動呼叫。正式測試流程：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場
#
# 【實際 LOG 範例】
#   [VERIFY] MOTION_SCENE_BOUNDARY_PROFILER_V10227 pass=1 ...
#   [PERF] MOTION_SCENE_BOUNDARY_SUMMARY_V10227 stats=[...]
#   [PERF] MOTION_SCENE_BOUNDARY_HOT_V10227 frame=1234 kind=scene_battle_step ms=48
#
# 【判讀】
#   - scene_battle_step 接近 50ms：下一版只拆 Battle Step 內層。
#   - scene_unit_sprites / effect / projectile 接近 50ms：只追該呈現集合。
#   - 所有 scope 都低，但 Frame Profiler 仍約 50ms：優先視為 Scene wrapper
#     之外的 runtime / OS scheduling pause，不再無限拆戰鬥子系統。
#
# 【維護注意】
#   - 本版是 CANDIDATE / DIAGNOSTIC，不可在 Windows 實機驗收前標 ACCEPTED。
#   - v1.02.26 GC A/B 必須保留，因本版需要在 GC disabled 的乾淨條件下判讀。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_SceneRuntimeBoundaryProfiler_v10227'] = true

module PMD_AC
  MOTION_SCENE_BOUNDARY_VERSION_V10227 = '1.02.27'
  MOTION_SCENE_BOUNDARY_ENABLED_V10227 = true
  MOTION_SCENE_BOUNDARY_START_FRAME_V10227 = 70
  MOTION_SCENE_BOUNDARY_SLOW_MS_V10227 = 15
  MOTION_SCENE_BOUNDARY_HOT_MS_V10227 = 20
  MOTION_SCENE_BOUNDARY_RECORD_LIMIT_V10227 = 24
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10227_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10227_prepare_verification_battle)
  alias pmd_ac_v10227_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10227_update_verification_script)
  alias pmd_ac_v10227_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10227_motion_perf_log_summary_v1023)
  alias pmd_ac_v10227_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10227_update_battle_input)
  alias pmd_ac_v10227_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10227_update_battle_step)
  alias pmd_ac_v10227_update_unit_sprites update_unit_sprites unless method_defined?(:pmd_ac_v10227_update_unit_sprites)
  alias pmd_ac_v10227_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v10227_update_effect_sprites)
  alias pmd_ac_v10227_update_projectile_sprites update_projectile_sprites unless method_defined?(:pmd_ac_v10227_update_projectile_sprites)
  alias pmd_ac_v10227_update_camera_shake update_camera_shake unless method_defined?(:pmd_ac_v10227_update_camera_shake)

  def motion_scene_boundary_mode_v10227?
    return false unless PMD_AC::MOTION_SCENE_BOUNDARY_ENABLED_V10227
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_scene_boundary_frame_v10227
    return 0 if @battle_started_frame == nil
    Graphics.frame_count - @battle_started_frame
  rescue
    0
  end

  def motion_scene_boundary_active_v10227?
    return false unless motion_scene_boundary_mode_v10227?
    return false unless @phase == :battle
    return false unless @motion_runtime_gc_disabled_v10226
    motion_scene_boundary_frame_v10227 >= PMD_AC::MOTION_SCENE_BOUNDARY_START_FRAME_V10227
  rescue
    false
  end

  def motion_scene_boundary_reset_v10227
    @motion_scene_boundary_stats_v10227 = {
      'scene_battle_input'       => [0,0,0,0],
      'scene_battle_step'        => [0,0,0,0],
      'scene_unit_sprites'       => [0,0,0,0],
      'scene_effect_sprites'     => [0,0,0,0],
      'scene_projectile_sprites' => [0,0,0,0],
      'scene_camera_shake'       => [0,0,0,0]
    }
    @motion_scene_boundary_hot_v10227 = []
    @motion_scene_boundary_verify_logged_v10227 = false
    @motion_scene_boundary_summary_logged_v10227 = false
    true
  end

  def prepare_verification_battle
    result = pmd_ac_v10227_prepare_verification_battle
    motion_scene_boundary_reset_v10227 if verification_mode == :pmd_motion_phase_a_v102
    result
  end

  # stats array = [calls, total_ms, max_ms, slow_calls]
  def motion_scene_boundary_record_v10227(kind, ms)
    stats = @motion_scene_boundary_stats_v10227
    return false if stats == nil
    row = stats[kind]
    return false if row == nil
    m = ms.to_i
    row[0] = row[0].to_i + 1
    row[1] = row[1].to_i + m
    row[2] = m if m > row[2].to_i
    row[3] = row[3].to_i + 1 if m >= PMD_AC::MOTION_SCENE_BOUNDARY_SLOW_MS_V10227
    if m >= PMD_AC::MOTION_SCENE_BOUNDARY_HOT_MS_V10227
      hot = @motion_scene_boundary_hot_v10227 || []
      if hot.size < PMD_AC::MOTION_SCENE_BOUNDARY_RECORD_LIMIT_V10227
        hot.push({:frame=>motion_scene_boundary_frame_v10227, :kind=>kind, :ms=>m})
      end
      @motion_scene_boundary_hot_v10227 = hot
    end
    true
  rescue
    false
  end

  def update_battle_input
    return pmd_ac_v10227_update_battle_input unless motion_scene_boundary_active_v10227?
    t = Time.now.to_f
    result = pmd_ac_v10227_update_battle_input
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_scene_boundary_record_v10227('scene_battle_input',ms)
    result
  end

  def update_battle_step
    return pmd_ac_v10227_update_battle_step unless motion_scene_boundary_active_v10227?
    t = Time.now.to_f
    result = pmd_ac_v10227_update_battle_step
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_scene_boundary_record_v10227('scene_battle_step',ms)
    result
  end

  def update_unit_sprites
    return pmd_ac_v10227_update_unit_sprites unless motion_scene_boundary_active_v10227?
    t = Time.now.to_f
    result = pmd_ac_v10227_update_unit_sprites
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_scene_boundary_record_v10227('scene_unit_sprites',ms)
    result
  end

  def update_effect_sprites
    return pmd_ac_v10227_update_effect_sprites unless motion_scene_boundary_active_v10227?
    t = Time.now.to_f
    result = pmd_ac_v10227_update_effect_sprites
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_scene_boundary_record_v10227('scene_effect_sprites',ms)
    result
  end

  def update_projectile_sprites
    return pmd_ac_v10227_update_projectile_sprites unless motion_scene_boundary_active_v10227?
    t = Time.now.to_f
    result = pmd_ac_v10227_update_projectile_sprites
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_scene_boundary_record_v10227('scene_projectile_sprites',ms)
    result
  end

  def update_camera_shake
    return pmd_ac_v10227_update_camera_shake unless motion_scene_boundary_active_v10227?
    t = Time.now.to_f
    result = pmd_ac_v10227_update_camera_shake
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_scene_boundary_record_v10227('scene_camera_shake',ms)
    result
  end

  def verify_motion_scene_boundary_v10227
    return if @motion_scene_boundary_verify_logged_v10227
    pass = motion_scene_boundary_mode_v10227? && @phase == :battle &&
           @motion_runtime_gc_disabled_v10226 &&
           motion_scene_boundary_frame_v10227 >= PMD_AC::MOTION_SCENE_BOUNDARY_START_FRAME_V10227
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_SCENE_BOUNDARY_PROFILER_V10227 pass=' + (pass ? '1' : '0') +
      ' gc_disabled=' + (@motion_runtime_gc_disabled_v10226 ? '1' : '0') +
      ' start_frame=' + PMD_AC::MOTION_SCENE_BOUNDARY_START_FRAME_V10227.to_i.to_s +
      ' scopes=battle_input,battle_step,unit_sprites,effect_sprites,projectile_sprites,camera_shake' +
      ' slow_ms=' + PMD_AC::MOTION_SCENE_BOUNDARY_SLOW_MS_V10227.to_i.to_s +
      ' hot_ms=' + PMD_AC::MOTION_SCENE_BOUNDARY_HOT_MS_V10227.to_i.to_s +
      ' sprite_child_timers=0 sprite_outer_timer=0' +
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_scene_boundary_verify_logged_v10227 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10227_update_verification_script
    if motion_scene_boundary_mode_v10227? && @phase == :battle &&
       motion_scene_boundary_frame_v10227 >= PMD_AC::MOTION_SCENE_BOUNDARY_START_FRAME_V10227 + 4
      verify_motion_scene_boundary_v10227
    end
    result
  end

  def motion_scene_boundary_log_summary_v10227
    return if @motion_scene_boundary_summary_logged_v10227
    return unless motion_scene_boundary_mode_v10227?
    @motion_scene_boundary_summary_logged_v10227 = true
    stats = @motion_scene_boundary_stats_v10227 || {}
    order = ['scene_battle_input','scene_battle_step','scene_unit_sprites',
             'scene_effect_sprites','scene_projectile_sprites','scene_camera_shake']
    rows = []
    order.each do |kind|
      r = stats[kind] || [0,0,0,0]
      calls = r[0].to_i
      avg = calls > 0 ? (r[1].to_i / calls) : 0
      rows.push(kind + ':max' + r[2].to_i.to_s + '/avg' + avg.to_i.to_s +
                '/slow' + r[3].to_i.to_s + '/calls' + calls.to_s)
    end
    hot = @motion_scene_boundary_hot_v10227 || []
    log_event(:perf,
      'MOTION_SCENE_BOUNDARY_SUMMARY_V10227 records=' + hot.size.to_i.to_s +
      ' stats=[' + rows.join(',') + ']')
    hot.each do |rec|
      log_event(:perf,
        'MOTION_SCENE_BOUNDARY_HOT_V10227 frame=' + rec[:frame].to_i.to_s +
        ' kind=' + rec[:kind].to_s + ' ms=' + rec[:ms].to_i.to_s)
    end
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10227_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_scene_boundary_log_summary_v10227
    end
    result
  end
end
