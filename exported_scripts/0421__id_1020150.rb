#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Projectile Launch Micro Profiler v1.02.15
# 分類：PMD Motion / Performance Diagnostic
#
# 【用途】
# v1.02.14 Windows RGSS2 實機 LOG 證明：
# - projectile_sprites / projectile_one 已降到約 14ms，飛行期不是目前主因。
# - 但 launch_projectile 仍可達 235ms，且整段時間同步落在
#   resolve_basic_attack -> launch_projectile。
# - v1.02.14 Shared Frame 並未降低該尖峰，且因 :web 等 legacy style 沒有
#   v0.30/v0.31 projectile profile，早期 verifier 會出現 fallback_spawn=1。
#
# 本版不再猜測下一個優化點，而是把「發射函式尚未返回前」切成細項計時，
# 讓下一份 Windows LOG 可以直接指出真正最慢的子區塊。
#
# 【本版機制】
# 1. 暫停 v1.02.14 Shared Frame fast path，回到已知可比較的 v1.02.13
#    projectile 建構路徑。v1.02.14 腳本仍保留在專案中，不刪除、不改原檔。
# 2. 僅在 PMD_MOTION_PHASE_A_V102 live battle 內啟用 launch probe。
# 3. 量測下列子區塊：
#    - launch_total
#    - projectile_initialize
#    - substitute_target
#    - tactical_redirect
#    - ability_redirect
#    - projectile_style
#    - projectile_tracking
#    - effect_anchor
#    - skill_data
#    - projectile_profile
#    - move_visual_profile
#    - launch_log_event
# 4. 戰後輸出統計與最慢 hot records，不改任何 return、Damage、AI、Spatial、
#    projectile hit logic、flight speed、tracking、Attack Speed 或 logical x/y。
#
# 【主要設定】
# PMD_AC::MOTION_LAUNCH_MICRO_V10215_ENABLED
#   true  = 啟用本診斷。
#   false = 完全略過本版 profiler。
#
# PMD_AC::MOTION_LAUNCH_MICRO_SLOW_MS_V10215
#   單一子區塊達此毫秒數時記入 slow count。
#
# PMD_AC::MOTION_LAUNCH_MICRO_HOT_MS_V10215
#   達此毫秒數時保留 hot record，方便直接看到 frame / unit / kind。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。正式測試：
#   S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場
#
# 【Windows LOG 必查】
# MOTION_LAUNCH_MICRO_PROFILER_V10215 pass=1
# MOTION_LAUNCH_MICRO_SUMMARY_V10215 stats=[...]
# MOTION_LAUNCH_MICRO_HOT_V10215 ...
# VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【判讀範例】
# 若 launch_total=120ms，而 skill_data=100ms：下一版只處理 skill_data 呼叫鏈。
# 若 projectile_initialize=110ms：下一版只拆 Projectile initialize 內部。
# 若 substitute_target / ability_redirect 高：只查 redirect path。
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - Frozen Combat Core 不直接修改，僅 trailing alias / hook。
# - Motion 只負責 presentation / profiler，不碰 logical x/y。
# - 本版是診斷候選版，Windows RGSS2 LOG 前不可標 ACCEPTED。
#==============================================================================

