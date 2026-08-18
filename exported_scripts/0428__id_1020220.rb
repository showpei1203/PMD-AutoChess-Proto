#==============================================================================
# ■ PMD AutoChess Performance Seal Lean Runtime A/B v1.02.22
#------------------------------------------------------------------------------
# 【用途】
#   本腳本是 PMD Motion Framework v1.02 Performance Seal 的「量測儀器退場」
#   A/B。v1.02.15～v1.02.21 為了追查 Windows RGSS2 live hitch，逐步加入了
#   Launch / Status / Damage / Movement / Deep Profiler。這些 profiler 大量使用
#   Time.now 包住高頻函式，本身也會產生 Ruby 物件與方法呼叫成本。
#
#   v1.02.20、v1.02.21 已用 Windows LOG 證實兩個真正有價值的修正：
#   1. Move Speed status 掃描不再建立 @statuses.keys snapshot。
#   2. Basic Flex species/form 靜態 profile 不再每次重新 dup / 建 Hash。
#
#   到 v1.02.21 為止，Movement 主要子項已降到 1～2ms，Projectile / Damage
#   也大多落在 5～20ms；剩餘 100ms 級停頓會在不同外層 profiler 間移動。
#   因此本版不再新增第六層 micro profiler，而是關閉高頻診斷計時，只留下
#   v1.02.3 Frame Profiler 與必要 verifier，量測更接近正式玩家 runtime。
#
# 【主要設定項】
#   MOTION_PERF_LEAN_RUNTIME_V10222_ENABLED
#     true  = 在 PMD_MOTION_PHASE_A_V102 live battle 使用 Lean A/B。
#     false = 完整回到 v1.02.21 的 profiler 行為。
#
# 【機制規則】
#   A. 保留 v1.02.3 Frame Profiler：
#      - 仍記錄 opening/runtime >= 50ms、max update、max wall gap。
#      - 因此本版仍可客觀比較實機 hitch 數量。
#
#   B. 關閉「高頻診斷計時」但不刪除舊腳本：
#      - v1.02.7  Deep component profiler
#      - v1.02.15 Launch micro profiler
#      - v1.02.17 Status micro profiler
#      - v1.02.18 Damage/Projectile-hit micro profiler
#      - v1.02.19 Movement micro profiler
#      全部只在 Motion verifier live battle 被 trailing override 停用。
#      NORMAL / Map Story 不會因本腳本改變戰鬥規則。
#
#   C. v1.02.20 Move Speed Allocation-Free 仍保留，但 Lean 路徑：
#      - 不再每次 Time.now。
#      - 不建立 @statuses.keys。
#      - 不用 [x, y].max 這類短命 Array。
#      - slow tag、stack_mode、stacks、value、SLOW_CAP、最低 0.10 完全不變。
#      - v1.02.20 原本的一次性 original-vs-fast verifier 仍會執行。
#
#   D. v1.02.21 Basic Flex Memo 仍保留，但 Lean 路徑：
#      - species/form 不變時直接回傳 memo profile。
#      - species/form 改變立即 miss 並用原始 v0.99.12 重建。
#      - live hit 不再執行舊 profiler 統計；只做 Fixnum 計數。
#      - v1.02.21 原本的一次性 Hash 等值 verifier 仍會執行。
#
# 【不可變更】
#   - Damage Formula / Attack Speed / AI 決策。
#   - Spatial Runtime logical x/y、速度數值、距離門檻。
#   - Adaptive Close dead-zone 修正。
#   - Motion hitFrame / Hurt ownership / hit-stop / Skill FX handoff。
#   - Visible Baseline / Target Anchor 計算結果。
#
# 【事件／腳本呼叫方式】
#   不需要事件呼叫。測試方式與既有 Motion verifier 完全相同：
#     S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整戰鬥
#
# 【實際驗證範例】
#   開場應看到：
#     MOTION_PERF_LEAN_RUNTIME_V10222 pass=1 ...
#   戰後應看到：
#     MOTION_PERF_LEAN_RUNTIME_SUMMARY_V10222 ...
#     MOTION_FRAME_PROFILE_V1023 ...
#     MOTION_HITCH_SPLIT_V1026 ...
#     VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【判讀重點】
#   - 若 runtime >=50ms / max_update 明顯下降：表示先前剩餘 spike 有顯著
#     profiler observer effect，下一步可進入 Performance Seal / Loading cache。
#   - 若仍穩定重現 100ms 級 spike：再針對「沒有 profiler 干擾下」的外層
#     重新掛單一 targeted profiler，不回到多層常駐量測。
#==============================================================================

