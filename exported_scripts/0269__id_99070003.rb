#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Combat AI Data v0.71
# 分類：戰鬥 AI
#
# 【用途／機制】
# 定義選招、選目標、威脅、隊伍協同、預測與多單位連鎖評分。
#
# 【怎麼調整】
# 要調 AI 行為，優先修改 Data 腳本中的權重／門檻；不要回頭重寫 v0.15 Movement core。
#
# 【本腳本主要設定常數／資料表】
# - COMBAT_AI_MANIFEST_V071 / COMBAT_AI_TUNING_V071 / COMBAT_AI_CHAIN_STATUS_MOVES_V071 / COMBAT_AI_MAJOR_STATUSES_V071
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Combat AI Data v0.71
# Combat AI Integration IV
#------------------------------------------------------------------------------
# Ordered team combo chains and short-term intent stability.  This data layer
# does not replace movement, basic targeting, Weather/Field runtime, damage
# packets, Native Pose or presentation anchors.
#==============================================================================
module PMD_AC
  COMBAT_AI_MANIFEST_V071 = {
    :schema_version=>"1.0",
    :content_version=>"0.71.0",
    :base_version=>"0.70",
    :feature=>"combat_ai_integration_iv",
    :selection_source=>"active_moves_v045_four_slot",
    :base_score=>"v0.70_reservation_sequence",
    :features=>[:intent_lock,:ordered_combo_prediction,:defense_break_chain,
      :special_defense_break_chain,:status_payoff_chain,:helping_hand_chain,
      :duplicate_debuff_avoidance,:conditional_power_awareness],
    :movement_core=>"v0.15_unchanged",
    :basic_target_core=>"v0.15_unchanged",
    :skill_target_layer=>"v0.69_pair_scoring_carried",
    :threat_core=>"v0.70_hysteresis_carried",
    :weather_field=>"v0.28+v0.35-v0.37_unchanged",
    :damage_packet=>"v0.60.2_unchanged",
    :native_router=>"v0.62_unchanged",
    :ability_slots=>1028,
    :ability_slots_total=>1193,
    :ability_species=>483,
    :move_runtime=>526,
    :learnset_coverage=>"7005/7005"
  }

  COMBAT_AI_TUNING_V071 = {
    :intent_lock_frames=>24,
    :defense_break_stage_bonus=>20.0,
    :special_defense_break_stage_bonus=>20.0,
    :duplicate_debuff_penalty=>44.0,
    :helping_hand_chain_bonus=>30.0,
    :ordered_setup_slow_factor=>0.45,
    :ordered_setup_committed_factor=>1.00,
    :ordered_setup_equal_priority_factor=>0.90,
    :venoshock_ready_factor=>1.75,
    :hex_ready_factor=>1.75,
    :dream_eater_unready_score=>8.0,
    :dream_eater_ready_bonus=>62.0,
    :nightmare_unready_score=>8.0,
    :nightmare_ready_bonus=>48.0,
    :wake_up_slap_ready_bonus=>28.0,
    :planned_status_bonus_factor=>0.85
  }

  COMBAT_AI_CHAIN_STATUS_MOVES_V071 = {
    :venoshock=>:poison,
    :hex=>:major,
    :dream_eater=>:sleep,
    :nightmare=>:sleep,
    :wake_up_slap=>:sleep
  }
  COMBAT_AI_MAJOR_STATUSES_V071 = [:sleep,:freeze,:burn,:poison,:paralysis]
end
