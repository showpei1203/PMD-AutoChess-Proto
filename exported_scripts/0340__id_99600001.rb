# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Data v0.96
# 分類：特性 Ability／Generation V Runtime Completion V
#
# 【用途】
# 延續 v0.24～v0.67.1 的特性系統，補上 12 種仍為 data-only 的 Ability，
# 讓 #0001～#0494 每個 Species 至少都有一個真正可運作的 Ability Runtime。
# 本腳本只定義資料與規則；實際執行在下一支 Runtime v0.96。
#
# 【本版新增 Ability】
# Pressure / Natural Cure / Regenerator / Trace / Unnerve / Mold Breaker /
# Magic Bounce / Analytic / Cute Charm / Healer / Run Away / Multitype
#
# 【AutoChess 轉譯規則】
# - Pressure：沒有 PP，因此改成「敵方技能鎖定持有者後，施術者累積 20 Energy Recharge Debt」。
#   後續 Energy Gain 會先償還 Debt，再真正增加能量；最多堆 60。
# - Natural Cure：沒有傳統換人，改為負面主要狀態持續 120f 後自動清除一項。
# - Regenerator：沒有傳統換人，改為脫離敵方 150px 以上並維持安全時，每 180f 回復 1/6 MaxHP。
# - Trace：開戰時複製一名存活敵人的 Ability，維持到本場戰鬥結束。
# - Unnerve：目前沒有 Berry Catalog，因此改為壓低敵方「普攻命中／受傷」兩種被動 Energy Gain 25%。
#   時間自然回能與技能專用回能不受影響。
# - Mold Breaker：傷害與敵方狀態效果結算期間暫時忽略目標 Ability；既有 Sturdy bypass 也保留。
# - Magic Bounce：反射可針對單一敵人的純狀態技能；Field／Weather／自我技不反射。
# - Analytic：若目標比自己更晚完成上一個 Action，該次直接傷害 ×1.30。
# - Cute Charm：沿用本專案 Attract 的「無性別化迷人」規則；被接觸命中時 30% 使攻擊者迷人 180f。
# - Healer：每 120f 檢查一次，30% 機率替一名隊友清除一項主要狀態。
# - Run Away：對 Root／Bind／Fire Trap 等移動束縛免疫，Mean Look 亦不構成移動鎖定。
# - Multitype：Arceus 的戰鬥型態不可被 Soak／Color Change 等臨時改變。
#
# 【主要設定項】
# - ABILITY_RUNTIME_MANIFEST_V096：覆蓋率與版本資訊。
# - ABILITY_RUNTIME_BEHAVIOR_V096：12 種 Ability 的可調參數。
#
# 【可調參數範例】
# Pressure：:debt=>20, :debt_cap=>60
# Regenerator：:safe_distance=>150.0, :pulse_frames=>180, :heal_num=>1, :heal_den=>6
# Natural Cure：:delay_frames=>120
# Cute Charm：:chance=>30, :duration=>180
# Healer：:chance=>30, :pulse_frames=>120
#
# 【事件／腳本呼叫】
# 一般遊戲不需要事件呼叫；Ability 由 Pokémon Instance 的 ability_slot 自動決定。
# Debug 可查：
#   PMD_AC.ability_runtime_behavior_v096(:pressure)
#   PMD_AC::ABILITY_RUNTIME_MANIFEST_V096[:implemented_slot_count]
#
# 【實際範例】
# Deoxys（Pressure）被敵方技能鎖定：
#   敵方技能正常施放，但施術者下一輪回能會先扣除 20 的 Pressure Debt。
# Celebi（Natural Cure）中毒：
#   持續 120f 後自動移除 Poison，並顯示特性提示。
# Arceus（Multitype）被 Soak：
#   類型改寫被拒絕，維持目前 Arceus 型態。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不使用舊式 instance-variable reflection probe。
# - 不修改舊 v0.24～v0.67.1 腳本；本版 additive override 插在 Main 前。
# - v0.60.2 Multi-hit、v0.62 Native Router、v0.91.4 Tactical Passive 均不改。
# - Rivalry 因專案尚無性別資料，本版刻意不做，留給下一輪正規處理。
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_MANIFEST_V096 = {
    :schema_version=>'1.0',:content_version=>'0.96.0',:canon_snapshot=>'2026-08-10',
    :ruleset=>'black_white',:target_generation=>5,:total_slot_count=>1193,
    :previous_implemented_ability_count=>135,:new_implemented_ability_count=>12,
    :cumulative_implemented_ability_count=>147,
    :previous_implemented_slot_count=>1028,:new_implemented_slot_count=>109,
    :implemented_slot_count=>1137,:implemented_slot_coverage_percent=>95.31,
    :previous_species_with_any_implemented_ability=>483,
    :new_species_with_any_implemented_ability=>11,
    :species_with_any_implemented_ability=>494,:species_coverage_percent=>100.0,
    :new_ability_keys=>[:pressure,:natural_cure,:regenerator,:trace,:unnerve,
      :mold_breaker,:magic_bounce,:analytic,:cute_charm,:healer,:run_away,:multitype],
    :remaining_ability_count=>12,:remaining_slot_count=>56,
    :runtime_checksum32=>1785501047,
    :notes=>[
      'Species runtime coverage reaches 494/494 without inventing a fake gender system for Rivalry.',
      'Switch/PP/Berry dependent abilities are translated onto existing realtime Energy, spatial and status systems.',
      'Cute Charm intentionally reuses the project genderless Attract adaptation already established in v0.58.',
      'Mold Breaker uses a temporary target-ability suppression scope around damage/status resolution; old scripts stay untouched.',
      'Loot/item catalog remains a separate production-content gap.'
    ]
  }

  ABILITY_RUNTIME_BEHAVIOR_V096 = {
    :pressure=>{:ability_key=>:pressure,:kind=>:skill_recharge_pressure,
      :behavior_status=>:implemented_ability_v096,:debt=>20,:debt_cap=>60},
    :natural_cure=>{:ability_key=>:natural_cure,:kind=>:delayed_major_status_cure,
      :behavior_status=>:implemented_ability_v096,:delay_frames=>120,
      :statuses=>[:poison,:burn,:paralysis,:sleep,:freeze]},
    :regenerator=>{:ability_key=>:regenerator,:kind=>:safe_disengage_regen,
      :behavior_status=>:implemented_ability_v096,:safe_distance=>150.0,
      :pulse_frames=>180,:heal_num=>1,:heal_den=>6},
    :trace=>{:ability_key=>:trace,:kind=>:entry_copy_opponent_ability,
      :behavior_status=>:implemented_ability_v096,:duration=>999999,
      :exclude=>[:trace,:multitype]},
    :unnerve=>{:ability_key=>:unnerve,:kind=>:enemy_passive_energy_suppression,
      :behavior_status=>:implemented_ability_v096,:num=>3,:den=>4,
      :reasons=>[:basic_hit,:damage_taken]},
    :mold_breaker=>{:ability_key=>:mold_breaker,:kind=>:target_ability_bypass,
      :behavior_status=>:implemented_ability_v096,:damage=>true,:status=>true},
    :magic_bounce=>{:ability_key=>:magic_bounce,:kind=>:enemy_status_reflect,
      :behavior_status=>:implemented_ability_v096,:single_target_only=>true,
      :status_only=>true},
    :analytic=>{:ability_key=>:analytic,:kind=>:late_action_damage_multiplier,
      :behavior_status=>:implemented_ability_v096,:num=>13,:den=>10},
    :cute_charm=>{:ability_key=>:cute_charm,:kind=>:contact_infatuation,
      :behavior_status=>:implemented_ability_v096,:chance=>30,:duration=>180,
      :gender_rule=>:project_genderless_v058},
    :healer=>{:ability_key=>:healer,:kind=>:ally_major_status_cure,
      :behavior_status=>:implemented_ability_v096,:chance=>30,:pulse_frames=>120,
      :statuses=>[:poison,:burn,:paralysis,:sleep,:freeze]},
    :run_away=>{:ability_key=>:run_away,:kind=>:movement_trap_immunity,
      :behavior_status=>:implemented_ability_v096,
      :blocked_statuses=>[:root,:bound_v052,:fire_trap_v051]},
    :multitype=>{:ability_key=>:multitype,:kind=>:type_change_immunity,
      :behavior_status=>:implemented_ability_v096,:species=>:arceus}
  }

  class << self
    alias pmd_ac_v096_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v096_ability_behavior)
    alias pmd_ac_v096_ability_data ability_data unless method_defined?(:pmd_ac_v096_ability_data)
    def ability_behavior(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V096[key]
      return b unless b==nil
      pmd_ac_v096_ability_behavior(key)
    end
    def ability_data(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V096[key]
      return b unless b==nil
      pmd_ac_v096_ability_data(key)
    end

    def ability_runtime_behavior_v096(key)
      ABILITY_RUNTIME_BEHAVIOR_V096[key] || {}
    end

    def ability_runtime_scalar_v096(x)
      return '' if x==nil
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+ability_runtime_scalar_v096(x[k])}.join(',')
      end
      return x.collect{|v|ability_runtime_scalar_v096(v)}.join(',') if x.is_a?(Array)
      x.to_s
    end

    def ability_runtime_checksum32_v096
      h=0
      ABILITY_RUNTIME_BEHAVIOR_V096.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        text=k.to_s+'|'+ability_runtime_scalar_v096(ABILITY_RUNTIME_BEHAVIOR_V096[k])
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end

    def validate_ability_runtime_v096
      e=[];m=ABILITY_RUNTIME_MANIFEST_V096
      e.push('new_count') unless ABILITY_RUNTIME_BEHAVIOR_V096.size==12
      e.push('ability_count') unless m[:cumulative_implemented_ability_count].to_i==147
      e.push('slots') unless m[:implemented_slot_count].to_i==1137 && m[:total_slot_count].to_i==1193
      e.push('species') unless m[:species_with_any_implemented_ability].to_i==494
      e.push('remaining') unless m[:remaining_ability_count].to_i==12 && m[:remaining_slot_count].to_i==56
      e.push('checksum') unless ability_runtime_checksum32_v096==m[:runtime_checksum32].to_i
      e
    end
  end
end
