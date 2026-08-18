#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.59.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0591 / TRIPLE_KICK_GAP_V0591 / TRIPLE_KICK_MIN_LEAD_V0591 / TRIPLE_KICK_MAX_LEAD_V0591
# - PRESENTATION_FIX_END_FRAME_V0591 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - presentation_showcase_v0553? / start / update / projectile_style
# - triple_kick_hit_lead_v0591 / apply_triple_kick_v059 / update_triple_kick_v059 / canonical_accuracy_hit?
# - projectile_tracking_for / complete_verification_mode / prepare_verification_battle / force_fix_demo_v0591
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.59.1
#    Triple Kick Pose Sequencing + Projectile Aim-Anchor Collision Fix
#------------------------------------------------------------------------------
# Focused additive runtime patch on v0.59.
# - Triple Kick keeps its canonical three damage packets (10/20/30), but now
#   starts a fresh PMD Attack pose before hit 2 and hit 3 and waits until that
#   action's visible hit timing before resolving each packet.
# - Logical projectile collision now checks the same lower-body aim anchor used
#   by projectile tracking.  v0.57.4 target-bound Impact/FX placement remains
#   untouched.
# - Newer move batches route projectile sprites from the current v0.31 visual
#   profile instead of falling back to the caster species projectile style.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0591 = "0.59.1"
  TRIPLE_KICK_GAP_V0591 = 4
  TRIPLE_KICK_MIN_LEAD_V0591 = 7
  TRIPLE_KICK_MAX_LEAD_V0591 = 12
  PRESENTATION_FIX_END_FRAME_V0591 = 650

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :presentation_fix_v0591,
    :visual_showcase_x,
    :move_coverage_x,
    :presentation_polish_v0573,
    :visual_showcase_ix
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :presentation_fix_v0591 => 'PRESENTATION_FIX_V0591',
    :visual_showcase_x      => 'VISUAL_SHOWCASE_X',
    :move_coverage_x        => 'MOVE_COVERAGE_X',
    :presentation_polish_v0573 => 'PRESENTATION_POLISH_V0573',
    :visual_showcase_ix     => 'VISUAL_SHOWCASE_IX'
  }
end

