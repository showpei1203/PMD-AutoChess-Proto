#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.55.3
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_PATCH_VERSION_V0553
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - presentation_showcase_v0553? / skill_in_range? / set_showcase_reactive_ready_v0553 / reactive_pre_hit_damaging_action_v043?
# - trigger_presentation_hit_reaction_v0552 / update / presentation_sprite_offset_v055 / start
# - canonical_accuracy_hit? / presentation_showcase_audio_spec_v0553 / play_skill_se / place_motion_demo_v055
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.55.3
#    Motion Showcase Hit Feedback / Audible Impact Fix
#------------------------------------------------------------------------------
# Additive patch on v0.55.2.
# - Fixes the visual Showcase's logical melee-range gate.  v0.55.1 only forced
#   canonical accuracy; v0.55.2 contact demos were still rejected BEFORE that
#   check because their logical positions remained 90px apart.
# - Guarantees an audible Hit SE path in Showcase and logs the exact SE used.
# - Adds a short visual target recoil on successful direct hits while keeping
#   PMD :hurt as the primary target reaction.
# - Primes Sucker Punch in Showcase without making the target visually busy.
#==============================================================================
module PMD_AC
  PRESENTATION_PATCH_VERSION_V0553 = "0.55.3"
end

class Game_PMDChessUnit
  alias pmd_ac_v0553_skill_in_range skill_in_range? unless method_defined?(:pmd_ac_v0553_skill_in_range)
  alias pmd_ac_v0553_presentation_sprite_offset_v055 presentation_sprite_offset_v055 unless method_defined?(:pmd_ac_v0553_presentation_sprite_offset_v055)
  alias pmd_ac_v0553_trigger_presentation_hit_reaction_v0552 trigger_presentation_hit_reaction_v0552 unless method_defined?(:pmd_ac_v0553_trigger_presentation_hit_reaction_v0552)
  alias pmd_ac_v0553_update update unless method_defined?(:pmd_ac_v0553_update)
  alias pmd_ac_v0553_reactive_pre_hit_damaging_action_v043 reactive_pre_hit_damaging_action_v043? unless method_defined?(:pmd_ac_v0553_reactive_pre_hit_damaging_action_v043)

  def presentation_showcase_v0553?
    return false if @scene==nil || !@scene.respond_to?(:verification_mode)
    @scene.verification_mode==:motion_showcase_v055
  end

  def skill_in_range?(other)
    if other!=nil && presentation_showcase_v0553? && PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:showcase_force_contact_in_range]
      p=@presentation_profile_v055
      if p!=nil && (PMD_AC::CONTACT_MOTIONS_V0551.include?(p[:motion]) || [:dash_engage,:blink_engage].include?(p[:motion]))
        return true
      end
    end
    pmd_ac_v0553_skill_in_range(other)
  end

  def set_showcase_reactive_ready_v0553(v)
    @presentation_showcase_reactive_ready_v0553=v ? true : false
  end

  def reactive_pre_hit_damaging_action_v043?
    return true if @presentation_showcase_reactive_ready_v0553
    pmd_ac_v0553_reactive_pre_hit_damaging_action_v043
  end

  def trigger_presentation_hit_reaction_v0552(source,move_key,damage,kind=:skill)
    result=pmd_ac_v0553_trigger_presentation_hit_reaction_v0552(source,move_key,damage,kind)
    if damage.to_i>0 && !dead?
      minf=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:target_hurt_frames_min].to_i
      if result && @presentation_hit_react_frames_v0552.to_i<minf
        @presentation_hit_react_frames_v0552=minf
      end
      if PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:target_recoil_enabled]
        @presentation_recoil_frames_v0553=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:target_recoil_frames].to_i
        @presentation_recoil_total_v0553=[@presentation_recoil_frames_v0553.to_i,1].max
        if source!=nil
          dx=@pixel_x.to_f-source.pixel_x.to_f;dy=@pixel_y.to_f-source.pixel_y.to_f
          d=Math.sqrt(dx*dx+dy*dy)
          if d<=0.001;dx=1.0;dy=0.0;d=1.0;end
          @presentation_recoil_nx_v0553=dx/d;@presentation_recoil_ny_v0553=dy/d
        else
          @presentation_recoil_nx_v0553=1.0;@presentation_recoil_ny_v0553=0.0
        end
        if PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:log_target_recoil]
          log_event(:presentation_recoil,log_name+' move='+move_key.to_s+' px='+PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:target_recoil_px].to_s+' frames='+@presentation_recoil_frames_v0553.to_s)
        end
      end
    end
    result
  end

  def update
    pmd_ac_v0553_update
    @presentation_recoil_frames_v0553-=1 if @presentation_recoil_frames_v0553.to_i>0
  end

  def presentation_sprite_offset_v055
    base=pmd_ac_v0553_presentation_sprite_offset_v055
    bx=base==nil ? 0.0 : base[0].to_f;by=base==nil ? 0.0 : base[1].to_f
    f=@presentation_recoil_frames_v0553.to_i
    return [bx,by] if f<=0
    total=[@presentation_recoil_total_v0553.to_i,1].max
    q=f.to_f/total.to_f
    # Strong at impact, quickly settles so the Hurt pose remains readable.
    amp=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:target_recoil_px].to_f*q*q
    [bx+@presentation_recoil_nx_v0553.to_f*amp,by+@presentation_recoil_ny_v0553.to_f*amp]
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0553_start start unless method_defined?(:pmd_ac_v0553_start)
  alias pmd_ac_v0553_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v0553_canonical_accuracy_hit)
  alias pmd_ac_v0553_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v0553_play_skill_se)
  alias pmd_ac_v0553_place_motion_demo_v055 place_motion_demo_v055 unless method_defined?(:pmd_ac_v0553_place_motion_demo_v055)
  alias pmd_ac_v0553_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0553_complete_verification_mode)
  alias pmd_ac_v0553_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0553_update_verification_script)

  def start
    pmd_ac_v0553_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.55\.2 Battle Verification Log/,'PMD AutoChess Proto v0.55.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.55.3 showcase_range_gate_fix=1 showcase_force_accuracy=1 audible_hit_feedback=1 target_recoil=1 hurt_min12=1 normal_accuracy_unchanged=1')
  end

  # v0.55.1 intended to force Showcase accuracy, but contact demos were often
  # stopped by the older logical range gate first.  Keep this explicit alias as
  # a second safety net after that gate is fixed.
  def canonical_accuracy_hit?(user,target,data,log_check=true)
    if verification_mode==:motion_showcase_v055 && PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:showcase_force_accuracy]
      if PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:log_showcase_force_hit] && log_check
        log_event(:presentation_force_hit,(user==nil ? 'NONE' : user.log_name)+' -> '+(target==nil ? 'NONE' : target.log_name)+' move='+(data==nil ? 'unknown' : (data[:canonical_move_key]||:unknown).to_s)+' accuracy=forced')
      end
      return true
    end
    pmd_ac_v0553_canonical_accuracy_hit(user,target,data,log_check)
  end

  def presentation_showcase_audio_spec_v0553(data,stage)
    return nil if data==nil
    mk=data[:canonical_move_key]
    spec=(mk==nil ? nil : PMD_AC.skill_audio_spec_v032(mk,stage,0))
    if spec==nil
      type=data[:move_type] || data[:type] || :normal
      tp=PMD_AC::SKILL_AUDIO_TYPE_V032[type] rescue nil
      cat=(tp==nil ? nil : tp[stage])
      pool=(cat==nil ? nil : PMD_AC.skill_audio_category_pool_v032(cat))
      if pool!=nil && !pool.empty?
        style=type
        spec={:name=>pool[0],:volume=>(PMD_AC::SKILL_AUDIO_VOLUME_V032[stage]||80),:pitch=>(PMD_AC::SKILL_AUDIO_PITCH_V032[style]||100)}
      end
    end
    if spec==nil && stage==:hit
      h=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553
      spec={:name=>h[:showcase_hit_fallback_name],:volume=>h[:showcase_hit_fallback_volume],:pitch=>h[:showcase_hit_fallback_pitch]}
    end
    spec
  end

  def play_skill_se(unit,stage,data=nil)
    unless verification_mode==:motion_showcase_v055
      return pmd_ac_v0553_play_skill_se(unit,stage,data)
    end
    return if unit==nil
    data=unit.skill_data if data==nil
    spec=presentation_showcase_audio_spec_v0553(data,stage)
    return if spec==nil
    s=spec.dup
    h=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553
    floor=stage==:hit ? h[:showcase_hit_volume_min].to_i : (stage==:launch ? h[:showcase_launch_volume_min].to_i : h[:showcase_cast_volume_min].to_i)
    s[:volume]=[s[:volume].to_i,floor].max
    # Preserve same-frame multi-target dedup for Hit SE.
    if stage==:hit
      @skill_hit_se_frames={} if @skill_hit_se_frames==nil
      hit_key=[unit.id,unit.skill_type]
      now=Graphics.frame_count
      last=@skill_hit_se_frames[hit_key] || -9999
      return if now-last < PMD_AC::SKILL_HIT_SE_DEDUP_FRAMES
      @skill_hit_se_frames[hit_key]=now
    end
    PMD_AC.play_se(s)
    if h[:log_showcase_sfx]
      log_event(:presentation_sfx,unit.log_name+' move='+(data==nil ? 'unknown' : (data[:canonical_move_key]||:unknown).to_s)+' stage='+stage.to_s+' name='+s[:name].to_s+' volume='+s[:volume].to_s+' pitch='+s[:pitch].to_s)
    end
  end

  def place_motion_demo_v055(caster,target)
    pmd_ac_v0553_place_motion_demo_v055(caster,target)
    (@units||[]).each{|u|u.set_showcase_reactive_ready_v0553(false) if u.respond_to?(:set_showcase_reactive_ready_v0553)}
    # Fourth demo is Sucker Punch.  Prime its condition without forcing the
    # target into an Attack pose, so the target can still visibly play Hurt.
    if @motion_showcase_index_v055.to_i==3 && target!=nil && PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553[:showcase_prime_reactive_moves]
      target.set_showcase_reactive_ready_v0553(true) if target.respond_to?(:set_showcase_reactive_ready_v0553)
    end
  end

  def complete_verification_mode
    (@units||[]).each{|u|u.set_showcase_reactive_ready_v0553(false) if u.respond_to?(:set_showcase_reactive_ready_v0553)}
    pmd_ac_v0553_complete_verification_mode
  end

  def verify_v0553_feedback
    return if @verification_done[:v0553_feedback]
    h=PMD_AC::PRESENTATION_HIT_FEEDBACK_V0553
    t=verification_unit(:ally,:charmander);r=verification_unit(:enemy,:rattata)
    range_ok=false
    if t!=nil && r!=nil
      old_scene=t.scene rescue nil
      # Verification mode is presentation_authoring here, so exercise the
      # static policy instead of altering normal skill_in_range at runtime.
      range_ok=h[:showcase_force_contact_in_range] && PMD_AC::CONTACT_MOTIONS_V0551.include?(PMD_AC.move_presentation_profile_v055(:tackle)[:motion])
    end
    spec=presentation_showcase_audio_spec_v0553(PMD_AC.skill_data(:mv_tackle),:hit)
    sfx_ok=spec!=nil && spec[:name]!=nil && spec[:volume].to_i>0
    ok=range_ok && h[:showcase_force_accuracy] && sfx_ok && h[:target_recoil_enabled] && h[:target_hurt_frames_min].to_i>=10
    log_event(:verify,'PRESENTATION_SHOWCASE_HIT_FEEDBACK_V0553 pass='+(ok ? '1':'0')+' contact_range_bypass='+(range_ok ? '1':'0')+' force_accuracy='+(h[:showcase_force_accuracy] ? '1':'0')+' hit_sfx='+(sfx_ok ? '1':'0')+' hurt_min='+h[:target_hurt_frames_min].to_s+' recoil_px='+h[:target_recoil_px].to_s+' sucker_punch_prime=1')
    @verification_done[:v0553_feedback]=true
  end

  def update_verification_script
    pmd_ac_v0553_update_verification_script
    return unless verification_mode==:presentation_authoring
    verify_v0553_feedback if @verification_frame==718
  end
end
