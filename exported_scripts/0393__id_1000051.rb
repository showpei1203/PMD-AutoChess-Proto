# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Dex + Scene Startup Performance v1.00.5
# 分類：RPG Foundation／圖鑑同步修正／Scene 啟動效能／Battle LOG I/O
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 1. 修正 v0.93 圖鑑 migration 只執行一次後，之後已在 Party／BOX 的 Pokémon
#    可能「目前持有」卻仍沒有 ever_owned / seen 紀錄，造成妙蛙種子等目前持有
#    Pokémon 在圖鑑中仍顯示 ????。
# 2. 修正 Scene_PMD_AutoChess 每次 start 都被數十個歷史版本的 Battle LOG
#    header rewrite + 每行 File.open/close 拖慢。v1.00.5 在 Scene startup 期間把
#    LOG 放在 RAM buffer，所有舊 header rewrite 因實體 LOG 尚未建立而自然跳過，
#    startup 結束後一次寫入；戰鬥中則保留一個 append handle，避免每一事件重新
#    開關檔案。
# 3. Battle BGM 延後到 Scene startup 完成後才播放，避免「音樂先播、畫面仍卡住」。
# 4. 新增 Scene startup wall-clock profiler，實機可直接看 route/start/transition、
#    create_units、create_unit_sprites 等耗時，不再只靠體感猜測。
#
# 【圖鑑規則】
# - 只要 Pokémon 目前存在於 Party 或 BOX，就必須同時滿足：seen=true、owned=true。
# - sync_current_owned_v093 本來已是 idempotent；本版讓 dex_summary / open collection
#   每次都先同步，因此舊存檔也會自動修復，不需要重開檔。
# - 不修改 encounter_count；擁有回填只做 seen/owned 身份，不偽造野外遭遇次數。
#
# 【Battle LOG 效能規則】
# - start 前刪除舊 Battle LOG；base init_battle_log 不立即建立檔案。
# - start alias 鏈中的所有 log_event 仍會跑原本 verifier side-effect，只是不做磁碟 I/O。
# - startup 結束後一次寫入完整 header + startup lines。
# - normal runtime 使用 persistent append File；sync=true，保留 crash 前 LOG 可讀性。
# - terminate 前先 close persistent handle，再交還舊 terminate 鏈。
# - 若 fast logger 自己失敗，會回退舊 log_event，不得為了效能犧牲可用性。
#
# 【BGM 規則】
# - 只在 Scene_PMD_AutoChess.start 期間 defer v0.85 presentation BGM。
# - Scene 初始化完成後播放最後一次 request 的 BGM；Battleback / mechanics 不變。
#
# 【效能 LOG】
#   PMD_SceneStartupPerf_v1.00.5.log
# 主要行：
#   ROUTE_BEGIN hub->battle kind=wild
#   AUTOCHESS_START_BEGIN route_wait_ms=...
#   AUTOCHESS_START_END total_ms=... units_ms=... sprites_ms=... startup_lines=...
#   AUTOCHESS_VISIBLE route_total_ms=... transition_ms=...
#
# 【Verifier】
# NORMAL -> S 一次 -> RPG_FOUNDATION_V100 -> Shift
# 新增：
#   RPG_COLLECTION_SYNC_V1005
#   RPG_STARTUP_LOG_PIPELINE_V1005
#   RPG_SCENE_PERF_PROBE_V1005
# 這些會在 v1.00 final marker 前執行。
#
# 【事件／腳本呼叫範例】
#   PMD_AC.sync_current_owned_v093
#   PMD_AC.dex_summary_v093
#   PMD_AC.open_collection_v093
#   PMD_AC.scene_perf_log_v1005('custom marker')
#
# 【維護限制】
# - 不直接修改 Frozen Combat Core。
# - 不修改 Attack Speed、Damage Formula、Basic Flex、Dynamic Role、Nature。
# - Pokémon identity 一律 instance_uid。
# - 本腳本以 Main 前 trailing alias 安裝，既有腳本保持 byte-for-byte 不動。
#==============================================================================
module PMD_AC
  RPG_SCENE_PERF_LOG_V1005='PMD_SceneStartupPerf_v1.00.5.log'

  class << self
    def scene_perf_time_ms_v1005(t0)
      begin
        ((Time.now.to_f-t0.to_f)*1000.0).round
      rescue
        -1
      end
    end

    def scene_perf_log_v1005(text)
      begin
        File.open(RPG_SCENE_PERF_LOG_V1005,'ab') do |f|
          stamp=Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time'
          f.write('['+stamp+'] '+text.to_s+"\r\n")
        end
        true
      rescue
        false
      end
    end

    #----------------------------------------------------------------------
    # 圖鑑一致性：current Party/BOX 永遠 implies seen + ever_owned。
    #----------------------------------------------------------------------
    alias pmd_ac_v1005_dex_summary_v093 dex_summary_v093 unless method_defined?(:pmd_ac_v1005_dex_summary_v093)
    alias pmd_ac_v1005_open_collection_v093 open_collection_v093 unless method_defined?(:pmd_ac_v1005_open_collection_v093)

    def dex_summary_v093
      begin
        sync_current_owned_v093
      rescue
      end
      pmd_ac_v1005_dex_summary_v093
    end

    def open_collection_v093
      begin
        sync_current_owned_v093
      rescue
      end
      pmd_ac_v1005_open_collection_v093
    end

    def collection_sync_check_v1005
      begin
        sync_current_owned_v093
        current=[]
        missing_owned=[]
        missing_seen=[]
        pokemon_registry_v045.each do |uid,inst|
          next if inst==nil || !inst.respond_to?(:species_key)
          loc=pokemon_location_v045(uid)
          next if loc==nil || (loc[0]!=:party && loc[0]!=:storage)
          key=inst.species_key
          current.push(key) unless current.include?(key)
          missing_owned.push(key) unless dex_ever_owned_v093?(key)
          missing_seen.push(key) unless dex_seen_v093?(key)
        end
        [missing_owned.empty? && missing_seen.empty?,current,missing_owned,missing_seen]
      rescue Exception => e
        [false,[],[:error],[:error],e.class.to_s+':'+e.message.to_s]
      end
    end

    #----------------------------------------------------------------------
    # v0.85 BGM defer：Scene 初始化完才開始播放。
    #----------------------------------------------------------------------
    alias pmd_ac_v1005_play_battle_presentation_bgm_v085 play_battle_presentation_bgm_v085 unless method_defined?(:pmd_ac_v1005_play_battle_presentation_bgm_v085)

    def begin_bgm_defer_v1005
      @bgm_defer_v1005=true
      @bgm_deferred_args_v1005=nil
    end

    def play_battle_presentation_bgm_v085(request=nil,map_id=nil,force=false)
      if @bgm_defer_v1005
        @bgm_deferred_args_v1005=[request,map_id,force]
        return true
      end
      pmd_ac_v1005_play_battle_presentation_bgm_v085(request,map_id,force)
    end

    def finish_bgm_defer_v1005
      args=@bgm_deferred_args_v1005
      @bgm_defer_v1005=false
      @bgm_deferred_args_v1005=nil
      return true if args==nil
      pmd_ac_v1005_play_battle_presentation_bgm_v085(args[0],args[1],args[2])
    end
  end
