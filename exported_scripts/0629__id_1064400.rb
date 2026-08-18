# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Landmark Template Authority I v1.06.44
#-------------------------------------------------------------------------------
# Restores environmental decoration ONLY through deterministic footprint-safe
# templates. Automatic one-cell TileB/C/D scattering remains forbidden.
#
# Phase-I scope is deliberately conservative:
# - TileB LEFT-half verified natural one-cell assets may be composed into a
#   fixed 2x2 / 3x2 landmark footprint. They are never selected independently.
# - TileD verified rock / ore / crystal / gravel cells may be composed into a
#   fixed 2x2 footprint.
# - TileB right-half composite / large-map art remains forbidden in this phase.
# - TileC remains forbidden.
# - Landmarks are placed only in NORMAL rooms, in corners, away from the room
#   center cross, entrance/exit, water and fixed positions.
# - Landmark footprint cells are reserved from later runtime event relocation.
# - No topology / encounter / reward / progression change.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDLandmarkTemplateAuthorityI_v10644']=true

module PMD_AC
  # tile IDs are global VX B/C/D IDs. Every array row is a complete footprint.
  VXRD_LANDMARK_TEMPLATES_V10644={
    :forest_grove=>{
      :label=>'林緣植被群',:sheet=>:tile_b_left,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[181,182],[180,196]]
    },
    :forest_flower_patch=>{
      :label=>'林緣花草群',:sheet=>:tile_b_left,:w=>3,:h=>2,:blocking=>false,
      :tiles=>[[160,161,162],[176,178,179]]
    },
    :wetland_reed_patch=>{
      :label=>'濕地草木群',:sheet=>:tile_b_left,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[161,162],[180,197]]
    },
    :dry_rock_cluster=>{
      :label=>'荒徑岩塊群',:sheet=>:tile_b_left,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[183,210],[226,195]]
    },
    :cave_stone_cluster=>{
      :label=>'洞窟碎岩群',:sheet=>:tile_d,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[545,577],[593,658]]
    },
    :mine_ore_pile=>{
      :label=>'礦層礦堆',:sheet=>:tile_d,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[664,665],[668,669]]
    },
    :mine_mixed_ore=>{
      :label=>'礦層礦石群',:sheet=>:tile_d,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[544,545],[576,577]]
    },
    :volcanic_ore_cluster=>{
      :label=>'熔鐵礦晶群',:sheet=>:tile_d,:w=>2,:h=>2,:blocking=>true,
      :tiles=>[[546,550],[578,582]]
    }
  }

  VXRD_LANDMARK_HUNT_PROFILE_V10644={
    'H01'=>{:templates=>[:forest_grove,:forest_flower_patch],:max=>2,:chance=>70},
    'H02'=>{:templates=>[:wetland_reed_patch,:forest_flower_patch],:max=>2,:chance=>58},
    'H04'=>{:templates=>[:dry_rock_cluster],:max=>2,:chance=>62},
    'H09'=>{:templates=>[:cave_stone_cluster],:max=>2,:chance=>68},
    'H14'=>{:templates=>[:mine_ore_pile,:mine_mixed_ore],:max=>3,:chance=>76},
    'H19'=>{:templates=>[:volcanic_ore_cluster],:max=>3,:chance=>78}
  }

  class << self
    def vxrd_landmark_template_v10644(key)
      t=VXRD_LANDMARK_TEMPLATES_V10644[key.to_sym]
      t==nil ? nil : t.dup
    rescue
      nil
    end

    def vxrd_landmark_reserved_v10644?(state,x,y)
      return false if state==nil
      h=state[:landmark_reserved_v10644]
      return false unless h.is_a?(Hash)
      h[[x.to_i,y.to_i]]==true
    rescue
      false
    end

    def vxrd_landmark_room_type_v10644(state,room)
      return :normal if state==nil || room==nil
      (state[:room_types_v10601]||{})[room[:id].to_i] || :normal
    rescue
      :normal
    end

    def vxrd_landmark_water_v10644?(state,x,y)
      return vxrd_state_water_cell_v10607?(state,x,y) if respond_to?(:vxrd_state_water_cell_v10607?)
      false
    rescue
      false
    end

    def vxrd_landmark_keypoint_v10644?(state,x,y)
      return true if state==nil
      [state[:entrance],state[:exit]].each do |p|
        next if p==nil || p.size<2
        return true if (p[0].to_i-x.to_i).abs+(p[1].to_i-y.to_i).abs<=2
      end
      false
    rescue
      true
    end

    def vxrd_landmark_fixed_v10644?(state,x,y)
      layout=state[:layout_v10582] rescue nil
      opts=layout==nil ? {} : (layout.instance_variable_get(:@options) rescue {})
      (opts[:fixed_positions]||[]).any?{|p|p.is_a?(Array) && (p[0].to_i-x.to_i).abs+(p[1].to_i-y.to_i).abs<=1}
    rescue
      false
    end

    def vxrd_landmark_tile_allowed_v10644?(tile,sheet)
      t=tile.to_i
      case sheet
      when :tile_b_left
        return false unless t>=0 && t<=255
        return false unless (t%16)<8
        return false if t<160 # upper TileB is building/UI material in this phase
        true
      when :tile_d
        return false unless t>=512 && t<=767
        true
      else
        false
      end
    rescue
      false
    end

    def vxrd_landmark_template_valid_v10644?(key)
      t=VXRD_LANDMARK_TEMPLATES_V10644[key.to_sym]
      return false if t==nil
      rows=t[:tiles]
      return false unless rows.is_a?(Array) && rows.size==t[:h].to_i
      return false unless rows.all?{|r|r.is_a?(Array) && r.size==t[:w].to_i}
      rows.flatten.all?{|id|id.to_i>0 && vxrd_landmark_tile_allowed_v10644?(id,t[:sheet])}
    rescue
      false
    end

    def vxrd_landmark_footprint_clear_v10644?(state,room,template,ax,ay)
      return false if state==nil || room==nil || template==nil || $game_map==nil
      map=$game_map.instance_variable_get(:@map)
      return false if map==nil || map.data==nil
      w=template[:w].to_i;h=template[:h].to_i
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
      return false if ax<x0 || ay<y0 || ax+w-1>x1 || ay+h-1>y1
      for dy in 0...h
        for dx in 0...w
          x=ax+dx;y=ay+dy
          return false if x==room[:cx].to_i || y==room[:cy].to_i
          return false if (x-room[:cx].to_i).abs<=1 || (y-room[:cy].to_i).abs<=1
          return false if vxrd_landmark_keypoint_v10644?(state,x,y)
          return false if vxrd_landmark_water_v10644?(state,x,y)
          return false if vxrd_landmark_fixed_v10644?(state,x,y)
          return false if vxrd_landmark_reserved_v10644?(state,x,y)
          return false if map.data[x,y,0].to_i<=0
          return false unless map.data[x,y,1].to_i==0 && map.data[x,y,2].to_i==0
        end
      end
      true
    rescue
      false
    end

    def vxrd_landmark_corner_anchors_v10644(room,template)
      return [] if room==nil || template==nil
      w=template[:w].to_i;h=template[:h].to_i
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
      [[x0,y0],[x1-w+1,y0],[x0,y1-h+1],[x1-w+1,y1-h+1]].uniq
    rescue
      []
    end

    def vxrd_landmark_stamp_v10644(state,room,key,ax,ay)
      return nil unless vxrd_landmark_template_valid_v10644?(key)
      t=VXRD_LANDMARK_TEMPLATES_V10644[key.to_sym]
      return nil unless vxrd_landmark_footprint_clear_v10644?(state,room,t,ax,ay)
      map=$game_map.instance_variable_get(:@map);return nil if map==nil
      state[:landmark_reserved_v10644]={} unless state[:landmark_reserved_v10644].is_a?(Hash)
      cells=[]
      t[:tiles].each_with_index do |row,dy|
        row.each_with_index do |id,dx|
          x=ax+dx;y=ay+dy
          map.data[x,y,1]=id.to_i
          state[:landmark_reserved_v10644][[x,y]]=true
          cells << [x,y,id.to_i]
        end
      end
      {:template=>key.to_sym,:label=>t[:label],:room_id=>room[:id].to_i,
       :anchor=>[ax,ay],:w=>t[:w].to_i,:h=>t[:h].to_i,:cells=>cells,
       :blocking=>t[:blocking] ? true:false,:sheet=>t[:sheet]}
    rescue
      nil
    end

    def vxrd_apply_landmarks_v10644(state)
      return nil if state==nil || $game_map==nil
      code=state[:code].to_s.upcase
      prof=VXRD_LANDMARK_HUNT_PROFILE_V10644[code]
      if prof==nil
        info={:code=>code,:enabled=>false,:placed=>0,:templates=>[],
          :single_scatter=>false,:tileb_right_half=>false,:tilec=>false,:gameplay_change=>false}
        state[:landmarks_v10644]=info
        return info
      end
      rng=VXRD_RNG_V10582.new((state[:seed].to_i ^ 0x10644A7) & 0x7fffffff)
      candidates=(state[:rooms]||[]).find_all{|r|vxrd_landmark_room_type_v10644(state,r)==:normal}
      # Deterministic shuffle without relying on modern Ruby Array#shuffle.
      order=[];pool=candidates.dup
      until pool.empty?
        order << pool.delete_at(rng.rand(pool.size))
      end
      placed=[];max=prof[:max].to_i;chance=prof[:chance].to_i
      order.each do |room|
        break if placed.size>=max
        next unless rng.rand(100)<chance
        keys=prof[:templates]||[];next if keys.empty?
        key=keys[rng.rand(keys.size)]
        t=VXRD_LANDMARK_TEMPLATES_V10644[key];next if t==nil
        anchors=vxrd_landmark_corner_anchors_v10644(room,t)
        # deterministic anchor rotation
        unless anchors.empty?
          off=rng.rand(anchors.size);anchors=anchors[off..-1]+anchors[0...off]
        end
        hit=nil
        anchors.each do |a|
          hit=vxrd_landmark_stamp_v10644(state,room,key,a[0],a[1])
          break unless hit==nil
        end
        placed << hit unless hit==nil
      end
      info={:code=>code,:enabled=>true,:placed=>placed.size,:max=>max,
        :templates=>placed.collect{|p|p[:template]},:placements=>placed,
        :reserved_cells=>(state[:landmark_reserved_v10644]||{}).size,
        :normal_rooms_only=>true,:corner_only=>true,:center_cross_safe=>true,
        :water_safe=>true,:event_reservation=>true,:single_scatter=>false,
        :tileb_right_half=>false,:tilec=>false,:tile_d_template_only=>true,
        :gameplay_change=>false}
      state[:landmarks_v10644]=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    # Run AFTER the v1.06.41 post-generation B/C/D purge. This is the only
    # sanctioned way for visual B/D objects to return to a Hunt map.
    alias pmd_ac_v10644_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10644_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10644_generate_current_map_v10582(code,seed,options)
      vxrd_apply_landmarks_v10644(st) unless st==nil
      st
    rescue
      st
    end

    # Runtime events must never be relocated onto a landmark footprint.
    alias pmd_ac_v10644_room_cells_for_type_v10601 vxrd_room_cells_for_type_v10601 unless method_defined?(:pmd_ac_v10644_room_cells_for_type_v10601)
    def vxrd_room_cells_for_type_v10601(type)
      cells=pmd_ac_v10644_room_cells_for_type_v10601(type)
      st=vxrd_state_v10582 rescue nil
      return cells if st==nil
      cells.find_all{|p|!vxrd_landmark_reserved_v10644?(st,p[0],p[1])}
    rescue
      cells || []
    end

    def vxrd_landmark_audit_v10644
      bad=[]
      VXRD_LANDMARK_TEMPLATES_V10644.each_key do |k|
        bad << k.to_s+':template' unless vxrd_landmark_template_valid_v10644?(k)
      end
      VXRD_LANDMARK_HUNT_PROFILE_V10644.each do |code,p|
        bad << code+':templates' if (p[:templates]||[]).empty?
        (p[:templates]||[]).each{|k|bad << code+':'+k.to_s unless VXRD_LANDMARK_TEMPLATES_V10644.has_key?(k)}
        bad << code+':max' unless p[:max].to_i>=1 && p[:max].to_i<=3
      end
      {:pass=>bad.empty?,:templates=>VXRD_LANDMARK_TEMPLATES_V10644.size,
       :hunt_profiles=>VXRD_LANDMARK_HUNT_PROFILE_V10644.size,
       :single_scatter=>false,:tileb_left_template_only=>true,
       :tileb_right_half=>false,:tilec=>false,:tiled_template_only=>true,
       :normal_rooms_only=>true,:center_cross_safe=>true,:water_safe=>true,
       :event_reservation=>true,:gameplay_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:templates=>0,:hunt_profiles=>0,:bad=>[:audit_error]}
    end

    alias pmd_ac_v10644_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10644_write_project_state_log)
    def project_version
      '1.06.44'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10644_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=30')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.44')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_LANDMARK_TEMPLATE_AUTHORITY_I+MINIMAP_FOUNDATION')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_EVENT_SEMANTIC_PLACEMENT+LANDMARK_TEMPLATE_II')
        text=text.gsub(/\r?\nVXRD_LANDMARK_V10644_BEGIN.*?VXRD_LANDMARK_V10644_END\r?\n/m,"\r\n")
        a=vxrd_landmark_audit_v10644
        lines=[]
        lines << ''
        lines << 'VXRD_LANDMARK_V10644_BEGIN'
        lines << 'VXRD_LANDMARK_TEMPLATE_AUTHORITY_I='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'VXRD_LANDMARK_TEMPLATES='+a[:templates].to_i.to_s
        lines << 'VXRD_LANDMARK_HUNT_PROFILES='+a[:hunt_profiles].to_i.to_s
        lines << 'VXRD_LANDMARK_PROFILE_CODES='+VXRD_LANDMARK_HUNT_PROFILE_V10644.keys.sort.join(',')
        lines << 'VXRD_LANDMARK_SINGLE_TILE_SCATTER=0'
        lines << 'VXRD_LANDMARK_TILEB_LEFT=TEMPLATE_ONLY'
        lines << 'VXRD_LANDMARK_TILEB_RIGHT_HALF=DISABLED_PHASE_I'
        lines << 'VXRD_LANDMARK_TILEC=DISABLED'
        lines << 'VXRD_LANDMARK_TILED=TEMPLATE_ONLY'
        lines << 'VXRD_LANDMARK_NORMAL_ROOMS_ONLY=1'
        lines << 'VXRD_LANDMARK_CENTER_CROSS_SAFE=1'
        lines << 'VXRD_LANDMARK_WATER_SAFE=1'
        lines << 'VXRD_LANDMARK_EVENT_RESERVATION=1'
        lines << 'VXRD_LANDMARK_GAMEPLAY_CHANGE=0'
        lines << 'VXRD_LANDMARK_VISUAL_QA=PENDING_USER_REVIEW'
        lines << 'VXRD_LANDMARK_V10644_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
