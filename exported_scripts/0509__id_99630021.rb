# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Basic Attack Readability Authority v1.05.24
#===============================================================================
# 【用途】
# 1. 修正 v1.05.23 將 ranged basic projectile Sprite 完全隱藏後，玩家無法直觀看出
#    「誰正在攻擊誰」的問題。
# 2. 依使用者指定的正式視覺語言，建立普通攻擊的可讀性 Authority：
#    小型屬性飛行球負責表示攻擊路徑；命中後由目標位置噴發多顆屬性色小光點，
#    負責表示「已命中」。兩者都保持固定小型尺度，不隨寶可夢進化／Sprite 尺寸放大。
# 3. 強化 v1.05.22 / v1.05.23 過於不明顯的 basic hit spark：
#    由 4 顆、12f、3x3 可見核心，調整為 6 顆、16f、較清楚的 5x5 色彩核心與白色中心。
# 4. 保留 v1.05.23 Pure Status Impact Allowlist：叫聲／吐絲／催眠粉等純狀態技能仍不可
#    生成 Ranger_222、大型 SkillImpact、basic hit particle 等不相干的攻擊命中特效。
# 5. 本腳本僅調整 Presentation，不改 Damage、HP、AI、Energy、Attack Wait、Priority、
#    logical projectile、collision、tracking、飛行速度、命中時機、Spatial endpoint。
#
# 【實機依據】
# - v1.05.23 Windows LOG 明確記錄 ranged basic 為 sprite_hidden=1。
# - 同一 LOG 的 basic hit spark 為 particles=4，且實機影片中命中光點非常不明顯。
# - 使用者指定：普攻必須保留小型飛行球以看懂目標；飛行球打中後再噴小光點。
#
# 【正式機制規則】
# A. Ranged Basic 飛行球
# - logical projectile 完整保留。
# - Sprite 恢復 visible=true。
# - 固定 zoom=0.26，約為既有 Ranger projectile 顯示尺寸的 1/4 左右。
# - basic projectile 不使用 Ranger trail，避免小型飛行球又拖出技能級尾焰。
# - 不依 species stage、species size、PMD sprite 尺寸放大。
#
# B. Basic 命中光點
# - melee / ranged basic 共用。
# - 每次命中 6 顆屬性色粒子，從目標中心向左右／斜上／斜下方向噴散。
# - 生命 16f，最大位移約 22px，帶極輕微下墜。
# - Bitmap 9x9 邊界；可見區由 7x7 低透明 halo、5x5 屬性色核心、3x3 白亮中心組成。
# - 仍屬「小型命中訊號」，不使用 Ranger_222 或其他大型技能 impact。
#
# C. Pure Status 保護
# - v1.05.23 的 add_vfx_impact / add_vfx_impact_xy block 保留。
# - 新增的 Sprite_PMDBasicHitParticleV10524 也被納入 pure-status purge 與 Focus carryover transient。
# - 因此叫聲結果只保留 -攻擊、藍色下降多光圈、Result Hold 等既定狀態語言。
#
# 【主要設定／可調參數】
# BASIC_PROJECTILE_VISIBLE_SCALE_V10524 = 0.26
#   ranged basic 小型飛行球顯示縮放。只改畫面，不改 logical radius。
# BASIC_PROJECTILE_VISIBLE_OPACITY_V10524 = 238
#   飛行球透明度。
# BASIC_HIT_PARTICLE_COUNT_V10524 = 6
#   每次 basic 命中粒子數。
# BASIC_HIT_PARTICLE_FRAMES_V10524 = 16
#   粒子存在時間。
# BASIC_HIT_PARTICLE_SPREAD_V10524 = 22.0
#   粒子由目標中心向外擴散的最大基準距離。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.22 / v1.05.23 後、Main 前。
# - 依賴 Sprite_PMDProjectile、Scene_PMD_AutoChess、v1.05.22 basic visual context、
#   v1.05.23 Pure Status Impact Allowlist。
# - 不直接修改 Frozen Motion Core。
#
# 【事件／腳本呼叫方式】
# - 無需事件呼叫。NORMAL 戰鬥自動生效。
# - F6 Important/Boss fixture 保持 v1.05.19 原規格。
#
# 【LOG】
# BATTLE_BASIC_ATTACK_READABILITY_V10524 START ...
# BATTLE_BASIC_PROJECTILE_VISIBLE_V10524 style=... scale=0.26 trail=0 ...
# BATTLE_BASIC_HIT_SPARK_V10524 style=... particles=6 frames=16 spread=22.0
# BATTLE_BASIC_ATTACK_READABILITY_SUMMARY_V10524 ...
#
# 【實際範例】
# 1. 小火龍 ranged basic：一顆小型火色飛行球由小火龍飛向目標，命中後目標身上
#    噴出 6 顆橘紅色小光點；不播放大型 Ranger_222 火球爆炸。
# 2. 傑尼龜 ranged basic：一顆小型水色飛行球飛向目標，命中後噴出 6 顆青藍光點。
# 3. 噴火龍 ranged basic：飛行球與命中粒子維持相同固定尺度，不因進化直接放大。
# 4. 小火龍使用叫聲：不生成 basic 飛行球，也不生成 basic hit spark，只顯示狀態結果語言。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BasicAttackReadabilityAuthority_v10524']=true

