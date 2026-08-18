# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Focus Cast Burst Queue v1.05.6
#==============================================================================
# 【用途】
# 1. 修正 v1.05.5 在多人同時／短時間連續施放技能時，只有第一位施放者取得
#    Full Focus，其餘技能因 Focus Lock / Global Cooldown 被降級成輕量 Cue 的問題。
# 2. 將「降級」改成 FIFO Skill Focus Queue：技能決策本身仍在原本 frame 發生，
#    Energy 也照原 begin_skill 正常消耗，但若當下已有 Full Focus，該技能的
#    action timer 先暫停，等輪到它時才正式推進技能動作與命中。
# 3. 每一個排隊技能都會完整取得：遮罩透明度漸入 → 集氣 → 技能文字 →
#    戰鬥恢復／遮罩漸退 → Native Action / Projectile / Effect → 完成後下一招。
# 4. 保留 v1.05.3 原始 HP / Damage / Attack Wait / Energy / Movement 節奏；本層
#    只仲裁「同時準備施放的技能」之技能 action clock，不改 Damage Formula 或 AI。
#
# 【為什麼採 Skill Timer Hold，而不是重新呼叫 begin_skill】
# - v1.05.5 的 begin_skill parent chain 內含麻痺、混亂、畏縮、Truant、Disable、
#   Torment、Pressure 等既有正式規則。若在 Focus 忙碌時完全不呼叫 parent，等
#   排到隊伍才重新 begin_skill，這些規則就會在不同 frame 重新判定，語意容易漂移。
# - v1.05.6 因此讓原 begin_skill 完整跑完一次，保留「這一刻技能已正式決定」的
#   Runtime 結果；只凍結該單位後續 update_action_timer，直到它取得 Focus。
# - Energy 不退款、不重扣；技能 Target、Move、Action Timing 都沿用原本那次決策。
#
# 【主要設定】
# FOCUS_CAST_QUEUE_MAX_V1056 = 8
#   3v3 正式戰場理論最大同時待處理技能不會超過 5；8 是安全上限。
# FOCUS_CAST_QUEUE_POPUP_FRAMES_V1056 = 54
#   排到 Full Focus 時重新啟動既有技能名稱 Banner 的正式 54f 顯示期。
# FOCUS_CAST_QUEUE_IDLE_VISUAL_V1056 = :idle
#   排隊等待時只替換 visual_action，避免技能 Native Pose 提前偷跑。
#
# 【Queue 規則】
# - 第一個可取得 Full Focus 的技能：完全沿用 v1.05.5。
# - Focus Intro / Focus Lock 中又有其他技能 begin_skill：
#     1) parent begin_skill 正常完成，技能決策／Energy／Target 已鎖定；
#     2) 該單位 action_timer 暫停，不讓技能提早命中；
#     3) v1.05.4 輕量 Source/Target Cue 與既有 Skill Banner 先隱藏；
#     4) Native visual_action 暫時切回 :idle；
#     5) 依原始 begin_skill 嘗試順序 FIFO 排隊。
# - 當前 Full Focus 真正完成（Effect / Action Complete）後：
#     1) 取出 Queue 第一位；
#     2) 還原其 Native skill pose / Skill Banner；
#     3) 重新建立 v1.05.4 context；
#     4) 直接取得下一個 v1.05.5 Full Focus，不受 18f cooldown 阻擋；
#     5) Intro 結束後該技能 action timer 才繼續前進。
# - 若只是碰到 v1.05.5 Global Cooldown、沒有 active skill，技能也不再降級；
#   會在 cooldown 結束後取得 Full Focus。
# - 排隊單位死亡／action 被既有正式規則取消時，該 entry 安全移除，不重生技能。
#
# 【Cast FX / SE 規則】
# - queued skill 在原 begin_skill 時會暫時抑制 add_cast_effect / play_skill_se(:cast)，
#   避免玩家先看到「第二招施法 FX」，十幾 frame 後才看到它的 Focus。
# - 真正輪到該技能 Full Focus 時，再補回原本的 Cast FX / Cast SE；只補一次。
#
# 【可調參數】
# - 若連續三、四招 Focus 覺得太長，不要先改 Combat Core；可在後續版本只針對
#   queue_position>=2 設較短 intro，例如 12~14f，但 v1.05.6 先保持每招同規格驗收。
# - Boss / 指定 Species / Skill 的 intro、mask、charge 仍沿用 v1.05.5 overrides。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。NORMAL → Shift 後自動啟用。
# LOG：
#   BATTLE_FOCUS_CAST_QUEUE_V1056 START ...
#   BATTLE_FOCUS_CAST_QUEUE_ADD_V1056 user=... skill=... depth=... reason=busy/cooldown/fifo
#   BATTLE_FOCUS_CAST_QUEUE_RELEASE_V1056 user=... skill=... waited=...
#   BATTLE_FOCUS_CAST_QUEUE_DROP_V1056 user=... reason=...
#   BATTLE_FOCUS_CAST_QUEUE_SUMMARY_V1056 queued=... released=... dropped=... max_depth=...
#
# 【實際範例】
# - 小拉達先使用電光一閃 → Full Focus。
# - 同一波傑尼龜與波波也滿 Energy：兩者原技能決策仍成立，但 action timer 暫停。
# - 電光一閃命中／動作完成 → 傑尼龜取得完整水槍 Focus；水槍完成後再輪到波波。
# - 其他沒有排隊的寶可夢與普通攻擊，在每招 Intro 以外仍照原本節奏活動。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusCastBurstQueue_v1056']=true

