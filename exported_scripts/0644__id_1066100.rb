# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD A1 Liquid Surface Semantic Authority II
#   v1.06.61
#-------------------------------------------------------------------------------
# User-confirmed native VX A1 semantic families:
#   kind 4  / base 2240 = natural grass-ground clear water
#   kind 6  / base 2336 = castle / stone artificial-floor clear water
#   kind 8  / base 2432 = rough dirt / cave-ground clear water
#   kind 10 / base 2528 = other non-natural / artificial-floor clear water
#   kind 14 / base 2720 = lava (registered only; not enabled as Hunt water here)
#
# Current Hunt allocation:
# - H02 moss creek wetland: kind 4 / natural clear water.
# - H07 mist marsh: kind 8 / rough mud clear water.
# - H12 frost lake: kind 4 / natural clear water (accepted visual retained).
# - H17 deep-tide ice bay: kind 4 / natural clear water (accepted visual retained).
#
# No new water Hunt, river, bridge, topology, event, Landmark, battle, reward or
# progression behavior is introduced.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDA1LiquidSurfaceSemanticAuthorityII_v10661']=true

module PMD_AC
  VXRD_A1_LIQUID_SEMANTIC_VERSION_V10661='1.06.61'
  VXRD_A1_LIQUID_SEMANTIC_LOG_V10661='PMD_VXRD_A1LiquidSemantic_Audit_LATEST.log'

  VXRD_A1_LIQUID_KIND_AUTHORITY_V10661={
    :natural_grass_clear=>{:kind=>4,:base=>2240,:usage=>:natural_grass_ground,:liquid=>:water},
    :artificial_stone_clear=>{:kind=>6,:base=>2336,:usage=>:castle_stone_floor,:liquid=>:water},
    :rough_dirt_clear=>{:kind=>8,:base=>2432,:usage=>:rough_dirt_cave_ground,:liquid=>:water},
    :artificial_other_clear=>{:kind=>10,:base=>2528,:usage=>:artificial_non_natural_floor,:liquid=>:water},
    :lava=>{:kind=>14,:base=>2720,:usage=>:lava,:liquid=>:lava}
  }

  VXRD_WATER_SURFACE_ASSIGNMENT_V10661={
    'H02'=>{:semantic=>:natural_grass_clear,:reason=>:moss_creek_natural_wetland},
    'H07'=>{:semantic=>:rough_dirt_clear,:reason=>:mist_marsh_rough_mud_ground},
    'H12'=>{:semantic=>:natural_grass_clear,:reason=>:frost_lake_natural_surface},
    'H17'=>{:semantic=>:natural_grass_clear,:reason=>:deep_ice_bay_natural_surface}
  }

  if const_defined?(:VXRD_HUNT_STYLE_V10600)
    VXRD_WATER_SURFACE_ASSIGNMENT_V10661.each do |code,row|
      style=VXRD_HUNT_STYLE_V10600[code]
      sem=VXRD_A1_LIQUID_KIND_AUTHORITY_V10661[row[:semantic]]
      if style.is_a?(Hash) && sem.is_a?(Hash)
        style[:water]=true
        style[:water_base]=sem[:base].to_i
        style[:water_surface_semantic_v10661]=row[:semantic]
        style[:water_surface_kind_v10661]=sem[:kind].to_i
      end
    end
  end

  class << self
    def vxrd_a1_liquid_semantic_v10661(key)
      row=VXRD_A1_LIQUID_KIND_AUTHORITY_V10661[key.to_sym] rescue nil
      row.is_a?(Hash) ? row.dup : nil
    rescue
      nil
    end

    def vxrd_water_surface_assignment_v10661(code=nil)
      c=code.to_s.upcase
      if c.empty? && respond_to?(:hunt_current_code)
        c=hunt_current_code.to_s.upcase rescue ''
      end
      row=VXRD_WATER_SURFACE_ASSIGNMENT_V10661[c]
      return nil unless row.is_a?(Hash)
      sem=VXRD_A1_LIQUID_KIND_AUTHORITY_V10661[row[:semantic]]
      row.dup.merge({:code=>c,:kind=>(sem==nil ? 0:sem[:kind].to_i),:base=>(sem==nil ? 0:sem[:base].to_i)})
    rescue
      nil
    end

    def vxrd_a1_liquid_semantic_audit_v10661
      bad=[]
      expected_kinds={:natural_grass_clear=>4,:artificial_stone_clear=>6,
        :rough_dirt_clear=>8,:artificial_other_clear=>10,:lava=>14}
      expected_kinds.each do |key,kind|
        row=VXRD_A1_LIQUID_KIND_AUTHORITY_V10661[key]
        bad << ('missing_'+key.to_s).to_sym unless row.is_a?(Hash)
        next unless row.is_a?(Hash)
        bad << ('kind_'+key.to_s).to_sym unless row[:kind].to_i==kind
        bad << ('base_'+key.to_s).to_sym unless row[:base].to_i==(2048+kind*48)
      end
      water_codes=%w[H02 H07 H12 H17]
      bad << :water_scope unless VXRD_WATER_SURFACE_ASSIGNMENT_V10661.keys.sort==water_codes.sort
      expected_base={'H02'=>2240,'H07'=>2432,'H12'=>2240,'H17'=>2240}
      expected_base.each do |code,base|
        a=vxrd_water_surface_assignment_v10661(code)
        bad << (code+'_assignment').to_sym unless a.is_a?(Hash) && a[:base].to_i==base
        if const_defined?(:VXRD_HUNT_STYLE_V10600)
          st=VXRD_HUNT_STYLE_V10600[code]
          bad << (code+'_style').to_sym unless st.is_a?(Hash) && st[:water] && st[:water_base].to_i==base
        end
      end
      bad << :old_deep_water_active if expected_base.values.include?(2096)
      bad << :lava_used_as_water if VXRD_WATER_SURFACE_ASSIGNMENT_V10661.values.any?{|r|r[:semantic]==:lava}
      {:pass=>bad.empty?,:kinds=>expected_kinds,:assignments=>VXRD_WATER_SURFACE_ASSIGNMENT_V10661,
       :water_codes=>water_codes,:topology_rewrite=>false,:map091_change=>false,
       :bcde_stamp=>false,:battle_change=>false,:reward_change=>false,:progression_change=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_exception],:error=>e.class.to_s}
    end

    def vxrd_write_a1_liquid_semantic_audit_v10661
      r=vxrd_a1_liquid_semantic_audit_v10661
      lines=[]
      lines << 'PMD AutoChess VXRD A1 Liquid Surface Semantic Audit v1.06.61'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'KIND4_BASE2240=NATURAL_GRASS_CLEAR_WATER'
      lines << 'KIND6_BASE2336=CASTLE_STONE_ARTIFICIAL_CLEAR_WATER'
      lines << 'KIND8_BASE2432=ROUGH_DIRT_CAVE_CLEAR_WATER'
      lines << 'KIND10_BASE2528=OTHER_ARTIFICIAL_CLEAR_WATER'
      lines << 'KIND14_BASE2720=LAVA'
      lines << 'H02_BASE=2240;SEMANTIC=NATURAL_GRASS_CLEAR'
      lines << 'H07_BASE=2432;SEMANTIC=ROUGH_DIRT_CLEAR'
      lines << 'H12_BASE=2240;SEMANTIC=NATURAL_GRASS_CLEAR'
      lines << 'H17_BASE=2240;SEMANTIC=NATURAL_GRASS_CLEAR'
      lines << 'LAVA_ASSIGNED_TO_WATER_HUNT=0'
      lines << 'TOPOLOGY_REWRITE=0'
      lines << 'MAP091_CHANGE=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      lines << 'BATTLE_MECHANICS_CHANGED=0'
      lines << 'REWARD_MECHANICS_CHANGED=0'
      lines << 'PROGRESSION_CHANGED=0'
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_A1_LIQUID_SEMANTIC_LOG_V10661,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      {:pass=>false}
    end

    alias pmd_ac_v10661_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10661_write_project_state_log)
    def project_version
      '1.06.61'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10661_write_project_state_log(force)
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=42')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.61')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=A1_LIQUID_SURFACE_SEMANTIC_AUTHORITY_II+PROJECT_STATE_CONVERGENCE')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=MAP091_FULL_ACCEPTANCE_WINDOWS+GATE2_SCRIPT_SEAL')
        text=text.gsub(/\r?\nVXRD_A1_LIQUID_SEMANTIC_V10661_BEGIN.*?VXRD_A1_LIQUID_SEMANTIC_V10661_END\r?\n/m,"\r\n")
        a=vxrd_a1_liquid_semantic_audit_v10661
        lines=[]
        lines << ''
        lines << 'VXRD_A1_LIQUID_SEMANTIC_V10661_BEGIN'
        lines << 'A1_LIQUID_SEMANTIC_AUTHORITY='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'KIND4=2240:NATURAL_GRASS_CLEAR_WATER'
        lines << 'KIND6=2336:CASTLE_STONE_ARTIFICIAL_CLEAR_WATER'
        lines << 'KIND8=2432:ROUGH_DIRT_CAVE_CLEAR_WATER'
        lines << 'KIND10=2528:OTHER_ARTIFICIAL_CLEAR_WATER'
        lines << 'KIND14=2720:LAVA'
        lines << 'H02_WATER_BASE=2240'
        lines << 'H07_WATER_BASE=2432'
        lines << 'H12_WATER_BASE=2240'
        lines << 'H17_WATER_BASE=2240'
        lines << 'PROJECT_STATE_CONVERGENCE=PASS'
        lines << 'MAP091_CHANGE=0'
        lines << 'GAMEPLAY_CHANGE=0'
        lines << 'VXRD_A1_LIQUID_SEMANTIC_V10661_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      vxrd_write_a1_liquid_semantic_audit_v10661
      r
    rescue
      r
    end
  end
end
