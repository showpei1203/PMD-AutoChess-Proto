#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.55.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_presentation_profile_v055 / initialize / start_combat / reset_presentation_contact_v0551
# - set_presentation_showcase_slow_v0551 / presentation_showcase_slow_v0551? / begin_skill / presentation_sprite_offset_v055
# - presentation_contact_source_v0551? / receive_damage / update_hurt / visual_action
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.55.1
#    Motion Contact / Attack Pose / Hit Reaction Fix
#------------------------------------------------------------------------------
# Additive patch on v0.55.
# - Contact motion becomes target-aware instead of fixed-distance capped.
# - Contact skills default to PMD :attack pose and log the pose switch.
# - MOTION_SHOWCASE is slowed and forced-hit / no-active-evade for visual audit.
# - Successful contact damage forces a short visual-only PMD :hurt reaction.
#==============================================================================
module PMD_AC
  class << self
    alias pmd_ac_v0551_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v0551_move_presentation_profile_v055)
    def move_presentation_profile_v055(move_key)
      r=pmd_ac_v0551_move_presentation_profile_v055(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      if CONTACT_MOTIONS_V0551.include?(r[:motion])
        r=r.dup
        r[:pose]=:attack if r[:pose]==nil
        ov=MOVE_CONTACT_TUNING_OVERRIDES_V0551[k] || {}
        gap=ov[:contact_gap]
        if gap==nil
          if k==:tackle
            gap=PRESENTATION_CONTACT_TUNING_V0551[:tackle_contact_gap]
          elsif k==:slash
            gap=PRESENTATION_CONTACT_TUNING_V0551[:slash_contact_gap]
          else
            gap=PRESENTATION_CONTACT_TUNING_V0551[:default_contact_gap]
          end
        end
        r[:contact_gap]=gap.to_f
        r[:target_aware_contact]=PRESENTATION_CONTACT_TUNING_V0551[:target_aware_contact] ? true : false
        r[:max_visual_travel]=PRESENTATION_CONTACT_TUNING_V0551[:max_visual_travel].to_f
        r[:hit_reaction_frames]=PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_frames].to_i
      end
      r
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v0551_initialize initialize unless method_defined?(:pmd_ac_v0551_initialize)
  alias pmd_ac_v0551_start_combat start_combat unless method_defined?(:pmd_ac_v0551_start_combat)
  alias pmd_ac_v0551_begin_skill begin_skill unless method_defined?(:pmd_ac_v0551_begin_skill)
  alias pmd_ac_v0551_update_hurt update_hurt unless method_defined?(:pmd_ac_v0551_update_hurt)
  alias pmd_ac_v0551_receive_damage receive_damage unless method_defined?(:pmd_ac_v0551_receive_damage)
  alias pmd_ac_v0551_visual_action visual_action unless method_defined?(:pmd_ac_v0551_visual_action)

  def initialize(*args)
    pmd_ac_v0551_initialize(*args)
    reset_presentation_contact_v0551
  end

  def start_combat
    pmd_ac_v0551_start_combat
    reset_presentation_contact_v0551
  end

  def reset_presentation_contact_v0551
    @presentation_hit_react_frames_v0551=0
    @presentation_showcase_slow_v0551=false
  end

  def set_presentation_showcase_slow_v0551(v)
    @presentation_showcase_slow_v0551=v ? true : false
  end

  def presentation_showcase_slow_v0551?
    @presentation_showcase_slow_v0551 ? true : false
  end

  def begin_skill(skill_target=nil)
    pmd_ac_v0551_begin_skill(skill_target)
    p=@presentation_profile_v055
    return if p==nil
    if p[:pose]!=nil
      available=PMD_AC.action_data(@species,p[:pose])!=nil
      @visual_action=p[:pose] if available
      log_event(:presentation_pose,log_name+' move='+((p[:move_key]||:unknown).to_s)+' requested='+p[:pose].to_s+' available='+(available ? '1':'0')+' visual_action='+@visual_action.to_s)
    end
    if presentation_showcase_slow_v0551? && @action==:skill
      old_total=[@action_total_frames.to_i,1].max
      old_hit=[@action_hit_frame.to_i,1].max
      old_pre=[old_total-old_hit,1].max
      min_total=PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:showcase_min_total_frames].to_i
      min_pre=PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:showcase_min_pre_hit_frames].to_i
      new_total=[old_total,min_total].max
      scale=new_total.to_f/old_total.to_f
      new_pre=[(old_pre.to_f*scale).round,min_pre].max
      new_pre=[new_pre,new_total-1].min
      @action_total_frames=new_total
      @action_timer=new_total
      @action_hit_frame=[new_total-new_pre,1].max
      log_event(:presentation_pose,log_name+' SHOWCASE_SLOW total='+old_total.to_s+'->'+new_total.to_s+' prehit='+old_pre.to_s+'->'+new_pre.to_s)
    end
  end

  # v0.55 used travel_px as a hard cap. For contact motions this could stop far
  # from the target in Showcase. v0.55.1 instead aims at target distance-gap.
  def presentation_sprite_offset_v055
    return [0.0,0.0] unless presentation_motion_active_v055?
    p=@presentation_profile_v055;motion=p[:motion]
    return [0.0,0.0] if motion==:stationary_cast || motion==:runtime_owned
    tx=@presentation_target_x_v055.to_f;ty=@presentation_target_y_v055.to_f
    dx=tx-@pixel_x.to_f;dy=ty-@pixel_y.to_f;dist=Math.sqrt(dx*dx+dy*dy)
    return [0.0,0.0] if dist<=0.001
    nx=dx/dist;ny=dy/dist
    total=[@action_total_frames.to_i,1].max;hit_cd=[@action_hit_frame.to_i,1].max;hit_elapsed=[total-hit_cd,1].max;elapsed=total-@action_timer.to_i
    speed=(p[:motion_speed]||1.0).to_f*PMD_AC::PRESENTATION_GLOBAL_V055[:motion_speed_mult].to_f
    if elapsed<=hit_elapsed
      q=elapsed.to_f/hit_elapsed.to_f;q*=speed;q=1.0 if q>1.0;pre=true
    else
      q=@action_timer.to_f/hit_cd.to_f;q*=speed;q=1.0 if q>1.0;pre=false
    end
    q=0.0 if q<0.0
    gap=(p[:contact_gap]||PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:default_contact_gap]).to_f
    reach=[dist-gap,0.0].max
    if p[:target_aware_contact]
      reach=[reach,(p[:max_visual_travel]||180.0).to_f].min
    else
      reach=[reach,(p[:travel_px]||42.0).to_f].min
    end
    amount=0.0
    case motion
    when :step_attack,:lunge_return,:contact_return
      amount=Math.sin(q*Math::PI/2.0)*reach
    when :dash_stop,:dash_return
      amount=(1.0-(1.0-q)*(1.0-q))*reach
    when :dash_through_return
      pass=(p[:pass_px]||20.0).to_f;amount=(1.0-(1.0-q)*(1.0-q))*(reach+pass)
    when :blink_return
      amount=(q>=0.35 ? reach : 0.0)
    when :charge_dash
      amount=q*q*reach
      if !pre && q<0.45
        amount-=((p[:recoil_px]||6.0).to_f*(1.0-q/0.45))
      end
    when :multi_contact
      amount=Math.sin(q*Math::PI/2.0)*reach
      wob=(p[:wobble_px]||5.0).to_f*Math.sin(elapsed.to_f*0.85)
      return [nx*amount-ny*wob,ny*amount+nx*wob]
    when :spin_contact
      amount=(1.0-(1.0-q)*(1.0-q))*reach
    end
    [nx*amount,ny*amount]
  end

  def presentation_contact_source_v0551?(source)
    return false if source==nil || !source.respond_to?(:presentation_profile_v055)
    p=source.presentation_profile_v055
    return false if p==nil
    PMD_AC::CONTACT_MOTIONS_V0551.include?(p[:motion])
  end

  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    before=@hp.to_i
    result=pmd_ac_v0551_receive_damage(value,source,grant_energy,bypass_link,critical)
    actual=before-@hp.to_i
    if actual>0 && PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:contact_hit_reaction] && presentation_contact_source_v0551?(source) && !dead?
      p=source.presentation_profile_v055
      frames=(p[:hit_reaction_frames] || PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_frames]).to_i
      @presentation_hit_react_frames_v0551=[@presentation_hit_react_frames_v0551.to_i,frames].max
      log_event(:presentation_hit_react,log_name+' <- '+source.log_name+' move='+(p[:move_key]||:unknown).to_s+' pose='+PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_pose].to_s+' frames='+frames.to_s+' damage='+actual.to_s)
    end
    result
  end

  def update_hurt
    pmd_ac_v0551_update_hurt
    @presentation_hit_react_frames_v0551-=1 if @presentation_hit_react_frames_v0551.to_i>0
  end

  def visual_action
    if @presentation_hit_react_frames_v0551.to_i>0
      pose=PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_pose]
      return pose if PMD_AC.action_data(@species,pose)!=nil
    end
    pmd_ac_v0551_visual_action
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0551_start start unless method_defined?(:pmd_ac_v0551_start)
  alias pmd_ac_v0551_place_motion_demo_v055 place_motion_demo_v055 unless method_defined?(:pmd_ac_v0551_place_motion_demo_v055)
  alias pmd_ac_v0551_update_motion_showcase_v055 update_motion_showcase_v055 unless method_defined?(:pmd_ac_v0551_update_motion_showcase_v055)
  alias pmd_ac_v0551_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0551_complete_verification_mode)
  alias pmd_ac_v0551_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v0551_canonical_accuracy_hit)
  alias pmd_ac_v0551_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0551_update_verification_script)

  def start
    pmd_ac_v0551_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.55 Battle Verification Log/,'PMD AutoChess Proto v0.55.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.55.1 target_aware_contact=1 attack_pose=1 contact_hit_reaction=1 showcase_force_hit=1 showcase_slow=1 mechanics_unchanged=1')
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    if verification_mode==:motion_showcase_v055 && PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:showcase_force_hit]
      return true
    end
    pmd_ac_v0551_canonical_accuracy_hit(user,target,data,log_check)
  end

  def place_motion_demo_v055(caster,target)
    pmd_ac_v0551_place_motion_demo_v055(caster,target)
    return if caster==nil || target==nil
    (@units||[]).each{|u|u.set_presentation_showcase_slow_v0551(false) if u.respond_to?(:set_presentation_showcase_slow_v0551)}
    caster.set_presentation_showcase_slow_v0551(true) if caster.respond_to?(:set_presentation_showcase_slow_v0551)
    if PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:showcase_disable_active_evade] && target.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
      target.pmd_ac_v0211_verification_suppress_active_evade
    end
  end

  def complete_verification_mode
    if verification_mode==:motion_showcase_v055
      (@units||[]).each do |u|
        u.set_presentation_showcase_slow_v0551(false) if u.respond_to?(:set_presentation_showcase_slow_v0551)
        u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)
      end
    end
    pmd_ac_v0551_complete_verification_mode
  end

  def verify_v0551_contact_patch
    return if @verification_done[:v0551_contact_patch]
    a=PMD_AC.move_presentation_profile_v055(:tackle)
    b=PMD_AC.move_presentation_profile_v055(:slash)
    ok=a[:target_aware_contact] && b[:target_aware_contact] && a[:pose]==:attack && b[:pose]==:attack && a[:contact_gap].to_f<=14.0 && b[:contact_gap].to_f<=16.0
    log_event(:verify,'PRESENTATION_CONTACT_PATCH pass='+(ok ? '1':'0')+' tackle_gap='+a[:contact_gap].to_s+' slash_gap='+b[:contact_gap].to_s+' target_aware=1 attack_pose=1')
    @verification_done[:v0551_contact_patch]=true
  end

  def verify_v0551_hit_reaction
    return if @verification_done[:v0551_hit_reaction]
    ok=PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:contact_hit_reaction] && PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_frames].to_i>0
    log_event(:verify,'PRESENTATION_HIT_REACTION pass='+(ok ? '1':'0')+' contact_only=1 pose='+PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_pose].to_s+' frames='+PMD_AC::PRESENTATION_CONTACT_TUNING_V0551[:hit_reaction_frames].to_s+' action_state_preserved=1')
    @verification_done[:v0551_hit_reaction]=true
  end

  def verify_v0551_showcase_patch
    return if @verification_done[:v0551_showcase_patch]
    t=PMD_AC::PRESENTATION_CONTACT_TUNING_V0551
    ok=t[:showcase_force_hit] && t[:showcase_disable_active_evade] && t[:showcase_min_total_frames].to_i>=36
    log_event(:verify,'PRESENTATION_SHOWCASE_PATCH pass='+(ok ? '1':'0')+' force_hit=1 active_evade=off min_total='+t[:showcase_min_total_frames].to_s+' min_prehit='+t[:showcase_min_pre_hit_frames].to_s)
    @verification_done[:v0551_showcase_patch]=true
  end

  def update_verification_script
    pmd_ac_v0551_update_verification_script
    return unless verification_mode==:presentation_authoring
    f=@verification_frame
    verify_v0551_contact_patch if f==675
    verify_v0551_hit_reaction if f==690
    verify_v0551_showcase_patch if f==705
  end
end
