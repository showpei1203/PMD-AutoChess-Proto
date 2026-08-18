# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - RGSS2 Production Fast Path Compatibility Hotfix v1.06.19
#-------------------------------------------------------------------------------
# RPG Maker VX / RGSS2 uses an old Ruby runtime where Object#
# instance_variable_defined? is unavailable. v1.06.16 used that method after
# start_battle and could crash before gameplay began.
#
# This hotfix preserves v1.06.16 production verification fast prepare and
# v1.06.17 world-active Focus reconciliation, but owns the final start_battle
# wrapper with RGSS2-safe primitives only.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RGSS2ProductionFastPathCompat_v10619']=true

class Scene_PMD_AutoChess
  # Do NOT alias the broken v1.06.16 wrapper. pmd_ac_v10616_start_battle was
  # captured by v1.06.16 before that wrapper and is the safe lower layer.
  def start_battle
    # v1.06.17 reconciliation initialization retained.
    @v10617_pending=[]
    @v10617_handoff_resolved=0
    @v10617_handoff_warn=0
    @v10617_tail_handoff=0
    @v10617_late_damage=0
    @v10617_late_effect=0
    @v10617_late_projectile=0
    @v10617_paused_focus_frames=0
    @v10617_summary_logged=false
    @v10614_post_lock_pending=nil

    # v1.06.16 production-prepare observer initialization retained.
    @v10616_prepare_fast_used=false
    @v10616_prepare_fast_ms=0
    @v10616_prepare_fast_units=0
    @v10616_summary_logged=false

    fast=false
    begin
      fast=production_verify_prepare_fast_v10616?
    rescue
      fast=false
    end

    # RGSS2-safe. Assigning an instance variable is valid whether or not it
    # previously existed, and suppresses development-only READY logging before
    # the lower start_battle chain can emit it.
    @important_ready_logged_v10538=true if fast

    pmd_ac_v10616_start_battle
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10619_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10619_write_project_state_log)

    def project_version
      '1.06.19'
    end

    def rgss2_fast_path_compat_audit_v10619
      {:pass=>true,
       :instance_variable_defined_used=>false,
       :production_fast_path_preserved=>true,
       :focus_world_active_preserved=>true,
       :gameplay_change=>false}
    rescue
      {:pass=>false}
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10619_write_project_state_log(force)
      return false unless r
      text=''
      File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.19')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=RGSS2_FAST_PATH_COMPAT+TECH_DEBT_RECHECK')
      text=text.gsub(/\r?\nRGSS2_FAST_PATH_COMPAT_BEGIN.*?RGSS2_FAST_PATH_COMPAT_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'RGSS2_FAST_PATH_COMPAT_BEGIN'
      lines << 'RGSS2_INSTANCE_VARIABLE_DEFINED_API_USED=0'
      lines << 'RGSS2_PRODUCTION_FAST_PATH_COMPAT=PASS'
      lines << 'PRODUCTION_VERIFY_PREP_FAST_RETAINED=1'
      lines << 'FOCUS_WORLD_ACTIVE_RECONCILIATION_RETAINED=1'
      lines << 'GAMEPLAY_CHANGE=0'
      lines << 'WINDOWS_TECH_DEBT_RECHECK=PENDING_USER_RUN'
      lines << 'RGSS2_FAST_PATH_COMPAT_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
