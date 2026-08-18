# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 17 / VXRD Windows Acceptance v1.06.28
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema17_VXRDWindowsAcceptance_v10628']=true

module PMD_AC
  class << self
    alias pmd_ac_v10628_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10628_write_project_state_log)

    def project_version
      '1.06.28'
    end

    def run_random_hunt_windows_acceptance_v10628(code='H01',mode=:event,seed=nil)
      run_random_hunt_windows_acceptance_v10627(code,mode,seed)
    rescue
      false
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10628_write_project_state_log(force)
      return false unless r
      tech=windows_tech_debt_acceptance_v10625 rescue {:status=>:pending,:pass=>false}
      sem=hunt_runtime_semantics_audit_v10626 rescue {:pass=>false,:runtime_ready=>0,:spawnable_now=>0,:gated=>[],:h21_unlocked=>0,:h21_total=>0}
      acc=vxrd_windows_acceptance_state_v10627 rescue nil
      aa=vxrd_windows_acceptance_audit_v10627 rescue {:pass=>false,:api=>0}
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=17')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.28')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=WINDOWS_TECH_DEBT_ACCEPTED+HUNT_RUNTIME_SEMANTICS+VXRD_PRODUCTION_ACCEPTANCE')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub(/HUNT_RUNTIME=\d+\/21/,'HUNT_RUNTIME='+sem[:runtime_ready].to_i.to_s+'/21')
      text=text.gsub(/VXRD_AUTOTEST_PRESETS=\d+\/\d+/,'VXRD_AUTOTEST_PRESETS=7/7')
      if tech[:pass]
        text=text.gsub(/WINDOWS_STARTUP_ACCEPTANCE=PENDING_USER_RUN/,'WINDOWS_STARTUP_ACCEPTANCE=PASS')
        text=text.gsub(/WINDOWS_TECH_DEBT_RECHECK=PENDING_USER_RUN/,'WINDOWS_TECH_DEBT_RECHECK=PASS')
        text=text.gsub(/WINDOWS_TECH_DEBT_FINAL_RECHECK=PENDING_USER_RUN/,'WINDOWS_TECH_DEBT_FINAL_RECHECK=PASS')
      end
      text=text.gsub(/\r?\nVXRD_WINDOWS_ACCEPTANCE_V10628_BEGIN.*?VXRD_WINDOWS_ACCEPTANCE_V10628_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'VXRD_WINDOWS_ACCEPTANCE_V10628_BEGIN'
      lines << 'WINDOWS_TECH_DEBT_ACCEPTANCE='+(tech[:pass] ? 'PASS':tech[:status].to_s.upcase)
      lines << 'WINDOWS_CORE_START_BATTLE_MS='+tech[:core_start_battle_ms].to_i.to_s
      lines << 'WINDOWS_INTENTIONAL_LOADING_MS='+tech[:intentional_loading_ms].to_i.to_s
      lines << 'WINDOWS_LOADING_ASSETS='+tech[:loading_assets].to_i.to_s
      lines << 'WINDOWS_FOCUS_UNRESOLVED='+tech[:focus_unresolved].to_i.to_s
      lines << 'HUNT_RUNTIME_READY='+sem[:runtime_ready].to_i.to_s+'/21'
      lines << 'HUNT_SPAWNABLE_NOW='+sem[:spawnable_now].to_i.to_s+'/21'
      lines << 'HUNT_GATED_CODES='+(sem[:gated]||[]).join(',')
      lines << 'H21_UNLOCKED_LEGENDS='+sem[:h21_unlocked].to_i.to_s+'/'+sem[:h21_total].to_i.to_s
      lines << 'H21_GATE_POLICY=LEGENDARY_CIRCUIT_CLEAR'
      lines << 'VXRD_WINDOWS_ACCEPTANCE_HARNESS='+(aa[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_WINDOWS_ACCEPTANCE_API=PMD_AC.run_random_hunt_windows_acceptance_v10628'
      lines << 'VXRD_WINDOWS_ACCEPTANCE_LOG='+VXRD_WINDOWS_ACCEPTANCE_LOG_V10627.to_s
      if acc==nil
        lines << 'VXRD_WINDOWS_ACCEPTANCE_STATE=PENDING'
      else
        lines << 'VXRD_WINDOWS_ACCEPTANCE_STATE='+(acc[:active] ? 'ACTIVE':'RECORDED')
        lines << 'VXRD_WINDOWS_ACCEPTANCE_CODE='+acc[:code].to_s
        lines << 'VXRD_WINDOWS_ACCEPTANCE_VISUAL='+acc[:manual_visual].to_s.upcase
        res=acc[:result]
        lines << 'VXRD_WINDOWS_ACCEPTANCE_RESULT='+(res==nil ? 'PENDING':res[:reason].to_s)
      end
      lines << 'VXRD_WINDOWS_ACCEPTANCE_V10628_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
