# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Production Windows Integrated Acceptance v1.06.27
#-------------------------------------------------------------------------------
# Acceptance now uses the real production Hunt runtime, not the old Map090
# AutoTest wrapper. Generates a compact acceptance log across floor generation,
# battle/run accounting, settlement and H21 gate behavior.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDProductionWindowsAcceptance_v10627']=true

class Game_System
  attr_accessor :pmd_vxrd_windows_acceptance_v10627
  attr_accessor :pmd_vxrd_windows_acceptance_last_v10627
end

module PMD_AC
  VXRD_WINDOWS_ACCEPTANCE_LOG_V10627='PMD_VXRD_WindowsAcceptance_LATEST.log'
  class << self
    def vxrd_windows_acceptance_state_v10627
      return nil if $game_system==nil
      $game_system.pmd_vxrd_windows_acceptance_v10627
    rescue
      nil
    end

    def run_random_hunt_windows_acceptance_v10627(code='H01',mode=:event,seed=nil)
      return false if $game_system==nil
      c=code.to_s.upcase;m=(mode||:event).to_sym;m=:event unless [:event,:steps].include?(m)
      gate=hunt_runtime_launch_gate_v10626(c)
      state={:active=>false,:code=>c,:mode=>m,:requested_seed=>seed,
        :started_frame=>(Graphics.frame_count.to_i rescue 0),:generated=>false,
        :floor_transitions=>0,:result=>nil,:gate=>gate,:manual_visual=>:pending}
      $game_system.pmd_vxrd_windows_acceptance_v10627=state
      if !gate[:pass]
        # H21 locked is an expected production gate until a Legendary Circuit clears.
        state[:gate_expected]=(c=='H21' && gate[:reason]==:legend_circuit_locked)
        write_vxrd_windows_acceptance_log_v10627(:gate)
        if state[:gate_expected]
          hunt_runtime_message_v10604(['Windows Acceptance｜H21 Gate PASS','裂隙聖域目前應保持鎖定。','完成 Legendary Circuit 後再驗收 H21 Encounter Pool。']) rescue nil
          return true
        end
        return false
      end
      state[:active]=true
      ok=start_hunt_dungeon_v10604(c,m,seed)
      unless ok
        state[:active]=false;state[:launch_fail]=true
        write_vxrd_windows_acceptance_log_v10627(:launch_fail)
      end
      ok
    rescue
      false
    end

    def write_vxrd_windows_acceptance_log_v10627(action)
      s=vxrd_windows_acceptance_state_v10627 || {}
      hs=(respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil)
      f=(respond_to?(:hunt_vx_floor_info_v10584) ? hunt_vx_floor_info_v10584 : nil)
      last=($game_system==nil ? nil : $game_system.pmd_vxrd_hunt_last_result_v10605)
      wall=(respond_to?(:vxrd_wall_geometry_audit_v10592) ? vxrd_wall_geometry_audit_v10592 : {})
      water=(respond_to?(:vxrd_regular_water_audit_v10593) ? vxrd_regular_water_audit_v10593 : {})
      room=(respond_to?(:vxrd_room_type_info_v10601) ? vxrd_room_type_info_v10601 : nil)
      tech=(respond_to?(:windows_tech_debt_acceptance_v10625) ? windows_tech_debt_acceptance_v10625 : {})
      sem=(respond_to?(:hunt_runtime_semantics_audit_v10626) ? hunt_runtime_semantics_audit_v10626 : {})
      result=s[:result] || last
      stats=(result==nil ? (hs==nil ? {}:(hs[:vxrd_runtime_stats_v10604]||{})):(result[:stats]||{}))
      lines=[]
      lines << 'PMD VXRD Windows Integrated Acceptance'
      lines << 'VERSION='+project_version.to_s
      lines << 'ACTION='+action.to_s
      lines << 'CODE='+s[:code].to_s
      lines << 'MODE='+s[:mode].to_s
      lines << 'PRODUCTION_PATH=1'
      lines << 'TECH_DEBT_ACCEPTANCE='+(tech[:pass] ? 'PASS':tech[:status].to_s.upcase)
      lines << 'CORE_START_BATTLE_MS='+tech[:core_start_battle_ms].to_i.to_s
      lines << 'INTENTIONAL_LOADING_MS='+tech[:intentional_loading_ms].to_i.to_s
      lines << 'HUNT_RUNTIME_READY='+sem[:runtime_ready].to_i.to_s+'/21'
      lines << 'HUNT_SPAWNABLE_NOW='+sem[:spawnable_now].to_i.to_s+'/21'
      lines << 'HUNT_GATED_CODES='+(sem[:gated]||[]).join(',')
      gate=s[:gate]||{}
      lines << 'LAUNCH_GATE='+(gate[:pass] ? 'PASS':gate[:reason].to_s)
      lines << 'H21_UNLOCKED_LEGENDS='+sem[:h21_unlocked].to_i.to_s+'/'+sem[:h21_total].to_i.to_s
      if hs!=nil
        lines << 'RUN='+hs[:run].to_i.to_s
        lines << 'FLOOR='+hs[:vxrd_floor_count_v10584].to_i.to_s
        lines << 'MAX_FLOOR='+hs[:vxrd_max_floors_v10604].to_i.to_s
        lines << 'ACTIVE_POOL='+(hs[:active_pool]||[]).collect{|x|x.to_s}.join(',')
      end
      if f!=nil
        lines << 'MAP_ID='+f[:map_id].to_i.to_s
        lines << 'FLOOR_SEED='+f[:seed].to_i.to_s
        lines << 'ROOMS='+f[:rooms].to_i.to_s
        lines << 'EDGES='+f[:edges].to_i.to_s
        lines << 'WALKABLE='+f[:walkable].to_i.to_s
        er=f[:event_relocate]||{}
        lines << 'EVENT_RELOCATE='+(er[:pass] ? 'PASS':'FAIL')
      end
      lines << 'WALL_GEOMETRY='+(wall[:pass] ? 'PASS':'FAIL')
      lines << 'WATER_AUDIT='+(water[:pass] ? 'PASS':'FAIL')
      lines << 'ROOM_TYPES='+(room==nil ? '{}':(room[:counts]||{}).inspect)
      lines << 'FLOOR_TRANSITIONS='+s[:floor_transitions].to_i.to_s
      lines << 'RUN_STATS='+stats.inspect
      if result!=nil
        lines << 'RESULT_REASON='+result[:reason].to_s
        lines << 'FLOORS_CLEARED='+result[:floors_cleared].to_i.to_s+'/'+result[:max_floors].to_i.to_s
        complete=(result[:reason].to_s.to_sym==:complete && result[:floors_cleared].to_i==result[:max_floors].to_i)
        lines << 'FUNCTIONAL_COMPLETE='+(complete ? 'PASS':'NO')
      else
        lines << 'FUNCTIONAL_COMPLETE=PENDING'
      end
      lines << 'MANUAL_VISUAL='+s[:manual_visual].to_s.upcase
      File.open(VXRD_WINDOWS_ACCEPTANCE_LOG_V10627,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    alias pmd_ac_v10627_hunt_runtime_generate_after_transfer_v10604 hunt_runtime_generate_after_transfer_v10604 unless method_defined?(:pmd_ac_v10627_hunt_runtime_generate_after_transfer_v10604)
    def hunt_runtime_generate_after_transfer_v10604
      r=pmd_ac_v10627_hunt_runtime_generate_after_transfer_v10604
      s=vxrd_windows_acceptance_state_v10627
      if r && s!=nil && s[:active]
        s[:generated]=true
        write_vxrd_windows_acceptance_log_v10627(:generated)
      end
      r
    rescue
      false
    end

    alias pmd_ac_v10627_hunt_runtime_advance_floor_v10605 hunt_runtime_advance_floor_v10605 unless method_defined?(:pmd_ac_v10627_hunt_runtime_advance_floor_v10605)
    def hunt_runtime_advance_floor_v10605
      before=hunt_runtime_current_floor_v10605 rescue 0
      r=pmd_ac_v10627_hunt_runtime_advance_floor_v10605
      s=vxrd_windows_acceptance_state_v10627
      if r && s!=nil && s[:active]
        after=hunt_runtime_current_floor_v10605 rescue 0
        s[:floor_transitions]=s[:floor_transitions].to_i+1 if after>before
        write_vxrd_windows_acceptance_log_v10627(after>before ? :next_floor : :finish_transition)
      end
      r
    rescue
      false
    end

    alias pmd_ac_v10627_hunt_runtime_finish_v10605 hunt_runtime_finish_v10605 unless method_defined?(:pmd_ac_v10627_hunt_runtime_finish_v10605)
    def hunt_runtime_finish_v10605(reason=:retreat,dry_run=false)
      s=vxrd_windows_acceptance_state_v10627
      r=pmd_ac_v10627_hunt_runtime_finish_v10605(reason,dry_run)
      if r && s!=nil && s[:active]
        s[:active]=false
        s[:result]=($game_system==nil ? nil:$game_system.pmd_vxrd_hunt_last_result_v10605)
        $game_system.pmd_vxrd_windows_acceptance_last_v10627=s.dup if $game_system!=nil
        write_vxrd_windows_acceptance_log_v10627(:finished)
        write_project_state_log(false) rescue nil
      end
      r
    rescue
      false
    end

    def vxrd_windows_acceptance_mark_visual_v10627(pass=true)
      s=vxrd_windows_acceptance_state_v10627
      return false if s==nil
      s[:manual_visual]=(pass ? :pass : :fail)
      write_vxrd_windows_acceptance_log_v10627(:visual_mark)
      write_project_state_log(false) rescue nil
      true
    rescue
      false
    end

    def vxrd_windows_acceptance_audit_v10627
      req=[:run_random_hunt_windows_acceptance_v10627,:write_vxrd_windows_acceptance_log_v10627,
        :vxrd_windows_acceptance_mark_visual_v10627,:vxrd_windows_acceptance_state_v10627]
      bad=req.find_all{|m|!respond_to?(m)}
      sem=hunt_runtime_semantics_audit_v10626 rescue {:pass=>false}
      {:pass=>bad.empty? && sem[:pass],:api=>req.size,:production_path=>true,
        :h21_gate=>true,:log=>VXRD_WINDOWS_ACCEPTANCE_LOG_V10627,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end
