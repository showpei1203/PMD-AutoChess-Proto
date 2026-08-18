# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Focus Cast Action Lane v1.05.8
#==============================================================================
# 【用途】
# 1. 延續 v1.05.5～v1.05.7 已獲使用者肯定的 Focus Cast 外觀，但把技能文字
#    Authority 改回既有「寶可夢頭上 Type 色技能 Banner」，不再使用中央大型 Title。
# 2. 集氣 Intro 由 36f 延長到 48f：遮罩 10f 漸入、通用集氣持續、18f 時才讓
#    舊 Banner 出現；玩家有約 30f 靜止閱讀時間，且 Banner 會一路跟著技能到完成。
# 3. 技能開始真正動作後，不再把整個世界一起恢復。改為 Focus Action Lane：
#    只有施放者與該技能新產生的 Projectile / Effect / Motion 可以繼續前進；其他
#    Pokémon、AI、Attack Wait、Status timer、Zone、Battle Object 與既有飛行物暫停。
# 4. Focus Lock 要等「施放者 action 結束 + Native/Presentation 動作結束 + Tactical
#    位移結束 + 該技能 Projectile 結束 + 短 Effect tail 結束」才釋放全場。
# 5. v1.05.6 FIFO Queue 在 Windows v1.05.7 仍出現 queued>0 / released=0 / dropped>0；
#    本版改由世界凍結本身阻止第二個技能進入 begin_skill，因此正式 NORMAL 下退休
#    Queue capture / cooldown。第一個技能取得 Action Lane 後，其餘單位根本不會推進
#    到下一個技能決策，技能完成後再依原 AI/Speed/Attack Wait 自然繼續。
#
# 【為什麼這次允許「Freeze 到技能完成」】
# - 這是使用者明確指定的戰鬥可讀性規則：玩家要能完整看清楚「誰施放 → 技能動作
#   / 位移 → 命中 / 效果」。因此它不再被視為純 Presentation-only 小提示，而是
#   正式的 Combat Presentation Clock arbitration。
# - Damage Formula、技能資料、命中內容、AI 選擇、Energy 數量、Spatial 終點都不改；
#   但其他單位的世界時鐘會在 Focus Action Lane 期間暫停。這項 timing change 是
#   本版唯一刻意新增的戰鬥節奏規則，必須在 Windows 實機以可讀性為驗收 Authority。
#
# 【主要設定】
# FOCUS_CAST_PRECHARGE_FRAMES_V1058 = 48
#   技能正式開始動作前的 Focus / 集氣時間。
# FOCUS_CAST_FADE_IN_FRAMES_V1058 = 10
#   FS Overlay1 遮罩透明度漸入時間。
# FOCUS_CAST_BANNER_FRAME_V1058 = 18
#   第 18f 才顯示舊頭頂技能 Banner；之後約 30f 可在靜止畫面閱讀。
# FOCUS_CAST_FADE_OUT_FRAMES_V1058 = 18
#   技能開始動作後，遮罩仍以透明度漸退，不阻擋 Action Lane。
# FOCUS_CAST_BANNER_KEEP_FRAMES_V1058 = 42
#   技能 Action Lane 期間，每 frame 將 Focus owner 的舊 Banner 保持至少 42f，
#   因此使用者可一路看到技能名稱；技能完成後改成 18f 自然淡出。
# FOCUS_CAST_EFFECT_TAIL_MAX_V1058 = 24
#   owner action / projectile / 位移都完成後，最多再等新 Effect sprite 24f。
# FOCUS_CAST_SETTLE_FRAMES_V1058 = 6
#   所有主要完成條件都滿足後，再保留 6f 收勢，避免剛命中就立刻解凍。
# FOCUS_CAST_TIMEOUT_V1058 = 360
#   安全上限。避免異常 Persistent Effect 將整場永久鎖死。
#
# 【技能完成判定】
# 仍鎖定，只要任一成立：
# - owner.action == :skill 且 action_timer > 0
# - presentation_motion_active_v055? == true
# - tactical_slide_active_v0914? == true
# - v0.60 multi-contact / multi-ranged choreography 仍屬於 owner
# - Focus 開始後新產生、且尚未 finished 的 Projectile 仍存在
# - 主要動作結束後，新 Effect sprite 尚在播放（最多 24f）
# 全部完成後再等 6f settle，才解凍其他五隻與世界物件。
#
# 【舊技能文字 Authority】
# - 使用既有 Sprite_PMDChessUnit @skill_sprite / skill_popup_frames。
# - 外觀、Type 色、18px 字體、108x24、Render Cache、Microsoft JhengHei Authority
#   全部沿用 v1.04.1～v1.04.6；本版不自己重畫 Banner。
# - Focus 開始先清除其他單位殘留 popup；到第 18f 才讓 Focus owner 的舊 Banner 出現。
# - v1.05.7 中央 300x44 Title 完全停用。
#
# 【Action Lane 世界凍結規則】
# - Intro：沿用 v1.05.5 硬停，owner 本身的 action timer 也不前進。
# - Release 後：Scene#update_battle_step 改為只推進 owner 的 action_timer、movement、
#   visual motion；不跑其他 unit.update / update_logic、Zone、Battle Object、Boss phase。
# - Sprite：只更新 Focus owner 與本次技能真正影響到的 reaction target sprite。
# - Projectile / Effect：Focus 前已存在的物件凍結；Focus 開始後新產生的物件可更新。
# - Camera shake 保留，因為它屬於目前技能 Impact 的演出。
# - Battle End 延後到 Action Lane 完成後下一個正常 battle step 判定，確保 KO 技能
#   能把演出播完。
#
# 【v1.05.6 Queue 退休】
# - NORMAL 下 focus_cast_queue_reason_v1056 永遠 nil，capture_started 不再入隊。
# - 既有 Queue 程式保留在 Scripts.rvdata 作歷史相容，不刪舊腳本；本版以 trailing
#   authority 取代它。PMD Motion verifier 仍不啟用 Focus Action Lane。
#
# 【專屬寶可夢 / Boss 擴充】
# - v1.05.5 的 FOCUS_CAST_SPECIES_OVERRIDES_V1055 / SKILL_OVERRIDES / BOSS_OVERRIDE
#   仍可使用；若值高於本版 minimum，會保留較長設定。
# - 後續可為特定 Species/Boss 新增 charge_style 方法，不必改 Combat Core。
#
# 【事件／操作】
# 無需事件呼叫。NORMAL → Shift。
# 主要 LOG：
#   BATTLE_FOCUS_CAST_ACTION_LANE_V1058 START ...
#   BATTLE_FOCUS_CAST_ACTION_LANE_BEGIN_V1058 ...
#   BATTLE_FOCUS_CAST_ACTION_LANE_RELEASE_V1058 ...
#   BATTLE_FOCUS_CAST_ACTION_LANE_COMPLETE_V1058 ...
#   BATTLE_FOCUS_CAST_ACTION_LANE_SUMMARY_V1058 ...
#
# 【實際範例】
# 1. 傑尼龜決定使用「水槍」。
# 2. 全場停止，Overlay 10f 漸入；通用集氣持續。
# 3. 第 18f，既有 Type 色「水槍」Banner 在傑尼龜頭上出現。
# 4. 第 48f，傑尼龜正式開始 Native shoot；Overlay 18f 漸退。
# 5. 其他五隻完全停住，只有傑尼龜、它的新 Projectile / Effect 和被命中的反應
#    sprite 繼續。Projectile 命中、位移與收勢都結束後再等 6f。
# 6. Action Lane 解鎖，全場從凍結前的狀態繼續。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusCastActionLane_v1058']=true

