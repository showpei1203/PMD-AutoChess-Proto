# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD RTP Material Authority II v1.06.38
#-------------------------------------------------------------------------------
# Latest visual authority:
#   TileA1(5), TileA2(5), TileA3(5), TileA4(6), TileA5(4),
#   TileB(3), TileC(3), TileD(2)
#
# Critical correction from user review:
# - TileB columns 8..15 (right half) are large-map/composite tiles and MUST NOT
#   be scattered as one-cell Hunt decor.
# - TileB auto-decor is therefore both LEFT-HALF ONLY and WHITELIST ONLY.
# - TileC is not used by automatic Hunt decor.
# - TileD contains many composite statues/structures; only verified independent
#   rock/mineral/crystal/pile cells are allowed for auto-decor. Larger objects
#   are reserved for a later Landmark Template pass.
# - Re-audit H01-H21 A5 floor/alt-floor choices against the latest supplied RTP.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRTPMaterialAuthorityII_v10638']=true

module PMD_AC
  VXRD_RTP_TILE_SOURCE_V10638={
    :tile_a1=>'TileA1(5).png',:tile_a2=>'TileA2(5).png',
    :tile_a3=>'TileA3(5).png',:tile_a4=>'TileA4(6).png',
    :tile_a5=>'TileA5(4).png',:tile_b=>'TileB(3).png',
    :tile_c=>'TileC(3).png',:tile_d=>'TileD(2).png'
  }

  # Verified independent one-cell natural objects from TileB LEFT half only.
  VXRD_TILEB_SINGLE_SAFE_V10638=[
    160,161,162,163,164,167,
    176,177,178,179,180,181,182,183,
    193,195,196,197,198,199,
    208,209,210,211,214,215,
    224,225,226,227,229,230,231,
    240,241,242,243,244
  ]

  # Verified independent one-cell rock/mineral/crystal/pile objects in TileD.
  # Values are global VX B/C/D tile IDs (TileD local + 512).
  VXRD_TILED_SINGLE_SAFE_V10638=[
    544,545,546,547,548,549,550,551,
    560,561,562,563,564,565,566,567,
    574,575,576,577,578,579,580,581,582,583,
    592,593,594,595,596,597,598,599,
    656,657,658,659,660,661,
    664,665,666,667,668,669,670,671
  ]

  VXRD_HUNT_RTP_MATERIAL_V10638={
    'H01'=>{:label=>'林緣草地',  :floor=>1558,:floor_alt=>1588,:decor=>[160,161,162,163,164,176,177,178,179,180,181,182,195,196,197,198,199],:density=>12,:family=>:forest},
    'H02'=>{:label=>'苔溪濕岸',  :floor=>1636,:floor_alt=>1584,:decor=>[160,161,162,163,180,195,215,225,244],:density=>9,:family=>:wetland},
    'H03'=>{:label=>'風鳴草原',  :floor=>1558,:floor_alt=>1612,:decor=>[160,161,162,163,176,177,178,179,195,244],:density=>6,:family=>:grassland},
    'H04'=>{:label=>'赤岩荒徑',  :floor=>1598,:floor_alt=>1638,:decor=>[167,183,195,226,544,546,550,560,576,592,656],:density=>11,:family=>:red_rock},
    'H05'=>{:label=>'月影遺跡',  :floor=>1621,:floor_alt=>1629,:decor=>[565,567,581,583,597,599],:density=>8,:family=>:relic},

    'H06'=>{:label=>'深蔭密林',  :floor=>1636,:floor_alt=>1596,:decor=>[160,161,162,163,164,180,181,182,196,197,198,199,208,209,224,225],:density=>16,:family=>:deep_forest},
    'H07'=>{:label=>'霧澤泥地',  :floor=>1584,:floor_alt=>1636,:decor=>[160,161,162,163,180,195,208,215,225,244],:density=>11,:family=>:marsh},
    'H08'=>{:label=>'雷羽石道',  :floor=>1621,:floor_alt=>1637,:decor=>[545,547,549,551,561,565,577,581,593,597],:density=>8,:family=>:storm},
    'H09'=>{:label=>'回聲洞層',  :floor=>1593,:floor_alt=>1564,:decor=>[544,545,560,561,576,577,592,593,656,660],:density=>13,:family=>:cave},
    'H10'=>{:label=>'夢霧碑地',  :floor=>1621,:floor_alt=>1629,:decor=>[565,567,581,583,597,599],:density=>9,:family=>:mystic_relic},

    'H11'=>{:label=>'古木根域',  :floor=>1596,:floor_alt=>1636,:decor=>[160,161,162,163,164,180,181,182,196,197,198,199,208,209,224,225,229,230],:density=>18,:family=>:ancient_forest},
    'H12'=>{:label=>'霜湖冰原',  :floor=>1589,:floor_alt=>1585,:decor=>[241,547,563,565,579,581,595,597,658],:density=>9,:family=>:ice_lake},
    'H13'=>{:label=>'暴風裂谷',  :floor=>1593,:floor_alt=>1633,:decor=>[545,561,577,593,656,660],:density=>9,:family=>:storm_canyon},
    'H14'=>{:label=>'鐵砂礦坑',  :floor=>1609,:floor_alt=>1593,:decor=>[544,545,546,547,548,549,550,551,560,561,576,577,592,593,664,665,666,667],:density=>15,:family=>:mine},
    'H15'=>{:label=>'幽光祭壇',  :floor=>1629,:floor_alt=>1557,:decor=>[549,551,565,567,581,583,597,599],:density=>10,:family=>:ritual},

    'H16'=>{:label=>'原始樹海',  :floor=>1596,:floor_alt=>1636,:decor=>[160,161,162,163,164,180,181,182,196,197,198,199,208,209,224,225,229,230],:density=>20,:family=>:primeval_forest},
    'H17'=>{:label=>'深潮冰灣',  :floor=>1637,:floor_alt=>1613,:decor=>[241,547,563,565,579,581,595,597,658],:density=>10,:family=>:deep_ice},
    'H18'=>{:label=>'龍風峽谷',  :floor=>1633,:floor_alt=>1593,:decor=>[545,547,561,565,577,581,593,597,656,660],:density=>10,:family=>:dragon_canyon},
    'H19'=>{:label=>'熔鐵火脈',  :floor=>1634,:floor_alt=>1598,:decor=>[226,546,550,562,566,578,582,594,598,666,667],:density=>16,:family=>:volcanic},
    'H20'=>{:label=>'星痕古域',  :floor=>1629,:floor_alt=>1621,:decor=>[549,551,565,567,581,583,597,599],:density=>11,:family=>:astral_relic},
    'H21'=>{:label=>'裂隙聖域',  :floor=>1585,:floor_alt=>1629,:decor=>[545,547,549,551,561,563,565,567,581,583,597,599],:density=>12,:family=>:sanctuary}
  }

  class << self
    def vxrd_tileb_right_half_v10638?(tile)
      t=tile.to_i
      t>=0 && t<=255 && (t%16)>=8
    rescue
      true
    end

    def vxrd_safe_single_decor_v10638?(tile)
      t=tile.to_i
      return VXRD_TILEB_SINGLE_SAFE_V10638.include?(t) if t>=0 && t<=255
      return false if t>=256 && t<=511 # TileC reserved from automatic Hunt decor
      return VXRD_TILED_SINGLE_SAFE_V10638.include?(t) if t>=512 && t<=767
      false
    rescue
      false
    end

    def vxrd_hunt_material_v10638(code=nil)
      c=code.to_s.upcase
      if c.empty? && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        c=st[:code].to_s.upcase unless st==nil
      end
      m=VXRD_HUNT_RTP_MATERIAL_V10638[c]
      m==nil ? nil : m.dup.merge({:code=>c})
    rescue
      nil
    end

    # v1.06.37 methods reference the mutable v10637 hash. Replace its content
    # below so all existing palette/floor hooks inherit the corrected mapping.

    def vxrd_content_decor_tile_v10636(profile,palette,hash)
      tiles=[]
      if profile!=nil && profile[:decor_tiles_v10638].is_a?(Array)
        tiles=profile[:decor_tiles_v10638]
      elsif profile!=nil && profile[:decor_tiles_v10637].is_a?(Array)
        tiles=profile[:decor_tiles_v10637]
      end
      tiles=tiles.find_all{|t|vxrd_safe_single_decor_v10638?(t)}
      if tiles.empty?
        a=(palette||{})[:decor_a].to_i;b=(palette||{})[:decor_b].to_i
        tiles=[a,b].find_all{|t|vxrd_safe_single_decor_v10638?(t)}
      end
      return 0 if tiles.empty?
      tiles[hash.to_i % tiles.size].to_i
    rescue
      0
    end

    # Same deterministic candidate contract as v1.06.37, now with hard tile
    # sheet safety validation rather than only retiring B77/B82.
    def vxrd_apply_ground_decor_v10598(layout,palette)
      return nil if $game_map==nil || layout==nil || palette==nil
      map=$game_map.instance_variable_get(:@map)
      return nil if map==nil || map.data==nil
      code=respond_to?(:vxrd_layout_hunt_code_v10637) ? vxrd_layout_hunt_code_v10637(layout) : ''
      mat=VXRD_HUNT_RTP_MATERIAL_V10638[code]
      biome=vxrd_decor_biome_v10598(layout)
      prof=VXRD_DECOR_PROFILE_V10598[biome] || VXRD_DECOR_PROFILE_V10598['forest']
      tiles=(mat==nil ? [] : (mat[:decor]||[])).find_all{|t|vxrd_safe_single_decor_v10638?(t)}
      if tiles.empty?
        tiles=[palette[:decor_a],palette[:decor_b]].find_all{|t|vxrd_safe_single_decor_v10638?(t)}
      end
      candidates=vxrd_decor_candidate_cells_v10598(layout)
      seed=(layout.instance_variable_get(:@seed).to_i ^ 0x10638DEC) & 0x7fffffff
      rng=VXRD_RNG_V10582.new(seed)
      density=(mat==nil ? prof[:density].to_i : mat[:density].to_i)
      density=[[density,0].max,28].min
      placed=[]
      candidates.each do |pt|
        next if tiles.empty?
        next unless rng.rand(100)<density
        x=pt[0];y=pt[1]
        next unless map.data[x,y,1].to_i==0 && map.data[x,y,2].to_i==0
        tile=tiles[rng.rand(tiles.size)].to_i
        next unless vxrd_safe_single_decor_v10638?(tile)
        map.data[x,y,1]=tile
        placed << [x,y,tile]
      end
      info={:biome=>biome,:label=>(mat==nil ? prof[:label] : mat[:label]),
        :hunt_code=>code,:density=>density,:candidates=>candidates.size,
        :placed=>placed.size,:verified_rtp_material=>(mat!=nil),
        :tileb_right_half_forbidden=>true,:tilec_autodecor=>false,
        :tiled_single_whitelist=>true,:landmark_template_deferred=>true,
        :corridor_safe=>true,:center_cross_safe=>true,:water_safe=>true,
        :bridge=>false,:external_png=>false}
      @pmd_vxrd_last_decor_v10598=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    def vxrd_rtp_material_audit_v10638
      bad=[];floors={};decor={};families={};bcount=0;dcount=0
      order=defined?(PHASE_DIV_HUNT_ORDER_V10553) ? PHASE_DIV_HUNT_ORDER_V10553 : []
      order.each do |code|
        m=VXRD_HUNT_RTP_MATERIAL_V10638[code]
        if m==nil
          bad << code+':missing';next
        end
        f=m[:floor].to_i;fa=m[:floor_alt].to_i;ds=m[:decor]||[]
        bad << code+':floor' unless f>=1536 && f<=1663
        bad << code+':floor_alt' unless fa>=1536 && fa<=1663
        bad << code+':decor_empty' if ds.empty?
        ds.each do |t|
          ti=t.to_i
          bad << code+':tileB_right_'+ti.to_s if vxrd_tileb_right_half_v10638?(ti)
          bad << code+':unsafe_'+ti.to_s unless vxrd_safe_single_decor_v10638?(ti)
          bcount+=1 if ti<=255
          dcount+=1 if ti>=512 && ti<=767
          decor[ti]=true
        end
        floors[f]=true;floors[fa]=true;families[m[:family]]=true
      end
      bad << 'profiles' unless VXRD_HUNT_RTP_MATERIAL_V10638.size==21
      bad << 'source_sheets' unless VXRD_RTP_TILE_SOURCE_V10638.size==8
      {:pass=>bad.empty?,:profiles=>VXRD_HUNT_RTP_MATERIAL_V10638.size,
        :source_sheets=>VXRD_RTP_TILE_SOURCE_V10638.size,:floor_tiles=>floors.size,
        :decor_tiles=>decor.size,:families=>families.size,:b_refs=>bcount,:d_refs=>dcount,
        :tileb_right_half_forbidden=>true,:tilec_autodecor=>false,
        :tiled_composite_forbidden=>true,:landmark_template_deferred=>true,
        :deterministic=>true,:topology_change=>false,:balance_change=>false,
        :external_png=>false,:bad=>bad}
    rescue
      {:pass=>false,:profiles=>0,:bad=>['audit_error']}
    end

    alias pmd_ac_v10638_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10638_write_project_state_log)
    def project_version
      '1.06.38'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10638_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=26')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.38')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_RTP_MATERIAL_AUTHORITY_II_SAFE_SINGLE_TILE')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_A1_WATER+A4_WALL+LANDMARK_TEMPLATE')
        text=text.gsub(/\r?\nVXRD_RTP_MATERIAL_V10638_BEGIN.*?VXRD_RTP_MATERIAL_V10638_END\r?\n/m,"\r\n")
        a=vxrd_rtp_material_audit_v10638
        lines=[]
        lines << ''
        lines << 'VXRD_RTP_MATERIAL_V10638_BEGIN'
        lines << 'RTP_REFERENCE_SHEETS='+a[:source_sheets].to_i.to_s+'/8'
        lines << 'HUNT_RTP_MATERIAL_PROFILES='+a[:profiles].to_i.to_s+'/21'
        lines << 'HUNT_RTP_FLOOR_TILES='+a[:floor_tiles].to_i.to_s
        lines << 'HUNT_RTP_DECOR_TILES='+a[:decor_tiles].to_i.to_s
        lines << 'HUNT_RTP_MATERIAL_FAMILIES='+a[:families].to_i.to_s
        lines << 'TILEB_AUTODECOR=LEFT_HALF_WHITELIST_ONLY'
        lines << 'TILEB_RIGHT_HALF=LARGE_MAP_LANDMARK_ONLY'
        lines << 'TILEC_AUTODECOR=DISABLED'
        lines << 'TILED_AUTODECOR=VERIFIED_SINGLE_TILE_WHITELIST_ONLY'
        lines << 'TILED_COMPOSITE=LANDMARK_TEMPLATE_ONLY'
        lines << 'RTP_MATERIAL_DETERMINISTIC=1'
        lines << 'RTP_MATERIAL_TOPOLOGY_CHANGE=0'
        lines << 'RTP_MATERIAL_BALANCE_CHANGE=0'
        lines << 'RTP_MATERIAL_EXTERNAL_PNG=0'
        lines << 'RTP_MATERIAL_AUDIT='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'RTP_MATERIAL_VISUAL_QA=PENDING_USER_REVIEW'
        lines << 'VXRD_RTP_MATERIAL_V10638_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end

  # Make all existing v1.06.37 material hooks consume the corrected authority.
  if defined?(VXRD_HUNT_RTP_MATERIAL_V10637)
    VXRD_HUNT_RTP_MATERIAL_V10637.clear
    VXRD_HUNT_RTP_MATERIAL_V10638.each{|code,m| VXRD_HUNT_RTP_MATERIAL_V10637[code]=m.dup}
  end

  if defined?(VXRD_HUNT_CONTENT_PROFILE_V10636)
    VXRD_HUNT_RTP_MATERIAL_V10638.each do |code,mat|
      p=VXRD_HUNT_CONTENT_PROFILE_V10636[code]
      next if p==nil
      p[:decor_tiles_v10637]=(mat[:decor]||[]).dup
      p[:decor_tiles_v10638]=(mat[:decor]||[]).dup
      p[:rtp_floor_v10637]=mat[:floor].to_i
      p[:rtp_floor_alt_v10637]=mat[:floor_alt].to_i
      p[:rtp_floor_v10638]=mat[:floor].to_i
      p[:rtp_floor_alt_v10638]=mat[:floor_alt].to_i
      p[:rtp_material_label_v10637]=mat[:label]
      p[:rtp_material_label_v10638]=mat[:label]
    end
  end
end
