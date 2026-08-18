#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.29
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - WEATHER_VISUAL_BOUNDS_Y / WEATHER_VISUAL_BOUNDS_BOTTOM / WEATHER_VISUAL_FADE_STEP / WEATHER_VISUAL_PARTICLE_Z
# - WEATHER_VISUAL_OVERLAY_Z / WEATHER_VISUAL_SUN_Z / WEATHER_VISUAL_FOG_Z
#
# 【PMD_AC 對外／共用方法】
# - weather_visual_bounds / weather_visual_picture_copy / weather_visual_fallback_light
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / initialize / change_kind / activate
# - deactivate / dispose / update / reset_position
# - offscreen? / active_weather / create_overlay_sprite / create_sun_sprite
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.29
#    Weather Visual Presentation Layer
#------------------------------------------------------------------------------
#  Base: verified v0.28 FullTestProject.
#  Adds battle-time weather visuals for Sun / Rain / Sandstorm / Hail without
#  rewriting the existing v0.15 Core or v0.28 weather mechanics.
#
#  Visual goals:
#  - Sun: warm overlay + light3-style additive sunlight.
#  - Rain: blue field tint + slanted rain particle streaks.
#  - Sandstorm: brown field tint + scrolling fog image.
#  - Hail: cool field tint + hail particle chips.
#
#  The layer automatically respects Cloud Nine / Air Lock suppression because it
#  only renders when Scene_PMD_AutoChess#canonical_weather_effective? is true.
#==============================================================================
module PMD_AC
  WEATHER_VISUAL_BOUNDS_Y = 68 unless const_defined?(:WEATHER_VISUAL_BOUNDS_Y)
  WEATHER_VISUAL_BOUNDS_BOTTOM = 52 unless const_defined?(:WEATHER_VISUAL_BOUNDS_BOTTOM)
  WEATHER_VISUAL_FADE_STEP = 6 unless const_defined?(:WEATHER_VISUAL_FADE_STEP)
  WEATHER_VISUAL_PARTICLE_Z = 180 unless const_defined?(:WEATHER_VISUAL_PARTICLE_Z)
  WEATHER_VISUAL_OVERLAY_Z = 150 unless const_defined?(:WEATHER_VISUAL_OVERLAY_Z)
  WEATHER_VISUAL_SUN_Z = 160 unless const_defined?(:WEATHER_VISUAL_SUN_Z)
  WEATHER_VISUAL_FOG_Z = 170 unless const_defined?(:WEATHER_VISUAL_FOG_Z)

  def self.weather_visual_bounds
    y = WEATHER_VISUAL_BOUNDS_Y
    h = Graphics.height - WEATHER_VISUAL_BOUNDS_Y - WEATHER_VISUAL_BOUNDS_BOTTOM
    h = 1 if h < 1
    {:x => 0, :y => y, :w => Graphics.width, :h => h}
  end

  def self.weather_visual_picture_copy(name)
    src = Cache.picture(name)
    bmp = Bitmap.new(src.width, src.height)
    bmp.blt(0, 0, src, src.rect)
    bmp
  rescue
    nil
  end

  def self.weather_visual_fallback_light(bounds)
    bmp = Bitmap.new(bounds[:w], bounds[:h])
    bmp.clear
    7.times do |i|
      x0 = -120 + i * 110
      y0 = -20
      26.times do |j|
        alpha = [42 - j, 0].max
        next if alpha <= 0
        bmp.fill_rect(x0 + j * 2, y0, 12, bounds[:h], Color.new(255, 240, 120, alpha))
      end
    end
    bmp
  end
end

