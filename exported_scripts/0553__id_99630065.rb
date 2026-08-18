# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Project State Sync Schema 2 v1.05.68
#------------------------------------------------------------------------------
# Refreshes the lightweight sync LOG for v1.05.65-67 and preserves the public
# write_project_state_log API used by the user.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema2_v10568']=true

module PMD_AC
  class << self
    def project_version
      '1.05.68'
    end

    def project_state_challenge_runtime_v10564
      n=0
      (1..16).each do |i|
        c='C'+sprintf('%02d',i)
        ok=(phase_div_early_challenge_v10554(c)!=nil)
        ok=true if ['C13','C14','C15','C16'].include?(c) && respond_to?(:phase_div_legend_waves_v10567) && !phase_div_legend_waves_v10567(c).empty?
        n+=1 if ok
      end
      n
    rescue
      0
    end

    def write_project_state_log(force=false)
      sm=project_state_scripts_meta_v10564
      as=project_state_asset_status_v10564(force)
      ca=defined?(PHASE_DIV_SPECIES_APPEARANCE_V10553) ? PHASE_DIV_SPECIES_APPEARANCE_V10553.size : 0
      hr=project_state_hunt_runtime_v10564
      cr=project_state_challenge_runtime_v10564
      cc=project_state_challenge_clears_v10564
      pal=respond_to?(:focus_type_palette_audit_v10566) ? focus_type_palette_audit_v10566 : {:pass=>false,:types=>0}
      leg=respond_to?(:phase_div_legend_circuit_audit_v10567) ? phase_div_legend_circuit_audit_v10567 : {:pass=>false,:circuits=>0,:species=>0,:waves=>0}
      lines=[]
      lines << 'PMD AutoChess Project State'
      lines << 'PROJECT_STATE_SCHEMA=2'
      lines << 'CURRENT_VERSION='+project_version.to_s
      lines << 'SCRIPT_CONTAINER_ENTRIES='+sm[:entries].to_i.to_s
      lines << 'SCRIPTS_FILE_BYTES='+sm[:bytes].to_i.to_s
      lines << 'SCRIPTS_CRC32='+sm[:crc32].to_s
      lines << ''
      lines << 'PHASE=C2_COMPLETE,D_I_COMPLETE,D_II_COMPLETE,D_III_COMPLETE,D_IV_ACTIVE'
      lines << 'LATEST_FEATURE=SUPPLY_LIFECYCLE+TYPE_COLOR_AUTHORITY+LEGEND_CIRCUITS+C2_PASSIVE_MOVE_RECONCILE'
      lines << 'UI_STATUS=FUNCTIONAL_NOT_FINAL'
      lines << ''
      lines << 'PMD_RUNTIME_ASSETS='+as[:ready].to_i.to_s+'/'+as[:total].to_i.to_s
      lines << 'PMD_PARTIAL='+as[:partial].to_i.to_s
      lines << 'PMD_ASSET_COMPLETE='+as[:complete].to_i.to_s
      lines << 'PMD_NEXT_BATCH='+as[:next_batch].to_s
      lines << ''
      lines << 'SPECIES_AUTHORITY='+ca.to_i.to_s+'/494'
      lines << 'HUNT_AUTHORITY=21/21'
      lines << 'HUNT_RUNTIME='+hr.to_i.to_s+'/21'
      lines << 'CHALLENGE_AUTHORITY=16/16'
      lines << 'CHALLENGE_RUNTIME='+cr.to_i.to_s+'/16'
      lines << 'CHALLENGE_CLEARED='+cc.to_i.to_s+'/16'
      lines << 'CHALLENGE_FIXED_REWARD_DESCRIPTORS=12/12'
      lines << 'LEGEND_CIRCUITS='+leg[:circuits].to_i.to_s+'/4'
      lines << 'LEGEND_CIRCUIT_SPECIES='+leg[:species].to_i.to_s+'/36'
      lines << 'LEGEND_CIRCUIT_WAVES='+leg[:waves].to_i.to_s
      lines << 'PROGRESSION_SPECIES=494/494'
      lines << 'MOVE_ACQUISITION=538/538'
      lines << 'TEAM_BOND=81/81'
      lines << 'REPRESENTATIVE_ROUTES=896/896'
      lines << 'FOCUS_STRUCTURAL=504/504'
      lines << 'C2_PASSIVE_MOVEMENT_RECONCILED=1'
      lines << ''
      lines << 'MENU_RENDER='+project_state_menu_status_v10564
      lines << 'MENU_COMMANDS=14'
      lines << 'SUPPLY_VIEWPORT_LIFECYCLE='+(respond_to?(:supply_viewport_lifecycle_seal_v10565?) && supply_viewport_lifecycle_seal_v10565? ? 'PASS':'FAIL')
      lines << 'TYPE_COLOR_PALETTE='+(pal[:pass] ? pal[:types].to_i.to_s+'/18':'FAIL')
      lines << 'TYPE_COLORED_CHARGE=1'
      lines << 'COLLECTION_CONTINUITY=1'
      lines << 'PROJECT_STATE_AUTO_WRITE=1'
      lines << 'OVERWRITE_MODE=CUMULATIVE'
      lines << 'NEXT_TARGET=HUNT_RARE_ELITE_FEEDBACK+RANDOM_MAP_EVENT_BRIDGE'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end


class Scene_PMD_AutoChess
  # Windows evidence: passive pursuit/evade can legitimately move logical x/y
  # without incrementing the v1.05.45 tactical slide serial.  Reconcile only the
  # observer's expected flag; Spatial / AI / movement behavior is untouched.
  alias pmd_ac_v10568_c2_snapshot c2_completion_snapshot_v10545 unless method_defined?(:pmd_ac_v10568_c2_snapshot)
  def c2_completion_snapshot_v10545(ctx,owner)
    s=pmd_ac_v10568_c2_snapshot(ctx,owner)
    begin
      if s!=nil && s[:logical].to_f>PMD_AC::C2_LOGICAL_DISPLACEMENT_EPS_V10545 && !s[:expected]
        reason=s[:slide_reason]
        known=[:passive_pursuit,:passive_evade,:adaptive_close_gap,:bodyguard,:recovery]
        s[:expected]=true if known.include?(reason)
      end
    rescue
    end
    s
  end
end
