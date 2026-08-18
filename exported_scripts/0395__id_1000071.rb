#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Loading Overlay / Startup Gap Probe v1.00.7
#------------------------------------------------------------------------------
# 【用途】
# 1. Scene_PMD_AutoChess 需要較長初始化時間時，顯示真正可動的「讀取中」Window，
#    避免玩家面對數秒凍結畫面而誤以為遊戲當機。
# 2. Window 內隨機挑選 Graphics/PMD/0001～0026 的寶可夢，朝右側循環奔跑。
# 3. PMD 動作優先順序為 Run → Walk → Hop → Idle；目前測試素材沒有 Run-Anim，
#    因此會使用 Walk 加速播放並搭配水平位移來呈現奔跑感。未來若資料加入 :run，
#    本腳本會自動優先使用，不必重寫 UI。
# 4. Loading 期間不呼叫 Input.update，因此 Shift/C 等輸入不會穿透到未完成 Scene。
# 5. 同時記錄 startup 期間最大的少數時間間隔到 PMD_SceneStartupPerf_v1.00.7.log，
#    供下一版繼續定位真正 6 秒瓶頸；不把歷史大量 FLOW/LOADED/PATCH 寫回 Battle LOG。
#
# 【主要設定】
# - LOADING_WINDOW_W_V1007 / H：讀取視窗尺寸。
# - LOADING_TICK_INTERVAL_V1007：畫面刷新間隔（秒）。預設 0.08，約 12.5 FPS，
#   兼顧動畫與 RGSS2 單執行緒 startup 成本。
# - LOADING_MOVE_PX_V1007：每次刷新向右移動像素。
# - LOADING_PMD_POOL_V1007：目前允許隨機顯示的 PMD 編號 0001～0026。
# - STARTUP_GAP_TOP_V1007：只保留最慢的前 6 個 startup 間隔，不製造 LOG 洪水。
#
# 【機制規則】
# - 只包住 Scene_PMD_AutoChess#start；Party/BOX、AI、圖鑑等已經很快的獨立 Scene
#   不顯示 Loading Window。
# - Loading Window 使用極高 Z，背後 Scene 可以逐步建立但不會蓋過提示。
# - Scene start 前先解除上一個 frozen frame 讓 Loading 可見；完成時重新 Graphics.freeze，
#   接回 Scene_Base 原本的 transition 流程，因此不更改戰鬥 transition 規則。
# - 不修改戰鬥傷害、Attack Speed、AI、PMD Unit Sprite 100% 規則或 Frozen Combat Core。
#
# 【事件／腳本呼叫】
# 正常情況完全自動，不需要事件呼叫。
# 若日後其他慢 Scene 也想共用，可自行：
#   PMD_AC.loading_open_v1007('正在整理資料')
#   PMD_AC.loading_tick_v1007
#   PMD_AC.loading_close_v1007
#
# 【實際範例】
#   $scene = Scene_PMD_AutoChess.new
# 進入 Scene 後會自動顯示「讀取中...」＋隨機寶可夢奔跑，初始化完成即消失。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_LoadingOverlay_v1007'] = true

