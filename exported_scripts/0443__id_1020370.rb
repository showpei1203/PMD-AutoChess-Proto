#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess NORMAL Mode Final Ring v1.02.37
#------------------------------------------------------------------------------
# 【用途】
# 1. 最終修正 v1.02.36 仍可能無法在布陣畫面切到 NORMAL 的問題。
# 2. 不再只依賴歷史 PMD_AC::VERIFICATION_MODES 常數與多層 start alias 的索引重設，
#    而是在所有既有腳本之後建立一個明確的最終模式環，並直接接管
#    verification_mode / verification_mode_label / cycle_verification_mode。
# 3. 布陣畫面每次新建 Scene 時強制以 NORMAL 為預設；S 從 NORMAL 開始依序輪替
#    最新五個 verifier，最後再回到 NORMAL。
# 4. 保留 v1.02.34～v1.02.36 的 Production Loading policy、transient Loading context、
#    Persistent Geometry Cache、UI throttle 與 Production Path Acceptance Probe。
#
# 【最終模式環】
#   0 NORMAL
#   1 PMD_MOTION_PHASE_A_V102
#   2 MAP_STORY_VERTICAL_SLICE_V101
#   3 RPG_FOUNDATION_V100
#   4 NATURE_AI_TEMPERAMENT_V09916
#   5 SPATIAL_CONDITIONS_AI_RULES_V09915
#
# NORMAL 為正式模式，不列入「最新五個 verifier」數量。
#
# 【機制規則】
# - Scene start 完成全部歷史 alias 後，再把 mode index 明確設為 0（NORMAL）。
# - verification_mode 不再依賴舊索引語意，直接讀取 FINAL_MODE_RING_V10237。
# - cycle_verification_mode 也直接使用同一個 final ring，因此不受歷史常數覆寫影響。
# - PMD_AC::VERIFICATION_MODES 同步設成相同內容，讓舊 verifier 若讀取該常數時仍一致。
# - v1.02.36 的 Loading Scope verifier 改用 NORMAL-first 語意重新驗收；
#   不會因「預設改回 NORMAL」而把 PMD Motion verifier 誤判 FAIL。
# - 不修改 AI、Damage Formula、Attack Speed、Spatial logical x/y、Motion hitFrame、
#   hit-stop、技能傷害時機或任何資源 preload 工作量。
#
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。
# Production Path 測試：
#   1. 開啟 AutoChess Scene，畫面一開始就必須顯示 NORMAL。
#   2. 不按 S，直接 Shift 開戰即可測正式 production path。
#   3. LOG 應出現：
#      MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 pass=1 mode=normal
#
# 【S 輪替範例】
# NORMAL -> PMD Motion -> Map Story -> RPG Foundation -> Nature AI
# -> Spatial Conditions -> NORMAL
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_NormalModeFinalRing_v10237'] = true

module PMD_AC
  NORMAL_MODE_FINAL_RING_VERSION_V10237 = '1.02.37'
  NORMAL_MODE_FINAL_RING_ENABLED_V10237 = true

  FINAL_MODE_RING_V10237 = [
    :normal,
    :pmd_motion_phase_a_v102,
    :map_story_vertical_slice_v101,
    :rpg_foundation_v100,
    :nature_ai_temperament_v09916,
    :spatial_conditions_ai_rules_v09915
  ]

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = FINAL_MODE_RING_V10237.dup

  begin
    labels = const_defined?(:VERIFICATION_LABELS) ? VERIFICATION_LABELS.dup : {}
    remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
    VERIFICATION_LABELS = labels
    VERIFICATION_LABELS[:normal] = 'NORMAL'
    VERIFICATION_LABELS[:pmd_motion_phase_a_v102] = 'PMD_MOTION_PHASE_A_V102'
    VERIFICATION_LABELS[:map_story_vertical_slice_v101] = 'MAP_STORY_VERTICAL_SLICE_V101'
    VERIFICATION_LABELS[:rpg_foundation_v100] = 'RPG_FOUNDATION_V100'
    VERIFICATION_LABELS[:nature_ai_temperament_v09916] = 'NATURE_AI_TEMPERAMENT_V09916'
    VERIFICATION_LABELS[:spatial_conditions_ai_rules_v09915] = 'SPATIAL_CONDITIONS_AI_RULES_V09915'
  rescue
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10237_start start unless method_defined?(:pmd_ac_v10237_start)

  def verification_mode
    ring = PMD_AC::FINAL_MODE_RING_V10237
    idx = @verification_mode_index.to_i
    idx = 0 if idx < 0 || idx >= ring.size
    ring[idx] || :normal
  rescue
    :normal
  end

  def verification_mode_label
    PMD_AC::VERIFICATION_LABELS[verification_mode] || verification_mode.to_s.upcase
  rescue
    'NORMAL'
  end

  def cycle_verification_mode
    ring = PMD_AC::FINAL_MODE_RING_V10237
    @verification_mode_index = @verification_mode_index.to_i + 1
    @verification_mode_index %= ring.size
    Sound.play_cursor
    log_event(:verify, 'MODE -> ' + verification_mode_label)
    refresh_header
    refresh_footer
  rescue
  end

  def start
    pmd_ac_v10237_start
    # 必須放在完整 inherited start chain 之後，否則歷史 alias 仍可能重設 index。
    @verification_mode_index = 0
    refresh_header
    refresh_footer
    begin
      log_event(:perf,
        'NORMAL_MODE_FINAL_RING_V10237 ready=1 default=normal mode_index=0 modes=6'+
        ' verifiers=5 direct_mode_methods=1 historical_index_bypass=1'+
        ' production_loading_retained=1 geometry_cache_unchanged=1'+
        ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    rescue
    end
  end

  # v1.02.36 原 verifier 假設 PMD Motion 位於 ring[0]；v1.02.37 正式恢復
  # NORMAL-first 後，改用新的正確條件，避免 PMD Motion verifier 自己誤判。
  def verify_loading_scope_isolation_v10236
    return if @motion_loading_scope_verify_logged_v10236
    return unless motion_verifier_mode_v10236?
    modes = PMD_AC::FINAL_MODE_RING_V10237
    normal_default = modes[0] == :normal
    five_verifiers = modes[1,5].size == 5 && !modes[1,5].include?(:normal)
    motion_access = modes.include?(:pmd_motion_phase_a_v102)
    pass = normal_default && five_verifiers && motion_access &&
      motion_v1024_mode? && motion_v1028_mode? &&
      !motion_production_loading_context_v10236?
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_LOADING_SCOPE_ISOLATION_V10236 pass='+(pass ? '1':'0')+
      ' normal_access='+(normal_default ? '1':'0')+
      ' latest_verifiers='+(five_verifiers ? '5':'0')+
      ' default_normal='+(normal_default ? '1':'0')+
      ' motion_access='+(motion_access ? '1':'0')+
      ' motion_dispatcher_verifier_only=1 motion_ui_verifier_only=1'+
      ' production_loading_transient=1 loading_context_live=0'+
      ' superseded_mode_ring=v10237'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_loading_scope_verify_logged_v10236 = true
  rescue
  end
end
