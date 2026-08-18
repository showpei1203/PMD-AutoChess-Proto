# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Battle Presentation Acceptance Seal v1.06.33
#-------------------------------------------------------------------------------
#  1. Extends the already-accepted Battle Complete cue from 36f to 48f.
#  2. Seals the v1.06.31-v1.06.32 Battle Presentation visual pass based on
#     Windows user acceptance on 2026-08-17.
#  3. Returns NEXT_TARGET to VXRD Windows Integrated Acceptance.
#-------------------------------------------------------------------------------
#  Presentation-only. AI choice, damage, attack speed and spatial endpoints are
#  intentionally unchanged.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BattlePresentationAcceptanceSeal_v10633']=true

module PMD_AC
  # v1.06.32 timing was visually accepted; only lengthen the cue hold slightly.
  remove_const(:BATTLE_END_CUE_FRAMES_V10631) if const_defined?(:BATTLE_END_CUE_FRAMES_V10631)
  BATTLE_END_CUE_FRAMES_V10631 = 48

  class << self
    alias pmd_ac_v10633_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10633_write_project_state_log)

    def project_version
      '1.06.33'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10633_write_project_state_log(force)
      return false unless r
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=21')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.33')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=BATTLE_PRESENTATION_ACCEPTANCE_SEAL+HUNT_UNLOCK_RETREAT')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub('BATTLE_PRESENTATION_WINDOWS_ACCEPTANCE=PENDING_USER_RUN','BATTLE_PRESENTATION_WINDOWS_ACCEPTANCE=PASS_USER_VISUAL_20260817')
      text=text.gsub('BATTLE_PRESENTATION_POLISH_WINDOWS_ACCEPTANCE=PENDING_USER_RUN','BATTLE_PRESENTATION_POLISH_WINDOWS_ACCEPTANCE=PASS_USER_VISUAL_20260817')
      text=text.gsub(/\r?\nBATTLE_PRESENTATION_ACCEPTANCE_V10633_BEGIN.*?BATTLE_PRESENTATION_ACCEPTANCE_V10633_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'BATTLE_PRESENTATION_ACCEPTANCE_V10633_BEGIN'
      lines << 'WINDOWS_USER_VISUAL_ACCEPTANCE=PASS'
      lines << 'WINDOWS_USER_VISUAL_ACCEPTANCE_DATE=2026-08-17'
      lines << 'CARRIED_FAINT_PRESENTATION=PASS'
      lines << 'RESULT_CHROME_CLEANUP=PASS'
      lines << 'SIDE_TEAM_HUD_READABILITY=PASS'
      lines << 'BATTLE_FINISH_EVENT_DRIVEN=PASS'
      lines << 'BATTLE_FINISH_MIN_DRAIN_FRAMES='+BATTLE_FINISH_MIN_DRAIN_V10631.to_s
      lines << 'BATTLE_END_CUE_FRAMES='+BATTLE_END_CUE_FRAMES_V10631.to_s
      lines << 'BATTLE_END_CUE_SECONDS_60FPS=0.80'
      lines << 'BATTLE_SETTLEMENT_HANDOFF_TIMING_LOG=RETAINED'
      lines << 'BATTLE_PRESENTATION_GAMEPLAY_CHANGE=0'
      lines << 'BATTLE_PRESENTATION_STATUS=SEALED_ISSUE_DRIVEN_ONLY'
      lines << 'NEXT_GATE=VXRD_WINDOWS_INTEGRATED_ACCEPTANCE'
      lines << 'BATTLE_PRESENTATION_ACCEPTANCE_V10633_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
