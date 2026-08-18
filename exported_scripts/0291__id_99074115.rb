#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Stage Data v0.80
# 分類：關卡／Stage
#
# 【用途／機制】
# 定義可選關卡、敵方編成、解鎖、招募與關卡 metadata。
#
# 【怎麼調整】
# 修改關卡時優先調整 STAGE_DB；例如新增第 4 關時複製一個關卡 Hash，改 enemy_setup、建議等級與招募池。
#
# 【本腳本主要設定常數／資料表】
# - STAGE_DB_V080 / STAGE_ORDER_V080 / STAGE_RECRUIT_FIRST_CLEAR_V080 / STAGE_RECRUIT_REPEAT_V080
# - STAGE_VERIFY_END_V080 / STAGE_MANIFEST_V080
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - stage_data_v080 / stage_name_v080 / stage_default_state_v080 / normalize_stage_state_v080
# - stage_state_v080 / current_stage_id_v080 / current_stage_v080 / stage_unlocked_v080?
# - stage_clear_count_v080 / record_stage_clear_in_state_v080 / record_stage_clear_v080 / cycle_stage_v080
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Stage / Encounter Data v0.80
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  STAGE_DB_V080 = {
    1=>{
      :id=>1,:name=>'林緣演習',:recommended_level=>12,
      :enemy_setup=>[
        [:caterpie,4,1,12],
        [:rattata,5,2,13],
        [:pidgey,5,3,12]
      ],
      :weather=>nil,
      :recruit_pool=>[:caterpie,:rattata,:pidgey],
      :recruit_level=>12,
      :repeat_recruit_rate=>35,
      :reward_tier=>1,:loot_table=>:deferred
    },
    2=>{
      :id=>2,:name=>'毒針林',:recommended_level=>14,
      :enemy_setup=>[
        [:weedle,4,1,14],
        [:kakuna,5,2,14],
        [:beedrill,5,3,15]
      ],
      :weather=>nil,
      :recruit_pool=>[:weedle,:kakuna,:beedrill],
      :recruit_level=>14,
      :repeat_recruit_rate=>35,
      :reward_tier=>2,:loot_table=>:deferred
    },
    3=>{
      :id=>3,:name=>'雷羽坡',:recommended_level=>16,
      :enemy_setup=>[
        [:spearow,4,1,16],
        [:ekans,5,2,16],
        [:pikachu,5,3,17]
      ],
      :weather=>nil,
      :recruit_pool=>[:spearow,:ekans,:pikachu],
      :recruit_level=>16,
      :repeat_recruit_rate=>35,
      :reward_tier=>3,:loot_table=>:deferred
    }
  }

  STAGE_ORDER_V080 = [1,2,3]
  STAGE_RECRUIT_FIRST_CLEAR_V080 = 100
  STAGE_RECRUIT_REPEAT_V080 = 35
  STAGE_VERIFY_END_V080 = 22

  STAGE_MANIFEST_V080 = {
    :schema_version=>'1.0',
    :content_version=>'0.80.0',
    :stage_count=>3,
    :enemy_slots=>3,
    :selection_input=>'Q/W',
    :unlock_policy=>'clear_previous',
    :first_clear_recruit_rate=>100,
    :repeat_recruit_rate=>35,
    :recruit_accept_input=>'A(Input::X)',
    :recruit_destination=>'first_available_box',
    :loot_table=>'deferred',
    :identity=>'instance_uid',
    :party=>'v0.78',
    :reward_loop=>'v0.79',
    :runtime_checksum32=>1809074412
  }

  class << self
    def stage_data_v080(id)
      STAGE_DB_V080[id.to_i]
    end

    def stage_name_v080(id)
      d=stage_data_v080(id)
      d==nil ? '未知關卡' : d[:name].to_s
    end

    def stage_default_state_v080
      {:selected_stage=>1,:unlocked=>[1],:clears=>{},:recruits=>0}
    end

    def normalize_stage_state_v080(state)
      state=stage_default_state_v080 if state==nil
      state[:selected_stage]=1 if state[:selected_stage]==nil
      state[:unlocked]=[1] if state[:unlocked]==nil || state[:unlocked].empty?
      state[:clears]={} if state[:clears]==nil
      state[:recruits]=state[:recruits].to_i
      state[:unlocked]=state[:unlocked].collect{|x|x.to_i}.uniq.sort
      state[:unlocked].push(1) unless state[:unlocked].include?(1)
      state[:unlocked].sort!
      unless state[:unlocked].include?(state[:selected_stage].to_i)
        state[:selected_stage]=state[:unlocked][0]
      end
      state
    end

    def stage_state_v080
      if $game_system!=nil && $game_system.respond_to?(:pmd_autochess_stage_v080)
        s=$game_system.pmd_autochess_stage_v080
        s=normalize_stage_state_v080(s)
        $game_system.pmd_autochess_stage_v080=s
        return s
      end
      @stage_fallback_v080=normalize_stage_state_v080(@stage_fallback_v080)
      @stage_fallback_v080
    end

    def current_stage_id_v080
      stage_state_v080[:selected_stage].to_i
    end

    def current_stage_v080
      stage_data_v080(current_stage_id_v080) || STAGE_DB_V080[1]
    end

    def stage_unlocked_v080?(id,state=nil)
      state=stage_state_v080 if state==nil
      (state[:unlocked]||[]).include?(id.to_i)
    end

    def stage_clear_count_v080(id,state=nil)
      state=stage_state_v080 if state==nil
      (state[:clears]||{})[id.to_i].to_i
    end

    def record_stage_clear_in_state_v080(state,id)
      state=normalize_stage_state_v080(state)
      sid=id.to_i
      first=stage_clear_count_v080(sid,state)==0
      state[:clears][sid]=stage_clear_count_v080(sid,state)+1
      idx=STAGE_ORDER_V080.index(sid)
      unlocked=nil
      if idx!=nil && idx+1<STAGE_ORDER_V080.size
        nxt=STAGE_ORDER_V080[idx+1]
        unless state[:unlocked].include?(nxt)
          state[:unlocked].push(nxt)
          state[:unlocked].sort!
          unlocked=nxt
        end
      end
      {:first_clear=>first,:unlocked_stage=>unlocked,:clear_count=>state[:clears][sid]}
    end

    def record_stage_clear_v080(id)
      record_stage_clear_in_state_v080(stage_state_v080,id)
    end

    def cycle_stage_v080(delta)
      s=stage_state_v080
      unlocked=(s[:unlocked]||[1]).sort
      return current_stage_id_v080 if unlocked.empty?
      cur=s[:selected_stage].to_i
      idx=unlocked.index(cur) || 0
      idx=(idx+delta.to_i)%unlocked.size
      s[:selected_stage]=unlocked[idx]
      s[:selected_stage]
    end

    def recruit_offer_for_stage_v080(stage_id,first_clear=false,roll=nil,pick=nil)
      d=stage_data_v080(stage_id)
      return nil if d==nil
      pool=d[:recruit_pool] || []
      return nil if pool.empty?
      chance=first_clear ? STAGE_RECRUIT_FIRST_CLEAR_V080 : (d[:repeat_recruit_rate]||STAGE_RECRUIT_REPEAT_V080).to_i
      r=roll==nil ? rand(100) : roll.to_i
      return nil if r>=chance
      p=pick==nil ? rand(pool.size) : pick.to_i
      p=0 if p<0
      p=p%pool.size
      {:stage_id=>stage_id.to_i,:species=>pool[p],:level=>d[:recruit_level].to_i,
       :first_clear=>first_clear ? true : false,:chance=>chance,:accepted=>false}
    end

    def accept_recruit_offer_v080(offer)
      return nil if offer==nil || offer[:accepted]
      return nil if first_available_box_v078==nil
      inst=PMD_PokemonInstance.new(offer[:species],offer[:level])
      return nil unless register_pokemon_instance_v045(inst)
      return nil unless store_instance_first_available_v078(inst,false)
      offer[:accepted]=true
      offer[:instance_uid]=inst.instance_uid.to_i
      stage_state_v080[:recruits]=stage_state_v080[:recruits].to_i+1
      inst
    end

    def stage_manifest_errors_v080
      e=[]
      e.push('stage_count') unless STAGE_DB_V080.size==3
      STAGE_ORDER_V080.each do |sid|
        d=stage_data_v080(sid)
        if d==nil
          e.push('missing_'+sid.to_s)
          next
        end
        setup=d[:enemy_setup]||[]
        e.push('enemy_slots_'+sid.to_s) unless setup.size==3
        setup.each do |row|
          sp=row[0]
          sd=species_identity_data(sp)
          e.push('species_'+sp.to_s) if sd==nil
          dex=sd==nil ? 0 : sd[:national_dex].to_i
          e.push('asset_range_'+sp.to_s) if dex<1 || dex>26
        end
        pool=d[:recruit_pool]||[]
        e.push('recruit_pool_'+sid.to_s) if pool.empty?
      end
      e.uniq
    end

    def stage_checksum32_v080
      STAGE_MANIFEST_V080[:runtime_checksum32].to_i
    end
  end
end
