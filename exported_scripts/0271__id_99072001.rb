#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Combat AI Data v0.72
# 分類：戰鬥 AI
#
# 【用途／機制】
# 定義選招、選目標、威脅、隊伍協同、預測與多單位連鎖評分。
#
# 【怎麼調整】
# 要調 AI 行為，優先修改 Data 腳本中的權重／門檻；不要回頭重寫 v0.15 Movement core。
#
# 【本腳本主要設定常數／資料表】
# - COMBAT_AI_MANIFEST_V072 / COMBAT_AI_TUNING_V072
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Combat AI Data v0.72
# Combat AI Integration V
#------------------------------------------------------------------------------
# Three-unit combo depth and short-horizon battle prediction over v0.71.
# No movement/basic-target/Weather/Field/damage-packet/Native-Pose rewrite.
#==============================================================================
module PMD_AC
  COMBAT_AI_MANIFEST_V072 = {
    :schema_version=>'1.0',
    :content_version=>'0.72.0',
    :base_version=>'0.71',
    :feature=>'combat_ai_integration_v',
    :selection_source=>'active_moves_v045_four_slot',
    :base_score=>'v0.71_ordered_combo_intent',
    :features=>[:three_unit_chain_depth,:reserved_damage_projection,
      :projected_ko_avoidance,:projected_ko_intent_release,
      :finisher_handoff,:weather_support_chain,
      :ordered_horizon_weighting,:target_reassignment],
    :movement_core=>'v0.15_unchanged',
    :basic_target_core=>'v0.15_unchanged',
    :skill_target_layer=>'v0.69_pair_scoring_carried',
    :threat_core=>'v0.70_hysteresis_carried',
    :intent_core=>'v0.71_24f_carried',
    :weather_field=>'v0.28+v0.35-v0.37_unchanged',
    :damage_packet=>'v0.60.2_unchanged',
    :native_router=>'v0.62_unchanged',
    :ability_slots=>1028,
    :ability_slots_total=>1193,
    :ability_species=>483,
    :move_runtime=>526,
    :learnset_coverage=>'7005/7005'
  }

  COMBAT_AI_TUNING_V072 = {
    :triple_chain_bonus=>22.0,
    :support_chain_cap=>2,
    :reserved_damage_scale=>0.90,
    :projected_ko_damage_factor=>0.18,
    :projected_ko_aoe_factor=>0.68,
    :projected_ko_target_penalty=>72.0,
    :finisher_hp_ratio=>0.25,
    :priority_finisher_bonus=>32.0,
    :execute_finisher_bonus=>16.0,
    :minimum_prediction_accuracy=>0.35,
    :weather_support_chain_bonus=>12.0,
    :planned_control_support=>1,
    :planned_break_support=>1,
    :planned_helping_support=>1,
    :planned_weather_support=>1
  }
end
