# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Loot / Item Economy Data v0.94
# 分類：RPG 獎勵／掉落池／經濟資料層
#
# 【用途】
# 把 v0.83「固定 Reward Row」往正式 RPG 掉落系統推進：新增 Weighted Loot Pool、
# Context 條件、Rare / Elite / Boss 額外 Roll、首通／重複條件與預覽資料。
# 本版故意不替正式關卡亂塞尚未定用途的道具；Runtime 與資料格式先完成，
# 真正 Item Catalog 之後只需在本腳本填資料，不必再重寫戰鬥結算。
#
# 【主要設定項】
# 1. LOOT_POOLS_V094
#    每個掉落池可設定：
#      :base_rolls  基本抽取次數
#      :max_rolls   加成後最多抽幾次
#      :entries     加權候選獎勵
#
# 2. LOOT_POOL_BINDINGS_V094
#    正式綁定表。支援 key：
#      [:stage, 1]              關卡
#      [:region, :forest_edge]  Region
#      [:formation, :xxx]       Formation
#      [:encounter, :boss_xxx]  v0.81 Encounter key
#    優先權：事件 options[:loot_pool] > Formation > Encounter > Region > Stage。
#    v0.94 預設為空 Hash，因此現有 v0.83 / v0.86 金錢與 Bonus Reward 平衡不變。
#
# 3. LOOT_CONTEXT_BONUS_ROLLS_V094
#    Context 額外抽取次數：Rare / Very Rare / Elite / Boss。
#
# 【Entry 格式】
# {:key=>:example,
#  :weight=>60,
#  :type=>:item,:id=>5,:qty=>1,
#  :chance=>100}
#
# type / id / qty / amount / min / max 等獎勵欄位完全沿用 v0.83。
# weight 是「被抽中的相對權重」，chance 是抽中後最後一次成功率判定。
#
# 可選 Context 條件：
# :first_clear_only=>true
# :repeat_only=>true
# :elite_only=>true
# :boss_only=>true
# :rare_only=>true
# :min_rarity=>:rare      # :normal < :uncommon < :rare < :very_rare
#
# 【重複抽取】
# 預設同一 Entry 在同一場只能被抽一次；若希望可重複抽：
#   :repeatable=>true
#
# 【事件／腳本呼叫方式】
# 事件可直接覆蓋：
#   PMD_AC.start_battle_v081(:roadside_pikachu,
#     {:loot_pool=>:my_route_pool})
#
# 自訂戰：
#   PMD_AC.event_custom_v092('伏擊', [[:rattata,15]],
#     {:loot_pool=>:my_route_pool})
#
# 查詢：
#   PMD_AC.loot_pool_key_for_v094(request, stage_id)
#   PMD_AC.loot_pool_preview_v094(:my_route_pool)
#   PMD_AC.last_loot_pool_result_v094
#
# 【實際範例】
# 本版只有 :verifier_sample_v094，專供 Dry-run Verifier；沒有綁定到正式 Stage。
# 未來若設計「林緣素材池」，可建立 :forest_materials，再於
# LOOT_POOL_BINDINGS_V094[[:region,:forest_edge]] 綁定即可。
#
# 【注意事項】
# - 本版不建立新 Item ID，也不修改 Data/Items.rvdata。
# - v0.83 固定 Reward、v0.86 Rare/Elite Bonus 仍先結算；v0.94 Loot Pool 是可選的
#   額外層，只有真的綁定 pool 時才會發放。
# - Boss 仍不可招募；Loot 與 Recruit 是不同系統。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容；禁止舊式 instance-variable reflection probe。
#==============================================================================
module PMD_AC
  PATCH_VERSION_ECONOMY_V094 = '0.94'

  LOOT_RARITY_RANK_V094 = {
    :normal=>0,
    :common=>0,
    :uncommon=>1,
    :rare=>2,
    :very_rare=>3
  }

  LOOT_CONTEXT_BONUS_ROLLS_V094 = {
    :rare=>1,
    :very_rare=>1,
    :elite=>1,
    :boss=>1
  }

  # 只供 Verifier；production binding 預設 0，現有掉落平衡完全不變。
  LOOT_POOLS_V094 = {
    :verifier_sample_v094=>{
      :name=>'Verifier Sample',
      :base_rolls=>2,
      :max_rolls=>5,
      :entries=>[
        {:key=>:coin_small,:weight=>60,:type=>:gold,:amount=>12,:chance=>100},
        {:key=>:item_sample,:weight=>30,:type=>:item,:id=>1,:qty=>1,:chance=>100},
        {:key=>:elite_coin,:weight=>10,:type=>:gold,:amount=>25,:chance=>100,
         :elite_only=>true},
        {:key=>:rare_coin,:weight=>10,:type=>:gold,:amount=>30,:chance=>100,
         :min_rarity=>:rare}
      ]
    }
  }

  # 正式內容尚未指定 Item Catalog，因此先不改任何現有關卡實際掉落。
  LOOT_POOL_BINDINGS_V094 = {
  }

  LOOT_ECONOMY_VERIFY_END_V094 = 34

  LOOT_ECONOMY_MANIFEST_V094 = {
    :version=>'0.94',
    :pools=>LOOT_POOLS_V094.size,
    :production_bindings=>LOOT_POOL_BINDINGS_V094.size,
    :weighted_pick=>true,
    :context=>[:stage,:region,:formation,:encounter,:rarity,:elite,:boss,:first_clear],
    :reward_backend=>:v083,
    :region_bonus=>:v086_preserved,
    :item_catalog=>:deferred_data_only,
    :balance_changed=>false
  }

  class << self
    def loot_pool_v094(key)
      return nil if key==nil
      LOOT_POOLS_V094[key.to_sym]
    end

    def loot_rarity_rank_v094(rarity)
      LOOT_RARITY_RANK_V094[rarity==nil ? :normal : rarity.to_sym] || 0
    end

    def loot_context_v094(request=nil,stage_id=nil,first_clear=false,elite_count=0)
      r=request || {}
      rarity=r[:rarity_v086] || :normal
      {
        :stage_id=>stage_id==nil ? r[:stage_id] : stage_id,
        :region=>r[:region_v086],
        :formation=>r[:formation_v086],
        :encounter=>r[:key],
        :rarity=>rarity,
        :elite_count=>elite_count.to_i,
        :elite=>elite_count.to_i>0,
        :boss=>r[:kind]==:boss,
        :first_clear=>first_clear ? true:false,
        :repeat=>first_clear ? false:true
      }
    end

    def loot_pool_key_for_v094(request=nil,stage_id=nil)
      if request!=nil && request[:options]!=nil && request[:options].has_key?(:loot_pool)
        v=request[:options][:loot_pool]
        return nil if v==false
        return v.to_sym unless v==nil
      end
      if request!=nil
        f=request[:formation_v086]
        return LOOT_POOL_BINDINGS_V094[[:formation,f]] if f!=nil && LOOT_POOL_BINDINGS_V094.has_key?([:formation,f])
        k=request[:key]
        return LOOT_POOL_BINDINGS_V094[[:encounter,k]] if k!=nil && LOOT_POOL_BINDINGS_V094.has_key?([:encounter,k])
        r=request[:region_v086]
        return LOOT_POOL_BINDINGS_V094[[:region,r]] if r!=nil && LOOT_POOL_BINDINGS_V094.has_key?([:region,r])
        sid=request[:stage_id]
        return LOOT_POOL_BINDINGS_V094[[:stage,sid.to_i]] if sid!=nil && LOOT_POOL_BINDINGS_V094.has_key?([:stage,sid.to_i])
      end
      return LOOT_POOL_BINDINGS_V094[[:stage,stage_id.to_i]] if stage_id!=nil && LOOT_POOL_BINDINGS_V094.has_key?([:stage,stage_id.to_i])
      nil
    end

    def loot_entry_allowed_v094(row,context)
      return false if row==nil
      c=context || {}
      return false if row[:first_clear_only] && !c[:first_clear]
      return false if row[:repeat_only] && !c[:repeat]
      return false if row[:elite_only] && !c[:elite]
      return false if row[:boss_only] && !c[:boss]
      if row[:rare_only]
        return false if loot_rarity_rank_v094(c[:rarity])<loot_rarity_rank_v094(:rare)
      end
      if row[:min_rarity]!=nil
        return false if loot_rarity_rank_v094(c[:rarity])<loot_rarity_rank_v094(row[:min_rarity])
      end
      (row[:weight]||0).to_i>0
    end

    def loot_roll_count_v094(pool,context)
      return 0 if pool==nil
      n=(pool[:base_rolls]||1).to_i
      n=0 if n<0
      c=context || {}
      rank=loot_rarity_rank_v094(c[:rarity])
      if rank>=loot_rarity_rank_v094(:very_rare)
        n+=LOOT_CONTEXT_BONUS_ROLLS_V094[:very_rare].to_i
      elsif rank>=loot_rarity_rank_v094(:rare)
        n+=LOOT_CONTEXT_BONUS_ROLLS_V094[:rare].to_i
      end
      n+=LOOT_CONTEXT_BONUS_ROLLS_V094[:elite].to_i if c[:elite]
      n+=LOOT_CONTEXT_BONUS_ROLLS_V094[:boss].to_i if c[:boss]
      mx=(pool[:max_rolls]||n).to_i
      mx=n if mx<n
      n=mx if n>mx
      n
    end

    def loot_weighted_pick_v094(entries,roll=nil)
      rows=entries || []
      total=0
      rows.each{|r| total+=(r[:weight]||0).to_i}
      return nil if total<=0
      x=roll==nil ? rand(total) : roll.to_i%total
      acc=0
      rows.each do |r|
        acc+=(r[:weight]||0).to_i
        return r if x<acc
      end
      rows[-1]
    end

    def loot_pool_preview_v094(key)
      p=loot_pool_v094(key)
      return '無' if p==nil
      name=p[:name] || key.to_s
      name.to_s+'｜基本 '+(p[:base_rolls]||1).to_i.to_s+' 抽｜候選 '+(p[:entries]||[]).size.to_s
    end

    def loot_economy_errors_v094
      e=[]
      LOOT_POOLS_V094.each do |key,p|
        e.push(key.to_s+':entries') if p[:entries]==nil || p[:entries].empty?
        (p[:entries]||[]).each do |row|
          e.push(key.to_s+':weight') if (row[:weight]||0).to_i<=0
          t=(row[:type]||:none).to_sym
          if const_defined?(:REWARD_LOOT_MANIFEST_V083)
            e.push(key.to_s+':type_'+t.to_s) unless REWARD_LOOT_MANIFEST_V083[:types].include?(t)
          end
        end
      end
      LOOT_POOL_BINDINGS_V094.each do |bind,key|
        e.push('binding_'+bind.inspect) if loot_pool_v094(key)==nil
      end
      e.uniq
    end
  end
end
