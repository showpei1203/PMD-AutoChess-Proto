#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Passive Data v0.26
# 分類：特性 Ability
#
# 【用途／機制】
# 定義特性資料、觸發時機、被動效果與 Runtime 覆蓋。
#
# 【怎麼調整】
# 新增特性時先放 Data，再在對應 Runtime helper 實作；需要 Popup／LOG 的觸發效果要同步補呈現。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_PASSIVE_MANIFEST_V026 / ABILITY_PASSIVE_BEHAVIOR_V026
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Ability Passive Data v0.26 - GENERATED
#==============================================================================
module PMD_AC
  ABILITY_PASSIVE_MANIFEST_V026 = {:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:new_passive_ability_count=>17,:cumulative_ability_behavior_count=>73,:new_implemented_slot_count=>91,:implemented_slot_count=>614,:total_slot_count=>1193,:implemented_slot_coverage_percent=>51.47,:species_with_any_implemented_ability=>396,:species_coverage_percent=>80.16,:runtime_checksum32=>404705731,:runtime_file=>"Data/PMD_AutoChess_AbilityPassive_v026_000.rvdata",:source_commit=>"fb1605aac09064bb34a12a8b790c2b800b4d0550",:notes=>["Passive/conditional abilities use the verified Gen-V ability slot snapshot from v0.24.","Quick Feet ignores the paralysis Speed penalty but full paralysis still applies.","Sheer Force boosts damaging moves with target-side secondary effects by 30% and suppresses those target-side secondary effects.","Poison Heal is translated to the v0.25 realtime ability-turn pulse: poison DOT is suppressed and 1/8 MaxHP is healed per trigger cycle.","Sniper multiplies this project damage model critical multiplier by 1.5 rather than replacing the project-wide critical baseline.","Wonder Guard affects direct damaging moves only; indirect damage/status behavior is unchanged."]}
  ABILITY_PASSIVE_BEHAVIOR_V026 = {}
  ABILITY_PASSIVE_BEHAVIOR_V026[:big_pecks] = {:ability_key=>:big_pecks,:kind=>:stat_drop_immunity,:stats=>[:def],:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:contrary] = {:ability_key=>:contrary,:kind=>:reverse_stat_change,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:early_bird] = {:ability_key=>:early_bird,:kind=>:sleep_block_reduction,:num=>1,:den=>2,:rounding=>:ceil_blocked,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:flare_boost] = {:ability_key=>:flare_boost,:kind=>:status_category_multiplier,:status=>:burn,:category=>:special,:num=>3,:den=>2,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:marvel_scale] = {:ability_key=>:marvel_scale,:kind=>:status_defense_multiplier,:num=>3,:den=>2,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:motor_drive] = {:ability_key=>:motor_drive,:kind=>:type_immunity_stage,:type=>:electric,:stat=>:speed,:stages=>1,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:multiscale] = {:ability_key=>:multiscale,:kind=>:full_hp_incoming_multiplier,:num=>1,:den=>2,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:poison_heal] = {:ability_key=>:poison_heal,:kind=>:poison_turn_heal,:num=>1,:den=>8,:suppress_poison_tick=>true,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:poison_touch] = {:ability_key=>:poison_touch,:kind=>:contact_inflict_status,:status=>:poison,:chance=>30,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:quick_feet] = {:ability_key=>:quick_feet,:kind=>:status_speed_multiplier,:num=>3,:den=>2,:ignore_paralysis_speed=>true,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:sap_sipper] = {:ability_key=>:sap_sipper,:kind=>:type_immunity_stage,:type=>:grass,:stat=>:atk,:stages=>1,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:sheer_force] = {:ability_key=>:sheer_force,:kind=>:secondary_power_suppress,:num=>13,:den=>10,:target_secondary_only=>true,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:simple] = {:ability_key=>:simple,:kind=>:stat_change_multiplier,:multiplier=>2,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:sniper] = {:ability_key=>:sniper,:kind=>:critical_damage_multiplier,:num=>3,:den=>2,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:stench] = {:ability_key=>:stench,:kind=>:damage_flinch_chance,:chance=>10,:exclude_existing_flinch=>true,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:toxic_boost] = {:ability_key=>:toxic_boost,:kind=>:status_category_multiplier,:status=>:poison,:category=>:physical,:num=>3,:den=>2,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
  ABILITY_PASSIVE_BEHAVIOR_V026[:wonder_guard] = {:ability_key=>:wonder_guard,:kind=>:non_super_effective_immunity,:schema_version=>"1.0",:content_version=>"0.26.0",:canon_snapshot=>"2026-08-07",:ruleset=>:black_white,:behavior_status=>:implemented_passive_v026}
end
