# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 12 / Random Hunt Integration Seal v1.06.12
#-------------------------------------------------------------------------------
# Final structural handoff for the VX-native Random Dungeon + Hunt gameplay loop.
# Windows visual/gameplay acceptance remains the next gate; UI art remains unsealed.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema12_RandomHuntSeal_v10612']=true

module PMD_AC
  class << self
    alias pmd_ac_v10612_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10612_write_project_state_log)

    def project_version
      '1.06.12'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10612_write_project_state_log(force)
      return false unless r
      seal=vxrd_random_hunt_system_audit_v10610 rescue {:pass=>false,:hunts=>0,:room_types=>0}
      ent=hunt_runtime_entry_audit_v10604 rescue {:pass=>false,:api=>0}
      set=hunt_runtime_settlement_audit_v10605 rescue {:pass=>false,:api=>0}
      nod=vxrd_node_lifecycle_audit_v10606 rescue {:pass=>false,:api=>0}
      vis=vxrd_room_visual_audit_v10607 rescue {:pass=>false,:api=>0}
      acc=hunt_run_accounting_audit_v10608 rescue {:pass=>false,:api=>0}
      sav=vxrd_save_resume_audit_v10609 rescue {:pass=>false,:api=>0}
      ina=vxrd_integrated_acceptance_audit_v10611 rescue {:pass=>false,:api=>0,:presets=>0}
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=12')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.12')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_RANDOM_HUNT_FULL_INTEGRATION')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_WINDOWS_INTEGRATED_ACCEPTANCE+UI_POLISH')
      text=text.gsub(/\r?\nVXRD_RANDOM_HUNT_FINAL_BEGIN.*?VXRD_RANDOM_HUNT_FINAL_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'VXRD_RANDOM_HUNT_FINAL_BEGIN'
      lines << 'VXRD_RANDOM_HUNT_PHASE='+(seal[:pass] ? 'STRUCTURAL_COMPLETE':'STRUCTURAL_FAIL')
      lines << 'VXRD_HUNT_SELECTOR_RANDOM_DUNGEON='+(ent[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_HUNT_RUNTIME_MAP=90'
      lines << 'VXRD_FLOOR_CURVE=3,4,5,5,6'
      lines << 'VXRD_FLOOR_EXIT_REQUIRES_WIN=1'
      lines << 'VXRD_ROOM_TYPES='+seal[:room_types].to_i.to_s+'/7'
      lines << 'VXRD_NODE_LIFECYCLE='+(nod[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_ROOM_VISUAL_IDENTITY='+(vis[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_RUN_ACCOUNTING='+(acc[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_RUN_SETTLEMENT='+(set[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_SAVE_RESUME='+(sav[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_WATER_CODES=H02,H07,H12,H17'
      lines << 'VXRD_WATER_BASE='+VXRD_FINAL_WATER_BASE_V10610.to_i.to_s
      lines << 'VXRD_WATER_RULE=ONE_TYPE_RECTANGLE_BANK_NO_RIVER_NO_BRIDGE'
      lines << 'VXRD_GROUND_DECOR=RTP_NATIVE'
      lines << 'VXRD_EXTERNAL_PNG=0'
      lines << 'VXRD_PARALLAX_GENERATION=0'
      lines << 'VXRD_SECOND_GAME_MAP=0'
      lines << 'VXRD_COMPLETION_BONUS=FULL_CLEAR_ONLY'
      lines << 'VXRD_RETREAT_KEEPS_IMMEDIATE_REWARDS=1'
      lines << 'VXRD_DEFEAT_KEEPS_IMMEDIATE_REWARDS=1'
      lines << 'VXRD_RARE_NEST_ACTIVE_POOL_ONLY=1'
      lines << 'VXRD_ELITE_ROOM_FORCE_ONE=1'
      lines << 'VXRD_RECOVERY_NO_REVIVE=1'
      lines << 'VXRD_INTEGRATED_ACCEPTANCE='+(ina[:pass] ? 'READY':'FAIL')
      lines << 'VXRD_INTEGRATED_PRESETS='+ina[:presets].to_i.to_s+'/7'
      lines << 'VXRD_INTEGRATED_LOG='+VXRD_INTEGRATED_LOG_V10611.to_s
      lines << 'VXRD_WINDOWS_ACCEPTANCE=PENDING_USER_RUN'
      lines << 'VXRD_UI_STATUS=FUNCTIONAL_NOT_FINAL'
      lines << 'VXRD_RANDOM_HUNT_FINAL_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def vxrd_final_integration_audit_v10612
      list=[]
      list << (vxrd_random_hunt_system_audit_v10610 rescue {:pass=>false})
      list << (hunt_runtime_entry_audit_v10604 rescue {:pass=>false})
      list << (hunt_runtime_settlement_audit_v10605 rescue {:pass=>false})
      list << (vxrd_node_lifecycle_audit_v10606 rescue {:pass=>false})
      list << (vxrd_room_visual_audit_v10607 rescue {:pass=>false})
      list << (hunt_run_accounting_audit_v10608 rescue {:pass=>false})
      list << (vxrd_save_resume_audit_v10609 rescue {:pass=>false})
      list << (vxrd_integrated_acceptance_audit_v10611 rescue {:pass=>false})
      {:pass=>list.all?{|x|x[:pass]},:components=>list.size,:windows_acceptance=>:pending,
        :ui_status=>:functional_not_final}
    rescue
      {:pass=>false,:components=>0,:windows_acceptance=>:pending}
    end
  end
end
