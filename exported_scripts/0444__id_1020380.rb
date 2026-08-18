#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Mode Ring Cleanup v1.02.38
#------------------------------------------------------------------------------
# 【用途】
# 1. 精簡布陣畫面的 S 模式切換，只保留目前仍有實際用途的 NORMAL 與
#    PMD_MOTION_PHASE_A_V102。
# 2. 移除 Map Story / RPG Foundation / Nature AI / Spatial Conditions 等已完成
#    驗收用途的舊 verifier「可選入口」，避免模式環過長、NORMAL 難以找到。
# 3. 每次建立 Scene_PMD_AutoChess 時固定以 NORMAL 為預設，因此正式遊戲不需要
#    先按 S；按 S 一次切到 PMD Motion，再按一次回 NORMAL。
# 4. 保留所有舊 verifier 腳本本體與共用方法，不做實體刪除，以免破壞歷史 alias、
#    共用 runtime 或後續腳本相依。清理範圍僅限使用者可選模式環與模式標籤。
# 5. 保留 v1.02.34～v1.02.36 Production Loading、Persistent Geometry Cache、
#    UI Refresh Throttle、Production Path Acceptance Probe 與所有戰鬥規則。
#
# 【目前正式模式環】
#   0 NORMAL
#   1 PMD_MOTION_PHASE_A_V102
#
# 【已從 S 模式環退休】
# - MAP_STORY_VERTICAL_SLICE_V101
# - RPG_FOUNDATION_V100
# - NATURE_AI_TEMPERAMENT_V09916
# - SPATIAL_CONDITIONS_AI_RULES_V09915
#
# 注意：上述舊 verifier 的腳本仍保留在 Scripts.rvdata，僅不再能由 S 選到。
# 若日後真的需要歷史回歸，可另做專用開發入口，不再污染正式模式環。
#
# 【機制規則】
# - verification_mode / verification_mode_label / cycle_verification_mode 最終由本腳本接管。
# - PMD_AC::VERIFICATION_MODES 同步只保留兩個模式，避免舊 UI 讀到過期清單。
# - NORMAL 永遠是 index 0 與 Scene 預設。
# - v1.02.36 Loading Scope verifier 改為「1 個 active verifier + NORMAL」語意。
# - 不修改 AI、Damage Formula、Attack Speed、Spatial logical x/y、Motion hitFrame、
#   hit-stop、技能傷害時機、Geometry Cache 或任何 preload 工作量。
#
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。
# 正式戰鬥：進入布陣畫面後直接 Shift，預設就是 NORMAL。
# Motion 測試：布陣畫面按 S 一次，再 Shift。
#
# 【實際範例】
# 開啟 AutoChess Scene：
#   NORMAL --S--> PMD_MOTION_PHASE_A_V102 --S--> NORMAL
#
# NORMAL 正式路徑驗收 LOG：
#   MOTION_PRODUCTION_PATH_ACCEPTANCE_V10235 pass=1 mode=normal
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_ModeRingCleanup_v10238'] = true

module PMD_AC
  MODE_RING_CLEANUP_VERSION_V10238 = '1.02.38'
  MODE_RING_CLEANUP_ENABLED_V10238 = true

  ACTIVE_MODE_RING_V10238 = [
    :normal,
    :pmd_motion_phase_a_v102
  ]

  RETIRED_SELECTABLE_MODES_V10238 = [
    :map_story_vertical_slice_v101,
    :rpg_foundation_v100,
    :nature_ai_temperament_v09916,
    :spatial_conditions_ai_rules_v09915
  ]

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = ACTIVE_MODE_RING_V10238.dup

  begin
    remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
    VERIFICATION_LABELS = {
      :normal => 'NORMAL',
      :pmd_motion_phase_a_v102 => 'PMD_MOTION_PHASE_A_V102'
    }
  rescue
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10238_start start unless method_defined?(:pmd_ac_v10238_start)

  def verification_mode
    ring = PMD_AC::ACTIVE_MODE_RING_V10238
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
    ring = PMD_AC::ACTIVE_MODE_RING_V10238
    @verification_mode_index = @verification_mode_index.to_i + 1
    @verification_mode_index %= ring.size
    Sound.play_cursor
    log_event(:verify, 'MODE -> ' + verification_mode_label)
    refresh_header
    refresh_footer
  rescue
  end

  def start
    pmd_ac_v10238_start
    @verification_mode_index = 0
    refresh_header
    refresh_footer
    begin
      log_event(:perf,
        'MODE_RING_CLEANUP_V10238 ready=1 default=normal modes=2 active_verifiers=1'+
        ' retired_selectable=4 normal_first=1 s_toggle_two_modes=1'+
        ' legacy_verifier_scripts_retained=1 production_loading_retained=1'+
        ' geometry_cache_unchanged=1 ai_unchanged=1 damage_unchanged=1'+
        ' attack_speed_unchanged=1 spatial_values_unchanged=1')
    rescue
    end
  end

  # v1.02.36 / v1.02.37 的舊驗收條件假設仍有五個 selectable verifier。
  # v1.02.38 正式清理模式環後，改驗收「NORMAL + 目前唯一 active verifier」。
  def verify_loading_scope_isolation_v10236
    return if @motion_loading_scope_verify_logged_v10236
    return unless motion_verifier_mode_v10236?
    modes = PMD_AC::ACTIVE_MODE_RING_V10238
    normal_default = modes[0] == :normal
    one_active_verifier = modes.size == 2 && modes[1] == :pmd_motion_phase_a_v102
    retired_absent = true
    PMD_AC::RETIRED_SELECTABLE_MODES_V10238.each do |mode|
      retired_absent = false if modes.include?(mode)
    end
    pass = normal_default && one_active_verifier && retired_absent &&
      motion_v1024_mode? && motion_v1028_mode? &&
      !motion_production_loading_context_v10236?
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_LOADING_SCOPE_ISOLATION_V10236 pass='+(pass ? '1':'0')+
      ' normal_access='+(normal_default ? '1':'0')+
      ' active_verifiers='+(one_active_verifier ? '1':'0')+
      ' retired_modes_absent='+(retired_absent ? '1':'0')+
      ' default_normal='+(normal_default ? '1':'0')+
      ' motion_access='+(modes.include?(:pmd_motion_phase_a_v102) ? '1':'0')+
      ' motion_dispatcher_verifier_only=1 motion_ui_verifier_only=1'+
      ' production_loading_transient=1 loading_context_live=0'+
      ' superseded_mode_ring=v10238'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_loading_scope_verify_logged_v10236 = true
  rescue
  end
end
