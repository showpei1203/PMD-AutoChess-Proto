# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Landmark Vegetation / Wetland Coverage Expansion I
#   v1.06.57
#-------------------------------------------------------------------------------
# Formal follow-up after:
# - v1.06.56 Random Hunt Real Loading Overlay I Windows/RMVX PASS.
# - SHO-22 broad route stress PASS (840 production-like + 11 adversarial cases).
#
# Purpose:
# - Expand accepted 32x32 PNG Landmark coverage only to Hunts whose ecology is
#   semantically compatible with the already accepted forest vegetation atlases.
# - H02 mossy wet bank, H03 wind grass, H06 deep thicket, H07 mist swamp,
#   H16 primordial forest.
# - Reuse v1.06.54 single-prop renderer and soft/passable semantics.
# - Reuse sealed v1.06.55 route safety. No topology rewrite.
#
# Deferred until dedicated art exists:
# H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.
# Do not fake those biomes by scattering unrelated rocks/crystals.
#
# Invariants:
# - No automatic B/C/D/E map-table stamping.
# - v1.06.44 runtime upper-tile Landmark IDs remain revoked.
# - Map090 / Map091 authority unchanged.
# - No battle / reward / progression change.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDLandmarkVegetationWetlandExpansionI_v10657']=true

module PMD_AC
  VXRD_LANDMARK_COVERAGE_VERSION_V10657='1.06.57'
  VXRD_LANDMARK_COVERAGE_LOG_V10657='PMD_VXRD_LandmarkCoverage_Audit_LATEST.log'
  VXRD_LANDMARK_EXPANSION_PROFILES_V10657={
    'H02'=>{:templates=>[:forest_green_a],:min=>1,:max=>2,
      :extra_chance=>35,:spacing=>4,:blocking=>false,:identity=>'苔溪濕岸'},
    'H03'=>{:templates=>[:forest_green_a,:forest_flower_a],:min=>2,:max=>3,
      :extra_chance=>40,:spacing=>4,:blocking=>false,:identity=>'風鳴草痕'},
    'H06'=>{:templates=>[:forest_green_a,:forest_flower_a],:min=>2,:max=>3,
      :extra_chance=>50,:spacing=>3,:blocking=>false,:identity=>'深蔭密叢'},
    'H07'=>{:templates=>[:forest_green_a],:min=>1,:max=>2,
      :extra_chance=>30,:spacing=>4,:blocking=>false,:identity=>'霧澤泥痕'},
    'H16'=>{:templates=>[:forest_green_a],:min=>2,:max=>3,
      :extra_chance=>45,:spacing=>3,:blocking=>false,:identity=>'原始樹海'}
  }
  VXRD_LANDMARK_DEFERRED_ART_HUNTS_V10657=%w[H05 H08 H10 H11 H12 H13 H15 H17 H18 H20 H21]

  if const_defined?(:VXRD_LANDMARK_HUNT_PROFILE_V10654)
    VXRD_LANDMARK_EXPANSION_PROFILES_V10657.each do |code,prof|
      p=prof.dup
      p.delete(:identity)
      VXRD_LANDMARK_HUNT_PROFILE_V10654[code]=p
    end
  end

  class << self
    def vxrd_landmark_coverage_audit_v10657
      bad=[]
      base=defined?(VXRD_LANDMARK_HUNT_PROFILE_V10654) ? VXRD_LANDMARK_HUNT_PROFILE_V10654 : {}
      sem=defined?(VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654) ? VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654 : {}
      VXRD_LANDMARK_EXPANSION_PROFILES_V10657.each do |code,p|
        row=base[code]
        bad << (code+':missing_profile') unless row.is_a?(Hash)
        bad << (code+':blocking') if row.is_a?(Hash) && row[:blocking]
        bad << (code+':min') if !row.is_a?(Hash) || row[:min].to_i<1
        bad << (code+':max') if !row.is_a?(Hash) || row[:max].to_i<row[:min].to_i
        bad << (code+':spacing') if !row.is_a?(Hash) || row[:spacing].to_i<3
        (p[:templates]||[]).each do |key|
          t=sem[key]
          bad << (code+':template:'+key.to_s) unless t.is_a?(Hash)
          bad << (code+':hard_template:'+key.to_s) if t.is_a?(Hash) && t[:blocking]
          bad << (code+':non_forest_template:'+key.to_s) unless [:forest_green_a,:forest_flower_a].include?(key)
        end
      end
      %w[H01 H04 H09 H14 H19].each do |code|
        bad << ('baseline:'+code) unless base[code].is_a?(Hash)
      end
      enabled=%w[H01 H02 H03 H04 H06 H07 H09 H14 H16 H19]
      enabled.each{|code|bad << ('enabled:'+code) unless base[code].is_a?(Hash)}
      {:pass=>bad.empty?,:expanded=>VXRD_LANDMARK_EXPANSION_PROFILES_V10657.keys.sort,
       :enabled=>enabled,:enabled_count=>enabled.size,
       :deferred=>VXRD_LANDMARK_DEFERRED_ART_HUNTS_V10657,
       :all_new_soft=>true,:renderer=>:png_atlas_cell_32,
       :route_safety=>:sealed_v10655,:topology_rewrite=>false,
       :map_table_bcde_stamp=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:expanded=>[],:enabled=>[],:bad=>[:audit_error],:error=>e.class.to_s}
    end

    def vxrd_write_landmark_coverage_audit_v10657
      r=vxrd_landmark_coverage_audit_v10657
      lines=[]
      lines << 'PMD AutoChess VXRD Landmark Coverage Audit v1.06.57'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'EXPANDED='+(r[:expanded]||[]).join(',')
      lines << 'ENABLED='+(r[:enabled]||[]).join(',')
      lines << 'ENABLED_COUNT='+(r[:enabled_count]||0).to_i.to_s
      lines << 'DEFERRED_ART='+(r[:deferred]||[]).join(',')
      lines << 'NEW_PROFILES_SOFT=1'
      lines << 'CELL_SIZE=32'
      lines << 'ROUTE_SAFETY=SEALED_V10655'
      lines << 'TOPOLOGY_REWRITE=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_LANDMARK_COVERAGE_LOG_V10657,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      {:pass=>false}
    end

    alias pmd_ac_v10657_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10657_write_project_state_log)
    def project_version
      '1.06.57'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10657_write_project_state_log(force)
      vxrd_write_landmark_coverage_audit_v10657
      r
    rescue
      r
    end
  end
end
