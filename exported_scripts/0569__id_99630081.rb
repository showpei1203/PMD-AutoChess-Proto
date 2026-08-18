# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt VX Native Random Floor Integration v1.05.84
#-------------------------------------------------------------------------------
# 【用途】
# 把 v1.05.82/83 直接接回現有 Hunt Run。使用目前 VX Map 當 template shell，
# 只改 Map#data tile table 與 tagged event 位置，不建立第二套 Scene / Game_Map。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntVXNativeRandomFloor_v10584']=true

module PMD_AC
  VXRD_EVENT_TAGS_V10584={
    :entrance=>'<PMD_RD_ENTRANCE>',
    :exit=>'<PMD_RD_EXIT>',
    :encounter=>'<PMD_RD_ENCOUNTER>',
    :treasure=>'<PMD_RD_TREASURE>',
    :fixed=>'<PMD_RD_FIXED>'
  }

  class << self
    def vxrd_game_event_name_v10584(ev)
      raw=ev==nil ? nil : ev.instance_variable_get(:@event)
      raw==nil ? '' : raw.name.to_s
    rescue
      ''
    end
    def vxrd_game_event_tag_v10584(ev)
      name=vxrd_game_event_name_v10584(ev)
      VXRD_EVENT_TAGS_V10584.each{|k,v|return k if name.index(v)!=nil}
      nil
    rescue
      nil
    end
    def vxrd_relocate_events_v10584
      s=vxrd_state_v10582;return {:pass=>false,:moved=>0} if s==nil || $game_map==nil
      occupied=[];moved=0;counts={:entrance=>0,:exit=>0,:encounter=>0,:treasure=>0,:fixed=>0}
      events=$game_map.events || {}
      events.keys.sort.each do |id|
        ev=events[id];tag=vxrd_game_event_tag_v10584(ev);next if tag==nil
        counts[tag]=counts[tag].to_i+1
        if tag==:fixed
          occupied << [ev.x.to_i,ev.y.to_i]
          next
        end
        pos=nil
        if tag==:entrance
          pos=s[:entrance]
        elsif tag==:exit
          pos=s[:exit]
        else
          pos=vxrd_random_walkable_position_v10583(:room,id.to_i*31,occupied,3)
        end
        next if pos==nil
        ev.moveto(pos[0],pos[1]);occupied << [pos[0],pos[1]];moved+=1
      end
      {:pass=>true,:moved=>moved,:counts=>counts,:occupied=>occupied}
    rescue
      {:pass=>false,:moved=>0,:counts=>{}}
    end
    def hunt_generate_vx_floor_v10584(code=nil,mode=:steps,options=nil)
      s=phase_div_hunt_session_v10555
      c=code==nil ? (s==nil ? 'H01' : s[:code].to_s) : code.to_s.upcase
      if s==nil || !s[:active] || s[:code].to_s!=c
        s=hunt_map_enter(c,mode)
      else
        s[:encounter_mode_v10579]=mode.to_sym if s!=nil
      end
      return nil if s==nil
      floor_index=(s[:vxrd_floor_count_v10584]||0).to_i+1
      floor_seed=(s[:seed].to_i ^ (floor_index*83492791) ^ ($game_map.map_id.to_i*19349663)) & 0x7fffffff
      o=options.is_a?(Hash) ? options.dup : {}
      o[:move_player]=true unless o.has_key?(:move_player)
      fixed=[]
      if $game_map!=nil && $game_map.events!=nil
        $game_map.events.each_value do |ev|
          fixed << [ev.x.to_i,ev.y.to_i] if vxrd_game_event_tag_v10584(ev)==:fixed
        end
      end
      o[:fixed_positions]=fixed unless fixed.empty?
      state=vxrd_generate_current_map_v10582(c,floor_seed,o)
      return nil if state==nil
      relocate=vxrd_relocate_events_v10584
      s[:vxrd_floor_count_v10584]=floor_index
      s[:vxrd_last_floor_seed_v10584]=floor_seed
      s[:vxrd_last_map_id_v10584]=$game_map.map_id.to_i
      s[:vxrd_last_generation_attempt_v10584]=state[:attempt].to_i
      s[:vxrd_last_event_relocate_v10584]=relocate
      hunt_map_floor_ready(c)
      vxrd_reveal_at_v10583 if respond_to?(:vxrd_reveal_at_v10583)
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      state
    rescue
      nil
    end
    def hunt_regenerate_vx_floor_v10584(options=nil)
      s=phase_div_hunt_session_v10555;return nil if s==nil || !s[:active]
      hunt_generate_vx_floor_v10584(s[:code],(s[:encounter_mode_v10579]||:steps),options)
    rescue
      nil
    end
    def hunt_vx_floor_info_v10584
      s=phase_div_hunt_session_v10555;st=vxrd_state_v10582
      return nil if s==nil || st==nil
      {:code=>s[:code],:run=>s[:run].to_i,:floor=>s[:vxrd_floor_count_v10584].to_i,
       :map_id=>st[:map_id].to_i,:seed=>st[:seed].to_i,:attempt=>st[:attempt].to_i,
       :palette=>st[:palette],:rooms=>(st[:rooms]||[]).size,:edges=>(st[:edges]||[]).size,
       :walkable=>(st[:walkable]||[]).size,:entrance=>st[:entrance],:exit=>st[:exit],
       :explored=>respond_to?(:vxrd_exploration_percent_v10583) ? vxrd_exploration_percent_v10583 : 0,
       :event_relocate=>s[:vxrd_last_event_relocate_v10584]}
    rescue
      nil
    end
    def hunt_vx_random_floor_audit_v10584
      req=[:hunt_generate_vx_floor_v10584,:hunt_regenerate_vx_floor_v10584,
        :hunt_vx_floor_info_v10584,:vxrd_relocate_events_v10584]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:bad=>bad,:scene_map_native=>true,
       :rtp_tileset_native=>true,:external_png=>false,:second_map_runtime=>false}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end
