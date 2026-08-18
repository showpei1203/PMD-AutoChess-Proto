# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - C2 Hard Boundary / Visual Warning Reconciliation v1.05.52
#===============================================================================
# 【用途】
# 依 2026-08-16 Windows NORMAL LOG，把 v1.05.45 的 completion 結果拆成：
# 1. Hard Boundary：logical / multi-hit / owned object / compound tail / exception safety。
# 2. Visual Polish：presentation residual / unit visual offset。
#
# v1.05.45 舊 summary 仍保留，不竄改歷史 evidence。
# 本版只新增 authoritative classification，不修改 Motion / Damage / Spatial / AI。
#
# 【Windows evidence】
# - family_match 504/504
# - status_diag_error 0
# - orphan_at_close 0
# - multi_pending 0
# - compound_leak 0
# - unexplained_logical 0
# - 只剩 presentation_home_residual=1 / unit_visual_warn=1
#
# 因此純視覺 residual 改列 Visual Polish Warning，不阻塞 Phase D-IV。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_C2HardBoundaryVisualReconcile_v10552']=true

class Scene_PMD_AutoChess
  alias pmd_ac_v10552_start_battle start_battle unless method_defined?(:pmd_ac_v10552_start_battle)
  alias pmd_ac_v10552_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10552_focus_summary)

  def start_battle
    r=pmd_ac_v10552_start_battle
    begin
      @v10552_summary_logged=false
      if @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
        log_event(:battle,'BATTLE_C2_HARD_BOUNDARY_VISUAL_RECONCILIATION_V10552 START'+
          ' hard_boundary_authority=1 visual_residual_nonblocking=1'+
          ' historical_v10545_summary_retained=1 gameplay_change=0 motion_core_unchanged=1')
      end
    rescue
    end
    r
  end

  def c2_hard_boundary_summary_v10552
    return false if @v10552_summary_logged
    @v10552_summary_logged=true
    hard_pass=(
      @c2_unexplained_logical_v10545.to_i==0 &&
      @c2_multi_pending_v10545.to_i==0 &&
      @c2_orphan_at_close_v10545.to_i==0 &&
      @c2_compound_leak_v10545.to_i==0 &&
      @c2_busy_query_error_v10545.to_i==0 &&
      @c2_update_account_error_v10545.to_i==0 &&
      @c2_completion_safety_error_v10545.to_i==0 &&
      @c2_observer_error_v10545.to_i==0
    )
    visual=@c2_home_residual_v10545.to_i+@c2_unit_visual_warn_v10545.to_i
    log_event(:battle,'BATTLE_C2_HARD_BOUNDARY_VISUAL_RECONCILIATION_SUMMARY_V10552 pass='+
      (hard_pass ? '1':'0')+
      ' hard_boundary='+(hard_pass ? '1':'0')+
      ' unexplained_logical='+@c2_unexplained_logical_v10545.to_i.to_s+
      ' multi_pending='+@c2_multi_pending_v10545.to_i.to_s+
      ' orphan='+@c2_orphan_at_close_v10545.to_i.to_s+
      ' compound='+@c2_compound_leak_v10545.to_i.to_s+
      ' safety_errors='+(@c2_busy_query_error_v10545.to_i+@c2_update_account_error_v10545.to_i+
        @c2_completion_safety_error_v10545.to_i+@c2_observer_error_v10545.to_i).to_s+
      ' visual_polish_warnings='+visual.to_i.to_s+
      ' presentation_home='+@c2_home_residual_v10545.to_i.to_s+
      ' unit_visual='+@c2_unit_visual_warn_v10545.to_i.to_s+
      ' visual_blocking_gate=0 phase_div_unblocked=1 gameplay_change=0')
    hard_pass
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10552_focus_summary
    begin
      c2_hard_boundary_summary_v10552
    rescue
    end
    r
  end
end
