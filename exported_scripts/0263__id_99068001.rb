#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Combat AI Data v0.68
# 分類：戰鬥 AI
#
# 【用途／機制】
# 定義選招、選目標、威脅、隊伍協同、預測與多單位連鎖評分。
#
# 【怎麼調整】
# 要調 AI 行為，優先修改 Data 腳本中的權重／門檻；不要回頭重寫 v0.15 Movement core。
#
# 【本腳本主要設定常數／資料表】
# - COMBAT_AI_MANIFEST_V068 / COMBAT_AI_TUNING_V068 / COMBAT_AI_REACTIVE_MOVES_V068 / COMBAT_AI_GUARD_MOVES_V068
# - COMBAT_AI_HARD_CONTROL_EFFECTS_V068 / COMBAT_AI_STATUS_EFFECTS_V068 / COMBAT_AI_HEAL_EFFECTS_V068
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Combat AI Data v0.68
# Combat AI Integration I
#------------------------------------------------------------------------------
# Tuning-only data for the v0.68 context-aware four-move selector.
# Runtime remains deterministic and continues to use the v0.46 active-move
# loadout bridge.  No movement, target-selection or damage-packet core is
# replaced here.
#==============================================================================
module PMD_AC
  COMBAT_AI_MANIFEST_V068 = {
    :schema_version=>"1.0",
    :content_version=>"0.68.0",
    :base_version=>"0.67.1",
    :feature=>"combat_ai_integration_i",
    :selection_source=>"active_moves_v045_four_slot",
    :base_score=>"progression_candidate_score_v046",
    :categories=>[:heal,:buff,:debuff,:status,:guard,:priority,:reactive,
      :field,:weather,:aoe,:multi_hit,:two_turn],
    :presentation_isolation=>true,
    :diagnostic_fake_unit_vfx=>false,
    :movement_core=>"v0.15_unchanged",
    :target_core=>"existing_policy_unchanged",
    :damage_packet=>"v0.60.2_unchanged",
    :native_router=>"v0.62_unchanged",
    :ability_slots=>1028,
    :ability_slots_total=>1193,
    :ability_species=>483,
    :move_runtime=>526,
    :learnset_coverage=>"7005/7005"
  }

  COMBAT_AI_TUNING_V068 = {
    :multi_hit_2_5_expected=>3.0,
    :aoe_extra_target_factor=>0.55,
    :aoe_multiplier_cap=>2.65,
    :two_turn_damage_factor=>0.82,
    :two_turn_low_hp_factor=>0.72,
    :priority_flat_per_stage=>10.0,
    :priority_execute_bonus=>24.0,
    :heal_base=>48.0,
    :heal_missing_hp_weight=>132.0,
    :buff_base=>68.0,
    :buff_stage_weight=>7.0,
    :debuff_base=>72.0,
    :debuff_stage_weight=>7.0,
    :status_base=>82.0,
    :hard_control_base=>92.0,
    :guard_base=>72.0,
    :guard_pressure_weight=>15.0,
    :guard_missing_hp_weight=>30.0,
    :reactive_floor=>108.0,
    :field_base=>82.0,
    :field_counter_weight=>18.0,
    :weather_base=>78.0,
    :weather_synergy_weight=>9.0,
    :secondary_status_bonus=>7.0
  }

  COMBAT_AI_REACTIVE_MOVES_V068 = [
    :sucker_punch,:counter,:mirror_coat,:metal_burst,:bide,:destiny_bond
  ]
  COMBAT_AI_GUARD_MOVES_V068 = [
    :protect,:detect,:endure,:wide_guard,:quick_guard
  ]
  COMBAT_AI_HARD_CONTROL_EFFECTS_V068 = [
    :canonical_sleep,:canonical_freeze,:control,:yawn_v052
  ]
  COMBAT_AI_STATUS_EFFECTS_V068 = [
    :canonical_sleep,:canonical_freeze,:canonical_confusion,
    :canonical_paralysis,:direct_poison_v049,:direct_burn_v050,
    :toxic_v056,:ailment,:status,:nightmare_v057,:infatuate_v058
  ]
  COMBAT_AI_HEAL_EFFECTS_V068 = [
    :heal,:hot,:heal_maxhp_ratio,:aqua_ring_v050,:ingrain_v051,
    :wish_v056,:healing_wish_v053,:lunar_dance_v059
  ]
end
