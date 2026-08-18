#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Combat AI Data v0.69
# 分類：戰鬥 AI
#
# 【用途／機制】
# 定義選招、選目標、威脅、隊伍協同、預測與多單位連鎖評分。
#
# 【怎麼調整】
# 要調 AI 行為，優先修改 Data 腳本中的權重／門檻；不要回頭重寫 v0.15 Movement core。
#
# 【本腳本主要設定常數／資料表】
# - COMBAT_AI_MANIFEST_V069 / COMBAT_AI_TUNING_V069 / COMBAT_AI_MAJOR_STATUS_EFFECT_MAP_V069
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Combat AI Data v0.69
# Combat AI Integration II
#------------------------------------------------------------------------------
# Skill-target pair evaluation, team coordination and ability/weather awareness.
# This is tuning/data only. Movement and the v0.15 basic target core remain
# unchanged; v0.69 only refines the four-active-move skill decision layer.
#==============================================================================
module PMD_AC
  COMBAT_AI_MANIFEST_V069 = {
    :schema_version=>"1.0",
    :content_version=>"0.69.0",
    :base_version=>"0.68",
    :feature=>"combat_ai_integration_ii",
    :selection_source=>"active_moves_v045_four_slot",
    :base_score=>"v0.68_context_score",
    :features=>[:move_target_pair,:type_ability_awareness,:accuracy_awareness,
      :redirect_awareness,:focus_fire,:ally_triage,:field_recast_awareness,
      :weather_runtime_awareness,:weather_ability_synergy],
    :movement_core=>"v0.15_unchanged",
    :basic_target_core=>"v0.15_unchanged",
    :skill_target_layer=>"v0.69_pair_scoring_overlay",
    :damage_packet=>"v0.60.2_unchanged",
    :native_router=>"v0.62_unchanged",
    :presentation_anchors=>"unchanged",
    :ability_slots=>1028,
    :ability_slots_total=>1193,
    :ability_species=>483,
    :move_runtime=>526,
    :learnset_coverage=>"7005/7005"
  }

  COMBAT_AI_TUNING_V069 = {
    :damage_accuracy_floor=>0.30,
    :damage_accuracy_weight=>0.70,
    :status_accuracy_floor=>0.55,
    :status_accuracy_weight=>0.45,
    :focus_fire_bonus=>14.0,
    :focus_fire_execute_bonus=>20.0,
    :current_target_bonus=>8.0,
    :execute_target_weight=>44.0,
    :cluster_target_weight=>12.0,
    :distance_target_penalty=>0.025,
    :ability_immunity_score=>0.10,
    :redundant_status_penalty=>70.0,
    :saturated_debuff_penalty=>42.0,
    :ally_missing_hp_weight=>120.0,
    :ally_threat_weight=>18.0,
    :ally_distance_penalty=>0.035,
    :weather_ability_synergy=>16.0,
    :active_field_score_factor=>0.12,
    :active_weather_score_factor=>0.12
  }

  COMBAT_AI_MAJOR_STATUS_EFFECT_MAP_V069 = {
    :canonical_sleep=>:sleep,
    :canonical_freeze=>:freeze,
    :canonical_confusion=>:confusion,
    :canonical_paralysis=>:paralysis,
    :direct_poison_v049=>:poison,
    :direct_burn_v050=>:burn,
    :toxic_v056=>:poison,
    :nightmare_v057=>:nightmare,
    :infatuate_v058=>:infatuation
  }
end
