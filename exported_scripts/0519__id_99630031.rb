# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Visual Fixture I v1.05.34
#===============================================================================
# 【用途】
# 1. 承接 v1.05.33 Windows 實機證據：56/56 Representative 已 admitted、896/896
#    Runtime routes PASS、generic Attack 已由 294 收斂至 222，且自動 safety candidate=0。
# 2. 正式停止「為了降低 generic Attack 數字而繼續自動替換」的流水線，改進入
#    56 隻 Representative 人工視覺 QA。F7 可在 NORMAL battle 安全時啟動獨立 Fixture。
# 3. Fixture 使用獨立 Preview Sprite，不改 Combat unit species / HP / Energy / AI / Spatial。
# 4. 7 body × 8 species 全部逐頁展示；每頁 4 隻，每隻同時顯示右 45°與左 45°。
# 5. 每頁依序展示 neutral、Attack、Hurt，以及三個 body-specific 高價值 family route，
#    直接播放正式 Runtime Router 當下實際 selected pose，而不是只看 metadata 名稱。
# 6. LOG 同步記錄每隻 neutral / Attack / Hurt / Faint native，以及三條 route 的
#    selected pose、fallback、selected_native，方便影片回看時精確定位需要人工 tuning 的物種。
#
# 【主要設定】
# REPRESENTATIVE_VISUAL_PHASE_FRAMES_V10534 = 42
#   每個展示 phase 自動停留 42 frame；可按 C 手動提前切下一 phase。
# REPRESENTATIVE_VISUAL_PREWARM_PER_FRAME_V10534 = 3
#   每 frame 最多暖載 3 張 Preview Bitmap，避免單幀一次讀完所有素材。
# REPRESENTATIVE_VISUAL_PER_PAGE_V10534 = 4
#   每頁 4 隻（2×2），56 隻共 14 頁。
# REPRESENTATIVE_VISUAL_BODY_ORDER_V10534
#   固定 small / medium / quadruped / heavy / hover / avian / serpentine，避免 Ruby Hash
#   iteration order 造成頁序每次不同。
# REPRESENTATIVE_VISUAL_ROUTE_FAMILIES_V10534
#   每個 body 固定三條人工 QA route，優先覆蓋 v1.05.28～33 的 fallback hotspot。
#
# 【機制規則】
# - F7 只在 NORMAL battle 使用；若 896-route QA 尚未完成或 Focus / Result Hold 正忙，
#   會記錄 pending，等安全邊界自動啟動，不會插進技能演出中間。
# - Fixture active 時暫停正式 update_battle_step，AI / Damage / Spatial / Energy / Timer 不走。
# - Preview 全部是新 Sprite，絕不改 Game_PMDChessUnit 的 species、logical x/y 或 action_timer。
# - 右 45°使用 direction=3；左 45°使用 direction=1，沿用 PMD Motion 既有 direction_row。
# - neutral 優先：hover/avian 可播 Float 時用 Float，其餘優先 Walk，再回退 Idle。
# - Attack / Hurt 直接顯示該物種 native action；Faint 只顯示 Y/N，不強迫缺 Faint 的物種假播。
# - 三條 family route 由 motion_source_route_v102 真實查詢；tuning 後的 Double / Swing 會直接顯示。
# - Fixture 期間暫停正式 v1.02.3 Performance capture，完成後重設 wall-time 邊界；
#   50ms 正式門檻完全不修改，Fixture loading / 人工觀察不混進正式 Combat Performance Seal。
# - 不修改 Damage Formula、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、速度、dash/lunge endpoint、push/pull/through。
# - Frozen Motion Combat Core 不直接修改；HOME 仍是本次 logical/action anchor。
#
# 【操作方式】
# - NORMAL battle 進場後按 F7：啟動 Fixture。若太早按，完成 896-route QA 後自動啟動。
# - C：下一個 phase。
# - ← / →：上一頁 / 下一頁。
# - ↑ / ↓：上一個 / 下一個 body group（跳到該組第一頁）。
# - B / Esc：提早離開 Fixture，原戰鬥原地恢復。
# - 不新增 S-menu verifier，不增加頂部事件 feed。
#
# 【畫面人工檢查重點】
# 1. 右/左 45°是否真的對應方向，沒有側面或背面誤列。
# 2. 身體構造是否合理：蛇型不應像人形拳腳，鳥類/hover 不應出現突兀落地感。
# 3. Sprite 尺寸、裁切、腳底/身體 anchor 是否穩定。
# 4. Attack / Hurt 是否清楚，動作是否突然跳尺寸或飄移。
# 5. route label 顯示 fallback 時，肉眼判斷該 fallback 是否仍自然；不追求 fallback=0。
# 6. 本 Fixture I 先驗「單一 Native 動作形狀 + 45° + identity」。真正 action HOME → hit →
#    recovery 的連續戰場 transition 會在後續 Live Visual Fixture 階段處理。
#
# 【LOG】
# BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_V10534 READY / START ...
# BATTLE_REPRESENTATIVE_VISUAL_PREWARM_V10534 ...
# BATTLE_REPRESENTATIVE_VISUAL_PAGE_V10534 ...
# BATTLE_REPRESENTATIVE_VISUAL_SPECIES_V10534 ...
# BATTLE_REPRESENTATIVE_VISUAL_PHASE_V10534 ...
# BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_COMPLETE_V10534 ...
# BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_SUMMARY_V10534 ...
#
# 【實際範例】
# - #0384 烈空坐在 serpentine 頁面：strike / lunge / punch 會顯示目前 Router 經 tuning
#   選到的 Swing；若畫面看起來仍不符合烈空坐，下一版才做 species-specific 人工 override。
# - #0493 阿爾宙斯在 heavy 頁面：lunge 會顯示目前 selected pose；真正位移距離與 endpoint
#   完全不在 Fixture 中改寫。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeVisualFixtureI_v10534']=true

