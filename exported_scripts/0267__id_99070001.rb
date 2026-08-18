#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Combat AI Data v0.70
# 分類：戰鬥 AI
#
# 【用途／機制】
# 定義選招、選目標、威脅、隊伍協同、預測與多單位連鎖評分。
#
# 【怎麼調整】
# 要調 AI 行為，優先修改 Data 腳本中的權重／門檻；不要回頭重寫 v0.15 Movement core。
#
# 【本腳本主要設定常數／資料表】
# - COMBAT_AI_MANIFEST_V070 / COMBAT_AI_TUNING_V070 / COMBAT_AI_INDIRECT_ONLY_MOVES_V070 / COMBAT_AI_OFFENSIVE_SETUP_STATS_V070
# - COMBAT_AI_HARD_CONTROL_STATUSES_V070 / COMBAT_AI_WEATHER_DAMAGE_TYPES_V070
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Combat AI Data v0.70
# Combat AI Integration III
#------------------------------------------------------------------------------
# Team action reservation, sequence/payoff context, guard/ability counterplay
# and threat-state hysteresis tuning.  Movement, v0.15 target core, Weather,
# Field/Spatial Field, damage packets and Native Pose remain unchanged.
#==============================================================================
module PMD_AC
  COMBAT_AI_MANIFEST_V070 = {
    :schema_version=>"1.0",
    :content_version=>"0.70.0",
    :base_version=>"0.69",
    :feature=>"combat_ai_integration_iii",
    :selection_source=>"active_moves_v045_four_slot",
    :base_score=>"v0.69_move_target_pair",
    :features=>[:team_action_reservation,:duplicate_control_avoidance,
      :controlled_target_payoff,:planned_weather_payoff,:duplicate_weather_avoidance,
      :duplicate_field_avoidance,:guard_counterplay,:ability_counterplay,
      :setup_timing,:threat_hysteresis],
    :movement_core=>"v0.15_unchanged",
    :basic_target_core=>"v0.15_unchanged",
    :skill_target_layer=>"v0.69_pair_scoring_carried",
    :threat_core=>"v0.15_with_v0.70_release_hysteresis",
    :damage_packet=>"v0.60.2_unchanged",
    :native_router=>"v0.62_unchanged",
    :weather_runtime=>"v0.28_unchanged",
    :field_runtime=>"v0.35-v0.37_unchanged",
    :ability_slots=>1028,
    :ability_slots_total=>1193,
    :ability_species=>483,
    :move_runtime=>526,
    :learnset_coverage=>"7005/7005"
  }

  COMBAT_AI_TUNING_V070 = {
    :duplicate_control_penalty=>58.0,
    :controlled_target_damage_bonus=>18.0,
    :ally_control_payoff_bonus=>14.0,
    :duplicate_weather_penalty=>72.0,
    :duplicate_field_penalty=>68.0,
    :planned_weather_payoff_bonus=>16.0,
    :guard_block_score=>0.10,
    :guard_break_bonus=>36.0,
    :magic_guard_indirect_factor=>0.20,
    :unaware_offense_setup_factor=>0.55,
    :safe_setup_bonus=>14.0,
    :danger_setup_penalty=>26.0,
    :overkill_reserved_penalty=>18.0,
    :recent_setup_window=>180,
    :recent_setup_payoff_bonus=>16.0,
    :threat_pressure_release_margin=>18.0,
    :threat_emergency_release_margin=>12.0
  }

  COMBAT_AI_INDIRECT_ONLY_MOVES_V070 = [
    :toxic,:poison_powder,:leech_seed,:nightmare
  ]
  COMBAT_AI_OFFENSIVE_SETUP_STATS_V070 = [:atk,:spatk]
  COMBAT_AI_HARD_CONTROL_STATUSES_V070 = [:sleep,:freeze]
  COMBAT_AI_WEATHER_DAMAGE_TYPES_V070 = {
    :sun=>[:fire],
    :rain=>[:water],
    :sandstorm=>[:rock,:ground,:steel],
    :hail=>[:ice]
  }
end
