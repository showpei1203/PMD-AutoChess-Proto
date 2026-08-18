# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Persistent Geometry Cache v1.02.30
# 分類：戰鬥效能／Battle Loading／PMD 幾何持久化快取
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v1.02.29 已正式封住 live battle 100ms 級卡頓；目前最大剩餘成本轉為
# Battle Loading：Windows 實機約 14 秒，其中 v1.02.12 Visible Baseline
# alpha scan 單獨約 9.2 秒，v1.02.16 Target Anchor scan 約 0.46 秒。
#
# 本版把兩套「只由 PMD PNG + Action metadata 決定」的幾何結果持久化：
#   1. v0.57.6 contact_bottom_cache_v0576
#   2. v0.57.3 target_anchor_cache_v0573
# 專案封包已附 Data/PMDGeometryCache.rvdata，內容由 0001～0026 現有 PMD
# 素材離線使用同一套 alpha_threshold=8 / scan_step=1 / frame metadata 算出。
# Battle Loading 只做 entry 驗證與 Hash hydrate，不再逐像素掃描。
#==============================================================================
# 【主要設定項】
# PMD_AC::GEOMETRY_CACHE_PATH_V10230
#   預設 Data/PMDGeometryCache.rvdata。
# PMD_AC::GEOMETRY_CACHE_FORMAT_V10230
#   Cache 格式識別；格式不符時整份視為不可用。
# PMD_AC::GEOMETRY_CACHE_STRICT_VERIFY_V10230
#   true：Motion verifier 必須要求本場 baseline / target pair 全部由磁碟命中。
#==============================================================================
# 【機制規則】
# 1. 不改 v0.57.6 / v0.57.3 的計算公式，只在原 preload 前注入已驗證結果。
# 2. 每筆 entry 驗證：species、requested action、解析後 file、File.size、
#    frame_w、frame_h、frames、durations size、目前 Bitmap width/height。
# 3. 任一欄位不符，只讓該 entry miss，交回原 v1.02.12 / v1.02.16 掃描。
# 4. 原掃描若產生新結果，會更新記憶體 payload；可寫時保存回同一 rvdata。
# 5. Cache 檔遺失／損毀／唯讀都不會阻止戰鬥，只會退回原本較慢流程。
# 6. Motion verifier 第一輪正式驗收要求 baseline / target 全磁碟命中，藉此確認
#    離線 cache 與 Windows RGSS2 現有素材 metadata 完整對齊。
#==============================================================================
# 【可調參數／維護方式】
# - 若替換 Graphics/PMD 圖、修改 frame metadata、alpha threshold 或 scan step，
#   應重新生成 PMDGeometryCache.rvdata；舊 entry 會因 fingerprint 不符而失效。
# - 不要為追求 Loading 數字而取消 entry 驗證；錯誤腳底／命中特效座標比慢更糟。
# - 下一階段若本版 Windows PASS，可把相同 cache 擴到 NORMAL / Map Story encounter。
#==============================================================================
# 【事件／腳本呼叫方式】
# 不需事件手動呼叫。
# 測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥。
#==============================================================================
# 【預期 LOG】
# Loading：
#   MOTION_GEOMETRY_CACHE_PRELOAD_V10230 ready=1 ... baseline_hit=266 ... target_hit=6 ...
#   MOTION_BASELINE_PRELOAD_V10212 ... computed=0 cached=266 total_ms≈0
#   MOTION_TARGET_ANCHOR_PRELOAD_V10216 ... computed=0 cached=6 total_ms≈0
# Verifier：
#   MOTION_PERSISTENT_GEOMETRY_CACHE_V10230 pass=1 ...
# Battle end 仍必須：
#   MOTION_BASELINE_RUNTIME_V10212 live_miss=0
#   MOTION_TARGET_ANCHOR_RUNTIME_V10216 live_miss=0
#   MOTION_PERFORMANCE_SEAL_V10229 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只用 Main 前 trailing alias。
# - 不修改 Damage Formula、Attack Speed、AI、Spatial Framework、logical x/y。
# - 不修改 True Foot gap、Target lower-body ratio、hitFrame、Hurt ownership、hit-stop。
# - Pokémon identity 仍使用 instance_uid。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_PersistentGeometryCache_v10230'] = true