module PMD_AC
  REPRESENTATIVE_VISUAL_PHASE_FRAMES_V10534=42
  REPRESENTATIVE_VISUAL_PREWARM_PER_FRAME_V10534=3
  REPRESENTATIVE_VISUAL_PER_PAGE_V10534=4
  REPRESENTATIVE_VISUAL_COLS_V10534=2
  REPRESENTATIVE_VISUAL_ROWS_V10534=2
  REPRESENTATIVE_VISUAL_BODY_ORDER_V10534=[:small,:medium,:quadruped,:heavy,:hover,:avian,:serpentine]
  REPRESENTATIVE_VISUAL_PHASES_V10534=[:neutral,:attack,:hurt,:route_a,:route_b,:hotspot]
  REPRESENTATIVE_VISUAL_ROUTE_FAMILIES_V10534={
    :small=>[:dash,:lunge,:spin],
    :medium=>[:dash,:lunge,:punch],
    :quadruped=>[:bite,:lunge,:spin],
    :heavy=>[:lunge,:punch,:bite],
    :hover=>[:dash,:lunge,:kick],
    :avian=>[:lunge,:bite,:punch],
    :serpentine=>[:strike,:lunge,:punch]
  }

  class << self
    def representative_visual_pages_v10534
      return @representative_visual_pages_v10534 if @representative_visual_pages_v10534!=nil
      groups=representative_reps_by_body_v10527
      pages=[]
      REPRESENTATIVE_VISUAL_BODY_ORDER_V10534.each do |body|
        sids=groups[body] || []
        i=0
        while i<sids.size
          pages.push([body,sids[i,REPRESENTATIVE_VISUAL_PER_PAGE_V10534] || []])
          i+=REPRESENTATIVE_VISUAL_PER_PAGE_V10534
        end
      end
      @representative_visual_pages_v10534=pages
      pages
    rescue
      []
    end

    def representative_visual_family_case_v10534(family)
      return nil unless const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043)
      MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
        return row if row[0]==family
      end
      nil
    rescue
      nil
    end

    def representative_visual_neutral_pose_v10534(sid,body)
      if (body==:hover || body==:avian) && motion_playable_v102?(sid.to_s,:float)
        return :float
      end
      return :walk if motion_playable_v102?(sid.to_s,:walk)
      return :idle if motion_playable_v102?(sid.to_s,:idle)
      return :float if motion_playable_v102?(sid.to_s,:float)
      nil
    rescue
      nil
    end

    def representative_visual_route_info_v10534(sid,family)
      row=representative_visual_family_case_v10534(family)
      return {:family=>family,:pose=>nil,:fallback=>false,:native=>false,:playable=>false} if row==nil
      r=motion_source_route_v102(sid.to_s,row[1],row[2],row[3])
      {:family=>family,:pose=>(r==nil ? nil : r[:selected]),
       :fallback=>(r!=nil && r[:fallback]),:native=>(r!=nil && r[:selected_native]),
       :playable=>(r!=nil && r[:has_playable])}
    rescue
      {:family=>family,:pose=>nil,:fallback=>false,:native=>false,:playable=>false}
    end

    def representative_visual_phase_info_v10534(sid,body,phase)
      sid=sid.to_s
      case phase
      when :neutral
        pose=representative_visual_neutral_pose_v10534(sid,body)
        return {:phase=>phase,:family=>:neutral,:pose=>pose,:fallback=>false,:native=>true,
          :playable=>(pose!=nil && motion_playable_v102?(sid,pose)),:label=>'NEUTRAL'}
      when :attack
        return {:phase=>phase,:family=>:attack,:pose=>:attack,:fallback=>false,:native=>true,
          :playable=>motion_playable_v102?(sid,:attack),:label=>'ATTACK'}
      when :hurt
        return {:phase=>phase,:family=>:hurt,:pose=>:hurt,:fallback=>false,:native=>true,
          :playable=>motion_playable_v102?(sid,:hurt),:label=>'HURT'}
      else
        fams=REPRESENTATIVE_VISUAL_ROUTE_FAMILIES_V10534[body] || []
        idx=(phase==:route_a ? 0 : (phase==:route_b ? 1 : 2))
        family=fams[idx]
        info=representative_visual_route_info_v10534(sid,family)
        info[:phase]=phase
        info[:label]=(family==nil ? phase.to_s.upcase : family.to_s.upcase)
        return info
      end
    rescue
      {:phase=>phase,:family=>phase,:pose=>nil,:fallback=>false,:native=>false,:playable=>false,:label=>phase.to_s.upcase}
    end

    def representative_visual_bitmap_v10534(sid,pose)
      return nil if pose==nil
      d=action_data(sid.to_s,pose)
      return nil if d==nil || d[:file]==nil
      folder=PMD_ROOT+sid.to_s+'/'
      return nil unless bitmap_exists?(folder,d[:file])
      Cache.load_bitmap(folder,d[:file])
    rescue
      nil
    end

    def representative_visual_asset_rows_v10534
      out=[];seen={}
      representative_visual_pages_v10534.each do |page|
        body=page[0]
        page[1].each do |sid|
          REPRESENTATIVE_VISUAL_PHASES_V10534.each do |phase|
            info=representative_visual_phase_info_v10534(sid,body,phase)
            pose=info[:pose]
            next if pose==nil
            key=sid.to_s+':'+pose.to_s
            next if seen[key]
            seen[key]=true
            out.push([sid.to_s,pose])
          end
        end
      end
      out
    rescue
      []
    end

    def representative_visual_species_log_v10534(sid,body)
      neutral=representative_visual_phase_info_v10534(sid,body,:neutral)
      attack=motion_playable_v102?(sid.to_s,:attack)
      hurt=motion_playable_v102?(sid.to_s,:hurt)
      faint=motion_playable_v102?(sid.to_s,:faint)
      fams=REPRESENTATIVE_VISUAL_ROUTE_FAMILIES_V10534[body] || []
      routes=[]
      fams.each do |family|
        r=representative_visual_route_info_v10534(sid,family)
        routes.push(family.to_s+'='+(r[:pose]==nil ? 'nil' : r[:pose].to_s)+
          ':fb'+(r[:fallback] ? '1':'0')+':nat'+(r[:native] ? '1':'0'))
      end
      {:neutral=>(neutral[:pose]==nil ? 'nil' : neutral[:pose].to_s),:attack=>attack,:hurt=>hurt,
       :faint=>faint,:routes=>routes}
    rescue
      {:neutral=>'nil',:attack=>false,:hurt=>false,:faint=>false,:routes=>[]}
    end
  end
