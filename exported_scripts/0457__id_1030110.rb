# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion QA II Deploy Visible-Foot Anchor Fix v1.03.11
#==============================================================================
# 【用途】
# v1.03.10 已把 0001～0026 Deploy 待機動作限制為「實際 PNG 具有真正 45° row」；
# 但 Windows 肉眼驗收又發現第二種問題：不同 action 的 FrameHeight / 透明底部 padding
# 不同，即使方向正確，切換 Idle -> Withdraw / Shake 等動作時，角色可見腳底仍會突然
# 上下跳。實測 metadata：0001 妙蛙種子 Idle->Shake 會讓腳底下沉約 4px；
# 0007 傑尼龜 Idle->Withdraw 會下沉約 8px。
#
# 本版只修 Deploy presentation：
# 1. 0001 妙蛙種子依 Windows 肉眼回報，移除 Deploy Shake，改為純 45° Idle。
# 2. 0001～0026 curated Deploy action 新增「可見腳底基準正規化」：每個 special action
#    都以該物種 Deploy base（通常 Idle；大針蜂為 Hover）的 row_foot_y 為基準，
#    只調整 Sprite self.y，使切換動作時可見腳底維持同一地面線。
# 3. 正規化只在 Deploy phase 生效；live battle / Spatial Runtime / logical pixel_y 不變。
#
# 【主要設定】
# MOTION_DEPLOY_FOOT_ANCHOR_RANGE_V10311
#   本輪只處理 QA 範圍 0001～0026。
# MOTION_DEPLOY_FOOT_ANCHOR_MAX_ABS_V10311 = 16
#   安全上限。若素材 metadata 推導出的修正超過 16px，視為異常，不在 Runtime 套用，
#   交由 QA 查素材／profile，不讓錯誤 metadata 把角色整隻拉走。
# MOTION_DEPLOY_PROFILE_OVERRIDES_V10311
#   Windows 肉眼確認的 profile 覆寫。目前 0001 妙蛙種子 specials=[]。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本是 Main 前的 trailing presentation layer。
# - HOME 仍是 current action anchor，不是出生點。
# - 不寫 Game_PMDChessUnit#pixel_x / pixel_y、velocity、HP、Energy、@action_timer。
# - 不改 Damage packet、Damage timing、AI、Attack Speed、Projectile / Beam timing。
# - Deploy 顯示方向沿用 v1.03.5：我方 dir=3（右下 45°），敵方 dir=1（左下 45°）。
# - anchor 使用既有 compiled action metadata 的 row_foot_y / frame_h，不做 live PNG alpha scan，
#   因此不會破壞 v1.02.29 Performance Seal / Geometry Cache 策略。
# - 只修 action 間的「整體腳底基準差」，不取消 action 自己逐 frame 的內部演技。
#
# 【可調參數】
# - 若某物種的特殊待機動作不自然，請改 MOTION_DEPLOY_PROFILE_OVERRIDES_V10311。
# - 若需調整 anchor 安全上限，改 MOTION_DEPLOY_FOOT_ANCHOR_MAX_ABS_V10311；
#   不建議超過 20px，超大差異通常表示素材或 action 語意本身不適合待機。
# - 不要用 Graphics.frame_rate 或 logical y 來修待機下沉。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。按 S 切 PMD Motion 後，在 Deploy 停 10～20 秒直接觀察。
# Windows LOG 應看到：
#   MOTION_DEPLOY_FOOT_ANCHOR_V10311 pass=1
#   MOTION_DEPLOY_PROFILE_FIX_V10311 pass=1 bulbasaur_shake=0
#
# 【實際範例】
# - 0001 妙蛙種子：Deploy = 45° Idle only；不再播放 Shake。
# - 0007 傑尼龜：Withdraw 保留，但 Sprite 額外上移約 8px，讓 Withdraw 可見腳底
#   與 Idle 落在同一基準，不再「縮殼時整隻沉進地面」。
# - 0008 卡咪龜：同機制約修正 12px；0009 水箭龜約修正 8px。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionDeployFootAnchor_v10311'] = true

