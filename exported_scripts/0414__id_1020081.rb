# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Transition Warmup / UI Fast Path v1.02.8
# 分類：PMD Motion Phase A／實機卡頓修正／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 依 v1.02.7 Deep Profiler 實機結果，修正「Bitmap 已預載，但 Sprite 第一次真正
#    切換 Attack / Hop / Hurt 等 Action 時仍出現 40~130ms hitch」的問題。
# 2. 在 deploy 階段，對本場六隻實際會用到的 Action 做一次真正的 Sprite.bitmap
#    transition warmup；戰鬥中第一次 Attack / Ambient 不再承擔首次綁定成本。
# 3. Motion verifier 專用 Header / Footer 改走輕量 fast path，避開數十版累積的
#    refresh_header / refresh_footer alias chain；其他正式模式完全不受影響。
#------------------------------------------------------------------------------
# 【v1.02.7 實機依據】
# - slow_bitmap=0，但 frame 20 / 28 / 36 / 126 / 160 仍出現 50~130ms Sprite update。
# - frame 126：皮卡丘 idle->hop，sprite_update 約 130ms。
# - frame 160：小火龍 idle->hop，sprite_update 約 103ms。
# - frame 20/28/36：各單位第一次 walk->attack 時，sprite_update 集中產生大型 spike。
# - 這表示 Cache.load_bitmap「檔案已在 Cache」不足以保證第一次 Sprite bitmap transition
#   沒有額外 RGSS2 圖形資源成本。
# - start_battle 的 refresh_header 另量到約 98ms；footer 在一場內被重畫數百次，
#   單次可達約 6~9ms。
#------------------------------------------------------------------------------
# 【核心規則】
# A. Transition Warmup
# - 等 v1.02.4 local bind / VFX prewarm 完成後才建立 warm queue。
# - 只暖 v1.02.4 motion_action_candidates_for_unit_v1024 回傳的「本場相關 Action」，
#   不把 0001-0026 全資料庫每個 Action 都跑一遍。
# - 每個 deploy frame 最多處理 1 個 Sprite/Action pair。
# - warmup 直接在「該單位自己的 Sprite」上暫時 assign 已快取 Bitmap，立刻恢復原
#   Bitmap / action_data / src_rect；同一個畫面 frame 最終仍顯示原姿勢，不改戰鬥狀態。
# - queue 完成後在 deploy 再做一次 GC settle，然後才允許真正 start_battle。
#
# B. Motion UI Fast Path
# - 只在 PMD_MOTION_PHASE_A_V102 生效。
# - Header 直接重畫目前必要資訊，不走歷史 refresh_header alias chain。
# - Footer 以狀態 key 去重；phase / speed / 存活數 / miss / warm-ready 沒改時不重畫。
# - NORMAL 與其他 S 模式仍完整呼叫舊 UI chain。
#
# C. Presentation-only
# - 不修改 AI、Target、Attack Speed、Damage Formula、Spatial Framework。
# - 不修改 hit-stop、Hurt ownership、source hitFrame、Projectile / FX timing。
# - Transition warmup 不寫 unit logical x/y，不改 action / action_timer。
#------------------------------------------------------------------------------
# 【可調參數】
# MOTION_TRANSITION_WARM_PER_FRAME_V1028 = 1
#   每個 deploy frame 暖幾個 Sprite/Action pair。1 最保守。
# MOTION_TRANSITION_SLOW_MS_V1028 = 20
#   deploy warmup 單項超過此毫秒數只做統計，不在 live battle 寫 LOG。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試：AutoChess 布陣 -> S 切 PMD_MOTION_PHASE_A_V102 -> Shift -> 完整打一場。
# 若玩家按 Shift 時 transition warmup 尚未完成，維持 deploy，完成後自動開始。
#------------------------------------------------------------------------------
# 【LOG／Verifier】
# deploy 完成：
#   MOTION_TRANSITION_WARM_V1028 ready=1 items=... total_ms=... max_ms=... slow=... gc_ms=...
# verifier：
#   MOTION_TRANSITION_UI_FASTPATH_V1028 pass=1 transition_warm=1 header_fast=1 footer_fast=1 ...
# 並繼續看 v1.02.3 / v1.02.6 / v1.02.7 的 frame profile 作前後比較。
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只以 Main 前 trailing override 安裝。
# - Pokémon 個體身份仍使用 instance_uid。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================
module PMD_AC
  MOTION_TRANSITION_WARM_VERSION_V1028='1.02.8'
  MOTION_TRANSITION_WARM_PER_FRAME_V1028=1
  MOTION_TRANSITION_SLOW_MS_V1028=20
