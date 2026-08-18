#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Move Runtime Coverage Data v0.51
# 分類：技能資料／效果覆蓋
#
# 【用途／機制】
# 定義 MoveDB、招式 Runtime 行為與 7005/7005 learnset reference 覆蓋。
#
# 【怎麼調整】
# 新增招式效果優先放在資料表與共用 foundation；不要為每招複製一份傷害流程。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_COVERAGE_III_CHECKSUM_TEXT_V051 / MOVE_COVERAGE_III_MANIFEST_V051 / MOVE_COVERAGE_III_MOVE_V051 / MOVE_PRESENTATION_V051
# - MOVE_COVERAGE_III_VISUAL_V051 / MOVE_COVERAGE_III_AUDIO_V051
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Move Runtime Coverage Data v0.51
#    Coverage Expansion III + Functional Presentation Profiles I
#-------------------------------------------------------------------------------
# Additive on v0.50. Includes an audited correction for historical Feint refs.
#===============================================================================
module PMD_AC
  MOVE_COVERAGE_III_CHECKSUM_TEXT_V051 = "mud_sport|ground|status|None|None|self|instant|:effects=>[{:type=>:sport_field_v051,:key=>:mud_sport,:turns=>5}],:field_runtime_v051=>true|30|('self_fx', 'ground', 'field_pulse', 'field_5t', 'cast_then_field', 'cast', 'none', 'field_ground', 'ground_field');earthquake|ground|physical|100|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>100}]|28|('area_hit', 'ground', 'ground', 'none', 'impact_same_frame', 'attack', 'hurt', 'shake', 'ground_impact');discharge|electric|special|80|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>80}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:paralysis,:chance=>30,:receiver=>:target,:duration=>180}]|27|('area_hit', 'electric', 'electric', 'none', 'impact_same_frame', 'charge', 'hurt', 'flash', 'electric_burst');hyper_beam|normal|special|150|90|enemy_targeted|beam|:beam_style=>:aurora,:beam_life=>26,:beam_width=>9,:cast_frames=>36,:hit_frame=>14,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:recharge_runtime_v051=>true|26|('beam', 'aurora', 'aurora', 'recharge', 'beam_then_recharge60', 'charge', 'hurt', 'flash', 'beam_heavy');leech_seed|grass|status|None|90|enemy_targeted|projectile|:effects=>[{:type=>:leech_seed_v051,:duration=>300,:interval=>60,:ratio=>0.125}],:persistent_runtime_v051=>true|24|('projectile', 'seed', 'grass', 'leech_pulse', 'projectile_then_tick60', 'shoot', 'hurt', 'none', 'seed_drain');water_sport|water|status|None|None|self|instant|:effects=>[{:type=>:sport_field_v051,:key=>:water_sport,:turns=>5}],:field_runtime_v051=>true|24|('self_fx', 'water', 'field_pulse', 'field_5t', 'cast_then_field', 'cast', 'none', 'field_water', 'water_field');flail|normal|physical|20|100|enemy_targeted|instant|:force_contact_range=>true,:dynamic_power_v051=>:flail,:effects=>[{:type=>:damage,:power=>20}],:contact=>true|24|('contact_hit', 'normal', 'normal', 'none', 'contact_same_frame', 'attack', 'hurt', 'none', 'impact_mid');explosion|normal|physical|250|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>250}],:self_faint_after_aoe_v051=>true|22|('area_hit', 'normal', 'normal', 'none', 'aoe_then_selfko', 'charge', 'hurt', 'shake_flash', 'explosion');fire_spin|fire|special|35|85|enemy_targeted|projectile|:effects=>[{:type=>:damage,:power=>35},{:type=>:fire_spin_trap_v051,:duration=>300,:interval=>60,:ratio=>0.0625,:slow=>0.35}],:persistent_runtime_v051=>true|19|('projectile', 'fire', 'fire', 'fire_trap', 'projectile_then_tick60', 'shoot', 'hurt', 'none', 'fire_trap');brine|water|special|65|100|enemy_targeted|projectile|:dynamic_power_v051=>:brine,:effects=>[{:type=>:damage,:power=>65}]|19|('projectile', 'water', 'water', 'none', 'projectile_hit', 'shoot', 'hurt', 'none', 'water_hit');electro_ball|electric|special|40|100|enemy_targeted|projectile|:dynamic_power_v051=>:electro_ball,:effects=>[{:type=>:damage,:power=>40}]|18|('projectile', 'electric', 'electric', 'none', 'projectile_hit', 'shoot', 'hurt', 'flash', 'electric_ball');gyro_ball|steel|physical|1|100|enemy_targeted|instant|:force_contact_range=>true,:dynamic_power_v051=>:gyro_ball,:effects=>[{:type=>:damage,:power=>1}],:contact=>true|18|('contact_hit', 'steel', 'steel', 'none', 'contact_same_frame', 'attack', 'hurt', 'none', 'steel_hit');night_shade|ghost|special|None|100|enemy_targeted|projectile|:effects=>[{:type=>:fixed_damage_v050,:level_based=>true}]|16|('projectile', 'ghost', 'ghost', 'none', 'projectile_hit', 'cast', 'hurt', 'darken', 'ghost_hit');haze|ice|status|None|None|self|instant|:effects=>[{:type=>:haze_v051}],:global_status_runtime_v051=>true|15|('self_fx', 'ice', 'ice', 'field_pulse', 'global_clear', 'cast', 'none', 'mist', 'ice_field');hex|ghost|special|50|100|enemy_targeted|projectile|:dynamic_power_v051=>:hex,:effects=>[{:type=>:damage,:power=>50}]|15|('projectile', 'ghost', 'ghost', 'none', 'projectile_hit', 'cast', 'hurt', 'darken', 'ghost_hit');stone_edge|rock|physical|100|80|enemy_targeted|projectile|:effects=>[{:type=>:damage,:power=>100,:crit_bonus=>0.075}]|15|('projectile', 'rock', 'rock', 'none', 'projectile_hit', 'attack', 'hurt', 'shake', 'rock_hit');lava_plume|fire|special|80|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>80}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:burn,:chance=>30,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}]|15|('area_hit', 'fire', 'fire', 'none', 'area_hit', 'cast', 'hurt', 'flash', 'fire_burst');solar_beam|grass|special|120|100|enemy_targeted|beam|:beam_style=>:aurora,:beam_life=>30,:beam_width=>10,:effects=>[{:type=>:damage,:power=>120}],:solar_charge_v051=>true,:charge_frames_v051=>60|14|('beam', 'aurora', 'grass', 'charge_glow', 'charge60_then_beam', 'charge', 'hurt', 'flash', 'solar_beam');flame_burst|fire|special|70|100|enemy_targeted|projectile|:effects=>[{:type=>:damage,:power=>70},{:type=>:flame_burst_splash_v051,:radius=>92.0,:ratio=>0.0625}]|13|('projectile', 'fire', 'fire', 'splash', 'projectile_then_splash', 'shoot', 'hurt', 'flash', 'fire_burst');ingrain|grass|status|None|None|self|instant|:effects=>[{:type=>:ingrain_v051,:duration=>300,:interval=>60,:ratio=>0.0625}],:persistent_runtime_v051=>true|13|('self_fx', 'grass', 'grass', 'root_pulse', 'cast_then_regen60', 'cast', 'none', 'none', 'grass_sustain');acrobatics|flying|physical|55|100|enemy_targeted|instant|:force_contact_range=>true,:dynamic_power_v051=>:acrobatics,:effects=>[{:type=>:damage,:power=>55}],:contact=>true|12|('contact_hit', 'flying', 'flying', 'none', 'contact_same_frame', 'attack', 'hurt', 'none', 'flying_hit');magnitude|ground|physical|70|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:dynamic_power_v051=>:magnitude,:effects=>[{:type=>:damage,:power=>70}]|11|('area_hit', 'ground', 'ground', 'none', 'roll_then_area_hit', 'attack', 'hurt', 'shake', 'ground_impact');magnet_rise|electric|status|None|None|self|instant|:effects=>[{:type=>:magnet_rise_v051,:duration=>300}],:persistent_runtime_v051=>true|12|('self_fx', 'electric', 'electric', 'airborne_glow', 'cast_then_airborne5t', 'cast', 'none', 'float', 'electric_sustain');self_destruct|normal|physical|200|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>200}],:self_faint_after_aoe_v051=>true|12|('area_hit', 'normal', 'normal', 'none', 'aoe_then_selfko', 'charge', 'hurt', 'shake_flash', 'explosion');audit:4955:-44:4911:5353"
  MOVE_COVERAGE_III_MANIFEST_V051 = {
    :schema_version=>"1.0", :content_version=>"0.51.0", :base_version=>"0.50",
    :feature=>"move_runtime_coverage_expansion_iii_presentation_i",
    :new_mapped_move_count=>24, :previous_mapped_move_count=>299, :cumulative_mapped_move_count=>323,
    :learnset_reference_total=>7005, :new_reference_covered=>442,
    :previous_reported_reference_covered=>4955, :coverage_audit_correction=>-44,
    :previous_audited_reference_covered=>4911, :cumulative_reference_covered=>5353,
    :cumulative_coverage_percent=>76.42,
    :coverage_audit_reason=>"v0.40 Feint ref count 70 -> SpeciesDB actual 26",
    :new_move_keys=>[:mud_sport,:earthquake,:discharge,:hyper_beam,:leech_seed,:water_sport,:flail,:explosion,:fire_spin,:brine,:electro_ball,:gyro_ball,:night_shade,:haze,:hex,:stone_edge,:lava_plume,:solar_beam,:flame_burst,:ingrain,:acrobatics,:magnitude,:magnet_rise,:self_destruct],
    :ref_counts=>{:mud_sport=>30,:earthquake=>28,:discharge=>27,:hyper_beam=>26,:leech_seed=>24,:water_sport=>24,:flail=>24,:explosion=>22,:fire_spin=>19,:brine=>19,:electro_ball=>18,:gyro_ball=>18,:night_shade=>16,:haze=>15,:hex=>15,:stone_edge=>15,:lava_plume=>15,:solar_beam=>14,:flame_burst=>13,:ingrain=>13,:acrobatics=>12,:magnitude=>11,:magnet_rise=>12,:self_destruct=>12},
    :presentation_profile_count=>24, :visual_profile_count=>24, :audio_profile_count=>24, :timing_profile_count=>24,
    :functional_sync=>[:charge,:recharge,:persistent,:area,:self_faint,:dynamic_power,:field_pulse],
    :runtime_checksum32=>1369075995, :next_phase=>"move_runtime_coverage_expansion_iv"
  }

  MOVE_COVERAGE_III_MOVE_V051 = {
    :mud_sport=>{:name=>"玩泥巴",:name_en=>"Mud Sport",:type=>:ground,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:ground,
      :effects=>[{:type=>:sport_field_v051,:key=>:mud_sport,:turns=>5}],:field_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:mud_sport,:canonical_move_key=>:mud_sport,:runtime_skill_key=>"mv_mud_sport",
      :move_type=>:ground,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :earthquake=>{:name=>"地震",:name_en=>"Earthquake",:type=>:ground,:category=>:physical,
      :canonical_power=>100,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:ground,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>100}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:earthquake,:canonical_move_key=>:earthquake,:runtime_skill_key=>"mv_earthquake",
      :move_type=>:ground,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :discharge=>{:name=>"放電",:name_en=>"Discharge",:type=>:electric,:category=>:special,
      :canonical_power=>80,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:electric,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>80}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:paralysis,:chance=>30,:receiver=>:target,:duration=>180}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:discharge,:canonical_move_key=>:discharge,:runtime_skill_key=>"mv_discharge",
      :move_type=>:electric,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :hyper_beam=>{:name=>"破壞光線",:name_en=>"Hyper Beam",:type=>:normal,:category=>:special,
      :canonical_power=>150,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:beam,:range_px=>230.0,:visual_kind=>:beam,:visual_style=>:aurora,
      :beam_style=>:aurora,:beam_life=>26,:beam_width=>9,:cast_frames=>36,:hit_frame=>14,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:recharge_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:hyper_beam,:canonical_move_key=>:hyper_beam,:runtime_skill_key=>"mv_hyper_beam",
      :move_type=>:normal,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :leech_seed=>{:name=>"寄生種子",:name_en=>"Leech Seed",:type=>:grass,:category=>:status,
      :canonical_power=>nil,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:seed,
      :effects=>[{:type=>:leech_seed_v051,:duration=>300,:interval=>60,:ratio=>0.125}],:persistent_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:leech_seed,:canonical_move_key=>:leech_seed,:runtime_skill_key=>"mv_leech_seed",
      :move_type=>:grass,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :water_sport=>{:name=>"玩水",:name_en=>"Water Sport",:type=>:water,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:water,
      :effects=>[{:type=>:sport_field_v051,:key=>:water_sport,:turns=>5}],:field_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:water_sport,:canonical_move_key=>:water_sport,:runtime_skill_key=>"mv_water_sport",
      :move_type=>:water,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :flail=>{:name=>"抓狂",:name_en=>"Flail",:type=>:normal,:category=>:physical,
      :canonical_power=>20,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,
      :force_contact_range=>true,:dynamic_power_v051=>:flail,:effects=>[{:type=>:damage,:power=>20}],:contact=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:flail,:canonical_move_key=>:flail,:runtime_skill_key=>"mv_flail",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :explosion=>{:name=>"大爆炸",:name_en=>"Explosion",:type=>:normal,:category=>:physical,
      :canonical_power=>250,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:normal,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>250}],:self_faint_after_aoe_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:explosion,:canonical_move_key=>:explosion,:runtime_skill_key=>"mv_explosion",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :fire_spin=>{:name=>"火焰旋渦",:name_en=>"Fire Spin",:type=>:fire,:category=>:special,
      :canonical_power=>35,:accuracy=>85,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:fire,
      :effects=>[{:type=>:damage,:power=>35},{:type=>:fire_spin_trap_v051,:duration=>300,:interval=>60,:ratio=>0.0625,:slow=>0.35}],:persistent_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:fire_spin,:canonical_move_key=>:fire_spin,:runtime_skill_key=>"mv_fire_spin",
      :move_type=>:fire,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :brine=>{:name=>"鹽水",:name_en=>"Brine",:type=>:water,:category=>:special,
      :canonical_power=>65,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:water,
      :dynamic_power_v051=>:brine,:effects=>[{:type=>:damage,:power=>65}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:brine,:canonical_move_key=>:brine,:runtime_skill_key=>"mv_brine",
      :move_type=>:water,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :electro_ball=>{:name=>"電球",:name_en=>"Electro Ball",:type=>:electric,:category=>:special,
      :canonical_power=>40,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:electric,
      :dynamic_power_v051=>:electro_ball,:effects=>[{:type=>:damage,:power=>40}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:electro_ball,:canonical_move_key=>:electro_ball,:runtime_skill_key=>"mv_electro_ball",
      :move_type=>:electric,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :gyro_ball=>{:name=>"陀螺球",:name_en=>"Gyro Ball",:type=>:steel,:category=>:physical,
      :canonical_power=>1,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:steel,
      :force_contact_range=>true,:dynamic_power_v051=>:gyro_ball,:effects=>[{:type=>:damage,:power=>1}],:contact=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:gyro_ball,:canonical_move_key=>:gyro_ball,:runtime_skill_key=>"mv_gyro_ball",
      :move_type=>:steel,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :night_shade=>{:name=>"黑夜魔影",:name_en=>"Night Shade",:type=>:ghost,:category=>:special,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:ghost,
      :effects=>[{:type=>:fixed_damage_v050,:level_based=>true}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:night_shade,:canonical_move_key=>:night_shade,:runtime_skill_key=>"mv_night_shade",
      :move_type=>:ghost,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :haze=>{:name=>"黑霧",:name_en=>"Haze",:type=>:ice,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:ice,
      :effects=>[{:type=>:haze_v051}],:global_status_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:haze,:canonical_move_key=>:haze,:runtime_skill_key=>"mv_haze",
      :move_type=>:ice,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :hex=>{:name=>"禍不單行",:name_en=>"Hex",:type=>:ghost,:category=>:special,
      :canonical_power=>50,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:ghost,
      :dynamic_power_v051=>:hex,:effects=>[{:type=>:damage,:power=>50}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:hex,:canonical_move_key=>:hex,:runtime_skill_key=>"mv_hex",
      :move_type=>:ghost,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :stone_edge=>{:name=>"尖石攻擊",:name_en=>"Stone Edge",:type=>:rock,:category=>:physical,
      :canonical_power=>100,:accuracy=>80,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:rock,
      :effects=>[{:type=>:damage,:power=>100,:crit_bonus=>0.075}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:stone_edge,:canonical_move_key=>:stone_edge,:runtime_skill_key=>"mv_stone_edge",
      :move_type=>:rock,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :lava_plume=>{:name=>"噴煙",:name_en=>"Lava Plume",:type=>:fire,:category=>:special,
      :canonical_power=>80,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:fire,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>80}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:burn,:chance=>30,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:lava_plume,:canonical_move_key=>:lava_plume,:runtime_skill_key=>"mv_lava_plume",
      :move_type=>:fire,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :solar_beam=>{:name=>"日光束",:name_en=>"Solar Beam",:type=>:grass,:category=>:special,
      :canonical_power=>120,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:beam,:range_px=>230.0,:visual_kind=>:beam,:visual_style=>:aurora,
      :beam_style=>:aurora,:beam_life=>30,:beam_width=>10,:effects=>[{:type=>:damage,:power=>120}],:solar_charge_v051=>true,:charge_frames_v051=>60,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:solar_beam,:canonical_move_key=>:solar_beam,:runtime_skill_key=>"mv_solar_beam",
      :move_type=>:grass,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :flame_burst=>{:name=>"烈焰濺射",:name_en=>"Flame Burst",:type=>:fire,:category=>:special,
      :canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:fire,
      :effects=>[{:type=>:damage,:power=>70},{:type=>:flame_burst_splash_v051,:radius=>92.0,:ratio=>0.0625}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:flame_burst,:canonical_move_key=>:flame_burst,:runtime_skill_key=>"mv_flame_burst",
      :move_type=>:fire,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :ingrain=>{:name=>"扎根",:name_en=>"Ingrain",:type=>:grass,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:grass,
      :effects=>[{:type=>:ingrain_v051,:duration=>300,:interval=>60,:ratio=>0.0625}],:persistent_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:ingrain,:canonical_move_key=>:ingrain,:runtime_skill_key=>"mv_ingrain",
      :move_type=>:grass,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :acrobatics=>{:name=>"雜技",:name_en=>"Acrobatics",:type=>:flying,:category=>:physical,
      :canonical_power=>55,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:flying,
      :force_contact_range=>true,:dynamic_power_v051=>:acrobatics,:effects=>[{:type=>:damage,:power=>55}],:contact=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:acrobatics,:canonical_move_key=>:acrobatics,:runtime_skill_key=>"mv_acrobatics",
      :move_type=>:flying,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :magnitude=>{:name=>"震級",:name_en=>"Magnitude",:type=>:ground,:category=>:physical,
      :canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:ground,
      :radius=>999.0,:global_direct=>true,:dynamic_power_v051=>:magnitude,:effects=>[{:type=>:damage,:power=>70}],:behavior_status=>:implemented_coverage_v051,
      :move_key=>:magnitude,:canonical_move_key=>:magnitude,:runtime_skill_key=>"mv_magnitude",
      :move_type=>:ground,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :magnet_rise=>{:name=>"電磁飄浮",:name_en=>"Magnet Rise",:type=>:electric,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:electric,
      :effects=>[{:type=>:magnet_rise_v051,:duration=>300}],:persistent_runtime_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:magnet_rise,:canonical_move_key=>:magnet_rise,:runtime_skill_key=>"mv_magnet_rise",
      :move_type=>:electric,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :self_destruct=>{:name=>"自爆",:name_en=>"Self-Destruct",:type=>:normal,:category=>:physical,
      :canonical_power=>200,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:normal,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>200}],:self_faint_after_aoe_v051=>true,:behavior_status=>:implemented_coverage_v051,
      :move_key=>:self_destruct,:canonical_move_key=>:self_destruct,:runtime_skill_key=>"mv_self_destruct",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015}
  }

  MOVE_PRESENTATION_V051 = {
    :mud_sport=>{:cast_visual=>:ground,:visual_kind=>:self_fx,:projectile_visual=>:ground,:impact_visual=>:field_pulse,:persistent_visual=>:field_5t,:timing=>:cast_then_field,:user_motion=>:cast,:target_motion=>:none,:screen_effect=>:field_ground,:sfx_profile=>:ground_field},
    :earthquake=>{:cast_visual=>:ground,:visual_kind=>:area_hit,:projectile_visual=>:ground,:impact_visual=>:ground,:persistent_visual=>:none,:timing=>:impact_same_frame,:user_motion=>:attack,:target_motion=>:hurt,:screen_effect=>:shake,:sfx_profile=>:ground_impact},
    :discharge=>{:cast_visual=>:electric,:visual_kind=>:area_hit,:projectile_visual=>:electric,:impact_visual=>:electric,:persistent_visual=>:none,:timing=>:impact_same_frame,:user_motion=>:charge,:target_motion=>:hurt,:screen_effect=>:flash,:sfx_profile=>:electric_burst},
    :hyper_beam=>{:cast_visual=>:aurora,:visual_kind=>:beam,:projectile_visual=>:aurora,:impact_visual=>:aurora,:persistent_visual=>:recharge,:timing=>:beam_then_recharge60,:user_motion=>:charge,:target_motion=>:hurt,:screen_effect=>:flash,:sfx_profile=>:beam_heavy},
    :leech_seed=>{:cast_visual=>:seed,:visual_kind=>:projectile,:projectile_visual=>:seed,:impact_visual=>:grass,:persistent_visual=>:leech_pulse,:timing=>:projectile_then_tick60,:user_motion=>:shoot,:target_motion=>:hurt,:screen_effect=>:none,:sfx_profile=>:seed_drain},
    :water_sport=>{:cast_visual=>:water,:visual_kind=>:self_fx,:projectile_visual=>:water,:impact_visual=>:field_pulse,:persistent_visual=>:field_5t,:timing=>:cast_then_field,:user_motion=>:cast,:target_motion=>:none,:screen_effect=>:field_water,:sfx_profile=>:water_field},
    :flail=>{:cast_visual=>:normal,:visual_kind=>:contact_hit,:projectile_visual=>:normal,:impact_visual=>:normal,:persistent_visual=>:none,:timing=>:contact_same_frame,:user_motion=>:attack,:target_motion=>:hurt,:screen_effect=>:none,:sfx_profile=>:impact_mid},
    :explosion=>{:cast_visual=>:normal,:visual_kind=>:area_hit,:projectile_visual=>:normal,:impact_visual=>:normal,:persistent_visual=>:none,:timing=>:aoe_then_selfko,:user_motion=>:charge,:target_motion=>:hurt,:screen_effect=>:shake_flash,:sfx_profile=>:explosion},
    :fire_spin=>{:cast_visual=>:fire,:visual_kind=>:projectile,:projectile_visual=>:fire,:impact_visual=>:fire,:persistent_visual=>:fire_trap,:timing=>:projectile_then_tick60,:user_motion=>:shoot,:target_motion=>:hurt,:screen_effect=>:none,:sfx_profile=>:fire_trap},
    :brine=>{:cast_visual=>:water,:visual_kind=>:projectile,:projectile_visual=>:water,:impact_visual=>:water,:persistent_visual=>:none,:timing=>:projectile_hit,:user_motion=>:shoot,:target_motion=>:hurt,:screen_effect=>:none,:sfx_profile=>:water_hit},
    :electro_ball=>{:cast_visual=>:electric,:visual_kind=>:projectile,:projectile_visual=>:electric,:impact_visual=>:electric,:persistent_visual=>:none,:timing=>:projectile_hit,:user_motion=>:shoot,:target_motion=>:hurt,:screen_effect=>:flash,:sfx_profile=>:electric_ball},
    :gyro_ball=>{:cast_visual=>:steel,:visual_kind=>:contact_hit,:projectile_visual=>:steel,:impact_visual=>:steel,:persistent_visual=>:none,:timing=>:contact_same_frame,:user_motion=>:attack,:target_motion=>:hurt,:screen_effect=>:none,:sfx_profile=>:steel_hit},
    :night_shade=>{:cast_visual=>:ghost,:visual_kind=>:projectile,:projectile_visual=>:ghost,:impact_visual=>:ghost,:persistent_visual=>:none,:timing=>:projectile_hit,:user_motion=>:cast,:target_motion=>:hurt,:screen_effect=>:darken,:sfx_profile=>:ghost_hit},
    :haze=>{:cast_visual=>:ice,:visual_kind=>:self_fx,:projectile_visual=>:ice,:impact_visual=>:ice,:persistent_visual=>:field_pulse,:timing=>:global_clear,:user_motion=>:cast,:target_motion=>:none,:screen_effect=>:mist,:sfx_profile=>:ice_field},
    :hex=>{:cast_visual=>:ghost,:visual_kind=>:projectile,:projectile_visual=>:ghost,:impact_visual=>:ghost,:persistent_visual=>:none,:timing=>:projectile_hit,:user_motion=>:cast,:target_motion=>:hurt,:screen_effect=>:darken,:sfx_profile=>:ghost_hit},
    :stone_edge=>{:cast_visual=>:rock,:visual_kind=>:projectile,:projectile_visual=>:rock,:impact_visual=>:rock,:persistent_visual=>:none,:timing=>:projectile_hit,:user_motion=>:attack,:target_motion=>:hurt,:screen_effect=>:shake,:sfx_profile=>:rock_hit},
    :lava_plume=>{:cast_visual=>:fire,:visual_kind=>:area_hit,:projectile_visual=>:fire,:impact_visual=>:fire,:persistent_visual=>:none,:timing=>:area_hit,:user_motion=>:cast,:target_motion=>:hurt,:screen_effect=>:flash,:sfx_profile=>:fire_burst},
    :solar_beam=>{:cast_visual=>:aurora,:visual_kind=>:beam,:projectile_visual=>:aurora,:impact_visual=>:grass,:persistent_visual=>:charge_glow,:timing=>:charge60_then_beam,:user_motion=>:charge,:target_motion=>:hurt,:screen_effect=>:flash,:sfx_profile=>:solar_beam},
    :flame_burst=>{:cast_visual=>:fire,:visual_kind=>:projectile,:projectile_visual=>:fire,:impact_visual=>:fire,:persistent_visual=>:splash,:timing=>:projectile_then_splash,:user_motion=>:shoot,:target_motion=>:hurt,:screen_effect=>:flash,:sfx_profile=>:fire_burst},
    :ingrain=>{:cast_visual=>:grass,:visual_kind=>:self_fx,:projectile_visual=>:grass,:impact_visual=>:grass,:persistent_visual=>:root_pulse,:timing=>:cast_then_regen60,:user_motion=>:cast,:target_motion=>:none,:screen_effect=>:none,:sfx_profile=>:grass_sustain},
    :acrobatics=>{:cast_visual=>:flying,:visual_kind=>:contact_hit,:projectile_visual=>:flying,:impact_visual=>:flying,:persistent_visual=>:none,:timing=>:contact_same_frame,:user_motion=>:attack,:target_motion=>:hurt,:screen_effect=>:none,:sfx_profile=>:flying_hit},
    :magnitude=>{:cast_visual=>:ground,:visual_kind=>:area_hit,:projectile_visual=>:ground,:impact_visual=>:ground,:persistent_visual=>:none,:timing=>:roll_then_area_hit,:user_motion=>:attack,:target_motion=>:hurt,:screen_effect=>:shake,:sfx_profile=>:ground_impact},
    :magnet_rise=>{:cast_visual=>:electric,:visual_kind=>:self_fx,:projectile_visual=>:electric,:impact_visual=>:electric,:persistent_visual=>:airborne_glow,:timing=>:cast_then_airborne5t,:user_motion=>:cast,:target_motion=>:none,:screen_effect=>:float,:sfx_profile=>:electric_sustain},
    :self_destruct=>{:cast_visual=>:normal,:visual_kind=>:area_hit,:projectile_visual=>:normal,:impact_visual=>:normal,:persistent_visual=>:none,:timing=>:aoe_then_selfko,:user_motion=>:charge,:target_motion=>:hurt,:screen_effect=>:shake_flash,:sfx_profile=>:explosion}
  }

  MOVE_COVERAGE_III_VISUAL_V051 = {}
  MOVE_COVERAGE_III_AUDIO_V051 = {}
  MOVE_COVERAGE_III_MOVE_V051.each do |k,d|
    p=MOVE_PRESENTATION_V051[k]||{}
    MOVE_COVERAGE_III_VISUAL_V051[k]={:visual_kind=>p[:visual_kind]||d[:visual_kind],:style=>p[:projectile_visual]||d[:visual_style],:hide_logical_projectile=>false,:timing=>p[:timing],:persistent_visual=>p[:persistent_visual]}
    MOVE_COVERAGE_III_AUDIO_V051[k]={:type=>d[:type],:category=>d[:category],:visual_kind=>d[:visual_kind],:audio_style=>d[:visual_style],:cast_cat=>(d[:category]==:status ? :magic_chime : :snap_click),:launch_cat=>([:projectile,:aoe,:beam].include?(d[:delivery]) ? :wind_hiss : nil),:hit_cat=>(d[:category]==:status ? :tone_soft : :impact_mid),:special=>true,:presentation_sfx=>p[:sfx_profile]}
  end
end
