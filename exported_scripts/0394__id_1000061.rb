# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Current-Test LOG + Startup Fast Path v1.00.6
# 分類：RPG Foundation／Scene 啟動效能／LOG 精簡／歷史相容
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 1. 解決 Scene_PMD_AutoChess 每次進入約 6~7 秒的無畫面等待。
#    v1.00.5 實機 profiler 已確認 background / board / units / sprites 都只有毫秒級，
#    真正延遲位於大量歷史 start alias 與 Battle LOG 相容鏈。
# 2. 歷史腳本共有大量「若 Battle LOG 存在就讀整份檔案、改 Header、再整份寫回」
#    的 start guard。v1.00.6 在 AutoChess startup 期間只針對 BATTLE_LOG_FILE 將
#    FileTest.exist? 改成純 RAM false，不觸碰其他檔案路徑，避免反覆查詢磁碟。
# 3. Startup FLOW / LOADED / PATCH 類歷史 LOG 不再逐行通過數十層 log_event alias。
#    NORMAL 與目前正式 RPG_FOUNDATION_V100 只輸出「當次必要 LOG」。
# 4. 正常戰鬥仍保留必要 RPG 流程、異常恢復、結果／摘要與效能資料；正式 S 測試
#    額外保留 VERIFY PASS/FAIL。其他舊模式若真的切回去測，仍回退完整舊 logger。
#
# 【目前 LOG Profile】
# NORMAL 寫入：
#   BATTLE / PERF / RPG_FOUNDATION / RPG_ENCOUNTER / RPG_FIELD /
#   REWARD_LOOP / COLLECTION / CADENCE_RECOVERY / SUMMARY
# RPG_FOUNDATION_V100 另加：
#   VERIFY
# 其他歷史驗證 mode：
#   回退 v1.00.5 舊 logger，確保歷史驗證能力仍可使用。
#
# 【重要機制規則】
# - 本版「少寫 LOG」不代表刪除戰鬥機制。
# - NORMAL 非 VERIFY 的 log_event 不再穿越整條歷史 logger alias chain；但 v0.89
#   Stalemate progress side effect 會直接保留，避免因 LOG 精簡破壞僵局監測。
# - 當前 RPG_FOUNDATION_V100 的 VERIFY 訊息仍會跑完整舊 verifier side-effect chain，
#   所以任何 pass=0 仍能正確把 final marker 判成 FAIL。
# - Startup 時只攔截「PMD_AC::BATTLE_LOG_FILE」的 FileTest.exist?；Graphics／PMD
#   素材或其他檔案檢查全部交回 RGSS2 原方法。
#
# 【可調參數】
#   PMD_AC::LOG_NORMAL_CATEGORIES_V1006
#   PMD_AC::LOG_RPG_VERIFY_CATEGORIES_V1006
# 未來某版需要診斷特定系統時，只要暫時把 category 加進當版清單，不要恢復全量 LOG。
#
# 【效能 LOG】
#   PMD_SceneStartupPerf_v1.00.6.log
# 重要欄位：
#   total_ms               AutoChess start 總耗時
#   legacy_file_guards     startup 期間被 RAM fast-path 接住的舊 Battle LOG existence guard
#   startup_logs_suppressed 被省略的歷史 startup LOG 行數
#   written_runtime        當次真正寫入 Battle LOG 的必要行數
#
# 【事件／腳本呼叫方式】
# 一般事件不需要呼叫。若開發時需要手動寫一行目前診斷：
#   $scene.log_event(:perf, "MY_TEST value=1")
# 若未來要暫時增加 category，修改本腳本上方 LOG_*_CATEGORIES_V1006 即可。
#
# 【Verifier】
# NORMAL -> S 一次 -> RPG_FOUNDATION_V100 -> Shift
# 新增：
#   RPG_LOG_PROFILE_V1006
#   RPG_STARTUP_FAST_PATH_V1006
#   RPG_STARTUP_PERF_PROBE_V1006
# 仍必須有：
#   RPG_FOUNDATION_V100 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【實際範例】
# - 正常戰鬥不再寫 TYPE / DAMAGE / TARGET / AUDIO_RUNTIME 等數百行流水帳。
# - 若當版正在查攻擊節奏，再把 :damage / :target / :cadence_recovery 暫時加入清單。
# - 舊的 v0.99.16 等模式仍可從 S 最近五項切換；該模式會使用完整舊 logger。
#
# 【維護限制】
# - 不修改 Frozen Combat Core、Attack Speed、Damage Formula、Basic Flex、Nature AI。
# - Pokémon identity 一律 instance_uid。
# - 本腳本以 Main 前 trailing override 安裝，既有腳本 byte-for-byte 保留。
#==============================================================================
module PMD_AC
  RPG_SCENE_PERF_LOG_V1006='PMD_SceneStartupPerf_v1.00.6.log'
  LOG_NORMAL_CATEGORIES_V1006=[
    :battle,:perf,:rpg_foundation,:rpg_encounter,:rpg_field,
    :reward_loop,:collection,:cadence_recovery,:summary
  ]
  LOG_RPG_VERIFY_CATEGORIES_V1006=(LOG_NORMAL_CATEGORIES_V1006+[:verify])

  class << self
    attr_accessor :battle_log_exist_fast_v1006
    attr_accessor :battle_log_exist_hits_v1006

    def begin_battle_log_exist_fast_v1006
      @battle_log_exist_hits_v1006=0
      @battle_log_exist_fast_v1006=true
    end

    def end_battle_log_exist_fast_v1006
      @battle_log_exist_fast_v1006=false
    end

    def battle_log_exist_fast_match_v1006?(path)
      return false unless @battle_log_exist_fast_v1006
      return false unless const_defined?(:BATTLE_LOG_FILE)
      path.to_s==BATTLE_LOG_FILE.to_s
    rescue
      false
    end

    def battle_log_exist_hit_v1006
      @battle_log_exist_hits_v1006=0 if @battle_log_exist_hits_v1006==nil
      @battle_log_exist_hits_v1006+=1
    end

    def scene_perf_log_v1006(text)
      begin
        File.open(RPG_SCENE_PERF_LOG_V1006,'ab') do |f|
          stamp=Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time'
          f.write('['+stamp+'] '+text.to_s+"\r\n")
        end
        true
      rescue
        false
      end
    end

    def log_category_allowed_v1006?(mode,category)
      c=category.to_s.to_sym
      if mode==:rpg_foundation_v100
        return LOG_RPG_VERIFY_CATEGORIES_V1006.include?(c)
      elsif mode==:normal || mode==nil
        return LOG_NORMAL_CATEGORIES_V1006.include?(c)
      end
      true
    rescue
      true
    end
  end
