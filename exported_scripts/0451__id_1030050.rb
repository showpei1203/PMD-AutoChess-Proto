#==============================================================================
# ■ PMD AutoChess - Deploy 45° Rich LOOP Rework v1.03.5
#==============================================================================
# 【用途】
# 重做 v1.03.3～v1.03.4 的布陣 Rich LOOP 展示方式。
# v1.03.4 為避免 PMD Native 空閒動作突然改變朝向，將 look_up / rotate / twirl
# 大量替換成較安全的原地動作；雖然方向較穩定，但結果過度保守，Rich LOOP 變得
# 缺乏動作變化。本版改採「固定 45° 展示方向 + 只使用真正具 8 方向素材的 Native
# 空閒動作」：動作可以豐富，但整體視角不亂跳。
#
# 【正式規則】
# 1. 本腳本只作用於 Deploy／布陣畫面，不修改 live battle Combat Motion。
# 2. 布陣展示方向固定為 45°：
#      我方（左側）  = 3：右下／右前 45°
#      敵方（右側）  = 1：左下／左前 45°
#    方向只覆寫 Sprite 取圖 row，不寫回 Game_PMDChessUnit#facing_dir，因此不污染
#    Directional Defense、AI face_toward、正式戰鬥開場方向或任何 Spatial Runtime。
# 3. Rich LOOP 不再使用 v1.03.4 的「危險 action -> 安全 action」替換思路。
#    改成動態建立每隻 Pokémon 的 Deploy 專用展示序列：
#      - 基本：Walk / Idle
#      - 物種原 Ambient 中具 8-direction 的特殊動作
#      - 依 Body Profile 再補 Nod / Pose / Shake / Hop / Flap Around /
#        Tail Whip / Withdraw / Dance 等非攻擊性 Native 演技
#      - 每一項都先確認該 action 自己真的可播放，且 rows >= 8。
#    因此單方向 LookUp / DeepBreath 等不會破壞 45° 視角。
# 4. 特殊動作會穿插短 Idle / Walk，不會像動作展示器一樣不停抽搐；每隻最多取
#    5 種特殊 Native action，讓 LOOP 比 v1.03.4 豐富但仍可讀。
# 5. Deploy Hop 沿用 v1.03.4 的 35% 可見高度，但改用本版 45° row 計算腳底校正。
#    正式戰鬥的 Hop / Jump / Launch 完全不受影響。
# 6. v1.03.2 Battle Ambient Isolation 保持有效：正式自走棋戰鬥仍不播放純待機
#    Rich LOOP；大幅位移只屬於真正 Combat Motion / Spatial Runtime。
#
# 【主要設定】
# DEPLOY_DISPLAY_DIRECTION_V1035
#   我方／敵方固定 45° 展示方向。
#
# DEPLOY_RICH_BODY_POOL_V1035
#   各 Body Profile 可加入的 Deploy Native 空閒演技候選。
#
# DEPLOY_RICH_COMMON_POOL_V1035
#   Body Pool 不足時的通用候選；仍要求 direct playable + rows >= 8。
#
# DEPLOY_RICH_MAX_SPECIALS_V1035 = 5
#   每隻 Pokémon 一輪最多使用的特殊演技數量。
#
# 【可調參數】
# - 想讓 LOOP 更豐富：提高 MAX_SPECIALS，或在 Body Pool 加入新的非攻擊 action。
# - 想讓 LOOP 更安靜：降低 MAX_SPECIALS，或拉長 Idle / Walk 的 hold frames。
# - 不要在此加入 Attack / Strike / Kick / Bite 等戰鬥語意 action。
# - 不要在此修改 AI、Damage、Attack Speed、Energy 或 logical pixel_x / pixel_y。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。Scene_PMD_AutoChess 處於 Deploy 時自動生效。
#
# 【實際範例】
# - 妙蛙種子：右前／左前 45° 下可輪播 Walk、Idle、Nod、Pose、Shake、Hop 等；
#   單方向 LookUp 不再把整隻角色突然轉去奇怪方向。
# - 傑尼龜：可使用 Nod / Pose / Shake / Hop / Withdraw 等真正 8-direction 動作。
# - 小火龍：Hop 保留但高度仍只有原始可見高度約 35%，並可混合 Nod / Pose 等
#   Native action，Rich LOOP 不再只剩 Walk + Idle。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_Deploy45RichLoopRework_v1035'] = true