module PMD_AC
  GEOMETRY_CACHE_VERSION_V10230 = '1.02.30'
  GEOMETRY_CACHE_PATH_V10230 = 'Data/PMDGeometryCache.rvdata'
  GEOMETRY_CACHE_FORMAT_V10230 = 'PMDGeometryCacheV1030'
  GEOMETRY_CACHE_STRICT_VERIFY_V10230 = true

  class << self
    def geometry_cache_reset_memory_v10230
      @geometry_cache_payload_v10230 = nil
      @geometry_cache_loaded_v10230 = false
      @geometry_cache_file_ok_v10230 = false
      @geometry_cache_format_ok_v10230 = false
      @geometry_cache_dirty_v10230 = false
    end

    def geometry_cache_payload_v10230
      return @geometry_cache_payload_v10230 if @geometry_cache_loaded_v10230
      @geometry_cache_loaded_v10230 = true
      @geometry_cache_file_ok_v10230 = false
      @geometry_cache_format_ok_v10230 = false
      h = nil
      begin
        h = load_data(GEOMETRY_CACHE_PATH_V10230) if FileTest.exist?(GEOMETRY_CACHE_PATH_V10230)
      rescue
        h = nil
      end
      if h.is_a?(Hash)
        @geometry_cache_file_ok_v10230 = true
        @geometry_cache_format_ok_v10230 = h[:format].to_s == GEOMETRY_CACHE_FORMAT_V10230
      end
      if !@geometry_cache_format_ok_v10230
        h = {
          :format => GEOMETRY_CACHE_FORMAT_V10230,
          :version => GEOMETRY_CACHE_VERSION_V10230,
          :algorithm => 'runtime_rebuild',
          :offline_precomputed => false,
          :baseline => {}, :anchor => {}
        }
      end
      h[:baseline] = {} unless h[:baseline].is_a?(Hash)
      h[:anchor] = {} unless h[:anchor].is_a?(Hash)
      @geometry_cache_payload_v10230 = h
      h
    end

    def geometry_cache_file_ok_v10230?
      geometry_cache_payload_v10230
      @geometry_cache_file_ok_v10230 && @geometry_cache_format_ok_v10230
    rescue
      false
    end

    def geometry_cache_offline_v10230?
      h = geometry_cache_payload_v10230
      h[:offline_precomputed] ? true : false
    rescue
      false
    end

    def geometry_cache_normalized_file_v10230(name)
      n = name.to_s
      n += '.png' unless n.downcase =~ /\.png$/
      n
    rescue
      name.to_s
    end

    def geometry_cache_meta_for_v10230(species, action)
      sid = species.to_s
      act = action == nil ? :idle : action.to_s.to_sym
      d = action_data(sid, act)
      return nil if d == nil || d[:file] == nil
      file = geometry_cache_normalized_file_v10230(d[:file])
      path = PMD_ROOT + sid + '/' + file
      return nil unless FileTest.exist?(path)
      bmp = nil
      begin
        bmp = Cache.load_bitmap(PMD_ROOT + sid + '/', d[:file].to_s)
      rescue
        bmp = nil
      end
      return nil if bmp == nil || bmp.disposed?
      {
        :file => file,
        :size => (File.size(path) rescue -1),
        :frame_w => d[:frame_w].to_i,
        :frame_h => d[:frame_h].to_i,
        :frames => d[:frames].to_i,
        :durations_size => (d[:durations].respond_to?(:size) ? d[:durations].size.to_i : 0),
        :image_w => bmp.width.to_i,
        :image_h => bmp.height.to_i
      }
    rescue
      nil
    end

    def geometry_cache_entry_valid_v10230?(entry, species, action)
      return false unless entry.is_a?(Hash)
      m = geometry_cache_meta_for_v10230(species, action)
      return false if m == nil
      [:file,:size,:frame_w,:frame_h,:frames,:durations_size,:image_w,:image_h].each do |k|
        if k == :file
          return false unless entry[k].to_s == m[k].to_s
        else
          return false unless entry[k].to_i == m[k].to_i
        end
      end
      true
    rescue
      false
    end

    def geometry_cache_capture_entry_v10230(kind, key, value)
      h = geometry_cache_payload_v10230
      store = kind == :anchor ? h[:anchor] : h[:baseline]
      m = geometry_cache_meta_for_v10230(key[0], key[1])
      return false if m == nil
      e = m.dup
      e[:value] = value
      old = store[key]
      changed = old != e
      store[key] = e
      @geometry_cache_dirty_v10230 = true if changed
      changed
    rescue
      false
    end

    def geometry_cache_save_v10230
      return [false,0] unless @geometry_cache_dirty_v10230
      h = geometry_cache_payload_v10230
      h[:format] = GEOMETRY_CACHE_FORMAT_V10230
      h[:version] = GEOMETRY_CACHE_VERSION_V10230
      t = Time.now.to_f
      ok = true
      begin
        save_data(h, GEOMETRY_CACHE_PATH_V10230)
      rescue
        ok = false
      end
      ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
      @geometry_cache_dirty_v10230 = false if ok
      [ok,ms]
    rescue
      [false,0]
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10230_start start unless method_defined?(:pmd_ac_v10230_start)
  alias pmd_ac_v10230_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10230_restart_to_deploy)
  alias pmd_ac_v10230_motion_precompute_baselines_v10212 motion_precompute_baselines_v10212 unless method_defined?(:pmd_ac_v10230_motion_precompute_baselines_v10212)
  alias pmd_ac_v10230_motion_precompute_target_anchor_bounds_v10216 motion_precompute_target_anchor_bounds_v10216 unless method_defined?(:pmd_ac_v10230_motion_precompute_target_anchor_bounds_v10216)
  alias pmd_ac_v10230_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10230_update_verification_script)
  alias pmd_ac_v10230_motion_log_target_anchor_runtime_v10216 motion_log_target_anchor_runtime_v10216 unless method_defined?(:pmd_ac_v10230_motion_log_target_anchor_runtime_v10216)

  def motion_geometry_cache_reset_v10230
    @motion_geometry_cache_stats_v10230 = {
      :baseline_pairs=>0,:baseline_hit=>0,:baseline_missing=>0,:baseline_invalid=>0,
      :target_pairs=>0,:target_hit=>0,:target_missing=>0,:target_invalid=>0,
      :hydrate_ms=>0,:write_ok=>0,:write_ms=>0
    }
    @motion_geometry_cache_verify_logged_v10230 = false
    @motion_geometry_cache_summary_logged_v10230 = false
  end

  def start
    motion_geometry_cache_reset_v10230
    pmd_ac_v10230_start
  end

  def restart_to_deploy
    r = pmd_ac_v10230_restart_to_deploy
    motion_geometry_cache_reset_v10230 if @phase == :deploy
    r
  end

  def motion_geometry_cache_mode_v10230?
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_geometry_hydrate_baseline_v10230(pairs)
    return unless motion_geometry_cache_mode_v10230?
    t = Time.now.to_f
    h = PMD_AC.geometry_cache_payload_v10230
    disk = h[:baseline] || {}
    runtime = PMD_AC.contact_bottom_cache_v0576
    s = @motion_geometry_cache_stats_v10230
    s[:baseline_pairs] = pairs.size
    pairs.each do |row|
      key = row[2]
      next if runtime.has_key?(key)
      e = disk[key]
      if e == nil
        s[:baseline_missing] += 1
      elsif PMD_AC.geometry_cache_entry_valid_v10230?(e,key[0],key[1])
        runtime[key] = e[:value].to_f
        s[:baseline_hit] += 1
      else
        s[:baseline_invalid] += 1
      end
    end
    s[:hydrate_ms] += (((Time.now.to_f-t)*1000.0).round rescue 0)
  rescue
  end

  def motion_geometry_capture_baseline_v10230(pairs)
    return unless motion_geometry_cache_mode_v10230?
    runtime = PMD_AC.contact_bottom_cache_v0576
    pairs.each do |row|
      key = row[2]
      next unless runtime.has_key?(key)
      PMD_AC.geometry_cache_capture_entry_v10230(:baseline,key,runtime[key].to_f)
    end
  rescue
  end

  def motion_precompute_baselines_v10212(ui)
    pairs = motion_baseline_pairs_v10212
    motion_geometry_hydrate_baseline_v10230(pairs)
    r = pmd_ac_v10230_motion_precompute_baselines_v10212(ui)
    motion_geometry_capture_baseline_v10230(pairs)
    r
  end

  def motion_geometry_hydrate_target_v10230(pairs)
    return unless motion_geometry_cache_mode_v10230?
    t = Time.now.to_f
    h = PMD_AC.geometry_cache_payload_v10230
    disk = h[:anchor] || {}
    runtime = PMD_AC.target_anchor_cache_v0573
    s = @motion_geometry_cache_stats_v10230
    s[:target_pairs] = pairs.size
    pairs.each do |row|
      key = row[2]
      next if runtime.has_key?(key)
      e = disk[key]
      if e == nil
        s[:target_missing] += 1
      elsif PMD_AC.geometry_cache_entry_valid_v10230?(e,key[0],key[1])
        runtime[key] = e[:value]
        s[:target_hit] += 1
      else
        s[:target_invalid] += 1
      end
    end
    s[:hydrate_ms] += (((Time.now.to_f-t)*1000.0).round rescue 0)
  rescue
  end

  def motion_geometry_capture_target_v10230(pairs)
    return unless motion_geometry_cache_mode_v10230?
    runtime = PMD_AC.target_anchor_cache_v0573
    pairs.each do |row|
      key = row[2]
      next unless runtime.has_key?(key)
      PMD_AC.geometry_cache_capture_entry_v10230(:anchor,key,runtime[key])
    end
  rescue
  end

  def motion_precompute_target_anchor_bounds_v10216(ui)
    pairs = motion_target_anchor_pairs_v10216
    motion_geometry_hydrate_target_v10230(pairs)
    r = pmd_ac_v10230_motion_precompute_target_anchor_bounds_v10216(ui)
    motion_geometry_capture_target_v10230(pairs)
    saved = PMD_AC.geometry_cache_save_v10230
    s = @motion_geometry_cache_stats_v10230
    s[:write_ok] = saved[0] ? 1 : 0 if saved[0]
    s[:write_ms] = saved[1].to_i
    motion_log_geometry_cache_loading_v10230
    r
  end

  def motion_log_geometry_cache_loading_v10230
    return if @motion_geometry_cache_summary_logged_v10230
    s = @motion_geometry_cache_stats_v10230 || {}
    h = PMD_AC.geometry_cache_payload_v10230
    log_event(:perf,
      'MOTION_GEOMETRY_CACHE_PRELOAD_V10230 ready=1 file='+(PMD_AC.geometry_cache_file_ok_v10230? ? '1':'0')+
      ' offline='+(PMD_AC.geometry_cache_offline_v10230? ? '1':'0')+
      ' baseline_entries='+(h[:baseline] || {}).size.to_i.to_s+
      ' anchor_entries='+(h[:anchor] || {}).size.to_i.to_s+
      ' baseline_pairs='+s[:baseline_pairs].to_i.to_s+
      ' baseline_hit='+s[:baseline_hit].to_i.to_s+
      ' baseline_missing='+s[:baseline_missing].to_i.to_s+
      ' baseline_invalid='+s[:baseline_invalid].to_i.to_s+
      ' target_pairs='+s[:target_pairs].to_i.to_s+
      ' target_hit='+s[:target_hit].to_i.to_s+
      ' target_missing='+s[:target_missing].to_i.to_s+
      ' target_invalid='+s[:target_invalid].to_i.to_s+
      ' hydrate_ms='+s[:hydrate_ms].to_i.to_s+
      ' write_ok='+s[:write_ok].to_i.to_s+' write_ms='+s[:write_ms].to_i.to_s)
    @motion_geometry_cache_summary_logged_v10230 = true
  rescue
  end

  def verify_motion_persistent_geometry_cache_v10230
    return if @motion_geometry_cache_verify_logged_v10230
    s = @motion_geometry_cache_stats_v10230 || {}
    bs = @motion_baseline_summary_v10212 || {}
    ts = @motion_target_anchor_summary_v10216 || {}
    strict = PMD_AC::GEOMETRY_CACHE_STRICT_VERIFY_V10230
    hit_ok = s[:baseline_pairs].to_i > 0 && s[:target_pairs].to_i > 0 &&
      s[:baseline_hit].to_i == s[:baseline_pairs].to_i &&
      s[:target_hit].to_i == s[:target_pairs].to_i &&
      s[:baseline_missing].to_i == 0 && s[:baseline_invalid].to_i == 0 &&
      s[:target_missing].to_i == 0 && s[:target_invalid].to_i == 0
    original_preload_zero = bs[:computed].to_i == 0 && ts[:computed].to_i == 0 &&
      bs[:fail].to_i == 0 && ts[:fail].to_i == 0
    pass = motion_geometry_cache_mode_v10230? && PMD_AC.geometry_cache_file_ok_v10230? &&
      PMD_AC.geometry_cache_offline_v10230? && original_preload_zero && (!strict || hit_ok)
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_PERSISTENT_GEOMETRY_CACHE_V10230 pass='+(pass ? '1':'0')+
      ' file='+(PMD_AC.geometry_cache_file_ok_v10230? ? '1':'0')+
      ' offline='+(PMD_AC.geometry_cache_offline_v10230? ? '1':'0')+
      ' baseline_hit='+s[:baseline_hit].to_i.to_s+'/'+s[:baseline_pairs].to_i.to_s+
      ' target_hit='+s[:target_hit].to_i.to_s+'/'+s[:target_pairs].to_i.to_s+
      ' baseline_computed='+bs[:computed].to_i.to_s+
      ' target_computed='+ts[:computed].to_i.to_s+
      ' missing='+(s[:baseline_missing].to_i+s[:target_missing].to_i).to_s+
      ' invalid='+(s[:baseline_invalid].to_i+s[:target_invalid].to_i).to_s+
      ' metadata_guard=1 file_size_guard=1 bitmap_dimension_guard=1'+
      ' formulas_unchanged=1 hp_bar_y_unchanged=1 target_anchor_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_geometry_cache_verify_logged_v10230 = true
  rescue
  end

  def update_verification_script
    pmd_ac_v10230_update_verification_script
    return unless motion_geometry_cache_mode_v10230?
    verify_motion_persistent_geometry_cache_v10230 if @verification_frame.to_i >= 78
  end

  def motion_log_target_anchor_runtime_v10216
    pmd_ac_v10230_motion_log_target_anchor_runtime_v10216
    motion_log_geometry_cache_loading_v10230 if motion_geometry_cache_mode_v10230?
  end
end