module PMD_AC
  BASIC_PROJECTILE_VISIBLE_SCALE_V10524 = 0.26
  BASIC_PROJECTILE_VISIBLE_OPACITY_V10524 = 238
  BASIC_HIT_PARTICLE_COUNT_V10524 = 6
  BASIC_HIT_PARTICLE_FRAMES_V10524 = 16
  BASIC_HIT_PARTICLE_SPREAD_V10524 = 22.0

  @basic_hit_particle_bitmap_cache_v10524 = {}

  def self.basic_hit_particle_bitmap_v10524(style)
    @basic_hit_particle_bitmap_cache_v10524={} if @basic_hit_particle_bitmap_cache_v10524==nil
    key=style || :normal
    bmp=@basic_hit_particle_bitmap_cache_v10524[key]
    return bmp if bmp!=nil && !bmp.disposed?
    rgb=basic_hit_rgb_v10522(key)
    bmp=Bitmap.new(9,9)
    bmp.clear
    bmp.fill_rect(1,1,7,7,Color.new(rgb[0],rgb[1],rgb[2],58))
    bmp.fill_rect(2,2,5,5,Color.new(rgb[0],rgb[1],rgb[2],220))
    bmp.fill_rect(3,3,3,3,Color.new(255,255,255,242))
    @basic_hit_particle_bitmap_cache_v10524[key]=bmp
    bmp
  rescue
    nil
  end
end

#===============================================================================
# ■ Sprite_PMDBasicHitParticleV10524
#------------------------------------------------------------------------------
# v1.05.24 專用 basic 命中粒子。只持有 Presentation state。
#===============================================================================
class Sprite_PMDBasicHitParticleV10524 < Sprite
  attr_reader :finished

  def initialize(viewport,x,y,style,index)
    super(viewport)
    @origin_x=x.to_f
    @origin_y=y.to_f
    @age=0
    @finished=false
    @frames=PMD_AC::BASIC_HIT_PARTICLE_FRAMES_V10524
    angles=[-24.0,-72.0,-142.0,142.0,72.0,24.0]
    deg=angles[index.to_i % angles.size]
    rad=deg*Math::PI/180.0
    base=PMD_AC::BASIC_HIT_PARTICLE_SPREAD_V10524.to_f/[[@frames-1,1].max,1].max.to_f
    speed=base*(0.92+(index.to_i%3)*0.09)
    @vx=Math.cos(rad)*speed
    @vy=Math.sin(rad)*speed
    self.bitmap=PMD_AC.basic_hit_particle_bitmap_v10524(style)
    self.ox=4
    self.oy=4
    self.x=@origin_x.to_i
    self.y=@origin_y.to_i
    self.z=9360
    self.blend_type=1
    self.opacity=250
  end

  def update
    super
    return if @finished
    @age+=1
    self.x=(@origin_x+@vx*@age).round
    self.y=(@origin_y+@vy*@age+0.028*@age*@age).round
    t=@age.to_f/[[@frames,1].max,1].max.to_f
    self.opacity=PMD_AC.clamp((250*(1.0-t)).round,0,255)
    z=1.0-0.16*t
    self.zoom_x=z
    self.zoom_y=z
    if @age>=@frames
      @finished=true
      self.visible=false
    end
  rescue
    @finished=true
    self.visible=false
  end

  def dispose
    self.bitmap=nil
    super
  end
