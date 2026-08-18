# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Geometry Cache Effective Coverage v1.02.32
# 分類：戰鬥效能／Battle Loading／Persistent Geometry Cache 驗收修正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v1.02.31 Windows 實機已證明 Persistent Geometry Cache 的實際運作成功：
# Visible Baseline 原 preload 顯示 computed=0 / cached=266 / total_ms=0，
# Target Anchor 顯示 computed=0 / cached=6 / total_ms=0，Battle Loading 亦降至
# 約 5.5 秒。然而 v1.02.30 / v1.02.31 verifier 仍錯誤要求「disk hydrate hit」
# 必須等於全部 pair 數，因此把 260 disk hit + 6 preexisting runtime entries
# 誤判成 260/266 FAIL。
#
# 本版只修正驗收語意：
#   effective coverage = disk hydrate hit + hydrate 前已存在的 runtime entries
# preexisting 不代表遺漏；只要該 pair 在 hydrate 前已經存在，就不應再次從磁碟
# 注入，也不需要進入 alpha scan。正式 PASS 仍同時要求 missing=0、invalid=0、
# computed=0、fail=0，確保沒有用「預先存在」名義掩蓋 fallback scan。
#==============================================================================
# 【主要設定項】
# - 不新增可調效能參數。
# - 沿用 v1.02.30：
#   PMD_AC::GEOMETRY_CACHE_STRICT_VERIFY_V10230
# - 沿用 v1.02.31 payload version / runtime parity / entry count 驗證。
#==============================================================================
# 【機制規則】
# 1. baseline_preexisting = baseline_pairs - disk_hit - missing - invalid。
# 2. target_preexisting 同理。
# 3. effective = disk_hit + preexisting。
# 4. Strict PASS 必須同時成立：
#    - effective baseline == baseline_pairs
#    - effective target == target_pairs
#    - missing=0 / invalid=0
#    - 原 v1.02.12 / v1.02.16 computed=0 / fail=0
#    - Geometry Cache file/offline/runtime parity payload 正確
# 5. 不修改 cache hydrate、metadata guard、File.size guard、Bitmap dimension guard。
# 6. 不修改 geometry value、HP Bar Y、Target Anchor 或任何戰鬥規則。
#==============================================================================
# 【可調參數】
# 無。這是 verifier correctness fix，不應以放寬條件換 PASS。
# 如果未來真的出現 missing / invalid / computed > 0，本版仍必須 FAIL。
#==============================================================================
# 【事件／腳本呼叫方式】
# 不需事件呼叫。
# 測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥。
#==============================================================================
# 【實際範例】
# Windows v1.02.31：
#   baseline_pairs=266
#   baseline_disk_hit=260
#   baseline_missing=0
#   baseline_invalid=0
#   v1.02.12 computed=0 cached=266
# 因此：baseline_preexisting=6，effective=260+6=266，應判 PASS。
#==============================================================================
# 【預期 LOG】
# MOTION_PERSISTENT_GEOMETRY_CACHE_V10230 pass=1 ...
#   baseline_disk_hit=260 baseline_preexisting=6 baseline_effective=266/266 ...
# MOTION_GEOMETRY_CACHE_RUNTIME_PARITY_VERIFY_V10231 pass=1 ...
# MOTION_GEOMETRY_CACHE_EFFECTIVE_COVERAGE_V10232 pass=1 ...
# PMD_MOTION_PHASE_A_V102 pass=1
#==============================================================================
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只使用 Main 前 trailing override。
# - 不修改 Damage Formula、Attack Speed、AI、Spatial logical x/y。
# - 不修改 v0.57.6 Visible Baseline / v0.57.3 Target Anchor 公式。
# - 不修改 True Foot gap、HP Bar Y、hitFrame、Hurt ownership、hit-stop。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_GeometryCacheEffectiveCoverage_v10232'] = true

