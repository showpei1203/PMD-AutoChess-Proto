#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Data v0.65
# 分類：特性 Ability
#
# 【用途／機制】
# 定義特性資料、觸發時機、被動效果與 Runtime 覆蓋。
#
# 【怎麼調整】
# 新增特性時先放 Data，再在對應 Runtime helper 實作；需要 Popup／LOG 的觸發效果要同步補呈現。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_RUNTIME_MANIFEST_V065 / ABILITY_RUNTIME_BEHAVIOR_V065
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Ability Runtime Coverage Data v0.65
# Generation V ability runtime expansion II. Additive to v0.24-v0.28 + v0.64.
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_MANIFEST_V065 = {
    :schema_version=>"1.0",:content_version=>"0.65.0",:canon_snapshot=>"2026-08-09",
    :ruleset=>"black_white",:target_generation=>5,:total_slot_count=>1193,
    :previous_implemented_ability_count=>107,:new_implemented_ability_count=>8,
    :cumulative_implemented_ability_count=>115,
    :previous_implemented_slot_count=>905,:new_implemented_slot_count=>47,
    :implemented_slot_count=>952,:implemented_slot_coverage_percent=>79.80,
    :previous_species_with_any_implemented_ability=>461,
    :new_species_with_any_implemented_ability=>12,
    :species_with_any_implemented_ability=>473,:species_coverage_percent=>95.75,
    :new_ability_keys=>[:lightning_rod,:storm_drain,:scrappy,:prankster,
      :unaware,:friend_guard,:liquid_ooze,:download],
    :runtime_checksum32=>1063759503,
    :notes=>[
      "Lightning Rod and Storm Drain redirect only single-target hostile matching-type actions; Follow Me/Rage Powder remains the higher-priority redirect layer.",
      "Scrappy bypasses Ghost type immunity only for Normal/Fighting damaging moves.",
      "Prankster adds +1 realtime priority to status moves while preserving Generation-V Quick Guard behavior.",
      "Unaware ignores the opponent stat stages relevant to damaging-move damage/accuracy only.",
      "Friend Guard reduces attack damage to allies by 25 percent per active source, multiplicatively.",
      "Liquid Ooze reverses explicit drain healing, Dream Eater drain, and Leech Seed healing into damage to the drainer.",
      "Download activates on entry/ability gain and compares living opposing Defense vs Special Defense totals.",
      "v0.62 Native Pose, v0.60.2 multi-hit packets, presentation anchors and v0.56.1 Organic SFX remain unchanged."
    ]
  }

  ABILITY_RUNTIME_BEHAVIOR_V065 = {
    :lightning_rod=>{:ability_key=>:lightning_rod,:kind=>:type_redirect_absorb_spatk,
      :behavior_status=>:implemented_ability_v065,:move_type=>:electric,
      :single_target_redirect=>true,:spatk_stages=>1,:ground_no_boost_gen5=>true},
    :storm_drain=>{:ability_key=>:storm_drain,:kind=>:type_redirect_absorb_spatk,
      :behavior_status=>:implemented_ability_v065,:move_type=>:water,
      :single_target_redirect=>true,:spatk_stages=>1},
    :scrappy=>{:ability_key=>:scrappy,:kind=>:ghost_type_immunity_bypass,
      :behavior_status=>:implemented_ability_v065,:move_types=>[:normal,:fighting],
      :damage_only=>true},
    :prankster=>{:ability_key=>:prankster,:kind=>:status_priority_bonus,
      :behavior_status=>:implemented_ability_v065,:priority_bonus=>1,
      :status_only=>true,:quick_guard_gen5_unchanged=>true},
    :unaware=>{:ability_key=>:unaware,:kind=>:opponent_stat_stage_ignore,
      :behavior_status=>:implemented_ability_v065,
      :attacker_ignores=>[:def,:spdef,:evasion],
      :defender_ignores=>[:atk,:spatk,:accuracy],:damage_only=>true},
    :friend_guard=>{:ability_key=>:friend_guard,:kind=>:ally_attack_damage_reduction,
      :behavior_status=>:implemented_ability_v065,:num=>3,:den=>4,
      :self_protection=>false,:stack_mode=>:multiplicative},
    :liquid_ooze=>{:ability_key=>:liquid_ooze,:kind=>:drain_reversal,
      :behavior_status=>:implemented_ability_v065,
      :covers=>[:drain_effect,:dream_eater,:leech_seed]},
    :download=>{:ability_key=>:download,:kind=>:entry_defense_compare,
      :behavior_status=>:implemented_ability_v065,:tie_result=>:spatk,
      :def_lower_result=>:atk,:stages=>1}
  }
end