module PMD_AC
  FOCUS_CAST_PRECHARGE_FRAMES_V1058 = 48
  FOCUS_CAST_FADE_IN_FRAMES_V1058 = 10
  FOCUS_CAST_BANNER_FRAME_V1058 = 18
  FOCUS_CAST_FADE_OUT_FRAMES_V1058 = 18
  FOCUS_CAST_BANNER_KEEP_FRAMES_V1058 = 42
  FOCUS_CAST_BANNER_FADE_FRAMES_V1058 = 18
  FOCUS_CAST_EFFECT_TAIL_MAX_V1058 = 24
  FOCUS_CAST_SETTLE_FRAMES_V1058 = 6
  FOCUS_CAST_TIMEOUT_V1058 = 360
end

class Game_PMDChessUnit
  alias pmd_ac_v1058_focus_lane_begin_skill begin_skill unless method_defined?(:pmd_ac_v1058_focus_lane_begin_skill)
  alias pmd_ac_v1058_focus_lane_update_logic update_logic unless method_defined?(:pmd_ac_v1058_focus_lane_update_logic)

  def begin_skill(skill_target=nil)
    s=@scene
    if s!=nil && s.respond_to?(:focus_cast_pre_begin_skill_v1058)
      s.focus_cast_pre_begin_skill_v1058(self)
    end
    r=pmd_ac_v1058_focus_lane_begin_skill(skill_target)
    if s!=nil && s.respond_to?(:focus_cast_post_begin_skill_v1058)
      s.focus_cast_post_begin_skill_v1058(self)
    end
    r
  end

  # 同一個 logic tick 中，第一位 unit 一旦取得 Focus，後面的 unit.update_logic
  # 立刻停止；因此不用再讓第二、第三招先 begin_skill 後再靠 Queue 補救。
  def update_logic
    s=@scene
    if s!=nil && s.respond_to?(:focus_cast_block_unit_logic_v1058?) &&
       s.focus_cast_block_unit_logic_v1058?(self)
      return
    end
    pmd_ac_v1058_focus_lane_update_logic
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1058_focus_lane_focus_cast_profile_v1055 focus_cast_profile_v1055 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_profile_v1055)
  alias pmd_ac_v1058_focus_lane_focus_cast_begin_v1055 focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_begin_v1055)
  alias pmd_ac_v1058_focus_lane_focus_cast_release_intro_v1055 focus_cast_release_intro_v1055 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_release_intro_v1055)
  alias pmd_ac_v1058_focus_lane_focus_cast_mark_effect_v1055 focus_cast_mark_effect_v1055 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_mark_effect_v1055)
  alias pmd_ac_v1058_focus_lane_focus_cast_complete_lock_v1055 focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_complete_lock_v1055)
  alias pmd_ac_v1058_focus_lane_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v1058_focus_lane_update_battle_step)
  alias pmd_ac_v1058_focus_lane_update_unit_sprites update_unit_sprites unless method_defined?(:pmd_ac_v1058_focus_lane_update_unit_sprites)
  alias pmd_ac_v1058_focus_lane_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v1058_focus_lane_update_effect_sprites)
  alias pmd_ac_v1058_focus_lane_update_projectile_sprites update_projectile_sprites unless method_defined?(:pmd_ac_v1058_focus_lane_update_projectile_sprites)
  alias pmd_ac_v1058_focus_lane_start_battle start_battle unless method_defined?(:pmd_ac_v1058_focus_lane_start_battle)
  alias pmd_ac_v1058_focus_lane_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1058_focus_lane_check_battle_end)
  alias pmd_ac_v1058_focus_lane_focus_cast_log_summary_v1055 focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_log_summary_v1055)
  alias pmd_ac_v1058_focus_lane_focus_cast_queue_log_summary_v1056 focus_cast_queue_log_summary_v1056 unless method_defined?(:pmd_ac_v1058_focus_lane_focus_cast_queue_log_summary_v1056)

  #--------------------------------------------------------------------------
  # ● Mode / profile
  #--------------------------------------------------------------------------
  def focus_cast_action_lane_normal_v1058?
    return false unless respond_to?(:focus_cast_normal_v1055?)
    focus_cast_normal_v1055?
  rescue
    false
  end

  def focus_cast_profile_v1055(user)
    p=pmd_ac_v1058_focus_lane_focus_cast_profile_v1055(user)
    p={} if p==nil
    p[:intro_frames]=PMD_AC::FOCUS_CAST_PRECHARGE_FRAMES_V1058 if
      p[:intro_frames].to_i<PMD_AC::FOCUS_CAST_PRECHARGE_FRAMES_V1058
    p[:fade_in_frames]=PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1058 if
      p[:fade_in_frames].to_i<PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1058
    p[:title_frame]=PMD_AC::FOCUS_CAST_BANNER_FRAME_V1058 if
      p[:title_frame].to_i<PMD_AC::FOCUS_CAST_BANNER_FRAME_V1058
    p[:fade_out_frames]=PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1058 if
      p[:fade_out_frames].to_i<PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1058
    p
  rescue
    {
      :intro_frames=>PMD_AC::FOCUS_CAST_PRECHARGE_FRAMES_V1058,
      :fade_in_frames=>PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1058,
      :title_frame=>PMD_AC::FOCUS_CAST_BANNER_FRAME_V1058,
      :fade_out_frames=>PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1058,
      :mask_opacity=>232,
      :charge_style=>:orbit
    }
  end

  #--------------------------------------------------------------------------
  # ● v1.05.6 Queue retirement
  #--------------------------------------------------------------------------
  def focus_cast_queue_reason_v1056(unit=nil)
    return nil if focus_cast_action_lane_normal_v1058?
    nil
  rescue
    nil
  end

  def focus_cast_queue_capture_started_v1056(unit,target)
    return false if focus_cast_action_lane_normal_v1058?
    false
  rescue
    false
  end

  def focus_cast_queue_update_v1056
    return if focus_cast_action_lane_normal_v1058?
  rescue
  end

  # v1.05.5 的 18f cooldown 不再需要；Action Lane 本身已序列化技能。
  def focus_cast_can_full_v1055(user)
    return false unless focus_cast_action_lane_normal_v1058?
    return false if user==nil
    return false if @focus_cast_intro_active_v1055
    return false if @focus_cast_lock_active_v1055
    true
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # ● begin_skill 前快照：讓 cast 時新產生的 Effect 也被視為本次 Focus-owned
  #--------------------------------------------------------------------------
  def focus_cast_pre_begin_skill_v1058(user)
    return false unless focus_cast_action_lane_normal_v1058?
    @focus_cast_pre_snapshots_v1058={} if @focus_cast_pre_snapshots_v1058==nil
    @focus_cast_pre_snapshots_v1058[user.object_id]={
      :effects=>(@effect_sprites || []).collect{|sp|sp.object_id},
      :projectiles=>(@projectile_sprites || []).collect{|sp|sp.object_id}
    }
    true
  rescue
    false
  end

  def focus_cast_post_begin_skill_v1058(user)
    return false if @focus_cast_pre_snapshots_v1058==nil || user==nil
    if @focus_cast_owner_v1055!=user
      @focus_cast_pre_snapshots_v1058.delete(user.object_id)
    end
    true
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # ● 舊 Banner Authority
  #--------------------------------------------------------------------------
  def focus_cast_clear_title_v1058
    begin
      @focus_cast_title_post_age_v1057=-1
      @focus_cast_title_owner_v1057=nil
      if @focus_cast_title_v1055!=nil
        @focus_cast_title_v1055.visible=false
        @focus_cast_title_v1055.opacity=0
        if @focus_cast_title_v1055.bitmap!=nil && !@focus_cast_title_v1055.bitmap.disposed?
          @focus_cast_title_v1055.bitmap.clear
        end
      end
    rescue
    end
    true
  end

  # v1.05.7 會呼叫這個方法；本版改成「先清所有舊 popup」，不是永久 suppress。
  def focus_cast_clear_legacy_popups_v1057
    (@unit_sprites || []).each do |usp|
      next if usp==nil
      begin
        u=usp.respond_to?(:unit) ? usp.unit : usp.instance_variable_get(:@unit)
        u.instance_variable_set(:@skill_popup_frames,0) if u!=nil
      rescue
      end
    end
    true
  rescue
    false
  end

  # v1.05.7 的 legacy-banner suppression 正式退休。
  def focus_cast_suppress_legacy_banners_v1057
    false
  end

  def focus_cast_update_title_post_v1057
    focus_cast_clear_title_v1058
  rescue
  end

  def focus_cast_show_legacy_banner_v1058
    u=@focus_cast_owner_v1055
    return false if u==nil
    cur=u.instance_variable_get(:@skill_popup_frames).to_i
    keep=PMD_AC::FOCUS_CAST_BANNER_KEEP_FRAMES_V1058
    u.instance_variable_set(:@skill_popup_frames,keep) if cur<keep
    focus_cast_clear_title_v1058
    true
  rescue
    false
  end

  # v1.05.5 / v1.05.7 都會在 title frame 呼叫此方法；改成既有頭頂 Banner。
  def focus_cast_show_title_v1055
    focus_cast_show_legacy_banner_v1058
  rescue
  end

  def focus_cast_hold_legacy_banner_v1058
    return false unless @focus_cast_lock_active_v1055
    u=@focus_cast_owner_v1055
    return false if u==nil
    cur=u.instance_variable_get(:@skill_popup_frames).to_i
    keep=PMD_AC::FOCUS_CAST_BANNER_KEEP_FRAMES_V1058
    u.instance_variable_set(:@skill_popup_frames,keep) if cur<keep
    true
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # ● Focus begin / release / completion lifecycle
  #--------------------------------------------------------------------------
  def focus_cast_begin_v1055(user,target)
    ok=pmd_ac_v1058_focus_lane_focus_cast_begin_v1055(user,target)
    return ok unless ok
    snap=nil
    if @focus_cast_pre_snapshots_v1058!=nil && user!=nil
      snap=@focus_cast_pre_snapshots_v1058.delete(user.object_id)
    end
    snap={:effects=>[], :projectiles=>[]} if snap==nil
    @focus_cast_baseline_effect_ids_v1058=snap[:effects] || []
    @focus_cast_baseline_projectile_ids_v1058=snap[:projectiles] || []
    @focus_cast_reaction_units_v1058=[]
    @focus_cast_release_frame_v1058=-1
    @focus_cast_action_done_frame_v1058=-1
    @focus_cast_settle_age_v1058=0
    @focus_cast_last_effect_frame_v1058=-1
    @focus_cast_lane_frames_v1058=0
    @focus_cast_effect_tail_frames_v1058=0
    @focus_cast_projectile_wait_frames_v1058=0
    @focus_cast_slide_wait_frames_v1058=0
    @focus_cast_timeout_current_v1058=false
    @focus_cast_lane_begin_count_v1058=@focus_cast_lane_begin_count_v1058.to_i+1
    focus_cast_clear_title_v1058
    # v1.05.7 wrapper 會在 parent 返回後清 popup；這裡先不顯示，等第 18f。
    log_event(:battle,'BATTLE_FOCUS_CAST_ACTION_LANE_BEGIN_V1058 user='+user.log_name.to_s+
      ' skill='+user.skill_name.to_s+' target='+(target==nil ? 'NONE' : target.log_name.to_s)+
      ' precharge='+PMD_AC::FOCUS_CAST_PRECHARGE_FRAMES_V1058.to_s+
      ' banner_frame='+PMD_AC::FOCUS_CAST_BANNER_FRAME_V1058.to_s+
      ' world_freeze_until_skill_complete=1 legacy_head_banner=1')
    true
  rescue
    false
  end

  def focus_cast_release_intro_v1055
    u=@focus_cast_owner_v1055
    r=pmd_ac_v1058_focus_lane_focus_cast_release_intro_v1055
    if r
      @focus_cast_release_frame_v1058=Graphics.frame_count.to_i
      @focus_cast_action_done_frame_v1058=-1
      @focus_cast_settle_age_v1058=0
      focus_cast_show_legacy_banner_v1058
      log_event(:battle,'BATTLE_FOCUS_CAST_ACTION_LANE_RELEASE_V1058 user='+
        (u==nil ? 'NONE' : u.log_name.to_s)+' skill='+(u==nil ? 'NONE' : u.skill_name.to_s)+
        ' owner_action_progress=1 other_units_frozen=1 overlay_fade_during_action=1')
    end
    r
  rescue
    false
  end

  def focus_cast_mark_effect_v1055(user,target,kind)
    r=pmd_ac_v1058_focus_lane_focus_cast_mark_effect_v1055(user,target,kind)
    if @focus_cast_lock_active_v1055 && user!=nil && user==@focus_cast_owner_v1055
      @focus_cast_last_effect_frame_v1058=Graphics.frame_count.to_i
      if target!=nil
        @focus_cast_reaction_units_v1058=[] if @focus_cast_reaction_units_v1058==nil
        @focus_cast_reaction_units_v1058.push(target) unless @focus_cast_reaction_units_v1058.include?(target)
      end
    end
    r
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # ● Action Lane busy predicates
  #--------------------------------------------------------------------------
  def focus_cast_action_lane_active_v1058?
    focus_cast_action_lane_normal_v1058? && @focus_cast_lock_active_v1055
  rescue
    false
  end

  def focus_cast_block_unit_logic_v1058?(unit)
    return false unless focus_cast_action_lane_active_v1058?
    return false if unit!=nil && unit==@focus_cast_owner_v1055
    true
  rescue
    false
  end

  def focus_cast_owned_projectile_v1058?(sp)
    return false if sp==nil
    ids=@focus_cast_baseline_projectile_ids_v1058 || []
    !ids.include?(sp.object_id)
  rescue
    false
  end

  def focus_cast_owned_effect_v1058?(sp)
    return false if sp==nil
    ids=@focus_cast_baseline_effect_ids_v1058 || []
    !ids.include?(sp.object_id)
  rescue
    false
  end

  def focus_cast_owner_projectile_active_v1058?
    (@projectile_sprites || []).each do |sp|
      next unless focus_cast_owned_projectile_v1058?(sp)
      begin
        return true unless sp.finished
      rescue
        return true
      end
    end
    false
  rescue
    false
  end

  def focus_cast_owner_effect_active_v1058?
    (@effect_sprites || []).each do |sp|
      next unless focus_cast_owned_effect_v1058?(sp)
      begin
        return true unless sp.finished
      rescue
        return true
      end
    end
    false
  rescue
    false
  end

  def focus_cast_owner_multi_active_v1058?(u)
    return false if u==nil
    st=u.instance_variable_get(:@multi_contact_choreo_v060)
    return true if st!=nil && st[:active]
    (@multi_contact_events_v060 || []).each do |q|
      return true if q!=nil && q[:user]==u
    end
    (@multi_ranged_events_v060 || []).each do |q|
      return true if q!=nil && q[:user]==u
    end
    false
  rescue
    false
  end

  def focus_cast_owner_slide_active_v1058?(u)
    return false if u==nil
    if u.respond_to?(:tactical_slide_active_v0914?)
      return true if u.tactical_slide_active_v0914?
    end
    false
  rescue
    false
  end

  def focus_cast_owner_presentation_active_v1058?(u)
    return false if u==nil
    if u.respond_to?(:presentation_motion_active_v055?)
      return true if u.presentation_motion_active_v055?
    end
    false
  rescue
    false
  end

  def focus_cast_owner_action_busy_v1058?(u)
    return false if u==nil || u.dead?
    return true if u.action==:skill && u.action_timer.to_i>0
    return true if focus_cast_owner_presentation_active_v1058?(u)
    return true if focus_cast_owner_multi_active_v1058?(u)
    return true if focus_cast_owner_slide_active_v1058?(u)
    return true if focus_cast_owner_projectile_active_v1058?
    false
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # ● Action Lane battle clock：只推進 owner action / movement / presentation
  #--------------------------------------------------------------------------
  def focus_cast_update_owner_step_v1058
    u=@focus_cast_owner_v1055
    return if u==nil || u.dead?
    begin
      u.update_action_timer if u.respond_to?(:update_action_timer)
      move_ok=(u.action==:skill) || focus_cast_owner_slide_active_v1058?(u) ||
        focus_cast_owner_presentation_active_v1058?(u)
      u.update_movement if move_ok && u.respond_to?(:update_movement)
      u.update_visual_motion if u.respond_to?(:update_visual_motion)
      u.refresh_motion_visual if u.respond_to?(:refresh_motion_visual)
    rescue
    end
    @focus_cast_lane_frames_v1058=@focus_cast_lane_frames_v1058.to_i+1
    @focus_cast_lane_total_frames_v1058=@focus_cast_lane_total_frames_v1058.to_i+1
  end

  def update_battle_step
    unless focus_cast_action_lane_active_v1058?
      return pmd_ac_v1058_focus_lane_update_battle_step
    end
    # Intro 仍交給 v1.05.5 的 hard-freeze guard（它會直接 return）。
    if @focus_cast_intro_active_v1055
      return pmd_ac_v1058_focus_lane_update_battle_step
    end
    return if @phase!=:battle
    focus_cast_update_owner_step_v1058
    # Zone / battle object / aura / boss phase / other AI intentionally do not advance.
    nil
  rescue
    nil
  end

  #--------------------------------------------------------------------------
  # ● Sprite updates：owner + reaction target；其他單位保持真正畫面凍結
  #--------------------------------------------------------------------------
  def focus_cast_sprite_unit_v1058(sp)
    return nil if sp==nil
    return sp.unit if sp.respond_to?(:unit)
    sp.instance_variable_get(:@unit)
  rescue
    nil
  end

  def update_unit_sprites
    unless focus_cast_action_lane_active_v1058?
      return pmd_ac_v1058_focus_lane_update_unit_sprites
    end
    owner=@focus_cast_owner_v1055
    reactions=@focus_cast_reaction_units_v1058 || []
    (@unit_sprites || []).each do |sp|
      next if sp==nil || sp.disposed?
      u=focus_cast_sprite_unit_v1058(sp)
      next unless u==owner || reactions.include?(u)
      sp.update
    end
    focus_cast_hold_legacy_banner_v1058 if
      @focus_cast_intro_age_v1055.to_i>=PMD_AC::FOCUS_CAST_BANNER_FRAME_V1058
    nil
  rescue
    nil
  end

  #--------------------------------------------------------------------------
  # ● Effect / Projectile：Focus 前存在者凍結；本次技能新產生者繼續
  #--------------------------------------------------------------------------
  def focus_cast_update_owned_array_v1058(iv,kind)
    list=instance_variable_get(iv) || []
    active=[]
    frozen=[]
    list.each do |sp|
      owned=(kind==:effect ? focus_cast_owned_effect_v1058?(sp) : focus_cast_owned_projectile_v1058?(sp))
      if owned
        active.push(sp)
      else
        frozen.push(sp)
      end
    end
    instance_variable_set(iv,active)
    if kind==:effect
      pmd_ac_v1058_focus_lane_update_effect_sprites
    else
      pmd_ac_v1058_focus_lane_update_projectile_sprites
    end
    active_after=instance_variable_get(iv) || []
    instance_variable_set(iv,frozen+active_after)
    true
  rescue
    instance_variable_set(iv,list) if list!=nil
    false
  end

  def update_effect_sprites
    unless focus_cast_action_lane_active_v1058?
      return pmd_ac_v1058_focus_lane_update_effect_sprites
    end
    # Intro 期間連本次 Cast FX 也凍住；只有通用集氣粒子由 Focus layer 自己更新。
    return nil if @focus_cast_intro_active_v1055
    focus_cast_update_owned_array_v1058(:@effect_sprites,:effect)
    nil
  end

  def update_projectile_sprites
    unless focus_cast_action_lane_active_v1058?
      return pmd_ac_v1058_focus_lane_update_projectile_sprites
    end
    return nil if @focus_cast_intro_active_v1055
    focus_cast_update_owned_array_v1058(:@projectile_sprites,:projectile)
    nil
  end

  # v0.60 Multi-hit Scene events使用 Graphics.frame_count；只讓 Focus owner 的事件推進。
  if method_defined?(:update_contact_multi_v060)
    alias pmd_ac_v1058_focus_lane_update_contact_multi_v060 update_contact_multi_v060 unless method_defined?(:pmd_ac_v1058_focus_lane_update_contact_multi_v060)
    def update_contact_multi_v060
      unless focus_cast_action_lane_active_v1058?
        return pmd_ac_v1058_focus_lane_update_contact_multi_v060
      end
      all=@multi_contact_events_v060 || []
      owner=@focus_cast_owner_v1055
      active=[];frozen=[]
      all.each{|q|(q!=nil && q[:user]==owner ? active : frozen).push(q)}
      @multi_contact_events_v060=active
      pmd_ac_v1058_focus_lane_update_contact_multi_v060
      @multi_contact_events_v060=frozen+(@multi_contact_events_v060 || [])
    rescue
      @multi_contact_events_v060=all if all!=nil
    end
  end

  if method_defined?(:update_ranged_multi_v060)
    alias pmd_ac_v1058_focus_lane_update_ranged_multi_v060 update_ranged_multi_v060 unless method_defined?(:pmd_ac_v1058_focus_lane_update_ranged_multi_v060)
    def update_ranged_multi_v060
      unless focus_cast_action_lane_active_v1058?
        return pmd_ac_v1058_focus_lane_update_ranged_multi_v060
      end
      all=@multi_ranged_events_v060 || []
      owner=@focus_cast_owner_v1055
      active=[];frozen=[]
      all.each{|q|(q!=nil && q[:user]==owner ? active : frozen).push(q)}
      @multi_ranged_events_v060=active
      pmd_ac_v1058_focus_lane_update_ranged_multi_v060
      @multi_ranged_events_v060=frozen+(@multi_ranged_events_v060 || [])
    rescue
      @multi_ranged_events_v060=all if all!=nil
    end
  end

  #--------------------------------------------------------------------------
  # ● Completion：等真正技能／位移／Projectile／短 Effect tail 全部結束
  #--------------------------------------------------------------------------
  def focus_cast_update_lock_v1055
    return unless @focus_cast_lock_active_v1055
    u=@focus_cast_owner_v1055
    if u==nil || u.dead?
      focus_cast_complete_lock_v1055(:owner_gone)
      return
    end
    age=Graphics.frame_count.to_i-@focus_cast_start_frame_v1055.to_i
    if age>PMD_AC::FOCUS_CAST_TIMEOUT_V1058
      @focus_cast_timeout_count_v1055=@focus_cast_timeout_count_v1055.to_i+1
      @focus_cast_timeout_current_v1058=true
      @focus_cast_timeout_seen_v1058=true
      focus_cast_complete_lock_v1055(:v1058_timeout)
      return
    end
    return if @focus_cast_intro_active_v1055

    action_busy=focus_cast_owner_action_busy_v1058?(u)
    if action_busy
      @focus_cast_action_done_frame_v1058=-1
      @focus_cast_settle_age_v1058=0
      @focus_cast_projectile_wait_frames_v1058=@focus_cast_projectile_wait_frames_v1058.to_i+1 if focus_cast_owner_projectile_active_v1058?
      @focus_cast_slide_wait_frames_v1058=@focus_cast_slide_wait_frames_v1058.to_i+1 if focus_cast_owner_slide_active_v1058?(u)
      return
    end

    if @focus_cast_action_done_frame_v1058.to_i<0
      @focus_cast_action_done_frame_v1058=Graphics.frame_count.to_i
    end
    tail_age=Graphics.frame_count.to_i-@focus_cast_action_done_frame_v1058.to_i
    if focus_cast_owner_effect_active_v1058? && tail_age<PMD_AC::FOCUS_CAST_EFFECT_TAIL_MAX_V1058
      @focus_cast_effect_tail_frames_v1058=@focus_cast_effect_tail_frames_v1058.to_i+1
      @focus_cast_settle_age_v1058=0
      return
    end

    @focus_cast_settle_age_v1058=@focus_cast_settle_age_v1058.to_i+1
    if @focus_cast_settle_age_v1058.to_i>=PMD_AC::FOCUS_CAST_SETTLE_FRAMES_V1058
      focus_cast_complete_lock_v1055(:skill_visual_complete)
    end
  rescue
  end

  def focus_cast_complete_lock_v1055(reason)
    return false unless @focus_cast_lock_active_v1055
    u=@focus_cast_owner_v1055
    skill=(u==nil ? 'NONE' : u.skill_name.to_s)
    total=Graphics.frame_count.to_i-@focus_cast_start_frame_v1055.to_i
    action_frames=@focus_cast_lane_frames_v1058.to_i
    project_wait=@focus_cast_projectile_wait_frames_v1058.to_i
    effect_tail=@focus_cast_effect_tail_frames_v1058.to_i
    slide_wait=@focus_cast_slide_wait_frames_v1058.to_i
    if u!=nil
      u.instance_variable_set(:@skill_popup_frames,PMD_AC::FOCUS_CAST_BANNER_FADE_FRAMES_V1058)
    end
    r=pmd_ac_v1058_focus_lane_focus_cast_complete_lock_v1055(reason)
    @focus_cast_lane_complete_count_v1058=@focus_cast_lane_complete_count_v1058.to_i+1
    log_event(:battle,'BATTLE_FOCUS_CAST_ACTION_LANE_COMPLETE_V1058 user='+
      (u==nil ? 'NONE' : u.log_name.to_s)+' skill='+skill+' reason='+reason.to_s+
      ' total_frames='+total.to_s+' action_lane_frames='+action_frames.to_s+
      ' projectile_wait='+project_wait.to_s+' effect_tail='+effect_tail.to_s+
      ' slide_wait='+slide_wait.to_s+' world_resume=1')
    @focus_cast_baseline_effect_ids_v1058=[]
    @focus_cast_baseline_projectile_ids_v1058=[]
    @focus_cast_reaction_units_v1058=[]
    @focus_cast_release_frame_v1058=-1
    @focus_cast_action_done_frame_v1058=-1
    @focus_cast_settle_age_v1058=0
    focus_cast_clear_title_v1058
    r
  rescue
    false
  end

  #--------------------------------------------------------------------------
  # ● Battle lifecycle / logs
  #--------------------------------------------------------------------------
  def start_battle
    r=pmd_ac_v1058_focus_lane_start_battle
    if focus_cast_action_lane_normal_v1058?
      @focus_cast_pre_snapshots_v1058={}
      @focus_cast_baseline_effect_ids_v1058=[]
      @focus_cast_baseline_projectile_ids_v1058=[]
      @focus_cast_reaction_units_v1058=[]
      @focus_cast_lane_begin_count_v1058=0
      @focus_cast_lane_complete_count_v1058=0
      @focus_cast_lane_total_frames_v1058=0
      @focus_cast_lane_summary_logged_v1058=false
      @focus_cast_timeout_seen_v1058=false
      focus_cast_clear_title_v1058
      log_event(:battle,'BATTLE_FOCUS_CAST_ACTION_LANE_V1058 START precharge=48 fade_in=10 banner_frame=18'+
        ' banner_authority=legacy_head_type_banner central_title=0'+
        ' world_freeze=until_skill_complete owner_only_action_clock=1 overlay_fade_during_action=1'+
        ' queue_v1056_retired=1 global_cooldown=0 projectile_owned_only=1 effect_owned_only=1'+
        ' hp_unchanged=1 damage_formula_unchanged=1 energy_amount_unchanged=1 ai_choice_unchanged=1'+
        ' spatial_endpoint_unchanged=1 performance_threshold_ms=50')
    end
    r
  end

  def check_battle_end
    # Action Lane 尚未完整收勢時，不讓 Result phase 先切走。
    return false if focus_cast_action_lane_active_v1058?
    pmd_ac_v1058_focus_lane_check_battle_end
  rescue
    false
  end

  def focus_cast_action_lane_log_summary_v1058
    return false if @focus_cast_lane_summary_logged_v1058
    @focus_cast_lane_summary_logged_v1058=true
    log_event(:battle,'BATTLE_FOCUS_CAST_ACTION_LANE_SUMMARY_V1058 begin='+@focus_cast_lane_begin_count_v1058.to_i.to_s+
      ' complete='+@focus_cast_lane_complete_count_v1058.to_i.to_s+
      ' active_at_summary='+(@focus_cast_lock_active_v1055 ? '1' : '0')+
      ' legacy_head_banner=1 central_title=0 queue_v1056_retired=1'+
      ' world_freeze_until_skill_complete=1 precharge_frames=48 action_lane_total_frames='+
      @focus_cast_lane_total_frames_v1058.to_i.to_s+' timeout_seen='+
      (@focus_cast_timeout_seen_v1058 ? '1' : '0'))
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v1058_focus_lane_focus_cast_log_summary_v1055
    focus_cast_action_lane_log_summary_v1058
    r
  rescue
    false
  end

  def focus_cast_queue_log_summary_v1056
    r=pmd_ac_v1058_focus_lane_focus_cast_queue_log_summary_v1056
    unless @focus_cast_queue_retired_summary_v1058
      @focus_cast_queue_retired_summary_v1058=true
      log_event(:battle,'BATTLE_FOCUS_CAST_QUEUE_RETIRED_V1058 pass=1 queued='+
        @focus_cast_queue_total_v1056.to_i.to_s+' released='+@focus_cast_queue_release_count_v1056.to_i.to_s+
        ' dropped='+@focus_cast_queue_drop_count_v1056.to_i.to_s+
        ' replacement=world_freeze_action_lane no_begin_skill_replay=1')
    end
    r
  rescue
    false
  end
end
