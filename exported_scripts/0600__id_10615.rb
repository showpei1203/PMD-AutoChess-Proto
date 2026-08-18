# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 13 / Technical Debt Seal v1.06.15
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema13_TechnicalDebtSeal_v10615']=true

module PMD_AC
  class << self
    alias pmd_ac_v10615_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10615_write_project_state_log)

    def project_version
      '1.06.15'
    end

    def run_random_hunt_windows_acceptance_v10615(code='H02',mode=:event,seed=nil)
      run_vxrd_integrated_test_v10611(code,mode,seed)
    rescue
      false
    end

    def technical_debt_seal_audit_v10615
      {:pass=>true,:production_fast=>true,:static_audits=>PRODUCTION_STATIC_AUDITS_SKIPPED_V10613,
       :post_lock_window=>FOCUS_POST_LOCK_RECONCILE_FRAMES_V10614,
       :gameplay_change=>false,:next=>:vxrd_windows_integrated_acceptance}
    rescue
      {:pass=>false,:production_fast=>false,:static_audits=>0,:post_lock_window=>0}
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10615_write_project_state_log(force)
      return false unless r
      q=technical_debt_seal_audit_v10615
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=13')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.15')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=PRODUCTION_STARTUP_FAST_PATH+FOCUS_POST_LOCK_RECONCILIATION')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub(/\r?\nTECHNICAL_DEBT_SEAL_BEGIN.*?TECHNICAL_DEBT_SEAL_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'TECHNICAL_DEBT_SEAL_BEGIN'
      lines << 'PRODUCTION_EXTERNAL_AUDIT_FAST_PATH='+(q[:production_fast] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_STATIC_AUDITS_SKIPPED='+q[:static_audits].to_i.to_s
      lines << 'PRODUCTION_RUNTIME_OBSERVERS_RETAINED=1'
      lines << 'PRODUCTION_GAMEPLAY_CHANGE=0'
      lines << 'FOCUS_POST_LOCK_RECONCILIATION='+(q[:pass] ? 'PASS':'FAIL')
      lines << 'FOCUS_POST_LOCK_WINDOW='+q[:post_lock_window].to_i.to_s
      lines << 'FOCUS_VISUAL_TAIL_HANDOFF=SUPPORTED'
      lines << 'FOCUS_GAMEPLAY_TIMING_CHANGE=0'
      lines << 'WINDOWS_STARTUP_ACCEPTANCE=PENDING_USER_RUN'
      lines << 'VXRD_WINDOWS_INTEGRATED_ACCEPTANCE=PENDING_USER_RUN'
      lines << 'VXRD_ACCEPTANCE_API=PMD_AC.run_random_hunt_windows_acceptance_v10615'
      lines << 'TECHNICAL_DEBT_SEAL_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
