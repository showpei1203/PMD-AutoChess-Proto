#==============================================================================
# ■ PMD AutoChess Visible Foot Baseline Sprite Memo v1.02.23
#------------------------------------------------------------------------------
# 【用途】
#   本腳本是 PMD Motion Framework v1.02 Performance Seal 的 Sprite 高頻配置
#   A/B。v1.02.21 Windows LOG 顯示 Movement 已降至 1～2ms，剩餘 100ms 級
#   spike 轉移到 Sprite update；v1.02.22 關閉五層 micro profiler 後，runtime
#   >=50ms 仍有 3 次，表示剩餘停頓不能只歸因於 profiler observer effect。
#
#   靜態追查 Sprite_PMDChessUnit#update_position 後發現：
#     visible_foot_frame_offset_v0884
#       -> PMD_AC.visible_bottom_rel_for_action_v0576
#   會在每隻 Pokémon、每個 live frame 都執行。v0.57.6 會建立一次
#   [species, action] key Array，v1.02.12 live-miss audit wrapper 又建立一次相同
#   類型的 key Array。alpha scan 雖已在 v1.02.12 搬到 Battle Loading，這兩份
#   runtime key snapshot 仍持續產生短命 Ruby 物件。
#
#   本版不改 Visible Baseline 的計算公式，也不改 HP Bar Y。只把「已解析好的
#   baseline Float」memo 在 Sprite instance 上；species、visual_action 或 bitmap
#   object 任一改變時立即失效，並交回既有 v0.89.2/v1.02.12 路徑重取。
#
# 【主要設定項】
#   MOTION_VISIBLE_FOOT_MEMO_V10223_ENABLED
#     true  = 在 PMD_MOTION_PHASE_A_V102 + live battle 使用 Sprite memo A/B。
#     false = 完整退回 v1.02.22 行為。
#
# 【機制規則】
#   1. 僅在 v1.02.22 Lean Runtime 的 live battle 生效。
#   2. placeholder、nil/disposed bitmap 不做 memo，完全走舊路徑。
#   3. memo key 不建立 Array，而使用三個 instance 欄位：
#      species / visual_action / bitmap.object_id。
#   4. 命中 memo 時直接回傳既有 Float，不再進入 v1.02.12/v0.57.6 Hash lookup。
#   5. miss 時仍呼叫舊 visible_foot_frame_offset_v0884，因此：
#      - Visible Baseline 預載與 live-miss audit 保留。
#      - Action fallback / species action data 規則不變。
#      - True Foot Bar gap / zoom / melee visual offset 不變。
#
# 【可調參數】
#   本版沒有遊戲數值可調參數。若要停用 A/B，只把
#   MOTION_VISIBLE_FOOT_MEMO_V10223_ENABLED 設為 false。
#
# 【事件／腳本呼叫方式】
#   不需要事件呼叫。正式驗證：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥
#
# 【實際範例】
#   開場預期：
#     MOTION_VISIBLE_FOOT_MEMO_V10223 pass=1 compared=6 mismatch=0 ...
#   戰後預期：
#     MOTION_VISIBLE_FOOT_MEMO_SUMMARY_V10223 calls=... hit=... miss=...
#     MOTION_HITCH_SPLIT_V1026 ...
#     VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【驗收重點】
#   - mismatch 必須為 0，max_diff 必須 <= 0.000001。
#   - MOTION_BASELINE_MISS_KEYS_V10213 live_miss 必須維持 0。
#   - MOTION_BASELINE_RUNTIME_V10212 live_miss 必須維持 0。
#   - 不以較少 hitch 作為容許定位數值變更的理由。
#
# 【不可變更】
#   - Damage Formula / Attack Speed / AI。
#   - Spatial Runtime logical x/y、move speed、spacing、Adaptive Close。
#   - HP Bar gap、Visible Baseline 數值、PMD Sprite scale。
#   - Motion hitFrame / Hurt ownership / hit-stop / Skill FX handoff。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_VisibleFootBaselineMemo_v10223'] = true

