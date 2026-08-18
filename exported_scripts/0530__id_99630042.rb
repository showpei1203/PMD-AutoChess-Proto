# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - C2 Completion Boundary Seal v1.05.45
#===============================================================================
# 【用途】
# Roadmap C2 Final：將 Move-family / Compound-tail / Multi-hit / Dash-return 的
# completion boundary 收斂成可長期維護的 contract。
#
# 1. logical displacement 與 presentation return 分離：
#    - Spatial Runtime 合法改變 pixel_x / pixel_y 時，記為 logical displacement。
#    - Presentation 是否回 HOME，改看 presentation_sprite_offset_v055，而不是拿 cast
#      開始座標當 HOME。HOME = completion 當下的 current logical/action anchor。
# 2. 實際 Tactical Slide 成功後記錄 serial/reason，只做 observer，不改位移。
# 3. Multi-hit / owned projectile/effect / compound semantic release 在真正 lock close 前
#    必須清空；本版補統一 completion snapshot 與 summary。
# 4. v1.05.43 owner_busy query 例外改 fail-closed，避免 query error 被誤認為 idle。
# 5. v1.05.43 update-lock accounting 例外不得跳過正式 parent update。
# 6. v1.05.13 Result Hold completion 改成 parent exactly once，18f hold 規則不變。
#
# 【不修改】
# Damage / HP / Accuracy / Crit / target / Energy / Priority / Attack Wait /
# projectile speed / tracking / collision / multi-hit cadence / Spatial endpoint /
# Motion Core / PMD pose selection。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_C2CompletionBoundarySeal_v10545']=true

module PMD_AC
  C2_PRESENTATION_HOME_EPS_V10545=1.0
  C2_UNIT_VISUAL_OFFSET_WARN_V10545=2.0
  C2_LOGICAL_DISPLACEMENT_EPS_V10545=1.0
  C2_NATIVE_USER_SPATIAL_TYPES_V10545=[:dash_user,:blink_user,:swap_position]
end

