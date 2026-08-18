# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Runtime Cache / Stutter Fix v1.02.2
# 分類：PMD Motion Phase A／效能／Presentation Cache／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 修正 v1.02～v1.02.1 啟用 PMD Motion Framework 後，在戰鬥剛開始、第一次播放
# Hurt／Ambient／Native Skill Action，以及 Motion verifier 寫入診斷 LOG 時可能出現的
# 短暫卡頓。此版只處理 Presentation 與診斷 I/O，不修改 AI、Attack Speed、Damage、
# Dynamic Tactical Role 或 Spatial Framework。
#------------------------------------------------------------------------------
# 【問題來源】
# 1. Sprite 第一次切換到某張 PMD Action PNG 時，Cache.load_bitmap 必須同步讀檔並解碼；
#    v1.02 新增更多 Hurt／Ambient／Native Action，因此第一次出現時會形成離散 hitch。
# 2. refresh_action_bitmap 每次切 Action 都會再次做 bitmap_exists?；即使 Bitmap 已在 RGSS2
#    Cache 中，仍有同步 FileTest 查詢。
# 3. Motion source route / hasNative / hasPlayable 在戰鬥與 verifier 中會重複做相同查找。
# 4. Current-Test LOG 的 persistent File 原本 sync=true；Motion verifier 新增 MOTION_HIT、
#    MOTION_NATIVE 等診斷後，每一行都可能立刻 flush 到磁碟。
# 5. motion_actual_moving_v102? 每次以 sqrt 求速度，對每隻單位每 frame 重複呼叫沒有必要。
#------------------------------------------------------------------------------
# 【本版機制】
# A. Static Runtime Cache
# - bitmap_exists? 結果以完整 folder/file 快取；素材在一次遊戲執行中視為靜態。
# - motion_direct_native / motion_playable / motion_source_route 以 species+action/move 快取。
# - 開發中若熱替換素材，可呼叫 PMD_AC.clear_motion_runtime_cache_v1022 手動清除。
#
# B. Active Battler Motion Prewarm
# - Scene 進入布陣後，逐 frame 預讀「本場實際六隻」需要的 Action Bitmap。
# - 預讀項目：Walk / Idle / Hurt / Attack、該物種 Ambient Rich LOOP 特殊動作、
#   Basic source pose、目前技能 source pose、Air/Float 時的 Hover。
# - 每個 deploy frame 最多讀 1 張，避免把數十張 PNG 一次同步解碼。
# - 若玩家太快按開始而 queue 尚未完成，會留在 deploy 幾個 frame，讀完後自動開戰；
#   不把未完成的 PNG 解碼工作帶進 live battle。
# - Cache 只保留 RGSS2 原本 Cache.load_bitmap 的 Bitmap，不建立第二份 Bitmap。
#
# C. Motion Verifier LOG I/O Buffer
# - 只在 PMD_MOTION_PHASE_A_V102 測試模式，把 persistent Battle LOG sync 暫時設為 false。
# - verifier side-effect 仍照常執行；只是不讓每一條 MOTION_HIT 立即同步 flush。
# - 戰鬥結束、回布陣、Scene terminate 時強制 flush 並恢復 sync。
# - NORMAL 模式完全沿用既有 LOG 行為。
#
# D. Moving Check
# - 以 vx*vx+vy*vy > 0.18^2 取代 sqrt，判定門檻完全相同。
#------------------------------------------------------------------------------
# 【可調參數】
# MOTION_PREWARM_PER_DEPLOY_FRAME_V1022 = 1
#   每個布陣 frame 預讀幾張 Action Bitmap。1 最平滑；若裝置 SSD 很快可改 2。
# MOTION_PREWARM_ROUTE_SAMPLES_V1022
#   Motion verifier 會查的代表 move metadata，預先建立 route cache，避免 verifier frame
#   44 集中第一次查找。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 一般遊戲與事件不需呼叫，Scene_PMD_AutoChess 自動處理。
# 開發時若在遊戲執行中替換 PMD PNG，可執行：
#   PMD_AC.clear_motion_runtime_cache_v1022
# 下一次進 AutoChess Scene 會重新建立本場 prewarm queue。
#------------------------------------------------------------------------------
# 【實際範例】
# 皮卡丘第一次使用 Shock：
# v1.02.1 可能在第一次 Action sheet 切換時才同步解碼 Shock-Anim.png。
# v1.02.2 在 deploy 已逐 frame Cache.load_bitmap，真正命中 skill release 時只取 Cache。
#
# 小火龍 Ambient Hop：
# v1.02.1 第一次 Hop 可能碰到 bitmap existence + decode。
# v1.02.2 Hop 已在 deploy 預熱；Ambient 切換只改既有 Cache bitmap / src_rect。
#------------------------------------------------------------------------------
# 【Verifier／LOG】
# PMD_MOTION_PHASE_A_V102 會新增：
#   MOTION_RUNTIME_CACHE_V1022 pass=1 ...
# PERF 會新增一次：
#   MOTION_PREWARM_V1022 ready=1 files=... loaded=... fail=... total_ms=...
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只以 Main 前 trailing alias／override 安裝。
# - Pokémon 個體身份仍使用 instance_uid。
# - Motion 只取得 Presentation 權限，不修改 logical pixel_x / pixel_y。
# - 不修改 Attack Speed、Damage Formula、AI Policy、Dynamic Tactical Role、Spatial Runtime。
#==============================================================================
module PMD_AC
  MOTION_RUNTIME_CACHE_VERSION_V1022='1.02.2'
  MOTION_PREWARM_PER_DEPLOY_FRAME_V1022=1
  MOTION_PREWARM_ROUTE_SAMPLES_V1022=[
    ['0001',:tackle],['0004',:ember],['0007',:water_gun],['0010',:string_shot],
    ['0019',:quick_attack],['0016',:gust],['0025',:thunderbolt]
  ]

  class << self
    alias pmd_ac_v1022_bitmap_exists? bitmap_exists? unless method_defined?(:pmd_ac_v1022_bitmap_exists?)
    alias pmd_ac_v1022_motion_direct_native_v102? motion_direct_native_v102? unless method_defined?(:pmd_ac_v1022_motion_direct_native_v102?)
    alias pmd_ac_v1022_motion_playable_v102? motion_playable_v102? unless method_defined?(:pmd_ac_v1022_motion_playable_v102?)
    alias pmd_ac_v1022_motion_source_route_v102 motion_source_route_v102 unless method_defined?(:pmd_ac_v1022_motion_source_route_v102)

    def clear_motion_runtime_cache_v1022
      @motion_bitmap_exists_cache_v1022={}
      @motion_direct_native_cache_v1022={}
      @motion_playable_cache_v1022={}
      @motion_source_route_cache_v1022={}
      true
    end

    def bitmap_exists?(folder,filename)
      return false if filename==nil
      @motion_bitmap_exists_cache_v1022={} if @motion_bitmap_exists_cache_v1022==nil
      key=folder.to_s+'|'+filename.to_s
      return @motion_bitmap_exists_cache_v1022[key] if @motion_bitmap_exists_cache_v1022.has_key?(key)
      value=pmd_ac_v1022_bitmap_exists?(folder,filename) ? true : false
      @motion_bitmap_exists_cache_v1022[key]=value
      value
    end

    def motion_direct_native_v102?(species,pose)
      return pmd_ac_v1022_motion_direct_native_v102?(species,pose) unless motion_phase_a_species_v102?(species)
      @motion_direct_native_cache_v1022={} if @motion_direct_native_cache_v1022==nil
      key=species.to_s+'|'+pose.to_s
      return @motion_direct_native_cache_v1022[key] if @motion_direct_native_cache_v1022.has_key?(key)
      value=pmd_ac_v1022_motion_direct_native_v102?(species,pose) ? true : false
      @motion_direct_native_cache_v1022[key]=value
      value
    end

    def motion_playable_v102?(species,pose)
      return pmd_ac_v1022_motion_playable_v102?(species,pose) unless motion_phase_a_species_v102?(species)
      @motion_playable_cache_v1022={} if @motion_playable_cache_v1022==nil
      key=species.to_s+'|'+pose.to_s
      return @motion_playable_cache_v1022[key] if @motion_playable_cache_v1022.has_key?(key)
      value=pmd_ac_v1022_motion_playable_v102?(species,pose) ? true : false
      @motion_playable_cache_v1022[key]=value
      value
    end

    def motion_source_route_v102(species,move_key,data=nil,profile=nil)
      return pmd_ac_v1022_motion_source_route_v102(species,move_key,data,profile) unless motion_phase_a_species_v102?(species)
      @motion_source_route_cache_v1022={} if @motion_source_route_cache_v1022==nil
      mk=motion_move_key_v102(move_key)
      key=species.to_s+'|'+mk.to_s
      return @motion_source_route_cache_v1022[key] if @motion_source_route_cache_v1022.has_key?(key)
      value=pmd_ac_v1022_motion_source_route_v102(species,move_key,data,profile)
      @motion_source_route_cache_v1022[key]=value
      value
    end

    def motion_runtime_cache_status_v1022
      {
        :bitmap=>(@motion_bitmap_exists_cache_v1022 || {}).size,
        :native=>(@motion_direct_native_cache_v1022 || {}).size,
        :playable=>(@motion_playable_cache_v1022 || {}).size,
        :route=>(@motion_source_route_cache_v1022 || {}).size
      }
    end
  end

  clear_motion_runtime_cache_v1022
