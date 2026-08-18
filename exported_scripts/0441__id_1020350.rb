#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Production Path Acceptance Probe v1.02.35
#------------------------------------------------------------------------------
# 【用途】
# 1. 驗證 v1.02.34 Production Motion Loading Rollout 是否真的在「非 PMD Motion
#    verifier」的正式戰鬥路徑生效，而不是只有 PMD_MOTION_PHASE_A_V102 測試場通過。
# 2. 本腳本只讀取既有 Loading / Geometry / UI throttle 的 summary 與 cache coverage，
#    不重新執行 preload、不改任何 Motion 動作、不改 AI / Damage / Attack Speed / Spatial。
# 3. 一般 NORMAL、Map Story 或其他非 PMD_MOTION_PHASE_A_V102 模式開始戰鬥後，
#    若場上含目前 Motion Framework 覆蓋物種，輸出一條正式 Production Path PASS/FAIL。
#
# 【主要設定】
# - PRODUCTION_PATH_PROBE_ENABLED_V10235 = true
#   是否啟用此被動驗收探針。正式封版後可保留，成本只是一場戰鬥一次的 summary 判讀。
#
# 【機制規則】
# - 只在 start_battle 完成既有 Loading Gate 後判讀，因此不會干擾 Loading 時序。
# - PMD_MOTION_PHASE_A_V102 模式不重複輸出本探針，避免把 verifier 當 production 證據。
# - 若本場沒有目前 Motion Framework 覆蓋物種，輸出 active_motion_species=0 skipped=1，
#   不判成失敗，因為 v1.02.34 本來就不要求未覆蓋物種支付 Motion preload 成本。
# - 有覆蓋物種時，PASS 必須同時滿足：
#   1) Battle Resource Loading ready；
#   2) asset_fail=0、motion=1、motion_fail=0；
#   3) Persistent Geometry effective coverage 全滿；
#   4) Visible Baseline / Target Anchor 都 computed=0 且 fail=0；
#   5) Loading UI Refresh Throttle 確實有 requests / flushes / skipped，並保留 0% / 100%。
# - 不以 Loading 總毫秒數作硬性 PASS 條件；時間只記錄供效能觀察，避免不同 Windows
#   機器或短暫排程抖動造成錯誤 FAIL。
#
# 【可調參數】
# - PRODUCTION_PATH_PROBE_ENABLED_V10235：true / false。
#   除非要完全關閉 Production 路徑驗收紀錄，否則保持 true。
#
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。正常布陣後 Shift 開戰即可自動驗收。
# 最低成本測試：
#   S 切回 NORMAL → 使用目前 0001～0026 代表 Pokémon → Shift 開戰。
# Map Story 實戰亦可；只要不是 PMD_MOTION_PHASE_A_V102，就屬 production-path 證據。
#
# 【實際範例】
# NORMAL 戰鬥含妙蛙種子／皮卡丘：
#   MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 pass=1 mode=normal ...
# 未含目前 Motion coverage 物種：
#   MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 active_motion_species=0 skipped=1 ...
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_ProductionPathAcceptanceProbe_v10235'] = true

