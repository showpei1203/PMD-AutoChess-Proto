# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD FS Height Topology Wall Pass v1.05.89
#-------------------------------------------------------------------------------
# Reimplements the useful FS_RandomDungeon height-wall topology directly in
# RPG::Map#data using native VX A4 autotile IDs. No Bitmap renderer, no PNG.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHeightTopologyWall_v10589']=true

module PMD_AC
  class << self
    def vxrd_mask_index_v10589(w,x,y)
      x.to_i + y.to_i * w.to_i
    end

    def vxrd_mask_inside_v10589(w,h,x,y)
      x>=0 && y>=0 && x<w && y<h
    end

    def vxrd_mask_shift_v10589(mask,w,h,dx,dy)
      out=Array.new(w*h,false)
      for y in 0...h
        for x in 0...w
          next unless mask[vxrd_mask_index_v10589(w,x,y)]
          nx=x+dx;ny=y+dy
          next unless vxrd_mask_inside_v10589(w,h,nx,ny)
          out[vxrd_mask_index_v10589(w,nx,ny)]=true
        end
      end
      out
    end

    def vxrd_mask_union_v10589(w,h,*masks)
      out=Array.new(w*h,false)
      masks.each do |m|
        next if m==nil
        for i in 0...out.size
          out[i]=true if m[i]
        end
      end
      out
    end

    def vxrd_mask_difference_v10589(source,*masks)
      out=source.clone
      masks.each do |m|
        next if m==nil
        for i in 0...out.size
          out[i]=false if m[i]
        end
      end
      out
    end

    def vxrd_mask_dilate8_v10589(mask,w,h)
      out=mask.clone
      for y in 0...h
        for x in 0...w
          next unless mask[vxrd_mask_index_v10589(w,x,y)]
          for dy in -1..1
            for dx in -1..1
              nx=x+dx;ny=y+dy
              next unless vxrd_mask_inside_v10589(w,h,nx,ny)
              out[vxrd_mask_index_v10589(w,nx,ny)]=true
            end
          end
        end
      end
      out
    end

    # FS v0.9.8: extend both ends of each horizontal south-face run by one cell.
    def vxrd_mask_extend_horizontal_ends_v10589(source,w,h,*blocked_masks)
      out=source.clone
      for y in 0...h
        x=0
        while x<w
          unless source[vxrd_mask_index_v10589(w,x,y)]
            x+=1
            next
          end
          start_x=x
          x+=1
          while x<w && source[vxrd_mask_index_v10589(w,x,y)]
            x+=1
          end
          finish_x=x-1
          [start_x-1,finish_x+1].each do |tx|
            next unless vxrd_mask_inside_v10589(w,h,tx,y)
            idx=vxrd_mask_index_v10589(w,tx,y)
            next if source[idx]
            blocked=false
            blocked_masks.each do |m|
              next if m==nil
              if m[idx]
                blocked=true
                break
              end
            end
            out[idx]=true unless blocked
          end
        end
      end
      out
    end

    def vxrd_mask_count_v10589(mask)
      n=0
      mask.each{|v|n+=1 if v}
      n
    end

    # FS height topology:
    # open -> north face -> solid -> 8-neighbor roof -> south face -> dark outer.
    def vxrd_height_topology_v10589(layout)
      w=layout.width.to_i;h=layout.height.to_i
      open=Array.new(w*h,false)
      for y in 0...h
        for x in 0...w
          open[vxrd_mask_index_v10589(w,x,y)]=true if layout.floor?(x,y)
        end
      end
      north=vxrd_mask_difference_v10589(vxrd_mask_shift_v10589(open,w,h,0,-1),open)
      solid=vxrd_mask_union_v10589(w,h,open,north)
      roof=vxrd_mask_difference_v10589(vxrd_mask_dilate8_v10589(solid,w,h),solid)
      south_roof=vxrd_mask_difference_v10589(vxrd_mask_shift_v10589(open,w,h,0,1),open,north)
      roof=vxrd_mask_union_v10589(w,h,roof,south_roof)
      south_face=vxrd_mask_difference_v10589(vxrd_mask_shift_v10589(south_roof,w,h,0,1),open,north,roof)
      south_face=vxrd_mask_extend_horizontal_ends_v10589(south_face,w,h,open,north,roof)
      outer=vxrd_mask_difference_v10589(vxrd_mask_shift_v10589(south_face,w,h,0,1),open,north,roof,south_face)
      {:width=>w,:height=>h,:open=>open,:north_face=>north,:wall_top=>roof,
       :south_face=>south_face,:outer=>outer,
       :counts=>{:open=>vxrd_mask_count_v10589(open),:north_face=>vxrd_mask_count_v10589(north),
         :wall_top=>vxrd_mask_count_v10589(roof),:south_face=>vxrd_mask_count_v10589(south_face),
         :outer=>vxrd_mask_count_v10589(outer)}}
    rescue
      nil
    end

    def vxrd_mask_same_v10589(mask,w,h,x,y)
      return false unless vxrd_mask_inside_v10589(w,h,x,y)
      mask[vxrd_mask_index_v10589(w,x,y)] ? true : false
    end

    # VX floor/ceiling autotile variant 0..46, same topology logic as the
    # reference dungeon script, but operating on an arbitrary boolean mask.
    def vxrd_floor_variant_from_mask_v10589(mask,w,h,x,y)
      l=!vxrd_mask_same_v10589(mask,w,h,x-1,y)
      r=!vxrd_mask_same_v10589(mask,w,h,x+1,y)
      u=!vxrd_mask_same_v10589(mask,w,h,x,y-1)
      d=!vxrd_mask_same_v10589(mask,w,h,x,y+1)
      missing=(l ? 1:0)+(r ? 1:0)+(u ? 1:0)+(d ? 1:0)
      if missing==0
        n=0
        n+=1 unless vxrd_mask_same_v10589(mask,w,h,x-1,y-1)
        n+=2 unless vxrd_mask_same_v10589(mask,w,h,x+1,y-1)
        n+=4 unless vxrd_mask_same_v10589(mask,w,h,x+1,y+1)
        n+=8 unless vxrd_mask_same_v10589(mask,w,h,x-1,y+1)
        return n
      elsif missing==1
        if l
          n=16;n+=1 unless vxrd_mask_same_v10589(mask,w,h,x+1,y-1);n+=2 unless vxrd_mask_same_v10589(mask,w,h,x+1,y+1);return n
        elsif u
          n=20;n+=1 unless vxrd_mask_same_v10589(mask,w,h,x+1,y+1);n+=2 unless vxrd_mask_same_v10589(mask,w,h,x-1,y+1);return n
        elsif r
          n=24;n+=1 unless vxrd_mask_same_v10589(mask,w,h,x-1,y+1);n+=2 unless vxrd_mask_same_v10589(mask,w,h,x-1,y-1);return n
        else
          n=28;n+=1 unless vxrd_mask_same_v10589(mask,w,h,x-1,y-1);n+=2 unless vxrd_mask_same_v10589(mask,w,h,x+1,y-1);return n
        end
      elsif missing==2
        if l
          return r ? 32 : (!u ? 40 : 34)
        else
          return !r ? 33 : (!u ? 38 : 36)
        end
      elsif missing==3
        return !d ? 42 : (!r ? 43 : (!u ? 44 : 45))
      end
      46
    rescue
      46
    end

    # VX A4 wall-type autotiles use a compact horizontal end-cap set.
    # The old dungeon reference maps wall-face base from ceiling base by +394.
    def vxrd_wall_face_variant_v10589(mask,w,h,x,y)
      v=0
      v+=1 unless vxrd_mask_same_v10589(mask,w,h,x-1,y)
      v+=4 unless vxrd_mask_same_v10589(mask,w,h,x+1,y)
      v
    rescue
      0
    end

    def vxrd_wall_face_base_v10589(palette)
      palette[:wall].to_i + 394
    end

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
      for y in 0...h
        for x in 0...w
          data[x,y,0]=0;data[x,y,1]=0;data[x,y,2]=0
          idx=vxrd_mask_index_v10589(w,x,y)
          if topo[:open][idx]
            data[x,y,0]=palette[:floor].to_i
          elsif topo[:wall_top][idx]
            data[x,y,0]=top_base+vxrd_floor_variant_from_mask_v10589(topo[:wall_top],w,h,x,y)
          elsif topo[:north_face][idx]
            data[x,y,0]=face_base+vxrd_wall_face_variant_v10589(topo[:north_face],w,h,x,y)
          elsif topo[:south_face][idx]
            data[x,y,0]=face_base+vxrd_wall_face_variant_v10589(topo[:south_face],w,h,x,y)
          else
            # outer + void intentionally remain tile 0; VX map background owns darkness.
            data[x,y,0]=0
          end
        end
      end
      @pmd_vxrd_last_wall_topology_v10589=topo
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      true
    rescue
      false
    end

    alias pmd_ac_v10589_vxrd_apply_layout_v10582 vxrd_apply_layout_v10582 unless method_defined?(:pmd_ac_v10589_vxrd_apply_layout_v10582)
    def vxrd_apply_layout_v10582(layout,palette)
      ok=vxrd_apply_height_topology_v10589(layout,palette)
      return true if ok
      pmd_ac_v10589_vxrd_apply_layout_v10582(layout,palette)
    end

    alias pmd_ac_v10589_vxrd_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10589_vxrd_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10589_vxrd_generate_current_map_v10582(code,seed,options)
      if st!=nil && @pmd_vxrd_last_wall_topology_v10589!=nil
        t=@pmd_vxrd_last_wall_topology_v10589
        st[:wall_topology_v10589]={:renderer=>:fs_height_vx_native,
          :wall_top_base=>st[:palette][:wall].to_i,
          :wall_face_base=>vxrd_wall_face_base_v10589(st[:palette]),
          :counts=>t[:counts]}
      end
      st
    rescue
      nil
    end

    def vxrd_wall_topology_info_v10589
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      st==nil ? nil : st[:wall_topology_v10589]
    rescue
      nil
    end

    def vxrd_wall_topology_audit_v10589
      p=VXRD_RTP_PALETTES_V10582
      face_ok=true
      p.each do |row|
        b=row[1].to_i+394
        face_ok=false if b<0 || b+5>8191
      end
      {:pass=>face_ok,:renderer=>:fs_height_vx_native,:palettes=>p.size,
       :wall_top_native=>true,:wall_face_native=>true,:external_png=>false,
       :bitmap_renderer=>false,:face_offset=>394}
    rescue
      {:pass=>false,:renderer=>:error,:palettes=>0}
    end
  end
end