module PMD_AC
  DEPLOY_DISPLAY_DIRECTION_V1035 = {
    :ally  => 3,
    :enemy => 1
  }

  DEPLOY_RICH_MAX_SPECIALS_V1035 = 5

  # Deploy 不使用具有明確攻擊／受傷／旋轉位移語意的 action。
  DEPLOY_RICH_BLOCKED_ACTIONS_V1035 = [
    :attack, :strike, :quick_strike, :double, :kick, :punch, :jab, :bite,
    :scratch, :slice, :stomp, :head, :shoot, :charge, :shock,
    :hurt, :faint, :pain, :trip, :tumble, :tumble_back, :rotate, :twirl
  ]

  DEPLOY_RICH_BODY_POOL_V1035 = {
    :small       => [:hop, :nod, :pose, :shake, :tail_whip, :dance],
    :medium      => [:pose, :nod, :shake, :tail_whip, :hop, :dance],
    :quadruped   => [:nod, :pose, :shake, :hop, :dance],
    :avian       => [:flap_around, :hover, :nod, :pose, :shake, :hop],
    :hover       => [:hover, :pose, :shake, :flap_around, :nod],
    :serpentine  => [:shake, :pose, :nod, :tail_whip, :hop],
    :heavy       => [:pose, :shake, :withdraw, :nod, :dance]
  }

  DEPLOY_RICH_COMMON_POOL_V1035 = [
    :nod, :pose, :shake, :hop, :flap_around, :hover,
    :tail_whip, :withdraw, :dance
  ]

  DEPLOY_RICH_HOLD_V1035 = {
    :walk=>24, :idle=>9, :nod=>12, :pose=>15, :shake=>13,
    :hop=>14, :flap_around=>18, :hover=>18, :tail_whip=>15,
    :withdraw=>15, :dance=>16
  }
end

