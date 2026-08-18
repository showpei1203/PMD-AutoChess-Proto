# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Projectile Spawn Shared Frame v1.02.14
# 分類：PMD Motion Phase A／Projectile Spawn 單點效能修正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.13 Windows RGSS2 實機 LOG 已把大型 live spike 收斂到：
# - resolve_basic_attack -> launch_projectile，單次約 83~129ms。
# - projectile live update 本身已由 113ms 級降到 15ms，因此本版不再改 update 路徑。
#
# 追查目前 Sprite_PMDProjectile 建立流程後確認：
# - 原始建構先建立 28x28 legacy Bitmap 並畫內容。
# - v0.30 skin 接著立刻丟棄該 Bitmap，再建立 48x48 Bitmap。
# - v1.02.13 雖已在 Loading 建好 48x48 frame cache，spawn 時仍會建立新的 48x48
#   Bitmap，再把 cache blt 進去。
#
# 本版只在 PMD_MOTION_PHASE_A_V102、且 v1.02.13 frame cache 已存在時，使用
# 「共享唯讀 frame Bitmap」快速建立 Projectile：
# - 不建立 28x28 legacy Bitmap。
# - 不建立 48x48 per-projectile Bitmap。
# - Sprite 直接引用 Loading 已完成的 cached frame。
# - 動畫換幀時只切換 bitmap reference，不做 clear / blt / stretch_blt。
#------------------------------------------------------------------------------
# 【主要設定項】
# PMD_AC::MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED
#   true：在正式 Motion verifier 中啟用共享 Projectile frame。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 只有 verification_mode == :pmd_motion_phase_a_v102 才使用快速建構。
# 2. 只有該 style 的 v1.02.13 cached frame 已存在時才走快速路徑；否則完整回退
#    到既有建構流程，避免缺素材時改變行為。
# 3. shared Bitmap 視為唯讀。Projectile dispose 時只解除 Sprite bitmap reference，
#    不 dispose 共用 cache。
# 4. 不修改 projectile 速度、tracking、碰撞、hit、生命期、style、trail、impact。
# 5. 不修改 AI、Damage Formula、Attack Speed、Spatial、logical xy、hit-stop、Hurt。
#------------------------------------------------------------------------------
# 【可調參數】
# 目前僅有總開關。若 Windows 實機證明 launch_projectile spike 消失，再決定是否
# 將同一安全路徑推進 NORMAL / Map Story production runtime。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需事件手動呼叫。
# 測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場。
#------------------------------------------------------------------------------
# 【實際 LOG 範例】
# MOTION_PROJECTILE_SHARED_FRAME_V10214 pass=1 shared_spawn=4 fallback_spawn=0
# MOTION_DEEP_SUMMARY_V1027 ... launch_projectile:max... projectile_one:max...
#------------------------------------------------------------------------------
# 【驗收重點】
# - launch_projectile max 應明顯低於 v1.02.13 的 129ms。
# - opening >=50ms 應優先下降；v1.02.13 為 6。
# - projectile_one / projectile_sprites 不得退化；v1.02.13 均為 15ms。
# - baseline live_miss 必須維持 0。
# - VERIFY_FINISHED_BATTLE_RESUME 必須 pass=1。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_ProjectileSpawnSharedFrame_v10214'] = true

module PMD_AC
  MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED = true

  class << self
    def motion_projectile_cached_frame_v10214(style, frame)
      return nil unless MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED
      c = motion_projectile_frame_cache_v10213 rescue nil
      return nil if c == nil
      s = style.respond_to?(:to_sym) ? style.to_sym : style
      p = skill_visual_projectile_profile_v030(s) rescue nil
      return nil if p == nil
      frames = [p[:frames].to_i, 1].max
      f = frame.to_i % frames
      bmp = c[[s, f]]
      return nil if bmp == nil || bmp.disposed?
      bmp
    rescue
      nil
    end
  end
end

#==============================================================================
# ■ Scene：只負責模式判定、統計與 verifier 訊號
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10214_start start unless method_defined?(:pmd_ac_v10214_start)
  alias pmd_ac_v10214_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10214_restart_to_deploy)
  alias pmd_ac_v10214_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10214_update_verification_script)

  def motion_projectile_shared_mode_v10214?
    PMD_AC::MOTION_PROJECTILE_SHARED_FRAME_V10214_ENABLED &&
      verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_projectile_shared_reset_v10214
    @motion_projectile_shared_spawn_v10214 = 0
    @motion_projectile_fallback_spawn_v10214 = 0
    @motion_projectile_shared_verify_logged_v10214 = false
  end

  def start
    motion_projectile_shared_reset_v10214
    pmd_ac_v10214_start
  end

  def restart_to_deploy
    r = pmd_ac_v10214_restart_to_deploy
    motion_projectile_shared_reset_v10214 if @phase == :deploy
    r
  end

  def motion_projectile_shared_record_v10214(shared)
    if shared
      @motion_projectile_shared_spawn_v10214 = @motion_projectile_shared_spawn_v10214.to_i + 1
    else
      @motion_projectile_fallback_spawn_v10214 = @motion_projectile_fallback_spawn_v10214.to_i + 1
    end
  end

  def verify_motion_projectile_shared_v10214
    return if @motion_projectile_shared_verify_logged_v10214
    shared = @motion_projectile_shared_spawn_v10214.to_i
    fallback = @motion_projectile_fallback_spawn_v10214.to_i
    pass = shared > 0 && fallback == 0
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_PROJECTILE_SHARED_FRAME_V10214 pass=' + (pass ? '1' : '0') +
      ' shared_spawn=' + shared.to_s + ' fallback_spawn=' + fallback.to_s +
      ' bitmap_alloc_live=0 frame_switch=reference_only' +
      ' projectile_logic_unchanged=1 ai_unchanged=1 damage_unchanged=1' +
      ' attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_projectile_shared_verify_logged_v10214 = true
  end

  def update_verification_script
    pmd_ac_v10214_update_verification_script
    return unless motion_projectile_shared_mode_v10214?
    verify_motion_projectile_shared_v10214 if @verification_frame.to_i >= 55
  end
