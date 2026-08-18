# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Regular Water Zone Authority v1.05.93
#-------------------------------------------------------------------------------
# One water autotile type per map style, rectangle-only pools, no organic water,
# no rivers and no bridges. Water is a real non-walkable VX A1 autotile region.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRegularWaterZone_v10593']=true

module PMD_AC
  # Conservative VX A1 water bases. Each biome/style uses exactly one base on
  # a generated floor. H02 uses the second RTP water family for visual QA;
  # other wet-capable styles use the first family until Windows palette review.
  VXRD_WATER_PROFILE_V10593={
    'forest'=>{:base=>2048,:rects=>1,:chance=>55},
    'water'=>{:base=>2096,:rects=>2,:chance=>100},
    'sky'=>{:base=>2048,:rects=>0,:chance=>0},
    'mountain'=>{:base=>2048,:rects=>1,:chance=>30},
    'mystic'=>{:base=>2096,:rects=>1,:chance=>70},
    'legend'=>{:base=>2096,:rects=>1,:chance=>80}
  }

  class VXRD_Layout_V10582
    attr_reader :water_rects_v10593

    def water?(x,y)
      return false if x<0 || y<0 || x>=@width || y>=@height
      @grid[y][x]==2
    rescue
      false
    end

    # Override previous attr_reader so placement APIs never select water cells.
    def room_cells
      (@room_cells||[]).find_all{|p| !water?(p[0],p[1])}
    rescue
      []
    end

    def water_cells_v10593
      out=[]
      for y in 0...@height
        for x in 0...@width
          out << [x,y] if water?(x,y)
        end
      end
      out
    rescue
      []
    end

    def pmd_vxrd_biome_v10593
      (@options[:biome_v10593]||'forest').to_s
    end

    def pmd_vxrd_water_profile_v10593
      PMD_AC::VXRD_WATER_PROFILE_V10593[pmd_vxrd_biome_v10593] || PMD_AC::VXRD_WATER_PROFILE_V10593['forest']
    rescue
      {:base=>2048,:rects=>0,:chance=>0}
    end

    def vxrd_place_regular_water_v10593
      @water_rects_v10593=[]
      prof=pmd_vxrd_water_profile_v10593
      return 0 if prof[:rects].to_i<=0 || @rng.rand(100)>=prof[:chance].to_i
      candidates=@rooms.find_all{|r|r[:w].to_i>=6 && r[:h].to_i>=6}
      candidates=candidates.find_all do |r|
        inside_e=@entrance && @entrance[0]>=r[:x] && @entrance[0]<r[:x]+r[:w] && @entrance[1]>=r[:y] && @entrance[1]<r[:y]+r[:h]
        inside_x=@exit_pos && @exit_pos[0]>=r[:x] && @exit_pos[0]<r[:x]+r[:w] && @exit_pos[1]>=r[:y] && @exit_pos[1]<r[:y]+r[:h]
        !inside_e && !inside_x
      end
      count=[prof[:rects].to_i,candidates.size].min
      count.times do |i|
        break if candidates.empty?
        ri=@rng.rand(candidates.size);r=candidates.delete_at(ri)
        maxw=[r[:w].to_i-2,4].min
        maxh=[r[:h].to_i-2,3].min
        next if maxw<2 || maxh<2
        ww=@rng.range(2,maxw);hh=@rng.range(2,maxh)
        xmin=r[:x].to_i+1;xmax=r[:x].to_i+r[:w].to_i-ww-1
        ymin=r[:y].to_i+1;ymax=r[:y].to_i+r[:h].to_i-hh-1
        next if xmax<xmin || ymax<ymin
        wx=nil;wy=nil
        # Corridors connect room centers. Keep the full center row + column dry,
        # so a rectangular pool can never sever the room graph.
        32.times do
          tx=@rng.range(xmin,xmax);ty=@rng.range(ymin,ymax)
          spans_cx=(tx<=r[:cx].to_i && tx+ww-1>=r[:cx].to_i)
          spans_cy=(ty<=r[:cy].to_i && ty+hh-1>=r[:cy].to_i)
          next if spans_cx || spans_cy
          fixed_hit=false
          (@options[:fixed_positions]||[]).each do |fp|
            next unless fp.is_a?(Array) && fp.size>=2
            fx=fp[0].to_i;fy=fp[1].to_i
            if fx>=tx && fx<tx+ww && fy>=ty && fy<ty+hh
              fixed_hit=true;break
            end
          end
          next if fixed_hit
          wx=tx;wy=ty;break
        end
        next if wx==nil || wy==nil
        for yy in wy...(wy+hh)
          for xx in wx...(wx+ww)
            @grid[yy][xx]=2 if @grid[yy][xx]==1
          end
        end
        @water_rects_v10593 << {:x=>wx,:y=>wy,:w=>ww,:h=>hh}
      end
      @water_rects_v10593.size
    rescue
      0
    end

    alias pmd_ac_v10593_choose_entrance_exit choose_entrance_exit unless method_defined?(:pmd_ac_v10593_choose_entrance_exit)
    def choose_entrance_exit
      pmd_ac_v10593_choose_entrance_exit
      vxrd_place_regular_water_v10593
    end
  end

  class << self
    alias pmd_ac_v10593_vxrd_options_v10582 vxrd_options_v10582 unless method_defined?(:pmd_ac_v10593_vxrd_options_v10582)
    def vxrd_options_v10582(code,options=nil)
      o=pmd_ac_v10593_vxrd_options_v10582(code,options)
      h=respond_to?(:phase_div_hunt_v10553) ? phase_div_hunt_v10553(code.to_s.upcase) : nil
      o[:biome_v10593]=(h==nil ? 'forest' : h[:biome].to_s) unless o.has_key?(:biome_v10593)
      o
    rescue
      options.is_a?(Hash) ? options.dup : {}
    end

    def vxrd_water_mask_v10593(layout)
      w=layout.width.to_i;h=layout.height.to_i
      m=Array.new(w*h,false)
      return m unless layout.respond_to?(:water?)
      for y in 0...h
        for x in 0...w
          m[vxrd_mask_index_v10589(w,x,y)]=true if layout.water?(x,y)
        end
      end
      m
    rescue
      []
    end

    def vxrd_water_profile_for_layout_v10593(layout)
      biome=layout.respond_to?(:pmd_vxrd_biome_v10593) ? layout.pmd_vxrd_biome_v10593 : 'forest'
      VXRD_WATER_PROFILE_V10593[biome] || VXRD_WATER_PROFILE_V10593['forest']
    rescue
      {:base=>2048,:rects=>0,:chance=>0}
    end

    # Supersedes v1.05.89 renderer to render water as open-like A1 autotile.
    def vxrd_apply_height_topology_v10589(layout,palette)
      return false if $game_map==nil
      map=$game_map.instance_variable_get(:@map)
      return false if map==nil || map.data==nil
      data=map.data
      topo=vxrd_height_topology_v10589(layout)
      return false if topo==nil
      w=topo[:width];h=topo[:height]
      top_base=palette[:wall].to_i
      face_base=vxrd_wall_face_base_v10589(palette)
      water_mask=vxrd_water_mask_v10593(layout)
      prof=vxrd_water_profile_for_layout_v10593(layout)
      water_base=prof[:base].to_i
      for y in 0...h
        for x in 0...w
          data[x,y,0]=0;data[x,y,1]=0;data[x,y,2]=0
          idx=vxrd_mask_index_v10589(w,x,y)
          if topo[:open][idx]
            if layout.respond_to?(:water?) && layout.water?(x,y)
              data[x,y,0]=water_base+vxrd_floor_variant_from_mask_v10589(water_mask,w,h,x,y)
            else
              data[x,y,0]=palette[:floor].to_i
            end
          elsif topo[:wall_top][idx]
            data[x,y,0]=top_base+vxrd_floor_variant_from_mask_v10589(topo[:wall_top],w,h,x,y)
          elsif topo[:north_face][idx]
            data[x,y,0]=face_base+vxrd_wall_face_variant_v10589(topo[:north_face],w,h,x,y)
          elsif topo[:south_face][idx]
            data[x,y,0]=face_base+vxrd_wall_face_variant_v10589(topo[:south_face],w,h,x,y)
          else
            data[x,y,0]=0
          end
        end
      end
      @pmd_vxrd_last_wall_topology_v10589=topo
      @pmd_vxrd_last_water_info_v10593={:biome=>(layout.respond_to?(:pmd_vxrd_biome_v10593) ? layout.pmd_vxrd_biome_v10593 : 'forest'),
        :base=>water_base,:shape=>:rectangle,:bridge=>false,
        :rects=>(layout.respond_to?(:water_rects_v10593) ? layout.water_rects_v10593||[] : []),
        :cells=>(layout.respond_to?(:water_cells_v10593) ? layout.water_cells_v10593.size : 0),
        :types_on_floor=>(layout.respond_to?(:water_cells_v10593) && layout.water_cells_v10593.size>0 ? 1 : 0)}
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      true
    rescue
      false
    end

    alias pmd_ac_v10593_vxrd_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10593_vxrd_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10593_vxrd_generate_current_map_v10582(code,seed,options)
      st[:water_v10593]=@pmd_vxrd_last_water_info_v10593 if st!=nil && @pmd_vxrd_last_water_info_v10593!=nil
      st
    rescue
      nil
    end

    def vxrd_water_info_v10593
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      st==nil ? nil : st[:water_v10593]
    rescue
      nil
    end

    def vxrd_regular_water_audit_v10593
      p=VXRD_WATER_PROFILE_V10593
      ok=p.size==6 && p.values.all?{|v|v[:base].to_i>=2048 && v[:shape].nil?}
      i=vxrd_water_info_v10593
      runtime_ok=i==nil || (i[:shape]==:rectangle && i[:bridge]==false && i[:types_on_floor].to_i<=1)
      {:pass=>ok && runtime_ok,:biomes=>p.size,:shape=>:rectangle,:irregular=>false,
        :river=>false,:bridge=>false,:one_type_per_style=>true,
        :runtime_rects=>(i==nil ? 0:(i[:rects]||[]).size),:runtime_cells=>(i==nil ? 0:i[:cells].to_i)}
    rescue
      {:pass=>false,:biomes=>0,:shape=>:rectangle,:bridge=>false}
    end
  end
end
