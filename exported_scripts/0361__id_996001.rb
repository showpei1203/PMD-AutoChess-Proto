# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Movepool Production Data v0.99.6
# 分類：非 Level-up 招式 Runtime 補完／稀疏招式表 Production Policy
#
# 【用途】
# 1. 補齊 v0.99.5 Movepool Acquisition 中尚未有 AutoChess Runtime 的 19 招。
# 2. 保留 Level-up 7005 refs 與 Frozen Combat Core，不反向修改舊資料。
# 3. 對「終生 Level-up 不足四招」與「Lv20 前不足四招」建立正式處理分類。
# 4. 對確實缺乏外部招式來源的稀疏物種，加入同一 PokeAPI pin 的
#    Black 2 / White 2 Tutor 補充資料；這是 RPG Tutor 取得內容，不是免費學會。
#
# 【重要規則】
# - 相容 ≠ 取得。Tutor 仍必須先 unlock，再以 instance_uid 教學。
# - Ditto / Unown / Smeargle 是玩法例外，不因「四招 KPI」硬塞無關招式。
# - Cocoon / rapid-evolution 種保留進化與繼承身份；B2W2 Tutor 提供可選養成路線。
# - 所有新招仍走既有 4 Active Moves + learned library + Mastery。
#
# 【可調參數】
# - PLEDGE_WINDOW_FRAMES_V0996：誓約連攜判定時間。
# - PLEDGE_FIELD_FRAMES_V0996：誓約場地效果時間。
# - VOLT_SWITCH_RETREAT_PX_V0996：伏特替換後撤距離。
# - VOLT_SWITCH_RETREAT_FRAMES_V0996：伏特替換後撤動畫幀數。
#
# 【事件／腳本呼叫範例】
# 解鎖 B2W2 Electroweb Tutor：
#   PMD_AC.unlock_tutor_v0995(:electroweb)
# 教給 Caterpie instance_uid=12345：
#   PMD_AC.teach_tutor_v0995(12345, :electroweb)
#
# 【維護規則】
# - RGSS2 / Ruby 1.8 相容。
# - Actor ID 不是 Pokémon identity；個體一律使用 instance_uid。
# - 禁止使用專案排除的 instance-variable introspection helper。
#==============================================================================
module PMD_AC
  MOVEPOOL_PRODUCTION_VERSION_V0996='0.99.6'
  PLEDGE_WINDOW_FRAMES_V0996=120
  PLEDGE_FIELD_FRAMES_V0996=180
  VOLT_SWITCH_RETREAT_PX_V0996=96.0
  VOLT_SWITCH_RETREAT_FRAMES_V0996=10

  MOVEPOOL_EXCLUSIVE_KEYS_V0996=[
    :blast_burn,:cut,:defog,:drain_punch,:fire_pledge,:frenzy_plant,
    :frost_breath,:grass_knot,:grass_pledge,:hydro_cannon,:scald,
    :secret_power,:simple_beam,:skill_swap,:strength,:surf,:tail_slap,
    :volt_switch,:water_pledge
  ]

  MOVEPOOL_EXCLUSIVE_MOVE_V0996={
    :blast_burn=>{:name=>"爆炸烈焰",:name_en=>"Blast Burn",:type=>:fire,:move_type=>:fire,:category=>:special,:damage_category=>:special,:canonical_power=>150,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>240.0,:visual_kind=>:beam,:visual_style=>:fire,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:behavior_status=>:implemented_recharge_v0996,:canonical_move_key=>:blast_burn,:move_key=>:blast_burn,:runtime_skill_key=>"mv_blast_burn",:energy_runtime_mode=>:full_bar_v015},
    :cut=>{:name=>"居合斬",:name_en=>"Cut",:type=>:normal,:move_type=>:normal,:category=>:physical,:damage_category=>:physical,:canonical_power=>50,:accuracy=>95,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>50}],:behavior_status=>:implemented_contact_v0996,:canonical_move_key=>:cut,:move_key=>:cut,:runtime_skill_key=>"mv_cut",:energy_runtime_mode=>:full_bar_v015},
    :defog=>{:name=>"清除濃霧",:name_en=>"Defog",:type=>:flying,:move_type=>:flying,:category=>:status,:damage_category=>:status,:canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>230.0,:visual_kind=>:target_hit,:visual_style=>:flying,:effects=>[{:type=>:defog_v0996}],:behavior_status=>:adapted_hazard_screen_clear_v0996,:canonical_move_key=>:defog,:move_key=>:defog,:runtime_skill_key=>"mv_defog",:energy_runtime_mode=>:full_bar_v015},
    :drain_punch=>{:name=>"吸取拳",:name_en=>"Drain Punch",:type=>:fighting,:move_type=>:fighting,:category=>:physical,:damage_category=>:physical,:canonical_power=>75,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fighting,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>75},{:type=>:drain,:ratio=>0.50}],:behavior_status=>:implemented_drain50_v0996,:canonical_move_key=>:drain_punch,:move_key=>:drain_punch,:runtime_skill_key=>"mv_drain_punch",:energy_runtime_mode=>:full_bar_v015},
    :fire_pledge=>{:name=>"火之誓約",:name_en=>"Fire Pledge",:type=>:fire,:move_type=>:fire,:category=>:special,:damage_category=>:special,:canonical_power=>50,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:fire,:effects=>[{:type=>:damage,:power=>50}],:pledge_v0996=>:fire,:behavior_status=>:implemented_team_combo_v0996,:canonical_move_key=>:fire_pledge,:move_key=>:fire_pledge,:runtime_skill_key=>"mv_fire_pledge",:energy_runtime_mode=>:full_bar_v015},
    :frenzy_plant=>{:name=>"瘋狂植物",:name_en=>"Frenzy Plant",:type=>:grass,:move_type=>:grass,:category=>:special,:damage_category=>:special,:canonical_power=>150,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>240.0,:visual_kind=>:beam,:visual_style=>:grass,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:behavior_status=>:implemented_recharge_v0996,:canonical_move_key=>:frenzy_plant,:move_key=>:frenzy_plant,:runtime_skill_key=>"mv_frenzy_plant",:energy_runtime_mode=>:full_bar_v015},
    :frost_breath=>{:name=>"冰息",:name_en=>"Frost Breath",:type=>:ice,:move_type=>:ice,:category=>:special,:damage_category=>:special,:canonical_power=>40,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:ice,:effects=>[{:type=>:damage,:power=>40,:crit_bonus=>1.0}],:behavior_status=>:implemented_forced_crit_v0996,:canonical_move_key=>:frost_breath,:move_key=>:frost_breath,:runtime_skill_key=>"mv_frost_breath",:energy_runtime_mode=>:full_bar_v015},
    :grass_knot=>{:name=>"打草結",:name_en=>"Grass Knot",:type=>:grass,:move_type=>:grass,:category=>:special,:damage_category=>:special,:canonical_power=>20,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>220.0,:visual_kind=>:projectile,:visual_style=>:grass,:dynamic_power_v0996=>:target_mass,:effects=>[{:type=>:damage,:power=>20}],:behavior_status=>:adapted_species_mass_proxy_v0996,:canonical_move_key=>:grass_knot,:move_key=>:grass_knot,:runtime_skill_key=>"mv_grass_knot",:energy_runtime_mode=>:full_bar_v015},
    :grass_pledge=>{:name=>"草之誓約",:name_en=>"Grass Pledge",:type=>:grass,:move_type=>:grass,:category=>:special,:damage_category=>:special,:canonical_power=>50,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:grass,:effects=>[{:type=>:damage,:power=>50}],:pledge_v0996=>:grass,:behavior_status=>:implemented_team_combo_v0996,:canonical_move_key=>:grass_pledge,:move_key=>:grass_pledge,:runtime_skill_key=>"mv_grass_pledge",:energy_runtime_mode=>:full_bar_v015},
    :hydro_cannon=>{:name=>"加農水炮",:name_en=>"Hydro Cannon",:type=>:water,:move_type=>:water,:category=>:special,:damage_category=>:special,:canonical_power=>150,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>240.0,:visual_kind=>:beam,:visual_style=>:water,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:behavior_status=>:implemented_recharge_v0996,:canonical_move_key=>:hydro_cannon,:move_key=>:hydro_cannon,:runtime_skill_key=>"mv_hydro_cannon",:energy_runtime_mode=>:full_bar_v015},
    :scald=>{:name=>"熱水",:name_en=>"Scald",:type=>:water,:move_type=>:water,:category=>:special,:damage_category=>:special,:canonical_power=>80,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:water,:effects=>[{:type=>:damage,:power=>80}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:burn,:chance=>30,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:behavior_status=>:implemented_burn30_v0996,:canonical_move_key=>:scald,:move_key=>:scald,:runtime_skill_key=>"mv_scald",:energy_runtime_mode=>:full_bar_v015},
    :secret_power=>{:name=>"秘密之力",:name_en=>"Secret Power",:type=>:normal,:move_type=>:normal,:category=>:physical,:damage_category=>:physical,:canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>220.0,:visual_kind=>:projectile,:visual_style=>:normal,:effects=>[{:type=>:damage,:power=>70}],:secret_power_v0996=>true,:behavior_status=>:adapted_weather_secondary_v0996,:canonical_move_key=>:secret_power,:move_key=>:secret_power,:runtime_skill_key=>"mv_secret_power",:energy_runtime_mode=>:full_bar_v015},
    :simple_beam=>{:name=>"單純光束",:name_en=>"Simple Beam",:type=>:normal,:move_type=>:normal,:category=>:status,:damage_category=>:status,:canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>230.0,:visual_kind=>:beam,:visual_style=>:normal,:effects=>[{:type=>:simple_beam_v0996}],:behavior_status=>:implemented_ability_override_v0996,:canonical_move_key=>:simple_beam,:move_key=>:simple_beam,:runtime_skill_key=>"mv_simple_beam",:energy_runtime_mode=>:full_bar_v015},
    :skill_swap=>{:name=>"特性互換",:name_en=>"Skill Swap",:type=>:psychic,:move_type=>:psychic,:category=>:status,:damage_category=>:status,:canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>230.0,:visual_kind=>:beam,:visual_style=>:psychic,:effects=>[{:type=>:skill_swap_v0996}],:behavior_status=>:implemented_ability_swap_v0996,:canonical_move_key=>:skill_swap,:move_key=>:skill_swap,:runtime_skill_key=>"mv_skill_swap",:energy_runtime_mode=>:full_bar_v015},
    :strength=>{:name=>"怪力",:name_en=>"Strength",:type=>:normal,:move_type=>:normal,:category=>:physical,:damage_category=>:physical,:canonical_power=>80,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>80}],:behavior_status=>:implemented_contact_v0996,:canonical_move_key=>:strength,:move_key=>:strength,:runtime_skill_key=>"mv_strength",:energy_runtime_mode=>:full_bar_v015},
    :surf=>{:name=>"衝浪",:name_en=>"Surf",:type=>:water,:move_type=>:water,:category=>:special,:damage_category=>:special,:canonical_power=>95,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,:delivery=>:aoe,:range_px=>240.0,:visual_kind=>:area_hit,:visual_style=>:water,:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>95}],:behavior_status=>:adapted_enemy_side_aoe_v0996,:canonical_move_key=>:surf,:move_key=>:surf,:runtime_skill_key=>"mv_surf",:energy_runtime_mode=>:full_bar_v015},
    :tail_slap=>{:name=>"掃尾拍打",:name_en=>"Tail Slap",:type=>:normal,:move_type=>:normal,:category=>:physical,:damage_category=>:physical,:canonical_power=>25,:accuracy=>85,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>25}],:behavior_status=>:implemented_multi_hit_v0996,:canonical_move_key=>:tail_slap,:move_key=>:tail_slap,:runtime_skill_key=>"mv_tail_slap",:energy_runtime_mode=>:full_bar_v015},
    :volt_switch=>{:name=>"伏特替換",:name_en=>"Volt Switch",:type=>:electric,:move_type=>:electric,:category=>:special,:damage_category=>:special,:canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:electric,:effects=>[{:type=>:damage,:power=>70},{:type=>:volt_retreat_v0996}],:behavior_status=>:adapted_tactical_retreat_v0996,:canonical_move_key=>:volt_switch,:move_key=>:volt_switch,:runtime_skill_key=>"mv_volt_switch",:energy_runtime_mode=>:full_bar_v015},
    :water_pledge=>{:name=>"水之誓約",:name_en=>"Water Pledge",:type=>:water,:move_type=>:water,:category=>:special,:damage_category=>:special,:canonical_power=>50,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:water,:effects=>[{:type=>:damage,:power=>50}],:pledge_v0996=>:water,:behavior_status=>:implemented_team_combo_v0996,:canonical_move_key=>:water_pledge,:move_key=>:water_pledge,:runtime_skill_key=>"mv_water_pledge",:energy_runtime_mode=>:full_bar_v015}
  }

  MOVEPOOL_EXCLUSIVE_VISUAL_V0996={}
  MOVEPOOL_EXCLUSIVE_AUDIO_V0996={}
  MOVEPOOL_EXCLUSIVE_MOVE_V0996.each do |k,d|
    MOVEPOOL_EXCLUSIVE_VISUAL_V0996[k]={:visual_kind=>d[:visual_kind],:style=>d[:visual_style],:hide_logical_projectile=>false,:timing=>:cast_resolve}
    MOVEPOOL_EXCLUSIVE_AUDIO_V0996[k]={:type=>d[:type],:category=>d[:category],:visual_kind=>d[:visual_kind],:audio_style=>d[:visual_style],:cast_cat=>(d[:category]==:status ? :magic_chime : :snap_click),:launch_cat=>([:projectile,:aoe,:beam].include?(d[:delivery]) ? :wind_hiss : nil),:hit_cat=>(d[:category]==:status ? :tone_soft : :impact_mid),:special=>true}
  end

  # 同一 PokeAPI pin，Black 2 / White 2 (version_group) 的稀疏物種 Tutor 補充。
  # 這些只是「可由 Tutor 教學」的相容資料，不會自動學會。
  SPARSE_TUTOR_B2W2_V0996={
    :caterpie=>[:snore,:bug_bite,:electroweb],
    :metapod=>[:iron_defense,:bug_bite,:electroweb],
    :weedle=>[:bug_bite,:electroweb],
    :kakuna=>[:iron_defense,:bug_bite,:electroweb],
    :magikarp=>[:bounce],
    :silcoon=>[:iron_defense,:bug_bite,:electroweb],
    :cascoon=>[:iron_defense,:bug_bite,:electroweb],
    :beldum=>[:iron_defense,:zen_headbutt,:iron_head],
    :combee=>[:snore,:endeavor,:tailwind,:bug_bite]
  }

  SPARSE_LIFETIME_LT4_V0996=[:caterpie,:metapod,:weedle,:kakuna,:abra,:magikarp,:ditto,:unown,:delibird,:smeargle,:silcoon,:cascoon,:feebas,:beldum,:combee]
  SPARSE_LV20_LT4_V0996=[:caterpie,:metapod,:weedle,:kakuna,:abra,:magikarp,:gyarados,:ditto,:unown,:delibird,:smeargle,:silcoon,:cascoon,:trapinch,:feebas,:beldum,:combee,:heatran,:shaymin]

  SPARSE_POLICY_V0996={
    :caterpie=>{:resolution=>:b2w2_tutor_and_rapid_evolution,:four_move_rule=>:normal},
    :metapod=>{:resolution=>:b2w2_tutor_and_lineage_inheritance,:four_move_rule=>:normal},
    :weedle=>{:resolution=>:b2w2_tutor_and_rapid_evolution,:four_move_rule=>:normal},
    :kakuna=>{:resolution=>:b2w2_tutor_and_lineage_inheritance,:four_move_rule=>:normal},
    :abra=>{:resolution=>:bw_machine_egg_and_evolution,:four_move_rule=>:normal},
    :magikarp=>{:resolution=>:b2w2_bounce_and_evolution,:four_move_rule=>:normal},
    :gyarados=>{:resolution=>:bw_machine_and_evolution_level,:four_move_rule=>:normal},
    :ditto=>{:resolution=>:identity_exception_transform,:four_move_rule=>:exempt},
    :unown=>{:resolution=>:identity_exception_hidden_power,:four_move_rule=>:exempt},
    :delibird=>{:resolution=>:bw_machine_egg,:four_move_rule=>:normal},
    :smeargle=>{:resolution=>:identity_exception_sketch,:four_move_rule=>:exempt},
    :silcoon=>{:resolution=>:b2w2_tutor_and_lineage_inheritance,:four_move_rule=>:normal},
    :cascoon=>{:resolution=>:b2w2_tutor_and_lineage_inheritance,:four_move_rule=>:normal},
    :trapinch=>{:resolution=>:bw_machine_egg,:four_move_rule=>:normal},
    :feebas=>{:resolution=>:bw_machine_egg_and_evolution,:four_move_rule=>:normal},
    :beldum=>{:resolution=>:b2w2_tutor_and_evolution,:four_move_rule=>:normal},
    :combee=>{:resolution=>:b2w2_tutor,:four_move_rule=>:normal},
    :heatran=>{:resolution=>:bw_machine_and_high_level_encounter,:four_move_rule=>:normal},
    :shaymin=>{:resolution=>:bw_machine_and_high_level_encounter,:four_move_rule=>:normal}
  }

  MOVEPOOL_PRODUCTION_MANIFEST_V0996={
    :version=>'0.99.6',:base=>'0.99.5',:exclusive_runtime_moves=>19,
    :nonlevel_unique=>434,:expected_nonlevel_executable=>434,:expected_nonlevel_blocked=>0,
    :sparse_lifetime_lt4=>15,:sparse_lv20_lt4=>19,:identity_exceptions=>3,
    :supplemental_tutor_species=>9,:supplemental_tutor_refs=>25,
    :supplemental_tutor_version_group=>'black-2-white-2',
    :source_commit=>'fb1605aac09064bb34a12a8b790c2b800b4d0550'
  }
end
