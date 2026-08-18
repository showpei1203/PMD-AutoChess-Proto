#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.74.3
# 分類：天氣
#
# 【用途／機制】
# 定義雨、晴、沙暴、冰雹等天氣的戰鬥效果與／或視覺呈現。
#
# 【怎麼調整】
# 機制天氣使用 v0.28；Rain 視覺目前走 VX Spriteset_Weather，晴天與沙暴保留 overlay/fog。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0743 / WEATHER_CORE_RAIN_TYPE_V0743 / WEATHER_CORE_HAIL_VISUAL_TYPE_V0743 / WEATHER_CORE_RAIN_MAX_V0743
# - WEATHER_CORE_HAIL_MAX_V0743 / RANGED_DISENGAGE_RANGE_V0743 / RANGED_DISENGAGE_FRAMES_V0743 / RANGED_RETREAT_SPEED_MULT_V0743
# - RANGED_DISENGAGE_POLICIES_V0743 / V0743_OLD_VERIFICATION_MODES / V0743_OLD_VERIFICATION_LABELS / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - create_particles / initialize / start_combat / ranged_disengage_role_v0743?
# - ranged_disengage_locked_v0743? / update_logic / update_threat_state / effective_move_speed
# - skill_in_range? / start / update / terminate
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.74.3
# Native VX Weather Visual Bridge + Ranged Disengage Cost
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Weather presentation:
# - Stop hand-drawing custom rain/hail particles from v0.29.
# - Rain uses the project's built-in Spriteset_Weather type 1.
# - Canonical Hail uses built-in type 3 (Snow visual) as the precipitation art.
# - Sun/Sandstorm keep the accepted v0.29 overlay/fog presentation.
# - Weather mechanics remain v0.28 unchanged.
#
# Ranged balance:
# - Kiter / Artillery / Controller keep their range and damage.
# - When a melee threat closes to 82 px, they enter a 24f disengage lock.
# - During that lock, enemy-targeted skills are withheld and basic attack cooldown
#   cannot immediately reset to fire while retreating.
# - Retreat movement is 0.86x while the melee threat is close, giving successful
#   melee engagement an actual payoff without deleting ranged identity.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0743 = '0.74.3'
  WEATHER_CORE_RAIN_TYPE_V0743 = 1
  WEATHER_CORE_HAIL_VISUAL_TYPE_V0743 = 3
  WEATHER_CORE_RAIN_MAX_V0743 = 26
  WEATHER_CORE_HAIL_MAX_V0743 = 18
  RANGED_DISENGAGE_RANGE_V0743 = 82.0
  RANGED_DISENGAGE_FRAMES_V0743 = 24
  RANGED_RETREAT_SPEED_MULT_V0743 = 0.86
  RANGED_DISENGAGE_POLICIES_V0743 = [:kiter,:artillery,:controller]

  # v0.73 made Full Soak the first verification mode.  Keep it available, but
  # restore NORMAL as the default visible play mode for UI/gameplay iteration.
  V0743_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V0743_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal] + V0743_OLD_VERIFICATION_MODES.reject{|x|x==:normal}
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V0743_OLD_VERIFICATION_LABELS.merge(:normal=>'NORMAL')
end

