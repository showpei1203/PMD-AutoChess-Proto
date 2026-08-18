#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Contact Visible Baseline Tuning v0.57.6
# 分類：自走棋資料／設定
#
# 【用途／機制】
# 提供 PMD AutoChess 的資料表、常數或共用設定。
#
# 【怎麼調整】
# 修改時先找本頁「主要設定常數／資料表」，改完用對應 Verification Mode 驗證。
#
# 【本腳本主要設定常數／資料表】
# - CONTACT_VISIBLE_BASELINE_V0576
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Contact Visible Baseline Tuning v0.57.6
#------------------------------------------------------------------------------
# 【玩家可自行調整】接觸攻擊的視覺地面線修正。
# v0.57.5 已讓 Sprite 的座標 Y 等於目標 pixel_y，但 PMD PNG 在不同動作
# 底部有不同透明留白，因此肉眼看到的「腳底」仍可能不在同一水平線。
# 本層只補償接觸攻擊者的可見腳底，不改 Beam / Projectile / Impact / Target FX。
#==============================================================================
module PMD_AC
  CONTACT_VISIBLE_BASELINE_V0576 = {
    :enabled=>true,
    :target_reference_action=>:idle,
    :alpha_threshold=>8,
    :scan_step=>1,
    :max_correction_px=>32.0,
    :log=>true
  }
end
