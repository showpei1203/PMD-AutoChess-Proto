#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Progression Flow Data v0.77
# 分類：成長／進化／學招
#
# 【用途／機制】
# 處理等級、EXP、四招配置、技能熟練、待學技能、進化與玩家成長流程。
#
# 【怎麼調整】
# 個體操作範例：instance.known_moves_v045；四招設定使用 set_active_moves_v045。
#
# 【本腳本主要設定常數／資料表】
# - PROGRESSION_FLOW_VERSION_V077 / PROGRESSION_FLOW_VERIFY_END_V077 / PROGRESSION_FLOW_MANIFEST_V077
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Progression Flow Data v0.77
# Evolution + Move Learning + Player Progression Flow
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  PROGRESSION_FLOW_VERSION_V077 = "0.77"
  PROGRESSION_FLOW_VERIFY_END_V077 = 18
  PROGRESSION_FLOW_MANIFEST_V077 = {
    :schema_version=>"1.0",
    :content_version=>"0.77.0",
    :base_version=>"0.76",
    :feature=>"evolution_move_learning_progression_flow",
    :identity_key=>"instance_uid",
    :active_move_slots=>4,
    :known_move_library=>"persistent",
    :pending_move_policy=>"replace_or_dismiss_library_retained",
    :simple_level_evolution=>"existing_auto",
    :branch_evolution=>"player_choice_at_unlock_level",
    :branch_input=>"Input::X",
    :branch_physical_key=>"A",
    :additional_spawn_evolution=>"deferred",
    :canonical_trigger_metadata=>"preserved_display_only",
    :progression_ui=>"v0.47+v0.76+v0.77",
    :stats_growth=>"v0.76",
    :battle_balance=>"v0.75",
    :basic_attack_sfx=>"v0.75.1"
  }
end
