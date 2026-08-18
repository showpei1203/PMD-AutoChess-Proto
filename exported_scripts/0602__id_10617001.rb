# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Focus World-Active Reconciliation Queue v1.06.17
#-------------------------------------------------------------------------------
# v1.06.14 used one Graphics-frame deadline and force-closed it when the next
# Focus began. A delayed delivery can legitimately be frozen by another Focus.
# This version owns a queue and counts only world-active reconciliation frames.
# Observer-only. No gameplay timing / Damage / AI / Spatial changes.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusWorldActiveReconciliationQueue_v10617']=true

module PMD_AC
  FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617=48
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10617_start_battle start_battle unless method_defined?(:pmd_ac_v10617_start_battle)
  alias pmd_ac_v10617_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v10617_apply_skill_effects)
  alias pmd_ac_v10617_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v10617_deal_direct_damage)
  alias pmd_ac_v10617_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10617_launch_projectile)
  alias pmd_ac_v10617_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10617_update_battle_step)
  alias pmd_ac_v10617_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10617_focus_summary)

  def start_battle
    @v10617_pending=[]
    @v10617_handoff_resolved=0
    @v10617_handoff_warn=0
    @v10617_tail_handoff=0
    @v10617_late_damage=0
    @v10617_late_effect=0
    @v10617_late_projectile=0
    @v10617_paused_focus_frames=0
    @v10617_summary_logged=false
    # Disable the v1.06.14 singleton path. v1.06.17 is authoritative.
    @v10614_post_lock_pending=nil
    pmd_ac_v10617_start_battle
  end

  def v10617_pending_list
    @v10617_pending=[] if @v10617_pending==nil
    @v10617_pending
  end

  def v10617_match_pending(user)
    return nil if user==nil
    v10617_pending_list.each do |p|
      next if p==nil || p[:done]
      ctx=p[:ctx]
      next if ctx==nil || ctx[:user]!=user
      return p if p[:remaining].to_i>0
    end
    nil
  rescue
    nil
  end

  def v10617_pending_resolved?(p)
    return false if p==nil
    damage_ok=!p[:missing_damage] || p[:late_commit]
    projectile_ok=!p[:missing_projectile] || p[:late_projectile].to_i>0 || p[:late_commit]
    damage_ok && projectile_ok
  rescue
    false
  end

  def v10617_note_late(user,kind,created=0)
    p=v10617_match_pending(user)
    return false if p==nil
    case kind
    when :damage
      p[:late_commit]=true
      p[:late_damage]=p[:late_damage].to_i+1
      @v10617_late_damage=@v10617_late_damage.to_i+1
    when :effect
      p[:late_commit]=true
      p[:late_effect]=p[:late_effect].to_i+1
      @v10617_late_effect=@v10617_late_effect.to_i+1
    when :projectile
      p[:late_projectile]=p[:late_projectile].to_i+1
      p[:late_projectile_objects]=p[:late_projectile_objects].to_i+created.to_i
      @v10617_late_projectile=@v10617_late_projectile.to_i+1
    end
    v10617_finish_one(p,false) if v10617_pending_resolved?(p)
    true
  rescue
    false
  end

  def v10617_finish_one(p,force=false)
    return false if p==nil || p[:done]
    return false unless force || v10617_pending_resolved?(p) || p[:remaining].to_i<=0
    ctx=p[:ctx] || {}
    c=@move_family_runtime_counts_v10541[ctx[:family]] || {}
    resolved=v10617_pending_resolved?(p)
    if resolved
      c[:impacts]=c[:impacts].to_i+1 if p[:missing_damage] && p[:late_commit]
      if p[:missing_projectile] && p[:late_projectile_objects].to_i>0
        c[:projectiles]=c[:projectiles].to_i+p[:late_projectile_objects].to_i
      end
      @move_family_runtime_counts_v10541[ctx[:family]]=c
      @v10617_handoff_resolved=@v10617_handoff_resolved.to_i+1
      log_event(:battle,'BATTLE_FOCUS_WORLD_ACTIVE_RECONCILIATION_V10617 move='+ctx[:move].to_s+
        ' family='+ctx[:family].to_s+' outcome=handoff'+
        ' late_damage='+p[:late_damage].to_i.to_s+' late_effect='+p[:late_effect].to_i.to_s+
        ' late_projectile='+p[:late_projectile].to_i.to_s+
        ' active_frames_used='+(PMD_AC::FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617-p[:remaining].to_i).to_s+
        ' paused_focus_frames='+p[:paused].to_i.to_s+' gameplay_change=0')
    else
      move_family_runtime_note_warn_v10541(ctx,'no_damage_commit_observed') if p[:missing_damage]
      move_family_runtime_note_warn_v10541(ctx,'logical_projectile_no_launch') if p[:missing_projectile]
      @v10617_handoff_warn=@v10617_handoff_warn.to_i+1
      log_event(:battle,'BATTLE_FOCUS_WORLD_ACTIVE_RECONCILIATION_V10617 move='+ctx[:move].to_s+
        ' family='+ctx[:family].to_s+' outcome=unresolved'+
        ' missing_damage='+(p[:missing_damage] ? '1':'0')+
        ' missing_projectile='+(p[:missing_projectile] ? '1':'0')+
        ' active_window='+PMD_AC::FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617.to_s+
        ' paused_focus_frames='+p[:paused].to_i.to_s+' observer_warning=1 gameplay_change=0')
    end
    @move_family_runtime_counts_v10541[ctx[:family]]=c
    p[:done]=true
    v10617_pending_list.delete(p)
    true
  rescue
    p[:done]=true if p!=nil
    v10617_pending_list.delete(p) rescue nil
    false
  end

  def v10617_tick_pending
    list=v10617_pending_list.dup
    return if list.empty?
    locked=(@focus_cast_lock_active_v1055 ? true:false) rescue false
    list.each do |p|
      next if p==nil || p[:done]
      if locked
        p[:paused]=p[:paused].to_i+1
        @v10617_paused_focus_frames=@v10617_paused_focus_frames.to_i+1
        next
      end
      now=Graphics.frame_count.to_i rescue 0
      next if p[:last_tick_frame].to_i==now
      p[:last_tick_frame]=now
      p[:remaining]=p[:remaining].to_i-1
      v10617_finish_one(p,false) if p[:remaining].to_i<=0
    end
  rescue
  end

  # v1.05.48 accounting retained; v1.06.17 owns ambiguous warning deferral.
  def move_family_runtime_finalize_v10541(ctx,reason,snap)
    active=snap[:active] || [0,0]
    hard=(reason==:v1058_timeout || active[0].to_i>0)
    immediate=[]
    missing_damage=(ctx[:damaging] && ctx[:impacts].to_i<=0)
    missing_projectile=(ctx[:delivery]==:projectile && ctx[:projectiles].to_i<=0)
    immediate.push('multi_hit_commit_lt2') if ctx[:family]==:multi_hit && ctx[:impacts].to_i<2
    tail_handoff=(active[1].to_i>0 && active[0].to_i<=0 && snap[:effect_tail].to_i>0)
    if active[1].to_i>0 && !tail_handoff
      immediate.push('effect_active_at_complete')
    elsif tail_handoff
      @v10617_tail_handoff=@v10617_tail_handoff.to_i+1
      log_event(:battle,'BATTLE_FOCUS_VISUAL_TAIL_HANDOFF_V10617 move='+ctx[:move].to_s+
        ' family='+ctx[:family].to_s+' active_effect='+active[1].to_i.to_s+
        ' effect_tail='+snap[:effect_tail].to_i.to_s+' gameplay_change=0')
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
      v10617_pending_list.push({:ctx=>ctx,:missing_damage=>missing_damage,
        :missing_projectile=>missing_projectile,:remaining=>PMD_AC::FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617,
        :last_tick_frame=>now,:paused=>0,:late_commit=>false,:late_damage=>0,
        :late_effect=>0,:late_projectile=>0,:late_projectile_objects=>0,:done=>false})
      @v10614_post_lock_pending=nil
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
      ' observer_only=1 actual_lock_complete=1 v10617=1')
    true
  rescue
    false
  end

  def apply_skill_effects(*args)
    user=(args[0] rescue nil)
    r=pmd_ac_v10617_apply_skill_effects(*args)
    v10617_note_late(user,:effect) unless (@focus_cast_lock_active_v1055 rescue false)
    r
  end

  def deal_direct_damage(*args)
    user=(args[0] rescue nil)
    r=pmd_ac_v10617_deal_direct_damage(*args)
    v10617_note_late(user,:damage) unless (@focus_cast_lock_active_v1055 rescue false)
    r
  end

  def launch_projectile(*args)
    user=(args[0] rescue nil)
    before=(@projectile_sprites || []).size rescue 0
    r=pmd_ac_v10617_launch_projectile(*args)
    after=(@projectile_sprites || []).size rescue before
    v10617_note_late(user,:projectile,[after-before,0].max) unless (@focus_cast_lock_active_v1055 rescue false)
    r
  end

  def update_battle_step
    r=pmd_ac_v10617_update_battle_step
    @v10614_post_lock_pending=nil
    v10617_tick_pending
    r
  end

  def v10617_finish_all
    v10617_pending_list.dup.each{|p|v10617_finish_one(p,true)}
  rescue
  end

  def v10617_summary
    return false if @v10617_summary_logged
    @v10617_summary_logged=true
    log_event(:battle,'BATTLE_FOCUS_WORLD_ACTIVE_RECONCILIATION_SUMMARY_V10617 pass='+
      (@v10617_handoff_warn.to_i==0 ? '1':'0')+
      ' resolved_handoff='+@v10617_handoff_resolved.to_i.to_s+
      ' unresolved='+@v10617_handoff_warn.to_i.to_s+
      ' visual_tail_handoff='+@v10617_tail_handoff.to_i.to_s+
      ' late_damage='+@v10617_late_damage.to_i.to_s+
      ' late_effect='+@v10617_late_effect.to_i.to_s+
      ' late_projectile='+@v10617_late_projectile.to_i.to_s+
      ' paused_focus_frames='+@v10617_paused_focus_frames.to_i.to_s+
      ' active_window='+PMD_AC::FOCUS_POST_LOCK_ACTIVE_FRAMES_V10617.to_s+
      ' clock=world_active observer_only=1 gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    v10617_finish_all
    @v10614_post_lock_pending=nil
    r=pmd_ac_v10617_focus_summary
    v10617_summary
    r
  rescue
    false
  end
end
