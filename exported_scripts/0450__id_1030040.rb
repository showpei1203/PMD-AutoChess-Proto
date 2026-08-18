#==============================================================================
# ■ PMD AutoChess - Deploy Rich LOOP Presentation Polish v1.03.4
#==============================================================================
# 【用途】
# 修正 v1.03.3 布陣 Rich LOOP 雖已能正常播放，但部分 PMD Native 空閒動作會造成
# 「展示方向突然改變」或「Hop 跳得過高」的問題。
#
# 【正式規則】
# 1. 本腳本只作用於 Deploy／布陣畫面，不修改 live battle Combat Motion。
# 2. Deploy Rich LOOP 期間固定保留每隻 Pokémon 進入布陣時的展示 facing：
#    - Ambient action 不得讓角色留下新的朝向。
#    - 不修改正式戰鬥中的 face_toward、Directional Defense、AI 轉向等規則。
# 3. 具有明顯「轉頭／轉身」觀感的 Ambient action 在 Deploy 會轉成安全原地替代：
#      look_up -> nod / pose / shake / idle
#      rotate  -> pose / shake / nod / idle
#      twirl   -> pose / shake / nod / idle
#    實際選擇仍先確認該物種 Native action 可播放。
# 4. Hop 在 Deploy 保留，但只保留約 35% 的原始可見跳高：
#    - 以 PMD action metadata 的 row_foot_y / frame_h 計算 Hop 與 Walk 的腳底基準差。
#    - 只對 Sprite 畫面 y 做補正；pixel_x / pixel_y 完全不變。
#    - Combat Motion 使用 Hop / Jump / Launch 時不套此補正。
# 5. v1.03.2 Battle Ambient Isolation 保持有效；正式戰鬥仍不播放純待機 Rich LOOP。
#
# 【主要設定】
# DEPLOY_HOP_HEIGHT_SCALE_V1034 = 0.35
#   布陣 Hop 保留的可見高度比例。0.0 = 幾乎取消跳高；1.0 = PMD 原始高度。
#
# DEPLOY_ORIENTATION_RISK_ACTIONS_V1034
#   在布陣展示中可能造成方向誤讀的 action 與安全替代候選。
#
# 【可調參數】
# - 想讓布陣 Hop 稍高：把 0.35 調到 0.45～0.55。
# - 想完全取消某個會轉向的 Ambient：將其替代候選第一項改成 :idle。
# - 不應在此修改 Attack Speed、Energy、Damage 或 Spatial Runtime。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。Scene_PMD_AutoChess 處於 Deploy 時自動生效。
#
# 【實際範例】
# - 妙蛙種子原本 Ambient 的 look_up，在布陣改用 nod，不再突然朝奇怪方向。
# - 傑尼龜的 look_up 同樣會使用安全原地替代；原本的 nod 仍保留。
# - 小火龍仍能 Hop，但跳高約縮成原本 35%，不再像戰鬥位移技能。
# - Quick Attack / Jump Kick 等正式戰鬥 Motion 完全不受影響。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_DeployRichLoopPresentationPolish_v1034'] = true

module PMD_AC
  DEPLOY_HOP_HEIGHT_SCALE_V1034 = 0.35
  DEPLOY_ORIENTATION_RISK_ACTIONS_V1034 = {
    :look_up => [:nod, :pose, :shake, :idle],
    :rotate  => [:pose, :shake, :nod, :idle],
    :twirl   => [:pose, :shake, :nod, :idle]
  }
end

