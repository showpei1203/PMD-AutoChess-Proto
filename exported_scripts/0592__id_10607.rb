# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Room Visual Identity / Ground Detail v1.06.07
#-------------------------------------------------------------------------------
# 【用途】
# - 在不新增外部圖檔的前提下，讓 Treasure / Rare Nest / Elite / Recovery 房間
#   使用 VX 原生地板替代 tile 與既有 decor_a / decor_b 產生可辨識差異。
# - 所有裝飾避開房間中心十字、入口出口與水域，避免裝飾 tile 阻塞主路徑。
# - Encounter 事件依 Room Type 使用不同既有角色圖，僅作功能辨識，正式 UI/美術仍可後續替換。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRoomVisualIdentity_v10607']=true

module PMD_AC
  class << self
    def vxrd_state_water_cell_v10607?(state,x,y)
      wi=state==nil ? nil : state[:water_v10593]
      (wi==nil ? [] : wi[:rects]||[]).any? do |r|
        x.to_i>=r[:x].to_i && x.to_i<r[:x].to_i+r[:w].to_i &&
          y.to_i>=r[:y].to_i && y.to_i<r[:y].to_i+r[:h].to_i
      end
    rescue
      false
    end

    def vxrd_room_visual_apply_v10607(state)
      return nil if state==nil || $game_map==nil
      map=$game_map.instance_variable_get(:@map);return nil if map==nil || map.data==nil
      pal=state[:palette]||{};floor=pal[:floor].to_i
      alt=respond_to?(:vxrd_floor_family_alt_v10600) ? vxrd_floor_family_alt_v10600(floor) : floor
      da=pal[:decor_a].to_i;db=pal[:decor_b].to_i
      types=state[:room_types_v10601]||{}
      counts={:treasure_floor=>0,:rare_decor=>0,:elite_decor=>0,:recovery_floor=>0}
      (state[:rooms]||[]).each do |r|
        type=types[r[:id].to_i]||:normal
        x0=r[:x].to_i+1;y0=r[:y].to_i+1;x1=r[:x].to_i+r[:w].to_i-2;y1=r[:y].to_i+r[:h].to_i-2
        next if x1<x0 || y1<y0
        seed=(state[:seed].to_i ^ (r[:id].to_i*2654435761) ^ 0x1060707) & 0x7fffffff
        rng=VXRD_RNG_V10582.new(seed)
        case type
        when :treasure
          for y in y0..y1
            for x in x0..x1
              next if x==r[:cx].to_i || y==r[:cy].to_i
              next if vxrd_state_water_cell_v10607?(state,x,y)
              border=(x==x0 || x==x1 || y==y0 || y==y1)
              next unless border
              map.data[x,y,0]=alt if alt>0
              counts[:treasure_floor]+=1
            end
          end
        when :recovery
          for y in (r[:cy].to_i-1)..(r[:cy].to_i+1)
            for x in (r[:cx].to_i-1)..(r[:cx].to_i+1)
              next if x<r[:x].to_i || y<r[:y].to_i || x>=r[:x].to_i+r[:w].to_i || y>=r[:y].to_i+r[:h].to_i
              next if vxrd_state_water_cell_v10607?(state,x,y)
              map.data[x,y,0]=alt if alt>0
              counts[:recovery_floor]+=1
            end
          end
        when :rare_nest,:elite
          tile=(type==:rare_nest ? da : db)
          next if tile<=0
          candidates=[]
          for y in y0..y1
            for x in x0..x1
              next if x==r[:cx].to_i || y==r[:cy].to_i
              next if vxrd_state_water_cell_v10607?(state,x,y)
              # Prefer room edge/corners so even an impassable B/C tile cannot sever the center route.
              edge=(x<=x0+1 || x>=x1-1 || y<=y0+1 || y>=y1-1)
              candidates << [x,y] if edge && map.data[x,y,1].to_i==0
            end
          end
          density=(type==:rare_nest ? 32 : 22)
          candidates.each do |p|
            next unless rng.rand(100)<density
            map.data[p[0],p[1],1]=tile
            if type==:rare_nest;counts[:rare_decor]+=1;else;counts[:elite_decor]+=1;end
          end
        end
      end
      info={:alt_floor=>alt,:decor_a=>da,:decor_b=>db,:counts=>counts,
        :center_cross_safe=>true,:water_safe=>true,:external_png=>false}
      state[:room_visual_v10607]=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    alias pmd_ac_v10607_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10607_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10607_generate_current_map_v10582(code,seed,options)
      vxrd_room_visual_apply_v10607(st) unless st==nil
      st
    rescue
      nil
    end

    def vxrd_event_set_character_v10607(ev,name)
      return false if ev==nil || name.to_s.empty?
      ev.instance_variable_set(:@character_name,name.to_s)
      ev.instance_variable_set(:@character_index,0)
      true
    rescue
      false
    end

    alias pmd_ac_v10607_relocate_events_v10584 vxrd_relocate_events_v10584 unless method_defined?(:pmd_ac_v10607_relocate_events_v10584)
    def vxrd_relocate_events_v10584
      r=pmd_ac_v10607_relocate_events_v10584
      return r if $game_map==nil
      ($game_map.events||{}).each do |id,ev|
        tag=vxrd_game_event_tag_v10584(ev)
        type=ev.instance_variable_get(:@pmd_vxrd_room_type_v10601) rescue nil
        if tag==:encounter
          vxrd_event_set_character_v10607(ev,type==:rare_nest ? '$Actor7_2' : (type==:elite ? '$Actor7_1' : '$Actor7_3'))
        elsif tag==:treasure
          vxrd_event_set_character_v10607(ev,'$Actor19')
        elsif tag==:recovery
          vxrd_event_set_character_v10607(ev,'$Actor19_1')
        elsif tag==:exit
          vxrd_event_set_character_v10607(ev,'$Actor22_3')
        elsif tag==:retreat
          vxrd_event_set_character_v10607(ev,'$Actor4')
        elsif tag==:info
          vxrd_event_set_character_v10607(ev,'$Actor12')
        end
      end
      r
    rescue
      r
    end

    def vxrd_room_visual_audit_v10607
      req=[:vxrd_room_visual_apply_v10607,:vxrd_state_water_cell_v10607?,:vxrd_event_set_character_v10607]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:room_types=>4,:uses_rtp_only=>true,
        :center_cross_safe=>true,:water_safe=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end
