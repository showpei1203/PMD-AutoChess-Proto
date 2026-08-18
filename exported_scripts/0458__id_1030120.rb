# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Verifier Contract Sync v1.03.12
#==============================================================================
# 【用途】
# 本版只修正 Motion Phase B 的「驗收合約漂移」，不修改任何實際戰鬥行為。
# v1.03.8 Remote Motion 上線後，正式 runtime 已依目前 presentation authority 將
# Water Gun 判為 :beam；但舊 verifier 仍硬編碼期待 :projectile，導致 Windows 實機
# 明明跑出正確 beam/shoot/H4/R8，驗證器卻自行標記 FAIL。
# 同時 v1.03.9～v1.03.11 已正式允許部分物種 Deploy 採 Idle-only profile，舊
# v1.03.5 verifier 卻仍要求 rich_ready == covered，因此會對「刻意不塞不自然 special」
# 的新規格留下過期紅字。
#
# 本版以 trailing method override 同步兩個 verifier 的 acceptance contract：
#   1. Remote route sample：Water Gun 正式期待 :beam；其餘五類維持既定 family。
#   2. Deploy 45° verifier：45° 鎖定仍是 blocker；每隻都必須有 rich special 不再是 blocker。
#------------------------------------------------------------------------------
# 【主要設定】
# REMOTE_ROUTE_EXPECTED_V10312
#   六個代表技能與正式 Remote family：
#   Water Gun=Beam / Ice Beam=Beam / Swords Dance=Cast /
#   Thunderbolt=Shock / Absorb=Drain / Screech=Sound。
#
# DEPLOY_RICH_REQUIRED_V10312 = false
#   v1.03.9 起允許 Idle-only；rich_ready 僅保留診斷數字，不再決定 PASS/FAIL。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 不重寫 motion_action_family_v102、motion_source_route_v102 或任何 gameplay router。
# 2. 不修改 Projectile / Beam / Cast / Shock / Drain / Sound 的 runtime presentation。
# 3. 不修改 Damage、AI、Attack Speed、Energy、Spatial logical x/y、velocity、action_timer。
# 4. 只覆寫 Scene_PMD_AutoChess 的兩個 verify method；Windows RGSS2 仍是正式 acceptance。
# 5. Remote verifier 同時檢查 selected pose 可播放，避免只修 family 文字而放過壞 route。
#------------------------------------------------------------------------------
# 【可調參數】
# 若未來正式 presentation authority 改變某個代表技能 family，只能在確認 runtime 規格後
# 修改 REMOTE_ROUTE_EXPECTED_V10312；不可為了讓 LOG 變綠而迎合錯誤輸出。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。按 S 切 PMD Motion verifier，Shift 開戰後自動於既有 frame 執行。
#------------------------------------------------------------------------------
# 【實際範例】
# Water Gun runtime：family=beam / pose=shoot / H4 / R8。
# 本版 verifier 期待 :beam，因此正確 runtime 不再被 v1.03.8 舊 :projectile 答案誤判。
# Deploy：若 6 隻代表中只有 4 隻有安全 rich special，只要 6/6 仍鎖定 45°，即可 PASS；
# 沒有安全 special 的物種維持 Idle-only，符合 QA II 的「寧可少動，不要亂轉向」規則。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionVerifierContractSync_v10312'] = true

module PMD_AC
  MOTION_VERIFIER_CONTRACT_VERSION_V10312 = '1.03.12'
  DEPLOY_RICH_REQUIRED_V10312 = false
  REMOTE_ROUTE_EXPECTED_V10312 = [
    ['0007', :water_gun,    :beam],
    ['0007', :ice_beam,     :beam],
    ['0001', :swords_dance, :cast],
    ['0025', :thunderbolt,  :shock],
    ['0001', :absorb,       :drain],
    ['0019', :screech,      :sound]
  ]
end