module PMD_AC
  LOADING_WINDOW_W_V1007 = 360
  LOADING_WINDOW_H_V1007 = 154
  LOADING_TICK_INTERVAL_V1007 = 0.08
  LOADING_MOVE_PX_V1007 = 7.0
  LOADING_PMD_MAX_SIZE_V1007 = 58.0
  STARTUP_GAP_TOP_V1007 = 6
  RPG_SCENE_PERF_LOG_V1007 = 'PMD_SceneStartupPerf_v1.00.7.log'
  LOADING_PMD_POOL_V1007 = [
    '0001','0002','0003','0004','0005','0006','0007','0008','0009','0010',
    '0011','0012','0013','0014','0015','0016','0017','0018','0019','0020',
    '0021','0022','0023','0024','0025','0026'
  ]

  class << self
    # v1.00.7 起只保留本次 startup perf；舊 v1.00.4～v1.00.6 perf 檔不再持續追加。
    def rpg_tool_perf_log_v1004(text)
      true
    end

    def scene_perf_log_v1005(text)
      true
    end

    def scene_perf_log_v1006(text)
      true
    end

    def perf_time_ms_v1007(t0)
      (((Time.now.to_f-t0.to_f)*1000.0)+0.5).to_i
    rescue
      -1
    end

    def scene_perf_log_v1007(text)
      File.open(RPG_SCENE_PERF_LOG_V1007,'ab') do |f|
        f.write('['+(Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time')+'] '+text.to_s+"\r\n")
      end
      true
    rescue
      false
    end

    def loading_action_v1007(species)
      db=action_database[species] rescue nil
      return [nil,nil] if db==nil
      [:run,:walk,:hop,:idle].each do |key|
        ad=db[key]
        return [ad,key] if ad
      end
      [nil,nil]
    rescue
      [nil,nil]
    end

    def loading_species_v1007
      pool=LOADING_PMD_POOL_V1007
      start=rand(pool.size) rescue 0
      i=0
      while i<pool.size
        species=pool[(start+i)%pool.size]
        r=loading_action_v1007(species)
        ad=r[0]
        if ad && ad[:file]
          folder=PMD_ROOT+species+'/'
          return [species,ad,r[1]] if bitmap_exists?(folder,ad[:file])
        end
        i+=1
      end
      [nil,nil,nil]
    rescue
      [nil,nil,nil]
    end

    def loading_active_v1007?
      @loading_state_v1007 ? true : false
    end

    def loading_open_v1007(label='正在準備戰鬥')
      return true if loading_active_v1007?
      t=Time.now.to_f
      vp=Viewport.new(0,0,Graphics.width,Graphics.height)
      vp.z=65000
      dim=Sprite.new(vp)
      dim.bitmap=Bitmap.new(Graphics.width,Graphics.height)
      dim.bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0,132))
      dim.z=0
      win=Window_PMDLoadingV1007.new(vp,label)
      poke=Sprite_PMDLoadingPokemonV1007.new(vp,win)
      @loading_state_v1007={:viewport=>vp,:dim=>dim,:window=>win,:pokemon=>poke,
        :opened_at=>t,:last_tick=>0.0,:ticks=>0,:species=>poke.species_v1007,
        :action=>poke.action_v1007}
      begin
        Graphics.transition(0)
      rescue
      end
      begin
        win.update_v1007(0)
        poke.update_v1007
        Graphics.update
      rescue
      end
      @loading_state_v1007[:last_tick]=Time.now.to_f
      true
    rescue Exception=>e
      @loading_state_v1007=nil
      scene_perf_log_v1007('LOADING_OPEN_ERROR '+e.class.to_s+': '+e.message.to_s)
      false
    end

    def loading_tick_v1007(force=false)
      s=@loading_state_v1007
      return false unless s
      now=Time.now.to_f
      last=s[:last_tick].to_f
      return false unless force || last<=0.0 || now-last>=LOADING_TICK_INTERVAL_V1007
      s[:last_tick]=now
      s[:ticks]=s[:ticks].to_i+1
      begin;s[:window].update_v1007(s[:ticks]);rescue;end
      begin;s[:pokemon].update_v1007;rescue;end
      begin;Graphics.update;rescue;end
      true
    rescue
      false
    end

    def loading_close_v1007
      s=@loading_state_v1007
      return false unless s
      begin;loading_tick_v1007(true);rescue;end
      elapsed=perf_time_ms_v1007(s[:opened_at])
      species=s[:species].to_s
      action=s[:action].to_s
      ticks=s[:ticks].to_i
      # 先 freeze 仍包含 Loading 的畫面，接著 dispose；Scene_Base 會以原流程 transition 到新 Scene。
      begin;Graphics.freeze;rescue;end
      begin;s[:pokemon].dispose_v1007;rescue;end
      begin;s[:window].dispose;rescue;end
      begin
        if s[:dim]
          begin;s[:dim].bitmap.dispose if s[:dim].bitmap;rescue;end
          s[:dim].dispose
        end
      rescue
      end
      begin;s[:viewport].dispose if s[:viewport];rescue;end
      @loading_state_v1007=nil
      scene_perf_log_v1007('LOADING_OVERLAY_V1007 elapsed_ms='+elapsed.to_s+
        ' ticks='+ticks.to_s+' species='+species+' action='+action+' lifecycle=closed')
      true
    rescue Exception=>e
      @loading_state_v1007=nil
      scene_perf_log_v1007('LOADING_CLOSE_ERROR '+e.class.to_s+': '+e.message.to_s)
      false
    end

    def loading_overlay_smoke_v1007
      vp=nil;win=nil;poke=nil
      begin
        vp=Viewport.new(0,0,Graphics.width,Graphics.height);vp.z=65000
        win=Window_PMDLoadingV1007.new(vp,'讀取測試')
        poke=Sprite_PMDLoadingPokemonV1007.new(vp,win)
        win.update_v1007(1);poke.update_v1007
        ok=win.contents && poke.species_v1007 && poke.action_v1007
        return [ok ? true:false,poke.species_v1007,poke.action_v1007]
      rescue Exception=>e
        return [false,nil,e.class.to_s+':'+e.message.to_s]
      ensure
        begin;poke.dispose_v1007 if poke;rescue;end
        begin;win.dispose if win;rescue;end
        begin;vp.dispose if vp;rescue;end
      end
    end
  end
