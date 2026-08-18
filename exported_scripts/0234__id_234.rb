#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Contact Ground-Y Tuning v0.57.5
# 分類：自走棋資料／設定
#
# 【用途／機制】
# 提供 PMD AutoChess 的資料表、常數或共用設定。
#
# 【怎麼調整】
# 修改時先找本頁「主要設定常數／資料表」，改完用對應 Verification Mode 驗證。
#
# 【本腳本主要設定常數／資料表】
# - CONTACT_GROUND_Y_V0575 / CONTACT_GROUND_Y_MOTIONS_V0575
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Contact Ground-Y Tuning v0.57.5
#------------------------------------------------------------------------------
# 【玩家可自行調整】接觸類動作的 Y 軸對齊。
# 目標：攻擊者抵達接觸位置時，Y 軸與目標的戰場 pixel_y 完全一致。
# 這支只改接觸移動/接戰位置，不改 Beam、Projectile、Impact、Target FX。
#==============================================================================
module PMD_AC
  CONTACT_GROUND_Y_V0575 = {
    :enabled=>true,
    :mode=>:target_pixel_y,
    :track_live_target_y=>true,
    :apply_visual_contact=>true,
    :apply_visual_commit=>true,
    :log_commit=>true
  }

  # 會真正貼近目標的 Motion。Fly / ranged cast / projectile / beam 不在此列。
  CONTACT_GROUND_Y_MOTIONS_V0575 = [
    :step_attack,:lunge_return,:contact_return,:dash_stop,:dash_return,
    :dash_through_return,:blink_return,:charge_dash,:multi_contact,:spin_contact,
    :dash_engage,:blink_engage
  ]
end
