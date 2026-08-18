#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Target FX Beam Tuning v0.57.4
# 分類：自走棋資料／設定
#
# 【用途／機制】
# 提供 PMD AutoChess 的資料表、常數或共用設定。
#
# 【怎麼調整】
# 修改時先找本頁「主要設定常數／資料表」，改完用對應 Verification Mode 驗證。
#
# 【本腳本主要設定常數／資料表】
# - TARGET_FX_ANCHOR_V0574 / WATER_BEAM_RENDER_V0574
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Target FX / Water Beam Tuning v0.57.4
#------------------------------------------------------------------------------
# User-editable presentation tuning.
# - Aim / travel anchors remain on the visible lower body from v0.57.3.
# - Target-bound animation sprites return to the legacy visual-center height.
# - Water Beam defaults to BODY-ONLY rendering to avoid the thick-head / thin-
#   body mismatch of Ranger_109 + Ranger_105.
#==============================================================================
module PMD_AC
  TARGET_FX_ANCHOR_V0574 = {
    :mode=>:legacy_visual_center,
    :apply_impact=>true,
    :apply_status_event=>true,
    :apply_column=>true,
    :apply_projectile_impact=>true,
    :apply_special_target_fx=>true,
    :log_showcase=>true
  }

  WATER_BEAM_RENDER_V0574 = {
    # :none = use Ranger_105 alone across the whole beam.  This keeps one
    # continuous silhouette and removes the Ranger_109 thickness mismatch.
    # :composite = restore the separate Ranger_109 head for manual tuning.
    :head_mode=>:none,
    :body_thickness=>0.62,
    :composite_body_thickness=>0.70,
    :composite_head_zoom_y=>0.70,
    :composite_overlap_px=>8.0
  }
end
