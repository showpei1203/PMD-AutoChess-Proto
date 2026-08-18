# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Hunt Visual Style / Water Bank Authority v1.06.00
#-------------------------------------------------------------------------------
# 【用途】
# 1. 將 21 張 Hunt 綁定到穩定的 VX RTP palette 變體，而非只按 biome 共用一張。
# 2. 水域預設只在 water biome 生成，避免森林／山地／秘境硬塞視覺不相容的水。
# 3. 規則矩形水池外圍使用同一 A5 floor family 的 alternate tile 作為乾岸過渡。
# 4. 維持 one water type / rectangle only / no river / no bridge。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHuntVisualStyleWaterBank_v10600']=true

module PMD_AC
  VXRD_HUNT_STYLE_V10600={
    'H01'=>{:palette=>0, :water=>false}, 'H06'=>{:palette=>1, :water=>false},
    'H11'=>{:palette=>2, :water=>false}, 'H16'=>{:palette=>3, :water=>false},
    'H02'=>{:palette=>8, :water=>true, :water_base=>2048, :water_rects=>1},
    'H07'=>{:palette=>9, :water=>true, :water_base=>2048, :water_rects=>1},
    'H12'=>{:palette=>10,:water=>true, :water_base=>2048, :water_rects=>2},
    'H17'=>{:palette=>11,:water=>true, :water_base=>2048, :water_rects=>2},
    'H03'=>{:palette=>4, :water=>false}, 'H08'=>{:palette=>5, :water=>false},
    'H13'=>{:palette=>6, :water=>false}, 'H18'=>{:palette=>7, :water=>false},
    'H04'=>{:palette=>16,:water=>false}, 'H09'=>{:palette=>17,:water=>false},
    'H14'=>{:palette=>18,:water=>false}, 'H19'=>{:palette=>19,:water=>false},
    'H05'=>{:palette=>20,:water=>false}, 'H10'=>{:palette=>21,:water=>false},
    'H15'=>{:palette=>22,:water=>false}, 'H20'=>{:palette=>23,:water=>false},
    'H21'=>{:palette=>23,:water=>false}
  }

  class VXRD_Layout_V10582
    alias pmd_ac_v10600_water_profile_v10593 pmd_vxrd_water_profile_v10593 unless method_defined?(:pmd_ac_v10600_water_profile_v10593)
    def pmd_vxrd_water_profile_v10593
      code=(@options[:hunt_code_v10600]||'').to_s.upcase rescue ''
      style=PMD_AC::VXRD_HUNT_STYLE_V10600[code]
      explicit=@options.has_key?(:water_enabled_v10600) rescue false
      if style!=nil || explicit
        enabled=explicit ? (@options[:water_enabled_v10600] ? true:false) : (style[:water] ? true:false)
        base=(style==nil ? 2048 : (style[:water_base]||2048)).to_i
        rects=(style==nil ? 1 : (style[:water_rects]||1)).to_i
        return {:base=>base,:rects=>(enabled ? rects:0),:chance=>(enabled ? 100:0),
          :pair_style=>:banked_clear_water,:palette_index=>PMD_AC.vxrd_palette_index_v10582(code,@options),
          :enabled=>enabled,:source=>:hunt_style_v10600}
      end
      pmd_ac_v10600_water_profile_v10593
    rescue
      {:base=>2048,:rects=>0,:chance=>0,:enabled=>false,:source=>:hunt_style_v10600}
    end
  end

  class << self
    alias pmd_ac_v10600_vxrd_options_v10582 vxrd_options_v10582 unless method_defined?(:pmd_ac_v10600_vxrd_options_v10582)
    def vxrd_options_v10582(code,options=nil)
      o=pmd_ac_v10600_vxrd_options_v10582(code,options)
      o[:hunt_code_v10600]=code.to_s.upcase
      o
    rescue
      options.is_a?(Hash) ? options.dup : {}
    end

    alias pmd_ac_v10600_palette_index_v10582 vxrd_palette_index_v10582 unless method_defined?(:pmd_ac_v10600_palette_index_v10582)
    def vxrd_palette_index_v10582(code=nil,options=nil)
      o=options.is_a?(Hash) ? options : {}
      return pmd_ac_v10600_palette_index_v10582(code,options) if o.has_key?(:palette_index)
      c=code.to_s.upcase
      style=VXRD_HUNT_STYLE_V10600[c]
      return style[:palette].to_i if style!=nil
      pmd_ac_v10600_palette_index_v10582(code,options)
    rescue
      0
    end

    def vxrd_floor_family_alt_v10600(floor_id)
      f=floor_id.to_i
      return f unless f>=1552 && f<=1591
      f + 64 - ((f-1552)/16)*8
    rescue
      floor_id.to_i
    end

    def vxrd_water_bank_reserved_v10600?(layout,x,y)
      return true if layout==nil
      ent=layout.entrance;ext=layout.exit_pos
      return true if ent!=nil && (ent[0].to_i-x.to_i).abs<=1 && (ent[1].to_i-y.to_i).abs<=1
      return true if ext!=nil && (ext[0].to_i-x.to_i).abs<=1 && (ext[1].to_i-y.to_i).abs<=1
      (layout.rooms||[]).each do |r|
        next unless x.to_i>=r[:x].to_i && x.to_i<r[:x].to_i+r[:w].to_i && y.to_i>=r[:y].to_i && y.to_i<r[:y].to_i+r[:h].to_i
        return true if x.to_i==r[:cx].to_i || y.to_i==r[:cy].to_i
      end
      opts=layout.instance_variable_get(:@options) rescue {}
      (opts[:fixed_positions]||[]).each do |p|
        next unless p.is_a?(Array) && p.size>=2
        return true if (p[0].to_i-x.to_i).abs<=1 && (p[1].to_i-y.to_i).abs<=1
      end
      false
    rescue
      true
    end

    def vxrd_apply_water_bank_v10600(layout,palette)
      return nil if $game_map==nil || layout==nil || palette==nil
      map=$game_map.instance_variable_get(:@map)
      return nil if map==nil || map.data==nil
      water=(layout.respond_to?(:water_cells_v10593) ? layout.water_cells_v10593 : []) || []
      bank_tile=vxrd_floor_family_alt_v10600(palette[:floor].to_i)
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
        :external_png=>false,:bridge=>false,:river=>false}
      @pmd_vxrd_last_water_bank_v10600=info
      info
    rescue
      nil
    end

    alias pmd_ac_v10600_apply_height_topology_v10589 vxrd_apply_height_topology_v10589 unless method_defined?(:pmd_ac_v10600_apply_height_topology_v10589)
    def vxrd_apply_height_topology_v10589(layout,palette)
      ok=pmd_ac_v10600_apply_height_topology_v10589(layout,palette)
      return false unless ok
      vxrd_apply_water_bank_v10600(layout,palette)
      true
    rescue
      false
    end

    alias pmd_ac_v10600_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10600_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10600_generate_current_map_v10582(code,seed,options)
      return st if st==nil
      c=st[:code].to_s.upcase
      style=VXRD_HUNT_STYLE_V10600[c] || {}
      bank=@pmd_vxrd_last_water_bank_v10600
      actual_base=(style[:water] ? (style[:water_base]||2048).to_i : 0)
      if st[:water_v10593].is_a?(Hash)
        st[:water_v10593][:base]=actual_base if style[:water]
        st[:water_v10593][:pair_style]=(style[:water] ? :banked_clear_water : :disabled)
        st[:water_v10593][:pair_source]=:hunt_style_v10600
      end
      st[:water_pair_v10597]={:palette_index=>(st[:palette]||{})[:index].to_i,
        :floor_base=>(st[:palette]||{})[:floor].to_i,:wall_base=>(st[:palette]||{})[:wall].to_i,
        :water_base=>actual_base,:style=>(style[:water] ? :banked_clear_water : :disabled),
        :source=>:hunt_style_v10600}
      st[:visual_style_v10600]={:code=>c,:palette=>(st[:palette]||{})[:index].to_i,
        :water_expected=>(style[:water] ? true:false),:water_base=>actual_base,
        :bank=>(bank==nil ? nil:bank.dup),:policy=>:water_biome_only_banked}
      st
    rescue
      nil
    end

    def vxrd_visual_style_info_v10600(code=nil)
      if code!=nil
        c=code.to_s.upcase;s=VXRD_HUNT_STYLE_V10600[c]
        return nil if s==nil
        return s.dup.merge({:code=>c})
      end
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      st==nil ? nil : st[:visual_style_v10600]
    rescue
      nil
    end

    def vxrd_visual_style_audit_v10600
      bad=[]
      PHASE_DIV_HUNT_ORDER_V10553.each do |c|
        s=VXRD_HUNT_STYLE_V10600[c]
        bad << c+':missing' if s==nil
        bad << c+':palette' if s!=nil && (s[:palette].to_i<0 || s[:palette].to_i>=24)
      end
      wet=VXRD_HUNT_STYLE_V10600.keys.find_all{|c|VXRD_HUNT_STYLE_V10600[c][:water]}
      expected=['H02','H07','H12','H17']
      bad << 'water_scope' unless wet.sort==expected.sort
      {:pass=>bad.empty?,:hunts=>VXRD_HUNT_STYLE_V10600.size,:water_hunts=>wet.size,
        :water_codes=>wet.sort,:one_water_type_per_style=>true,:banked=>true,
        :river=>false,:bridge=>false,:irregular=>false,:bad=>bad}
    rescue
      {:pass=>false,:hunts=>0,:water_hunts=>0,:bad=>['audit_error']}
    end
  end
end
