#==============================================================================
# PMD AutoChess Reward / Loot Data v0.83
#==============================================================================
# 【中文使用說明】
# 本腳本負責「戰鬥勝利後，除了 EXP／技能熟練／招募之外還能得到什麼」。
# 它不改傷害、AI、招募、進化或既有 v0.79 Reward Loop，只新增 RPG 獎勵層。
#
# -----------------------------------------------------------------------------
# 一、可以發哪些獎勵？
# -----------------------------------------------------------------------------
# :gold         VX 原生金錢
# :item         資料庫 Item
# :weapon       資料庫 Weapon
# :armor        資料庫 Armor
# :variable     增加指定遊戲變數
# :switch       設定指定遊戲開關
# :common_event 預約公用事件
#
# -----------------------------------------------------------------------------
# 二、Reward Table 格式
# -----------------------------------------------------------------------------
# REWARD_TABLES_V083 = {
#   :my_battle => {
#     :first_clear => [ ...首次勝利... ],
#     :repeat      => [ ...重複勝利... ],
#     :win         => [ ...沒有首通概念時使用... ]
#   }
# }
#
# 每一筆獎勵是一個 Hash：
#   {:type=>:gold, :min=>100, :max=>150, :chance=>100}
#   {:type=>:item, :id=>5, :qty=>2, :chance=>35}
#   {:type=>:weapon, :id=>3, :qty=>1, :chance=>10}
#   {:type=>:armor, :id=>8, :qty=>1, :chance=>10}
#   {:type=>:variable, :id=>21, :amount=>3, :chance=>100}
#   {:type=>:switch, :id=>40, :value=>true, :chance=>100}
#   {:type=>:common_event, :id=>12, :chance=>100}
#
# chance = 0..100。省略時視為 100%。
# Gold 可用 :amount 固定值，也可用 :min / :max 做區間。
# Item / Weapon / Armor 使用資料庫 ID；若該 ID 不存在會安全略過並留下 LOG。
#
# -----------------------------------------------------------------------------
# 三、Stage 要怎麼指定獎勵表？
# -----------------------------------------------------------------------------
# STAGE_REWARD_TABLE_V083 = {
#   1=>:stage_1,
#   2=>:stage_2,
#   3=>:stage_3
# }
#
# 目前測試三關只發 VX Gold，方便直接看到 RPG Reward Loop；你可自行換掉。
#
# -----------------------------------------------------------------------------
# 四、Wild / Boss / Scripted 怎麼指定？
# -----------------------------------------------------------------------------
# ENCOUNTER_REWARD_TABLE_V083 依 v0.81 Encounter key 對應：
#   :forest_wild      => :forest_wild
#   :roadside_pikachu => :roadside_pikachu
#   :boss_beedrill    => :boss_beedrill
#
# 事件呼叫時也可以覆蓋：
#   PMD_AC.start_battle_v081(:roadside_pikachu,
#     {:reward_table=>:my_battle})
#
# 自訂戰鬥：
#   PMD_AC.start_custom_battle_v082('伏擊', [[:rattata,15]],
#     {:reward_table=>:my_battle})
#
# 如果某場完全不要 Loot：
#   {:reward_table=>false}
#
# -----------------------------------------------------------------------------
# 五、直接在單一戰鬥塞臨時獎勵（不用建立 Reward Table）
# -----------------------------------------------------------------------------
#   PMD_AC.start_custom_battle_v082('寶箱怪', [[:voltorb,20]], {
#     :rewards=>[
#       {:type=>:gold,:amount=>250},
#       {:type=>:item,:id=>7,:qty=>1}
#     ]
#   })
#
# -----------------------------------------------------------------------------
# 六、Boss 與招募
# -----------------------------------------------------------------------------
# Boss 依舊「強制不可招募」，但可以正常給 Gold／物品／開關／公用事件獎勵。
# 招募規則與 Loot 是兩套獨立系統，不要把「可否招募」拿來當掉寶開關。
#==============================================================================
module PMD_AC
  REWARD_TABLES_V083 = {
    :stage_1=>{
      :first_clear=>[
        {:type=>:gold,:amount=>100,:chance=>100}
      ],
      :repeat=>[
        {:type=>:gold,:amount=>35,:chance=>100}
      ]
    },
    :stage_2=>{
      :first_clear=>[
        {:type=>:gold,:amount=>160,:chance=>100}
      ],
      :repeat=>[
        {:type=>:gold,:amount=>55,:chance=>100}
      ]
    },
    :stage_3=>{
      :first_clear=>[
        {:type=>:gold,:amount=>240,:chance=>100}
      ],
      :repeat=>[
        {:type=>:gold,:amount=>80,:chance=>100}
      ]
    },
    :forest_wild=>{
      :win=>[
        {:type=>:gold,:min=>8,:max=>15,:chance=>100}
      ]
    },
    :roadside_pikachu=>{
      :win=>[
        {:type=>:gold,:amount=>40,:chance=>100}
      ]
    },
    :boss_beedrill=>{
      :win=>[
        {:type=>:gold,:amount=>300,:chance=>100}
      ]
    }
  }

  STAGE_REWARD_TABLE_V083 = {
    1=>:stage_1,
    2=>:stage_2,
    3=>:stage_3
  }

  ENCOUNTER_REWARD_TABLE_V083 = {
    :forest_wild=>:forest_wild,
    :roadside_pikachu=>:roadside_pikachu,
    :boss_beedrill=>:boss_beedrill
  }

  REWARD_RESULT_H_V083 = 318
  REWARD_LOOT_Y_V083 = 261
  REWARD_LOOT_H_V083 = 28
  REWARD_VERIFY_END_V083 = 24

  REWARD_LOOT_MANIFEST_V083 = {
    :version=>'0.83',
    :types=>[:gold,:item,:weapon,:armor,:variable,:switch,:common_event],
    :stage_tables=>STAGE_REWARD_TABLE_V083.size,
    :encounter_tables=>ENCOUNTER_REWARD_TABLE_V083.size,
    :inline_rewards=>true,
    :boss_reward=>true,
    :boss_recruitable=>false
  }

  def self.reward_table_key_v083(request,stage_id=nil)
    return nil if request!=nil && request[:options]!=nil && request[:options].has_key?(:reward_table) && request[:options][:reward_table]==false
    if request!=nil && request[:options]!=nil && request[:options][:reward_table]!=nil
      return request[:options][:reward_table]
    end
    if request!=nil && request[:kind]==:stage
      sid=request[:stage_id] || stage_id
      return STAGE_REWARD_TABLE_V083[sid.to_i]
    end
    if request!=nil
      return ENCOUNTER_REWARD_TABLE_V083[request[:key]]
    end
    return STAGE_REWARD_TABLE_V083[stage_id.to_i] if stage_id!=nil
    nil
  end

  def self.inline_reward_rules_v083(request)
    return nil if request==nil || request[:options]==nil
    rows=request[:options][:rewards]
    return nil if rows==nil
    rows.is_a?(Array) ? rows : [rows]
  end

  def self.reward_rules_v083(table_key,first_clear=false)
    t=REWARD_TABLES_V083[table_key]
    return [] if t==nil
    if first_clear && t[:first_clear]!=nil
      return t[:first_clear]
    end
    if !first_clear && t[:repeat]!=nil
      return t[:repeat]
    end
    t[:win] || []
  end

  def self.reward_amount_v083(row,random_value=nil)
    return 0 if row==nil
    return row[:amount].to_i if row.has_key?(:amount)
    mn=(row[:min]||0).to_i
    mx=(row[:max]||mn).to_i
    mx=mn if mx<mn
    return mn if mx==mn
    rv=random_value==nil ? rand(mx-mn+1) : random_value.to_i%(mx-mn+1)
    mn+rv
  end

  def self.reward_chance_pass_v083(row,roll=nil)
    chance=[[((row[:chance]||100).to_i),0].max,100].min
    r=roll==nil ? rand(100) : roll.to_i%100
    r<chance
  end

  def self.reward_database_object_v083(type,id)
    case type
    when :item
      return nil if $data_items==nil
      $data_items[id.to_i]
    when :weapon
      return nil if $data_weapons==nil
      $data_weapons[id.to_i]
    when :armor
      return nil if $data_armors==nil
      $data_armors[id.to_i]
    end
    nil
  end

  def self.reward_label_v083(result)
    return '' if result==nil
    type=result[:type]
    case type
    when :gold
      return result[:amount].to_i.to_s+'G'
    when :item,:weapon,:armor
      obj=reward_database_object_v083(type,result[:id])
      name=obj==nil ? (type.to_s+'#'+result[:id].to_i.to_s) : obj.name.to_s
      return name+'×'+result[:amount].to_i.to_s
    when :variable
      return '變數'+result[:id].to_i.to_s+' +'+result[:amount].to_i.to_s
    when :switch
      return '開關'+result[:id].to_i.to_s+'='+(result[:value] ? 'ON':'OFF')
    when :common_event
      return '公用事件'+result[:id].to_i.to_s
    end
    type.to_s
  end

  def self.apply_reward_row_v083(row,dry_run=false,roll=nil,amount_roll=nil)
    return {:granted=>false,:reason=>:nil} if row==nil
    type=(row[:type]||:none).to_sym
    unless REWARD_LOOT_MANIFEST_V083[:types].include?(type)
      return {:granted=>false,:reason=>:unknown_type,:type=>type}
    end
    unless reward_chance_pass_v083(row,roll)
      return {:granted=>false,:reason=>:chance,:type=>type}
    end
    result={:granted=>true,:type=>type}
    case type
    when :gold
      n=reward_amount_v083(row,amount_roll)
      result[:amount]=n
      $game_party.gain_gold(n) if !dry_run && $game_party!=nil && $game_party.respond_to?(:gain_gold)
    when :item,:weapon,:armor
      id=row[:id].to_i
      qty=[(row[:qty]||1).to_i,1].max
      obj=reward_database_object_v083(type,id)
      if obj==nil && !dry_run
        return {:granted=>false,:reason=>:missing_database,:type=>type,:id=>id}
      end
      result[:id]=id; result[:amount]=qty
      $game_party.gain_item(obj,qty) if !dry_run && $game_party!=nil && obj!=nil && $game_party.respond_to?(:gain_item)
    when :variable
      id=row[:id].to_i; n=(row[:amount]||1).to_i
      result[:id]=id;result[:amount]=n
      $game_variables[id]=$game_variables[id].to_i+n if !dry_run && $game_variables!=nil && id>0
    when :switch
      id=row[:id].to_i; val=row.has_key?(:value) ? (row[:value] ? true:false) : true
      result[:id]=id;result[:value]=val
      $game_switches[id]=val if !dry_run && $game_switches!=nil && id>0
    when :common_event
      id=row[:id].to_i; result[:id]=id
      if !dry_run && $game_temp!=nil && id>0
        if $game_temp.common_event_id.to_i>0
          return {:granted=>false,:reason=>:common_event_busy,:type=>type,:id=>id}
        end
        $game_temp.common_event_id=id
      end
    end
    result[:label]=reward_label_v083(result)
    result
  end

  def self.resolve_rewards_v083(request,stage_id=nil,first_clear=false,dry_run=false,rolls=nil)
    rules=inline_reward_rules_v083(request)
    table_key=reward_table_key_v083(request,stage_id)
    rules=reward_rules_v083(table_key,first_clear) if rules==nil
    rules=[] if rules==nil
    results=[]
    for i in 0...rules.size
      roll=rolls==nil ? nil : rolls[i]
      r=apply_reward_row_v083(rules[i],dry_run,roll,i)
      results.push(r) if r[:granted]
    end
    {:table=>table_key,:first_clear=>first_clear ? true:false,:results=>results,
     :labels=>results.collect{|x|x[:label].to_s},:dry_run=>dry_run ? true:false}
  end

  def self.reward_loot_errors_v083
    e=[]
    e.push('types') unless REWARD_LOOT_MANIFEST_V083[:types].size==7
    for sid in STAGE_REWARD_TABLE_V083.keys
      e.push('stage_'+sid.to_s) if REWARD_TABLES_V083[STAGE_REWARD_TABLE_V083[sid]]==nil
    end
    for key in ENCOUNTER_REWARD_TABLE_V083.keys
      e.push('encounter_'+key.to_s) if REWARD_TABLES_V083[ENCOUNTER_REWARD_TABLE_V083[key]]==nil
    end
    e
  end
end
