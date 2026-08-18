#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Data v0.66
# 分類：特性 Ability
#
# 【用途／機制】
# 定義特性資料、觸發時機、被動效果與 Runtime 覆蓋。
#
# 【怎麼調整】
# 新增特性時先放 Data，再在對應 Runtime helper 實作；需要 Popup／LOG 的觸發效果要同步補呈現。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_RUNTIME_MANIFEST_V066 / ABILITY_RUNTIME_BEHAVIOR_V066
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Ability Runtime Coverage Data v0.66
# Generation V ability runtime expansion III. Additive to v0.24-v0.28 + v0.64-v0.65.
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_MANIFEST_V066 = {
    :schema_version=>"1.0",:content_version=>"0.66.0",:canon_snapshot=>"2026-08-09",
    :ruleset=>"black_white",:target_generation=>5,:total_slot_count=>1193,
    :previous_implemented_ability_count=>115,:new_implemented_ability_count=>10,
    :cumulative_implemented_ability_count=>125,
    :previous_implemented_slot_count=>952,:new_implemented_slot_count=>23,
    :implemented_slot_count=>975,:implemented_slot_coverage_percent=>81.73,
    :previous_species_with_any_implemented_ability=>473,
    :new_species_with_any_implemented_ability=>8,
    :species_with_any_implemented_ability=>481,:species_coverage_percent=>97.37,
    :new_ability_keys=>[:infiltrator,:cursed_body,:heatproof,:normalize,:truant,
      :slow_start,:bad_dreams,:color_change,:forecast,:flower_gift],
    :runtime_checksum32=>1001032422,
    :notes=>[
      "Generation-V Infiltrator bypasses the executable Reflect, Light Screen, Safeguard and Mist field protections; Substitute bypass is intentionally not included until the Gen-VI ruleset.",
      "Cursed Body rolls independently per damaging hit and reuses the v0.52 Disable runtime duration; disabling never interrupts an in-flight multi-hit sequence.",
      "Heatproof halves Fire attack damage and the existing burn tick value.",
      "Generation-V Normalize changes move type without the later-generation power bonus and keeps Gen-V exceptions unchanged.",
      "Truant alternates successful action opportunity and loafing without spending skill energy on the loaf.",
      "Slow Start halves Attack and Speed for five 60-frame canonical turns after entry or ability gain.",
      "Bad Dreams deals one eighth max HP to sleeping opposing units each canonical turn pulse.",
      "Color Change updates type after the complete damaging move, not between multi-hit packets.",
      "Forecast changes Castform battle type with effective sun/rain/hail; weather suppression returns Normal behavior.",
      "Flower Gift gives Cherrim and living allies 1.5x Attack and Special Defense in effective sun.",
      "v0.62 Native Pose, v0.60.2 multi-hit packets, presentation anchors and v0.56.1 Organic SFX remain unchanged."
    ]
  }

  ABILITY_RUNTIME_BEHAVIOR_V066 = {
    :infiltrator=>{:ability_key=>:infiltrator,:kind=>:barrier_bypass,
      :behavior_status=>:implemented_ability_v066,:bypass=>[:reflect,:light_screen,:safeguard,:mist],
      :future_non_executable=>[:substitute_gen6]},
    :cursed_body=>{:ability_key=>:cursed_body,:kind=>:on_hit_disable,
      :behavior_status=>:implemented_ability_v066,:chance_num=>30,:chance_den=>100,
      :disable_frames=>180,:roll_once_per_hit=>true},
    :heatproof=>{:ability_key=>:heatproof,:kind=>:fire_and_burn_reduction,
      :behavior_status=>:implemented_ability_v066,:fire_num=>1,:fire_den=>2,
      :burn_num=>1,:burn_den=>2},
    :normalize=>{:ability_key=>:normalize,:kind=>:move_type_normalize,
      :behavior_status=>:implemented_ability_v066,:target_type=>:normal,
      :power_bonus_gen5=>false,
      :exceptions=>[:hidden_power,:weather_ball,:natural_gift,:judgment,:techno_blast,:struggle]},
    :truant=>{:ability_key=>:truant,:kind=>:alternate_action_loaf,
      :behavior_status=>:implemented_ability_v066,:pattern=>[:act,:loaf],
      :loaf_spends_energy=>false,:loaf_frames=>36},
    :slow_start=>{:ability_key=>:slow_start,:kind=>:entry_timed_stat_reduction,
      :behavior_status=>:implemented_ability_v066,:turns=>5,:turn_frames=>60,
      :atk_num=>1,:atk_den=>2,:speed_num=>1,:speed_den=>2},
    :bad_dreams=>{:ability_key=>:bad_dreams,:kind=>:sleeping_enemy_turn_damage,
      :behavior_status=>:implemented_ability_v066,:damage_num=>1,:damage_den=>8,
      :turn_frames=>60},
    :color_change=>{:ability_key=>:color_change,:kind=>:post_move_type_change,
      :behavior_status=>:implemented_ability_v066,:after_complete_move=>true,
      :damaging_only=>true},
    :forecast=>{:ability_key=>:forecast,:kind=>:castform_weather_type,
      :behavior_status=>:implemented_ability_v066,
      :weather_types=>{:sun=>:fire,:rain=>:water,:hail=>:ice},
      :suppressed_or_other=>:normal},
    :flower_gift=>{:ability_key=>:flower_gift,:kind=>:sun_team_stat_multiplier,
      :behavior_status=>:implemented_ability_v066,:species=>:cherrim,
      :weather=>:sun,:atk_num=>3,:atk_den=>2,:spdef_num=>3,:spdef_den=>2}
  }
end
