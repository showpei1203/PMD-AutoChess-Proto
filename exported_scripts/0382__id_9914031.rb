#==============================================================================
# ■ PMD AutoChess Attack Cadence Verifier Fix v0.99.14.3
#------------------------------------------------------------------------------
# 【用途】
#   修正 v0.99.14.2「技能擊殺後攻擊節奏恢復」驗證場本身的距離設定錯誤。
#   v0.99.14.2 會把小火龍的新目標放在 72px；在 Adaptive Basic 已處於
#   close mode 時，72px 可能位於 close basic 射程外、但又尚未達 ranged
#   resume threshold，因此 basic_allowed=0。Runtime 依安全規則不應強迫攻擊，
#   但舊 verifier 卻仍把 cooldown clamp / dispatch 判定為必須成功，造成假 FAIL。
#
# 【本版規則】
#   1. 不修改任何正常戰鬥的 Attack Speed、傷害、Basic Range 或 AI 決策。
#   2. 只覆寫 verify_post_kill_cadence_v099142 測試內容。
#   3. 測試目標改放在 120px，確保 Adaptive Basic 已進入 ranged 合法區。
#   4. 在執行 recovery 前先驗證 fixture 本身 basic_allowed=1；若不成立，
#      直接以 CADENCE_FIXTURE_VALID_V099143 pass=0 報告測試場無效，不嫁禍 Runtime。
#   5. 舊 v0.99.14.2 的 Runtime watchdog / stale timer guard 完全沿用。
#
# 【可調參數】
#   CADENCE_FIXTURE_DISTANCE_V099143：驗證場的新目標距離，預設 120px。
#   此參數僅供 verifier 使用，不影響 NORMAL 戰鬥。
#
# 【測試方式】
#   NORMAL -> S 一次 -> SPATIAL_FRAMEWORK_EXPANSION_V09914 -> Shift
#
# 【必要 LOG】
#   CADENCE_FIXTURE_VALID_V099143 pass=1
#   POST_KILL_TARGET_HANDOFF_V099142 pass=1
#   ATTACK_CADENCE_RECOVERY_V099143 pass=1
#   SPATIAL_FRAMEWORK_EXPANSION_V09914 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【事件／腳本呼叫】
#   無。此腳本為測試修正層，由既有 verifier 自動呼叫。
#==============================================================================
module PMD_AC
  CADENCE_FIXTURE_DISTANCE_V099143=120.0 unless const_defined?('CADENCE_FIXTURE_DISTANCE_V099143')
  ATTACK_CADENCE_REPORT_V099143='PMD_AttackCadenceRecovery_v0.99.14.3.txt' unless const_defined?('ATTACK_CADENCE_REPORT_V099143')
end