end

#===============================================================================
# ■ Sprite_PMDRepresentativeVisualPanelV10534
#   只做獨立 Preview，不接觸 Combat unit。
#===============================================================================
class Sprite_PMDRepresentativeVisualPanelV10534
  def initialize(viewport,x,y,w,h,sid,body,index,total)
    @viewport=viewport;@x=x.to_i;@y=y.to_i;@w=w.to_i;@h=h.to_i
    @sid=sid.to_s;@body=body;@index=index.to_i;@total=total.to_i
    @phase=nil;@data=nil;@bitmap=nil;@frame_index=0;@frame_wait=0
    create_panel_v10534
    create_sides_v10534
  end

  def create_panel_v10534
    @panel=Sprite.new(@viewport)
    @panel.bitmap=Bitmap.new(@w,@h)
    @panel.x=@x;@panel.y=@y;@panel.z=15002
    @right=Sprite.new(@viewport);@left=Sprite.new(@viewport)
    @right.z=15003;@left.z=15003
  end

  def create_sides_v10534
    @right.x=@x+@w/4
    @left.x=@x+(@w*3)/4
    @right.y=@y+@h-24
    @left.y=@y+@h-24
    @right.mirror=false;@left.mirror=false
  end

  def set_phase_v10534(phase)
    @phase=phase
    @info=PMD_AC.representative_visual_phase_info_v10534(@sid,@body,phase)
    pose=@info[:pose]
    @data=pose==nil ? nil : PMD_AC.action_data(@sid,pose)
    @bitmap=pose==nil ? nil : PMD_AC.representative_visual_bitmap_v10534(@sid,pose)
    @right.bitmap=@bitmap;@left.bitmap=@bitmap
    @right.visible=(@bitmap!=nil && @data!=nil)
    @left.visible=@right.visible
    @frame_index=0;@frame_wait=0
    configure_geometry_v10534
    redraw_panel_v10534
    update_source_rect_v10534
  rescue
    @right.visible=false if @right!=nil
    @left.visible=false if @left!=nil
  end

  def redraw_panel_v10534
    b=@panel.bitmap;b.clear
    b.fill_rect(0,0,@w,@h,Color.new(8,12,18,235))
    b.fill_rect(1,1,@w-2,@h-2,Color.new(34,43,55,225))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=16;b.font.bold=true;b.font.color=Color.new(255,255,255)
    faint=PMD_AC.motion_playable_v102?(@sid,:faint) ? 'Y' : 'N'
    b.draw_text(6,2,@w-12,22,'#'+@sid+'  '+@body.to_s.upcase+'  Faint:'+faint,0)
    pose=@info==nil || @info[:pose]==nil ? 'nil' : @info[:pose].to_s
    label=@info==nil ? @phase.to_s.upcase : @info[:label].to_s
    flags=''
    if @info!=nil && @info[:family]!=:neutral && @info[:family]!=:attack && @info[:family]!=:hurt
      flags='  '+(@info[:fallback] ? 'FALLBACK' : 'DIRECT')+' / '+(@info[:native] ? 'NATIVE' : 'ROUTED')
    end
    b.font.size=14;b.font.bold=false;b.font.color=Color.new(210,225,240)
    b.draw_text(6,24,@w-12,20,label+' -> '+pose+flags,0)
    if @bitmap==nil || @data==nil
      b.font.size=20;b.font.bold=true;b.font.color=Color.new(255,150,150)
      b.draw_text(4,62,@w-8,30,'NO PLAYABLE PREVIEW',1)
    end
    b.font.size=12;b.font.bold=false;b.font.color=Color.new(165,205,255)
    b.draw_text(4,@h-20,@w/2-6,18,'RIGHT 45',1)
    b.draw_text(@w/2+2,@h-20,@w/2-6,18,'LEFT 45',1)
  rescue
  end

  def configure_geometry_v10534
    return if @data==nil
    fw=@data[:frame_w].to_i;fh=@data[:frame_h].to_i
    fw=1 if fw<=0;fh=1 if fh<=0
    maxw=(@w/2-18).to_f;maxh=(@h-72).to_f
    scale=[maxw/fw.to_f,maxh/fh.to_f,1.0].min
    scale=0.12 if scale<0.12
    @right.zoom_x=scale;@right.zoom_y=scale;@left.zoom_x=scale;@left.zoom_y=scale
    @right.ox=fw/2;@right.oy=fh;@left.ox=fw/2;@left.oy=fh
    @right.y=@y+@h-22;@left.y=@y+@h-22
  rescue
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
    update_source_rect_v10534
  rescue
  end

  def update_source_rect_v10534
    return if @data==nil || @bitmap==nil
    fw=@data[:frame_w].to_i;fh=@data[:frame_h].to_i
    return if fw<=0 || fh<=0
    rr=PMD_AC.direction_row(@data,3);lr=PMD_AC.direction_row(@data,1)
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

