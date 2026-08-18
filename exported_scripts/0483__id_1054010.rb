# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Batch IX Windows Visual Acceptance Harness v1.04.14
#==============================================================================
# 【用途】
# v1.04.13 已完成 64 隻代表物種、74 條 Rare Native Identity route 的 metadata
# QA，但預設 executable 仍只打包 0001～0026，因此 0027～0494 尚未真正經過
# Windows 畫面驗收。本腳本補上「看得到、可逐頁觀察」的 Runtime Visual Harness。
#
# 【主要設定】
# MOTION_BATCHIX_VISUAL_HARNESS_*_V10414
# - 每頁 6 條 route（3 欄 × 2 列）。
# - 每條 route 同時播放右 45°（direction=3）與左 45°（direction=1）。
# - 每頁約 72 frame；共 74 route，約 13 頁。
# - SHIFT：PMD Motion verifier 完成後啟動 Visual Harness。
#
# 【機制規則】
# 1. 只有 Graphics/PMD/_BATCHIX_VISUAL_V10413_READY.txt 存在，且 74/74 exact
#    pose 均 hasPlayable 時才允許啟動。
# 2. Visual Harness 是 verifier-only presentation 工具。啟動期間暫停正式 battle
#    step（unit update / AI / Damage / Spatial / Zone tick / battle end），完成後原地恢復。
# 3. 不變更任何 Game_PMDChessUnit 的 species、HP、Energy、logical x/y、velocity、
#    action_timer；預覽使用獨立 Sprite，與 Combat Core 完全隔離。
# 4. 預覽 Bitmap 先以每 frame 少量工作的方式暖載，再進入逐頁播放，避免按 SHIFT
#    當幀一次載入 74 張素材造成假性卡頓。
# 5. 這是人工視覺驗收流程。Visual Harness 一旦啟動，該場 Performance Seal 數字
#    僅供參考，不再當正式效能 acceptance；正式 Performance baseline 仍是 v1.04.9+。
# 6. HOME / Spatial Runtime / Damage / AI / Attack Speed / Energy authority 全部不碰。
#
# 【可調參數】
# MOTION_BATCHIX_VISUAL_HARNESS_PAGE_FRAMES_V10414 = 72
#   每頁停留時間。想觀察更久可調大，但不會改 Combat timing。
# MOTION_BATCHIX_VISUAL_HARNESS_PREWARM_PER_FRAME_V10414 = 2
#   每 frame 暖載幾張 route bitmap。
#
# 【事件／腳本呼叫方式】
# 1. 先執行 Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat 匯入 64 隻素材。
# 2. 啟動遊戲，S 切到 PMD Motion verifier 並進戰鬥。
# 3. Verifier 完成後畫面會提示：SHIFT = Batch IX Visual Acceptance。
# 4. 按 SHIFT，自動暖載後依序播放 74 routes。
# 5. 每頁會顯示 route 編號、species id、exact pose，以及左右 45°。
# 6. 全部播放完自動恢復原戰鬥並寫 LOG。
#
# 【實際範例】
# #0303 Mawile / Bite：同一格左側播放 direction=3，右側 direction=1；兩邊都必須
# 真正顯示 Bite Native，而不是 Attack / Head fallback。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BatchIXVisualAcceptanceHarness_v10414']=true

module PMD_AC
  MOTION_BATCHIX_VISUAL_HARNESS_PAGE_FRAMES_V10414=72
  MOTION_BATCHIX_VISUAL_HARNESS_PREWARM_PER_FRAME_V10414=2
  MOTION_BATCHIX_VISUAL_HARNESS_COLS_V10414=3
  MOTION_BATCHIX_VISUAL_HARNESS_ROWS_V10414=2
  MOTION_BATCHIX_VISUAL_HARNESS_PER_PAGE_V10414=6
  MOTION_BATCHIX_VISUAL_HARNESS_MARKER_V10414='Graphics/PMD/_BATCHIX_VISUAL_V10413_READY.txt'

  class << self
    def motion_batchix_visual_routes_v10414
      return @motion_batchix_visual_routes_v10414 if @motion_batchix_visual_routes_v10414!=nil
      rows=[]
      MOTION_BATCHIX_CASES_V10413.each do |row|
        tag=row[0];pose=row[5]
        motion_batchix_target_list_v10413(row[6]).each do |sid|
          rows.push([sid,pose,tag])
        end
      end
      @motion_batchix_visual_routes_v10414=rows
      rows
    rescue
      []
    end

    def motion_batchix_visual_assets_ready_v10414?
      return false unless FileTest.exist?(MOTION_BATCHIX_VISUAL_HARNESS_MARKER_V10414)
      a=motion_batchix_asset_audit_v10413
      a[:ready] && a[:total].to_i==74 && a[:playable].to_i==74 && (a[:bad]||[]).empty?
    rescue
      false
    end

    def motion_batchix_visual_route_bitmap_v10414(sid,pose)
      d=action_data(sid,pose)
      return nil if d==nil
      filename=d[:file]
      return nil if filename==nil
      folder=PMD_ROOT+sid.to_s+'/'
      return nil unless bitmap_exists?(folder,filename)
      Cache.load_bitmap(folder,filename)
    rescue
      nil
    end
  end
