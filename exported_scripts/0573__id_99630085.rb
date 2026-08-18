# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 7 + VXRD AutoTest v1.05.88
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema7_v10588']=true

module PMD_AC
  class << self
    alias pmd_ac_v10588_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10588_write_project_state_log)

    def project_version
      '1.05.88'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10588_write_project_state_log(force)
      return false unless r
      a=respond_to?(:vxrd_autotest_audit_v10586) ? vxrd_autotest_audit_v10586 : {:pass=>false,:api=>0,:presets=>0,:map_id=>90,:map_file=>false}
      s=respond_to?(:vxrd_autotest_state_v10586) ? vxrd_autotest_state_v10586 : nil
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|f|text=f.read}
      text=text.gsub('PROJECT_STATE_SCHEMA=6','PROJECT_STATE_SCHEMA=7')
      text=text.gsub('LATEST_FEATURE=VX_NATIVE_RANDOM_DUNGEON+HUNT_RANDOM_FLOOR','LATEST_FEATURE=VXRD_AUTOTEST_HARNESS+DEDICATED_MAP090')
      text=text.gsub('NEXT_TARGET=VXRD_WINDOWS_VISUAL_QA+HUNT_NODE_CONTENT+UI_PHASE_PREP','NEXT_TARGET=VXRD_RTP_VISUAL_QA+WATER_RIVER_BRIDGE+HUNT_NODE_CONTENT')
      text=text.gsub('MENU_COMMANDS=14','MENU_COMMANDS=15')
      lines=[]
      lines << ''
      lines << 'VXRD_AUTOTEST='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_AUTOTEST_MAP_ID='+a[:map_id].to_i.to_s
      lines << 'VXRD_AUTOTEST_MAP_FILE='+(a[:map_file] ? 'PASS':'FAIL')
      lines << 'VXRD_AUTOTEST_API='+a[:api].to_i.to_s+'/8'
      lines << 'VXRD_AUTOTEST_PRESETS='+a[:presets].to_i.to_s+'/6'
      lines << 'VXRD_AUTOTEST_LOG='+VXRD_AUTOTEST_LOG_V10586
      lines << 'VXRD_MENU_ENTRY=1'
      if s!=nil
        lines << 'VXRD_AUTOTEST_ACTIVE='+(s[:active] ? '1':'0')
        lines << 'VXRD_AUTOTEST_CODE='+s[:code].to_s
        lines << 'VXRD_AUTOTEST_MODE='+s[:mode].to_s
        lines << 'VXRD_AUTOTEST_FLOORS='+s[:floors].to_i.to_s
      else
        lines << 'VXRD_AUTOTEST_ACTIVE=0'
      end
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10588_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10588_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10588_focus_summary
    begin
      a=PMD_AC.vxrd_autotest_audit_v10586
      log_event(:battle,'BATTLE_VXRD_AUTOTEST_SUMMARY_V10586 pass='+(a[:pass] ? '1':'0')+
        ' map='+a[:map_id].to_i.to_s+' map_file='+(a[:map_file] ? '1':'0')+
        ' api='+a[:api].to_i.to_s+'/8 presets='+a[:presets].to_i.to_s+'/6 menu_entry=1')
    rescue
    end
    r
  end
end
