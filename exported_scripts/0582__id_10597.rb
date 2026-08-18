# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Floor/Water Palette Pair Authority v1.05.97
#-------------------------------------------------------------------------------
# Water is selected by the resolved VX floor/wall palette, not biome alone.
# One floor style always receives exactly one paired A1 water family per floor.
# No river / irregular pool / bridge is introduced.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDFloorWaterPalettePair_v10597']=true

module PMD_AC
  # The two conservative animated VX A1 water families already proven in the
  # Windows runtime. Pairing is per RTP palette index so a custom palette test
  # cannot accidentally inherit a visually unrelated biome default.
  VXRD_WATER_BY_PALETTE_V10597={
     0=>{:base=>2048,:style=>:clear_blue},  1=>{:base=>2048,:style=>:clear_blue},
     2=>{:base=>2048,:style=>:clear_blue},  3=>{:base=>2048,:style=>:clear_blue},
     4=>{:base=>2096,:style=>:deep_blue},   5=>{:base=>2096,:style=>:deep_blue},
     6=>{:base=>2096,:style=>:deep_blue},   7=>{:base=>2096,:style=>:deep_blue},
     8=>{:base=>2096,:style=>:deep_blue},   9=>{:base=>2096,:style=>:deep_blue},
    10=>{:base=>2096,:style=>:deep_blue},  11=>{:base=>2096,:style=>:deep_blue},
    12=>{:base=>2048,:style=>:clear_blue}, 13=>{:base=>2048,:style=>:clear_blue},
    14=>{:base=>2048,:style=>:clear_blue}, 15=>{:base=>2048,:style=>:clear_blue},
    16=>{:base=>2048,:style=>:clear_blue}, 17=>{:base=>2048,:style=>:clear_blue},
    18=>{:base=>2048,:style=>:clear_blue}, 19=>{:base=>2048,:style=>:clear_blue},
    20=>{:base=>2096,:style=>:deep_blue},  21=>{:base=>2096,:style=>:deep_blue},
    22=>{:base=>2096,:style=>:deep_blue},  23=>{:base=>2096,:style=>:deep_blue}
  }

  class VXRD_Layout_V10582
    def pmd_vxrd_palette_index_v10597
      return @options[:palette_index].to_i if @options.is_a?(Hash) && @options.has_key?(:palette_index)
      biome=pmd_vxrd_biome_v10593
      (PMD_AC::VXRD_BIOME_PALETTE_V10582[biome] || 0).to_i
    rescue
      0
    end

    def pmd_vxrd_water_pair_v10597
      idx=pmd_vxrd_palette_index_v10597
      PMD_AC::VXRD_WATER_BY_PALETTE_V10597[idx] || PMD_AC::VXRD_WATER_BY_PALETTE_V10597[0]
    rescue
      {:base=>2048,:style=>:clear_blue}
    end

    # Supersedes v1.05.93's biome-only base choice while retaining biome-specific
    # chance / rectangle count.
    def pmd_vxrd_water_profile_v10593
      biome=pmd_vxrd_biome_v10593
      src=PMD_AC::VXRD_WATER_PROFILE_V10593[biome] || PMD_AC::VXRD_WATER_PROFILE_V10593['forest']
      prof=src.dup
      pair=pmd_vxrd_water_pair_v10597
      prof[:base]=pair[:base].to_i
      prof[:pair_style]=pair[:style]
      prof[:palette_index]=pmd_vxrd_palette_index_v10597
      prof
    rescue
      {:base=>2048,:rects=>0,:chance=>0,:pair_style=>:clear_blue,:palette_index=>0}
    end
  end

  class << self
    def vxrd_water_profile_for_layout_v10593(layout)
      return layout.pmd_vxrd_water_profile_v10593 if layout!=nil && layout.respond_to?(:pmd_vxrd_water_profile_v10593)
      {:base=>2048,:rects=>0,:chance=>0,:pair_style=>:clear_blue,:palette_index=>0}
    rescue
      {:base=>2048,:rects=>0,:chance=>0,:pair_style=>:clear_blue,:palette_index=>0}
    end

    alias pmd_ac_v10597_vxrd_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10597_vxrd_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10597_vxrd_generate_current_map_v10582(code,seed,options)
      return st if st==nil
      idx=(st[:palette]||{})[:index].to_i
      pair=VXRD_WATER_BY_PALETTE_V10597[idx] || VXRD_WATER_BY_PALETTE_V10597[0]
      w=st[:water_v10593]||{}
      w[:base]=pair[:base].to_i
      w[:pair_style]=pair[:style]
      w[:palette_index]=idx
      w[:pair_source]=:palette
      st[:water_v10593]=w
      st[:water_pair_v10597]={:palette_index=>idx,:floor_base=>(st[:palette]||{})[:floor].to_i,
        :wall_base=>(st[:palette]||{})[:wall].to_i,:water_base=>pair[:base].to_i,
        :style=>pair[:style],:source=>:palette}
      st
    rescue
      nil
    end

    def vxrd_water_pair_info_v10597
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      st==nil ? nil : st[:water_pair_v10597]
    rescue
      nil
    end

    def vxrd_water_pair_audit_v10597
      h=VXRD_WATER_BY_PALETTE_V10597
      keys=(0...24).to_a
      valid=keys.all?{|i|h.has_key?(i) && [2048,2096].include?(h[i][:base].to_i)}
      {:pass=>valid && h.size==24,:pairs=>h.size,:palettes=>24,:one_water_per_palette=>true,
       :water_families=>h.values.collect{|v|v[:base].to_i}.uniq.size,:source=>:palette,
       :irregular=>false,:river=>false,:bridge=>false}
    rescue
      {:pass=>false,:pairs=>0,:palettes=>24}
    end
  end
end
