# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Ground Decoration Pass v1.05.98
#-------------------------------------------------------------------------------
# Adds deterministic RTP ground decoration on dry room interiors. Uses each
# palette's existing decor_a / decor_b TileB/C IDs. It never decorates corridors,
# room center cross, water, entrance/exit or fixed anchors, so even an impassable
# decorative tile cannot sever the dungeon graph.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDGroundDecoration_v10598']=true

module PMD_AC
  VXRD_DECOR_PROFILE_V10598={
    'forest'=>{:density=>9,:a_weight=>78,:label=>:grass_weeds},
    'water'=>{:density=>6,:a_weight=>68,:label=>:wetland_detail},
    'sky'=>{:density=>3,:a_weight=>72,:label=>:wind_detail},
    'mountain'=>{:density=>6,:a_weight=>58,:label=>:rock_detail},
    'mystic'=>{:density=>5,:a_weight=>62,:label=>:mystic_detail},
    'legend'=>{:density=>4,:a_weight=>50,:label=>:sanctuary_detail}
  }

  class << self
    def vxrd_decor_biome_v10598(layout)
      return layout.pmd_vxrd_biome_v10593 if layout!=nil && layout.respond_to?(:pmd_vxrd_biome_v10593)
      'forest'
    rescue
      'forest'
    end

    def vxrd_decor_reserved_v10598?(layout,x,y)
      return true if layout==nil
      ent=layout.entrance;ext=layout.exit_pos
      return true if ent!=nil && (ent[0].to_i-x.to_i).abs<=2 && (ent[1].to_i-y.to_i).abs<=2
      return true if ext!=nil && (ext[0].to_i-x.to_i).abs<=2 && (ext[1].to_i-y.to_i).abs<=2
      opts=layout.instance_variable_get(:@options) rescue {}
      (opts[:fixed_positions]||[]).each do |p|
        next unless p.is_a?(Array) && p.size>=2
        return true if (p[0].to_i-x.to_i).abs<=2 && (p[1].to_i-y.to_i).abs<=2
      end
      false
    rescue
      true
    end

    def vxrd_decor_candidate_cells_v10598(layout)
      out=[]
      (layout.rooms||[]).each do |r|
        x0=r[:x].to_i+1;y0=r[:y].to_i+1
        x1=r[:x].to_i+r[:w].to_i-2;y1=r[:y].to_i+r[:h].to_i-2
        next if x1<x0 || y1<y0
        for y in y0..y1
          for x in x0..x1
            next unless layout.floor?(x,y)
            next if layout.respond_to?(:water?) && layout.water?(x,y)
            # Keep the same center cross dry/open as the water pass and corridor graph.
            next if x==r[:cx].to_i || y==r[:cy].to_i
            next if vxrd_decor_reserved_v10598?(layout,x,y)
            out << [x,y]
          end
        end
      end
      out
    rescue
      []
    end

    def vxrd_apply_ground_decor_v10598(layout,palette)
      return nil if $game_map==nil || layout==nil || palette==nil
      map=$game_map.instance_variable_get(:@map)
      return nil if map==nil || map.data==nil
      biome=vxrd_decor_biome_v10598(layout)
      prof=VXRD_DECOR_PROFILE_V10598[biome] || VXRD_DECOR_PROFILE_V10598['forest']
      a=palette[:decor_a].to_i;b=palette[:decor_b].to_i
      candidates=vxrd_decor_candidate_cells_v10598(layout)
      seed=(layout.instance_variable_get(:@seed).to_i ^ 0x10598DEC) & 0x7fffffff
      rng=VXRD_RNG_V10582.new(seed)
      placed=[]
      candidates.each do |p|
        next unless rng.rand(100)<prof[:density].to_i
        tile=(rng.rand(100)<prof[:a_weight].to_i ? a : b)
        next if tile<=0
        x=p[0];y=p[1]
        next unless map.data[x,y,1].to_i==0 && map.data[x,y,2].to_i==0
        map.data[x,y,1]=tile
        placed << [x,y,tile]
      end
      info={:biome=>biome,:label=>prof[:label],:density=>prof[:density].to_i,
        :decor_a=>a,:decor_b=>b,:candidates=>candidates.size,:placed=>placed.size,
        :tile_a_count=>placed.count{|p|p[2]==a},:tile_b_count=>placed.count{|p|p[2]==b},
        :corridor_safe=>true,:center_cross_safe=>true,:water_safe=>true,:bridge=>false}
      @pmd_vxrd_last_decor_v10598=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    alias pmd_ac_v10598_vxrd_apply_height_topology_v10589 vxrd_apply_height_topology_v10589 unless method_defined?(:pmd_ac_v10598_vxrd_apply_height_topology_v10589)
    def vxrd_apply_height_topology_v10589(layout,palette)
      ok=pmd_ac_v10598_vxrd_apply_height_topology_v10589(layout,palette)
      return false unless ok
      vxrd_apply_ground_decor_v10598(layout,palette)
      true
    rescue
      false
    end

    alias pmd_ac_v10598_vxrd_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10598_vxrd_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10598_vxrd_generate_current_map_v10582(code,seed,options)
      st[:decor_v10598]=@pmd_vxrd_last_decor_v10598 if st!=nil && @pmd_vxrd_last_decor_v10598!=nil
      st
    rescue
      nil
    end

    def vxrd_ground_decor_info_v10598
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      st==nil ? nil : st[:decor_v10598]
    rescue
      nil
    end

    def vxrd_ground_decor_audit_v10598
      p=VXRD_RTP_PALETTES_V10582
      ids_ok=p.size==24 && p.all?{|row|row[2].to_i>0 && row[3].to_i>0}
      prof=VXRD_DECOR_PROFILE_V10598
      {:pass=>ids_ok && prof.size==6,:palettes=>p.size,:biomes=>prof.size,
       :dry_room_only=>true,:corridor_safe=>true,:center_cross_safe=>true,
       :water_safe=>true,:external_png=>false,:uses_palette_decor=>true}
    rescue
      {:pass=>false,:palettes=>0,:biomes=>0}
    end
  end
end
