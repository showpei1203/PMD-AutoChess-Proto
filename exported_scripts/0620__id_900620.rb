# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Acceptance Non-Combat Fixture v1.06.35
#-------------------------------------------------------------------------------
# Acceptance correction:
# - H12 is used only as a structural/save-load/retreat fixture.
# - No battle is required or allowed while the v1.06.34 final acceptance state
#   is active on the H12 fixture map.
# - Encounter nodes may be consumed by contact, but never launch Scene_Battle.
# - Production Hunt behavior outside the acceptance fixture is untouched.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDAcceptanceNonCombatFixture_v10635']=true

module PMD_AC
  class << self
    def vxrd_final_acceptance_noncombat_v10635?
      s=vxrd_final_acceptance_state_v10634 rescue nil
      hs=hunt_runtime_session_v10605 rescue nil
      return false if s==nil || hs==nil
      return false unless s[:overall]==:active
      return false if s[:stage]==:failed || s[:stage]==:complete
      hs[:code].to_s.upcase=='H12' && $game_map!=nil &&
        $game_map.map_id.to_i==VXRD_HUNT_RUNTIME_MAP_ID_V10604
    rescue
      false
    end

    def vxrd_final_acceptance_noncombat_notice_v10635
      s=vxrd_final_acceptance_state_v10634 rescue nil
      return true if s==nil
      unless s[:noncombat_notice_shown_v10635]
        s[:noncombat_notice_shown_v10635]=true
        hunt_runtime_message_v10604([
          'VXRD 最終驗收｜NON-COMBAT',
          '這張 H12 只驗地圖結構與 Save / Load。',
          '驗收期間所有 Encounter 都不會進入戰鬥。',
          '不需要、也不應該用目前隊伍通關 H12。'
        ]) rescue nil
      end
      true
    rescue
      false
    end

    # Event-room encounters are the production path for the acceptance fixture.
    # Let the node lifecycle regard the interaction as handled, but never create
    # a battle request or mutate encounter counters.
    alias pmd_ac_v10635_hunt_room_encounter_v10602 hunt_room_encounter_v10602 unless method_defined?(:pmd_ac_v10635_hunt_room_encounter_v10602)
    def hunt_room_encounter_v10602(room_type=nil)
      if vxrd_final_acceptance_noncombat_v10635?
        s=phase_div_current_hunt_session_v10555 rescue nil
        if s!=nil
          type=(room_type==nil ? (vxrd_player_room_type_v10602 rescue :normal) : room_type.to_sym)
          type=:normal unless [:rare_nest,:elite,:normal].include?(type)
          s[:last_room_encounter_v10602]=type
          s[:acceptance_encounter_suppressed_v10635]=s[:acceptance_encounter_suppressed_v10635].to_i+1
        end
        vxrd_final_acceptance_noncombat_notice_v10635
        return true
      end
      pmd_ac_v10635_hunt_room_encounter_v10602(room_type)
    rescue
      false
    end

    # Defensive seal for any legacy/step-based Hunt encounter path.
    alias pmd_ac_v10635_phase_div_launch_hunt_encounter_v10555 phase_div_launch_hunt_encounter_v10555 unless method_defined?(:pmd_ac_v10635_phase_div_launch_hunt_encounter_v10555)
    def phase_div_launch_hunt_encounter_v10555
      if vxrd_final_acceptance_noncombat_v10635?
        hs=hunt_runtime_session_v10605 rescue nil
        hs[:acceptance_encounter_suppressed_v10635]=hs[:acceptance_encounter_suppressed_v10635].to_i+1 if hs!=nil
        vxrd_final_acceptance_noncombat_notice_v10635
        return true
      end
      pmd_ac_v10635_phase_div_launch_hunt_encounter_v10555
    rescue
      false
    end

    # Replace the v1.06.34 ready notice with an explicit no-battle contract.
    def on_vxrd_final_acceptance_h12_generated_v10634
      s=vxrd_final_acceptance_state_v10634
      return true if s==nil || s[:stage]!=:launching_h12
      hs=hunt_runtime_session_v10605 rescue nil
      return fail_vxrd_final_acceptance_v10634(:wrong_hunt_after_launch) if hs==nil || hs[:code].to_s.upcase!='H12'
      probes=vxrd_acceptance_detached_probes_v10634
      s[:probes]=probes
      return fail_vxrd_final_acceptance_v10634(:h12_probe_failed) unless probes[:pass]
      snap=vxrd_acceptance_snapshot_v10634
      return fail_vxrd_final_acceptance_v10634(:initial_snapshot_failed) if snap==nil
      s[:initial_snapshot_crc]=snap[:crc32].to_i
      s[:stage]=:await_save
      s[:manual_visual]=:pending
      s[:noncombat_fixture_v10635]=true
      s[:noncombat_notice_shown_v10635]=true
      write_vxrd_final_acceptance_log_v10634(:h12_ready)
      write_project_state_log(false) rescue nil
      hunt_runtime_message_v10604([
        'VXRD 最終驗收｜H12 NON-COMBAT Fixture',
        '特殊房／水域／出口 Gate 已背景語意檢查 PASS。',
        '不需要打任何一場戰鬥，也不需要通關 H12。',
        '現在：Menu 存檔 → 立刻讀回同一個檔。',
        '讀檔後系統會自動比對、撤退並驗證 H21 Gate。'
      ]) rescue nil
      true
    rescue
      fail_vxrd_final_acceptance_v10634(:h12_ready_error)
    end

    # v1.06.35 log keeps v1.06.34 state compatibility but makes the fixture
    # contract explicit for future handoff/debugging.
    alias pmd_ac_v10635_write_vxrd_final_acceptance_log_v10634 write_vxrd_final_acceptance_log_v10634 unless method_defined?(:pmd_ac_v10635_write_vxrd_final_acceptance_log_v10634)
    def write_vxrd_final_acceptance_log_v10634(action)
      r=pmd_ac_v10635_write_vxrd_final_acceptance_log_v10634(action)
      begin
        path=VXRD_FINAL_ACCEPTANCE_LOG_V10634
        text='';File.open(path,'rb'){|io|text=io.read}
        text=text.gsub(/VERSION=[^\r\n]+/,'VERSION=1.06.35')
        text=text.gsub(/CONDUCTOR=[^\r\n]+/,'CONDUCTOR=v1.06.35_NONCOMBAT_FIXTURE')
        extra=[]
        extra << 'H12_ACCEPTANCE_COMBAT=DISABLED'
        extra << 'H12_CLEAR_REQUIRED=0'
        extra << 'H12_PARTY_POWER_REQUIRED=0'
        s=vxrd_final_acceptance_state_v10634 || {}
        extra << 'H12_ENCOUNTERS_SUPPRESSED='+((hunt_runtime_session_v10605 rescue nil)||{})[:acceptance_encounter_suppressed_v10635].to_i.to_s
        File.open(path,'wb'){|io|io.write(text.rstrip+"\r\n"+extra.join("\r\n")+"\r\n")}
      rescue
      end
      r
    rescue
      false
    end

    alias pmd_ac_v10635_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10635_write_project_state_log)
    def project_version
      '1.06.35'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10635_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=23')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.35')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_FINAL_ACCEPTANCE_NONCOMBAT_FIXTURE+BATTLE_PRESENTATION_SEALED')
        text=text.gsub(/\r?\nVXRD_ACCEPTANCE_NONCOMBAT_V10635_BEGIN.*?VXRD_ACCEPTANCE_NONCOMBAT_V10635_END\r?\n/m,"\r\n")
        s=vxrd_final_acceptance_state_v10634 || {}
        lines=[]
        lines << ''
        lines << 'VXRD_ACCEPTANCE_NONCOMBAT_V10635_BEGIN'
        lines << 'VXRD_ACCEPTANCE_FIXTURE=H12'
        lines << 'VXRD_ACCEPTANCE_COMBAT=DISABLED'
        lines << 'VXRD_ACCEPTANCE_H12_CLEAR_REQUIRED=0'
        lines << 'VXRD_ACCEPTANCE_PARTY_POWER_REQUIRED=0'
        lines << 'VXRD_ACCEPTANCE_USER_ACTION=ONE_REAL_SAVE_THEN_LOAD'
        lines << 'VXRD_ACCEPTANCE_STATE='+((s[:overall]||:pending).to_s.upcase)
        lines << 'VXRD_ACCEPTANCE_NONCOMBAT_V10635_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
