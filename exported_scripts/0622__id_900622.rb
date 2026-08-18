# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD RTP Material Authority I v1.06.37
#-------------------------------------------------------------------------------
# User-supplied RPG Maker VX RTP TileA1/A2/A3/A4/A5/B/C/D sheets are the
# visual authority for Hunt contentization from this version forward.
#
# Purpose:
# - Replace the legacy guessed decor IDs (notably TileB 77/82) with verified
#   RTP material choices.
# - Give H01-H21 deterministic, biome-appropriate A5 ground material and
#   verified TileB/TileD edge decoration.
# - Preserve BSP topology, wall autotile authority, water scope, room types,
#   encounter/reward balance and all battle systems.
# - Keep this layer fully deterministic under the existing Hunt seed contract.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRTPMaterialAuthorityI_v10637']=true

module PMD_AC
  # VX tile ID anchors used by the supplied RTP sheets.
  # B=0..255, C=256..511, D=512..767, A5 starts at 1536.
  VXRD_RTP_TILE_SOURCE_V10637={
    :tile_a1=>'TileA1(4).png',:tile_a2=>'TileA2(4).png',
    :tile_a3=>'TileA3(4).png',:tile_a4=>'TileA4(5).png',
    :tile_a5=>'TileA5(3).png',:tile_b=>'TileB(2).png',
    :tile_c=>'TileC(2).png',:tile_d=>'TileD(1).png'
  }

  # NOTE: decor IDs below were chosen from the actual supplied RTP sheets.
  # Large multi-cell building/statue fragments are intentionally excluded.
  # Decoration is restricted to dry room edges and never owns the center route.
  VXRD_HUNT_RTP_MATERIAL_V10637={
    'H01'=>{:label=>'林緣草地',  :floor=>1558,:floor_alt=>1596,:decor=>[160,161,162,163,176,177,178,180,181,164],:density=>12,:family=>:forest},
    'H02'=>{:label=>'苔溪濕岸',  :floor=>1584,:floor_alt=>1558,:decor=>[160,161,163,180,195,215,244,90],            :density=>9, :family=>:wetland},
    'H03'=>{:label=>'風鳴草原',  :floor=>1558,:floor_alt=>1596,:decor=>[160,161,162,176,177,215],                   :density=>6, :family=>:grassland},
    'H04'=>{:label=>'赤岩荒徑',  :floor=>1553,:floor_alt=>1634,:decor=>[167,183,195,244,544,546,560,562],           :density=>11,:family=>:red_rock},
    'H05'=>{:label=>'月影遺跡',  :floor=>1581,:floor_alt=>1579,:decor=>[536,537,545,549,551,565,567],               :density=>8, :family=>:relic},

    'H06'=>{:label=>'深蔭密林',  :floor=>1596,:floor_alt=>1558,:decor=>[160,161,163,164,180,181,182,208,209,231],   :density=>16,:family=>:deep_forest},
    'H07'=>{:label=>'霧澤泥地',  :floor=>1564,:floor_alt=>1596,:decor=>[163,180,195,215,227,244,545,561],           :density=>11,:family=>:marsh},
    'H08'=>{:label=>'雷羽石道',  :floor=>1557,:floor_alt=>1637,:decor=>[167,195,244,547,549,551,565,567],           :density=>8, :family=>:storm},
    'H09'=>{:label=>'回聲洞層',  :floor=>1592,:floor_alt=>1565,:decor=>[167,183,195,545,561,562,565,593],           :density=>13,:family=>:cave},
    'H10'=>{:label=>'夢霧碑地',  :floor=>1579,:floor_alt=>1581,:decor=>[536,537,545,549,551,565,567],               :density=>9, :family=>:mystic_relic},

    'H11'=>{:label=>'古木根域',  :floor=>1596,:floor_alt=>1558,:decor=>[160,163,164,180,181,182,208,209,231,227],   :density=>18,:family=>:ancient_forest},
    'H12'=>{:label=>'霜湖冰原',  :floor=>1587,:floor_alt=>1597,:decor=>[29,30,31,45,46,47,241,563,595,597],         :density=>9, :family=>:ice_lake},
    'H13'=>{:label=>'暴風裂谷',  :floor=>1565,:floor_alt=>1593,:decor=>[167,183,195,244,545,561,593,594],           :density=>9, :family=>:storm_canyon},
    'H14'=>{:label=>'鐵砂礦坑',  :floor=>1593,:floor_alt=>1565,:decor=>[544,545,546,547,548,549,550,551,560,561,665,666,667],:density=>15,:family=>:mine},
    'H15'=>{:label=>'幽光祭壇',  :floor=>1580,:floor_alt=>1599,:decor=>[536,537,549,551,565,567,597,599],           :density=>10,:family=>:ritual},

    'H16'=>{:label=>'原始樹海',  :floor=>1596,:floor_alt=>1558,:decor=>[160,161,163,164,180,181,182,208,209,229,231],:density=>20,:family=>:primeval_forest},
    'H17'=>{:label=>'深潮冰灣',  :floor=>1597,:floor_alt=>1587,:decor=>[29,30,31,45,46,47,241,563,595,597],         :density=>10,:family=>:deep_ice},
    'H18'=>{:label=>'龍風峽谷',  :floor=>1557,:floor_alt=>1593,:decor=>[167,183,195,244,545,561,593,597,599],       :density=>10,:family=>:dragon_canyon},
    'H19'=>{:label=>'熔鐵火脈',  :floor=>1586,:floor_alt=>1594,:decor=>[226,546,550,562,566,598,665,667],           :density=>16,:family=>:volcanic},
    'H20'=>{:label=>'星痕古域',  :floor=>1637,:floor_alt=>1581,:decor=>[536,537,549,551,565,567,597,599],           :density=>11,:family=>:astral_relic},
    'H21'=>{:label=>'裂隙聖域',  :floor=>1599,:floor_alt=>1637,:decor=>[536,537,549,551,565,567,597,599],           :density=>12,:family=>:sanctuary}
  }

  # Explicitly ban the two confirmed legacy visual mismatches from automatic
  # Hunt ground decoration. B77 = yellow tent, B82 = wooden market/stall piece.
  VXRD_RETIRED_GUESSED_DECOR_V10637=[77,82]

  class << self
    def vxrd_hunt_material_v10637(code=nil)
      c=code.to_s.upcase
      if c.empty? && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        c=st[:code].to_s.upcase unless st==nil
      end
      m=VXRD_HUNT_RTP_MATERIAL_V10637[c]
      m==nil ? nil : m.dup.merge({:code=>c})
    rescue
      nil
    end

    def vxrd_layout_hunt_code_v10637(layout)
      o=layout==nil ? {} : (layout.instance_variable_get(:@options) rescue {})
      c=(o[:hunt_code_v10600]||o[:hunt_code]||'').to_s.upcase
      if c.empty? && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        c=st[:code].to_s.upcase unless st==nil
      end
      c
    rescue
      ''
    end

    alias pmd_ac_v10637_palette_v10582 vxrd_palette_v10582 unless method_defined?(:pmd_ac_v10637_palette_v10582)
    def vxrd_palette_v10582(code=nil,options=nil)
      p=pmd_ac_v10637_palette_v10582(code,options)
      return p if p==nil
      m=vxrd_hunt_material_v10637(code)
      return p if m==nil
      q=p.dup
      q[:floor]=m[:floor].to_i
      q[:floor_alt]=m[:floor_alt].to_i
      q[:decor_a]=(m[:decor]||[])[0].to_i
      q[:decor_b]=(m[:decor]||[])[1].to_i
      q[:rtp_material_v10637]=m[:label]
      q[:rtp_family_v10637]=m[:family]
      q
    rescue
      p
    end

    alias pmd_ac_v10637_floor_family_alt_v10600 vxrd_floor_family_alt_v10600 unless method_defined?(:pmd_ac_v10637_floor_family_alt_v10600)
    def vxrd_floor_family_alt_v10600(floor_id)
      f=floor_id.to_i
      st=respond_to?(:vxrd_state_v10582) ? (vxrd_state_v10582 rescue nil) : nil
      if st!=nil
        m=VXRD_HUNT_RTP_MATERIAL_V10637[st[:code].to_s.upcase]
        if m!=nil && m[:floor].to_i==f
          return m[:floor_alt].to_i
        end
      end
      VXRD_HUNT_RTP_MATERIAL_V10637.each_value do |m|
        return m[:floor_alt].to_i if m[:floor].to_i==f
      end
      pmd_ac_v10637_floor_family_alt_v10600(floor_id)
    rescue
      floor_id.to_i
    end

    # Replaces the old v1.05.98 use of palette.decor_a/decor_b. It deliberately
    # keeps the same candidate safety rules and deterministic RNG contract.
    def vxrd_apply_ground_decor_v10598(layout,palette)
      return nil if $game_map==nil || layout==nil || palette==nil
      map=$game_map.instance_variable_get(:@map)
      return nil if map==nil || map.data==nil
      code=vxrd_layout_hunt_code_v10637(layout)
      mat=VXRD_HUNT_RTP_MATERIAL_V10637[code]
      biome=vxrd_decor_biome_v10598(layout)
      prof=VXRD_DECOR_PROFILE_V10598[biome] || VXRD_DECOR_PROFILE_V10598['forest']
      tiles=(mat==nil ? [] : (mat[:decor]||[])).find_all{|t|t.to_i>0 && !VXRD_RETIRED_GUESSED_DECOR_V10637.include?(t.to_i)}
      # If a non-Hunt caller reaches this method, retain the old palette safely
      # but still filter the two known visual mismatches.
      if tiles.empty?
        tiles=[palette[:decor_a],palette[:decor_b]].find_all{|t|t.to_i>0 && !VXRD_RETIRED_GUESSED_DECOR_V10637.include?(t.to_i)}
      end
      candidates=vxrd_decor_candidate_cells_v10598(layout)
      seed=(layout.instance_variable_get(:@seed).to_i ^ 0x10637DEC) & 0x7fffffff
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
        next if tile<=0
        map.data[x,y,1]=tile
        placed << [x,y,tile]
      end
      info={:biome=>biome,:label=>(mat==nil ? prof[:label] : mat[:label]),
        :hunt_code=>code,:density=>density,:candidates=>candidates.size,
        :placed=>placed.size,:verified_rtp_material=>(mat!=nil),
        :retired_legacy_decor=>VXRD_RETIRED_GUESSED_DECOR_V10637.dup,
        :corridor_safe=>true,:center_cross_safe=>true,:water_safe=>true,
        :bridge=>false,:external_png=>false}
      @pmd_vxrd_last_decor_v10598=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    # v1.06.00 water banks now use the Hunt's explicit dry-bank material.
    def vxrd_apply_water_bank_v10600(layout,palette)
      return nil if $game_map==nil || layout==nil || palette==nil
      map=$game_map.instance_variable_get(:@map)
      return nil if map==nil || map.data==nil
      water=(layout.respond_to?(:water_cells_v10593) ? layout.water_cells_v10593 : []) || []
      bank_tile=(palette[:floor_alt]||vxrd_floor_family_alt_v10600(palette[:floor].to_i)).to_i
      seen={};placed=[]
      water.each do |p|
        x=p[0].to_i;y=p[1].to_i
        [[x-1,y],[x+1,y],[x,y-1],[x,y+1]].each do |q|
          bx=q[0];by=q[1]
          next if bx<0 || by<0 || bx>=layout.width.to_i || by>=layout.height.to_i
          next if seen[[bx,by]]
          seen[[bx,by]]=true
          next unless layout.floor?(bx,by)
          next if layout.respond_to?(:water?) && layout.water?(bx,by)
          next if vxrd_water_bank_reserved_v10600?(layout,bx,by)
          map.data[bx,by,0]=bank_tile
          map.data[bx,by,1]=0
          map.data[bx,by,2]=0
          placed << [bx,by]
        end
      end
      info={:enabled=>!water.empty?,:water_cells=>water.size,:bank_tile=>bank_tile,
        :bank_cells=>placed.size,:one_tile_rim=>true,:center_cross_safe=>true,
        :verified_rtp_material=>true,:external_png=>false,:bridge=>false,:river=>false}
      @pmd_vxrd_last_water_bank_v10600=info
      info
    rescue
      nil
    end

    # Make Foundation I's deterministic edge-detail pass consume the verified
    # per-Hunt material list rather than legacy palette guesses.
    def vxrd_content_decor_tile_v10636(profile,palette,hash)
      tiles=[]
      if profile!=nil && profile[:decor_tiles_v10637].is_a?(Array)
        tiles=profile[:decor_tiles_v10637]
      end
      tiles=tiles.find_all{|t|t.to_i>0 && !VXRD_RETIRED_GUESSED_DECOR_V10637.include?(t.to_i)}
      if tiles.empty?
        a=(palette||{})[:decor_a].to_i;b=(palette||{})[:decor_b].to_i
        tiles=[a,b].find_all{|t|t>0 && !VXRD_RETIRED_GUESSED_DECOR_V10637.include?(t)}
      end
      return 0 if tiles.empty?
      tiles[hash.to_i % tiles.size].to_i
    rescue
      0
    end

    def vxrd_rtp_material_audit_v10637
      bad=[];floors={};decor={};families={}
      order=defined?(PHASE_DIV_HUNT_ORDER_V10553) ? PHASE_DIV_HUNT_ORDER_V10553 : []
      order.each do |code|
        m=VXRD_HUNT_RTP_MATERIAL_V10637[code]
        if m==nil
          bad << code+':missing';next
        end
        f=m[:floor].to_i;fa=m[:floor_alt].to_i;ds=m[:decor]||[]
        bad << code+':floor' unless f>=1536 && f<=1663
        bad << code+':floor_alt' unless fa>=1536 && fa<=1663
        bad << code+':decor_empty' if ds.empty?
        bad << code+':legacy77' if ds.include?(77)
        bad << code+':legacy82' if ds.include?(82)
        bad << code+':decor_range' unless ds.all?{|t|t.to_i>=0 && t.to_i<=767}
        floors[f]=true;floors[fa]=true;families[m[:family]]=true
        ds.each{|t|decor[t.to_i]=true}
      end
      bad << 'profiles' unless VXRD_HUNT_RTP_MATERIAL_V10637.size==21
      bad << 'source_sheets' unless VXRD_RTP_TILE_SOURCE_V10637.size==8
      {:pass=>bad.empty?,:profiles=>VXRD_HUNT_RTP_MATERIAL_V10637.size,
        :source_sheets=>VXRD_RTP_TILE_SOURCE_V10637.size,:floor_tiles=>floors.size,
        :decor_tiles=>decor.size,:families=>families.size,:retired=>VXRD_RETIRED_GUESSED_DECOR_V10637.dup,
        :deterministic=>true,:topology_change=>false,:balance_change=>false,
        :external_png=>false,:bad=>bad}
    rescue
      {:pass=>false,:profiles=>0,:bad=>['audit_error']}
    end

    alias pmd_ac_v10637_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10637_write_project_state_log)
    def project_version
      '1.06.37'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10637_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=25')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.37')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_RTP_MATERIAL_AUTHORITY_I+HUNT_CONTENTIZATION')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=H01-H21_RTP_MATERIAL_VISUAL_QA')
        text=text.gsub(/\r?\nVXRD_RTP_MATERIAL_V10637_BEGIN.*?VXRD_RTP_MATERIAL_V10637_END\r?\n/m,"\r\n")
        a=vxrd_rtp_material_audit_v10637
        lines=[]
        lines << ''
        lines << 'VXRD_RTP_MATERIAL_V10637_BEGIN'
        lines << 'RTP_REFERENCE_SHEETS='+a[:source_sheets].to_i.to_s+'/8'
        lines << 'HUNT_RTP_MATERIAL_PROFILES='+a[:profiles].to_i.to_s+'/21'
        lines << 'HUNT_RTP_FLOOR_TILES='+a[:floor_tiles].to_i.to_s
        lines << 'HUNT_RTP_DECOR_TILES='+a[:decor_tiles].to_i.to_s
        lines << 'HUNT_RTP_MATERIAL_FAMILIES='+a[:families].to_i.to_s
        lines << 'LEGACY_DECOR_77_82=RETIRED'
        lines << 'RTP_MATERIAL_DETERMINISTIC=1'
        lines << 'RTP_MATERIAL_TOPOLOGY_CHANGE=0'
        lines << 'RTP_MATERIAL_BALANCE_CHANGE=0'
        lines << 'RTP_MATERIAL_EXTERNAL_PNG=0'
        lines << 'RTP_MATERIAL_AUDIT='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'RTP_MATERIAL_VISUAL_QA=PENDING_USER_REVIEW'
        lines << 'VXRD_RTP_MATERIAL_V10637_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end

  # Attach the verified decor set to the v1.06.36 content profiles without
  # mutating their motif/density identity contracts.
  if defined?(VXRD_HUNT_CONTENT_PROFILE_V10636)
    VXRD_HUNT_RTP_MATERIAL_V10637.each do |code,mat|
      p=VXRD_HUNT_CONTENT_PROFILE_V10636[code]
      next if p==nil
      p[:decor_tiles_v10637]=(mat[:decor]||[]).dup
      p[:rtp_floor_v10637]=mat[:floor].to_i
      p[:rtp_floor_alt_v10637]=mat[:floor_alt].to_i
      p[:rtp_material_label_v10637]=mat[:label]
    end
  end
end
