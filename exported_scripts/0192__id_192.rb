#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Identity Growth Data v0.45
# 分類：成長／進化／學招
#
# 【用途／機制】
# 處理等級、EXP、四招配置、技能熟練、待學技能、進化與玩家成長流程。
#
# 【怎麼調整】
# 個體操作範例：instance.known_moves_v045；四招設定使用 set_active_moves_v045。
#
# 【本腳本主要設定常數／資料表】
# - IDENTITY_GROWTH_MANIFEST_V045 / PARTY_CAPACITY_V045 / STORAGE_BOX_COUNT_V045 / STORAGE_BOX_CAPACITY_V045
# - ACTIVE_MOVE_SLOTS_V045 / MOVE_LEVEL_MAX_V045 / MOVE_MASTERY_THRESHOLDS_V045
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Identity / Growth Bridge Data v0.45
#===============================================================================
module PMD_AC
  IDENTITY_GROWTH_MANIFEST_V045 = {:schema_version=>"1.0",:content_version=>"0.45.0",:base_version=>"0.44",:feature=>"party_storage_clone_identity_bridge_and_rpg_growth_data_foundation",:identity_source=>"PMD_PokemonInstance",:identity_key=>"instance_uid",:party_capacity=>3,:storage_box_count=>24,:storage_box_capacity=>30,:runtime_actor_identity=>false,:template_actor_identity=>false,:active_move_slots=>4,:move_level_max=>5,:move_mastery_thresholds=>[0,10,30,70,150],:pokemon_level_max=>100,:canonical_learnset_ruleset=>"black_white",:growth_status=>{:level_exp=>"existing_v012_runtime_preserved",:battle_exp=>"existing_v012_reward_preserved",:canonical_level_learn=>"v045_persistent_known_move_bridge",:active_move_slots=>"v045_persistent_data_only_not_yet_combat_selection",:move_mastery=>"v045_persistent_data_and_per_use_gain",:move_mastery_combat_bonus=>"deferred_v046",:growth_ui=>"deferred_v046"},:runtime_checksum32=>182612967}
  PARTY_CAPACITY_V045 = 3
  STORAGE_BOX_COUNT_V045 = 24
  STORAGE_BOX_CAPACITY_V045 = 30
  ACTIVE_MOVE_SLOTS_V045 = 4
  MOVE_LEVEL_MAX_V045 = 5
  MOVE_MASTERY_THRESHOLDS_V045 = [0,10,30,70,150]
end