class Game_PMDChessUnit
  alias pmd_ac_v10545_tactical_slide begin_tactical_slide_vector_v0914 unless method_defined?(:pmd_ac_v10545_tactical_slide)

  # Observer only. Parent executes exactly once; note failure cannot replay movement.
  def begin_tactical_slide_vector_v0914(dx,dy,distance,frames,reason=:passive)
    r=pmd_ac_v10545_tactical_slide(dx,dy,distance,frames,reason)
    begin
      if r
        @c2_slide_serial_v10545=@c2_slide_serial_v10545.to_i+1
        @c2_slide_reason_v10545=reason
        @c2_slide_frame_v10545=(Graphics.frame_count.to_i rescue -1)
      end
    rescue
    end
    r
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10545_start_battle start_battle unless method_defined?(:pmd_ac_v10545_start_battle)
  alias pmd_ac_v10545_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10545_focus_begin)
  alias pmd_ac_v10545_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10545_focus_summary)

  #--------------------------------------------------------------------------
  # ● v1.05.13 safe completion seam used inside the v1.05.22 body.
  #   Replacing this alias seam preserves Result Hold semantics without parent replay.
  #--------------------------------------------------------------------------
  def pmd_ac_v10522_focus_complete(reason)
    unless reason==:skill_visual_complete
      @result_hold_active_v10513=false
      @result_hold_start_frame_v10513=-1
      return pmd_ac_v10513_result_focus_complete(reason)
    end

    unless @result_hold_active_v10513
      begin
        result_feedback_begin_hold_v10513
      rescue
        @c2_completion_safety_error_v10545=@c2_completion_safety_error_v10545.to_i+1
      end
      return false
    end

    age=(Graphics.frame_count.to_i rescue 0)-@result_hold_start_frame_v10513.to_i
    return false if age<PMD_AC::RESULT_IMPACT_HOLD_FRAMES_V10513

    @result_hold_total_frames_v10513=@result_hold_total_frames_v10513.to_i+age
    begin
      log_event(:battle,'BATTLE_RESULT_HOLD_V10513 COMPLETE held_frames='+age.to_i.to_s+
        ' owner='+(@focus_cast_owner_v1055==nil ? 'NONE' : @focus_cast_owner_v1055.log_name.to_s))
    rescue
      @c2_completion_safety_error_v10545=@c2_completion_safety_error_v10545.to_i+1
    end
    @result_hold_active_v10513=false
    @result_hold_start_frame_v10513=-1

    # Exactly one formal completion delegation.
    pmd_ac_v10513_result_focus_complete(reason)
  end

  #--------------------------------------------------------------------------
  # ● v1.05.43 safe owner-busy gate.
  #   Query failures fail closed. Existing v1.05.8 timeout remains the escape hatch.
  #--------------------------------------------------------------------------
  def focus_cast_owner_action_busy_v1058?(u)
    begin
      base=pmd_ac_v10543_owner_busy(u)
    rescue
      @c2_busy_query_error_v10545=@c2_busy_query_error_v10545.to_i+1
      return true
    end
    return true if base
    return false if u==nil || u!=@focus_cast_owner_v1055
    begin
      return false unless focus_cast_action_lane_active_v1058?
      return false if @focus_cast_intro_active_v1055
      if focus_compound_tail_active_v10543?
        @focus_compound_tail_busy_seen_v10543=true
        return true
      end
    rescue
      @c2_busy_query_error_v10545=@c2_busy_query_error_v10545.to_i+1
      return true
    end
    false
  end

  # v1.05.43 accounting may fail, but formal update_lock must still run once.
  def focus_cast_update_lock_v1055
    begin
      if @focus_cast_lock_active_v1055 && !@focus_cast_intro_active_v1055 && focus_compound_tail_active_v10543?
        @focus_compound_tail_frames_v10543=@focus_compound_tail_frames_v10543.to_i+1
        @focus_compound_tail_total_frames_v10543=@focus_compound_tail_total_frames_v10543.to_i+1
        if focus_compound_content_active_v10543?
          @focus_compound_content_frames_v10543=@focus_compound_content_frames_v10543.to_i+1
        end
        if focus_compound_semantic_active_v10543?
          @focus_compound_semantic_frames_v10543=@focus_compound_semantic_frames_v10543.to_i+1
        end
      end
    rescue
      @c2_update_account_error_v10545=@c2_update_account_error_v10545.to_i+1
    end
    pmd_ac_v10543_update_lock
  end

  def c2_move_data_v10545(ctx)
    return {} if ctx==nil
    if PMD_AC.respond_to?(:move_family_skill_data_v10541)
      d=PMD_AC.move_family_skill_data_v10541(ctx[:move])
      return d if d!=nil
    end
    u=ctx[:user]
    d=(u!=nil && u.respond_to?(:skill_data)) ? u.skill_data : nil
    d==nil ? {} : d
  rescue
    {}
  end

  def c2_native_user_spatial_v10545(ctx)
    d=c2_move_data_v10545(ctx)
    (d[:effects] || []).each do |e|
      t=e[:type] rescue nil
      next if t==nil
      k=t.to_s.to_sym
      return k if PMD_AC::C2_NATIVE_USER_SPATIAL_TYPES_V10545.include?(k)
    end
    nil
  rescue
    nil
  end

  def c2_configured_spatial_kind_v10545(ctx)
    return nil if ctx==nil
    if PMD_AC.respond_to?(:spatial_extension_unified_v09914)
      e=PMD_AC.spatial_extension_unified_v09914(ctx[:move])
      return e[:kind] if e!=nil
    end
    nil
  rescue
    nil
  end

  def c2_distance_v10545(x,y)
    Math.sqrt(x.to_f*x.to_f+y.to_f*y.to_f)
  rescue
    0.0
  end

  def c2_completion_snapshot_v10545(ctx,owner)
    x0=(ctx==nil ? 0.0 : ctx[:start_x].to_f)
    y0=(ctx==nil ? 0.0 : ctx[:start_y].to_f)
    lx=(owner==nil ? x0 : owner.pixel_x.to_f)
    ly=(owner==nil ? y0 : owner.pixel_y.to_f)
    logical=c2_distance_v10545(lx-x0,ly-y0)

    po=[0.0,0.0]
    begin
      po=owner.presentation_sprite_offset_v055 if owner!=nil && owner.respond_to?(:presentation_sprite_offset_v055)
      po=[0.0,0.0] if po==nil
    rescue
      po=[0.0,0.0]
    end
    presentation=c2_distance_v10545(po[0],po[1])

    vx=0.0;vy=0.0
    begin
      if owner!=nil
        vx=owner.respond_to?(:visual_offset_x) ? owner.visual_offset_x.to_f : owner.instance_variable_get(:@visual_offset_x).to_f
        vy=owner.respond_to?(:visual_offset_y) ? owner.visual_offset_y.to_f : owner.instance_variable_get(:@visual_offset_y).to_f
      end
    rescue
      vx=0.0;vy=0.0
    end
    unit_visual=c2_distance_v10545(vx,vy)

    slide_start=(ctx==nil ? 0 : ctx[:c2_slide_serial_start].to_i)
    slide_now=(owner==nil ? slide_start : owner.instance_variable_get(:@c2_slide_serial_v10545).to_i)
    slide_delta=[slide_now-slide_start,0].max
    slide_reason=(owner==nil ? nil : owner.instance_variable_get(:@c2_slide_reason_v10545))
    native=c2_native_user_spatial_v10545(ctx)
    configured=c2_configured_spatial_kind_v10545(ctx)
    expected=(logical>PMD_AC::C2_LOGICAL_DISPLACEMENT_EPS_V10545 &&
      (slide_delta>0 || native!=nil))

    multi=false
    begin
      multi=focus_cast_owner_multi_active_v1058?(owner) if owner!=nil
    rescue
      multi=false
    end
    active=[0,0]
    begin
      active=move_family_owned_active_counts_v10541 if respond_to?(:move_family_owned_active_counts_v10541)
    rescue
      active=[0,0]
    end

    {:logical=>logical,:presentation=>presentation,:unit_visual=>unit_visual,
     :slide_delta=>slide_delta,:slide_reason=>slide_reason,:native=>native,
     :configured=>configured,:expected=>expected,:multi=>multi,:active=>active}
  rescue
    {:logical=>0.0,:presentation=>0.0,:unit_visual=>0.0,:slide_delta=>0,
     :slide_reason=>nil,:native=>nil,:configured=>nil,:expected=>false,:multi=>false,:active=>[0,0]}
  end

  def focus_cast_begin_v1055(user,target)
    r=pmd_ac_v10545_focus_begin(user,target)
    begin
      if r && @move_family_runtime_current_v10541!=nil && user!=nil
        @move_family_runtime_current_v10541[:c2_slide_serial_start]=user.instance_variable_get(:@c2_slide_serial_v10545).to_i
        @move_family_runtime_current_v10541[:c2_logical_anchor_semantics]=:current_logical_home
      end
    rescue
      @c2_observer_error_v10545=@c2_observer_error_v10545.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● Final completion wrapper.
  #   Bypasses the v1.05.43 wrapper body but preserves its accounting here, then delegates
  #   to the v1.05.42 -> v1.05.41 -> v1.05.44/45 safe chain exactly once.
  #--------------------------------------------------------------------------
  def focus_cast_complete_lock_v1055(reason)
    was_active=(@focus_cast_lock_active_v1055 ? true:false)
    owner=@focus_cast_owner_v1055
    ctx=@move_family_runtime_current_v10541
    # Completion-boundary semantics must be measured AFTER the formal parent has
    # actually closed the lock.  The parent chain may perform the final
    # presentation return-to-HOME; sampling before it would create a false drift.
    before_content=(focus_compound_content_active_v10543? rescue false)
    before_semantic=(focus_compound_semantic_active_v10543? rescue false)

    # Exactly one formal delegation.
    r=pmd_ac_v10543_focus_complete(reason)

    still_active=(@focus_cast_lock_active_v1055 ? true:false)
    if was_active && !still_active
      begin
        leak_content=focus_compound_content_active_v10543?
        leak_semantic=focus_compound_semantic_active_v10543?
        leaked=leak_content || leak_semantic
        @focus_compound_completion_count_v10543=@focus_compound_completion_count_v10543.to_i+1
        if @focus_compound_tail_busy_seen_v10543
          @focus_compound_tail_completion_seen_v10543=@focus_compound_tail_completion_seen_v10543.to_i+1
        end
        @focus_compound_tail_leak_v10543=@focus_compound_tail_leak_v10543.to_i+1 if leaked
        log_event(:battle,'BATTLE_FOCUS_COMPOUND_TAIL_COMPLETE_V10543 reason='+reason.to_s+
          ' before_content='+(before_content ? '1':'0')+' before_semantic='+(before_semantic ? '1':'0')+
          ' leak_content='+(leak_content ? '1':'0')+' leak_semantic='+(leak_semantic ? '1':'0')+
          ' compound_tail_frames='+@focus_compound_tail_frames_v10543.to_i.to_s+
          ' actual_lock_complete=1 world_resume_safe='+(leaked ? '0':'1'))
        @focus_compound_tail_frames_v10543=0
        @focus_compound_content_frames_v10543=0
        @focus_compound_semantic_frames_v10543=0
        @focus_compound_tail_busy_seen_v10543=false
      rescue
        @c2_completion_safety_error_v10545=@c2_completion_safety_error_v10545.to_i+1
      end

      begin
        s=c2_completion_snapshot_v10545(ctx,owner)
        active=s[:active] || [0,0]
        unexplained=(s[:logical].to_f>PMD_AC::C2_LOGICAL_DISPLACEMENT_EPS_V10545 && !s[:expected])
        home_bad=s[:presentation].to_f>PMD_AC::C2_PRESENTATION_HOME_EPS_V10545
        visual_warn=s[:unit_visual].to_f>PMD_AC::C2_UNIT_VISUAL_OFFSET_WARN_V10545
        multi_bad=s[:multi] ? true:false
        orphan=(active[0].to_i>0 || active[1].to_i>0)
        compound_bad=(focus_compound_content_active_v10543? || focus_compound_semantic_active_v10543?)

        @c2_completion_count_v10545=@c2_completion_count_v10545.to_i+1
        @c2_expected_spatial_v10545=@c2_expected_spatial_v10545.to_i+1 if s[:expected]
        @c2_unexplained_logical_v10545=@c2_unexplained_logical_v10545.to_i+1 if unexplained
        @c2_home_residual_v10545=@c2_home_residual_v10545.to_i+1 if home_bad
        @c2_unit_visual_warn_v10545=@c2_unit_visual_warn_v10545.to_i+1 if visual_warn
        @c2_multi_pending_v10545=@c2_multi_pending_v10545.to_i+1 if multi_bad
        @c2_orphan_at_close_v10545=@c2_orphan_at_close_v10545.to_i+1 if orphan
        @c2_compound_leak_v10545=@c2_compound_leak_v10545.to_i+1 if compound_bad

        log_event(:battle,'BATTLE_C2_COMPLETION_BOUNDARY_V10545 move='+(ctx==nil ? 'NONE' : ctx[:move].to_s)+
          ' family='+(ctx==nil ? 'NONE' : ctx[:family].to_s)+
          ' logical_displacement='+s[:logical].round.to_i.to_s+
          ' logical_expected='+(s[:expected] ? '1':'0')+
          ' unexplained_logical='+(unexplained ? '1':'0')+
          ' tactical_slide_count='+s[:slide_delta].to_i.to_s+
          ' tactical_reason='+(s[:slide_reason]==nil ? 'NONE' : s[:slide_reason].to_s)+
          ' native_spatial='+(s[:native]==nil ? 'NONE' : s[:native].to_s)+
          ' configured_spatial='+(s[:configured]==nil ? 'NONE' : s[:configured].to_s)+
          ' presentation_home_residual='+sprintf('%.2f',s[:presentation].to_f)+
          ' unit_visual_offset_residual='+sprintf('%.2f',s[:unit_visual].to_f)+
          ' multi_pending='+(multi_bad ? '1':'0')+
          ' owned_projectile='+active[0].to_i.to_s+' owned_effect='+active[1].to_i.to_s+
          ' compound_leak='+(compound_bad ? '1':'0')+
          ' actual_lock_complete=1 current_logical_home=1')
      rescue
        @c2_observer_error_v10545=@c2_observer_error_v10545.to_i+1
      end
    end
    r
  end

  def c2_completion_reset_v10545
    @c2_completion_count_v10545=0
    @c2_expected_spatial_v10545=0
    @c2_unexplained_logical_v10545=0
    @c2_home_residual_v10545=0
    @c2_unit_visual_warn_v10545=0
    @c2_multi_pending_v10545=0
    @c2_orphan_at_close_v10545=0
    @c2_compound_leak_v10545=0
    @c2_busy_query_error_v10545=0
    @c2_update_account_error_v10545=0
    @c2_completion_safety_error_v10545=0
    @c2_observer_error_v10545=0
    @c2_summary_logged_v10545=false
  end

  def start_battle
    r=pmd_ac_v10545_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal
        c2_completion_reset_v10545
        log_event(:battle,'BATTLE_C2_COMPLETION_BOUNDARY_SEAL_V10545 START'+
          ' logical_home=current_logical_anchor presentation_home_eps='+PMD_AC::C2_PRESENTATION_HOME_EPS_V10545.to_s+
          ' tactical_slide_observer=1 multi_pending_gate=1 compound_tail_gate=1'+
          ' result_hold_parent_once=1 busy_query_fail_closed=1 update_lock_parent_once=1'+
          ' gameplay_change=0')
      end
    rescue
    end
    r
  end

  def c2_completion_summary_v10545
    return false if @c2_summary_logged_v10545
    @c2_summary_logged_v10545=true
    pass=(@c2_unexplained_logical_v10545.to_i==0 && @c2_home_residual_v10545.to_i==0 &&
      @c2_multi_pending_v10545.to_i==0 && @c2_orphan_at_close_v10545.to_i==0 &&
      @c2_compound_leak_v10545.to_i==0)
    log_event(:battle,'BATTLE_C2_COMPLETION_BOUNDARY_SUMMARY_V10545 pass='+(pass ? '1':'0')+
      ' completions='+@c2_completion_count_v10545.to_i.to_s+
      ' expected_spatial='+@c2_expected_spatial_v10545.to_i.to_s+
      ' unexplained_logical='+@c2_unexplained_logical_v10545.to_i.to_s+
      ' presentation_home_residual='+@c2_home_residual_v10545.to_i.to_s+
      ' unit_visual_warn='+@c2_unit_visual_warn_v10545.to_i.to_s+
      ' multi_pending='+@c2_multi_pending_v10545.to_i.to_s+
      ' orphan_at_close='+@c2_orphan_at_close_v10545.to_i.to_s+
      ' compound_leak='+@c2_compound_leak_v10545.to_i.to_s+
      ' busy_query_error='+@c2_busy_query_error_v10545.to_i.to_s+
      ' update_account_error='+@c2_update_account_error_v10545.to_i.to_s+
      ' completion_safety_error='+@c2_completion_safety_error_v10545.to_i.to_s+
      ' observer_error='+@c2_observer_error_v10545.to_i.to_s+
      ' blocking_gate=0 issue_driven_adjustment=1')
    pass
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10545_focus_summary
    begin
      c2_completion_summary_v10545
    rescue
    end
    r
  end
end
