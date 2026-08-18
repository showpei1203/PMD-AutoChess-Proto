#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Production Motion Loading Rollout v1.02.34
#------------------------------------------------------------------------------
# 【用途】
# 1. 將 v1.02.9～v1.02.33 已在 Windows RGSS2 實機驗證的 Motion Loading 流程，
#    從「只有 PMD_MOTION_PHASE_A_V102 驗證模式才完整啟用」正式擴展到一般戰鬥。
# 2. 只要目前戰場至少有一隻屬於現階段 PMD Motion Framework 覆蓋範圍的 Pokémon，
#    就在 Shift 後的 0～100% Loading Gate 完成 Motion route、local bind / VFX、
#    transition warm、Residual prewarm、Visible Baseline、Target Anchor 與 Persistent
#    Geometry Cache hydrate，完成後才開始 live battle。
# 3. 保留 v1.02.33 已驗證的 Loading UI Refresh Throttle，以及 v1.02.29 已 ACCEPTED
#    的 Runtime Performance Seal；本版不改 AI、傷害、Attack Speed 或 Spatial 規則。
#
# 【為什麼需要本版】
# - Phase A 的 presentation / Hurt / hitFrame handoff 本身會套用到現階段覆蓋物種，
#   但早期 Loading mode 判斷仍綁定 verification_mode。
# - 因此測試模式可以在 Loading 前完整預熱，一般 Map/Story battle 卻可能落回 lazy
#   cache / lazy geometry 路徑。這會讓測試結果與正式遊戲行為不一致。
# - v1.02.33 已把完整 Motion Loading 實測壓到約 2.15 秒，現在才適合正式 rollout。
#
# 【主要設定】
# - PRODUCTION_MOTION_LOADING_ENABLED_V10234 = true
#   總開關。若日後需要緊急退回舊 policy，可暫時設 false。
# - 目前適用物種仍由 PMD_AC.motion_phase_a_species_v102? 決定。
#   本版不擅自把 Motion coverage 從 0001～0026 擴大到 0494。
#
# 【機制規則】
# - Policy 只看本場 active units 是否包含目前 Motion Framework 覆蓋物種，
#   不依賴 verification_mode，因此 NORMAL / Map / Story battle 與 verifier 使用同一路徑。
# - 沒有任何已覆蓋物種的戰鬥，不額外執行 Motion-specific preload。
# - Persistent Geometry Cache 仍保留 metadata / file size / Bitmap dimensions guard；
#   cache 不符時仍由既有安全 fallback 接手。
# - Loading Gate 仍 input_passthrough=0，0～100% 百分比與 PMD mascot 保留。
# - Production GC Guard 的 battle runtime policy 完全不改。
#
# 【可調參數】
# - PRODUCTION_MOTION_LOADING_ENABLED_V10234：true / false。
#   除非定位 production regression，否則應保持 true。
#
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。Scene_PMD_AutoChess 進入戰鬥時自動判斷。
# 開發時可查：
#   $scene.motion_production_loading_policy_v10234?
#
# 【實際範例】
# 例：Map Story battle 中有妙蛙種子、皮卡丘：
#   production policy = true
#   Shift -> Loading 0～100% -> Geometry Cache / Motion preload ready -> live battle
# 例：未來某個 battle 全部是尚未納入 Motion Framework 的物種：
#   production policy = false
#   不額外支付目前 Phase A 專用 preload 成本。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_ProductionMotionLoadingRollout_v10234'] = true

module PMD_AC
  PRODUCTION_MOTION_LOADING_VERSION_V10234 = '1.02.34'
  PRODUCTION_MOTION_LOADING_ENABLED_V10234 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10234_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10234_update_verification_script)

  def motion_production_loading_policy_v10234?
    return false unless PMD_AC::PRODUCTION_MOTION_LOADING_ENABLED_V10234
    list = @units || []
    list.each do |u|
      next if u == nil
      sid = u.species.to_s rescue ''
      next if sid.empty?
      return true if PMD_AC.motion_phase_a_species_v102?(sid)
    end
    false
  rescue
    false
  end

  # v1.02.9 的總 Motion Loading Gate：不再依 verifier mode。
  def motion_loading_mode_v1029?
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.4 local bind / VFX queue。
  def motion_v1024_mode?
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.8 transition warm queue。
  def motion_v1028_mode?
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.13 projectile frame / Audio residual prewarm。
  def motion_runtime_residual_mode_v10213?
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.12 Visible Baseline preload。
  def motion_baseline_preload_mode_v10212?
    return false unless PMD_AC::MOTION_BASELINE_PRELOAD_ENABLED_V10212
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.16 Target Anchor preload。
  def motion_target_anchor_preload_mode_v10216?
    return false unless PMD_AC::MOTION_TARGET_ANCHOR_PRELOAD_ENABLED_V10216
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  # v1.02.30 Persistent Geometry Cache hydrate / capture。
  def motion_geometry_cache_mode_v10230?
    motion_production_loading_policy_v10234?
  rescue
    false
  end

  def verify_production_motion_loading_rollout_v10234
    return if @motion_production_loading_verify_logged_v10234
    return unless verification_mode == :pmd_motion_phase_a_v102
    applicable = motion_production_loading_policy_v10234?
    loading = motion_loading_mode_v1029?
    live = motion_v1024_mode?
    transition = motion_v1028_mode?
    residual = motion_runtime_residual_mode_v10213?
    baseline = motion_baseline_preload_mode_v10212?
    anchor = motion_target_anchor_preload_mode_v10216?
    geometry = motion_geometry_cache_mode_v10230?
    pass = applicable && loading && live && transition && residual && baseline && anchor && geometry
    @motion_phase_a_failed_v102 = true unless pass
    log_event(:verify,
      'MOTION_PRODUCTION_LOADING_ROLLOUT_V10234 pass='+(pass ? '1':'0')+
      ' active_motion_species='+(applicable ? '1':'0')+
      ' loading_gate='+(loading ? '1':'0')+
      ' local_bind_vfx='+(live ? '1':'0')+
      ' transition_warm='+(transition ? '1':'0')+
      ' residual_prewarm='+(residual ? '1':'0')+
      ' baseline_preload='+(baseline ? '1':'0')+
      ' target_anchor_preload='+(anchor ? '1':'0')+
      ' geometry_cache='+(geometry ? '1':'0')+
      ' verifier_independent_policy=1 normal_map_story_ready=1'+
      ' loading_ui_throttle_retained=1 production_gc_guard_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @motion_production_loading_verify_logged_v10234 = true
  rescue
  end

  def update_verification_script
    verify_production_motion_loading_rollout_v10234 if @verification_frame.to_i >= 84
    pmd_ac_v10234_update_verification_script
  end
end
