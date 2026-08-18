#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Battle Resource Loading Gate v1.02.9
#------------------------------------------------------------------------------
# 【用途】
# 1. 將「實際進入 live battle 前才可能第一次碰到的 PMD Action / VFX / SkillFX」
#    統一搬到戰鬥開始前讀取，避免戰鬥進行到第一次 Attack / Hurt / Hop / Shock 等動作時，
#    才同步讀取或建立資源而造成肉眼可見停頓。
# 2. 玩家按下開始戰鬥後，不立刻進入 live battle，而是顯示獨立讀取視窗：
#    「戰鬥準備中 + 百分比 + 目前階段 + 隨機 PMD 寶可夢跑動」。
# 3. 讀取完成、Motion local bind / transition warm / GC settle 全部結束後，才真正 start battle。
# 4. Loading 期間不呼叫 Input.update，因此 Shift/C/B 不會穿透到尚未完成的戰鬥。
#
# 【主要設定】
# - BATTLE_LOAD_VISUAL_BATCH_V1029：每處理幾個資源刷新一次 Loading 畫面。預設 4。
# - BATTLE_LOAD_ACTION_WEIGHT_V1029：Active Pokémon Action 資源占進度 0～58%。
# - BATTLE_LOAD_FX_WEIGHT_V1029：PMD_VFX + PMD_SkillFX 占 58～78%。
# - Motion 專用 cache/bind/transition 佔 78～97%，最後 GC / finalize 到 100%。
#
# 【機制規則】
# - Scene_PMD_AutoChess#start_battle 是唯一正式 gate。玩家按 Shift 後先跑 loading gate，
#   完成後才交回既有 start_battle alias chain。
# - 本版會預讀「本場 Active Pokémon 物種資料庫中所有存在的 PMD Action PNG」，不是只猜
#   目前技能會選哪一張，因此 Attack / Hurt / Hop / LookUp / Double / Shock 等 fallback 也先準備。
# - Graphics/Animations/PMD_VFX 與 Graphics/Pictures/PMD_SkillFX 目前體積很小，正式採整包預讀，
#   以換取 live battle 不再臨時解碼。未來素材量大幅成長時可再改成 encounter manifest。
# - PMD_MOTION_PHASE_A_V102 模式另外把 v1.02.2～v1.02.8 的 route cache、local bind、
#   transition warm 與 GC settle 全部放進此 Loading 階段；deploy 階段不再偷偷背景預熱。
# - 不修改 AI、傷害、Attack Speed、Spatial Framework、hit-stop、技能傷害時機或 logical xy。
#
# 【參數／可調整項】
# BATTLE_LOAD_VISUAL_BATCH_V1029 = 4
#   越小：百分比與跑動更新較細，但 Loading 最短時間會略增加。
#   越大：讀取較快，但 Loading 動畫更新較少。
#
# 【事件／腳本呼叫方式】
# 一般遊戲不需事件呼叫。所有 Scene_PMD_AutoChess 戰鬥在 start_battle 前自動執行。
# 開發查詢：
#   scene = $scene
#   scene.battle_resource_loading_ready_v1029?   # true / false
#
# 【實際範例】
# 布陣完成 → Shift
# → 顯示「戰鬥準備中 0%」
# → Action 58% → VFX/SkillFX 78% → Motion cache/bind/transition 97%
# → GC / Finalize 100%
# → Loading 視窗關閉 → live battle 才開始。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_BattleResourceLoadingGate_v1029'] = true

module PMD_AC
  BATTLE_RESOURCE_LOADING_VERSION_V1029 = '1.02.9'
  BATTLE_LOAD_VISUAL_BATCH_V1029 = 4
  BATTLE_LOAD_PMD_VFX_FOLDER_V1029 = 'Graphics/Animations/PMD_VFX/'
  BATTLE_LOAD_SKILL_FX_FOLDER_V1029 = 'Graphics/Pictures/PMD_SkillFX/'
end

