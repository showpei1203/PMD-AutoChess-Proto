#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Tactical Support Data v0.44
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
# - TACTICAL_SUPPORT_MANIFEST_V044 / TACTICAL_SUPPORT_MOVE_V044 / TACTICAL_SUPPORT_VISUAL_V044 / TACTICAL_SUPPORT_AUDIO_V044
# - TACTICAL_AURA_VISUAL_V044
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Tactical Support Data v0.44
#===============================================================================
module PMD_AC
  TACTICAL_SUPPORT_MANIFEST_V044 = {:schema_version=>"1.0",:content_version=>"0.44.0",:base_version=>"0.43.2",:feature=>"tactical_support_runtime_i",:new_mapped_move_count=>5,:previous_mapped_move_count=>257,:cumulative_mapped_move_count=>262,:learnset_reference_total=>7005,:new_reference_covered=>53,:cumulative_reference_covered=>4333,:cumulative_coverage_percent=>61.86,:redirect_duration_frames=>60,:redirect_radius_x=>118,:redirect_radius_y=>82,:helping_hand_duration_frames=>60,:helping_hand_multiplier=>1.50,:helping_hand_resolution_grace_frames=>8,:ally_switch_max_range=>190,:new_move_keys=>["fake_out","follow_me","rage_powder","helping_hand","ally_switch"],:ref_counts=>{:fake_out=>14,:follow_me=>5,:rage_powder=>6,:helping_hand=>26,:ally_switch=>2},:realtime_adaptations=>{:fake_out=>"usable only as the first skill started after deployment; basic attacks do not consume the opening-skill gate",:follow_me=>"60-frame source-following spatial redirection aura; redirects single-target hostile attacks aimed at allies inside the aura",:rage_powder=>"same spatial redirection controller as Follow Me for the pinned Gen V ruleset",:helping_hand=>"boosts the ally next damaging resolution by 1.5x; same-resolution grace preserves AOE/multi-hit hits that land together",:ally_switch=>"selects a living ally and swaps exact battlefield pixel positions; action/target identity is preserved"},:runtime_checksum32=>609711350}
  TACTICAL_SUPPORT_MOVE_V044 = {
    :fake_out=>{:name=>"擊掌奇襲",:name_en=>"Fake Out",:type=>:normal,:category=>:physical,:power=>40,:accuracy=>100,:priority=>3,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.00,:force_contact_range=>true,:contact=>true,:visual_kind=>:contact_hit,:visual_style=>:normal,:cast_cat=>:snap_click,:launch_cat=>nil,:hit_cat=>:impact_mid,:tactical_kind=>:fake_out,:effects=>[{:type=>:damage,:power=>40}],:source_move_flags=>[:contact,:mirror,:protect],:move_key=>:fake_out,:canonical_move_key=>:fake_out,:runtime_skill_key=>"mv_fake_out",:canonical_power=>40,:move_type=>:normal,:damage_category=>:physical,:behavior_status=>:implemented_tactical_support_v044,:energy_runtime_mode=>:full_bar_v015},
    :follow_me=>{:name=>"看我嘛",:name_en=>"Follow Me",:type=>:normal,:category=>:status,:power=>nil,:accuracy=>nil,:priority=>3,:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.00,:force_contact_range=>false,:contact=>false,:visual_kind=>:self_fx,:visual_style=>:normal,:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_soft,:tactical_kind=>:redirect,:redirect_kind=>:follow_me,:duration_frames=>60,:radius_x=>118,:radius_y=>82,:effects=>[],:source_move_flags=>[],:move_key=>:follow_me,:canonical_move_key=>:follow_me,:runtime_skill_key=>"mv_follow_me",:canonical_power=>0,:move_type=>:normal,:damage_category=>:status,:behavior_status=>:implemented_tactical_support_v044,:energy_runtime_mode=>:full_bar_v015},
    :rage_powder=>{:name=>"憤怒粉",:name_en=>"Rage Powder",:type=>:bug,:category=>:status,:power=>nil,:accuracy=>nil,:priority=>3,:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.00,:force_contact_range=>false,:contact=>false,:visual_kind=>:self_fx,:visual_style=>:bug,:cast_cat=>:wind_hiss,:launch_cat=>nil,:hit_cat=>:impact_soft,:tactical_kind=>:redirect,:redirect_kind=>:rage_powder,:duration_frames=>60,:radius_x=>118,:radius_y=>82,:effects=>[],:source_move_flags=>[],:move_key=>:rage_powder,:canonical_move_key=>:rage_powder,:runtime_skill_key=>"mv_rage_powder",:canonical_power=>0,:move_type=>:bug,:damage_category=>:status,:behavior_status=>:implemented_tactical_support_v044,:energy_runtime_mode=>:full_bar_v015},
    :helping_hand=>{:name=>"幫助",:name_en=>"Helping Hand",:type=>:normal,:category=>:status,:power=>nil,:accuracy=>nil,:priority=>5,:target_type=>:ally,:policy=>:best_damage_ally,:delivery=>:instant,:range_px=>190.00,:force_contact_range=>false,:contact=>false,:visual_kind=>:target_hit,:visual_style=>:normal,:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_soft,:tactical_kind=>:helping_hand,:duration_frames=>60,:damage_multiplier=>1.50,:effects=>[],:source_move_flags=>[],:move_key=>:helping_hand,:canonical_move_key=>:helping_hand,:runtime_skill_key=>"mv_helping_hand",:canonical_power=>0,:move_type=>:normal,:damage_category=>:status,:behavior_status=>:implemented_tactical_support_v044,:energy_runtime_mode=>:full_bar_v015},
    :ally_switch=>{:name=>"交換場地",:name_en=>"Ally Switch",:type=>:psychic,:category=>:status,:power=>nil,:accuracy=>nil,:priority=>2,:target_type=>:ally,:policy=>:swap_ally,:delivery=>:instant,:range_px=>190.00,:force_contact_range=>false,:contact=>false,:visual_kind=>:target_hit,:visual_style=>:psychic,:cast_cat=>:tone_low_hum,:launch_cat=>nil,:hit_cat=>:magic_chime,:tactical_kind=>:ally_switch,:swap_max_range=>190,:effects=>[],:source_move_flags=>[],:move_key=>:ally_switch,:canonical_move_key=>:ally_switch,:runtime_skill_key=>"mv_ally_switch",:canonical_power=>0,:move_type=>:psychic,:damage_category=>:status,:behavior_status=>:implemented_tactical_support_v044,:energy_runtime_mode=>:full_bar_v015},
  }
  TACTICAL_SUPPORT_VISUAL_V044 = {
    :fake_out=>{:visual_kind=>:contact_hit,:style=>:normal},
    :follow_me=>{:visual_kind=>:self_fx,:style=>:normal},
    :rage_powder=>{:visual_kind=>:self_fx,:style=>:bug},
    :helping_hand=>{:visual_kind=>:target_hit,:style=>:normal},
    :ally_switch=>{:visual_kind=>:target_hit,:style=>:psychic},
  }
  TACTICAL_SUPPORT_AUDIO_V044 = {
    :fake_out=>{:type=>:normal,:category=>:physical,:visual_kind=>:contact_hit,:audio_style=>:normal,:cast_cat=>:snap_click,:launch_cat=>nil,:hit_cat=>:impact_mid,:special=>true},
    :follow_me=>{:type=>:normal,:category=>:status,:visual_kind=>:self_fx,:audio_style=>:normal,:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_soft,:special=>true},
    :rage_powder=>{:type=>:bug,:category=>:status,:visual_kind=>:self_fx,:audio_style=>:bug,:cast_cat=>:wind_hiss,:launch_cat=>nil,:hit_cat=>:impact_soft,:special=>true},
    :helping_hand=>{:type=>:normal,:category=>:status,:visual_kind=>:target_hit,:audio_style=>:normal,:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_soft,:special=>true},
    :ally_switch=>{:type=>:psychic,:category=>:status,:visual_kind=>:target_hit,:audio_style=>:psychic,:cast_cat=>:tone_low_hum,:launch_cat=>nil,:hit_cat=>:magic_chime,:special=>true},
  }
  TACTICAL_AURA_VISUAL_V044 = {
    :follow_me=>{:width=>154,:height=>82,:color=>[245,245,210,58],:z=>64},
    :rage_powder=>{:width=>154,:height=>82,:color=>[214,160,235,58],:z=>64},
    :helping_hand=>{:width=>104,:height=>56,:color=>[255,220,100,62],:z=>65},
  }
end
