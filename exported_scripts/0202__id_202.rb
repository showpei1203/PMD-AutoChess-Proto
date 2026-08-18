#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Move Runtime Coverage Data v0.50
# 分類：技能資料／效果覆蓋
#
# 【用途／機制】
# 定義 MoveDB、招式 Runtime 行為與 7005/7005 learnset reference 覆蓋。
#
# 【怎麼調整】
# 新增招式效果優先放在資料表與共用 foundation；不要為每招複製一份傷害流程。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_COVERAGE_II_CHECKSUM_TEXT_V050 / MOVE_COVERAGE_II_MANIFEST_V050 / MOVE_COVERAGE_II_MOVE_V050 / MOVE_COVERAGE_II_VISUAL_V050
# - MOVE_COVERAGE_II_AUDIO_V050
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Move Runtime Coverage Data v0.50
#    Coverage Expansion II - reusable status / fixed damage / multi-hit grammar
#===============================================================================
module PMD_AC
  MOVE_COVERAGE_II_CHECKSUM_TEXT_V050 = "taunt|dark|status|None|100|enemy_targeted|instant|:effects=>[{:type=>:taunt,:duration=>120}],:source_move_flags=>[:authentic,:mental,:mirror,:protect,:reflectable];aqua_ring|water|status|None|None|self|instant|:effects=>[{:type=>:aqua_ring_v050,:duration=>240,:interval=>30,:tick_maxhp_ratio=>0.0625}],:source_move_flags=>[:snatch];roost|flying|status|None|None|self|instant|:effects=>[{:type=>:heal_maxhp_ratio,:ratio=>0.5}],:source_move_flags=>[:heal,:snatch];heal_pulse|psychic|status|None|None|ally|projectile|:ally_hp_below=>0.85,:effects=>[{:type=>:heal_maxhp_ratio,:ratio=>0.5}],:source_move_flags=>[:distance,:heal,:protect,:pulse,:reflectable],:pulse=>true;refresh|normal|status|None|None|self|instant|:effects=>[{:type=>:refresh_v050}],:source_move_flags=>[:snatch];splash|normal|status|None|None|self|instant|:effects=>[{:type=>:no_effect_v050}],:source_move_flags=>[:gravity];rock_blast|rock|physical|25|90|enemy_targeted|projectile|:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>25}],:source_move_flags=>[:ballistics,:mirror,:protect];sonic_boom|normal|special|None|90|enemy_targeted|projectile|:effects=>[{:type=>:fixed_damage_v050,:flat=>20}],:source_move_flags=>[:mirror,:protect],:sound=>true;poison_gas|poison|status|None|80|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:direct_poison_v049,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.015}],:source_move_flags=>[:mirror,:protect,:reflectable];memento|dark|status|None|100|enemy_targeted|instant|:effects=>[{:type=>:stat_stage,:stat=>:atk,:stages=>-2},{:type=>:stat_stage,:stat=>:spatk,:stages=>-2},{:type=>:self_faint_v050}],:source_move_flags=>[:mirror,:protect];dragon_rage|dragon|special|None|100|enemy_targeted|projectile|:effects=>[{:type=>:fixed_damage_v050,:flat=>40}],:source_move_flags=>[:mirror,:protect];double_kick|fighting|physical|30|100|enemy_targeted|instant|:force_contact_range=>true,:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>2,:effects=>[{:type=>:damage,:power=>30}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true;minimize|normal|status|None|None|self|instant|:effects=>[{:type=>:stat_stage,:stat=>:evasion,:stages=>2}],:source_move_flags=>[:snatch];cosmic_power|psychic|status|None|None|self|instant|:effects=>[{:type=>:stat_stage,:stat=>:def,:stages=>1},{:type=>:stat_stage,:stat=>:spdef,:stages=>1}],:source_move_flags=>[:snatch];seismic_toss|fighting|physical|None|100|enemy_targeted|instant|:force_contact_range=>true,:effects=>[{:type=>:fixed_damage_v050,:level_based=>true}],:source_move_flags=>[:contact,:mirror,:non_sky_battle,:protect],:contact=>true;double_hit|normal|physical|35|90|enemy_targeted|instant|:force_contact_range=>true,:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>2,:effects=>[{:type=>:damage,:power=>35}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true;fake_tears|dark|status|None|100|enemy_targeted|instant|:effects=>[{:type=>:stat_stage,:stat=>:spdef,:stages=>-2}],:source_move_flags=>[:mirror,:protect,:reflectable];bulldoze|ground|physical|60|100|ground_enemy|aoe|:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>60},{:type=>:stat_stage,:stat=>:speed,:stages=>-1}],:source_move_flags=>[:mirror,:non_sky_battle,:protect];bullet_seed|grass|physical|25|100|enemy_targeted|projectile|:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>25}],:source_move_flags=>[:ballistics,:mirror,:protect];will_o_wisp|fire|status|None|75|enemy_targeted|projectile|:effects=>[{:type=>:direct_burn_v050,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:source_move_flags=>[:mirror,:protect,:reflectable];leaf_blade|grass|physical|90|100|enemy_targeted|instant|:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>90,:crit_bonus=>0.075}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true;cross_poison|poison|physical|70|100|enemy_targeted|instant|:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>70,:crit_bonus=>0.075}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:poison,:chance=>10,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.015}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true;psycho_cut|psychic|physical|70|100|enemy_targeted|projectile|:effects=>[{:type=>:damage,:power=>70,:crit_bonus=>0.075}],:source_move_flags=>[:mirror,:protect];flare_blitz|fire|physical|120|100|enemy_targeted|instant|:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>120},{:type=>:recoil_last_damage,:ratio=>0.33}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:burn,:chance=>10,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:source_move_flags=>[:contact,:defrost,:mirror,:protect],:contact=>true"
  MOVE_COVERAGE_II_MANIFEST_V050 = {
    :schema_version=>"1.0", :content_version=>"0.50.0", :base_version=>"0.49",
    :feature=>"move_runtime_coverage_expansion_ii", :new_mapped_move_count=>24,
    :previous_mapped_move_count=>275, :cumulative_mapped_move_count=>299,
    :learnset_reference_total=>7005, :new_reference_covered=>261,
    :cumulative_reference_covered=>4955, :cumulative_coverage_percent=>70.74,
    :foundations=>[:fixed_damage,:direct_burn,:aqua_ring,:refresh,:self_faint,:reuse_multi_hit,:reuse_high_crit],
    :new_move_keys=>[:taunt,:aqua_ring,:roost,:heal_pulse,:refresh,:splash,:rock_blast,:sonic_boom,:poison_gas,:memento,:dragon_rage,:double_kick,:minimize,:cosmic_power,:seismic_toss,:double_hit,:fake_tears,:bulldoze,:bullet_seed,:will_o_wisp,:leaf_blade,:cross_poison,:psycho_cut,:flare_blitz],
    :ref_counts=>{:taunt=>23,:aqua_ring=>20,:roost=>15,:heal_pulse=>13,:refresh=>13,:splash=>13,:rock_blast=>12,:sonic_boom=>12,:poison_gas=>12,:memento=>12,:dragon_rage=>11,:double_kick=>10,:minimize=>10,:cosmic_power=>9,:seismic_toss=>9,:double_hit=>9,:fake_tears=>9,:bulldoze=>8,:bullet_seed=>8,:will_o_wisp=>6,:leaf_blade=>6,:cross_poison=>6,:psycho_cut=>6,:flare_blitz=>9},
    :runtime_checksum32=>1639756694, :next_phase=>"move_runtime_coverage_expansion_iii"
  }

  MOVE_COVERAGE_II_MOVE_V050 = {
    :taunt=>{:name=>"挑釁",:name_en=>"Taunt",:type=>:dark,:category=>:status,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>230.0,:visual_kind=>:target_hit,:visual_style=>:dark,
      :effects=>[{:type=>:taunt,:duration=>120}],:source_move_flags=>[:authentic,:mental,:mirror,:protect,:reflectable],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:taunt,:canonical_move_key=>:taunt,:runtime_skill_key=>"mv_taunt",
      :move_type=>:dark,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :aqua_ring=>{:name=>"水流環",:name_en=>"Aqua Ring",:type=>:water,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:water,
      :effects=>[{:type=>:aqua_ring_v050,:duration=>240,:interval=>30,:tick_maxhp_ratio=>0.0625}],:source_move_flags=>[:snatch],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:aqua_ring,:canonical_move_key=>:aqua_ring,:runtime_skill_key=>"mv_aqua_ring",
      :move_type=>:water,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :roost=>{:name=>"羽棲",:name_en=>"Roost",:type=>:flying,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:flying,
      :effects=>[{:type=>:heal_maxhp_ratio,:ratio=>0.5}],:source_move_flags=>[:heal,:snatch],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:roost,:canonical_move_key=>:roost,:runtime_skill_key=>"mv_roost",
      :move_type=>:flying,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :heal_pulse=>{:name=>"治癒波動",:name_en=>"Heal Pulse",:type=>:psychic,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:ally,:policy=>:lowest_ally,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:psychic,
      :ally_hp_below=>0.85,:effects=>[{:type=>:heal_maxhp_ratio,:ratio=>0.5}],:source_move_flags=>[:distance,:heal,:protect,:pulse,:reflectable],:pulse=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:heal_pulse,:canonical_move_key=>:heal_pulse,:runtime_skill_key=>"mv_heal_pulse",
      :move_type=>:psychic,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :refresh=>{:name=>"煥然一新",:name_en=>"Refresh",:type=>:normal,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:normal,
      :effects=>[{:type=>:refresh_v050}],:source_move_flags=>[:snatch],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:refresh,:canonical_move_key=>:refresh,:runtime_skill_key=>"mv_refresh",
      :move_type=>:normal,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :splash=>{:name=>"躍起",:name_en=>"Splash",:type=>:normal,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:normal,
      :effects=>[{:type=>:no_effect_v050}],:source_move_flags=>[:gravity],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:splash,:canonical_move_key=>:splash,:runtime_skill_key=>"mv_splash",
      :move_type=>:normal,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :rock_blast=>{:name=>"岩石爆擊",:name_en=>"Rock Blast",:type=>:rock,:category=>:physical,
      :canonical_power=>25,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:rock,
      :multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>25}],:source_move_flags=>[:ballistics,:mirror,:protect],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:rock_blast,:canonical_move_key=>:rock_blast,:runtime_skill_key=>"mv_rock_blast",
      :move_type=>:rock,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :sonic_boom=>{:name=>"音爆",:name_en=>"Sonic Boom",:type=>:normal,:category=>:special,
      :canonical_power=>nil,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:normal,
      :effects=>[{:type=>:fixed_damage_v050,:flat=>20}],:source_move_flags=>[:mirror,:protect],:sound=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:sonic_boom,:canonical_move_key=>:sonic_boom,:runtime_skill_key=>"mv_sonic_boom",
      :move_type=>:normal,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :poison_gas=>{:name=>"毒瓦斯",:name_en=>"Poison Gas",:type=>:poison,:category=>:status,
      :canonical_power=>nil,:accuracy=>80,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:poison,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:direct_poison_v049,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.015}],:source_move_flags=>[:mirror,:protect,:reflectable],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:poison_gas,:canonical_move_key=>:poison_gas,:runtime_skill_key=>"mv_poison_gas",
      :move_type=>:poison,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :memento=>{:name=>"臨別禮物",:name_en=>"Memento",:type=>:dark,:category=>:status,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>230.0,:visual_kind=>:target_hit,:visual_style=>:dark,
      :effects=>[{:type=>:stat_stage,:stat=>:atk,:stages=>-2},{:type=>:stat_stage,:stat=>:spatk,:stages=>-2},{:type=>:self_faint_v050}],:source_move_flags=>[:mirror,:protect],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:memento,:canonical_move_key=>:memento,:runtime_skill_key=>"mv_memento",
      :move_type=>:dark,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :dragon_rage=>{:name=>"龍之怒",:name_en=>"Dragon Rage",:type=>:dragon,:category=>:special,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:dragon,
      :effects=>[{:type=>:fixed_damage_v050,:flat=>40}],:source_move_flags=>[:mirror,:protect],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:dragon_rage,:canonical_move_key=>:dragon_rage,:runtime_skill_key=>"mv_dragon_rage",
      :move_type=>:dragon,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},
    :double_kick=>{:name=>"二連踢",:name_en=>"Double Kick",:type=>:fighting,:category=>:physical,
      :canonical_power=>30,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fighting,
      :force_contact_range=>true,:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>2,:effects=>[{:type=>:damage,:power=>30}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:double_kick,:canonical_move_key=>:double_kick,:runtime_skill_key=>"mv_double_kick",
      :move_type=>:fighting,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :minimize=>{:name=>"變小",:name_en=>"Minimize",:type=>:normal,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:normal,
      :effects=>[{:type=>:stat_stage,:stat=>:evasion,:stages=>2}],:source_move_flags=>[:snatch],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:minimize,:canonical_move_key=>:minimize,:runtime_skill_key=>"mv_minimize",
      :move_type=>:normal,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :cosmic_power=>{:name=>"宇宙力量",:name_en=>"Cosmic Power",:type=>:psychic,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:psychic,
      :effects=>[{:type=>:stat_stage,:stat=>:def,:stages=>1},{:type=>:stat_stage,:stat=>:spdef,:stages=>1}],:source_move_flags=>[:snatch],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:cosmic_power,:canonical_move_key=>:cosmic_power,:runtime_skill_key=>"mv_cosmic_power",
      :move_type=>:psychic,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :seismic_toss=>{:name=>"地球上投",:name_en=>"Seismic Toss",:type=>:fighting,:category=>:physical,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fighting,
      :force_contact_range=>true,:effects=>[{:type=>:fixed_damage_v050,:level_based=>true}],:source_move_flags=>[:contact,:mirror,:non_sky_battle,:protect],:contact=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:seismic_toss,:canonical_move_key=>:seismic_toss,:runtime_skill_key=>"mv_seismic_toss",
      :move_type=>:fighting,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :double_hit=>{:name=>"二連擊",:name_en=>"Double Hit",:type=>:normal,:category=>:physical,
      :canonical_power=>35,:accuracy=>90,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,
      :force_contact_range=>true,:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>2,:effects=>[{:type=>:damage,:power=>35}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:double_hit,:canonical_move_key=>:double_hit,:runtime_skill_key=>"mv_double_hit",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :fake_tears=>{:name=>"假哭",:name_en=>"Fake Tears",:type=>:dark,:category=>:status,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>230.0,:visual_kind=>:target_hit,:visual_style=>:dark,
      :effects=>[{:type=>:stat_stage,:stat=>:spdef,:stages=>-2}],:source_move_flags=>[:mirror,:protect,:reflectable],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:fake_tears,:canonical_move_key=>:fake_tears,:runtime_skill_key=>"mv_fake_tears",
      :move_type=>:dark,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :bulldoze=>{:name=>"重踏",:name_en=>"Bulldoze",:type=>:ground,:category=>:physical,
      :canonical_power=>60,:accuracy=>100,:priority=>0,:target_type=>:ground_enemy,:policy=>:best_cluster,
      :delivery=>:aoe,:range_px=>230.0,:visual_kind=>:area_hit,:visual_style=>:ground,
      :radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>60},{:type=>:stat_stage,:stat=>:speed,:stages=>-1}],:source_move_flags=>[:mirror,:non_sky_battle,:protect],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:bulldoze,:canonical_move_key=>:bulldoze,:runtime_skill_key=>"mv_bulldoze",
      :move_type=>:ground,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :bullet_seed=>{:name=>"種子機關槍",:name_en=>"Bullet Seed",:type=>:grass,:category=>:physical,
      :canonical_power=>25,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:grass,
      :multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>25}],:source_move_flags=>[:ballistics,:mirror,:protect],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:bullet_seed,:canonical_move_key=>:bullet_seed,:runtime_skill_key=>"mv_bullet_seed",
      :move_type=>:grass,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :will_o_wisp=>{:name=>"鬼火",:name_en=>"Will-O-Wisp",:type=>:fire,:category=>:status,
      :canonical_power=>nil,:accuracy=>75,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:fire,
      :effects=>[{:type=>:direct_burn_v050,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:source_move_flags=>[:mirror,:protect,:reflectable],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:will_o_wisp,:canonical_move_key=>:will_o_wisp,:runtime_skill_key=>"mv_will_o_wisp",
      :move_type=>:fire,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},
    :leaf_blade=>{:name=>"葉刃",:name_en=>"Leaf Blade",:type=>:grass,:category=>:physical,
      :canonical_power=>90,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:grass,
      :force_contact_range=>true,:effects=>[{:type=>:damage,:power=>90,:crit_bonus=>0.075}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:leaf_blade,:canonical_move_key=>:leaf_blade,:runtime_skill_key=>"mv_leaf_blade",
      :move_type=>:grass,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :cross_poison=>{:name=>"十字毒刃",:name_en=>"Cross Poison",:type=>:poison,:category=>:physical,
      :canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:poison,
      :force_contact_range=>true,:effects=>[{:type=>:damage,:power=>70,:crit_bonus=>0.075}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:poison,:chance=>10,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.015}],:source_move_flags=>[:contact,:mirror,:protect],:contact=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:cross_poison,:canonical_move_key=>:cross_poison,:runtime_skill_key=>"mv_cross_poison",
      :move_type=>:poison,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :psycho_cut=>{:name=>"精神利刃",:name_en=>"Psycho Cut",:type=>:psychic,:category=>:physical,
      :canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:psychic,
      :effects=>[{:type=>:damage,:power=>70,:crit_bonus=>0.075}],:source_move_flags=>[:mirror,:protect],:behavior_status=>:implemented_coverage_v050,
      :move_key=>:psycho_cut,:canonical_move_key=>:psycho_cut,:runtime_skill_key=>"mv_psycho_cut",
      :move_type=>:psychic,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},
    :flare_blitz=>{:name=>"閃焰衝鋒",:name_en=>"Flare Blitz",:type=>:fire,:category=>:physical,
      :canonical_power=>120,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,:policy=>:current_target,
      :delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fire,
      :force_contact_range=>true,:effects=>[{:type=>:damage,:power=>120},{:type=>:recoil_last_damage,:ratio=>0.33}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:burn,:chance=>10,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:source_move_flags=>[:contact,:defrost,:mirror,:protect],:contact=>true,:behavior_status=>:implemented_coverage_v050,
      :move_key=>:flare_blitz,:canonical_move_key=>:flare_blitz,:runtime_skill_key=>"mv_flare_blitz",
      :move_type=>:fire,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015}
  }

  MOVE_COVERAGE_II_VISUAL_V050 = {}
  MOVE_COVERAGE_II_AUDIO_V050 = {}
  MOVE_COVERAGE_II_MOVE_V050.each do |k,d|
    MOVE_COVERAGE_II_VISUAL_V050[k]={:visual_kind=>d[:visual_kind],:style=>d[:visual_style],:hide_logical_projectile=>(d[:delivery]==:instant && d[:target_type]!=:self && d[:category]==:status)}
    MOVE_COVERAGE_II_AUDIO_V050[k]={:type=>d[:type],:category=>d[:category],:visual_kind=>d[:visual_kind],:audio_style=>d[:visual_style],
      :cast_cat=>(d[:category]==:status ? :magic_chime : :snap_click),
      :launch_cat=>([:projectile,:aoe].include?(d[:delivery]) ? :wind_hiss : nil),
      :hit_cat=>(d[:category]==:status ? :tone_soft : :impact_mid),:special=>true}
  end
end
