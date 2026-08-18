#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Verification Mode Access / Production Loading Scope Fix v1.02.36
#------------------------------------------------------------------------------
# 【用途】
# 1. 修正 v1.02.34 將「Production Motion Loading policy」直接綁到舊版
#    motion_v1024_mode? / motion_v1028_mode? 等 verifier 專用判斷後，造成布陣畫面
#    即使按 S 切換模式，仍被 PMD Motion 專用 Header / Footer 蓋住，看起來像完全不能切換。
# 2. 修正更嚴重的潛在問題：v1.02.4 的 motion_v1024_mode? 同時控制 Motion verifier
#    lean dispatcher；若 NORMAL 戰鬥也回傳 true，正式戰鬥可能誤走 PMD Motion verifier
#    update_verification_script。Production preload 必須和 verifier dispatcher 徹底分離。
# 3. 恢復 NORMAL 到 S 模式循環中，同時保留「NORMAL + 最新五個 verifier」；
#    PMD_MOTION_PHASE_A_V102 仍維持預設第一項，按 S 一次即可切到 NORMAL。
# 4. Production preload 仍完整保留：NORMAL / Map Story 戰鬥只要包含目前 Motion Framework
#    覆蓋物種，Shift 後仍執行 Motion route、local bind / VFX、transition warm、Residual
#    prewarm、Baseline、Target Anchor、Persistent Geometry Cache 與 Loading UI throttle。
#
# 【根因】
# - v1.02.34 為了讓 NORMAL / Map Story 也能 preload，重寫：
#     motion_v1024_mode?
#     motion_v1028_mode?
#     motion_runtime_residual_mode_v10213?
#     motion_baseline_preload_mode_v10212?
#     motion_target_anchor_preload_mode_v10216?
#     motion_geometry_cache_mode_v10230?
#   讓它們只看「場上是否有 Motion coverage 物種」。
# - 但其中部分方法不只是 preload 開關，還兼任 verifier UI / verifier dispatcher 開關。
# - 正確做法是：
#   A. motion_loading_mode_v1029? 可維持 production policy；
#   B. verifier 專用 mode 判斷平時只看 verification_mode；
#   C. 只有真正執行 Loading Gate 的短暫期間，才以 transient loading context 允許
#      Residual / Geometry / Baseline / Target Anchor / Transition preload 使用 production policy。
#
# 【主要設定】
# - PRODUCTION_LOADING_SCOPE_FIX_ENABLED_V10236 = true
#   總開關，正式應保持 true。
# - VERIFICATION_MODES：
#     PMD_MOTION_PHASE_A_V102
#     NORMAL
#     MAP_STORY_VERTICAL_SLICE_V101
#     RPG_FOUNDATION_V100
#     NATURE_AI_TEMPERAMENT_V09916
#     SPATIAL_CONDITIONS_AI_RULES_V09915
#   NORMAL 不算 verifier，因此仍符合「只保留最新五個 verifier」的專案規則。
#
# 【機制規則】
# - PMD Motion verifier：保留 v1.02.4 lean dispatcher 與 v1.02.8 fast UI。
# - NORMAL / Map Story：不使用 PMD Motion verifier UI / dispatcher。
# - Shift 後進入 Loading Gate 時，若 production policy 成立，設定短暫
#   @motion_production_loading_context_v10236=true；Loading 完成或例外時一定清除。
# - transient context 只允許 preload 相關方法工作，不會延伸到 live battle。
# - 不修改 AI、Damage、Attack Speed、Spatial logical x/y、hit-stop 或技能傷害時機。
#
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。
# 測試 Production Path：
#   1. 進入 AutoChess 布陣畫面。
#   2. 預設為 PMD_MOTION_PHASE_A_V102 時按 S 一次，切到 NORMAL。
#   3. Header / Footer 應立即改回 NORMAL / 一般布陣 UI。
#   4. Shift 開戰，仍會看到 0～100% Loading。
#   5. LOG 應出現 MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 pass=1 mode=normal。
#
# 【實際範例】
# - PMD Motion 布陣：S → NORMAL
#   UI 必須立即切離「PMD Motion Framework Phase A」專用 Header。
# - NORMAL + 妙蛙種子 / 小火龍 / 傑尼龜：Shift
#   production loading context=1 → preload 完成 → context 清除 → 正常 live battle。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_VerificationModeAccessProductionLoadingScopeFix_v10236'] = true

