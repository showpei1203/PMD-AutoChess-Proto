#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Move Runtime Coverage Data v0.59
# 分類：技能資料／效果覆蓋
#
# 【用途／機制】
# 定義 MoveDB、招式 Runtime 行為與 7005/7005 learnset reference 覆蓋。
#
# 【怎麼調整】
# 新增招式效果優先放在資料表與共用 foundation；不要為每招複製一份傷害流程。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_COVERAGE_X_MANIFEST_V059 / MOVE_COVERAGE_X_CHECKSUM_TEXT_V059 / MOVE_COVERAGE_X_CONFIG_V059 / MOVE_COVERAGE_X_MOVE_V059
# - MOVE_PRESENTATION_V059 / MOVE_COVERAGE_X_VISUAL_V059
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Move Runtime Coverage Data v0.59
#    Expansion X - Final Black/White Level-up Learnset Coverage
#===============================================================================
module PMD_AC
  MOVE_COVERAGE_X_MANIFEST_V059 = {
    :schema_version=>"1.0",:content_version=>"0.59.0",:base_version=>"0.58",
    :feature=>"move_runtime_coverage_expansion_x_final_learnset",
    :new_mapped_move_count=>24,:cumulative_mapped_move_count=>526,
    :new_reference_covered=>24,:cumulative_reference_covered=>7005,
    :learnset_reference_total=>7005,:cumulative_coverage_percent=>100.00,
    :remaining_reference_count=>0,:remaining_unique_move_count=>0,
    :new_move_keys=>[:circle_throw,:crush_grip,:defend_order,:doom_desire,
      :facade,:frustration,:heart_swap,:icicle_spear,:incinerate,:judgment,
      :lunar_dance,:magma_storm,:pain_split,:pay_day,:poison_tail,:present,
      :psystrike,:return,:roar_of_time,:rock_wrecker,:sacred_fire,:sky_drop,
      :teeter_dance,:triple_kick],
    :ref_counts=>{:circle_throw=>1,:crush_grip=>1,:defend_order=>1,:doom_desire=>1,
      :facade=>1,:frustration=>1,:heart_swap=>1,:icicle_spear=>1,:incinerate=>1,
      :judgment=>1,:lunar_dance=>1,:magma_storm=>1,:pain_split=>1,:pay_day=>1,
      :poison_tail=>1,:present=>1,:psystrike=>1,:return=>1,:roar_of_time=>1,
      :rock_wrecker=>1,:sacred_fire=>1,:sky_drop=>1,:teeter_dance=>1,
      :triple_kick=>1},
    :presentation_profiles=>24,:timing_profiles=>24,:audio_profiles=>24,
    :visual_showcase_moves=>24,:runtime_checksum32=>243111014
  }
  MOVE_COVERAGE_X_CHECKSUM_TEXT_V059 = "v059|circle_throw|crush_grip|defend_order|doom_desire|facade|frustration|heart_swap|icicle_spear|incinerate|judgment|lunar_dance|magma_storm|pain_split|pay_day|poison_tail|present|psystrike|return|roar_of_time|rock_wrecker|sacred_fire|sky_drop|teeter_dance|triple_kick|24|7005|100.00|remaining0|presentation24|organic_audio|final_learnset"

  MOVE_COVERAGE_X_CONFIG_V059 = {
    :circle_throw=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fighting,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>60},{:type=>:force_back_v052,:distance=>128.0}],:behavior_status=>:adapted_realtime_knockback_no_bench_v059},
    :crush_grip=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:dynamic_power_v052=>:wring_out,:effects=>[{:type=>:damage,:power=>1}],:behavior_status=>:implemented_current_hp_scaled_1_to_121_v059},
    :defend_order=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:bug,:effects=>[{:type=>:stat_stage,:stat=>:def,:stages=>1},{:type=>:stat_stage,:stat=>:spdef,:stages=>1}],:behavior_status=>:implemented_def_spdef_up_v059},
    :doom_desire=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>250.0,:visual_kind=>:target_hit,:visual_style=>:steel,:effects=>[{:type=>:doom_desire_v059,:power=>140,:delay=>120}],:behavior_status=>:implemented_delayed_steel_hit_v059},
    :facade=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:dynamic_power_v059=>:facade,:effects=>[{:type=>:damage,:power=>70}],:behavior_status=>:implemented_status_double_power_v059},
    :frustration=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>102}],:behavior_status=>:adapted_no_friendship_fixed_power_102_v059},
    :heart_swap=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>230.0,:visual_kind=>:target_hit,:visual_style=>:psychic,:effects=>[{:type=>:heart_swap_v059}],:behavior_status=>:implemented_all_stat_stage_swap_v059},
    :icicle_spear=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>250.0,:visual_kind=>:projectile,:visual_style=>:ice,:multi_hit_v049=>true,:multi_hit_min=>2,:multi_hit_max=>5,:effects=>[{:type=>:damage,:power=>25}],:behavior_status=>:implemented_sequential_2_to_5_v059},
    :incinerate=>{:target_type=>:ground_enemy,:policy=>:best_cluster,:delivery=>:aoe,:range_px=>260.0,:visual_kind=>:area_hit,:visual_style=>:fire,:radius=>999.0,:global_direct=>true,:effects=>[{:type=>:damage,:power=>30,:directional=>false},{:type=>:incinerate_item_v059}],:behavior_status=>:adapted_enemy_side_aoe_consumable_item_destroy_v059},
    :judgment=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>260.0,:visual_kind=>:projectile,:visual_style=>:normal,:effects=>[{:type=>:damage,:power=>100}],:behavior_status=>:adapted_no_plate_profiles_normal_type_v059},
    :lunar_dance=>{:target_type=>:ally,:policy=>:protect_ally,:delivery=>:instant,:range_px=>200.0,:visual_kind=>:target_hit,:visual_style=>:psychic,:effects=>[{:type=>:lunar_dance_v059}],:behavior_status=>:adapted_active_ally_fullheal_cure_energy100_selfko_v059},
    :magma_storm=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>250.0,:visual_kind=>:projectile,:visual_style=>:fire,:effects=>[{:type=>:damage,:power=>120},{:type=>:bound_v052,:duration=>300,:interval=>60,:ratio=>0.0625,:style=>:fire}],:behavior_status=>:implemented_damage_bind_tick_v059},
    :pain_split=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:normal,:effects=>[{:type=>:pain_split_v059}],:behavior_status=>:implemented_hp_average_v059},
    :pay_day=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:normal,:effects=>[{:type=>:damage,:power=>40},{:type=>:pay_day_v059,:level_mult=>5}],:behavior_status=>:implemented_damage_plus_gold_v059},
    :poison_tail=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:poison,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>50,:crit_bonus=>0.075}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:poison,:chance=>10,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.015}],:behavior_status=>:implemented_highcrit_poison10_v059},
    :present=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>230.0,:visual_kind=>:projectile,:visual_style=>:normal,:effects=>[{:type=>:present_v059}],:behavior_status=>:implemented_random_40_80_120_or_heal25_v059},
    :psystrike=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>250.0,:visual_kind=>:projectile,:visual_style=>:psychic,:damage_calc_v057=>:psyshock,:effects=>[{:type=>:damage,:power=>100}],:behavior_status=>:implemented_spatk_vs_def_v059},
    :return=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>102}],:behavior_status=>:adapted_no_friendship_fixed_power_102_v059},
    :roar_of_time=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>270.0,:visual_kind=>:beam,:visual_style=>:dragon,:beam_style=>:signal,:beam_life=>28,:beam_width=>10,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:behavior_status=>:implemented_heavy_beam_recharge60_v059},
    :rock_wrecker=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>260.0,:visual_kind=>:projectile,:visual_style=>:rock,:effects=>[{:type=>:damage,:power=>150},{:type=>:recharge_v051,:frames=>60}],:behavior_status=>:implemented_heavy_projectile_recharge60_v059},
    :sacred_fire=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>250.0,:visual_kind=>:projectile,:visual_style=>:fire,:effects=>[{:type=>:damage,:power=>100}],:secondary_effects=>[{:group=>0,:type=>:ailment,:status=>:burn,:chance=>50,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}],:behavior_status=>:implemented_burn50_v059},
    :sky_drop=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:flying,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:sky_drop_v059,:power=>60,:delay=>60}],:behavior_status=>:adapted_two_phase_carry_airborne_lock_no_weight_rule_v059},
    :teeter_dance=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:normal,:effects=>[{:type=>:teeter_dance_v059}],:behavior_status=>:implemented_all_other_units_confusion_v059},
    :triple_kick=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fighting,:contact=>true,:force_contact_range=>true,:triple_kick_v059=>true,:effects=>[{:type=>:damage,:power=>10}],:behavior_status=>:implemented_sequential_three_hits_power_10_20_30_v059}
  }

  MOVE_COVERAGE_X_MOVE_V059={}
  MOVE_COVERAGE_X_CONFIG_V059.each do |k,cfg|
    src=MOVE_DB_V017[k]||{}
    d={:canonical_move_key=>k,:move_key=>k,:runtime_skill_key=>("mv_"+k.to_s).to_sym,
      :name=>src[:name]||k.to_s,:name_en=>src[:name_en]||k.to_s,
      :type=>src[:type]||:normal,:move_type=>src[:type]||:normal,
      :category=>src[:category]||:status,:damage_category=>src[:category]||:status,
      :canonical_power=>src[:canonical_power],:accuracy=>src[:accuracy],
      :priority=>src[:priority].to_i}
    cfg.each{|x,v|d[x]=v}
    MOVE_COVERAGE_X_MOVE_V059[k]=d
  end

  MOVE_PRESENTATION_V059={}
  MOVE_COVERAGE_X_MOVE_V059.each do |k,d|
    kind=d[:visual_kind];motion=:stationary_cast;pose=:charge;timing=:cast_resolve
    if d[:contact]
      motion=(k==:triple_kick ? :multi_contact : (k==:sky_drop ? :runtime_owned : :contact_return));pose=:attack;timing=(k==:sky_drop ? :sky_drop_60f : (k==:triple_kick ? :sequential_three_hit : :contact_hit_hold))
    elsif kind==:beam
      motion=:stationary_cast;pose=:shoot;timing=:beam_impact
    elsif kind==:area_hit
      motion=:stationary_cast;pose=:shoot;timing=:area_same_frame
    elsif d[:category]!=:status
      motion=:stationary_cast;pose=:shoot;timing=(kind==:projectile ? :projectile_impact : :cast_resolve)
    end
    timing=:delay120_then_impact if k==:doom_desire
    timing=:fullheal_cure_energy_then_selfko if k==:lunar_dance
    MOVE_PRESENTATION_V059[k]={:move_key=>k,:motion=>motion,:pose=>pose,:visual_kind=>kind,
      :projectile_visual=>d[:visual_style],:impact_visual=>d[:visual_style],
      :persistent_visual=>((k==:doom_desire) ? :future_marker : ((k==:magma_storm) ? :fire_trap : :none)),
      :timing=>timing,:sfx_profile=>:organic_v0561}
  end
  MOVE_COVERAGE_X_VISUAL_V059={};MOVE_COVERAGE_X_AUDIO_V059={}
  MOVE_COVERAGE_X_MOVE_V059.each do |k,d|
    p=MOVE_PRESENTATION_V059[k]
    MOVE_COVERAGE_X_VISUAL_V059[k]={:visual_kind=>p[:visual_kind],:style=>p[:projectile_visual],
      :hide_logical_projectile=>false,:timing=>p[:timing],:persistent_visual=>p[:persistent_visual]}
    MOVE_COVERAGE_X_AUDIO_V059[k]={:type=>d[:type],:category=>d[:category],
      :visual_kind=>d[:visual_kind],:audio_style=>d[:visual_style],
      :organic_palette=>:v0561,:special=>true}
  end
end
