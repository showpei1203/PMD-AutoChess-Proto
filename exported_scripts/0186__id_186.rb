#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Reactive Priority Data v0.43
# 分類：防禦／優先度／支援
#
# 【用途／機制】
# 處理 Protect 類、防護 aura、Priority、Reactive Priority、Helping Hand、Follo
# w Me 等戰術效果。
#
# 【怎麼調整】
# 新增支援技時應優先沿用既有 Guard / Priority / Tactical Support helper，而不是直接在傷害函
# 式硬寫特例。
#
# 【本腳本主要設定常數／資料表】
# - REACTIVE_PRIORITY_MANIFEST_V043 / REACTIVE_PRIORITY_MOVE_V043 / REACTIVE_PRIORITY_VISUAL_V043 / REACTIVE_PRIORITY_AUDIO_V043
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Reactive Priority Data v0.43
#===============================================================================
module PMD_AC
  REACTIVE_PRIORITY_MANIFEST_V043 = {:schema_version=>"1.0",:content_version=>"0.43.0",:base_version=>"0.42.1",:feature=>"reactive_priority_runtime_i",:new_mapped_move_count=>6,:previous_mapped_move_count=>251,:cumulative_mapped_move_count=>257,:learnset_reference_total=>7005,:new_reference_covered=>70,:cumulative_reference_covered=>4280,:cumulative_coverage_percent=>61.10,:reaction_window_frames=>60,:new_move_keys=>["sucker_punch","counter","mirror_coat","revenge","avalanche","vital_throw"],:ref_counts=>{:sucker_punch=>29,:counter=>11,:mirror_coat=>9,:revenge=>13,:avalanche=>2,:vital_throw=>6},:rules=>{:sucker_punch=>"target must be in pre-hit damaging action",:counter=>"2x most recent direct physical HP damage within 60 frames, return to source",:mirror_coat=>"2x most recent direct special HP damage within 60 frames, return to source",:revenge=>"120 power if selected target damaged user within 60 frames, else 60",:avalanche=>"120 power if selected target damaged user within 60 frames, else 60",:vital_throw=>"never miss, canonical priority -1"},:runtime_checksum32=>1898919474}
  REACTIVE_PRIORITY_MOVE_V043 = {
    :sucker_punch=>{:name=>"突襲",:name_en=>"Sucker Punch",:type=>:dark,:category=>:physical,:power=>80,:accuracy=>100,:priority=>1,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.00,:force_contact_range=>true,:contact=>true,:visual_kind=>:contact_hit,:visual_style=>:dark,:cast_cat=>:tone_low_hum,:launch_cat=>nil,:hit_cat=>:impact_burst,:reactive_kind=>:sucker_punch,:effects=>[{:type=>:damage,:power=>80}],:source_move_flags=>[:contact,:mirror,:protect],:move_key=>"sucker_punch",:canonical_move_key=>"sucker_punch",:runtime_skill_key=>"mv_sucker_punch",:canonical_power=>80,:move_type=>:dark,:damage_category=>:physical,:behavior_status=>:implemented_reactive_priority_v043,:energy_runtime_mode=>:full_bar_v015},
    :counter=>{:name=>"雙倍奉還",:name_en=>"Counter",:type=>:fighting,:category=>:physical,:power=>nil,:accuracy=>100,:priority=>-5,:target_type=>:enemy_targeted,:policy=>:reactive_attacker,:delivery=>:instant,:range_px=>280.00,:force_contact_range=>false,:contact=>true,:visual_kind=>:contact_hit,:visual_style=>:fighting,:cast_cat=>:low_thump,:launch_cat=>nil,:hit_cat=>:impact_heavy,:reactive_kind=>:counter,:reactive_category=>:physical,:return_ratio=>2,:effects=>[{:type=>:reactive_return,:category=>:physical,:ratio=>2}],:source_move_flags=>[:contact,:protect],:move_key=>"counter",:canonical_move_key=>"counter",:runtime_skill_key=>"mv_counter",:canonical_power=>0,:move_type=>:fighting,:damage_category=>:physical,:behavior_status=>:implemented_reactive_priority_v043,:energy_runtime_mode=>:full_bar_v015},
    :mirror_coat=>{:name=>"鏡面反射",:name_en=>"Mirror Coat",:type=>:psychic,:category=>:special,:power=>nil,:accuracy=>100,:priority=>-5,:target_type=>:enemy_targeted,:policy=>:reactive_attacker,:delivery=>:instant,:range_px=>320.00,:force_contact_range=>false,:contact=>false,:visual_kind=>:target_hit,:visual_style=>:psychic,:cast_cat=>:magic_chime,:launch_cat=>:tone_low_hum,:hit_cat=>:impact_burst,:reactive_kind=>:mirror_coat,:reactive_category=>:special,:return_ratio=>2,:effects=>[{:type=>:reactive_return,:category=>:special,:ratio=>2}],:source_move_flags=>[:protect],:move_key=>"mirror_coat",:canonical_move_key=>"mirror_coat",:runtime_skill_key=>"mv_mirror_coat",:canonical_power=>0,:move_type=>:psychic,:damage_category=>:special,:behavior_status=>:implemented_reactive_priority_v043,:energy_runtime_mode=>:full_bar_v015},
    :revenge=>{:name=>"報復",:name_en=>"Revenge",:type=>:fighting,:category=>:physical,:power=>60,:accuracy=>100,:priority=>-4,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.00,:force_contact_range=>true,:contact=>true,:visual_kind=>:contact_hit,:visual_style=>:fighting,:cast_cat=>nil,:launch_cat=>nil,:hit_cat=>:impact_heavy,:reactive_kind=>:revenge,:effects=>[{:type=>:damage,:power=>60}],:source_move_flags=>[:contact,:mirror,:protect],:move_key=>"revenge",:canonical_move_key=>"revenge",:runtime_skill_key=>"mv_revenge",:canonical_power=>60,:move_type=>:fighting,:damage_category=>:physical,:behavior_status=>:implemented_reactive_priority_v043,:energy_runtime_mode=>:full_bar_v015},
    :avalanche=>{:name=>"雪崩",:name_en=>"Avalanche",:type=>:ice,:category=>:physical,:power=>60,:accuracy=>100,:priority=>-4,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.00,:force_contact_range=>true,:contact=>true,:visual_kind=>:contact_hit,:visual_style=>:ice,:cast_cat=>:wind_hiss,:launch_cat=>nil,:hit_cat=>:impact_sharp,:reactive_kind=>:avalanche,:effects=>[{:type=>:damage,:power=>60}],:source_move_flags=>[:contact,:mirror,:protect],:move_key=>"avalanche",:canonical_move_key=>"avalanche",:runtime_skill_key=>"mv_avalanche",:canonical_power=>60,:move_type=>:ice,:damage_category=>:physical,:behavior_status=>:implemented_reactive_priority_v043,:energy_runtime_mode=>:full_bar_v015},
    :vital_throw=>{:name=>"借力摔",:name_en=>"Vital Throw",:type=>:fighting,:category=>:physical,:power=>70,:accuracy=>nil,:priority=>-1,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.00,:force_contact_range=>true,:contact=>true,:visual_kind=>:contact_hit,:visual_style=>:fighting,:cast_cat=>nil,:launch_cat=>nil,:hit_cat=>:impact_heavy,:reactive_kind=>:vital_throw,:always_hit=>true,:canonical_accuracy=>100,:effects=>[{:type=>:damage,:power=>70}],:source_move_flags=>[:contact,:mirror,:protect],:move_key=>"vital_throw",:canonical_move_key=>"vital_throw",:runtime_skill_key=>"mv_vital_throw",:canonical_power=>70,:move_type=>:fighting,:damage_category=>:physical,:behavior_status=>:implemented_reactive_priority_v043,:energy_runtime_mode=>:full_bar_v015},
  }
  REACTIVE_PRIORITY_VISUAL_V043 = {
    :sucker_punch=>{:visual_kind=>:contact_hit,:style=>:dark},
    :counter=>{:visual_kind=>:contact_hit,:style=>:fighting},
    :mirror_coat=>{:visual_kind=>:target_hit,:style=>:psychic},
    :revenge=>{:visual_kind=>:contact_hit,:style=>:fighting},
    :avalanche=>{:visual_kind=>:contact_hit,:style=>:ice},
    :vital_throw=>{:visual_kind=>:contact_hit,:style=>:fighting},
  }
  REACTIVE_PRIORITY_AUDIO_V043 = {
    :sucker_punch=>{:type=>:dark,:category=>:physical,:visual_kind=>:contact_hit,:audio_style=>:dark,:cast_cat=>:tone_low_hum,:launch_cat=>nil,:hit_cat=>:impact_burst,:special=>true},
    :counter=>{:type=>:fighting,:category=>:physical,:visual_kind=>:contact_hit,:audio_style=>:fighting,:cast_cat=>:low_thump,:launch_cat=>nil,:hit_cat=>:impact_heavy,:special=>true},
    :mirror_coat=>{:type=>:psychic,:category=>:special,:visual_kind=>:target_hit,:audio_style=>:psychic,:cast_cat=>:magic_chime,:launch_cat=>:tone_low_hum,:hit_cat=>:impact_burst,:special=>true},
    :revenge=>{:type=>:fighting,:category=>:physical,:visual_kind=>:contact_hit,:audio_style=>:fighting,:cast_cat=>nil,:launch_cat=>nil,:hit_cat=>:impact_heavy,:special=>true},
    :avalanche=>{:type=>:ice,:category=>:physical,:visual_kind=>:contact_hit,:audio_style=>:ice,:cast_cat=>:wind_hiss,:launch_cat=>nil,:hit_cat=>:impact_sharp,:special=>true},
    :vital_throw=>{:type=>:fighting,:category=>:physical,:visual_kind=>:contact_hit,:audio_style=>:fighting,:cast_cat=>nil,:launch_cat=>nil,:hit_cat=>:impact_heavy,:special=>true},
  }
end
