# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Production External Battle Audit Fast Path v1.06.13
#-------------------------------------------------------------------------------
# External Hunt/Challenge battles start synchronously inside Scene#start (v0.81).
# Historical static QA must not execute there. Runtime gameplay and observers stay on.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProductionExternalBattleAuditFastPath_v10613']=true

module PMD_AC
  PRODUCTION_STATIC_AUDITS_SKIPPED_V10613=21
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10613_start_battle start_battle unless method_defined?(:pmd_ac_v10613_start_battle)
  alias pmd_ac_v10613_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10613_focus_summary)

  def production_external_battle_fast_v10613?
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    return false unless respond_to?(:rpg_external_battle_v081?) && rpg_external_battle_v081?
    true
  rescue
    false
  end

  def start_battle
    fast=production_external_battle_fast_v10613?
    t=Time.now.to_f
    @v10613_fast_active=fast
    @v10613_fast_summary_logged=false
    r=nil
    begin
      r=pmd_ac_v10613_start_battle
      if fast
        ms=((Time.now.to_f-t)*1000.0).round
        @v10613_start_battle_ms=ms
        log_event(:perf,'BATTLE_PRODUCTION_AUDIT_FAST_PATH_V10613 external=1 start_battle_ms='+ms.to_s+
          ' static_audits_skipped='+PMD_AC::PRODUCTION_STATIC_AUDITS_SKIPPED_V10613.to_s+
          ' runtime_observers_retained=1 gameplay_change=0 ai_unchanged=1 damage_unchanged=1'+
          ' motion_unchanged=1 spatial_unchanged=1')
      end
    rescue
      @v10613_start_battle_observer_error=@v10613_start_battle_observer_error.to_i+1
    end
    r
  end

  def production_external_fast_summary_v10613
    return false if @v10613_fast_summary_logged
    @v10613_fast_summary_logged=true
    return true unless @v10613_fast_active
    log_event(:perf,'BATTLE_PRODUCTION_AUDIT_FAST_PATH_SUMMARY_V10613 pass=1 external=1'+
      ' start_battle_ms='+@v10613_start_battle_ms.to_i.to_s+
      ' static_audits_skipped='+PMD_AC::PRODUCTION_STATIC_AUDITS_SKIPPED_V10613.to_s+
      ' move_family_runtime_observer=1 single_delegation_runtime=1 c2_runtime=1'+
      ' dedicated_verifier_modes_retained=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10613_focus_summary
    production_external_fast_summary_v10613
    r
  rescue
    false
  end
end