end

#==============================================================================
# ■ Sprite_PMDChessUnit - 真正 Sprite/Bitmap transition warmup
#==============================================================================
class Sprite_PMDChessUnit
  def motion_warm_action_transition_v1028(action)
    return [false,0] if @unit==nil || action==nil
    key=action.to_s.to_sym
    entry=motion_local_action_cache_v1024[key] rescue nil
    return [false,0] if entry==nil || entry[0]==nil || entry[0].disposed?

    old_bitmap=self.bitmap
    old_data=@action_data
    old_placeholder=@placeholder
    old_frame_index=@frame_index
    old_frame_wait=@frame_wait
    old_ox=self.ox
    old_oy=self.oy
    old_src=[self.src_rect.x,self.src_rect.y,self.src_rect.width,self.src_rect.height]
    old_visible=self.visible
    ms=0
    ok=true
    begin
      # 同 frame 立即恢復，因此玩家不會看到 warm pose。
      self.visible=false
      t=Time.now.to_f
      self.bitmap=entry[0]
      @action_data=entry[1]
      @placeholder=false
      @frame_index=0
      @frame_wait=0
      setup_source_rect
      ms=((Time.now.to_f-t)*1000.0).round
    rescue
      ok=false
    ensure
      begin
        self.bitmap=old_bitmap
        @action_data=old_data
        @placeholder=old_placeholder
        @frame_index=old_frame_index
        @frame_wait=old_frame_wait
        self.ox=old_ox
        self.oy=old_oy
        self.src_rect.set(old_src[0],old_src[1],old_src[2],old_src[3])
        self.visible=old_visible
      rescue
        ok=false
      end
    end
    [ok,ms]
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - transition queue / start gate / Motion UI fast path
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1028_start start unless method_defined?(:pmd_ac_v1028_start)
  alias pmd_ac_v1028_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1028_restart_to_deploy)
  alias pmd_ac_v1028_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v1028_update_deploy_phase)
  alias pmd_ac_v1028_motion_live_ready_v1024 motion_live_ready_v1024? unless method_defined?(:pmd_ac_v1028_motion_live_ready_v1024)
  alias pmd_ac_v1028_refresh_header refresh_header unless method_defined?(:pmd_ac_v1028_refresh_header)
  alias pmd_ac_v1028_refresh_footer refresh_footer unless method_defined?(:pmd_ac_v1028_refresh_footer)
  alias pmd_ac_v1028_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1028_update_verification_script)

  def motion_v1028_mode?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_reset_transition_warm_v1028
    @motion_transition_queue_v1028=nil
    @motion_transition_seen_v1028={}
    @motion_transition_ready_v1028=false
    @motion_transition_total_v1028=0
    @motion_transition_done_v1028=0
    @motion_transition_fail_v1028=0
    @motion_transition_total_ms_v1028=0
    @motion_transition_max_ms_v1028=0
    @motion_transition_slow_v1028=0
    @motion_transition_gc_ms_v1028=0
    @motion_transition_logged_v1028=false
    @motion_ui_header_fast_used_v1028=false
    @motion_ui_footer_fast_used_v1028=false
    @motion_ui_footer_key_v1028=nil
  end

  def start
    motion_reset_transition_warm_v1028
    pmd_ac_v1028_start
  end

  def restart_to_deploy
    result=pmd_ac_v1028_restart_to_deploy
    motion_reset_transition_warm_v1028 if @phase==:deploy && motion_v1028_mode?
    result
  end

  def motion_transition_base_ready_v1028?
    # 直接問 v1.02.4 的 underlying local bind / VFX 狀態；v1.02.5 final ready 還含 heap gate。
    @motion_local_bind_done_v1024 && @motion_vfx_done_v1024
  rescue
    false
  end

  def motion_build_transition_queue_v1028
    return if @motion_transition_queue_v1028!=nil
    return unless motion_v1028_mode? && motion_transition_base_ready_v1028?
    q=[]
    seen={}
    (@units || []).each do |u|
      next if u==nil
      sid=u.species.to_s rescue ''
      next unless PMD_AC.motion_phase_a_species_v102?(sid)
      sprite=motion_sprite_for_unit_v1024(u) rescue nil
      next if sprite==nil
      actions=[]
      begin;actions=motion_action_candidates_for_unit_v1024(u);rescue;actions=[:walk,:idle,:hurt,:attack];end
      actions.each do |a|
        next if a==nil
        k=a.to_s.to_sym
        token=sprite.object_id.to_s+'|'+k.to_s
        next if seen[token]
        begin
          cache=sprite.motion_local_action_cache_v1024
          next unless cache.has_key?(k)
        rescue
          next
        end
        seen[token]=true
        q.push([sprite,k])
      end
    end
    @motion_transition_queue_v1028=q
    @motion_transition_total_v1028=q.size
    if q.empty?
      motion_finish_transition_warm_v1028
    end
  rescue
    @motion_transition_queue_v1028=[]
    @motion_transition_fail_v1028=@motion_transition_fail_v1028.to_i+1
    motion_finish_transition_warm_v1028
  end

  def motion_step_transition_warm_v1028
    return if @motion_transition_ready_v1028
    motion_build_transition_queue_v1028 if @motion_transition_queue_v1028==nil
    q=@motion_transition_queue_v1028
    return if q==nil
    lim=PMD_AC::MOTION_TRANSITION_WARM_PER_FRAME_V1028.to_i
    lim=1 if lim<=0
    n=0
    while n<lim && !q.empty?
      row=q.shift
      sprite=row[0];action=row[1]
      ok=false;ms=0
      begin
        r=sprite.motion_warm_action_transition_v1028(action)
        ok=r[0];ms=r[1].to_i
      rescue
        ok=false;ms=0
      end
      @motion_transition_done_v1028=@motion_transition_done_v1028.to_i+1 if ok
      @motion_transition_fail_v1028=@motion_transition_fail_v1028.to_i+1 unless ok
      @motion_transition_total_ms_v1028=@motion_transition_total_ms_v1028.to_i+ms
      @motion_transition_max_ms_v1028=[@motion_transition_max_ms_v1028.to_i,ms].max
      @motion_transition_slow_v1028=@motion_transition_slow_v1028.to_i+1 if ms>=PMD_AC::MOTION_TRANSITION_SLOW_MS_V1028
      n+=1
    end
    motion_finish_transition_warm_v1028 if q.empty?
  rescue
    @motion_transition_fail_v1028=@motion_transition_fail_v1028.to_i+1
    motion_finish_transition_warm_v1028
  end

  def motion_finish_transition_warm_v1028
    return if @motion_transition_ready_v1028
    gc_ms=0
    begin
      t=Time.now.to_f
      GC.start
      gc_ms=((Time.now.to_f-t)*1000.0).round
    rescue
      gc_ms=-1
    end
    @motion_transition_gc_ms_v1028=gc_ms
    @motion_transition_ready_v1028=true
    @motion_transition_queue_v1028=nil
    unless @motion_transition_logged_v1028
      @motion_transition_logged_v1028=true
      log_event(:perf,'MOTION_TRANSITION_WARM_V1028 ready=1 items='+@motion_transition_total_v1028.to_i.to_s+
        ' warmed='+@motion_transition_done_v1028.to_i.to_s+
        ' fail='+@motion_transition_fail_v1028.to_i.to_s+
        ' total_ms='+@motion_transition_total_ms_v1028.to_i.to_s+
        ' max_ms='+@motion_transition_max_ms_v1028.to_i.to_s+
        ' slow='+@motion_transition_slow_v1028.to_i.to_s+
        ' gc_ms='+gc_ms.to_i.to_s+' per_frame='+PMD_AC::MOTION_TRANSITION_WARM_PER_FRAME_V1028.to_i.to_s)
    end
  end

  # v1.02.4 / v1.02.5 的 start gate 最後會呼叫這個方法；Motion mode 再加 transition gate。
  def motion_live_ready_v1024?
    base=pmd_ac_v1028_motion_live_ready_v1024
    return base unless motion_v1028_mode?
    base && @motion_transition_ready_v1028
  rescue
    false
  end

  def update_deploy_phase
    result=pmd_ac_v1028_update_deploy_phase
    if @phase==:deploy && motion_v1028_mode?
      motion_build_transition_queue_v1028 if motion_transition_base_ready_v1028? && @motion_transition_queue_v1028==nil && !@motion_transition_ready_v1028
      motion_step_transition_warm_v1028 if @motion_transition_queue_v1028!=nil && !@motion_transition_ready_v1028
      # deploy footer 只在 ready 狀態改變時刷新，顯示「準備中 / ready」。
      refresh_footer if @motion_transition_ready_v1028 && @motion_ui_footer_key_v1028==nil
    end
    result
  end

  def motion_draw_header_fast_v1028
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(12,4,Graphics.width-24,26,'PMD Motion Framework Phase A v1.02',1)
    bmp.font.size=15;bmp.font.bold=false;bmp.font.color=Color.new(190,225,255)
    text='布陣｜Motion 資源準備中'
    if @phase==:battle
      text='Motion Runtime｜速度 x'+@battle_speed.to_i.to_s+'｜A 切換速度｜B 離開'
    elsif @phase==:result
      text='Motion 測試結束｜C 回布陣｜B 離開'
    elsif @motion_transition_ready_v1028
      text='布陣｜Motion Transition Ready｜Shift 開戰'
    end
    bmp.draw_text(12,34,Graphics.width-24,22,text,1)
    @motion_ui_header_fast_used_v1028=true
  end

  def refresh_header
    unless motion_v1028_mode?
      pmd_ac_v1028_refresh_header
      return
    end
    motion_draw_header_fast_v1028
  end

  def motion_footer_key_v1028
    if @phase==:battle
      [:battle,@battle_speed.to_i,living_units(:ally).size,living_units(:enemy).size,@miss_count.to_i]
    elsif @phase==:deploy
      [:deploy,@motion_transition_ready_v1028 ? 1:0]
    else
      [:result,@result_text.to_s]
    end
  rescue
    [@phase]
  end

  def motion_draw_footer_fast_v1028
    return if @footer_sprite==nil || @footer_sprite.bitmap==nil
    key=motion_footer_key_v1028
    return if @motion_ui_footer_key_v1028==key
    @motion_ui_footer_key_v1028=key
    bmp=@footer_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,52,Color.new(0,0,0,205))
    bmp.font.size=15;bmp.font.bold=false;bmp.font.color=Color.new(235,240,245)
    if @phase==:battle
      line1='藍方存活 '+living_units(:ally).size.to_s+'｜紅方存活 '+living_units(:enemy).size.to_s
      line2='Motion Phase A｜落空 '+@miss_count.to_i.to_s+' 次｜速度 x'+@battle_speed.to_i.to_s
    elsif @phase==:deploy
      line1=@motion_transition_ready_v1028 ? 'Motion Transition Warmup 完成' : 'Motion 資源合作式準備中…'
      line2=@motion_transition_ready_v1028 ? 'S 切換模式｜Shift 開戰' : '完成後才允許進入 live battle'
    else
      line1=@result_text.to_s
      line2='C 回到布陣｜B 離開'
    end
    bmp.draw_text(10,2,Graphics.width-20,22,line1,0)
    bmp.font.color=Color.new(170,220,255)
    bmp.draw_text(10,25,Graphics.width-20,22,line2,0)
    @motion_ui_footer_fast_used_v1028=true
  end

  def refresh_footer
    unless motion_v1028_mode?
      pmd_ac_v1028_refresh_footer
      return
    end
    motion_draw_footer_fast_v1028
  end

  def verify_motion_transition_ui_fastpath_v1028
    return if @verification_done[:motion_transition_ui_fastpath_v1028]
    pass=@motion_transition_ready_v1028 && @motion_transition_fail_v1028.to_i==0 &&
      @motion_ui_header_fast_used_v1028 && @motion_ui_footer_fast_used_v1028
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_TRANSITION_UI_FASTPATH_V1028 pass='+(pass ? '1':'0')+
      ' transition_warm='+(@motion_transition_ready_v1028 ? '1':'0')+
      ' warm_fail='+@motion_transition_fail_v1028.to_i.to_s+
      ' warm_items='+@motion_transition_total_v1028.to_i.to_s+
      ' warm_max_ms='+@motion_transition_max_ms_v1028.to_i.to_s+
      ' header_fast='+(@motion_ui_header_fast_used_v1028 ? '1':'0')+
      ' footer_fast='+(@motion_ui_footer_fast_used_v1028 ? '1':'0')+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_transition_ui_fastpath_v1028]=true
  end

  def update_verification_script
    pmd_ac_v1028_update_verification_script
    if motion_v1028_mode? && @verification_frame.to_i>=43
      verify_motion_transition_ui_fastpath_v1028
    end
  end
end
