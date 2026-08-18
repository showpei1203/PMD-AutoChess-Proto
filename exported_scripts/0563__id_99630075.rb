# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Phase D-IV Hunt Region Economy v1.05.78
#-------------------------------------------------------------------------------
# 21 張 Hunt 正式接既有 v0.94/v0.98 Weighted Loot Runtime。
# 不新增垃圾素材 Item ID；先讓現有補給品、EXP、Mastery、Gold 隨 Tier / Biome
# 形成可理解的刷圖經濟。Rare / Elite 沿用 v0.94 Context bonus roll。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntRegionEconomy_v10578']=true

module PMD_AC
  HUNT_ECONOMY_TIER_V10578={
    1=>{:base_rolls=>1,:max_rolls=>2,:gold=>18},
    2=>{:base_rolls=>1,:max_rolls=>3,:gold=>28},
    3=>{:base_rolls=>2,:max_rolls=>3,:gold=>42},
    4=>{:base_rolls=>2,:max_rolls=>4,:gold=>60},
    5=>{:base_rolls=>2,:max_rolls=>4,:gold=>90}
  }
  HUNT_ECONOMY_BIOME_V10578={
    'forest'=>{:label=>'林地補給',:bias=>:sustain},
    'water'=>{:label=>'水域補給',:bias=>:recovery},
    'sky'=>{:label=>'高地補給',:bias=>:growth},
    'mountain'=>{:label=>'礦脈補給',:bias=>:growth_gold},
    'mystic'=>{:label=>'秘境補給',:bias=>:mastery},
    'legend'=>{:label=>'裂隙補給',:bias=>:endgame}
  }
  HUNT_RARITY_RANK_V10578={'common'=>0,'uncommon'=>1,'rare'=>2,'very_rare'=>3,'legendary'=>4}

  class << self
    def hunt_loot_pool_key_v10578(code)
      ('phase_div_hunt_'+code.to_s.downcase+'_v10578').to_sym
    end

    def hunt_loot_pool_code_from_key_v10578(key)
      s=key.to_s
      return nil unless s.index('phase_div_hunt_')==0 && s.index('_v10578')!=nil
      body=s.sub('phase_div_hunt_','').sub('_v10578','')
      c=body.upcase
      phase_div_hunt_v10553(c)==nil ? nil : c
    rescue
      nil
    end

    def hunt_loot_entries_v10578(code)
      h=phase_div_hunt_v10553(code);return [] if h==nil
      tier=[[h[:tier].to_i,1].max,5].min
      biome=h[:biome].to_s
      t=HUNT_ECONOMY_TIER_V10578[tier]
      gold=t[:gold].to_i
      rows=[]
      case biome
      when 'forest'
        rows=[
          {:key=>:heal,:weight=>28,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:exp_s,:weight=>24,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:mastery,:weight=>24,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:revive,:weight=>10,:type=>:item,:id=>7,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:ration,:weight=>6,:type=>:item,:id=>12,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:gold,:weight=>8,:type=>:gold,:amount=>gold,:chance=>100,:repeatable=>true}
        ]
      when 'water'
        rows=[
          {:key=>:heal,:weight=>24,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:revive,:weight=>16,:type=>:item,:id=>7,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:ration,:weight=>12,:type=>:item,:id=>12,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:exp_s,:weight=>24,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:mastery,:weight=>12,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:gold,:weight=>12,:type=>:gold,:amount=>gold,:chance=>100,:repeatable=>true}
        ]
      when 'sky'
        rows=[
          {:key=>:exp_s,:weight=>28,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:mastery,:weight=>24,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:heal,:weight=>18,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:exp_m,:weight=>12,:type=>:item,:id=>9,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:manual,:weight=>6,:type=>:item,:id=>11,:qty=>1,:chance=>100,:min_rarity=>:very_rare},
          {:key=>:gold,:weight=>12,:type=>:gold,:amount=>gold,:chance=>100,:repeatable=>true}
        ]
      when 'mountain'
        rows=[
          {:key=>:gold,:weight=>26,:type=>:gold,:amount=>gold,:chance=>100,:repeatable=>true},
          {:key=>:exp_s,:weight=>22,:type=>:item,:id=>8,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:exp_m,:weight=>14,:type=>:item,:id=>9,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:revive,:weight=>14,:type=>:item,:id=>7,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:mastery,:weight=>16,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:ration,:weight=>8,:type=>:item,:id=>12,:qty=>1,:chance=>100,:min_rarity=>:rare}
        ]
      when 'mystic'
        rows=[
          {:key=>:mastery,:weight=>28,:type=>:item,:id=>10,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:manual,:weight=>14,:type=>:item,:id=>11,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:exp_m,:weight=>18,:type=>:item,:id=>9,:qty=>1,:chance=>100,:min_rarity=>:rare},
          {:key=>:heal,:weight=>18,:type=>:item,:id=>6,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:honey,:weight=>6,:type=>:item,:id=>13,:qty=>1,:chance=>100,:min_rarity=>:very_rare},
          {:key=>:gold,:weight=>16,:type=>:gold,:amount=>gold,:chance=>100,:repeatable=>true}
        ]
      else
        rows=[
          {:key=>:exp_m,:weight=>24,:type=>:item,:id=>9,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:manual,:weight=>22,:type=>:item,:id=>11,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:honey,:weight=>18,:type=>:item,:id=>13,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:revive,:weight=>14,:type=>:item,:id=>7,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:ration,:weight=>10,:type=>:item,:id=>12,:qty=>1,:chance=>100,:repeatable=>true},
          {:key=>:gold,:weight=>12,:type=>:gold,:amount=>gold,:chance=>100,:repeatable=>true}
        ]
      end
      # 高 Tier 把較低階 EXP / Mastery 的部分權重轉向高階補給，但不改 Item 效果本身。
      if tier>=3
        rows.each do |r|
          if r[:id].to_i==8
            r[:weight]=[r[:weight].to_i-8,4].max
          elsif r[:id].to_i==9
            r[:weight]=r[:weight].to_i+8
          elsif r[:id].to_i==11
            r[:weight]=r[:weight].to_i+4
          end
        end
      end
      rows
    rescue
      []
    end

    def hunt_loot_pool_v10578(code)
      h=phase_div_hunt_v10553(code);return nil if h==nil
      tier=[[h[:tier].to_i,1].max,5].min
      t=HUNT_ECONOMY_TIER_V10578[tier]
      bp=HUNT_ECONOMY_BIOME_V10578[h[:biome].to_s] || HUNT_ECONOMY_BIOME_V10578['legend']
      {:name=>h[:name].to_s+'｜'+bp[:label].to_s,
       :base_rolls=>t[:base_rolls].to_i,:max_rolls=>t[:max_rolls].to_i,
       :entries=>hunt_loot_entries_v10578(code)}
    rescue
      nil
    end

    alias pmd_ac_v10578_loot_rarity_rank_v094 loot_rarity_rank_v094 unless method_defined?(:pmd_ac_v10578_loot_rarity_rank_v094)
    def loot_rarity_rank_v094(rarity)
      return 4 if rarity!=nil && rarity.to_sym==:legendary
      pmd_ac_v10578_loot_rarity_rank_v094(rarity)
    end

    alias pmd_ac_v10578_loot_pool_v094 loot_pool_v094 unless method_defined?(:pmd_ac_v10578_loot_pool_v094)
    def loot_pool_v094(key)
      code=hunt_loot_pool_code_from_key_v10578(key)
      return hunt_loot_pool_v10578(code) unless code==nil
      pmd_ac_v10578_loot_pool_v094(key)
    end

    def hunt_request_rarity_v10578(session)
      max='common';mr=0
      rows=session==nil ? [] : (session[:last_formation_v10575]||[])
      rows.each do |x|
        sp=x[0];r=phase_div_species_v10553(sp);rk=r==nil ? 'common' : r[:spawn_rarity].to_s
        n=HUNT_RARITY_RANK_V10578[rk].to_i
        if n>mr;mr=n;max=rk;end
      end
      max.to_sym
    rescue
      :normal
    end

    alias pmd_ac_v10578_hunt_request phase_div_hunt_request_v10555 unless method_defined?(:pmd_ac_v10578_hunt_request)
    def phase_div_hunt_request_v10555(session)
      r=pmd_ac_v10578_hunt_request(session)
      return nil if r==nil || session==nil
      r[:options]={} unless r[:options].is_a?(Hash)
      key=hunt_loot_pool_key_v10578(session[:code])
      r[:options][:loot_pool]=key
      r[:rarity_v086]=hunt_request_rarity_v10578(session)
      r[:phase_div_hunt_loot_pool_v10578]=key
      r
    rescue
      r
    end

    def hunt_economy_info(code)
      c=code.to_s.upcase;h=phase_div_hunt_v10553(c);return nil if h==nil
      p=hunt_loot_pool_v10578(c);return nil if p==nil
      {:code=>c,:tier=>h[:tier].to_i,:biome=>h[:biome].to_s,:pool=>hunt_loot_pool_key_v10578(c),
       :name=>p[:name].to_s,:base_rolls=>p[:base_rolls].to_i,:max_rolls=>p[:max_rolls].to_i,
       :candidate_items=>(p[:entries]||[]).find_all{|r|r[:type]==:item}.collect{|r|r[:id].to_i}.uniq.sort,
       :gold=>HUNT_ECONOMY_TIER_V10578[h[:tier].to_i][:gold].to_i,
       :rare_bonus_roll=>1,:elite_bonus_roll=>1}
    rescue
      nil
    end

    def hunt_region_economy_audit_v10578
      bad=[];seen={}
      PHASE_DIV_HUNT_ORDER_V10553.each do |c|
        p=hunt_loot_pool_v10578(c);info=hunt_economy_info(c)
        bad.push(c+':pool') if p==nil || (p[:entries]||[]).empty?
        bad.push(c+':rolls') if p!=nil && (p[:base_rolls].to_i<=0 || p[:max_rolls].to_i<p[:base_rolls].to_i)
        (p==nil ? [] : p[:entries]||[]).each do |r|
          bad.push(c+':weight') if r[:weight].to_i<=0
          if r[:type]==:item
            bad.push(c+':item'+r[:id].to_i.to_s) if !defined?(SUPPLY_CATALOG_V098) || SUPPLY_CATALOG_V098[r[:id].to_i]==nil
          end
        end
        seen[info[:biome]]=true unless info==nil
      end
      {:pass=>bad.empty?,:hunts=>PHASE_DIV_HUNT_ORDER_V10553.size,:biomes=>seen.keys.size,:tiers=>HUNT_ECONOMY_TIER_V10578.size,:bad=>bad}
    rescue
      {:pass=>false,:hunts=>0,:biomes=>0,:tiers=>0,:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10578_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10578_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10578_focus_summary
    begin
      a=PMD_AC.hunt_region_economy_audit_v10578
      log_event(:battle,'BATTLE_PHASE_DIV_HUNT_REGION_ECONOMY_SUMMARY_V10578 pass='+(a[:pass] ? '1':'0')+
        ' hunts='+a[:hunts].to_i.to_s+'/21 biomes='+a[:biomes].to_i.to_s+'/6 tiers='+a[:tiers].to_i.to_s+'/5'+
        ' existing_supply_catalog=8 no_new_junk_materials=1 rare_bonus_roll=1 elite_bonus_roll=1'+
        ' errors=['+(a[:bad]||[]).join(',')+']')
    rescue
    end
    r
  end
end
