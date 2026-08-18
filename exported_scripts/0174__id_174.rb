#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Two-Turn Data v0.39
# 分類：高度／兩回合動作
#
# 【用途／機制】
# 處理飛行、Gravity、Dive、Dig、Fly 等高度與半潛地狀態。
#
# 【怎麼調整】
# 新增兩回合招式時要同時處理 phase、可選目標與視覺姿勢，避免第一段結束後卡住。
#
# 【本腳本主要設定常數／資料表】
# - TWO_TURN_MANIFEST_V039 / TWO_TURN_MOVE_V039 / TWO_TURN_AUDIO_V039
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.39 Two-Turn / Semi-Invulnerable Move Data
module PMD_AC
  TWO_TURN_MANIFEST_V039 = {
    :schema_version=>"1.0",
    :content_version=>"0.39.0",
    :base_version=>"0.38",
    :feature=>"two_turn_semi_invulnerable_move_runtime_i",
    :new_mapped_move_count=>5,
    :previous_mapped_move_count=>232,
    :cumulative_mapped_move_count=>237,
    :learnset_reference_total=>7005,
    :new_reference_covered=>38,
    :cumulative_reference_covered=>3923,
    :cumulative_coverage_percent=>56.00,
    :phase_frames=>60,
    :poses=>[:airborne,:submerged,:underground,:vanished],
    :move_keys=>[:fly,:bounce,:dive,:dig,:shadow_force],
    :gravity_cancel_moves=>[:fly,:bounce],
    :natural_airborne_is_not_semi_invulnerable=>true,
    :hostile_basic_blocked_during_semi_phase=>true,
    :no_guard_hook=>true,
    :exception_power_multiplier=>2.00,
    :target_lock=>"instance_uid",
    :movement_locked_during_charge=>true,
    :shadow_force_protect_bypass_hook=>true,
    :ref_counts=>{:fly=>2,:bounce=>16,:dive=>9,:dig=>10,:shadow_force=>1},
    :runtime_checksum32=>2083832541,
  }
  TWO_TURN_MOVE_V039 = {
    :fly=>{:name=>"飛翔",:type=>:flying,:category=>:physical,:power=>90,:accuracy=>95,:energy_cost_hint=>60,:pose=>:airborne,:phase_frames=>60,:gravity_blocked=>true,:vfx_style=>:flying,:semi_hit_by=>[:thunder,:hurricane,:gust,:twister,:sky_uppercut,:smack_down],:semi_double_power_from=>[:gust,:twister],:cast_cat=>:wind_whoosh,:launch_cat=>:wind_hiss,:hit_cat=>:slash_swish,:move_key=>:fly,:runtime_skill_key=>"mv_fly",:canonical_power=>90,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>58.00,:force_contact_range=>true,:projectile_tracking=>nil,:behavior_status=>:two_turn_runtime_v039,:energy_runtime_mode=>:full_bar_v015,:effects=>[{:type=>:damage,:power=>90}],:two_turn=>true,:semi_invulnerable=>true,:visual_kind=>"contact_hit"},
    :bounce=>{:name=>"彈跳",:type=>:flying,:category=>:physical,:power=>85,:accuracy=>85,:energy_cost_hint=>55,:pose=>:airborne,:phase_frames=>60,:gravity_blocked=>true,:vfx_style=>:flying,:semi_hit_by=>[:thunder,:hurricane,:gust,:twister,:sky_uppercut,:smack_down],:semi_double_power_from=>[:gust,:twister],:secondary_paralysis_chance=>30,:cast_cat=>:energy_rise,:launch_cat=>:wind_whoosh,:hit_cat=>:impact_heavy,:move_key=>:bounce,:runtime_skill_key=>"mv_bounce",:canonical_power=>85,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>58.00,:force_contact_range=>true,:projectile_tracking=>nil,:behavior_status=>:two_turn_runtime_v039,:energy_runtime_mode=>:full_bar_v015,:effects=>[{:type=>:damage,:power=>85}],:two_turn=>true,:semi_invulnerable=>true,:visual_kind=>"contact_hit"},
    :dive=>{:name=>"潛水",:type=>:water,:category=>:physical,:power=>80,:accuracy=>100,:energy_cost_hint=>55,:pose=>:submerged,:phase_frames=>60,:gravity_blocked=>false,:vfx_style=>:water,:semi_hit_by=>[:surf,:whirlpool],:semi_double_power_from=>[:surf,:whirlpool],:cast_cat=>:ambient_stream,:launch_cat=>:splash_noise,:hit_cat=>:water_splash,:move_key=>:dive,:runtime_skill_key=>"mv_dive",:canonical_power=>80,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>58.00,:force_contact_range=>true,:projectile_tracking=>nil,:behavior_status=>:two_turn_runtime_v039,:energy_runtime_mode=>:full_bar_v015,:effects=>[{:type=>:damage,:power=>80}],:two_turn=>true,:semi_invulnerable=>true,:visual_kind=>"contact_hit"},
    :dig=>{:name=>"挖洞",:type=>:ground,:category=>:physical,:power=>80,:accuracy=>100,:energy_cost_hint=>55,:pose=>:underground,:phase_frames=>60,:gravity_blocked=>false,:vfx_style=>:ground,:semi_hit_by=>[:earthquake,:magnitude],:semi_double_power_from=>[:earthquake,:magnitude],:cast_cat=>:low_rumble,:launch_cat=>:rumble_impact,:hit_cat=>:low_impact,:move_key=>:dig,:runtime_skill_key=>"mv_dig",:canonical_power=>80,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>58.00,:force_contact_range=>true,:projectile_tracking=>nil,:behavior_status=>:two_turn_runtime_v039,:energy_runtime_mode=>:full_bar_v015,:effects=>[{:type=>:damage,:power=>80}],:two_turn=>true,:semi_invulnerable=>true,:visual_kind=>"contact_hit"},
    :shadow_force=>{:name=>"暗影潛襲",:type=>:ghost,:category=>:physical,:power=>120,:accuracy=>100,:energy_cost_hint=>70,:pose=>:vanished,:phase_frames=>60,:gravity_blocked=>false,:vfx_style=>:ghost,:semi_hit_by=>[],:semi_double_power_from=>[],:bypass_protect=>true,:cast_cat=>:tone_low_hum,:launch_cat=>:magic_sustain,:hit_cat=>:impact_burst,:move_key=>:shadow_force,:runtime_skill_key=>"mv_shadow_force",:canonical_power=>120,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>58.00,:force_contact_range=>true,:projectile_tracking=>nil,:behavior_status=>:two_turn_runtime_v039,:energy_runtime_mode=>:full_bar_v015,:effects=>[{:type=>:damage,:power=>120}],:two_turn=>true,:semi_invulnerable=>true,:visual_kind=>"contact_hit"},
  }
  TWO_TURN_AUDIO_V039 = {
    :fly=>{:type=>:flying,:category=>:physical,:visual_kind=>"contact_hit",:audio_style=>:flying,:cast_cat=>:wind_whoosh,:launch_cat=>:wind_hiss,:hit_cat=>:slash_swish,:special=>true},
    :bounce=>{:type=>:flying,:category=>:physical,:visual_kind=>"contact_hit",:audio_style=>:flying,:cast_cat=>:energy_rise,:launch_cat=>:wind_whoosh,:hit_cat=>:impact_heavy,:special=>true},
    :dive=>{:type=>:water,:category=>:physical,:visual_kind=>"contact_hit",:audio_style=>:water,:cast_cat=>:ambient_stream,:launch_cat=>:splash_noise,:hit_cat=>:water_splash,:special=>true},
    :dig=>{:type=>:ground,:category=>:physical,:visual_kind=>"contact_hit",:audio_style=>:ground,:cast_cat=>:low_rumble,:launch_cat=>:rumble_impact,:hit_cat=>:low_impact,:special=>true},
    :shadow_force=>{:type=>:ghost,:category=>:physical,:visual_kind=>"contact_hit",:audio_style=>:ghost,:cast_cat=>:tone_low_hum,:launch_cat=>:magic_sustain,:hit_cat=>:impact_burst,:special=>true},
  }
end
