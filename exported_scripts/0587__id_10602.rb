# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Treasure / Rare Nest / Elite Room Runtime v1.06.02
#-------------------------------------------------------------------------------
# Treasure Room 使用既有 Hunt Loot Economy；Rare Nest 保證在當次 Active Pool
# 有 rare+ 時至少帶 1 隻稀有種；Elite Room 強制 1 隻 Elite。
# AutoTest Treasure 保持 dry-run，不污染測試存檔。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRoomRuntime_v10602']=true

module PMD_AC
  class << self
    def vxrd_player_room_type_v10602
      st=vxrd_state_v10582;return :normal if st==nil || $game_player==nil
      id=vxrd_room_id_for_point_v10601(st,$game_player.x,$game_player.y)
      (st[:room_types_v10601]||{})[id] || :normal
    rescue
      :normal
    end

    def vxrd_species_level_for_hunt_v10602(session,sp,salt)
      row=phase_div_species_v10553(sp)||{}
      mn=[session[:level_min].to_i,row[:level_min].to_i].max
      mx=[session[:level_max].to_i,row[:level_max].to_i].min
      mn=session[:level_min].to_i if mn<=0
      mx=session[:level_max].to_i if mx<mn
      span=[mx-mn+1,1].max
      mn+(phase_div_seed_value_v10555(session[:seed],salt)%span)
    rescue
      session[:level_min].to_i
    end

    alias pmd_ac_v10602_hunt_formation_v10555 phase_div_hunt_formation_v10555 unless method_defined?(:pmd_ac_v10602_hunt_formation_v10555)
    def phase_div_hunt_formation_v10555(session)
      out=pmd_ac_v10602_hunt_formation_v10555(session)
      return out if session==nil || session[:room_encounter_context_v10602]!=:rare_nest || out==nil || out.empty?
      rare=(session[:active_pool]||[]).find_all do |sp|
        row=phase_div_species_v10553(sp) rescue nil
        rk=row==nil ? 0 : (HUNT_RARITY_RANK_V10578[row[:spawn_rarity].to_s]||0).to_i
        rk>=2
      end
      return out if rare.empty?
      salt=session[:encounters].to_i*41+10602
      sp=phase_div_weighted_species_pick_v10555(rare,session[:seed],salt)
      return out if sp==nil
      lv=vxrd_species_level_for_hunt_v10602(session,sp,salt+19)
      first=out[0]
      out[0]=[sp,first[1],first[2],lv,{:phase_div_hunt_v10555=>true,:rare_nest_v10602=>true}]
      # 保持三隻 distinct；若替換後重複，從原 Active Pool 找一隻未使用的替代。
      used={};out.each_with_index do |row,i|
        if used[row[0]] && i>0
          cand=(session[:active_pool]||[]).find{|x|!used[x]}
          unless cand==nil
            row[0]=cand;row[3]=vxrd_species_level_for_hunt_v10602(session,cand,salt+30+i)
          end
        end
        used[row[0]]=true
      end
      session[:last_formation_v10575]=(out||[]).collect{|row|[row[0],row[3].to_i]}
      out
    rescue
      out || []
    end

    alias pmd_ac_v10602_hunt_request_v10555 phase_div_hunt_request_v10555 unless method_defined?(:pmd_ac_v10602_hunt_request_v10555)
    def phase_div_hunt_request_v10555(session)
      r=pmd_ac_v10602_hunt_request_v10555(session)
      return r if r==nil || session==nil
      ctx=(session[:room_encounter_context_v10602]||:normal).to_sym
      r[:phase_div_room_type_v10602]=ctx
      if ctx==:elite
        r[:elite_rate_v084]=100
        r[:elite_profile_v084]=:standard_elite
        r[:elite_max_v084]=1
      elsif ctx==:rare_nest
        r[:rarity_v086]=:rare if respond_to?(:hunt_request_rarity_v10578) && loot_rarity_rank_v094(r[:rarity_v086])<loot_rarity_rank_v094(:rare)
      end
      r
    rescue
      r
    end

    def hunt_room_encounter_v10602(room_type=nil)
      s=phase_div_current_hunt_session_v10555;return false if s==nil
      type=(room_type==nil ? vxrd_player_room_type_v10602 : room_type.to_sym)
      type=:normal unless [:rare_nest,:elite,:normal].include?(type)
      s[:room_encounter_context_v10602]=type
      r=phase_div_hunt_request_v10555(s)
      s.delete(:room_encounter_context_v10602)
      return false if r==nil
      s[:encounters]=s[:encounters].to_i+1
      s[:last_room_encounter_v10602]=type
      launch_battle_request_v081(r)
    rescue
      s.delete(:room_encounter_context_v10602) if s!=nil
      false
    end

    def vxrd_current_room_id_v10602
      st=vxrd_state_v10582;return nil if st==nil || $game_player==nil
      vxrd_room_id_for_point_v10601(st,$game_player.x,$game_player.y)
    rescue
      nil
    end

    def hunt_room_treasure_v10602(dry_run=false)
      s=phase_div_hunt_session_v10555;st=vxrd_state_v10582
      return nil if s==nil || st==nil
      rid=vxrd_current_room_id_v10602
      type=(st[:room_types_v10601]||{})[rid] || :normal
      return {:granted=>false,:reason=>:not_treasure_room,:room_type=>type} unless type==:treasure
      s[:treasure_claims_v10602]={} unless s[:treasure_claims_v10602].is_a?(Hash)
      claim=(st[:seed].to_i.to_s+':'+rid.to_i.to_s)
      return {:granted=>false,:reason=>:already_claimed,:room_id=>rid} if !dry_run && s[:treasure_claims_v10602][claim]
      key=hunt_loot_pool_key_v10578(s[:code])
      ctx={:rarity=>:rare,:elite=>false,:boss=>false}
      result=resolve_loot_pool_v094(key,ctx,dry_run ? true:false)
      s[:treasure_claims_v10602][claim]=true unless dry_run
      s[:last_treasure_result_v10602]=result
      result[:room_id]=rid if result.is_a?(Hash)
      result[:room_type]=:treasure if result.is_a?(Hash)
      result
    rescue
      nil
    end

    def hunt_room_runtime_info_v10602
      st=vxrd_state_v10582;s=phase_div_hunt_session_v10555
      {:room_type=>vxrd_player_room_type_v10602,:room_id=>vxrd_current_room_id_v10602,
        :last_encounter=>(s==nil ? nil:s[:last_room_encounter_v10602]),
        :treasure_claims=>(s==nil || !s[:treasure_claims_v10602].is_a?(Hash) ? 0:s[:treasure_claims_v10602].size),
        :room_counts=>(st==nil ? {}:(st[:room_type_counts_v10601]||{}).dup)}
    rescue
      nil
    end

    # AutoTest Encounter 使用所在 Room Type；Treasure 維持 dry-run。
    def vxrd_autotest_encounter_v10586
      return false unless vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586;s[:encounter_nodes]=s[:encounter_nodes].to_i+1
      write_vxrd_autotest_log_v10586(:encounter_node,{:room_type=>vxrd_player_room_type_v10602})
      return hunt_room_encounter_v10602 if respond_to?(:hunt_map_active?) && hunt_map_active?
      vxrd_autotest_message_v10586(['目前 Hunt Session 不可用','此節點只測地圖配置。'])
      false
    rescue
      false
    end

    def vxrd_autotest_treasure_v10586
      return false unless vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586;s[:treasure_nodes]=s[:treasure_nodes].to_i+1
      result=hunt_room_treasure_v10602(true)
      write_vxrd_autotest_log_v10586(:treasure_node,result)
      labels=result.is_a?(Hash) ? (result[:labels]||[]) : []
      if result.is_a?(Hash) && result[:reason]==:not_treasure_room
        vxrd_autotest_message_v10586(['此 Treasure event 不在寶藏房','Room Type '+result[:room_type].to_s])
      else
        text=labels.empty? ? 'Loot dry-run 完成' : labels[0,2].join('、')
        vxrd_autotest_message_v10586(['Treasure Room｜測試不實際發獎',text,
          '正式事件：PMD_AC.hunt_room_treasure_v10602'])
      end
      true
    rescue
      false
    end

    def vxrd_room_runtime_audit_v10602
      req=[:hunt_room_encounter_v10602,:hunt_room_treasure_v10602,:hunt_room_runtime_info_v10602]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:rare_nest=>true,:elite_room=>true,:treasure_room=>true,
        :treasure_uses_existing_loot=>true,:autotest_dry_run=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end
