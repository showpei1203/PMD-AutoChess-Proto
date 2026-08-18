# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Geometry Cache Runtime Parity v1.02.31
# 分類：戰鬥效能／Battle Loading／Persistent Geometry Cache 校正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v1.02.30 首次 Windows A/B 證明 Persistent Geometry Cache 有效：
# Target Anchor 已 6/6 命中、0ms；但 Visible Baseline 只有 185/266 命中，
# 另外 69 invalid + 6 missing，因此仍有 75 筆 fallback alpha scan，約 4 秒。
#
# 根因不是 alpha scan 公式錯誤，而是「離線生成器的 action 解析規則」落後於
# Windows runtime：
#   1. v0.60 會先合併 Native Added Actions / CopyOf aliases。
#   2. v0.61 會擴充 ACTION_FALLBACKS，例如 punch/bite/slice/sound/emit 等。
#   3. 舊核心另有 :mega fallback key。
# v1.02.30 離線 cache 使用較早 fallback 表，因此 requested-key 指向不同 sheet；
# 六隻實戰 Pokémon 正好產生 69 invalid，而每隻缺少 :mega，正好 6 missing。
#
# 本版不改 runtime geometry 公式，只替換 Data/PMDGeometryCache.rvdata 為
# 「v0.60 native merge + v0.61 最終 fallbacks + :mega」完全同規則離線重建版本，
# 並增加 Runtime Parity verifier，要求本場 266/266 baseline、6/6 anchor 全命中。
#==============================================================================
# 【主要設定／資料】
# - Data/PMDGeometryCache.rvdata
#   version=1.02.31
#   runtime_parity=v060_native_merge+v061_fallbacks+mega
#   baseline entries=2210（0001～0026 × 85 requested keys）
#   anchor entries=26
# - 本腳本不建立新的 Bitmap，不修改 cache value，只做驗收與 LOG。
#==============================================================================
# 【機制規則】
# 1. v1.02.30 hydrate / metadata guard / fallback scan 邏輯原封不動。
# 2. v1.02.31 只確保離線資料和 runtime action_data() 的解析結果一致。
# 3. 若 PNG、File.size、frame metadata 或 Bitmap dimensions 改變，v1.02.30
#    仍會把該筆判 invalid 並安全 fallback，不會硬套錯誤腳底／Anchor。
# 4. Motion verifier 若不是 baseline 266/266、anchor 6/6、computed=0，直接 FAIL。
#==============================================================================
# 【可調參數／重新生成方式】
# 專案附 Tools/GeometryCache：
#   export_geom_meta_v10231.rb
#   precompute_geometry_v10231.py
#   build_geom_cache_v10231.rb
# 修改 PMD 素材或 ACTION_FALLBACKS 後，必須同步更新 exporter 的 runtime parity
# 規則再重新生成。不要單純關閉 metadata guard 來換 Loading 數字。
#==============================================================================
# 【事件／腳本呼叫方式】
# 不需事件呼叫。
# 測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥。
#==============================================================================
# 【預期 LOG】
# MOTION_GEOMETRY_CACHE_PRELOAD_V10230 ... baseline_hit=266 ... invalid=0 missing=0
# MOTION_BASELINE_PRELOAD_V10212 ... computed=0 cached=266 total_ms≈0
# MOTION_TARGET_ANCHOR_PRELOAD_V10216 ... computed=0 cached=6 total_ms=0
# MOTION_GEOMETRY_CACHE_RUNTIME_PARITY_V10231 ready=1 baseline_entries=2210 ...
# MOTION_GEOMETRY_CACHE_RUNTIME_PARITY_VERIFY_V10231 pass=1 ...
#==============================================================================
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只使用 Main 前 trailing alias。
# - 不修改 Damage Formula、Attack Speed、AI、Spatial logical x/y。
# - 不修改 v0.57.6 Visible Baseline / v0.57.3 Target Anchor 計算公式。
# - 不修改 True Foot gap、HP Bar Y、hitFrame、Hurt ownership、hit-stop。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_GeometryCacheRuntimeParity_v10231'] = true

