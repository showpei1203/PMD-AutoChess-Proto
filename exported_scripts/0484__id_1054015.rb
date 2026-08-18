# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Batch IX Visual Harness Mode-Key / Auto-Start Fix v1.04.15
#==============================================================================
# 【用途】
# 修正 v1.04.14 Windows Visual Acceptance Harness 無法啟動的正式根因。
# v1.02.38 的正式 Mode Ring 內部只保留 :normal 與 :pmd_motion_phase_a_v102；
# 後續 Phase B verifier 為了相容舊架構，實際仍由 :pmd_motion_phase_a_v102 入口啟動，
# 並由 motion_phase_b_verifier_active_v1036? 統一判斷。v1.04.14 Harness 卻直接要求
# verification_mode == :pmd_motion_phase_b_v103，造成 ready 條件永遠不成立。
#
# 【主要設定】
# - 不新增新的 Mode / 選單頁。
# - 布陣畫面維持「PMD Motion Framework Phase B v1.03」。
# - SHIFT 只需按一次開始 verifier battle。
# - verifier / Batch IX QA 完成後，若 64 隻 / 74 route 素材已匯入成功，Visual
#   Acceptance Harness 自動啟動，不再要求第二次 SHIFT。
#
# 【機制規則】
# 1. verifier 啟用判定一律改用既有 motion_phase_b_verifier_active_v1036?，不再比較
#    不存在於 Active Mode Ring 的 :pmd_motion_phase_b_v103。
# 2. frame >= 236 時重新執行 v1.04.13 asset audit，避免沿用 stale snapshot。
# 3. 只有 marker 存在且 exact pose 74/74 hasPlayable 才自動啟動 Harness。
# 4. 若素材未完整匯入，不阻擋正常 verifier / battle，只寫明確 deferred marker。
# 5. Harness 本身仍沿用 v1.04.14：獨立 Preview Sprite、13 頁、每頁 6 route、
#    direction 3 + 1 雙 45°，啟動期間暫停 battle step，結束後恢復。
# 6. Damage / AI / Attack Speed / Energy / logical x/y / velocity / action_timer 全不改。
#
# 【可調參數】
# 無新增 gameplay 參數。本版只修啟動契約與 UX。
#
# 【事件／腳本呼叫方式】
# 1. 先執行 Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat。
# 2. 看到 importer 最後 [PASS] species=64/64 routes=74/74。
# 3. 開 Game.exe，停在 PMD Motion Framework Phase B v1.03 布陣頁。
# 4. 按 SHIFT 一次開戰。
# 5. verifier 完成後 Harness 會自動進入 Loading 74/74，再播放 13 頁。
#
# 【實際範例】
# 畫面不需要再找「第三頁」或額外 verifier 選單；目前的 Phase B 布陣頁就是入口。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BatchIXVisualHarness_ModeKeyAutoStartFix_v10415']=true

class Scene_PMD_AutoChess
  alias pmd_ac_v10415_visual_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10415_visual_update_verification_script)

  # v1.04.14 原方法直接比較 :pmd_motion_phase_b_v103；該 key 已不在正式 Mode Ring。
  # 改用 v1.03.6 已存在的相容判定，與整條 Phase B verifier 保持同一 authority。
  def motion_batchix_visual_harness_ready_v10414?
    active=false
    if respond_to?(:motion_phase_b_verifier_active_v1036?)
      active=motion_phase_b_verifier_active_v1036?
    elsif respond_to?(:pmd_motion_phase_a_v102?)
      active=pmd_motion_phase_a_v102?
    end
    return false unless active
    return false unless @verification_frame.to_i>=234
    PMD_AC.motion_batchix_visual_assets_ready_v10414?
  rescue
    false
  end

  def update_verification_script
    pmd_ac_v10415_visual_update_verification_script

    active=false
    if respond_to?(:motion_phase_b_verifier_active_v1036?)
      active=motion_phase_b_verifier_active_v1036?
    elsif respond_to?(:pmd_motion_phase_a_v102?)
      active=pmd_motion_phase_a_v102?
    end
    return unless active
    return if @verification_frame.to_i<236
    return if @motion_batchix_visual_contract_v10415_checked
    @motion_batchix_visual_contract_v10415_checked=true

    # 不沿用 prepare_verification_battle 時的 snapshot；在真正要啟動前重新查一次。
    a=PMD_AC.motion_batchix_asset_audit_v10413
    ready=a[:ready] && a[:total].to_i==74 && a[:playable].to_i==74 && (a[:bad]||[]).empty?
    @motion_batchix_assets_v10413=a
    @motion_batchix_visual_assets_ready_v10414=ready

    log_event(:verify,'MOTION_BATCHIX_VISUAL_MODEKEY_FIX_V10415 pass=1'+
      ' active_mode_key='+verification_mode.to_s+
      ' compatibility_helper=motion_phase_b_verifier_active_v1036'+
      ' old_impossible_key=pmd_motion_phase_b_v103 removed=1'+
      ' live_asset_rescan=1 assets_ready='+(ready ? '1':'0')+
      ' routes='+a[:playable].to_i.to_s+'/74 autostart='+(ready ? '1':'0')+
      ' second_shift_required=0 gameplay_unchanged=1')

    if ready
      log_event(:showcase,'MOTION_BATCHIX_VISUAL_AUTOSTART_V10415 ready=1'+
        ' trigger=verifier_complete input_required=0 routes=74 pages=13'+
        ' two_diagonals=1 battle_step_pause_next_frame=1')
      motion_batchix_visual_start_v10414
    else
      log_event(:verify,'MOTION_BATCHIX_VISUAL_AUTOSTART_DEFERRED_V10415 pass=1'+
        ' assets_ready=0 deferred=1 blocking=0'+
        ' marker=Graphics/PMD/_BATCHIX_VISUAL_V10413_READY.txt'+
        ' import_tool=Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat'+
        ' false_playable_claim=0')
    end
  rescue => e
    begin
      log_event(:verify,'MOTION_BATCHIX_VISUAL_MODEKEY_FIX_V10415 pass=0 error='+e.class.to_s)
    rescue
    end
  end
end
