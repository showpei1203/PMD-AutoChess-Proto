# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Windows Final Acceptance Conductor v1.06.34
#-------------------------------------------------------------------------------
# Purpose
#  1. Collapse the remaining VXRD Windows acceptance into one production H12 run.
#  2. Use deterministic H12 seed 1063404; floor 1 contains Treasure / Rare Nest /
#     Elite / Recovery coverage while keeping normal production room/runtime code.
#  3. Run detached semantic probes for room content and exit gate without granting
#     QA loot or launching extra QA battles.
#  4. Require one real Save -> Load cycle, then compare floor / seed / active pool /
#     BSP layout / event placement / Map090 tile checksum exactly.
#  5. Auto-retreat after the resumed map is shown, verify no completion bonus and
#     no H12 clear mutation, then execute the real H21 launch gate and prove that
#     no empty H21 run is created while Legendary Circuits remain uncleared.
#  6. Write PMD_VXRD_WindowsAcceptance_LATEST.log and seal Gate 1 on PASS.
#-------------------------------------------------------------------------------
# QA/acceptance-only orchestration. Hunt generation, rewards, battle, AI, damage,
# spatial and Random Dungeon production authorities are not rewritten.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDWindowsFinalAcceptanceConductor_v10634']=true

class Game_System
  attr_accessor :pmd_vxrd_final_acceptance_v10634
end

