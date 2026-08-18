# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Focus Post-Lock Delivery Reconciliation v1.06.14
#-------------------------------------------------------------------------------
# NORMAL gameplay may hand a delayed delivery back to the world after Focus lock
# closes. Observer-only reconciliation tracks that handoff for 48f instead of
# immediately reporting false no-commit/no-projectile warnings.
# No gameplay timing, damage, AI, projectile speed, or Spatial behavior changes.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusPostLockDeliveryReconciliation_v10614']=true

module PMD_AC
  FOCUS_POST_LOCK_RECONCILE_FRAMES_V10614=48
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10614_start_battle start_battle unless method_defined?(:pmd_ac_v10614_start_battle)
  alias pmd_ac_v10614_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v10614_apply_skill_effects)
  alias pmd_ac_v10614_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v10614_deal_direct_damage)
  alias pmd_ac_v10614_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10614_launch_projectile)
  alias pmd_ac_v10614_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10614_update_battle_step)
  alias pmd_ac_v10614_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10614_focus_begin)
  alias pmd_ac_v10614_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10614_focus_summary)

  def start_battle
    @v10614_post_lock_pending=nil
    @v10614_handoff_resolved=0
    @v10614_handoff_warn=0
    @v10614_tail_handoff=0
    @v10614_late_damage=0
    @v10614_late_effect=0
    @v10614_late_projectile=0
    @v10614_summary_logged=false
    pmd_ac_v10614_start_battle
  end

  def v10614_pending_match?(user)
    p=@v10614_post_lock_pending
    return false if p==nil || user==nil
    return false unless p[:ctx]!=nil && p[:ctx][:user]==user
    now=Graphics.frame_count.to_i rescue 0
    now<=p[:deadline].to_i
  rescue
    false
  end

  def v10614_note_late(user,kind,created=0)
    return false unless v10614_pending_match?(user)
    p=@v10614_post_lock_pending
    case kind
    when :damage
      p[:late_commit]=true;p[:late_damage]=p[:late_damage].to_i+1
      @v10614_late_damage=@v10614_late_damage.to_i+1
    when :effect
      p[:late_commit]=true;p[:late_effect]=p[:late_effect].to_i+1
      @v10614_late_effect=@v10614_late_effect.to_i+1
    when :projectile
      p[:late_projectile]=p[:late_projectile].to_i+1
      p[:late_projectile_objects]=p[:late_projectile_objects].to_i+created.to_i
      @v10614_late_projectile=@v10614_late_projectile.to_i+1
    end
    v10614_finish_pending(false)
    true
  rescue
    false
  end

  def v10614_pending_resolved?(p)
    return false if p==nil
    damage_ok=!p[:missing_damage] || p[:late_commit]
    # A real post-lock commit proves the projectile-delivery action resolved even
    # when the legacy path does not instantiate Scene#launch_projectile.
    projectile_ok=!p[:missing_projectile] || p[:late_projectile].to_i>0 || p[:late_commit]
    damage_ok && projectile_ok
  rescue
    false
  end

  def v10614_finish_pending(force=false)
    p=@v10614_post_lock_pending
    return false if p==nil
    now=Graphics.frame_count.to_i rescue 0
    return false unless force || v10614_pending_resolved?(p) || now>p[:deadline].to_i
    ctx=p[:ctx] || {}
    c=@move_family_runtime_counts_v10541[ctx[:family]] || {}
    resolved=v10614_pending_resolved?(p)
    if resolved
      if p[:missing_damage] && p[:late_commit]
        c[:impacts]=c[:impacts].to_i+1
      end
      if p[:missing_projectile] && p[:late_projectile_objects].to_i>0
        c[:projectiles]=c[:projectiles].to_i+p[:late_projectile_objects].to_i
      end
      @move_family_runtime_counts_v10541[ctx[:family]]=c
      @v10614_handoff_resolved=@v10614_handoff_resolved.to_i+1
      log_event(:battle,'BATTLE_FOCUS_POST_LOCK_RECONCILIATION_V10614 move='+ctx[:move].to_s+
        ' family='+ctx[:family].to_s+' outcome=handoff'+
        ' late_damage='+p[:late_damage].to_i.to_s+' late_effect='+p[:late_effect].to_i.to_s+
        ' late_projectile='+p[:late_projectile].to_i.to_s+
        ' age='+(now-p[:closed_frame].to_i).to_s+
        ' gameplay_change=0')
    else
      if p[:missing_damage]
        move_family_runtime_note_warn_v10541(ctx,'no_damage_commit_observed')
      end
      if p[:missing_projectile]
        move_family_runtime_note_warn_v10541(ctx,'logical_projectile_no_launch')
      end
      @v10614_handoff_warn=@v10614_handoff_warn.to_i+1
      log_event(:battle,'BATTLE_FOCUS_POST_LOCK_RECONCILIATION_V10614 move='+ctx[:move].to_s+
        ' family='+ctx[:family].to_s+' outcome=unresolved'+
        ' missing_damage='+(p[:missing_damage] ? '1':'0')+
        ' missing_projectile='+(p[:missing_projectile] ? '1':'0')+
        ' window='+PMD_AC::FOCUS_POST_LOCK_RECONCILE_FRAMES_V10614.to_s+
        ' observer_warning=1 gameplay_change=0')
    end
    @move_family_runtime_counts_v10541[ctx[:family]]=c
    @v10614_post_lock_pending=nil
    true
  rescue
    @v10614_post_lock_pending=nil
    false
  end

  # v1.05.48 accounting retained; only ambiguous warnings are deferred.
  def move_family_runtime_finalize_v10541(ctx,reason,snap)
    active=snap[:active] || [0,0]
    hard=(reason==:v1058_timeout || active[0].to_i>0)
    immediate=[]
    missing_damage=(ctx[:damaging] && ctx[:impacts].to_i<=0)
    missing_projectile=(ctx[:delivery]==:projectile && ctx[:projectiles].to_i<=0)
    if ctx[:family]==:multi_hit && ctx[:impacts].to_i<2
      immediate.push('multi_hit_commit_lt2')
    end
    tail_handoff=(active[1].to_i>0 && active[0].to_i<=0 && snap[:effect_tail].to_i>0)
    if active[1].to_i>0 && !tail_handoff
      immediate.push('effect_active_at_complete')
    elsif tail_handoff
      @v10614_tail_handoff=@v10614_tail_handoff.to_i+1
      log_event(:battle,'BATTLE_FOCUS_VISUAL_TAIL_HANDOFF_V10614 move='+ctx[:move].to_s+
        ' family='+ctx[:family].to_s+' active_effect='+active[1].to_i.to_s+
        ' effect_tail='+snap[:effect_tail].to_i.to_s+' owned_projectile=0 gameplay_change=0')
    end

    c=@move_family_runtime_counts_v10541[ctx[:family]] || {}
    c[:complete]=c[:complete].to_i+1
    c[:projectiles]=c[:projectiles].to_i+ctx[:projectile_objects].to_i
    c[:impacts]=c[:impacts].to_i+ctx[:impacts].to_i
    c[:max_total]=snap[:total].to_i if snap[:total].to_i>c[:max_total].to_i
    c[:max_project_wait]=snap[:project_wait].to_i if snap[:project_wait].to_i>c[:max_project_wait].to_i
    c[:max_effect_tail]=snap[:effect_tail].to_i if snap[:effect_tail].to_i>c[:max_effect_tail].to_i
    if hard
      c[:hard_fail]=c[:hard_fail].to_i+1
      @move_family_runtime_hard_fail_v10541=@move_family_runtime_hard_fail_v10541.to_i+1
    end
    @move_family_runtime_counts_v10541[ctx[:family]]=c
    immediate.each{|w|move_family_runtime_note_warn_v10541(ctx,w)}

    pending=(missing_damage || missing_projectile)
    if pending
      now=Graphics.frame_count.to_i rescue 0
      @v10614_post_lock_pending={:ctx=>ctx,:missing_damage=>missing_damage,
        :missing_projectile=>missing_projectile,:closed_frame=>now,
        :deadline=>now+PMD_AC::FOCUS_POST_LOCK_RECONCILE_FRAMES_V10614,
        :late_commit=>false,:late_damage=>0,:late_effect=>0,
        :late_projectile=>0,:late_projectile_objects=>0}
    end

    log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_CAST_V10541 COMPLETE family='+ctx[:family].to_s+
      ' move='+ctx[:move].to_s+' delivery='+(ctx[:delivery]||:unknown).to_s+
      ' reason='+reason.to_s+' total_frames='+snap[:total].to_i.to_s+
      ' impacts='+ctx[:impacts].to_s+' projectile_calls='+ctx[:projectiles].to_s+
      ' projectile_created='+ctx[:projectile_objects].to_s+' release_to_first_impact='+snap[:release_to_impact].to_i.to_s+
      ' last_impact_to_complete='+snap[:impact_to_complete].to_i.to_s+' projectile_wait='+snap[:project_wait].to_i.to_s+
      ' effect_tail='+snap[:effect_tail].to_i.to_s+' slide_wait='+snap[:slide_wait].to_i.to_s+
      ' orphan_projectile='+active[0].to_i.to_s+' active_effect_at_complete='+active[1].to_i.to_s+
      ' logical_drift_observed='+snap[:drift].to_i.to_s+' hard_fail='+(hard ? '1':'0')+
      ' warn=['+immediate.join(',')+'] post_lock_pending='+(pending ? '1':'0')+
      ' observer_only=1 actual_lock_complete=1 v10614=1')
    true
  rescue
    false
  end

  def apply_skill_effects(*args)
    user=(args[0] rescue nil)
    r=pmd_ac_v10614_apply_skill_effects(*args)
    v10614_note_late(user,:effect) unless @focus_cast_lock_active_v1055
    r
  end

  def deal_direct_damage(*args)
    user=(args[0] rescue nil)
    r=pmd_ac_v10614_deal_direct_damage(*args)
    v10614_note_late(user,:damage) unless @focus_cast_lock_active_v1055
    r
  end

  def launch_projectile(*args)
    user=(args[0] rescue nil)
    before=(@projectile_sprites || []).size rescue 0
    r=pmd_ac_v10614_launch_projectile(*args)
    after=(@projectile_sprites || []).size rescue before
    v10614_note_late(user,:projectile,[after-before,0].max) unless @focus_cast_lock_active_v1055
    r
  end

  def focus_cast_begin_v1055(user,target)
    v10614_finish_pending(true) if @v10614_post_lock_pending!=nil
    pmd_ac_v10614_focus_begin(user,target)
  end

  def update_battle_step
    r=pmd_ac_v10614_update_battle_step
    v10614_finish_pending(false) if @v10614_post_lock_pending!=nil
    r
  end

  def v10614_summary
    return false if @v10614_summary_logged
    @v10614_summary_logged=true
    log_event(:battle,'BATTLE_FOCUS_POST_LOCK_RECONCILIATION_SUMMARY_V10614 pass='+
      (@v10614_handoff_warn.to_i==0 ? '1':'0')+
      ' resolved_handoff='+@v10614_handoff_resolved.to_i.to_s+
      ' unresolved='+@v10614_handoff_warn.to_i.to_s+
      ' visual_tail_handoff='+@v10614_tail_handoff.to_i.to_s+
      ' late_damage='+@v10614_late_damage.to_i.to_s+
      ' late_effect='+@v10614_late_effect.to_i.to_s+
      ' late_projectile='+@v10614_late_projectile.to_i.to_s+
      ' window='+PMD_AC::FOCUS_POST_LOCK_RECONCILE_FRAMES_V10614.to_s+
      ' observer_only=1 gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    v10614_finish_pending(true) if @v10614_post_lock_pending!=nil
    r=pmd_ac_v10614_focus_summary
    v10614_summary
    r
  rescue
    false
  end
end
