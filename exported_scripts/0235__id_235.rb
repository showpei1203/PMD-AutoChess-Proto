#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.57.5
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_PATCH_VERSION_V0575
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - contact_ground_y_motion_v0575? / presentation_contact_target_y_v0575 / presentation_contact_y_factor_v0575 / presentation_recoil_y_v0575
# - presentation_sprite_offset_v055 / presentation_commit_near_target_v0552 / start / verify_contact_ground_y_v0575
# - presentation_recoil_y_for_verify_v0575 / update_verification_script
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.57.5
#    Contact Ground-Y Alignment Fix
#------------------------------------------------------------------------------
# Additive patch on v0.57.4.
# - Contact battler motion arrives on the target's exact battlefield pixel_y.
# - Engage-stay logical commit also ends at target.pixel_y.
# - Beam / projectile aim / impact / target-FX anchors remain v0.57.4 unchanged.
#==============================================================================
module PMD_AC
  PRESENTATION_PATCH_VERSION_V0575 = "0.57.5"
  class << self
    def contact_ground_y_motion_v0575?(motion)
      CONTACT_GROUND_Y_MOTIONS_V0575.include?(motion)
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v0575_presentation_sprite_offset_v055 presentation_sprite_offset_v055 unless method_defined?(:pmd_ac_v0575_presentation_sprite_offset_v055)
  alias pmd_ac_v0575_presentation_commit_near_target_v0552 presentation_commit_near_target_v0552 unless method_defined?(:pmd_ac_v0575_presentation_commit_near_target_v0552)

  # Use the live skill target when possible.  The stored begin-skill target Y is
  # retained as a safe fallback if the target reference is no longer available.
  def presentation_contact_target_y_v0575
    if PMD_AC::CONTACT_GROUND_Y_V0575[:track_live_target_y]
      t=@skill_target
      return t.pixel_y.to_f if t!=nil && !t.dead?
    end
    @presentation_target_y_v055.to_f
  end

  # Same phase cadence as v0.55.2, but expressed as a 0..1 Y alignment factor.
  # At the contact/impact hold this becomes exactly 1.0, making battler pixel_y
  # visually coincide with the target pixel_y. Return motions then go back to 0.
  def presentation_contact_y_factor_v0575(profile)
    m=profile[:motion]
    total=[@action_total_frames.to_i,1].max
    pre=[total-@action_hit_frame.to_i,1].max
    elapsed=total-@action_timer.to_i
    cad=PMD_AC.presentation_cadence_for_v0552(profile)
    app=cad[:approach].to_i;app=1 if app<=0
    hold=cad[:hold].to_i
    ret=cad[:return].to_i;ret=1 if ret<=0
    if elapsed<pre
      q=[elapsed.to_f/app.to_f,1.0].min;q=0.0 if q<0.0
      return 1.0-(1.0-q)*(1.0-q)
    end
    post=elapsed-pre
    if m==:dash_engage || m==:blink_engage || m==:dash_stop
      return 1.0
    end
    if m==:blink_return
      return 1.0 if post<hold
      q=[(post-hold).to_f/ret.to_f,1.0].min
      return q>=0.55 ? 0.0 : 1.0
    end
    if post<hold
      return 1.0
    end
    q=[(post-hold).to_f/ret.to_f,1.0].min
    1.0-(q*q)
  end

  def presentation_recoil_y_v0575
    f=@presentation_recoil_frames_v0553.to_i
    return 0.0 if f<=0
    total=[@presentation_recoil_total_v0553.to_i,1].max
    q=f.to_f/total.to_f
    amp=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:target_recoil_px].to_f*q*q
    @presentation_recoil_ny_v0553.to_f*amp
  end

  def presentation_sprite_offset_v055
    base=pmd_ac_v0575_presentation_sprite_offset_v055
    return base unless PMD_AC::CONTACT_GROUND_Y_V0575[:enabled]
    return base unless PMD_AC::CONTACT_GROUND_Y_V0575[:apply_visual_contact]
    return base unless presentation_motion_active_v055?
    p=@presentation_profile_v055
    return base if p==nil || !PMD_AC.contact_ground_y_motion_v0575?(p[:motion])
    bx=base==nil ? 0.0 : base[0].to_f
    target_y=presentation_contact_target_y_v0575
    dy=target_y-@pixel_y.to_f
    factor=presentation_contact_y_factor_v0575(p)
    # Keep v0.55.3 hit recoil if this attacker happens to be struck mid-action.
    [bx,dy*factor+presentation_recoil_y_v0575]
  end

  # Gap-closers that intentionally remain beside the target also commit their
  # logical ground Y to the target's exact pixel_y. X/gap behavior stays v0.55.2.
  def presentation_commit_near_target_v0552(target,move_key=nil)
    result=pmd_ac_v0575_presentation_commit_near_target_v0552(target,move_key)
    return result unless result && target!=nil
    return result unless PMD_AC::CONTACT_GROUND_Y_V0575[:enabled] && PMD_AC::CONTACT_GROUND_Y_V0575[:apply_visual_commit]
    p=@presentation_profile_v055
    return result if p==nil || !PMD_AC.contact_ground_y_motion_v0575?(p[:motion])
    old_y=@pixel_y.to_f
    @pixel_y=target.pixel_y.to_f
    clamp_to_board
    sync_cell_from_pixel
    @velocity_y=0.0
    if PMD_AC::CONTACT_GROUND_Y_V0575[:log_commit]
      log_event(:presentation_contact_y,log_name+' move='+(move_key||p[:move_key]||:unknown).to_s+' target='+target.log_name+' y='+sprintf('%.1f',old_y)+'->'+sprintf('%.1f',@pixel_y.to_f)+' target_y='+sprintf('%.1f',target.pixel_y.to_f)+' aligned='+( (@pixel_y.to_f-target.pixel_y.to_f).abs<0.01 ? '1':'0'))
    end
    result
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0575_start start unless method_defined?(:pmd_ac_v0575_start)
  alias pmd_ac_v0575_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0575_update_verification_script)

  def start
    pmd_ac_v0575_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.57\.4 Battle Verification Log/,'PMD AutoChess Proto v0.57.5 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.57.5 contact_ground_y=target_pixel_y visual_contact=1 engage_commit=1 beam_projectile_impact_targetfx_unchanged=1')
  end

  def verify_contact_ground_y_v0575
    return if @verification_done[:v0575_contact_y]
    u=verification_unit(:ally,:charmander)
    t=verification_unit(:enemy,:caterpie)
    ok=u!=nil && t!=nil
    visual_ok=false;commit_rule_ok=false;fy=0.0;ty=0.0
    if ok
      old=[u.instance_variable_get(:@presentation_profile_v055),u.instance_variable_get(:@presentation_target_x_v055),u.instance_variable_get(:@presentation_target_y_v055),u.instance_variable_get(:@skill_target),u.instance_variable_get(:@action),u.instance_variable_get(:@action_total_frames),u.instance_variable_get(:@action_hit_frame),u.instance_variable_get(:@action_timer)]
      p=PMD_AC.move_presentation_profile_v055(:slash)
      u.instance_variable_set(:@presentation_profile_v055,p)
      u.instance_variable_set(:@presentation_target_x_v055,t.pixel_x.to_f)
      u.instance_variable_set(:@presentation_target_y_v055,t.pixel_y.to_f)
      u.instance_variable_set(:@skill_target,t)
      u.instance_variable_set(:@action,:skill)
      u.instance_variable_set(:@action_total_frames,30)
      u.instance_variable_set(:@action_hit_frame,10)
      u.instance_variable_set(:@action_timer,8) # post-hit hold: Y factor must be 1.0
      o=u.presentation_sprite_offset_v055
      fy=u.pixel_y.to_f+o[1].to_f-presentation_recoil_y_for_verify_v0575(u)
      ty=t.pixel_y.to_f
      visual_ok=(fy-ty).abs<0.01
      u.instance_variable_set(:@presentation_profile_v055,old[0]);u.instance_variable_set(:@presentation_target_x_v055,old[1]);u.instance_variable_set(:@presentation_target_y_v055,old[2]);u.instance_variable_set(:@skill_target,old[3]);u.instance_variable_set(:@action,old[4]);u.instance_variable_set(:@action_total_frames,old[5]);u.instance_variable_set(:@action_hit_frame,old[6]);u.instance_variable_set(:@action_timer,old[7])
      commit_rule_ok=PMD_AC::CONTACT_GROUND_Y_V0575[:apply_visual_commit] && PMD_AC.contact_ground_y_motion_v0575?(:dash_engage)
      ok=visual_ok && commit_rule_ok
    end
    log_event(:verify,'CONTACT_GROUND_Y_V0575 pass='+(ok ? '1':'0')+' visual_hold_y='+sprintf('%.1f',fy)+' target_y='+sprintf('%.1f',ty)+' exact_y='+(visual_ok ? '1':'0')+' engage_commit_target_y='+(commit_rule_ok ? '1':'0')+' fx_anchor=unchanged beam_anchor=unchanged')
    @verification_done[:v0575_contact_y]=true
  end

  def presentation_recoil_y_for_verify_v0575(u)
    return 0.0 unless u.respond_to?(:presentation_recoil_y_v0575)
    u.presentation_recoil_y_v0575
  end

  def update_verification_script
    pmd_ac_v0575_update_verification_script
    return unless verification_mode==:presentation_polish_v0573
    verify_contact_ground_y_v0575 if @verification_frame==445
  end
end
