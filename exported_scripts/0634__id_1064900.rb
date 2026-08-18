# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD FS-Style Event Template Map Authority v1.06.49
#-------------------------------------------------------------------------------
# Adopts the proven Forest Symphony RandomDungeon event-template architecture:
# - Map090 remains the generated Hunt runtime map.
# - Map091 is an event-template library loaded from Data/Map091.rvdata.
# - Source events are never transferred as live source objects. Selected
#   RPG::Event templates are deep-cloned into Map090 as generated Game_Events.
# - Event pages / graphics / conditions / triggers / command lists stay editor
#   authored instead of being reconstructed in Ruby.
# - Floor filters, weighted pools, per-source caps, unique/shared/fixed/control
#   modifiers are parsed from event names.
# - v1.06.47/48 marker presentation is bypassed for template-owned events, so
#   the event's own RPG Maker VX graphic is the visual authority.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDFSEventTemplateMapAuthority_v10649']=true

class Game_System
  attr_accessor :pmd_vxrd_event_template_overrides_v10649
end

module PMD_AC
  VXRD_EVENT_TEMPLATE_DEFAULT_MAP_ID_V10649=91
  VXRD_EVENT_TEMPLATE_MAP_BY_HUNT_V10649={}
  (1..21).each{|i|VXRD_EVENT_TEMPLATE_MAP_BY_HUNT_V10649['H'+sprintf('%02d',i)]=91}

  VXRD_EVENT_TEMPLATE_ROLE_TAGS_V10649={
    :entrance=>'<PMD_RD_ENTRANCE>',
    :exit=>'<PMD_RD_EXIT>',
    :encounter=>'<PMD_RD_ENCOUNTER>',
    :rare=>'<PMD_RD_RARE>',
    :elite=>'<PMD_RD_ELITE>',
    :treasure=>'<PMD_RD_TREASURE>',
    :recovery=>'<PMD_RD_RECOVERY>',
    :retreat=>'<PMD_RD_RETREAT>',
    :info=>'<PMD_RD_INFO>'
  }

  class << self
    def vxrd_event_template_map_id_v10649(code=nil)
      c=code.to_s.upcase
      if c.empty?
        s=phase_div_hunt_session_v10555 rescue nil
        c=s[:code].to_s.upcase unless s==nil
      end
      begin
        h=$game_system==nil ? nil : $game_system.pmd_vxrd_event_template_overrides_v10649
        return h[c].to_i if h.is_a?(Hash) && h[c].to_i>0
      rescue
      end
      (VXRD_EVENT_TEMPLATE_MAP_BY_HUNT_V10649[c]||VXRD_EVENT_TEMPLATE_DEFAULT_MAP_ID_V10649).to_i
    rescue
      VXRD_EVENT_TEMPLATE_DEFAULT_MAP_ID_V10649
    end

    # Optional persistent override for later Hunt-specific event libraries.
    # Example: PMD_AC.vxrd_set_event_template_map_v10649('H14', 92)
    def vxrd_set_event_template_map_v10649(code,map_id)
      return false if $game_system==nil
      c=code.to_s.upcase;mid=map_id.to_i
      return false if c.empty? || mid<=0
      h=$game_system.pmd_vxrd_event_template_overrides_v10649
      h={} unless h.is_a?(Hash)
      h[c]=mid
      $game_system.pmd_vxrd_event_template_overrides_v10649=h
      true
    rescue
      false
    end

    def vxrd_load_event_template_map_v10649(map_id)
      mid=map_id.to_i
      return nil if mid<=0
      load_data(sprintf('Data/Map%03d.rvdata',mid))
    rescue
      nil
    end

    def vxrd_template_event_name_v10649(rpg_event)
      rpg_event==nil ? '' : rpg_event.name.to_s
    rescue
      ''
    end

    def vxrd_template_event_role_v10649(rpg_event_or_name)
      name=rpg_event_or_name.respond_to?(:name) ? rpg_event_or_name.name.to_s : rpg_event_or_name.to_s
      # More specific encounter roles first.
      return :rare if name.index(VXRD_EVENT_TEMPLATE_ROLE_TAGS_V10649[:rare])
      return :elite if name.index(VXRD_EVENT_TEMPLATE_ROLE_TAGS_V10649[:elite])
      VXRD_EVENT_TEMPLATE_ROLE_TAGS_V10649.each do |role,tag|
        next if [:rare,:elite].include?(role)
        return role if name.index(tag)
      end
      nil
    rescue
      nil
    end

    def vxrd_template_floor_set_v10649(name)
      text=name.to_s
      out=[]
      text.scan(/<PMD_RD_FLOOR\s*:\s*(\d+)\s*>/i){|m|out << m[0].to_i}
      text.scan(/<PMD_RD_FLOORS\s*:\s*([^>]+)>/i) do |m|
        m[0].to_s.split(',').each do |token|
          t=token.to_s.strip
          if t =~ /^(\d+)\s*-\s*(\d+)$/
            a=$1.to_i;b=$2.to_i;a,b=b,a if a>b
            (a..b).each{|n|out << n}
          elsif t =~ /^\d+$/
            out << t.to_i
          end
        end
      end
      out.uniq.sort
    rescue
      []
    end

    def vxrd_template_enabled_on_floor_v10649?(name,floor)
      set=vxrd_template_floor_set_v10649(name)
      set.empty? || set.include?(floor.to_i)
    rescue
      true
    end

    def vxrd_template_hunt_set_v10649(name)
      text=name.to_s.upcase
      out=[]
      text.scan(/<PMD_RD_HUNT\s*:\s*(H\d{2})\s*>/i){|m|out << m[0].to_s.upcase}
      text.scan(/<PMD_RD_HUNTS\s*:\s*([^>]+)>/i) do |m|
        m[0].to_s.split(',').each do |token|
          t=token.to_s.strip.upcase
          out << t if t =~ /^H\d{2}$/
        end
      end
      out.uniq.sort
    rescue
      []
    end

    def vxrd_template_enabled_for_hunt_v10649?(name,code)
      set=vxrd_template_hunt_set_v10649(name)
      set.empty? || set.include?(code.to_s.upcase)
    rescue
      true
    end

    def vxrd_template_weight_v10649(name)
      m=name.to_s.match(/<PMD_RD_WEIGHT\s*:\s*(\d+)\s*>/i)
      v=m==nil ? 100:m[1].to_i
      v<=0 ? 1:v
    rescue
      100
    end

    def vxrd_template_max_v10649(name)
      return 1 if name.to_s =~ /<PMD_RD_(UNIQUE|NO_REPEAT)>/i
      m=name.to_s.match(/<PMD_RD_MAX\s*:\s*(\d+)\s*>/i)
      return nil if m==nil
      v=m[1].to_i
      v<=0 ? nil:v
    rescue
      nil
    end

    def vxrd_template_shared_v10649?(name)
      name.to_s.index('<PMD_RD_SHARED>')!=nil
    rescue
      false
    end

    def vxrd_template_fixed_v10649?(name)
      name.to_s.index('<PMD_RD_FIXED>')!=nil
    rescue
      false
    end

    def vxrd_template_control_v10649?(name)
      name.to_s.index('<PMD_RD_CONTROL>')!=nil
    rescue
      false
    end

    def vxrd_template_entries_v10649(map,floor,role=nil,code=nil)
      return [] if map==nil
      events=map.events rescue nil
      return [] unless events.is_a?(Hash)
      out=[]
      events.keys.sort.each do |id|
        ev=events[id];next if ev==nil
        r=vxrd_template_event_role_v10649(ev)
        next if r==nil
        next if role!=nil && r!=role.to_sym
        name=ev.name.to_s
        next unless vxrd_template_enabled_on_floor_v10649?(name,floor)
        next unless vxrd_template_enabled_for_hunt_v10649?(name,code)
        out << {:source_id=>id.to_i,:event=>ev,:role=>r,
          :weight=>vxrd_template_weight_v10649(name),:max=>vxrd_template_max_v10649(name),
          :shared=>vxrd_template_shared_v10649?(name),
          :fixed=>vxrd_template_fixed_v10649?(name),:control=>vxrd_template_control_v10649?(name)}
      end
      out
    rescue
      []
    end

    def vxrd_template_weighted_pick_v10649(entries,rng,used)
      available=[];total=0
      (entries||[]).each do |e|
        cap=e[:max]
        count=used[e[:source_id]].to_i
        next if cap!=nil && count>=cap.to_i
        w=[e[:weight].to_i,1].max
        available << [e,w];total+=w
      end
      return nil if available.empty? || total<=0
      roll=rng.rand(total)
      acc=0
      available.each do |row|
        acc+=row[1]
        return row[0] if roll<acc
      end
      available[-1][0]
    rescue
      nil
    end

    def vxrd_template_room_present_v10649?(state,type)
      return false if state==nil
      (state[:room_types_v10601]||{}).values.include?(type.to_sym)
    rescue
      false
    end

    # Preserve the established total of three encounter nodes per floor. Rare
    # and Elite consume one of those three slots when their room exists.
    def vxrd_template_requested_counts_v10649(state,floor)
      rare=vxrd_template_room_present_v10649?(state,:rare_nest) ? 1:0
      elite=vxrd_template_room_present_v10649?(state,:elite) ? 1:0
      normal=[3-rare-elite,0].max
      {
        :entrance=>1,:exit=>1,:retreat=>1,:info=>1,
        :treasure=>(vxrd_template_room_present_v10649?(state,:treasure) ? 1:0),
        :recovery=>(vxrd_template_room_present_v10649?(state,:recovery) ? 1:0),
        :rare=>rare,:elite=>elite,:encounter=>normal
      }
    rescue
      {:entrance=>1,:exit=>1,:retreat=>1,:info=>1,:encounter=>3}
    end

    def vxrd_template_plan_v10649(template_map,state,floor,map_id)
      counts=vxrd_template_requested_counts_v10649(state,floor)
      seed=((state==nil ? 0:state[:seed].to_i) ^ (floor.to_i*83492791) ^ (map_id.to_i*19349663) ^ 0x10649E7) & 0x7fffffff
      rng=VXRD_RNG_V10582.new(seed)
      plan=[]
      [:entrance,:exit,:retreat,:info,:treasure,:recovery,:rare,:elite,:encounter].each do |role|
        requested=counts[role].to_i;next if requested<=0
        entries=vxrd_template_entries_v10649(template_map,floor,role,state==nil ? nil:state[:code])
        next if entries.empty?
        used={}
        requested.times do
          picked=vxrd_template_weighted_pick_v10649(entries,rng,used)
          break if picked==nil
          used[picked[:source_id]]=used[picked[:source_id]].to_i+1
          plan << picked.dup
        end
      end
      plan
    rescue
      []
    end

    def vxrd_template_runtime_event_id_v10649(floor,serial,entry)
      if entry[:shared]
        return 800+entry[:source_id].to_i
      end
      1000+floor.to_i*100+serial.to_i
    rescue
      1000+floor.to_i*100+serial.to_i
    end

    def vxrd_template_generated_name_v10649(source_name,map_id,source_id)
      source_name.to_s+'<PMD_RD_GENERATED><PMD_RD_SOURCE:'+map_id.to_i.to_s+':'+source_id.to_i.to_s+'>'
    rescue
      source_name.to_s+'<PMD_RD_GENERATED>'
    end

    def vxrd_template_remove_runtime_events_v10649
      return 0 if $game_map==nil
      map=$game_map.instance_variable_get(:@map) rescue nil
      game_events=$game_map.events||{}
      raw_events=map==nil ? {}:(map.events rescue {})
      ids=[]
      game_events.each do |id,ev|
        name=vxrd_game_event_name_v10584(ev) rescue ''
        ids << id if name.to_s.index('<PMD_RD_')!=nil
      end
      ids.each do |id|
        game_events.delete(id)
        raw_events.delete(id) if raw_events.respond_to?(:delete)
      end
      ids.size
    rescue
      0
    end

    def vxrd_template_materialize_events_v10649(state,code,floor)
      return {:pass=>false,:reason=>:no_game_map} if $game_map==nil || state==nil
      source_map_id=vxrd_event_template_map_id_v10649(code)
      template=vxrd_load_event_template_map_v10649(source_map_id)
      return {:pass=>false,:reason=>:template_missing,:map_id=>source_map_id} if template==nil
      plan=vxrd_template_plan_v10649(template,state,floor,source_map_id)
      removed=vxrd_template_remove_runtime_events_v10649
      runtime_map=$game_map.instance_variable_get(:@map) rescue nil
      return {:pass=>false,:reason=>:runtime_map_missing} if runtime_map==nil
      runtime_map.events={} unless runtime_map.events.is_a?(Hash)
      generated=[];serial=1
      plan.each do |entry|
        source=entry[:event];next if source==nil
        begin
          clone=Marshal.load(Marshal.dump(source))
        rescue
          begin;clone=source.clone;rescue;next;end
        end
        event_id=vxrd_template_runtime_event_id_v10649(floor,serial,entry);serial+=1
        clone.id=event_id if clone.respond_to?(:id=)
        clone.instance_variable_set(:@id,event_id) unless clone.respond_to?(:id=)
        clone.name=vxrd_template_generated_name_v10649(clone.name,source_map_id,entry[:source_id]) if clone.respond_to?(:name=)
        clone.instance_variable_set(:@name,vxrd_template_generated_name_v10649(clone.instance_variable_get(:@name),source_map_id,entry[:source_id])) unless clone.respond_to?(:name=)
        runtime_map.events[event_id]=clone
        ge=Game_Event.new($game_map.map_id,clone)
        ge.instance_variable_set(:@pmd_vxrd_template_event_v10649,true)
        ge.instance_variable_set(:@pmd_vxrd_template_source_map_v10649,source_map_id)
        ge.instance_variable_set(:@pmd_vxrd_template_source_id_v10649,entry[:source_id].to_i)
        ge.instance_variable_set(:@pmd_vxrd_template_role_v10649,entry[:role])
        ge.instance_variable_set(:@pmd_vxrd_template_fixed_v10649,entry[:fixed] ? true:false)
        ge.instance_variable_set(:@pmd_vxrd_template_control_v10649,entry[:control] ? true:false)
        ge.instance_variable_set(:@pmd_vxrd_template_source_x_v10649,source.x.to_i)
        ge.instance_variable_set(:@pmd_vxrd_template_source_y_v10649,source.y.to_i)
        $game_map.events[event_id]=ge
        generated << {:event_id=>event_id,:source_id=>entry[:source_id].to_i,:role=>entry[:role],:shared=>entry[:shared] ? true:false}
      end
      state[:event_template_map_id_v10649]=source_map_id
      state[:event_template_plan_v10649]=generated
      state[:event_template_materialized_v10649]=true
      {:pass=>true,:map_id=>source_map_id,:removed=>removed,:generated=>generated.size,:plan=>generated}
    rescue
      {:pass=>false,:reason=>:materialize_error}
    end

    def vxrd_template_event_owned_v10649?(ev)
      ev!=nil && ev.instance_variable_get(:@pmd_vxrd_template_event_v10649)==true
    rescue
      false
    end

    # Template-owned Game_Event roles are authoritative, independent of name
    # parsing or older tag-hash ordering.
    alias pmd_ac_v10649_game_event_tag_v10584 vxrd_game_event_tag_v10584 unless method_defined?(:pmd_ac_v10649_game_event_tag_v10584)
    def vxrd_game_event_tag_v10584(ev)
      if vxrd_template_event_owned_v10649?(ev)
        r=ev.instance_variable_get(:@pmd_vxrd_template_role_v10649)
        return r unless r==nil
      end
      pmd_ac_v10649_game_event_tag_v10584(ev)
    rescue
      nil
    end

    # Template event graphics authored on Map091 replace v1.06.47/48 markers.
    alias pmd_ac_v10649_event_owned_marker_profile_v10648 vxrd_event_owned_marker_profile_v10648 unless method_defined?(:pmd_ac_v10649_event_owned_marker_profile_v10648)
    def vxrd_event_owned_marker_profile_v10648(character)
      return nil if vxrd_template_event_owned_v10649?(character)
      pmd_ac_v10649_event_owned_marker_profile_v10648(character)
    rescue
      nil
    end

    def vxrd_template_fixed_positions_v10649(code,floor)
      mid=vxrd_event_template_map_id_v10649(code)
      map=vxrd_load_event_template_map_v10649(mid);return [] if map==nil
      vxrd_template_entries_v10649(map,floor,nil,code).find_all{|e|e[:fixed]}.collect{|e|[e[:event].x.to_i,e[:event].y.to_i]}.uniq
    rescue
      []
    end

    # Feed FIXED template anchors into layout generation before the old runtime
    # generation pipeline runs, mirroring the FS preserve/connect behavior.
    alias pmd_ac_v10649_hunt_generate_vx_floor_v10584 hunt_generate_vx_floor_v10584 unless method_defined?(:pmd_ac_v10649_hunt_generate_vx_floor_v10584)
    def hunt_generate_vx_floor_v10584(code=nil,mode=:steps,options=nil)
      s=phase_div_hunt_session_v10555 rescue nil
      c=code==nil ? (s==nil ? 'H01':s[:code].to_s.upcase) : code.to_s.upcase
      next_floor=(s==nil ? 1:(s[:vxrd_floor_count_v10584]||0).to_i+1)
      o=options.is_a?(Hash) ? options.dup : {}
      fixed=vxrd_template_fixed_positions_v10649(c,next_floor)
      o[:fixed_positions]=fixed unless fixed.empty?
      st=pmd_ac_v10649_hunt_generate_vx_floor_v10584(c,mode,o)
      return st if st==nil
      s=phase_div_hunt_session_v10555 rescue nil
      floor=s==nil ? next_floor:s[:vxrd_floor_count_v10584].to_i
      mat=vxrd_template_materialize_events_v10649(st,c,floor)
      if mat[:pass]
        rel=vxrd_relocate_events_v10584
        s[:vxrd_last_event_relocate_v10584]=rel if s!=nil
        s[:vxrd_event_template_v10649]=mat if s!=nil
        vxrd_reset_floor_events_v10606 if respond_to?(:vxrd_reset_floor_events_v10606)
      end
      st
    rescue
      st
    end

    def vxrd_template_room_for_role_v10649(state,role,used_normal)
      type=nil
      case role
      when :treasure;type=:treasure
      when :recovery;type=:recovery
      when :rare;type=:rare_nest
      when :elite;type=:elite
      when :encounter;type=:normal
      end
      return [nil,nil] if type==nil
      room=vxrd_event_pick_room_v10646(state,type,role.to_s.size*401+(used_normal||{}).size*17,used_normal)
      [room,type]
    rescue
      [nil,nil]
    end

    # Template-aware semantic placement. It uses v1.06.46's safe positioning
    # helpers but preserves the cloned event itself as the content authority.
    alias pmd_ac_v10649_relocate_events_v10584 vxrd_relocate_events_v10584 unless method_defined?(:pmd_ac_v10649_relocate_events_v10584)
    def vxrd_relocate_events_v10584
      state=vxrd_state_v10582 rescue nil
      return pmd_ac_v10649_relocate_events_v10584 unless state && state[:event_template_materialized_v10649]
      events=$game_map==nil ? {}:($game_map.events||{})
      occupied=[];placements={};room_map={};used_normal={}
      events.keys.sort.each do |id|
        ev=events[id];next unless vxrd_template_event_owned_v10649?(ev)
        role=vxrd_game_event_tag_v10584(ev);next if role==nil
        pos=nil;rtype=nil;semantic=role
        if ev.instance_variable_get(:@pmd_vxrd_template_control_v10649)==true
          pos=[ev.instance_variable_get(:@pmd_vxrd_template_source_x_v10649).to_i,ev.instance_variable_get(:@pmd_vxrd_template_source_y_v10649).to_i]
          rtype=:control
        elsif ev.instance_variable_get(:@pmd_vxrd_template_fixed_v10649)==true
          pos=[ev.instance_variable_get(:@pmd_vxrd_template_source_x_v10649).to_i,ev.instance_variable_get(:@pmd_vxrd_template_source_y_v10649).to_i]
          rtype=:fixed
        elsif role==:entrance
          pos=state[:entrance];rtype=:entrance
        elsif role==:exit
          pos=state[:exit];rtype=:exit
        elsif [:retreat,:info].include?(role)
          room=vxrd_event_rooms_of_type_v10646(state,:entrance).first
          pos=vxrd_event_pick_ranked_cell_v10646(state,room,:entrance_utility,id.to_i*137,occupied) unless room==nil
          rtype=:entrance
        else
          room,rtype=vxrd_template_room_for_role_v10649(state,role,used_normal)
          next if room==nil
          used_normal[room[:id].to_i]=true if rtype==:normal
          sem=(role==:treasure ? :treasure_focus : (role==:recovery ? :recovery_focus : (role==:rare ? :rare_focus : (role==:elite ? :elite_focus : :normal_focus))))
          pos=vxrd_event_pick_ranked_cell_v10646(state,room,sem,id.to_i*149,occupied)
          semantic=sem
        end
        next unless pos.is_a?(Array) && pos.size>=2
        ev.moveto(pos[0].to_i,pos[1].to_i)
        occupied << [pos[0].to_i,pos[1].to_i]
        ev.instance_variable_set(:@pmd_vxrd_room_type_v10601,rtype)
        room_map[id]=rtype
        placements[id]={:tag=>role,:room_type=>rtype,:x=>pos[0].to_i,:y=>pos[1].to_i,
          :semantic=>semantic,:template_source_map=>ev.instance_variable_get(:@pmd_vxrd_template_source_map_v10649),
          :template_source_id=>ev.instance_variable_get(:@pmd_vxrd_template_source_id_v10649)}
      end
      state[:event_room_types_v10601]=room_map
      state[:event_semantic_placement_v10646]=placements
      state[:event_reserved_v10646]={}
      placements.each_value{|row|state[:event_reserved_v10646][[row[:x],row[:y]]]=true}
      {:pass=>true,:template_map_id=>state[:event_template_map_id_v10649],:moved=>placements.size,
       :room_types=>room_map,:semantic_v10646=>placements,:fs_style_template_authority=>true}
    rescue
      {:pass=>false,:moved=>0,:fs_style_template_authority=>true}
    end

    def vxrd_event_template_audit_v10649
      map_id=VXRD_EVENT_TEMPLATE_DEFAULT_MAP_ID_V10649
      map=vxrd_load_event_template_map_v10649(map_id)
      bad=[];roles={}
      if map==nil
        bad << :template_map_missing
      else
        vxrd_template_entries_v10649(map,1,nil,nil).each{|e|roles[e[:role]]=roles[e[:role]].to_i+1}
        [:entrance,:exit,:encounter,:rare,:elite,:treasure,:recovery,:retreat,:info].each{|r|bad << ('missing_'+r.to_s).to_sym if roles[r].to_i<=0}
      end
      {:pass=>bad.empty?,:template_map_id=>map_id,:roles=>roles,:role_types=>roles.keys.size,
       :floor_filter=>true,:hunt_filter=>true,:weighted_pool=>true,:max_unique=>true,:fixed_control=>true,
       :event_page_clone=>true,:marker_override=>false,:second_game_map_runtime=>false,:bad=>bad}
    rescue
      {:pass=>false,:template_map_id=>0,:bad=>[:audit_error]}
    end

    alias pmd_ac_v10649_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10649_write_project_state_log)
    def project_version
      '1.06.49'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10649_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=35')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.49')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_FS_STYLE_EVENT_TEMPLATE_MAP_AUTHORITY')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=EVENT_TEMPLATE_WINDOWS_ACCEPTANCE+LANDMARK_TEMPLATE_II')
        text=text.gsub(/\r?\nVXRD_EVENT_TEMPLATE_V10649_BEGIN.*?VXRD_EVENT_TEMPLATE_V10649_END\r?\n/m,"\r\n")
        a=vxrd_event_template_audit_v10649
        lines=[]
        lines << ''
        lines << 'VXRD_EVENT_TEMPLATE_V10649_BEGIN'
        lines << 'VXRD_EVENT_TEMPLATE_AUTHORITY='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'VXRD_EVENT_TEMPLATE_MAP_ID='+a[:template_map_id].to_i.to_s
        lines << 'VXRD_EVENT_TEMPLATE_ROLE_TYPES='+a[:role_types].to_i.to_s+'/9'
        lines << 'VXRD_EVENT_TEMPLATE_FLOOR_FILTER=1'
        lines << 'VXRD_EVENT_TEMPLATE_HUNT_FILTER=1'
        lines << 'VXRD_EVENT_TEMPLATE_WEIGHTED_POOL=1'
        lines << 'VXRD_EVENT_TEMPLATE_MAX_UNIQUE=1'
        lines << 'VXRD_EVENT_TEMPLATE_FIXED_CONTROL=1'
        lines << 'VXRD_EVENT_TEMPLATE_RPG_EVENT_DEEP_CLONE=1'
        lines << 'VXRD_EVENT_TEMPLATE_GRAPHIC_AUTHORITY=RPG_EVENT_PAGE'
        lines << 'VXRD_EVENT_TEMPLATE_MARKER_OVERRIDE=DISABLED_FOR_TEMPLATE_EVENTS'
        lines << 'VXRD_EVENT_TEMPLATE_SECOND_GAME_MAP_RUNTIME=0'
        lines << 'VXRD_EVENT_TEMPLATE_WINDOWS_ACCEPTANCE=PENDING_USER_RUN'
        lines << 'VXRD_EVENT_TEMPLATE_V10649_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
