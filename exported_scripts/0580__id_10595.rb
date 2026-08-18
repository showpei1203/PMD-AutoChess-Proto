# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 9 Wall Repair Water v1.05.95
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema9_v10595']=true

module PMD_AC
  class << self
    alias pmd_ac_v10595_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10595_write_project_state_log)

    def project_version
      '1.05.95'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10595_write_project_state_log(force)
      return false unless r
      a=respond_to?(:vxrd_wall_water_audit_v10594) ? vxrd_wall_water_audit_v10594 : {:pass=>false,:wall=>{},:water=>{}}
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|f|text=f.read}
      text=text.gsub('PROJECT_STATE_SCHEMA=8','PROJECT_STATE_SCHEMA=9')
      text=text.gsub('LATEST_FEATURE=VXRD_FS_HEIGHT_WALL_TOPOLOGY+AUTOTEST_DIAGNOSTICS','LATEST_FEATURE=VXRD_HEIGHT_WALL_GEOMETRY_REPAIR+REGULAR_WATER')
      text=text.gsub('NEXT_TARGET=VXRD_HEIGHT_WALL_WINDOWS_QA+WATER_RIVER_BRIDGE+ROOM_TYPES','NEXT_TARGET=VXRD_WINDOWS_WALL_WATER_QA+ROOM_TYPES+RARE_NEST')
      wall=a[:wall]||{};water=a[:water]||{}
      lines=[]
      lines << ''
      lines << 'VXRD_WALL_GEOMETRY_REPAIR='+(wall[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_WALL_VERTICAL_PINCHES='+wall[:vertical_pinches].to_i.to_s
      lines << 'VXRD_WALL_UNSUPPORTED_NORTH='+wall[:unsupported_north].to_i.to_s
      lines << 'VXRD_WALL_UNSUPPORTED_SOUTH='+wall[:unsupported_south].to_i.to_s
      lines << 'VXRD_WALL_ORPHAN_FACE='+wall[:orphan_face].to_i.to_s
      lines << 'VXRD_REGULAR_WATER='+(water[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_WATER_BIOMES='+water[:biomes].to_i.to_s+'/6'
      lines << 'VXRD_WATER_SHAPE=rectangle'
      lines << 'VXRD_WATER_IRREGULAR=0'
      lines << 'VXRD_WATER_RIVER=0'
      lines << 'VXRD_WATER_BRIDGE=0'
      lines << 'VXRD_WATER_ONE_TYPE_PER_STYLE=1'
      lines << 'VXRD_WALL_WATER_AUTOTEST_API=1/1'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
