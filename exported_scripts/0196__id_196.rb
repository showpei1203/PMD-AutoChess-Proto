#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Progression UI Data v0.47
# 分類：成長／進化／學招
#
# 【用途／機制】
# 處理等級、EXP、四招配置、技能熟練、待學技能、進化與玩家成長流程。
#
# 【怎麼調整】
# 個體操作範例：instance.known_moves_v045；四招設定使用 set_active_moves_v045。
#
# 【本腳本主要設定常數／資料表】
# - PROGRESSION_UI_MANIFEST_V047
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess RPG Progression UI Data v0.47
#===============================================================================
module PMD_AC
  PROGRESSION_UI_MANIFEST_V047 = {:schema_version=>"1.0",:content_version=>"0.47.0",:base_version=>"0.46",:feature=>"rpg_progression_ui_and_move_management_i",:identity_key=>"instance_uid",:open_phase=>"deploy",:open_input=>"Input::Z",:party_source=>"uid_registry",:active_move_slots=>4,:known_move_library_persistent=>true,:pending_move_resolution=>true,:non_executable_move_lock=>true,:move_mastery_display=>true,:move_level_max=>5,:exp_display=>true,:level_max=>100,:party_switch_inputs=>["Input::L","Input::R"],:ui_size=>[544,416],:ui_z=>9950,:runtime_moves=>262,:learnset_reference_covered=>4333,:learnset_reference_total=>7005,:next_phase=>"move_mastery_policy_ii",:runtime_checksum32=>685670198}
end