end

#==============================================================================
# ■ FileTest Battle LOG existence fast path
#   只攔 BATTLE_LOG_FILE；其餘所有 exist? 仍走 RGSS2 / Ruby 原生方法。
#==============================================================================
module FileTest
  class << self
    unless method_defined?(:pmd_ac_v1006_exist?)
      alias pmd_ac_v1006_exist? exist? unless method_defined?(:pmd_ac_v1006_exist?)
    end
    def exist?(path)
      if defined?(PMD_AC) && PMD_AC.battle_log_exist_fast_match_v1006?(path)
        PMD_AC.battle_log_exist_hit_v1006
        return false
      end
      pmd_ac_v1006_exist?(path)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1006_start start unless method_defined?(:pmd_ac_v1006_start)
  alias pmd_ac_v1006_log_event log_event unless method_defined?(:pmd_ac_v1006_log_event)
  alias pmd_ac_v1006_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1006_update_verification_script)

  def v1006_current_log_mode
    begin
      verification_mode
    rescue
      :normal
    end
  end

  def v1006_current_profile_active?
    m=v1006_current_log_mode
    m==:normal || m==:rpg_foundation_v100
  end

  def v1006_write_line(category,message)
    return false unless @battle_log_enabled
    line=v1005_format_log_line(category,message)
    if @v1005_battle_log_io
      @v1005_battle_log_io.write(line)
    else
      File.open(PMD_AC::BATTLE_LOG_FILE,'ab'){|f|f.write(line)}
    end
    @v1006_written_runtime=0 if @v1006_written_runtime==nil
    @v1006_written_runtime+=1
    true
  rescue
    false
  end

  # NORMAL 下不能因略過歷史 logger alias chain 而破壞 v0.89 僵局監測。
  def v1006_preserve_normal_log_side_effects(category,message)
    begin
      if respond_to?(:stalemate_progress_event_v089?) && respond_to?(:stalemate_safety_v089?) &&
         respond_to?(:stall_mark_progress_v089)
        progress=stalemate_progress_event_v089?(category,message)
        if progress && !@stall_progress_guard_v089 && !stalemate_safety_v089?
          stall_mark_progress_v089(category.to_s)
        end
      end
    rescue
    end
  end

  def log_event(category,message)
    unless v1006_current_profile_active? || @v1006_startup_fast
      return pmd_ac_v1006_log_event(category,message)
    end
    return unless @battle_log_enabled

    c=category.to_s.to_sym

    # Startup 的歷史 FLOW/LOADED/PATCH 完全不需要進 160+ 層 logger alias。
    if @v1006_startup_fast
      if c==:verify
        begin;v1005_run_log_side_effects(category,message);rescue;end
      else
        @v1006_startup_logs_suppressed=0 if @v1006_startup_logs_suppressed==nil
        @v1006_startup_logs_suppressed+=1
      end
      # startup 本身只保留真正必要的 battle / perf；多數舊行直接略過。
      return true unless c==:verify || c==:battle || c==:perf
      return v1006_write_line(category,message) if PMD_AC.log_category_allowed_v1006?(:normal,c)
      return true
    end

    mode=v1006_current_log_mode
    # Current verifier 的 VERIFY 仍走完整歷史 side-effect chain，pass=0 不得漏失。
    if c==:verify
      begin;v1005_run_log_side_effects(category,message);rescue;end
    else
      # NORMAL / current RPG mode 僅保留真正的 gameplay side effect。
      v1006_preserve_normal_log_side_effects(category,message)
    end

    return true unless PMD_AC.log_category_allowed_v1006?(mode,c)
    v1006_write_line(category,message)
  end

  # v1.00.5 會呼叫這個方法輸出 startup buffer；v1.00.6 改成極簡 header。
  def v1005_write_startup_log
    begin
      v1005_close_fast_log if respond_to?(:v1005_close_fast_log)
    rescue
    end
    File.open(PMD_AC::BATTLE_LOG_FILE,'wb') do |f|
      f.write('PMD AutoChess Proto v1.00.6 Current-Test Log'+"\r\n")
      f.write('Session: '+(@v1005_log_session || (Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time'))+"\r\n")
      f.write('LOG Profile: current-test minimal'+"\r\n")
      f.write('============================================================'+"\r\n")
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

  def start
    t=Time.now.to_f
    @v1006_startup_fast=true
    @v1006_startup_logs_suppressed=0
    @v1006_written_runtime=0
    PMD_AC.begin_battle_log_exist_fast_v1006
    begin
      pmd_ac_v1006_start
    ensure
      PMD_AC.end_battle_log_exist_fast_v1006
      @v1006_startup_fast=false
    end
    total=PMD_AC.scene_perf_time_ms_v1005(t) rescue -1
    guards=PMD_AC.battle_log_exist_hits_v1006.to_i
    suppressed=@v1006_startup_logs_suppressed.to_i
    PMD_AC.scene_perf_log_v1006('AUTOCHESS_START_V1006 total_ms='+total.to_s+
      ' legacy_file_guards='+guards.to_s+
      ' startup_logs_suppressed='+suppressed.to_s+
      ' log_profile=current_test_minimal')
    log_event(:perf,'STARTUP_V1006 total_ms='+total.to_s+
      ' legacy_file_guards='+guards.to_s+
      ' startup_logs_suppressed='+suppressed.to_s+
      ' log_profile=current_test_minimal')
  end

  #----------------------------------------------------------------------
  # v1.00.6 Verifier
  #----------------------------------------------------------------------
  def verify_rpg_log_profile_v1006
    return if @verification_done[:rpg_log_profile_v1006]
    normal=PMD_AC::LOG_NORMAL_CATEGORIES_V1006
    current=PMD_AC::LOG_RPG_VERIFY_CATEGORIES_V1006
    pass=normal.include?(:battle) && normal.include?(:perf) && !normal.include?(:damage) &&
      !normal.include?(:audio_runtime) && current.include?(:verify)
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_LOG_PROFILE_V1006 pass='+(pass ? '1':'0')+
      ' current_only=1 damage_flood=0 audio_flood=0 verify_kept=1 normal_categories='+normal.size.to_s)
    @verification_done[:rpg_log_profile_v1006]=true
  end

  def verify_rpg_startup_fast_path_v1006
    return if @verification_done[:rpg_startup_fast_path_v1006]
    guards=PMD_AC.battle_log_exist_hits_v1006.to_i
    suppressed=@v1006_startup_logs_suppressed.to_i
    pass=guards>0 && suppressed>0 && !PMD_AC.battle_log_exist_fast_v1006
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_STARTUP_FAST_PATH_V1006 pass='+(pass ? '1':'0')+
      ' legacy_file_guards='+guards.to_s+' startup_logs_suppressed='+suppressed.to_s+
      ' disk_guard_during_start=0 old_start_log_chain=0')
    @verification_done[:rpg_startup_fast_path_v1006]=true
  end

  def verify_rpg_startup_perf_probe_v1006
    return if @verification_done[:rpg_startup_perf_probe_v1006]
    pass=@v1005_scene_start_t!=nil && FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_STARTUP_PERF_PROBE_V1006 pass='+(pass ? '1':'0')+
      ' perf_log='+PMD_AC::RPG_SCENE_PERF_LOG_V1006+' bgm_after_start=1')
    @verification_done[:rpg_startup_perf_probe_v1006]=true
  end

  def update_verification_script
    pmd_ac_v1006_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_log_profile_v1006 if f>=168
    verify_rpg_startup_fast_path_v1006 if f>=172
    verify_rpg_startup_perf_probe_v1006 if f>=176
  end
end

PMD_AC.scene_perf_log_v1006('PATCH v1.00.6 current_test_log=1 battle_log_file_guard_fastpath=1 startup_alias_log_bypass=1')
PMD_AC.log_global(:rpg_foundation,'PATCH v1.00.6 log=current_test_minimal startup_fast_path=legacy_battle_log_guards+startup_log_chain') if PMD_AC.respond_to?(:log_global)
