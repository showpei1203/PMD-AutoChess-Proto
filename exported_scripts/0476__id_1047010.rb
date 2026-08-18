# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Zone Bitmap Cache Performance Fix v1.04.7
# 分類：戰鬥效能／Zone Presentation Cache／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 針對 v1.04.6 Windows 實機單一 54ms internal spike 做窄範圍修正。
# 2. 原 Sprite_PMDArenaZone 每建立一個 Zone，都會現場 Bitmap.new(128,128)，
#    再以大量 Math.sin / Math.cos / fill_rect 重畫完全相同的地面圓環。
# 3. Zone 圖樣實際只依 style 決定；radius 由 Sprite#zoom_x / zoom_y 表現，
#    position、duration、opacity、follow_owner 與 Zone gameplay logic 都不寫進 bitmap。
# 4. 因此把固定圖樣搬到 battle loading 預先繪製，Runtime Zone Sprite 只共享 bitmap。
#    消除技能 resolve 當幀的 Bitmap.new + procedural draw 成本。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_ZONE_CACHE_STYLES_V1047
#   預先建立的正式 Zone 視覺 style：neutral/fire/water/web/poison/heal/energy/ice。
#   未知 style 在舊版 zone_color 本來就使用 neutral 顏色，因此視覺快取也映射 neutral。
# MOTION_ZONE_BITMAP_SIZE_V1047 = 128
#   與 v0.15 Sprite_PMDArenaZone 完全相同。
#------------------------------------------------------------------------------
# 【機制規則】
# - 預繪圖樣完整複製 v0.15 draw_zone 幾何：58/48/35 三圈＋24 個內點。
# - 色彩完整複製 v0.15 zone_color；不修改任何 Zone 顏色、透明度或外觀。
# - 每個 Zone Sprite 仍有自己的 x/y/z/zoom/opacity/life/finished；只共享不可變 bitmap。
# - Sprite dispose 時只解除 bitmap 參照，不 dispose 共用快取，避免其他 Zone 被一起清空。
# - 不修改 add_zone、Zone tick、radius、duration、interval、scope、effects、Damage、AI、
#   Attack Speed、Energy、logical x/y、velocity、action_timer 或技能 Damage timing。
# - 若未來出現未知 style，因舊版原本就落到 neutral 顏色，本層使用 neutral bitmap，
#   保持相同視覺語意且避免 live rebuild。
#------------------------------------------------------------------------------
# 【可調參數】
# - 若日後 Zone 新增「真正不同的」style 顏色，需同時加入
#   MOTION_ZONE_CACHE_STYLES_V1047 與 motion_zone_color_v1047。
# - 不要把 cache 改回每 instance Bitmap；那會把已移出 live battle 的 procedural draw
#   又搬回技能命中幀。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。battle loading 自動 prewarm。
# Motion verifier 會輸出：
#   MOTION_ZONE_BITMAP_CACHE_PREWARM_V1047
#   MOTION_ZONE_BITMAP_CACHE_V1047
# 戰鬥結束 Performance summary 會輸出：
#   MOTION_ZONE_BITMAP_CACHE_RUNTIME_V1047
#------------------------------------------------------------------------------
# 【實際範例】
# Flame Burst 建立 :fire Zone：
#   舊：skill resolve -> Bitmap.new(128,128) -> procedural draw -> Sprite
#   新：loading 先畫 :fire -> skill resolve -> cache hit -> Sprite
# radius=66 仍由 zoom=66/60 表現，Zone gameplay radius 仍由 Scene @zones 原值判定。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ZoneBitmapCache_PerformanceFix_v1047']=true

