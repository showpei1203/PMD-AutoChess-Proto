#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Guard Data v0.40
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
# - GUARD_MANIFEST_V040 / GUARD_MOVE_V040 / GUARD_VISUAL_V040 / GUARD_AUDIO_V040
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.40 Protect / Guard Runtime Data
module PMD_AC
  GUARD_MANIFEST_V040 = {
    :schema_version=>"1.0",
    :content_version=>"0.40.0",
    :base_version=>"0.39.1",
    :feature=>"protect_guard_runtime_i",
    :new_mapped_move_count=>6,
    :previous_mapped_move_count=>237,
    :cumulative_mapped_move_count=>243,
    :learnset_reference_total=>7005,
    :new_reference_covered=>154,
    :cumulative_reference_covered=>4077,
    :cumulative_coverage_percent=>58.20,
    :guard_duration_frames=>60,
    :personal_guards=>[:protect,:detect,:endure],
    :aura_guards=>[:wide_guard,:quick_guard],
    :aura_radius=>[145,96],
    :feint_breaks_guard=>true,
    :shadow_force_bypass_integrated=>true,
    :protect_scope=>"hostile_protectable_moves_plus_basic",
    :wide_guard_scope=>"multi_target_only",
    :quick_guard_scope=>"priority_gt_0_only",
    :endure_min_hp=>1,
    :success_decay_mode=>"energy_gated_no_extra_rng",
    :ref_counts=>{:protect=>37,:detect=>16,:endure=>21,:wide_guard=>6,:quick_guard=>4,:feint=>70},
    :runtime_checksum32=>922966613,
  }
  GUARD_MOVE_V040 = {
    :protect=>{:name=>"守住",:name_en=>"Protect",:type=>:normal,:category=>:status,:priority=>4,:energy_cost_hint=>40,:guard_kind=>:protect,:duration_frames=>60,:target_type=>:self,:policy=>:self,:delivery=>:instant,:visual_kind=>:guard_self,:cast_cat=>:energy_charge,:hit_cat=>:tone_sustain,:move_key=>:protect,:runtime_skill_key=>"mv_protect",:behavior_status=>:implemented_guard_v040,:energy_runtime_mode=>:full_bar_v015,:canonical_move_key=>:protect,:canonical_power=>0,:move_type=>:normal,:damage_category=>:status,:effects=>[{:type=>"guard_effect",:key=>:protect,:frames=>60}]},
    :detect=>{:name=>"看穿",:name_en=>"Detect",:type=>:fighting,:category=>:status,:priority=>4,:energy_cost_hint=>40,:guard_kind=>:detect,:duration_frames=>60,:target_type=>:self,:policy=>:self,:delivery=>:instant,:visual_kind=>:guard_self,:cast_cat=>:tone_mid_beep,:hit_cat=>:tone_sustain,:move_key=>:detect,:runtime_skill_key=>"mv_detect",:behavior_status=>:implemented_guard_v040,:energy_runtime_mode=>:full_bar_v015,:canonical_move_key=>:detect,:canonical_power=>0,:move_type=>:fighting,:damage_category=>:status,:effects=>[{:type=>"guard_effect",:key=>:detect,:frames=>60}]},
    :endure=>{:name=>"挺住",:name_en=>"Endure",:type=>:normal,:category=>:status,:priority=>4,:energy_cost_hint=>40,:guard_kind=>:endure,:duration_frames=>60,:target_type=>:self,:policy=>:self,:delivery=>:instant,:visual_kind=>:guard_self,:cast_cat=>:low_thump,:hit_cat=>:energy_rise,:move_key=>:endure,:runtime_skill_key=>"mv_endure",:behavior_status=>:implemented_guard_v040,:energy_runtime_mode=>:full_bar_v015,:canonical_move_key=>:endure,:canonical_power=>0,:move_type=>:normal,:damage_category=>:status,:effects=>[{:type=>"guard_effect",:key=>:endure,:frames=>60}]},
    :wide_guard=>{:name=>"廣域防守",:name_en=>"Wide Guard",:type=>:rock,:category=>:status,:priority=>3,:energy_cost_hint=>50,:guard_kind=>:wide_guard,:duration_frames=>60,:target_type=>:self,:policy=>:self,:delivery=>:instant,:visual_kind=>:guard_aura,:radius_x=>145,:radius_y=>96,:cast_cat=>:low_rumble,:hit_cat=>:impact_heavy,:move_key=>:wide_guard,:runtime_skill_key=>"mv_wide_guard",:behavior_status=>:implemented_guard_v040,:energy_runtime_mode=>:full_bar_v015,:canonical_move_key=>:wide_guard,:canonical_power=>0,:move_type=>:rock,:damage_category=>:status,:effects=>[{:type=>"guard_effect",:key=>:wide_guard,:frames=>60}]},
    :quick_guard=>{:name=>"快速防守",:name_en=>"Quick Guard",:type=>:fighting,:category=>:status,:priority=>3,:energy_cost_hint=>50,:guard_kind=>:quick_guard,:duration_frames=>60,:target_type=>:self,:policy=>:self,:delivery=>:instant,:visual_kind=>:guard_aura,:radius_x=>145,:radius_y=>96,:cast_cat=>:wind_whoosh,:hit_cat=>:slash_swish,:move_key=>:quick_guard,:runtime_skill_key=>"mv_quick_guard",:behavior_status=>:implemented_guard_v040,:energy_runtime_mode=>:full_bar_v015,:canonical_move_key=>:quick_guard,:canonical_power=>0,:move_type=>:fighting,:damage_category=>:status,:effects=>[{:type=>"guard_effect",:key=>:quick_guard,:frames=>60}]},
    :feint=>{:name=>"佯攻",:name_en=>"Feint",:type=>:normal,:category=>:physical,:power=>30,:accuracy=>100,:priority=>2,:energy_cost_hint=>30,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.00,:visual_kind=>:projectile,:vfx_style=>:normal,:bypass_protect=>true,:break_guard=>true,:cast_cat=>:wind_whoosh,:launch_cat=>:wind_whoosh,:hit_cat=>:impact_sharp,:move_key=>:feint,:runtime_skill_key=>"mv_feint",:behavior_status=>:implemented_guard_v040,:energy_runtime_mode=>:full_bar_v015,:canonical_move_key=>:feint,:canonical_power=>30,:move_type=>:normal,:damage_category=>:physical,:effects=>[{:type=>:damage,:power=>30}],:projectile_tracking=>"strong"},
  }
  GUARD_VISUAL_V040 = {
    :protect=>{:color=>[80,210,180,58],:width=>92,:height=>54,:z=>63},
    :detect=>{:color=>[175,120,235,58],:width=>92,:height=>54,:z=>63},
    :endure=>{:color=>[240,155,70,58],:width=>92,:height=>54,:z=>63},
    :wide_guard=>{:color=>[215,185,85,48],:width=>290,:height=>172,:z=>62},
    :quick_guard=>{:color=>[80,205,240,48],:width=>290,:height=>172,:z=>62},
  }
  GUARD_AUDIO_V040 = {
    :protect=>{:type=>:normal,:category=>:status,:visual_kind=>:guard_self,:audio_style=>:normal,:cast_cat=>:energy_charge,:launch_cat=>nil,:hit_cat=>:tone_sustain,:special=>true},
    :detect=>{:type=>:fighting,:category=>:status,:visual_kind=>:guard_self,:audio_style=>:fighting,:cast_cat=>:tone_mid_beep,:launch_cat=>nil,:hit_cat=>:tone_sustain,:special=>true},
    :endure=>{:type=>:normal,:category=>:status,:visual_kind=>:guard_self,:audio_style=>:normal,:cast_cat=>:low_thump,:launch_cat=>nil,:hit_cat=>:energy_rise,:special=>true},
    :wide_guard=>{:type=>:rock,:category=>:status,:visual_kind=>:guard_aura,:audio_style=>:rock,:cast_cat=>:low_rumble,:launch_cat=>nil,:hit_cat=>:impact_heavy,:special=>true},
    :quick_guard=>{:type=>:fighting,:category=>:status,:visual_kind=>:guard_aura,:audio_style=>:fighting,:cast_cat=>:wind_whoosh,:launch_cat=>nil,:hit_cat=>:slash_swish,:special=>true},
    :feint=>{:type=>:normal,:category=>:physical,:visual_kind=>:projectile,:audio_style=>:normal,:cast_cat=>:wind_whoosh,:launch_cat=>:wind_whoosh,:hit_cat=>:impact_sharp,:special=>true},
  }
end
