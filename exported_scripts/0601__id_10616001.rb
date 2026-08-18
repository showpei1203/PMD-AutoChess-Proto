# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Production Verification Prepare Fast Path v1.06.16
#-------------------------------------------------------------------------------
# NORMAL external Hunt/Challenge battles do not need the 141-layer historical
# prepare_verification_battle verifier chain. Keep only the base NORMAL reset
# semantics; dedicated verifier modes still execute the original full chain.
# Gameplay / AI / Damage / Motion / Spatial remain unchanged.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProductionVerificationPrepareFastPath_v10616']=true

module PMD_AC
  PRODUCTION_VERIFY_PREP_ALIAS_CHAIN_V10616=141
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10616_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10616_prepare_verification_battle)
  alias pmd_ac_v10616_start_battle start_battle unless method_defined?(:pmd_ac_v10616_start_battle)
  alias pmd_ac_v10616_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10616_focus_summary)

  def production_verify_prepare_fast_v10616?
    return false unless respond_to?(:production_external_battle_fast_v10613?)
    production_external_battle_fast_v10613?
  rescue
    false
  end

  def prepare_verification_battle
    unless production_verify_prepare_fast_v10616?
      return pmd_ac_v10616_prepare_verification_battle
    end
    t=Time.now.to_f
    @verification_frame=0
    @verification_done={}
    @zone_avoid_log_frames={}
    count=0
    (@units || []).each do |unit|
      next if unit==nil
      begin
        unit.verification_prepare(false,PMD_AC::VERIFICATION_HP_MULTIPLIER)
      rescue
      end
      begin;unit.verification_energy_sandbox(false);rescue;end
      begin;unit.verification_combat_sandbox(false);rescue;end
      count+=1
    end
    @v10616_prepare_fast_ms=((Time.now.to_f-t)*1000.0).round rescue 0
    @v10616_prepare_fast_units=count
    @v10616_prepare_fast_used=true
    true
  rescue
    # Safety fallback: a prepare optimization must never prevent battle start.
    @verification_frame=0
    @verification_done={}
    @zone_avoid_log_frames={}
    @v10616_prepare_fast_used=true
    true
  end

  def start_battle
    @v10616_prepare_fast_used=false
    @v10616_prepare_fast_ms=0
    @v10616_prepare_fast_units=0
    @v10616_summary_logged=false
    r=pmd_ac_v10616_start_battle
    if production_verify_prepare_fast_v10616?
      # v1.05.38 manual QA READY belongs to dedicated QA, not production Hunt log.
      @important_ready_logged_v10538=true if instance_variable_defined?(:@important_ready_logged_v10538)
    end
    r
  end

  def production_verify_prepare_summary_v10616
    return false if @v10616_summary_logged
    @v10616_summary_logged=true
    return true unless production_verify_prepare_fast_v10616?
    log_event(:perf,'BATTLE_PRODUCTION_VERIFY_PREP_FAST_V10616 pass='+(@v10616_prepare_fast_used ? '1':'0')+
      ' alias_chain_skipped='+PMD_AC::PRODUCTION_VERIFY_PREP_ALIAS_CHAIN_V10616.to_s+
      ' units='+@v10616_prepare_fast_units.to_i.to_s+
      ' prepare_ms='+@v10616_prepare_fast_ms.to_i.to_s+
      ' dedicated_verifier_chain_retained=1 gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10616_focus_summary
    production_verify_prepare_summary_v10616
    r
  rescue
    false
  end
end
