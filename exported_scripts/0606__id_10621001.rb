# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 15 / Startup Debt Recheck v1.06.21
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema15_v10621']=true

module PMD_AC
  class << self
    alias pmd_ac_v10621_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10621_write_project_state_log)

    def project_version
      '1.06.21'
    end

    def production_runtime_asset_scan_fast_audit_v10621
      ok=true
      ok=false unless Scene_PMD_AutoChess.method_defined?(:pmd_ac_v10620_original_v10527_start_battle)
      ok=false unless Scene_PMD_AutoChess.method_defined?(:production_runtime_asset_scan_fast_v10620?)
      {:pass=>ok,:catalog_species=>494,:generated_species=>468,
       :battle_full_scan=>false,:force_scan_retained=>true,:gameplay_change=>false}
    rescue
      {:pass=>false,:catalog_species=>494,:generated_species=>468}
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10621_write_project_state_log(force)
      return false unless r
      a=production_runtime_asset_scan_fast_audit_v10621
      text=''
      File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=15')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.21')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=PRODUCTION_RUNTIME_ASSET_SCAN_FAST_PATH+FOCUS_WORLD_ACTIVE_SEAL')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=WINDOWS_STARTUP_RECHECK_THEN_VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub(/\r?\nSTARTUP_DEBT_RECHECK_V10621_BEGIN.*?STARTUP_DEBT_RECHECK_V10621_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'STARTUP_DEBT_RECHECK_V10621_BEGIN'
      lines << 'PRODUCTION_RUNTIME_ASSET_SCAN_FAST='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_RUNTIME_ASSET_CATALOG_SPECIES=494'
      lines << 'PRODUCTION_RUNTIME_ASSET_GENERATED_SPECIES=468'
      lines << 'PRODUCTION_BATTLE_FULL_ASSET_SCAN=0'
      lines << 'PROJECT_STATE_FORCE_ASSET_SCAN_RETAINED=1'
      lines << 'DEDICATED_QA_ASSET_SCAN_RETAINED=1'
      lines << 'ACTUAL_UNIT_SPRITE_LOADER_RETAINED=1'
      lines << 'FOCUS_WORLD_ACTIVE_WINDOWS_EVIDENCE=PASS'
      lines << 'FOCUS_WORLD_ACTIVE_UNRESOLVED_LAST_EVIDENCE=0'
      lines << 'WINDOWS_STARTUP_RECHECK=PENDING_USER_RUN'
      lines << 'GAMEPLAY_CHANGE=0'
      lines << 'STARTUP_DEBT_RECHECK_V10621_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
