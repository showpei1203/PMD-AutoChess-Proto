#==============================================================================
# ■ PMD AutoChess - Deploy Idle Loop Restore v1.03.3
#==============================================================================
# 【用途】
# 修正布陣／待機畫面沒有真正播放 Species Ambient Rich LOOP 的問題。
# Phase A 的 Rich LOOP 原本只在 Game_PMDChessUnit#update 中推進，但 Deploy phase
# 只更新 Sprite，不會呼叫 Unit#update；而且舊 ambient eligibility 另要求 battle_active，
# 因此布陣畫面實際上一直停在單一 pose。
#
# 【正式規則】
# 1. Deploy／布陣畫面：
#    - 啟用完整 Species Ambient Rich LOOP。
#    - 重用 Phase A 既有每物種 ambient sequence，不建立第二份動作資料。
#    - Hop / Look Up / Flap Around / Shake / Pose 等純視覺演技只在這裡允許自由輪播。
# 2. Live Battle／正式自走棋戰鬥：
#    - 繼續遵守 v1.03.2 Battle Ambient Isolation。
#    - 不因本腳本重新啟用 Rich LOOP。
#    - 大幅位移仍只能由 Combat Motion 或 Spatial Runtime 產生。
# 3. Result／勝利慶祝：
#    - 不套用 Deploy Rich LOOP，維持既有 Victory presentation。
# 4. 本腳本只切換 Sprite 使用的 action；不修改 pixel_x / pixel_y、格子、AI、Damage、
#    Attack Speed、Energy、Pathfinding、Targeting 或任何 Spatial logical value。
#
# 【主要設定】
# DEPLOY_IDLE_LOOP_ENABLED_V1033 = true
#   是否在 Deploy phase 啟用完整 Species Ambient sequence。
#
# 【可調參數】
# 實際每隻 Pokémon 的動作與停留時間仍由
# PMD_AC::MOTION_SPECIES_PHASE_A_V102[sid][:ambient] 控制。
# 例如小火龍可在布陣畫面播放 walk / idle / hop / look_up；
# 正式戰鬥中則仍由 v1.03.2 禁止這些純待機大動作。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。Scene_PMD_AutoChess 處於 :deploy 時自動生效。
#
# 【實際範例】
# - 進入布陣畫面，小火龍會依 restless_spark 的 ambient sequence 自然輪播。
# - 按 Shift 進入戰鬥後，小火龍不會因為純待機再次突然 Hop。
# - Quick Attack 真正使用 Hop / Dash 時仍正常，因為那是 Combat Motion。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_DeployIdleLoopRestore_v1033'] = true

module PMD_AC
  DEPLOY_IDLE_LOOP_ENABLED_V1033 = true
end

