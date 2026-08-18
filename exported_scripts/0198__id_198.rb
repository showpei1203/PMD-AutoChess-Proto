#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Skill Mastery Policy Data v0.48
# 分類：成長／進化／學招
#
# 【用途／機制】
# 處理等級、EXP、四招配置、技能熟練、待學技能、進化與玩家成長流程。
#
# 【怎麼調整】
# 個體操作範例：instance.known_moves_v045；四招設定使用 set_active_moves_v045。
#
# 【本腳本主要設定常數／資料表】
# - MASTERY_POLICY_MANIFEST_V048 / MASTERY_MAGNITUDE_MULT_V048 / MASTERY_DRAIN_RATIO_MULT_V048 / MASTERY_SECONDARY_CHANCE_V048
# - MASTERY_STATUS_ACCURACY_V048 / MASTERY_STATUS_ENERGY_REFUND_V048 / MASTERY_REACTIVE_ENERGY_REFUND_V048 / MASTERY_FIELD_TURN_BONUS_V048
# - MASTERY_WEATHER_TURN_BONUS_V048 / MASTERY_GUARD_FRAME_BONUS_V048 / MASTERY_TACTICAL_FRAME_BONUS_V048 / MASTERY_POLICY_SAFETY_V048
# - MASTERY_POLICY_CHECKSUM_TEXT_V048
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Skill Mastery Policy Data v0.48
#===============================================================================
module PMD_AC
  MASTERY_POLICY_MANIFEST_V048 = {
    :schema_version=>"1.0",
    :content_version=>"0.48.0",
    :base_version=>"0.47",
    :feature=>"skill_mastery_policy_ii",
    :identity_key=>"instance_uid",
    :move_level_max=>5,
    :runtime_moves=>262,
    :learnset_reference_covered=>4333,
    :learnset_reference_total=>7005,
    :next_phase=>"move_runtime_coverage_expansion",
    :runtime_checksum32=>1097729901
  }

  MASTERY_MAGNITUDE_MULT_V048       = [1.00,1.05,1.10,1.15,1.20]
  MASTERY_DRAIN_RATIO_MULT_V048     = [1.00,1.0125,1.025,1.0375,1.05]
  MASTERY_SECONDARY_CHANCE_V048     = [0,1,2,3,5]
  MASTERY_STATUS_ACCURACY_V048      = [0.0,2.0,4.0,6.0,8.0]
  MASTERY_STATUS_ENERGY_REFUND_V048 = [0,2,4,6,8]
  MASTERY_REACTIVE_ENERGY_REFUND_V048 = [0,1,2,3,5]
  MASTERY_FIELD_TURN_BONUS_V048     = [0,0,0,1,1]
  MASTERY_WEATHER_TURN_BONUS_V048   = [0,0,0,1,1]
  MASTERY_GUARD_FRAME_BONUS_V048    = [0,2,4,6,8]
  MASTERY_TACTICAL_FRAME_BONUS_V048 = [0,2,4,6,8]

  # Explicit safety locks. Mastery may make a move better, but must not mutate
  # the battle grammar itself into permanent stun / infinite guard nonsense.
  MASTERY_POLICY_SAFETY_V048 = {
    :stat_stage_amplification=>false,
    :hard_control_duration_scaling=>false,
    :priority_tier_scaling=>false,
    :two_turn_phase_reduction=>false,
    :helping_hand_multiplier_scaling=>false,
    :reactive_return_ratio_scaling=>false
  }

  MASTERY_POLICY_CHECKSUM_TEXT_V048 =
    "identity=instance_uid|magnitude=1,1.05,1.1,1.15,1.2|"+
    "drain=1,1.0125,1.025,1.0375,1.05|secondary=0,1,2,3,5|"+
    "status_acc=0,2,4,6,8|status_energy=0,2,4,6,8|reactive_energy=0,1,2,3,5|"+
    "field=0,0,0,1,1|weather=0,0,0,1,1|guard=0,2,4,6,8|"+
    "tactical=0,2,4,6,8|safety=stage0,control0,priority0,two_turn0,help150,reactive2"
end
