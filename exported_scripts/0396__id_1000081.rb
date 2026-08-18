# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：Scene_PMD_AutoChess Startup Cooperative Loader / Cache v1.00.8
# 分類：啟動效能／Loading 協作式刷新／Startup Cache／Verifier
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 保留 v1.00.7「讀取中＋隨機 PMD 寶可夢奔跑」外觀，但完全不使用
#    real-time position catch-up；每次真正 yield 只前進固定一個 Loading step。
# 2. 將歷史 167 層 Scene_PMD_AutoChess#start 中反覆要求的 Header/Footer 重繪，
#    在 startup 期間合併成 dirty request，等必要初始化完成後各正式重繪一次。
# 3. 把只為歷史 startup LOG 組字串而執行的昂貴 registry / checksum / summary
#    診斷延後；正式 verifier 或遊戲之後真的呼叫時仍執行原方法。
# 4. 快取 Loading mascot 的 0001～0026 可播放 PMD 清單，同一個 Game.exe 內
#    第二次進戰鬥直接 cache hit，不必再次逐隻檢查動作與 Bitmap。
# 5. 在安全 phase boundary / dirty checkpoint 間 cooperative yield：只呼叫
#    PMD_AC.loading_tick_v1007(true) → Graphics.update；絕不 Input.update、絕不 Thread。
# 6. 只輸出本版需要的 startup profiler：total、phase timing、cache hit/miss、
#    yield count、最慢 checkpoint top N、PASS/FAIL 摘要；不恢復舊流水帳。
#
# 【核心規則】
# - Frozen Combat Core、Damage Formula、Attack Speed、AI、Dynamic Tactical Role、
#   Spatial Framework、技能 FX 均不改。
# - 任何可能改變遊戲狀態的 startup 初始化照原順序執行，例如 Units、Spatial、
#   Weather、Party/BOX seed、Dex migration 等。本版只 defer「純診斷讀取」。
# - Header/Footer 只有 startup Loading 正在覆蓋畫面時才合併；Scene 完成後所有
#   refresh_header / refresh_footer 呼叫恢復原本即時行為。
# - Loading runner 不依 elapsed time 改變座標，只在實際 Graphics.update 時固定走一步。
#
# 【主要設定】
# - STARTUP_COOP_YIELD_INTERVAL_V1008：兩次非強制 yield 最短間隔，預設 0.055 秒。
# - STARTUP_COOP_TOP_V1008：profiler 只保留最慢 checkpoint 前 6 名。
# - RPG_STARTUP_COOP_LOG_V1008：本版唯一 startup profiler 檔名。
#
# 【事件／腳本呼叫】
# 正常遊戲不需任何呼叫；進入 Scene_PMD_AutoChess 時自動生效。
# 手動查最近一次 startup 摘要：
#   PMD_AC.startup_last_session_v1008
# 手動清 Loading mascot cache（僅開發測試）：
#   PMD_AC.clear_loading_candidate_cache_v1008
#
# 【驗證方式】
# 1. S 切到 RPG_FOUNDATION_V100，Shift 啟動正式 verifier。
# 2. 本版追加 STARTUP_COOPERATIVE_V1008 / STARTUP_CACHE_V1008 /
#    STARTUP_PROFILER_V1008 三個 marker；舊 RPG Foundation 最終 PASS 會等它們完成。
# 3. Windows RGSS2 最終仍以 VERIFY_FINISHED_BATTLE_RESUME pass=1 為 acceptance。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_StartupCooperative_v1008'] = true