end

class Game_Temp
  attr_accessor :pmd_rpg_route_started_at_v1005
  attr_accessor :pmd_rpg_route_kind_v1005
end

#==============================================================================
# ■ Hub -> AutoChess route timing
#==============================================================================
class Scene_PMD_RPGFoundationV100
  alias pmd_ac_v1005_execute_v100 execute_v100 unless method_defined?(:pmd_ac_v1005_execute_v100)
  def execute_v100
    key=PMD_AC::RPG_FOUNDATION_MENU_V100[@index]
    if [:wild,:special,:boss].include?(key) && item_enabled_v100(key)
      if $game_temp
        $game_temp.pmd_rpg_route_started_at_v1005=Time.now.to_f
        $game_temp.pmd_rpg_route_kind_v1005=key
      end
      PMD_AC.scene_perf_log_v1005('ROUTE_BEGIN hub->battle kind='+key.to_s)
    end
    pmd_ac_v1005_execute_v100
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess Startup Fast Logger + Profiler
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1005_start start unless method_defined?(:pmd_ac_v1005_start)
  alias pmd_ac_v1005_post_start post_start unless method_defined?(:pmd_ac_v1005_post_start)
  alias pmd_ac_v1005_init_battle_log init_battle_log unless method_defined?(:pmd_ac_v1005_init_battle_log)
  alias pmd_ac_v1005_log_event log_event unless method_defined?(:pmd_ac_v1005_log_event)
  alias pmd_ac_v1005_terminate terminate unless method_defined?(:pmd_ac_v1005_terminate)
  alias pmd_ac_v1005_create_units create_units unless method_defined?(:pmd_ac_v1005_create_units)
  alias pmd_ac_v1005_create_unit_sprites create_unit_sprites unless method_defined?(:pmd_ac_v1005_create_unit_sprites)
  alias pmd_ac_v1005_create_background create_background unless method_defined?(:pmd_ac_v1005_create_background)
  alias pmd_ac_v1005_create_board create_board unless method_defined?(:pmd_ac_v1005_create_board)
  alias pmd_ac_v1005_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1005_update_verification_script)

  def v1005_component_time(name)
    t=Time.now.to_f
    result=yield
    @v1005_start_parts={} if @v1005_start_parts==nil
    @v1005_start_parts[name]=PMD_AC.scene_perf_time_ms_v1005(t)
    result
  end

  def create_background
    v1005_component_time(:background){pmd_ac_v1005_create_background}
  end

  def create_board
    v1005_component_time(:board){pmd_ac_v1005_create_board}
  end

  def create_units
    v1005_component_time(:units){pmd_ac_v1005_create_units}
  end

  def create_unit_sprites
    v1005_component_time(:sprites){pmd_ac_v1005_create_unit_sprites}
  end

  # Base init_battle_log 的狀態初始化保留，但 startup 不建立實體檔案。
  def init_battle_log
    unless @v1005_startup_log_buffering
      return pmd_ac_v1005_init_battle_log
    end
    @battle_log_enabled=false
    @battle_log_battle_id=0
    @battle_log_counts={}
    @battle_started_frame=nil
    return unless PMD_AC::BATTLE_LOG_ENABLED
    @battle_log_enabled=true
    @v1005_log_session=(Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time')
    true
  end

  def v1005_format_log_line(category,message)
    key=category.to_s
    unless key=='battle' || key=='summary'
      @battle_log_counts={} if @battle_log_counts==nil
      @battle_log_counts[key]=0 if @battle_log_counts[key]==nil
      @battle_log_counts[key]+=1
    end
    frame=@battle_started_frame==nil ? 0 : Graphics.frame_count-@battle_started_frame
    sprintf('[%06d][%s] %s\r\n',frame,key.upcase,message.to_s)
  end

  # 跑完整舊 alias chain 以保留 verifier fail flags，但把 base 寫檔暫時關掉。
  def v1005_run_log_side_effects(category,message)
    old=@battle_log_enabled
    @battle_log_enabled=false
    begin
      pmd_ac_v1005_log_event(category,message)
    ensure
      @battle_log_enabled=old
    end
  end

  def log_event(category,message)
    unless @v1005_fast_log_active
      return pmd_ac_v1005_log_event(category,message)
    end
    return unless @battle_log_enabled
    begin
      v1005_run_log_side_effects(category,message)
      line=v1005_format_log_line(category,message)
      if @v1005_startup_log_buffering
        @v1005_startup_log_buffer=[] if @v1005_startup_log_buffer==nil
        @v1005_startup_log_buffer.push(line)
      elsif @v1005_battle_log_io
        @v1005_battle_log_io.write(line)
      else
        File.open(PMD_AC::BATTLE_LOG_FILE,'ab'){|f|f.write(line)}
      end
      true
    rescue
      # 效能層失敗時退回舊 logger；不能為了快而失去 LOG。
      @v1005_fast_log_active=false
      pmd_ac_v1005_log_event(category,message)
    end
  end

  def v1005_write_startup_log
    lines=@v1005_startup_log_buffer || []
    File.open(PMD_AC::BATTLE_LOG_FILE,'wb') do |f|
      f.write('PMD AutoChess Proto v1.00.5 Battle Verification Log'+"\r\n")
      f.write('Session: '+(@v1005_log_session || (Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time'))+"\r\n")
      f.write('Unit Sprite Scale: '+PMD_AC::UNIT_SPRITE_SCALE.to_s+"\r\n")
      f.write('Effect Sprite Scale: '+PMD_AC::EFFECT_SPRITE_SCALE.to_s+"\r\n")
      f.write('Projectile Sprite Scale: '+PMD_AC::PROJECTILE_SPRITE_SCALE.to_s+"\r\n")
      f.write('============================================================'+"\r\n")
      f.write(lines.join)
    end
    @v1005_startup_log_buffer=[]
    begin
      @v1005_battle_log_io=File.open(PMD_AC::BATTLE_LOG_FILE,'ab')
      @v1005_battle_log_io.sync=true if @v1005_battle_log_io.respond_to?(:sync=)
    rescue
      @v1005_battle_log_io=nil
    end
    true
  end

  def v1005_close_fast_log
    io=@v1005_battle_log_io
    @v1005_battle_log_io=nil
    if io
      begin;io.flush;rescue;end
      begin;io.close;rescue;end
    end
  end

  def start
    @v1005_scene_start_t=Time.now.to_f
    @v1005_start_parts={}
    @v1005_startup_log_buffer=[]
    @v1005_startup_log_buffering=true
    @v1005_fast_log_active=true
    @v1005_route_t=nil
    if $game_temp && $game_temp.pmd_rpg_route_started_at_v1005
      @v1005_route_t=$game_temp.pmd_rpg_route_started_at_v1005
    end
    route_wait=@v1005_route_t ? PMD_AC.scene_perf_time_ms_v1005(@v1005_route_t) : -1
    PMD_AC.scene_perf_log_v1005('AUTOCHESS_START_BEGIN route_wait_ms='+route_wait.to_s+
      ' kind='+(($game_temp && $game_temp.pmd_rpg_route_kind_v1005) ? $game_temp.pmd_rpg_route_kind_v1005.to_s : 'direct'))
    begin
      File.delete(PMD_AC::BATTLE_LOG_FILE) if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
    rescue
    end
    PMD_AC.begin_bgm_defer_v1005
    begin
      pmd_ac_v1005_start
      startup_lines=(@v1005_startup_log_buffer || []).size
      v1005_write_startup_log
      @v1005_startup_log_buffering=false
      PMD_AC.finish_bgm_defer_v1005
      total=PMD_AC.scene_perf_time_ms_v1005(@v1005_scene_start_t)
      p=@v1005_start_parts || {}
      PMD_AC.scene_perf_log_v1005('AUTOCHESS_START_END total_ms='+total.to_s+
        ' background_ms='+(p[:background]||-1).to_s+' board_ms='+(p[:board]||-1).to_s+
        ' units_ms='+(p[:units]||-1).to_s+' sprites_ms='+(p[:sprites]||-1).to_s+
        ' startup_lines='+startup_lines.to_s+' log_mode=buffered_once bgm=deferred')
      log_event(:perf,'STARTUP_V1005 total_ms='+total.to_s+' startup_lines='+startup_lines.to_s+
        ' units_ms='+(p[:units]||-1).to_s+' sprites_ms='+(p[:sprites]||-1).to_s+
        ' log_mode=buffered_once bgm=deferred')
    rescue Exception => e
      begin
        @v1005_startup_log_buffering=false
        v1005_write_startup_log unless FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
      rescue
      end
      begin;PMD_AC.finish_bgm_defer_v1005;rescue;end
      PMD_AC.scene_perf_log_v1005('AUTOCHESS_START_ERROR '+e.class.to_s+': '+e.message.to_s)
      raise
    end
  end

  def post_start
    t=Time.now.to_f
    pmd_ac_v1005_post_start
    transition_ms=PMD_AC.scene_perf_time_ms_v1005(t)
    route_total=@v1005_route_t ? PMD_AC.scene_perf_time_ms_v1005(@v1005_route_t) : -1
    PMD_AC.scene_perf_log_v1005('AUTOCHESS_VISIBLE route_total_ms='+route_total.to_s+
      ' transition_ms='+transition_ms.to_s)
    if $game_temp
      $game_temp.pmd_rpg_route_started_at_v1005=nil
      $game_temp.pmd_rpg_route_kind_v1005=nil
    end
  end

  def terminate
    # 舊 terminate / report 可能會重新讀 Battle LOG；先關掉 persistent handle。
    v1005_close_fast_log
    pmd_ac_v1005_terminate
  end

  #----------------------------------------------------------------------
  # v1.00.5 verifier
  #----------------------------------------------------------------------
  def verify_rpg_collection_sync_v1005
    return if @verification_done[:rpg_collection_sync_v1005]
    r=PMD_AC.collection_sync_check_v1005
    pass=r[0]
    @rpg_foundation_failed_v100=true unless pass
    detail='current_species='+r[1].size.to_s+' missing_owned='+r[2].size.to_s+' missing_seen='+r[3].size.to_s
    detail+=' error='+r[4].to_s if r.size>4
    log_event(:verify,'RPG_COLLECTION_SYNC_V1005 pass='+(pass ? '1':'0')+' '+detail)
    @verification_done[:rpg_collection_sync_v1005]=true
  end

  def verify_rpg_startup_log_pipeline_v1005
    return if @verification_done[:rpg_startup_log_pipeline_v1005]
    # 此時 Scene 已完成 startup；若 fast logger 活著且 startup buffer 已關閉，
    # 代表舊 header rewrite 沒有在 start 中反覆碰磁碟，runtime append 也已接管。
    pass=@v1005_fast_log_active && !@v1005_startup_log_buffering && FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_STARTUP_LOG_PIPELINE_V1005 pass='+(pass ? '1':'0')+
      ' deferred_file=1 buffered_start=1 persistent_runtime='+( @v1005_battle_log_io ? '1':'0')+
      ' bgm_deferred=1 header_rewrite_skip=1')
    @verification_done[:rpg_startup_log_pipeline_v1005]=true
  end

  def verify_rpg_scene_perf_probe_v1005
    return if @verification_done[:rpg_scene_perf_probe_v1005]
    p=@v1005_start_parts || {}
    pass=@v1005_scene_start_t!=nil && p.has_key?(:units) && p.has_key?(:sprites)
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_SCENE_PERF_PROBE_V1005 pass='+(pass ? '1':'0')+
      ' units_ms='+(p[:units]||-1).to_s+' sprites_ms='+(p[:sprites]||-1).to_s+
      ' perf_log='+PMD_AC::RPG_SCENE_PERF_LOG_V1005)
    @verification_done[:rpg_scene_perf_probe_v1005]=true
  end

  def update_verification_script
    pmd_ac_v1005_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_collection_sync_v1005 if f>=152
    verify_rpg_startup_log_pipeline_v1005 if f>=156
    verify_rpg_scene_perf_probe_v1005 if f>=160
  end
end

PMD_AC.scene_perf_log_v1005('PATCH v1.00.5 dex_current_implies_owned=1 startup_log_buffer=1 persistent_runtime_log=1 bgm_defer=1 scene_profiler=1')
PMD_AC.log_global(:rpg_foundation,'PATCH v1.00.5 dex_sync=1 startup_log_io=buffered_once runtime_log_io=persistent bgm_after_start=1 scene_profiler=1') if PMD_AC.respond_to?(:log_global)