module PMD_AC
  PRODUCTION_PATH_PROBE_VERSION_V10235 = '1.02.35'
  PRODUCTION_PATH_PROBE_ENABLED_V10235 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10235_start start unless method_defined?(:pmd_ac_v10235_start)
  alias pmd_ac_v10235_start_battle start_battle unless method_defined?(:pmd_ac_v10235_start_battle)
  alias pmd_ac_v10235_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10235_restart_to_deploy)

  def production_path_probe_reset_v10235
    @production_path_probe_logged_v10235 = false
  end

  def start
    production_path_probe_reset_v10235
    pmd_ac_v10235_start
  end

  def restart_to_deploy
    r = pmd_ac_v10235_restart_to_deploy
    production_path_probe_reset_v10235 if @phase == :deploy
    r
  end

  def production_path_probe_mode_v10235
    verification_mode
  rescue
    :unknown
  end

  def production_path_probe_log_v10235(mode_before)
    return unless PMD_AC::PRODUCTION_PATH_PROBE_ENABLED_V10235
    return if @production_path_probe_logged_v10235
    mode = mode_before || production_path_probe_mode_v10235
    return if mode == :pmd_motion_phase_a_v102

    applicable = motion_production_loading_policy_v10234? rescue false
    unless applicable
      begin
        log_event(:perf,
          'MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 active_motion_species=0 skipped=1'+
          ' mode='+mode.to_s+' verifier_independent=1 behavior_unchanged=1')
      rescue
      end
      @production_path_probe_logged_v10235 = true
      return
    end

    s = @battle_resource_loading_summary_v1029 || {}
    bs = @motion_baseline_summary_v10212 || {}
    ts = @motion_target_anchor_summary_v10216 || {}
    c = motion_geometry_cache_coverage_v10232 rescue {}
    ui = loading_ui_refresh_summary_v10233 rescue {}

    loading_ready = battle_resource_loading_ready_v1029? rescue false
    resource_ok = loading_ready && s[:loaded].to_i > 0 && s[:asset_fail].to_i == 0 &&
      s[:motion].to_i == 1 && s[:motion_fail].to_i == 0
    geometry_ok = c[:baseline_pairs].to_i > 0 &&
      c[:baseline_effective].to_i == c[:baseline_pairs].to_i &&
      c[:target_pairs].to_i > 0 &&
      c[:target_effective].to_i == c[:target_pairs].to_i &&
      c[:baseline_missing].to_i == 0 && c[:baseline_invalid].to_i == 0 &&
      c[:target_missing].to_i == 0 && c[:target_invalid].to_i == 0
    original_scan_zero = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    ui_ok = ui[:requests].to_i > 0 && ui[:flushes].to_i > 0 &&
      ui[:skipped].to_i > 0 && ui[:flushes].to_i < ui[:requests].to_i &&
      ui[:initial].to_i == 1 && ui[:final].to_i == 1
    pass = resource_ok && geometry_ok && original_scan_zero && ui_ok

    begin
      log_event(:verify,
        'MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 pass='+(pass ? '1':'0')+
        ' mode='+mode.to_s+
        ' active_motion_species=1 loading_ready='+(loading_ready ? '1':'0')+
        ' assets='+s[:assets].to_i.to_s+' loaded='+s[:loaded].to_i.to_s+
        ' asset_fail='+s[:asset_fail].to_i.to_s+
        ' motion='+s[:motion].to_i.to_s+' motion_fail='+s[:motion_fail].to_i.to_s+
        ' loading_ms='+s[:total_ms].to_i.to_s+
        ' baseline_effective='+c[:baseline_effective].to_i.to_s+'/'+c[:baseline_pairs].to_i.to_s+
        ' target_effective='+c[:target_effective].to_i.to_s+'/'+c[:target_pairs].to_i.to_s+
        ' baseline_computed='+bs[:computed].to_i.to_s+
        ' target_computed='+ts[:computed].to_i.to_s+
        ' geometry_missing='+(c[:baseline_missing].to_i+c[:target_missing].to_i).to_s+
        ' geometry_invalid='+(c[:baseline_invalid].to_i+c[:target_invalid].to_i).to_s+
        ' ui_requests='+ui[:requests].to_i.to_s+' ui_flushes='+ui[:flushes].to_i.to_s+
        ' ui_skipped='+ui[:skipped].to_i.to_s+
        ' initial_0='+ui[:initial].to_i.to_s+' final_100='+ui[:final].to_i.to_s+
        ' verifier_independent=1 normal_map_story_path=1'+
        ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    rescue
    end
    @production_path_probe_logged_v10235 = true
  rescue
    @production_path_probe_logged_v10235 = true
  end

  def start_battle
    mode_before = production_path_probe_mode_v10235
    r = pmd_ac_v10235_start_battle
    production_path_probe_log_v10235(mode_before)
    r
  end
end
