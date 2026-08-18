# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Loot / Item Production Content Data v0.98
# 分類：正式掉落／道具內容／區域經濟
#
# 【用途】
# 把 v0.94 已完成的 Weighted Loot Runtime 從「只有測試池」推進成目前 Demo
# Stage / Region / Boss 可實際使用的正式內容。這一版同時定義 8 種有實際用途的
# AutoChess 補給品，避免為了讓 Production Warning 消失而塞入沒有用途的素材垃圾。
#
# 【正式道具 ID】
#  6 林緣傷藥    ：單體場外回復 35% MaxHP（倒下不可用）
#  7 活力種子    ：單體倒下復活至 40% MaxHP
#  8 經驗糖果 S  ：單體 +300 EXP
#  9 經驗糖果 M  ：單體 +900 EXP
# 10 招式心得    ：指定已學招式熟練度 +10
# 11 招式秘典    ：指定已學招式熟練度 +30
# 12 團隊口糧    ：目前三隻隊伍中存活者各回復 25% MaxHP
# 13 蜂王蜜      ：存活者回復 50%；倒下者復活至 25% MaxHP
#
# 【掉落池】
# :forest_supplies_v098       林緣／Stage 1
# :deep_forest_supplies_v098 深林危險區
# :poison_supplies_v098       毒針林／Stage 2
# :thunder_supplies_v098      雷羽坡／Stage 3
# :hive_boss_supplies_v098    大針蜂 Boss
#
# 【Binding 優先權】
# 仍沿用 v0.94：事件 options > Formation > Encounter > Region > Stage。
# v0.98 不修改 v0.94 Runtime，只以新資料表擴充查詢結果。
#
# 【事件／腳本呼叫】
# 查道具：PMD_AC.supply_data_v098(8)
# 查掉落：PMD_AC.loot_pool_v094(:forest_supplies_v098)
# 強制指定：PMD_AC.start_battle_v081(:roadside_pikachu,
#   {:loot_pool=>:thunder_supplies_v098})
#
# 【實際範例】
# 林緣 Wild 戰會自動走 :forest_supplies_v098；若遇 Rare / Elite，v0.94 會自動
# 增加 Roll。Boss Beedrill 走 :hive_boss_supplies_v098，並保留 v0.83 的 300G
# 與 v0.91 首通額外獎勵，Loot 是追加層而不是取代層。
#
# 【可調參數】
# SUPPLY_CATALOG_V098：用途與數值。
# LOOT_POOLS_V098：權重、抽數、稀有條件。
# LOOT_POOL_BINDINGS_V098：Stage / Region / Encounter 綁定。
#
# 【注意】
# - Data/Items.rvdata 的 ID 6～13 必須與本表一致。
# - Item 使用由 v0.98 Runtime API 執行，不走 VX 原生 Item Effect，避免和
#   PMD_PokemonInstance / field_hp_v082 形成兩套 HP。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不修改 Ability 1193/1193、AI、Damage、PMD Motion 或 Multi-hit Freeze。
#==============================================================================
module PMD_AC
  PATCH_VERSION_LOOT_CONTENT_V098='0.98'

  SUPPLY_CATALOG_V098={
    6=>{:key=>:field_potion,:name=>'林緣傷藥',:kind=>:heal_one,:ratio=>0.35},
    7=>{:key=>:revive_seed,:name=>'活力種子',:kind=>:revive_one,:ratio=>0.40},
    8=>{:key=>:exp_candy_s,:name=>'經驗糖果 S',:kind=>:exp_one,:amount=>300},
    9=>{:key=>:exp_candy_m,:name=>'經驗糖果 M',:kind=>:exp_one,:amount=>900},
    10=>{:key=>:mastery_note,:name=>'招式心得',:kind=>:mastery_one,:amount=>10},
    11=>{:key=>:mastery_manual,:name=>'招式秘典',:kind=>:mastery_one,:amount=>30},
    12=>{:key=>:team_ration,:name=>'團隊口糧',:kind=>:heal_party,:ratio=>0.25},
    13=>{:key=>:queen_honey,:name=>'蜂王蜜',:kind=>:honey_party,:heal_ratio=>0.50,:revive_ratio=>0.25}
  }

  LOOT_POOLS_V098={
    :forest_supplies_v098=>{
      :name=>'林緣補給',:base_rolls=>1,:max_rolls=>3,
      :entries=>[
        {:key=>:forest_potion,:weight=>40,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:forest_exp_s,:weight=>30,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:forest_mastery,:weight=>20,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:forest_revive,:weight=>7,:type=>:item,:id=>7,:qty=>1,:chance=>100,:min_rarity=>:rare},
        {:key=>:forest_ration,:weight=>3,:type=>:item,:id=>12,:qty=>1,:chance=>100,:min_rarity=>:rare}
      ]
    },
    :deep_forest_supplies_v098=>{
      :name=>'深林補給',:base_rolls=>2,:max_rolls=>4,
      :entries=>[
        {:key=>:deep_potion,:weight=>28,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:deep_exp_s,:weight=>24,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:deep_mastery,:weight=>20,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:deep_revive,:weight=>14,:type=>:item,:id=>7,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:deep_exp_m,:weight=>9,:type=>:item,:id=>9,:qty=>1,:chance=>100,:min_rarity=>:rare},
        {:key=>:deep_ration,:weight=>5,:type=>:item,:id=>12,:qty=>1,:chance=>100,:min_rarity=>:rare}
      ]
    },
    :poison_supplies_v098=>{
      :name=>'毒針林補給',:base_rolls=>1,:max_rolls=>3,
      :entries=>[
        {:key=>:poison_potion,:weight=>30,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:poison_exp_s,:weight=>25,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:poison_mastery,:weight=>25,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:poison_revive,:weight=>14,:type=>:item,:id=>7,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:poison_exp_m,:weight=>6,:type=>:item,:id=>9,:qty=>1,:chance=>100,:min_rarity=>:rare}
      ]
    },
    :thunder_supplies_v098=>{
      :name=>'雷羽坡補給',:base_rolls=>1,:max_rolls=>3,
      :entries=>[
        {:key=>:thunder_exp_s,:weight=>30,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:thunder_mastery,:weight=>25,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:thunder_potion,:weight=>20,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:thunder_exp_m,:weight=>15,:type=>:item,:id=>9,:qty=>1,:chance=>100,:min_rarity=>:rare},
        {:key=>:thunder_revive,:weight=>10,:type=>:item,:id=>7,:qty=>1,:chance=>100,:min_rarity=>:rare}
      ]
    },
    :hive_boss_supplies_v098=>{
      :name=>'蜂巢戰利品',:base_rolls=>2,:max_rolls=>4,
      :entries=>[
        {:key=>:hive_honey,:weight=>35,:type=>:item,:id=>13,:qty=>1,:chance=>100},
        {:key=>:hive_exp_m,:weight=>30,:type=>:item,:id=>9,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:hive_mastery_manual,:weight=>25,:type=>:item,:id=>11,:qty=>1,:chance=>100,:repeatable=>true},
        {:key=>:hive_revive,:weight=>10,:type=>:item,:id=>7,:qty=>1,:chance=>100,:repeatable=>true}
      ]
    }
  }

  LOOT_POOL_BINDINGS_V098={
    [:stage,1]=>:forest_supplies_v098,
    [:stage,2]=>:poison_supplies_v098,
    [:stage,3]=>:thunder_supplies_v098,
    [:region,:forest_edge]=>:forest_supplies_v098,
    [:region,:deep_forest]=>:deep_forest_supplies_v098,
    [:region,:poison_grove]=>:poison_supplies_v098,
    [:region,:thunder_slope]=>:thunder_supplies_v098,
    [:encounter,:boss_beedrill]=>:hive_boss_supplies_v098
  }

  LOOT_CONTENT_VERIFY_END_V098=38
  LOOT_CONTENT_MANIFEST_V098={
    :version=>'0.98',:catalog_items=>SUPPLY_CATALOG_V098.size,
    :production_pools=>LOOT_POOLS_V098.size,:production_bindings=>LOOT_POOL_BINDINGS_V098.size,
    :item_ids=>SUPPLY_CATALOG_V098.keys.sort,:use_runtime=>true,
    :stage_bindings=>3,:region_bindings=>4,:boss_bindings=>1,
    :content_validator_warning_target=>0,:production_ready_target=>true,
    :ability_slots=>1193,:species=>494
  }

  class << self
    def supply_data_v098(id);SUPPLY_CATALOG_V098[id.to_i];end
    def supply_item_ids_v098;SUPPLY_CATALOG_V098.keys.sort;end
    def loot_pools_v098;LOOT_POOLS_V098;end
    def loot_pool_bindings_v098;LOOT_POOL_BINDINGS_V098;end
    def loot_content_errors_v098
      e=[]
      SUPPLY_CATALOG_V098.each_pair do |id,d|
        e.push('item_'+id.to_s) if $data_items==nil || $data_items[id]==nil
        if $data_items!=nil && $data_items[id]!=nil
          e.push('item_name_'+id.to_s) if $data_items[id].name.to_s!=d[:name].to_s
        end
      end
      LOOT_POOLS_V098.each_pair do |key,p|
        e.push(key.to_s+':entries') if (p[:entries]||[]).empty?
        (p[:entries]||[]).each do |r|
          e.push(key.to_s+':weight') if r[:weight].to_i<=0
          e.push(key.to_s+':item') if r[:type]==:item && SUPPLY_CATALOG_V098[r[:id].to_i]==nil
        end
      end
      LOOT_POOL_BINDINGS_V098.each_pair do |src,key|
        e.push('binding_'+src.inspect) if LOOT_POOLS_V098[key]==nil
      end
      e.uniq
    end
  end
end
