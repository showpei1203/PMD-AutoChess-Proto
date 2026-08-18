# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Stage / Region Preview Data v0.90
# 分類：RPG 關卡／區域／遭遇預覽資料層
#
# 【用途】
# 將 v0.80 Stage、v0.83 Reward、v0.84 Elite／Scaling、v0.86 Region Ecology、
# v0.87 Unlock 整理成「玩家在開戰前可以直接閱讀」的統一資料模型。
# 本腳本只讀既有資料，不改傷害、AI、移動、招募機率、掉寶結果或解鎖判定。
#
# 【主要設定項】
# 1. STAGE_REGION_MAP_V090
#    指定 Stage 對應哪個 Region，方便預覽同時顯示該區域的生態資料。
# 2. PREVIEW_W/H/Y_V090
#    預覽面板尺寸；VX 544×416 下預設 510×280，位於 Header 與 Footer 之間。
# 3. PREVIEW_VERIFY_END_V090
#    v0.90 Runtime Verifier 的結束 Frame。
#
# 【機制規則】
# - Stage 敵方預覽直接讀 STAGE_DB_V080，不另外複製敵人資料。
# - Region Formation 直接讀 REGION_ECOLOGY_PROFILES_V086。
# - Formation 是否可出現，直接沿用 v0.87 的 region/formation unlock 判定。
# - Elite 機率與上限直接讀 v0.84 Encounter Profile。
# - 獎勵預覽只格式化 Reward Row，不呼叫發獎函式，因此不會真的給 Gold／Item。
# - 「已持有」依 instance_uid Registry 判斷，不使用 Actor ID。
#
# 【可調參數】
# - 若新增 Stage 4，只需在 STAGE_REGION_MAP_V090 增加：
#     4=>:new_region
# - 若某 Stage 不需顯示 Region，可設：
#     4=>nil
# - 面板間距／字體屬純 UI，可在 Runtime v0.90 調整，不需改本 Data。
#
# 【事件／腳本呼叫方式】
# 取得 Stage 預覽資料：
#   data = PMD_AC.stage_preview_model_v090(1)
#
# 取得指定 RPG Encounter 預覽資料：
#   req = PMD_AC.region_request_v086(:forest_edge,{:formation=>:forest_mixed})
#   data = PMD_AC.request_preview_model_v090(req)
#
# 檢查玩家是否已持有皮卡丘：
#   PMD_AC.species_owned_v090?(:pikachu)
#
# 【實際範例】
# Stage 1 會同時顯示：
# - 林緣演習／建議 Lv12／通關次數
# - 綠毛蟲、小拉達、波波固定敵方編成
# - 首通 100G／重複 35G
# - 對應 Region「林緣」的 Formation 權重、稀有度與 Elite 10%／最多 1 隻
# - 招募候選是否已持有
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不使用禁止的舊式 instance variable probe。
# - 本腳本是純資料整合層；正式內容新增仍應回原 Stage/Region/Reward Data 修改。
# - 不要把預覽顯示值另做一份平衡資料，否則兩邊早晚會各自活成不同宇宙。
#==============================================================================
module PMD_AC
  STAGE_REGION_MAP_V090 = {
    1=>:forest_edge,
    2=>:poison_grove,
    3=>:thunder_slope
  }

  PREVIEW_W_V090 = 510
  PREVIEW_H_V090 = 280
  PREVIEW_Y_V090 = 72
  PREVIEW_VERIFY_END_V090 = 24

  PREVIEW_MANIFEST_V090 = {
    :schema_version=>'1.0',
    :content_version=>'0.90.0',
    :stage_region_links=>STAGE_REGION_MAP_V090.size,
    :preview_stage=>true,
    :preview_region=>true,
    :preview_encounter=>true,
    :preview_rarity=>true,
    :preview_elite=>true,
    :preview_recruit=>true,
    :preview_rewards=>true,
    :preview_owned=>true,
    :unlock_aware=>'v0.87',
    :region_ecology=>'v0.86',
    :elite_scaling=>'v0.84',
    :reward=>'v0.83',
    :identity=>'instance_uid',
    :runtime_checksum32=>900900517
  }

  class << self
    def stage_region_key_v090(stage_id)
      STAGE_REGION_MAP_V090[stage_id.to_i]
    end

    def species_owned_v090?(species)
      key=species.to_s
      reg=respond_to?(:pokemon_registry_v045) ? pokemon_registry_v045 : {}
      reg.each_value do |inst|
        next if inst==nil || !inst.respond_to?(:species_key)
        return true if inst.species_key.to_s==key
      end
      false
    end

    def species_owned_label_v090(species)
      species_owned_v090?(species) ? '已持有' : '未持有'
    end

    def preview_species_name_v090(species)
      if respond_to?(:species_display_name_v047)
        return species_display_name_v047(species)
      end
      species.to_s
    end

    def preview_reward_row_text_v090(row)
      return '無' if row==nil
      type=(row[:type]||:none).to_sym
      chance=(row[:chance]||100).to_i
      text=''
      case type
      when :gold
        if row.has_key?(:amount)
          text=row[:amount].to_i.to_s+'G'
        else
          mn=(row[:min]||0).to_i
          mx=(row[:max]||mn).to_i
          text=mn==mx ? mn.to_s+'G' : mn.to_s+'-'+mx.to_s+'G'
        end
      when :item,:weapon,:armor
        obj=respond_to?(:reward_database_object_v083) ? reward_database_object_v083(type,row[:id]) : nil
        name=obj==nil ? type.to_s+'#'+row[:id].to_i.to_s : obj.name.to_s
        text=name+'×'+(row[:qty]||1).to_i.to_s
      when :variable
        text='變數'+row[:id].to_i.to_s+' +'+(row[:amount]||1).to_i.to_s
      when :switch
        text='開關'+row[:id].to_i.to_s+'='+(row.has_key?(:value) && !row[:value] ? 'OFF' : 'ON')
      when :common_event
        text='公用事件'+row[:id].to_i.to_s
      else
        text=type.to_s
      end
      text+=' '+chance.to_s+'%' if chance<100
      text
    end

    def preview_reward_lines_v090(table_key,first_clear=false)
      return [] if table_key==nil || !respond_to?(:reward_rules_v083)
      rows=reward_rules_v083(table_key,first_clear) || []
      rows.collect{|row| preview_reward_row_text_v090(row)}
    end

    def preview_region_model_v090(region_key)
      return nil if region_key==nil || !respond_to?(:region_data_v086)
      region=region_data_v086(region_key)
      return nil if region==nil
      profile=respond_to?(:encounter_profile_v084) ? encounter_profile_v084(region[:base_profile]) : nil
      profile={} if profile==nil
      all_rows=region[:formations] || []
      available_rows=respond_to?(:available_formation_rows_v087) ? available_formation_rows_v087(region_key) : all_rows
      available_keys={}
      total=0
      available_rows.each do |row|
        next unless row.is_a?(Hash)
        available_keys[row[:formation]]=true
        total += [(row[:weight]||1).to_i,1].max
      end
      formations=[]
      all_rows.each do |row|
        next unless row.is_a?(Hash)
        fk=row[:formation]
        fd=formation_data_v086(fk)
        next if fd==nil
        available=available_keys[fk] ? true : false
        weight=[(row[:weight]||1).to_i,1].max
        chance=(available && total>0) ? ((weight.to_f*100.0/total.to_f).round) : 0
        formations.push({
          :key=>fk,
          :name=>fd[:name].to_s,
          :rarity=>formation_rarity_v086(fk),
          :rarity_label=>formation_rarity_label_v086(fk),
          :weight=>weight,
          :chance=>chance,
          :available=>available,
          :members=>(fd[:members]||[]).collect{|m|m[:species]}
        })
      end
      {
        :key=>region_key,
        :name=>region[:name].to_s,
        :available=>(respond_to?(:region_available_v087?) ? region_available_v087?(region_key) : true),
        :difficulty=>(region[:difficulty]||1).to_i,
        :recruit_rate=>(region[:recruit_rate]||0).to_i,
        :base_profile=>region[:base_profile],
        :elite_rate=>(profile[:elite_rate]||0).to_i,
        :elite_max=>(profile[:elite_max]||0).to_i,
        :elite_profile=>profile[:elite_profile],
        :formations=>formations
      }
    end

    def stage_preview_model_v090(stage_id=nil)
      sid=stage_id==nil ? current_stage_id_v080 : stage_id.to_i
      stage=stage_data_v080(sid)
      return nil if stage==nil
      enemies=[]
      (stage[:enemy_setup]||[]).each do |row|
        enemies.push({:species=>row[0],:level=>row[3].to_i,
          :owned=>species_owned_v090?(row[0])})
      end
      recruits=[]
      (stage[:recruit_pool]||[]).each do |sp|
        recruits.push({:species=>sp,:owned=>species_owned_v090?(sp)})
      end
      clears=stage_clear_count_v080(sid)
      table=defined?(STAGE_REWARD_TABLE_V083) ? STAGE_REWARD_TABLE_V083[sid] : nil
      {
        :mode=>:stage,
        :stage_id=>sid,
        :title=>stage[:name].to_s,
        :recommended_level=>(stage[:recommended_level]||0).to_i,
        :unlocked=>stage_unlocked_v080?(sid),
        :clear_count=>clears,
        :first_clear_pending=>clears<=0,
        :enemies=>enemies,
        :recruits=>recruits,
        :recruit_first_rate=>defined?(STAGE_RECRUIT_FIRST_CLEAR_V080) ? STAGE_RECRUIT_FIRST_CLEAR_V080.to_i : 100,
        :recruit_repeat_rate=>(stage[:repeat_recruit_rate]||STAGE_RECRUIT_REPEAT_V080).to_i,
        :reward_first=>preview_reward_lines_v090(table,true),
        :reward_repeat=>preview_reward_lines_v090(table,false),
        :region=>preview_region_model_v090(stage_region_key_v090(sid))
      }
    end

    def preview_enemy_rows_from_request_v090(request)
      out=[]
      return out if request==nil
      setup=request[:enemy_setup]
      if setup!=nil
        setup.each do |row|
          sp=row[0];lv=row[3].to_i;mods=row[4].is_a?(Hash) ? row[4] : {}
          out.push({:species=>sp,:level=>lv,:owned=>species_owned_v090?(sp),
            :boss=>mods[:boss] ? true:false,:elite=>mods[:elite_v084] ? true:false})
        end
        return out
      end
      pool=request[:enemy_pool] || []
      pool.each do |row|
        out.push({:species=>row[:species],:min_level=>(row[:min_level]||1).to_i,
          :max_level=>(row[:max_level]||row[:min_level]||1).to_i,
          :weight=>(row[:weight]||1).to_i,:owned=>species_owned_v090?(row[:species])})
      end
      out
    end

    def request_preview_model_v090(request)
      return nil if request==nil
      return stage_preview_model_v090(request[:stage_id]) if request[:kind]==:stage && request[:stage_id]!=nil
      table=respond_to?(:reward_table_key_v083) ? reward_table_key_v083(request,nil) : nil
      region=preview_region_model_v090(request[:region_v086])
      {
        :mode=>:request,
        :kind=>request[:kind],
        :title=>request[:name].to_s,
        :enemies=>preview_enemy_rows_from_request_v090(request),
        :recruitable=>request[:recruitable] ? true:false,
        :recruit_rate=>(request[:recruit_rate]||0).to_i,
        :can_escape=>request[:can_escape] ? true:false,
        :boss=>request[:boss] ? true:false,
        :reward_first=>[],
        :reward_repeat=>preview_reward_lines_v090(table,false),
        :region=>region,
        :formation=>request[:formation_v086],
        :rarity=>request[:rarity_v086],
        :rare=>request[:rare_v086] ? true:false
      }
    end

    def preview_manifest_errors_v090
      e=[]
      e.push('stage_region_links') unless STAGE_REGION_MAP_V090.size==3
      STAGE_REGION_MAP_V090.each_pair do |sid,rk|
        e.push('stage_'+sid.to_s) if stage_data_v080(sid)==nil
        e.push('region_'+rk.to_s) if rk!=nil && region_data_v086(rk)==nil
      end
      e.push('preview_size') if PREVIEW_W_V090>Graphics.width || PREVIEW_H_V090<=0
      e.uniq
    end
  end
end
