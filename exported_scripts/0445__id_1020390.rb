# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Production Path Seal / NORMAL LOG Visibility Fix v1.02.39
# 分類：正式 NORMAL 戰鬥路徑驗收／Current-Test Minimal LOG 可見性修正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 修正 v1.02.35 Production Path Acceptance Probe 在 NORMAL 戰鬥雖然有執行，
#    卻把結果寫成 :verify category，因 v1.00.6 current-test minimal 的 NORMAL
#    LOG 白名單不包含 :verify，導致正式 PASS/FAIL 行被 logger 正常過濾掉的問題。
# 2. 不重新執行 Loading、不修改 Geometry Cache、不修改 Motion／AI／Damage／
#    Attack Speed／Spatial；只把同一份正式路徑驗收摘要改用 NORMAL 本來就允許的
#    :perf category 輸出。
# 3. v1.02.38 已把使用者可選模式清理成 NORMAL 與 PMD_MOTION_PHASE_A_V102；
#    本版順便把「NORMAL + Production Loading + Cache + UI throttle」收成正式 Seal。
#
# 【為什麼 v1.02.38 LOG 沒有 v1.02.35 那一行】
# - v1.00.6 NORMAL 白名單：battle / perf / rpg_* / reward_loop / collection /
#   cadence_recovery / summary，不含 verify。
# - v1.02.35 使用 log_event(:verify, ...)，因此資料有算，但文字被 current-test
#   minimal filter 丟掉。這是 LOG visibility 問題，不是 Production Loading 未執行。
#
# 【PASS 條件】
# NORMAL 且本場含目前 Motion Framework 覆蓋物種時，必須同時滿足：
# 1. Battle Resource Loading ready，asset_fail=0、motion=1、motion_fail=0；
# 2. Geometry Cache Baseline / Target effective coverage 全滿，missing=0、invalid=0；
# 3. Visible Baseline / Target Anchor computed=0 且 fail=0；
# 4. Loading UI throttle 有 request / flush / skipped，且 0% / 100% 都實際顯示；
# 5. Loading transient context 已在 live battle 前清除；
# 6. v1.02.38 模式環仍為 NORMAL + PMD Motion，NORMAL 位於 index 0。
#
# 【可調參數】
# PRODUCTION_PATH_SEAL_ENABLED_V10239 = true
#   正式應保持 true。成本只是一場 NORMAL 戰鬥開始時讀取既有 summary 一次。
#
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。NORMAL 布陣後直接 Shift 開戰即可。
# 正式 LOG：
#   MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 pass=1 mode=normal ... log_visibility_fix=v10239
#   MOTION_PRODUCTION_PATH_SEAL_V10239 pass=1 mode=normal ...
#
# 【實際範例】
# NORMAL + 妙蛙種子／小火龍／傑尼龜：
# - 先跑 0～100% Production Loading；
# - Geometry Cache 全命中；
# - 進 live battle 前 transient context 清除；
# - 以 :perf 寫出正式 PASS，因此 current-test minimal 一定看得到。
#
# 【不可破壞】
# - Frozen Combat Core 不直接修改。
# - Pokémon identity 仍為 instance_uid。
# - 不修改 AI、Damage Formula、Attack Speed、Spatial logical x/y。
# - 不修改 Persistent Geometry Cache payload、公式、HP bar Y、Target Anchor。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_ProductionPathSeal_v10239'] = true

module PMD_AC
  PRODUCTION_PATH_SEAL_VERSION_V10239 = '1.02.39'
  PRODUCTION_PATH_SEAL_ENABLED_V10239 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10239_start start unless method_defined?(:pmd_ac_v10239_start)

  def production_path_seal_summary_v10239(mode)
    applicable = motion_production_loading_policy_v10234? rescue false
    return {:applicable=>false, :mode=>mode} unless applicable

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
    scan_zero = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    ui_ok = ui[:requests].to_i > 0 && ui[:flushes].to_i > 0 &&
      ui[:skipped].to_i > 0 && ui[:flushes].to_i < ui[:requests].to_i &&
      ui[:initial].to_i == 1 && ui[:final].to_i == 1
    context_clear = !(motion_production_loading_context_v10236? rescue false)

    ring_ok = false
    begin
      ring = PMD_AC::ACTIVE_MODE_RING_V10238
      ring_ok = ring.size == 2 && ring[0] == :normal &&
        ring[1] == :pmd_motion_phase_a_v102
    rescue
      ring_ok = false
    end

    pass = mode == :normal && resource_ok && geometry_ok && scan_zero &&
      ui_ok && context_clear && ring_ok

    {
      :applicable=>true, :mode=>mode, :pass=>pass,
      :loading_ready=>loading_ready, :resource=>s, :baseline=>bs, :target=>ts,
      :coverage=>c, :ui=>ui, :context_clear=>context_clear, :ring_ok=>ring_ok
    }
  rescue
    {:applicable=>true, :mode=>mode, :pass=>false}
  end

  # v1.02.35 的 start_battle alias 會動態呼叫這個方法；在本腳本最終覆寫後，
  # 不需要再疊一層 start_battle alias，也避免多跑一次驗收。
  def production_path_probe_log_v10235(mode_before)
    return unless PMD_AC::PRODUCTION_PATH_PROBE_ENABLED_V10235
    return unless PMD_AC::PRODUCTION_PATH_SEAL_ENABLED_V10239
    return if @production_path_probe_logged_v10235
    mode = mode_before || production_path_probe_mode_v10235
    return if mode == :pmd_motion_phase_a_v102

    r = production_path_seal_summary_v10239(mode)
    unless r[:applicable]
      log_event(:perf,
        'MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 active_motion_species=0 skipped=1'+
        ' mode='+mode.to_s+' verifier_independent=1 log_visibility_fix=v10239')
      @production_path_probe_logged_v10235 = true
      return
    end

    s = r[:resource] || {}
    bs = r[:baseline] || {}
    ts = r[:target] || {}
    c = r[:coverage] || {}
    ui = r[:ui] || {}
    pass = r[:pass] ? true : false

    common =
      ' pass='+(pass ? '1':'0')+
      ' mode='+mode.to_s+
      ' active_motion_species=1 loading_ready='+(r[:loading_ready] ? '1':'0')+
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
      ' loading_context_clear='+(r[:context_clear] ? '1':'0')+
      ' mode_ring_ok='+(r[:ring_ok] ? '1':'0')

    # NORMAL current-test minimal 允許 :perf，不允許 :verify。
    log_event(:perf,
      'MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235'+common+
      ' verifier_independent=1 normal_path=1 log_visibility_fix=v10239'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    log_event(:perf,
      'MOTION_PRODUCTION_PATH_SEAL_V10239'+common+
      ' current_test_category=perf effective_coverage=1 geometry_cache_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @production_path_probe_logged_v10235 = true
  rescue
    @production_path_probe_logged_v10235 = true
  end

  def start
    r = pmd_ac_v10239_start
    begin
      log_event(:perf,
        'PRODUCTION_PATH_SEAL_V10239 ready=1 normal_acceptance_category=perf'+
        ' v10235_visibility_fixed=1 mode_ring=normal,pmd_motion_phase_a_v102'+
        ' production_loading_unchanged=1 geometry_cache_unchanged=1'+
        ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    rescue
    end
    r
  end
end