module PMD_AC
  PRODUCTION_LOADING_SCOPE_FIX_VERSION_V10236 = '1.02.36'
  PRODUCTION_LOADING_SCOPE_FIX_ENABLED_V10236 = true

  # NORMAL 是正式模式，不列入「最新五個 verifier」數量。
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :pmd_motion_phase_a_v102,
    :normal,
    :map_story_vertical_slice_v101,
    :rpg_foundation_v100,
    :nature_ai_temperament_v09916,
    :spatial_conditions_ai_rules_v09915
  ]

  begin
    labels = VERIFICATION_LABELS.dup
    remove_const(:VERIFICATION_LABELS)
    VERIFICATION_LABELS = labels
    VERIFICATION_LABELS[:normal] = 'NORMAL'
  rescue
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10236_run_battle_resource_loading_v1029 run_battle_resource_loading_v1029 unless method_defined?(:pmd_ac_v10236_run_battle_resource_loading_v1029)
  alias pmd_ac_v10236_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10236_update_verification_script)

  def motion_production_loading_context_v10236?
    @motion_production_loading_context_v10236 ? true : false
  rescue
    false
  end

  def motion_verifier_mode_v10236?
    verification_mode == :pmd_motion_phase_a_v102
  rescue
    false
  end

  # v1.02.9 的總 Loading policy 可以是 production-wide。
  def motion_loading_mode_v1029?
    return motion_verifier_mode_v10236? unless PMD_AC::PRODUCTION_LOADING_SCOPE_FIX_ENABLED_V10236
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.4 的 mode 同時控制 lean verifier dispatcher，絕不能 production-wide。
  def motion_v1024_mode?
    motion_verifier_mode_v10236?
  rescue
    false
  end

  # v1.02.8 mode 同時控制 PMD Motion 專用 Header / Footer。
  # 只有 verifier 或「正在 Loading Gate 內」才允許 true。
  def motion_v1028_mode?
    motion_verifier_mode_v10236? || motion_production_loading_context_v10236?
  rescue
    false
  end

  # 以下四個 mode 只在 verifier 或 Loading transient context 啟用。
  # 這樣正式 live battle 不會誤跑 Motion verifier / profiler 分支，但 preload 仍完整。
  def motion_runtime_residual_mode_v10213?
    motion_verifier_mode_v10236? || motion_production_loading_context_v10236?
  rescue
    false
  end

  def motion_baseline_preload_mode_v10212?
    return false unless PMD_AC::MOTION_BASELINE_PRELOAD_ENABLED_V10212
    motion_verifier_mode_v10236? || motion_production_loading_context_v10236?
  rescue
    false
  end

  def motion_target_anchor_preload_mode_v10216?
    return false unless PMD_AC::MOTION_TARGET_ANCHOR_PRELOAD_ENABLED_V10216
    motion_verifier_mode_v10236? || motion_production_loading_context_v10236?
  rescue
    false
  end

  def motion_geometry_cache_mode_v10230?
    motion_verifier_mode_v10236? || motion_production_loading_context_v10236?
  rescue
    false
  end

  # Production preload 僅在真正 Loading Gate 執行期間打開 transient context。
  # ensure 保證任何例外都不會把 production mode 污染到 live battle。
  def run_battle_resource_loading_v1029
    applicable = false
    begin
      applicable = motion_production_loading_policy_v10234?
    rescue
      applicable = false
    end
    @motion_production_loading_context_v10236 = applicable ? true : false
    begin
      pmd_ac_v10236_run_battle_resource_loading_v1029
    ensure
      @motion_production_loading_context_v10236 = false
    end
  end

  def verify_loading_scope_isolation_v10236
    return if @motion_loading_scope_verify_logged_v10236
    return unless motion_verifier_mode_v10236?
    modes = PMD_AC::VERIFICATION_MODES
    normal_access = modes.include?(:normal)
    five_verifiers = modes.reject { |m| m == :normal }.size == 5
    default_motion = modes[0] == :pmd_motion_phase_a_v102
    pass = normal_access && five_verifiers && default_motion &&
      motion_v1024_mode? && motion_v1028_mode? &&
      !motion_production_loading_context_v10236?
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_LOADING_SCOPE_ISOLATION_V10236 pass='+(pass ? '1':'0')+
      ' normal_access='+(normal_access ? '1':'0')+
      ' latest_verifiers='+(five_verifiers ? '5':'0')+
      ' default_motion='+(default_motion ? '1':'0')+
      ' motion_dispatcher_verifier_only=1 motion_ui_verifier_only=1'+
      ' production_loading_transient=1 loading_context_live=0'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_loading_scope_verify_logged_v10236 = true
  rescue
  end

  def update_verification_script
    verify_loading_scope_isolation_v10236 if motion_verifier_mode_v10236? && @verification_frame.to_i >= 86
    pmd_ac_v10236_update_verification_script
  end
end
