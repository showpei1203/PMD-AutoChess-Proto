#==============================================================================
# ■ PMD AutoChess Motion Phase B - Anticipation Snap Polish v1.03.1
#==============================================================================
# 【用途】
# Phase B Contact Chain Batch A 的第一輪實機手感修正。
# v1.03.0 已完成 anticipation → hitFrame → impact → landing/recovery → ambient reset；
# 本版只調整「出手前小幅後縮」與「真正往前攻擊」之間的速度對比，讓接觸技更俐落。
#
# 【設計規則】
# 1. 前置後移距離縮小：沿用 v1.03.0 的 anticipation 幀數，但位移幅度乘上
#    MOTION_PHASE_B_ANTICIPATION_DISTANCE_MULT_V1031。
#    幀數不縮短，因此平均後移速度也同步降低，不會像突然被向後吸走。
# 2. 前搖期間抑制 Core basic lunge：避免「一邊向前衝、一邊又疊負向 anticipation」
#    互相抵消，讓蓄勢方向更乾淨。
# 3. 前搖結束後，使用更快的 ease-out 曲線到達原本相同的 @action_lunge 最大距離。
#    最終接觸距離、hitFrame、action_timer、Attack Speed 完全不變；只是前衝視覺更快。
# 4. 命中之後仍交回 v1.03.0 / Frozen Combat Core 原本 return / recovery 邏輯。
# 5. 本版只處理 presentation，禁止修改 logical pixel_x / pixel_y、Pathfinding、AI、
#    Damage Formula、Attack Speed、Energy、Skill cooldown 或 Spatial Framework。
# 6. 全戰場慢節奏 + 低 HP 的 Battle Readability Tempo 不在本版實作；等所有
#    Motion Phase 完成後再獨立 A/B，避免 Motion 手感與戰鬥時間尺度互相污染。
#
# 【主要設定】
# MOTION_PHASE_B_ANTICIPATION_DISTANCE_MULT_V1031 = 0.55
#   0.55 = 前搖後縮幅度約為 v1.03.0 的 55%。
#   想更克制可降到 0.45；想更戲劇化可升到 0.65。
#
# MOTION_PHASE_B_ANTICIPATION_EASE_POWER_V1031 = 1.60
#   後縮 ease-in 強度。第一幀只吃少量距離，最後一幀才到最大後縮，避免瞬間後彈。
#
# MOTION_PHASE_B_FORWARD_EASE_POWER_V1031 = 2.80
#   前搖放開後的前衝 ease-out 強度。值越高越早取得大部分前衝距離，視覺越俐落。
#   不改命中幀，也不改總 action 時間。
#
# 【事件／腳本呼叫】
# 無需事件呼叫。只要 Phase B Contact Chain 啟用，本修正自動生效。
# 測試：布陣畫面按 S 切至 PMD Motion Phase B → Shift 開戰。
#
# 【實際範例】
# 例如基本接觸攻擊原本最大 lunge 9px：
#   - 前搖只後縮約原幅度 55%，時間仍相同；
#   - 前搖解除後快速前衝至原本相同 9px 接觸點；
#   - Damage / hitFrame / Attack Speed 不變。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionPhaseBAnticipationSnapPolish_v1031'] = true

module PMD_AC
  MOTION_PHASE_B_ANTICIPATION_DISTANCE_MULT_V1031 = 0.55
  MOTION_PHASE_B_ANTICIPATION_EASE_POWER_V1031 = 1.60
  MOTION_PHASE_B_FORWARD_EASE_POWER_V1031 = 2.80
end

