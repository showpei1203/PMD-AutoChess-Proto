#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Presentation User Config v0.55
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
# - PRESENTATION_GLOBAL_V055 / MOTION_DEFAULTS_V055 / MOVE_PRESENTATION_USER_OVERRIDES_V055
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Presentation User Config v0.55
#------------------------------------------------------------------------------
# 【這一支就是留給最後人工微調的設定腳本】
# 不必修改傷害公式、AI、Move Runtime。
#
# 可調整：
#   1. 全域近戰/衝刺距離、回程節奏
#   2. 每一招的角色 Motion
#   3. 每一招的 PMD Pose（若該寶可夢沒有該 Pose，會安全沿用原技能動作）
#   4. Visual Kind / VFX Style
#   5. Cast / Launch / Hit 音效、音量、Pitch
#
# motion 可用值：
#   :stationary_cast      原地施法
#   :step_attack          往前踏一步
#   :lunge_return         小幅前衝 -> 命中 -> 回原位
#   :contact_return       貼近接觸 -> 命中 -> 回原位
#   :dash_stop            快速突進（純演出；結束會回邏輯座標）
#   :dash_return          高速突進 -> 命中 -> 回原位
#   :dash_through_return  穿過目標 -> 回原位
#   :blink_return         瞬身到目標旁 -> 命中 -> 回原位
#   :charge_dash          蓄勢高速撞擊 -> 命中 -> 回原位
#   :multi_contact        連續近戰型
#   :spin_contact         旋轉接觸型
#   :runtime_owned        Fly/Dig/Dive 等由既有 Runtime 自己控制
#
# 注意：這裡的 Motion 預設全部是「視覺位移」，不修改 AutoChess 真正座標。
#       Knockback / Pull / Teleport / Ally Switch 等真正位移仍由戰鬥 Runtime 管理。
#==============================================================================
module PMD_AC
  PRESENTATION_GLOBAL_V055 = {
    :enabled=>true,
    :sfx_volume_mult=>1.00,
    :sfx_pitch_add=>0,
    :motion_speed_mult=>1.00,
    :impact_scale_mult=>1.00
  }

  MOTION_DEFAULTS_V055 = {
    :step_attack=>{:travel_px=>8.0,:contact_gap=>22.0,:motion_speed=>1.00,:hold_frames=>2},
    :lunge_return=>{:travel_px=>18.0,:contact_gap=>20.0,:motion_speed=>1.00,:hold_frames=>3},
    :contact_return=>{:travel_px=>42.0,:contact_gap=>18.0,:motion_speed=>1.00,:hold_frames=>4},
    :dash_stop=>{:travel_px=>72.0,:contact_gap=>16.0,:motion_speed=>1.35,:hold_frames=>4},
    :dash_return=>{:travel_px=>84.0,:contact_gap=>16.0,:motion_speed=>1.45,:hold_frames=>3},
    :dash_through_return=>{:travel_px=>92.0,:contact_gap=>10.0,:pass_px=>24.0,:motion_speed=>1.45,:hold_frames=>2},
    :blink_return=>{:travel_px=>128.0,:contact_gap=>14.0,:motion_speed=>2.40,:hold_frames=>5},
    :charge_dash=>{:travel_px=>78.0,:contact_gap=>14.0,:motion_speed=>1.18,:hold_frames=>5,:recoil_px=>7.0},
    :multi_contact=>{:travel_px=>44.0,:contact_gap=>18.0,:motion_speed=>1.10,:hold_frames=>4,:wobble_px=>5.0},
    :spin_contact=>{:travel_px=>48.0,:contact_gap=>18.0,:motion_speed=>1.20,:hold_frames=>4}
  }

  # ---------------------------------------------------------------------------
  # 每招 Override。最後自行微調，直接在這裡加/改即可。
  # 未列出的招式會由 v0.55 自動分類，因此不用手填 400 招。
  #
  # 音效欄位可填 Audio/SE 中的檔名（不含副檔名）：
  # :cast_se=>"檔名", :launch_se=>"檔名", :hit_se=>"檔名"
  # :sfx_volume=>80, :sfx_pitch=>100
  #
  # VFX：:visual_kind / :vfx_style 會覆寫既有 Skill Visual Profile。
  # ---------------------------------------------------------------------------
  MOVE_PRESENTATION_USER_OVERRIDES_V055 = {
    :tackle=>{:motion=>:contact_return,:pose=>:attack,:travel_px=>38.0,:hit_se=>nil},
    :slash=>{:motion=>:lunge_return,:pose=>:attack,:travel_px=>28.0},
    :false_swipe=>{:motion=>:lunge_return,:pose=>:attack,:travel_px=>28.0},
    :quick_attack=>{:motion=>:dash_return,:pose=>:attack,:travel_px=>86.0,:motion_speed=>1.60},
    :sucker_punch=>{:motion=>:blink_return,:pose=>:attack,:travel_px=>118.0},
    :pursuit=>{:motion=>:dash_stop,:pose=>:attack,:travel_px=>70.0},
    :u_turn=>{:motion=>:dash_through_return,:pose=>:attack,:travel_px=>88.0,:pass_px=>26.0},
    :flame_wheel=>{:motion=>:charge_dash,:pose=>:attack,:travel_px=>72.0,:vfx_style=>:fire},
    :flare_blitz=>{:motion=>:charge_dash,:pose=>:attack,:travel_px=>86.0,:vfx_style=>:fire},
    :volt_tackle=>{:motion=>:charge_dash,:pose=>:attack,:travel_px=>88.0,:vfx_style=>:electric},
    :wild_charge=>{:motion=>:charge_dash,:pose=>:attack,:travel_px=>82.0,:vfx_style=>:electric},
    :double_kick=>{:motion=>:multi_contact,:pose=>:attack,:wobble_px=>6.0},
    :fury_swipes=>{:motion=>:multi_contact,:pose=>:attack,:wobble_px=>7.0},
    :double_slap=>{:motion=>:multi_contact,:pose=>:attack,:wobble_px=>6.0},
    :rapid_spin=>{:motion=>:spin_contact,:pose=>:attack,:travel_px=>46.0},
    :rollout=>{:motion=>:spin_contact,:pose=>:attack,:travel_px=>52.0},
    :hydro_pump=>{:motion=>:stationary_cast,:pose=>:shoot,:vfx_style=>:water},
    :flamethrower=>{:motion=>:stationary_cast,:pose=>:shoot,:vfx_style=>:fire},
    :solar_beam=>{:motion=>:stationary_cast,:pose=>:shoot},
    :fly=>{:motion=>:runtime_owned},
    :bounce=>{:motion=>:runtime_owned},
    :dive=>{:motion=>:runtime_owned},
    :dig=>{:motion=>:runtime_owned},
    :shadow_force=>{:motion=>:runtime_owned}
  }
end
