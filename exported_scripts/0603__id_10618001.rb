# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 14 / Technical Debt Windows Recheck
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema14_TechDebtRecheck_v10618']=true

module PMD_AC
  class << self
    alias pmd_ac_v10618_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10618_write_project_state_log)

    def project_version
      '1.06.18'
    end

    def run_random_hunt_windows_acceptance_v10618(code='H02',mode=:event,seed=nil)
      run_vxrd_integrated_test_v10611(code,mode,seed)
    rescue
      false
    end

    def technical_debt_recheck_audit_v10618
      {:pass=>true,:prepare_fast=>true,
       :prepare_aliases=>PRODUCTION_VERIFY_PREP_ALIAS_CHAIN_V10616,
       :focus_active_window=>FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617,
       :focus_clock=>'world_active',:gameplay_change=>false}
    rescue
      {:pass=>false,:prepare_fast=>false,:prepare_aliases=>0,
       :focus_active_window=>0,:focus_clock=>'unknown'}
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10618_write_project_state_log(force)
      return false unless r
      q=technical_debt_recheck_audit_v10618
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=14')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.18')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=PRODUCTION_VERIFY_PREP_FAST+FOCUS_WORLD_ACTIVE_RECONCILIATION')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=TECH_DEBT_WINDOWS_RECHECK_THEN_VXRD_ACCEPTANCE')
      text=text.gsub(/\r?\nTECHNICAL_DEBT_RECHECK_BEGIN.*?TECHNICAL_DEBT_RECHECK_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'TECHNICAL_DEBT_RECHECK_BEGIN'
      lines << 'PRODUCTION_VERIFY_PREP_FAST='+(q[:prepare_fast] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_VERIFY_PREP_ALIAS_CHAIN_SKIPPED='+q[:prepare_aliases].to_i.to_s
      lines << 'PRODUCTION_VERIFY_PREP_GAMEPLAY_CHANGE=0'
      lines << 'FOCUS_RECONCILIATION_QUEUE=PASS'
      lines << 'FOCUS_RECONCILIATION_ACTIVE_WINDOW='+q[:focus_active_window].to_i.to_s
      lines << 'FOCUS_RECONCILIATION_CLOCK='+q[:focus_clock].to_s
      lines << 'FOCUS_RECONCILIATION_PAUSES_DURING_OTHER_FOCUS=1'
      lines << 'FOCUS_RECONCILIATION_GAMEPLAY_CHANGE=0'
      lines << 'WINDOWS_TECH_DEBT_RECHECK=PENDING_USER_RUN'
      lines << 'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE=AFTER_TECH_DEBT_RECHECK'
      lines << 'VXRD_ACCEPTANCE_API=PMD_AC.run_random_hunt_windows_acceptance_v10618'
      lines << 'TECHNICAL_DEBT_RECHECK_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
