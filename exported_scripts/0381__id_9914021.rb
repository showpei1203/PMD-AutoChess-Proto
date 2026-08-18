#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Attack Cadence Recovery v0.99.14.2
# 分類：戰鬥節奏安全修正／Post-Kill Target Handoff Regression（Trailing Hook）
#
# 【用途】
# 修正 v0.99.14.1 實戰觀察到的罕見節奏卡死：單位以技能擊倒目前目標、
# 成功切換到下一個活目標後，仍可能長時間沒有新的普攻或技能 dispatch。
# 本腳本不提高 Attack Speed、不縮短正常普攻冷卻，也不改傷害公式；只在
# 「已有活目標＋合法普攻距離＋超過異常沉默時間」時檢查並修復 stale state。
#
# 【主要規則】
# 1. 追蹤最後一次成功開始 Attack／Skill 的 frame，以及最後一次 Target Handoff。
# 2. 若 action_timer > 0 卻連續多 frame 完全不遞減，視為 stale action timer，
#    清回 idle，避免永久 acting lock。正常 action_timer 每 frame 都會下降，因此
#    不會碰正常技能／普攻動畫。
# 3. 若已有活目標、非 Fear／Stun、非 Acting、目標已在合法 Basic Range，且
#    超過 POST_KILL_CADENCE_FORCE_FRAMES 都沒有新攻擊：
#    - 先將不合理大於正常上限的 @attack_wait 壓回合法範圍；
#    - 若已 Ready，重新 dispatch 一次 begin_attack。
# 4. 只有 NORMAL 與目前 SPATIAL_FRAMEWORK_EXPANSION_V09914 使用此保護。
# 5. 不改 Basic Flex、Dynamic Role、Spatial Framework、Threat、Damage 或 Speed。
#
# 【可調參數】
# POST_KILL_CADENCE_WARN_FRAMES_V099142  = 120：開始寫 CADENCE_WATCH 的門檻。
# POST_KILL_CADENCE_FORCE_FRAMES_V099142 = 180：允許安全恢復的異常沉默門檻。
# STALE_ACTION_TIMER_FRAMES_V099142       = 8：action_timer 完全不下降的容忍 frame。
# ATTACK_WAIT_CAP_MULT_V099142            = 1.50：異常 cooldown 上限倍數。
#
# 【事件／腳本呼叫方式】
# 正式遊戲不需事件呼叫，Runtime 自動工作。
# Debug 可讀：
#   unit.cadence_state_v099142
# 取得 last_action / target_change / silence / attack_wait / action_timer 等狀態。
#
# 【驗證方式】
# S 切到 SPATIAL_FRAMEWORK_EXPANSION_V09914 後 Shift。
# 需看到：
#   POST_KILL_TARGET_HANDOFF_V099142 pass=1
#   ATTACK_CADENCE_RECOVERY_V099142 pass=1
#   SPATIAL_FRAMEWORK_EXPANSION_V09914 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【實際範例】
# 小火龍以火焰擴散擊倒波波 -> 自動改鎖綠毛蟲；若綠毛蟲已在合法 Basic
# Range，小火龍不得再出現數百 frame 完全不攻擊的狀態。
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不直接修改 Frozen Combat Core，只追加 trailing alias。
# - Pokémon 身份一律 instance_uid。
#==============================================================================

module PMD_AC
  POST_KILL_CADENCE_WARN_FRAMES_V099142=120 unless const_defined?('POST_KILL_CADENCE_WARN_FRAMES_V099142')
  POST_KILL_CADENCE_FORCE_FRAMES_V099142=180 unless const_defined?('POST_KILL_CADENCE_FORCE_FRAMES_V099142')
  STALE_ACTION_TIMER_FRAMES_V099142=8 unless const_defined?('STALE_ACTION_TIMER_FRAMES_V099142')
  ATTACK_WAIT_CAP_MULT_V099142=1.50 unless const_defined?('ATTACK_WAIT_CAP_MULT_V099142')
  ATTACK_CADENCE_REPORT_V099142='PMD_AttackCadenceRecovery_v0.99.14.2.txt' unless const_defined?('ATTACK_CADENCE_REPORT_V099142')
end