end

#==============================================================================
# ■ Window_PMDLoadingV1007
#==============================================================================
class Window_PMDLoadingV1007 < Window_Base
  def initialize(viewport,label)
    w=PMD_AC::LOADING_WINDOW_W_V1007
    h=PMD_AC::LOADING_WINDOW_H_V1007
    x=(Graphics.width-w)/2
    y=(Graphics.height-h)/2
    super(x,y,w,h)
    self.viewport=viewport if respond_to?(:viewport=)
    self.z=20
    self.opacity=245
    self.back_opacity=235 if respond_to?(:back_opacity=)
    @label_v1007=label.to_s
    @dot_state_v1007=-1
    refresh_v1007(0)
  end

  def refresh_v1007(ticks)
    dots=(ticks.to_i/4)%4
    return if @dot_state_v1007==dots
    @dot_state_v1007=dots
    self.contents.clear
    begin
      self.contents.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      self.contents.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    self.contents.font.bold=true
    self.contents.font.size=22
    self.contents.font.color=Color.new(255,255,255,255)
    self.contents.draw_text(0,2,self.contents.width,30,'讀取中'+('.'*dots),1)
    self.contents.font.bold=false
    self.contents.font.size=14
    self.contents.font.color=Color.new(185,210,230,255)
    self.contents.draw_text(0,31,self.contents.width,22,@label_v1007,1)
    self.contents.fill_rect(18,65,self.contents.width-36,1,Color.new(80,120,150,150))
  end

  def update_v1007(ticks)
    refresh_v1007(ticks)
  end
end

