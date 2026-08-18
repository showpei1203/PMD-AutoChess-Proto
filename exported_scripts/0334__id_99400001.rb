# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess PMD Motion Semantic Expansion v0.94
# 分類：戰鬥視覺／PMDCollab 動作語意／純 Presentation
#
# 【用途】
# 1. 寶可夢進入 AutoChess 戰場後，原本「沒有移動、沒有出招」時使用 Idle 的
#    常駐顯示，改成優先使用 Walk，讓角色即使站在原地也維持較有生命感的動態。
# 2. 擴充 v0.62 Native Semantic Router：突進、貼身、Contact 類招式若沒有更
#    專門的 Kick／Punch／Bite／Scratch／Slash／Tail／Spin 等姿勢，優先嘗試
#    PMDCollab 的 Hop / LeapForth，而不是一律退回 Attack / Strike。
# 3. 頭槌／頭部衝撞類招式額外優先嘗試 Head；重型衝撞類則優先 LeapForth，
#    輕／快速貼近類優先 Hop。沒有對應 PNG 時仍由既有 asset-aware fallback
#    自動退回原本 v0.62 選擇，因此不要求每隻寶可夢一定具有所有特殊動作。
#
# 【主要設定項】
# - BATTLE_REST_VISUAL_V094：戰鬥中靜止待機使用的視覺動作，預設 :walk。
# - CONTACT_DASH_MOTIONS_V094：哪些 Presentation motion 視為貼身／突進語意。
# - HEAD_RUSH_MOVES_V094：優先使用 Head 的頭部衝撞招式。
# - HEAVY_RUSH_MOVES_V094：優先使用 LeapForth 的重型突進招式。
# - GENERIC_CONTACT_POSES_V094：只有落到這些通用姿勢時才插入 Hop/LeapForth；
#   已經選到 Kick/Punch/Bite 等專門姿勢時不覆蓋。
#
# 【機制規則】
# - 只改 Sprite 的 visual_action；Game_PMDChessUnit 的 @action 邏輯仍維持 :idle，
#   因此 AI、Cooldown、Damage Packet、移動判定、攻擊距離完全不變。
# - Stun / Hurt / Evade / Faint / Skill / Attack 等既有戰鬥狀態優先，不會被 Walk
#   蓋掉。只有真正處於「邏輯 Idle」時才把視覺切成 Walk。
# - 多段攻擊仍由 v0.60.2 Hit→退步→再接近→下一擊的 Packet Driver 控制；
#   本腳本只挑更合適的 PMD 動作，不增加額外傷害段。
# - Hop / LeapForth / Head 都必須通過 v0.61 的 compiled action + 實體 PNG
#   availability 檢查；素材不存在時自動走舊 fallback。
# - v0.91.4 的 :advance 空間技能會被視為突進語意，但原本的位移距離與 AI
#   Utility 完全不改。
#
# 【可調參數】
# 想讓某招重型衝刺：加入 HEAVY_RUSH_MOVES_V094。
# 想讓某招用頭部動作：加入 HEAD_RUSH_MOVES_V094。
# 想把某個 Presentation motion 視為突進：加入 CONTACT_DASH_MOTIONS_V094。
# 若日後不想站立時 Walk，只需把 BATTLE_REST_VISUAL_V094 改回 :idle。
#
# 【事件／腳本呼叫方式】
# 正常戰鬥全自動，不需要事件呼叫。
# 開發時可查：
#   PMD_AC.native_pose_for_move_v060('0001', :tackle, data, profile)
#   PMD_AC.motion_contact_or_dash_v094?(:tackle, data, profile)
#
# 【實際範例】
# - 妙蛙種子站著等攻擊：邏輯 action=:idle，但 visual_action=:walk。
# - Tackle / Aqua Jet 等一般突進：若該寶可夢有 Hop/LeapForth，優先使用。
# - Headbutt / Zen Headbutt：若有 Head，優先 Head；沒有才 LeapForth/Hop/舊動作。
# - Double Kick：仍優先 Kick，不會因為「Contact」被粗暴改成 Hop。
# - Thunderbolt：仍優先 Shock/SpAttack，不受本腳本影響。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 禁止使用舊式 instance-variable reflection probe。
# - 不修改 v0.62 Native Semantic Router 原腳本，只做 Main 前 additive override。
# - 圖鑑 v0.93.1 仍維持 Idle 左前 45°預覽；「戰場常駐 Walk」只套戰鬥單位。
#==============================================================================
module PMD_AC
  PATCH_VERSION_MOTION_V094 = '0.94'
  BATTLE_REST_VISUAL_V094 = :walk

  CONTACT_DASH_MOTIONS_V094 = [
    :contact_return,:lunge_return,:step_attack,:charge_dash,
    :dash_return,:dash_stop,:dash_engage,:blink_return,:blink_engage,
    :dash_through_return,:spin_contact,:multi_contact
  ]

  HEAD_RUSH_MOVES_V094 = [
    :headbutt,:zen_headbutt,:head_smash,:skull_bash
  ]

  HEAVY_RUSH_MOVES_V094 = [
    :tackle,:take_down,:double_edge,:giga_impact,:retaliate,
    :volt_tackle,:wild_charge,:flame_charge,:aqua_jet
  ]

  # 只有目前 Router 已經落到「通用接觸姿勢」時才讓 Hop/LeapForth 插隊。
  # Kick / Punch / Bite / Scratch / Slice / QuickStrike 等專門姿勢不在此表。
  GENERIC_CONTACT_POSES_V094 = [
    :attack,:strike,:charge,:shoot,:sp_attack,:emit,nil
  ]

  class << self
    alias pmd_ac_v094_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v094_native_pose_candidates_v061)

    def normalized_move_key_v094(move_key)
      return :unknown if move_key==nil
      move_key.to_s.downcase.gsub(/[^a-z0-9]+/,'_').to_sym
    end

    def spatial_advance_move_v094?(move_key)
      return false unless const_defined?(:SPATIAL_MOVE_EXTENSIONS_V0914)
      k=normalized_move_key_v094(move_key)
      d=SPATIAL_MOVE_EXTENSIONS_V0914[k]
      return false if d==nil
      d[:kind]==:advance
    end

    def motion_contact_or_dash_v094?(move_key,data=nil,profile=nil)
      motion=profile==nil ? nil : profile[:motion]
      return true if CONTACT_DASH_MOTIONS_V094.include?(motion)
      if data!=nil
        return true if data[:contact]
        flags=data[:source_move_flags]
        if flags!=nil
          flags.each do |f|
            return true if f.to_s=='contact'
          end
        end
      end
      return true if spatial_advance_move_v094?(move_key)
      false
    end

    def generic_contact_candidate_v094?(candidates)
      return true if candidates==nil || candidates.empty?
      GENERIC_CONTACT_POSES_V094.include?(candidates[0])
    end

    # 這裡包住「目前最新版」v0.62 native_pose_candidates_v061。
    # 先讓既有語意選 Kick/Punch/Bite/...，只有仍屬 generic contact 才補 Hop。
    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      k=normalized_move_key_v094(move_key)
      base=pmd_ac_v094_native_pose_candidates_v061(species,k,data,profile)
      out=[]

      if HEAD_RUSH_MOVES_V094.include?(k)
        out=[:head,:leap_forth,:hop]
      elsif HEAVY_RUSH_MOVES_V094.include?(k) && generic_contact_candidate_v094?(base)
        out=[:leap_forth,:hop]
      elsif motion_contact_or_dash_v094?(k,data,profile) && generic_contact_candidate_v094?(base)
        out=[:hop,:leap_forth]
      end

      append_unique_poses_v061(out,base)
      out
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit
#------------------------------------------------------------------------------
#  邏輯 Idle 保留，只有場上常駐 visual_action 改成 Walk。
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v094_refresh_motion_visual refresh_motion_visual unless method_defined?(:pmd_ac_v094_refresh_motion_visual)
  alias pmd_ac_v094_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v094_deploy_to_cell)
  alias pmd_ac_v094_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v094_deploy_to_pixel)
  alias pmd_ac_v094_clear_multi_sequence_lock_v060 clear_multi_sequence_lock_v060 unless method_defined?(:pmd_ac_v094_clear_multi_sequence_lock_v060)

  def apply_battle_rest_visual_v094
    return if dead?
    return if acting?
    return if @stun_frames.to_i>0
    return if @hurt_frames.to_i>0
    return if @evade_visual_frames.to_i>0
    return if @victory_celebrating
    @visual_action=PMD_AC::BATTLE_REST_VISUAL_V094
  end

  def refresh_motion_visual
    pmd_ac_v094_refresh_motion_visual
    apply_battle_rest_visual_v094
  end

  def deploy_to_cell(x,y)
    pmd_ac_v094_deploy_to_cell(x,y)
    apply_battle_rest_visual_v094
  end

  def deploy_to_pixel(x,y)
    pmd_ac_v094_deploy_to_pixel(x,y)
    apply_battle_rest_visual_v094
  end

  def clear_multi_sequence_lock_v060
    pmd_ac_v094_clear_multi_sequence_lock_v060
    apply_battle_rest_visual_v094
  end
end