module PMD_AC
  MOTION_DEPLOY_FOOT_ANCHOR_VERSION_V10311='1.03.11'
  MOTION_DEPLOY_FOOT_ANCHOR_RANGE_V10311=(1..26).to_a.collect{|i|'%04d'%i}
  MOTION_DEPLOY_FOOT_ANCHOR_MAX_ABS_V10311=16.0

  MOTION_DEPLOY_PROFILE_OVERRIDES_V10311={
    '0001'=>{:base=>:idle,:specials=>[],:primary=>34,:between=>14,:ending=>26}
  }

  class << self
    alias pmd_ac_v10311_motion_species_qa_deploy_v1039 motion_species_qa_deploy_v1039 unless method_defined?(:pmd_ac_v10311_motion_species_qa_deploy_v1039)

    # Windows 肉眼結果優先於「檔案裡有這個 action」：有素材不代表適合作為待機演技。
    def motion_species_qa_deploy_v1039(species)
      sid=species.to_s
      q=MOTION_DEPLOY_PROFILE_OVERRIDES_V10311[sid]
      return q if q!=nil
      pmd_ac_v10311_motion_species_qa_deploy_v1039(species)
    rescue
      pmd_ac_v10311_motion_species_qa_deploy_v1039(species)
    end

    def motion_deploy_foot_anchor_species_v10311?(species)
      MOTION_DEPLOY_FOOT_ANCHOR_RANGE_V10311.include?(species.to_s)
    rescue
      false
    end

    # 回傳「把 current action 的可見腳底對齊 base action」所需 Sprite Y 修正值（未乘 zoom）。
    # 負值 = Sprite 上移；正值 = Sprite 下移。
    def motion_deploy_foot_anchor_delta_v10311(species,current_action,display_dir)
      sid=species.to_s
      return 0.0 unless motion_deploy_foot_anchor_species_v10311?(sid)
      q=motion_species_qa_deploy_v1039(sid)
      return 0.0 if q==nil
      base_action=q[:base] || :idle
      action=current_action==nil ? base_action : current_action.to_sym
      allowed=[base_action]
      (q[:specials] || []).each{|a|allowed.push(a) unless allowed.include?(a)}
      return 0.0 unless allowed.include?(action)
      return 0.0 if action==base_action

      data=action_data(sid,action)
      base=action_data(sid,base_action)
      return 0.0 if data==nil || base==nil
      feet=data[:row_foot_y]
      bfeet=base[:row_foot_y]
      return 0.0 if feet==nil || bfeet==nil
      row=direction_row(data,display_dir)
      brow=direction_row(base,display_dir)
      foot=feet[row]
      bfoot=bfeet[brow]
      return 0.0 if foot==nil || bfoot==nil
      fh=data[:frame_h].to_f
      bfh=base[:frame_h].to_f
      return 0.0 if fh<=0.0 || bfh<=0.0

      action_rel=foot.to_f-fh
      base_rel=bfoot.to_f-bfh
      delta=base_rel-action_rel
      lim=MOTION_DEPLOY_FOOT_ANCHOR_MAX_ABS_V10311.to_f
      return 0.0 if delta.abs>lim
      delta
    rescue
      0.0
    end
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit - Deploy visible-foot normalization
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v10311_update_position update_position unless method_defined?(:pmd_ac_v10311_update_position)

  def motion_deploy_foot_anchor_delta_v10311
    return 0.0 if @unit==nil
    return 0.0 unless @unit.respond_to?(:motion_deploy_phase_v1033?)
    return 0.0 unless @unit.motion_deploy_phase_v1033?
    return 0.0 unless PMD_AC.motion_deploy_foot_anchor_species_v10311?(@unit.species)
    action=@unit.visual_action
    q=PMD_AC.motion_species_qa_deploy_v1039(@unit.species)
    return 0.0 if q==nil
    action=q[:base] if action==nil
    d=respond_to?(:motion_deploy_display_direction_v1035) ? motion_deploy_display_direction_v1035 : nil
    d=(@unit.team==:enemy ? 1 : 3) if d==nil
    base_delta=PMD_AC.motion_deploy_foot_anchor_delta_v10311(@unit.species,action,d)
    base_delta.to_f*self.zoom_y.to_f
  rescue
    0.0
  end

  def update_position
    pmd_ac_v10311_update_position
    delta=motion_deploy_foot_anchor_delta_v10311
    if delta!=0.0
      px=delta.round
      self.y=(self.y.to_f+delta).round
      # True Foot Bar / UI 先在舊 update_position chain 定位；Deploy 只需同步同一個
      # presentation shift，避免本體修好後 bar 留在舊高度。
      @bar_sprite.y=@bar_sprite.y.to_i+px if @bar_sprite!=nil
    end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Windows verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10311_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10311_prepare_verification_battle)
  alias pmd_ac_v10311_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10311_update_verification_script)

  def motion_deploy_anchor_reset_v10311
    @motion_deploy_anchor_verified_v10311=false
  end

  def prepare_verification_battle
    pmd_ac_v10311_prepare_verification_battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
      motion_deploy_anchor_reset_v10311
      log_event(:showcase,
        'MOTION_DEPLOY_ANCHOR_V10311 START scope=0001-0026 visible_foot_normalization=1'+
        ' bulbasaur_idle_only=1 deploy_only=1 live_alpha_scan=0'+
        ' logical_xy_unchanged=1 damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    end
  end

  def verify_motion_deploy_anchor_v10311
    return if @motion_deploy_anchor_verified_v10311
    profiles=0;specials=0;anchored=0;bad=[];max_abs=0.0
    PMD_AC::MOTION_DEPLOY_FOOT_ANCHOR_RANGE_V10311.each do |sid|
      q=PMD_AC.motion_species_qa_deploy_v1039(sid)
      next if q==nil
      profiles+=1
      (q[:specials] || []).each do |action|
        specials+=1
        [3,1].each do |d|
          delta=PMD_AC.motion_deploy_foot_anchor_delta_v10311(sid,action,d)
          a=delta.abs
          max_abs=a if a>max_abs
          if a<=PMD_AC::MOTION_DEPLOY_FOOT_ANCHOR_MAX_ABS_V10311.to_f
            anchored+=1
          else
            bad.push(sid+':'+action.to_s+':'+d.to_s)
          end
        end
      end
    end
    b=PMD_AC.motion_species_qa_deploy_v1039('0001') || {}
    bulba_specials=b[:specials] || []
    bulba_ok=!bulba_specials.include?(:shake)
    squirtle_delta=PMD_AC.motion_deploy_foot_anchor_delta_v10311('0007',:withdraw,3)
    expected=specials*2
    pass=profiles==26 && anchored==expected && bad.empty? && bulba_ok && squirtle_delta.to_i==-8
    log_event(:verify,
      'MOTION_DEPLOY_PROFILE_FIX_V10311 pass='+(bulba_ok ? '1':'0')+
      ' bulbasaur_shake='+(bulba_specials.include?(:shake) ? '1':'0')+
      ' bulbasaur_specials=['+bulba_specials.collect{|a|a.to_s}.join(',')+']')
    log_event(:verify,
      'MOTION_DEPLOY_FOOT_ANCHOR_V10311 pass='+(pass ? '1':'0')+
      ' profiles='+profiles.to_s+'/26 specials='+specials.to_s+
      ' anchored_sides='+anchored.to_s+'/'+expected.to_s+
      ' squirtle_withdraw_delta='+squirtle_delta.to_i.to_s+
      ' max_abs='+sprintf('%.1f',max_abs)+' bad=['+bad[0,10].join(',')+']'+
      ' deploy_only=1 sprite_y_only=1 live_alpha_scan=0 logical_y_unchanged=1'+
      ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @motion_deploy_anchor_verified_v10311=true
  rescue
    log_event(:verify,'MOTION_DEPLOY_FOOT_ANCHOR_V10311 pass=0 error=1')
    @motion_deploy_anchor_verified_v10311=true
  end

  def update_verification_script
    pmd_ac_v10311_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    return if @verification_done==nil
    verify_motion_deploy_anchor_v10311 if @verification_frame.to_i>=199
  end
end