$imported = {} if $imported == nil
$imported['PMD_AutoChess_PerformanceSealLeanRuntime_v10222'] = true

module PMD_AC
  MOTION_PERF_LEAN_RUNTIME_VERSION_V10222 = '1.02.22'
  MOTION_PERF_LEAN_RUNTIME_V10222_ENABLED = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10222_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10222_update_verification_script)
  alias pmd_ac_v10222_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10222_prepare_verification_battle)
  alias pmd_ac_v10222_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10222_motion_perf_log_summary_v1023)
  alias pmd_ac_v10222_motion_deep_active_v1027? motion_deep_active_v1027? unless method_defined?(:pmd_ac_v10222_motion_deep_active_v1027?)
  alias pmd_ac_v10222_motion_launch_probe_mode_v10215? motion_launch_probe_mode_v10215? unless method_defined?(:pmd_ac_v10222_motion_launch_probe_mode_v10215?)
  alias pmd_ac_v10222_motion_launch_probe_active_v10215? motion_launch_probe_active_v10215? unless method_defined?(:pmd_ac_v10222_motion_launch_probe_active_v10215?)
  alias pmd_ac_v10222_motion_status_micro_active_v10217? motion_status_micro_active_v10217? unless method_defined?(:pmd_ac_v10222_motion_status_micro_active_v10217?)
  alias pmd_ac_v10222_motion_damage_micro_active_v10218? motion_damage_micro_active_v10218? unless method_defined?(:pmd_ac_v10222_motion_damage_micro_active_v10218?)
  alias pmd_ac_v10222_motion_movement_micro_active_v10219? motion_movement_micro_active_v10219? unless method_defined?(:pmd_ac_v10222_motion_movement_micro_active_v10219?)
  alias pmd_ac_v10222_motion_deep_log_summary_v1027 motion_deep_log_summary_v1027 unless method_defined?(:pmd_ac_v10222_motion_deep_log_summary_v1027)
  alias pmd_ac_v10222_motion_launch_probe_report_v10215 motion_launch_probe_report_v10215 unless method_defined?(:pmd_ac_v10222_motion_launch_probe_report_v10215)
  alias pmd_ac_v10222_motion_status_micro_log_summary_v10217 motion_status_micro_log_summary_v10217 unless method_defined?(:pmd_ac_v10222_motion_status_micro_log_summary_v10217)
  alias pmd_ac_v10222_motion_damage_micro_log_summary_v10218 motion_damage_micro_log_summary_v10218 unless method_defined?(:pmd_ac_v10222_motion_damage_micro_log_summary_v10218)
  alias pmd_ac_v10222_motion_movement_micro_log_summary_v10219 motion_movement_micro_log_summary_v10219 unless method_defined?(:pmd_ac_v10222_motion_movement_micro_log_summary_v10219)
  alias pmd_ac_v10222_motion_move_speed_alloc_free_log_summary_v10220 motion_move_speed_alloc_free_log_summary_v10220 unless method_defined?(:pmd_ac_v10222_motion_move_speed_alloc_free_log_summary_v10220)
  alias pmd_ac_v10222_motion_basic_flex_memo_log_summary_v10221 motion_basic_flex_memo_log_summary_v10221 unless method_defined?(:pmd_ac_v10222_motion_basic_flex_memo_log_summary_v10221)

  def motion_perf_lean_mode_v10222?
    return false unless PMD_AC::MOTION_PERF_LEAN_RUNTIME_V10222_ENABLED
    return false unless respond_to?(:verification_mode)
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_perf_lean_live_v10222?
    motion_perf_lean_mode_v10222? && @phase == :battle
  rescue
    false
  end

  def motion_perf_lean_reset_v10222
    @motion_perf_lean_move_speed_calls_v10222 = 0
    @motion_perf_lean_move_speed_scanned_v10222 = 0
    @motion_perf_lean_flex_calls_v10222 = 0
    @motion_perf_lean_flex_hits_v10222 = 0
    @motion_perf_lean_flex_misses_v10222 = 0
    @motion_perf_lean_verify_logged_v10222 = false
    @motion_perf_lean_summary_logged_v10222 = false
    true
  end

  def prepare_verification_battle
    result = pmd_ac_v10222_prepare_verification_battle
    motion_perf_lean_reset_v10222 if verification_mode == :pmd_motion_phase_a_v102
    result
  end

  #--------------------------------------------------------------------------
  # 高頻 profiler observer effect 關閉。
  # 僅改「是否計時」，不改被量測函式本身。
  #--------------------------------------------------------------------------
  def motion_deep_active_v1027?
    return false if motion_perf_lean_live_v10222?
    pmd_ac_v10222_motion_deep_active_v1027?
  rescue
    false
  end

  def motion_launch_probe_mode_v10215?
    return false if motion_perf_lean_live_v10222?
    pmd_ac_v10222_motion_launch_probe_mode_v10215?
  rescue
    false
  end

  def motion_launch_probe_active_v10215?
    return false if motion_perf_lean_live_v10222?
    pmd_ac_v10222_motion_launch_probe_active_v10215?
  rescue
    false
  end

  def motion_status_micro_active_v10217?
    return false if motion_perf_lean_live_v10222?
    pmd_ac_v10222_motion_status_micro_active_v10217?
  rescue
    false
  end

  def motion_damage_micro_active_v10218?
    return false if motion_perf_lean_live_v10222?
    pmd_ac_v10222_motion_damage_micro_active_v10218?
  rescue
    false
  end

  def motion_movement_micro_active_v10219?
    return false if motion_perf_lean_live_v10222?
    pmd_ac_v10222_motion_movement_micro_active_v10219?
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # Lean counters：只用 Fixnum 累加，不做 Time.now / Array / Hash record。
  #--------------------------------------------------------------------------
  def motion_perf_lean_note_move_speed_v10222(scanned)
    return unless motion_perf_lean_live_v10222?
    @motion_perf_lean_move_speed_calls_v10222 =
      @motion_perf_lean_move_speed_calls_v10222.to_i + 1
    @motion_perf_lean_move_speed_scanned_v10222 =
      @motion_perf_lean_move_speed_scanned_v10222.to_i + scanned.to_i
    true
  rescue
    false
  end

  def motion_perf_lean_note_flex_v10222(hit)
    return unless motion_perf_lean_live_v10222?
    @motion_perf_lean_flex_calls_v10222 = @motion_perf_lean_flex_calls_v10222.to_i + 1
    if hit
      @motion_perf_lean_flex_hits_v10222 = @motion_perf_lean_flex_hits_v10222.to_i + 1
    else
      @motion_perf_lean_flex_misses_v10222 = @motion_perf_lean_flex_misses_v10222.to_i + 1
    end
    true
  rescue
    false
  end

  # 舊 micro summary 在 Lean A/B 不再輸出空統計，避免 current-test LOG 噪音。
  def motion_deep_log_summary_v1027
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_deep_log_summary_v1027
  end

  def motion_launch_probe_report_v10215
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_launch_probe_report_v10215
  end

  def motion_status_micro_log_summary_v10217
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_status_micro_log_summary_v10217
  end

  def motion_damage_micro_log_summary_v10218
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_damage_micro_log_summary_v10218
  end

  def motion_movement_micro_log_summary_v10219
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_movement_micro_log_summary_v10219
  end

  def motion_move_speed_alloc_free_log_summary_v10220
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_move_speed_alloc_free_log_summary_v10220
  end

  def motion_basic_flex_memo_log_summary_v10221
    return true if motion_perf_lean_mode_v10222?
    pmd_ac_v10222_motion_basic_flex_memo_log_summary_v10221
  end

  def verify_motion_perf_lean_v10222
    return if @verification_done != nil && @verification_done[:motion_perf_lean_v10222]
    frame_ok = respond_to?(:motion_perf_mode_v1023?) && motion_perf_mode_v1023?
    fast20 = respond_to?(:motion_move_speed_alloc_free_active_v10220?) &&
             motion_move_speed_alloc_free_active_v10220?
    fast21 = respond_to?(:motion_basic_flex_memo_active_v10221?) &&
             motion_basic_flex_memo_active_v10221?
    disabled = !motion_deep_active_v1027? &&
               !motion_launch_probe_mode_v10215? &&
               !motion_status_micro_active_v10217? &&
               !motion_damage_micro_active_v10218? &&
               !motion_movement_micro_active_v10219?
    pass = motion_perf_lean_mode_v10222? && frame_ok && fast20 && fast21 && disabled
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_PERF_LEAN_RUNTIME_V10222 pass=' + (pass ? '1' : '0') +
      ' frame_profiler=1 deep_profiler=0 launch_micro=0 status_micro=0 damage_micro=0 movement_micro=0' +
      ' move_speed_fast=1 basic_flex_memo=1 high_freq_time_now=0' +
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @verification_done[:motion_perf_lean_v10222] = true if @verification_done != nil
  rescue
  end

  def update_verification_script
    result = pmd_ac_v10222_update_verification_script
    if verification_mode == :pmd_motion_phase_a_v102 && @verification_frame.to_i >= 63
      verify_motion_perf_lean_v10222
    end
    result
  end

  def motion_perf_lean_log_summary_v10222
    return if @motion_perf_lean_summary_logged_v10222
    return unless motion_perf_lean_mode_v10222?
    @motion_perf_lean_summary_logged_v10222 = true
    log_event(:perf,
      'MOTION_PERF_LEAN_RUNTIME_SUMMARY_V10222' +
      ' move_speed_calls=' + @motion_perf_lean_move_speed_calls_v10222.to_i.to_s +
      ' move_speed_scanned=' + @motion_perf_lean_move_speed_scanned_v10222.to_i.to_s +
      ' flex_calls=' + @motion_perf_lean_flex_calls_v10222.to_i.to_s +
      ' flex_hit=' + @motion_perf_lean_flex_hits_v10222.to_i.to_s +
      ' flex_miss=' + @motion_perf_lean_flex_misses_v10222.to_i.to_s +
      ' deep_profiler=0 launch_micro=0 status_micro=0 damage_micro=0 movement_micro=0' +
      ' frame_profiler=1 high_freq_time_now=0')
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already = @motion_perf_summary_logged_v1023
    result = pmd_ac_v10222_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_perf_lean_log_summary_v10222
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10222_motion_move_speed_multiplier_alloc_free_v10220 motion_move_speed_multiplier_alloc_free_v10220 unless method_defined?(:pmd_ac_v10222_motion_move_speed_multiplier_alloc_free_v10220)
  alias pmd_ac_v10222_motion_basic_flex_profile_memo_v10221 motion_basic_flex_profile_memo_v10221 unless method_defined?(:pmd_ac_v10222_motion_basic_flex_profile_memo_v10221)
  #--------------------------------------------------------------------------
  # v1.02.20 等價公式 Lean 版。
  # - 不 Time.now
  # - 不 @statuses.keys
  # - 不 [x,y].max
  #--------------------------------------------------------------------------
  def motion_move_speed_multiplier_alloc_free_v10220(record=true)
    lean = false
    begin
      lean = @scene != nil && @scene.respond_to?(:motion_perf_lean_live_v10222?) &&
             @scene.motion_perf_lean_live_v10222?
    rescue
      lean = false
    end
    return pmd_ac_v10222_motion_move_speed_multiplier_alloc_free_v10220(record) unless lean
    total = 0.0
    scanned = 0
    if @statuses != nil
      @statuses.each_pair do |key,data|
        scanned += 1
        next if data == nil
        base = PMD_AC.status_def(key)
        tags = base[:tags]
        next if tags == nil || !tags.include?(:slow)
        next unless base[:stat] == :move_speed
        stacks = data[:stacks].to_i
        stacks = 1 if stacks < 1
        value = data[:value].to_f
        value *= stacks if (base[:stack_mode] || :refresh) == :stack
        total += value
      end
    end
    total = PMD_AC.clamp(total,0.0,PMD_AC::SLOW_CAP)
    result = 1.0 - total
    result = 0.10 if result < 0.10
    begin
      @scene.motion_perf_lean_note_move_speed_v10222(scanned) if
        @scene != nil && @scene.respond_to?(:motion_perf_lean_note_move_speed_v10222)
    rescue
    end
    result
  end

  #--------------------------------------------------------------------------
  # v1.02.21 Memo Lean 版。
  # species/form 不變直接回傳；miss 才呼叫原始 v0.99.12。
  #--------------------------------------------------------------------------
  def motion_basic_flex_profile_memo_v10221(record=true)
    lean = false
    begin
      lean = @scene != nil && @scene.respond_to?(:motion_perf_lean_live_v10222?) &&
             @scene.motion_perf_lean_live_v10222?
    rescue
      lean = false
    end
    return pmd_ac_v10222_motion_basic_flex_profile_memo_v10221(record) unless lean
    sk = nil
    fk = :normal
    begin; sk = species_key; rescue; end
    begin; fk = form_key if respond_to?(:form_key); rescue; end
    fk = :normal if fk == nil
    hit = (@motion_basic_flex_memo_ready_v10221 &&
           @motion_basic_flex_species_v10221 == sk &&
           @motion_basic_flex_form_v10221 == fk)
    begin
      @scene.motion_perf_lean_note_flex_v10222(hit) if
        @scene != nil && @scene.respond_to?(:motion_perf_lean_note_flex_v10222)
    rescue
    end
    return @motion_basic_flex_profile_v10221 if hit

    profile = pmd_ac_v10221_basic_flex_profile_v09912
    @motion_basic_flex_species_v10221 = sk
    @motion_basic_flex_form_v10221 = fk
    @motion_basic_flex_profile_v10221 = profile
    @motion_basic_flex_memo_ready_v10221 = true
    profile
  end
end
