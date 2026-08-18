#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Coverage Data v0.64
# 分類：特性 Ability
#
# 【用途／機制】
# 定義特性資料、觸發時機、被動效果與 Runtime 覆蓋。
#
# 【怎麼調整】
# 新增特性時先放 Data，再在對應 Runtime helper 實作；需要 Popup／LOG 的觸發效果要同步補呈現。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_RUNTIME_MANIFEST_V064 / ABILITY_RUNTIME_BEHAVIOR_V064
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Ability Runtime Coverage Data v0.64
# Generation V ability runtime expansion. Additive to v0.24-v0.28.
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_MANIFEST_V064 = {
    :schema_version=>"1.0",:content_version=>"0.64.0",:canon_snapshot=>"2026-08-09",
    :ruleset=>"black_white",:target_generation=>5,:total_slot_count=>1193,
    :previous_implemented_ability_count=>99,:new_implemented_ability_count=>8,
    :cumulative_implemented_ability_count=>107,
    :previous_implemented_slot_count=>840,:new_implemented_slot_count=>65,
    :implemented_slot_count=>905,:implemented_slot_coverage_percent=>75.86,
    :previous_species_with_any_implemented_ability=>451,
    :new_species_with_any_implemented_ability=>10,
    :species_with_any_implemented_ability=>461,:species_coverage_percent=>93.32,
    :new_ability_keys=>[:oblivious,:damp,:skill_link,:wonder_skin,:super_luck,:plus,:minus,:telepathy],
    :runtime_checksum32=>1734316672,
    :notes=>[
      "Damp reuses the existing global Damp/Aftermath gate and now also blocks Explosion/Self-Destruct resolution.",
      "Skill Link controls only random multi-hit count; v0.60.2 remains the damage-packet/choreography driver.",
      "Wonder Skin caps opposing accuracy-checked status moves at 50 percent without touching always-hit status moves.",
      "Telepathy blocks the complete allied damaging move packet, including secondary effects from that packet.",
      "Native Pose router, Beam/Projectile/Impact/Target-FX anchors and Organic SFX are unchanged."
    ]
  }

  ABILITY_RUNTIME_BEHAVIOR_V064 = {
    :oblivious=>{:ability_key=>:oblivious,:kind=>:infatuation_immunity,
      :behavior_status=>:implemented_ability_v064,:blocks=>[:infatuation]},
    :damp=>{:ability_key=>:damp,:kind=>:global_explosion_block,
      :behavior_status=>:implemented_ability_v064,
      :moves=>[:explosion,:self_destruct],:blocks_aftermath=>true},
    :skill_link=>{:ability_key=>:skill_link,:kind=>:multi_hit_max,
      :behavior_status=>:implemented_ability_v064,:random_multi_hit_only=>true},
    :wonder_skin=>{:ability_key=>:wonder_skin,:kind=>:status_accuracy_cap,
      :behavior_status=>:implemented_ability_v064,:accuracy_cap=>50},
    :super_luck=>{:ability_key=>:super_luck,:kind=>:critical_stage_bonus,
      :behavior_status=>:implemented_ability_v064,:crit_bonus=>0.075},
    :plus=>{:ability_key=>:plus,:kind=>:ally_plus_minus_spatk,
      :behavior_status=>:implemented_ability_v064,:partners=>[:plus,:minus],
      :num=>3,:den=>2},
    :minus=>{:ability_key=>:minus,:kind=>:ally_plus_minus_spatk,
      :behavior_status=>:implemented_ability_v064,:partners=>[:plus,:minus],
      :num=>3,:den=>2},
    :telepathy=>{:ability_key=>:telepathy,:kind=>:ally_damaging_move_immunity,
      :behavior_status=>:implemented_ability_v064,:damage_only=>true}
  }
end
