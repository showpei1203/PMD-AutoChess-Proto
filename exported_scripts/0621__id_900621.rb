# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Gate 2 Hunt Contentization Foundation I v1.06.36
#-------------------------------------------------------------------------------
# Gate 1 is user-accepted and structurally sealed.
# Gate 2 begins with deterministic VX-native regional identity for H01-H21.
#
# Scope:
# - 21/21 Hunt-specific ecology visual profiles.
# - Stronger region-specific floor accents and edge decoration using the
#   current RTP palette only.
# - Stronger Treasure / Rare Nest / Elite / Recovery room identity while
#   preserving the center route, water policy and event topology.
# - No external PNG, no parallax generator, no second Game_Map.
# - No AI / damage / battle pacing / encounter pool / reward change.
# - Room frequency remains unchanged here; risk/reward frequency tuning stays
#   for Gate 3 so visual contentization cannot silently rebalance progression.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHuntContentizationFoundationI_v10636']=true

module PMD_AC
  VXRD_HUNT_CONTENT_PROFILE_V10636={
    'H01'=>{:identity=>'林緣嫩葉',:motif=>:scatter,      :floor_density=>11,:decor_density=>16,:decor_bias=>:a},
    'H02'=>{:identity=>'苔溪濕岸',:motif=>:soft_bands,   :floor_density=>10,:decor_density=>12,:decor_bias=>:mix},
    'H03'=>{:identity=>'風鳴草痕',:motif=>:diagonal,     :floor_density=>12,:decor_density=>8, :decor_bias=>:a},
    'H04'=>{:identity=>'赤岩碎徑',:motif=>:edge_rubble,  :floor_density=>13,:decor_density=>18,:decor_bias=>:b},
    'H05'=>{:identity=>'月影殘紋',:motif=>:relic_ring,   :floor_density=>15,:decor_density=>11,:decor_bias=>:mix},

    'H06'=>{:identity=>'深蔭密叢',:motif=>:clusters,     :floor_density=>15,:decor_density=>24,:decor_bias=>:a},
    'H07'=>{:identity=>'霧澤泥痕',:motif=>:mottle,       :floor_density=>14,:decor_density=>16,:decor_bias=>:mix},
    'H08'=>{:identity=>'雷羽風道',:motif=>:diagonal,     :floor_density=>16,:decor_density=>12,:decor_bias=>:b},
    'H09'=>{:identity=>'回聲岩層',:motif=>:hard_bands,   :floor_density=>17,:decor_density=>22,:decor_bias=>:b},
    'H10'=>{:identity=>'夢霧碑痕',:motif=>:relic_corners,:floor_density=>18,:decor_density=>15,:decor_bias=>:mix},

    'H11'=>{:identity=>'古木根網',:motif=>:root_lines,   :floor_density=>18,:decor_density=>27,:decor_bias=>:a},
    'H12'=>{:identity=>'霜湖冰紋',:motif=>:soft_bands,   :floor_density=>18,:decor_density=>12,:decor_bias=>:mix},
    'H13'=>{:identity=>'暴風裂痕',:motif=>:wind_tracks,  :floor_density=>20,:decor_density=>14,:decor_bias=>:b},
    'H14'=>{:identity=>'鐵砂礦脈',:motif=>:veins,        :floor_density=>21,:decor_density=>25,:decor_bias=>:b},
    'H15'=>{:identity=>'幽光祭紋',:motif=>:relic_ring,   :floor_density=>22,:decor_density=>18,:decor_bias=>:mix},

    'H16'=>{:identity=>'原始樹海',:motif=>:root_lines,   :floor_density=>22,:decor_density=>30,:decor_bias=>:a},
    'H17'=>{:identity=>'深潮冰灣',:motif=>:ice_shards,   :floor_density=>21,:decor_density=>14,:decor_bias=>:mix},
    'H18'=>{:identity=>'龍風峽痕',:motif=>:wind_tracks,  :floor_density=>23,:decor_density=>17,:decor_bias=>:b},
    'H19'=>{:identity=>'熔鐵火脈',:motif=>:veins,        :floor_density=>24,:decor_density=>28,:decor_bias=>:b},
    'H20'=>{:identity=>'星痕古印',:motif=>:star_grid,    :floor_density=>25,:decor_density=>20,:decor_bias=>:mix},
    'H21'=>{:identity=>'裂隙聖印',:motif=>:sanctuary,    :floor_density=>27,:decor_density=>22,:decor_bias=>:mix}
  }

  VXRD_CONTENT_MOTIFS_V10636=[
    :scatter,:soft_bands,:diagonal,:edge_rubble,:relic_ring,
    :clusters,:mottle,:hard_bands,:relic_corners,:root_lines,
    :wind_tracks,:veins,:ice_shards,:star_grid,:sanctuary
  ]

  class << self
    def vxrd_hunt_content_profile_v10636(code=nil)
      c=(code==nil ? ((vxrd_state_v10582||{})[:code] rescue '') : code).to_s.upcase
      p=VXRD_HUNT_CONTENT_PROFILE_V10636[c]
      p==nil ? nil : p.dup.merge({:code=>c})
    rescue
      nil
    end

    def vxrd_content_hash_v10636(seed,room_id,x,y,salt=0)
      n=seed.to_i
      n ^= room_id.to_i*1103515245
      n ^= x.to_i*73856093
      n ^= y.to_i*19349663
      n ^= salt.to_i*83492791
      n & 0x7fffffff
    rescue
      0
    end

    def vxrd_content_water_v10636?(state,x,y)
      return vxrd_state_water_cell_v10607?(state,x,y) if respond_to?(:vxrd_state_water_cell_v10607?)
      false
    rescue
      false
    end

    def vxrd_content_key_point_v10636?(state,x,y)
      return false if state==nil
      [state[:entrance],state[:exit]].each do |p|
        next if p==nil || p.size<2
        return true if (p[0].to_i-x.to_i).abs+(p[1].to_i-y.to_i).abs<=1
      end
      false
    rescue
      true
    end

    def vxrd_content_center_route_v10636?(room,x,y)
      return true if room==nil
      x.to_i==room[:cx].to_i || y.to_i==room[:cy].to_i
    rescue
      true
    end

    def vxrd_content_alt_candidate_v10636?(profile,room,x,y,seed)
      return false if profile==nil || room==nil
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
      return false if x<x0 || x>x1 || y<y0 || y>y1
      rx=x-x0;ry=y-y0;w=[x1-x0+1,1].max;h=[y1-y0+1,1].max
      hv=vxrd_content_hash_v10636(seed,room[:id],x,y,17)
      d=[[rx,ry,w-1-rx,h-1-ry].min,0].max
      den=[[profile[:floor_density].to_i,2].max,55].min
      phase=(vxrd_content_hash_v10636(seed,room[:id],0,0,29)%5).to_i
      motif=profile[:motif]
      case motif
      when :scatter
        hv%100<den
      when :soft_bands
        ((ry+phase)%4==0 && hv%100<den+24) || hv%100<[den/4,3].max
      when :hard_bands
        ((rx+phase)%4==0 && hv%100<den+28) || ((ry+phase)%5==0 && hv%100<den/2)
      when :diagonal
        ((rx+ry+phase)%4==0 && hv%100<den+28)
      when :edge_rubble
        (d<=1 && hv%100<den+30) || hv%100<[den/5,3].max
      when :relic_ring
        ((d==1 || d==3) && hv%100<den+26) || ((rx+ry+phase)%7==0 && hv%100<den/2)
      when :clusters
        ((((rx/2)+(ry/2)+phase)%3)==0 && hv%100<den+18)
      when :mottle
        ((hv%11)<3 && hv%100<den+20)
      when :relic_corners
        corner=(rx<=1 && ry<=1)||(rx>=w-2 && ry<=1)||(rx<=1 && ry>=h-2)||(rx>=w-2 && ry>=h-2)
        (corner && hv%100<den+38) || hv%100<[den/5,4].max
      when :root_lines
        (((rx*2+ry+phase)%6)==0 && hv%100<den+28) || (d<=1 && hv%100<den/2)
      when :wind_tracks
        (((rx+ry*2+phase)%6)==0 && hv%100<den+34)
      when :veins
        (((rx*3+ry+phase)%7)==0 && hv%100<den+36) || ((rx+ry+phase)%11==0)
      when :ice_shards
        (((rx+ry+phase)%5)==0 && ((rx*2-ry).abs%4)<=1 && hv%100<den+28)
      when :star_grid
        (((rx+phase)%4==0 && (ry+phase)%4==0) || ((rx+ry+phase)%9==0 && hv%100<den+20))
      when :sanctuary
        ring=(d==1 || d==3)
        diag=((rx+ry+phase)%5==0 || (rx-ry+phase)%5==0)
        (ring && hv%100<den+34) || (diag && hv%100<den+16)
      else
        hv%100<den
      end
    rescue
      false
    end

    def vxrd_content_edge_candidate_v10636?(room,x,y)
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
      return false if x<x0 || x>x1 || y<y0 || y>y1
      x<=x0+1 || x>=x1-1 || y<=y0+1 || y>=y1-1
    rescue
      false
    end

    def vxrd_content_decor_tile_v10636(profile,palette,hash)
      a=(palette||{})[:decor_a].to_i;b=(palette||{})[:decor_b].to_i
      bias=profile==nil ? :mix : profile[:decor_bias]
      return a if b<=0
      return b if a<=0
      case bias
      when :a
        hash.to_i%100<76 ? a:b
      when :b
        hash.to_i%100<76 ? b:a
      else
        (hash.to_i % 2)==0 ? a:b
      end
    rescue
      0
    end

    def vxrd_apply_region_contentization_v10636(state)
      return nil if state==nil || $game_map==nil
      return state[:contentization_v10636] if state[:contentization_v10636].is_a?(Hash)
      code=state[:code].to_s.upcase;profile=VXRD_HUNT_CONTENT_PROFILE_V10636[code]
      return nil if profile==nil
      map=$game_map.instance_variable_get(:@map);return nil if map==nil || map.data==nil
      pal=state[:palette]||{};floor=pal[:floor].to_i
      alt=respond_to?(:vxrd_floor_family_alt_v10600) ? vxrd_floor_family_alt_v10600(floor) : floor
      seed=state[:seed].to_i;types=state[:room_types_v10601]||{}
      counts={:floor_accent=>0,:edge_decor=>0,:special_floor=>0,:special_decor=>0}
      (state[:rooms]||[]).each do |room|
        rid=room[:id].to_i;type=types[rid]||:normal
        x0=room[:x].to_i+1;y0=room[:y].to_i+1
        x1=room[:x].to_i+room[:w].to_i-2;y1=room[:y].to_i+room[:h].to_i-2
        next if x1<x0 || y1<y0
        for y in y0..y1
          for x in x0..x1
            next if vxrd_content_center_route_v10636?(room,x,y)
            next if vxrd_content_key_point_v10636?(state,x,y)
            next if vxrd_content_water_v10636?(state,x,y)
            if alt>0 && vxrd_content_alt_candidate_v10636?(profile,room,x,y,seed)
              map.data[x,y,0]=alt
              counts[:floor_accent]+=1
            end
            next unless [:normal,:entrance,:exit].include?(type)
            next unless vxrd_content_edge_candidate_v10636?(room,x,y)
            next unless map.data[x,y,1].to_i==0
            hv=vxrd_content_hash_v10636(seed,rid,x,y,43)
            next unless hv%100<profile[:decor_density].to_i
            tile=vxrd_content_decor_tile_v10636(profile,pal,hv)
            next if tile<=0
            map.data[x,y,1]=tile
            counts[:edge_decor]+=1
          end
        end
        # Stronger special-room silhouettes remain floor-first so they never
        # compromise the central cross used for traversal/event access.
        if [:treasure,:rare_nest,:elite,:recovery].include?(type) && alt>0
          for y in y0..y1
            for x in x0..x1
              next if vxrd_content_center_route_v10636?(room,x,y)
              next if vxrd_content_water_v10636?(state,x,y)
              rx=x-x0;ry=y-y0;w=x1-x0+1;h=y1-y0+1
              mark=false
              case type
              when :treasure
                mark=(rx==0 || ry==0 || rx==w-1 || ry==h-1)
              when :rare_nest
                mark=((rx+ry)%3==0 && (rx<=1 || ry<=1 || rx>=w-2 || ry>=h-2))
              when :elite
                mark=((rx==1 || rx==w-2) && (ry==1 || ry==h-2)) || ((rx+ry)%5==0 && (rx==0 || ry==0 || rx==w-1 || ry==h-1))
              when :recovery
                dx=(x-room[:cx].to_i).abs;dy=(y-room[:cy].to_i).abs
                mark=(dx+dy==2)
              end
              if mark
                map.data[x,y,0]=alt
                counts[:special_floor]+=1
              end
            end
          end
          # Rare/Elite/Treasure get a few edge landmarks, but only on empty
          # B/C cells and never on the central access cross.
          if type!=:recovery
            for y in y0..y1
              for x in x0..x1
                next unless vxrd_content_edge_candidate_v10636?(room,x,y)
                next if vxrd_content_center_route_v10636?(room,x,y)
                next if vxrd_content_water_v10636?(state,x,y)
                next unless map.data[x,y,1].to_i==0
                hv=vxrd_content_hash_v10636(seed,rid,x,y,71+type.to_s.size)
                rate=(type==:treasure ? 8 : (type==:rare_nest ? 14:12))
                next unless hv%100<rate
                tile=vxrd_content_decor_tile_v10636(profile,pal,hv)
                next if tile<=0
                map.data[x,y,1]=tile;counts[:special_decor]+=1
              end
            end
          end
        end
      end
      info={:code=>code,:identity=>profile[:identity],:motif=>profile[:motif],
        :floor_density=>profile[:floor_density].to_i,:decor_density=>profile[:decor_density].to_i,
        :palette=>(pal[:index]||0).to_i,:counts=>counts,:deterministic=>true,
        :center_cross_safe=>true,:water_safe=>true,:external_png=>false,
        :room_frequency_changed=>false,:gameplay_change=>false}
      state[:contentization_v10636]=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    alias pmd_ac_v10636_room_visual_apply_v10607 vxrd_room_visual_apply_v10607 unless method_defined?(:pmd_ac_v10636_room_visual_apply_v10607)
    def vxrd_room_visual_apply_v10607(state)
      r=pmd_ac_v10636_room_visual_apply_v10607(state)
      vxrd_apply_region_contentization_v10636(state) unless state==nil
      r
    rescue
      r
    end

    def vxrd_hunt_contentization_audit_v10636
      bad=[];ids={};motifs={};biomes={}
      order=defined?(PHASE_DIV_HUNT_ORDER_V10553) ? PHASE_DIV_HUNT_ORDER_V10553 : []
      order.each do |code|
        p=VXRD_HUNT_CONTENT_PROFILE_V10636[code]
        if p==nil
          bad << code+':missing';next
        end
        bad << code+':motif' unless VXRD_CONTENT_MOTIFS_V10636.include?(p[:motif])
        bad << code+':floor_density' unless p[:floor_density].to_i>=2 && p[:floor_density].to_i<=55
        bad << code+':decor_density' unless p[:decor_density].to_i>=0 && p[:decor_density].to_i<=40
        ids[p[:identity].to_s]=true;motifs[p[:motif]]=true
        h=phase_div_hunt_v10553(code) rescue nil
        biomes[h[:biome].to_s]=true unless h==nil
      end
      wet=VXRD_HUNT_STYLE_V10600.keys.find_all{|c|VXRD_HUNT_STYLE_V10600[c][:water]} rescue []
      bad << 'water_scope' unless wet.sort==['H02','H07','H12','H17']
      {:pass=>bad.empty?,:profiles=>VXRD_HUNT_CONTENT_PROFILE_V10636.size,
        :unique_identities=>ids.size,:motifs=>motifs.size,:biomes=>biomes.size,
        :water_scope=>wet.sort,:deterministic=>true,:external_png=>false,
        :room_frequency_changed=>false,:gameplay_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:profiles=>0,:bad=>['audit_error']}
    end

    alias pmd_ac_v10636_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10636_write_project_state_log)
    def project_version
      '1.06.36'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10636_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=24')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.36')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_GATE1_ACCEPTANCE_SEALED+HUNT_CONTENTIZATION_FOUNDATION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=H01-H21_CONTENTIZATION_VISUAL_QA')
        text=text.gsub(/\r?\nVXRD_CONTENTIZATION_V10636_BEGIN.*?VXRD_CONTENTIZATION_V10636_END\r?\n/m,"\r\n")
        a=vxrd_hunt_contentization_audit_v10636
        lines=[]
        lines << ''
        lines << 'VXRD_GATE1_SEAL_V10636_BEGIN'
        lines << 'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE=PASS_USER_CONFIRMED'
        lines << 'VXRD_RANDOM_HUNT_STRUCTURAL_RUNTIME=SEALED_ISSUE_DRIVEN_ONLY'
        lines << 'VXRD_GATE1_SEAL_V10636_END'
        lines << ''
        lines << 'VXRD_CONTENTIZATION_V10636_BEGIN'
        lines << 'HUNT_CONTENT_PROFILES='+a[:profiles].to_i.to_s+'/21'
        lines << 'HUNT_CONTENT_UNIQUE_IDENTITIES='+a[:unique_identities].to_i.to_s+'/21'
        lines << 'HUNT_CONTENT_MOTIFS='+a[:motifs].to_i.to_s
        lines << 'HUNT_CONTENT_BIOMES='+a[:biomes].to_i.to_s+'/6'
        lines << 'HUNT_CONTENT_DETERMINISTIC=1'
        lines << 'HUNT_CONTENT_EXTERNAL_PNG=0'
        lines << 'HUNT_CONTENT_ROOM_FREQUENCY_CHANGED=0'
        lines << 'HUNT_CONTENT_GAMEPLAY_CHANGE=0'
        lines << 'HUNT_CONTENT_AUDIT='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'HUNT_CONTENT_VISUAL_QA=PENDING_USER_REVIEW'
        lines << 'VXRD_CONTENTIZATION_V10636_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
