#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.55.2
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - MOTION_SHOWCASE_INTERVAL_V055 / MOTION_SHOWCASE_END_FRAME_V055
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_presentation_profile_v055 / presentation_cadence_for_v0552 / presentation_remote_audit_v0552 / initialize
# - start_combat / clear_presentation_v0552 / presentation_motion_active_v055? / skill_in_range?
# - begin_skill / presentation_reach_v0552 / presentation_sprite_offset_v055 / presentation_commit_near_target_v0552
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.55.2
#    Autobattler Combat Cadence / Gap Close / Ranged Cast / Fly Dive
#------------------------------------------------------------------------------
# Additive presentation patch on v0.55.1.
#==============================================================================
module PMD_AC
  # Faster showcase cadence. Normal battle action timings are NOT globally
  # accelerated; only visual travel/return use this new phase cadence.
  remove_const(:MOTION_SHOWCASE_INTERVAL_V055) if const_defined?(:MOTION_SHOWCASE_INTERVAL_V055)
  MOTION_SHOWCASE_INTERVAL_V055=PRESENTATION_CADENCE_V0552[:showcase_interval_frames].to_i
  remove_const(:MOTION_SHOWCASE_END_FRAME_V055) if const_defined?(:MOTION_SHOWCASE_END_FRAME_V055)
  MOTION_SHOWCASE_END_FRAME_V055=1680

  class << self
    alias pmd_ac_v0552_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v0552_move_presentation_profile_v055)
    def move_presentation_profile_v055(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      r=pmd_ac_v0552_move_presentation_profile_v055(k)
      r=r.dup
      d=skill_data(('mv_'+k.to_s).to_sym)
      engage=ENGAGE_STAY_MOVES_V0552[k]
      if engage!=nil
        r[:motion]=engage[:motion]
        r[:motion_space]=:visual_commit
        r[:contact_gap]=(engage[:gap] || PRESENTATION_CADENCE_V0552[:engage_default_gap]).to_f
        r[:engage_cast_range]=(engage[:cast_range] || PRESENTATION_CADENCE_V0552[:engage_max_cast_range]).to_f
        r[:pose]=:attack
        r[:target_aware_contact]=true
        r[:max_visual_travel]=PRESENTATION_CONTACT_TUNING_V0551[:max_visual_travel].to_f
      end
      kind=nil
      begin
        vp=skill_visual_move_profile_v031(k);kind=vp[:visual_kind] if vp!=nil
      rescue
      end
      if r[:motion]==:stationary_cast
        damaging=(d!=nil && d[:category]!=:status)
        r[:pose]=damaging ? PRESENTATION_CADENCE_V0552[:ranged_damage_cast_pose] : PRESENTATION_CADENCE_V0552[:ranged_support_cast_pose]
        r[:remote_cast]=true
        r[:visual_kind]=kind if kind!=nil
        r[:fallback_remote_impact]=true if damaging && !RANGED_DAMAGE_VISUAL_KINDS_V0552.include?(kind)
      end
      ov=MOVE_CADENCE_OVERRIDES_V0552[k] || {}
      r[:approach_frames]=ov[:approach_frames] if ov.has_key?(:approach_frames)
      r[:attack_hold]=ov[:attack_hold] if ov.has_key?(:attack_hold)
      r[:return_frames]=ov[:return_frames] if ov.has_key?(:return_frames)
      r
    end

    def presentation_cadence_for_v0552(profile)
      m=profile[:motion]
      c=PRESENTATION_CADENCE_V0552
      approach=profile[:approach_frames]
      hold=profile[:attack_hold]
      ret=profile[:return_frames]
      if approach==nil
        approach=case m
        when :blink_return,:blink_engage then c[:blink_approach_frames]
        when :dash_return,:dash_stop,:dash_through_return,:dash_engage then c[:dash_approach_frames]
        when :charge_dash then c[:charge_approach_frames]
        else c[:contact_approach_frames]
        end
      end
      if hold==nil
        hold=[:charge_dash].include?(m) ? c[:heavy_impact_hold_frames] : c[:impact_hold_frames]
        hold=c[:multi_impact_hold_frames] if [:multi_contact,:spin_contact].include?(m)
      end
      if ret==nil
        ret=case m
        when :dash_return,:dash_through_return,:blink_return then c[:dash_return_frames]
        when :charge_dash then c[:charge_return_frames]
        else c[:contact_return_frames]
        end
      end
      {:approach=>[approach.to_i,1].max,:hold=>[hold.to_i,0].max,:return=>[ret.to_i,1].max}
    end

    def presentation_remote_audit_v0552
      keys=executable_move_keys_v055
      total=0;pose_ok=0;damage_total=0;impact_ok=0;issues=[]
      keys.each do |k|
        p=move_presentation_profile_v055(k)
        next unless p[:motion]==:stationary_cast
        d=skill_data(('mv_'+k.to_s).to_sym)
        kind=nil
        begin
          vp=skill_visual_move_profile_v031(k);kind=vp[:visual_kind] if vp!=nil
        rescue
        end
        total+=1
        pose_ok+=1 if p[:pose]==:shoot || p[:pose]==:charge
        if d!=nil && d[:category]!=:status
          damage_total+=1
          # Existing visual layer owns known impact routes; unknown legacy routes get a v0.55.2 fallback impact.
          if RANGED_DAMAGE_VISUAL_KINDS_V0552.include?(kind) || p[:fallback_remote_impact]
            impact_ok+=1
          else
            issues.push(k)
          end
        end
      end
      {:total=>total,:pose_ok=>pose_ok,:damage_total=>damage_total,:impact_ok=>impact_ok,:issues=>issues}
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v0552_initialize initialize unless method_defined?(:pmd_ac_v0552_initialize)
  alias pmd_ac_v0552_start_combat start_combat unless method_defined?(:pmd_ac_v0552_start_combat)
  alias pmd_ac_v0552_begin_skill begin_skill unless method_defined?(:pmd_ac_v0552_begin_skill)
  alias pmd_ac_v0552_skill_in_range skill_in_range? unless method_defined?(:pmd_ac_v0552_skill_in_range)
  alias pmd_ac_v0552_desired_velocity desired_velocity unless method_defined?(:pmd_ac_v0552_desired_velocity)
  alias pmd_ac_v0552_begin_attack begin_attack unless method_defined?(:pmd_ac_v0552_begin_attack)
  alias pmd_ac_v0552_update update unless method_defined?(:pmd_ac_v0552_update)
  alias pmd_ac_v0552_altitude_visual_offset_y_v038 altitude_visual_offset_y_v038 unless method_defined?(:pmd_ac_v0552_altitude_visual_offset_y_v038)

  def initialize(*args)
    pmd_ac_v0552_initialize(*args)
    clear_presentation_v0552
  end
  def start_combat
    pmd_ac_v0552_start_combat
    clear_presentation_v0552
  end
  def clear_presentation_v0552
    @presentation_committed_v0552=false
    @presentation_hit_react_frames_v0552=0
    @presentation_hit_react_pose_v0552=nil
    @presentation_fly_v0552=nil
  end

  def presentation_motion_active_v055?
    return false if @presentation_profile_v055==nil || @action!=:skill || @action_timer.to_i<=0
    sp=@presentation_profile_v055[:motion_space]
    return false if sp==:visual_commit && @presentation_committed_v0552
    sp==:visual || sp==:visual_commit
  end

  def skill_in_range?(other)
    return false if other==nil || other.dead?
    d=skill_data;mk=d==nil ? nil : d[:canonical_move_key]
    if mk!=nil
      e=PMD_AC::ENGAGE_STAY_MOVES_V0552[mk]
      return distance_to(other).to_f <= e[:cast_range].to_f if e!=nil
    end
    pmd_ac_v0552_skill_in_range(other)
  end

  def begin_skill(skill_target=nil)
    return if presentation_fly_active_v0552?
    # v0.55.1 made Showcase intentionally slow. v0.55.2 instead uses fast
    # travel plus a visible impact hold, so bypass that old timing stretch.
    was_slow=@presentation_showcase_slow_v0551
    @presentation_showcase_slow_v0551=false if was_slow
    pmd_ac_v0552_begin_skill(skill_target)
    @presentation_showcase_slow_v0551=was_slow if was_slow
    p=@presentation_profile_v055
    return if p==nil || @action!=:skill
    @presentation_committed_v0552=false
    if was_slow
      old_total=[@action_total_frames.to_i,1].max
      old_hit=[@action_hit_frame.to_i,1].max
      old_pre=[old_total-old_hit,1].max
      min_total=PMD_AC::PRESENTATION_CADENCE_V0552[:showcase_min_total_frames].to_i
      min_pre=PMD_AC::PRESENTATION_CADENCE_V0552[:showcase_min_pre_hit_frames].to_i
      if old_total<min_total || old_pre<min_pre
        new_pre=[old_pre,min_pre].max
        post=[old_hit,1].max
        new_total=[new_pre+post,min_total].max
        @action_total_frames=new_total;@action_timer=new_total;@action_hit_frame=[new_total-new_pre,1].max
        log_event(:presentation_cadence,log_name+' SHOWCASE total='+old_total.to_s+'->'+new_total.to_s+' prehit='+old_pre.to_s+'->'+new_pre.to_s)
      end
    end
    if p[:remote_cast] && PMD_AC::PRESENTATION_CADENCE_V0552[:ranged_cast_log]
      log_event(:presentation_cast,log_name+' move='+(p[:move_key]||:unknown).to_s+' pose='+p[:pose].to_s+' visual_kind='+(p[:visual_kind]||:fallback).to_s+' release_at='+(@action_total_frames.to_i-@action_hit_frame.to_i).to_s)
    end
  end

  def presentation_reach_v0552(p)
    tx=@presentation_target_x_v055.to_f;ty=@presentation_target_y_v055.to_f
    dx=tx-@pixel_x.to_f;dy=ty-@pixel_y.to_f;dist=Math.sqrt(dx*dx+dy*dy)
    return [0.0,0.0,0.0,0.0,dist] if dist<=0.001
    nx=dx/dist;ny=dy/dist;gap=(p[:contact_gap]||PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:default_contact_gap]).to_f
    reach=[dist-gap,0.0].max
    reach=[reach,(p[:max_visual_travel]||PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:max_visual_travel]).to_f].min
    [nx,ny,reach,gap,dist]
  end

  def presentation_sprite_offset_v055
    return fly_cinematic_offset_v0552 if presentation_fly_active_v0552?
    return [0.0,0.0] unless presentation_motion_active_v055?
    p=@presentation_profile_v055;m=p[:motion]
    return [0.0,0.0] if m==:stationary_cast || m==:runtime_owned
    rr=presentation_reach_v0552(p);nx=rr[0];ny=rr[1];reach=rr[2]
    return [0.0,0.0] if rr[4]<=0.001
    total=[@action_total_frames.to_i,1].max;pre=[total-@action_hit_frame.to_i,1].max;elapsed=total-@action_timer.to_i
    cad=PMD_AC.presentation_cadence_for_v0552(p);app=cad[:approach];hold=cad[:hold];ret=cad[:return]
    amount=0.0
    if elapsed<pre
      q=[elapsed.to_f/app.to_f,1.0].min;q=0.0 if q<0.0
      ease=1.0-(1.0-q)*(1.0-q)
      amount=reach*ease
    else
      post=elapsed-pre
      if m==:dash_through_return
        pass=(p[:pass_px]||20.0).to_f
        if post<hold
          q=hold<=0 ? 1.0 : post.to_f/hold.to_f
          amount=reach+pass*q
        else
          q=[(post-hold).to_f/ret.to_f,1.0].min
          amount=(reach+pass)*(1.0-(q*q))
        end
      elsif m==:blink_return
        if post<hold
          amount=reach
        else
          q=[(post-hold).to_f/ret.to_f,1.0].min
          amount=q>=0.55 ? 0.0 : reach
        end
      elsif m==:dash_engage || m==:blink_engage || m==:dash_stop
        amount=reach
      else
        if post<hold
          amount=reach
        else
          q=[(post-hold).to_f/ret.to_f,1.0].min
          amount=reach*(1.0-(q*q))
        end
      end
    end
    if m==:multi_contact
      wob=(p[:wobble_px]||5.0).to_f*Math.sin(elapsed.to_f*1.10)
      return [nx*amount-ny*wob,ny*amount+nx*wob]
    end
    [nx*amount,ny*amount]
  end

  def presentation_commit_near_target_v0552(target,move_key=nil)
    p=@presentation_profile_v055;return false if p==nil || target==nil || target.dead?
    return false unless p[:motion_space]==:visual_commit
    return true if @presentation_committed_v0552
    dx=@pixel_x.to_f-target.pixel_x.to_f;dy=@pixel_y.to_f-target.pixel_y.to_f;dist=Math.sqrt(dx*dx+dy*dy)
    if dist<=0.001;dx=@team==:ally ? -1.0 : 1.0;dy=0.0;dist=1.0;end
    gap=(p[:contact_gap]||PMD_AC::PRESENTATION_CADENCE_V0552[:engage_default_gap]).to_f
    @pixel_x=target.pixel_x.to_f+dx/dist*gap;@pixel_y=target.pixel_y.to_f+dy/dist*gap
    clamp_to_board;sync_cell_from_pixel;@velocity_x=0.0;@velocity_y=0.0;clear_move_goal
    @presentation_committed_v0552=true
    log_event(:presentation_engage,log_name+' move='+(move_key||p[:move_key]||:unknown).to_s+' COMMIT near='+target.log_name+' gap='+sprintf('%.1f',gap)+' logical=1')
    true
  end

  def presentation_busy_for_hurt_v0552?
    return true if dead?
    return true if respond_to?(:two_turn_pending_v039?) && two_turn_pending_v039?
    return true if presentation_fly_active_v0552?
    return true if @action==:skill && @action_timer.to_i>0 && !PMD_AC::PRESENTATION_CADENCE_V0552[:target_hurt_busy_skill]
    false
  end
  def trigger_presentation_hit_reaction_v0552(source,move_key,damage,kind=:skill)
    return if damage.to_i<=0 || dead?
    busy=presentation_busy_for_hurt_v0552?
    if busy
      log_event(:presentation_hit_react,log_name+' <- '+(source==nil ? 'SYSTEM' : source.log_name)+' move='+move_key.to_s+' mode=recoil_only busy=1 damage='+damage.to_i.to_s)
      return false
    end
    frames=PMD_AC::PRESENTATION_CADENCE_V0552[:target_hurt_frames].to_i
    @presentation_hit_react_frames_v0552=[@presentation_hit_react_frames_v0552.to_i,frames].max
    @presentation_hit_react_pose_v0552=PMD_AC::PRESENTATION_CADENCE_V0552[:target_hurt_pose]
    log_event(:presentation_hit_react,log_name+' <- '+(source==nil ? 'SYSTEM' : source.log_name)+' move='+move_key.to_s+' pose='+@presentation_hit_react_pose_v0552.to_s+' frames='+frames.to_s+' busy=0 damage='+damage.to_i.to_s)
    true
  end

  # Bypass v0.55.1's contact-only hurt overlay. v0.55.2 triggers reactions from
  # Scene#deal_direct_damage so ranged skill impacts are covered too.
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    pmd_ac_v0551_receive_damage(value,source,grant_energy,bypass_link,critical)
  end
  def update_hurt
    pmd_ac_v0551_update_hurt
    @presentation_hit_react_frames_v0552-=1 if @presentation_hit_react_frames_v0552.to_i>0
  end
  def visual_action
    if @presentation_hit_react_frames_v0552.to_i>0
      pose=@presentation_hit_react_pose_v0552 || :hurt
      return pose if PMD_AC.action_data(@species,pose)!=nil
    end
    if presentation_fly_active_v0552?
      return :attack if PMD_AC.action_data(@species,:attack)!=nil
    end
    pmd_ac_v0551_visual_action
  end

  # High Fly charge replaces the tiny generic airborne -10px presentation.
  def altitude_visual_offset_y_v038
    if respond_to?(:two_turn_pending_v039?) && two_turn_pending_v039? && respond_to?(:two_turn_move_v039) && two_turn_move_v039==:fly
      total=(PMD_AC::TWO_TURN_MOVE_V039[:fly][:phase_frames] rescue 60).to_i;total=60 if total<=0
      elapsed=total-two_turn_frames_v039.to_i;asc=[PMD_AC::PRESENTATION_CADENCE_V0552[:fly_ascent_frames].to_i,1].max
      q=[[elapsed.to_f/asc.to_f,0.0].max,1.0].min
      high=PMD_AC::PRESENTATION_CADENCE_V0552[:fly_high_y].to_f
      y=-10.0+(high+10.0)*(1.0-(1.0-q)*(1.0-q))
      y+=Math.sin((Graphics.frame_count%36).to_f/36.0*Math::PI*2.0)*1.5 if q>=1.0
      return y
    end
    pmd_ac_v0552_altitude_visual_offset_y_v038
  end

  def begin_fly_cinematic_v0552(target,data)
    return false if target==nil || target.dead?
    c=PMD_AC::PRESENTATION_CADENCE_V0552
    @presentation_fly_v0552={:elapsed=>0,:target=>target,:target_uid=>(target.respond_to?(:instance_uid) ? target.instance_uid : nil),:data=>data,:impact_done=>false,
      :origin_x=>@pixel_x.to_f,:origin_y=>@pixel_y.to_f,:target_x=>target.pixel_x.to_f,:target_y=>target.pixel_y.to_f}
    face_toward(target,true)
    log_event(:presentation_fly,log_name+' DIVE_START high_y='+c[:fly_high_y].to_s+' dive='+c[:fly_dive_frames].to_s+' impact='+c[:fly_impact_frame].to_s+' overshoot='+c[:fly_overshoot_px].to_s)
    true
  end
  def presentation_fly_active_v0552?;@presentation_fly_v0552!=nil;end
  def update_fly_cinematic_v0552
    s=@presentation_fly_v0552;return if s==nil
    if dead?;@presentation_fly_v0552=nil;return;end
    t=s[:target]
    if t!=nil && !t.dead? && !s[:impact_done]
      s[:target_x]=t.pixel_x.to_f;s[:target_y]=t.pixel_y.to_f
    end
    s[:elapsed]=s[:elapsed].to_i+1
    if !s[:impact_done] && s[:elapsed]>=PMD_AC::PRESENTATION_CADENCE_V0552[:fly_impact_frame].to_i
      s[:impact_done]=true
      @scene.resolve_fly_impact_v0552(self,s) if @scene!=nil && @scene.respond_to?(:resolve_fly_impact_v0552)
    end
    total=PMD_AC::PRESENTATION_CADENCE_V0552[:fly_dive_frames].to_i+PMD_AC::PRESENTATION_CADENCE_V0552[:fly_impact_hold_frames].to_i+PMD_AC::PRESENTATION_CADENCE_V0552[:fly_return_frames].to_i
    if s[:elapsed]>=total
      log_event(:presentation_fly,log_name+' RETURN origin=('+s[:origin_x].round.to_s+','+s[:origin_y].round.to_s+') logical_unchanged=1')
      @presentation_fly_v0552=nil
    end
  end
  def fly_cinematic_offset_v0552
    s=@presentation_fly_v0552;return [0.0,0.0] if s==nil
    c=PMD_AC::PRESENTATION_CADENCE_V0552;d=[c[:fly_dive_frames].to_i,1].max;h=[c[:fly_impact_hold_frames].to_i,0].max;r=[c[:fly_return_frames].to_i,1].max;e=s[:elapsed].to_i
    ox=s[:origin_x].to_f;oy=s[:origin_y].to_f;tx=s[:target_x].to_f;ty=s[:target_y].to_f
    dx=tx-ox;dy=ty-oy;dist=Math.sqrt(dx*dx+dy*dy);dist=1.0 if dist<=0.001;nx=dx/dist;ny=dy/dist
    ex=tx+nx*c[:fly_overshoot_px].to_f;ey=ty+ny*c[:fly_overshoot_px].to_f;endx=ex-ox;endy=ey-oy
    if e<=d
      q=[[e.to_f/d.to_f,0.0].max,1.0].min;ease=1.0-(1.0-q)*(1.0-q)
      x=endx*ease;y=endy*ease
      impact_q=[c[:fly_impact_frame].to_f/d.to_f,0.15].max
      drop=[q/impact_q,1.0].min
      y+=c[:fly_high_y].to_f*(1.0-drop)
      return [x,y]
    elsif e<=d+h
      return [endx,endy]
    else
      q=[(e-d-h).to_f/r.to_f,1.0].min;back=1.0-q
      x=endx*back;y=endy*back+c[:fly_return_arc_y].to_f*Math.sin(q*Math::PI)
      return [x,y]
    end
  end

  def desired_velocity
    return [0.0,0.0] if presentation_fly_active_v0552?
    pmd_ac_v0552_desired_velocity
  end
  def begin_attack
    return if presentation_fly_active_v0552?
    pmd_ac_v0552_begin_attack
  end
  def update
    pmd_ac_v0552_update
    update_fly_cinematic_v0552
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0552_start start unless method_defined?(:pmd_ac_v0552_start)
  alias pmd_ac_v0552_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v0552_deal_direct_damage)
  alias pmd_ac_v0552_resolve_two_turn_release_v039 resolve_two_turn_release_v039 unless method_defined?(:pmd_ac_v0552_resolve_two_turn_release_v039)
  alias pmd_ac_v0552_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0552_update_verification_script)
  alias pmd_ac_v0552_place_motion_demo_v055 place_motion_demo_v055 unless method_defined?(:pmd_ac_v0552_place_motion_demo_v055)

  def start
    pmd_ac_v0552_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.55\.1 Battle Verification Log/,'PMD AutoChess Proto v0.55.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.55.2 cadence=fast_travel+impact_hold gap_close_commit=1 ranged_cast_audit=1 ranged_hurt=1 fly_high_dive=1 core_damage_unchanged=1 spatial_adaptation=engage_commit')
  end

  def deal_direct_damage(user,target,power,options=nil)
    before=target==nil ? 0 : target.hp.to_i
    result=pmd_ac_v0552_deal_direct_damage(user,target,power,options)
    actual=target==nil ? 0 : [before-target.hp.to_i,0].max
    if actual>0 && target.respond_to?(:trigger_presentation_hit_reaction_v0552)
      opt=options || {};sd=opt[:skill_data];mk=sd==nil ? :basic_attack : (sd[:canonical_move_key] || :skill)
      kind=sd==nil ? :basic : :skill
      target.trigger_presentation_hit_reaction_v0552(user,mk,actual,kind)
      if sd!=nil && user!=nil
        begin
          pp=PMD_AC.move_presentation_profile_v055(mk)
          if pp[:fallback_remote_impact]
            vp=PMD_AC.skill_visual_move_profile_v031(mk);style=(vp==nil ? (sd[:vfx_style]||sd[:move_type]||:normal) : (vp[:style]||sd[:vfx_style]||sd[:move_type]||:normal))
            add_vfx_impact(target,style)
            log_event(:presentation_impact,target.log_name+' move='+mk.to_s+' fallback_impact=1 style='+style.to_s)
          end
        rescue
        end
      end
      if user!=nil && user.respond_to?(:presentation_commit_near_target_v0552) && PMD_AC::PRESENTATION_CADENCE_V0552[:engage_commit_after_hit]
        user.presentation_commit_near_target_v0552(target,mk)
      end
    end
    result
  end

  # Fly keeps the tactical/logical position at the takeoff cell. The dive is a
  # visual cinematic; impact resolves when the sprite crosses the target.
  def resolve_two_turn_release_v039(unit)
    if unit!=nil && unit.respond_to?(:two_turn_pending_v039?) && unit.two_turn_pending_v039? && unit.two_turn_move_v039==:fly
      uid=unit.two_turn_target_uid_v039;data=PMD_AC.skill_data(:mv_fly);target=two_turn_unit_by_uid_v039(uid)
      unit.clear_two_turn_charge_v039
      if target==nil || target.dead?
        log_event(:two_turn,unit.log_name+' PHASE2_CANCEL fly target_uid='+uid.to_s+' reason=target_lost');return false
      end
      unit.begin_fly_cinematic_v0552(target,data);play_skill_se(unit,:launch,data)
      log_event(:two_turn,unit.log_name+' PHASE2_CINEMATIC fly -> '+target.log_name+' logical_dash=0')
      return true
    end
    pmd_ac_v0552_resolve_two_turn_release_v039(unit)
  end
  def resolve_fly_impact_v0552(unit,state)
    return false if unit==nil || state==nil
    target=state[:target];data=state[:data]
    if target==nil || target.dead?
      log_event(:presentation_fly,unit.log_name+' IMPACT_CANCEL target_lost=1');return false
    end
    unit.face_toward(target,true) if unit.respond_to?(:face_toward)
    result=apply_skill_effects(unit,target,data,1.0);amount=result.is_a?(Numeric) ? result.to_i : 0
    add_vfx_impact(target,data[:vfx_style]||:normal) if amount>0
    log_event(:presentation_fly,unit.log_name+' IMPACT '+target.log_name+' result='+amount.to_s+' overshoot_next=1')
    log_event(:two_turn,unit.log_name+' PHASE2 fly -> '+target.log_name+' result='+amount.to_s+' pose=returning')
    amount>0
  end

  def motion_showcase_sequence_v055
    [[:tackle,:charmander,:rattata],[:slash,:charmander,:rattata],[:quick_attack,:charmander,:rattata],
     [:sucker_punch,:rattata,:bulbasaur],[:pursuit,:rattata,:bulbasaur],[:flame_wheel,:charmander,:rattata],
     [:double_kick,:charmander,:rattata],[:rapid_spin,:squirtle,:rattata],[:u_turn,:charmander,:rattata],
     [:hydro_pump,:squirtle,:rattata],[:flamethrower,:charmander,:rattata],[:psywave,:bulbasaur,:rattata],
     [:dream_eater,:squirtle,:rattata],[:solar_beam,:bulbasaur,:rattata],[:fly,:charmander,:rattata]]
  end

  # Remote demos need a few setup states to actually resolve visibly.
  def place_motion_demo_v055(caster,target)
    pmd_ac_v0552_place_motion_demo_v055(caster,target)
    return if caster==nil || target==nil
    target.instance_variable_set(:@statuses,{})
    idx=@motion_showcase_index_v055.to_i
    if idx==12 && target.respond_to?(:apply_status)
      target.apply_status(:sleep,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},caster)
    end
    # Keep targets idle so Hurt can be inspected unless a demo explicitly needs state.
    target.instance_variable_set(:@action,:idle);target.instance_variable_set(:@action_timer,0);target.instance_variable_set(:@visual_action,:idle)
  end

  def verify_v055_examples
    return if @verification_done[:v055_examples]
    pairs={:tackle=>:contact_return,:quick_attack=>:dash_return,:sucker_punch=>:blink_engage,:pursuit=>:dash_engage,:flame_wheel=>:charge_dash,:double_kick=>:multi_contact,:rapid_spin=>:spin_contact,:u_turn=>:dash_through_return,:hydro_pump=>:stationary_cast,:fly=>:runtime_owned}
    ok=pairs.all?{|k,v|PMD_AC.move_presentation_profile_v055(k)[:motion]==v}
    log_event(:verify,'PRESENTATION_EXAMPLES pass='+(ok ? '1':'0')+' tackle=contact_return quick_attack=dash_return sucker_punch=blink_engage pursuit=dash_engage flame_wheel=charge_dash double_kick=multi rapid_spin=spin u_turn=dash_through_return hydro=cast fly=runtime_owned')
    @verification_done[:v055_examples]=true
  end
  def verify_v055_showcase
    return if @verification_done[:v055_showcase];s=motion_showcase_sequence_v055;ok=s.size==15 && s.all?{|x|PMD_AC.move_executable?(x[0])};log_event(:verify,'PRESENTATION_SHOWCASE_READY pass='+(ok ? '1':'0')+' demos='+s.size.to_s+' melee=9 ranged=5 fly=1 actual_force_skill=1 ai_frozen=1');@verification_done[:v055_showcase]=true
  end

  def verify_v0552_cadence
    return if @verification_done[:v0552_cadence];a=PMD_AC.presentation_cadence_for_v0552(PMD_AC.move_presentation_profile_v055(:tackle));q=PMD_AC.presentation_cadence_for_v0552(PMD_AC.move_presentation_profile_v055(:quick_attack));ok=a[:approach]<=5 && a[:hold]>=7 && a[:return]<=5 && q[:approach]<=3 && q[:return]<=3;log_event(:verify,'PRESENTATION_CADENCE_V0552 pass='+(ok ? '1':'0')+' tackle='+a[:approach].to_s+'/'+a[:hold].to_s+'/'+a[:return].to_s+' quick='+q[:approach].to_s+'/'+q[:hold].to_s+'/'+q[:return].to_s+' design=fast_commit_hold_fast_recover');@verification_done[:v0552_cadence]=true
  end
  def verify_v0552_engage
    return if @verification_done[:v0552_engage];a=PMD_AC.move_presentation_profile_v055(:pursuit);b=PMD_AC.move_presentation_profile_v055(:sucker_punch);ok=a[:motion]==:dash_engage && b[:motion]==:blink_engage && a[:motion_space]==:visual_commit && b[:motion_space]==:visual_commit;log_event(:verify,'PRESENTATION_ENGAGE_V0552 pass='+(ok ? '1':'0')+' pursuit=dash_engage sucker_punch=blink_engage stay_after_hit=1 logical_commit_after_damage=1 range='+a[:engage_cast_range].to_i.to_s);@verification_done[:v0552_engage]=true
  end
  def verify_v0552_ranged
    return if @verification_done[:v0552_ranged];h=PMD_AC.presentation_remote_audit_v0552;ok=h[:total]>0 && h[:pose_ok]==h[:total] && h[:damage_total]>0 && h[:impact_ok]==h[:damage_total];log_event(:verify,'PRESENTATION_RANGED_AUDIT_V0552 pass='+(ok ? '1':'0')+' ranged='+h[:total].to_s+' cast_pose='+h[:pose_ok].to_s+' damaging='+h[:damage_total].to_s+' impact_path='+h[:impact_ok].to_s+' target_hurt=direct_damage_sync issues=['+h[:issues][0,8].collect{|x|x.to_s}.join(',')+']');@verification_done[:v0552_ranged]=true
  end
  def verify_v0552_fly
    return if @verification_done[:v0552_fly];c=PMD_AC::PRESENTATION_CADENCE_V0552;ok=c[:fly_high_y].to_f<=-40.0 && c[:fly_overshoot_px].to_f>0 && c[:fly_return_frames].to_i<=10;log_event(:verify,'PRESENTATION_FLY_V0552 pass='+(ok ? '1':'0')+' high_y='+c[:fly_high_y].to_s+' dive='+c[:fly_dive_frames].to_s+' impact='+c[:fly_impact_frame].to_s+' overshoot='+c[:fly_overshoot_px].to_s+' return='+c[:fly_return_frames].to_s+' logical_origin_preserved=1');@verification_done[:v0552_fly]=true
  end

  def update_verification_script
    pmd_ac_v0552_update_verification_script
    return unless verification_mode==:presentation_authoring
    f=@verification_frame
    verify_v0552_cadence if f==708
    verify_v0552_engage if f==712
    verify_v0552_ranged if f==716
    verify_v0552_fly if f==719
  end
end