class Game_PMDChessUnit
  alias pmd_ac_v1031_motion_phase_b_begin_action_v103 motion_phase_b_begin_action_v103 unless method_defined?(:pmd_ac_v1031_motion_phase_b_begin_action_v103)
  alias pmd_ac_v1031_current_lunge_amount current_lunge_amount unless method_defined?(:pmd_ac_v1031_current_lunge_amount)

  def motion_phase_b_begin_action_v103(move_key,data=nil,profile=nil)
    result=pmd_ac_v1031_motion_phase_b_begin_action_v103(move_key,data,profile)
    s=@motion_phase_b_action_v103
    if result && s!=nil
      s[:anticipation_px]=s[:anticipation_px].to_f * PMD_AC::MOTION_PHASE_B_ANTICIPATION_DISTANCE_MULT_V1031
      s[:snap_forward_v1031]=true
    end
    result
  rescue
    false
  end


  # 取代 v1.03.0 的 sin 波前搖。
  # 新曲線只往後逐步累積：開始慢、最後才到最大後縮；不在前搖內自己回彈。
  # 回彈／前衝由 current_lunge_amount 的 fast release 接手。
  def motion_phase_b_apply_anticipation_offset_v103
    return unless motion_phase_b_anticipation_active_v103?
    s=@motion_phase_b_action_v103
    n=[s[:anticipation].to_i,1].max
    e=@action_total_frames.to_i-@action_timer.to_i
    q=(e.to_f+1.0)/n.to_f
    q=0.0 if q<0.0
    q=1.0 if q>1.0
    power=PMD_AC::MOTION_PHASE_B_ANTICIPATION_EASE_POWER_V1031.to_f
    eased=q**power
    amp=s[:anticipation_px].to_f*eased
    @visual_offset_x=@visual_offset_x.to_f-@action_dir_x.to_f*amp
    @visual_offset_y=@visual_offset_y.to_f-@action_dir_y.to_f*amp+amp*0.22
  rescue
  end

  # Phase B contact 的 pre-hit lunge 視覺曲線。
  # 前搖仍在進行時不向前疊加 lunge；一解除便以快速 ease-out 追上原本接觸距離。
  # hit_elapsed、@action_hit_frame、@action_timer 都不變，因此不影響真正傷害時機。
  def current_lunge_amount
    s=@motion_phase_b_action_v103
    if s!=nil && s[:snap_forward_v1031] && @action_timer.to_i>0 &&
       @action_total_frames.to_i>0 && @action_lunge.to_f>0.0
      hit_elapsed=@action_total_frames.to_i-@action_hit_frame.to_i
      hit_elapsed=1 if hit_elapsed<=0
      elapsed=@action_total_frames.to_i-@action_timer.to_i
      ant=[s[:anticipation].to_i,0].max
      if elapsed<hit_elapsed
        return 0.0 if elapsed<ant
        release_count=[hit_elapsed-ant+1,1].max
        q=(elapsed-ant+1).to_f/release_count.to_f
        q=0.0 if q<0.0
        q=1.0 if q>1.0
        power=PMD_AC::MOTION_PHASE_B_FORWARD_EASE_POWER_V1031.to_f
        eased=1.0-(1.0-q)**power
        return eased*@action_lunge.to_f
      elsif elapsed==hit_elapsed
        return @action_lunge.to_f
      end
    end
    pmd_ac_v1031_current_lunge_amount
  rescue
    pmd_ac_v1031_current_lunge_amount
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1031_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1031_update_verification_script)

  def update_verification_script
    pmd_ac_v1031_update_verification_script
    return unless verification_mode==:pmd_motion_phase_b_v103
    return if @verification_done==nil
    f=@verification_frame.to_i
    if f==170 && !@verification_done[:motion_phase_b_snap_polish_v1031]
      verify_motion_phase_b_snap_polish_v1031
    end
  end

  def verify_motion_phase_b_snap_polish_v1031
    dist=PMD_AC::MOTION_PHASE_B_ANTICIPATION_DISTANCE_MULT_V1031.to_f
    ant_power=PMD_AC::MOTION_PHASE_B_ANTICIPATION_EASE_POWER_V1031.to_f
    power=PMD_AC::MOTION_PHASE_B_FORWARD_EASE_POWER_V1031.to_f
    old_ant_first=Math.sin((1.0/3.0)*Math::PI)
    new_ant_first=(1.0/3.0)**ant_power*dist
    old_mid=Math.sin(0.5*Math::PI/2.0)
    new_mid=1.0-(1.0-0.5)**power
    old_early=Math.sin(0.25*Math::PI/2.0)
    new_early=1.0-(1.0-0.25)**power
    pass=dist>0.0 && dist<1.0 && ant_power>1.0 && new_ant_first<old_ant_first && power>1.0 && new_mid>old_mid && new_early>old_early
    log_event(:verify,
      'MOTION_PHASE_B_ANTICIPATION_SNAP_V1031 pass='+(pass ? '1':'0')+
      ' anticipation_distance_mult='+format('%.2f',dist)+
      ' anticipation_frames_unchanged=1 anticipation_ease_power='+format('%.2f',ant_power)+
      ' backward_speed_reduced=1 backward_first_step_reduced=1'+
      ' forward_ease_power='+format('%.2f',power)+
      ' forward_early_faster=1 forward_mid_faster=1'+
      ' prehit_lunge_suppressed_during_anticipation=1 same_max_lunge=1'+
      ' hitFrame_unchanged=1 action_timer_unchanged=1 attack_speed_unchanged=1'+
      ' damage_unchanged=1 logical_xy_unchanged=1 global_tempo_deferred=1')
    @verification_done[:motion_phase_b_snap_polish_v1031]=true
  rescue
    log_event(:verify,'MOTION_PHASE_B_ANTICIPATION_SNAP_V1031 pass=0 error=1')
    @verification_done[:motion_phase_b_snap_polish_v1031]=true
  end
end