module PMD_AC
  MOTION_LAUNCH_MICRO_V10215_ENABLED = true
  MOTION_LAUNCH_MICRO_SLOW_MS_V10215 = 6
  MOTION_LAUNCH_MICRO_HOT_MS_V10215 = 20
  MOTION_LAUNCH_MICRO_HOT_LIMIT_V10215 = 40

  # v1.02.14 實機沒有改善 launch_projectile，且存在合法 legacy fallback。
  # 此處只以 trailing constant override 暫停 fast path，保留原腳本方便 A/B。
  if const_defined?(:MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED)
    remove_const(:MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED)
  end
  MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED = false

  class << self
    def motion_launch_probe_scene_v10215
      @motion_launch_probe_scene_v10215
    end

    def motion_launch_probe_scene_v10215=(scene)
      @motion_launch_probe_scene_v10215 = scene
    end

    alias pmd_ac_v10215_skill_data skill_data unless method_defined?(:pmd_ac_v10215_skill_data)
    def skill_data(key)
      s = @motion_launch_probe_scene_v10215
      return pmd_ac_v10215_skill_data(key) if s == nil ||
        !s.respond_to?(:motion_launch_probe_active_v10215?) ||
        !s.motion_launch_probe_active_v10215?
      t = Time.now.to_f
      r = pmd_ac_v10215_skill_data(key)
      ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      s.motion_launch_probe_record_v10215('skill_data', ms, 'key=' + key.to_s) rescue nil
      r
    end

    alias pmd_ac_v10215_projectile_profile skill_visual_projectile_profile_v030 unless method_defined?(:pmd_ac_v10215_projectile_profile)
    def skill_visual_projectile_profile_v030(style)
      s = @motion_launch_probe_scene_v10215
      return pmd_ac_v10215_projectile_profile(style) if s == nil ||
        !s.respond_to?(:motion_launch_probe_active_v10215?) ||
        !s.motion_launch_probe_active_v10215?
      t = Time.now.to_f
      r = pmd_ac_v10215_projectile_profile(style)
      ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      s.motion_launch_probe_record_v10215('projectile_profile', ms, 'style=' + style.to_s) rescue nil
      r
    end

    if method_defined?(:skill_visual_move_profile_v031)
      alias pmd_ac_v10215_move_visual_profile skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v10215_move_visual_profile)
      def skill_visual_move_profile_v031(key)
        s = @motion_launch_probe_scene_v10215
        return pmd_ac_v10215_move_visual_profile(key) if s == nil ||
          !s.respond_to?(:motion_launch_probe_active_v10215?) ||
          !s.motion_launch_probe_active_v10215?
        t = Time.now.to_f
        r = pmd_ac_v10215_move_visual_profile(key)
        ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
        s.motion_launch_probe_record_v10215('move_visual_profile', ms, 'key=' + key.to_s) rescue nil
        r
      end
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10215_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10215_launch_projectile)
  alias pmd_ac_v10215_substitute_target_for substitute_target_for unless method_defined?(:pmd_ac_v10215_substitute_target_for)
  alias pmd_ac_v10215_projectile_style projectile_style unless method_defined?(:pmd_ac_v10215_projectile_style)
  alias pmd_ac_v10215_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v10215_projectile_tracking_for)
  alias pmd_ac_v10215_effect_anchor_xy effect_anchor_xy unless method_defined?(:pmd_ac_v10215_effect_anchor_xy)
  alias pmd_ac_v10215_log_event log_event unless method_defined?(:pmd_ac_v10215_log_event)
  alias pmd_ac_v10215_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10215_prepare_verification_battle)
  alias pmd_ac_v10215_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10215_update_verification_script)
  alias pmd_ac_v10215_motion_log_baseline_runtime_v10212 motion_log_baseline_runtime_v10212 unless method_defined?(:pmd_ac_v10215_motion_log_baseline_runtime_v10212)

  if method_defined?(:tactical_redirect_target_v044)
    alias pmd_ac_v10215_tactical_redirect_target tactical_redirect_target_v044 unless method_defined?(:pmd_ac_v10215_tactical_redirect_target)
  end
  if method_defined?(:ability_type_redirect_target_v065)
    alias pmd_ac_v10215_ability_redirect_target ability_type_redirect_target_v065 unless method_defined?(:pmd_ac_v10215_ability_redirect_target)
  end

  def motion_launch_probe_mode_v10215?
    PMD_AC::MOTION_LAUNCH_MICRO_V10215_ENABLED &&
      respond_to?(:verification_mode) && verification_mode == :pmd_motion_phase_a_v102 &&
      @phase == :battle
  rescue
    false
  end

  def motion_launch_probe_active_v10215?
    motion_launch_probe_mode_v10215? && @motion_launch_probe_depth_v10215.to_i > 0
  end

  def motion_launch_probe_reset_v10215
    @motion_launch_probe_stats_v10215 = {}
    @motion_launch_probe_hot_v10215 = []
    @motion_launch_probe_depth_v10215 = 0
    @motion_launch_probe_unit_v10215 = nil
    @motion_launch_probe_kind_v10215 = nil
    @motion_launch_probe_effect_v10215 = nil
    @motion_launch_probe_verify_logged_v10215 = false
  end

  def prepare_verification_battle
    pmd_ac_v10215_prepare_verification_battle
    motion_launch_probe_reset_v10215 if verification_mode == :pmd_motion_phase_a_v102
  end

  def motion_launch_probe_record_v10215(kind, ms, extra = nil)
    return unless motion_launch_probe_active_v10215?
    @motion_launch_probe_stats_v10215 = {} if @motion_launch_probe_stats_v10215 == nil
    k = kind.to_s
    s = @motion_launch_probe_stats_v10215[k]
    if s == nil
      s = {:calls => 0, :total => 0, :max => 0, :slow => 0}
      @motion_launch_probe_stats_v10215[k] = s
    end
    v = ms.to_i
    s[:calls] += 1
    s[:total] += v
    s[:max] = v if v > s[:max]
    s[:slow] += 1 if v >= PMD_AC::MOTION_LAUNCH_MICRO_SLOW_MS_V10215

    if v >= PMD_AC::MOTION_LAUNCH_MICRO_HOT_MS_V10215
      @motion_launch_probe_hot_v10215 = [] if @motion_launch_probe_hot_v10215 == nil
      if @motion_launch_probe_hot_v10215.size < PMD_AC::MOTION_LAUNCH_MICRO_HOT_LIMIT_V10215
        unit = @motion_launch_probe_unit_v10215
        @motion_launch_probe_hot_v10215.push({
          :frame => Graphics.frame_count,
          :kind => k,
          :ms => v,
          :unit => (unit == nil ? '-' : unit.log_name),
          :launch_kind => @motion_launch_probe_kind_v10215,
          :effect => @motion_launch_probe_effect_v10215,
          :extra => extra
        })
      end
    end
  rescue
  end

  def motion_launch_probe_time_v10215(kind, extra = nil)
    return yield unless motion_launch_probe_active_v10215?
    t = Time.now.to_f
    r = yield
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    motion_launch_probe_record_v10215(kind, ms, extra)
    r
  end

  def launch_projectile(*args)
    return pmd_ac_v10215_launch_projectile(*args) unless motion_launch_probe_mode_v10215?
    outer = @motion_launch_probe_depth_v10215.to_i == 0
    unless outer
      return pmd_ac_v10215_launch_projectile(*args)
    end

    @motion_launch_probe_depth_v10215 = 1
    @motion_launch_probe_unit_v10215 = args[0] rescue nil
    @motion_launch_probe_kind_v10215 = args[2] rescue nil
    @motion_launch_probe_effect_v10215 = args[4] rescue nil
    PMD_AC.motion_launch_probe_scene_v10215 = self
    t = Time.now.to_f
    result = nil
    begin
      result = pmd_ac_v10215_launch_projectile(*args)
    ensure
      ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      motion_launch_probe_record_v10215('launch_total', ms,
        'kind=' + @motion_launch_probe_kind_v10215.to_s +
        ' effect=' + @motion_launch_probe_effect_v10215.to_s)
      PMD_AC.motion_launch_probe_scene_v10215 = nil
      @motion_launch_probe_depth_v10215 = 0
      @motion_launch_probe_unit_v10215 = nil
      @motion_launch_probe_kind_v10215 = nil
      @motion_launch_probe_effect_v10215 = nil
    end
    result
  end

  def substitute_target_for(*args)
    motion_launch_probe_time_v10215('substitute_target') do
      pmd_ac_v10215_substitute_target_for(*args)
    end
  end

  def projectile_style(*args)
    motion_launch_probe_time_v10215('projectile_style') do
      pmd_ac_v10215_projectile_style(*args)
    end
  end

  def projectile_tracking_for(*args)
    motion_launch_probe_time_v10215('projectile_tracking') do
      pmd_ac_v10215_projectile_tracking_for(*args)
    end
  end

  def effect_anchor_xy(*args)
    motion_launch_probe_time_v10215('effect_anchor') do
      pmd_ac_v10215_effect_anchor_xy(*args)
    end
  end

  if method_defined?(:pmd_ac_v10215_tactical_redirect_target)
    def tactical_redirect_target_v044(*args)
      motion_launch_probe_time_v10215('tactical_redirect') do
        pmd_ac_v10215_tactical_redirect_target(*args)
      end
    end
  end

  if method_defined?(:pmd_ac_v10215_ability_redirect_target)
    def ability_type_redirect_target_v065(*args)
      motion_launch_probe_time_v10215('ability_redirect') do
        pmd_ac_v10215_ability_redirect_target(*args)
      end
    end
  end

  def log_event(category, message)
    if motion_launch_probe_active_v10215?
      motion_launch_probe_time_v10215('launch_log_event', category.to_s) do
        pmd_ac_v10215_log_event(category, message)
      end
    else
      pmd_ac_v10215_log_event(category, message)
    end
  end

  def verify_motion_launch_micro_v10215
    return if @motion_launch_probe_verify_logged_v10215
    hooks = ['launch_total','projectile_initialize','substitute_target','projectile_style',
             'projectile_tracking','effect_anchor','skill_data','launch_log_event']
    log_event(:verify,
      'MOTION_LAUNCH_MICRO_PROFILER_V10215 pass=1 hooks=' + hooks.join(',') +
      ' shared_v10214_disabled=1 behavior_unchanged=1 ai_unchanged=1' +
      ' damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_launch_probe_verify_logged_v10215 = true
  end

  def update_verification_script
    pmd_ac_v10215_update_verification_script
    return unless verification_mode == :pmd_motion_phase_a_v102
    verify_motion_launch_micro_v10215 if @verification_frame.to_i >= 55
  end

  def motion_launch_probe_report_v10215
    return unless verification_mode == :pmd_motion_phase_a_v102
    h = @motion_launch_probe_stats_v10215 || {}
    order = ['launch_total','projectile_initialize','substitute_target','tactical_redirect',
             'ability_redirect','projectile_style','projectile_tracking','effect_anchor',
             'skill_data','projectile_profile','move_visual_profile','launch_log_event']
    parts = []
    order.each do |k|
      s = h[k]
      next if s == nil
      avg = s[:calls].to_i <= 0 ? 0 : (s[:total].to_f / s[:calls].to_f).round
      parts.push(k + ':max' + s[:max].to_i.to_s + '/avg' + avg.to_i.to_s +
        '/slow' + s[:slow].to_i.to_s + '/calls' + s[:calls].to_i.to_s)
    end
    log_event(:perf,
      'MOTION_LAUNCH_MICRO_SUMMARY_V10215 shared_v10214_disabled=1 stats=[' +
      parts.join(',') + ']')

    hot = (@motion_launch_probe_hot_v10215 || []).sort_by do |r|
      [-r[:ms].to_i, r[:frame].to_i]
    end
    hot[0, 24].each do |r|
      log_event(:perf,
        'MOTION_LAUNCH_MICRO_HOT_V10215 frame=' + r[:frame].to_i.to_s +
        ' kind=' + r[:kind].to_s + ' ms=' + r[:ms].to_i.to_s +
        ' unit=' + r[:unit].to_s + ' launch_kind=' + r[:launch_kind].to_s +
        ' effect=' + r[:effect].to_s +
        (r[:extra] == nil ? '' : ' extra=' + r[:extra].to_s))
    end
  rescue
  end

  def motion_log_baseline_runtime_v10212
    pmd_ac_v10215_motion_log_baseline_runtime_v10212
    motion_launch_probe_report_v10215
  end
end

class Sprite_PMDProjectile
  alias pmd_ac_v10215_initialize initialize unless method_defined?(:pmd_ac_v10215_initialize)
  def initialize(*args)
    scene = args[1] rescue nil
    active = scene != nil && scene.respond_to?(:motion_launch_probe_active_v10215?) &&
      scene.motion_launch_probe_active_v10215?
    return pmd_ac_v10215_initialize(*args) unless active
    t = Time.now.to_f
    r = pmd_ac_v10215_initialize(*args)
    ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
    scene.motion_launch_probe_record_v10215('projectile_initialize', ms,
      'style=' + (@style == nil ? 'nil' : @style.to_s)) rescue nil
    r
  end
end