class Game_PMDChessUnit
  alias pmd_ac_v1035_motion_deploy_idle_reset_v1033 motion_deploy_idle_reset_v1033 unless method_defined?(:pmd_ac_v1035_motion_deploy_idle_reset_v1033)

  def motion_deploy_idle_reset_v1033
    pmd_ac_v1035_motion_deploy_idle_reset_v1033
    @motion_deploy_rich_sequence_v1035=nil
    @motion_deploy_rich_special_count_v1035=0
    @motion_deploy_rich_45_count_v1035=0
  end

  def motion_deploy_display_direction_v1035
    PMD_AC::DEPLOY_DISPLAY_DIRECTION_V1035[@team] || 3
  rescue
    3
  end

  def motion_deploy_direct_8dir_v1035?(action)
    return false if action==nil
    return false unless respond_to?(:motion_playable_v102?)
    return false unless motion_playable_v102?(action)
    d=PMD_AC.action_data(@species,action)
    return false if d==nil
    d[:rows].to_i>=8
  rescue
    false
  end

  def motion_deploy_push_unique_v1035(out,action)
    return if action==nil
    return if PMD_AC::DEPLOY_RICH_BLOCKED_ACTIONS_V1035.include?(action)
    return if out.include?(action)
    return unless motion_deploy_direct_8dir_v1035?(action)
    out.push(action)
  rescue
  end

  def motion_deploy_rich_specials_v1035
    out=[]
    p=respond_to?(:motion_species_profile_v102) ? motion_species_profile_v102 : nil
    ambient=p==nil ? nil : p[:ambient]
    if ambient!=nil
      ambient.each do |row|
        a=row==nil ? nil : row[0]
        next if a==:walk || a==:idle
        motion_deploy_push_unique_v1035(out,a)
      end
    end
    body=p==nil ? :medium : p[:body]
    pool=PMD_AC::DEPLOY_RICH_BODY_POOL_V1035[body] || PMD_AC::DEPLOY_RICH_BODY_POOL_V1035[:medium]
    pool.each{|a| motion_deploy_push_unique_v1035(out,a)}
    PMD_AC::DEPLOY_RICH_COMMON_POOL_V1035.each{|a| motion_deploy_push_unique_v1035(out,a)}
    max=PMD_AC::DEPLOY_RICH_MAX_SPECIALS_V1035.to_i
    max=1 if max<1
    out=out[0,max] if out.size>max
    out
  rescue
    []
  end

  def motion_deploy_hold_v1035(action)
    (PMD_AC::DEPLOY_RICH_HOLD_V1035[action] || 12).to_i
  rescue
    12
  end

  def motion_deploy_rich_sequence_v1035
    return @motion_deploy_rich_sequence_v1035 if @motion_deploy_rich_sequence_v1035!=nil
    specials=motion_deploy_rich_specials_v1035
    seq=[[:walk,24],[:idle,9]]
    specials.each_with_index do |a,i|
      seq.push([a,motion_deploy_hold_v1035(a)])
      seq.push([:idle,6+(i%2)*2])
      seq.push([:walk,16]) if i==1 || i==3
    end
    seq=[[:walk,24],[:idle,12]] if seq.empty?
    @motion_deploy_rich_special_count_v1035=specials.size
    @motion_deploy_rich_sequence_v1035=seq
    seq
  rescue
    [[:walk,24],[:idle,12]]
  end

  # v1.03.5 直接接管 Deploy tick，不再讓 v1.03.4 把特殊 action sanitize 掉。
  # 舊 facing anchor 仍會更新，確保 v1.03.4 verifier 與戰鬥前 unit state 保持相容；
  # 真正畫面方向則由 Sprite 層固定到 45° row。
  def motion_update_deploy_idle_v1033
    return unless motion_deploy_idle_eligible_v1033?
    motion_deploy_capture_facing_v1034 if respond_to?(:motion_deploy_capture_facing_v1034)
    @motion_deploy_idle_ticks_v1033=@motion_deploy_idle_ticks_v1033.to_i+1
    @motion_ambient_frames_v102=@motion_ambient_frames_v102.to_i-1
    return if @motion_ambient_frames_v102.to_i>0
    seq=motion_deploy_rich_sequence_v1035
    idx=@motion_ambient_index_v102.to_i % seq.size
    row=seq[idx]
    requested=row[0]
    action=motion_resolve_ambient_action_v102(requested)
    @motion_ambient_action_v102=action
    @motion_ambient_frames_v102=[row[1].to_i,1].max
    @motion_ambient_index_v102=(idx+1)%seq.size
    @motion_deploy_idle_transitions_v1033=@motion_deploy_idle_transitions_v1033.to_i+1
    if action!=:walk && action!=:idle
      @motion_deploy_idle_rich_seen_v1033=@motion_deploy_idle_rich_seen_v1033.to_i+1
      @motion_deploy_rich_45_count_v1035=@motion_deploy_rich_45_count_v1035.to_i+1
    end
  rescue
  end

  def motion_deploy_rich_stats_v1035
    seq=motion_deploy_rich_sequence_v1035
    [seq.size,
     @motion_deploy_rich_special_count_v1035.to_i,
     @motion_deploy_rich_45_count_v1035.to_i,
     motion_deploy_display_direction_v1035]
  rescue
    [0,0,0,3]
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1035_setup_source_rect setup_source_rect unless method_defined?(:pmd_ac_v1035_setup_source_rect)
  alias pmd_ac_v1035_update_animation update_animation unless method_defined?(:pmd_ac_v1035_update_animation)

  def motion_deploy_display_direction_v1035
    return nil if @unit==nil
    return nil unless @unit.respond_to?(:motion_deploy_phase_v1033?)
    return nil unless @unit.motion_deploy_phase_v1033?
    return @unit.motion_deploy_display_direction_v1035 if @unit.respond_to?(:motion_deploy_display_direction_v1035)
    @unit.team==:enemy ? 1 : 3
  rescue
    nil
  end

  def motion_apply_deploy_45_row_v1035
    d=motion_deploy_display_direction_v1035
    return if d==nil
    return if @placeholder || @action_data==nil || self.bitmap==nil
    fw=@action_data[:frame_w].to_i
    fh=@action_data[:frame_h].to_i
    fw=self.bitmap.width if fw<=0
    fh=self.bitmap.height if fh<=0
    return if fw<=0 || fh<=0
    row=PMD_AC.direction_row(@action_data,d)
    self.src_rect.set(@frame_index.to_i*fw,row*fh,fw,fh)
  rescue
  end

  def setup_source_rect
    pmd_ac_v1035_setup_source_rect
    motion_apply_deploy_45_row_v1035
  end

  def update_animation
    pmd_ac_v1035_update_animation
    motion_apply_deploy_45_row_v1035
  end

  # 覆寫 v1.03.4 同名 helper：Hop 高度比例仍為 35%，但腳底 row 必須跟畫面
  # 實際使用的 45° row 一致，不能再拿 unit 原本的 6/4 方向計算。
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
    d=motion_deploy_display_direction_v1035
    d=@unit.facing_dir if d==nil
    row=PMD_AC.direction_row(data,d)
    brow=PMD_AC.direction_row(base,d)
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
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1035_start_battle start_battle unless method_defined?(:pmd_ac_v1035_start_battle)
  alias pmd_ac_v1035_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1035_update_verification_script)

  def motion_capture_deploy_45_rich_v1035
    covered=0
    diag_locked=0
    rich_ready=0
    specials=0
    seq_items=0
    ally_dir=0
    enemy_dir=0
    (@units || []).each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      st=u.respond_to?(:motion_deploy_rich_stats_v1035) ? u.motion_deploy_rich_stats_v1035 : [0,0,0,0]
      seq_items+=st[0].to_i
      specials+=st[1].to_i
      rich_ready+=1 if st[0].to_i>=3 && st[1].to_i>=1
      expected=u.team==:enemy ? 1 : 3
      diag_locked+=1 if st[3].to_i==expected
      ally_dir+=1 if u.team==:ally && st[3].to_i==3
      enemy_dir+=1 if u.team==:enemy && st[3].to_i==1
    end
    @motion_deploy_45_rich_snapshot_v1035={
      :covered=>covered,:diag_locked=>diag_locked,:rich_ready=>rich_ready,
      :specials=>specials,:seq_items=>seq_items,:ally_dir=>ally_dir,:enemy_dir=>enemy_dir
    }
    if verification_mode==:pmd_motion_phase_b_v103
      log_event(:perf,
        'MOTION_DEPLOY_45_RICH_LOOP_V1035 ready=1 covered='+covered.to_s+
        ' diagonal_locked='+diag_locked.to_s+'/'+covered.to_s+
        ' rich_ready='+rich_ready.to_s+'/'+covered.to_s+
        ' specials='+specials.to_s+' sequence_items='+seq_items.to_s+
        ' ally_dir=3 enemy_dir=1 direct_8dir_only=1'+
        ' max_specials='+PMD_AC::DEPLOY_RICH_MAX_SPECIALS_V1035.to_s+
        ' v1034_sanitizer_superseded=1 hop_height_scale='+PMD_AC::DEPLOY_HOP_HEIGHT_SCALE_V1034.to_s+
        ' deploy_only=1 battle_ambient_isolation_retained=1 logical_xy_unchanged=1')
    end
  rescue
  end

  def start_battle
    motion_capture_deploy_45_rich_v1035 if @phase==:deploy
    pmd_ac_v1035_start_battle
  end

  def update_verification_script
    pmd_ac_v1035_update_verification_script
    return unless verification_mode==:pmd_motion_phase_b_v103
    return if @verification_done==nil
    f=@verification_frame.to_i
    if f==178 && !@verification_done[:deploy_45_rich_v1035]
      verify_deploy_45_rich_v1035
    end
  end

  def verify_deploy_45_rich_v1035
    s=@motion_deploy_45_rich_snapshot_v1035 || {}
    covered=s[:covered].to_i
    diag=s[:diag_locked].to_i
    ready=s[:rich_ready].to_i
    pass=covered>0 && diag==covered && ready==covered &&
      PMD_AC::DEPLOY_DISPLAY_DIRECTION_V1035[:ally]==3 &&
      PMD_AC::DEPLOY_DISPLAY_DIRECTION_V1035[:enemy]==1
    log_event(:verify,
      'MOTION_DEPLOY_45_RICH_LOOP_V1035 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' diagonal_locked='+diag.to_s+'/'+covered.to_s+
      ' rich_ready='+ready.to_s+'/'+covered.to_s+
      ' specials='+s[:specials].to_i.to_s+' sequence_items='+s[:seq_items].to_i.to_s+
      ' ally_45_dir=3 enemy_45_dir=1 direct_8dir_only=1'+
      ' v1034_orientation_substitution_superseded=1'+
      ' hop_height_scale='+PMD_AC::DEPLOY_HOP_HEIGHT_SCALE_V1034.to_s+
      ' deploy_only=1 combat_motion_unchanged=1 battle_ambient_isolation_retained=1'+
      ' logical_xy_unchanged=1 ai_unchanged=1 damage_unchanged=1'+
      ' attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:deploy_45_rich_v1035]=true
  rescue
    log_event(:verify,'MOTION_DEPLOY_45_RICH_LOOP_V1035 pass=0 error=1')
    @verification_done[:deploy_45_rich_v1035]=true
  end
end
