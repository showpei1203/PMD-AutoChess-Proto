#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Data v0.67
# 分類：特性 Ability
#
# 【用途／機制】
# 定義特性資料、觸發時機、被動效果與 Runtime 覆蓋。
#
# 【怎麼調整】
# 新增特性時先放 Data，再在對應 Runtime helper 實作；需要 Popup／LOG 的觸發效果要同步補呈現。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_RUNTIME_MANIFEST_V067 / ABILITY_RUNTIME_BEHAVIOR_V067
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Ability Runtime Coverage Data v0.67
# Generation V ability runtime expansion IV. Additive to v0.24-v0.28 + v0.64-v0.66.1.
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_MANIFEST_V067 = {
    :schema_version=>"1.0",:content_version=>"0.67.0",:canon_snapshot=>"2026-08-09",
    :ruleset=>"black_white",:target_generation=>5,:total_slot_count=>1193,
    :previous_implemented_ability_count=>125,:new_implemented_ability_count=>10,
    :cumulative_implemented_ability_count=>135,
    :previous_implemented_slot_count=>975,:new_implemented_slot_count=>53,
    :implemented_slot_count=>1028,:implemented_slot_coverage_percent=>86.17,
    :previous_species_with_any_implemented_ability=>481,
    :new_species_with_any_implemented_ability=>2,
    :species_with_any_implemented_ability=>483,:species_coverage_percent=>97.77,
    :new_ability_keys=>[:magic_guard,:sticky_hold,:unburden,:pickpocket,:klutz,
      :heavy_metal,:light_metal,:frisk,:anticipation,:forewarn],
    :runtime_checksum32=>1564356489,
    :notes=>[
      "Magic Guard completes current-runtime indirect damage protection: status/tick damage, Leech Seed, Nightmare/Toxic, hazards, weather, ability damage, Life Orb, crash damage and recoil; Struggle recoil remains exempt.",
      "Sticky Hold blocks hostile Knock Off, Bug Bite, Pluck, Thief, Trick, Switcheroo and Pickpocket item removal while leaving the holder's own item-changing actions intact.",
      "Unburden doubles realtime Speed after a held item is consumed or lost without replacement and resets at combat start or ability loss.",
      "Pickpocket steals the attacker's held item after a completed damaging contact move only when the defender survives and holds no item; multi-hit packets remain v0.60.2-owned.",
      "Klutz disables all current held-item effects and naturally gates Fling/Natural Gift through the existing held-item-effective check.",
      "Heavy Metal and Light Metal modify the existing v0.53 species mass proxy only, preserving the project's HP/stat-derived weight adaptation.",
      "Frisk reveals one randomly selected living opponent's held item on entry/ability gain.",
      "Anticipation scans opponents' current battle move pools for executable OHKO or damaging super-effective moves and logs the first threat found.",
      "Forewarn scores opponents' current battle move pools by Generation-V canonical power rules and reveals one highest-power move.",
      "v0.62 Native Pose, v0.60.2 multi-hit packets, presentation anchors and v0.56.1 Organic SFX remain unchanged."
    ]
  }

  ABILITY_RUNTIME_BEHAVIOR_V067 = {
    :magic_guard=>{:ability_key=>:magic_guard,:kind=>:indirect_damage_immunity,
      :behavior_status=>:implemented_ability_v067,
      :covers=>[:status_ticks,:toxic,:nightmare,:leech_seed,:hazards,:weather,
        :ability_damage,:life_orb,:crash_damage,:move_recoil],
      :exceptions=>[:struggle_recoil,:direct_move_damage,:hp_cost]},
    :sticky_hold=>{:ability_key=>:sticky_hold,:kind=>:hostile_item_removal_immunity,
      :behavior_status=>:implemented_ability_v067,
      :blocked_moves=>[:knock_off,:bug_bite,:pluck,:thief,:trick,:switcheroo,:pickpocket],
      :own_item_actions_allowed=>true},
    :unburden=>{:ability_key=>:unburden,:kind=>:item_loss_speed_multiplier,
      :behavior_status=>:implemented_ability_v067,:speed_num=>2,:speed_den=>1,
      :requires_prior_item=>true,:no_trigger_on_replacement=>true},
    :pickpocket=>{:ability_key=>:pickpocket,:kind=>:post_contact_item_steal,
      :behavior_status=>:implemented_ability_v067,:contact_only=>true,
      :requires_empty_holder=>true,:requires_survival=>true,:after_complete_move=>true},
    :klutz=>{:ability_key=>:klutz,:kind=>:held_item_effect_suppression,
      :behavior_status=>:implemented_ability_v067,:blocks_current_item_effects=>true,
      :blocks_item_power_moves=>[:fling,:natural_gift]},
    :heavy_metal=>{:ability_key=>:heavy_metal,:kind=>:mass_proxy_multiplier,
      :behavior_status=>:implemented_ability_v067,:num=>2,:den=>1,
      :affects=>[:heavy_slam,:low_kick]},
    :light_metal=>{:ability_key=>:light_metal,:kind=>:mass_proxy_multiplier,
      :behavior_status=>:implemented_ability_v067,:num=>1,:den=>2,
      :affects=>[:heavy_slam,:low_kick]},
    :frisk=>{:ability_key=>:frisk,:kind=>:entry_item_reveal,
      :behavior_status=>:implemented_ability_v067,:target=>:random_living_opponent,
      :reveal_none_if_selected_empty=>true},
    :anticipation=>{:ability_key=>:anticipation,:kind=>:entry_threat_scan,
      :behavior_status=>:implemented_ability_v067,
      :threats=>[:ohko,:damaging_super_effective],:source=>:current_battle_move_pool},
    :forewarn=>{:ability_key=>:forewarn,:kind=>:entry_highest_power_reveal,
      :behavior_status=>:implemented_ability_v067,:source=>:current_battle_move_pool,
      :ohko_power=>150,:counter_family_power=>120,:variable_damage_power=>80,
      :status_power=>1,:tie=>:random}
  }
end