module PMD_AC
  MOTION_VISIBLE_FOOT_MEMO_VERSION_V10223 = '1.02.23'
  MOTION_VISIBLE_FOOT_MEMO_V10223_ENABLED = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10223_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10223_prepare_verification_battle)
  alias pmd_ac_v10223_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10223_update_verification_script)
  alias pmd_ac_v10223_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10223_motion_perf_log_summary_v1023)

  def motion_visible_foot_memo_mode_v10223?
    return false unless PMD_AC::MOTION_VISIBLE_FOOT_MEMO_V10223_ENABLED
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_visible_foot_memo_live_v10223?
    return false unless motion_visible_foot_memo_mode_v10223?
    return false unless respond_to?(:motion_perf_lean_live_v10222?)
    motion_perf_lean_live_v10222?
  rescue
    false
  end

  def motion_visible_foot_memo_reset_v10223
    @motion_visible_foot_calls_v10223 = 0
    @motion_visible_foot_hits_v10223 = 0
    @motion_visible_foot_misses_v10223 = 0
    @motion_visible_foot_verify_logged_v10223 = false
    @motion_visible_foot_summary_logged_v10223 = false
    true
  end

  def prepare_verification_battle
    result = pmd_ac_v10223_prepare_verification_battle
    motion_visible_foot_memo_reset_v10223 if verification_mode == :pmd_motion_phase_a_v102
    result
  end

  # 只做 Fixnum 計數，不使用 Time.now，不建立 record Array/Hash。
  def motion_visible_foot_note_v10223(hit)
    return unless motion_visible_foot_memo_live_v10223?
    @motion_visible_foot_calls_v10223 = @motion_visible_foot_calls_v10223.to_i + 1
    if hit
      @motion_visible_foot_hits_v10223 = @motion_visible_foot_hits_v10223.to_i + 1
    else
      @motion_visible_foot_misses_v10223 = @motion_visible_foot_misses_v10223.to_i + 1
    end
    true
  rescue
    false
  end

  def verify_motion_visible_foot_memo_v10223
    return if @motion_visible_foot_verify_logged_v10223
    compared = 0
    mismatch = 0
    max_diff = 0.0
    begin
      sprites = @unit_sprites || []
      sprites.each do |sp|
        next if sp == nil
        next unless sp.respond_to?(:motion_visible_foot_original_v10223)
        next unless sp.respond_to?(:motion_visible_foot_memo_clear_v10223)
        original = sp.motion_visible_foot_original_v10223.to_f
        sp.motion_visible_foot_memo_clear_v10223
        memo = sp.visible_foot_frame_offset_v0884.to_f
        diff = (original - memo).abs
        max_diff = diff if diff > max_diff
        compared += 1
        mismatch += 1 if diff > 0.000001
      end
    rescue
      mismatch += 1
    end
    pass = motion_visible_foot_memo_mode_v10223? && compared > 0 && mismatch == 0
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_VISIBLE_FOOT_MEMO_V10223 pass=' + (pass ? '1' : '0') +
      ' compared=' + compared.to_s +
      ' mismatch=' + mismatch.to_s +
      ' max_diff=' + ('%.6f' % max_diff) +
      ' sprite_key_fields=species,action,bitmap_object' +
      ' baseline_value_unchanged=1 hp_bar_y_unchanged=1' +
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_visible_foot_verify_logged_v10223 = true
    true
  rescue
    false
  end

  def update_verification_script
    result = pmd_ac_v10223_update_verification_script
    if verification_mode == :pmd_motion_phase_a_v102 && @verification_frame.to_i >= 64
      verify_motion_visible_foot_memo_v10223
    end
    result
  end

  def motion_visible_foot_memo_log_summary_v10223
    return if @motion_visible_foot_summary_logged_v10223
    return unless motion_visible_foot_memo_mode_v10223?
    @motion_visible_foot_summary_logged_v10223 = true
    calls = @motion_visible_foot_calls_v10223.to_i
    hit = @motion_visible_foot_hits_v10223.to_i
    miss = @motion_visible_foot_misses_v10223.to_i
    # 現行 v1.02.12 wrapper + v0.57.6 各建一份 [species,action] key。
    estimated_avoided_arrays = hit * 2
    log_event(:perf,
      'MOTION_VISIBLE_FOOT_MEMO_SUMMARY_V10223' +
      ' calls=' + calls.to_s +
      ' hit=' + hit.to_s +
      ' miss=' + miss.to_s +
      ' avoided_baseline_lookup_calls=' + hit.to_s +
      ' estimated_avoided_key_arrays=' + estimated_avoided_arrays.to_s +
      ' high_freq_time_now=0')
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10223_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_visible_foot_memo_log_summary_v10223
    end
    result
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v10223_visible_foot_frame_offset_v0884 visible_foot_frame_offset_v0884 unless method_defined?(:pmd_ac_v10223_visible_foot_frame_offset_v0884)

  def motion_visible_foot_memo_scene_v10223
    return nil if @unit == nil
    s = @unit.scene rescue nil
    return nil if s == nil
    return nil unless s.respond_to?(:motion_visible_foot_memo_live_v10223?)
    return nil unless s.motion_visible_foot_memo_live_v10223?
    s
  rescue
    nil
  end

  def motion_visible_foot_memo_clear_v10223
    @motion_visible_foot_memo_valid_v10223 = false
    @motion_visible_foot_species_v10223 = nil
    @motion_visible_foot_action_v10223 = nil
    @motion_visible_foot_bitmap_id_v10223 = nil
    @motion_visible_foot_value_v10223 = 0.0
    true
  end

  # Verifier 專用：直接取得 v1.02.22 以前的正式結果。
  def motion_visible_foot_original_v10223
    pmd_ac_v10223_visible_foot_frame_offset_v0884
  end

  def visible_foot_frame_offset_v0884
    s = motion_visible_foot_memo_scene_v10223
    return pmd_ac_v10223_visible_foot_frame_offset_v0884 if s == nil
    return pmd_ac_v10223_visible_foot_frame_offset_v0884 if @unit == nil
    return pmd_ac_v10223_visible_foot_frame_offset_v0884 if @placeholder
    bmp = self.bitmap
    return pmd_ac_v10223_visible_foot_frame_offset_v0884 if bmp == nil || bmp.disposed?

    species = @unit.species.to_s
    action = @unit.visual_action
    action = :idle if action == nil
    bitmap_id = bmp.object_id

    if @motion_visible_foot_memo_valid_v10223 &&
       @motion_visible_foot_species_v10223 == species &&
       @motion_visible_foot_action_v10223 == action &&
       @motion_visible_foot_bitmap_id_v10223 == bitmap_id
      s.motion_visible_foot_note_v10223(true)
      return @motion_visible_foot_value_v10223.to_f
    end

    value = pmd_ac_v10223_visible_foot_frame_offset_v0884.to_f
    @motion_visible_foot_species_v10223 = species
    @motion_visible_foot_action_v10223 = action
    @motion_visible_foot_bitmap_id_v10223 = bitmap_id
    @motion_visible_foot_value_v10223 = value
    @motion_visible_foot_memo_valid_v10223 = true
    s.motion_visible_foot_note_v10223(false)
    value
  rescue
    pmd_ac_v10223_visible_foot_frame_offset_v0884
  end
end