class Game_PMDChessUnit
  alias pmd_ac_v0591_presentation_showcase_v0553 presentation_showcase_v0553? unless method_defined?(:pmd_ac_v0591_presentation_showcase_v0553)
  def presentation_showcase_v0553?
    if @scene != nil && @scene.respond_to?(:verification_mode)
      return true if @scene.verification_mode == :presentation_fix_v0591
    end
    pmd_ac_v0591_presentation_showcase_v0553
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0591_start start unless method_defined?(:pmd_ac_v0591_start)
  alias pmd_ac_v0591_update update unless method_defined?(:pmd_ac_v0591_update)
  alias pmd_ac_v0591_projectile_style projectile_style unless method_defined?(:pmd_ac_v0591_projectile_style)
  alias pmd_ac_v0591_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v0591_canonical_accuracy_hit)
  alias pmd_ac_v0591_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v0591_projectile_tracking_for)
  alias pmd_ac_v0591_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0591_prepare_verification_battle)
  alias pmd_ac_v0591_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0591_update_verification_script)
  alias pmd_ac_v0591_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0591_complete_verification_mode)

  def start
    pmd_ac_v0591_start
    @triple_kick_pose_count_v0591 = 0
    @triple_kick_hit_frames_v0591 = []
    @projectile_anchor_hits_v0591 = []
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t = File.open(PMD_AC::BATTLE_LOG_FILE, 'rb') { |f| f.read }
        t.sub!(/PMD AutoChess Proto v0\.59 Battle Verification Log/,
               'PMD AutoChess Proto v0.59.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE, 'wb') { |f| f.write(t) }
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.59.1 triple_kick=pose_then_hit_per_packet projectile_collision=aim_anchor projectile_style=current_move_profile target_fx=v0.57.4_unchanged beam=unchanged')
  end

  def update
    pmd_ac_v0591_update
  end

  #--------------------------------------------------------------------------
  # New move batches define their visual profile through the current v0.31
  # accessor.  Older projectile_style ultimately queried the frozen v0.30 move
  # table, so a Squirtle could fire a water sprite for Sacred Fire.
  #--------------------------------------------------------------------------
  def projectile_style(user, kind, effect_type)
    if effect_type != nil
      data = PMD_AC.skill_data(effect_type)
      if data != nil && data[:canonical_move_key] != nil
        mk = data[:canonical_move_key]
        # Preserve the already verified dynamic Weather Ball routing.
        return pmd_ac_v0591_projectile_style(user, kind, effect_type) if mk == :weather_ball
        visual = PMD_AC.skill_visual_move_profile_v031(mk)
        if visual != nil && visual[:style] != nil
          style = visual[:style]
          return style if PMD_AC.skill_visual_projectile_profile_v030(style) != nil
        end
      end
    end
    pmd_ac_v0591_projectile_style(user, kind, effect_type)
  end

  #--------------------------------------------------------------------------
  # Triple Kick: first hit is still resolved by the canonical skill impact.
  # Hit 2/3 now use two phases: restart Attack pose, wait to that species'
  # visible Attack hit timing, then resolve damage.  This prevents three damage
  # packets being crammed into one visible kick.
  #--------------------------------------------------------------------------
  def triple_kick_hit_lead_v0591(user)
    timing = PMD_AC.action_timing(user.species, :attack, 18, 8)
    lead = timing[0].to_i - timing[1].to_i
    lead = PMD_AC::TRIPLE_KICK_MIN_LEAD_V0591 if lead < PMD_AC::TRIPLE_KICK_MIN_LEAD_V0591
    lead = PMD_AC::TRIPLE_KICK_MAX_LEAD_V0591 if lead > PMD_AC::TRIPLE_KICK_MAX_LEAD_V0591
    lead
  end

  def apply_triple_kick_v059(user, target, data, scale)
    return 0 if user == nil || target == nil || target.dead?
    single = data.dup
    single[:triple_kick_v059] = false
    single[:effects] = (data[:effects] || []).collect do |e|
      x = e.dup
      x[:power] = 10 if x[:type] == :damage
      x
    end
    first = pmd_ac_v059_apply_skill_effects(user, target, single, scale).to_i
    @triple_kick_pose_count_v0591 = 1
    @triple_kick_hit_frames_v0591 = [Graphics.frame_count]
    return first if target.dead?

    lead = triple_kick_hit_lead_v0591(user)
    gap = PMD_AC::TRIPLE_KICK_GAP_V0591
    extra = (gap + lead) * 2 + 4
    extend_multi_hit_action_v0572(user, extra) if respond_to?(:extend_multi_hit_action_v0572)
    @triple_kick_events_v059 = [] if @triple_kick_events_v059 == nil
    @triple_kick_events_v059.push({
      :user => user, :target => target, :data => single, :scale => scale,
      :next_frame => Graphics.frame_count + gap, :hit => 2,
      :total => first, :phase => :pose, :lead => lead
    })
    log_event(:multi_sequence,
      user.log_name + ' move=triple_kick START hits=3 first_damage=' + first.to_s +
      ' mode=pose_then_hit gap=' + gap.to_s + ' hit_lead=' + lead.to_s +
      ' powers=10,20,30')
    first
  end

  def update_triple_kick_v059
    return if @triple_kick_events_v059 == nil || @triple_kick_events_v059.empty?
    now = Graphics.frame_count
    keep = []
    @triple_kick_events_v059.each do |q|
      user = q[:user]
      target = q[:target]
      next if user == nil || target == nil || user.dead? || target.dead?
      if now < q[:next_frame].to_i
        keep.push(q)
        next
      end

      h = q[:hit].to_i
      if q[:phase] == :pose
        restart_unit_pose_v0572(user, :attack) if respond_to?(:restart_unit_pose_v0572)
        play_skill_se(user, :launch, q[:data])
        @triple_kick_pose_count_v0591 = @triple_kick_pose_count_v0591.to_i + 1
        log_event(:multi_sequence,
          user.log_name + ' move=triple_kick POSE ' + h.to_s + '/3 lead=' + q[:lead].to_i.to_s)
        q[:phase] = :hit
        q[:next_frame] = now + q[:lead].to_i
        keep.push(q)
        next
      end

      power = h == 2 ? 20 : 30
      d = q[:data].dup
      d[:effects] = (q[:data][:effects] || []).collect do |e|
        x = e.dup
        x[:power] = power if x[:type] == :damage
        x
      end
      dmg = pmd_ac_v059_apply_skill_effects(user, target, d, q[:scale]).to_i
      q[:total] = q[:total].to_i + dmg
      @triple_kick_hit_frames_v0591.push(now)
      log_event(:multi_sequence,
        user.log_name + ' move=triple_kick HIT ' + h.to_s + '/3 power=' +
        power.to_s + ' damage=' + dmg.to_s + ' total=' + q[:total].to_s)

      if h >= 3 || target.dead?
        log_event(:multi_sequence,
          user.log_name + ' move=triple_kick COMPLETE hits=' + h.to_s +
          '/3 total_damage=' + q[:total].to_s + ' pose_count=' +
          @triple_kick_pose_count_v0591.to_i.to_s)
      else
        q[:hit] = h + 1
        q[:phase] = :pose
        q[:next_frame] = now + PMD_AC::TRIPLE_KICK_GAP_V0591
        keep.push(q)
      end
    end
    @triple_kick_events_v059 = keep
  end

  def canonical_accuracy_hit?(user, target, data, log_check=true)
    return true if verification_mode == :presentation_fix_v0591
    pmd_ac_v0591_canonical_accuracy_hit(user, target, data, log_check)
  end

  def projectile_tracking_for(user, kind, effect_type)
    return :perfect if verification_mode == :presentation_fix_v0591
    pmd_ac_v0591_projectile_tracking_for(user, kind, effect_type)
  end

  def complete_verification_mode
    if verification_mode == :presentation_fix_v0591
      (@units || []).each do |u|
        u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)
      end
    end
    pmd_ac_v0591_complete_verification_mode
  end

  def prepare_verification_battle
    pmd_ac_v0591_prepare_verification_battle
    return unless verification_mode == :presentation_fix_v0591
    (@units || []).each do |u|
      u.verification_combat_sandbox(true)
      u.verification_energy_sandbox(true)
      u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
    end
    @triple_kick_pose_count_v0591 = 0
    @triple_kick_hit_frames_v0591 = []
    @projectile_anchor_hits_v0591 = []
    @presentation_fix_step_v0591 = 0
    log_event(:showcase,
      'START mode=PRESENTATION_FIX_V0591 triple_kick=3_real_poses projectile_collision=aim_anchor tracking=perfect')
  end

  def force_fix_demo_v0591(skill_key, user, target, label)
    showcase_reset_unit_v059(user) if respond_to?(:showcase_reset_unit_v059)
    showcase_reset_unit_v059(target) if respond_to?(:showcase_reset_unit_v059)
    user.verification_force_skill(skill_key, target)
    log_event(:showcase,
      'FIX_DEMO ' + label + ' caster=' + user.log_name + ' target=' + target.log_name)
  end

  def verify_presentation_fix_v0591
    return if @verification_done[:v0591_fix]
    frames = @triple_kick_hit_frames_v0591 || []
    gaps = []
    i = 1
    while i < frames.size
      gaps.push(frames[i].to_i - frames[i-1].to_i)
      i += 1
    end
    triple_ok = (@triple_kick_pose_count_v0591.to_i >= 3 && frames.size >= 3 && gaps.all? { |g| g >= 7 })
    ph = @projectile_anchor_hits_v0591 || []
    fire = ph.find_all { |x| x[:style] == :fire }
    projectile_ok = fire.size >= 3 && fire.all? { |x| x[:travel].to_i < 90 }
    log_event(:verify,
      'TRIPLE_KICK_VISUAL_V0591 pass=' + (triple_ok ? '1' : '0') +
      ' pose_count=' + @triple_kick_pose_count_v0591.to_i.to_s +
      ' hit_frames=' + frames.join(',') + ' gaps=' + gaps.join(','))
    log_event(:verify,
      'PROJECTILE_ANCHOR_COLLISION_V0591 pass=' + (projectile_ok ? '1' : '0') +
      ' fire_hits=' + fire.size.to_s + ' travel_frames=' + fire.collect { |x| x[:travel] }.join(',') +
      ' target_fx=v0.57.4_unchanged beam=unchanged')
    log_event(:verify,
      'PROJECTILE_STYLE_ROUTE_V0591 pass=' + (fire.size >= 3 ? '1' : '0') +
      ' expected=fire moves=incinerate,magma_storm,sacred_fire caster_species=squirtle')
    @verification_done[:v0591_fix] = true
  end

  def update_presentation_fix_v0591
    f = @verification_frame
    ally_squirtle = verification_unit(:ally, :squirtle)
    enemy_pikachu = verification_unit(:enemy, :pikachu)
    if f == 70
      force_fix_demo_v0591(:mv_triple_kick, ally_squirtle, enemy_pikachu, '01 triple_kick')
    elsif f == 210
      force_fix_demo_v0591(:mv_incinerate, ally_squirtle, enemy_pikachu, '02 incinerate')
    elsif f == 340
      force_fix_demo_v0591(:mv_magma_storm, ally_squirtle, enemy_pikachu, '03 magma_storm')
    elsif f == 470
      force_fix_demo_v0591(:mv_sacred_fire, ally_squirtle, enemy_pikachu, '04 sacred_fire')
    elsif f == 600
      verify_presentation_fix_v0591
    elsif f == PMD_AC::PRESENTATION_FIX_END_FRAME_V0591
      complete_verification_mode
    end
  end

  def update_verification_script
    pmd_ac_v0591_update_verification_script
    if verification_mode == :presentation_fix_v0591
      update_presentation_fix_v0591
      return
    end
  end