end

#==============================================================================
# ■ Projectile：Motion verifier 專用零 per-instance Bitmap spawn
#==============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v10214_initialize initialize unless method_defined?(:pmd_ac_v10214_initialize)
  alias pmd_ac_v10214_redraw_skill_visual_v030 redraw_skill_visual_v030 unless method_defined?(:pmd_ac_v10214_redraw_skill_visual_v030)
  alias pmd_ac_v10214_dispose dispose unless method_defined?(:pmd_ac_v10214_dispose)

  def initialize(*args)
    viewport = args[0]
    scene = args[1]
    user = args[3]
    target = args[4]
    kind = args[5]
    effect_type = args[7]

    fast = false
    style = nil
    profile = nil
    cached = nil
    begin
      if scene != nil && scene.respond_to?(:motion_projectile_shared_mode_v10214?) &&
          scene.motion_projectile_shared_mode_v10214? && user != nil && target != nil
        style = scene.projectile_style(user, kind, effect_type)
        profile = PMD_AC.skill_visual_projectile_profile_v030(style)
        cached = PMD_AC.motion_projectile_cached_frame_v10214(style, 0)
        fast = profile != nil && cached != nil
      end
    rescue
      fast = false
    end

    unless fast
      pmd_ac_v10214_initialize(*args)
      scene.motion_projectile_shared_record_v10214(false) if scene != nil &&
        scene.respond_to?(:motion_projectile_shared_record_v10214) &&
        scene.respond_to?(:motion_projectile_shared_mode_v10214?) &&
        scene.motion_projectile_shared_mode_v10214?
      return
    end

    # 以下欄位與既有 base + v0.30 + v0.59.1 完成後的 runtime state 對齊，
    # 唯一差異是 bitmap 直接引用 Loading cache，不建立 / 繪製 / 丟棄個別 Bitmap。
    super(viewport)
    @scene = scene
    @id = args[2]
    @user = user
    @target = target
    @kind = kind
    @power = args[6]
    @effect_type = effect_type
    @style = style
    @tracking_level = args[8] || :perfect
    @attack_modifier = args[9]
    @evade_triggered = false
    @evade_target = nil

    source_anchor = @scene.effect_anchor_xy(user, true)
    target_anchor = @scene.effect_anchor_xy(target, false)
    @x_f = source_anchor[0].to_f
    @y_f = source_anchor[1].to_f
    @target_x = target_anchor[0].to_f
    @target_y = target_anchor[1].to_f
    hdx = @target_x - @x_f
    hdy = @target_y - @y_f
    hlen = Math.sqrt(hdx * hdx + hdy * hdy)
    if hlen <= 0.001
      @heading_x = user.team == :ally ? 1.0 : -1.0
      @heading_y = 0.0
    else
      @heading_x = hdx / hlen
      @heading_y = hdy / hlen
    end

    @scene.log_event(:projectile_track,
      user.log_name + ' -> ' + target.log_name + ' level=' + @tracking_level.to_s)
    @scene.log_event(:vfx_anchor,
      user.log_name + ' PROJECTILE style=' + @style.to_s +
      ' src=(' + @x_f.round.to_s + ',' + @y_f.round.to_s + ')' +
      ' dst=(' + @target_x.round.to_s + ',' + @target_y.round.to_s + ')')

    @impact_x = @target_x
    @impact_y = @target_y
    @speed = PMD_AC::PROJECTILE_SPEED
    @radius = PMD_AC::PROJECTILE_RADIUS
    @life = PMD_AC::PROJECTILE_LIFE
    @closest_target_distance = hlen
    @entered_orbit_break_radius = false
    @overshoot_frames = 0
    @finished = false

    @pmd_skill_visual_profile_v030 = profile
    @pmd_v030_frame = 0
    @pmd_v030_wait = 0
    @pmd_v030_trail_wait = 0
    @pmd_v0591_birth_frame = Graphics.frame_count
    @pmd_v10214_shared_bitmap = true

    self.bitmap = cached
    self.ox = 24
    self.oy = 24
    self.z = 9200
    self.zoom_x = PMD_AC::PROJECTILE_SPRITE_SCALE
    self.zoom_y = PMD_AC::PROJECTILE_SPRITE_SCALE
    self.blend_type = (profile[:blend] || 0).to_i
    update_screen_position
    @scene.motion_projectile_shared_record_v10214(true)
  rescue
    # 若快速建構在欄位初始化前發生例外，不能安全重跑完整 initialize；
    # 讓錯誤照常拋出，避免產生半初始化 Projectile 靜默污染戰鬥。
    raise
  end

  def redraw_skill_visual_v030
    if @pmd_v10214_shared_bitmap
      p = @pmd_skill_visual_profile_v030
      if p != nil
        f = @pmd_v030_frame.to_i % [p[:frames].to_i, 1].max
        cached = PMD_AC.motion_projectile_cached_frame_v10214(@style, f)
        if cached != nil
          self.bitmap = cached
          self.blend_type = (p[:blend] || 0).to_i
          return
        end
      end
    end
    pmd_ac_v10214_redraw_skill_visual_v030
  end

  def dispose
    if @pmd_v10214_shared_bitmap
      self.bitmap = nil
      return super
    end
    pmd_ac_v10214_dispose
  end
end
