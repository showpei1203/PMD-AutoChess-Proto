# encoding: UTF-8
#==============================================================================
# PMD AutoChess Region Ecology Data v0.86
# 區域生態／固定敵方編成／稀有遭遇／精英額外獎勵設定層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# v0.84 已能設定「敵人等級縮放＋精英率」，但一般 Wild Encounter 仍主要是
# 從 enemy_pool 各自抽 Pokémon。v0.86 再往 RPG 方向增加「區域生態」：
# 你可以直接定義一組完整敵方隊伍，並用權重決定哪一組較常／較少出現。
#
# 最常修改的只有兩張表：
#   1. ENCOUNTER_FORMATIONS_V086：一場戰鬥的敵方組合。
#   2. REGION_ECOLOGY_PROFILES_V086：某個區域會抽哪些組合、難度與額外獎勵。
#
#-----------------------------------------------------------------------------
# 【A. Formation：一場完整敵方編成】
# 每個 Formation 可設定：
#   :name    => 顯示名稱
#   :rarity  => :common / :uncommon / :rare / :very_rare
#   :members => 敵方 Pokémon 陣列
#
# member 可用欄位：
#   :species => :pikachu
#   :level   => 15               # 基礎 Lv；仍可被 v0.84 Scaling 重算
#   :cell    => [5,2]            # 可省略，Runtime 會依順序配置
#   :mods    => {...}            # v0.81/v0.84 敵人 Mods
#
# 範例：
#   :my_rare_group=>{
#     :name=>'雷光群', :rarity=>:rare,
#     :members=>[
#       {:species=>:pikachu,:level=>16},
#       {:species=>:pidgey,:level=>15},
#       {:species=>:rattata,:level=>15}
#     ],
#     :bonus_rewards=>[{:type=>:gold,:amount=>30}]
#   }
#
#-----------------------------------------------------------------------------
# 【B. Region：一個 RPG 區域的生態】
# 每個 Region 可設定：
#   :name             => 區域名稱
#   :base_profile     => 引用 v0.84 ENCOUNTER_PROFILES_V084
#   :difficulty       => 1..5，現在主要供 UI／資料管理，不直接偷乘傷害
#   :presentation     => v0.85 Battle Presentation Profile
#   :recruit_rate     => 此區域招募率；省略則沿用原 Encounter
#   :formations       => Formation 權重表
#   :rare_bonus_rewards  => 抽到 rare / very_rare 時的額外獎勵
#   :elite_bonus_rewards => 勝利時每隻精英提供的額外獎勵
#
# Formation 權重：
#   {:formation=>:forest_mixed,:weight=>60}
#   {:formation=>:forest_pikachu_rare,:weight=>5}
#
# weight 是相對權重，不需要加總 100。
# 例如 60 / 25 / 10 / 5，最後就是 60% / 25% / 10% / 5%。
#
#-----------------------------------------------------------------------------
# 【C. 事件直接進入某區域戰鬥】
#   PMD_AC.start_region_battle_v086(:forest_edge)
#
# 強制指定某個 Formation：
#   PMD_AC.start_region_battle_v086(:forest_edge, {
#     :formation=>:forest_pikachu_rare
#   })
#
# 臨時加難度／精英率／背景 BGM 仍沿用舊 API：
#   PMD_AC.start_region_battle_v086(:forest_edge, {
#     :level_offset=>2,
#     :elite_rate=>25,
#     :presentation=>:story_demo
#   })
#
#-----------------------------------------------------------------------------
# 【D. 地圖野外 Encounter】
# 在目前地圖開啟：
#   PMD_AC.wild_region_on_v086(:forest_edge, 10, 18)
#
# 只允許 Terrain Tag 1、2：
#   PMD_AC.wild_region_on_v086(:forest_edge, 10, 18, [1,2])
#
# 指定 Map ID：
#   PMD_AC.wild_region_on_v086(:forest_edge, 10, 18, [1], 12)
#
# 關閉仍使用既有：
#   PMD_AC.wild_off_v081
#
# 也可以直接在 MAP_REGION_DEFAULTS_V086 寫 Map ID，正式專案最方便。
# 測試專案保持空白，避免驗證時亂入野怪。
#
#-----------------------------------------------------------------------------
# 【E. 稀有與精英是兩件事】
# 稀有：Formation 的 rarity == :rare / :very_rare。
# 精英：v0.84 隨機把單隻敵人套 Elite Profile。
#
# 因此可能出現：
#   一般 Encounter + 1 隻精英
#   稀有 Encounter + 0 隻精英
#   稀有 Encounter + 1 隻精英
#
# 稀有／精英倍率都只存在敵方 Runtime；招募進 BOX 後仍是正常 Pokémon 個體。
#
#-----------------------------------------------------------------------------
# 【F. 額外獎勵】
# 使用 v0.83 Reward Row 格式，例如：
#   {:type=>:gold,:amount=>20}
#   {:type=>:item,:id=>5,:qty=>1,:chance=>25}
#
# :rare_bonus_rewards：稀有 Encounter 勝利額外給一次。
# :elite_bonus_rewards：依精英數量給；若 row 寫 :per_elite=>true，amount 會乘精英數。
#
# 例如：
#   :elite_bonus_rewards=>[
#     {:type=>:gold,:amount=>15,:per_elite=>true}
#   ]
# 這場打倒 2 隻精英，就會額外得到 30G。
#
#-----------------------------------------------------------------------------
# 【G. 維護規則】
# - 一般新增地區／改生態，只改本 Data 腳本。
# - v0.84 Scaling／Elite、v0.85 Battleback/BGM、v0.83 Loot 直接沿用，不另造系統。
# - Boss 不走 Region Elite；Boss 仍使用 v0.81 的 :stat_mult / :phases / :mechanic。
# - instance_uid 才是玩家 Pokémon 個體身份。
# - 往後新增 PMD AutoChess 腳本，開頭必須保留完整中文說明與實際範例。
#==============================================================================
module PMD_AC
  FORMATION_RARITY_LABELS_V086 = {
    :common=>'一般',
    :uncommon=>'少見',
    :rare=>'稀有',
    :very_rare=>'極稀有'
  }

  ENCOUNTER_FORMATIONS_V086 = {
    :forest_mixed=>{
      :name=>'林緣混生群',:rarity=>:common,
      :members=>[
        {:species=>:caterpie,:level=>12},
        {:species=>:rattata,:level=>12},
        {:species=>:pidgey,:level=>12}
      ]
    },
    :forest_bird_pack=>{
      :name=>'林間鳥群',:rarity=>:uncommon,
      :members=>[
        {:species=>:pidgey,:level=>12},
        {:species=>:pidgey,:level=>13},
        {:species=>:rattata,:level=>12}
      ]
    },
    :forest_bug_pack=>{
      :name=>'蟲群',:rarity=>:uncommon,
      :members=>[
        {:species=>:caterpie,:level=>12},
        {:species=>:weedle,:level=>12},
        {:species=>:kakuna,:level=>13}
      ]
    },
    :forest_pikachu_rare=>{
      :name=>'雷光林群',:rarity=>:rare,
      :members=>[
        {:species=>:pikachu,:level=>14},
        {:species=>:pidgey,:level=>13},
        {:species=>:rattata,:level=>13}
      ],
      :bonus_rewards=>[
        {:type=>:gold,:amount=>25,:chance=>100}
      ]
    },
    :poison_grove_swarm=>{
      :name=>'毒針蟲群',:rarity=>:common,
      :members=>[
        {:species=>:weedle,:level=>14},
        {:species=>:kakuna,:level=>14},
        {:species=>:weedle,:level=>14}
      ]
    },
    :poison_grove_beedrill=>{
      :name=>'大針蜂巡獵群',:rarity=>:rare,
      :members=>[
        {:species=>:weedle,:level=>15},
        {:species=>:beedrill,:level=>16},
        {:species=>:kakuna,:level=>15}
      ],
      :bonus_rewards=>[
        {:type=>:gold,:amount=>35,:chance=>100}
      ]
    },
    :thunder_slope_mix=>{
      :name=>'雷羽坡群',:rarity=>:common,
      :members=>[
        {:species=>:spearow,:level=>16},
        {:species=>:ekans,:level=>16},
        {:species=>:pikachu,:level=>16}
      ]
    },
    :thunder_slope_pikachu=>{
      :name=>'皮卡丘群',:rarity=>:very_rare,
      :members=>[
        {:species=>:pikachu,:level=>17},
        {:species=>:pikachu,:level=>17},
        {:species=>:spearow,:level=>16}
      ],
      :bonus_rewards=>[
        {:type=>:gold,:amount=>50,:chance=>100}
      ]
    }
  }

  REGION_ECOLOGY_PROFILES_V086 = {
    :forest_edge=>{
      :name=>'林緣',
      :base_profile=>:forest_adaptive,
      :difficulty=>1,
      :presentation=>:forest_demo,
      :recruit_rate=>30,
      :formations=>[
        {:formation=>:forest_mixed,:weight=>60},
        {:formation=>:forest_bird_pack,:weight=>22},
        {:formation=>:forest_bug_pack,:weight=>13},
        {:formation=>:forest_pikachu_rare,:weight=>5}
      ],
      :rare_bonus_rewards=>[
        {:type=>:gold,:amount=>15,:chance=>100}
      ],
      :elite_bonus_rewards=>[
        {:type=>:gold,:amount=>15,:chance=>100,:per_elite=>true}
      ]
    },
    :deep_forest=>{
      :name=>'深林危險區',
      :base_profile=>:forest_danger,
      :difficulty=>3,
      :presentation=>:forest_demo,
      :recruit_rate=>32,
      :formations=>[
        {:formation=>:forest_mixed,:weight=>40},
        {:formation=>:forest_bug_pack,:weight=>30},
        {:formation=>:forest_bird_pack,:weight=>20},
        {:formation=>:forest_pikachu_rare,:weight=>10}
      ],
      :rare_bonus_rewards=>[
        {:type=>:gold,:amount=>25,:chance=>100}
      ],
      :elite_bonus_rewards=>[
        {:type=>:gold,:amount=>20,:chance=>100,:per_elite=>true}
      ]
    },
    :poison_grove=>{
      :name=>'毒針林',
      :base_profile=>:forest_danger,
      :difficulty=>2,
      :presentation=>:forest_demo,
      :recruit_rate=>28,
      :formations=>[
        {:formation=>:poison_grove_swarm,:weight=>82},
        {:formation=>:poison_grove_beedrill,:weight=>18}
      ],
      :rare_bonus_rewards=>[
        {:type=>:gold,:amount=>20,:chance=>100}
      ],
      :elite_bonus_rewards=>[
        {:type=>:gold,:amount=>18,:chance=>100,:per_elite=>true}
      ]
    },
    :thunder_slope=>{
      :name=>'雷羽坡',
      :base_profile=>:forest_danger,
      :difficulty=>3,
      :presentation=>:story_demo,
      :recruit_rate=>25,
      :formations=>[
        {:formation=>:thunder_slope_mix,:weight=>92},
        {:formation=>:thunder_slope_pikachu,:weight=>8}
      ],
      :rare_bonus_rewards=>[
        {:type=>:gold,:amount=>30,:chance=>100}
      ],
      :elite_bonus_rewards=>[
        {:type=>:gold,:amount=>22,:chance=>100,:per_elite=>true}
      ]
    }
  }

  # 正式專案可以直接填：
  #   12=>{:region=>:forest_edge,:min_steps=>10,:max_steps=>18,:terrain_tags=>[1]},
  #   18=>{:region=>:poison_grove,:min_steps=>8,:max_steps=>14,:terrain_tags=>[1,2]}
  MAP_REGION_DEFAULTS_V086 = {
  }

  REGION_ECOLOGY_VERIFY_END_V086 = 24
  REGION_ECOLOGY_MANIFEST_V086 = {
    :schema_version=>'1.0',
    :content_version=>'0.86.0',
    :formations=>ENCOUNTER_FORMATIONS_V086.size,
    :regions=>REGION_ECOLOGY_PROFILES_V086.size,
    :rarities=>FORMATION_RARITY_LABELS_V086.size,
    :elite_reward=>true,
    :rare_reward=>true,
    :recruit_keeps_runtime_mods=>false,
    :scaling=>'v0.84',
    :presentation=>'v0.85',
    :reward=>'v0.83',
    :runtime_checksum32=>860860317
  }

  class << self
    def formation_data_v086(key)
      ENCOUNTER_FORMATIONS_V086[key]
    end

    def region_data_v086(key)
      REGION_ECOLOGY_PROFILES_V086[key]
    end

    def formation_rarity_v086(key)
      d=formation_data_v086(key)
      d==nil ? :common : (d[:rarity]||:common)
    end

    def formation_rare_v086?(key)
      r=formation_rarity_v086(key)
      r==:rare || r==:very_rare
    end

    def formation_rarity_label_v086(key)
      FORMATION_RARITY_LABELS_V086[formation_rarity_v086(key)] || '一般'
    end

    def weighted_formation_pick_v086(region_key,roll=nil)
      d=region_data_v086(region_key)
      return nil if d==nil
      rows=d[:formations] || []
      return nil if rows.empty?
      total=0
      rows.each{|row|total += [(row[:weight]||1).to_i,1].max}
      r=roll==nil ? rand(total) : roll.to_i%total
      acc=0
      rows.each do |row|
        acc += [(row[:weight]||1).to_i,1].max
        return row[:formation] if r<acc
      end
      rows[-1][:formation]
    end

    def copy_enemy_mods_v086(mods)
      return {} unless mods.is_a?(Hash)
      out=mods.dup
      out[:stat_mult]=mods[:stat_mult].dup if mods[:stat_mult].is_a?(Hash)
      out[:active_moves]=mods[:active_moves].dup if mods[:active_moves].is_a?(Array)
      out
    end

    def build_formation_setup_v086(formation_key)
      d=formation_data_v086(formation_key)
      return [] if d==nil
      pos=[[4,1],[5,2],[5,3],[4,2],[5,1],[4,3]]
      out=[]
      members=d[:members] || []
      members.each_with_index do |m,i|
        cell=m[:cell]
        cell=pos[i%pos.size] if cell==nil
        out.push([m[:species],cell[0].to_i,cell[1].to_i,
          [(m[:level]||1).to_i,1].max,copy_enemy_mods_v086(m[:mods])])
      end
      out
    end

    def region_config_errors_v086
      e=[]
      REGION_ECOLOGY_PROFILES_V086.each do |key,d|
        bp=d[:base_profile]
        if !defined?(ENCOUNTER_PROFILES_V084) || ENCOUNTER_PROFILES_V084[bp]==nil
          e.push(key.to_s+':base_profile')
        end
        rows=d[:formations] || []
        e.push(key.to_s+':formations_empty') if rows.empty?
        rows.each do |row|
          fk=row[:formation]
          e.push(key.to_s+':formation_'+fk.to_s) if ENCOUNTER_FORMATIONS_V086[fk]==nil
        end
      end
      ENCOUNTER_FORMATIONS_V086.each do |key,d|
        e.push(key.to_s+':members_empty') if (d[:members]||[]).empty?
        r=d[:rarity]||:common
        e.push(key.to_s+':rarity') unless FORMATION_RARITY_LABELS_V086.has_key?(r)
        (d[:members]||[]).each do |m|
          if respond_to?(:species_identity_data)
            e.push(key.to_s+':species_'+m[:species].to_s) if species_identity_data(m[:species])==nil
          end
        end
      end
      e.uniq
    end

    def region_bonus_rules_v086(request,elite_count=0)
      out=[]
      return out if request==nil
      region=region_data_v086(request[:region_v086])
      return out if region==nil
      if request[:rare_v086]
        rows=(region[:rare_bonus_rewards]||[]).dup
        fd=formation_data_v086(request[:formation_v086])
        rows += (fd[:bonus_rewards]||[]) if fd!=nil
        rows.each{|r|out.push([:rare,r])}
      end
      if elite_count.to_i>0
        (region[:elite_bonus_rewards]||[]).each do |row|
          x=row.dup
          if x[:per_elite]
            if x.has_key?(:amount)
              x[:amount]=x[:amount].to_i*elite_count.to_i
            elsif x.has_key?(:min) || x.has_key?(:max)
              x[:min]=(x[:min]||0).to_i*elite_count.to_i
              x[:max]=(x[:max]||x[:min]).to_i*elite_count.to_i
            end
          end
          x.delete(:per_elite)
          out.push([:elite,x])
        end
      end
      out
    end

    def apply_region_bonus_rewards_v086(request,elite_count=0,dry_run=false,rolls=nil)
      rules=region_bonus_rules_v086(request,elite_count)
      results=[]
      rules.each_with_index do |pair,i|
        kind=pair[0];row=pair[1]
        roll=rolls==nil ? nil : rolls[i]
        r=apply_reward_row_v083(row,dry_run,roll,i)
        next unless r[:granted]
        prefix=kind==:elite ? '精英獎勵 ' : '稀有獎勵 '
        r[:region_bonus_kind_v086]=kind
        r[:label]=prefix+r[:label].to_s
        results.push(r)
      end
      results
    end
  end
end
