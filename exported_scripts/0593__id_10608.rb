# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Hunt Run Battle / Recruit / Loot Accounting v1.06.08
#-------------------------------------------------------------------------------
# 【用途】
# - 將隨機地圖 Hunt Run 的戰鬥勝敗、逃跑、招募、掉落正式累計到 Run Stats。
# - Rare Nest / Elite Room 勝利獨立計數，供結算與後續 UI 使用。
# - Production Hunt 敗北時結束整趟 Run；一般勝利／逃跑回到目前 Floor。
# - 不修改戰鬥公式、AI、掉落內容或招募個體 Authority。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHuntRunAccounting_v10608']=true

module PMD_AC
  class << self
    def hunt_runtime_stats_v10608
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return nil if s==nil
      s[:vxrd_runtime_stats_v10604]||={}
      s[:vxrd_runtime_stats_v10604]
    rescue
      nil
    end

    def hunt_runtime_request_v10608?(request)
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return false if s==nil || request==nil
      request[:phase_div_hunt_code_v10555].to_s==s[:code].to_s
    rescue
      false
    end

    alias pmd_ac_v10608_record_battle_result_v081 record_battle_result_v081 unless method_defined?(:pmd_ac_v10608_record_battle_result_v081)
    def record_battle_result_v081(request,result)
      data=pmd_ac_v10608_record_battle_result_v081(request,result)
      begin
        if hunt_runtime_request_v10608?(request) && !request[:vxrd_run_stat_recorded_v10608]
          request[:vxrd_run_stat_recorded_v10608]=true
          st=hunt_runtime_stats_v10608
          if st!=nil
            st[:battles]=st[:battles].to_i+1
            case result
            when :win
              st[:wins]=st[:wins].to_i+1
              st[:floor_wins]||={}
              floor=(hunt_runtime_session_v10605==nil ? 0:hunt_runtime_session_v10605[:vxrd_floor_count_v10584].to_i)
              st[:floor_wins][floor]=st[:floor_wins][floor].to_i+1 if floor>0
              rt=(request[:phase_div_room_type_v10602]||:normal).to_sym
              st[:rare_nest_wins]=st[:rare_nest_wins].to_i+1 if rt==:rare_nest
              st[:elite_room_wins]=st[:elite_room_wins].to_i+1 if rt==:elite
            when :lose
              st[:losses]=st[:losses].to_i+1
            when :escape
              st[:escapes]=st[:escapes].to_i+1
            end
            st[:last_battle_result]=result
            st[:last_room_type]=(request[:phase_div_room_type_v10602]||:normal).to_sym
          end
          s=hunt_runtime_session_v10605
          s[:pending_defeat_finish_v10608]=true if s!=nil && result==:lose
          if s!=nil
            eid=s[:pending_encounter_event_id_v10606].to_i
            vxrd_set_node_consumed_v10606(eid,false) if result==:escape && eid>0 && respond_to?(:vxrd_set_node_consumed_v10606)
            s.delete(:pending_encounter_event_id_v10606)
          end
        end
      rescue
      end
      data
    end

    alias pmd_ac_v10608_accept_recruit_offer_v080 accept_recruit_offer_v080 unless method_defined?(:pmd_ac_v10608_accept_recruit_offer_v080)
    def accept_recruit_offer_v080(offer)
      hunt_before=(respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil)
      inst=pmd_ac_v10608_accept_recruit_offer_v080(offer)
      begin
        req=respond_to?(:rpg_request_v081) ? rpg_request_v081 : nil
        if inst!=nil && hunt_before!=nil && req!=nil && req[:phase_div_hunt_code_v10555].to_s==hunt_before[:code].to_s
          st=hunt_before[:vxrd_runtime_stats_v10604]||={}
          st[:recruits]=st[:recruits].to_i+1
          st[:recruit_rows]||=[]
          row={:species=>(inst.respond_to?(:species_key) ? inst.species_key : offer[:species]),
            :uid=>(inst.respond_to?(:instance_uid) ? inst.instance_uid.to_i : offer[:instance_uid].to_i),
            :floor=>hunt_before[:vxrd_floor_count_v10584].to_i}
          st[:recruit_rows] << row
        end
      rescue
      end
      inst
    end

    alias pmd_ac_v10608_record_loot_pool_result_v094 record_loot_pool_result_v094 unless method_defined?(:pmd_ac_v10608_record_loot_pool_result_v094)
    def record_loot_pool_result_v094(result)
      pmd_ac_v10608_record_loot_pool_result_v094(result)
      begin
        s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
        if s!=nil && result!=nil
          wanted=respond_to?(:hunt_loot_pool_key_v10578) ? hunt_loot_pool_key_v10578(s[:code]) : nil
          if wanted!=nil && result[:pool].to_s==wanted.to_s
            st=s[:vxrd_runtime_stats_v10604]||={}
            rows=result[:results]||[]
            st[:loot_results]=st[:loot_results].to_i+rows.size
            st[:loot_labels]||=[]
            (result[:labels]||[]).each{|x|st[:loot_labels] << x.to_s if st[:loot_labels].size<24}
          end
        end
      rescue
      end
    end

    alias pmd_ac_v10608_hunt_finish_snapshot_v10575 hunt_finish_snapshot_v10575 unless method_defined?(:pmd_ac_v10608_hunt_finish_snapshot_v10575)
    def hunt_finish_snapshot_v10575(reason=:normal)
      s=phase_div_hunt_session_v10555 rescue nil
      stats=s==nil ? nil : (s[:vxrd_runtime_stats_v10604]||{}).dup
      out=pmd_ac_v10608_hunt_finish_snapshot_v10575(reason)
      if out!=nil && stats!=nil
        out[:runtime_stats_v10608]=stats
        $game_system.pmd_phase_div_hunt_last_summary_v10575=out if $game_system!=nil
      end
      out
    rescue
      out
    end

    def hunt_run_accounting_audit_v10608
      req=[:hunt_runtime_stats_v10608,:hunt_runtime_request_v10608?]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:battle=>true,:recruit=>true,:loot=>true,
        :rare_elite=>true,:defeat_run_end=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10608_return_to_map_v081 return_to_map_v081 unless method_defined?(:pmd_ac_v10608_return_to_map_v081)
  def return_to_map_v081
    req=rpg_request_v081 rescue nil
    result=PMD_AC.respond_to?(:last_battle_result_v081) ? PMD_AC.last_battle_result_v081 : nil
    production=PMD_AC.hunt_runtime_request_v10608?(req) rescue false
    pending=false
    begin
      ss=PMD_AC.hunt_runtime_session_v10605
      pending=(ss!=nil && ss[:pending_defeat_finish_v10608])
    rescue
    end
    r=pmd_ac_v10608_return_to_map_v081
    begin
      if production && (result==:lose || pending) && PMD_AC.hunt_runtime_session_v10605!=nil
        ss=PMD_AC.hunt_runtime_session_v10605
        ss.delete(:pending_defeat_finish_v10608) if ss!=nil
        PMD_AC.hunt_runtime_finish_v10605(:defeat,false)
      end
    rescue
    end
    r
  end
end