end

#===============================================================================
# ■ Ranged basic projectile：恢復小型可見飛行球，停用技能級 trail
#===============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v10524_basic_initialize initialize unless method_defined?(:pmd_ac_v10524_basic_initialize)

  def initialize(*args)
    pmd_ac_v10524_basic_initialize(*args)
    begin
      if @kind==:basic
        @pmd_basic_target_only_v10523=false
        self.visible=true
        self.zoom_x=PMD_AC::BASIC_PROJECTILE_VISIBLE_SCALE_V10524
        self.zoom_y=PMD_AC::BASIC_PROJECTILE_VISIBLE_SCALE_V10524
        self.opacity=PMD_AC::BASIC_PROJECTILE_VISIBLE_OPACITY_V10524
        if @pmd_skill_visual_profile_v030!=nil
          p=@pmd_skill_visual_profile_v030.dup
          p[:trail]=false
          @pmd_skill_visual_profile_v030=p
        end
        if @scene!=nil && @scene.respond_to?(:basic_projectile_visible_note_v10524)
          @scene.basic_projectile_visible_note_v10524(self)
        end
      end
    rescue
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10524_start_battle start_battle unless method_defined?(:pmd_ac_v10524_start_battle)
  alias pmd_ac_v10524_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10524_focus_summary)
  alias pmd_ac_v10524_status_forbidden status_forbidden_effect_sprite_v10523? unless method_defined?(:pmd_ac_v10524_status_forbidden)
  alias pmd_ac_v10524_focus_transient focus_carryover_transient_v10522? unless method_defined?(:pmd_ac_v10524_focus_transient)

  # v1.05.23 initialize 會先要求 target-only hidden；v1.05.24 已退休該規則。
  # 動態 method dispatch 會落到這裡，因此不再把該 request 計入「實際 hidden」統計。
  def basic_projectile_target_only_note_v10523(projectile)
    @basic_projectile_legacy_hide_request_v10524=@basic_projectile_legacy_hide_request_v10524.to_i+1
    true
  rescue
    false
  end

  def basic_projectile_visible_note_v10524(projectile)
    @basic_projectile_visible_v10524=@basic_projectile_visible_v10524.to_i+1
    if @basic_projectile_visible_v10524<=6
      style=nil
      begin;style=projectile.style;rescue;style=nil;end
      log_event(:battle,'BATTLE_BASIC_PROJECTILE_VISIBLE_V10524 style='+(style==nil ? 'NONE' : style.to_s)+
        ' scale='+PMD_AC::BASIC_PROJECTILE_VISIBLE_SCALE_V10524.to_s+
        ' opacity='+PMD_AC::BASIC_PROJECTILE_VISIBLE_OPACITY_V10524.to_s+
        ' trail=0 logical_radius_unchanged=1 speed_unchanged=1 tracking_unchanged=1')
    end
    true
  rescue
    false
  end

  # 覆寫 v1.05.22 的 basic hit spark factory：改用 6 顆較清楚的新粒子。
  def add_basic_hit_sparks_v10522(x,y,style)
    return false if @effect_sprites==nil
    key=basic_attack_particle_style_v10522(style)
    count=PMD_AC::BASIC_HIT_PARTICLE_COUNT_V10524
    i=0
    while i<count
      @effect_sprites.push(Sprite_PMDBasicHitParticleV10524.new(@viewport,x,y,key,i))
      i+=1
    end
    @basic_hit_spark_events_v10522=@basic_hit_spark_events_v10522.to_i+1
    @basic_hit_spark_particles_v10522=@basic_hit_spark_particles_v10522.to_i+count
    @basic_hit_spark_events_v10524=@basic_hit_spark_events_v10524.to_i+1
    @basic_hit_spark_particles_v10524=@basic_hit_spark_particles_v10524.to_i+count
    if @basic_hit_spark_events_v10524<=8
      log_event(:battle,'BATTLE_BASIC_HIT_SPARK_V10524 style='+key.to_s+
        ' particles='+count.to_s+
        ' frames='+PMD_AC::BASIC_HIT_PARTICLE_FRAMES_V10524.to_s+
        ' spread='+PMD_AC::BASIC_HIT_PARTICLE_SPREAD_V10524.to_s+
        ' fixed_scale=1 evolution_independent=1')
    end
    true
  rescue
    false
  end

  # Pure Status 仍必須能清掉上一個 basic 的 v1.05.24 粒子。
  def status_forbidden_effect_sprite_v10523?(sp)
    return true if sp!=nil && sp.class.to_s=='Sprite_PMDBasicHitParticleV10524'
    pmd_ac_v10524_status_forbidden(sp)
  rescue
    false
  end

  def focus_carryover_transient_v10522?(sp)
    return true if sp!=nil && sp.class.to_s=='Sprite_PMDBasicHitParticleV10524'
    pmd_ac_v10524_focus_transient(sp)
  rescue
    false
  end

  def basic_attack_readability_reset_v10524
    @basic_projectile_visible_v10524=0
    @basic_projectile_legacy_hide_request_v10524=0
    @basic_hit_spark_events_v10524=0
    @basic_hit_spark_particles_v10524=0
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10524_start_battle
    basic_attack_readability_reset_v10524
    if respond_to?(:verification_mode) && verification_mode==:normal
      log_event(:battle,'BATTLE_BASIC_ATTACK_READABILITY_V10524 START'+
        ' ranged_projectile=small_visible projectile_scale='+PMD_AC::BASIC_PROJECTILE_VISIBLE_SCALE_V10524.to_s+
        ' projectile_trail=0 hit_particles='+PMD_AC::BASIC_HIT_PARTICLE_COUNT_V10524.to_s+
        ' particle_frames='+PMD_AC::BASIC_HIT_PARTICLE_FRAMES_V10524.to_s+
        ' particle_spread='+PMD_AC::BASIC_HIT_PARTICLE_SPREAD_V10524.to_s+
        ' evolution_independent=1 v10523_target_only_retired=1 status_allowlist_retained=1'+
        ' damage_unchanged=1 collision_unchanged=1 speed_unchanged=1 tracking_unchanged=1 hit_timing_unchanged=1')
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10524_focus_summary
    log_event(:battle,'BATTLE_BASIC_ATTACK_READABILITY_SUMMARY_V10524'+
      ' projectiles_visible='+@basic_projectile_visible_v10524.to_i.to_s+
      ' legacy_hide_requests_overridden='+@basic_projectile_legacy_hide_request_v10524.to_i.to_s+
      ' hit_events='+@basic_hit_spark_events_v10524.to_i.to_s+
      ' particles='+@basic_hit_spark_particles_v10524.to_i.to_s+
      ' projectile_scale='+PMD_AC::BASIC_PROJECTILE_VISIBLE_SCALE_V10524.to_s+
      ' particles_per_hit='+PMD_AC::BASIC_HIT_PARTICLE_COUNT_V10524.to_s+
      ' particle_frames='+PMD_AC::BASIC_HIT_PARTICLE_FRAMES_V10524.to_s+
      ' trail=0 evolution_independent=1 status_allowlist_retained=1')
    r
  rescue
    false
  end
end
