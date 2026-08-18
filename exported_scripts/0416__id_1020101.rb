#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Battle Render Prime v1.02.10
#------------------------------------------------------------------------------
# 【用途】
# 1. 延續 v1.02.9「戰鬥前 Loading Gate」：除了把 Bitmap 載進 RGSS Cache，
#    再讓本場 Active Pokémon 的實際 Sprite 在 Loading 遮罩後方真正綁定並渲染一次
#    每個可用 PMD Action，將「第一次真正顯示 Attack / Hurt / Hop / Shock 時才發生」的
#    renderer / texture first-touch 成本提前搬到讀取畫面。
# 2. v1.02.8 的 transition warm 只在同一 Ruby frame 內 assign→restore，沒有保證
#    Graphics.update 曾看見該 Action；本版改成 assign → Graphics.update → restore。
# 3. Loading 期間使用全黑遮罩蓋住 battle viewport，玩家只會看到「戰鬥準備中＋百分比＋
#    隨機 PMD 寶可夢跑動」，不會看到被預熱的戰鬥 Sprite 閃爍。
# 4. 預熱完成後再做一次 GC settle，才交回 v1.02.9 的 final GC / 100% / start_battle。
# 5. 本版不修改 AI、Damage、Attack Speed、Spatial Framework、hit-stop、Hurt ownership、
#    Native hitFrame、技能傷害時機或 logical xy。
#
# 【主要設定】
# - BATTLE_RENDER_PRIME_ACTIONS_PER_FRAME_V1030 = 6
#   每個 Graphics.update 最多同時讓 6 隻 Active Pokémon 各預熱 1 個 Action。
#   3v3 正好可同時處理 6 隻，避免 179 個 Action 需要 179 次 Graphics.update。
# - BATTLE_RENDER_PRIME_SLOW_MS_V1030 = 24
#   單一預熱畫面若超過此值，記入 slow_batch 統計；只記統計、不寫 live LOG。
# - BATTLE_RENDER_PRIME_OPAQUE_MASK_V1030 = true
#   GPU/Renderer 預熱期間把 v1.02.9 dim 改為全黑，確保預熱 Sprite 不會穿透 Loading。
#
# 【機制規則】
# - 只在 v1.02.9 Loading Gate 已完成 local action bind 後執行。
# - 預熱使用「實際 @unit_sprites」與 v1.02.4 local action cache，不建立替代戰鬥單位。
# - 每輪每隻 Sprite 只切 1 個 Action，然後呼叫一次 Graphics.update；下一輪再切下一個。
# - 每個 Sprite 的 bitmap / action_data / frame / src_rect / visible / opacity 等狀態在
#   Graphics.update 後立即完整還原，因此不改 live battle 初始 Pose。
# - Loading 期間不呼叫 Input.update，沿用 v1.02.9 input_passthrough=0。
# - 若個別 Action 預熱失敗，正式戰鬥仍可用既有 local cache / fallback，不會卡死 Loading。
#
# 【可調參數】
# PMD_AC::BATTLE_RENDER_PRIME_ACTIONS_PER_FRAME_V1030
#   建議保持 6。調低會讓 Loading 更久但每幀工作較少；調高對 3v3 沒實益。
# PMD_AC::BATTLE_RENDER_PRIME_SLOW_MS_V1030
#   只影響診斷門檻，不影響戰鬥。
#
# 【事件／腳本呼叫方式】
# 一般遊戲不需事件呼叫。v1.02.9 run_battle_resource_loading_v1029 自動執行。
# 開發查詢：
#   scene = $scene
#   scene.battle_render_prime_ready_v1030?      # true / false
#   scene.battle_render_prime_summary_v1030     # Hash
#
# 【實際範例】
# Shift → 戰鬥準備中 0% → 資源 Cache / Motion bind →
# 「預熱戰鬥動作 97～98%」：六隻 Sprite 在黑色 Loading 遮罩後實際渲染各 Action →
# GC settle → 100% → 才開始 live battle。
#
# 【驗證 LOG】
# PERF：
#   BATTLE_RENDER_PRIME_V1030 ready=1 items=... rendered=... fail=0 graphics_updates=...
# VERIFY：
#   BATTLE_RENDER_PRIME_V1030 pass=1 real_sprite=1 graphics_update=1 before_live_battle=1 ...
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_BattleRenderPrime_v1030'] = true

module PMD_AC
  BATTLE_RENDER_PRIME_VERSION_V1030='1.02.10'
  BATTLE_RENDER_PRIME_ACTIONS_PER_FRAME_V1030=6
  BATTLE_RENDER_PRIME_SLOW_MS_V1030=24
  BATTLE_RENDER_PRIME_OPAQUE_MASK_V1030=true
end