module PMD_AC
  FOCUS_CAST_QUEUE_MAX_V1056 = 8
  FOCUS_CAST_QUEUE_POPUP_FRAMES_V1056 = 54
  FOCUS_CAST_QUEUE_IDLE_VISUAL_V1056 = :idle
end

class Game_PMDChessUnit
  alias pmd_ac_v1056_focus_queue_start_combat start_combat unless method_defined?(:pmd_ac_v1056_focus_queue_start_combat)
  alias pmd_ac_v1056_focus_queue_begin_skill begin_skill unless method_defined?(:pmd_ac_v1056_focus_queue_begin_skill)
  alias pmd_ac_v1056_focus_queue_update_action_timer update_action_timer unless method_defined?(:pmd_ac_v1056_focus_queue_update_action_timer)
  alias pmd_ac_v1056_focus_queue_presentation_sprite_offset_v055 presentation_sprite_offset_v055 unless method_defined?(:pmd_ac_v1056_focus_queue_presentation_sprite_offset_v055)
  alias pmd_ac_v1056_focus_queue_start_faint start_faint unless method_defined?(:pmd_ac_v1056_focus_queue_start_faint)

  def focus_cast_queue_pending_v1056?
    @focus_cast_queue_pending_v1056 ? true : false
  rescue
    false
  end

  def focus_cast_queue_mark_v1056
    return false if focus_cast_queue_pending_v1056?
    @focus_cast_queue_pending_v1056=true
    @focus_cast_queue_saved_visual_v1056=@visual_action
    @focus_cast_queue_saved_popup_v1056=@skill_popup_frames.to_i
    @visual_action=PMD_AC::FOCUS_CAST_QUEUE_IDLE_VISUAL_V1056
    @skill_popup_frames=0
    true
  rescue
    false
  end

  def focus_cast_queue_release_v1056
    @focus_cast_queue_pending_v1056=false
    if @focus_cast_queue_saved_visual_v1056!=nil
      @visual_action=@focus_cast_queue_saved_visual_v1056
    end
    @skill_popup_frames=PMD_AC::FOCUS_CAST_QUEUE_POPUP_FRAMES_V1056
    @focus_cast_queue_saved_visual_v1056=nil
    @focus_cast_queue_saved_popup_v1056=nil
    true
  rescue
    false
  end

  def focus_cast_queue_cancel_v1056
    @focus_cast_queue_pending_v1056=false
    @focus_cast_queue_saved_visual_v1056=nil
    @focus_cast_queue_saved_popup_v1056=nil
    true
  rescue
    false
  end

  def start_combat
    @focus_cast_queue_pending_v1056=false
    @focus_cast_queue_saved_visual_v1056=nil
    @focus_cast_queue_saved_popup_v1056=nil
    pmd_ac_v1056_focus_queue_start_combat
  end

  def begin_skill(skill_target=nil)
    r=pmd_ac_v1056_focus_queue_begin_skill(skill_target)
    if @action==:skill && @action_timer.to_i>0 && @scene!=nil &&
       @scene.respond_to?(:focus_cast_queue_capture_started_v1056)
      @scene.focus_cast_queue_capture_started_v1056(self,@skill_target)
    end
    r
  end

  def update_action_timer
    return if focus_cast_queue_pending_v1056?
    pmd_ac_v1056_focus_queue_update_action_timer
  end

  def presentation_sprite_offset_v055
    return [0.0,0.0] if focus_cast_queue_pending_v1056?
    pmd_ac_v1056_focus_queue_presentation_sprite_offset_v055
  end

  def start_faint
    if focus_cast_queue_pending_v1056? && @scene!=nil &&
       @scene.respond_to?(:focus_cast_queue_remove_unit_v1056)
      @scene.focus_cast_queue_remove_unit_v1056(self,:owner_faint)
    end
    pmd_ac_v1056_focus_queue_start_faint
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1056_focus_queue_start_battle start_battle unless method_defined?(:pmd_ac_v1056_focus_queue_start_battle)
  alias pmd_ac_v1056_focus_queue_update update unless method_defined?(:pmd_ac_v1056_focus_queue_update)
  alias pmd_ac_v1056_focus_queue_add_cast_effect add_cast_effect unless method_defined?(:pmd_ac_v1056_focus_queue_add_cast_effect)
  alias pmd_ac_v1056_focus_queue_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v1056_focus_queue_play_skill_se)
  alias pmd_ac_v1056_focus_queue_focus_cast_can_full_v1055 focus_cast_can_full_v1055 unless method_defined?(:pmd_ac_v1056_focus_queue_focus_cast_can_full_v1055)
  alias pmd_ac_v1056_focus_queue_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1056_focus_queue_check_battle_end)

  def focus_cast_queue_reset_v1056
    @focus_cast_queue_v1056=[]
    @focus_cast_queue_force_full_v1056=false
    @focus_cast_queue_replay_cast_v1056=false
    @focus_cast_queue_total_v1056=0
    @focus_cast_queue_release_count_v1056=0
    @focus_cast_queue_drop_count_v1056=0
    @focus_cast_queue_max_depth_v1056=0
    @focus_cast_queue_promoted_downgrade_v1056=0
    @focus_cast_queue_summary_logged_v1056=false
    true
  rescue
    false
  end

  def focus_cast_queue_normal_v1056?
    return false unless respond_to?(:focus_cast_normal_v1055?)
    focus_cast_normal_v1055?
  rescue
    false
  end

  def focus_cast_queue_reason_v1056(unit=nil)
    return nil unless focus_cast_queue_normal_v1056?
    return nil if @focus_cast_queue_force_full_v1056
    return :busy if @focus_cast_intro_active_v1055 || @focus_cast_lock_active_v1055
    q=@focus_cast_queue_v1056 || []
    return :fifo unless q.empty?
    now=Graphics.frame_count.to_i
    last=@focus_cast_last_complete_frame_v1055.to_i
    cd=PMD_AC::FOCUS_CAST_GLOBAL_COOLDOWN_V1055.to_i
    return :cooldown if now-last<cd
    nil
  rescue
    nil
  end

  # begin_skill 深層 parent 會先呼叫這兩個方法；如果當下明確會進 Queue，
  # 先抑制 Cast FX / SE，等輪到 Full Focus 再補回，避免視覺因果提前。
  def add_cast_effect(unit)
    if !@focus_cast_queue_replay_cast_v1056 && focus_cast_queue_reason_v1056(unit)!=nil
      return nil
    end
    pmd_ac_v1056_focus_queue_add_cast_effect(unit)
  end

  def play_skill_se(unit,stage,data=nil)
    if !@focus_cast_queue_replay_cast_v1056 && stage==:cast &&
       focus_cast_queue_reason_v1056(unit)!=nil
      return nil
    end
    pmd_ac_v1056_focus_queue_play_skill_se(unit,stage,data)
  end

  def focus_cast_can_full_v1055(user)
    if @focus_cast_queue_force_full_v1056
      return false unless focus_cast_queue_normal_v1056?
      return false if user==nil
      return false if @focus_cast_intro_active_v1055
      return false if @focus_cast_lock_active_v1055
      return true
    end
    pmd_ac_v1056_focus_queue_focus_cast_can_full_v1055(user)
  rescue
    false
  end

  def focus_cast_queue_hide_light_context_v1056(unit)
    if @skill_focus_contexts_v1054!=nil
      @skill_focus_contexts_v1054.delete_if{|c|c!=nil && c[:user]==unit}
    end
    true
  rescue
    false
  end

  def focus_cast_queue_capture_started_v1056(unit,target)
    return false unless focus_cast_queue_normal_v1056?
    return false if unit==nil || unit==@focus_cast_owner_v1055
    return true if unit.respond_to?(:focus_cast_queue_pending_v1056?) && unit.focus_cast_queue_pending_v1056?
    reason=focus_cast_queue_reason_v1056(unit)
    return false if reason==nil
    @focus_cast_queue_v1056=[] if @focus_cast_queue_v1056==nil
    if @focus_cast_queue_v1056.size>=PMD_AC::FOCUS_CAST_QUEUE_MAX_V1056
      # 3v3 正式戰場理論上不會撞到；若真的發生，保留原技能而不凍結，避免死鎖。
      @focus_cast_queue_drop_count_v1056=@focus_cast_queue_drop_count_v1056.to_i+1
      log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_DROP_V1056 user='+unit.log_name.to_s+
        ' skill='+unit.skill_name.to_s+' reason=queue_full action_continues=1')
      return false
    end
    return false unless unit.focus_cast_queue_mark_v1056
    focus_cast_queue_hide_light_context_v1056(unit)
    entry={:user=>unit,:target=>target,:queued_at=>Graphics.frame_count.to_i,:reason=>reason,
           :skill=>unit.skill_name.to_s}
    @focus_cast_queue_v1056.push(entry)
    @focus_cast_queue_total_v1056=@focus_cast_queue_total_v1056.to_i+1
    depth=@focus_cast_queue_v1056.size
    @focus_cast_queue_max_depth_v1056=depth if depth>@focus_cast_queue_max_depth_v1056.to_i
    # v1.05.5 已經把這次記成 downgraded；v1.05.6 會把它正式升格回 Full Focus。
    if @focus_cast_downgrade_count_v1055.to_i>0
      @focus_cast_downgrade_count_v1055-=1
      @focus_cast_queue_promoted_downgrade_v1056=@focus_cast_queue_promoted_downgrade_v1056.to_i+1
    end
    log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_ADD_V1056 user='+unit.log_name.to_s+
      ' skill='+unit.skill_name.to_s+' target='+(target==nil ? 'NONE' : target.log_name.to_s)+
      ' depth='+depth.to_s+' reason='+reason.to_s+' skill_timer_hold=1 energy_recharge=0')
    true
  rescue
    false
  end

  def focus_cast_queue_remove_unit_v1056(unit,reason)
    return false if unit==nil
    removed=false
    q=@focus_cast_queue_v1056 || []
    q.delete_if do |e|
      hit=e!=nil && e[:user]==unit
      removed=true if hit
      hit
    end
    if removed
      unit.focus_cast_queue_cancel_v1056 if unit.respond_to?(:focus_cast_queue_cancel_v1056)
      @focus_cast_queue_drop_count_v1056=@focus_cast_queue_drop_count_v1056.to_i+1
      log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_DROP_V1056 user='+unit.log_name.to_s+
        ' skill='+unit.skill_name.to_s+' reason='+reason.to_s)
    end
    removed
  rescue
    false
  end

  def focus_cast_queue_valid_entry_v1056(entry)
    return false if entry==nil
    u=entry[:user]
    return false if u==nil || u.dead?
    return false unless u.respond_to?(:focus_cast_queue_pending_v1056?) && u.focus_cast_queue_pending_v1056?
    return false unless u.action==:skill && u.action_timer.to_i>0
    true
  rescue
    false
  end

  def focus_cast_queue_next_v1056
    q=@focus_cast_queue_v1056 || []
    while !q.empty?
      e=q.shift
      if focus_cast_queue_valid_entry_v1056(e)
        return e
      end
      u=e==nil ? nil : e[:user]
      if u!=nil && u.respond_to?(:focus_cast_queue_cancel_v1056)
        u.focus_cast_queue_cancel_v1056
      end
      @focus_cast_queue_drop_count_v1056=@focus_cast_queue_drop_count_v1056.to_i+1
      log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_DROP_V1056 user='+(u==nil ? 'NONE' : u.log_name.to_s)+
        ' skill='+(e==nil ? 'NONE' : e[:skill].to_s)+' reason=invalid_before_release')
    end
    nil
  rescue
    nil
  end

  def focus_cast_queue_cooldown_ready_v1056(entry)
    return true if entry==nil
    return true if entry[:reason]==:busy || entry[:reason]==:fifo
    now=Graphics.frame_count.to_i
    last=@focus_cast_last_complete_frame_v1055.to_i
    now-last>=PMD_AC::FOCUS_CAST_GLOBAL_COOLDOWN_V1055.to_i
  rescue
    true
  end

  def focus_cast_queue_release_entry_v1056(entry)
    return false unless focus_cast_queue_valid_entry_v1056(entry)
    u=entry[:user];t=entry[:target]
    # Target 在等待期間死亡時，沿用單位目前正式 target；若仍無有效目標，
    # 保留原 skill_target，讓既有 resolve 規則自行判斷，不人工製造額外命中。
    if (t==nil || t.dead?) && u.respond_to?(:target_alive?)
      begin
        cur=u.instance_eval{@target}
        t=cur if cur!=nil && !cur.dead?
      rescue
      end
    end
    u.focus_cast_queue_release_v1056
    if respond_to?(:skill_focus_begin_v1054)
      skill_focus_begin_v1054(u,t)
    end
    @focus_cast_queue_force_full_v1056=true
    ok=focus_cast_begin_v1055(u,t)
    @focus_cast_queue_force_full_v1056=false
    unless ok
      # 不應發生；安全回復 action timer，避免單位永久卡在 queue。
      @focus_cast_queue_drop_count_v1056=@focus_cast_queue_drop_count_v1056.to_i+1
      log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_DROP_V1056 user='+u.log_name.to_s+
        ' skill='+u.skill_name.to_s+' reason=focus_begin_failed action_resumed=1')
      return false
    end
    @focus_cast_queue_replay_cast_v1056=true
    pmd_ac_v1056_focus_queue_add_cast_effect(u)
    pmd_ac_v1056_focus_queue_play_skill_se(u,:cast,nil)
    @focus_cast_queue_replay_cast_v1056=false
    @focus_cast_queue_release_count_v1056=@focus_cast_queue_release_count_v1056.to_i+1
    waited=Graphics.frame_count.to_i-entry[:queued_at].to_i
    log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_RELEASE_V1056 user='+u.log_name.to_s+
      ' skill='+u.skill_name.to_s+' target='+(t==nil ? 'NONE' : t.log_name.to_s)+
      ' waited='+waited.to_s+' remaining='+(@focus_cast_queue_v1056 || []).size.to_s+
      ' full_focus=1 skill_timer_resume_after_intro=1')
    true
  rescue
    @focus_cast_queue_force_full_v1056=false
    @focus_cast_queue_replay_cast_v1056=false
    false
  end

  def focus_cast_queue_update_v1056
    return unless focus_cast_queue_normal_v1056?
    return if @focus_cast_intro_active_v1055 || @focus_cast_lock_active_v1055
    q=@focus_cast_queue_v1056 || []
    return if q.empty?
    first=q[0]
    return unless focus_cast_queue_cooldown_ready_v1056(first)
    entry=focus_cast_queue_next_v1056
    focus_cast_queue_release_entry_v1056(entry) if entry!=nil
  rescue
  end

  def start_battle
    r=pmd_ac_v1056_focus_queue_start_battle
    if focus_cast_queue_normal_v1056?
      focus_cast_queue_reset_v1056
      log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_V1056 START policy=fifo_all_skills'+
        ' queued_skill_timer_hold=1 queued_visual_pose_hidden=1 cast_fx_se_deferred=1'+
        ' busy_skill_downgrade_retired=1 cooldown_skill_downgrade_retired=1'+
        ' release_after_previous_focus_complete=1 max_queue=8'+
        ' hp_unchanged=1 damage_unchanged=1 energy_amount_unchanged=1 ai_decision_unchanged=1')
    end
    r
  end

  def update
    r=pmd_ac_v1056_focus_queue_update
    focus_cast_queue_update_v1056 if $scene==self
    r
  end

  def focus_cast_queue_log_summary_v1056
    return false if @focus_cast_queue_summary_logged_v1056
    @focus_cast_queue_summary_logged_v1056=true
    log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_SUMMARY_V1056 queued='+@focus_cast_queue_total_v1056.to_i.to_s+
      ' released='+@focus_cast_queue_release_count_v1056.to_i.to_s+
      ' dropped='+@focus_cast_queue_drop_count_v1056.to_i.to_s+
      ' max_depth='+@focus_cast_queue_max_depth_v1056.to_i.to_s+
      ' promoted_v1055_downgrades='+@focus_cast_queue_promoted_downgrade_v1056.to_i.to_s+
      ' pending=' + ((@focus_cast_queue_v1056 || []).size).to_s+
      ' fifo=1 all_surviving_skills_full_focus=1 skill_timer_hold=1')
    true
  rescue
    false
  end

  def check_battle_end
    before=@phase
    r=pmd_ac_v1056_focus_queue_check_battle_end
    if before==:battle && @phase!=:battle
      focus_cast_queue_log_summary_v1056
      (@focus_cast_queue_v1056 || []).each do |e|
        u=e==nil ? nil : e[:user]
        u.focus_cast_queue_cancel_v1056 if u!=nil && u.respond_to?(:focus_cast_queue_cancel_v1056)
      end
      @focus_cast_queue_v1056=[]
    end
    r
  end
end