end

#==============================================================================
# ■ Projectile trajectory/collision alignment
#------------------------------------------------------------------------------
# v0.57.3 intentionally tracks toward the target's lower-body aim anchor, while
# the old collision circle still lived at target.pixel_y (ground baseline).
# Some projectiles therefore reached their visible destination but never hit,
# animating there until PROJECTILE_LIFE expired.  Add a second collision test
# centered on the actual tracking anchor.  Sprite_PMDProjectile#hit remains the
# v0.57.4 implementation, so target Impact/FX still plays at legacy center.
#==============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v0591_initialize initialize unless method_defined?(:pmd_ac_v0591_initialize)
  alias pmd_ac_v0591_update update unless method_defined?(:pmd_ac_v0591_update)

  def initialize(*args)
    pmd_ac_v0591_initialize(*args)
    @pmd_v0591_birth_frame = Graphics.frame_count
  end

  def update
    return pmd_ac_v0591_update if @finished
    old_x = @x_f
    old_y = @y_f
    pmd_ac_v0591_update
    return if @finished
    return if @scene == nil || @target == nil || !@target.alive?
    return unless @scene.respond_to?(:effect_anchor_xy)
    anchor = @scene.effect_anchor_xy(@target, false)
    return if anchor == nil
    radius = @target.collision_radius.to_f + @radius.to_f
    if @scene.segment_circle_hit?(old_x, old_y, @x_f, @y_f,
                                  anchor[0].to_f, anchor[1].to_f, radius)
      travel = Graphics.frame_count - @pmd_v0591_birth_frame.to_i
      move_key = nil
      begin
        data = PMD_AC.skill_data(@effect_type)
        move_key = data[:canonical_move_key] if data != nil
      rescue
        move_key = nil
      end
      @scene.log_event(:projectile_anchor_hit,
        @user.log_name + ' -> ' + @target.log_name + ' move=' +
        (move_key == nil ? 'unknown' : move_key.to_s) + ' style=' + @style.to_s +
        ' travel_frames=' + travel.to_s + ' anchor=(' + anchor[0].to_i.to_s + ',' +
        anchor[1].to_i.to_s + ')')
      if @scene.instance_variable_get(:@projectile_anchor_hits_v0591) != nil
        a = @scene.instance_variable_get(:@projectile_anchor_hits_v0591)
        a.push({:move => move_key, :style => @style, :travel => travel})
      end
      hit(anchor[0], anchor[1])
    end
  end
end