module PMD_AC
  RPG_STARTUP_COOP_LOG_V1008 = 'PMD_StartupCooperative_v1.00.8.log'
  STARTUP_COOP_YIELD_INTERVAL_V1008 = 0.055
  STARTUP_COOP_TOP_V1008 = 6

  class << self
    #--------------------------------------------------------------------------
    # Session / profiler：startup 全程只記 RAM，結束後一次 flush，避免 profiler 自己
    # 變成 startup I/O 負擔。
    #--------------------------------------------------------------------------
    def startup_begin_v1008
      now=Time.now.to_f
      h={
        :active=>true,
        :started_at=>now,
        :checkpoint_at=>now,
        :last_yield_at=>now,
        :phases=>{},
        :phase_counts=>{},
        :segments=>[],
        :cache_hits=>0,
        :cache_misses=>0,
        :cache_events=>[],
        :deferred=>{},
        :deferred_total=>0,
        :yield_count=>0,
        :yield_reasons=>{},
        :header_requests=>0,
        :footer_requests=>0,
        :final_header_refresh=>0,
        :final_footer_refresh=>0,
        :total_ms=>-1,
        :ok=>false,
        :error=>nil
      }
      @startup_session_v1008=h
      h
    rescue
      @startup_session_v1008=nil
      nil
    end

    def startup_active_v1008?
      h=@startup_session_v1008
      h!=nil && h[:active] ? true : false
    rescue
      false
    end

    def startup_current_session_v1008
      @startup_session_v1008
    end

    def startup_last_session_v1008
      @startup_last_session_v1008
    end

    def startup_phase_add_v1008(name,ms)
      h=@startup_session_v1008
      return false if h==nil
      key=name.to_sym
      h[:phases][key]=h[:phases][key].to_i+ms.to_i
      h[:phase_counts][key]=h[:phase_counts][key].to_i+1
      true
    rescue
      false
    end

    def startup_note_cache_v1008(key,status)
      h=@startup_session_v1008
      return false if h==nil
      if status==:hit
        h[:cache_hits]=h[:cache_hits].to_i+1
      else
        h[:cache_misses]=h[:cache_misses].to_i+1
      end
      rows=h[:cache_events]
      text=key.to_s+'='+status.to_s
      rows.push(text) unless rows.include?(text)
      true
    rescue
      false
    end

    def startup_note_deferred_v1008(key)
      h=@startup_session_v1008
      return false if h==nil
      k=key.to_sym
      h[:deferred][k]=h[:deferred][k].to_i+1
      h[:deferred_total]=h[:deferred_total].to_i+1
      true
    rescue
      false
    end

    def startup_record_segment_v1008(label)
      h=@startup_session_v1008
      return false if h==nil || !h[:active]
      now=Time.now.to_f
      last=h[:checkpoint_at].to_f
      ms=(((now-last)*1000.0)+0.5).to_i
      h[:segments].push([ms,label.to_s]) if ms>=0
      h[:segments].sort!{|a,b|b[0]<=>a[0]}
      h[:segments]=h[:segments][0,STARTUP_COOP_TOP_V1008]
      h[:checkpoint_at]=now
      true
    rescue
      false
    end

    def startup_yield_v1008(reason,force=false)
      h=@startup_session_v1008
      return false if h==nil || !h[:active]
      return false unless respond_to?(:loading_active_v1007?) && loading_active_v1007?
      now=Time.now.to_f
      last=h[:last_yield_at].to_f
      return false unless force || last<=0.0 || now-last>=STARTUP_COOP_YIELD_INTERVAL_V1008
      ok=loading_tick_v1007(true)
      if ok
        h[:yield_count]=h[:yield_count].to_i+1
        k=reason.to_sym
        h[:yield_reasons][k]=h[:yield_reasons][k].to_i+1
        h[:last_yield_at]=Time.now.to_f
        h[:checkpoint_at]=h[:last_yield_at]
      end
      ok
    rescue
      false
    end

    def startup_checkpoint_v1008(label,force=false)
      startup_record_segment_v1008(label)
      startup_yield_v1008(label,force)
    rescue
      false
    end

    def startup_escape_v1008(text)
      text.to_s.gsub(/\r|\n/,' ')
    rescue
      text.to_s
    end

    def startup_flush_v1008(h)
      return false if h==nil
      lines=[]
      stamp=Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time'
      lines << '['+stamp+'] START v1.00.8 cooperative_loader=1 catchup=0 input_passthrough=0'
      keys=h[:phases].keys
      keys.sort!{|a,b|h[:phases][b].to_i<=>h[:phases][a].to_i}
      keys.each do |k|
        lines << 'PHASE '+k.to_s+' ms='+h[:phases][k].to_i.to_s+
          ' calls='+h[:phase_counts][k].to_i.to_s
      end
      lines << 'CACHE hit='+h[:cache_hits].to_i.to_s+' miss='+h[:cache_misses].to_i.to_s+
        ' events='+(h[:cache_events]||[]).join(',')
      d=(h[:deferred]||{}).keys.sort{|a,b|a.to_s<=>b.to_s}.collect do |k|
        k.to_s+':'+h[:deferred][k].to_i.to_s
      end
      lines << 'LAZY deferred_total='+h[:deferred_total].to_i.to_s+' items='+d.join(',')
      yr=(h[:yield_reasons]||{}).keys.sort{|a,b|a.to_s<=>b.to_s}.collect do |k|
        k.to_s+':'+h[:yield_reasons][k].to_i.to_s
      end
      lines << 'YIELD count='+h[:yield_count].to_i.to_s+' fixed_step=1 reasons='+yr.join(',')
      (h[:segments]||[]).each_with_index do |row,i|
        lines << 'TOP rank='+(i+1).to_s+' ms='+row[0].to_i.to_s+' checkpoint='+row[1].to_s
      end
      lines << 'RENDER header_requests='+h[:header_requests].to_i.to_s+
        ' footer_requests='+h[:footer_requests].to_i.to_s+
        ' final_header='+h[:final_header_refresh].to_i.to_s+
        ' final_footer='+h[:final_footer_refresh].to_i.to_s
      integrity=h[:ok] && h[:final_header_refresh].to_i==1 && h[:final_footer_refresh].to_i==1 &&
        h[:yield_count].to_i>0
      lines << 'SUMMARY total_ms='+h[:total_ms].to_i.to_s+
        ' pass='+(integrity ? '1':'0')+
        ' cache_hit='+h[:cache_hits].to_i.to_s+' cache_miss='+h[:cache_misses].to_i.to_s+
        ' yields='+h[:yield_count].to_i.to_s+' deferred='+h[:deferred_total].to_i.to_s+
        ' catchup=0'+(h[:error] ? ' error='+startup_escape_v1008(h[:error]) : '')
      File.open(RPG_STARTUP_COOP_LOG_V1008,'ab'){|f|f.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def startup_finish_v1008(total_ms,ok,error_text=nil)
      h=@startup_session_v1008
      return nil if h==nil
      h[:active]=false
      h[:total_ms]=total_ms.to_i
      h[:ok]=ok ? true:false
      h[:error]=error_text
      @startup_last_session_v1008=h
      startup_flush_v1008(h)
      @startup_session_v1008=nil
      h
    rescue
      @startup_session_v1008=nil
      nil
    end

    #--------------------------------------------------------------------------
    # Loading mascot cache：只快取靜態 0001～0026 可播放來源，不碰 Pokemon instance。
    #--------------------------------------------------------------------------
    alias pmd_ac_v1008_loading_species_v1007 loading_species_v1007 unless method_defined?(:pmd_ac_v1008_loading_species_v1007)

    def clear_loading_candidate_cache_v1008
      @loading_candidate_cache_v1008=nil
      true
    end

    def loading_candidate_cache_v1008
      rows=@loading_candidate_cache_v1008
      if rows!=nil
        startup_note_cache_v1008(:loading_species,:hit) if startup_active_v1008?
        return rows
      end
      startup_note_cache_v1008(:loading_species,:miss) if startup_active_v1008?
      rows=[]
      for species in LOADING_PMD_POOL_V1007
        r=loading_action_v1007(species)
        ad=r[0]
        if ad && ad[:file]
          folder=PMD_ROOT+species+'/'
          rows.push([species,ad,r[1]]) if bitmap_exists?(folder,ad[:file])
        end
      end
      @loading_candidate_cache_v1008=rows
      rows
    rescue
      @loading_candidate_cache_v1008=[]
      @loading_candidate_cache_v1008
    end

    def loading_species_v1007
      rows=loading_candidate_cache_v1008
      if rows && !rows.empty?
        return rows[rand(rows.size)]
      end
      pmd_ac_v1008_loading_species_v1007
    rescue
      pmd_ac_v1008_loading_species_v1007
    end

    #--------------------------------------------------------------------------
    # v1.00.7 startup gap log 由本版 profiler 取代。Loading 外觀／lifecycle 完整保留。
    #--------------------------------------------------------------------------
    def scene_perf_log_v1007(text)
      true
    end

    #--------------------------------------------------------------------------
    # Startup-only lazy diagnostics。
    # 這些方法在歷史 start 中只拿來組已被 minimal log 丟棄的說明字串；正式 verifier
    # 與 UI 在 startup 結束後呼叫時仍進原方法，因此不改 acceptance / gameplay state。
    #--------------------------------------------------------------------------
    alias pmd_ac_v1008_validate_identity_registry validate_identity_registry unless method_defined?(:pmd_ac_v1008_validate_identity_registry)
    def validate_identity_registry
      if startup_active_v1008?
        startup_note_deferred_v1008(:identity_registry)
        return []
      end
      pmd_ac_v1008_validate_identity_registry
    end

    alias pmd_ac_v1008_presentation_class_counts_v055 presentation_class_counts_v055 unless method_defined?(:pmd_ac_v1008_presentation_class_counts_v055)
    def presentation_class_counts_v055
      if startup_active_v1008?
        startup_note_deferred_v1008(:presentation_class_counts)
        return {:contact_return=>0,:stationary_cast=>0,:dash_return=>0,:charge_dash=>0,
          :blink_return=>0,:multi_contact=>0,:spin_contact=>0}
      end
      pmd_ac_v1008_presentation_class_counts_v055
    end

    alias pmd_ac_v1008_beam_move_keys_v0572 beam_move_keys_v0572 unless method_defined?(:pmd_ac_v1008_beam_move_keys_v0572)
    def beam_move_keys_v0572
      if startup_active_v1008?
        startup_note_deferred_v1008(:beam_move_keys)
        return []
      end
      pmd_ac_v1008_beam_move_keys_v0572
    end

    alias pmd_ac_v1008_soak_checksum32_v073 soak_checksum32_v073 unless method_defined?(:pmd_ac_v1008_soak_checksum32_v073)
    def soak_checksum32_v073
      if startup_active_v1008?
        startup_note_deferred_v1008(:soak_checksum)
        return 0
      end
      pmd_ac_v1008_soak_checksum32_v073
    end

    alias pmd_ac_v1008_stats_growth_checksum32_v076 stats_growth_checksum32_v076 unless method_defined?(:pmd_ac_v1008_stats_growth_checksum32_v076)
    def stats_growth_checksum32_v076
      if startup_active_v1008?
        startup_note_deferred_v1008(:stats_growth_checksum)
        return 0
      end
      pmd_ac_v1008_stats_growth_checksum32_v076
    end

    alias pmd_ac_v1008_progression_flow_counts_v077 progression_flow_counts_v077 unless method_defined?(:pmd_ac_v1008_progression_flow_counts_v077)
    def progression_flow_counts_v077
      if startup_active_v1008?
        startup_note_deferred_v1008(:progression_flow_counts)
        return {:species=>0,:rules=>0,:branch_species=>0,:additional=>0}
      end
      pmd_ac_v1008_progression_flow_counts_v077
    end

    alias pmd_ac_v1008_progression_flow_checksum32_v077 progression_flow_checksum32_v077 unless method_defined?(:pmd_ac_v1008_progression_flow_checksum32_v077)
    def progression_flow_checksum32_v077
      if startup_active_v1008?
        startup_note_deferred_v1008(:progression_flow_checksum)
        return 0
      end
      pmd_ac_v1008_progression_flow_checksum32_v077
    end

    alias pmd_ac_v1008_dex_summary_v093 dex_summary_v093 unless method_defined?(:pmd_ac_v1008_dex_summary_v093)
    def dex_summary_v093
      if startup_active_v1008?
        # v1.00.5 的 current Party/BOX -> seen/owned 同步是資料一致性副作用，必須保留；
        # 只略過後面 494 species summary 掃描。
        begin;sync_current_owned_v093;rescue;end
        startup_note_deferred_v1008(:dex_summary_scan)
        total=(defined?(SPECIES_DB_V016) && SPECIES_DB_V016) ? SPECIES_DB_V016.size : 494
        return {:total=>total,:seen=>0,:owned=>0,:current=>0,:elite=>0}
      end
      pmd_ac_v1008_dex_summary_v093
    end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess startup cooperative boundary
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1008_start start unless method_defined?(:pmd_ac_v1008_start)
  alias pmd_ac_v1008_refresh_header refresh_header unless method_defined?(:pmd_ac_v1008_refresh_header)
  alias pmd_ac_v1008_refresh_footer refresh_footer unless method_defined?(:pmd_ac_v1008_refresh_footer)
  alias pmd_ac_v1008_create_viewport create_viewport unless method_defined?(:pmd_ac_v1008_create_viewport)
  alias pmd_ac_v1008_create_background create_background unless method_defined?(:pmd_ac_v1008_create_background)
  alias pmd_ac_v1008_create_board create_board unless method_defined?(:pmd_ac_v1008_create_board)
  alias pmd_ac_v1008_create_header create_header unless method_defined?(:pmd_ac_v1008_create_header)
  alias pmd_ac_v1008_create_footer create_footer unless method_defined?(:pmd_ac_v1008_create_footer)
  alias pmd_ac_v1008_create_units create_units unless method_defined?(:pmd_ac_v1008_create_units)
  alias pmd_ac_v1008_create_unit_sprites create_unit_sprites unless method_defined?(:pmd_ac_v1008_create_unit_sprites)
  alias pmd_ac_v1008_create_deploy_cursor create_deploy_cursor unless method_defined?(:pmd_ac_v1008_create_deploy_cursor)
  alias pmd_ac_v1008_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1008_update_verification_script)
  alias pmd_ac_v1008_verify_rpg_final_v100 verify_rpg_final_v100 unless method_defined?(:pmd_ac_v1008_verify_rpg_final_v100)
  alias pmd_ac_v1008_v1007_probe_step v1007_probe_step unless method_defined?(:pmd_ac_v1008_v1007_probe_step)

  def v1008_startup_active?
    @v1008_render_coalesce ? true:false
  end

  # v1.00.7 的 gap top-N profiler 已由 v1.00.8 phase/checkpoint profiler 取代；
  # 保留 log_event 邊界的 Loading tick，但不再每次建立 marker / sort gap array。
  def v1007_probe_step(category,message)
    return unless @v1007_loading_probe_active
    PMD_AC.loading_tick_v1007
  rescue
  end

  def v1008_timed_phase(name)
    t=Time.now.to_f
    result=yield
    ms=PMD_AC.perf_time_ms_v1007(t)
    PMD_AC.startup_phase_add_v1008(name,ms)
    PMD_AC.startup_checkpoint_v1008(name,true)
    result
  end

  def create_viewport
    return pmd_ac_v1008_create_viewport unless v1008_startup_active?
    v1008_timed_phase(:create_viewport){pmd_ac_v1008_create_viewport}
  end

  def create_background
    return pmd_ac_v1008_create_background unless v1008_startup_active?
    v1008_timed_phase(:create_background){pmd_ac_v1008_create_background}
  end

  def create_board
    return pmd_ac_v1008_create_board unless v1008_startup_active?
    v1008_timed_phase(:create_board){pmd_ac_v1008_create_board}
  end

  def create_header
    return pmd_ac_v1008_create_header unless v1008_startup_active?
    v1008_timed_phase(:create_header){pmd_ac_v1008_create_header}
  end

  def create_footer
    return pmd_ac_v1008_create_footer unless v1008_startup_active?
    v1008_timed_phase(:create_footer){pmd_ac_v1008_create_footer}
  end

  def create_units
    return pmd_ac_v1008_create_units unless v1008_startup_active?
    v1008_timed_phase(:create_units){pmd_ac_v1008_create_units}
  end

  def create_unit_sprites
    return pmd_ac_v1008_create_unit_sprites unless v1008_startup_active?
    v1008_timed_phase(:create_unit_sprites){pmd_ac_v1008_create_unit_sprites}
  end

  def create_deploy_cursor
    return pmd_ac_v1008_create_deploy_cursor unless v1008_startup_active?
    v1008_timed_phase(:create_deploy_cursor){pmd_ac_v1008_create_deploy_cursor}
  end

  # startup Loading 覆蓋期間只記 dirty，不跑歷史 refresh alias chain。
  def refresh_header
    if v1008_startup_active?
      @v1008_header_requests=@v1008_header_requests.to_i+1
      h=PMD_AC.startup_current_session_v1008
      h[:header_requests]=@v1008_header_requests if h
      PMD_AC.startup_checkpoint_v1008('header_'+@v1008_header_requests.to_s,false)
      return
    end
    pmd_ac_v1008_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    begin
      bmp.draw_text(16,1,Graphics.width-32,28,'PMD AutoChess v1.00.8｜Startup Cooperative Loader',1)
    rescue
    end
  end

  def refresh_footer
    if v1008_startup_active?
      @v1008_footer_requests=@v1008_footer_requests.to_i+1
      h=PMD_AC.startup_current_session_v1008
      h[:footer_requests]=@v1008_footer_requests if h
      PMD_AC.startup_checkpoint_v1008('footer_'+@v1008_footer_requests.to_s,false)
      return
    end
    pmd_ac_v1008_refresh_footer
  end

  def start
    t0=Time.now.to_f
    @v1008_header_requests=0
    @v1008_footer_requests=0
    @v1008_render_coalesce=true
    PMD_AC.startup_begin_v1008
    ok=false
    err=nil
    begin
      t=Time.now.to_f
      pmd_ac_v1008_start
      PMD_AC.startup_phase_add_v1008(:legacy_start_chain,PMD_AC.perf_time_ms_v1007(t))
      PMD_AC.startup_checkpoint_v1008(:legacy_start_complete,true)

      # 只有這裡解除 coalesce；之後正式 UI 與 gameplay refresh 都照原行為。
      @v1008_render_coalesce=false
      t=Time.now.to_f
      refresh_header
      h=PMD_AC.startup_current_session_v1008
      h[:final_header_refresh]=1 if h
      refresh_footer
      h[:final_footer_refresh]=1 if h
      PMD_AC.startup_phase_add_v1008(:final_render,PMD_AC.perf_time_ms_v1007(t))
      ok=true
    rescue Exception=>e
      err=e.class.to_s+': '+e.message.to_s
      raise
    ensure
      @v1008_render_coalesce=false
      total=PMD_AC.perf_time_ms_v1007(t0)
      PMD_AC.startup_finish_v1008(total,ok,err)
    end
  end

  #--------------------------------------------------------------------------
  # v1.00.8 formal verifier：沿用 RPG_FOUNDATION_V100，不新增第六個 S 正式模式。
  #--------------------------------------------------------------------------
  def verify_rpg_startup_cooperative_v1008
    return if @verification_done[:rpg_startup_cooperative_v1008]
    h=PMD_AC.startup_last_session_v1008 || {}
    pass=h[:ok] && h[:header_requests].to_i>1 && h[:footer_requests].to_i>0 &&
      h[:final_header_refresh].to_i==1 && h[:final_footer_refresh].to_i==1 &&
      h[:yield_count].to_i>0
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'STARTUP_COOPERATIVE_V1008 pass='+(pass ? '1':'0')+
      ' header_requests='+h[:header_requests].to_i.to_s+
      ' footer_requests='+h[:footer_requests].to_i.to_s+
      ' final_header='+h[:final_header_refresh].to_i.to_s+
      ' final_footer='+h[:final_footer_refresh].to_i.to_s+
      ' yields='+h[:yield_count].to_i.to_s+' catchup=0 input_passthrough=0')
    @verification_done[:rpg_startup_cooperative_v1008]=true
  end

  def verify_rpg_startup_cache_v1008
    return if @verification_done[:rpg_startup_cache_v1008]
    h=PMD_AC.startup_last_session_v1008 || {}
    rows=PMD_AC.loading_candidate_cache_v1008 rescue []
    pass=rows!=nil && !rows.empty? && h[:cache_misses].to_i+h[:cache_hits].to_i>=1 &&
      h[:deferred_total].to_i>=5
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'STARTUP_CACHE_V1008 pass='+(pass ? '1':'0')+
      ' mascot_candidates='+(rows==nil ? 0:rows.size).to_s+
      ' startup_hit='+h[:cache_hits].to_i.to_s+' startup_miss='+h[:cache_misses].to_i.to_s+
      ' lazy_deferred='+h[:deferred_total].to_i.to_s+' instance_uid_untouched=1')
    @verification_done[:rpg_startup_cache_v1008]=true
  end

  def verify_rpg_startup_profiler_v1008
    return if @verification_done[:rpg_startup_profiler_v1008]
    h=PMD_AC.startup_last_session_v1008 || {}
    file_ok=FileTest.exist?(PMD_AC::RPG_STARTUP_COOP_LOG_V1008) rescue false
    phase_ok=h[:phases]!=nil && h[:phases][:legacy_start_chain]!=nil && h[:phases][:final_render]!=nil
    pass=file_ok && phase_ok && h[:total_ms].to_i>=0
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'STARTUP_PROFILER_V1008 pass='+(pass ? '1':'0')+
      ' total_ms='+h[:total_ms].to_i.to_s+' phases='+(h[:phases]||{}).size.to_s+
      ' minimal_log=1 legacy_perf_suppressed=1')
    @verification_done[:rpg_startup_profiler_v1008]=true
  end

  # 舊 RPG Foundation final 不准搶在本版三個 startup verifier 前先 PASS。
  def verify_rpg_final_v100
    if verification_mode==:rpg_foundation_v100
      return unless @verification_done[:rpg_startup_cooperative_v1008] &&
        @verification_done[:rpg_startup_cache_v1008] &&
        @verification_done[:rpg_startup_profiler_v1008]
    end
    pmd_ac_v1008_verify_rpg_final_v100
  end

  def update_verification_script
    pmd_ac_v1008_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_startup_cooperative_v1008 if f>=181
    verify_rpg_startup_cache_v1008 if f>=182
    verify_rpg_startup_profiler_v1008 if f>=183
  end
end

# 本次執行只保留 v1.00.8 startup profiler；舊 v1.00.7 profiler 不再當正式輸出。
begin
  File.delete(PMD_AC::RPG_SCENE_PERF_LOG_V1007) if FileTest.exist?(PMD_AC::RPG_SCENE_PERF_LOG_V1007)
  File.delete(PMD_AC::RPG_STARTUP_COOP_LOG_V1008) if FileTest.exist?(PMD_AC::RPG_STARTUP_COOP_LOG_V1008)
rescue
end
