#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Priority Data v0.42
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
# - PRIORITY_MANIFEST_V042 / PRIORITY_MOVE_V042 / PRIORITY_VISUAL_V042 / PRIORITY_AUDIO_V042
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.42 Priority Runtime Data
module PMD_AC
  PRIORITY_MANIFEST_V042 = {
    :schema_version=>"1.0",
    :content_version=>"0.42.0",
    :base_version=>"0.41.1",
    :feature=>"priority_runtime_i",
    :new_mapped_move_count=>8,
    :previous_mapped_move_count=>243,
    :cumulative_mapped_move_count=>251,
    :learnset_reference_total=>7005,
    :new_reference_covered=>133,
    :cumulative_reference_covered=>4210,
    :cumulative_coverage_percent=>60.10,
    :priority_move_count=>8,
    :startup_frames=>{5=>1,4=>2,3=>3,2=>4,1=>6,-1=>18,-2=>19,-3=>20,-4=>21,-5=>22,-6=>23,-7=>24},
    :timing_model=>"startup_shift_recovery_preserved",
    :total_action_duration_unchanged=>true,
    :positive_priority_quick_guard_integrated=>true,
    :existing_guard_priority_integrated=>true,
    :existing_room_negative_priority_integrated=>true,
    :same_priority_tiebreak=>"existing_realtime_state_then_instance_order",
    :new_move_keys=>["quick_attack","mach_punch","extreme_speed","vacuum_wave","bullet_punch","ice_shard","shadow_sneak","aqua_jet"],
    :ref_counts=>{"quick_attack"=>82,"mach_punch"=>6,"extreme_speed"=>5,"vacuum_wave"=>2,"bullet_punch"=>4,"ice_shard"=>12,"shadow_sneak"=>12,"aqua_jet"=>10},
    :runtime_checksum32=>1634732235,
  }
  PRIORITY_MOVE_V042 = {
    :quick_attack=>{"name"=>"電光一閃","name_en"=>"Quick Attack","type"=>:normal,"category"=>:physical,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:instant,"range_px"=>52.00,"force_contact_range"=>true,"contact"=>true,"visual_kind"=>:contact_hit,"visual_style"=>:normal,"cast_cat"=>nil,"launch_cat"=>nil,"hit_cat"=>:impact_mid,"move_key"=>"quick_attack","canonical_move_key"=>"quick_attack","runtime_skill_key"=>"mv_quick_attack","canonical_power"=>40,"move_type"=>:normal,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>["contact",:mirror,:protect]},
    :mach_punch=>{"name"=>"音速拳","name_en"=>"Mach Punch","type"=>:fighting,"category"=>:physical,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:instant,"range_px"=>52.00,"force_contact_range"=>true,"contact"=>true,"visual_kind"=>:contact_hit,"visual_style"=>:fighting,"cast_cat"=>nil,"launch_cat"=>nil,"hit_cat"=>:impact_heavy,"move_key"=>"mach_punch","canonical_move_key"=>"mach_punch","runtime_skill_key"=>"mv_mach_punch","canonical_power"=>40,"move_type"=>:fighting,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>["contact",:mirror,:protect,:punch]},
    :extreme_speed=>{"name"=>"神速","name_en"=>"Extreme Speed","type"=>:normal,"category"=>:physical,"power"=>80,"accuracy"=>100,"priority"=>2,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:instant,"range_px"=>52.00,"force_contact_range"=>true,"contact"=>true,"visual_kind"=>:contact_hit,"visual_style"=>:normal,"cast_cat"=>:wind_whoosh,"launch_cat"=>nil,"hit_cat"=>:impact_heavy,"move_key"=>"extreme_speed","canonical_move_key"=>"extreme_speed","runtime_skill_key"=>"mv_extreme_speed","canonical_power"=>80,"move_type"=>:normal,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>80}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>["contact",:mirror,:protect]},
    :vacuum_wave=>{"name"=>"真空波","name_en"=>"Vacuum Wave","type"=>:fighting,"category"=>:special,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:projectile,"range_px"=>230.00,"projectile_tracking"=>:strong,"contact"=>false,"visual_kind"=>:projectile,"visual_style"=>:fighting,"cast_cat"=>:low_thump,"launch_cat"=>:wind_whoosh,"hit_cat"=>:impact_heavy,"move_key"=>"vacuum_wave","canonical_move_key"=>"vacuum_wave","runtime_skill_key"=>"mv_vacuum_wave","canonical_power"=>40,"move_type"=>:fighting,"damage_category"=>:special,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>[:mirror,:protect]},
    :bullet_punch=>{"name"=>"子彈拳","name_en"=>"Bullet Punch","type"=>:steel,"category"=>:physical,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:instant,"range_px"=>52.00,"force_contact_range"=>true,"contact"=>true,"visual_kind"=>:contact_hit,"visual_style"=>:steel,"cast_cat"=>nil,"launch_cat"=>nil,"hit_cat"=>:impact_sharp,"move_key"=>"bullet_punch","canonical_move_key"=>"bullet_punch","runtime_skill_key"=>"mv_bullet_punch","canonical_power"=>40,"move_type"=>:steel,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>["contact",:mirror,:protect,:punch]},
    :ice_shard=>{"name"=>"冰礫","name_en"=>"Ice Shard","type"=>:ice,"category"=>:physical,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:projectile,"range_px"=>230.00,"projectile_tracking"=>:strong,"contact"=>false,"visual_kind"=>:projectile,"visual_style"=>:ice,"cast_cat"=>:magic_chime,"launch_cat"=>:wind_hiss,"hit_cat"=>:impact_sharp,"move_key"=>"ice_shard","canonical_move_key"=>"ice_shard","runtime_skill_key"=>"mv_ice_shard","canonical_power"=>40,"move_type"=>:ice,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>[:mirror,:protect]},
    :shadow_sneak=>{"name"=>"影子偷襲","name_en"=>"Shadow Sneak","type"=>:ghost,"category"=>:physical,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:instant,"range_px"=>52.00,"force_contact_range"=>true,"contact"=>true,"visual_kind"=>:contact_hit,"visual_style"=>:ghost,"cast_cat"=>:tone_low_hum,"launch_cat"=>nil,"hit_cat"=>:impact_burst,"move_key"=>"shadow_sneak","canonical_move_key"=>"shadow_sneak","runtime_skill_key"=>"mv_shadow_sneak","canonical_power"=>40,"move_type"=>:ghost,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>["contact",:mirror,:protect]},
    :aqua_jet=>{"name"=>"水流噴射","name_en"=>"Aqua Jet","type"=>:water,"category"=>:physical,"power"=>40,"accuracy"=>100,"priority"=>1,"target_type"=>:enemy_targeted,"policy"=>:current_target,"delivery"=>:instant,"range_px"=>52.00,"force_contact_range"=>true,"contact"=>true,"visual_kind"=>:contact_hit,"visual_style"=>:water,"cast_cat"=>:ambient_stream,"launch_cat"=>nil,"hit_cat"=>:water_splash,"move_key"=>"aqua_jet","canonical_move_key"=>"aqua_jet","runtime_skill_key"=>"mv_aqua_jet","canonical_power"=>40,"move_type"=>:water,"damage_category"=>:physical,"effects"=>[{"type"=>:damage,"power"=>40}],"behavior_status"=>:implemented_priority_v042,"energy_runtime_mode"=>:full_bar_v015,"source_move_flags"=>["contact",:mirror,:protect]},
  }
  PRIORITY_VISUAL_V042 = {
    :quick_attack=>{"visual_kind"=>:contact_hit,"style"=>:normal},
    :mach_punch=>{"visual_kind"=>:contact_hit,"style"=>:fighting},
    :extreme_speed=>{"visual_kind"=>:contact_hit,"style"=>:normal},
    :vacuum_wave=>{"visual_kind"=>:projectile,"style"=>:fighting},
    :bullet_punch=>{"visual_kind"=>:contact_hit,"style"=>:steel},
    :ice_shard=>{"visual_kind"=>:projectile,"style"=>:ice},
    :shadow_sneak=>{"visual_kind"=>:contact_hit,"style"=>:ghost},
    :aqua_jet=>{"visual_kind"=>:contact_hit,"style"=>:water},
  }
  PRIORITY_AUDIO_V042 = {
    :quick_attack=>{"type"=>:normal,"category"=>:physical,"visual_kind"=>:contact_hit,"audio_style"=>:normal,"cast_cat"=>nil,"launch_cat"=>nil,"hit_cat"=>:impact_mid,:special=>true},
    :mach_punch=>{"type"=>:fighting,"category"=>:physical,"visual_kind"=>:contact_hit,"audio_style"=>:fighting,"cast_cat"=>nil,"launch_cat"=>nil,"hit_cat"=>:impact_heavy,:special=>true},
    :extreme_speed=>{"type"=>:normal,"category"=>:physical,"visual_kind"=>:contact_hit,"audio_style"=>:normal,"cast_cat"=>:wind_whoosh,"launch_cat"=>nil,"hit_cat"=>:impact_heavy,:special=>true},
    :vacuum_wave=>{"type"=>:fighting,"category"=>:special,"visual_kind"=>:projectile,"audio_style"=>:fighting,"cast_cat"=>:low_thump,"launch_cat"=>:wind_whoosh,"hit_cat"=>:impact_heavy,:special=>true},
    :bullet_punch=>{"type"=>:steel,"category"=>:physical,"visual_kind"=>:contact_hit,"audio_style"=>:steel,"cast_cat"=>nil,"launch_cat"=>nil,"hit_cat"=>:impact_sharp,:special=>true},
    :ice_shard=>{"type"=>:ice,"category"=>:physical,"visual_kind"=>:projectile,"audio_style"=>:ice,"cast_cat"=>:magic_chime,"launch_cat"=>:wind_hiss,"hit_cat"=>:impact_sharp,:special=>true},
    :shadow_sneak=>{"type"=>:ghost,"category"=>:physical,"visual_kind"=>:contact_hit,"audio_style"=>:ghost,"cast_cat"=>:tone_low_hum,"launch_cat"=>nil,"hit_cat"=>:impact_burst,:special=>true},
    :aqua_jet=>{"type"=>:water,"category"=>:physical,"visual_kind"=>:contact_hit,"audio_style"=>:water,"cast_cat"=>:ambient_stream,"launch_cat"=>nil,"hit_cat"=>:water_splash,:special=>true},
  }
end
