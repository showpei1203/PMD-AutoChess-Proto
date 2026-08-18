#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Presentation Hit Feedback Tuning v0.55.3
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
# - PRESENTATION_HIT_FEEDBACK_V0553
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Presentation Hit Feedback Tuning v0.55.3
#------------------------------------------------------------------------------
# User-editable presentation settings.  These values affect presentation only
# unless explicitly labelled SHOWCASE.  Normal battle accuracy / range rules
# are not changed by SHOWCASE options.
#==============================================================================
module PMD_AC
  PRESENTATION_HIT_FEEDBACK_V0553 = {
    # MOTION_SHOWCASE is a visual audit.  Contact demos are allowed to resolve
    # at the fixed 90px staging distance so Hit/Hurt/SFX can actually be seen.
    :showcase_force_contact_in_range => true,
    :showcase_force_accuracy        => true,
    :showcase_prime_reactive_moves  => true,

    # Audible impact floor used only in MOTION_SHOWCASE.  Existing per-move
    # audio profiles are preserved; their volume is lifted to this minimum.
    :showcase_hit_volume_min        => 94,
    :showcase_cast_volume_min       => 72,
    :showcase_launch_volume_min     => 80,

    # If a canonical move has no usable Hit category, use a real Impact_Mid SE.
    :showcase_hit_fallback_name     => "PMD_SFX_Library/Pokemon_Ranger/Impact_Mid/RGR_Impact_Mid_003",
    :showcase_hit_fallback_volume   => 96,
    :showcase_hit_fallback_pitch    => 100,

    # Visual-only target recoil layered on top of the PMD Hurt action.
    :target_recoil_enabled          => true,
    :target_recoil_px               => 6.0,
    :target_recoil_frames           => 9,

    # Keep the PMD Hurt pose readable for successful direct hits.
    :target_hurt_frames_min         => 12,

    # Debug logging makes the visual audit objective instead of interpretive.
    :log_showcase_force_hit         => true,
    :log_showcase_sfx               => true,
    :log_target_recoil              => true
  }
end