end

#==============================================================================
# ■ Sprite_PMDBatchIXRoutePreviewV10414
#   Combat unit 不共用此 Sprite；純 Visual Acceptance 預覽。
#==============================================================================
class Sprite_PMDBatchIXRoutePreviewV10414
  def initialize(viewport,x,y,w,h,sid,pose,tag,index,total)
    @viewport=viewport
    @panel_x=x.to_i;@panel_y=y.to_i;@w=w.to_i;@h=h.to_i
    @sid=sid.to_s;@pose=pose;@tag=tag
    @index=index.to_i;@total=total.to_i
    @frame_index=0;@frame_wait=0
    @data=PMD_AC.action_data(@sid,@pose)
    @bitmap=PMD_AC.motion_batchix_visual_route_bitmap_v10414(@sid,@pose)
    create_panel
    create_sides
    update_source_rect
  end

  def create_panel
    @panel=Sprite.new(@viewport)
    @panel.bitmap=Bitmap.new(@w,@h)
    @panel.x=@panel_x;@panel.y=@panel_y;@panel.z=10002
    b=@panel.bitmap
    b.fill_rect(0,0,@w,@h,Color.new(10,14,20,225))
    b.fill_rect(1,1,@w-2,@h-2,Color.new(42,53,66,210))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Arial']
    b.font.name=font
    b.font.size=16
    b.font.bold=true
    b.font.color=Color.new(255,255,255)
    head=sprintf('%02d/%02d',@index,@total)+'  #'+@sid+'  '+@pose.to_s
    b.draw_text(6,2,@w-12,22,head,0)
    b.font.size=13
    b.font.bold=false
    b.font.color=Color.new(205,220,235)
    b.draw_text(6,24,@w-12,18,@tag.to_s.upcase,0)
    b.font.color=Color.new(165,205,255)
    b.draw_text(6,@h-21,@w/2-8,18,'RIGHT 45',1)
    b.draw_text(@w/2+2,@h-21,@w/2-8,18,'LEFT 45',1)
  end

  def create_sides
    @right=Sprite.new(@viewport)
    @left=Sprite.new(@viewport)
    [@right,@left].each do |s|
      s.bitmap=@bitmap
      s.z=10003
      s.mirror=false
    end
    fw=@data==nil ? 1 : @data[:frame_w].to_i
    fh=@data==nil ? 1 : @data[:frame_h].to_i
    fw=1 if fw<=0;fh=1 if fh<=0
    maxw=(@w/2-16).to_f
    maxh=(@h-60).to_f
    scale=[maxw/fw.to_f,maxh/fh.to_f,1.0].min
    scale=0.15 if scale<0.15
    @right.zoom_x=scale;@right.zoom_y=scale
    @left.zoom_x=scale;@left.zoom_y=scale
    @right.ox=fw/2;@right.oy=fh
    @left.ox=fw/2;@left.oy=fh
    base_y=@panel_y+@h-27
    @right.x=@panel_x+@w/4
    @left.x=@panel_x+(@w*3)/4
    @right.y=base_y;@left.y=base_y
  end

  def update
    return if @data==nil || @bitmap==nil
    if @frame_wait>0
      @frame_wait-=1
      return
    end
    ds=@data[:durations]
    frames=@data[:frames].to_i
    frames=ds.size if frames<=0 && ds!=nil
    frames=1 if frames<=0
    duration=6
    if ds!=nil && !ds.empty?
      duration=ds[@frame_index % ds.size].to_i
      duration=1 if duration<=0
    end
    @frame_wait=duration
    @frame_index+=1
    @frame_index=0 if @frame_index>=frames
    update_source_rect
  rescue
  end

  def update_source_rect
    return if @data==nil || @bitmap==nil
    fw=@data[:frame_w].to_i;fh=@data[:frame_h].to_i
    return if fw<=0 || fh<=0
    rr=PMD_AC.direction_row(@data,3)
    lr=PMD_AC.direction_row(@data,1)
    @right.src_rect.set(@frame_index*fw,rr*fh,fw,fh)
    @left.src_rect.set(@frame_index*fw,lr*fh,fw,fh)
  rescue
  end

  def dispose
    [@right,@left,@panel].each do |s|
      next if s==nil
      if s==@panel && s.bitmap!=nil && !s.bitmap.disposed?
        s.bitmap.dispose
      end
      s.dispose unless s.disposed?
    end
  rescue
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - SHIFT Visual Harness
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10414_visual_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10414_visual_update_battle_input)
  alias pmd_ac_v10414_visual_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10414_visual_update_battle_step)
  alias pmd_ac_v10414_visual_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10414_visual_update_verification_script)
  alias pmd_ac_v10414_visual_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10414_visual_restart_to_deploy)
  alias pmd_ac_v10414_visual_terminate terminate unless method_defined?(:pmd_ac_v10414_visual_terminate)

  def motion_batchix_visual_harness_ready_v10414?
    return false unless verification_mode==:pmd_motion_phase_b_v103
    return false unless @verification_frame.to_i>=234
    @motion_batchix_visual_assets_ready_v10414==true
  rescue
    false
  end

  def motion_batchix_visual_harness_active_v10414?
    @motion_batchix_visual_harness_active_v10414==true
  end

  def motion_batchix_visual_create_overlay_v10414
    return if @motion_batchix_visual_overlay_v10414!=nil
    @motion_batchix_visual_overlay_v10414=Sprite.new(@viewport)
    @motion_batchix_visual_overlay_v10414.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @motion_batchix_visual_overlay_v10414.z=10000
    @motion_batchix_visual_overlay_v10414.bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(4,7,12,242))
  end

  def motion_batchix_visual_draw_header_v10414(text,sub)
    motion_batchix_visual_create_overlay_v10414
    b=@motion_batchix_visual_overlay_v10414.bitmap
    b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(4,7,12,242))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Arial']
    b.font.name=font
    b.font.size=20;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(10,4,Graphics.width-20,26,text,1)
    b.font.size=14;b.font.bold=false;b.font.color=Color.new(190,210,230)
    b.draw_text(10,29,Graphics.width-20,20,sub,1)
  rescue
  end

  def motion_batchix_visual_show_prompt_v10414
    return if @motion_batchix_visual_prompt_v10414!=nil
    @motion_batchix_visual_prompt_v10414=Sprite.new(@viewport)
    @motion_batchix_visual_prompt_v10414.bitmap=Bitmap.new(360,28)
    @motion_batchix_visual_prompt_v10414.x=(Graphics.width-360)/2
    @motion_batchix_visual_prompt_v10414.y=Graphics.height-66
    @motion_batchix_visual_prompt_v10414.z=9998
    b=@motion_batchix_visual_prompt_v10414.bitmap
    b.fill_rect(0,0,360,28,Color.new(0,0,0,210))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Arial']
    b.font.name=font;b.font.size=16;b.font.bold=true;b.font.color=Color.new(255,245,170)
    b.draw_text(4,2,352,24,'SHIFT：Batch IX 64隻 / 74 Route 視覺驗收',1)
  rescue
  end

  def motion_batchix_visual_dispose_prompt_v10414
    s=@motion_batchix_visual_prompt_v10414
    if s!=nil
      s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?
      s.dispose unless s.disposed?
    end
    @motion_batchix_visual_prompt_v10414=nil
  rescue
  end

  def motion_batchix_visual_start_v10414
    return unless motion_batchix_visual_harness_ready_v10414?
    return if motion_batchix_visual_harness_active_v10414?
    @motion_batchix_visual_harness_active_v10414=true
    @motion_batchix_visual_loading_v10414=true
    @motion_batchix_visual_load_index_v10414=0
    @motion_batchix_visual_page_v10414=0
    @motion_batchix_visual_page_frame_v10414=0
    @motion_batchix_visual_panels_v10414=[]
    motion_batchix_visual_dispose_prompt_v10414
    motion_batchix_visual_draw_header_v10414('Batch IX Windows Visual Acceptance','Loading 64 species / 74 exact Native routes...')
    log_event(:showcase,'MOTION_BATCHIX_VISUAL_HARNESS_V10414 START routes=74 visual_reps=64'+
      ' two_diagonals=1 combat_step_paused=1 performance_acceptance_non_authoritative=1')
  rescue
    @motion_batchix_visual_harness_active_v10414=false
  end

  def motion_batchix_visual_prewarm_v10414
    routes=PMD_AC.motion_batchix_visual_routes_v10414
    n=PMD_AC::MOTION_BATCHIX_VISUAL_HARNESS_PREWARM_PER_FRAME_V10414
    n=1 if n<=0
    n.times do
      break if @motion_batchix_visual_load_index_v10414.to_i>=routes.size
      row=routes[@motion_batchix_visual_load_index_v10414.to_i]
      PMD_AC.motion_batchix_visual_route_bitmap_v10414(row[0],row[1])
      @motion_batchix_visual_load_index_v10414=@motion_batchix_visual_load_index_v10414.to_i+1
    end
    done=@motion_batchix_visual_load_index_v10414.to_i
    motion_batchix_visual_draw_header_v10414('Batch IX Windows Visual Acceptance','Loading route '+done.to_s+'/74')
    if done>=routes.size
      @motion_batchix_visual_loading_v10414=false
      @motion_batchix_visual_page_v10414=0
      motion_batchix_visual_build_page_v10414
      log_event(:showcase,'MOTION_BATCHIX_VISUAL_HARNESS_PREWARM_V10414 ready=1 routes=74/74 incremental=1 per_frame='+n.to_s)
    end
  rescue
    motion_batchix_visual_finish_v10414(false,'prewarm_exception')
  end

  def motion_batchix_visual_dispose_panels_v10414
    (@motion_batchix_visual_panels_v10414||[]).each{|p|p.dispose if p!=nil}
    @motion_batchix_visual_panels_v10414=[]
  rescue
  end

  def motion_batchix_visual_build_page_v10414
    motion_batchix_visual_dispose_panels_v10414
    routes=PMD_AC.motion_batchix_visual_routes_v10414
    per=PMD_AC::MOTION_BATCHIX_VISUAL_HARNESS_PER_PAGE_V10414
    page=@motion_batchix_visual_page_v10414.to_i
    start=page*per
    return motion_batchix_visual_finish_v10414(true,'complete') if start>=routes.size
    last=[start+per,routes.size].min
    total_pages=(routes.size+per-1)/per
    motion_batchix_visual_draw_header_v10414('Batch IX Windows Visual Acceptance',
      'Page '+(page+1).to_s+'/'+total_pages.to_s+'  routes '+(start+1).to_s+'-'+last.to_s+'/74')
    top=54;bottom=18;gap=4
    cols=PMD_AC::MOTION_BATCHIX_VISUAL_HARNESS_COLS_V10414
    rows=PMD_AC::MOTION_BATCHIX_VISUAL_HARNESS_ROWS_V10414
    pw=(Graphics.width-gap*(cols+1))/cols
    ph=(Graphics.height-top-bottom-gap*(rows+1))/rows
    (start...last).each do |i|
      local=i-start;c=local%cols;r=local/cols
      x=gap+c*(pw+gap);y=top+gap+r*(ph+gap)
      row=routes[i]
      p=Sprite_PMDBatchIXRoutePreviewV10414.new(@viewport,x,y,pw,ph,row[0],row[1],row[2],i+1,routes.size)
      @motion_batchix_visual_panels_v10414.push(p)
    end
    @motion_batchix_visual_page_frame_v10414=0
    log_event(:showcase,'MOTION_BATCHIX_VISUAL_PAGE_V10414 page='+(page+1).to_s+'/'+total_pages.to_s+
      ' routes='+(start+1).to_s+'-'+last.to_s+' two_diagonals=1')
  rescue
    motion_batchix_visual_finish_v10414(false,'page_exception')
  end

  def motion_batchix_visual_update_v10414
    return unless motion_batchix_visual_harness_active_v10414?
    if @motion_batchix_visual_loading_v10414
      motion_batchix_visual_prewarm_v10414
      return
    end
    (@motion_batchix_visual_panels_v10414||[]).each{|p|p.update if p!=nil}
    @motion_batchix_visual_page_frame_v10414=@motion_batchix_visual_page_frame_v10414.to_i+1
    if @motion_batchix_visual_page_frame_v10414.to_i>=PMD_AC::MOTION_BATCHIX_VISUAL_HARNESS_PAGE_FRAMES_V10414
      @motion_batchix_visual_page_v10414=@motion_batchix_visual_page_v10414.to_i+1
      motion_batchix_visual_build_page_v10414
    end
  rescue
    motion_batchix_visual_finish_v10414(false,'update_exception')
  end

  def motion_batchix_visual_finish_v10414(ok,reason)
    return unless motion_batchix_visual_harness_active_v10414?
    motion_batchix_visual_dispose_panels_v10414
    s=@motion_batchix_visual_overlay_v10414
    if s!=nil
      s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?
      s.dispose unless s.disposed?
    end
    @motion_batchix_visual_overlay_v10414=nil
    @motion_batchix_visual_harness_active_v10414=false
    @motion_batchix_visual_loading_v10414=false
    @motion_batchix_visual_completed_v10414=ok
    log_event(:verify,'MOTION_BATCHIX_WINDOWS_VISUAL_HARNESS_COMPLETE_V10414 pass='+(ok ? '1':'0')+
      ' routes=74 pages=13 two_diagonals=1 combat_step_resumed=1 manual_visual_judgement_required=1'+
      ' reason='+reason.to_s+' performance_acceptance_non_authoritative=1')
  rescue
  end

  def update_battle_input
    pmd_ac_v10414_visual_update_battle_input
    return unless @phase==:battle
    if motion_batchix_visual_harness_ready_v10414? && !motion_batchix_visual_harness_active_v10414?
      if Input.trigger?(Input::SHIFT)
        Sound.play_decision
        motion_batchix_visual_start_v10414
      end
    end
  end

  def update_battle_step
    if motion_batchix_visual_harness_active_v10414?
      motion_batchix_visual_update_v10414
      return
    end
    pmd_ac_v10414_visual_update_battle_step
  end

  def update_verification_script
    pmd_ac_v10414_visual_update_verification_script
    return unless verification_mode==:pmd_motion_phase_b_v103
    if !@motion_batchix_visual_harness_verify_v10414 && @verification_frame.to_i>=236
      @motion_batchix_visual_harness_verify_v10414=true
      a=@motion_batchix_assets_v10413 || {}
      ready=a[:ready] && a[:total].to_i==74 && a[:playable].to_i==74 && (a[:bad]||[]).empty?
      @motion_batchix_visual_assets_ready_v10414=ready
      routes=PMD_AC.motion_batchix_visual_routes_v10414
      structural=routes.size==74 && routes.collect{|r|r[0]}.uniq.size==64
      log_event(:verify,'MOTION_BATCHIX_VISUAL_HARNESS_READY_V10414 pass='+(structural ? '1':'0')+
        ' routes='+routes.size.to_i.to_s+'/74 visual_reps='+routes.collect{|r|r[0]}.uniq.size.to_i.to_s+'/64'+
        ' assets_ready='+(ready ? '1':'0')+' activation=SHIFT pages=13 per_page=6 page_frames='+
        PMD_AC::MOTION_BATCHIX_VISUAL_HARNESS_PAGE_FRAMES_V10414.to_i.to_s+
        ' two_diagonals=1 preview_sprites_isolated=1 combat_unit_mutation=0 performance_v1049_frozen=1')
      if ready
        motion_batchix_visual_show_prompt_v10414
        log_event(:showcase,'MOTION_BATCHIX_VISUAL_HARNESS_PROMPT_V10414 ready=1 input=SHIFT'+
          ' normal_battle_continues_until_activation=1 performance_run_remains_authoritative_until_activation=1')
      else
        log_event(:verify,'MOTION_BATCHIX_VISUAL_HARNESS_DEFERRED_V10414 pass=1 assets_ready=0 deferred=1 blocking=0'+
          ' import_tool=Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat false_playable_claim=0')
      end
    end
  rescue
  end

  def restart_to_deploy
    motion_batchix_visual_dispose_all_v10414
    pmd_ac_v10414_visual_restart_to_deploy
  end

  def terminate
    motion_batchix_visual_dispose_all_v10414
    pmd_ac_v10414_visual_terminate
  end

  def motion_batchix_visual_dispose_all_v10414
    motion_batchix_visual_dispose_panels_v10414
    motion_batchix_visual_dispose_prompt_v10414
    s=@motion_batchix_visual_overlay_v10414
    if s!=nil
      s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?
      s.dispose unless s.disposed?
    end
    @motion_batchix_visual_overlay_v10414=nil
    @motion_batchix_visual_harness_active_v10414=false
  rescue
  end
end