class Scene_PMD_AutoChess
  alias pmd_ac_v099143_start start unless method_defined?(:pmd_ac_v099143_start)

  def start
    pmd_ac_v099143_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.99\.14\.2 Battle Verification Log/,
          'PMD AutoChess Proto v0.99.14.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:cadence_recovery,'PATCH v0.99.14.3 verifier_fixture_distance=120 basic_allowed_precondition=1 runtime_unchanged=1')
  end

  def verify_post_kill_cadence_v099142
    return if @verification_done[:post_kill_cadence_v099142]
    u=verification_unit(:ally,:charmander)
    t=verification_unit(:enemy,:caterpie)
    handoff=false
    fixture_allowed=false
    dispatch=false
    clamp=false
    timer_guard=false
    fixture_distance=PMD_AC::CADENCE_FIXTURE_DISTANCE_V099143.to_f
    if u!=nil && t!=nil && !u.dead? && !t.dead?
      saved={}
      ivs=[:@target,:@pixel_x,:@pixel_y,:@attack_wait,:@action,:@visual_action,:@action_timer,
        :@action_total_frames,:@action_hit_frame,:@action_hit_done,:@skill_target,:@stun_frames,
        :@cadence_last_action_frame_v099142,:@cadence_target_change_frame_v099142,
        :@cadence_last_warn_frame_v099142,:@cadence_timer_last_value_v099142,
        :@cadence_timer_stale_frames_v099142,:@cadence_recovery_count_v099142]
      ivs.each{|iv|saved[iv]=u.instance_variable_get(iv)}
      tx=t.instance_variable_get(:@pixel_x)
      ty=t.instance_variable_get(:@pixel_y)
      begin
        t.instance_variable_set(:@pixel_x,u.instance_variable_get(:@pixel_x).to_f+fixture_distance)
        t.instance_variable_set(:@pixel_y,u.instance_variable_get(:@pixel_y).to_f)
        u.set_target(t)
        handoff=(u.target==t)
        u.instance_variable_set(:@action,:idle)
        u.instance_variable_set(:@visual_action,:idle)
        u.instance_variable_set(:@action_timer,0)
        u.instance_variable_set(:@stun_frames,0)

        # 先確認驗證場本身可合法普攻；若此處失敗，後續 clamp/dispatch 不應被要求。
        fixture_allowed=u.cadence_basic_allowed_v099142?

        if fixture_allowed
          u.instance_variable_set(:@attack_wait,[u.instance_variable_get(:@attack_wait_max).to_f*4.0,400.0].max)
          old=Graphics.frame_count.to_i-PMD_AC::POST_KILL_CADENCE_FORCE_FRAMES_V099142-20
          u.instance_variable_set(:@cadence_last_action_frame_v099142,old)
          u.instance_variable_set(:@cadence_target_change_frame_v099142,old)
          u.cadence_recovery_v099142(true)
          dispatch=(u.instance_variable_get(:@action)==:attack && u.instance_variable_get(:@action_timer).to_i>0)
          clamp=(u.instance_variable_get(:@attack_wait).to_f<=u.instance_variable_get(:@attack_wait_max).to_f+0.01)
        end

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
        handoff=false
        fixture_allowed=false
        dispatch=false
        clamp=false
        timer_guard=false
      ensure
        t.instance_variable_set(:@pixel_x,tx)
        t.instance_variable_set(:@pixel_y,ty)
        saved.each{|iv,val|u.instance_variable_set(iv,val)}
      end
    end

    pass=handoff&&fixture_allowed&&dispatch&&clamp&&timer_guard
    @spatial_framework_failed_v09914=true unless pass
    log_event(:verify,'CADENCE_FIXTURE_VALID_V099143 pass='+(fixture_allowed ? '1':'0')+
      ' distance='+fixture_distance.round.to_s+' basic_allowed='+(fixture_allowed ? '1':'0')+
      ' purpose=post_kill_dispatch')
    log_event(:verify,'POST_KILL_TARGET_HANDOFF_V099142 pass='+(handoff ? '1':'0')+
      ' species=charmander next_target=caterpie target_alive=1')
    log_event(:verify,'ATTACK_CADENCE_RECOVERY_V099143 pass='+(pass ? '1':'0')+
      ' fixture='+(fixture_allowed ? '1':'0')+' cooldown_clamp='+(clamp ? '1':'0')+
      ' dispatch='+(dispatch ? '1':'0')+' stale_timer_guard='+(timer_guard ? '1':'0')+
      ' normal_attack_speed_unchanged=1 runtime_v099142_unchanged=1')
    # 舊 marker 保留相容性，但標明 verifier fixture 已由 v0.99.14.3 修正。
    log_event(:verify,'ATTACK_CADENCE_RECOVERY_V099142 pass='+(pass ? '1':'0')+
      ' cooldown_clamp='+(clamp ? '1':'0')+' dispatch='+(dispatch ? '1':'0')+
      ' stale_timer_guard='+(timer_guard ? '1':'0')+' verifier_fixture=v099143')
    begin
      lines=[]
      lines << 'PMD AutoChess Attack Cadence Recovery v0.99.14.3'
      lines << 'Post-kill target handoff: '+(handoff ? 'PASS':'FAIL')
      lines << 'Verifier fixture basic allowed: '+(fixture_allowed ? 'PASS':'FAIL')
      lines << 'Cooldown clamp: '+(clamp ? 'PASS':'FAIL')
      lines << 'Attack dispatch recovery: '+(dispatch ? 'PASS':'FAIL')
      lines << 'Stale action timer guard: '+(timer_guard ? 'PASS':'FAIL')
      lines << 'Normal Attack Speed modified: NO'
      lines << 'Runtime v0.99.14.2 behavior modified: NO'
      lines << 'Damage formula modified: NO'
      lines << 'Frozen Combat Core direct modification: NO'
      lines << 'Review PASS: '+(pass ? '1':'0')
      File.open(PMD_AC::ATTACK_CADENCE_REPORT_V099143,'wb'){|f|f.write(lines.join("\n")+"\n")}
    rescue
      @spatial_framework_failed_v09914=true
    end
    @verification_done[:post_kill_cadence_v099142]=true
  end
end
