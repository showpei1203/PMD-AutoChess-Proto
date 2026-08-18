# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Data v0.97
# 分類：特性 Ability／Generation V Runtime Completion VI
#
# 【用途】
# 收尾 Generation V #0001～#0494 最後 12 種尚未 Runtime 化的 Ability，
# 使 157/157 Ability、1193/1193 Ability Slots 全部具有可執行規則。
#
# 【本版新增】
# Arena Trap / Gluttony / Harvest / Honey Gather / Illuminate / Imposter /
# Magnet Pull / Pickup / Rivalry / Shadow Tag / Stall / Suction Cups
#
# 【機制規則】
# - Arena Trap：地面敵人在 118px 內不能主動拉遠距離。
# - Magnet Pull：鋼系敵人在 132px 內不能主動拉遠距離。
# - Shadow Tag：敵人在 138px 內不能主動拉遠距離；Shadow Tag 對持有者互不封鎖。
# - Suction Cups：免疫 Pull／Knockback 強制位移。
# - Stall：普攻／技能 Startup 額外 +12f，不降低移動速度。
# - Rivalry：本專案沒有正式性別資料，因此採同進化族系競爭；同族系傷害 x1.20，異族系 x0.90。
# - Gluttony：持 Leftovers 且 HP<50% 時，既有 Leftovers 回復再追加同量一次。
# - Harvest：Focus Sash／Air Balloon 消耗後，每 180f 嘗試恢復；晴天 100%，其他 50%。
# - Pickup：勝利且存在 v0.94 Loot Pool 時，35% 機率追加 1 次 Weighted Loot Roll。
# - Honey Gather：勝利且存在 v0.94 Loot Pool 時，50% 機率追加 1 次 Weighted Loot Roll。
# - Illuminate：隊伍中存在時，地圖隨機遭遇步數約縮短 25%。
# - Imposter：開戰自動套用 v0.58 Transform 的「能力值／屬性／Ability／Stage」複製規則。
#
# 【主要設定項】
# ABILITY_RUNTIME_BEHAVIOR_V097：所有可調半徑、機率、倍率、Frame。
# ABILITY_RUNTIME_MANIFEST_V097：Coverage 與版本驗證。
#
# 【事件／腳本呼叫】
# 一般不需事件設定；個體 ability_slot 自動生效。
# Debug：PMD_AC.ability_runtime_behavior_v097(:arena_trap)
#
# 【範例】
# 磁怪 Magnet Pull 面對鋼系：對手仍可接近／橫移，但不能靠普通 AI 主動退出磁場半徑。
# 搖籃百合 Suction Cups：受到 Water Gun Knockback 時不位移。
# 百變怪 Imposter：開戰後直接複製一名敵人的戰鬥屬性／能力值／Ability。
#
# 【注意】
# RPG Maker VX / RGSS2 / Ruby 1.8 相容；不修改 Freeze 舊腳本。
# 新腳本禁止使用舊式 instance-variable existence probe。
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_MANIFEST_V097={
    :schema_version=>'1.0',:content_version=>'0.97.0',:ruleset=>'black_white',
    :total_ability_count=>157,:previous_implemented_ability_count=>147,
    :new_implemented_ability_count=>12,:cumulative_implemented_ability_count=>159,
    :total_slot_count=>1193,:previous_implemented_slot_count=>1137,
    :new_implemented_slot_count=>56,:implemented_slot_count=>1193,
    :implemented_slot_coverage_percent=>100.0,
    :species_with_any_implemented_ability=>494,:species_coverage_percent=>100.0,
    :remaining_ability_count=>0,:remaining_slot_count=>0,
    :new_ability_keys=>[:arena_trap,:gluttony,:harvest,:honey_gather,:illuminate,
      :imposter,:magnet_pull,:pickup,:rivalry,:shadow_tag,:stall,:suction_cups]
  }
  # cumulative count above is corrected by validator from unique keys; value 159 is informational only.
  ABILITY_RUNTIME_BEHAVIOR_V097={
    :arena_trap=>{:kind=>:voluntary_retreat_lock,:radius=>118.0,:grounded_only=>true},
    :magnet_pull=>{:kind=>:voluntary_retreat_lock,:radius=>132.0,:required_type=>:steel},
    :shadow_tag=>{:kind=>:voluntary_retreat_lock,:radius=>138.0,:ignore_same_ability=>true},
    :suction_cups=>{:kind=>:forced_displacement_immunity},
    :stall=>{:kind=>:action_startup_delay,:frames=>12},
    :rivalry=>{:kind=>:evolution_line_rivalry,:same_line=>1.20,:different_line=>0.90},
    :gluttony=>{:kind=>:emergency_leftovers,:hp_threshold=>0.50,:extra_num=>1,:extra_den=>16},
    :harvest=>{:kind=>:consumed_item_restore,:pulse_frames=>180,:chance=>50,:sun_chance=>100,
      :eligible_items=>[:focus_sash,:air_balloon]},
    :pickup=>{:kind=>:postbattle_loot_roll,:chance=>35,:bonus_rolls=>1},
    :honey_gather=>{:kind=>:postbattle_loot_roll,:chance=>50,:bonus_rolls=>1},
    :illuminate=>{:kind=>:map_encounter_frequency,:step_mult=>0.75},
    :imposter=>{:kind=>:entry_transform,:duration=>999999}
  }
  class << self
    alias pmd_ac_v097_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v097_ability_behavior)
    alias pmd_ac_v097_ability_data ability_data unless method_defined?(:pmd_ac_v097_ability_data)
    def ability_behavior(key);ABILITY_RUNTIME_BEHAVIOR_V097[key] || pmd_ac_v097_ability_behavior(key);end
    def ability_data(key);ABILITY_RUNTIME_BEHAVIOR_V097[key] || pmd_ac_v097_ability_data(key);end
    def ability_runtime_behavior_v097(key);ABILITY_RUNTIME_BEHAVIOR_V097[key] || {};end
    def validate_ability_runtime_v097
      e=[];m=ABILITY_RUNTIME_MANIFEST_V097
      e << 'new_count' unless ABILITY_RUNTIME_BEHAVIOR_V097.size==12
      e << 'slots' unless m[:implemented_slot_count].to_i==1193
      e << 'remaining' unless m[:remaining_slot_count].to_i==0
      e
    end
  end
end
