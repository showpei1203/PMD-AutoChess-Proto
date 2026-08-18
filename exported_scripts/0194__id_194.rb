#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Progression Data v0.46
# 分類：成長／進化／學招
#
# 【用途／機制】
# 處理等級、EXP、四招配置、技能熟練、待學技能、進化與玩家成長流程。
#
# 【怎麼調整】
# 個體操作範例：instance.known_moves_v045；四招設定使用 set_active_moves_v045。
#
# 【本腳本主要設定常數／資料表】
# - PROGRESSION_RUNTIME_MANIFEST_V046 / PROGRESSION_MOVE_LEVEL_MULT_V046 / PROGRESSION_EXP_ALIVE_RATE_V046 / PROGRESSION_EXP_FAINTED_RATE_V046
# - PROGRESSION_EXP_RESERVE_RATE_V046 / PROGRESSION_EXP_SUMMON_RATE_V046
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess RPG Progression Data v0.46
#===============================================================================
module PMD_AC
  PROGRESSION_RUNTIME_MANIFEST_V046 = {:schema_version=>"1.0",:content_version=>"0.46.0",:base_version=>"0.45",:feature=>"rpg_progression_runtime_i",:identity_key=>"instance_uid",:level_max=>100,:growth_groups=>["erratic","fast","medium_fast","medium_slow","slow","fluctuating"],:growth_level100_totals=>{:erratic=>600000,:fast=>800000,:medium_fast=>1000000,:medium_slow=>1059860,:slow=>1250000,:fluctuating=>1640000},:active_move_slots=>4,:move_level_max=>5,:move_mastery_thresholds=>[0,10,30,70,150],:move_level_multipliers=>[1,1.05,1.1,1.15,1.2],:move_level_scaled_effects=>["damage","heal","shield","hot"],:status_mastery_bonus=>"deferred",:battle_exp=>{:deployed_alive_rate=>1,:deployed_fainted_rate=>0.5,:reserve_rate=>0,:summon_rate=>0,:split_by_deployed_count=>true},:move_learning=>{:canonical_level_up=>true,:learned_library_persistent=>true,:battle_loadout_slots=>4,:overflow=>"pending_replacement",:replacement_preserves_mastery=>true},:battle_move_selection=>{:source=>"active_moves_v045",:fallback=>"legacy_profile_skill_if_no_executable_active_move",:mode=>"deterministic_context_score"},:canonical_runtime_moves=>262,:learnset_reference_covered=>4333,:learnset_reference_total=>7005,:coverage_percent=>61.86,:runtime_checksum32=>2054714170}
  PROGRESSION_MOVE_LEVEL_MULT_V046 = [1.00,1.05,1.10,1.15,1.20]
  PROGRESSION_EXP_ALIVE_RATE_V046 = 1.00
  PROGRESSION_EXP_FAINTED_RATE_V046 = 0.50
  PROGRESSION_EXP_RESERVE_RATE_V046 = 0.00
  PROGRESSION_EXP_SUMMON_RATE_V046 = 0.00
end
