# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Room Type Authority v1.06.01
#-------------------------------------------------------------------------------
# 將生成後房間分類為 entrance / exit / treasure / rare_nest / elite / normal。
# Room Type 只決定內容與事件擺位，不改 BSP、牆、水、通路。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRoomTypeAuthority_v10601']=true

module PMD_AC
  VXRD_ROOM_TYPE_LABEL_V10601={
    :entrance=>'入口房',:exit=>'出口房',:treasure=>'寶藏房',:rare_nest=>'稀有巢穴',
    :elite=>'菁英房',:normal=>'一般房'
  }
  VXRD_RARE_NEST_RATE_V10601={1=>18,2=>28,3=>40,4=>52,5=>65}
  VXRD_ELITE_ROOM_RATE_V10601={1=>0,2=>30,3=>42,4=>55,5=>70}

  class << self
    def vxrd_room_id_for_point_v10601(state,x,y)
      return nil if state==nil
      (state[:rooms]||[]).each do |r|
        if x.to_i>=r[:x].to_i && x.to_i<r[:x].to_i+r[:w].to_i && y.to_i>=r[:y].to_i && y.to_i<r[:y].to_i+r[:h].to_i
          return r[:id].to_i
        end
      end
      nil
    rescue
      nil
    end

    def vxrd_room_graph_distance_v10601(state,start_id)
      out={};return out if state==nil || start_id==nil
      adj={}
      (state[:rooms]||[]).each{|r|adj[r[:id].to_i]=[]}
      (state[:edges]||[]).each do |e|
        a=e[0].to_i;b=e[1].to_i
        adj[a]||=[];adj[b]||=[];adj[a] << b unless adj[a].include?(b);adj[b] << a unless adj[b].include?(a)
      end
      q=[start_id.to_i];out[start_id.to_i]=0
      until q.empty?
        a=q.shift
        (adj[a]||[]).each do |b|
          next if out.has_key?(b)
          out[b]=out[a].to_i+1;q << b
        end
      end
      out
    rescue
      {}
    end

    def vxrd_active_pool_has_rare_v10601?
      s=respond_to?(:phase_div_hunt_session_v10555) ? phase_div_hunt_session_v10555 : nil
      return false if s==nil
      (s[:active_pool]||[]).any? do |sp|
        row=phase_div_species_v10553(sp) rescue nil
        rk=row==nil ? 0 : (HUNT_RARITY_RANK_V10578[row[:spawn_rarity].to_s]||0).to_i
        rk>=2
      end
    rescue
      false
    end

    def vxrd_assign_room_types_v10601(state)
      return nil if state==nil
      rooms=(state[:rooms]||[]);return nil if rooms.empty?
      types={};entry=vxrd_room_id_for_point_v10601(state,(state[:entrance]||[])[0],(state[:entrance]||[])[1])
      exit_id=vxrd_room_id_for_point_v10601(state,(state[:exit]||[])[0],(state[:exit]||[])[1])
      types[entry]=:entrance unless entry==nil
      types[exit_id]=:exit unless exit_id==nil
      remain=rooms.collect{|r|r[:id].to_i}.find_all{|id|!types.has_key?(id)}
      dist=vxrd_room_graph_distance_v10601(state,entry)
      seed=(state[:seed].to_i ^ 0x10601A3) & 0x7fffffff
      rng=VXRD_RNG_V10582.new(seed)
      h=respond_to?(:phase_div_hunt_v10553) ? phase_div_hunt_v10553(state[:code].to_s) : nil
      tier=h==nil ? 1 : [[h[:tier].to_i,1].max,5].min
      forced=(respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?) rescue false
      if !remain.empty?
        treasure=remain.sort_by{|id|[-(dist[id]||0).to_i,id]}.first
        types[treasure]=:treasure;remain.delete(treasure)
      end
      rare_ok=vxrd_active_pool_has_rare_v10601?
      if !remain.empty? && rare_ok && (forced || rng.rand(100)<VXRD_RARE_NEST_RATE_V10601[tier].to_i)
        idx=rng.rand(remain.size);rid=remain.delete_at(idx);types[rid]=:rare_nest
      end
      if !remain.empty? && tier>=2 && (forced || rng.rand(100)<VXRD_ELITE_ROOM_RATE_V10601[tier].to_i)
        idx=rng.rand(remain.size);rid=remain.delete_at(idx);types[rid]=:elite
      end
      remain.each{|id|types[id]=:normal}
      counts={}
      types.values.each{|t|counts[t]=counts[t].to_i+1}
      state[:room_types_v10601]=types
      state[:room_type_counts_v10601]=counts
      state[:room_type_meta_v10601]={:tier=>tier,:rare_available=>rare_ok,:autotest_forced=>forced,
        :rare_rate=>VXRD_RARE_NEST_RATE_V10601[tier].to_i,:elite_rate=>VXRD_ELITE_ROOM_RATE_V10601[tier].to_i}
      state
    rescue
      state
    end

    alias pmd_ac_v10601_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10601_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10601_generate_current_map_v10582(code,seed,options)
      vxrd_assign_room_types_v10601(st) unless st==nil
      st
    rescue
      nil
    end

    def vxrd_room_cells_for_type_v10601(type)
      st=vxrd_state_v10582;return [] if st==nil
      ids=(st[:room_types_v10601]||{}).keys.find_all{|id|(st[:room_types_v10601]||{})[id]==type.to_sym}
      out=[]
      ids.each do |id|
        r=(st[:rooms]||[]).find{|x|x[:id].to_i==id.to_i};next if r==nil
        (st[:room_cells]||[]).each do |p|
          x=p[0].to_i;y=p[1].to_i
          next unless x>=r[:x].to_i+1 && x<=r[:x].to_i+r[:w].to_i-2 && y>=r[:y].to_i+1 && y<=r[:y].to_i+r[:h].to_i-2
          next if x==r[:cx].to_i || y==r[:cy].to_i
          out << [x,y,id]
        end
      end
      out
    rescue
      []
    end

    def vxrd_pick_room_type_position_v10601(type,salt,occupied)
      cells=vxrd_room_cells_for_type_v10601(type)
      cells=cells.find_all{|p|!(occupied||[]).any?{|q|(q[0].to_i-p[0].to_i).abs+(q[1].to_i-p[1].to_i).abs<2}}
      return nil if cells.empty?
      st=vxrd_state_v10582;seed=(st==nil ? 10601:st[:seed].to_i)
      rng=VXRD_RNG_V10582.new((seed ^ salt.to_i ^ 0x4D52) & 0x7fffffff)
      cells[rng.rand(cells.size)]
    rescue
      nil
    end

    alias pmd_ac_v10601_relocate_events_v10584 vxrd_relocate_events_v10584 unless method_defined?(:pmd_ac_v10601_relocate_events_v10584)
    def vxrd_relocate_events_v10584
      result=pmd_ac_v10601_relocate_events_v10584
      return result if $game_map==nil || vxrd_state_v10582==nil
      events=$game_map.events||{};occupied=[];room_map={}
      events.each_value do |ev|
        tag=vxrd_game_event_tag_v10584(ev)
        occupied << [ev.x.to_i,ev.y.to_i] if [:fixed,:entrance,:exit].include?(tag)
      end
      encounters=events.keys.sort.find_all{|id|vxrd_game_event_tag_v10584(events[id])==:encounter}
      treasures=events.keys.sort.find_all{|id|vxrd_game_event_tag_v10584(events[id])==:treasure}
      treasures.each do |id|
        ev=events[id];p=vxrd_pick_room_type_position_v10601(:treasure,id.to_i*71,occupied)
        next if p==nil
        ev.moveto(p[0],p[1]);occupied << [p[0],p[1]];room_map[id]=:treasure
        ev.instance_variable_set(:@pmd_vxrd_room_type_v10601,:treasure)
      end
      order=[]
      order << :rare_nest unless vxrd_room_cells_for_type_v10601(:rare_nest).empty?
      order << :elite unless vxrd_room_cells_for_type_v10601(:elite).empty?
      order << :normal
      encounters.each_with_index do |id,i|
        type=order[[i,order.size-1].min] || :normal
        p=vxrd_pick_room_type_position_v10601(type,id.to_i*97+i*13,occupied)
        if p==nil && type!=:normal
          type=:normal;p=vxrd_pick_room_type_position_v10601(type,id.to_i*97+i*13,occupied)
        end
        next if p==nil
        ev=events[id];ev.moveto(p[0],p[1]);occupied << [p[0],p[1]];room_map[id]=type
        ev.instance_variable_set(:@pmd_vxrd_room_type_v10601,type)
      end
      st=vxrd_state_v10582;st[:event_room_types_v10601]=room_map
      result={} unless result.is_a?(Hash)
      result[:room_type_relocated]=room_map.size
      result[:room_types]=room_map.dup
      result
    rescue
      result
    end

    def vxrd_room_type_info_v10601
      st=vxrd_state_v10582;return nil if st==nil
      {:types=>(st[:room_types_v10601]||{}).dup,:counts=>(st[:room_type_counts_v10601]||{}).dup,
       :events=>(st[:event_room_types_v10601]||{}).dup,:meta=>(st[:room_type_meta_v10601]||{}).dup}
    rescue
      nil
    end

    def vxrd_room_type_audit_v10601
      st=vxrd_state_v10582
      if st!=nil
        t=st[:room_types_v10601]||{};r=st[:rooms]||[]
        return {:pass=>t.size==r.size && t.values.include?(:entrance) && t.values.include?(:exit) && t.values.include?(:treasure),
          :rooms=>r.size,:typed=>t.size,:counts=>(st[:room_type_counts_v10601]||{}).dup}
      end
      {:pass=>true,:rooms=>0,:typed=>0,:structural=>true}
    rescue
      {:pass=>false,:rooms=>0,:typed=>0}
    end
  end
end