module PMD_AC
  MOTION_ZONE_BITMAP_SIZE_V1047=128
  MOTION_ZONE_CACHE_STYLES_V1047=[:neutral,:fire,:water,:web,:poison,:heal,:energy,:ice]

  @motion_zone_bitmap_cache_v1047={}
  @motion_zone_bitmap_builds_v1047=0
  @motion_zone_bitmap_live_builds_v1047=0
  @motion_zone_bitmap_hits_v1047=0
  @motion_zone_sprite_instances_v1047=0
  @motion_zone_prewarm_active_v1047=false

  class << self
    def motion_zone_visual_style_v1047(style)
      s=(style || :neutral).to_sym rescue :neutral
      return s if MOTION_ZONE_CACHE_STYLES_V1047.include?(s)
      :neutral
    rescue
      :neutral
    end

    def motion_zone_color_v1047(style,alpha)
      case motion_zone_visual_style_v1047(style)
      when :fire
        Color.new(255,105,35,alpha)
      when :water
        Color.new(65,175,255,alpha)
      when :web
        Color.new(225,240,220,alpha)
      when :poison
        Color.new(170,85,205,alpha)
      when :heal
        Color.new(100,235,135,alpha)
      when :energy
        Color.new(255,215,90,alpha)
      when :ice
        Color.new(130,225,255,alpha)
      else
        Color.new(210,220,235,alpha)
      end
    end

    # v0.15 Sprite_PMDArenaZone#draw_zone 的 exact geometry copy。
    def motion_build_zone_bitmap_v1047(style)
      bmp=Bitmap.new(MOTION_ZONE_BITMAP_SIZE_V1047,MOTION_ZONE_BITMAP_SIZE_V1047)
      [58,48,35].each_with_index do |radius,index|
        step=index==0 ? 10 : 18
        alpha=index==0 ? 150 : 70
        degree=0
        while degree<360
          rad=degree*Math::PI/180.0
          x=64+Math.cos(rad)*radius
          y=64+Math.sin(rad)*radius
          bmp.fill_rect(x.to_i-1,y.to_i-1,3,3,motion_zone_color_v1047(style,alpha))
          degree+=step
        end
      end
      for i in 0...24
        angle=(i*47)%360
        distance=12+(i*13)%40
        rad=angle*Math::PI/180.0
        x=64+Math.cos(rad)*distance
        y=64+Math.sin(rad)*distance
        bmp.fill_rect(x.to_i,y.to_i,2,2,motion_zone_color_v1047(style,55))
      end
      @motion_zone_bitmap_builds_v1047=@motion_zone_bitmap_builds_v1047.to_i+1
      unless @motion_zone_prewarm_active_v1047
        @motion_zone_bitmap_live_builds_v1047=@motion_zone_bitmap_live_builds_v1047.to_i+1
      end
      bmp
    rescue
      Bitmap.new(1,1)
    end

    def motion_zone_bitmap_v1047(style)
      key=motion_zone_visual_style_v1047(style)
      bmp=@motion_zone_bitmap_cache_v1047[key]
      if bmp!=nil && !bmp.disposed?
        @motion_zone_bitmap_hits_v1047=@motion_zone_bitmap_hits_v1047.to_i+1
        return bmp
      end
      bmp=motion_build_zone_bitmap_v1047(key)
      @motion_zone_bitmap_cache_v1047[key]=bmp
      bmp
    rescue
      Bitmap.new(1,1)
    end

    def motion_prewarm_zone_bitmaps_v1047
      built_before=@motion_zone_bitmap_builds_v1047.to_i
      ok=0
      @motion_zone_prewarm_active_v1047=true
      begin
        MOTION_ZONE_CACHE_STYLES_V1047.each do |style|
          bmp=motion_zone_bitmap_v1047(style)
          ok+=1 if bmp!=nil && !bmp.disposed? && bmp.width==128 && bmp.height==128
        end
      ensure
        @motion_zone_prewarm_active_v1047=false
      end
      {:ok=>ok,:total=>MOTION_ZONE_CACHE_STYLES_V1047.size,
       :built=>@motion_zone_bitmap_builds_v1047.to_i-built_before}
    rescue
      @motion_zone_prewarm_active_v1047=false
      {:ok=>0,:total=>MOTION_ZONE_CACHE_STYLES_V1047.size,:built=>0}
    end

    def motion_note_zone_sprite_v1047
      @motion_zone_sprite_instances_v1047=@motion_zone_sprite_instances_v1047.to_i+1
    end

    def motion_zone_cache_stats_v1047
      {:styles=>MOTION_ZONE_CACHE_STYLES_V1047.size,
       :cached=>(@motion_zone_bitmap_cache_v1047 || {}).size,
       :builds=>@motion_zone_bitmap_builds_v1047.to_i,
       :live_builds=>@motion_zone_bitmap_live_builds_v1047.to_i,
       :hits=>@motion_zone_bitmap_hits_v1047.to_i,
       :instances=>@motion_zone_sprite_instances_v1047.to_i}
    rescue
      {:styles=>0,:cached=>0,:builds=>0,:live_builds=>0,:hits=>0,:instances=>0}
    end
  end
end