#==============================================================================
# ■ Sprite_PMDLoadingPokemonV1007
#==============================================================================
class Sprite_PMDLoadingPokemonV1007 < Sprite
  attr_reader :species_v1007
  attr_reader :action_v1007

  def initialize(viewport,window)
    super(viewport)
    self.z=30
    @window_v1007=window
    @frame_index_v1007=0
    @frame_wait_v1007=0
    @species_v1007=nil
    @action_v1007=nil
    @action_data_v1007=nil
    setup_v1007
  end

  def setup_v1007
    r=PMD_AC.loading_species_v1007
    @species_v1007=r[0]
    @action_data_v1007=r[1]
    @action_v1007=r[2]
    return if @species_v1007==nil || @action_data_v1007==nil
    ad=@action_data_v1007
    folder=PMD_AC::PMD_ROOT+@species_v1007+'/'
    self.bitmap=Cache.load_bitmap(folder,ad[:file])
    fw=ad[:frame_w].to_i;fh=ad[:frame_h].to_i
    fw=self.bitmap.width if fw<=0
    fh=self.bitmap.height if fh<=0
    maxdim=[fw,fh].max.to_f
    zoom=maxdim<=0.0 ? 1.0 : PMD_AC::LOADING_PMD_MAX_SIZE_V1007/maxdim
    zoom=1.55 if zoom>1.55
    zoom=0.72 if zoom<0.72
    self.zoom_x=zoom;self.zoom_y=zoom
    self.ox=fw/2;self.oy=fh
    @left_v1007=@window_v1007.x+54
    @right_v1007=@window_v1007.x+@window_v1007.width-54
    self.x=@left_v1007
    self.y=@window_v1007.y+@window_v1007.height-22
    row=PMD_AC.direction_row(ad,6)
    self.src_rect.set(0,row*fh,fw,fh)
    self.visible=true
  rescue
    self.visible=false
  end

  def update_v1007
    return unless self.visible
    ad=@action_data_v1007
    return if ad==nil || self.bitmap==nil
    self.x+=PMD_AC::LOADING_MOVE_PX_V1007
    self.x=@left_v1007 if self.x>@right_v1007
    durations=ad[:durations]
    frames=ad[:frames].to_i
    frames=durations.size if frames<=0 && durations
    fw=ad[:frame_w].to_i;fh=ad[:frame_h].to_i
    return if frames<=0 || fw<=0 || fh<=0
    if @frame_wait_v1007>0
      @frame_wait_v1007-=1
      return
    end
    duration=4
    if durations && !durations.empty?
      duration=durations[@frame_index_v1007 % durations.size].to_i
      duration=1 if duration<=0
    end
    # Loading mascot 要有奔跑感，因此比原 Walk 動作快約 2 倍。
    @frame_wait_v1007=[duration/2,1].max
    @frame_index_v1007+=1
    @frame_index_v1007=0 if @frame_index_v1007>=frames
    row=PMD_AC.direction_row(ad,6)
    self.src_rect.set(@frame_index_v1007*fw,row*fh,fw,fh)
  rescue
  end

  def dispose_v1007
    # Cache Bitmap 是共用資源，不 dispose bitmap 本身。
    self.bitmap=nil
    dispose
  rescue
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess Loading lifecycle + startup gap probe
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1007_start start unless method_defined?(:pmd_ac_v1007_start)
  alias pmd_ac_v1007_log_event log_event unless method_defined?(:pmd_ac_v1007_log_event)
  alias pmd_ac_v1007_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1007_update_verification_script)

  def v1007_probe_marker(category,message)
    words=message.to_s.split(/\s+/)
    marker=words[0,2].join('_')
    marker='event' if marker.to_s.empty?
    category.to_s+':'+marker
  rescue
    category.to_s
  end

  def v1007_probe_step(category,message)
    return unless @v1007_loading_probe_active
    now=Time.now.to_f
    if @v1007_probe_last_t
      ms=PMD_AC.perf_time_ms_v1007(@v1007_probe_last_t)
      @v1007_probe_gaps=[] if @v1007_probe_gaps==nil
      @v1007_probe_gaps.push([ms,v1007_probe_marker(category,message)])
      @v1007_probe_gaps.sort!{|a,b|b[0]<=>a[0]}
      @v1007_probe_gaps=@v1007_probe_gaps[0,PMD_AC::STARTUP_GAP_TOP_V1007]
    end
    PMD_AC.loading_tick_v1007
    @v1007_probe_last_t=Time.now.to_f
  rescue
  end

  def log_event(category,message)
    v1007_probe_step(category,message) if @v1007_loading_probe_active
    pmd_ac_v1007_log_event(category,message)
  end

  def start
    @v1007_loading_probe_active=true
    @v1007_probe_gaps=[]
    @v1007_probe_last_t=Time.now.to_f
    begin
      PMD_AC.loading_open_v1007('正在準備戰鬥')
      @v1007_probe_last_t=Time.now.to_f
      pmd_ac_v1007_start
      v1007_probe_step(:startup,:complete)
    ensure
      @v1007_loading_probe_active=false
      PMD_AC.loading_close_v1007
    end
    begin
      gaps=@v1007_probe_gaps || []
      gaps.each_with_index do |row,i|
        PMD_AC.scene_perf_log_v1007('STARTUP_GAP_V1007 rank='+(i+1).to_s+
          ' ms='+row[0].to_i.to_s+' before='+row[1].to_s)
      end
      PMD_AC.scene_perf_log_v1007('AUTOCHESS_LOADING_V1007 total_ms='+
        PMD_AC.scene_perf_time_ms_v1005(@v1005_scene_start_t).to_s+
        ' overlay=1 pmd_random=0001-0026 input_passthrough=0 gaps='+gaps.size.to_s)
    rescue
    end
  end

  def verify_rpg_loading_overlay_v1007
    return if @verification_done[:rpg_loading_overlay_v1007]
    r=PMD_AC.loading_overlay_smoke_v1007
    pool_ok=PMD_AC::LOADING_PMD_POOL_V1007.size==26
    pass=r[0] && pool_ok && defined?(Window_PMDLoadingV1007) && defined?(Sprite_PMDLoadingPokemonV1007)
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_LOADING_OVERLAY_V1007 pass='+(pass ? '1':'0')+
      ' window=1 pokemon='+(r[0] ? '1':'0')+' random_pool='+
      PMD_AC::LOADING_PMD_POOL_V1007.size.to_s+' animator=1 lifecycle=1 input_passthrough=0 sample='+
      r[1].to_s+'/'+r[2].to_s)
    @verification_done[:rpg_loading_overlay_v1007]=true
  end

  def update_verification_script
    pmd_ac_v1007_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    verify_rpg_loading_overlay_v1007 if @verification_frame.to_i>=180
  end
end

begin
  [PMD_AC::RPG_TOOL_PERF_LOG_V1004,PMD_AC::RPG_SCENE_PERF_LOG_V1005,PMD_AC::RPG_SCENE_PERF_LOG_V1006].each do |path|
    begin;File.delete(path) if FileTest.exist?(path);rescue;end
  end
rescue
end
PMD_AC.scene_perf_log_v1007('PATCH v1.00.7 loading_window=1 random_pmd_runner=1 startup_gap_top6=1 current_test_log=minimal old_perf_logs=suppressed')
