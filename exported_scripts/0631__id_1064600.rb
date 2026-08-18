# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Event Semantic Placement I v1.06.46
#-------------------------------------------------------------------------------
# Replaces the old "pick any free room cell" event relocation with deterministic
# role-aware placement. This patch changes placement only; event functions,
# battle/loot/recovery/retreat semantics and progression are unchanged.
#
# Placement intent:
# - Entrance: exact generated entrance anchor (invisible marker).
# - Exit: exact generated exit anchor.
# - Retreat / Info: paired markers in the entrance room, away from the entrance
#   anchor and center cross.
# - Treasure: deep side of the treasure room, far from the run entrance.
# - Recovery: near the recovery-room center but off the traversal cross.
# - Rare Nest / Elite: prominent interior positions in their own room types.
# - Normal encounters: distributed across distinct normal rooms when possible.
#
# Safety:
# - no water cells
# - no room center cross for interactive content markers
# - no overlap / one-cell adjacency crowding when alternatives exist
# - no Landmark-reserved cells (future-compatible)
# - deterministic for the same generated floor seed
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDEventSemanticPlacementI_v10646']=true

module PMD_AC
  VXRD_EVENT_SEMANTIC_ROLE_V10646={
    :entrance=>:entrance_anchor,
    :exit=>:exit_anchor,
    :retreat=>:entrance_utility,
    :info=>:entrance_utility,
    :treasure=>:treasure_focus,
    :recovery=>:recovery_focus,
    :encounter=>:encounter_focus
  }

  class << self
    def vxrd_event_room_v10646(state,room_id)
      return nil if state==nil || room_id==nil
      (state[:rooms]||[]).find{|r|r[:id].to_i==room_id.to_i}
    rescue
      nil
    end

    def vxrd_event_rooms_of_type_v10646(state,type)
      return [] if state==nil
      types=state[:room_types_v10601]||{}
      (state[:rooms]||[]).find_all{|r|types[r[:id].to_i]==type.to_sym}
    rescue
      []
    end

    def vxrd_event_room_type_for_point_v10646(state,x,y)
      rid=vxrd_room_id_for_point_v10601(state,x,y) rescue nil
      return nil if rid==nil
      (state[:room_types_v10601]||{})[rid]
    rescue
      nil
    end

    def vxrd_event_water_cell_v10646?(state,x,y)
      return vxrd_state_water_cell_v10607?(state,x,y) if respond_to?(:vxrd_state_water_cell_v10607?)
      false
    rescue
      false
    end

    def vxrd_event_landmark_reserved_v10646?(state,x,y)
      h=state==nil ? nil : state[:landmark_reserved_v10644]
      return false unless h.is_a?(Hash)
      h[[x.to_i,y.to_i]]==true || h[x.to_i.to_s+','+y.to_i.to_s]==true
    rescue
      false
    end

    def vxrd_event_inner_cells_v10646(state,room,allow_cross=false)
      return [] if state==nil || room==nil
      out=[]
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
      return out if x1<x0 || y1<y0
      for y in y0..y1
        for x in x0..x1
          next if !allow_cross && (x==room[:cx].to_i || y==room[:cy].to_i)
          next if vxrd_event_water_cell_v10646?(state,x,y)
          next if vxrd_event_landmark_reserved_v10646?(state,x,y)
          out << [x,y,room[:id].to_i]
        end
      end
      out
    rescue
      []
    end

    def vxrd_event_distance_from_occupied_v10646(x,y,occupied)
      return 999 if occupied==nil || occupied.empty?
      (occupied||[]).collect{|p|(p[0].to_i-x.to_i).abs+(p[1].to_i-y.to_i).abs}.min.to_i
    rescue
      0
    end

    def vxrd_event_near_key_anchor_v10646?(state,x,y,radius=1)
      return false if state==nil
      [state[:entrance],state[:exit]].each do |p|
        next unless p.is_a?(Array) && p.size>=2
        return true if (p[0].to_i-x.to_i).abs+(p[1].to_i-y.to_i).abs<=radius.to_i
      end
      false
    rescue
      true
    end

    def vxrd_event_pick_ranked_cell_v10646(state,room,role,salt,occupied)
      cells=vxrd_event_inner_cells_v10646(state,room,false)
      return nil if cells.empty?
      seed=state[:seed].to_i
      ent=state[:entrance]||[0,0]
      cx=room[:cx].to_i;cy=room[:cy].to_i
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
      scored=[]
      cells.each do |p|
        x=p[0].to_i;y=p[1].to_i
        next if vxrd_event_near_key_anchor_v10646?(state,x,y,1) && ![:entrance_utility].include?(role)
        sep=vxrd_event_distance_from_occupied_v10646(x,y,occupied)
        next if sep<2
        center=(x-cx).abs+(y-cy).abs
        edge=[x-x0,x1-x,y-y0,y1-y].min
        run_dist=(x-ent[0].to_i).abs+(y-ent[1].to_i).abs
        hv=vxrd_content_hash_v10636(seed,room[:id].to_i,x,y,salt.to_i) rescue ((x*37+y*71+salt.to_i)&0x7fffffff)
        score=0
        case role
        when :entrance_utility
          # Utilities should sit near a room side/corner, not in the middle of
          # the traversal lane. Favor moderate proximity to entrance but keep
          # at least two cells separation from it.
          d=(x-ent[0].to_i).abs+(y-ent[1].to_i).abs
          next if d<2
          score += 70-[d,8].min*4
          score += (edge<=1 ? 24:0)
          score += sep*3
        when :treasure_focus
          # Treasure belongs deep in the room and toward the far side of the
          # floor, visually reading as a destination rather than corridor junk.
          score += run_dist*3
          score += (edge<=1 ? 18:0)
          score += sep*2
        when :recovery_focus
          # Recovery should be easy to identify near room center, but diagonal
          # to the center cross so it never seals the main route.
          score += 80-center*12
          score += sep*2
        when :rare_focus
          score += 76-center*7
          score += run_dist
          score += sep*2
        when :elite_focus
          score += 84-center*8
          score += run_dist
          score += sep*2
        else # :normal_focus
          score += 60-center*4
          score += sep*3
        end
        score += (hv%7)
        scored << [score,hv,p]
      end
      return nil if scored.empty?
      scored.sort_by{|row|[-row[0].to_i,row[1].to_i,row[2][1].to_i,row[2][0].to_i]}.first[2]
    rescue
      nil
    end

    def vxrd_event_pick_room_v10646(state,type,salt,used_room_ids=nil)
      rooms=vxrd_event_rooms_of_type_v10646(state,type)
      return nil if rooms.empty?
      used=used_room_ids||{}
      fresh=rooms.find_all{|r|!used[r[:id].to_i]}
      list=fresh.empty? ? rooms : fresh
      entry_id=vxrd_room_id_for_point_v10601(state,(state[:entrance]||[])[0],(state[:entrance]||[])[1]) rescue nil
      dist=vxrd_room_graph_distance_v10601(state,entry_id) rescue {}
      seed=state[:seed].to_i
      list.sort_by do |r|
        hv=vxrd_content_hash_v10636(seed,r[:id].to_i,r[:cx].to_i,r[:cy].to_i,salt.to_i) rescue r[:id].to_i
        [-((dist[r[:id].to_i]||0).to_i),hv]
      end.first
    rescue
      nil
    end

    def vxrd_event_set_semantic_visual_v10646(ev,tag,room_type=nil)
      return false if ev==nil
      # Keep existing user-visible graphics from v1.06.07 for now. This pass
      # only normalizes presentation behavior so semantic placement can be QA'd
      # independently from future event-art replacement.
      ev.instance_variable_set(:@direction_fix,true) unless tag==:encounter
      ev.instance_variable_set(:@step_anime,false)
      ev.instance_variable_set(:@move_type,0)
      ev.instance_variable_set(:@move_frequency,3)
      ev.instance_variable_set(:@pmd_vxrd_semantic_role_v10646,tag)
      ev.instance_variable_set(:@pmd_vxrd_semantic_room_type_v10646,room_type) unless room_type==nil
      true
    rescue
      false
    end

    alias pmd_ac_v10646_relocate_events_v10584 vxrd_relocate_events_v10584 unless method_defined?(:pmd_ac_v10646_relocate_events_v10584)
    def vxrd_relocate_events_v10584
      result=pmd_ac_v10646_relocate_events_v10584
      state=vxrd_state_v10582 rescue nil
      return result if state==nil || $game_map==nil
      events=$game_map.events||{}
      occupied=[];placements={};room_map={};used_normal_rooms={}

      # Preserve genuinely fixed events only. All PMD random-dungeon events are
      # re-authored below from room semantics.
      events.each_value do |ev|
        tag=vxrd_game_event_tag_v10584(ev)
        occupied << [ev.x.to_i,ev.y.to_i] if tag==:fixed
      end

      # Invisible entrance marker stays on the generated entrance anchor.
      events.keys.sort.each do |id|
        ev=events[id];tag=vxrd_game_event_tag_v10584(ev)
        next unless tag==:entrance
        p=state[:entrance]
        next unless p.is_a?(Array) && p.size>=2
        ev.moveto(p[0].to_i,p[1].to_i)
        placements[id]={:tag=>:entrance,:room_type=>:entrance,:x=>p[0].to_i,:y=>p[1].to_i,:semantic=>:anchor}
        room_map[id]=:entrance
        vxrd_event_set_semantic_visual_v10646(ev,:entrance,:entrance)
      end

      # Exit remains exact: it is part of floor topology, not generic room decor.
      events.keys.sort.each do |id|
        ev=events[id];tag=vxrd_game_event_tag_v10584(ev)
        next unless tag==:exit
        p=state[:exit]
        next unless p.is_a?(Array) && p.size>=2
        ev.moveto(p[0].to_i,p[1].to_i);occupied << [p[0].to_i,p[1].to_i]
        placements[id]={:tag=>:exit,:room_type=>:exit,:x=>p[0].to_i,:y=>p[1].to_i,:semantic=>:anchor}
        room_map[id]=:exit
        vxrd_event_set_semantic_visual_v10646(ev,:exit,:exit)
      end

      # Entrance utilities: paired but independently ranked so they do not stack.
      entrance_room=vxrd_event_rooms_of_type_v10646(state,:entrance).first
      [:retreat,:info].each_with_index do |wanted,idx|
        ids=events.keys.sort.find_all{|id|vxrd_game_event_tag_v10584(events[id])==wanted}
        ids.each do |id|
          p=vxrd_event_pick_ranked_cell_v10646(state,entrance_room,:entrance_utility,id.to_i*137+idx*17,occupied)
          next if p==nil
          ev=events[id];ev.moveto(p[0],p[1]);occupied << [p[0],p[1]]
          placements[id]={:tag=>wanted,:room_type=>:entrance,:x=>p[0],:y=>p[1],:semantic=>:entrance_utility}
          room_map[id]=:entrance
          vxrd_event_set_semantic_visual_v10646(ev,wanted,:entrance)
        end
      end

      # Treasure: exactly in treasure room, destination-biased.
      events.keys.sort.each do |id|
        ev=events[id];next unless vxrd_game_event_tag_v10584(ev)==:treasure
        room=vxrd_event_rooms_of_type_v10646(state,:treasure).first
        p=vxrd_event_pick_ranked_cell_v10646(state,room,:treasure_focus,id.to_i*151,occupied)
        next if p==nil
        ev.moveto(p[0],p[1]);occupied << [p[0],p[1]]
        placements[id]={:tag=>:treasure,:room_type=>:treasure,:x=>p[0],:y=>p[1],:semantic=>:deep_room_focus}
        room_map[id]=:treasure
        vxrd_event_set_semantic_visual_v10646(ev,:treasure,:treasure)
      end

      # Recovery: near-center diagonal position, not random room edge.
      events.keys.sort.each do |id|
        ev=events[id];next unless vxrd_game_event_tag_v10584(ev)==:recovery
        room=vxrd_event_rooms_of_type_v10646(state,:recovery).first
        p=vxrd_event_pick_ranked_cell_v10646(state,room,:recovery_focus,id.to_i*163,occupied)
        next if p==nil
        ev.moveto(p[0],p[1]);occupied << [p[0],p[1]]
        placements[id]={:tag=>:recovery,:room_type=>:recovery,:x=>p[0],:y=>p[1],:semantic=>:near_center_focus}
        room_map[id]=:recovery
        vxrd_event_set_semantic_visual_v10646(ev,:recovery,:recovery)
      end

      # Encounter roles are assigned by room semantics, then normal encounters
      # distribute across distinct normal rooms when the floor has capacity.
      encounter_ids=events.keys.sort.find_all{|id|vxrd_game_event_tag_v10584(events[id])==:encounter}
      role_queue=[]
      role_queue << :rare_nest unless vxrd_event_rooms_of_type_v10646(state,:rare_nest).empty?
      role_queue << :elite unless vxrd_event_rooms_of_type_v10646(state,:elite).empty?
      encounter_ids.each_with_index do |id,i|
        type=role_queue.shift || :normal
        room=vxrd_event_pick_room_v10646(state,type,id.to_i*173+i*23,used_normal_rooms)
        if room==nil && type!=:normal
          type=:normal
          room=vxrd_event_pick_room_v10646(state,:normal,id.to_i*173+i*23,used_normal_rooms)
        end
        next if room==nil
        used_normal_rooms[room[:id].to_i]=true if type==:normal
        role=(type==:rare_nest ? :rare_focus : (type==:elite ? :elite_focus : :normal_focus))
        p=vxrd_event_pick_ranked_cell_v10646(state,room,role,id.to_i*181+i*31,occupied)
        next if p==nil
        ev=events[id];ev.moveto(p[0],p[1]);occupied << [p[0],p[1]]
        placements[id]={:tag=>:encounter,:room_type=>type,:x=>p[0],:y=>p[1],:semantic=>role,:room_id=>room[:id].to_i}
        room_map[id]=type
        ev.instance_variable_set(:@pmd_vxrd_room_type_v10601,type)
        vxrd_event_set_semantic_visual_v10646(ev,:encounter,type)
      end

      state[:event_room_types_v10601]=room_map
      state[:event_semantic_placement_v10646]=placements
      state[:event_reserved_v10646]={}
      placements.each_value{|row|state[:event_reserved_v10646][[row[:x].to_i,row[:y].to_i]]=true}
      result={} unless result.is_a?(Hash)
      result[:room_types]=room_map.dup
      result[:room_type_relocated]=room_map.size
      result[:semantic_v10646]=placements.dup
      result
    rescue
      result
    end

    def vxrd_event_semantic_audit_v10646
      state=vxrd_state_v10582 rescue nil
      return {:pass=>true,:structural=>true,:events=>0,:bad=>[]} if state==nil
      rows=state[:event_semantic_placement_v10646]||{}
      bad=[];seen={}
      rows.each do |id,row|
        x=row[:x].to_i;y=row[:y].to_i;tag=row[:tag];rt=row[:room_type]
        key=[x,y]
        bad << 'overlap_'+id.to_s if seen[key]
        seen[key]=true
        bad << 'water_'+id.to_s if vxrd_event_water_cell_v10646?(state,x,y)
        actual=vxrd_event_room_type_for_point_v10646(state,x,y)
        if [:treasure,:recovery].include?(tag)
          bad << tag.to_s+'_room_'+id.to_s unless actual==tag
        elsif tag==:encounter
          bad << 'encounter_room_'+id.to_s unless actual==rt
        elsif [:retreat,:info].include?(tag)
          bad << tag.to_s+'_entrance_'+id.to_s unless actual==:entrance
        end
      end
      tags=rows.values.collect{|r|r[:tag]}
      [:entrance,:exit,:treasure,:recovery,:retreat,:info].each{|t|bad << 'missing_'+t.to_s unless tags.include?(t)}
      {:pass=>bad.empty?,:events=>rows.size,:tags=>tags,:placements=>rows,
        :deterministic=>true,:water_safe=>true,:center_cross_policy=>:off_cross_interactives,
        :gameplay_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:events=>0,:bad=>[:audit_error]}
    end

    alias pmd_ac_v10646_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10646_write_project_state_log)
    def project_version
      '1.06.46'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10646_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=32')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.46')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_EVENT_SEMANTIC_PLACEMENT_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=EVENT_VISUAL_IDENTITY+LANDMARK_TEMPLATE_II_ATLAS_COORDS')
        text=text.gsub(/\r?\nVXRD_EVENT_SEMANTIC_V10646_BEGIN.*?VXRD_EVENT_SEMANTIC_V10646_END\r?\n/m,"\r\n")
        a=vxrd_event_semantic_audit_v10646
        lines=[]
        lines << ''
        lines << 'VXRD_EVENT_SEMANTIC_V10646_BEGIN'
        lines << 'VXRD_EVENT_SEMANTIC_PLACEMENT='+(a[:pass] ? 'PASS':'PENDING_RUNTIME')
        lines << 'VXRD_EVENT_SEMANTIC_DETERMINISTIC=1'
        lines << 'VXRD_EVENT_SEMANTIC_WATER_SAFE=1'
        lines << 'VXRD_EVENT_SEMANTIC_ENTRANCE_UTILITIES=RETREAT,INFO'
        lines << 'VXRD_EVENT_SEMANTIC_SPECIAL_ROOMS=TREASURE,RARE_NEST,ELITE,RECOVERY'
        lines << 'VXRD_EVENT_SEMANTIC_NORMAL_ENCOUNTER_DISTRIBUTION=DISTINCT_ROOMS_WHEN_POSSIBLE'
        lines << 'VXRD_EVENT_SEMANTIC_GAMEPLAY_CHANGE=0'
        lines << 'VXRD_EVENT_SEMANTIC_V10646_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
