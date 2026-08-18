# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Focus Source-KO Delivery Cancellation Reconciliation v1.06.22
#-------------------------------------------------------------------------------
# A post-lock delivery that never launches because its caster is KO'd before
# commit is a legitimate cancellation, not a missing projectile/damage warning.
# Observer-only. No Damage / AI / projectile timing / Spatial changes.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusSourceKOCancelReconciliation_v10622']=true

class Scene_PMD_AutoChess
  alias pmd_ac_v10622_start_battle start_battle unless method_defined?(:pmd_ac_v10622_start_battle)
  alias pmd_ac_v10622_v10617_tick_pending v10617_tick_pending unless method_defined?(:pmd_ac_v10622_v10617_tick_pending)
  alias pmd_ac_v10622_v10617_summary v10617_summary unless method_defined?(:pmd_ac_v10622_v10617_summary)

  def start_battle
    @v10622_source_ko_cancel=0
    @v10622_summary_logged=false
    pmd_ac_v10622_start_battle
  end

  def v10622_unit_dead?(u)
    return false if u==nil
    begin
      return u.dead? ? true : false if u.respond_to?(:dead?)
    rescue
    end
    begin
      return u.hp.to_i<=0 if u.respond_to?(:hp)
    rescue
    end
    false
  end

  def v10622_cancel_source_ko_pending(p)
    return false if p==nil || p[:done]
    ctx=p[:ctx] || {}
    # Once a post-lock projectile/commit exists, let v1.06.17 keep reconciling;
    # an already-launched projectile may still land after its source is KO'd.
    return false if p[:late_commit]
    return false if p[:late_projectile].to_i>0
    return false if ctx[:projectiles].to_i>0 || ctx[:projectile_objects].to_i>0
    user=ctx[:user]
    return false unless v10622_unit_dead?(user)
    @v10622_source_ko_cancel=@v10622_source_ko_cancel.to_i+1
    log_event(:battle,'BATTLE_FOCUS_WORLD_ACTIVE_RECONCILIATION_V10622 move='+ctx[:move].to_s+
      ' family='+ctx[:family].to_s+' outcome=source_ko_cancel'+
      ' active_frames_used='+(PMD_AC::FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617-p[:remaining].to_i).to_s+
      ' paused_focus_frames='+p[:paused].to_i.to_s+
      ' missing_damage='+(p[:missing_damage] ? '1':'0')+
      ' missing_projectile='+(p[:missing_projectile] ? '1':'0')+
      ' observer_warning=0 gameplay_change=0')
    p[:done]=true
    v10617_pending_list.delete(p)
    true
  rescue
    false
  end

  def v10617_tick_pending
    begin
      v10617_pending_list.dup.each do |p|
        next if p==nil || p[:done]
        v10622_cancel_source_ko_pending(p)
      end
    rescue
    end
    pmd_ac_v10622_v10617_tick_pending
  end

  def v10622_summary
    return false if @v10622_summary_logged
    @v10622_summary_logged=true
    log_event(:battle,'BATTLE_FOCUS_SOURCE_KO_CANCEL_SUMMARY_V10622 pass=1 source_ko_cancel='+
      @v10622_source_ko_cancel.to_i.to_s+
      ' already_launched_projectile_not_cancelled=1 observer_only=1 gameplay_change=0')
    true
  rescue
    false
  end

  def v10617_summary
    r=pmd_ac_v10622_v10617_summary
    v10622_summary
    r
  rescue
    false
  end
end