class Sprite_PMDWeatherParticle < Sprite
  def initialize(viewport, kind, bounds)
    super(viewport)
    @bounds = bounds
    @kind = nil
    @active = false
    @vx = 0
    @vy = 0
    self.z = PMD_AC::WEATHER_VISUAL_PARTICLE_Z
    self.visible = false
    change_kind(kind)
    reset_position(true)
  end

  def change_kind(kind)
    return if @kind == kind && self.bitmap != nil
    @kind = kind
    if self.bitmap != nil && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    case @kind
    when :rain
      self.bitmap = Bitmap.new(8, 24)
      6.times do |i|
        self.bitmap.fill_rect(3, i * 3, 2, 3, Color.new(185, 225, 255, 210 - i * 20))
      end
      self.angle = 24
      self.blend_type = 0
    when :hail
      self.bitmap = Bitmap.new(8, 8)
      self.bitmap.fill_rect(2, 1, 4, 6, Color.new(240, 248, 255, 220))
      self.bitmap.fill_rect(1, 2, 6, 4, Color.new(210, 230, 255, 190))
      self.angle = 0
      self.blend_type = 0
    else
      self.bitmap = Bitmap.new(4, 4)
      self.bitmap.fill_rect(0, 0, 4, 4, Color.new(255, 255, 255, 255))
      self.angle = 0
      self.blend_type = 0
    end
  end

  def activate(kind)
    change_kind(kind)
    @active = true
    self.visible = true
    reset_position(true)
  end

  def deactivate
    @active = false
    self.visible = false
  end

  def dispose
    if self.bitmap != nil && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    super
  end

  def update
    super
    return unless @active
    self.x += @vx
    self.y += @vy
    if @kind == :rain
      self.opacity = 155 + rand(55)
    elsif @kind == :hail
      self.opacity = 160 + rand(80)
    end
    reset_position(false) if offscreen?
  end

  def reset_position(initial)
    bx = @bounds[:x]
    by = @bounds[:y]
    bw = @bounds[:w]
    bh = @bounds[:h]
    if @kind == :rain
      self.x = bx + rand(bw + 48) - 24
      self.y = initial ? (by + rand(bh)) : (by - rand(40) - 24)
      @vx = -5 - rand(3)
      @vy = 10 + rand(5)
      zf = 0.85 + rand(35) / 100.0
      self.zoom_x = zf
      self.zoom_y = zf
    elsif @kind == :hail
      self.x = bx + rand(bw + 24) - 12
      self.y = initial ? (by + rand(bh)) : (by - rand(24) - 10)
      @vx = -1 + rand(3)
      @vy = 6 + rand(4)
      zf = 0.8 + rand(45) / 100.0
      self.zoom_x = zf
      self.zoom_y = zf
    else
      self.x = bx + rand(bw)
      self.y = by + rand(bh)
      @vx = 0
      @vy = 0
    end
  end

  def offscreen?
    bx = @bounds[:x]
    by = @bounds[:y]
    bw = @bounds[:w]
    bh = @bounds[:h]
    self.y > by + bh + 24 || self.x < bx - 48 || self.x > bx + bw + 48
  end
end

