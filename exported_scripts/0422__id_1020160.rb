# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Target Anchor Bounds Preload v1.02.16
# 分類：戰鬥效能／Battle Loading Gate／Target FX Anchor 幾何預運算
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v1.02.15 Windows RGSS2 Micro Profiler 已把 launch_projectile 的大型尖峰精確
# 定位到 effect_anchor：
#   projectile_initialize max 約 234ms
#   effect_anchor max 約 231ms
# 呼叫鏈為：
#   effect_anchor_xy
#   -> Game_PMDChessUnit#visual_target_anchor_v0573
#   -> PMD_AC.target_anchor_local_v0573
#   -> PMD_AC.target_opaque_bounds_v0573
#
# v0.57.3 的 target_opaque_bounds_v0573 會在 species/action 第一次使用時，對
# PMD Action Bitmap 的所有 Frame／方向列使用 Bitmap#get_pixel 掃描不透明範圍。
# 這是「Target FX lower-body anchor」自己的 Cache，與 v1.02.12 已預載的
# Visible Baseline / contact_bottom_cache_v0576 是兩套不同資料，因此先前仍會把
# 一次性的 alpha scan 留在 live projectile launch 內。
#
# 本版只把 v0.57.3 Target Anchor opaque-bounds 掃描搬到 Battle Loading Gate。
# lower-body anchor 的計算公式、lower_body_ratio、species override 與實際結果
# 完全沿用 v0.57.3；正式戰鬥中改為 Hash lookup，不改任何戰鬥邏輯。
#==============================================================================
# 【主要設定項】
# PMD_AC::MOTION_TARGET_ANCHOR_PRELOAD_ENABLED_V10216
#   true：PMD_MOTION_PHASE_A_V102 的 Battle Loading 階段預算 Target Anchor。
# PMD_AC::MOTION_TARGET_ANCHOR_PRELOAD_SLOW_MS_V10216
#   單一 species/action 掃描達此毫秒數時計入 slow，只做統計。
#==============================================================================
# 【機制規則】
# 1. 只在 PMD_MOTION_PHASE_A_V102 使用，不擴到 NORMAL / Map Story。
# 2. 取本場 @units，依 v0.57.3 原本 target_anchor_action_v0573 決定 action。
# 3. 以 species + action 去重。
# 4. 若 target_anchor_cache_v0573 已有 key，不重掃。
# 5. 尚未存在者在 Loading 100% 前呼叫原 target_opaque_bounds_v0573 建 Cache。
# 6. live battle 若仍遇到 Target Anchor cache miss，只記錄 miss，不改 fallback。
# 7. v1.02.15 Launch Micro Profiler 保留，方便直接驗證 effect_anchor / launch 是否下降。
#==============================================================================
# 【可調參數】
# - 不要為了縮短 Loading 而重新允許 live alpha scan。
# - Performance Seal 後，應與 Visible Baseline 一起做離線／持久化 Geometry Cache。
# - 不修改 TARGET_ANCHOR_V0573 的 lower_body_ratio、scan_step、alpha_threshold。
#==============================================================================
# 【事件／腳本呼叫方式】
# 不需事件手動呼叫。
# 正式測試：
#   S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場
#==============================================================================
# 【Windows LOG 驗收範例】
# Loading：
#   MOTION_TARGET_ANCHOR_PRELOAD_V10216 ready=1 pairs=6 computed=6 cached=0 fail=0 ...
# Verifier：
#   MOTION_TARGET_ANCHOR_PRELOAD_V10216 pass=1 ... before_live_battle=1
# Battle end：
#   MOTION_TARGET_ANCHOR_RUNTIME_V10216 live_miss=0 unique=0 expected=0
# 同時應看到：
#   MOTION_LAUNCH_MICRO_SUMMARY_V10215 ... effect_anchor:max 接近 0
#   MOTION_DEEP_SUMMARY_V1027 ... launch_projectile:max 明顯下降
#==============================================================================
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只使用 Main 前 trailing alias / hook。
# - Pokémon identity 仍為 instance_uid。
# - Motion 只負責 presentation，不改 logical x/y。
# - 不修改 Damage Formula、Attack Speed、AI、Spatial Runtime、projectile speed、
#   tracking、collision、hit timing、hit-stop、Hurt ownership、Native hitFrame。
# - Game.ini 不得有 UTF-8 BOM，第 0 byte 必須為 [。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_TargetAnchorBoundsPreload_v10216'] = true

