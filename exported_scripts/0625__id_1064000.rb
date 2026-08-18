# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt Style Correction I v1.06.40
#-------------------------------------------------------------------------------
# User visual QA found that early Hunt profiles still had semantic tile misuse:
# - H01/H02 floor accents could read as vine patches / mismatched ground.
# - H02 wall palette could resolve to wooden walls, conflicting with wetland.
# - Early-area contentization was too noisy for style review.
#
# This patch performs a conservative front-line correction for H01-H05:
# 1) rebind H01-H05 to safer floor/alt/decor sets;
# 2) hard-switch H02 wall palette away from the wooden water-family wall;
# 3) simplify early-area contentization to sparse, edge-only, single-biome decor;
# 4) keep v1.06.39 Hunt Style Preview QA active for visual review.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntStyleCorrectionI_v10640']=true

module PMD_AC
  VXRD_HUNT_STYLE_CORRECTION_I_V10640={
    'H01'=>{
      :label=>'林緣草地修正',:floor=>1558,:floor_alt=>1558,:palette=>0,
      :decor=>[160,161,162,163,176,177,178,179,180,181,182,195,196,197,198,199],
      :material_density=>6,:content_motif=>:scatter,:floor_density=>2,:decor_density=>6,:decor_bias=>:a,
      :family=>:forest
    },
    'H02'=>{
      :label=>'苔溪濕岸修正',:floor=>1558,:floor_alt=>1558,:palette=>0,
      :decor=>[160,161,162,163,176,177,180,181,195,196,197,198,199],
      :material_density=>5,:content_motif=>:mottle,:floor_density=>2,:decor_density=>5,:decor_bias=>:mix,
      :family=>:wetland
    },
    'H03'=>{
      :label=>'風鳴草原修正',:floor=>1558,:floor_alt=>1558,:palette=>4,
      :decor=>[160,161,176,177,178,179,180,195,196,244],
      :material_density=>4,:content_motif=>:scatter,:floor_density=>2,:decor_density=>4,:decor_bias=>:a,
      :family=>:grassland
    },
    'H04'=>{
      :label=>'赤岩荒徑修正',:floor=>1598,:floor_alt=>1598,:palette=>16,
      :decor=>[183,195,226,544,546,548,550,560,576,592,656],
      :material_density=>7,:content_motif=>:edge_rubble,:floor_density=>2,:decor_density=>7,:decor_bias=>:b,
      :family=>:red_rock
    },
    'H05'=>{
      :label=>'月影遺跡修正',:floor=>1621,:floor_alt=>1621,:palette=>20,
      :decor=>[545,547,565,567,577,581,583,593,597,599],
      :material_density=>5,:content_motif=>:relic_corners,:floor_density=>2,:decor_density=>5,:decor_bias=>:mix,
      :family=>:relic
    }
  }

  class << self
    def vxrd_style_correction_profile_v10640(code=nil)
      c=code.to_s.upcase
      if c.empty? && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        c=st[:code].to_s.upcase unless st==nil
      end
      p=VXRD_HUNT_STYLE_CORRECTION_I_V10640[c]
      p==nil ? nil : p.dup.merge({:code=>c})
    rescue
      nil
    end

    # Conservative correction for the front-line Hunts. H02 reuses the safer
    # stone/grass palette family so wetlands no longer get wooden walls.
    if defined?(VXRD_HUNT_STYLE_V10600)
      VXRD_HUNT_STYLE_CORRECTION_I_V10640.each do |code,cfg|
        next unless VXRD_HUNT_STYLE_V10600[code].is_a?(Hash)
        VXRD_HUNT_STYLE_V10600[code][:palette]=cfg[:palette].to_i
      end
    end

    if defined?(VXRD_HUNT_RTP_MATERIAL_V10638)
      VXRD_HUNT_STYLE_CORRECTION_I_V10640.each do |code,cfg|
        base=VXRD_HUNT_RTP_MATERIAL_V10638[code] || {}
        VXRD_HUNT_RTP_MATERIAL_V10638[code]=base.merge({
          :label=>cfg[:label],:floor=>cfg[:floor].to_i,:floor_alt=>cfg[:floor_alt].to_i,
          :decor=>(cfg[:decor]||[]).dup,:density=>cfg[:material_density].to_i,:family=>cfg[:family]
        })
      end
    end

    if defined?(VXRD_HUNT_RTP_MATERIAL_V10637)
      VXRD_HUNT_STYLE_CORRECTION_I_V10640.each do |code,cfg|
        base=VXRD_HUNT_RTP_MATERIAL_V10637[code] || {}
        VXRD_HUNT_RTP_MATERIAL_V10637[code]=base.merge({
          :label=>cfg[:label],:floor=>cfg[:floor].to_i,:floor_alt=>cfg[:floor_alt].to_i,
          :decor=>(cfg[:decor]||[]).dup,:density=>cfg[:material_density].to_i,:family=>cfg[:family]
        })
      end
    end

    if defined?(VXRD_HUNT_CONTENT_PROFILE_V10636)
      VXRD_HUNT_STYLE_CORRECTION_I_V10640.each do |code,cfg|
        next unless VXRD_HUNT_CONTENT_PROFILE_V10636[code].is_a?(Hash)
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:motif]=cfg[:content_motif]
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:floor_density]=cfg[:floor_density].to_i
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:decor_density]=cfg[:decor_density].to_i
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:decor_bias]=cfg[:decor_bias]
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:style_correction_v10640]=true
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:decor_tiles_v10637]=(cfg[:decor]||[]).dup
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:decor_tiles_v10638]=(cfg[:decor]||[]).dup
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:rtp_floor_v10637]=cfg[:floor].to_i
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:rtp_floor_alt_v10637]=cfg[:floor_alt].to_i
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:rtp_floor_v10638]=cfg[:floor].to_i
        VXRD_HUNT_CONTENT_PROFILE_V10636[code][:rtp_floor_alt_v10638]=cfg[:floor_alt].to_i
      end
    end

    # Early-area contentization is intentionally simplified: no broad room-wide
    # accent carpets, no mixed floor families, only sparse edge decor that uses
    # verified single-cell natural objects.
    alias pmd_ac_v10640_apply_region_contentization_v10636 vxrd_apply_region_contentization_v10636 unless method_defined?(:pmd_ac_v10640_apply_region_contentization_v10636)
    def vxrd_apply_region_contentization_v10636(state)
      return nil if state==nil
      code=state[:code].to_s.upcase
      cfg=vxrd_style_correction_profile_v10640(code)
      return pmd_ac_v10640_apply_region_contentization_v10636(state) if cfg==nil
      return state[:contentization_v10636] if state[:contentization_v10636].is_a?(Hash)
      return nil if $game_map==nil
      map=$game_map.instance_variable_get(:@map)
      return nil if map==nil || map.data==nil
      pal=state[:palette]||{}
      tiles=(cfg[:decor]||[]).find_all{|t| respond_to?(:vxrd_safe_single_decor_v10638?) ? vxrd_safe_single_decor_v10638?(t) : t.to_i>0 }
      alt=cfg[:floor_alt].to_i
      types=state[:room_types_v10601]||{}
      counts={:floor_accent=>0,:edge_decor=>0,:special_floor=>0,:special_decor=>0,:cleanup=>0}
      (state[:rooms]||[]).each do |room|
        rid=room[:id].to_i
        type=types[rid]||:normal
        x0=room[:x].to_i+1; y0=room[:y].to_i+1
        x1=room[:x].to_i+room[:w].to_i-2; y1=room[:y].to_i+room[:h].to_i-2
        next if x1<x0 || y1<y0
        # Remove any pre-existing layer-1 clutter inside corrected early hunts
        # unless it is an actual event tile (events are separate and untouched).
        for y in y0..y1
          for x in x0..x1
            next if vxrd_content_center_route_v10636?(room,x,y)
            next if vxrd_content_key_point_v10636?(state,x,y)
            next if vxrd_content_water_v10636?(state,x,y)
            if map.data[x,y,1].to_i>0
              map.data[x,y,1]=0
              counts[:cleanup]+=1
            end
          end
        end
        # Rare/Treasure/Elite/Recovery keep only simple floor signatures.
        if [:treasure,:rare_nest,:elite,:recovery].include?(type) && alt>0
          for y in y0..y1
            for x in x0..x1
              next if vxrd_content_center_route_v10636?(room,x,y)
              next if vxrd_content_key_point_v10636?(state,x,y)
              next if vxrd_content_water_v10636?(state,x,y)
              rx=x-x0; ry=y-y0; w=x1-x0+1; h=y1-y0+1
              mark=false
              case type
              when :treasure
                mark=(x==x0 || x==x1 || y==y0 || y==y1)
              when :rare_nest
                mark=((rx<=1 || ry<=1 || rx>=w-2 || ry>=h-2) && ((rx+ry)%3==0))
              when :elite
                mark=((rx==1 || rx==w-2 || ry==1 || ry==h-2) && ((rx+ry)%2==0))
              when :recovery
                dx=(x-room[:cx].to_i).abs; dy=(y-room[:cy].to_i).abs
                mark=(dx+dy<=1)
              end
              next unless mark
              map.data[x,y,0]=alt
              counts[:special_floor]+=1
            end
          end
          next
        end
        # Normal / entrance / exit rooms get sparse edge-only decor.
        next unless [:normal,:entrance,:exit].include?(type)
        for y in y0..y1
          for x in x0..x1
            next unless vxrd_content_edge_candidate_v10636?(room,x,y)
            next if vxrd_content_center_route_v10636?(room,x,y)
            next if vxrd_content_key_point_v10636?(state,x,y)
            next if vxrd_content_water_v10636?(state,x,y)
            next unless map.data[x,y,1].to_i==0
            hv=vxrd_content_hash_v10636(state[:seed].to_i,rid,x,y,140)
            next unless hv%100<cfg[:decor_density].to_i
            next if tiles.empty?
            tile=tiles[hv % tiles.size].to_i
            next if tile<=0
            map.data[x,y,1]=tile
            counts[:edge_decor]+=1
          end
        end
      end
      info={:code=>code,:identity=>cfg[:label],:motif=>:early_sparse_edges,
        :floor_density=>cfg[:floor_density].to_i,:decor_density=>cfg[:decor_density].to_i,
        :palette=>(pal[:index]||0).to_i,:counts=>counts,:deterministic=>true,
        :center_cross_safe=>true,:water_safe=>true,:external_png=>false,
        :room_frequency_changed=>false,:gameplay_change=>false,
        :style_correction_i=>true,:tile_semantics_cleaned=>true}
      state[:contentization_v10636]=info
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      info
    rescue
      nil
    end

    def hunt_style_correction_audit_v10640
      bad=[]
      %w[H01 H02 H03 H04 H05].each do |code|
        cfg=VXRD_HUNT_STYLE_CORRECTION_I_V10640[code]
        bad << code+':cfg' if cfg==nil
        mat=(defined?(VXRD_HUNT_RTP_MATERIAL_V10638) ? VXRD_HUNT_RTP_MATERIAL_V10638[code] : nil)
        bad << code+':mat' if mat==nil
        bad << code+':floor_alt_mismatch' if mat && mat[:floor].to_i!=mat[:floor_alt].to_i
        if mat
          (mat[:decor]||[]).each do |t|
            bad << code+':unsafe_'+t.to_s unless respond_to?(:vxrd_safe_single_decor_v10638?) ? vxrd_safe_single_decor_v10638?(t) : true
          end
        end
      end
      h02=(defined?(VXRD_HUNT_STYLE_V10600) ? VXRD_HUNT_STYLE_V10600['H02'] : nil)
      bad << 'H02:palette' unless h02 && h02[:palette].to_i==0
      {:pass=>bad.empty?,:hunts=>5,:preview_qa_kept=>defined?(HUNT_STYLE_PREVIEW_CODES_V10639) ? true:false,
       :h02_palette=>(h02==nil ? -1 : h02[:palette].to_i),:bad=>bad}
    rescue
      {:pass=>false,:hunts=>0,:bad=>['audit_error']}
    end

    alias pmd_ac_v10640_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10640_write_project_state_log)
    def project_version
      '1.06.40'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10640_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=HUNT_STYLE_CORRECTION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=H01-H05_VISUAL_RECHECK+H06-H21_PROGRESSIVE_CORRECTION')
        text=text.gsub(/HUNT_CONTENT_VISUAL_QA=[^\r\n]+/,'HUNT_CONTENT_VISUAL_QA=FRONTLINE_REPAIR_IN_PROGRESS')
        text=text.gsub(/RTP_MATERIAL_VISUAL_QA=[^\r\n]+/,'RTP_MATERIAL_VISUAL_QA=EARLY_HUNTS_RECHECK_REQUIRED')
        text=text.gsub(/HUNT_STYLE_PREVIEW_QA=[^\r\n]+/,'HUNT_STYLE_PREVIEW_QA=ACTIVE_FOR_REVIEW')
        text=text.gsub(/CURRENT_VERSION=1\.06\.39/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.38/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.37/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.36/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.35/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.34/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.33/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.32/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.31/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/CURRENT_VERSION=1\.06\.30/,'CURRENT_VERSION=1.06.40')
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=27')
        text=text.gsub(/\r?\nHUNT_STYLE_CORRECTION_V10640_BEGIN.*?HUNT_STYLE_CORRECTION_V10640_END\r?\n/m,"\r\n")
        a=hunt_style_correction_audit_v10640
        lines=[]
        lines << ''
        lines << 'HUNT_STYLE_CORRECTION_V10640_BEGIN'
        lines << 'HUNT_STYLE_CORRECTION_I='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'HUNT_STYLE_CORRECTION_HUNTS=H01,H02,H03,H04,H05'
        lines << 'HUNT_STYLE_CORRECTION_H02_PALETTE='+a[:h02_palette].to_i.to_s
        lines << 'HUNT_STYLE_CORRECTION_MIXED_FLOORS=DISABLED_EARLY_HUNTS'
        lines << 'HUNT_STYLE_CORRECTION_TILEB_RIGHT_HALF=FORBIDDEN'
        lines << 'HUNT_STYLE_CORRECTION_TILEC_AUTODECOR=DISABLED'
        lines << 'HUNT_STYLE_CORRECTION_PREVIEW_QA='+(a[:preview_qa_kept] ? 'ACTIVE':'INACTIVE')
        lines << 'HUNT_STYLE_CORRECTION_V10640_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