end

#==============================================================================
# ■ Game_PMDChessUnit - remove repeated sqrt from Ambient motion checks
#==============================================================================
class Game_PMDChessUnit
  def motion_actual_moving_v102?
    vx=@velocity_x.to_f
    vy=@velocity_y.to_f
    (vx*vx+vy*vy)>0.0324 || @move_goal_x!=nil || @move_goal_y!=nil
  rescue
    false
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - active bitmap prewarm + verifier IO buffering
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1022_start start unless method_defined?(:pmd_ac_v1022_start)
  alias pmd_ac_v1022_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v1022_update_deploy_phase)
  alias pmd_ac_v1022_start_battle start_battle unless method_defined?(:pmd_ac_v1022_start_battle)
  alias pmd_ac_v1022_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1022_check_battle_end)
  alias pmd_ac_v1022_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1022_restart_to_deploy)
  alias pmd_ac_v1022_terminate terminate unless method_defined?(:pmd_ac_v1022_terminate)
  alias pmd_ac_v1022_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1022_update_verification_script)

  def motion_prewarm_add_bitmap_v1022(species,action)
    return if species==nil || action==nil
    sid=species.to_s
    return unless PMD_AC.motion_phase_a_species_v102?(sid)
    d=nil
    begin
      d=PMD_AC.compiled_direct_action_v061(sid,action) if PMD_AC.respond_to?(:compiled_direct_action_v061)
    rescue
      d=nil
    end
    begin
      d=PMD_AC.action_data(sid,action) if d==nil
    rescue
      d=nil
    end
    return if d==nil || d[:file]==nil
    folder=PMD_AC::PMD_ROOT+sid+'/'
    file=d[:file].to_s
    return unless PMD_AC.bitmap_exists?(folder,file)
    @motion_prewarm_seen_v1022={} if @motion_prewarm_seen_v1022==nil
    key=folder+'|'+file
    return if @motion_prewarm_seen_v1022[key]
    @motion_prewarm_seen_v1022[key]=true
    @motion_prewarm_queue_v1022.push([:bitmap,folder,file,sid,action])
  end

  def motion_prewarm_add_route_v1022(species,move_key,data=nil,profile=nil)
    @motion_prewarm_queue_v1022.push([:route,species.to_s,move_key,data,profile])
  end

  def motion_build_prewarm_queue_v1022
    @motion_prewarm_queue_v1022=[]
    @motion_prewarm_seen_v1022={}
    @motion_prewarm_loaded_v1022=0
    @motion_prewarm_failed_v1022=0
    @motion_prewarm_total_ms_v1022=0
    @motion_prewarm_done_v1022=false
    @motion_prewarm_summary_logged_v1022=false
    @motion_prewarm_pending_start_v1022=false

    (@units || []).each do |u|
      next if u==nil
      sid=u.species.to_s rescue ''
      next unless PMD_AC.motion_phase_a_species_v102?(sid)
      actions=[:walk,:idle,:hurt,:attack]
      p=nil
      begin;p=PMD_AC.motion_species_profile_v102(sid);rescue;p=nil;end
      if p!=nil && p[:ambient]!=nil
        p[:ambient].each do |row|
          next if row==nil
          a=row[0]
          actions.push(a) if a!=nil && !actions.include?(a)
        end
      end
      begin
        support=u.motion_support_state_v102
        actions.push(:hover) if (support==:air || support==:float) && !actions.include?(:hover)
      rescue
      end
      begin
        r=PMD_AC.motion_source_route_v102(sid,:basic_attack,nil,nil)
        a=r==nil ? nil : r[:selected]
        actions.push(a) if a!=nil && !actions.include?(a)
      rescue
      end
      begin
        d=u.skill_data
        mk=d==nil ? :skill : (d[:canonical_move_key] || d[:move_key] || :skill)
        pp=nil
        begin;pp=PMD_AC.move_presentation_profile_v055(mk);rescue;pp=nil;end
        r=PMD_AC.motion_source_route_v102(sid,mk,d,pp)
        a=r==nil ? nil : r[:selected]
        actions.push(a) if a!=nil && !actions.include?(a)
      rescue
      end
      actions.each{|a|motion_prewarm_add_bitmap_v1022(sid,a)}
    end

    # Static verifier route samples are cheap metadata tasks. Put them after the
    # live battler bitmaps so real battle smoothness always has priority.
    PMD_AC::MOTION_PREWARM_ROUTE_SAMPLES_V1022.each do |row|
      sid=row[0];mk=row[1]
      d=nil;pp=nil
      begin;d=PMD_AC.skill_data(('mv_'+mk.to_s).to_sym);rescue;d=nil;end
      begin;pp=PMD_AC.move_presentation_profile_v055(mk);rescue;pp=nil;end
      motion_prewarm_add_route_v1022(sid,mk,d,pp)
    end
    @motion_prewarm_total_items_v1022=@motion_prewarm_queue_v1022.size
    @motion_prewarm_done_v1022=true if @motion_prewarm_queue_v1022.empty?
    true
  end

  def motion_prewarm_step_v1022(max_items=nil)
    return if @motion_prewarm_done_v1022
    q=@motion_prewarm_queue_v1022 || []
    lim=max_items==nil ? PMD_AC::MOTION_PREWARM_PER_DEPLOY_FRAME_V1022 : max_items.to_i
    lim=1 if lim<=0
    done=0
    while done<lim && !q.empty?
      row=q.shift
      t=Time.now.to_f
      ok=true
      begin
        if row[0]==:bitmap
          Cache.load_bitmap(row[1],row[2])
          @motion_prewarm_loaded_v1022=@motion_prewarm_loaded_v1022.to_i+1
        elsif row[0]==:route
          PMD_AC.motion_source_route_v102(row[1],row[2],row[3],row[4])
        end
      rescue
        ok=false
        @motion_prewarm_failed_v1022=@motion_prewarm_failed_v1022.to_i+1
      end
      begin
        @motion_prewarm_total_ms_v1022=@motion_prewarm_total_ms_v1022.to_i+
          (((Time.now.to_f-t)*1000.0).round)
      rescue
      end
      done+=1
    end
    @motion_prewarm_queue_v1022=q
    @motion_prewarm_done_v1022=true if q.empty?
    ok
  end

  def motion_enable_log_buffer_v1022
    return false unless verification_mode==:pmd_motion_phase_a_v102
    io=@v1005_battle_log_io
    return false if io==nil || !io.respond_to?(:sync=)
    begin
      @motion_previous_io_sync_v1022=io.sync
    rescue
      @motion_previous_io_sync_v1022=true
    end
    begin
      io.sync=false
      @motion_io_buffered_v1022=true
      return true
    rescue
      @motion_io_buffered_v1022=false
      return false
    end
  end

  def motion_flush_log_v1022(restore=false)
    io=@v1005_battle_log_io
    return false if io==nil
    begin;io.flush;rescue;end
    if restore && io.respond_to?(:sync=)
      begin;io.sync=(@motion_previous_io_sync_v1022==false ? false : true);rescue;end
      @motion_io_buffered_v1022=false
    end
    true
  end

  def motion_log_prewarm_summary_v1022
    return if @motion_prewarm_summary_logged_v1022
    @motion_prewarm_summary_logged_v1022=true
    st=PMD_AC.motion_runtime_cache_status_v1022
    log_event(:perf,'MOTION_PREWARM_V1022 ready='+( @motion_prewarm_done_v1022 ? '1':'0')+
      ' items='+@motion_prewarm_total_items_v1022.to_i.to_s+
      ' loaded='+@motion_prewarm_loaded_v1022.to_i.to_s+
      ' fail='+@motion_prewarm_failed_v1022.to_i.to_s+
      ' total_ms='+@motion_prewarm_total_ms_v1022.to_i.to_s+
      ' cache_bitmap='+st[:bitmap].to_s+' cache_route='+st[:route].to_s)
  end

  def start
    pmd_ac_v1022_start
    motion_build_prewarm_queue_v1022
  end

  def update_deploy_phase
    pmd_ac_v1022_update_deploy_phase
    return unless @phase==:deploy
    motion_prewarm_step_v1022
    if @motion_prewarm_pending_start_v1022 && @motion_prewarm_done_v1022
      @motion_prewarm_pending_start_v1022=false
      @motion_prewarm_force_start_v1022=true
      begin
        start_battle
      ensure
        @motion_prewarm_force_start_v1022=false
      end
    end
  end

  def start_battle
    if !@motion_prewarm_force_start_v1022 && !@motion_prewarm_done_v1022
      @motion_prewarm_pending_start_v1022=true
      return
    end
    motion_enable_log_buffer_v1022
    result=pmd_ac_v1022_start_battle
    motion_log_prewarm_summary_v1022 if @phase==:battle
    result
  end

  def check_battle_end
    old=@phase
    result=pmd_ac_v1022_check_battle_end
    motion_flush_log_v1022(false) if old==:battle && @phase==:result
    result
  end

  def restart_to_deploy
    motion_flush_log_v1022(true)
    result=pmd_ac_v1022_restart_to_deploy
    motion_build_prewarm_queue_v1022 if @phase==:deploy
    result
  end

  def terminate
    motion_flush_log_v1022(true)
    pmd_ac_v1022_terminate
  end

  def verify_motion_runtime_cache_v1022
    return if @verification_done[:motion_runtime_cache_v1022]
    st=PMD_AC.motion_runtime_cache_status_v1022
    pass=@motion_prewarm_done_v1022 && @motion_prewarm_failed_v1022.to_i==0 &&
      st[:bitmap].to_i>0 && st[:route].to_i>0 && @motion_io_buffered_v1022
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_RUNTIME_CACHE_V1022 pass='+(pass ? '1':'0')+
      ' prewarm='+( @motion_prewarm_done_v1022 ? '1':'0')+
      ' fail='+@motion_prewarm_failed_v1022.to_i.to_s+
      ' bitmap_exists_cache='+st[:bitmap].to_s+
      ' native_cache='+st[:native].to_s+
      ' playable_cache='+st[:playable].to_s+
      ' route_cache='+st[:route].to_s+
      ' io_buffer='+( @motion_io_buffered_v1022 ? '1':'0')+
      ' squared_speed=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:motion_runtime_cache_v1022]=true
  end

  def update_verification_script
    pmd_ac_v1022_update_verification_script
    return unless verification_mode==:pmd_motion_phase_a_v102
    verify_motion_runtime_cache_v1022 if @verification_frame.to_i>=30
  end
end
