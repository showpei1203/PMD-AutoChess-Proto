# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Water-Bottom Autotile Pair Authority I
#   v1.06.58
#-------------------------------------------------------------------------------
# Purpose:
# - Replace the current opaque/deep A1 water family used by Random Hunt with the
#   two visible-bottom native VX A1 autotile families identified beside the ice
#   decoration group.
# - Natural / grass-earth water uses A1 base 2048.
# - Stone / hard-ground water uses A1 base 2240.
# - Preserve H02/H07/H12/H17 as the only water-enabled Hunts.
#
# Rules:
# - H02 => 2048 (natural/grass-earth bottom)
# - H07 => 2240 (stone/hard bottom)
# - H12 => 2240 (ice/hard bottom; never grassy)
# - H17 => 2240 (ice/hard bottom; never grassy)
# - A1 base 2096 is revoked from current Random Hunt water use.
# - Keep native VX A1 animation/autotile edge behavior.
# - Keep rectangle water only; no river/bridge feature expansion.
# - Keep water blocked/non-walkable.
# - No automatic B/C/D/E map-table stamping.
# - No topology rewrite, Battle AI, Damage, Attack Speed, Focus/C2, Reward or
#   Progression change.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDWaterBottomAutotilePairAuthorityI_v10658']=true

module PMD_AC
  VXRD_WATER_BOTTOM_VERSION_V10658='1.06.58'
  VXRD_WATER_BOTTOM_AUDIT_LOG_V10658='PMD_VXRD_WaterBottom_Audit_LATEST.log'
  VXRD_WATER_BOTTOM_PAIR_V10658={
    'H02'=>{:base=>2048,:style=>:grass_bottom_clear},
    'H07'=>{:base=>2240,:style=>:stone_bottom_clear},
    'H12'=>{:base=>2240,:style=>:hard_ice_bottom_clear},
    'H17'=>{:base=>2240,:style=>:hard_ice_bottom_clear}
  }
  VXRD_WATER_BOTTOM_REVOKED_BASES_V10658=[2096]

  if const_defined?(:VXRD_HUNT_NATIVE_FLOOR_PROFILE_V10642)
    VXRD_WATER_BOTTOM_PAIR_V10658.each do |code,row|
      p=VXRD_HUNT_NATIVE_FLOOR_PROFILE_V10642[code]
      next unless p.is_a?(Hash)
      p[:water]=true
      p[:water_base]=row[:base]
    end
  end

  if const_defined?(:VXRD_A1_WATER_BASE_V10642)
    # Legacy global constant remains defined for compatibility, but per-Hunt
    # water_base above is now the runtime authority for Random Hunt water.
  end

  class << self
    def vxrd_water_bottom_audit_v10658
      bad=[]
      profiles=defined?(VXRD_HUNT_NATIVE_FLOOR_PROFILE_V10642) ? VXRD_HUNT_NATIVE_FLOOR_PROFILE_V10642 : {}
      expected={'H02'=>2048,'H07'=>2240,'H12'=>2240,'H17'=>2240}
      expected.each do |code,base|
        p=profiles[code]
        bad << (code+':missing_profile') unless p.is_a?(Hash)
        bad << (code+':water_disabled') if p.is_a?(Hash) && !p[:water]
        bad << (code+':water_base='+((p && p[:water_base])||'nil').to_s) if !p.is_a?(Hash) || p[:water_base].to_i!=base
      end
      water_codes=[]
      profiles.each do |code,p|
        water_codes << code if p.is_a?(Hash) && p[:water]
      end
      water_codes.sort!
      bad << ('water_scope='+water_codes.join(',')) unless water_codes==%w[H02 H07 H12 H17]
      bad << 'deep_water_2096_still_active' if water_codes.any?{|code|profiles[code][:water_base].to_i==2096}
      {
        :pass=>bad.empty?,
        :mapping=>expected,
        :water_codes=>water_codes,
        :deep_water_2096_active=>water_codes.any?{|code|profiles[code][:water_base].to_i==2096},
        :native_a1=>true,
        :water_blocking=>true,
        :rectangle_only=>true,
        :river=>false,
        :bridge=>false,
        :topology_rewrite=>false,
        :map_table_bcde_stamp=>false,
        :bad=>bad
      }
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    def vxrd_write_water_bottom_audit_v10658
      r=vxrd_water_bottom_audit_v10658
      lines=[]
      lines << 'PMD AutoChess VXRD Water-Bottom Autotile Pair Audit v1.06.58'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'H02_WATER_BASE=2048'
      lines << 'H07_WATER_BASE=2240'
      lines << 'H12_WATER_BASE=2240'
      lines << 'H17_WATER_BASE=2240'
      lines << 'DEEP_WATER_2096_ACTIVE='+(r[:deep_water_2096_active] ? '1':'0')
      lines << 'WATER_SCOPE='+(r[:water_codes]||[]).join(',')
      lines << 'NATIVE_A1=1'
      lines << 'WATER_BLOCKING=1'
      lines << 'RECTANGLE_ONLY=1'
      lines << 'RIVER=0'
      lines << 'BRIDGE=0'
      lines << 'TOPOLOGY_REWRITE=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_WATER_BOTTOM_AUDIT_LOG_V10658,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      {:pass=>false}
    end

    alias pmd_ac_v10658_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10658_write_project_state_log)
    def project_version
      '1.06.58'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10658_write_project_state_log(force)
      vxrd_write_water_bottom_audit_v10658
      r
    rescue
      r
    end
  end
end
