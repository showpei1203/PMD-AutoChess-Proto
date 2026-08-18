#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Presentation Contact Tuning v0.55.1
# 分類：動畫／Presentation
#
# 【用途／機制】
# 處理 PMDCollab Native Pose、接近／攻擊／受擊、Beam、Projectile、Impact、Target FX
#  與畫面節奏。
#
# 【怎麼調整】
# 外觀調整優先改 Config / Tuning；不要改傷害 packet。接觸多段仍由 v0.60.2 負責傷害節奏。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_CONTACT_TUNING_V0551 / CONTACT_MOTIONS_V0551 / MOVE_CONTACT_TUNING_OVERRIDES_V0551
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Presentation Contact Tuning v0.55.1
#------------------------------------------------------------------------------
# 【玩家可自行調整】v0.55.1 接觸動作與受擊演出設定。
# 這支只控制演出，不修改 AutoChess 邏輯座標、傷害、AI 或技能命中率。
#==============================================================================
module PMD_AC
  PRESENTATION_CONTACT_TUNING_V0551 = {
    # 接觸動作會依「目前使用者 -> 目標」距離自動貼近，不再只走固定 travel_px。
    :target_aware_contact=>true,
    :max_visual_travel=>180.0,

    # 接觸中心距離。數字越小，Sprite 越貼近甚至略為重疊。
    :default_contact_gap=>14.0,
    :tackle_contact_gap=>12.0,
    :slash_contact_gap=>14.0,

    # MOTION_SHOWCASE 專用。只把展示放慢，不改正常戰鬥節奏。
    :showcase_min_total_frames=>42,
    :showcase_min_pre_hit_frames=>18,
    :showcase_force_hit=>true,
    :showcase_disable_active_evade=>true,

    # 接觸技能實際造成 HP 傷害時，目標短暫切換 PMD :hurt 動作。
    :contact_hit_reaction=>true,
    :hit_reaction_pose=>:hurt,
    :hit_reaction_frames=>12
  }

  CONTACT_MOTIONS_V0551 = [
    :step_attack,:lunge_return,:contact_return,:dash_stop,:dash_return,
    :dash_through_return,:blink_return,:charge_dash,:multi_contact,:spin_contact
  ]

  # 單招接觸距離 Override。最後可自行新增，例如：
  # :bite=>{:contact_gap=>10.0}
  MOVE_CONTACT_TUNING_OVERRIDES_V0551 = {
    :tackle=>{:contact_gap=>12.0},
    :slash=>{:contact_gap=>14.0},
    :false_swipe=>{:contact_gap=>14.0},
    :quick_attack=>{:contact_gap=>12.0},
    :sucker_punch=>{:contact_gap=>10.0},
    :flame_wheel=>{:contact_gap=>10.0},
    :double_kick=>{:contact_gap=>12.0},
    :rapid_spin=>{:contact_gap=>12.0},
    :u_turn=>{:contact_gap=>10.0}
  }
end
