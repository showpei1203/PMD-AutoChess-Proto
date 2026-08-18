#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Altitude Data v0.38
# 分類：高度／兩回合動作
#
# 【用途／機制】
# 處理飛行、Gravity、Dive、Dig、Fly 等高度與半潛地狀態。
#
# 【怎麼調整】
# 新增兩回合招式時要同時處理 phase、可選目標與視覺姿勢，避免第一段結束後卡住。
#
# 【本腳本主要設定常數／資料表】
# - ALTITUDE_MANIFEST_V038 / ALTITUDE_POSE_V038
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.38 Altitude / Grounded Data
module PMD_AC
  ALTITUDE_MANIFEST_V038 = {
    :schema_version=>"1.0",
    :content_version=>"0.38.0",
    :base_version=>"0.37",
    :feature=>"grounded_airborne_altitude_visual_state_i",
    :cumulative_mapped_move_count=>232,
    :learnset_reference_total=>7005,
    :cumulative_reference_covered=>3885,
    :cumulative_coverage_percent=>55.46,
    :pose_count=>5,
    :natural_airborne_sources=>[:flying_type,:levitate],
    :gravity_forces_ground=>true,
    :gravity_restores_ground_move_hit=>true,
    :airborne_base_y=>-10,
    :airborne_bob_amp=>3,
    :airborne_bob_period=>48,
    :semi_phase_y=>6,
    :semi_phase_opacity=>150,
    :bars_follow_altitude=>false,
    :sprite_z_uses_ground_baseline=>true,
    :transient_pose_api=>:set_altitude_pose_v038,
    :movement_lock_for=>[:submerged,:underground,:vanished],
    :future_move_hooks=>[:fly,:bounce,:dive,:dig,:shadow_force],
    :runtime_checksum32=>944040194,
  }
  ALTITUDE_POSE_V038 = {
    :ground=>{:base_y=>0,:bob_amp=>0,:bob_period=>0,:opacity=>255,:tone=>[0,0,0,0],:movement_locked=>false},
    :airborne=>{:base_y=>-10,:bob_amp=>3,:bob_period=>48,:opacity=>255,:tone=>[0,0,0,0],:movement_locked=>false},
    :submerged=>{:base_y=>6,:bob_amp=>0,:bob_period=>0,:opacity=>150,:tone=>[-35,0,70,0],:movement_locked=>true},
    :underground=>{:base_y=>6,:bob_amp=>0,:bob_period=>0,:opacity=>150,:tone=>[45,18,-28,0],:movement_locked=>true},
    :vanished=>{:base_y=>-2,:bob_amp=>0,:bob_period=>0,:opacity=>72,:tone=>[30,-20,60,0],:movement_locked=>true},
  }
end
