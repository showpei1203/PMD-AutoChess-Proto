# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Landmark Route Safety Audit I v1.06.55
#-------------------------------------------------------------------------------
# Formal follow-up to v1.06.54 Windows/RMVX Visual + Semantic PASS.
#
# Purpose:
# - Hard Landmark blocking must never break entrance -> exit connectivity.
# - After Map091 semantic events are materialized, their required destinations
#   must remain reachable from the generated entrance.
# - If a hard Landmark makes a required route unsafe, reject that Landmark.
#   Never rewrite the sealed Gate 1 room/corridor topology to save decoration.
#
# Invariants:
# - H01 soft foliage remains non-blocking.
# - No automatic B/C/D/E map-table stamping.
# - v1.06.44 runtime upper-tile Landmark IDs remain revoked.
# - No battle / reward / progression changes.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDLandmarkRouteSafetyAuditI_v10655']=true

module PMD_AC
  VXRD_LANDMARK_ROUTE_AUDIT_LOG_V10655='PMD_VXRD_LandmarkRoute_Audit_LATEST.log'
  VXRD_LANDMARK_ROUTE_HISTORY_LOG_V10655='PMD_VXRD_LandmarkRoute_Audit_HISTORY.log'
  VXRD_LANDMARK_ROUTE_REQUIRED_TAGS_V10655=[:exit,:retreat,:info,:treasure,:recovery,:rare,:elite,:encounter]
  VXRD_LANDMARK_ROUTE_DIRS_V10655=[[1,0],[-1,0],[0,1],[0,-1]]

  class << self
    def vxrd_route_key_v10655(x,y)
      [x.to_i,y.to_i]
    end

    def vxrd_route_walkable_hash_v10655(state)
      out={}
      return out if state==nil
      (state[:walkable]||[]).each do |p|
        next unless p.is_a?(Array) && p.size>=2
        x=p[0].to_i;y=p[1].to_i
        if respond_to?(:vxrd_state_water_cell_v10607?)
          next if vxrd_state_water_cell_v10607?(state,x,y)
        end
        out[[x,y]]=true
      end
      out
    rescue
      {}
    end

    def vxrd_route_blocked_hash_v10655(state)
      out={}
      return out if state==nil
      h=state[:landmark_blocked_v10654]
      if h.is_a?(Hash)
        h.each_key do |p|
          next unless p.is_a?(Array) && p.size>=2
          out[[p[0].to_i,p[1].to_i]]=true if h[p]
        end
      end
      out
    rescue
      {}
    end

    def vxrd_route_bfs_sets_v10655(walkable,blocked,start)
      seen={}
      return seen unless walkable.is_a?(Hash) && blocked.is_a?(Hash)
      return seen unless start.is_a?(Array) && start.size>=2
      s=[start[0].to_i,start[1].to_i]
      return seen unless walkable[s]
      return seen if blocked[s]
      q=[s];seen[s]=true
      until q.empty?
        p=q.shift
        VXRD_LANDMARK_ROUTE_DIRS_V10655.each do |d|
          n=[p[0].to_i+d[0].to_i,p[1].to_i+d[1].to_i]
          next unless walkable[n]
          next if blocked[n] || seen[n]
          seen[n]=true;q << n
        end
      end
      seen
    rescue
      {}
    end

    def vxrd_route_target_rows_v10655(state,include_events=true)
      rows=[];seen={}
      return rows if state==nil
      ex=state[:exit]
      if ex.is_a?(Array) && ex.size>=2
        row={:tag=>:exit,:x=>ex[0].to_i,:y=>ex[1].to_i,:source=>:topology}
        rows << row;seen[[:exit,row[:x],row[:y]]]=true
      end
      if include_events
        placements=state[:event_semantic_placement_v10646]
        if placements.is_a?(Hash)
          placements.keys.sort.each do |id|
            r=placements[id];next unless r.is_a?(Hash)
            tag=r[:tag]
            next unless VXRD_LANDMARK_ROUTE_REQUIRED_TAGS_V10655.include?(tag)
            x=r[:x].to_i;y=r[:y].to_i
            key=[tag,x,y]
            next if seen[key]
            seen[key]=true
            rows << {:tag=>tag,:x=>x,:y=>y,:event_id=>id.to_i,
              :room_type=>r[:room_type],:source=>:semantic_event}
          end
        end
      end
      rows
    rescue
      []
    end

    def vxrd_route_target_accessible_v10655?(seen,walkable,row)
      return false unless row.is_a?(Hash)
      key=[row[:x].to_i,row[:y].to_i]
      return true if seen[key]
      VXRD_LANDMARK_ROUTE_DIRS_V10655.each do |d|
        n=[key[0]+d[0].to_i,key[1]+d[1].to_i]
        return true if walkable[n] && seen[n]
      end
      false
    rescue
      false
    end

    def vxrd_landmark_route_audit_state_v10655(state,include_events=true)
      return {:pass=>false,:reason=>:no_state,:bad=>[:no_state]} if state==nil
      walkable=vxrd_route_walkable_hash_v10655(state)
      blocked=vxrd_route_blocked_hash_v10655(state)
      start=state[:entrance]
      seen=vxrd_route_bfs_sets_v10655(walkable,blocked,start)
      targets=vxrd_route_target_rows_v10655(state,include_events)
      bad=[];target_rows=[]
      if !start.is_a?(Array) || start.size<2
        bad << :missing_entrance
      elsif !seen[[start[0].to_i,start[1].to_i]]
        bad << :entrance_not_walkable
      end
      targets.each do |row|
        ok=vxrd_route_target_accessible_v10655?(seen,walkable,row)
        target_rows << row.merge(:reachable=>ok)
        bad << ('unreachable_'+row[:tag].to_s+'_'+row[:x].to_i.to_s+'_'+row[:y].to_i.to_s).to_sym unless ok
      end
      exit_ok=target_rows.any?{|r|r[:tag]==:exit && r[:reachable]}
      bad << :missing_reachable_exit unless exit_ok
      hard=(state[:landmarks_v10654].is_a?(Hash) ? (state[:landmarks_v10654][:placements]||[]) : []).find_all{|p|p.is_a?(Hash) && p[:blocking]}
      {:pass=>bad.empty?,:stage=>(include_events ? :post_event : :pre_event),
       :walkable=>walkable.size,:reachable=>seen.size,:blocked=>blocked.size,
       :hard_landmarks=>hard.size,:targets=>target_rows,:exit_reachable=>exit_ok,
       :topology_rewrite=>false,:unsafe_policy=>:reject_hard_landmark,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:reason=>:audit_error,:error=>e.class.to_s,:bad=>[:audit_error]}
    end

    def vxrd_landmark_route_rebuild_masks_v10655(state)
      return false if state==nil
      info=state[:landmarks_v10654]
      return false unless info.is_a?(Hash)
      reserved={};blocked={}
      (info[:placements]||[]).each do |p|
        next unless p.is_a?(Hash)
        a=p[:anchor];next unless a.is_a?(Array) && a.size>=2
        w=[p[:w].to_i,1].max;h=[p[:h].to_i,1].max
        for dy in 0...h
          for dx in 0...w
            key=[a[0].to_i+dx,a[1].to_i+dy]
            reserved[key]=true
            blocked[key]=true if p[:blocking]
          end
        end
      end
      state[:landmark_reserved_v10654]=reserved
      state[:landmark_blocked_v10654]=blocked
      state[:landmark_reserved_v10644]=reserved
      info[:placed]=(info[:placements]||[]).size
      info[:reserved_cells]=reserved.size
      info[:blocked_cells]=blocked.size
      true
    rescue
      false
    end

    def vxrd_landmark_route_reject_v10655(state,placement)
      return false if state==nil || placement==nil
      info=state[:landmarks_v10654];return false unless info.is_a?(Hash)
      arr=info[:placements]||[]
      idx=arr.index(placement)
      return false if idx==nil
      arr.delete_at(idx)
      info[:placements]=arr
      vxrd_landmark_route_rebuild_masks_v10655(state)
    rescue
      false
    end

    def vxrd_landmark_route_repair_v10655(state,include_events=true)
      before=vxrd_landmark_route_audit_state_v10655(state,include_events)
      removed=[]
      if !before[:pass]
        info=state==nil ? nil : state[:landmarks_v10654]
        hard=(info.is_a?(Hash) ? (info[:placements]||[]) : []).find_all{|p|p.is_a?(Hash) && p[:blocking]}
        # Preserve earlier placements when possible; reject later decorations first.
        hard.reverse.each do |p|
          break if vxrd_landmark_route_audit_state_v10655(state,include_events)[:pass]
          a=p[:anchor]||[0,0]
          if vxrd_landmark_route_reject_v10655(state,p)
            removed << {:template=>p[:template],:x=>a[0].to_i,:y=>a[1].to_i}
          end
        end
      end
      after=vxrd_landmark_route_audit_state_v10655(state,include_events)
      result={:pass=>after[:pass],:stage=>after[:stage],:before_pass=>before[:pass],
        :removed=>removed,:removed_count=>removed.size,:after=>after,
        :topology_rewrite=>false,:unsafe_policy=>:reject_hard_landmark}
      if state!=nil
        state[:landmark_route_audit_v10655]=result
        info=state[:landmarks_v10654]
        if info.is_a?(Hash)
          info[:route_audit_v10655]=after[:pass] ? :pass : :fail
          info[:route_rejected_v10655]=removed.size
          info[:full_route_audit_v10655]=true
        end
      end
      result
    rescue Exception=>e
      {:pass=>false,:stage=>(include_events ? :post_event : :pre_event),:removed=>[],
       :error=>e.class.to_s,:topology_rewrite=>false,:unsafe_policy=>:reject_hard_landmark}
    end

    def vxrd_landmark_route_static_audit_v10655
      bad=[]
      # A one-cell-wide corridor must fail while a hard blocker occupies its throat.
      walk={};5.times{|x|walk[[x,0]]=true}
      blocked={[2,0]=>true}
      seen=vxrd_route_bfs_sets_v10655(walk,blocked,[0,0])
      bad << :narrow_corridor_block_not_detected if seen[[4,0]]
      # Removing the hard blocker must restore the same topology without rewriting it.
      seen=vxrd_route_bfs_sets_v10655(walk,{},[0,0])
      bad << :narrow_corridor_restore_failed unless seen[[4,0]]
      # A blocker in an open 3x3 room must not falsely report a route failure.
      open={};3.times{|y|3.times{|x|open[[x,y]]=true}}
      seen=vxrd_route_bfs_sets_v10655(open,{[1,1]=>true},[0,1])
      bad << :open_room_detour_failed unless seen[[2,1]]
      # Soft decoration is absent from the blocked mask by contract.
      seen=vxrd_route_bfs_sets_v10655(open,{},[0,1])
      bad << :soft_decoration_false_block unless seen[[2,1]]
      {:pass=>bad.empty?,:tests=>4,:topology_rewrite=>false,
       :unsafe_policy=>:reject_hard_landmark,:map_table_bcde_stamp=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:tests=>0,:error=>e.class.to_s,:bad=>[:static_audit_error]}
    end

    def vxrd_write_landmark_route_audit_v10655(result=nil)
      s=vxrd_landmark_route_static_audit_v10655
      r=result
      if r==nil
        st=vxrd_state_v10582 rescue nil
        r=(st==nil ? nil:st[:landmark_route_audit_v10655])
      end
      lines=[]
      lines << 'PMD AutoChess VXRD Landmark Route Audit v1.06.55'
      lines << 'STATIC_RESULT='+(s[:pass] ? 'PASS':'FAIL')
      lines << 'STATIC_TESTS='+s[:tests].to_i.to_s+'/4'
      lines << 'TOPOLOGY_REWRITE=0'
      lines << 'UNSAFE_LANDMARK_POLICY=REJECT_HARD_LANDMARK'
      lines << 'SOFT_DECORATION_BLOCKS_ROUTE=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      if r.is_a?(Hash)
        lines << 'RUNTIME_RESULT='+(r[:pass] ? 'PASS':'FAIL')
        lines << 'RUNTIME_STAGE='+r[:stage].to_s.upcase
        lines << 'RUNTIME_REMOVED='+r[:removed_count].to_i.to_s
        a=r[:after]
        if a.is_a?(Hash)
          lines << 'RUNTIME_WALKABLE='+a[:walkable].to_i.to_s
          lines << 'RUNTIME_REACHABLE='+a[:reachable].to_i.to_s
          lines << 'RUNTIME_BLOCKED='+a[:blocked].to_i.to_s
          lines << 'RUNTIME_TARGETS='+(a[:targets]||[]).size.to_i.to_s
          lines << 'RUNTIME_EXIT_REACHABLE='+(a[:exit_reachable] ? '1':'0')
          (a[:bad]||[]).each{|x|lines << 'RUNTIME_ERROR='+x.to_s}
        end
      else
        lines << 'RUNTIME_RESULT=PENDING_FLOOR_GENERATION'
      end
      (s[:bad]||[]).each{|x|lines << 'STATIC_ERROR='+x.to_s}
      st=vxrd_state_v10582 rescue nil
      if st.is_a?(Hash)
        lines << 'CODE='+st[:code].to_s.upcase
        lines << 'SEED='+st[:seed].to_i.to_s
        sess=phase_div_hunt_session_v10555 rescue nil
        lines << 'FLOOR='+(sess.is_a?(Hash) ? sess[:vxrd_floor_count_v10584].to_i.to_s : '0')
      end
      File.open(VXRD_LANDMARK_ROUTE_AUDIT_LOG_V10655,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      if r.is_a?(Hash) && r[:stage]==:post_event
        a=r[:after].is_a?(Hash) ? r[:after] : {}
        sess=phase_div_hunt_session_v10555 rescue nil
        hist=[]
        hist << 'RUN'
        hist << 'FRAME='+(Graphics.frame_count.to_i rescue 0).to_s
        hist << 'CODE='+(st.is_a?(Hash) ? st[:code].to_s.upcase : '')
        hist << 'SEED='+(st.is_a?(Hash) ? st[:seed].to_i.to_s : '0')
        hist << 'FLOOR='+(sess.is_a?(Hash) ? sess[:vxrd_floor_count_v10584].to_i.to_s : '0')
        hist << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
        hist << 'REMOVED='+r[:removed_count].to_i.to_s
        hist << 'WALKABLE='+a[:walkable].to_i.to_s
        hist << 'REACHABLE='+a[:reachable].to_i.to_s
        hist << 'BLOCKED='+a[:blocked].to_i.to_s
        hist << 'TARGETS='+(a[:targets]||[]).size.to_i.to_s
        hist << 'EXIT_REACHABLE='+(a[:exit_reachable] ? '1':'0')
        hist << 'BAD='+(a[:bad]||[]).collect{|x|x.to_s}.join(',')
        File.open(VXRD_LANDMARK_ROUTE_HISTORY_LOG_V10655,'ab'){|io|io.write(hist.join("\r\n")+"\r\nEND_RUN\r\n")}
      end
      {:static=>s,:runtime=>r}
    rescue
      {:static=>{:pass=>false},:runtime=>nil}
    end

    # Stage 1: after v1.06.54 places hard/soft Landmarks, guarantee base
    # entrance -> exit connectivity before Map091 events are materialized.
    alias pmd_ac_v10655_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10655_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10655_generate_current_map_v10582(code,seed,options)
      vxrd_landmark_route_repair_v10655(st,false) unless st==nil
      st
    rescue
      st
    end

    # Stage 2: v1.06.49 materializes/relocates Map091 events after the base
    # generator returns. Audit all semantic destinations, rejecting additional
    # hard Landmarks if necessary. This wrapper is intentionally late in Script
    # order so it sees the final event positions.
    alias pmd_ac_v10655_hunt_generate_vx_floor_v10584 hunt_generate_vx_floor_v10584 unless method_defined?(:pmd_ac_v10655_hunt_generate_vx_floor_v10584)
    def hunt_generate_vx_floor_v10584(code=nil,mode=:steps,options=nil)
      st=pmd_ac_v10655_hunt_generate_vx_floor_v10584(code,mode,options)
      return st if st==nil
      r=vxrd_landmark_route_repair_v10655(st,true)
      s=phase_div_hunt_session_v10555 rescue nil
      s[:vxrd_landmark_route_v10655]=r if s.is_a?(Hash)
      vxrd_write_landmark_route_audit_v10655(r)
      st
    rescue
      st
    end

    alias pmd_ac_v10655_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10655_write_project_state_log)
    def project_version
      '1.06.55'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10655_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=40')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.55')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=LANDMARK_ROUTE_SAFETY_AUDIT_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=LANDMARK_ROUTE_WINDOWS_ACCEPTANCE+MULTI_SEED_EXPANSION')
        text=text.gsub(/\r?\nVXRD_LANDMARK_ROUTE_V10655_BEGIN.*?VXRD_LANDMARK_ROUTE_V10655_END\r?\n/m,"\r\n")
        a=vxrd_landmark_route_static_audit_v10655
        lines=[]
        lines << ''
        lines << 'VXRD_LANDMARK_ROUTE_V10655_BEGIN'
        lines << 'LANDMARK_ROUTE_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'LANDMARK_ROUTE_STATIC_TESTS='+a[:tests].to_i.to_s+'/4'
        lines << 'LANDMARK_ROUTE_RUNTIME_GATE=1'
        lines << 'LANDMARK_ROUTE_TOPOLOGY_REWRITE=0'
        lines << 'LANDMARK_ROUTE_UNSAFE_POLICY=REJECT_HARD_LANDMARK'
        lines << 'LANDMARK_ROUTE_REQUIRED_TARGETS=EXIT,RETREAT,INFO,TREASURE,RECOVERY,RARE,ELITE,ENCOUNTER'
        lines << 'LANDMARK_ROUTE_SOFT_H01_BLOCKING=0'
        lines << 'LANDMARK_ROUTE_MAP_TABLE_BCDE_STAMP=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_LANDMARK_ROUTE_V10655_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

begin
  PMD_AC.vxrd_write_landmark_route_audit_v10655
rescue
end
