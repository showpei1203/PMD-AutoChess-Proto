# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Height Wall Geometry Repair II v1.05.92
#-------------------------------------------------------------------------------
# Fixes two Windows visual defects found in v1.05.91:
# 1) a one-cell vertical void between two open regions cannot physically fit
#    the VX two-cell wall stack (top + face), producing a floating face;
# 2) south faces were derived only from open's direct south roof, so exposed
#    south edges created by side/corner wall tops could show black holes.
# No external PNG / parallax / second Game_Map.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHeightWallGeometryRepairII_v10592']=true

module PMD_AC
  class VXRD_Layout_V10582
    attr_reader :height_clearance_repairs_v10592

    def normalize_height_clearance_v10592
      @height_clearance_repairs_v10592=0
      # A single void cell vertically sandwiched by open floor can never render
      # a proper VX height wall. Merge only that impossible slit into floor.
      6.times do
        pending=[]
        for y in 1...(@height-1)
          for x in 1...(@width-1)
            next if floor?(x,y)
            if floor?(x,y-1) && floor?(x,y+1)
              pending << [x,y]
            end
          end
        end
        break if pending.empty?
        pending.each do |p|
          carve(p[0],p[1],false)
          @height_clearance_repairs_v10592+=1
        end
      end
      @height_clearance_repairs_v10592
    rescue
      0
    end

    alias pmd_ac_v10592_connect_fixed_positions connect_fixed_positions unless method_defined?(:pmd_ac_v10592_connect_fixed_positions)
    def connect_fixed_positions
      pmd_ac_v10592_connect_fixed_positions
      normalize_height_clearance_v10592
    end
  end

  class << self
    def vxrd_open_like_v10592(layout,x,y)
      return true if layout.floor?(x,y)
      return true if layout.respond_to?(:water?) && layout.water?(x,y)
      false
    rescue
      false
    end

    def vxrd_count_vertical_pinches_v10592(layout)
      n=0
      for y in 1...(layout.height.to_i-1)
        for x in 1...(layout.width.to_i-1)
          next if vxrd_open_like_v10592(layout,x,y)
          n+=1 if vxrd_open_like_v10592(layout,x,y-1) && vxrd_open_like_v10592(layout,x,y+1)
        end
      end
      n
    rescue
      9999
    end

    # Supersedes v1.05.89 topology. South face is now generated from EVERY
    # exposed south edge of wall_top, not only the direct south edge of open.
    def vxrd_height_topology_v10589(layout)
      w=layout.width.to_i;h=layout.height.to_i
      open=Array.new(w*h,false)
      for y in 0...h
        for x in 0...w
          open[vxrd_mask_index_v10589(w,x,y)]=true if vxrd_open_like_v10592(layout,x,y)
        end
      end

      north=vxrd_mask_difference_v10589(vxrd_mask_shift_v10589(open,w,h,0,-1),open)
      solid=vxrd_mask_union_v10589(w,h,open,north)
      roof=vxrd_mask_difference_v10589(vxrd_mask_dilate8_v10589(solid,w,h),solid)

      # Direct south border of open must always be wall-top.
      south_roof=vxrd_mask_difference_v10589(vxrd_mask_shift_v10589(open,w,h,0,1),open,north)
      roof=vxrd_mask_union_v10589(w,h,roof,south_roof)

      # Critical v1.05.92 correction:
      # every exposed southern edge of ANY roof tile gets a face beneath it.
      # This includes stair/corner roof segments formed on east/west walls.
      south_face=vxrd_mask_difference_v10589(
        vxrd_mask_shift_v10589(roof,w,h,0,1),open,north,roof
      )

      # No legacy horizontal end extension here. It was compensating for the
      # old south_roof-only derivation and can create unsupported face cells
      # once all exposed roof edges are authoritative.
      outer=vxrd_mask_difference_v10589(
        vxrd_mask_shift_v10589(south_face,w,h,0,1),open,north,roof,south_face
      )

      # Invariants used by AutoTest / ProjectState.
      unsupported_north=0
      unsupported_south=0
      orphan_face=0
      for y in 0...h
        for x in 0...w
          idx=vxrd_mask_index_v10589(w,x,y)
          if north[idx]
            if y<=0 || !roof[vxrd_mask_index_v10589(w,x,y-1)]
              unsupported_north+=1
            end
          end
          if roof[idx]
            sy=y+1
            if sy<h
              si=vxrd_mask_index_v10589(w,x,sy)
              exposed=!roof[si] && !open[si] && !north[si]
              unsupported_south+=1 if exposed && !south_face[si]
            end
          end
          if south_face[idx]
            orphan_face+=1 if y<=0 || !roof[vxrd_mask_index_v10589(w,x,y-1)]
          end
        end
      end

      {:width=>w,:height=>h,:open=>open,:north_face=>north,:wall_top=>roof,
       :south_face=>south_face,:outer=>outer,
       :counts=>{:open=>vxrd_mask_count_v10589(open),:north_face=>vxrd_mask_count_v10589(north),
         :wall_top=>vxrd_mask_count_v10589(roof),:south_face=>vxrd_mask_count_v10589(south_face),
         :outer=>vxrd_mask_count_v10589(outer)},
       :geometry_v10592=>{:vertical_pinches=>vxrd_count_vertical_pinches_v10592(layout),
         :clearance_repairs=>(layout.respond_to?(:height_clearance_repairs_v10592) ? layout.height_clearance_repairs_v10592.to_i : 0),
         :unsupported_north=>unsupported_north,:unsupported_south=>unsupported_south,
         :orphan_face=>orphan_face}}
    rescue
      nil
    end

    alias pmd_ac_v10592_vxrd_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10592_vxrd_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10592_vxrd_generate_current_map_v10582(code,seed,options)
      if st!=nil && @pmd_vxrd_last_wall_topology_v10589!=nil
        g=@pmd_vxrd_last_wall_topology_v10589[:geometry_v10592]||{}
        st[:wall_geometry_v10592]=g
      end
      st
    rescue
      nil
    end

    def vxrd_wall_geometry_audit_v10592
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      g=st==nil ? nil : st[:wall_geometry_v10592]
      if g==nil
        return {:pass=>true,:runtime=>:not_active,:vertical_pinches=>0,
          :unsupported_north=>0,:unsupported_south=>0,:orphan_face=>0}
      end
      pass=g[:vertical_pinches].to_i==0 && g[:unsupported_north].to_i==0 &&
        g[:unsupported_south].to_i==0 && g[:orphan_face].to_i==0
      g.merge(:pass=>pass,:runtime=>:active)
    rescue
      {:pass=>false,:runtime=>:error}
    end
  end
end