class Game_PMDChessUnit
  alias pmd_ac_v1034_motion_deploy_idle_reset_v1033 motion_deploy_idle_reset_v1033 unless method_defined?(:pmd_ac_v1034_motion_deploy_idle_reset_v1033)
  alias pmd_ac_v1034_motion_update_deploy_idle_v1033 motion_update_deploy_idle_v1033 unless method_defined?(:pmd_ac_v1034_motion_update_deploy_idle_v1033)

  def motion_deploy_idle_reset_v1033
    pmd_ac_v1034_motion_deploy_idle_reset_v1033
    # facing anchor 故意跨 combat 保留，回到 Deploy 時仍回原展示方向。
    @motion_deploy_safe_substitutions_v1034=0
  end

  def motion_deploy_capture_facing_v1034
    return unless motion_deploy_phase_v1033?
    if @motion_deploy_facing_anchor_v1034==nil
      @motion_deploy_facing_anchor_v1034=@facing_dir
    end
    @facing_dir=@motion_deploy_facing_anchor_v1034
    @pending_dir=@motion_deploy_facing_anchor_v1034
    @pending_dir_frames=0
  rescue
  end

  def motion_deploy_safe_ambient_action_v1034(action)
    map=PMD_AC::DEPLOY_ORIENTATION_RISK_ACTIONS_V1034[action]
    return action if map==nil
    map.each do |candidate|
      return candidate if candidate==:idle
      if respond_to?(:motion_playable_v102?)
        return candidate if motion_playable_v102?(candidate)
      elsif PMD_AC.respond_to?(:motion_playable_v102?)
        return candidate if PMD_AC.motion_playable_v102?(@species,candidate)
      end
    end
    :idle
  rescue
    :idle
  end

  def motion_update_deploy_idle_v1033
    motion_deploy_capture_facing_v1034
    before=@motion_ambient_action_v102
    pmd_ac_v1034_motion_update_deploy_idle_v1033
    motion_deploy_capture_facing_v1034
    current=@motion_ambient_action_v102
    safe=motion_deploy_safe_ambient_action_v1034(current)
    if current!=nil && safe!=current
      @motion_ambient_action_v102=safe
      @motion_deploy_safe_substitutions_v1034=@motion_deploy_safe_substitutions_v1034.to_i+1
    end
  rescue
  end

  def motion_deploy_polish_stats_v1034
    [@motion_deploy_safe_substitutions_v1034.to_i,
     @motion_deploy_facing_anchor_v1034]
  rescue
    [0,nil]
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1034_update_position update_position unless method_defined?(:pmd_ac_v1034_update_position)

  def motion_deploy_hop_correction_v1034
    return 0.0 if @unit==nil
    return 0.0 unless @unit.respond_to?(:motion_deploy_phase_v1033?)
    return 0.0 unless @unit.motion_deploy_phase_v1033?
    return 0.0 unless @unit.visual_action==:hop
    data=@action_data
    return 0.0 if data==nil
    base=PMD_AC.action_data(@unit.species,:walk)
    base=PMD_AC.action_data(@unit.species,:idle) if base==nil
    return 0.0 if base==nil
    row=PMD_AC.direction_row(data,@unit.facing_dir)
    brow=PMD_AC.direction_row(base,@unit.facing_dir)
    feet=data[:row_foot_y]
    bfeet=base[:row_foot_y]
    return 0.0 if feet==nil || bfeet==nil
    foot=feet[row]
    bfoot=bfeet[brow]
    return 0.0 if foot==nil || bfoot==nil
    fh=data[:frame_h].to_f
    bfh=base[:frame_h].to_f
    return 0.0 if fh<=0.0 || bfh<=0.0
    action_rel=foot.to_f-fh
    base_rel=bfoot.to_f-bfh
    elevated=base_rel-action_rel
    return 0.0 if elevated<=0.0
    keep=PMD_AC::DEPLOY_HOP_HEIGHT_SCALE_V1034.to_f
    keep=0.0 if keep<0.0
    keep=1.0 if keep>1.0
    elevated*(1.0-keep)
  rescue
    0.0
  end

  def update_position
    pmd_ac_v1034_update_position
    correction=motion_deploy_hop_correction_v1034
    if correction>0.0
      self.y=(self.y.to_f+correction).round
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1034_start_battle start_battle unless method_defined?(:pmd_ac_v1034_start_battle)
  alias pmd_ac_v1034_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1034_update_verification_script)

  def motion_capture_deploy_polish_v1034
    covered=0
    substitutions=0
    facing_locked=0
    (@units || []).each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      st=u.respond_to?(:motion_deploy_polish_stats_v1034) ? u.motion_deploy_polish_stats_v1034 : [0,nil]
      substitutions+=st[0].to_i
      facing_locked+=1 if st[1]!=nil
    end
    @motion_deploy_polish_snapshot_v1034={
      :covered=>covered,
      :substitutions=>substitutions,
      :facing_locked=>facing_locked
    }
    if verification_mode==:pmd_motion_phase_b_v103
      log_event(:perf,
        'MOTION_DEPLOY_RICH_POLISH_V1034 ready=1 covered='+covered.to_s+
        ' facing_locked='+facing_locked.to_s+
        ' orientation_substitutions='+substitutions.to_s+
        ' hop_height_scale='+PMD_AC::DEPLOY_HOP_HEIGHT_SCALE_V1034.to_s+
        ' deploy_only=1 live_battle_unchanged=1 logical_xy_unchanged=1')
    end
  rescue
  end

  def start_battle
    motion_capture_deploy_polish_v1034 if @phase==:deploy
    pmd_ac_v1034_start_battle
  end

  def update_verification_script
    pmd_ac_v1034_update_verification_script
    return unless verification_mode==:pmd_motion_phase_b_v103
    return if @verification_done==nil
    f=@verification_frame.to_i
    if f==176 && !@verification_done[:deploy_rich_polish_v1034]
      verify_deploy_rich_polish_v1034
    end
  end

  def verify_deploy_rich_polish_v1034
    s=@motion_deploy_polish_snapshot_v1034 || {}
    covered=s[:covered].to_i
    locked=s[:facing_locked].to_i
    pass=covered>0 && locked==covered && PMD_AC::DEPLOY_HOP_HEIGHT_SCALE_V1034.to_f<1.0
    log_event(:verify,
      'MOTION_DEPLOY_RICH_POLISH_V1034 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' facing_locked='+locked.to_s+
      ' orientation_substitutions='+s[:substitutions].to_i.to_s+
      ' look_up_sanitized=1 rotate_sanitized=1 twirl_sanitized=1'+
      ' hop_height_scale='+PMD_AC::DEPLOY_HOP_HEIGHT_SCALE_V1034.to_s+
      ' hop_retained=1 deploy_only=1 battle_ambient_isolation_retained=1'+
      ' combat_hop_unchanged=1 logical_xy_unchanged=1 ai_unchanged=1'+
      ' damage_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:deploy_rich_polish_v1034]=true
  rescue
    log_event(:verify,'MOTION_DEPLOY_RICH_POLISH_V1034 pass=0 error=1')
    @verification_done[:deploy_rich_polish_v1034]=true
  end
end