module PMD_AC
  VXRD_FINAL_ACCEPTANCE_SEED_V10634 = 1063404
  VXRD_FINAL_ACCEPTANCE_LOG_V10634 = 'PMD_VXRD_WindowsAcceptance_LATEST.log'

  class << self
    #--------------------------------------------------------------------------
    # State / helpers
    #--------------------------------------------------------------------------
    def vxrd_final_acceptance_state_v10634
      return nil if $game_system==nil
      $game_system.pmd_vxrd_final_acceptance_v10634
    rescue
      nil
    end

    def vxrd_final_acceptance_pass_v10634?
      s=vxrd_final_acceptance_state_v10634
      s!=nil && s[:overall]==:pass
    rescue
      false
    end

    def vxrd_acceptance_crc_v10634(obj)
      Zlib.crc32(Marshal.dump(obj))
    rescue
      0
    end

    def vxrd_acceptance_tile_checksum_v10634
      return 0 if $game_map==nil
      map=$game_map.instance_variable_get(:@map)
      return 0 if map==nil || map.data==nil
      h=5381
      zmax=3
      for z in 0...zmax
        for y in 0...$game_map.height.to_i
          for x in 0...$game_map.width.to_i
            v=map.data[x,y,z].to_i
            h=((h*33)+v+(x*3)+(y*5)+(z*7)) & 0x7fffffff
          end
        end
      end
      h
    rescue
      0
    end

    def vxrd_acceptance_event_positions_v10634
      out=[]
      return out if $game_map==nil
      ($game_map.events||{}).keys.sort.each do |id|
        ev=($game_map.events||{})[id]
        tag=respond_to?(:vxrd_game_event_tag_v10584) ? vxrd_game_event_tag_v10584(ev) : nil
        next if tag==nil
        erased=ev.instance_variable_get(:@erased) ? 1 : 0
        out << [id.to_i,tag.to_s,ev.x.to_i,ev.y.to_i,erased]
      end
      out
    rescue
      []
    end

    def vxrd_acceptance_sorted_rooms_v10634(st)
      (st[:rooms]||[]).collect do |r|
        [r[:id].to_i,r[:x].to_i,r[:y].to_i,r[:w].to_i,r[:h].to_i,r[:cx].to_i,r[:cy].to_i]
      end.sort{|a,b|a[0]<=>b[0]}
    rescue
      []
    end

    def vxrd_acceptance_sorted_edges_v10634(st)
      (st[:edges]||[]).collect do |e|
        a=e[0].to_i;b=e[1].to_i
        a<=b ? [a,b] : [b,a]
      end.sort{|a,b|x=(a[0]<=>b[0]);x==0 ? (a[1]<=>b[1]) : x}
    rescue
      []
    end

    def vxrd_acceptance_sorted_type_map_v10634(h)
      out=[]
      (h||{}).keys.sort{|a,b|a.to_i<=>b.to_i}.each{|k|out << [k.to_i,(h||{})[k].to_s]}
      out
    rescue
      []
    end

    def vxrd_acceptance_snapshot_v10634
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      return nil if s==nil || st==nil || $game_map==nil || $game_player==nil
      consumed=(s[:vxrd_consumed_nodes_v10606]||{}).keys.collect{|k|k.to_s}.sort
      water=st[:water_v10593]||{}
      rects=(water[:rects]||[]).collect{|r|[r[:x].to_i,r[:y].to_i,r[:w].to_i,r[:h].to_i,r[:room_id].to_i]}.sort
      snap={
        :code=>s[:code].to_s.upcase,
        :run=>s[:run].to_i,
        :floor=>s[:vxrd_floor_count_v10584].to_i,
        :max_floor=>s[:vxrd_max_floors_v10604].to_i,
        :run_seed=>s[:seed].to_i,
        :floor_seed=>s[:vxrd_last_floor_seed_v10584].to_i,
        :layout_seed=>st[:seed].to_i,
        :active_pool=>(s[:active_pool]||[]).collect{|x|x.to_s},
        :map_id=>$game_map.map_id.to_i,
        :player=>[$game_player.x.to_i,$game_player.y.to_i,$game_player.direction.to_i],
        :entrance=>(st[:entrance]||[]).collect{|x|x.to_i},
        :exit=>(st[:exit]||[]).collect{|x|x.to_i},
        :rooms=>vxrd_acceptance_sorted_rooms_v10634(st),
        :edges=>vxrd_acceptance_sorted_edges_v10634(st),
        :room_types=>vxrd_acceptance_sorted_type_map_v10634(st[:room_types_v10601]||{}),
        :event_room_types=>vxrd_acceptance_sorted_type_map_v10634(st[:event_room_types_v10601]||{}),
        :event_positions=>vxrd_acceptance_event_positions_v10634,
        :consumed=>consumed,
        :water_rects=>rects,
        :tile_checksum=>vxrd_acceptance_tile_checksum_v10634
      }
      snap[:crc32]=vxrd_acceptance_crc_v10634(snap)
      snap
    rescue
      nil
    end

    def vxrd_acceptance_compare_snapshots_v10634(a,b)
      return [:missing_snapshot] if a==nil || b==nil
      keys=[:code,:run,:floor,:max_floor,:run_seed,:floor_seed,:layout_seed,:active_pool,
        :map_id,:player,:entrance,:exit,:rooms,:edges,:room_types,:event_room_types,
        :event_positions,:consumed,:water_rects,:tile_checksum]
      bad=[]
      keys.each{|k|bad << k unless a[k]==b[k]}
      bad
    rescue
      [:compare_error]
    end

    #--------------------------------------------------------------------------
    # Detached semantic probes on the real H12 production floor.
    #--------------------------------------------------------------------------
    def vxrd_acceptance_detached_probes_v10634
      s=hunt_runtime_session_v10605 rescue nil
      st=vxrd_state_v10582 rescue nil
      return {:pass=>false,:bad=>[:no_h12]} if s==nil || st==nil || s[:code].to_s.upcase!='H12'
      bad=[]
      counts=(st[:room_type_counts_v10601]||{}).dup
      required=[:treasure,:rare_nest,:elite,:recovery]
      required.each{|t|bad << ('room_'+t.to_s).to_sym if counts[t].to_i<=0}
      bad << :entrance unless counts[:entrance].to_i==1
      bad << :exit unless counts[:exit].to_i==1

      wall=respond_to?(:vxrd_wall_geometry_audit_v10592) ? vxrd_wall_geometry_audit_v10592 : {:pass=>false}
      water=respond_to?(:vxrd_regular_water_audit_v10593) ? vxrd_regular_water_audit_v10593 : {:pass=>false}
      visual=respond_to?(:vxrd_room_visual_audit_v10607) ? vxrd_room_visual_audit_v10607 : {:pass=>false}
      bad << :wall unless wall[:pass]
      bad << :water unless water[:pass]
      bad << :room_visual unless visual[:pass]

      # Exit gate negative + positive semantics without advancing the floor.
      gate0=respond_to?(:hunt_runtime_floor_gate_v10610) ? hunt_runtime_floor_gate_v10610 : {:pass=>false}
      stats=s[:vxrd_runtime_stats_v10604]||={}
      had_fw=stats.has_key?(:floor_wins)
      stats[:floor_wins]={} unless stats[:floor_wins].is_a?(Hash)
      f=s[:vxrd_floor_count_v10584].to_i
      had_f=stats[:floor_wins].has_key?(f)
      old_f=stats[:floor_wins][f]
      stats[:floor_wins][f]=1
      gate1=respond_to?(:hunt_runtime_floor_gate_v10610) ? hunt_runtime_floor_gate_v10610 : {:pass=>false}
      if had_f;stats[:floor_wins][f]=old_f;else;stats[:floor_wins].delete(f);end
      stats.delete(:floor_wins) unless had_fw
      exit_gate=(!gate0[:pass] && gate1[:pass])
      bad << :exit_gate unless exit_gate

      # Rare Nest request: request-only, no battle launch.
      rare_pass=false
      begin
        c=Marshal.load(Marshal.dump(s))
        c[:room_encounter_context_v10602]=:rare_nest
        r=phase_div_hunt_request_v10555(c)
        setup=r==nil ? []:(r[:enemy_setup]||[])
        rare_pass=setup.any? do |row|
          mods=row[4].is_a?(Hash) ? row[4] : {}
          mods[:rare_nest_v10602] ? true:false
        end
      rescue
        rare_pass=false
      end
      bad << :rare_request unless rare_pass

      # Elite request: request-only, no battle launch.
      elite_pass=false
      begin
        c=Marshal.load(Marshal.dump(s))
        c[:room_encounter_context_v10602]=:elite
        r=phase_div_hunt_request_v10555(c)
        elite_pass=(r!=nil && r[:elite_rate_v084].to_i==100 && r[:elite_max_v084].to_i==1 &&
          r[:elite_profile_v084].to_s=='standard_elite')
      rescue
        elite_pass=false
      end
      bad << :elite_request unless elite_pass

      # Treasure dry-run from the actual Treasure room. Player position restored.
      treasure_pass=false
      begin
        tid=(st[:room_types_v10601]||{}).keys.find{|id|(st[:room_types_v10601]||{})[id]==:treasure}
        room=(st[:rooms]||[]).find{|r|r[:id].to_i==tid.to_i} unless tid==nil
        if room!=nil && $game_player!=nil
          ox=$game_player.x.to_i;oy=$game_player.y.to_i;od=$game_player.direction.to_i
          $game_player.moveto(room[:cx].to_i,room[:cy].to_i)
          tr=hunt_room_treasure_v10602(true)
          treasure_pass=(tr.is_a?(Hash) && tr[:reason]!=:not_treasure_room && tr[:reason]!=:already_claimed)
          $game_player.moveto(ox,oy);$game_player.set_direction(od) if $game_player.respond_to?(:set_direction)
        end
      rescue
        treasure_pass=false
      end
      bad << :treasure_dry_run unless treasure_pass

      recovery=respond_to?(:hunt_recovery_apply_v10606) ? hunt_recovery_apply_v10606(true) : nil
      recovery_pass=(recovery.is_a?(Hash) && recovery[:revive]==false && recovery[:ratio].to_f>0.0)
      bad << :recovery_no_revive unless recovery_pass

      {:pass=>bad.empty?,:bad=>bad,:room_counts=>counts,:wall=>wall[:pass],:water=>water[:pass],
        :room_visual=>visual[:pass],:exit_gate=>exit_gate,:rare_request=>rare_pass,
        :elite_request=>elite_pass,:treasure_dry_run=>treasure_pass,
        :recovery_no_revive=>recovery_pass}
    rescue
      {:pass=>false,:bad=>[:probe_error]}
    end

    #--------------------------------------------------------------------------
    # Flow
    #--------------------------------------------------------------------------
    def begin_vxrd_final_acceptance_v10634(menu_index=11)
      if vxrd_final_acceptance_pass_v10634?
        hunt_runtime_message_v10604(['VXRD Windows Integrated Acceptance 已 PASS',
          'Random Hunt structural runtime 已封版。','隨機地圖測試工具仍可保留作後續 issue-driven QA。']) rescue nil
        $scene=Scene_Map.new unless $scene.is_a?(Scene_Map)
        return true
      end
      old=hunt_runtime_session_v10605 rescue nil
      state={:overall=>:active,:stage=>:prepare,:started_frame=>(Graphics.frame_count.to_i rescue 0),
        :seed=>VXRD_FINAL_ACCEPTANCE_SEED_V10634,:menu_index=>menu_index.to_i,
        :h12_clear_before=>(respond_to?(:hunt_clear_count_v10629) ? hunt_clear_count_v10629('H12').to_i : 0),
        :preexisting_run=>(old==nil ? nil:old[:code].to_s.upcase),:bad=>[]}
      $game_system.pmd_vxrd_final_acceptance_v10634=state
      write_vxrd_final_acceptance_log_v10634(:begin)
      if old!=nil
        state[:stage]=:retreat_preexisting
        ok=hunt_runtime_finish_v10605(:retreat,false)
        unless ok
          return fail_vxrd_final_acceptance_v10634(:preexisting_retreat_failed)
        end
        state[:stage]=:pending_h12
        write_project_state_log(false) rescue nil
        return true
      end
      state[:stage]=:pending_h12
      start_vxrd_final_acceptance_h12_v10634
    rescue
      fail_vxrd_final_acceptance_v10634(:begin_error)
    end

    def start_vxrd_final_acceptance_h12_v10634
      s=vxrd_final_acceptance_state_v10634
      return false if s==nil || s[:overall]==:pass
      return false if $game_message!=nil && $game_message.busy
      s[:stage]=:launching_h12
      ok=run_random_hunt_windows_acceptance_v10628('H12',:event,VXRD_FINAL_ACCEPTANCE_SEED_V10634)
      unless ok
        return fail_vxrd_final_acceptance_v10634(:h12_launch_failed)
      end
      write_vxrd_final_acceptance_log_v10634(:h12_launch)
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:h12_launch_error)
    end

    def on_vxrd_final_acceptance_h12_generated_v10634
      s=vxrd_final_acceptance_state_v10634
      return true if s==nil || s[:stage]!=:launching_h12
      hs=hunt_runtime_session_v10605 rescue nil
      return fail_vxrd_final_acceptance_v10634(:wrong_hunt_after_launch) if hs==nil || hs[:code].to_s.upcase!='H12'
      probes=vxrd_acceptance_detached_probes_v10634
      s[:probes]=probes
      return fail_vxrd_final_acceptance_v10634(:h12_probe_failed) unless probes[:pass]
      snap=vxrd_acceptance_snapshot_v10634
      return fail_vxrd_final_acceptance_v10634(:initial_snapshot_failed) if snap==nil
      s[:initial_snapshot_crc]=snap[:crc32].to_i
      s[:stage]=:await_save
      s[:manual_visual]=:pending
      write_vxrd_final_acceptance_log_v10634(:h12_ready)
      write_project_state_log(false) rescue nil
      hunt_runtime_message_v10604([
        'VXRD 最終驗收｜H12 已就緒',
        '特殊房／水域／出口 Gate 已背景語意檢查 PASS。',
        '現在只做 1 件事：Menu 存檔，然後立刻讀回同一個檔。',
        '讀檔後會自動比對地圖並完成撤退＋H21 Gate。'
      ]) rescue nil
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:h12_ready_error)
    end

    def vxrd_final_acceptance_before_save_v10634
      s=vxrd_final_acceptance_state_v10634
      return true if s==nil || s[:stage]!=:await_save
      snap=vxrd_acceptance_snapshot_v10634
      return fail_vxrd_final_acceptance_v10634(:save_snapshot_failed) if snap==nil
      s[:saved_snapshot]=snap
      s[:saved_snapshot_crc]=snap[:crc32].to_i
      s[:stage]=:await_load
      write_vxrd_final_acceptance_log_v10634(:saved)
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:save_hook_error)
    end

    def vxrd_final_acceptance_after_load_raw_v10634
      s=vxrd_final_acceptance_state_v10634
      return true if s==nil || s[:stage]!=:await_load
      s[:stage]=:loaded_pending_resume
      true
    rescue
      false
    end

    def vxrd_final_acceptance_after_map_resume_v10634
      s=vxrd_final_acceptance_state_v10634
      return true if s==nil || s[:stage]!=:loaded_pending_resume
      return fail_vxrd_final_acceptance_v10634(:resume_not_map090) if $game_map==nil || $game_map.map_id.to_i!=VXRD_HUNT_RUNTIME_MAP_ID_V10604
      after=vxrd_acceptance_snapshot_v10634
      before=s[:saved_snapshot]
      bad=vxrd_acceptance_compare_snapshots_v10634(before,after)
      s[:loaded_snapshot_crc]=(after==nil ? 0:after[:crc32].to_i)
      s[:save_load_bad]=bad
      s[:save_load_pass]=bad.empty?
      unless bad.empty?
        return fail_vxrd_final_acceptance_v10634(:save_load_mismatch)
      end
      s[:manual_visual]=:pass_by_continue
      s[:stage]=:postload_confirm
      s[:postload_frame]=(Graphics.frame_count.to_i rescue 0)
      write_vxrd_final_acceptance_log_v10634(:save_load_pass)
      write_project_state_log(false) rescue nil
      hunt_runtime_message_v10604([
        'Save / Load Continuity PASS',
        'Floor／Seed／Active Pool／BSP／事件位置／Tiles 全部一致。',
        '畫面確認正常後關閉這段訊息即可。',
        '系統接著會自動撤退並驗證 H21 Legendary Gate。'
      ]) rescue nil
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:resume_compare_error)
    end

    def vxrd_final_acceptance_auto_retreat_v10634
      s=vxrd_final_acceptance_state_v10634
      return false if s==nil || s[:stage]!=:postload_confirm
      hs=hunt_runtime_session_v10605 rescue nil
      return fail_vxrd_final_acceptance_v10634(:no_h12_before_retreat) if hs==nil || hs[:code].to_s.upcase!='H12'
      s[:retreat_stats_before]=Marshal.load(Marshal.dump(hs[:vxrd_runtime_stats_v10604]||{})) rescue (hs[:vxrd_runtime_stats_v10604]||{}).dup
      s[:origin_expected]=(hs[:vxrd_origin_v10604]||{}).dup
      s[:stage]=:retreating_h12
      ok=hunt_runtime_finish_v10605(:retreat,false)
      return fail_vxrd_final_acceptance_v10634(:retreat_call_failed) unless ok
      result=$game_system.pmd_vxrd_hunt_last_result_v10605 rescue nil
      s[:retreat_result]=result
      bonus=result==nil ? nil:result[:completion_bonus]
      labels=bonus.is_a?(Hash) ? (bonus[:labels]||[]) : []
      same_stats=(result!=nil && (result[:stats]||{})==s[:retreat_stats_before])
      clear_after=respond_to?(:hunt_clear_count_v10629) ? hunt_clear_count_v10629('H12').to_i : s[:h12_clear_before].to_i
      s[:retreat_pass]=(result!=nil && result[:reason].to_s=='retreat' && labels.empty? && same_stats &&
        clear_after.to_i==s[:h12_clear_before].to_i)
      return fail_vxrd_final_acceptance_v10634(:retreat_semantics_failed) unless s[:retreat_pass]
      s[:stage]=:await_return_origin
      write_vxrd_final_acceptance_log_v10634(:retreat_pass)
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:retreat_error)
    end

    def vxrd_final_acceptance_after_return_v10634
      s=vxrd_final_acceptance_state_v10634
      return true if s==nil || s[:stage]!=:await_return_origin
      origin=s[:origin_expected]||{}
      expected=origin[:map_id].to_i;expected=2 if expected<=0 || expected==VXRD_HUNT_RUNTIME_MAP_ID_V10604
      s[:return_origin_pass]=($game_map!=nil && $game_map.map_id.to_i==expected)
      return fail_vxrd_final_acceptance_v10634(:return_origin_failed) unless s[:return_origin_pass]
      s[:stage]=:h21_gate_pending
      write_vxrd_final_acceptance_log_v10634(:return_origin_pass)
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:return_origin_error)
    end

    def vxrd_final_acceptance_h21_gate_v10634
      s=vxrd_final_acceptance_state_v10634
      return false if s==nil || s[:stage]!=:h21_gate_pending
      return false if $game_message!=nil && $game_message.busy
      before_pending=($game_temp==nil ? nil:$game_temp.pmd_vxrd_hunt_pending_v10604)
      before_session=hunt_runtime_session_v10605 rescue nil
      gate=hunt_runtime_launch_gate_v10626('H21') rescue {:pass=>false,:reason=>:gate_error}
      launch=start_hunt_dungeon_v10604('H21',:event,1063421) rescue false
      after_pending=($game_temp==nil ? nil:$game_temp.pmd_vxrd_hunt_pending_v10604)
      after_session=hunt_runtime_session_v10605 rescue nil
      sem=hunt_runtime_semantics_audit_v10626 rescue {:h21_unlocked=>0,:h21_total=>0}
      no_empty=(after_pending==nil && (after_session==nil || after_session[:code].to_s.upcase!='H21'))
      expected_locked=(!gate[:pass] && gate[:reason].to_s=='legend_circuit_locked' && sem[:h21_unlocked].to_i==0)
      s[:h21_gate]=gate
      s[:h21_launch_return]=launch
      s[:h21_no_empty_run]=no_empty
      s[:h21_gate_pass]=(expected_locked && !launch && no_empty)
      return fail_vxrd_final_acceptance_v10634(:h21_gate_failed) unless s[:h21_gate_pass]
      s[:stage]=:final_notice_pending
      s[:overall]=:pass
      s[:completed_frame]=(Graphics.frame_count.to_i rescue 0)
      write_vxrd_final_acceptance_log_v10634(:pass)
      write_project_state_log(false) rescue nil
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:h21_gate_error)
    end

    def fail_vxrd_final_acceptance_v10634(reason)
      s=vxrd_final_acceptance_state_v10634
      if s==nil && $game_system!=nil
        s={};$game_system.pmd_vxrd_final_acceptance_v10634=s
      end
      if s!=nil
        s[:overall]=:fail;s[:stage]=:failed;s[:failed_reason]=reason.to_sym
        s[:bad]||=[];s[:bad] << reason.to_sym unless s[:bad].include?(reason.to_sym)
      end
      write_vxrd_final_acceptance_log_v10634(:fail) rescue nil
      write_project_state_log(false) rescue nil
      hunt_runtime_message_v10604(['VXRD 最終驗收 FAIL',reason.to_s,
        '請保留 PMD_VXRD_WindowsAcceptance_LATEST.log。','只有 FAIL 才需要把 LOG 丟回來。']) rescue nil
      false
    rescue
      false
    end

    #--------------------------------------------------------------------------
    # Final log
    #--------------------------------------------------------------------------
    def write_vxrd_final_acceptance_log_v10634(action)
      s=vxrd_final_acceptance_state_v10634 || {}
      p=s[:probes]||{}
      gate=s[:h21_gate]||{}
      result=s[:retreat_result]
      lines=[]
      lines << 'PMD VXRD Windows Integrated Acceptance'
      lines << 'VERSION='+project_version.to_s
      lines << 'CONDUCTOR=v1.06.34'
      lines << 'ACTION='+action.to_s
      lines << 'OVERALL='+((s[:overall]||:pending).to_s.upcase)
      lines << 'STAGE='+(s[:stage]||:pending).to_s
      lines << 'PRODUCTION_H12=1'
      lines << 'H12_RUN_SEED='+s[:seed].to_i.to_s
      lines << 'H12_SPECIAL_ROOM_COVERAGE='+(p[:pass] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'H12_ROOM_COUNTS='+(p[:room_counts]||{}).inspect
      lines << 'H12_WALL='+(p[:wall] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'H12_WATER='+(p[:water] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'H12_ROOM_VISUAL='+(p[:room_visual] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'EXIT_WIN_GATE_DETACHED='+(p[:exit_gate] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'RARE_NEST_REQUEST_DETACHED='+(p[:rare_request] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'ELITE_REQUEST_DETACHED='+(p[:elite_request] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'TREASURE_DRY_RUN='+(p[:treasure_dry_run] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'RECOVERY_NO_REVIVE='+(p[:recovery_no_revive] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'SAVE_LOAD='+(s[:save_load_pass] ? 'PASS':(s[:save_load_bad] ? 'FAIL':'PENDING'))
      lines << 'SAVE_SNAPSHOT_CRC32='+sprintf('%08X',s[:saved_snapshot_crc].to_i)
      lines << 'LOAD_SNAPSHOT_CRC32='+sprintf('%08X',s[:loaded_snapshot_crc].to_i)
      lines << 'SAVE_LOAD_MISMATCHES='+(s[:save_load_bad]||[]).collect{|x|x.to_s}.join(',')
      lines << 'MANUAL_VISUAL='+((s[:manual_visual]||:pending).to_s.upcase)
      lines << 'RETREAT='+(s[:retreat_pass] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'RETREAT_REASON='+(result==nil ? '':result[:reason].to_s)
      bonus=result==nil ? nil:result[:completion_bonus]
      labels=bonus.is_a?(Hash) ? (bonus[:labels]||[]) : []
      lines << 'RETREAT_COMPLETION_BONUS_LABELS='+labels.join(',')
      lines << 'H12_CLEAR_COUNT_UNCHANGED='+(s[:retreat_pass] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'RETURN_ORIGIN='+(s[:return_origin_pass] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'H21_GATE='+(s[:h21_gate_pass] ? 'PASS':'PENDING_OR_FAIL')
      lines << 'H21_GATE_REASON='+gate[:reason].to_s
      lines << 'H21_EMPTY_RUN_CREATED='+(s[:h21_no_empty_run]==false ? '1':'0')
      lines << 'H21_LAUNCH_RETURN='+(s[:h21_launch_return] ? 'TRUE':'FALSE')
      lines << 'FAILED_REASON='+(s[:failed_reason]||'').to_s
      lines << 'NEXT_GATE='+(s[:overall]==:pass ? 'H01-H21_CONTENTIZATION':'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      File.open(VXRD_FINAL_ACCEPTANCE_LOG_V10634,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    #--------------------------------------------------------------------------
    # ProjectState v22
    #--------------------------------------------------------------------------
    alias pmd_ac_v10634_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10634_write_project_state_log)
    def project_version
      '1.06.34'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10634_write_project_state_log(force)
      return false unless r
      s=vxrd_final_acceptance_state_v10634 || {}
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=22')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.34')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_WINDOWS_FINAL_ACCEPTANCE_CONDUCTOR+BATTLE_PRESENTATION_SEALED')
      next_target=(s[:overall]==:pass ? 'HUNT_H01-H21_CONTENTIZATION':'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET='+next_target)
      if s[:overall]==:pass
        text=text.gsub(/VXRD_WINDOWS_ACCEPTANCE_STATE=[^\r\n]+/,'VXRD_WINDOWS_ACCEPTANCE_STATE=PASS')
        text=text.gsub(/VXRD_WINDOWS_INTEGRATED_ACCEPTANCE=[^\r\n]+/,'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE=PASS')
      end
      text=text.gsub(/\r?\nVXRD_FINAL_ACCEPTANCE_V10634_BEGIN.*?VXRD_FINAL_ACCEPTANCE_V10634_END\r?\n/m,"\r\n")
      p=s[:probes]||{}
      lines=[]
      lines << ''
      lines << 'VXRD_FINAL_ACCEPTANCE_V10634_BEGIN'
      lines << 'VXRD_FINAL_ACCEPTANCE_CONDUCTOR=READY'
      lines << 'VXRD_FINAL_ACCEPTANCE_STATE='+((s[:overall]||:pending).to_s.upcase)
      lines << 'VXRD_FINAL_ACCEPTANCE_STAGE='+(s[:stage]||:pending).to_s
      lines << 'VXRD_FINAL_ACCEPTANCE_H12_SEED='+VXRD_FINAL_ACCEPTANCE_SEED_V10634.to_s
      lines << 'VXRD_FINAL_ACCEPTANCE_ROOM_COVERAGE='+(p[:pass] ? 'PASS':'PENDING')
      lines << 'VXRD_FINAL_ACCEPTANCE_SAVE_LOAD='+(s[:save_load_pass] ? 'PASS':'PENDING')
      lines << 'VXRD_FINAL_ACCEPTANCE_RETREAT='+(s[:retreat_pass] ? 'PASS':'PENDING')
      lines << 'VXRD_FINAL_ACCEPTANCE_H21_GATE='+(s[:h21_gate_pass] ? 'PASS':'PENDING')
      lines << 'VXRD_FINAL_ACCEPTANCE_LOG='+VXRD_FINAL_ACCEPTANCE_LOG_V10634
      lines << 'VXRD_FINAL_ACCEPTANCE_USER_ACTION=ONE_REAL_SAVE_THEN_LOAD'
      lines << 'VXRD_FINAL_ACCEPTANCE_LOG_REQUIRED_ON_PASS=0'
      lines << 'VXRD_FINAL_ACCEPTANCE_LOG_REQUIRED_ON_FAIL=1'
      lines << 'VXRD_FINAL_ACCEPTANCE_NEXT_GATE='+(s[:overall]==:pass ? 'H01-H21_CONTENTIZATION':'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      lines << 'VXRD_FINAL_ACCEPTANCE_V10634_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

#===============================================================================
# Save / Load hooks: exactly one real Windows serialization cycle.
#===============================================================================
class Scene_File
  alias pmd_ac_v10634_write_save_data write_save_data unless method_defined?(:pmd_ac_v10634_write_save_data)
  alias pmd_ac_v10634_read_save_data read_save_data unless method_defined?(:pmd_ac_v10634_read_save_data)
  def write_save_data(file)
    PMD_AC.vxrd_final_acceptance_before_save_v10634 rescue nil
    pmd_ac_v10634_write_save_data(file)
  end
  def read_save_data(file)
    pmd_ac_v10634_read_save_data(file)
    PMD_AC.vxrd_final_acceptance_after_load_raw_v10634 rescue nil
  end
end

#===============================================================================
# H12 generation hook.
#===============================================================================
module PMD_AC
  class << self
    alias pmd_ac_v10634_hunt_runtime_generate_after_transfer_v10604 hunt_runtime_generate_after_transfer_v10604 unless method_defined?(:pmd_ac_v10634_hunt_runtime_generate_after_transfer_v10604)
    def hunt_runtime_generate_after_transfer_v10604
      r=pmd_ac_v10634_hunt_runtime_generate_after_transfer_v10604
      on_vxrd_final_acceptance_h12_generated_v10634 if r
      r
    rescue
      false
    end
  end
end

#===============================================================================
# Scene_Map: compare after v1.06.09 resume, then conduct the remaining steps.
#===============================================================================
class Scene_Map
  alias pmd_ac_v10634_start start unless method_defined?(:pmd_ac_v10634_start)
  alias pmd_ac_v10634_update update unless method_defined?(:pmd_ac_v10634_update)
  def start
    pmd_ac_v10634_start
    PMD_AC.vxrd_final_acceptance_after_map_resume_v10634 rescue nil
  end
  def update
    pmd_ac_v10634_update
    begin
      s=PMD_AC.vxrd_final_acceptance_state_v10634
      return if s==nil || s[:overall]==:fail
      busy=($game_message!=nil && $game_message.busy)
      if s[:stage]==:pending_h12 && !busy && ($game_map==nil || $game_map.map_id.to_i!=PMD_AC::VXRD_HUNT_RUNTIME_MAP_ID_V10604)
        PMD_AC.start_vxrd_final_acceptance_h12_v10634
      elsif s[:stage]==:postload_confirm && !busy
        age=(Graphics.frame_count.to_i rescue 0)-s[:postload_frame].to_i
        PMD_AC.vxrd_final_acceptance_auto_retreat_v10634 if age>=12
      elsif s[:stage]==:h21_gate_pending && !busy
        PMD_AC.vxrd_final_acceptance_h21_gate_v10634
      elsif s[:stage]==:final_notice_pending && !busy
        s[:stage]=:complete
        PMD_AC.write_vxrd_final_acceptance_log_v10634(:complete)
        PMD_AC.write_project_state_log(false) rescue nil
        PMD_AC.hunt_runtime_message_v10604([
          'VXRD Windows Integrated Acceptance｜PASS',
          'H12 Save/Load/Retreat + H21 Gate 全部通過。',
          'Random Hunt structural runtime 已封版。',
          '下一階段：H01–H21 生態／內容差異化。'
        ]) rescue nil
      end
    rescue
    end
  end
end

#===============================================================================
# Confirm return-to-origin after the retreat transfer.
#===============================================================================
class Game_Player
  alias pmd_ac_v10634_perform_transfer perform_transfer unless method_defined?(:pmd_ac_v10634_perform_transfer)
  def perform_transfer
    pmd_ac_v10634_perform_transfer
    begin
      PMD_AC.vxrd_final_acceptance_after_return_v10634
    rescue
    end
  end
end

#===============================================================================
# Dev menu: while Gate 1 is pending, replace the old test label with one action.
# After PASS, the original Random Map test selector is restored automatically.
#===============================================================================
class Scene_Menu
  def create_command_window
    s1=Vocab::item;s2=Vocab::skill;s3=Vocab::equip;s4=Vocab::status
    qa=PMD_AC.vxrd_final_acceptance_pass_v10634? ? '隨機地圖測試' : 'VXRD最終驗收'
    cmds=[s1,s2,s3,s4,'PMD基地','隊伍／BOX','AI策略','圖鑑','補給品','狩獵','挑戰',qa,'素材測試',Vocab::save,Vocab::game_end]
    @command_window=Window_Command.new(160,cmds)
    PMD_AC.command_window_refresh_after_resize_v10562(@command_window,344)
    @command_window.index=@menu_index
    if $game_party.members.size==0
      @command_window.draw_item(0,false);@command_window.draw_item(1,false)
      @command_window.draw_item(2,false);@command_window.draw_item(3,false)
    end
    @command_window.draw_item(13,false) if $game_system.save_disabled
  end

  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel;$scene=Scene_Map.new;return
    end
    return unless Input.trigger?(Input::C)
    idx=@command_window.index
    if $game_party.members.size==0 && idx<4
      Sound.play_buzzer;return
    elsif $game_system.save_disabled && idx==13
      Sound.play_buzzer;return
    end
    Sound.play_decision
    case idx
    when 0
      $scene=Scene_Item.new
    when 1,2,3
      start_actor_selection
    when 4
      PMD_AC.open_pmd_hub_v10561(idx)
    when 5
      PMD_AC.open_party_scene_v10561(idx)
    when 6
      PMD_AC.open_ai_scene_v10561(idx)
    when 7
      PMD_AC.open_collection_scene_v10561(idx)
    when 8
      PMD_AC.open_supply_scene_v10561(idx)
    when 9
      PMD_AC.open_hunt_scene_v10561(idx)
    when 10
      PMD_AC.open_challenge_scene_v10561(idx)
    when 11
      if PMD_AC.vxrd_final_acceptance_pass_v10634?
        PMD_AC.open_vxrd_autotest_scene_v10587(idx)
      else
        PMD_AC.begin_vxrd_final_acceptance_v10634(idx)
      end
    when 12
      PMD_AC.open_visual_test_scene_v10561(idx)
    when 13
      $scene=Scene_File.new(true,false,false)
    when 14
      $scene=Scene_End.new
    end
  end
end