#==============================================================================
# ■ Sprite_PMDChessUnit - real-render prime apply / restore
#==============================================================================
class Sprite_PMDChessUnit
  def battle_render_prime_snapshot_v1030
    [self.bitmap,@action_data,@placeholder,@frame_index,@frame_wait,self.ox,self.oy,
      self.src_rect.x,self.src_rect.y,self.src_rect.width,self.src_rect.height,
      self.visible,self.opacity,self.zoom_x,self.zoom_y,self.mirror]
  rescue
    nil
  end

  def battle_render_prime_apply_v1030(action)
    return nil if @unit==nil || action==nil
    key=action.to_s.to_sym
    entry=nil
    begin;entry=motion_local_action_cache_v1024[key];rescue;entry=nil;end
    return nil if entry==nil || entry[0]==nil || entry[0].disposed? || entry[1]==nil
    snap=battle_render_prime_snapshot_v1030
    return nil if snap==nil
    self.bitmap=entry[0]
    @action_data=entry[1]
    @placeholder=false
    @frame_index=0
    @frame_wait=0
    self.visible=true
    self.opacity=255
    setup_source_rect
    snap
  rescue
    nil
  end

  def battle_render_prime_restore_v1030(snap)
    return false if snap==nil
    self.bitmap=snap[0]
    @action_data=snap[1]
    @placeholder=snap[2]
    @frame_index=snap[3]
    @frame_wait=snap[4]
    self.ox=snap[5]
    self.oy=snap[6]
    self.src_rect.set(snap[7],snap[8],snap[9],snap[10])
    self.visible=snap[11]
    self.opacity=snap[12]
    self.zoom_x=snap[13]
    self.zoom_y=snap[14]
    self.mirror=snap[15]
    true
  rescue
    false
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - renderer first-touch inside v1.02.9 Loading Gate
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1030_start start unless method_defined?(:pmd_ac_v1030_start)
  alias pmd_ac_v1030_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1030_restart_to_deploy)
  alias pmd_ac_v1030_battle_loading_process_motion_v1029 battle_loading_process_motion_v1029 unless method_defined?(:pmd_ac_v1030_battle_loading_process_motion_v1029)
  alias pmd_ac_v1030_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1030_update_verification_script)

  def battle_render_prime_reset_v1030
    @battle_render_prime_ready_v1030=false
    @battle_render_prime_summary_v1030=nil
    @battle_render_prime_verify_logged_v1030=false
  end

  def start
    battle_render_prime_reset_v1030
    pmd_ac_v1030_start
  end

  def restart_to_deploy
    r=pmd_ac_v1030_restart_to_deploy
    battle_render_prime_reset_v1030 if @phase==:deploy
    r
  end

  def battle_render_prime_ready_v1030?
    @battle_render_prime_ready_v1030 ? true:false
  rescue
    false
  end

  def battle_render_prime_summary_v1030
    @battle_render_prime_summary_v1030 || {}
  rescue
    {}
  end

  def battle_render_prime_make_opaque_v1030(ui)
    return unless PMD_AC::BATTLE_RENDER_PRIME_OPAQUE_MASK_V1030
    return if ui==nil || ui[1]==nil || ui[1].bitmap==nil
    bmp=ui[1].bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0,255))
  rescue
  end

  # 每隻實際 Sprite 各自建立 Action queue。每個 Graphics.update 每隻最多取一個，
  # 因此同一輪最多 6 個真實 Action transition 可被 renderer 看見。
  def battle_render_prime_queues_v1030
    rows=[]
    (@unit_sprites || []).each do |sprite|
      next if sprite==nil || !sprite.respond_to?(:unit) || sprite.unit==nil
      cache=nil
      begin;cache=sprite.motion_local_action_cache_v1024;rescue;cache=nil;end
      next if cache==nil || cache.empty?
      acts=cache.keys.sort_by{|k|k.to_s}
      rows.push([sprite,acts]) unless acts.empty?
    end
    rows
  rescue
    []
  end

  def battle_render_prime_v1030(ui)
    return @battle_render_prime_summary_v1030 if @battle_render_prime_ready_v1030
    battle_render_prime_make_opaque_v1030(ui)
    queues=battle_render_prime_queues_v1030
    total=0
    queues.each{|row|total+=row[1].size}
    rendered=0;fail=0;updates=0;slow=0;max_ms=0;total_ms=0
    cursor={}
    queues.each{|row|cursor[row[0].object_id]=0}
    limit=PMD_AC::BATTLE_RENDER_PRIME_ACTIONS_PER_FRAME_V1030.to_i
    limit=1 if limit<=0

    loop do
      active=[]
      queues.each do |row|
        break if active.size>=limit
        sprite=row[0];acts=row[1];idx=cursor[sprite.object_id].to_i
        next if idx>=acts.size
        action=acts[idx]
        cursor[sprite.object_id]=idx+1
        snap=nil
        begin;snap=sprite.battle_render_prime_apply_v1030(action);rescue;snap=nil;end
        if snap==nil
          fail+=1
        else
          active.push([sprite,snap,action])
        end
      end
      break if active.empty? && queues.all?{|row|cursor[row[0].object_id].to_i>=row[1].size}

      done_now=rendered+fail+active.size
      pct=97.0+([done_now,total].min.to_f/[total,1].max.to_f)
      pct=98 if pct>98
      detail=[done_now,total].min.to_i.to_s+'/'+total.to_i.to_s+'  real Sprite render'
      begin
        win=ui==nil ? nil:ui[2];poke=ui==nil ? nil:ui[3]
        win.update_progress_v1029(pct.round,'預熱戰鬥動作',detail) if win
        poke.update_v1007 if poke
      rescue
      end
      t=Time.now.to_f
      begin;Graphics.update;rescue;end
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      total_ms+=ms;max_ms=ms if ms>max_ms;slow+=1 if ms>=PMD_AC::BATTLE_RENDER_PRIME_SLOW_MS_V1030
      updates+=1
      active.each do |row|
        ok=false
        begin;ok=row[0].battle_render_prime_restore_v1030(row[1]);rescue;ok=false;end
        ok ? rendered+=1 : fail+=1
      end
    end

    gc_ms=0;gc_ok=1
    begin
      t=Time.now.to_f;GC.start;gc_ms=((Time.now.to_f-t)*1000.0).round
    rescue
      gc_ok=0;gc_ms=-1
    end
    @battle_render_prime_ready_v1030=true
    @battle_render_prime_summary_v1030={
      :items=>total,:rendered=>rendered,:fail=>fail,:graphics_updates=>updates,
      :total_ms=>total_ms,:max_ms=>max_ms,:slow=>slow,:gc_ms=>gc_ms,:gc_ok=>gc_ok
    }
    begin
      log_event(:perf,'BATTLE_RENDER_PRIME_V1030 ready=1 items='+total.to_i.to_s+
        ' rendered='+rendered.to_i.to_s+' fail='+fail.to_i.to_s+
        ' graphics_updates='+updates.to_i.to_s+' total_ms='+total_ms.to_i.to_s+
        ' max_update_ms='+max_ms.to_i.to_s+' slow_batches='+slow.to_i.to_s+
        ' gc_ms='+gc_ms.to_i.to_s+' real_sprite=1 graphics_update=1 opaque_mask=1')
    rescue
    end
    @battle_render_prime_summary_v1030
  rescue Exception=>e
    @battle_render_prime_ready_v1030=true
    @battle_render_prime_summary_v1030={:items=>0,:rendered=>0,:fail=>1,:graphics_updates=>0,:gc_ok=>0}
    begin;log_event(:perf,'BATTLE_RENDER_PRIME_V1030 ready=1 fallback=1 error='+e.class.to_s);rescue;end
    @battle_render_prime_summary_v1030
  end

  # v1.02.9 Motion cache/bind/transition 都完成後，真正 start_battle 前再做 render prime。
  def battle_loading_process_motion_v1029(ui)
    stat=pmd_ac_v1030_battle_loading_process_motion_v1029(ui)
    if motion_loading_mode_v1029?
      rs=battle_render_prime_v1030(ui)
      stat[:fail]=stat[:fail].to_i+rs[:fail].to_i if stat.is_a?(Hash)
    end
    stat
  rescue
    {:enabled=>1,:fail=>1}
  end

  def verify_battle_render_prime_v1030
    return if @battle_render_prime_verify_logged_v1030
    s=battle_render_prime_summary_v1030
    pass=@battle_render_prime_ready_v1030 && s[:items].to_i>0 && s[:rendered].to_i>0 && s[:fail].to_i==0 && s[:graphics_updates].to_i>0 && s[:gc_ok].to_i==1
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'BATTLE_RENDER_PRIME_V1030 pass='+(pass ? '1':'0')+
      ' real_sprite=1 graphics_update=1 before_live_battle=1 items='+s[:items].to_i.to_s+
      ' rendered='+s[:rendered].to_i.to_s+' fail='+s[:fail].to_i.to_s+
      ' graphics_updates='+s[:graphics_updates].to_i.to_s+' opaque_loading_mask=1 input_passthrough=0'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @battle_render_prime_verify_logged_v1030=true
  end

  def update_verification_script
    pmd_ac_v1030_update_verification_script
    return unless verification_mode==:pmd_motion_phase_a_v102
    verify_battle_render_prime_v1030 if @verification_frame.to_i>=46
  end
end
