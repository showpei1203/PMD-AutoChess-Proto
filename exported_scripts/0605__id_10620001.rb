# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Production Runtime Asset Catalog Scan Fast Path v1.06.20
#-------------------------------------------------------------------------------
# v1.05.26 performs a full 494-species Graphics/PMD catalog filesystem scan in
# every first NORMAL battle of a process. That scan is QA/admission evidence,
# not gameplay. On Windows/handheld storage it can dominate synchronous battle
# startup with thousands of directory/file probes.
#
# Production external Hunt/Challenge battles now bypass only the v1.05.26 full
# catalog scan wrapper. Actual sprite loading remains authoritative and missing
# runtime assets still fail/fallback through the existing loader. Full catalog
# scanning remains available to ProjectState force scan and dedicated QA.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProductionRuntimeAssetCatalogScanFastPath_v10620']=true

class Scene_PMD_AutoChess
  # v1.05.27 captured v1.05.26's start_battle wrapper under this alias.
  # Preserve that alias for non-production modes, then replace the alias method
  # itself so the v1.05.27 wrapper can skip only v1.05.26 in production.
  alias pmd_ac_v10620_original_v10527_start_battle pmd_ac_v10527_start_battle unless method_defined?(:pmd_ac_v10620_original_v10527_start_battle)
  alias pmd_ac_v10620_original_v10527_focus_summary pmd_ac_v10527_focus_summary unless method_defined?(:pmd_ac_v10620_original_v10527_focus_summary)
  alias pmd_ac_v10620_start_battle start_battle unless method_defined?(:pmd_ac_v10620_start_battle)
  alias pmd_ac_v10620_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10620_focus_summary)

  def production_runtime_asset_scan_fast_v10620?
    return false unless respond_to?(:production_external_battle_fast_v10613?)
    production_external_battle_fast_v10613?
  rescue
    false
  end

  # Called from v1.05.27 start_battle. In production external NORMAL, call the
  # alias below v1.05.26, thereby skipping only runtime_asset_scan_v10526.
  def pmd_ac_v10527_start_battle
    if production_runtime_asset_scan_fast_v10620?
      @v10620_catalog_scan_skipped=true
      return pmd_ac_v10526_start_battle
    end
    pmd_ac_v10620_original_v10527_start_battle
  end

  # Same idea for battle-end summary: do not postpone the full catalog scan to
  # Focus summary after having removed it from startup.
  def pmd_ac_v10527_focus_summary
    if production_runtime_asset_scan_fast_v10620?
      return pmd_ac_v10526_focus_summary
    end
    pmd_ac_v10620_original_v10527_focus_summary
  end

  def start_battle
    @v10620_catalog_scan_skipped=false
    @v10620_summary_logged=false
    r=pmd_ac_v10620_start_battle
    begin
      if production_runtime_asset_scan_fast_v10620?
        log_event(:perf,'BATTLE_PRODUCTION_RUNTIME_ASSET_SCAN_FAST_V10620 pass='+
          (@v10620_catalog_scan_skipped ? '1':'0')+
          ' full_catalog_scan_skipped='+(@v10620_catalog_scan_skipped ? '1':'0')+
          ' catalog_species=494 generated_species=468'+
          ' actual_unit_sprite_loader_retained=1 project_state_force_scan_retained=1'+
          ' dedicated_qa_scan_retained=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  def production_runtime_asset_scan_summary_v10620
    return false if @v10620_summary_logged
    @v10620_summary_logged=true
    return true unless production_runtime_asset_scan_fast_v10620?
    log_event(:perf,'BATTLE_PRODUCTION_RUNTIME_ASSET_SCAN_FAST_SUMMARY_V10620 pass='+
      (@v10620_catalog_scan_skipped ? '1':'0')+
      ' full_catalog_scan_skipped='+(@v10620_catalog_scan_skipped ? '1':'0')+
      ' runtime_asset_scan_v10526_called_in_battle=0'+
      ' actual_unit_sprite_loader_retained=1 gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10620_focus_summary
    production_runtime_asset_scan_summary_v10620
    r
  rescue
    false
  end
end
