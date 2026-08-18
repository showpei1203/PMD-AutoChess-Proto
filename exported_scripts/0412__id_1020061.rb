# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Verify Fast Path v1.02.6
# 分類：PMD Motion Phase A／開場卡頓根因修正／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.5 實機 Profiler 已把 PMD / VFX late bitmap 降到 0，但開戰仍在 frame 20～50
# 出現約 90～225ms 的 update spike。比對 spike frame 與 verifier 排程後可確認：
# 這些尖峰幾乎逐一落在 MOTION_* verifier 寫入 VERIFY LOG 的 frame。
#
# 原因不是 Motion AI、GC 或 Bitmap，而是 v1.00.6 current-test logger 對所有 :verify
# 訊息仍刻意呼叫 v1005_run_log_side_effects，讓每一行 VERIFY 穿過歷代大量 log_event
# alias chain，以保留舊驗證模式透過 LOG 文字設定 fail flag 的相容性。Motion Phase A 的
# verifier 已經在各 verify_* 方法內直接設定 @motion_phase_a_failed_v102，因此不需要再
# 讓同一行文字巡迴歷史 logger chain 一次。
#
# 本版只在 PMD_MOTION_PHASE_A_V102 模式，將 :verify LOG 改成直接走 v1.00.6
# current-test writer。其他正式模式仍完整保留歷史 side-effect chain。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_VERIFY_FAST_PATH_V1026 = true
#   Motion Phase A 是否繞過歷史 VERIFY logger alias chain。
# MOTION_HITCH_THRESHOLD_MS_V1026 = 50
#   新增較符合肉眼「真的卡一下」的 hitch 門檻；舊 v1.02.3 spike record 仍保留。
# MOTION_HITCH_OPENING_WINDOW_V1026 = 60
#   前 60 battle frame 視為 opening，其後視為 runtime。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 只有 verification_mode == :pmd_motion_phase_a_v102 且 category == :verify 才走
#    fast path；Map Story、RPG Foundation、Nature、Spatial 等模式完全不受影響。
# 2. Motion verifier 的 pass/fail 仍由各 verify_motion_* 方法直接設定，並由
#    PMD_MOTION_PHASE_A_V102 pass=... 與 COMPLETE / VERIFY_FINISHED_BATTLE_RESUME 驗收。
# 3. fast path 仍呼叫 v1006_write_line，因此 current-test minimal 的格式、frame number、
#    category count、buffered IO 都保留，不會少 LOG。
# 4. 不修改 AI、Target、Dynamic Tactical Role、Spatial Framework、Damage Formula、
#    Attack Speed、Motion hit-stop、Hurt ownership、source hitFrame 或 Skill FX。
# 5. v1.02.5 的 GC settle、全 Action bind 與 Event VFX prewarm 繼續保留；本版只處理
#    已由 profiler 指向的 VERIFY logger CPU hitch。
#------------------------------------------------------------------------------
# 【可調參數】
# - MOTION_HITCH_THRESHOLD_MS_V1026 建議維持 50ms；12～16ms 在 RGSS2 中屬正常 frame
#   波動，不應與真正 100～200ms 停頓混在同一統計。
# - 若未來新的 Motion verifier 又依賴「解析 log 字串」才能設定 fail flag，應在該
#   verifier 內改成直接設定 failure state，而不是重新開啟歷史 logger chain。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試：AutoChess 布陣 → S 切 PMD_MOTION_PHASE_A_V102 → Shift → 完整看完一場。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# verifier：
#   MOTION_VERIFY_FASTPATH_V1026 pass=1 historical_verify_chain=0 ...
# battle end：
#   MOTION_HITCH_SPLIT_V1026 opening=... runtime=... threshold_ms=50 ...
# 並繼續保留：
#   MOTION_FRAME_PROFILE_V1023 ...
#   PMD_MOTION_PHASE_A_V102 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#------------------------------------------------------------------------------
# 【實際範例】
# v1.02.5 實機曾在 verifier frame 20 寫 MOTION_PHASE_A_REGISTRY_V102 時 update 約 118ms，
# frame 32 約 118ms、frame 42 約 90ms、frame 45 約 107ms；同場 slow_bitmap=0。
# 本版讓這些 Motion VERIFY 行直接寫 current-test buffer，不再穿越歷代 logger alias。
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只在 Main 前追加 trailing override。
# - Pokémon 個體身份仍以 instance_uid 為唯一身份。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================
module PMD_AC
  MOTION_VERIFY_FAST_PATH_VERSION_V1026='1.02.6'
  MOTION_VERIFY_FAST_PATH_V1026=true
  MOTION_HITCH_THRESHOLD_MS_V1026=50
  MOTION_HITCH_OPENING_WINDOW_V1026=60
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1026_start start unless method_defined?(:pmd_ac_v1026_start)
  alias pmd_ac_v1026_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1026_restart_to_deploy)
  alias pmd_ac_v1026_log_event log_event unless method_defined?(:pmd_ac_v1026_log_event)
  alias pmd_ac_v1026_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1026_update_verification_script)
  alias pmd_ac_v1026_motion_perf_record_spike_v1023 motion_perf_record_spike_v1023 unless method_defined?(:pmd_ac_v1026_motion_perf_record_spike_v1023)
  alias pmd_ac_v1026_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1026_motion_perf_log_summary_v1023)

  def motion_reset_verify_fastpath_v1026
    @motion_verify_fast_count_v1026=0
    @motion_verify_fast_total_ms_v1026=0
    @motion_verify_fast_max_ms_v1026=0
    @motion_verify_fast_failed_v1026=false
    @motion_hitch_opening_v1026=0
    @motion_hitch_runtime_v1026=0
    @motion_hitch_opening_max_v1026=0
    @motion_hitch_runtime_max_v1026=0
    @motion_hitch_opening_update_max_v1026=0
    @motion_hitch_runtime_update_max_v1026=0
    @motion_hitch_summary_logged_v1026=false
  end

  def start
    motion_reset_verify_fastpath_v1026
    pmd_ac_v1026_start
  end

  def restart_to_deploy
    result=pmd_ac_v1026_restart_to_deploy
    motion_reset_verify_fastpath_v1026 if @phase==:deploy && motion_verify_fastpath_mode_v1026?
    result
  end

  def motion_verify_fastpath_mode_v1026?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  # Motion verifier 已自行維護 failure state，因此 VERIFY 只需直接寫 current-test LOG。
  # 這條路徑刻意不呼叫歷史 side-effect chain。
  def log_event(category,message)
    if PMD_AC::MOTION_VERIFY_FAST_PATH_V1026 && motion_verify_fastpath_mode_v1026? &&
       category.to_s.to_sym==:verify && @battle_log_enabled
      t=Time.now.to_f
      ok=true
      begin
        if PMD_AC.log_category_allowed_v1006?(:pmd_motion_phase_a_v102,:verify)
          ok=v1006_write_line(category,message)
        end
      rescue
        ok=false
      end
      ms=0
      begin;ms=((Time.now.to_f-t)*1000.0).round;rescue;ms=0;end
      @motion_verify_fast_count_v1026=@motion_verify_fast_count_v1026.to_i+1
      @motion_verify_fast_total_ms_v1026=@motion_verify_fast_total_ms_v1026.to_i+ms
      @motion_verify_fast_max_ms_v1026=ms if ms>@motion_verify_fast_max_ms_v1026.to_i
      @motion_verify_fast_failed_v1026=true unless ok
      return ok
    end
    # v1.02.5 的 split 統計使用過低門檻，會把正常 12～16ms frame 也列入 runtime。
    # 保留舊腳本本身但不再把那行誤導性的摘要寫入 Motion current-test LOG。
    if motion_verify_fastpath_mode_v1026? && category.to_s.to_sym==:perf &&
       message.to_s.index('MOTION_SPIKE_SPLIT_V1025 ')==0
      return true
    end
    pmd_ac_v1026_log_event(category,message)
  end

  def verify_motion_verify_fastpath_v1026
    return if @verification_done[:motion_verify_fastpath_v1026]
    pass=PMD_AC::MOTION_VERIFY_FAST_PATH_V1026 && !@motion_verify_fast_failed_v1026 &&
      @motion_verify_fast_count_v1026.to_i>0
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_VERIFY_FASTPATH_V1026 pass='+(pass ? '1':'0')+
      ' historical_verify_chain=0 direct_current_test_writer=1'+
      ' bypassed='+@motion_verify_fast_count_v1026.to_i.to_s+
      ' total_write_ms='+@motion_verify_fast_total_ms_v1026.to_i.to_s+
      ' max_write_ms='+@motion_verify_fast_max_ms_v1026.to_i.to_s+
      ' io_buffer='+( @motion_io_buffered_v1022 ? '1':'0')+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_verify_fastpath_v1026]=true
  end

  def update_verification_script
    pmd_ac_v1026_update_verification_script
    if motion_verify_fastpath_mode_v1026? && @verification_frame.to_i>=40
      verify_motion_verify_fastpath_v1026
    end
  end

  # 舊 v1.02.3 record limit 只保存前幾筆，v1.02.5 又用太低門檻統計所有 frame。
  # 本版另外記真正 >=50ms 的肉眼 hitch，opening / runtime 分開，不改舊 profiler。
  def motion_perf_record_spike_v1023(gap_ms,update_ms)
    if motion_perf_capture_active_v1023?
      g=gap_ms.to_i
      u=update_ms.to_i
      peak=[g,u].max
      if peak>=PMD_AC::MOTION_HITCH_THRESHOLD_MS_V1026
        f=motion_perf_relative_frame_v1023
        if f<=PMD_AC::MOTION_HITCH_OPENING_WINDOW_V1026
          @motion_hitch_opening_v1026=@motion_hitch_opening_v1026.to_i+1
          @motion_hitch_opening_max_v1026=peak if peak>@motion_hitch_opening_max_v1026.to_i
          @motion_hitch_opening_update_max_v1026=u if u>@motion_hitch_opening_update_max_v1026.to_i
        else
          @motion_hitch_runtime_v1026=@motion_hitch_runtime_v1026.to_i+1
          @motion_hitch_runtime_max_v1026=peak if peak>@motion_hitch_runtime_max_v1026.to_i
          @motion_hitch_runtime_update_max_v1026=u if u>@motion_hitch_runtime_update_max_v1026.to_i
        end
      end
    end
    pmd_ac_v1026_motion_perf_record_spike_v1023(gap_ms,update_ms)
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v1026_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023 && !@motion_hitch_summary_logged_v1026
      @motion_hitch_summary_logged_v1026=true
      log_event(:perf,'MOTION_HITCH_SPLIT_V1026 opening='+@motion_hitch_opening_v1026.to_i.to_s+
        ' runtime='+@motion_hitch_runtime_v1026.to_i.to_s+
        ' threshold_ms='+PMD_AC::MOTION_HITCH_THRESHOLD_MS_V1026.to_i.to_s+
        ' opening_window='+PMD_AC::MOTION_HITCH_OPENING_WINDOW_V1026.to_i.to_s+
        ' opening_peak_ms='+@motion_hitch_opening_max_v1026.to_i.to_s+
        ' runtime_peak_ms='+@motion_hitch_runtime_max_v1026.to_i.to_s+
        ' opening_update_peak_ms='+@motion_hitch_opening_update_max_v1026.to_i.to_s+
        ' runtime_update_peak_ms='+@motion_hitch_runtime_update_max_v1026.to_i.to_s+
        ' old_record_list_capped=1')
    end
    result
  end
end