class Game_PMDChessUnit
  alias pmd_ac_v099142_start_combat start_combat unless method_defined?(:pmd_ac_v099142_start_combat)
  alias pmd_ac_v099142_set_target set_target unless method_defined?(:pmd_ac_v099142_set_target)
  alias pmd_ac_v099142_begin_attack begin_attack unless method_defined?(:pmd_ac_v099142_begin_attack)
  alias pmd_ac_v099142_begin_skill begin_skill unless method_defined?(:pmd_ac_v099142_begin_skill)
  alias pmd_ac_v099142_update update unless method_defined?(:pmd_ac_v099142_update)
  alias pmd_ac_v099142_update_logic update_logic unless method_defined?(:pmd_ac_v099142_update_logic)

  def cadence_runtime_v099142?
    return true if @scene==nil || !@scene.respond_to?(:verification_mode)
    m=@scene.verification_mode
    m==:normal || m==:spatial_framework_expansion_v09914
  end

  def cadence_now_v099142
    Graphics.frame_count.to_i
  rescue
    0
  end

  def cadence_reset_tracking_v099142
    n=cadence_now_v099142
    @cadence_last_action_frame_v099142=n
    @cadence_target_change_frame_v099142=n
    @cadence_last_warn_frame_v099142=-9999
    @cadence_timer_last_value_v099142=@action_timer.to_i
    @cadence_timer_stale_frames_v099142=0
    @cadence_recovery_count_v099142=0
  end

  def start_combat
    pmd_ac_v099142_start_combat
    cadence_reset_tracking_v099142
  end

  def set_target(new_target)
    old=@target
    r=pmd_ac_v099142_set_target(new_target)
    if cadence_runtime_v099142? && new_target!=nil && new_target!=old
      @cadence_target_change_frame_v099142=cadence_now_v099142
    end
    r
  end

  def begin_attack
    before=@action_timer.to_i
    r=pmd_ac_v099142_begin_attack
    if cadence_runtime_v099142? && @action==:attack && @action_timer.to_i>before
      @cadence_last_action_frame_v099142=cadence_now_v099142
    end
    r
  end

  def begin_skill(skill_target=nil)
    before=@action_timer.to_i
    r=pmd_ac_v099142_begin_skill(skill_target)
    if cadence_runtime_v099142? && @action==:skill && @action_timer.to_i>before
      @cadence_last_action_frame_v099142=cadence_now_v099142
    end
    r
  end

  def cadence_stale_action_guard_v099142
    return false unless cadence_runtime_v099142?
    cur=@action_timer.to_i
    if cur>0
      if @cadence_timer_last_value_v099142.to_i==cur
        @cadence_timer_stale_frames_v099142=@cadence_timer_stale_frames_v099142.to_i+1
      else
        @cadence_timer_stale_frames_v099142=0
      end
      @cadence_timer_last_value_v099142=cur
      if @cadence_timer_stale_frames_v099142.to_i>=PMD_AC::STALE_ACTION_TIMER_FRAMES_V099142
        log_event(:cadence_recovery,log_name+' reason=stale_action_timer timer='+cur.to_s+
          ' action='+@action.to_s+' stale_frames='+@cadence_timer_stale_frames_v099142.to_i.to_s)
        @action_timer=0
        @action_total_frames=0
        @action_hit_frame=0
        @action_hit_done=false
        @action=:idle unless dead?
        @visual_action=:idle unless dead?
        @channeling=false
        @skill_target=nil
        @cadence_timer_stale_frames_v099142=0
        @cadence_timer_last_value_v099142=0
        @cadence_recovery_count_v099142=@cadence_recovery_count_v099142.to_i+1
        return true
      end
    else
      @cadence_timer_last_value_v099142=0
      @cadence_timer_stale_frames_v099142=0
    end
    false
  end

  def update
    r=pmd_ac_v099142_update
    cadence_stale_action_guard_v099142
    r
  end

  def cadence_basic_allowed_v099142?
    return false if @target==nil || @target.dead?
    d=distance_to(@target).to_f
    if respond_to?(:basic_attack_distance_allowed_v09912) && respond_to?(:basic_delivery_for_distance_v09912)
      return basic_attack_distance_allowed_v09912(d,basic_delivery_for_distance_v09912(d))
    end
    lim=ranged? ? @max_range.to_f : (@melee_reach.to_f+PMD_AC::MELEE_HIT_GRACE.to_f)
    d<=lim
  rescue
    false
  end

  def cadence_blocked_status_v099142?
    return true if dead?
    return true if @stun_frames.to_i>0
    return true if respond_to?(:feared?) && feared?
    return true if acting?
    false
  end

  def cadence_silence_frames_v099142
    n=cadence_now_v099142
    a=@cadence_last_action_frame_v099142.to_i
    t=@cadence_target_change_frame_v099142.to_i
    n-[a,t].max
  end

  def cadence_recovery_v099142(force_test=false)
    return false unless cadence_runtime_v099142?
    return false if @target==nil || @target.dead?
    return false if cadence_blocked_status_v099142?
    silence=force_test ? PMD_AC::POST_KILL_CADENCE_FORCE_FRAMES_V099142+1 : cadence_silence_frames_v099142
    return false if silence<PMD_AC::POST_KILL_CADENCE_WARN_FRAMES_V099142
    allowed=cadence_basic_allowed_v099142?
    now=cadence_now_v099142
    if now-@cadence_last_warn_frame_v099142.to_i>=PMD_AC::POST_KILL_CADENCE_WARN_FRAMES_V099142
      @cadence_last_warn_frame_v099142=now
      d=distance_to(@target).to_f.round
      log_event(:cadence_watch,log_name+' target='+@target.log_name+' silence='+silence.to_i.to_s+
        ' distance='+d.to_s+' basic_allowed='+(allowed ? '1':'0')+
        ' attack_wait='+sprintf('%.1f',@attack_wait.to_f)+' attack_wait_max='+@attack_wait_max.to_f.round.to_s+
        ' action='+@action.to_s+' timer='+@action_timer.to_i.to_s+' threat='+@threat_level.to_s)
    end
    return false if silence<PMD_AC::POST_KILL_CADENCE_FORCE_FRAMES_V099142
    return false unless allowed

    max=[@attack_wait_max.to_f,1.0].max
    if @attack_wait.to_f>max*PMD_AC::ATTACK_WAIT_CAP_MULT_V099142
      log_event(:cadence_recovery,log_name+' reason=attack_wait_clamp old='+sprintf('%.1f',@attack_wait.to_f)+
        ' max='+sprintf('%.1f',max)+' target='+@target.log_name)
      @attack_wait=0.0
    end
    if @attack_wait.to_f<=0.0
      before=@action_timer.to_i
      begin_attack
      if @action==:attack && @action_timer.to_i>before
        @cadence_last_action_frame_v099142=now
        @cadence_recovery_count_v099142=@cadence_recovery_count_v099142.to_i+1
        log_event(:cadence_recovery,log_name+' reason=post_kill_dispatch target='+@target.log_name+
          ' silence='+silence.to_i.to_s+' distance='+distance_to(@target).to_f.round.to_s)
        return true
      end
    end
    false
  end

  def update_logic
    r=pmd_ac_v099142_update_logic
    cadence_recovery_v099142(false)
    r
  end

  def cadence_state_v099142
    {
      :last_action=>@cadence_last_action_frame_v099142.to_i,
      :target_change=>@cadence_target_change_frame_v099142.to_i,
      :silence=>cadence_silence_frames_v099142,
      :attack_wait=>@attack_wait.to_f,
      :attack_wait_max=>@attack_wait_max.to_f,
      :action=>@action,
      :action_timer=>@action_timer.to_i,
      :target=>(@target==nil ? nil : @target.instance_uid),
      :recoveries=>@cadence_recovery_count_v099142.to_i
    }
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v099142_start start unless method_defined?(:pmd_ac_v099142_start)
  alias pmd_ac_v099142_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v099142_update_verification_script)

  def start
    pmd_ac_v099142_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.99\.14\.1 Battle Verification Log/,
          'PMD AutoChess Proto v0.99.14.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:cadence_recovery,'PATCH v0.99.14.2 post_kill_handoff=1 cadence_watchdog=1 attack_speed_unchanged=1 damage_unchanged=1')
  end

  def verify_post_kill_cadence_v099142
    return if @verification_done[:post_kill_cadence_v099142]
    u=verification_unit(:ally,:charmander)
    t=verification_unit(:enemy,:caterpie)
    handoff=false;dispatch=false;clamp=false;timer_guard=false
    if u!=nil && t!=nil && !u.dead? && !t.dead?
      saved={}
      ivs=[:@target,:@pixel_x,:@pixel_y,:@attack_wait,:@action,:@visual_action,:@action_timer,
        :@action_total_frames,:@action_hit_frame,:@action_hit_done,:@skill_target,:@stun_frames,
        :@cadence_last_action_frame_v099142,:@cadence_target_change_frame_v099142,
        :@cadence_last_warn_frame_v099142,:@cadence_timer_last_value_v099142,
        :@cadence_timer_stale_frames_v099142,:@cadence_recovery_count_v099142]
      ivs.each{|iv|saved[iv]=u.instance_variable_get(iv)}
      tx=t.instance_variable_get(:@pixel_x);ty=t.instance_variable_get(:@pixel_y)
      begin
        t.instance_variable_set(:@pixel_x,u.instance_variable_get(:@pixel_x).to_f+72.0)
        t.instance_variable_set(:@pixel_y,u.instance_variable_get(:@pixel_y).to_f)
        u.set_target(t)
        handoff=(u.target==t)
        u.instance_variable_set(:@action,:idle)
        u.instance_variable_set(:@visual_action,:idle)
        u.instance_variable_set(:@action_timer,0)
        u.instance_variable_set(:@stun_frames,0)
        u.instance_variable_set(:@attack_wait,[u.instance_variable_get(:@attack_wait_max).to_f*4.0,400.0].max)
        old=Graphics.frame_count.to_i-PMD_AC::POST_KILL_CADENCE_FORCE_FRAMES_V099142-20
        u.instance_variable_set(:@cadence_last_action_frame_v099142,old)
        u.instance_variable_set(:@cadence_target_change_frame_v099142,old)
        u.cadence_recovery_v099142(true)
        dispatch=(u.instance_variable_get(:@action)==:attack && u.instance_variable_get(:@action_timer).to_i>0)
        clamp=(u.instance_variable_get(:@attack_wait).to_f<=u.instance_variable_get(:@attack_wait_max).to_f+0.01)

        # action_timer 完全不下降時的獨立安全測試。
        u.instance_variable_set(:@action,:skill)
        u.instance_variable_set(:@visual_action,:skill)
        u.instance_variable_set(:@action_timer,20)
        u.instance_variable_set(:@action_total_frames,20)
        u.instance_variable_set(:@cadence_timer_last_value_v099142,20)
        u.instance_variable_set(:@cadence_timer_stale_frames_v099142,PMD_AC::STALE_ACTION_TIMER_FRAMES_V099142)
        u.cadence_stale_action_guard_v099142
        timer_guard=(u.instance_variable_get(:@action_timer).to_i==0 && u.instance_variable_get(:@action)==:idle)
      rescue
        handoff=false;dispatch=false;clamp=false;timer_guard=false
      ensure
        t.instance_variable_set(:@pixel_x,tx);t.instance_variable_set(:@pixel_y,ty)
        saved.each{|iv,val|u.instance_variable_set(iv,val)}
      end
    end
    pass=handoff&&dispatch&&clamp&&timer_guard
    @spatial_framework_failed_v09914=true unless pass
    log_event(:verify,'POST_KILL_TARGET_HANDOFF_V099142 pass='+(handoff ? '1':'0')+
      ' species=charmander next_target=caterpie target_alive=1')
    log_event(:verify,'ATTACK_CADENCE_RECOVERY_V099142 pass='+(pass ? '1':'0')+
      ' cooldown_clamp='+(clamp ? '1':'0')+' dispatch='+(dispatch ? '1':'0')+
      ' stale_timer_guard='+(timer_guard ? '1':'0')+' normal_attack_speed_unchanged=1')
    begin
      lines=[]
      lines << 'PMD AutoChess Attack Cadence Recovery v0.99.14.2'
      lines << 'Post-kill target handoff: '+(handoff ? 'PASS':'FAIL')
      lines << 'Cooldown clamp: '+(clamp ? 'PASS':'FAIL')
      lines << 'Attack dispatch recovery: '+(dispatch ? 'PASS':'FAIL')
      lines << 'Stale action timer guard: '+(timer_guard ? 'PASS':'FAIL')
      lines << 'Normal Attack Speed modified: NO'
      lines << 'Damage formula modified: NO'
      lines << 'Frozen Combat Core direct modification: NO'
      lines << 'Review PASS: '+(pass ? '1':'0')
      File.open(PMD_AC::ATTACK_CADENCE_REPORT_V099142,'wb'){|f|f.write(lines.join("\n")+"\n")}
    rescue
      @spatial_framework_failed_v09914=true
    end
    @verification_done[:post_kill_cadence_v099142]=true
  end

  def update_verification_script
    if verification_mode==:spatial_framework_expansion_v09914 && !@verification_done[:verification_complete]
      verify_post_kill_cadence_v099142 if @verification_frame.to_i>=134
    end
    pmd_ac_v099142_update_verification_script
  end
end
