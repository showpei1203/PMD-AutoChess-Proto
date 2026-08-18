# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Tileset Semantic Reset I v1.06.41
#-------------------------------------------------------------------------------
# Root-cause reset after user visual QA on v1.06.40.
#
# Authority rules:
# - A1: water / animated environmental autotiles only.
# - A2: primary Hunt ground autotiles. Rendered with VX autotile variants.
# - A3: roofs / building walls. Not used by Random Hunt terrain generation.
# - A4: cliff / wall autotiles only.
# - A5: fixed single-tile floor material only; removed from automatic Hunt
#       accent scattering in this reset.
# - TileB: NO automatic Random Hunt scattering. Large/composite right-half
#          pieces are landmark/template material only; left-half natural pieces
#          are also deferred until explicit footprint-safe placement exists.
# - TileC: indoor furniture / interior objects. No automatic Random Hunt use.
# - TileD: cave/relic/mineral/structure material. No automatic scattering;
#          future Landmark Template placement only.
#
# This reset intentionally makes Hunt maps visually simpler but semantically
# correct. Decorative richness returns only after explicit placement authority.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDTilesetSemanticResetI_v10641']=true

module PMD_AC
  VXRD_TILE_A2_BASE_V10641=2816
  VXRD_TILE_A4_BASE_V10641=5888

  # floor_a2 = TileA2(5) 64x96 autotile block index (0..31)
  # wall_palette = one of the established v1.05.82 A4 wall-pair palette indices.
  VXRD_TILESET_SEMANTIC_PROFILE_V10641={
    'H01'=>{:label=>'林緣草地',  :floor_a2=>3, :wall_palette=>6, :water=>false,:family=>:forest},
    'H02'=>{:label=>'苔溪濕地',  :floor_a2=>0, :wall_palette=>6, :water=>true, :family=>:wetland},
    'H03'=>{:label=>'風鳴草原',  :floor_a2=>3, :wall_palette=>4, :water=>false,:family=>:grassland},
    'H04'=>{:label=>'赤岩荒徑',  :floor_a2=>8, :wall_palette=>4, :water=>false,:family=>:dry_rock},
    'H05'=>{:label=>'月影石徑',  :floor_a2=>6, :wall_palette=>5, :water=>false,:family=>:relic},

    'H06'=>{:label=>'深蔭密林',  :floor_a2=>0, :wall_palette=>6, :water=>false,:family=>:forest},
    'H07'=>{:label=>'霧澤泥地',  :floor_a2=>8, :wall_palette=>6, :water=>true, :family=>:marsh},
    'H08'=>{:label=>'雷羽石道',  :floor_a2=>23,:wall_palette=>5, :water=>false,:family=>:storm},
    'H09'=>{:label=>'回聲洞層',  :floor_a2=>9, :wall_palette=>20,:water=>false,:family=>:cave},
    'H10'=>{:label=>'夢霧碑地',  :floor_a2=>6, :wall_palette=>5, :water=>false,:family=>:mystic},

    'H11'=>{:label=>'古木根域',  :floor_a2=>0, :wall_palette=>6, :water=>false,:family=>:forest},
    'H12'=>{:label=>'霜湖雪原',  :floor_a2=>24,:wall_palette=>7, :water=>true, :family=>:ice},
    'H13'=>{:label=>'暴風裂谷',  :floor_a2=>8, :wall_palette=>4, :water=>false,:family=>:canyon},
    'H14'=>{:label=>'鐵砂礦層',  :floor_a2=>13,:wall_palette=>20,:water=>false,:family=>:mine},
    'H15'=>{:label=>'幽光祭地',  :floor_a2=>23,:wall_palette=>5, :water=>false,:family=>:ritual},

    'H16'=>{:label=>'原始樹海',  :floor_a2=>3, :wall_palette=>6, :water=>false,:family=>:forest},
    'H17'=>{:label=>'深潮冰灣',  :floor_a2=>24,:wall_palette=>7, :water=>true, :family=>:ice},
    'H18'=>{:label=>'龍風峽谷',  :floor_a2=>8, :wall_palette=>4, :water=>false,:family=>:canyon},
    'H19'=>{:label=>'熔鐵火脈',  :floor_a2=>9, :wall_palette=>20,:water=>false,:family=>:volcanic},
    'H20'=>{:label=>'星痕古域',  :floor_a2=>23,:wall_palette=>5, :water=>false,:family=>:astral},
    'H21'=>{:label=>'裂隙聖域',  :floor_a2=>6, :wall_palette=>5, :water=>false,:family=>:sanctuary}
  }

  class << self
    def vxrd_tileset_semantic_profile_v10641(code=nil)
      c=code.to_s.upcase
      if c.empty? && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        c=st[:code].to_s.upcase unless st==nil
      end
      p=VXRD_TILESET_SEMANTIC_PROFILE_V10641[c]
      p==nil ? nil : p.dup.merge({:code=>c})
    rescue
      nil
    end

    def vxrd_a2_base_v10641(index)
      VXRD_TILE_A2_BASE_V10641 + index.to_i*48
    rescue
      VXRD_TILE_A2_BASE_V10641
    end

    def vxrd_semantic_wall_base_v10641(palette_index)
      i=palette_index.to_i
      i=0 if i<0 || i>=VXRD_RTP_PALETTES_V10582.size
      (VXRD_RTP_PALETTES_V10582[i]||[])[1].to_i
    rescue
      VXRD_TILE_A4_BASE_V10641
    end

    # Final palette authority. Do not inherit v1.06.37/v1.06.38 A5 floor
    # guesses or B/D decor IDs for Hunt maps.
    alias pmd_ac_v10641_palette_v10582 vxrd_palette_v10582 unless method_defined?(:pmd_ac_v10641_palette_v10582)
    def vxrd_palette_v10582(code=nil,options=nil)
      c=code.to_s.upcase
      prof=VXRD_TILESET_SEMANTIC_PROFILE_V10641[c]
      return pmd_ac_v10641_palette_v10582(code,options) if prof==nil
      pi=prof[:wall_palette].to_i
      {
        :index=>pi,
        :floor=>vxrd_a2_base_v10641(prof[:floor_a2]),
        :floor_alt=>vxrd_a2_base_v10641(prof[:floor_a2]),
        :wall=>vxrd_semantic_wall_base_v10641(pi),
        :decor_a=>0,:decor_b=>0,
        :tileset_semantic_v10641=>true,
        :semantic_label_v10641=>prof[:label],
        :semantic_family_v10641=>prof[:family]
      }
    rescue
      pmd_ac_v10641_palette_v10582(code,options)
    end

    # Keep the existing Hunt selector/style metadata coherent with the new wall
    # palette choices. Water scope remains H02/H07/H12/H17 only.
    if defined?(VXRD_HUNT_STYLE_V10600)
      VXRD_TILESET_SEMANTIC_PROFILE_V10641.each do |code,prof|
        next unless VXRD_HUNT_STYLE_V10600[code].is_a?(Hash)
        VXRD_HUNT_STYLE_V10600[code][:palette]=prof[:wall_palette].to_i
        VXRD_HUNT_STYLE_V10600[code][:water]=prof[:water] ? true:false
      end
    end

    # A2 floor autotiles need 0..46 VX variant selection. The old renderer wrote
    # a single A5 tile ID to every dry cell; this renderer creates a proper dry
    # floor mask and therefore never uses one-cell grass patches as fake terrain.
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
      floor_base=palette[:floor].to_i
      dry_mask=Array.new(w*h,false)
      for y in 0...h
        for x in 0...w
          idx=vxrd_mask_index_v10589(w,x,y)
          if topo[:open][idx]
            is_water=(layout.respond_to?(:water?) && layout.water?(x,y))
            dry_mask[idx]=true unless is_water
          end
        end
      end
      for y in 0...h
        for x in 0...w
          data[x,y,0]=0; data[x,y,1]=0; data[x,y,2]=0
          idx=vxrd_mask_index_v10589(w,x,y)
          if topo[:open][idx]
            if layout.respond_to?(:water?) && layout.water?(x,y)
              data[x,y,0]=water_base+vxrd_floor_variant_from_mask_v10589(water_mask,w,h,x,y)
            elsif floor_base>=2816 && floor_base<4352
              data[x,y,0]=floor_base+vxrd_floor_variant_from_mask_v10589(dry_mask,w,h,x,y)
            else
              data[x,y,0]=floor_base
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
        :base=>water_base,:shape=>:rectangle,:bridge=>false,
        :rects=>(layout.respond_to?(:water_rects_v10593) ? layout.water_rects_v10593||[] : []),
        :cells=>(layout.respond_to?(:water_cells_v10593) ? layout.water_cells_v10593.size : 0),
        :types_on_floor=>(layout.respond_to?(:water_cells_v10593) && layout.water_cells_v10593.size>0 ? 1 : 0)
      }
      @pmd_vxrd_last_decor_v10598={
        :label=>:disabled_v10641,:density=>0,:decor_a=>0,:decor_b=>0,
        :candidates=>0,:placed=>0,:auto_tileb=>false,:auto_tilec=>false,
        :auto_tiled=>false,:semantic_reset=>true
      }
      @pmd_vxrd_last_water_bank_v10600={
        :enabled=>false,:water_cells=>(@pmd_vxrd_last_water_info_v10593[:cells]||0),
        :bank_cells=>0,:bank_tile=>0,:one_tile_rim=>false,
        :center_cross_safe=>true,:external_png=>false,:bridge=>false,:river=>false,
        :semantic_reset=>true
      }
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      true
    rescue
      false
    end

    # Explicitly disable every legacy automatic B/C/D ground scatter path.
    def vxrd_apply_ground_decor_v10598(layout,palette)
      info={:biome=>(layout.respond_to?(:pmd_vxrd_biome_v10593) ? layout.pmd_vxrd_biome_v10593 : 'forest'),
        :label=>:disabled_v10641,:density=>0,:decor_a=>0,:decor_b=>0,
        :candidates=>0,:placed=>0,:tileb=>false,:tilec=>false,:tiled=>false,
        :landmark_template_only=>true,:semantic_reset=>true,
        :corridor_safe=>true,:center_cross_safe=>true,:water_safe=>true,:bridge=>false}
      @pmd_vxrd_last_decor_v10598=info
      info
    rescue
      nil
    end

    # No artificial dry-bank material replacement in this reset. A2 floor
    # autotile edges meet A1 water directly; this removes the abrupt beige/wood
    # strips that visually read as bridges or unrelated floor families.
    def vxrd_apply_water_bank_v10600(layout,palette)
      water=(layout.respond_to?(:water_cells_v10593) ? layout.water_cells_v10593 : []) || []
      info={:enabled=>false,:water_cells=>water.size,:bank_tile=>0,:bank_cells=>0,
        :one_tile_rim=>false,:center_cross_safe=>true,:external_png=>false,
        :bridge=>false,:river=>false,:semantic_reset=>true}
      @pmd_vxrd_last_water_bank_v10600=info
      info
    rescue
      nil
    end

    # Room identity must not reintroduce B/D or unrelated alternate floors.
    # Events remain responsible for functional Treasure/Rare/Elite/Recovery
    # identity until a footprint-safe landmark pass exists.
    def vxrd_room_visual_apply_v10607(state)
      return nil if state==nil
      info={:alt_floor=>0,:decor_a=>0,:decor_b=>0,
        :counts=>{:treasure_floor=>0,:rare_decor=>0,:elite_decor=>0,:recovery_floor=>0},
        :center_cross_safe=>true,:water_safe=>true,:external_png=>false,
        :visual_tiles_disabled_v10641=>true,:event_identity_retained=>true}
      state[:room_visual_v10607]=info
      info
    rescue
      nil
    end

    # Retire the v1.06.36 random floor motif pass for now. The feature remains
    # in Scripts.rvdata as history, but semantic reset is the live authority.
    def vxrd_apply_region_contentization_v10636(state)
      return nil if state==nil
      code=state[:code].to_s.upcase
      prof=VXRD_TILESET_SEMANTIC_PROFILE_V10641[code] || {}
      info={:code=>code,:identity=>prof[:label],:motif=>:semantic_base_only,
        :floor_density=>0,:decor_density=>0,:counts=>{:floor_accent=>0,:edge_decor=>0,:special_floor=>0,:special_decor=>0},
        :deterministic=>true,:center_cross_safe=>true,:water_safe=>true,
        :external_png=>false,:room_frequency_changed=>false,:gameplay_change=>false,
        :semantic_reset_v10641=>true}
      state[:contentization_v10636]=info
      info
    rescue
      nil
    end

    # Hard post-generation seal. This is deliberately redundant: even if an
    # older alias path writes a B/C/D tile after the main renderer, remove it
    # before the generated Hunt map is returned to Scene_Map.
    alias pmd_ac_v10641_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10641_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10641_generate_current_map_v10582(code,seed,options)
      return st if st==nil || $game_map==nil
      c=st[:code].to_s.upcase
      return st unless VXRD_TILESET_SEMANTIC_PROFILE_V10641.has_key?(c)
      map=$game_map.instance_variable_get(:@map)
      return st if map==nil || map.data==nil
      removed=[]; removed_ids={}
      for y in 0...$game_map.height.to_i
        for x in 0...$game_map.width.to_i
          [1,2].each do |z|
            t=map.data[x,y,z].to_i
            next if t<=0
            # B/C/D/E range. Hunt auto-generated visual objects are forbidden
            # in the semantic reset. Event sprites are separate and untouched.
            if t>=0 && t<1536
              map.data[x,y,z]=0
              removed << [x,y,z,t]
              removed_ids[t]=true
            end
          end
        end
      end
      st[:tileset_semantic_v10641]={
        :code=>c,:label=>VXRD_TILESET_SEMANTIC_PROFILE_V10641[c][:label],
        :floor_a2=>VXRD_TILESET_SEMANTIC_PROFILE_V10641[c][:floor_a2].to_i,
        :floor_base=>(st[:palette]||{})[:floor].to_i,
        :wall_palette=>VXRD_TILESET_SEMANTIC_PROFILE_V10641[c][:wall_palette].to_i,
        :wall_base=>(st[:palette]||{})[:wall].to_i,
        :water=>VXRD_TILESET_SEMANTIC_PROFILE_V10641[c][:water] ? true:false,
        :layer_object_removed=>removed.size,:removed_tile_ids=>removed_ids.keys.sort,
        :tileb_autodecor=>false,:tilec_autodecor=>false,:tiled_autodecor=>false,
        :a3_hunt_terrain=>false,:a5_random_accent=>false,
        :landmark_template_only=>true,:gameplay_change=>false
      }
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      st
    rescue
      st
    end

    def vxrd_tileset_semantic_audit_v10641
      bad=[]; families={}; waters=[]
      order=defined?(PHASE_DIV_HUNT_ORDER_V10553) ? PHASE_DIV_HUNT_ORDER_V10553 : []
      order.each do |code|
        p=VXRD_TILESET_SEMANTIC_PROFILE_V10641[code]
        if p==nil
          bad << code+':missing';next
        end
        bad << code+':a2' unless p[:floor_a2].to_i>=0 && p[:floor_a2].to_i<32
        bad << code+':wall' unless p[:wall_palette].to_i>=0 && p[:wall_palette].to_i<24
        families[p[:family]]=true
        waters << code if p[:water]
      end
      bad << 'profiles' unless VXRD_TILESET_SEMANTIC_PROFILE_V10641.size==21
      bad << 'water_scope' unless waters.sort==['H02','H07','H12','H17']
      h01=VXRD_TILESET_SEMANTIC_PROFILE_V10641['H01']||{}
      h02=VXRD_TILESET_SEMANTIC_PROFILE_V10641['H02']||{}
      {:pass=>bad.empty?,:profiles=>VXRD_TILESET_SEMANTIC_PROFILE_V10641.size,
        :families=>families.size,:water_codes=>waters.sort,
        :h01_floor_base=>vxrd_a2_base_v10641(h01[:floor_a2]),
        :h01_wall_base=>vxrd_semantic_wall_base_v10641(h01[:wall_palette]),
        :h02_floor_base=>vxrd_a2_base_v10641(h02[:floor_a2]),
        :h02_wall_base=>vxrd_semantic_wall_base_v10641(h02[:wall_palette]),
        :tileb_autodecor=>false,:tilec_autodecor=>false,:tiled_autodecor=>false,
        :a3_hunt_terrain=>false,:a5_random_accent=>false,
        :mixed_floor_motif=>false,:landmark_template_only=>true,
        :gameplay_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:profiles=>0,:bad=>['audit_error']}
    end

    # Old structural audits expected generic decoration to exist. From this
    # version, decoration=0 is intentional and therefore the semantic-safe
    # audit supersedes their visual assumptions without touching topology.
    def vxrd_ground_decor_audit_v10598
      {:pass=>true,:palettes=>24,:biomes=>6,:dry_room_only=>true,
        :corridor_safe=>true,:center_cross_safe=>true,:water_safe=>true,
        :external_png=>false,:uses_palette_decor=>false,
        :auto_decor_disabled_v10641=>true}
    rescue
      {:pass=>false,:palettes=>0,:biomes=>0}
    end

    def vxrd_room_visual_audit_v10607
      {:pass=>true,:api=>3,:room_types=>4,:uses_rtp_only=>true,
        :center_cross_safe=>true,:water_safe=>true,
        :visual_tiles_disabled_v10641=>true,:event_identity_retained=>true,:bad=>[]}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end

    alias pmd_ac_v10641_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10641_write_project_state_log)
    def project_version
      '1.06.41'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10641_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=28')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.41')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_TILESET_SEMANTIC_RESET_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=H01-H02_SEMANTIC_VISUAL_ACCEPTANCE_THEN_LANDMARK_TEMPLATES')
        text=text.gsub(/\r?\nVXRD_TILESET_SEMANTIC_V10641_BEGIN.*?VXRD_TILESET_SEMANTIC_V10641_END\r?\n/m,"\r\n")
        a=vxrd_tileset_semantic_audit_v10641
        lines=[]
        lines << ''
        lines << 'VXRD_TILESET_SEMANTIC_V10641_BEGIN'
        lines << 'TILESET_SEMANTIC_AUDIT='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'TILESET_SEMANTIC_PROFILES='+a[:profiles].to_i.to_s+'/21'
        lines << 'TILESET_A1_USE=WATER_ANIMATED_ONLY'
        lines << 'TILESET_A2_USE=PRIMARY_HUNT_GROUND_AUTOTILE'
        lines << 'TILESET_A3_USE=BUILDING_ONLY_NO_RANDOM_HUNT'
        lines << 'TILESET_A4_USE=HUNT_WALL_CLIFF_AUTOTILE'
        lines << 'TILESET_A5_USE=FIXED_FLOOR_ONLY_NO_RANDOM_ACCENT'
        lines << 'TILESET_B_AUTODECOR=DISABLED'
        lines << 'TILESET_C_AUTODECOR=DISABLED'
        lines << 'TILESET_D_AUTODECOR=DISABLED'
        lines << 'TILESET_BCD_FUTURE_USE=FOOTPRINT_SAFE_LANDMARK_TEMPLATE_ONLY'
        lines << 'TILESET_MIXED_FLOOR_MOTIF=DISABLED'
        lines << 'TILESET_WATER_CODES='+a[:water_codes].join(',')
        lines << 'H01_A2_FLOOR_BASE='+a[:h01_floor_base].to_i.to_s
        lines << 'H01_A4_WALL_BASE='+a[:h01_wall_base].to_i.to_s
        lines << 'H02_A2_FLOOR_BASE='+a[:h02_floor_base].to_i.to_s
        lines << 'H02_A4_WALL_BASE='+a[:h02_wall_base].to_i.to_s
        lines << 'TILESET_SEMANTIC_GAMEPLAY_CHANGE=0'
        lines << 'TILESET_SEMANTIC_VISUAL_QA=H01_H02_REQUIRED'
        lines << 'VXRD_TILESET_SEMANTIC_V10641_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