# The v0.29 overlay remains useful for Sun / Sandstorm and subtle weather tint,
# but its custom rain/hail Sprite_PMDWeatherParticle layer is retired here.
class PMD_AC_WeatherVisualLayer
  def create_particles
    @rain_particles = []
    @hail_particles = []
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v0743_initialize initialize unless method_defined?(:pmd_ac_v0743_initialize)
  alias pmd_ac_v0743_start_combat start_combat unless method_defined?(:pmd_ac_v0743_start_combat)
  alias pmd_ac_v0743_update_logic update_logic unless method_defined?(:pmd_ac_v0743_update_logic)
  alias pmd_ac_v0743_update_threat_state update_threat_state unless method_defined?(:pmd_ac_v0743_update_threat_state)
  alias pmd_ac_v0743_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v0743_effective_move_speed)
  alias pmd_ac_v0743_skill_in_range skill_in_range? unless method_defined?(:pmd_ac_v0743_skill_in_range)

  def initialize(*args)
    pmd_ac_v0743_initialize(*args)
    @ranged_disengage_lock_v0743 = 0
    @ranged_disengage_episode_v0743 = false
  end

  def start_combat
    pmd_ac_v0743_start_combat
    @ranged_disengage_lock_v0743 = 0
    @ranged_disengage_episode_v0743 = false
  end

  def ranged_disengage_role_v0743?
    return false unless ranged?
    PMD_AC::RANGED_DISENGAGE_POLICIES_V0743.include?(@movement_policy)
  end

  def ranged_disengage_locked_v0743?
    @ranged_disengage_lock_v0743.to_i > 0
  end

  def update_logic
    if @ranged_disengage_lock_v0743.to_i > 0
      @ranged_disengage_lock_v0743 -= PMD_AC::LOGIC_TICK
      @ranged_disengage_lock_v0743 = 0 if @ranged_disengage_lock_v0743 < 0
    end
    if @ranged_disengage_lock_v0743.to_i <= 0 &&
       (@threat_level == :safe || @threat_source == nil)
      @ranged_disengage_episode_v0743 = false
    end
    pmd_ac_v0743_update_logic
  end

  def update_threat_state
    pmd_ac_v0743_update_threat_state
    return unless ranged_disengage_role_v0743?
    return if @threat_source == nil || @threat_source.dead?
    return unless @threat_source.melee?
    return unless @threat_level == :pressured || @threat_level == :emergency
    distance = distance_to(@threat_source).to_f
    return if distance > PMD_AC::RANGED_DISENGAGE_RANGE_V0743

    entering = !@ranged_disengage_episode_v0743
    @ranged_disengage_episode_v0743 = true
    @ranged_disengage_lock_v0743 = PMD_AC::RANGED_DISENGAGE_FRAMES_V0743
    wait = @attack_wait.to_f
    floor = PMD_AC::RANGED_DISENGAGE_FRAMES_V0743.to_f
    @attack_wait = floor if wait < floor
    if entering
      log_event(:ranged_balance,
        log_name+' DISENGAGE threat='+@threat_source.log_name+
        ' distance='+distance.round.to_s+
        ' lock='+PMD_AC::RANGED_DISENGAGE_FRAMES_V0743.to_s+
        ' retreat_speed='+sprintf('%.2f',PMD_AC::RANGED_RETREAT_SPEED_MULT_V0743))
    end
  end

  def effective_move_speed
    speed = pmd_ac_v0743_effective_move_speed
    if ranged_disengage_locked_v0743? && ranged_disengage_role_v0743? &&
       @threat_source != nil && !@threat_source.dead? && @threat_source.melee?
      speed *= PMD_AC::RANGED_RETREAT_SPEED_MULT_V0743
    end
    speed
  end

  def skill_in_range?(other)
    # Retreating ranged units can still use self/ally defensive support, but do
    # not kite while firing enemy-targeted skills for free.
    if ranged_disengage_locked_v0743? && other != nil && enemy_of?(other)
      return false
    end
    pmd_ac_v0743_skill_in_range(other)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0743_start start unless method_defined?(:pmd_ac_v0743_start)
  alias pmd_ac_v0743_update update unless method_defined?(:pmd_ac_v0743_update)
  alias pmd_ac_v0743_terminate terminate unless method_defined?(:pmd_ac_v0743_terminate)

  def start
    pmd_ac_v0743_start
    # Core Scene#start resets the mode index.  Select NORMAL only after the
    # complete inherited start chain has finished.
    idx = PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index = idx unless idx == nil
    create_native_weather_core_v0743
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.74.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.74.3 weather_visual_core=Spriteset_Weather '+
      'rain=type1 hail_visual=snow_type3 custom_precipitation=off '+
      'sun_sand_overlay=v0.29 weather_mechanics=v0.28_unchanged')
    log_event(:ranged_balance,
      'PATCH v0.74.3 close_range='+PMD_AC::RANGED_DISENGAGE_RANGE_V0743.to_i.to_s+
      ' disengage_lock='+PMD_AC::RANGED_DISENGAGE_FRAMES_V0743.to_s+
      ' retreat_speed='+sprintf('%.2f',PMD_AC::RANGED_RETREAT_SPEED_MULT_V0743)+
      ' range_damage=unchanged policies=kiter,artillery,controller')
    refresh_header
    refresh_footer
  end

  def update
    pmd_ac_v0743_update
    update_native_weather_core_v0743 if $scene == self
  end

  def terminate
    dispose_native_weather_core_v0743
    pmd_ac_v0743_terminate
  end

  def create_native_weather_core_v0743
    dispose_native_weather_core_v0743
    y = PMD_AC::WEATHER_VISUAL_BOUNDS_Y
    h = Graphics.height - PMD_AC::WEATHER_VISUAL_BOUNDS_Y -
        PMD_AC::WEATHER_VISUAL_BOUNDS_BOTTOM
    h = 1 if h < 1
    @native_weather_viewport_v0743 = Viewport.new(0,y,Graphics.width,h)
    @native_weather_viewport_v0743.z = PMD_AC::WEATHER_VISUAL_PARTICLE_Z + 20
    @native_weather_core_v0743 = Spriteset_Weather.new(@native_weather_viewport_v0743)
    @native_weather_core_v0743.ox = 0
    @native_weather_core_v0743.oy = 0
    @native_weather_type_v0743 = -1
    sync_native_weather_type_v0743
  end

  def dispose_native_weather_core_v0743
    if @native_weather_core_v0743 != nil
      begin
        @native_weather_core_v0743.dispose
      rescue
      end
      @native_weather_core_v0743 = nil
    end
    if @native_weather_viewport_v0743 != nil
      begin
        @native_weather_viewport_v0743.dispose unless @native_weather_viewport_v0743.disposed?
      rescue
      end
      @native_weather_viewport_v0743 = nil
    end
  end

  def native_weather_type_v0743
    return 0 unless @phase == :battle
    return 0 unless respond_to?(:canonical_weather)
    return 0 unless respond_to?(:canonical_weather_effective?)
    return 0 unless canonical_weather_effective?
    case canonical_weather
    when :rain
      PMD_AC::WEATHER_CORE_RAIN_TYPE_V0743
    when :hail
      PMD_AC::WEATHER_CORE_HAIL_VISUAL_TYPE_V0743
    else
      0
    end
  rescue
    0
  end

  def native_weather_max_v0743(type)
    return PMD_AC::WEATHER_CORE_RAIN_MAX_V0743 if type == PMD_AC::WEATHER_CORE_RAIN_TYPE_V0743
    return PMD_AC::WEATHER_CORE_HAIL_MAX_V0743 if type == PMD_AC::WEATHER_CORE_HAIL_VISUAL_TYPE_V0743
    0
  end

  def sync_native_weather_type_v0743
    return if @native_weather_core_v0743 == nil
    type = native_weather_type_v0743
    if @native_weather_type_v0743 != type
      @native_weather_type_v0743 = type
      @native_weather_core_v0743.type = type
      @native_weather_core_v0743.max = native_weather_max_v0743(type)
      label = type == 1 ? 'rain' : (type == 3 ? 'hail_as_snow' : 'clear')
      log_event(:weather_visual,'CORE type='+type.to_s+' label='+label+
        ' renderer=Spriteset_Weather') if @battle_log_enabled
    else
      @native_weather_core_v0743.max = native_weather_max_v0743(type)
    end
  end

  def update_native_weather_core_v0743
    return if @native_weather_core_v0743 == nil
    sync_native_weather_type_v0743
    @native_weather_core_v0743.update
  end

  def refresh_header
    return if @header_sprite == nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.74.3',1)
    bmp.font.size=PMD_AC::HEADER_SUB_FONT_V0741
    bmp.font.bold=false
    bmp.font.color=Color.new(210,220,230)
    text=''
    if @phase==:deploy
      text='戰前布陣｜D 成長/技能｜S 驗證：'+verification_mode_label+'｜Shift 開戰'
    elsif @phase==:battle
      text='AI Framework／Pixel Movement｜速度 x'+@battle_speed.to_s+'｜A 鍵切換｜B 離開'
    else
      text='戰鬥結束｜C 回到布陣｜B 離開'
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end
end
