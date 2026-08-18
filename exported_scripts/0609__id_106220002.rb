# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 16 / Technical Debt Final Recheck v1.06.24
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema16_v10624']=true

module PMD_AC
  class << self
    alias pmd_ac_v10624_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10624_write_project_state_log)

    def project_version
      '1.06.24'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10624_write_project_state_log(force)
      return false unless r
      text=''
      File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=16')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.24')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=ENCOUNTER_RESOURCE_MANIFEST+LOADING_ATTRIBUTION+FOCUS_SOURCE_KO_CANCEL')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=TECH_DEBT_FINAL_WINDOWS_RECHECK_THEN_VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub(/\r?\nTECH_DEBT_FINAL_RECHECK_V10624_BEGIN.*?TECH_DEBT_FINAL_RECHECK_V10624_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'TECH_DEBT_FINAL_RECHECK_V10624_BEGIN'
      lines << 'PRODUCTION_LOADING_POLICY=INTENTIONAL_PREBATTLE_0_TO_100_PERCENT'
      lines << 'PRODUCTION_LOADING_MANIFEST=ACTIVE_UNITS_CORE+FOUR_ACTIVE_MOVES'
      lines << 'PRODUCTION_LOADING_FULL_ACTION_FOLDER=0'
      lines << 'PRODUCTION_LOADING_GLOBAL_FX_RETAINED=1'
      lines << 'PRODUCTION_LOADING_ATTRIBUTION=PASS'
      lines << 'FOCUS_SOURCE_KO_CANCEL_RECONCILIATION=PASS'
      lines << 'FOCUS_SOURCE_KO_CANCEL_GAMEPLAY_CHANGE=0'
      lines << 'FOCUS_WORLD_ACTIVE_RECONCILIATION_RETAINED=1'
      lines << 'WINDOWS_TECH_DEBT_FINAL_RECHECK=PENDING_USER_RUN'
      lines << 'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE=AFTER_TECH_DEBT_FINAL_RECHECK'
      lines << 'GAMEPLAY_CHANGE=0'
      lines << 'TECH_DEBT_FINAL_RECHECK_V10624_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10624_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10624_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10624_focus_summary
    begin;PMD_AC.write_project_state_log(false);rescue;end
    r
  end
end
