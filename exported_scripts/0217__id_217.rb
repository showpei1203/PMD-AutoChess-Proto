#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Presentation Cadence Tuning v0.55.2
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
# - PRESENTATION_CADENCE_V0552 / ENGAGE_STAY_MOVES_V0552 / MOVE_CADENCE_OVERRIDES_V0552 / RANGED_VISUAL_KINDS_V0552
# - RANGED_DAMAGE_VISUAL_KINDS_V0552 / MOTION_LIBRARY_V0552
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Presentation Cadence Tuning v0.55.2
#------------------------------------------------------------------------------
# 【玩家可自行調整】AutoChess 戰鬥演出節奏、突進停留、遠程施法與 Fly 俯衝。
# 這支集中處理「看起來怎麼打」，數值、傷害、AI 與一般命中率仍由原 Runtime 控制。
#==============================================================================
module PMD_AC
  PRESENTATION_CADENCE_V0552 = {
    # 接近/返回要快，打中後要停一下。單位都是 frame (60fps)。
    :contact_approach_frames=>5,
    :dash_approach_frames=>4,
    :charge_approach_frames=>6,
    :blink_approach_frames=>1,
    :contact_return_frames=>5,
    :dash_return_frames=>4,
    :charge_return_frames=>6,
    :impact_hold_frames=>7,
    :heavy_impact_hold_frames=>9,
    :multi_impact_hold_frames=>5,

    # Showcase 只負責看演出，故縮短走位、保留明顯的命中停頓。
    :showcase_min_total_frames=>30,
    :showcase_min_pre_hit_frames=>9,
    :showcase_interval_frames=>104,

    # 目標受擊。若目標正在施放重要技能/兩段技，保留其施法 Pose，只做 recoil + impact VFX。
    :target_hurt_pose=>:hurt,
    :target_hurt_frames=>10,
    :target_hurt_busy_skill=>false,
    :target_hurt_basic_attack=>true,
    :target_recoil_on_busy=>true,

    # 遠程技能：有傷害的遠程預設 Shoot；支援/場地/狀態預設 Charge。
    :ranged_damage_cast_pose=>:shoot,
    :ranged_support_cast_pose=>:charge,
    :ranged_cast_log=>true,

    # 真正 Gap Closer：技能命中後把邏輯位置提交到目標旁，而不是回原位。
    :engage_default_gap=>18.0,
    :engage_max_cast_range=>132.0,
    :engage_commit_after_hit=>true,

    # Fly：高空蓄力 → 快速俯衝 → 穿過目標少許 → 短停 → 弧線高速返回原位置。
    :fly_high_y=>-46.0,
    :fly_ascent_frames=>10,
    :fly_dive_frames=>8,
    :fly_impact_frame=>6,
    :fly_overshoot_px=>20.0,
    :fly_impact_hold_frames=>5,
    :fly_return_frames=>9,
    :fly_return_arc_y=>-20.0
  }

  # 這些招式是「貼近後留在敵人身邊」的戰術位移。
  # 最後可自行增減。Quick Attack / U-turn 等刻意不放，仍為演出後回原位。
  ENGAGE_STAY_MOVES_V0552 = {
    :pursuit=>{:motion=>:dash_engage,:gap=>18.0,:cast_range=>132.0},
    :sucker_punch=>{:motion=>:blink_engage,:gap=>14.0,:cast_range=>126.0},
    :aqua_jet=>{:motion=>:dash_engage,:gap=>16.0,:cast_range=>126.0},
    :mach_punch=>{:motion=>:dash_engage,:gap=>16.0,:cast_range=>112.0},
    :bullet_punch=>{:motion=>:dash_engage,:gap=>16.0,:cast_range=>116.0},
    :shadow_sneak=>{:motion=>:blink_engage,:gap=>14.0,:cast_range=>128.0},
    :flame_charge=>{:motion=>:dash_engage,:gap=>16.0,:cast_range=>126.0}
  }

  # 單招節奏微調。attack_hold 是「命中後維持 Attack Sprite」的時間。
  MOVE_CADENCE_OVERRIDES_V0552 = {
    :tackle=>{:approach_frames=>5,:attack_hold=>7,:return_frames=>5},
    :slash=>{:approach_frames=>4,:attack_hold=>8,:return_frames=>5},
    :quick_attack=>{:approach_frames=>3,:attack_hold=>5,:return_frames=>3},
    :sucker_punch=>{:approach_frames=>1,:attack_hold=>7},
    :pursuit=>{:approach_frames=>4,:attack_hold=>7},
    :flame_wheel=>{:approach_frames=>5,:attack_hold=>9,:return_frames=>5},
    :double_kick=>{:approach_frames=>4,:attack_hold=>5,:return_frames=>5},
    :rapid_spin=>{:approach_frames=>4,:attack_hold=>6,:return_frames=>5},
    :u_turn=>{:approach_frames=>3,:attack_hold=>5,:return_frames=>4},
    :fly=>{:attack_hold=>5}
  }

  RANGED_VISUAL_KINDS_V0552 = [:projectile,:beam,:target_hit,:area_hit,:field_disc,:self_fx]
  RANGED_DAMAGE_VISUAL_KINDS_V0552 = [:projectile,:beam,:target_hit,:area_hit]
  MOTION_LIBRARY_V0552 = [:dash_engage,:blink_engage]
end
