#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Trigger Data v0.25
# 分類：特性 Ability
#
# 【用途／機制】
# 定義特性資料、觸發時機、被動效果與 Runtime 覆蓋。
#
# 【怎麼調整】
# 新增特性時先放 Data，再在對應 Runtime helper 實作；需要 Popup／LOG 的觸發效果要同步補呈現。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_TRIGGER_MANIFEST_V025 / ABILITY_TRIGGER_BEHAVIOR_V025
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Ability Trigger Data v0.25 - GENERATED
#==============================================================================
module PMD_AC
  ABILITY_TRIGGER_MANIFEST_V025 = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:new_trigger_ability_count=>14,:cumulative_ability_behavior_count=>56,:new_implemented_slot_count=>120,:implemented_slot_count=>523,:total_slot_count=>1193,:implemented_slot_coverage_percent=>43.84,:species_with_any_implemented_ability=>364,:species_coverage_percent=>73.68,:runtime_checksum32=>20065848,:runtime_file=>"Data/PMD_AutoChess_AbilityTriggers_v025_000.rvdata",:source_commit=>"fb1605aac09064bb34a12a8b790c2b800b4d0550",:realtime_turn_translation=>{:cycle_basis=>"base_attack_wait_frames",:speed_independent=>true,:dot_order=>"trigger_before_status_tick"},:notes=>["Trigger cycle is a realtime translation of end-of-turn abilities: one pulse per base attack-wait cycle, independent of Speed Stage / paralysis.","Shed Skin uses exact Generation-V 1/3 chance and pulses before burn/poison status tick on the trigger frame.","Weak Armor uses Generation-V behavior: Defense -1 and Speed +1 per qualifying physical hit.","Effect Spore uses Generation-V distribution: 9% poison, 10% paralysis, 11% sleep; failed immunity does not reroll.","Aftermath is suppressed when any living Damp holder is on the field. Magic Guard is honored for Rough Skin/Aftermath damage without being counted as fully implemented.","Sturdy applies to direct damaging hits and confusion self-damage from full HP; Mold Breaker/Teravolt/Turboblaze bypass it."]}
  ABILITY_TRIGGER_BEHAVIOR_V025 = {}
  ABILITY_TRIGGER_BEHAVIOR_V025[:aftermath] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:aftermath,:kind=>:contact_faint_indirect_damage,:behavior_status=>"implemented_trigger_v025",:ratio_num=>1,:ratio_den=>4,:damp_blocks=>true}
  ABILITY_TRIGGER_BEHAVIOR_V025[:anger_point] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:anger_point,:kind=>:on_critical_set_stage,:behavior_status=>"implemented_trigger_v025",:stat=>:atk,:stage=>6}
  ABILITY_TRIGGER_BEHAVIOR_V025[:defiant] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:defiant,:kind=>:on_opponent_stat_drop_stage,:behavior_status=>"implemented_trigger_v025",:stat=>:atk,:stages=>2}
  ABILITY_TRIGGER_BEHAVIOR_V025[:effect_spore] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:effect_spore,:kind=>:contact_random_status,:behavior_status=>"implemented_trigger_v025",:roll_max=>100,:distribution=>[{:status=>:poison,:from=>0,:to=>8},{:status=>:paralysis,:from=>9,:to=>18},{:status=>:sleep,:from=>19,:to=>29}],:generation_note=>"Gen V 9% poison / 10% paralysis / 11% sleep"}
  ABILITY_TRIGGER_BEHAVIOR_V025[:justified] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:justified,:kind=>:on_hit_type_stage,:behavior_status=>"implemented_trigger_v025",:move_types=>[:dark],:stat=>:atk,:stages=>1}
  ABILITY_TRIGGER_BEHAVIOR_V025[:moxie] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:moxie,:kind=>:on_ko_stage,:behavior_status=>"implemented_trigger_v025",:stat=>:atk,:stages=>1,:direct_damage_only=>true}
  ABILITY_TRIGGER_BEHAVIOR_V025[:rattled] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:rattled,:kind=>:on_hit_type_stage,:behavior_status=>"implemented_trigger_v025",:move_types=>[:bug,:ghost,:dark],:stat=>:speed,:stages=>1}
  ABILITY_TRIGGER_BEHAVIOR_V025[:rough_skin] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:rough_skin,:kind=>:contact_indirect_damage,:behavior_status=>"implemented_trigger_v025",:ratio_num=>1,:ratio_den=>8}
  ABILITY_TRIGGER_BEHAVIOR_V025[:shed_skin] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:shed_skin,:kind=>:turn_end_status_cure,:behavior_status=>"implemented_trigger_v025",:chance_num=>1,:chance_den=>3,:statuses=>[:burn,:poison,:paralysis,:sleep,:freeze]}
  ABILITY_TRIGGER_BEHAVIOR_V025[:speed_boost] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:speed_boost,:kind=>:turn_end_stage,:behavior_status=>"implemented_trigger_v025",:stat=>:speed,:stages=>1}
  ABILITY_TRIGGER_BEHAVIOR_V025[:steadfast] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:steadfast,:kind=>:on_flinch_stage,:behavior_status=>"implemented_trigger_v025",:stat=>:speed,:stages=>1}
  ABILITY_TRIGGER_BEHAVIOR_V025[:sturdy] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:sturdy,:kind=>:full_hp_survive,:behavior_status=>"implemented_trigger_v025",:remain_hp=>1,:confusion_eligible=>true,:mold_breaker_ignored=>true}
  ABILITY_TRIGGER_BEHAVIOR_V025[:synchronize] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:synchronize,:kind=>:mirror_major_status,:behavior_status=>"implemented_trigger_v025",:statuses=>[:burn,:poison,:paralysis]}
  ABILITY_TRIGGER_BEHAVIOR_V025[:weak_armor] = {:schema_version=>"1.0",:content_version=>"0.25.0",:canon_snapshot=>"2026-08-07",:ruleset=>"black_white",:ability_key=>:weak_armor,:kind=>:on_hit_category_multi,:behavior_status=>"implemented_trigger_v025",:category=>:physical,:changes=>[{:stat=>:def,:stages=>-1},{:stat=>:speed,:stages=>1}],:generation_note=>"Gen V-VI Speed +1"}
end
