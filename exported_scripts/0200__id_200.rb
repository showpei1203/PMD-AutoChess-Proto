#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Move Runtime Coverage Data v0.49
# 分類：技能資料／效果覆蓋
#
# 【用途／機制】
# 定義 MoveDB、招式 Runtime 行為與 7005/7005 learnset reference 覆蓋。
#
# 【怎麼調整】
# 新增招式效果優先放在資料表與共用 foundation；不要為每招複製一份傷害流程。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_COVERAGE_MANIFEST_V049 / MOVE_COVERAGE_MOVE_V049 / MOVE_COVERAGE_VISUAL_V049 / MOVE_COVERAGE_AUDIO_V049
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Move Runtime Coverage Data v0.49
#    Coverage Expansion I - high-frequency Gen-V learnset foundations
#===============================================================================
module PMD_AC
  MOVE_COVERAGE_MANIFEST_V049 = {
    :schema_version=>"1.0", :content_version=>"0.49.0", :base_version=>"0.48",
    :feature=>"move_runtime_coverage_expansion_i", :new_mapped_move_count=>13,
    :previous_mapped_move_count=>262, :cumulative_mapped_move_count=>275,
    :learnset_reference_total=>7005, :new_reference_covered=>361,
    :cumulative_reference_covered=>4694, :cumulative_coverage_percent=>67.01,
    :foundations=>[:multi_hit,:focus_energy,:rest,:direct_poison,:high_crit],
    :new_move_keys=>[:focus_energy,:slash,:fury_swipes,:rest,:fury_attack,
      :poison_powder,:charm,:razor_leaf,:night_slash,:withdraw,:metal_sound,
      :bug_buzz,:double_slap],
    :ref_counts=>{:focus_energy=>53,:slash=>50,:fury_swipes=>36,:rest=>34,
      :fury_attack=>28,:poison_powder=>27,:charm=>27,:razor_leaf=>25,
      :night_slash=>23,:withdraw=>16,:metal_sound=>14,:bug_buzz=>13,
      :double_slap=>15},
    :runtime_checksum32=>1520796850,
    :next_phase=>"move_runtime_coverage_expansion_ii"
  }

  MOVE_COVERAGE_MOVE_V049 = {
    :focus_energy=>{:name=>"聚氣",:name_en=>"Focus Energy",:type=>:normal,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:contact=>false,:visual_kind=>:self_fx,
      :visual_style=>:normal,:effects=>[{:type=>:focus_energy_v049}],
      :behavior_status=>:implemented_exact_realtime,:source_move_flags=>[:snatch],
      :move_key=>:focus_energy,:canonical_move_key=>:focus_energy,:runtime_skill_key=>"mv_focus_energy",
      :move_type=>:normal,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},

    :slash=>{:name=>"劈開",:name_en=>"Slash",:type=>:normal,:category=>:physical,
      :canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:force_contact_range=>true,
      :contact=>true,:visual_kind=>:contact_hit,:visual_style=>:normal,
      :effects=>[{:type=>:damage,:power=>70,:crit_bonus=>0.075}],
      :behavior_status=>:implemented_exact_project_crit_curve,:source_move_flags=>[:contact,:mirror,:protect],
      :move_key=>:slash,:canonical_move_key=>:slash,:runtime_skill_key=>"mv_slash",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},

    :fury_swipes=>{:name=>"亂抓",:name_en=>"Fury Swipes",:type=>:normal,:category=>:physical,
      :canonical_power=>18,:accuracy=>80,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:force_contact_range=>true,
      :contact=>true,:visual_kind=>:contact_hit,:visual_style=>:normal,:multi_hit_v049=>true,
      :multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>18}],
      :behavior_status=>:implemented_exact_multi_hit,:source_move_flags=>[:contact,:mirror,:protect],
      :move_key=>:fury_swipes,:canonical_move_key=>:fury_swipes,:runtime_skill_key=>"mv_fury_swipes",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},

    :rest=>{:name=>"睡覺",:name_en=>"Rest",:type=>:psychic,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:contact=>false,:visual_kind=>:self_fx,
      :visual_style=>:psychic,:effects=>[{:type=>:rest_v049}],
      :behavior_status=>:implemented_exact_realtime,:source_move_flags=>[:heal,:snatch],
      :move_key=>:rest,:canonical_move_key=>:rest,:runtime_skill_key=>"mv_rest",
      :move_type=>:psychic,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},

    :fury_attack=>{:name=>"亂擊",:name_en=>"Fury Attack",:type=>:normal,:category=>:physical,
      :canonical_power=>15,:accuracy=>85,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:force_contact_range=>true,
      :contact=>true,:visual_kind=>:contact_hit,:visual_style=>:normal,:multi_hit_v049=>true,
      :multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>15}],
      :behavior_status=>:implemented_exact_multi_hit,:source_move_flags=>[:contact,:mirror,:protect],
      :move_key=>:fury_attack,:canonical_move_key=>:fury_attack,:runtime_skill_key=>"mv_fury_attack",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},

    :poison_powder=>{:name=>"毒粉",:name_en=>"Poison Powder",:type=>:poison,:category=>:status,
      :canonical_power=>nil,:accuracy=>75,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:contact=>false,
      :visual_kind=>:projectile,:visual_style=>:poison,:effects=>[{:type=>:direct_poison_v049,
        :duration=>180,:interval=>30,:tick_maxhp_ratio=>0.015}],
      :behavior_status=>:implemented_exact_realtime,:source_move_flags=>[:mirror,:powder,:protect,:reflectable],
      :move_key=>:poison_powder,:canonical_move_key=>:poison_powder,:runtime_skill_key=>"mv_poison_powder",
      :move_type=>:poison,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},

    :charm=>{:name=>"撒嬌",:name_en=>"Charm",:type=>:normal,:category=>:status,
      :canonical_power=>nil,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>230.0,:contact=>false,
      :visual_kind=>:target_hit,:visual_style=>:normal,
      :effects=>[{:type=>:stat_stage,:stat=>:atk,:stages=>-2}],
      :behavior_status=>:implemented_exact,:source_move_flags=>[:mirror,:protect,:reflectable],
      :move_key=>:charm,:canonical_move_key=>:charm,:runtime_skill_key=>"mv_charm",
      :move_type=>:normal,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},

    :razor_leaf=>{:name=>"飛葉快刀",:name_en=>"Razor Leaf",:type=>:grass,:category=>:physical,
      :canonical_power=>55,:accuracy=>95,:priority=>0,:target_type=>:ground_enemy,
      :policy=>:best_cluster,:delivery=>:aoe,:range_px=>260.0,:radius=>999.0,:global_direct=>true,
      :contact=>false,:visual_kind=>:area_hit,:visual_style=>:grass,
      :effects=>[{:type=>:damage,:power=>55,:crit_bonus=>0.075}],
      :behavior_status=>:implemented_exact_project_crit_curve,:source_move_flags=>[:mirror,:protect],
      :move_key=>:razor_leaf,:canonical_move_key=>:razor_leaf,:runtime_skill_key=>"mv_razor_leaf",
      :move_type=>:grass,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},

    :night_slash=>{:name=>"暗襲要害",:name_en=>"Night Slash",:type=>:dark,:category=>:physical,
      :canonical_power=>70,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:force_contact_range=>true,
      :contact=>true,:visual_kind=>:contact_hit,:visual_style=>:dark,
      :effects=>[{:type=>:damage,:power=>70,:crit_bonus=>0.075}],
      :behavior_status=>:implemented_exact_project_crit_curve,:source_move_flags=>[:contact,:mirror,:protect],
      :move_key=>:night_slash,:canonical_move_key=>:night_slash,:runtime_skill_key=>"mv_night_slash",
      :move_type=>:dark,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015},

    :withdraw=>{:name=>"縮入殼中",:name_en=>"Withdraw",:type=>:water,:category=>:status,
      :canonical_power=>nil,:accuracy=>nil,:priority=>0,:target_type=>:self,:policy=>:self,
      :delivery=>:instant,:range_px=>0.0,:contact=>false,:visual_kind=>:self_fx,
      :visual_style=>:water,:effects=>[{:type=>:stat_stage,:stat=>:def,:stages=>1}],
      :behavior_status=>:implemented_exact,:source_move_flags=>[:snatch],
      :move_key=>:withdraw,:canonical_move_key=>:withdraw,:runtime_skill_key=>"mv_withdraw",
      :move_type=>:water,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},

    :metal_sound=>{:name=>"金屬音",:name_en=>"Metal Sound",:type=>:steel,:category=>:status,
      :canonical_power=>nil,:accuracy=>85,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>230.0,:contact=>false,:sound=>true,
      :visual_kind=>:target_hit,:visual_style=>:steel,
      :effects=>[{:type=>:stat_stage,:stat=>:spdef,:stages=>-2}],
      :behavior_status=>:implemented_exact,:source_move_flags=>[:authentic,:mirror,:protect,:reflectable,:sound],
      :move_key=>:metal_sound,:canonical_move_key=>:metal_sound,:runtime_skill_key=>"mv_metal_sound",
      :move_type=>:steel,:damage_category=>:status,:energy_runtime_mode=>:full_bar_v015},

    :bug_buzz=>{:name=>"蟲鳴",:name_en=>"Bug Buzz",:type=>:bug,:category=>:special,
      :canonical_power=>90,:accuracy=>100,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:contact=>false,:sound=>true,
      :visual_kind=>:projectile,:visual_style=>:bug,:effects=>[{:type=>:damage,:power=>90}],
      :secondary_effects=>[{:group=>0,:type=>:stat_stage,:stat=>:spdef,:stages=>-1,:chance=>10,:receiver=>:target}],
      :behavior_status=>:implemented_primary_plus_secondary,:source_move_flags=>[:authentic,:mirror,:protect,:sound],
      :move_key=>:bug_buzz,:canonical_move_key=>:bug_buzz,:runtime_skill_key=>"mv_bug_buzz",
      :move_type=>:bug,:damage_category=>:special,:energy_runtime_mode=>:full_bar_v015},

    :double_slap=>{:name=>"連環巴掌",:name_en=>"Double Slap",:type=>:normal,:category=>:physical,
      :canonical_power=>15,:accuracy=>85,:priority=>0,:target_type=>:enemy_targeted,
      :policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:force_contact_range=>true,
      :contact=>true,:visual_kind=>:contact_hit,:visual_style=>:normal,:multi_hit_v049=>true,
      :multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>15}],
      :behavior_status=>:implemented_exact_multi_hit,:source_move_flags=>[:contact,:mirror,:protect],
      :move_key=>:double_slap,:canonical_move_key=>:double_slap,:runtime_skill_key=>"mv_double_slap",
      :move_type=>:normal,:damage_category=>:physical,:energy_runtime_mode=>:full_bar_v015}
  }

  MOVE_COVERAGE_VISUAL_V049 = {
    :focus_energy=>{:visual_kind=>:self_fx,:style=>:normal},
    :slash=>{:visual_kind=>:contact_hit,:style=>:normal},
    :fury_swipes=>{:visual_kind=>:contact_hit,:style=>:normal},
    :rest=>{:visual_kind=>:self_fx,:style=>:psychic},
    :fury_attack=>{:visual_kind=>:contact_hit,:style=>:normal},
    :poison_powder=>{:visual_kind=>:projectile,:style=>:poison},
    :charm=>{:visual_kind=>:target_hit,:style=>:normal,:hide_logical_projectile=>true},
    :razor_leaf=>{:visual_kind=>:area_hit,:style=>:grass},
    :night_slash=>{:visual_kind=>:contact_hit,:style=>:dark},
    :withdraw=>{:visual_kind=>:self_fx,:style=>:water},
    :metal_sound=>{:visual_kind=>:target_hit,:style=>:steel,:hide_logical_projectile=>true},
    :bug_buzz=>{:visual_kind=>:projectile,:style=>:bug},
    :double_slap=>{:visual_kind=>:contact_hit,:style=>:normal}
  }

  MOVE_COVERAGE_AUDIO_V049 = {}
  MOVE_COVERAGE_MOVE_V049.each do |k,d|
    MOVE_COVERAGE_AUDIO_V049[k]={:type=>d[:type],:category=>d[:category],
      :visual_kind=>d[:visual_kind],:audio_style=>d[:visual_style],
      :cast_cat=>(d[:sound] ? :tone_low_hum : (d[:category]==:status ? :magic_chime : :snap_click)),
      :launch_cat=>(d[:delivery]==:projectile || d[:delivery]==:aoe ? :wind_hiss : nil),
      :hit_cat=>(d[:sound] ? :tone_soft : (d[:category]==:status ? :tone_soft : :impact_mid)),
      :special=>true}
  end
end
