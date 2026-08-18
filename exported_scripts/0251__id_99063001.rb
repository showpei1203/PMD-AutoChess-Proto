#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Native Semantic Audit Data v0.63
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - NATIVE_SEMANTIC_AUDIT_VERSION_V063 / NATIVE_SEMANTIC_AUDIT_SCOPE_V063 / NATIVE_SEMANTIC_AUDIT_EXPECTED_V063 / NATIVE_SEMANTIC_CLASS_POSES_V063
# - NATIVE_SEMANTIC_CLASS_MAP_V063 / NATIVE_SEMANTIC_CLASS_STATS_V063
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Native Semantic Audit Data v0.63
# Diagnostic classification for all 526 executable runtime moves.
# This data does NOT replace the v0.62 runtime pose router.
#==============================================================================
module PMD_AC
  NATIVE_SEMANTIC_AUDIT_VERSION_V063 = "0.63"
  NATIVE_SEMANTIC_AUDIT_SCOPE_V063 = {:executable_moves=>526,:learnset_refs=>7005,:router=>:v062_unchanged,:combo_packet_driver=>:v0602_backstep}
  NATIVE_SEMANTIC_AUDIT_EXPECTED_V063 = {:classes=>30,:native=>2327,:alias=>384,:fallback=>4294}
  NATIVE_SEMANTIC_CLASS_POSES_V063 = {
    :appeal=>[:appeal, :pose, :shake],
    :bite=>[:bite],
    :charge_dash=>[:quick_strike, :leap_forth],
    :chop=>[:chop, :slice, :swing],
    :dance=>[:dance, :shake, :pose],
    :field=>[:look_up, :pose, :emit],
    :flap=>[:flap_around, :hover, :leap_forth],
    :gas=>[:gas, :emit],
    :generic_contact=>[],
    :head=>[:head, :rear_up],
    :heal=>[:deep_breath, :pose],
    :jab=>[:jab, :head],
    :jump=>[:leap_forth, :hop],
    :kick=>[:kick, :stomp],
    :lick=>[:lick],
    :punch=>[:uppercut, :punch, :jab, :chop],
    :quick=>[:quick_strike],
    :ranged=>[:sp_attack, :emit],
    :scratch=>[:scratch],
    :self_support=>[:swell, :pose, :shake, :deep_breath],
    :slap=>[:slap, :punch],
    :slice=>[:slice, :swing],
    :sound=>[:sound, :sing, :rear_up, :rumble],
    :spin=>[:rotate, :twirl],
    :stomp=>[:stomp, :slam],
    :swell=>[:swell, :pose, :shake],
    :tail=>[:tail_whip, :slam, :swing],
    :target_support=>[:appeal, :emit, :sp_attack],
    :throw=>[:swing],
    :withdraw=>[:withdraw, :swell],
  }
  NATIVE_SEMANTIC_CLASS_MAP_V063 = {
    :pound=>:generic_contact,:karate_chop=>:chop,:double_slap=>:slap,:comet_punch=>:punch,:mega_punch=>:punch,:pay_day=>:ranged,:fire_punch=>:punch,:ice_punch=>:punch,
    :thunder_punch=>:punch,:scratch=>:scratch,:vice_grip=>:generic_contact,:guillotine=>:generic_contact,:razor_wind=>:ranged,:swords_dance=>:dance,:gust=>:flap,:wing_attack=>:flap,
    :whirlwind=>:target_support,:fly=>:jump,:bind=>:generic_contact,:slam=>:stomp,:vine_whip=>:generic_contact,:stomp=>:stomp,:double_kick=>:kick,:mega_kick=>:kick,
    :jump_kick=>:kick,:rolling_kick=>:kick,:sand_attack=>:target_support,:headbutt=>:head,:horn_attack=>:jab,:fury_attack=>:jab,:horn_drill=>:jab,:tackle=>:charge_dash,
    :body_slam=>:stomp,:wrap=>:generic_contact,:take_down=>:charge_dash,:thrash=>:generic_contact,:double_edge=>:charge_dash,:tail_whip=>:tail,:poison_sting=>:ranged,:twineedle=>:ranged,
    :pin_missile=>:ranged,:leer=>:target_support,:bite=>:bite,:growl=>:sound,:roar=>:sound,:sing=>:sound,:supersonic=>:sound,:sonic_boom=>:ranged,
    :disable=>:target_support,:acid=>:ranged,:ember=>:ranged,:flamethrower=>:ranged,:mist=>:field,:water_gun=>:ranged,:hydro_pump=>:ranged,:ice_beam=>:ranged,
    :blizzard=>:ranged,:psybeam=>:ranged,:bubble_beam=>:ranged,:aurora_beam=>:ranged,:hyper_beam=>:ranged,:peck=>:jab,:drill_peck=>:jab,:submission=>:generic_contact,
    :low_kick=>:kick,:counter=>:generic_contact,:seismic_toss=>:throw,:absorb=>:ranged,:mega_drain=>:ranged,:leech_seed=>:target_support,:growth=>:swell,:razor_leaf=>:ranged,
    :solar_beam=>:ranged,:poison_powder=>:target_support,:stun_spore=>:target_support,:sleep_powder=>:target_support,:petal_dance=>:dance,:string_shot=>:target_support,:dragon_rage=>:ranged,:fire_spin=>:spin,
    :thunder_shock=>:ranged,:thunderbolt=>:ranged,:thunder_wave=>:target_support,:thunder=>:ranged,:rock_throw=>:throw,:earthquake=>:ranged,:fissure=>:ranged,:dig=>:generic_contact,
    :toxic=>:target_support,:confusion=>:ranged,:psychic=>:ranged,:hypnosis=>:target_support,:meditate=>:swell,:agility=>:self_support,:quick_attack=>:quick,:rage=>:generic_contact,
    :teleport=>:self_support,:night_shade=>:ranged,:mimic=>:target_support,:screech=>:sound,:double_team=>:self_support,:recover=>:heal,:harden=>:swell,:minimize=>:self_support,
    :smokescreen=>:gas,:confuse_ray=>:target_support,:withdraw=>:withdraw,:defense_curl=>:swell,:barrier=>:swell,:light_screen=>:field,:haze=>:field,:reflect=>:field,
    :focus_energy=>:self_support,:bide=>:generic_contact,:metronome=>:self_support,:mirror_move=>:target_support,:self_destruct=>:ranged,:egg_bomb=>:ranged,:lick=>:lick,:smog=>:gas,
    :sludge=>:ranged,:bone_club=>:ranged,:fire_blast=>:ranged,:waterfall=>:generic_contact,:clamp=>:generic_contact,:swift=>:ranged,:skull_bash=>:head,:spike_cannon=>:ranged,
    :constrict=>:generic_contact,:amnesia=>:swell,:kinesis=>:target_support,:soft_boiled=>:heal,:high_jump_kick=>:kick,:glare=>:target_support,:dream_eater=>:ranged,:poison_gas=>:gas,
    :barrage=>:ranged,:leech_life=>:generic_contact,:lovely_kiss=>:target_support,:sky_attack=>:ranged,:transform=>:target_support,:bubble=>:ranged,:dizzy_punch=>:punch,:spore=>:target_support,
    :flash=>:target_support,:psywave=>:ranged,:splash=>:self_support,:acid_armor=>:self_support,:crabhammer=>:generic_contact,:explosion=>:ranged,:fury_swipes=>:scratch,:bonemerang=>:ranged,
    :rest=>:heal,:rock_slide=>:ranged,:hyper_fang=>:bite,:sharpen=>:swell,:conversion=>:self_support,:tri_attack=>:ranged,:super_fang=>:bite,:slash=>:slice,
    :substitute=>:self_support,:sketch=>:target_support,:triple_kick=>:kick,:thief=>:generic_contact,:spider_web=>:target_support,:mind_reader=>:target_support,:nightmare=>:target_support,:flame_wheel=>:spin,
    :snore=>:sound,:curse=>:target_support,:flail=>:generic_contact,:conversion_2=>:target_support,:aeroblast=>:ranged,:cotton_spore=>:target_support,:reversal=>:generic_contact,:spite=>:target_support,
    :powder_snow=>:ranged,:protect=>:self_support,:mach_punch=>:punch,:scary_face=>:appeal,:feint_attack=>:generic_contact,:sweet_kiss=>:appeal,:belly_drum=>:swell,:sludge_bomb=>:ranged,
    :mud_slap=>:slap,:octazooka=>:ranged,:spikes=>:field,:zap_cannon=>:ranged,:foresight=>:target_support,:destiny_bond=>:self_support,:perish_song=>:sound,:icy_wind=>:ranged,
    :detect=>:self_support,:bone_rush=>:ranged,:lock_on=>:target_support,:outrage=>:generic_contact,:sandstorm=>:field,:giga_drain=>:ranged,:endure=>:self_support,:charm=>:appeal,
    :rollout=>:spin,:false_swipe=>:slice,:swagger=>:appeal,:milk_drink=>:heal,:spark=>:generic_contact,:fury_cutter=>:slice,:steel_wing=>:generic_contact,:mean_look=>:target_support,
    :attract=>:appeal,:sleep_talk=>:self_support,:heal_bell=>:sound,:return=>:generic_contact,:present=>:ranged,:frustration=>:generic_contact,:safeguard=>:field,:pain_split=>:target_support,
    :sacred_fire=>:ranged,:magnitude=>:ranged,:dynamic_punch=>:punch,:megahorn=>:jab,:dragon_breath=>:ranged,:baton_pass=>:self_support,:encore=>:appeal,:pursuit=>:quick,
    :rapid_spin=>:spin,:sweet_scent=>:target_support,:iron_tail=>:tail,:metal_claw=>:scratch,:vital_throw=>:throw,:morning_sun=>:heal,:synthesis=>:heal,:moonlight=>:heal,
    :hidden_power=>:ranged,:cross_chop=>:chop,:twister=>:ranged,:rain_dance=>:dance,:sunny_day=>:field,:crunch=>:bite,:mirror_coat=>:ranged,:psych_up=>:target_support,
    :extreme_speed=>:quick,:ancient_power=>:ranged,:shadow_ball=>:ranged,:future_sight=>:ranged,:rock_smash=>:generic_contact,:whirlpool=>:ranged,:beat_up=>:ranged,:fake_out=>:quick,
    :uproar=>:sound,:stockpile=>:swell,:spit_up=>:ranged,:swallow=>:heal,:heat_wave=>:ranged,:hail=>:field,:torment=>:appeal,:flatter=>:appeal,
    :will_o_wisp=>:target_support,:memento=>:target_support,:facade=>:generic_contact,:focus_punch=>:punch,:smelling_salts=>:generic_contact,:follow_me=>:self_support,:nature_power=>:target_support,:charge=>:self_support,
    :taunt=>:appeal,:helping_hand=>:target_support,:trick=>:target_support,:role_play=>:target_support,:wish=>:heal,:assist=>:self_support,:ingrain=>:heal,:superpower=>:generic_contact,
    :magic_coat=>:self_support,:recycle=>:self_support,:revenge=>:generic_contact,:brick_break=>:generic_contact,:yawn=>:target_support,:knock_off=>:generic_contact,:endeavor=>:generic_contact,:eruption=>:ranged,
    :imprison=>:self_support,:refresh=>:self_support,:grudge=>:self_support,:snatch=>:self_support,:dive=>:generic_contact,:arm_thrust=>:punch,:camouflage=>:self_support,:tail_glow=>:tail,
    :luster_purge=>:ranged,:mist_ball=>:ranged,:feather_dance=>:dance,:teeter_dance=>:dance,:blaze_kick=>:kick,:mud_sport=>:field,:ice_ball=>:spin,:needle_arm=>:generic_contact,
    :slack_off=>:heal,:hyper_voice=>:sound,:poison_fang=>:bite,:crush_claw=>:scratch,:meteor_mash=>:generic_contact,:astonish=>:generic_contact,:weather_ball=>:ranged,:aromatherapy=>:field,
    :fake_tears=>:appeal,:air_cutter=>:slice,:overheat=>:ranged,:odor_sleuth=>:target_support,:rock_tomb=>:ranged,:silver_wind=>:ranged,:metal_sound=>:sound,:grass_whistle=>:sound,
    :tickle=>:appeal,:cosmic_power=>:swell,:water_spout=>:ranged,:signal_beam=>:ranged,:shadow_punch=>:punch,:extrasensory=>:ranged,:sky_uppercut=>:punch,:sand_tomb=>:ranged,
    :sheer_cold=>:ranged,:muddy_water=>:ranged,:bullet_seed=>:ranged,:aerial_ace=>:slice,:icicle_spear=>:ranged,:iron_defense=>:swell,:block=>:target_support,:howl=>:sound,
    :dragon_claw=>:scratch,:bulk_up=>:swell,:bounce=>:jump,:mud_shot=>:ranged,:poison_tail=>:tail,:covet=>:generic_contact,:volt_tackle=>:charge_dash,:magical_leaf=>:ranged,
    :water_sport=>:field,:calm_mind=>:swell,:leaf_blade=>:slice,:dragon_dance=>:dance,:rock_blast=>:ranged,:shock_wave=>:ranged,:water_pulse=>:ranged,:doom_desire=>:ranged,
    :psycho_boost=>:ranged,:roost=>:heal,:gravity=>:field,:miracle_eye=>:target_support,:wake_up_slap=>:slap,:hammer_arm=>:punch,:gyro_ball=>:spin,:healing_wish=>:heal,
    :brine=>:ranged,:natural_gift=>:ranged,:feint=>:quick,:pluck=>:generic_contact,:tailwind=>:flap,:acupressure=>:target_support,:metal_burst=>:ranged,:u_turn=>:generic_contact,
    :close_combat=>:generic_contact,:payback=>:generic_contact,:assurance=>:generic_contact,:embargo=>:target_support,:fling=>:throw,:psycho_shift=>:target_support,:trump_card=>:generic_contact,:heal_block=>:target_support,
    :wring_out=>:generic_contact,:power_trick=>:self_support,:gastro_acid=>:gas,:lucky_chant=>:field,:me_first=>:target_support,:copycat=>:self_support,:power_swap=>:target_support,:guard_swap=>:target_support,
    :punishment=>:generic_contact,:last_resort=>:generic_contact,:worry_seed=>:target_support,:sucker_punch=>:quick,:toxic_spikes=>:field,:heart_swap=>:target_support,:aqua_ring=>:heal,:magnet_rise=>:self_support,
    :flare_blitz=>:charge_dash,:force_palm=>:generic_contact,:aura_sphere=>:ranged,:rock_polish=>:self_support,:poison_jab=>:jab,:dark_pulse=>:ranged,:night_slash=>:slice,:aqua_tail=>:tail,
    :seed_bomb=>:ranged,:air_slash=>:slice,:x_scissor=>:slice,:bug_buzz=>:sound,:dragon_pulse=>:ranged,:dragon_rush=>:charge_dash,:power_gem=>:ranged,:vacuum_wave=>:ranged,
    :focus_blast=>:ranged,:energy_ball=>:ranged,:brave_bird=>:jump,:earth_power=>:ranged,:switcheroo=>:target_support,:giga_impact=>:charge_dash,:nasty_plot=>:self_support,:bullet_punch=>:punch,
    :avalanche=>:generic_contact,:ice_shard=>:ranged,:shadow_claw=>:scratch,:thunder_fang=>:bite,:ice_fang=>:bite,:fire_fang=>:bite,:shadow_sneak=>:quick,:mud_bomb=>:ranged,
    :psycho_cut=>:slice,:zen_headbutt=>:head,:mirror_shot=>:ranged,:flash_cannon=>:ranged,:rock_climb=>:generic_contact,:trick_room=>:field,:draco_meteor=>:ranged,:discharge=>:ranged,
    :lava_plume=>:ranged,:leaf_storm=>:ranged,:power_whip=>:generic_contact,:rock_wrecker=>:ranged,:cross_poison=>:slice,:gunk_shot=>:ranged,:iron_head=>:head,:magnet_bomb=>:ranged,
    :stone_edge=>:ranged,:captivate=>:appeal,:stealth_rock=>:field,:chatter=>:sound,:judgment=>:ranged,:bug_bite=>:bite,:charge_beam=>:ranged,:wood_hammer=>:charge_dash,
    :aqua_jet=>:quick,:attack_order=>:ranged,:defend_order=>:self_support,:heal_order=>:heal,:head_smash=>:head,:double_hit=>:generic_contact,:roar_of_time=>:ranged,:spacial_rend=>:ranged,
    :lunar_dance=>:dance,:crush_grip=>:generic_contact,:magma_storm=>:ranged,:dark_void=>:target_support,:seed_flare=>:ranged,:ominous_wind=>:ranged,:shadow_force=>:generic_contact,:hone_claws=>:scratch,
    :wide_guard=>:field,:guard_split=>:target_support,:power_split=>:target_support,:wonder_room=>:field,:psyshock=>:ranged,:venoshock=>:ranged,:autotomize=>:self_support,:rage_powder=>:self_support,
    :telekinesis=>:target_support,:magic_room=>:field,:smack_down=>:ranged,:flame_burst=>:ranged,:sludge_wave=>:ranged,:quiver_dance=>:dance,:heavy_slam=>:stomp,:synchronoise=>:ranged,
    :electro_ball=>:ranged,:soak=>:target_support,:flame_charge=>:charge_dash,:coil=>:swell,:low_sweep=>:kick,:acid_spray=>:gas,:foul_play=>:generic_contact,:entrainment=>:target_support,
    :after_you=>:target_support,:round=>:sound,:echoed_voice=>:sound,:chip_away=>:generic_contact,:clear_smog=>:gas,:stored_power=>:ranged,:quick_guard=>:field,:ally_switch=>:self_support,
    :shell_smash=>:self_support,:heal_pulse=>:heal,:hex=>:ranged,:sky_drop=>:jump,:shift_gear=>:self_support,:circle_throw=>:throw,:incinerate=>:ranged,:quash=>:target_support,
    :acrobatics=>:jump,:reflect_type=>:target_support,:retaliate=>:generic_contact,:final_gambit=>:ranged,:bestow=>:target_support,:inferno=>:ranged,:struggle_bug=>:ranged,:bulldoze=>:ranged,
    :dragon_tail=>:tail,:work_up=>:swell,:electroweb=>:ranged,:wild_charge=>:charge_dash,:drill_run=>:jab,:dual_chop=>:chop,:heart_stamp=>:generic_contact,:razor_shell=>:slice,
    :leaf_tornado=>:ranged,:steamroller=>:stomp,:cotton_guard=>:swell,:night_daze=>:ranged,:psystrike=>:ranged,:hurricane=>:flap,:searing_shot=>:ranged,:glaciate=>:ranged,
    :bolt_strike=>:charge_dash,:blue_flare=>:ranged,:fiery_dance=>:dance,:snarl=>:sound,:icicle_crash=>:ranged,:v_create=>:charge_dash,
  }
  NATIVE_SEMANTIC_CLASS_STATS_V063 = {
    :appeal=>{:moves=>12, :refs=>229, :native=>106, :alias=>0, :fallback=>123},
    :bite=>{:moves=>9, :refs=>235, :native=>26, :alias=>0, :fallback=>209},
    :charge_dash=>{:moves=>12, :refs=>298, :native=>93, :alias=>205, :fallback=>0},
    :chop=>{:moves=>3, :refs=>14, :native=>14, :alias=>0, :fallback=>0},
    :dance=>{:moves=>9, :refs=>73, :native=>24, :alias=>0, :fallback=>49},
    :field=>{:moves=>21, :refs=>282, :native=>84, :alias=>0, :fallback=>198},
    :flap=>{:moves=>4, :refs=>63, :native=>43, :alias=>0, :fallback=>20},
    :gas=>{:moves=>6, :refs=>68, :native=>13, :alias=>0, :fallback=>55},
    :generic_contact=>{:moves=>59, :refs=>633, :native=>0, :alias=>0, :fallback=>633},
    :head=>{:moves=>5, :refs=>92, :native=>27, :alias=>0, :fallback=>65},
    :heal=>{:moves=>16, :refs=>195, :native=>55, :alias=>0, :fallback=>140},
    :jab=>{:moves=>8, :refs=>111, :native=>23, :alias=>0, :fallback=>88},
    :jump=>{:moves=>5, :refs=>37, :native=>37, :alias=>0, :fallback=>0},
    :kick=>{:moves=>9, :refs=>39, :native=>15, :alias=>24, :fallback=>0},
    :lick=>{:moves=>1, :refs=>16, :native=>4, :alias=>0, :fallback=>12},
    :punch=>{:moves=>14, :refs=>82, :native=>28, :alias=>0, :fallback=>54},
    :quick=>{:moves=>8, :refs=>216, :native=>61, :alias=>155, :fallback=>0},
    :ranged=>{:moves=>144, :refs=>1679, :native=>557, :alias=>0, :fallback=>1122},
    :scratch=>{:moves=>7, :refs=>135, :native=>13, :alias=>0, :fallback=>122},
    :self_support=>{:moves=>37, :refs=>477, :native=>158, :alias=>0, :fallback=>319},
    :slap=>{:moves=>3, :refs=>56, :native=>5, :alias=>0, :fallback=>51},
    :slice=>{:moves=>12, :refs=>170, :native=>170, :alias=>0, :fallback=>0},
    :sound=>{:moves=>18, :refs=>368, :native=>85, :alias=>0, :fallback=>283},
    :spin=>{:moves=>6, :refs=>93, :native=>93, :alias=>0, :fallback=>0},
    :stomp=>{:moves=>5, :refs=>89, :native=>15, :alias=>0, :fallback=>74},
    :swell=>{:moves=>16, :refs=>247, :native=>91, :alias=>0, :fallback=>156},
    :tail=>{:moves=>6, :refs=>99, :native=>99, :alias=>0, :fallback=>0},
    :target_support=>{:moves=>65, :refs=>846, :native=>326, :alias=>0, :fallback=>520},
    :throw=>{:moves=>5, :refs=>47, :native=>47, :alias=>0, :fallback=>0},
    :withdraw=>{:moves=>1, :refs=>16, :native=>15, :alias=>0, :fallback=>1},
  }
end
