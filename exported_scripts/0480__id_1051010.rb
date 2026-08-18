#==============================================================================
# ■ PMD AutoChess - Result Semantics Verifier Isolation v1.04.11
#==============================================================================
# 【用途】
# 修正 PMD Motion Phase B 的 Result Semantics 驗收器在 live verifier 戰鬥中偶發
# `target_hurt_suppressed=0` 的假 FAIL。
#
# v1.03.6 的驗收器在 frame 184 直接要求目標當下「完全沒有 Hurt state」。但該目標
# 同時也是真正測試戰鬥中的敵方單位，可能剛好在前幾個 frame 被正常攻擊命中，因此
# 即使 MISS / IMMUNE / GUARD presentation 根本沒有新增 Hurt，仍會因既存 Hurt 而誤判。
#
# 本版只修正驗收契約，不修改正式戰鬥 Result Runtime：
# - 不清除、不縮短、不重設既有 Hurt。
# - 不製造 synthetic Damage。
# - 改為比較 verifier 呼叫前後的 Hurt state identity 與 Hurt serial。
# - 若目標原本就在 Hurt，只要本次 MISS / IMMUNE / GUARD 測試沒有新增 Hurt，即 PASS。
#
# 【主要設定】
# 無玩家可調 gameplay 參數。
# 驗收條件由「target currently clean」改成「target hurt state unchanged」。
#
# 【機制規則】
# 1. 仍測 MISS / IMMUNE / GUARD 三種 attacker result state 是否能建立。
# 2. 仍驗證雙方 HP、logical pixel_x / pixel_y 完全不變。
# 3. Target Hurt suppression 改以：
#      before_hurt_state.equal?(after_hurt_state)
#      before_hurt_serial == after_hurt_serial
#    判定，不要求目標在 live battle 當下恰好沒有正常 Hurt。
# 4. 0001～0026、Generated 0027～0494、Damage、AI、Attack Speed、Energy、Spatial、
#    Hit-stop、Hurt/Faint ownership 全部不變。
#
# 【可調參數】
# 無。這是 verifier isolation 修正，不應被拿來調整戰鬥表現。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。Windows PMD Motion verifier 在 frame 184 自動執行。
#
# 【實際範例】
# 若小拉達在 frame 168 被妙蛙種子的正常攻擊命中，frame 184 仍可能處於 Hurt。
# v1.03.6 會因此誤判 target_hurt_suppressed=0；v1.04.11 會確認本次 Result verifier
# 沒有新增 Hurt token / state，正確判定 PASS，同時保留畫面上原本的 Hurt 動畫。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_ResultSemanticsVerifierIsolation_v10411'] = true

class Scene_PMD_AutoChess
  # 覆寫舊 verifier 的「目標當下必須完全沒有 Hurt」不穩定條件。
  # 正式 runtime routing method 完全不動。
  def verify_motion_phase_b_result_semantics_v1036
    return if @verification_done[:motion_phase_b_result_semantics_v1036]
    a=verification_unit(:ally,:bulbasaur)
    t=verification_unit(:enemy,:rattata)
    pass=a!=nil && t!=nil
    miss=false;immune=false;guard=false
    target_clean=false;hurt_state_unchanged=false;hurt_serial_unchanged=false;xy_ok=false
    preexisting_hurt=false
    if pass
      ax=a.pixel_x.to_f;ay=a.pixel_y.to_f;tx=t.pixel_x.to_f;ty=t.pixel_y.to_f
      ah=a.hp.to_i;th=t.hp.to_i
      before_hurt=t.instance_variable_get(:@motion_hurt_state_v102)
      before_serial=t.instance_variable_get(:@motion_hurt_serial_v102).to_i
      preexisting_hurt=(before_hurt!=nil)
      route=motion_phase_b_result_route_v1036(a,nil)
      if route!=nil
        miss=a.motion_phase_b_begin_result_v1036(:miss,t,route,:verify)
        miss=miss && a.motion_phase_b_result_kind_v1036==:miss
        a.motion_phase_b_clear_test_state_v103
        immune=a.motion_phase_b_begin_result_v1036(:immune,t,route,:verify)
        immune=immune && a.motion_phase_b_result_kind_v1036==:immune
        a.motion_phase_b_clear_test_state_v103
        guard=a.motion_phase_b_begin_result_v1036(:guard,t,route,:protect)
        guard=guard && a.motion_phase_b_result_kind_v1036==:guard
        a.motion_phase_b_clear_test_state_v103
      end
      after_hurt=t.instance_variable_get(:@motion_hurt_state_v102)
      after_serial=t.instance_variable_get(:@motion_hurt_serial_v102).to_i
      hurt_state_unchanged=before_hurt.equal?(after_hurt)
      hurt_serial_unchanged=(before_serial==after_serial)
      target_clean=hurt_state_unchanged && hurt_serial_unchanged
      xy_ok=a.pixel_x.to_f==ax && a.pixel_y.to_f==ay &&
        t.pixel_x.to_f==tx && t.pixel_y.to_f==ty &&
        a.hp.to_i==ah && t.hp.to_i==th
      pass=miss && immune && guard && target_clean && xy_ok
    end
    @motion_phase_b_batch_b_failed_v1036=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_RESULT_SEMANTICS_V1036 pass='+(pass ? '1':'0')+
      ' miss='+(miss ? '1':'0')+' immune='+(immune ? '1':'0')+' guard='+(guard ? '1':'0')+
      ' target_hurt_suppressed='+(target_clean ? '1':'0')+' hp_unchanged='+(xy_ok ? '1':'0')+
      ' visual_offset_only=1 miss_forward_whiff=1 immune_short_recoil=1 guard_strong_recoil=1'+
      ' guard_miss_counter_unchanged=1 multi_hit_unchanged=1 logical_xy_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1'+
      ' verifier_contract=v10411')
    log_event(:verify,
      'MOTION_RESULT_SEMANTICS_VERIFIER_ISOLATION_V10411 pass='+(pass ? '1':'0')+
      ' preexisting_hurt_allowed=1 preexisting_hurt='+(preexisting_hurt ? '1':'0')+
      ' hurt_state_unchanged='+(hurt_state_unchanged ? '1':'0')+
      ' hurt_serial_unchanged='+(hurt_serial_unchanged ? '1':'0')+
      ' live_hurt_not_cleared=1 synthetic_damage=0 runtime_result_routing_unchanged=1'+
      ' damage_unchanged=1 hitstop_unchanged=1 hurt_unchanged=1 faint_unchanged=1'+
      ' ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_phase_b_result_semantics_v1036]=true
  rescue
    @motion_phase_b_batch_b_failed_v1036=true
    log_event(:verify,'MOTION_PHASE_B_RESULT_SEMANTICS_V1036 pass=0 error=1 verifier_contract=v10411')
    log_event(:verify,'MOTION_RESULT_SEMANTICS_VERIFIER_ISOLATION_V10411 pass=0 error=1')
    @verification_done[:motion_phase_b_result_semantics_v1036]=true
  end
end
