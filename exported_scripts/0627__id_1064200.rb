# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Native Autotile Rule Correction I v1.06.42
#-------------------------------------------------------------------------------
# Authority rebuilt against the original RPG Maker VX material specification:
# - TileA2 is NOT 32 interchangeable ground autotiles.
# - Each row is A(3 patterns) + A(3 patterns) + B + C.
# - For each A triplet, only the leftmost pattern is the base terrain; middle
#   and right patterns are overlay/composite patterns whose transparent pixels
#   are filled by the leftmost base.
# - B does not create borders against other tiles; C also does not create
#   borders and carries the counter semantics. Neither B nor C is a generic
#   Hunt ground base.
# - TileA1 owns animated water. TileA4 owns walls. TileA5 is fixed normal tile
#   material and official VX allows designated rows as dungeon floors.
#
# Visual-rule correction requested by user:
# - A2 floor must create shoreline borders against A1 water.
# - A2 floor should NOT create an artificial outline merely because it touches
#   an A4 wall in our generated dungeon geometry. The wall visually occludes the
#   continuation of ground, so wall topology is treated as connected ground only
#   for A2 shape selection. Water remains a cut-out in that mask.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDNativeAutotileRuleCorrectionI_v10642']=true

module PMD_AC
  VXRD_A2_PRIMARY_BASE_INDICES_V10642=[0,3,8,11,16,19,24,27]
  VXRD_A2_OVERLAY_INDICES_V10642=[1,2,4,5,9,10,12,13,17,18,20,21,25,26,28,29]
  VXRD_A2_BORDERLESS_B_INDICES_V10642=[6,14,22,30]
  VXRD_A2_COUNTER_C_INDICES_V10642=[7,15,23,31]
  VXRD_A5_BASE_V10642=1536
  VXRD_A1_WATER_BASE_V10642=2096

  # Corrected semantic palette. Primary A2 floors use ONLY official A-group
  # leftmost patterns. Dungeon-like zones deliberately use fixed A5 floors.
  VXRD_NATIVE_AUTOTILE_PROFILE_V10642={
    'H01'=>{:label=>'林緣草地',  :floor_kind=>:a2,:floor_index=>0, :wall_palette=>6, :water=>false,:family=>:forest},
    'H02'=>{:label=>'苔溪濕地',  :floor_kind=>:a2,:floor_index=>0, :wall_palette=>6, :water=>true, :family=>:wetland},
    'H03'=>{:label=>'風鳴草原',  :floor_kind=>:a2,:floor_index=>3, :wall_palette=>6, :water=>false,:family=>:grassland},
    'H04'=>{:label=>'赤岩荒徑',  :floor_kind=>:a2,:floor_index=>8, :wall_palette=>17,:water=>false,:family=>:dry_rock},
    'H05'=>{:label=>'月影古徑',  :floor_kind=>:a5,:floor_index=>21,:wall_palette=>5, :water=>false,:family=>:relic},

    'H06'=>{:label=>'深蔭密林',  :floor_kind=>:a2,:floor_index=>0, :wall_palette=>6, :water=>false,:family=>:forest},
    'H07'=>{:label=>'霧澤泥地',  :floor_kind=>:a2,:floor_index=>8, :wall_palette=>17,:water=>true, :family=>:marsh},
    'H08'=>{:label=>'雷羽石道',  :floor_kind=>:a5,:floor_index=>22,:wall_palette=>14,:water=>false,:family=>:storm},
    'H09'=>{:label=>'回聲洞窟',  :floor_kind=>:a5,:floor_index=>49,:wall_palette=>17,:water=>false,:family=>:cave},
    'H10'=>{:label=>'夢霧碑地',  :floor_kind=>:a5,:floor_index=>21,:wall_palette=>5, :water=>false,:family=>:mystic},

    'H11'=>{:label=>'古木根域',  :floor_kind=>:a2,:floor_index=>0, :wall_palette=>6, :water=>false,:family=>:forest},
    'H12'=>{:label=>'霜湖雪原',  :floor_kind=>:a2,:floor_index=>24,:wall_palette=>19,:water=>true, :family=>:ice_lake},
    'H13'=>{:label=>'暴風裂谷',  :floor_kind=>:a2,:floor_index=>8, :wall_palette=>17,:water=>false,:family=>:canyon},
    'H14'=>{:label=>'鐵砂礦層',  :floor_kind=>:a5,:floor_index=>49,:wall_palette=>17,:water=>false,:family=>:mine},
    'H15'=>{:label=>'幽光祭地',  :floor_kind=>:a5,:floor_index=>55,:wall_palette=>23,:water=>false,:family=>:ritual},

    'H16'=>{:label=>'原始樹海',  :floor_kind=>:a2,:floor_index=>3, :wall_palette=>6, :water=>false,:family=>:primeval_forest},
    'H17'=>{:label=>'深潮冰灣',  :floor_kind=>:a2,:floor_index=>24,:wall_palette=>19,:water=>true, :family=>:deep_ice},
    'H18'=>{:label=>'龍風峽谷',  :floor_kind=>:a2,:floor_index=>8, :wall_palette=>22,:water=>false,:family=>:dragon_canyon},
    'H19'=>{:label=>'熔鐵古坑',  :floor_kind=>:a5,:floor_index=>54,:wall_palette=>18,:water=>false,:family=>:volcanic},
    'H20'=>{:label=>'星痕高地',  :floor_kind=>:a5,:floor_index=>53,:wall_palette=>21,:water=>false,:family=>:astral},
    'H21'=>{:label=>'裂隙聖域',  :floor_kind=>:a5,:floor_index=>21,:wall_palette=>5, :water=>false,:family=>:sanctuary}
  }

  class << self
    def vxrd_native_autotile_profile_v10642(code=nil)
      c=code.to_s.upcase
      if c.empty? && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        c=st[:code].to_s.upcase unless st==nil
      end
      p=VXRD_NATIVE_AUTOTILE_PROFILE_V10642[c]
      p==nil ? nil : p.dup.merge({:code=>c})
    rescue
      nil
    end

    def vxrd_floor_id_v10642(profile)
      return 0 if profile==nil
      if profile[:floor_kind]==:a2
        return VXRD_TILE_A2_BASE_V10641 + profile[:floor_index].to_i*48
      elsif profile[:floor_kind]==:a5
        return VXRD_A5_BASE_V10642 + profile[:floor_index].to_i
      end
      0
    rescue
      0
    end

    alias pmd_ac_v10642_palette_v10582 vxrd_palette_v10582 unless method_defined?(:pmd_ac_v10642_palette_v10582)
    def vxrd_palette_v10582(code=nil,options=nil)
      c=code.to_s.upcase
      prof=VXRD_NATIVE_AUTOTILE_PROFILE_V10642[c]
      return pmd_ac_v10642_palette_v10582(code,options) if prof==nil
      pi=prof[:wall_palette].to_i
      fid=vxrd_floor_id_v10642(prof)
      {
        :index=>pi,:floor=>fid,:floor_alt=>fid,
        :wall=>vxrd_semantic_wall_base_v10641(pi),
        :decor_a=>0,:decor_b=>0,
        :tileset_semantic_v10642=>true,
        :semantic_label_v10642=>prof[:label],
        :semantic_family_v10642=>prof[:family],
        :floor_kind_v10642=>prof[:floor_kind],
        :floor_index_v10642=>prof[:floor_index].to_i
      }
    rescue
      pmd_ac_v10642_palette_v10582(code,options)
    end

    if defined?(VXRD_HUNT_STYLE_V10600)
      VXRD_NATIVE_AUTOTILE_PROFILE_V10642.each do |code,prof|
        next unless VXRD_HUNT_STYLE_V10600[code].is_a?(Hash)
        VXRD_HUNT_STYLE_V10600[code][:palette]=prof[:wall_palette].to_i
        VXRD_HUNT_STYLE_V10600[code][:water]=prof[:water] ? true:false
        VXRD_HUNT_STYLE_V10600[code][:water_base]=VXRD_A1_WATER_BASE_V10642 if prof[:water]
      end
    end

    # Build the A2 shape mask separately from the walkable/open mask.
    # - Water is NOT connected => A2 generates shoreline boundaries.
    # - Wall topology IS connected => A2 does not draw a fake outline against
    #   an A4 wall. This emulates the desired VX editor-style visual relationship
    #   for our generated height-wall geometry.
    def vxrd_ground_shape_mask_v10642(topo,water_mask)
      return [] if topo==nil
      w=topo[:width].to_i; h=topo[:height].to_i
      mask=Array.new(w*h,false)
      for y in 0...h
        for x in 0...w
          idx=vxrd_mask_index_v10589(w,x,y)
          is_water=(water_mask && water_mask[idx]) ? true:false
          if topo[:open][idx]
            mask[idx]=!is_water
          elsif topo[:wall_top][idx] || topo[:north_face][idx] || topo[:south_face][idx] || topo[:outer][idx]
            mask[idx]=true
          end
        end
      end
      mask
    rescue
      []
    end

    def vxrd_apply_height_topology_v10589(layout,palette)
      return false if $game_map==nil || layout==nil || palette==nil
      map=$game_map.instance_variable_get(:@map)
      return false if map==nil || map.data==nil
      data=map.data
      topo=vxrd_height_topology_v10589(layout)
      return false if topo==nil
      w=topo[:width].to_i; h=topo[:height].to_i
      top_base=palette[:wall].to_i
      face_base=vxrd_wall_face_base_v10589(palette)
      water_mask=vxrd_water_mask_v10593(layout)
      water_prof=vxrd_water_profile_for_layout_v10593(layout)
      water_base=water_prof[:base].to_i
      water_base=VXRD_A1_WATER_BASE_V10642 if water_base<=0
      floor_id=palette[:floor].to_i
      floor_kind=palette[:floor_kind_v10642]
      ground_shape=vxrd_ground_shape_mask_v10642(topo,water_mask)
      for y in 0...h
        for x in 0...w
          data[x,y,0]=0; data[x,y,1]=0; data[x,y,2]=0
          idx=vxrd_mask_index_v10589(w,x,y)
          if topo[:open][idx]
            if water_mask[idx]
              # A1 water is always drawn as an autotile variant from the water
              # connectivity mask. Never stamp one representative water tile.
              data[x,y,0]=water_base+vxrd_floor_variant_from_mask_v10589(water_mask,w,h,x,y)
            elsif floor_kind==:a2
              # A2 border rules: water cuts the ground mask; walls do not.
              data[x,y,0]=floor_id+vxrd_floor_variant_from_mask_v10589(ground_shape,w,h,x,y)
            else
              # A5 is a fixed normal lower-layer tile, intentionally no autotile
              # shape arithmetic.
              data[x,y,0]=floor_id
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
      @pmd_vxrd_last_water_info_v10593={
        :biome=>(layout.respond_to?(:pmd_vxrd_biome_v10593) ? layout.pmd_vxrd_biome_v10593 : 'forest'),
        :base=>water_base,:shape=>:rectangle,:autotile=>true,
        :ground_border_at_water=>true,:ground_border_at_wall=>false,
        :bridge=>false,:river=>false,
        :rects=>(layout.respond_to?(:water_rects_v10593) ? layout.water_rects_v10593||[] : []),
        :cells=>(layout.respond_to?(:water_cells_v10593) ? layout.water_cells_v10593.size : 0),
        :types_on_floor=>(layout.respond_to?(:water_cells_v10593) && layout.water_cells_v10593.size>0 ? 1 : 0)
      }
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      true
    rescue
      false
    end

    def vxrd_native_autotile_audit_v10642
      bad=[];a2=[];a5=[];water=[]
      VXRD_NATIVE_AUTOTILE_PROFILE_V10642.each do |code,p|
        if p[:floor_kind]==:a2
          idx=p[:floor_index].to_i;a2 << [code,idx]
          bad << code+':invalid_a2_base_'+idx.to_s unless VXRD_A2_PRIMARY_BASE_INDICES_V10642.include?(idx)
        elsif p[:floor_kind]==:a5
          idx=p[:floor_index].to_i;a5 << [code,idx]
          bad << code+':invalid_a5_'+idx.to_s unless idx>=0 && idx<128
        else
          bad << code+':floor_kind'
        end
        bad << code+':wall' unless p[:wall_palette].to_i>=0 && p[:wall_palette].to_i<24
        water << code if p[:water]
      end
      bad << 'profiles' unless VXRD_NATIVE_AUTOTILE_PROFILE_V10642.size==21
      bad << 'water_scope' unless water.sort==['H02','H07','H12','H17']
      h14=VXRD_NATIVE_AUTOTILE_PROFILE_V10642['H14']||{}
      h19=VXRD_NATIVE_AUTOTILE_PROFILE_V10642['H19']||{}
      {:pass=>bad.empty?,:profiles=>VXRD_NATIVE_AUTOTILE_PROFILE_V10642.size,
       :a2_profiles=>a2.size,:a5_profiles=>a5.size,:water_codes=>water.sort,
       :h14_floor_kind=>h14[:floor_kind],:h14_floor_index=>h14[:floor_index].to_i,
       :h14_wall_palette=>h14[:wall_palette].to_i,
       :h19_floor_kind=>h19[:floor_kind],:h19_floor_index=>h19[:floor_index].to_i,
       :h19_wall_palette=>h19[:wall_palette].to_i,
       :water_autotile=>true,:ground_border_at_water=>true,:ground_border_at_wall=>false,
       :bad=>bad}
    rescue
      {:pass=>false,:profiles=>0,:bad=>['audit_error']}
    end

    alias pmd_ac_v10642_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10642_write_project_state_log)
    def project_version
      '1.06.42'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10642_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=28')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.42')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_NATIVE_AUTOTILE_RULE_CORRECTION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=H02_WATER+H14_MINE+H19_VOLCANIC_VISUAL_QA')
        text=text.gsub(/\r?\nVXRD_NATIVE_AUTOTILE_V10642_BEGIN.*?VXRD_NATIVE_AUTOTILE_V10642_END\r?\n/m,"\r\n")
        a=vxrd_native_autotile_audit_v10642
        lines=[]
        lines << ''
        lines << 'VXRD_NATIVE_AUTOTILE_V10642_BEGIN'
        lines << 'VX_RTP_A2_RULE=A3PATTERN+A3PATTERN+B+C_PER_ROW'
        lines << 'VX_RTP_A2_PRIMARY_BASE_INDICES='+VXRD_A2_PRIMARY_BASE_INDICES_V10642.join(',')
        lines << 'VX_RTP_A2_OVERLAY_INDICES='+VXRD_A2_OVERLAY_INDICES_V10642.join(',')
        lines << 'VX_RTP_A2_B_BORDERLESS='+VXRD_A2_BORDERLESS_B_INDICES_V10642.join(',')
        lines << 'VX_RTP_A2_C_COUNTER='+VXRD_A2_COUNTER_C_INDICES_V10642.join(',')
        lines << 'VXRD_NATIVE_AUTOTILE_PROFILES='+a[:profiles].to_i.to_s+'/21'
        lines << 'VXRD_A2_GROUND_PROFILES='+a[:a2_profiles].to_i.to_s
        lines << 'VXRD_A5_FIXED_FLOOR_PROFILES='+a[:a5_profiles].to_i.to_s
        lines << 'VXRD_A1_WATER_AUTOTILE=1'
        lines << 'VXRD_A1_WATER_BASE='+VXRD_A1_WATER_BASE_V10642.to_s
        lines << 'VXRD_A2_BORDER_AT_A1_WATER=1'
        lines << 'VXRD_A2_BORDER_AT_A4_WALL=0'
        lines << 'H14_FLOOR=A5:'+a[:h14_floor_index].to_i.to_s
        lines << 'H14_WALL_PALETTE='+a[:h14_wall_palette].to_i.to_s
        lines << 'H19_FLOOR=A5:'+a[:h19_floor_index].to_i.to_s
        lines << 'H19_WALL_PALETTE='+a[:h19_wall_palette].to_i.to_s
        lines << 'VXRD_NATIVE_AUTOTILE_AUDIT='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'VXRD_NATIVE_AUTOTILE_VISUAL_QA=PENDING_H02_H14_H19'
        lines << 'VXRD_NATIVE_AUTOTILE_V10642_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