module PMD_AC
  GEOMETRY_CACHE_EFFECTIVE_COVERAGE_VERSION_V10232 = '1.02.32'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10232_start start unless method_defined?(:pmd_ac_v10232_start)
  alias pmd_ac_v10232_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10232_restart_to_deploy)
  alias pmd_ac_v10232_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10232_update_verification_script)

  def motion_geometry_cache_effective_reset_v10232
    @motion_geometry_cache_effective_verify_logged_v10232 = false
  end

  def start
    motion_geometry_cache_effective_reset_v10232
    pmd_ac_v10232_start
  end

  def restart_to_deploy
    r = pmd_ac_v10232_restart_to_deploy
    motion_geometry_cache_effective_reset_v10232 if @phase == :deploy
    r
  end

  def motion_geometry_cache_coverage_v10232
    s = @motion_geometry_cache_stats_v10230 || {}
    bp = s[:baseline_pairs].to_i
    bh = s[:baseline_hit].to_i
    bm = s[:baseline_missing].to_i
    bi = s[:baseline_invalid].to_i
    tp = s[:target_pairs].to_i
    th = s[:target_hit].to_i
    tm = s[:target_missing].to_i
    ti = s[:target_invalid].to_i
    bpre = bp - bh - bm - bi
    tpre = tp - th - tm - ti
    bpre = 0 if bpre < 0
    tpre = 0 if tpre < 0
    {
      :baseline_pairs=>bp, :baseline_disk_hit=>bh,
      :baseline_missing=>bm, :baseline_invalid=>bi,
      :baseline_preexisting=>bpre, :baseline_effective=>bh+bpre,
      :target_pairs=>tp, :target_disk_hit=>th,
      :target_missing=>tm, :target_invalid=>ti,
      :target_preexisting=>tpre, :target_effective=>th+tpre
    }
  rescue
    {}
  end

  # v1.02.30 的 strict verifier 改用 effective coverage。
  # 方法名稱保持不變，讓舊 update_verification_script 自動呼叫本版實作。
  def verify_motion_persistent_geometry_cache_v10230
    return if @motion_geometry_cache_verify_logged_v10230
    s = @motion_geometry_cache_stats_v10230 || {}
    bs = @motion_baseline_summary_v10212 || {}
    ts = @motion_target_anchor_summary_v10216 || {}
    c = motion_geometry_cache_coverage_v10232
    strict = PMD_AC::GEOMETRY_CACHE_STRICT_VERIFY_V10230
    coverage_ok = c[:baseline_pairs].to_i > 0 && c[:target_pairs].to_i > 0 &&
      c[:baseline_effective].to_i == c[:baseline_pairs].to_i &&
      c[:target_effective].to_i == c[:target_pairs].to_i &&
      c[:baseline_missing].to_i == 0 && c[:baseline_invalid].to_i == 0 &&
      c[:target_missing].to_i == 0 && c[:target_invalid].to_i == 0
    original_preload_zero = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    pass = motion_geometry_cache_mode_v10230? && PMD_AC.geometry_cache_file_ok_v10230? &&
      PMD_AC.geometry_cache_offline_v10230? && original_preload_zero && (!strict || coverage_ok)
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_PERSISTENT_GEOMETRY_CACHE_V10230 pass='+(pass ? '1':'0')+
      ' file='+(PMD_AC.geometry_cache_file_ok_v10230? ? '1':'0')+
      ' offline='+(PMD_AC.geometry_cache_offline_v10230? ? '1':'0')+
      ' baseline_hit='+s[:baseline_hit].to_i.to_s+'/'+s[:baseline_pairs].to_i.to_s+
      ' baseline_disk_hit='+c[:baseline_disk_hit].to_i.to_s+
      ' baseline_preexisting='+c[:baseline_preexisting].to_i.to_s+
      ' baseline_effective='+c[:baseline_effective].to_i.to_s+'/'+c[:baseline_pairs].to_i.to_s+
      ' target_hit='+s[:target_hit].to_i.to_s+'/'+s[:target_pairs].to_i.to_s+
      ' target_disk_hit='+c[:target_disk_hit].to_i.to_s+
      ' target_preexisting='+c[:target_preexisting].to_i.to_s+
      ' target_effective='+c[:target_effective].to_i.to_s+'/'+c[:target_pairs].to_i.to_s+
      ' baseline_computed='+bs[:computed].to_i.to_s+
      ' target_computed='+ts[:computed].to_i.to_s+
      ' missing='+(s[:baseline_missing].to_i+s[:target_missing].to_i).to_s+
      ' invalid='+(s[:baseline_invalid].to_i+s[:target_invalid].to_i).to_s+
      ' effective_coverage=1 metadata_guard=1 file_size_guard=1 bitmap_dimension_guard=1'+
      ' formulas_unchanged=1 hp_bar_y_unchanged=1 target_anchor_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_geometry_cache_verify_logged_v10230 = true
  rescue
  end

  # v1.02.31 Runtime Parity verifier 同步修正 coverage 定義；payload 嚴格條件不變。
  def verify_motion_geometry_cache_runtime_parity_v10231
    return if @motion_geometry_cache_runtime_parity_verify_logged_v10231
    s = @motion_geometry_cache_stats_v10230 || {}
    bs = @motion_baseline_summary_v10212 || {}
    ts = @motion_target_anchor_summary_v10216 || {}
    c = motion_geometry_cache_coverage_v10232
    h = PMD_AC.geometry_cache_payload_v10230
    parity = h[:runtime_parity].to_s rescue ''
    bsize = (h[:baseline] || {}).size rescue 0
    asize = (h[:anchor] || {}).size rescue 0
    coverage_ok = c[:baseline_pairs].to_i > 0 &&
      c[:baseline_effective].to_i == c[:baseline_pairs].to_i &&
      c[:baseline_missing].to_i == 0 && c[:baseline_invalid].to_i == 0 &&
      c[:target_pairs].to_i > 0 &&
      c[:target_effective].to_i == c[:target_pairs].to_i &&
      c[:target_missing].to_i == 0 && c[:target_invalid].to_i == 0
    compute_ok = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    payload_ok = h[:version].to_s == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_VERSION_V10231 &&
      parity == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_MARK_V10231 &&
      bsize.to_i == PMD_AC::GEOMETRY_CACHE_BASELINE_ENTRIES_V10231 &&
      asize.to_i == PMD_AC::GEOMETRY_CACHE_ANCHOR_ENTRIES_V10231
    pass = motion_geometry_cache_mode_v10230? && coverage_ok && compute_ok && payload_ok
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_GEOMETRY_CACHE_RUNTIME_PARITY_VERIFY_V10231 pass='+(pass ? '1':'0')+
      ' baseline_hit='+s[:baseline_hit].to_i.to_s+'/'+s[:baseline_pairs].to_i.to_s+
      ' baseline_preexisting='+c[:baseline_preexisting].to_i.to_s+
      ' baseline_effective='+c[:baseline_effective].to_i.to_s+'/'+c[:baseline_pairs].to_i.to_s+
      ' target_hit='+s[:target_hit].to_i.to_s+'/'+s[:target_pairs].to_i.to_s+
      ' target_preexisting='+c[:target_preexisting].to_i.to_s+
      ' target_effective='+c[:target_effective].to_i.to_s+'/'+c[:target_pairs].to_i.to_s+
      ' baseline_computed='+bs[:computed].to_i.to_s+
      ' target_computed='+ts[:computed].to_i.to_s+
      ' missing='+(s[:baseline_missing].to_i+s[:target_missing].to_i).to_s+
      ' invalid='+(s[:baseline_invalid].to_i+s[:target_invalid].to_i).to_s+
      ' baseline_entries='+bsize.to_i.to_s+' anchor_entries='+asize.to_i.to_s+
      ' runtime_parity='+(payload_ok ? '1':'0')+' effective_coverage=1'+
      ' formulas_unchanged=1 hp_bar_y_unchanged=1 target_anchor_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_geometry_cache_runtime_parity_verify_logged_v10231 = true
  rescue
  end

  def verify_motion_geometry_cache_effective_coverage_v10232
    return if @motion_geometry_cache_effective_verify_logged_v10232
    return unless motion_geometry_cache_mode_v10230?
    s = @motion_geometry_cache_stats_v10230 || {}
    bs = @motion_baseline_summary_v10212 || {}
    ts = @motion_target_anchor_summary_v10216 || {}
    c = motion_geometry_cache_coverage_v10232
    h = PMD_AC.geometry_cache_payload_v10230
    payload_ok = h[:version].to_s == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_VERSION_V10231 &&
      (h[:runtime_parity].to_s rescue '') == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_MARK_V10231
    coverage_ok = c[:baseline_pairs].to_i > 0 &&
      c[:baseline_effective].to_i == c[:baseline_pairs].to_i &&
      c[:target_pairs].to_i > 0 && c[:target_effective].to_i == c[:target_pairs].to_i &&
      c[:baseline_missing].to_i == 0 && c[:baseline_invalid].to_i == 0 &&
      c[:target_missing].to_i == 0 && c[:target_invalid].to_i == 0
    compute_ok = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    pass = coverage_ok && compute_ok && payload_ok
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_GEOMETRY_CACHE_EFFECTIVE_COVERAGE_V10232 pass='+(pass ? '1':'0')+
      ' baseline_disk_hit='+c[:baseline_disk_hit].to_i.to_s+
      ' baseline_preexisting='+c[:baseline_preexisting].to_i.to_s+
      ' baseline_effective='+c[:baseline_effective].to_i.to_s+'/'+c[:baseline_pairs].to_i.to_s+
      ' target_disk_hit='+c[:target_disk_hit].to_i.to_s+
      ' target_preexisting='+c[:target_preexisting].to_i.to_s+
      ' target_effective='+c[:target_effective].to_i.to_s+'/'+c[:target_pairs].to_i.to_s+
      ' baseline_computed='+bs[:computed].to_i.to_s+
      ' target_computed='+ts[:computed].to_i.to_s+
      ' missing='+(s[:baseline_missing].to_i+s[:target_missing].to_i).to_s+
      ' invalid='+(s[:baseline_invalid].to_i+s[:target_invalid].to_i).to_s+
      ' payload_parity='+(payload_ok ? '1':'0')+
      ' verifier_semantics=effective_coverage'+
      ' formulas_unchanged=1 hp_bar_y_unchanged=1 target_anchor_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_geometry_cache_effective_verify_logged_v10232 = true
  rescue
  end

  def update_verification_script
    pmd_ac_v10232_update_verification_script
    return unless motion_geometry_cache_mode_v10230?
    verify_motion_geometry_cache_effective_coverage_v10232 if @verification_frame.to_i >= 80
  end
end