class PMD_AC_WeatherVisualLayer
  def initialize(viewport, scene)
    @viewport = viewport
    @scene = scene
    @bounds = PMD_AC.weather_visual_bounds
    @current_weather = nil
    @overlay_target_opacity = 0
    @sun_target_opacity = 0
    @fog_target_opacity = 0
    @sun_phase = 0
    @fog_scroll = 0.0
    create_overlay_sprite
    create_sun_sprite
    create_fog_sprites
    create_particles
    apply_profile(nil)
  end

  def dispose
    dispose_particles(@rain_particles)
    dispose_particles(@hail_particles)
    dispose_sprite(@overlay_sprite)
    dispose_sprite(@sun_sprite)
    dispose_sprite(@fog_sprite_a)
    dispose_sprite(@fog_sprite_b)
  end

  def update
    weather = active_weather
    if weather != @current_weather
      @current_weather = weather
      apply_profile(weather)
    end
    update_overlay
    update_sun
    update_fog
    update_particles
  end

  def active_weather
    return nil if @scene == nil
    phase = @scene.instance_variable_get(:@phase) rescue nil
    return nil unless phase == :battle
    return nil unless @scene.respond_to?(:canonical_weather)
    return nil unless @scene.respond_to?(:canonical_weather_effective?)
    return nil unless @scene.canonical_weather_effective?
    @scene.canonical_weather
  rescue
    nil
  end

  def create_overlay_sprite
    @overlay_sprite = Sprite.new(@viewport)
    @overlay_sprite.bitmap = Bitmap.new(@bounds[:w], @bounds[:h])
    @overlay_sprite.x = @bounds[:x]
    @overlay_sprite.y = @bounds[:y]
    @overlay_sprite.z = PMD_AC::WEATHER_VISUAL_OVERLAY_Z
    @overlay_sprite.opacity = 0
  end

  def create_sun_sprite
    @sun_sprite = Sprite.new(@viewport)
    bmp = PMD_AC.weather_visual_picture_copy('PMD_Weather_SunOverlay')
    bmp = PMD_AC.weather_visual_fallback_light(@bounds) if bmp == nil
    @sun_sprite.bitmap = bmp
    @sun_sprite.x = @bounds[:x]
    @sun_sprite.y = @bounds[:y] - 18
    @sun_sprite.z = PMD_AC::WEATHER_VISUAL_SUN_Z
    @sun_sprite.blend_type = 1
    @sun_sprite.opacity = 0
    sx = (@bounds[:w].to_f / bmp.width.to_f)
    sy = ((@bounds[:h] + 36).to_f / bmp.height.to_f)
    scale = [sx, sy].max
    @sun_sprite.zoom_x = scale
    @sun_sprite.zoom_y = scale
  end

  def create_fog_sprites
    fog_bmp = PMD_AC.weather_visual_picture_copy('PMD_Weather_SandFog')
    if fog_bmp == nil
      fog_bmp = Bitmap.new(128, 128)
      64.times do |i|
        fog_bmp.fill_rect(0, i * 2, 128, 2, Color.new(220, 215, 190, 40 - (i % 8) * 4))
      end
    end
    @fog_base_width = fog_bmp.width
    @fog_scaled_width = [@bounds[:w], ((fog_bmp.width.to_f * [@bounds[:w].to_f / fog_bmp.width.to_f, @bounds[:h].to_f / fog_bmp.height.to_f].max).ceil)].max
    fog_scale = @fog_scaled_width.to_f / fog_bmp.width.to_f
    @fog_sprite_a = Sprite.new(@viewport)
    @fog_sprite_b = Sprite.new(@viewport)
    for sprite in [@fog_sprite_a, @fog_sprite_b]
      sprite.bitmap = Bitmap.new(fog_bmp.width, fog_bmp.height)
      sprite.bitmap.blt(0, 0, fog_bmp, fog_bmp.rect)
      sprite.y = @bounds[:y]
      sprite.z = PMD_AC::WEATHER_VISUAL_FOG_Z
      sprite.zoom_x = fog_scale
      sprite.zoom_y = [@bounds[:h].to_f / fog_bmp.height.to_f, fog_scale].max
      sprite.opacity = 0
      sprite.tone = Tone.new(40, -25, -60, 0)
    end
    @fog_sprite_a.x = @bounds[:x]
    @fog_sprite_b.x = @bounds[:x] + @fog_scaled_width - 1
    fog_bmp.dispose if fog_bmp != nil && !fog_bmp.disposed?
  end

  def create_particles
    @rain_particles = []
    28.times do
      @rain_particles << Sprite_PMDWeatherParticle.new(@viewport, :rain, @bounds)
    end
    @hail_particles = []
    20.times do
      @hail_particles << Sprite_PMDWeatherParticle.new(@viewport, :hail, @bounds)
    end
  end

  def apply_profile(weather)
    case weather
    when :sun
      fill_overlay(Color.new(255, 190, 80, 255))
      @overlay_target_opacity = 28
      @sun_target_opacity = 88
      @fog_target_opacity = 0
      activate_particles(@rain_particles, false)
      activate_particles(@hail_particles, false)
    when :rain
      fill_overlay(Color.new(90, 120, 180, 255))
      @overlay_target_opacity = 26
      @sun_target_opacity = 0
      @fog_target_opacity = 0
      activate_particles(@rain_particles, true)
      activate_particles(@hail_particles, false)
    when :hail
      fill_overlay(Color.new(165, 205, 255, 255))
      @overlay_target_opacity = 18
      @sun_target_opacity = 0
      @fog_target_opacity = 0
      activate_particles(@rain_particles, false)
      activate_particles(@hail_particles, true)
    when :sandstorm
      fill_overlay(Color.new(155, 122, 76, 255))
      @overlay_target_opacity = 22
      @sun_target_opacity = 0
      @fog_target_opacity = 90
      activate_particles(@rain_particles, false)
      activate_particles(@hail_particles, false)
    else
      @overlay_target_opacity = 0
      @sun_target_opacity = 0
      @fog_target_opacity = 0
      activate_particles(@rain_particles, false)
      activate_particles(@hail_particles, false)
    end
  end

  def activate_particles(list, active)
    for sprite in list
      active ? sprite.activate(sprite.instance_variable_get(:@kind)) : sprite.deactivate
    end
  end

  def fill_overlay(color)
    bmp = @overlay_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0, 0, bmp.width, bmp.height, color)
  end

  def update_overlay
    @overlay_sprite.opacity = approach(@overlay_sprite.opacity, @overlay_target_opacity, PMD_AC::WEATHER_VISUAL_FADE_STEP)
  end

  def update_sun
    @sun_phase += 1
    base = approach(@sun_sprite.opacity, @sun_target_opacity, PMD_AC::WEATHER_VISUAL_FADE_STEP)
    if @sun_target_opacity > 0
      pulse = (Math.sin(@sun_phase / 18.0) * 12.0).to_i
      @sun_sprite.opacity = [[base + pulse, 0].max, 255].min
    else
      @sun_sprite.opacity = base
    end
  end

  def update_fog
    @fog_sprite_a.opacity = approach(@fog_sprite_a.opacity, @fog_target_opacity, PMD_AC::WEATHER_VISUAL_FADE_STEP)
    @fog_sprite_b.opacity = approach(@fog_sprite_b.opacity, @fog_target_opacity, PMD_AC::WEATHER_VISUAL_FADE_STEP)
    return if @fog_sprite_a.opacity <= 0 && @fog_sprite_b.opacity <= 0
    @fog_scroll += 1.4
    @fog_scroll = 0.0 if @fog_scroll >= @fog_scaled_width
    base_x = @bounds[:x] - @fog_scroll.to_i
    @fog_sprite_a.x = base_x
    @fog_sprite_b.x = base_x + @fog_scaled_width - 1
  end

  def update_particles
    for sprite in @rain_particles
      sprite.update
    end
    for sprite in @hail_particles
      sprite.update
    end
  end

  def approach(current, target, step)
    return target if current == target
    if current < target
      current += step
      current = target if current > target
    else
      current -= step
      current = target if current < target
    end
    current
  end

  def dispose_particles(list)
    return if list == nil
    for sprite in list
      sprite.dispose unless sprite == nil || sprite.disposed?
    end
    list.clear
  end

  def dispose_sprite(sprite)
    return if sprite == nil || sprite.disposed?
    if sprite.bitmap != nil && !sprite.bitmap.disposed?
      sprite.bitmap.dispose
    end
    sprite.dispose
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v029_start start unless method_defined?(:pmd_ac_v029_start)
  alias pmd_ac_v029_update update unless method_defined?(:pmd_ac_v029_update)
  alias pmd_ac_v029_terminate terminate unless method_defined?(:pmd_ac_v029_terminate)

  def start
    pmd_ac_v029_start
    create_weather_visual_layer_v029
  end

  def update
    pmd_ac_v029_update
    if $scene == self && @weather_visual_layer_v029 != nil
      @weather_visual_layer_v029.update
    end
  end

  def terminate
    dispose_weather_visual_layer_v029
    pmd_ac_v029_terminate
  end

  def create_weather_visual_layer_v029
    dispose_weather_visual_layer_v029
    @weather_visual_layer_v029 = PMD_AC_WeatherVisualLayer.new(@viewport, self)
  end

  def dispose_weather_visual_layer_v029
    return if @weather_visual_layer_v029 == nil
    @weather_visual_layer_v029.dispose
    @weather_visual_layer_v029 = nil
  end
end