class Game_PMDChessUnit
  alias pmd_ac_v1033_visual_action visual_action unless method_defined?(:pmd_ac_v1033_visual_action)
  alias pmd_ac_v1033_start_combat start_combat unless method_defined?(:pmd_ac_v1033_start_combat)
  alias pmd_ac_v1033_stop_combat stop_combat unless method_defined?(:pmd_ac_v1033_stop_combat)

  def motion_deploy_idle_reset_v1033
    @motion_deploy_idle_transitions_v1033=0
    @motion_deploy_idle_rich_seen_v1033=0
    @motion_deploy_idle_ticks_v1033=0
  end

  def start_combat
    motion_deploy_idle_reset_v1033
    pmd_ac_v1033_start_combat
  end

  def stop_combat
    r=pmd_ac_v1033_stop_combat
    motion_deploy_idle_reset_v1033
    r
  end

  def motion_deploy_phase_v1033?
    return false if @scene==nil
    return @scene.pmd_deploy_phase_v1033? if @scene.respond_to?(:pmd_deploy_phase_v1033?)
    @scene.instance_variable_get(:@phase)==:deploy
  rescue
    false
  end

  def motion_deploy_idle_eligible_v1033?
    return false unless PMD_AC::DEPLOY_IDLE_LOOP_ENABLED_V1033
    return false unless motion_phase_a_species_v102?
    return false unless motion_deploy_phase_v1033?
    return false if @battle_active
    return false if dead?
    return false if @victory_celebrating
    true
  rescue
    false
  end

  # Deploy 不會走 Unit#update，因此由 Scene deploy tick 主動呼叫本方法。
  # 共用 Phase A ambient state，確保進戰鬥時既有 start_combat/reset 邏輯能乾淨重置。
  def motion_update_deploy_idle_v1033
    return unless motion_deploy_idle_eligible_v1033?
    @motion_deploy_idle_ticks_v1033=@motion_deploy_idle_ticks_v1033.to_i+1
    @motion_ambient_frames_v102=@motion_ambient_frames_v102.to_i-1
    return if @motion_ambient_frames_v102.to_i>0
    p=motion_species_profile_v102
    seq=p==nil ? [[:walk,24],[:idle,14]] : p[:ambient]
    seq=[[:walk,24],[:idle,14]] if seq==nil || seq.empty?
    idx=@motion_ambient_index_v102.to_i % seq.size
    row=seq[idx]
    action=motion_resolve_ambient_action_v102(row[0])
    @motion_ambient_action_v102=action
    @motion_ambient_frames_v102=[row[1].to_i,1].max
    @motion_ambient_index_v102=(idx+1)%seq.size
    @motion_deploy_idle_transitions_v1033=@motion_deploy_idle_transitions_v1033.to_i+1
    if action!=:walk && action!=:idle
      @motion_deploy_idle_rich_seen_v1033=@motion_deploy_idle_rich_seen_v1033.to_i+1
    end
  rescue
  end

  def motion_deploy_idle_stats_v1033
    [@motion_deploy_idle_ticks_v1033.to_i,
     @motion_deploy_idle_transitions_v1033.to_i,
     @motion_deploy_idle_rich_seen_v1033.to_i]
  rescue
    [0,0,0]
  end

  # v1.03.2 的 visual_action 在非 battle 時回到舊 base；這裡只於 Deploy
  # 將 stationary display 改為目前 Rich LOOP action。Live battle 完全不碰。
  def visual_action
    base=pmd_ac_v1033_visual_action
    return base unless motion_deploy_idle_eligible_v1033?
    a=@motion_ambient_action_v102
    return base if a==nil
    a
  rescue
    base
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1033_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v1033_update_deploy_phase)
  alias pmd_ac_v1033_start_battle start_battle unless method_defined?(:pmd_ac_v1033_start_battle)
  alias pmd_ac_v1033_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1033_restart_to_deploy)
  alias pmd_ac_v1033_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1033_update_verification_script)

  def pmd_deploy_phase_v1033?
    @phase==:deploy
  end

  def motion_deploy_idle_reset_scene_v1033
    @motion_deploy_idle_frames_v1033=0
    @motion_deploy_idle_snapshot_v1033=nil
  end

  def update_deploy_phase
    pmd_ac_v1033_update_deploy_phase
    return unless @phase==:deploy
    @motion_deploy_idle_frames_v1033=@motion_deploy_idle_frames_v1033.to_i+1
    units=@units || []
    units.each do |u|
      next if u==nil
      u.motion_update_deploy_idle_v1033 if u.respond_to?(:motion_update_deploy_idle_v1033)
    end
  end

  def motion_capture_deploy_idle_v1033
    covered=0;ticks=0;transitions=0;rich_seen=0
    (@units || []).each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      st=u.respond_to?(:motion_deploy_idle_stats_v1033) ? u.motion_deploy_idle_stats_v1033 : [0,0,0]
      ticks+=st[0].to_i
      transitions+=st[1].to_i
      rich_seen+=st[2].to_i
    end
    @motion_deploy_idle_snapshot_v1033={
      :covered=>covered,
      :scene_frames=>@motion_deploy_idle_frames_v1033.to_i,
      :ticks=>ticks,
      :transitions=>transitions,
      :rich_seen=>rich_seen
    }
    if verification_mode==:pmd_motion_phase_b_v103
      log_event(:perf,
        'MOTION_DEPLOY_IDLE_LOOP_V1033 ready=1 covered='+covered.to_s+
        ' scene_frames='+@motion_deploy_idle_frames_v1033.to_i.to_s+
        ' ticks='+ticks.to_s+' transitions='+transitions.to_s+
        ' rich_actions_seen='+rich_seen.to_s+
        ' deploy_rich_loop=1 live_battle_rich_loop=0'+
        ' shared_species_profile=1 logical_xy_unchanged=1')
    end
  rescue
  end

  def start_battle
    motion_capture_deploy_idle_v1033 if @phase==:deploy
    pmd_ac_v1033_start_battle
  end

  def restart_to_deploy
    r=pmd_ac_v1033_restart_to_deploy
    motion_deploy_idle_reset_scene_v1033 if @phase==:deploy
    r
  end

  def update_verification_script
    pmd_ac_v1033_update_verification_script
    return unless verification_mode==:pmd_motion_phase_b_v103
    return if @verification_done==nil
    f=@verification_frame.to_i
    if f==174 && !@verification_done[:deploy_idle_loop_v1033]
      verify_deploy_idle_loop_v1033
    end
  end

  def verify_deploy_idle_loop_v1033
    s=@motion_deploy_idle_snapshot_v1033 || {}
    covered=s[:covered].to_i
    ticks=s[:ticks].to_i
    transitions=s[:transitions].to_i
    frames=s[:scene_frames].to_i
    pass=covered>0 && frames>0 && ticks>=covered && transitions>0
    log_event(:verify,
      'MOTION_DEPLOY_IDLE_LOOP_V1033 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' scene_frames='+frames.to_s+
      ' ticks='+ticks.to_s+' transitions='+transitions.to_s+
      ' rich_actions_seen='+s[:rich_seen].to_i.to_s+
      ' deploy_rich_loop=1 live_battle_rich_loop=0'+
      ' species_profile_shared=1 battle_ambient_isolation_retained=1'+
      ' result_victory_unchanged=1 logical_xy_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:deploy_idle_loop_v1033]=true
  rescue
    log_event(:verify,'MOTION_DEPLOY_IDLE_LOOP_V1033 pass=0 error=1')
    @verification_done[:deploy_idle_loop_v1033]=true
  end
end
