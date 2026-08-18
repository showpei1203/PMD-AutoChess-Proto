# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Gravel-Bottom Clear Water Palette Probe I
#   v1.06.59 TEST-ONLY DIAGNOSTIC
#-------------------------------------------------------------------------------
# Purpose:
# - Identify the exact native VX A1 clear-water autotile requested by the user.
# - User visual locator: the gravel/pebble clear-bottom water is two editor
#   palette cells to the right of the currently accepted H07/H12/H17 water.
# - Candidate runtime base under test: 2336.
#
# Safety:
# - This is NOT production Water Authority and MUST NOT be promoted directly.
# - Only RMVX Test Play ($TEST) changes H07 water_base to 2336.
# - H02/H12/H17 remain exactly v1.06.58.
# - Non-Test Play keeps the accepted v1.06.58 mapping unchanged.
# - No topology, route, event, Loading, Landmark, battle or progression change.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDGravelBottomClearWaterPaletteProbeI_v10659']=true

module PMD_AC
  VXRD_GRAVEL_WATER_PROBE_VERSION_V10659='1.06.59-PROBE'
  VXRD_GRAVEL_WATER_PROBE_LOG_V10659='PMD_VXRD_GravelWaterProbe_LATEST.log'
  VXRD_GRAVEL_WATER_PROBE_BASE_V10659=2336
  VXRD_GRAVEL_WATER_PROBE_HUNT_V10659='H07'

  if $TEST && const_defined?(:VXRD_HUNT_STYLE_V10600)
    row=VXRD_HUNT_STYLE_V10600[VXRD_GRAVEL_WATER_PROBE_HUNT_V10659]
    if row.is_a?(Hash)
      row[:water]=true
      row[:water_base]=VXRD_GRAVEL_WATER_PROBE_BASE_V10659
      row[:water_bottom_style_v10659_probe]=:candidate_gravel_bottom_clear
    end
  end

  class << self
    def vxrd_gravel_water_probe_audit_v10659
      row=(const_defined?(:VXRD_HUNT_STYLE_V10600) ? VXRD_HUNT_STYLE_V10600['H07'] : nil)
      h02=(const_defined?(:VXRD_HUNT_STYLE_V10600) ? VXRD_HUNT_STYLE_V10600['H02'] : nil)
      h12=(const_defined?(:VXRD_HUNT_STYLE_V10600) ? VXRD_HUNT_STYLE_V10600['H12'] : nil)
      h17=(const_defined?(:VXRD_HUNT_STYLE_V10600) ? VXRD_HUNT_STYLE_V10600['H17'] : nil)
      expected_h07=($TEST ? 2336 : 2240)
      bad=[]
      bad << 'H07_missing' unless row.is_a?(Hash)
      bad << 'H07_base' if !row.is_a?(Hash) || row[:water_base].to_i!=expected_h07
      bad << 'H02_changed' if h02.is_a?(Hash) && h02[:water_base].to_i!=2048
      bad << 'H12_changed' if h12.is_a?(Hash) && h12[:water_base].to_i!=2240
      bad << 'H17_changed' if h17.is_a?(Hash) && h17[:water_base].to_i!=2240
      {:pass=>bad.empty?,:test_mode=>($TEST ? true:false),:hunt=>'H07',
       :candidate_base=>2336,:accepted_base=>2240,
       :runtime_h07=>(row.is_a?(Hash) ? row[:water_base].to_i : 0),
       :h02=>(h02.is_a?(Hash) ? h02[:water_base].to_i : 0),
       :h12=>(h12.is_a?(Hash) ? h12[:water_base].to_i : 0),
       :h17=>(h17.is_a?(Hash) ? h17[:water_base].to_i : 0),
       :production_authority_changed=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    def vxrd_write_gravel_water_probe_audit_v10659
      r=vxrd_gravel_water_probe_audit_v10659
      lines=[]
      lines << 'PMD AutoChess VXRD Gravel Water Palette Probe v1.06.59'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'TEST_MODE='+(r[:test_mode] ? '1':'0')
      lines << 'PROBE_HUNT=H07'
      lines << 'ACCEPTED_H07_BASE=2240'
      lines << 'CANDIDATE_H07_BASE=2336'
      lines << 'RUNTIME_H07_BASE='+r[:runtime_h07].to_i.to_s
      lines << 'H02_BASE='+r[:h02].to_i.to_s
      lines << 'H12_BASE='+r[:h12].to_i.to_s
      lines << 'H17_BASE='+r[:h17].to_i.to_s
      lines << 'PRODUCTION_AUTHORITY_CHANGED=0'
      lines << 'USER_DECISION_REQUIRED=GRAVEL_BOTTOM_MATCH_YES_OR_NO'
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_GRAVEL_WATER_PROBE_LOG_V10659,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      {:pass=>false}
    end

    alias pmd_ac_v10659_probe_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10659_probe_write_project_state_log)
    def project_version
      $TEST ? VXRD_GRAVEL_WATER_PROBE_VERSION_V10659 : '1.06.58'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10659_probe_write_project_state_log(force)
      vxrd_write_gravel_water_probe_audit_v10659
      r
    rescue
      r
    end
  end
end