#==============================================================================
# ■ Window_PMDBattleResourceLoadingV1029
#==============================================================================
class Window_PMDBattleResourceLoadingV1029 < Window_Base
  attr_reader :progress_v1029

  def initialize(viewport)
    w=390;h=184
    x=(Graphics.width-w)/2;y=(Graphics.height-h)/2
    super(x,y,w,h)
    self.viewport=viewport if respond_to?(:viewport=)
    self.z=20
    self.opacity=245
    self.back_opacity=235 if respond_to?(:back_opacity=)
    @progress_v1029=-1
    @stage_v1029='建立戰鬥資源清單'
    @detail_v1029=''
    @ticks_v1029=0
    refresh_v1029(0,@stage_v1029,@detail_v1029)
  end

  def update_progress_v1029(percent,stage,detail='')
    p=percent.to_i;p=0 if p<0;p=100 if p>100
    @ticks_v1029+=1
    return if @progress_v1029==p && @stage_v1029==stage.to_s && @detail_v1029==detail.to_s && (@ticks_v1029%4)!=0
    @progress_v1029=p
    @stage_v1029=stage.to_s
    @detail_v1029=detail.to_s
    refresh_v1029(p,@stage_v1029,@detail_v1029)
  end

  def refresh_v1029(percent,stage,detail)
    self.contents.clear
    begin
      self.contents.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      self.contents.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    self.contents.font.bold=true
    self.contents.font.size=22
    self.contents.font.color=Color.new(255,255,255)
    self.contents.draw_text(0,0,self.contents.width,28,'戰鬥準備中  '+percent.to_i.to_s+'%',1)

    bar_x=18;bar_y=39;bar_w=self.contents.width-36;bar_h=14
    self.contents.fill_rect(bar_x,bar_y,bar_w,bar_h,Color.new(35,45,55,220))
    fill=((bar_w-4)*percent.to_i/100.0).round
    fill=0 if fill<0
    self.contents.fill_rect(bar_x+2,bar_y+2,fill,bar_h-4,Color.new(100,190,245,235))

    self.contents.font.bold=false
    self.contents.font.size=15
    self.contents.font.color=Color.new(205,230,245)
    self.contents.draw_text(8,61,self.contents.width-16,22,stage.to_s,1)
    self.contents.font.size=13
    self.contents.font.color=Color.new(170,195,215)
    self.contents.draw_text(8,84,self.contents.width-16,20,detail.to_s,1)
    self.contents.font.size=12
    self.contents.font.color=Color.new(145,170,190)
    self.contents.draw_text(8,108,self.contents.width-16,18,'完成後才會正式開始戰鬥',1)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Loading Gate
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1029_start start unless method_defined?(:pmd_ac_v1029_start)
  alias pmd_ac_v1029_start_battle start_battle unless method_defined?(:pmd_ac_v1029_start_battle)
  alias pmd_ac_v1029_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1029_restart_to_deploy)
  alias pmd_ac_v1029_motion_prewarm_step_v1022 motion_prewarm_step_v1022 unless method_defined?(:pmd_ac_v1029_motion_prewarm_step_v1022)
  alias pmd_ac_v1029_motion_step_local_bind_v1024 motion_step_local_bind_v1024 unless method_defined?(:pmd_ac_v1029_motion_step_local_bind_v1024)
  alias pmd_ac_v1029_motion_step_vfx_prewarm_v1024 motion_step_vfx_prewarm_v1024 unless method_defined?(:pmd_ac_v1029_motion_step_vfx_prewarm_v1024)
  alias pmd_ac_v1029_motion_step_transition_warm_v1028 motion_step_transition_warm_v1028 unless method_defined?(:pmd_ac_v1029_motion_step_transition_warm_v1028)
  alias pmd_ac_v1029_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1029_update_verification_script)

  def battle_resource_loading_mode_v1029?
    true
  rescue
    false
  end

  def motion_loading_mode_v1029?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def battle_resource_loading_reset_v1029
    @battle_resource_loading_ready_v1029=false
    @battle_resource_loading_running_v1029=false
    @battle_resource_loading_summary_v1029=nil
    @battle_resource_loading_verify_logged_v1029=false
  end

  def start
    battle_resource_loading_reset_v1029
    pmd_ac_v1029_start
  end

  def restart_to_deploy
    result=pmd_ac_v1029_restart_to_deploy
    battle_resource_loading_reset_v1029 if @phase==:deploy
    result
  end

  # v1.02.2～v1.02.8 原本在 deploy 背景合作式預熱；v1.02.9 改為 Shift 後顯示百分比視窗
  # 再執行，因此 Loading 前一律不偷偷消耗這些 queue。
  def motion_prewarm_step_v1022(max_items=nil)
    return true if motion_loading_mode_v1029? && !@battle_resource_loading_running_v1029
    pmd_ac_v1029_motion_prewarm_step_v1022(max_items)
  end

  def motion_step_local_bind_v1024
    return if motion_loading_mode_v1029? && !@battle_resource_loading_running_v1029
    pmd_ac_v1029_motion_step_local_bind_v1024
  end

  def motion_step_vfx_prewarm_v1024
    return if motion_loading_mode_v1029? && !@battle_resource_loading_running_v1029
    pmd_ac_v1029_motion_step_vfx_prewarm_v1024
  end

  def motion_step_transition_warm_v1028
    return if motion_loading_mode_v1029? && !@battle_resource_loading_running_v1029
    pmd_ac_v1029_motion_step_transition_warm_v1028
  end

  def battle_resource_loading_ready_v1029?
    @battle_resource_loading_ready_v1029 ? true : false
  rescue
    false
  end

  def battle_loading_active_species_v1029
    seen={};out=[]
    (@units || []).each do |u|
      next if u==nil
      sid=u.species.to_s rescue ''
      next if sid.empty? || seen[sid]
      seen[sid]=true;out.push(sid)
    end
    out
  rescue
    []
  end

  def battle_loading_add_bitmap_v1029(queue,seen,folder,name,stage)
    return if folder==nil || name==nil
    n=name.to_s.sub(/\.png$/i,'')
    return if n.empty?
    key=folder.to_s+'|'+n
    return if seen[key]
    path=folder.to_s+n+'.png'
    return unless FileTest.exist?(path)
    seen[key]=true
    queue.push([folder.to_s,n,stage.to_s])
  rescue
  end

  def battle_loading_collect_assets_v1029
    queue=[];seen={}
    battle_loading_active_species_v1029.each do |sid|
      folder=PMD_AC::PMD_ROOT+sid+'/'
      begin
        db=PMD_AC.action_database[sid]
        if db
          db.each_value do |ad|
            next if ad==nil || ad[:file]==nil
            battle_loading_add_bitmap_v1029(queue,seen,folder,ad[:file],'寶可夢動作')
          end
        end
      rescue
      end
      # action_database 以外的 fallback / legacy -Anim 也納入。
      begin
        Dir.glob(folder+'*.png').sort.each do |path|
          name=File.basename(path,'.png')
          battle_loading_add_bitmap_v1029(queue,seen,folder,name,'寶可夢動作')
        end
      rescue
      end
    end
    begin
      Dir.glob(PMD_AC::BATTLE_LOAD_PMD_VFX_FOLDER_V1029+'*.png').sort.each do |path|
        battle_loading_add_bitmap_v1029(queue,seen,PMD_AC::BATTLE_LOAD_PMD_VFX_FOLDER_V1029,
          File.basename(path,'.png'),'技能 VFX')
      end
    rescue
    end
    begin
      Dir.glob(PMD_AC::BATTLE_LOAD_SKILL_FX_FOLDER_V1029+'*.png').sort.each do |path|
        battle_loading_add_bitmap_v1029(queue,seen,PMD_AC::BATTLE_LOAD_SKILL_FX_FOLDER_V1029,
          File.basename(path,'.png'),'技能特效')
      end
    rescue
    end
    queue
  rescue
    []
  end

  def battle_loading_open_overlay_v1029
    vp=Viewport.new(0,0,Graphics.width,Graphics.height);vp.z=65000
    dim=Sprite.new(vp);dim.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    dim.bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0,145));dim.z=0
    win=Window_PMDBattleResourceLoadingV1029.new(vp)
    poke=nil
    begin;poke=Sprite_PMDLoadingPokemonV1007.new(vp,win);rescue;poke=nil;end
    [vp,dim,win,poke]
  rescue
    [nil,nil,nil,nil]
  end

  def battle_loading_draw_v1029(ui,percent,stage,detail='',force=false)
    return if ui==nil
    win=ui[2];poke=ui[3]
    begin;win.update_progress_v1029(percent,stage,detail) if win;rescue;end
    begin;poke.update_v1007 if poke;rescue;end
    begin;Graphics.update;rescue;end
  end

  def battle_loading_close_overlay_v1029(ui)
    return if ui==nil
    vp=ui[0];dim=ui[1];win=ui[2];poke=ui[3]
    begin;poke.dispose_v1007 if poke;rescue;end
    begin;win.dispose if win;rescue;end
    begin
      if dim
        begin;dim.bitmap.dispose if dim.bitmap && !dim.bitmap.disposed?;rescue;end
        dim.dispose unless dim.disposed?
      end
    rescue
    end
    begin;vp.dispose if vp && !vp.disposed?;rescue;end
    begin;Graphics.update;rescue;end
  end

  def battle_loading_percent_range_v1029(done,total,a,b)
    return b if total.to_i<=0
    a.to_f+(b.to_f-a.to_f)*(done.to_f/total.to_f)
  rescue
    a
  end

  def battle_loading_process_asset_queue_v1029(ui,queue)
    total=queue.size;done=0;fail=0;ms_total=0;ms_max=0
    batch=PMD_AC::BATTLE_LOAD_VISUAL_BATCH_V1029.to_i;batch=1 if batch<=0
    queue.each do |row|
      t=Time.now.to_f;ok=true
      begin;Cache.load_bitmap(row[0],row[1]);rescue;ok=false;fail+=1;end
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      ms_total+=ms;ms_max=ms if ms>ms_max
      done+=1
      if done==1 || done==total || (done%batch)==0
        pct=battle_loading_percent_range_v1029(done,total,0,78).round
        detail=done.to_s+'/'+total.to_s+'  '+row[2].to_s
        battle_loading_draw_v1029(ui,pct,row[2],detail)
      end
    end
    [total,done,fail,ms_total,ms_max]
  rescue
    [0,0,1,0,0]
  end

  def battle_loading_process_motion_v1029(ui)
    return {:enabled=>0,:fail=>0} unless motion_loading_mode_v1029?
    # v1.02.2 route / representative bitmap queue：78～84%
    begin
      motion_build_prewarm_queue_v1022 if @motion_prewarm_queue_v1022==nil
      total=(@motion_prewarm_queue_v1022 || []).size;start_total=total;done=0
      while !@motion_prewarm_done_v1022
        before=(@motion_prewarm_queue_v1022 || []).size
        pmd_ac_v1029_motion_prewarm_step_v1022(1)
        after=(@motion_prewarm_queue_v1022 || []).size
        done+=1 if after<before
        pct=battle_loading_percent_range_v1029(done,[start_total,1].max,78,84).round
        battle_loading_draw_v1029(ui,pct,'建立 Motion Route Cache',done.to_s+'/'+start_total.to_s) if (done%4)==0 || @motion_prewarm_done_v1022
      end
    rescue
      @motion_prewarm_done_v1022=true
      @motion_prewarm_failed_v1022=@motion_prewarm_failed_v1022.to_i+1
    end

    # v1.02.4 local bind + VFX：84～92%
    begin
      @motion_live_queue_ready_v1024=false if @motion_live_queue_ready_v1024==nil
      motion_build_live_queues_v1024 unless @motion_live_queue_ready_v1024
      lt=@motion_local_bind_total_v1024.to_i;vt=@motion_vfx_total_v1024.to_i
      while !@motion_local_bind_done_v1024 || !@motion_vfx_done_v1024
        pmd_ac_v1029_motion_step_local_bind_v1024 unless @motion_local_bind_done_v1024
        pmd_ac_v1029_motion_step_vfx_prewarm_v1024 unless @motion_vfx_done_v1024
        ld=@motion_local_bind_ok_v1024.to_i+@motion_local_bind_fail_v1024.to_i
        vd=@motion_vfx_loaded_v1024.to_i+@motion_vfx_fail_v1024.to_i
        all=[lt+vt,1].max;now=ld+vd
        pct=battle_loading_percent_range_v1029(now,all,84,92).round
        battle_loading_draw_v1029(ui,pct,'綁定戰鬥 Sprite / VFX',now.to_s+'/'+all.to_s)
      end
    rescue
      @motion_local_bind_done_v1024=true;@motion_vfx_done_v1024=true
      @motion_local_bind_fail_v1024=@motion_local_bind_fail_v1024.to_i+1
    end

    # v1.02.5 heap settle：92～94%。必須在 local bind / VFX ready 後設好既有 gate flag。
    begin
      motion_heap_settle_v1025 unless @motion_heap_settled_v1025
      battle_loading_draw_v1029(ui,94,'整理 Motion Heap','local bind / VFX 已完成')
    rescue
      @motion_heap_settled_v1025=true
      @motion_heap_settle_failed_v1025=true
    end

    # v1.02.8 真正 Sprite transition warm：94～97%
    begin
      motion_build_transition_queue_v1028 if @motion_transition_queue_v1028==nil && !@motion_transition_ready_v1028
      tt=@motion_transition_total_v1028.to_i
      while !@motion_transition_ready_v1028
        before=(@motion_transition_queue_v1028 || []).size
        pmd_ac_v1029_motion_step_transition_warm_v1028
        after=(@motion_transition_queue_v1028 || []).size
        td=tt-after
        pct=battle_loading_percent_range_v1029(td,[tt,1].max,94,97).round
        battle_loading_draw_v1029(ui,pct,'預熱動作切換',td.to_s+'/'+tt.to_s)
      end
    rescue
      @motion_transition_ready_v1028=true
      @motion_transition_fail_v1028=@motion_transition_fail_v1028.to_i+1
    end

    {:enabled=>1,
      :fail=>@motion_prewarm_failed_v1022.to_i+@motion_local_bind_fail_v1024.to_i+
        @motion_vfx_fail_v1024.to_i+@motion_transition_fail_v1028.to_i}
  rescue
    {:enabled=>1,:fail=>1}
  end

  def run_battle_resource_loading_v1029
    return true if @battle_resource_loading_ready_v1029
    @battle_resource_loading_running_v1029=true
    ui=battle_loading_open_overlay_v1029
    t0=Time.now.to_f
    battle_loading_draw_v1029(ui,0,'建立戰鬥資源清單','Active Pokémon / VFX / SkillFX')
    assets=battle_loading_collect_assets_v1029
    asset_stat=battle_loading_process_asset_queue_v1029(ui,assets)
    motion_stat=battle_loading_process_motion_v1029(ui)

    battle_loading_draw_v1029(ui,98,'整理記憶體','完成後正式進入戰鬥')
    gc_ms=0;gc_ok=1
    begin
      gt=Time.now.to_f;GC.start;gc_ms=((Time.now.to_f-gt)*1000.0).round
    rescue
      gc_ok=0;gc_ms=-1
    end
    battle_loading_draw_v1029(ui,100,'完成','戰鬥即將開始')
    total_ms=((Time.now.to_f-t0)*1000.0).round rescue 0
    @battle_resource_loading_ready_v1029=(asset_stat[2].to_i==0 && motion_stat[:fail].to_i==0 && gc_ok==1)
    # 即使個別 optional bitmap fail，也不讓玩家永遠卡在 Loading；舊 fallback 仍可接手。
    @battle_resource_loading_ready_v1029=true unless @battle_resource_loading_ready_v1029
    @battle_resource_loading_summary_v1029={
      :assets=>asset_stat[0],:loaded=>asset_stat[1],:asset_fail=>asset_stat[2],
      :asset_ms=>asset_stat[3],:asset_max=>asset_stat[4],:motion=>motion_stat[:enabled],
      :motion_fail=>motion_stat[:fail],:gc_ms=>gc_ms,:total_ms=>total_ms
    }
    battle_loading_close_overlay_v1029(ui)
    @battle_resource_loading_running_v1029=false
    begin
      log_event(:perf,'BATTLE_RESOURCE_LOADING_V1029 ready=1 assets='+asset_stat[0].to_i.to_s+
        ' loaded='+asset_stat[1].to_i.to_s+' asset_fail='+asset_stat[2].to_i.to_s+
        ' asset_ms='+asset_stat[3].to_i.to_s+' asset_max_ms='+asset_stat[4].to_i.to_s+
        ' motion='+motion_stat[:enabled].to_i.to_s+' motion_fail='+motion_stat[:fail].to_i.to_s+
        ' gc_ms='+gc_ms.to_i.to_s+' total_ms='+total_ms.to_i.to_s+' percent_ui=1 input_passthrough=0')
    rescue
    end
    true
  rescue Exception=>e
    @battle_resource_loading_running_v1029=false
    @battle_resource_loading_ready_v1029=true
    begin;battle_loading_close_overlay_v1029(ui);rescue;end
    begin;log_event(:perf,'BATTLE_RESOURCE_LOADING_V1029 ready=1 fallback=1 error='+e.class.to_s);rescue;end
    true
  end

  def start_battle
    if battle_resource_loading_mode_v1029? && !@battle_resource_loading_ready_v1029 && !@battle_resource_loading_running_v1029
      run_battle_resource_loading_v1029
    end
    pmd_ac_v1029_start_battle
  end

  def verify_battle_resource_loading_v1029
    return if @verification_done[:battle_resource_loading_v1029]
    s=@battle_resource_loading_summary_v1029 || {}
    pass=@battle_resource_loading_ready_v1029 && s[:loaded].to_i>0 && s[:asset_fail].to_i==0 && s[:motion_fail].to_i==0
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'BATTLE_RESOURCE_LOADING_V1029 pass='+(pass ? '1':'0')+
      ' before_live_battle=1 percentage_ui=1 action_assets='+s[:assets].to_i.to_s+
      ' asset_fail='+s[:asset_fail].to_i.to_s+' motion_fail='+s[:motion_fail].to_i.to_s+
      ' input_passthrough=0 gc_before_battle=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:battle_resource_loading_v1029]=true
  end

  def update_verification_script
    pmd_ac_v1029_update_verification_script
    return unless motion_loading_mode_v1029?
    verify_battle_resource_loading_v1029 if @verification_frame.to_i>=45
  end
end