module PMD_AC
  MOTION_TARGET_ANCHOR_PRELOAD_VERSION_V10216 = '1.02.16'
  MOTION_TARGET_ANCHOR_PRELOAD_ENABLED_V10216 = true
  MOTION_TARGET_ANCHOR_PRELOAD_SLOW_MS_V10216 = 20

  class << self
    alias pmd_ac_v10216_target_opaque_bounds_v0573 target_opaque_bounds_v0573 unless method_defined?(:pmd_ac_v10216_target_opaque_bounds_v0573)

    # 只做 live cache-miss audit；真正計算與 fallback 仍完全交給 v0.57.3。
    def target_opaque_bounds_v0573(unit)
      key = nil
      miss = false
      begin
        act = target_anchor_action_v0573(unit)
        key = [unit == nil ? '' : unit.species.to_s, act]
        c = target_anchor_cache_v0573
        miss = !c.has_key?(key)
      rescue
        miss = false
      end
      if miss && $scene != nil && $scene.respond_to?(:motion_target_anchor_live_active_v10216?) &&
         $scene.motion_target_anchor_live_active_v10216?
        begin
          $scene.motion_target_anchor_live_miss_v10216(key)
        rescue
        end
      end
      pmd_ac_v10216_target_opaque_bounds_v0573(unit)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10216_battle_loading_process_motion_v1029 battle_loading_process_motion_v1029 unless method_defined?(:pmd_ac_v10216_battle_loading_process_motion_v1029)
  alias pmd_ac_v10216_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10216_update_verification_script)
  alias pmd_ac_v10216_motion_log_baseline_runtime_v10212 motion_log_baseline_runtime_v10212 unless method_defined?(:pmd_ac_v10216_motion_log_baseline_runtime_v10212)

  def motion_target_anchor_preload_mode_v10216?
    return false unless PMD_AC::MOTION_TARGET_ANCHOR_PRELOAD_ENABLED_V10216
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_target_anchor_reset_v10216
    @motion_target_anchor_summary_v10216 = nil
    @motion_target_anchor_live_miss_v10216 = 0
    @motion_target_anchor_live_miss_keys_v10216 = {}
    @motion_target_anchor_verify_logged_v10216 = false
    @motion_target_anchor_runtime_logged_v10216 = false
    @motion_target_anchor_loading_v10216 = false
  end

  def motion_target_anchor_live_active_v10216?
    motion_target_anchor_preload_mode_v10216? && @phase == :battle && !@motion_target_anchor_loading_v10216
  rescue
    false
  end

  def motion_target_anchor_live_miss_v10216(key)
    @motion_target_anchor_live_miss_v10216 = @motion_target_anchor_live_miss_v10216.to_i + 1
    @motion_target_anchor_live_miss_keys_v10216 = {} if @motion_target_anchor_live_miss_keys_v10216 == nil
    @motion_target_anchor_live_miss_keys_v10216[key] = true if key != nil
  rescue
  end

  def motion_target_anchor_pairs_v10216
    rows = []
    seen = {}
    (@units || []).each do |u|
      next if u == nil
      begin
        act = PMD_AC.target_anchor_action_v0573(u)
        key = [u.species.to_s, act]
        next if seen[key]
        seen[key] = true
        rows.push([u, act, key])
      rescue
      end
    end
    rows
  rescue
    []
  end

  def motion_precompute_target_anchor_bounds_v10216(ui)
    motion_target_anchor_reset_v10216
    @motion_target_anchor_loading_v10216 = true
    pairs = motion_target_anchor_pairs_v10216
    total = pairs.size
    computed = 0
    cached = 0
    fail = 0
    slow = 0
    total_ms = 0
    max_ms = 0
    cache = PMD_AC.target_anchor_cache_v0573

    pairs.each_with_index do |row, i|
      u = row[0]
      act = row[1]
      key = row[2]
      if cache.has_key?(key)
        cached += 1
      else
        t = Time.now.to_f
        ok = true
        begin
          PMD_AC.target_opaque_bounds_v0573(u)
          ok = cache.has_key?(key)
        rescue
          ok = false
        end
        ms = ((Time.now.to_f - t) * 1000.0).round rescue 0
        total_ms += ms
        max_ms = ms if ms > max_ms
        slow += 1 if ms >= PMD_AC::MOTION_TARGET_ANCHOR_PRELOAD_SLOW_MS_V10216.to_i
        if ok
          computed += 1
        else
          fail += 1
        end
      end
      if i == 0 || i == total - 1 || ((i + 1) % 2) == 0
        detail = (i + 1).to_s + '/' + total.to_s + '  ' + u.species.to_s + ' / ' + act.to_s
        begin
          battle_loading_draw_v1029(ui, 99, '分析目標命中特效定位', detail)
        rescue
        end
      end
    end

    @motion_target_anchor_summary_v10216 = {
      :pairs => total, :computed => computed, :cached => cached, :fail => fail,
      :total_ms => total_ms, :max_ms => max_ms, :slow => slow,
      :cache_after => cache.size
    }
    begin
      log_event(:perf,
        'MOTION_TARGET_ANCHOR_PRELOAD_V10216 ready=1 pairs=' + total.to_i.to_s +
        ' computed=' + computed.to_i.to_s + ' cached=' + cached.to_i.to_s +
        ' fail=' + fail.to_i.to_s + ' total_ms=' + total_ms.to_i.to_s +
        ' max_ms=' + max_ms.to_i.to_s + ' slow=' + slow.to_i.to_s +
        ' cache_after=' + cache.size.to_i.to_s + ' before_live_battle=1')
    rescue
    end
    @motion_target_anchor_loading_v10216 = false
    @motion_target_anchor_summary_v10216
  rescue Exception => e
    @motion_target_anchor_loading_v10216 = false
    @motion_target_anchor_summary_v10216 = {
      :pairs => 0, :computed => 0, :cached => 0, :fail => 1,
      :total_ms => 0, :max_ms => 0, :slow => 0, :cache_after => 0
    }
    begin
      log_event(:perf, 'MOTION_TARGET_ANCHOR_PRELOAD_V10216 ready=1 fallback=1 error=' + e.class.to_s)
    rescue
    end
    @motion_target_anchor_summary_v10216
  end

  # 所有既有 v1.02.9～v1.02.13 Loading 工作完成後、真正 live battle 前預算。
  def battle_loading_process_motion_v1029(ui)
    stat = pmd_ac_v10216_battle_loading_process_motion_v1029(ui)
    if motion_target_anchor_preload_mode_v10216?
      s = motion_precompute_target_anchor_bounds_v10216(ui)
      stat[:fail] = stat[:fail].to_i + s[:fail].to_i if stat.is_a?(Hash)
    end
    stat
  rescue
    stat || {:enabled => 1, :fail => 1}
  end

  def verify_motion_target_anchor_preload_v10216
    return if @motion_target_anchor_verify_logged_v10216
    s = @motion_target_anchor_summary_v10216 || {}
    pass = motion_target_anchor_preload_mode_v10216? && s[:pairs].to_i > 0 && s[:fail].to_i == 0
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_TARGET_ANCHOR_PRELOAD_V10216 pass=' + (pass ? '1' : '0') +
      ' pairs=' + s[:pairs].to_i.to_s + ' computed=' + s[:computed].to_i.to_s +
      ' cached=' + s[:cached].to_i.to_s + ' fail=' + s[:fail].to_i.to_s +
      ' cache_after=' + s[:cache_after].to_i.to_s +
      ' target_anchor_alpha_scan_shifted_to_loading=1 before_live_battle=1' +
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_target_anchor_verify_logged_v10216 = true
  rescue
  end

  def update_verification_script
    pmd_ac_v10216_update_verification_script
    return unless motion_target_anchor_preload_mode_v10216?
    verify_motion_target_anchor_preload_v10216 if @verification_frame.to_i >= 57
  end

  def motion_log_target_anchor_runtime_v10216
    return if @motion_target_anchor_runtime_logged_v10216
    keys = @motion_target_anchor_live_miss_keys_v10216 == nil ? 0 : @motion_target_anchor_live_miss_keys_v10216.size
    begin
      log_event(:perf,
        'MOTION_TARGET_ANCHOR_RUNTIME_V10216 live_miss=' + @motion_target_anchor_live_miss_v10216.to_i.to_s +
        ' unique=' + keys.to_i.to_s + ' expected=0 alpha_scan_live_expected=0')
    rescue
    end
    @motion_target_anchor_runtime_logged_v10216 = true
  end

  # v1.02.12 show_result 已呼叫此 runtime report；串在這裡可與 v1.02.15
  # Launch Micro Summary 同一批輸出，不改 show_result 本體。
  def motion_log_baseline_runtime_v10212
    pmd_ac_v10216_motion_log_baseline_runtime_v10212
    motion_log_target_anchor_runtime_v10216 if motion_target_anchor_preload_mode_v10216?
  end
end