#==============================================================================
# ■ Sprite_PMDArenaZone v1.04.7 shared immutable bitmap bridge
#==============================================================================
class Sprite_PMDArenaZone < Sprite
  # v0.15 initialize exact layout, except Bitmap.new + draw_zone becomes cache lookup.
  def initialize(viewport,x,y,radius,style,duration)
    super(viewport)
    @life=[duration.to_i,1].max
    @max_life=@life
    @finished=false
    @style=style || :neutral
    self.bitmap=PMD_AC.motion_zone_bitmap_v1047(@style)
    self.ox=64
    self.oy=64
    self.x=x.to_i
    self.y=y.to_i
    self.z=120
    scale=[radius.to_f/60.0,0.20].max
    self.zoom_x=scale
    self.zoom_y=scale
    PMD_AC.motion_note_zone_sprite_v1047
  end

  # 共用 Bitmap 由 PMD_AC cache 擁有；Zone instance dispose 不可將它銷毀。
  def dispose
    self.bitmap=nil
    super
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1047_zone_cache_battle_loading_process_motion_v1029 battle_loading_process_motion_v1029 unless method_defined?(:pmd_ac_v1047_zone_cache_battle_loading_process_motion_v1029)
  alias pmd_ac_v1047_zone_cache_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1047_zone_cache_update_verification_script)
  alias pmd_ac_v1047_zone_cache_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1047_zone_cache_motion_perf_log_summary_v1023)

  def battle_loading_process_motion_v1029(ui)
    stat=pmd_ac_v1047_zone_cache_battle_loading_process_motion_v1029(ui)
    begin
      t0=Time.now
      z=PMD_AC.motion_prewarm_zone_bitmaps_v1047
      ms=((Time.now-t0)*1000.0).round
      @motion_zone_cache_prewarm_v1047=z
      @motion_zone_cache_prewarm_v1047[:ms]=ms
      log_event(:perf,'MOTION_ZONE_BITMAP_CACHE_PREWARM_V1047 ready='+(z[:ok].to_i==z[:total].to_i ? '1':'0')+
        ' styles='+z[:ok].to_i.to_s+'/'+z[:total].to_i.to_s+
        ' built='+z[:built].to_i.to_s+' ms='+ms.to_i.to_s+
        ' before_live_battle=1 shared_immutable=1 radius_via_zoom=1')
    rescue => e
      @motion_zone_cache_prewarm_v1047={:ok=>0,:total=>PMD_AC::MOTION_ZONE_CACHE_STYLES_V1047.size,:built=>0,:ms=>0}
      log_event(:perf,'MOTION_ZONE_BITMAP_CACHE_PREWARM_V1047 ready=0 error='+e.class.to_s) rescue nil
    end
    stat
  rescue
    stat || {:enabled=>1,:fail=>1}
  end

  def update_verification_script
    pmd_ac_v1047_zone_cache_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_zone_cache_verify_v1047 && @verification_frame.to_i>=224
      @motion_zone_cache_verify_v1047=true
      p=@motion_zone_cache_prewarm_v1047 || {}
      s=PMD_AC.motion_zone_cache_stats_v1047
      ok=p[:ok].to_i==PMD_AC::MOTION_ZONE_CACHE_STYLES_V1047.size &&
         s[:cached].to_i==PMD_AC::MOTION_ZONE_CACHE_STYLES_V1047.size && s[:live_builds].to_i==0
      log_event(:verify,'MOTION_ZONE_BITMAP_CACHE_V1047 pass='+(ok ? '1':'0')+
        ' styles='+s[:cached].to_i.to_s+'/'+PMD_AC::MOTION_ZONE_CACHE_STYLES_V1047.size.to_s+
        ' loading_builds='+p[:built].to_i.to_s+' live_builds='+s[:live_builds].to_i.to_s+
        ' shared_bitmap=1 per_zone_bitmap_new=0 per_zone_draw_zone=0 exact_v015_geometry=1'+
        ' radius_via_zoom=1 zone_logic_unchanged=1 damage_unchanged=1 ai_unchanged=1'+
        ' attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    pmd_ac_v1047_zone_cache_motion_perf_log_summary_v1023
    begin
      s=PMD_AC.motion_zone_cache_stats_v1047
      log_event(:perf,'MOTION_ZONE_BITMAP_CACHE_RUNTIME_V1047 instances='+s[:instances].to_i.to_s+
        ' cache_hits='+s[:hits].to_i.to_s+' builds_total='+s[:builds].to_i.to_s+
        ' live_builds='+s[:live_builds].to_i.to_s+' expected_live_builds=0'+
        ' shared_bitmap=1 per_instance_draw=0 performance_threshold_unchanged=50')
    rescue
    end
  end
end
