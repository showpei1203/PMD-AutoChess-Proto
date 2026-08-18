# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Windows Technical Debt Acceptance Seal v1.06.25
#-------------------------------------------------------------------------------
# Converts the production startup/focus diagnostics into persistent Windows
# evidence. The intentional 0-100% prebattle loader is not counted as core
# startup debt. Observer-only / diagnostics only.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_WindowsTechnicalDebtAcceptance_v10625']=true

class Game_System
  attr_accessor :pmd_windows_tech_debt_evidence_v10625
end

module PMD_AC
  WINDOWS_CORE_STARTUP_LIMIT_MS_V10625=500
  class << self
    def windows_tech_debt_evidence_v10625
      return nil if $game_system==nil
      $game_system.pmd_windows_tech_debt_evidence_v10625
    rescue
      nil
    end

    def windows_tech_debt_acceptance_v10625
      e=windows_tech_debt_evidence_v10625
      return {:status=>:pending,:pass=>false} if e==nil
      pass=e[:core_start_battle_ms].to_i<=WINDOWS_CORE_STARTUP_LIMIT_MS_V10625 &&
        e[:focus_unresolved].to_i==0 && e[:full_catalog_scan_skipped] &&
        e[:verify_prepare_ms].to_i<=50 && e[:loading_manifest] &&
        e[:fallback_species].to_i==0
      h=e.dup;h[:pass]=pass;h[:status]=(pass ? :pass : :fail);h
    rescue
      {:status=>:error,:pass=>false}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10625_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10625_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10625_focus_summary
    begin
      if respond_to?(:v10623_production_manifest_active?) && v10623_production_manifest_active? && $game_system!=nil
        start_ms=@v10613_start_battle_ms.to_i
        loading_ms=@v10623_loading_total_ms.to_i
        core_ms=start_ms-loading_ms;core_ms=0 if core_ms<0
        e={
          :start_battle_ms=>start_ms,
          :intentional_loading_ms=>loading_ms,
          :core_start_battle_ms=>core_ms,
          :loading_assets=>@v10623_loading_asset_count.to_i,
          :manifest_action_assets=>@v10623_manifest_action_assets.to_i,
          :manifest_fx_assets=>@v10623_manifest_fx_assets.to_i,
          :fallback_species=>@v10623_manifest_fallback_species.to_i,
          :loading_manifest=>(@v10623_manifest_total_assets.to_i>0),
          :focus_unresolved=>@v10617_handoff_warn.to_i,
          :focus_handoff=>@v10617_handoff_resolved.to_i,
          :source_ko_cancel=>@v10622_source_ko_cancel.to_i,
          :full_catalog_scan_skipped=>(@v10620_catalog_scan_skipped ? true:false),
          :verify_prepare_ms=>(@v10616_prepare_fast_ms.to_i rescue 0),
          :frame=>(Graphics.frame_count.to_i rescue 0)
        }
        e[:pass]=e[:core_start_battle_ms].to_i<=PMD_AC::WINDOWS_CORE_STARTUP_LIMIT_MS_V10625 &&
          e[:focus_unresolved].to_i==0 && e[:full_catalog_scan_skipped] &&
          e[:verify_prepare_ms].to_i<=50 && e[:loading_manifest] && e[:fallback_species].to_i==0
        $game_system.pmd_windows_tech_debt_evidence_v10625=e
        log_event(:perf,'BATTLE_WINDOWS_TECH_DEBT_ACCEPTANCE_V10625 pass='+(e[:pass] ? '1':'0')+
          ' core_start_battle_ms='+e[:core_start_battle_ms].to_i.to_s+
          ' intentional_loading_ms='+e[:intentional_loading_ms].to_i.to_s+
          ' loading_assets='+e[:loading_assets].to_i.to_s+
          ' focus_unresolved='+e[:focus_unresolved].to_i.to_s+
          ' full_catalog_scan_skipped='+(e[:full_catalog_scan_skipped] ? '1':'0')+
          ' core_limit_ms='+PMD_AC::WINDOWS_CORE_STARTUP_LIMIT_MS_V10625.to_s+
          ' gameplay_change=0')
        PMD_AC.write_project_state_log(false) rescue nil
      end
    rescue
    end
    r
  rescue
    false
  end
end
