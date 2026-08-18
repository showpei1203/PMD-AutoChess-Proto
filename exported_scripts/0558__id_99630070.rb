# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 3 v1.05.73
#-------------------------------------------------------------------------------
# 同步 v1.05.69-72：Weather decision audit、curated visual loadout、Hunt Rare /
# Elite feedback、Random Map Event Bridge。維持既有 write_project_state_log API。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema3_v10573']=true

module PMD_AC
  class << self
    def project_version
      '1.05.73'
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
      wg=respond_to?(:weather_maintenance_audit_v10569) ? weather_maintenance_audit_v10569 : {:pass=>false}
      vl=respond_to?(:visual_test_loadout_audit_v10570) ? visual_test_loadout_audit_v10570 : {:pass=>false,:species=>0,:slots=>0}
      rm=respond_to?(:random_map_event_bridge_audit_v10572) ? random_map_event_bridge_audit_v10572 : {:pass=>false,:api=>0}
      hs=respond_to?(:hunt_info) ? hunt_info : nil
      lines=[]
      lines << 'PMD AutoChess Project State'
      lines << 'PROJECT_STATE_SCHEMA=3'
      lines << 'CURRENT_VERSION='+project_version.to_s
      lines << 'SCRIPT_CONTAINER_ENTRIES='+sm[:entries].to_i.to_s
      lines << 'SCRIPTS_FILE_BYTES='+sm[:bytes].to_i.to_s
      lines << 'SCRIPTS_CRC32='+sm[:crc32].to_s
      lines << ''
      lines << 'PHASE=C2_COMPLETE,D_I_COMPLETE,D_II_COMPLETE,D_III_COMPLETE,D_IV_ACTIVE'
      lines << 'LATEST_FEATURE=WEATHER_DECISION_AUDIT+VISUAL_4MOVE+HUNT_RARE_ELITE+RANDOM_MAP_BRIDGE'
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
      lines << ''
      lines << 'MENU_RENDER='+project_state_menu_status_v10564
      lines << 'MENU_COMMANDS=14'
      lines << 'SUPPLY_VIEWPORT_LIFECYCLE='+(respond_to?(:supply_viewport_lifecycle_seal_v10565?) && supply_viewport_lifecycle_seal_v10565? ? 'PASS':'FAIL')
      lines << 'TYPE_COLOR_PALETTE='+(pal[:pass] ? pal[:types].to_i.to_s+'/18':'FAIL')
      lines << 'WEATHER_MAINTENANCE_AUDIT='+(wg[:pass] ? 'PASS':'FAIL')
      lines << 'VISUAL_TEST_LOADOUT='+(vl[:pass] ? vl[:species].to_i.to_s+'/6,'+vl[:slots].to_i.to_s+'/24':'FAIL')
      lines << 'HUNT_RARE_ELITE_FEEDBACK=1'
      lines << 'RANDOM_MAP_EVENT_BRIDGE='+(rm[:pass] ? rm[:api].to_i.to_s+'/8':'FAIL')
      lines << 'COLLECTION_CONTINUITY=1'
      lines << 'PROJECT_STATE_AUTO_WRITE=1'
      lines << 'OVERWRITE_MODE=CUMULATIVE'
      if hs!=nil && hs[:active]
        lines << 'HUNT_SESSION_ACTIVE=1'
        lines << 'HUNT_SESSION_CODE='+hs[:code].to_s
        lines << 'HUNT_SESSION_RUN='+hs[:run].to_i.to_s
        lines << 'HUNT_SESSION_ENCOUNTERS='+hs[:encounters].to_i.to_s
        lines << 'HUNT_SESSION_MAPS='+(hs[:maps]||[]).collect{|x|x.to_i.to_s}.join(',')
        lines << 'HUNT_SESSION_POOL='+(hs[:active_pool]||[]).collect{|x|x.to_s}.join(',')
      else
        lines << 'HUNT_SESSION_ACTIVE=0'
      end
      lines << 'NEXT_TARGET=HUNT_RUN_LIFECYCLE+COLLECTION_INFO_DATA+UI_PHASE_PREP'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
