# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 8 VXRD Height Wall v1.05.91
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema8_v10591']=true

module PMD_AC
  class << self
    alias pmd_ac_v10591_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10591_write_project_state_log)

    def project_version
      '1.05.91'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10591_write_project_state_log(force)
      return false unless r
      a=respond_to?(:vxrd_wall_topology_audit_v10589) ? vxrd_wall_topology_audit_v10589 : {:pass=>false,:renderer=>:missing,:palettes=>0}
      i=respond_to?(:vxrd_wall_topology_info_v10589) ? vxrd_wall_topology_info_v10589 : nil
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|f|text=f.read}
      text=text.gsub('PROJECT_STATE_SCHEMA=7','PROJECT_STATE_SCHEMA=8')
      text=text.gsub('LATEST_FEATURE=VXRD_AUTOTEST_HARNESS+DEDICATED_MAP090','LATEST_FEATURE=VXRD_FS_HEIGHT_WALL_TOPOLOGY+AUTOTEST_DIAGNOSTICS')
      text=text.gsub('NEXT_TARGET=VXRD_RTP_VISUAL_QA+WATER_RIVER_BRIDGE+HUNT_NODE_CONTENT','NEXT_TARGET=VXRD_HEIGHT_WALL_WINDOWS_QA+WATER_RIVER_BRIDGE+ROOM_TYPES')
      lines=[]
      lines << ''
      lines << 'VXRD_HEIGHT_WALL='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_HEIGHT_WALL_RENDERER='+a[:renderer].to_s
      lines << 'VXRD_HEIGHT_WALL_PALETTES='+a[:palettes].to_i.to_s+'/24'
      lines << 'VXRD_HEIGHT_WALL_EXTERNAL_PNG='+(a[:external_png] ? '1':'0')
      lines << 'VXRD_HEIGHT_WALL_BITMAP_RENDERER='+(a[:bitmap_renderer] ? '1':'0')
      lines << 'VXRD_HEIGHT_WALL_FACE_OFFSET='+a[:face_offset].to_i.to_s
      if i!=nil
        c=i[:counts]||{}
        lines << 'VXRD_WALL_TOP_BASE='+i[:wall_top_base].to_i.to_s
        lines << 'VXRD_WALL_FACE_BASE='+i[:wall_face_base].to_i.to_s
        lines << 'VXRD_WALL_OPEN='+c[:open].to_i.to_s
        lines << 'VXRD_WALL_NORTH_FACE='+c[:north_face].to_i.to_s
        lines << 'VXRD_WALL_TOP='+c[:wall_top].to_i.to_s
        lines << 'VXRD_WALL_SOUTH_FACE='+c[:south_face].to_i.to_s
        lines << 'VXRD_WALL_OUTER='+c[:outer].to_i.to_s
      end
      lines << 'VXRD_WALL_AUTOTEST_API=2/2'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