#===============================================================================
# ■ Scene_PMD_AutoChess - F7 Representative Visual Fixture
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10534_visual_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10534_visual_update_battle_input)
  alias pmd_ac_v10534_visual_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10534_visual_update_battle_step)
  alias pmd_ac_v10534_visual_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10534_visual_restart_to_deploy)
  alias pmd_ac_v10534_visual_terminate terminate unless method_defined?(:pmd_ac_v10534_visual_terminate)
  alias pmd_ac_v10534_visual_motion_perf_capture_active_v1023 motion_perf_capture_active_v1023? unless method_defined?(:pmd_ac_v10534_visual_motion_perf_capture_active_v1023)
  alias pmd_ac_v10534_visual_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10534_visual_focus_summary)
  alias pmd_ac_v10534_visual_start_battle start_battle unless method_defined?(:pmd_ac_v10534_visual_start_battle)

  def start_battle
    @rep_visual_runs_v10534=0
    @rep_visual_completes_v10534=0
    @rep_visual_ready_logged_v10534=false
    @rep_visual_autostart_requested_v10534=false
    pmd_ac_v10534_visual_start_battle
  end

  def representative_visual_fixture_active_v10534?
    @rep_visual_active_v10534==true
  end

  def representative_visual_fixture_ready_v10534?
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    m=PMD_AC.representative_runtime_matrix_v10527
    return false unless m[:complete]
    rs=PMD_AC.representative_route_qa_state_v10528
    return false if rs==nil || !rs[:complete] || !rs[:pass]
    return false unless (rs[:tuning] || []).empty?
    if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
      return false
    end
    if respond_to?(:result_feedback_hold_active_v10513?) && result_feedback_hold_active_v10513?
      return false
    end
    true
  rescue
    false
  end

  def motion_perf_capture_active_v1023?
    return false if representative_visual_fixture_active_v10534?
    pmd_ac_v10534_visual_motion_perf_capture_active_v1023
  rescue
    pmd_ac_v10534_visual_motion_perf_capture_active_v1023
  end

  def representative_visual_create_overlay_v10534
    return if @rep_visual_overlay_v10534!=nil
    @rep_visual_overlay_v10534=Sprite.new(@viewport)
    @rep_visual_overlay_v10534.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @rep_visual_overlay_v10534.z=15000
  end

  def representative_visual_draw_header_v10534(sub)
    representative_visual_create_overlay_v10534
    b=@rep_visual_overlay_v10534.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(3,6,10,248))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=20;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,3,Graphics.width-16,26,'Representative Visual Fixture I  |  56 Species',1)
    b.font.size=13;b.font.bold=false;b.font.color=Color.new(195,215,235)
    b.draw_text(8,28,Graphics.width-16,19,sub.to_s,1)
    b.font.size=12;b.font.color=Color.new(255,235,165)
    b.draw_text(8,Graphics.height-21,Graphics.width-16,18,'C 下一動作   ←/→ 換頁   ↑/↓ 換體型   B/Esc 離開   檢查 45° / 肢體 / 尺寸 / Anchor',1)
  rescue
  end

  def representative_visual_dispose_panels_v10534
    (@rep_visual_panels_v10534 || []).each{|p|p.dispose if p!=nil}
    @rep_visual_panels_v10534=[]
  rescue
  end

  def representative_visual_start_v10534
    return false unless representative_visual_fixture_ready_v10534?
    return false if representative_visual_fixture_active_v10534?
    @rep_visual_active_v10534=true
    @rep_visual_loading_v10534=true
    @rep_visual_load_index_v10534=0
    @rep_visual_page_v10534=0
    @rep_visual_phase_index_v10534=0
    @rep_visual_phase_frame_v10534=0
    @rep_visual_panels_v10534=[]
    @rep_visual_pages_seen_v10534={}
    @rep_visual_species_seen_v10534={}
    @rep_visual_phase_seen_v10534={}
    @rep_visual_species_logged_v10534={}
    @rep_visual_assets_v10534=PMD_AC.representative_visual_asset_rows_v10534
    @rep_visual_runs_v10534=@rep_visual_runs_v10534.to_i+1
    @rep_visual_autostart_requested_v10534=false
    representative_visual_draw_header_v10534('Incremental prewarm 0/'+@rep_visual_assets_v10534.size.to_s+' ...')
    log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_V10534 START reps=56 pages=14 per_page=4 phases=6'+
      ' two_diagonals=1 input=F7 combat_step_paused=1 preview_sprite_isolated=1'+
      ' performance_capture_paused=1 manual_visual_judgement_required=1')
    true
  rescue
    @rep_visual_active_v10534=false
    false
  end

  def representative_visual_prewarm_v10534
    rows=@rep_visual_assets_v10534 || []
    n=PMD_AC::REPRESENTATIVE_VISUAL_PREWARM_PER_FRAME_V10534
    n=1 if n<=0
    n.times do
      break if @rep_visual_load_index_v10534.to_i>=rows.size
      row=rows[@rep_visual_load_index_v10534.to_i]
      PMD_AC.representative_visual_bitmap_v10534(row[0],row[1])
      @rep_visual_load_index_v10534=@rep_visual_load_index_v10534.to_i+1
    end
    done=@rep_visual_load_index_v10534.to_i
    representative_visual_draw_header_v10534('Incremental prewarm '+done.to_s+'/'+rows.size.to_s+' ...')
    if done>=rows.size
      @rep_visual_loading_v10534=false
      representative_visual_build_page_v10534
      log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_PREWARM_V10534 ready=1 assets='+rows.size.to_s+'/'+rows.size.to_s+
        ' per_frame='+n.to_s+' formal_perf_capture_paused=1')
    end
  rescue
    representative_visual_finish_v10534(false,'prewarm_exception')
  end

  def representative_visual_build_page_v10534
    representative_visual_dispose_panels_v10534
    pages=PMD_AC.representative_visual_pages_v10534
    page=@rep_visual_page_v10534.to_i
    return representative_visual_finish_v10534(true,'complete') if page>=pages.size
    row=pages[page];body=row[0];sids=row[1]
    @rep_visual_phase_index_v10534=0 if @rep_visual_phase_index_v10534==nil
    phase=PMD_AC::REPRESENTATIVE_VISUAL_PHASES_V10534[@rep_visual_phase_index_v10534.to_i]
    phase=:neutral if phase==nil
    @rep_visual_phase_frame_v10534=0
    representative_visual_draw_header_v10534('Page '+(page+1).to_s+'/'+pages.size.to_s+'  '+body.to_s.upcase+
      '  species '+sids.join(',')+'  phase '+phase.to_s.upcase+'  auto '+PMD_AC::REPRESENTATIVE_VISUAL_PHASE_FRAMES_V10534.to_s+'f')
    top=50;bottom=25;gap=4
    cols=PMD_AC::REPRESENTATIVE_VISUAL_COLS_V10534;rows=PMD_AC::REPRESENTATIVE_VISUAL_ROWS_V10534
    pw=(Graphics.width-gap*(cols+1))/cols
    ph=(Graphics.height-top-bottom-gap*(rows+1))/rows
    sids.each_with_index do |sid,i|
      c=i%cols;r=i/cols;x=gap+c*(pw+gap);y=top+gap+r*(ph+gap)
      p=Sprite_PMDRepresentativeVisualPanelV10534.new(@viewport,x,y,pw,ph,sid,body,page*4+i+1,56)
      p.set_phase_v10534(phase)
      @rep_visual_panels_v10534.push(p)
      @rep_visual_species_seen_v10534[sid.to_s]=true
      unless @rep_visual_species_logged_v10534 && @rep_visual_species_logged_v10534[sid.to_s]
        @rep_visual_species_logged_v10534={} if @rep_visual_species_logged_v10534==nil
        @rep_visual_species_logged_v10534[sid.to_s]=true
        q=PMD_AC.representative_visual_species_log_v10534(sid,body)
        log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_SPECIES_V10534 sid='+sid.to_s+' body='+body.to_s+
          ' neutral='+q[:neutral].to_s+' attack='+(q[:attack] ? '1':'0')+' hurt='+(q[:hurt] ? '1':'0')+
          ' faint_native='+(q[:faint] ? '1':'0')+' routes=['+q[:routes].join(',')+']')
      end
    end
    @rep_visual_pages_seen_v10534[page]=true
    @rep_visual_phase_seen_v10534[page.to_s+':'+phase.to_s]=true
    log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_PAGE_V10534 page='+(page+1).to_s+'/'+pages.size.to_s+
      ' body='+body.to_s+' species=['+sids.join(',')+'] phase='+phase.to_s+' two_diagonals=1')
  rescue
    representative_visual_finish_v10534(false,'page_exception')
  end

  def representative_visual_apply_phase_v10534
    pages=PMD_AC.representative_visual_pages_v10534
    page=@rep_visual_page_v10534.to_i
    return if page<0 || page>=pages.size
    phase=PMD_AC::REPRESENTATIVE_VISUAL_PHASES_V10534[@rep_visual_phase_index_v10534.to_i]
    phase=:neutral if phase==nil
    body=pages[page][0];sids=pages[page][1]
    (@rep_visual_panels_v10534 || []).each{|p|p.set_phase_v10534(phase) if p!=nil}
    @rep_visual_phase_frame_v10534=0
    @rep_visual_phase_seen_v10534[page.to_s+':'+phase.to_s]=true
    representative_visual_draw_header_v10534('Page '+(page+1).to_s+'/'+pages.size.to_s+'  '+body.to_s.upcase+
      '  species '+sids.join(',')+'  phase '+phase.to_s.upcase+'  auto '+PMD_AC::REPRESENTATIVE_VISUAL_PHASE_FRAMES_V10534.to_s+'f')
    log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_PHASE_V10534 page='+(page+1).to_s+
      ' body='+body.to_s+' phase='+phase.to_s+' species=['+sids.join(',')+']')
  rescue
  end

  def representative_visual_next_phase_v10534
    n=PMD_AC::REPRESENTATIVE_VISUAL_PHASES_V10534.size
    @rep_visual_phase_index_v10534=@rep_visual_phase_index_v10534.to_i+1
    if @rep_visual_phase_index_v10534>=n
      @rep_visual_phase_index_v10534=0
      @rep_visual_page_v10534=@rep_visual_page_v10534.to_i+1
      pages=PMD_AC.representative_visual_pages_v10534
      if @rep_visual_page_v10534>=pages.size
        representative_visual_finish_v10534(true,'complete')
        return
      end
      representative_visual_build_page_v10534
    else
      representative_visual_apply_phase_v10534
    end
  rescue
    representative_visual_finish_v10534(false,'phase_exception')
  end

  def representative_visual_change_page_v10534(delta)
    pages=PMD_AC.representative_visual_pages_v10534
    return if pages.empty?
    @rep_visual_page_v10534=(@rep_visual_page_v10534.to_i+delta.to_i)%pages.size
    @rep_visual_phase_index_v10534=0
    representative_visual_build_page_v10534
  rescue
  end

  def representative_visual_change_group_v10534(delta)
    pages=PMD_AC.representative_visual_pages_v10534
    return if pages.empty?
    group=@rep_visual_page_v10534.to_i/2
    group=(group+delta.to_i)%PMD_AC::REPRESENTATIVE_VISUAL_BODY_ORDER_V10534.size
    @rep_visual_page_v10534=group*2
    @rep_visual_phase_index_v10534=0
    representative_visual_build_page_v10534
  rescue
  end

  def representative_visual_update_v10534
    return unless representative_visual_fixture_active_v10534?
    if @rep_visual_loading_v10534
      representative_visual_prewarm_v10534
      return
    end
    (@rep_visual_panels_v10534 || []).each{|p|p.update if p!=nil}
    @rep_visual_phase_frame_v10534=@rep_visual_phase_frame_v10534.to_i+1
    if @rep_visual_phase_frame_v10534>=PMD_AC::REPRESENTATIVE_VISUAL_PHASE_FRAMES_V10534
      representative_visual_next_phase_v10534
    end
  rescue
    representative_visual_finish_v10534(false,'update_exception')
  end

  def representative_visual_input_v10534
    if Input.trigger?(Input::B)
      begin;Sound.play_cancel;rescue;end
      representative_visual_finish_v10534(false,'manual_exit')
    elsif Input.trigger?(Input::RIGHT)
      begin;Sound.play_cursor;rescue;end
      representative_visual_change_page_v10534(1)
    elsif Input.trigger?(Input::LEFT)
      begin;Sound.play_cursor;rescue;end
      representative_visual_change_page_v10534(-1)
    elsif Input.trigger?(Input::DOWN)
      begin;Sound.play_cursor;rescue;end
      representative_visual_change_group_v10534(1)
    elsif Input.trigger?(Input::UP)
      begin;Sound.play_cursor;rescue;end
      representative_visual_change_group_v10534(-1)
    elsif Input.trigger?(Input::C)
      begin;Sound.play_decision;rescue;end
      representative_visual_next_phase_v10534
    end
  rescue
  end

  def representative_visual_finish_v10534(ok,reason)
    return unless representative_visual_fixture_active_v10534?
    representative_visual_dispose_panels_v10534
    s=@rep_visual_overlay_v10534
    if s!=nil
      s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?
      s.dispose unless s.disposed?
    end
    @rep_visual_overlay_v10534=nil
    @rep_visual_active_v10534=false
    @rep_visual_loading_v10534=false
    @motion_perf_prev_update_time_v1023=Time.now.to_f
    pages_seen=(@rep_visual_pages_seen_v10534 || {}).size
    species_seen=(@rep_visual_species_seen_v10534 || {}).size
    phase_seen=(@rep_visual_phase_seen_v10534 || {}).size
    expected_phases=PMD_AC.representative_visual_pages_v10534.size*PMD_AC::REPRESENTATIVE_VISUAL_PHASES_V10534.size
    structural=(pages_seen==14 && species_seen==56 && phase_seen==expected_phases)
    pass=ok && structural
    @rep_visual_completes_v10534=@rep_visual_completes_v10534.to_i+1 if pass
    log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_COMPLETE_V10534 pass='+(pass ? '1':'0')+
      ' reason='+reason.to_s+' pages_seen='+pages_seen.to_s+'/14 species_seen='+species_seen.to_s+'/56'+
      ' phase_views='+phase_seen.to_s+'/'+expected_phases.to_s+' two_diagonals=1'+
      ' combat_step_resumed=1 performance_capture_resumed=1 manual_visual_judgement_required=1')
    pass
  rescue
    false
  end

  def update_battle_input
    if representative_visual_fixture_active_v10534?
      representative_visual_input_v10534
      return
    end
    pmd_ac_v10534_visual_update_battle_input
    return unless @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
    if Input.trigger?(Input::F7)
      if representative_visual_fixture_ready_v10534?
        begin;Sound.play_decision;rescue;end
        representative_visual_start_v10534
      else
        @rep_visual_autostart_requested_v10534=true
        begin;Sound.play_cursor;rescue;end
        log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_V10534 REQUEST input=F7 pending_safe_boundary=1'+
          ' route_qa_complete='+(PMD_AC.representative_route_qa_state_v10528!=nil && PMD_AC.representative_route_qa_state_v10528[:complete] ? '1':'0'))
      end
    end
  end

  def update_battle_step
    if representative_visual_fixture_active_v10534?
      representative_visual_update_v10534
      return
    end
    r=pmd_ac_v10534_visual_update_battle_step
    if !@rep_visual_ready_logged_v10534 && representative_visual_fixture_ready_v10534?
      @rep_visual_ready_logged_v10534=true
      log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_V10534 READY input=F7 reps=56 pages=14 phases=6'+
        ' candidate_exhausted=1 s_menu_added=0 top_event_feed_added=0')
    end
    if @rep_visual_autostart_requested_v10534 && representative_visual_fixture_ready_v10534?
      representative_visual_start_v10534
    end
    r
  end

  def representative_visual_dispose_all_v10534
    representative_visual_dispose_panels_v10534
    s=@rep_visual_overlay_v10534
    if s!=nil
      s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?
      s.dispose unless s.disposed?
    end
    @rep_visual_overlay_v10534=nil
    @rep_visual_active_v10534=false
    @rep_visual_loading_v10534=false
  rescue
  end

  def restart_to_deploy
    representative_visual_dispose_all_v10534
    pmd_ac_v10534_visual_restart_to_deploy
  end

  def terminate
    representative_visual_dispose_all_v10534
    pmd_ac_v10534_visual_terminate
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10534_visual_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      ready=PMD_AC.representative_runtime_matrix_v10527[:complete]
      rs=PMD_AC.representative_route_qa_state_v10528
      exhausted=(rs!=nil && rs[:complete] && (rs[:tuning] || []).empty?)
      log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FIXTURE_SUMMARY_V10534 ready='+(ready ? '1':'0')+
        ' candidate_exhausted='+(exhausted ? '1':'0')+' runs='+@rep_visual_runs_v10534.to_i.to_s+
        ' completes='+@rep_visual_completes_v10534.to_i.to_s+' input=F7'+
        ' next_gate=' + (@rep_visual_completes_v10534.to_i>0 ? 'manual_visual_findings':'run_visual_fixture')+
        ' gameplay_change=0')
    rescue
    end
    r
  end
end
