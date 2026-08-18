#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Target Anchor Tuning v0.57.3
# 分類：自走棋資料／設定
#
# 【用途／機制】
# 提供 PMD AutoChess 的資料表、常數或共用設定。
#
# 【怎麼調整】
# 修改時先找本頁「主要設定常數／資料表」，改完用對應 Verification Mode 驗證。
#
# 【本腳本主要設定常數／資料表】
# - TARGET_ANCHOR_V0573 / BEAM_SEAM_TUNING_V0573 / TARGET_ANCHOR_SPECIES_OVERRIDES_V0573
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Target Anchor / Beam Seam Tuning v0.57.3
#------------------------------------------------------------------------------
# User-editable presentation tuning.
# - Target impact anchors use the visible Pokemon sprite's opaque lower body,
#   rather than the old rectangular-frame geometric center.
# - Water beam body/head overlap is exposed here for final visual tuning.
#==============================================================================
module PMD_AC
  TARGET_ANCHOR_V0573 = {
    :enabled=>true,
    # 0.0 = top of visible opaque body, 1.0 = visible foot/bottom.
    # 0.74 intentionally lands attacks between torso and feet.
    :lower_body_ratio=>0.74,
    :fallback_lower_body_ratio=>0.72,
    :alpha_threshold=>8,
    :scan_step=>1,
    :max_x_shift=>12.0,
    :prefer_idle_bounds=>true,
    :apply_effect_anchor=>true,
    :apply_skill_beam=>true,
    :apply_arena_beam=>true,
    :apply_special_target_fx=>true,
    :showcase_anchor_markers=>true,
    :log_showcase=>true
  }

  # Water Gun and Hydro Pump use the same water beam profile.  The source art
  # contains transparent edge pixels between body and head, so pure geometric
  # butt-joining can show a seam.  Overlap hides that transparent seam.
  BEAM_SEAM_TUNING_V0573 = {
    :water_head_body_overlap_px=>8.0,
    :default_head_body_overlap_px=>0.0
  }

  # Per-species/manual final tuning hook. Values are SCREEN-pixel offsets after
  # automatic opaque-bound anchoring. Example:
  # "0149"=>{:x=>0.0,:y=>4.0}
  TARGET_ANCHOR_SPECIES_OVERRIDES_V0573 = {
  }
end