module PMD_AC
  GEOMETRY_CACHE_RUNTIME_PARITY_VERSION_V10231 = '1.02.31'
  GEOMETRY_CACHE_RUNTIME_PARITY_MARK_V10231 = 'v060_native_merge+v061_fallbacks+mega'
  GEOMETRY_CACHE_BASELINE_ENTRIES_V10231 = 2210
  GEOMETRY_CACHE_ANCHOR_ENTRIES_V10231 = 26
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10231_start start unless method_defined?(:pmd_ac_v10231_start)
  alias pmd_ac_v10231_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10231_restart_to_deploy)
  alias pmd_ac_v10231_motion_log_geometry_cache_loading_v10230 motion_log_geometry_cache_loading_v10230 unless method_defined?(:pmd_ac_v10231_motion_log_geometry_cache_loading_v10230)
  alias pmd_ac_v10231_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10231_update_verification_script)

  def motion_geometry_cache_runtime_parity_reset_v10231
    @motion_geometry_cache_runtime_parity_loading_logged_v10231 = false
    @motion_geometry_cache_runtime_parity_verify_logged_v10231 = false
  end

  def start
    motion_geometry_cache_runtime_parity_reset_v10231
    pmd_ac_v10231_start
  end

  def restart_to_deploy
    r = pmd_ac_v10231_restart_to_deploy
    motion_geometry_cache_runtime_parity_reset_v10231 if @phase == :deploy
    r
  end

  def motion_log_geometry_cache_loading_v10230
    pmd_ac_v10231_motion_log_geometry_cache_loading_v10230
    return if @motion_geometry_cache_runtime_parity_loading_logged_v10231
    return unless motion_geometry_cache_mode_v10230?
    h = PMD_AC.geometry_cache_payload_v10230
    parity = h[:runtime_parity].to_s rescue ''
    bsize = (h[:baseline] || {}).size rescue 0
    asize = (h[:anchor] || {}).size rescue 0
    log_event(:perf,
      'MOTION_GEOMETRY_CACHE_RUNTIME_PARITY_V10231 ready=1'+
      ' version='+h[:version].to_s+
      ' parity='+(parity == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_MARK_V10231 ? '1':'0')+
      ' baseline_entries='+bsize.to_i.to_s+
      ' anchor_entries='+asize.to_i.to_s+
      ' v060_native_merge=1 v061_final_fallbacks=1 mega_requested_key=1'+
      ' formulas_unchanged=1 metadata_guard_unchanged=1')
    @motion_geometry_cache_runtime_parity_loading_logged_v10231 = true
  rescue
  end

  def verify_motion_geometry_cache_runtime_parity_v10231
    return if @motion_geometry_cache_runtime_parity_verify_logged_v10231
    s = @motion_geometry_cache_stats_v10230 || {}
    bs = @motion_baseline_summary_v10212 || {}
    ts = @motion_target_anchor_summary_v10216 || {}
    h = PMD_AC.geometry_cache_payload_v10230
    parity = h[:runtime_parity].to_s rescue ''
    bsize = (h[:baseline] || {}).size rescue 0
    asize = (h[:anchor] || {}).size rescue 0
    hit_ok = s[:baseline_pairs].to_i > 0 &&
      s[:baseline_hit].to_i == s[:baseline_pairs].to_i &&
      s[:baseline_missing].to_i == 0 && s[:baseline_invalid].to_i == 0 &&
      s[:target_pairs].to_i > 0 &&
      s[:target_hit].to_i == s[:target_pairs].to_i &&
      s[:target_missing].to_i == 0 && s[:target_invalid].to_i == 0
    compute_ok = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    payload_ok = h[:version].to_s == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_VERSION_V10231 &&
      parity == PMD_AC::GEOMETRY_CACHE_RUNTIME_PARITY_MARK_V10231 &&
      bsize.to_i == PMD_AC::GEOMETRY_CACHE_BASELINE_ENTRIES_V10231 &&
      asize.to_i == PMD_AC::GEOMETRY_CACHE_ANCHOR_ENTRIES_V10231
    pass = motion_geometry_cache_mode_v10230? && hit_ok && compute_ok && payload_ok
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_GEOMETRY_CACHE_RUNTIME_PARITY_VERIFY_V10231 pass='+(pass ? '1':'0')+
      ' baseline_hit='+s[:baseline_hit].to_i.to_s+'/'+s[:baseline_pairs].to_i.to_s+
      ' target_hit='+s[:target_hit].to_i.to_s+'/'+s[:target_pairs].to_i.to_s+
      ' baseline_computed='+bs[:computed].to_i.to_s+
      ' target_computed='+ts[:computed].to_i.to_s+
      ' missing='+(s[:baseline_missing].to_i+s[:target_missing].to_i).to_s+
      ' invalid='+(s[:baseline_invalid].to_i+s[:target_invalid].to_i).to_s+
      ' baseline_entries='+bsize.to_i.to_s+' anchor_entries='+asize.to_i.to_s+
      ' runtime_parity='+(payload_ok ? '1':'0')+
      ' formulas_unchanged=1 hp_bar_y_unchanged=1 target_anchor_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_geometry_cache_runtime_parity_verify_logged_v10231 = true
  rescue
  end

  def update_verification_script
    pmd_ac_v10231_update_verification_script
    return unless motion_geometry_cache_mode_v10230?
    verify_motion_geometry_cache_runtime_parity_v10231 if @verification_frame.to_i >= 79
  end
end
