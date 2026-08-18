#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Move Runtime Coverage Data v0.58
# 分類：技能資料／效果覆蓋
#
# 【用途／機制】
# 定義 MoveDB、招式 Runtime 行為與 7005/7005 learnset reference 覆蓋。
#
# 【怎麼調整】
# 新增招式效果優先放在資料表與共用 foundation；不要為每招複製一份傷害流程。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_COVERAGE_IX_MANIFEST_V058 / MOVE_COVERAGE_IX_CHECKSUM_TEXT_V058 / MOVE_COVERAGE_IX_CONFIG_V058 / MOVE_COVERAGE_IX_MOVE_V058
# - MOVE_PRESENTATION_V058 / MOVE_COVERAGE_IX_VISUAL_V058
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Move Runtime Coverage Data v0.58
#    Expansion IX-A - Final Learnset Coverage Sprint Part 1
#===============================================================================
module PMD_AC
  MOVE_COVERAGE_IX_MANIFEST_V058 = {
    :schema_version=>"1.0",:content_version=>"0.58.0",:base_version=>"0.57.6",
    :feature=>"move_runtime_coverage_expansion_ix_a",:new_mapped_move_count=>24,
    :cumulative_mapped_move_count=>502,:new_reference_covered=>82,
    :cumulative_reference_covered=>6981,:learnset_reference_total=>7005,
    :cumulative_coverage_percent=>99.66,
    :new_move_keys=>[:attract,:after_you,:grudge,:nature_power,:power_trick,
      :guard_split,:high_jump_kick,:jump_kick,:power_split,:snatch,:beat_up,
      :conversion_2,:echoed_voice,:retaliate,:telekinesis,:trump_card,
      :camouflage,:focus_punch,:quash,:round,:transform,:aeroblast,
      :attack_order,:chatter],
    :ref_counts=>{:attract=>11,:after_you=>5,:grudge=>5,:nature_power=>5,
      :power_trick=>5,:guard_split=>4,:high_jump_kick=>4,:jump_kick=>4,
      :power_split=>4,:snatch=>4,:beat_up=>3,:conversion_2=>3,
      :echoed_voice=>3,:retaliate=>3,:telekinesis=>3,:trump_card=>3,
      :camouflage=>2,:focus_punch=>2,:quash=>2,:round=>2,:transform=>2,
      :aeroblast=>1,:attack_order=>1,:chatter=>1},
    :presentation_profiles=>24,:timing_profiles=>24,:audio_profiles=>24,
    :visual_showcase_moves=>24,:runtime_checksum32=>1319456942
  }
  MOVE_COVERAGE_IX_CHECKSUM_TEXT_V058 = "v058|attract|after_you|grudge|nature_power|power_trick|guard_split|high_jump_kick|jump_kick|power_split|snatch|beat_up|conversion_2|echoed_voice|retaliate|telekinesis|trump_card|camouflage|focus_punch|quash|round|transform|aeroblast|attack_order|chatter|82|6981|99.66|presentation24|organic_audio|special_foundations"

  MOVE_COVERAGE_IX_CONFIG_V058 = {
    :attract=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:fairy,:effects=>[{:type=>:infatuate_v058,:duration=>180}],:behavior_status=>:adapted_genderless_infatuation_50pct_action_check_v058},
    :after_you=>{:target_type=>:ally,:policy=>:protect_ally,:delivery=>:instant,:range_px=>190.0,:visual_kind=>:target_hit,:visual_style=>:normal,:effects=>[{:type=>:after_you_v058,:energy=>70}],:behavior_status=>:adapted_realtime_ally_readiness_boost_v058},
    :grudge=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:ghost,:effects=>[{:type=>:grudge_v058,:duration=>300,:disable=>120}],:behavior_status=>:adapted_faint_revenge_energy_zero_disable_v058},
    :nature_power=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>240.0,:visual_kind=>:target_hit,:visual_style=>:normal,:effects=>[{:type=>:nature_power_v058}],:behavior_status=>:adapted_weather_field_move_replay_v058},
    :power_trick=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:psychic,:effects=>[{:type=>:power_trick_v058}],:behavior_status=>:implemented_attack_defense_swap_v058},
    :guard_split=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:psychic,:effects=>[{:type=>:guard_split_v058,:duration=>300}],:behavior_status=>:implemented_def_spdef_average_override_v058},
    :high_jump_kick=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>:contact,:visual_kind=>:contact_hit,:visual_style=>:fighting,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>130}],:crash_on_miss_v058=>0.5,:behavior_status=>:implemented_crash_on_miss_v058},
    :jump_kick=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>:contact,:visual_kind=>:contact_hit,:visual_style=>:fighting,:contact=>true,:force_contact_range=>true,:effects=>[{:type=>:damage,:power=>100}],:crash_on_miss_v058=>0.5,:behavior_status=>:implemented_crash_on_miss_v058},
    :power_split=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:psychic,:effects=>[{:type=>:power_split_v058,:duration=>300}],:behavior_status=>:implemented_atk_spatk_average_override_v058},
    :snatch=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:dark,:effects=>[{:type=>:snatch_v058,:duration=>180}],:behavior_status=>:adapted_next_enemy_self_support_stolen_v058},
    :beat_up=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:dark,:contact=>true,:force_contact_range=>true,:multi_hit_v049=>true,:beat_up_v058=>true,:effects=>[{:type=>:damage,:power=>20}],:behavior_status=>:adapted_hits_equal_living_deployed_allies_v058},
    :conversion_2=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:normal,:effects=>[{:type=>:conversion_2_v058}],:behavior_status=>:adapted_resist_last_incoming_move_type_v058},
    :echoed_voice=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>240.0,:visual_kind=>:target_hit,:visual_style=>:normal,:dynamic_power_v058=>:echoed_voice,:effects=>[{:type=>:damage,:power=>40}],:sound=>true,:behavior_status=>:implemented_team_chain_40_to_200_v058},
    :retaliate=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:normal,:contact=>true,:force_contact_range=>true,:dynamic_power_v058=>:retaliate,:effects=>[{:type=>:damage,:power=>70}],:behavior_status=>:adapted_recent_ally_faint_double_power_v058},
    :telekinesis=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:psychic,:effects=>[{:type=>:telekinesis_v058,:duration=>180}],:behavior_status=>:implemented_airborne_evasion_neutral_v058},
    :trump_card=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>240.0,:visual_kind=>:projectile,:visual_style=>:normal,:dynamic_power_v058=>:trump_card,:effects=>[{:type=>:damage,:power=>40}],:behavior_status=>:adapted_consecutive_use_power_40_50_60_80_200_v058},
    :camouflage=>{:target_type=>:self,:policy=>:self,:delivery=>:instant,:range_px=>0.0,:visual_kind=>:self_fx,:visual_style=>:normal,:effects=>[{:type=>:camouflage_v058}],:behavior_status=>:adapted_weather_field_type_change_v058},
    :focus_punch=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>52.0,:visual_kind=>:contact_hit,:visual_style=>:fighting,:contact=>true,:force_contact_range=>true,:charge_v058=>60,:effects=>[{:type=>:damage,:power=>150}],:behavior_status=>:implemented_charge_cancel_if_hit_v058},
    :quash=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:dark,:effects=>[{:type=>:quash_v058,:delay=>36,:energy_loss=>40}],:behavior_status=>:adapted_realtime_action_delay_v058},
    :round=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>240.0,:visual_kind=>:target_hit,:visual_style=>:normal,:dynamic_power_v058=>:round,:effects=>[{:type=>:damage,:power=>60}],:sound=>true,:behavior_status=>:implemented_team_round_chain_double_v058},
    :transform=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:instant,:range_px=>220.0,:visual_kind=>:target_hit,:visual_style=>:normal,:effects=>[{:type=>:transform_v058,:duration=>300}],:behavior_status=>:adapted_combat_stats_types_ability_stage_copy_no_sprite_move_copy_v058},
    :aeroblast=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:beam,:range_px=>260.0,:visual_kind=>:beam,:visual_style=>:flying,:effects=>[{:type=>:damage,:power=>100,:crit_bonus=>0.075}],:behavior_status=>:implemented_high_crit_v058},
    :attack_order=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>240.0,:visual_kind=>:projectile,:visual_style=>:bug,:effects=>[{:type=>:damage,:power=>90,:crit_bonus=>0.075}],:behavior_status=>:implemented_high_crit_v058},
    :chatter=>{:target_type=>:enemy_targeted,:policy=>:current_target,:delivery=>:projectile,:range_px=>240.0,:visual_kind=>:target_hit,:visual_style=>:flying,:effects=>[{:type=>:damage,:power=>60},{:type=>:confusion,:chance=>100,:duration=>120}],:sound=>true,:behavior_status=>:adapted_guaranteed_confusion_gen5_no_recording_v058}
  }

  MOVE_COVERAGE_IX_MOVE_V058={}
  MOVE_COVERAGE_IX_CONFIG_V058.each do |k,cfg|
    src=MOVE_DB_V017[k]||{}
    d={:canonical_move_key=>k,:move_key=>k,:runtime_skill_key=>("mv_"+k.to_s).to_sym,
      :name=>src[:name]||k.to_s,:name_en=>src[:name_en]||k.to_s,:type=>src[:type]||:normal,
      :move_type=>src[:type]||:normal,:category=>src[:category]||:status,
      :damage_category=>src[:category]||:status,:canonical_power=>src[:canonical_power],
      :accuracy=>src[:accuracy],:priority=>src[:priority].to_i}
    cfg.each{|x,v|d[x]=v}
    d[:range_px]=52.0 if d[:range_px]==:contact
    MOVE_COVERAGE_IX_MOVE_V058[k]=d
  end

  MOVE_PRESENTATION_V058={}
  MOVE_COVERAGE_IX_MOVE_V058.each do |k,d|
    kind=d[:visual_kind]
    motion=:stationary_cast;pose=:charge;timing=:cast_resolve
    if d[:contact]
      motion=(k==:beat_up ? :multi_contact : ([:high_jump_kick,:jump_kick,:focus_punch].include?(k) ? :charge_dash : :contact_return));pose=:attack;timing=:contact_hit_hold
    elsif kind==:beam
      motion=:stationary_cast;pose=:shoot;timing=:beam_impact
    elsif d[:category]!=:status
      motion=:stationary_cast;pose=:shoot;timing=(kind==:projectile ? :projectile_impact : :cast_resolve)
    end
    MOVE_PRESENTATION_V058[k]={:move_key=>k,:motion=>motion,:pose=>pose,:visual_kind=>kind,
      :projectile_visual=>d[:visual_style],:impact_visual=>d[:visual_style],:persistent_visual=>:none,
      :timing=>timing,:sfx_profile=>:organic_v0561}
  end
  MOVE_COVERAGE_IX_VISUAL_V058={};MOVE_COVERAGE_IX_AUDIO_V058={}
  MOVE_COVERAGE_IX_MOVE_V058.each do |k,d|
    p=MOVE_PRESENTATION_V058[k]
    MOVE_COVERAGE_IX_VISUAL_V058[k]={:visual_kind=>p[:visual_kind],:style=>p[:projectile_visual],:hide_logical_projectile=>false,:timing=>p[:timing],:persistent_visual=>p[:persistent_visual]}
    MOVE_COVERAGE_IX_AUDIO_V058[k]={:type=>d[:type],:category=>d[:category],:visual_kind=>d[:visual_kind],:audio_style=>d[:visual_style],:organic_palette=>:v0561,:special=>true}
  end
end
