#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Presentation Flash & Sequence Config v0.57.2
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
# - PRESENTATION_FLASH_V0572 / TYPE_FLASH_RGB_V0572 / BEAM_STYLE_BY_TYPE_V0572 / MULTI_HIT_SEQUENCE_V0572
# - BEAM_SHOWCASE_MOVES_V0572
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Presentation Flash & Sequence Config v0.57.2
#------------------------------------------------------------------------------
# 【留給最後人工微調的演出設定】
# - 普通攻擊：出手前快速白色 Flash
# - 技能：依 18 屬性快速 Flash
# - Direct Hit：受擊者快速紅色 Flash
# - Beam：後續 :beam 技能統一轉到真正存在的 8 組 Ranger Beam Profile
# - Multi-hit：每一擊分幀播放 Attack/Shoot、Impact、SFX、Damage、Hurt
#==============================================================================
module PMD_AC
  PRESENTATION_FLASH_V0572 = {
    :enabled=>true,
    :basic_frames=>4,
    :basic_color=>[255,255,255,205],
    :skill_frames=>5,
    :skill_alpha=>190,
    :hit_frames=>5,
    :hit_color=>[255,45,45,220],
    :log=>true
  }

  TYPE_FLASH_RGB_V0572 = {
    :normal=>[245,245,245],
    :fire=>[255,92,36],
    :water=>[55,155,255],
    :electric=>[255,225,45],
    :grass=>[85,205,80],
    :ice=>[125,225,255],
    :fighting=>[220,70,55],
    :poison=>[180,85,210],
    :ground=>[205,160,75],
    :flying=>[145,195,255],
    :psychic=>[245,90,175],
    :bug=>[165,195,55],
    :rock=>[185,160,85],
    :ghost=>[120,90,185],
    :dragon=>[105,85,235],
    :dark=>[105,90,120],
    :steel=>[190,205,220],
    :fairy=>[250,155,205]
  }

  # 真正已存在的 Beam texture profile 只有這 8 組。
  # 後續 Move 的屬性 Style 會轉到最接近的一組，而不是掉回 species projectile_style。
  BEAM_STYLE_BY_TYPE_V0572 = {
    :normal=>:aurora,
    :fire=>:fire,
    :water=>:water,
    :electric=>:electric,
    :grass=>:aurora,
    :ice=>:ice,
    :fighting=>:fire,
    :poison=>:signal,
    :ground=>:steel_beam,
    :flying=>:aurora,
    :psychic=>:psychic_beam,
    :bug=>:signal,
    :rock=>:steel_beam,
    :ghost=>:psychic_beam,
    :dragon=>:signal,
    :dark=>:psychic_beam,
    :steel=>:steel_beam,
    :fairy=>:aurora
  }

  MULTI_HIT_SEQUENCE_V0572 = {
    :enabled=>true,
    :contact_interval=>7,
    :projectile_interval=>9,
    :other_interval=>8,
    :restart_pose_each_hit=>true,
    :repeat_launch_sfx=>true,
    :extend_action_until_last_hit=>true,
    :log_each_hit=>true
  }

  # Beam Showcase 專門回歸早期已做好的 Beam Grammar。
  BEAM_SHOWCASE_MOVES_V0572 = [
    :water_gun,:flamethrower,:hydro_pump,:ice_beam,:thunderbolt,
    :psybeam,:aurora_beam,:signal_beam,:flash_cannon,:charge_beam,
    :shock_wave,:hyper_beam,:solar_beam,:stored_power,:spacial_rend
  ]
end