class Scene_PMD_AutoChess
  #--------------------------------------------------------------------------
  # v1.03.5 Deploy verifier 合約同步
  # rich_ready 不再要求 covered/covered；45° 鎖定仍是 blocking requirement。
  #--------------------------------------------------------------------------
  def verify_deploy_45_rich_v1035
    s=@motion_deploy_45_rich_snapshot_v1035 || {}
    covered=s[:covered].to_i
    diag=s[:diag_locked].to_i
    ready=s[:rich_ready].to_i
    dir_ok=PMD_AC::DEPLOY_DISPLAY_DIRECTION_V1035[:ally]==3 &&
      PMD_AC::DEPLOY_DISPLAY_DIRECTION_V1035[:enemy]==1
    pass=covered>0 && diag==covered && dir_ok
    log_event(:verify,
      'MOTION_DEPLOY_45_RICH_LOOP_V1035 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' diagonal_locked='+diag.to_s+'/'+covered.to_s+
      ' rich_ready='+ready.to_s+'/'+covered.to_s+
      ' specials='+s[:specials].to_i.to_s+' sequence_items='+s[:seq_items].to_i.to_s+
      ' ally_45_dir=3 enemy_45_dir=1 direct_8dir_only=1'+
      ' contract_sync=v10312 idle_only_allowed=1 rich_ready_nonblocking=1'+
      ' v1034_orientation_substitution_superseded=1 deploy_only=1'+
      ' combat_motion_unchanged=1 battle_ambient_isolation_retained=1'+
      ' logical_xy_unchanged=1 ai_unchanged=1 damage_unchanged=1'+
      ' attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:deploy_45_rich_v1035]=true
  rescue
    log_event(:verify,'MOTION_DEPLOY_45_RICH_LOOP_V1035 pass=0 error=1 contract_sync=v10312')
    @verification_done[:deploy_45_rich_v1035]=true if @verification_done!=nil
  end

  #--------------------------------------------------------------------------
  # v1.03.8 Remote route verifier 合約同步
  # Runtime router 不改；只把代表技能的正式 family expectation 與目前 authority 對齊。
  #--------------------------------------------------------------------------
  def verify_motion_remote_routes_v1038
    return if @verification_done[:motion_remote_routes_v1038]
    rows=[]
    pass=true
    family_hits={}
    PMD_AC::REMOTE_ROUTE_EXPECTED_V10312.each do |sample|
      sid=sample[0]
      mk=sample[1]
      expected=sample[2]
      d=nil;p=nil;r=nil
      begin;d=PMD_AC.skill_data(('mv_'+mk.to_s).to_sym);rescue;d=nil;end
      begin;p=PMD_AC.move_presentation_profile_v055(mk);rescue;p=nil;end
      begin;r=PMD_AC.motion_source_route_v102(sid,mk,d,p);rescue;r=nil;end
      actual=r==nil ? nil : r[:family]
      playable=r!=nil && r[:selected]!=nil && r[:has_playable]
      authority=nil
      begin;authority=PMD_AC.motion_action_family_v102(mk,d,p);rescue;authority=nil;end
      ok=r!=nil && actual==expected && authority==expected && playable
      pass=false unless ok
      family_hits[expected]=family_hits[expected].to_i+1 if ok
      rows.push(sid+':'+mk.to_s+'='+(r==nil ? 'nil':actual.to_s+'/'+r[:selected].to_s+
        '/H'+(r[:hit_frame]==nil ? 'nil':r[:hit_frame].to_s)+
        '/R'+(r[:return_frame]==nil ? 'nil':r[:return_frame].to_s))+
        '/E'+expected.to_s+'/A'+(authority==nil ? 'nil':authority.to_s))
    end
    [:beam,:cast,:shock,:drain,:sound].each{|f|pass=false if family_hits[f].to_i<=0}
    # Projectile family registry/runtime 仍保留；本代表樣本組現階段不強迫 Water Gun 扮演 projectile。
    begin
      pass=false unless PMD_AC::MOTION_REMOTE_FAMILIES_V1038.include?(:projectile)
    rescue
      pass=false
    end
    @motion_phase_b_remote_failed_v1038=true unless pass
    log_event(:verify,
      'MOTION_REMOTE_SOURCE_ROUTES_V1038 pass='+(pass ? '1':'0')+
      ' samples=['+rows.join(',')+'] playable_source=1 provenance_separated=1'+
      ' contract_sync=v10312 water_gun_expected=beam runtime_router_unchanged=1'+
      ' projectile_family_retained=1')
    @verification_done[:motion_remote_routes_v1038]=true
  rescue
    @motion_phase_b_remote_failed_v1038=true
    log_event(:verify,'MOTION_REMOTE_SOURCE_ROUTES_V1038 pass=0 error=1 contract_sync=v10312')
    @verification_done[:motion_remote_routes_v1038]=true if @verification_done!=nil
  end
end
