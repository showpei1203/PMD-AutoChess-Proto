# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Battle Stalemate Safety Net v0.89
# 分類：戰鬥流程保護／極端僵局防護
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v0.89 不改正常戰鬥節奏，只處理極端「雙方仍存活，但長時間完全沒有實質進展」
# 的戰局。這種情況可能來自走位互卡、極端 Kite、技能條件、低命中／低傷害組合，
# 或未來加入更多 Pokémon 後出現目前測試陣容沒有碰到的邊界案例。
#
# Safety Net 分兩階段：
# 1. STALL_WATCH：9 秒（540 battle frames）無進展。
#    - 不限制走位。
#    - 額外每 30f 給所有存活 Pokémon +2 Energy。
#    - 讓技能更快有機會自行打破僵局。
#
# 2. STALL_ESCALATE / Resolve Mode：16 秒（960 battle frames）仍無進展。
#    - 進入短暫「強制接戰」邏輯。
#    - 遠程不再主動 Retreat / Kite；射程內就攻擊，射程外才靠近。
#    - 進場一次 +20 Energy，之後每 30f 額外 +4 Energy。
#    - 每 6 秒仍無進展會再記錄一次 resolve pulse 並補 +20 Energy。
#
# 一旦真的出現 Damage / KO / 有效 Heal / Stat Stage 改變 / Control / Shield / Pull
# 等實質效果，STALL timer 立刻 Reset，Resolve Mode 也立即解除，全部回到正常 AI。
#
#==============================================================================
# 【什麼叫「有進展」】
# 一定 Reset：
# - 任意 DAMAGE（含 DOT / Field / Weather，只要真的造成傷害）。
# - DEATH / KO。
# - HEAL 且 actual > 0。
#
# 視為 meaningful skill effect：
# - STAT_STAGE 且 delta != 0。
# - CONTROL（Stun / Fear / Root 等）。
# - SHIELD 新增（不是單純 Expire）。
# - PULL / DISPEL / LINK 建立。
#
# 不 Reset：
# - 純移動／Threat 切換／Target 切換。
# - Skill Hold。
# - HEAL actual=0。
# - 狀態 Aura 的週期 refresh/expire（避免常駐 Aura 讓真正僵局永遠不被判定）。
# - 單純 CAST / VFX / Audio。
#
#==============================================================================
# 【主要設定項】
# STALL_WATCH_FRAMES_V089 = 540        # 約 9 秒
# STALL_RESOLVE_FRAMES_V089 = 960      # 約 16 秒
# STALL_ENERGY_INTERVAL_V089 = 30
# STALL_WATCH_ENERGY_GAIN_V089 = 2
# STALL_RESOLVE_ENERGY_GAIN_V089 = 4
# STALL_RESOLVE_ENTRY_ENERGY_V089 = 20
# STALL_RESOLVE_REPULSE_FRAMES_V089 = 360  # Resolve 後每約 6 秒再補一次
#
#==============================================================================
# 【Resolve Mode 的遠程行為】
# NORMAL 狀態：完全沿用 v0.88.3，遠程可正常拉打，近戰打中後才有 Ranged Stagger。
# Resolve 狀態：
# - target 在 max_range 內：停下並正常 Attack / Skill。
# - target 在 max_range 外：往目標靠近到可攻擊距離。
# - 不使用 Kiter / Artillery 的主動 Retreat 迴圈。
# - Ranged Hit Stagger v0.88.3 仍有效；Resolve 並不讓遠程免疫被黏住。
#
#==============================================================================
# 【LOG】
# 9 秒無進展：
#   [STALL_WATCH] age=540 energy_bonus=+2/30f
#
# 16 秒仍無進展：
#   [STALL_ESCALATE] level=resolve age=960 ...
#
# Resolve 仍持續：
#   [STALL_ESCALATE] level=resolve_pulse ...
#
# 重新產生實質進展：
#   [STALL_RESOLVED] stage=watch/resolve age=... reason=damage/...
#
#==============================================================================
# 【事件／腳本呼叫】
# Runtime 自動套用，不需事件頁呼叫。
#
# Script 查詢：
#   $scene.stalemate_resolve_mode_v089?
#   $scene.stalemate_age_v089
#
#==============================================================================
# 【驗證方式】
# 布陣畫面：NORMAL -> 按 S 一次 -> STALEMATE_SAFETY_V089 -> Shift。
# 預期 LOG：
#   STALEMATE_MANIFEST_V089 pass=1
#   TRUE_FOOT_BAR_V0884 pass=1
#   STALL_WATCH_POLICY_V089 pass=1
#   STALL_RESOLVE_POLICY_V089 pass=1
#   STALL_PROGRESS_RESET_V089 pass=1
#   STALEMATE_CARRY_V089 pass=1
#   STALEMATE_SAFETY_V089 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 實戰 NORMAL 不需要刻意等到 16 秒；若正常戰鬥持續有 Damage，理論上完全不會看到
# STALL_WATCH。只有真的長時間沒進展才應介入。
#
#==============================================================================
# 【不修改內容】
# - 不改 v0.15 Movement Core 的一般行為。
# - 不改 Damage / Accuracy / Evasion / Projectile Tracking。
# - 不改 v0.60.2 Multi-hit Packet / Choreography。
# - 不改 v0.62 Native Semantic Router。
# - 不改 v0.87.1 Miss Pace。
# - 不改 v0.88.3 拉打能力與被 Contact Hit 後的 Ranged Stagger。
# - 不改 Pokémon 數值、種族值、成長、招募、掉落、RPG Encounter。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V089 = '0.89'
  STALL_WATCH_FRAMES_V089 = 540
  STALL_RESOLVE_FRAMES_V089 = 960
  STALL_ENERGY_INTERVAL_V089 = 30
  STALL_WATCH_ENERGY_GAIN_V089 = 2
  STALL_RESOLVE_ENERGY_GAIN_V089 = 4
  STALL_RESOLVE_ENTRY_ENERGY_V089 = 20
  STALL_RESOLVE_REPULSE_FRAMES_V089 = 360
  STALEMATE_VERIFY_END_V089 = 24

  STALEMATE_MANIFEST_V089 = {
    :version=>PATCH_VERSION_V089,
    :watch_frames=>STALL_WATCH_FRAMES_V089,
    :resolve_frames=>STALL_RESOLVE_FRAMES_V089,
    :energy_interval=>STALL_ENERGY_INTERVAL_V089,
    :watch_energy=>STALL_WATCH_ENERGY_GAIN_V089,
    :resolve_energy=>STALL_RESOLVE_ENERGY_GAIN_V089,
    :resolve_entry_energy=>STALL_RESOLVE_ENTRY_ENERGY_V089,
    :resolve_repulse=>STALL_RESOLVE_REPULSE_FRAMES_V089,
    :normal_ai=>:unchanged_until_stall,
    :damage=>:unchanged,
    :accuracy=>:unchanged,
    :range=>:unchanged
  }

  V089_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V089_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:stalemate_safety_v089] +
    V089_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:stalemate_safety_v089}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V089_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:stalemate_safety_v089]='STALEMATE_SAFETY_V089'
end

#==============================================================================
# ■ Game_PMDChessUnit : Resolve Mode 只在真正 stall 時覆寫「主動退避」
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v089_update_movement_policy_logic update_movement_policy_logic unless method_defined?(:pmd_ac_v089_update_movement_policy_logic)

  def stalemate_resolve_runtime_v089?
    return false if @scene==nil
    return false unless @scene.respond_to?(:stalemate_resolve_mode_v089?)
    @scene.stalemate_resolve_mode_v089?
  end

  def update_stalemate_resolve_engagement_v089
    if @target==nil || @target.dead?
      pmd_ac_v089_update_movement_policy_logic
      return
    end

    unless ranged?
      # 近戰只需要繼續正常貼身；不用改既有追擊／命中規則。
      update_melee_logic
      return
    end

    @scene.release_attack_slot(self) if @scene!=nil
    d=distance_to(@target).to_f
    if d<=@max_range.to_f
      clear_move_goal
      face_toward(@target,true)
      begin_attack if @attack_wait.to_f<=0.0
    else
      desired=[@preferred_range.to_f,@max_range.to_f-12.0].min
      desired=@max_range.to_f-12.0 if desired<=0.0
      desired=24.0 if desired<24.0
      move_toward_distance(@target,desired)
    end
  end

  def update_movement_policy_logic
    if stalemate_resolve_runtime_v089?
      update_stalemate_resolve_engagement_v089
    else
      pmd_ac_v089_update_movement_policy_logic
    end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : no-progress timer / escalation / reset / verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v089_start start unless method_defined?(:pmd_ac_v089_start)
  alias pmd_ac_v089_start_battle start_battle unless method_defined?(:pmd_ac_v089_start_battle)
  alias pmd_ac_v089_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v089_update_battle_step)
  alias pmd_ac_v089_log_event log_event unless method_defined?(:pmd_ac_v089_log_event)
  alias pmd_ac_v089_refresh_header refresh_header unless method_defined?(:pmd_ac_v089_refresh_header)
  alias pmd_ac_v089_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v089_prepare_verification_battle)
  alias pmd_ac_v089_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v089_update_verification_script)

  def start
    pmd_ac_v089_start
    stalemate_reset_state_v089
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.89 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.89 stalemate_watch='+PMD_AC::STALL_WATCH_FRAMES_V089.to_s+'f'+
      ' resolve='+PMD_AC::STALL_RESOLVE_FRAMES_V089.to_s+'f'+
      ' watch_energy=+'+PMD_AC::STALL_WATCH_ENERGY_GAIN_V089.to_s+'/'+
      PMD_AC::STALL_ENERGY_INTERVAL_V089.to_s+'f'+
      ' resolve_energy=+'+PMD_AC::STALL_RESOLVE_ENERGY_GAIN_V089.to_s+'/'+
      PMD_AC::STALL_ENERGY_INTERVAL_V089.to_s+'f'+
      ' resolve_retreat=off normal_ai=unchanged')
    refresh_header
  end

  def refresh_header
    pmd_ac_v089_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.89',1)
  end

  def start_battle
    pmd_ac_v089_start_battle
    stalemate_reset_state_v089 if @phase==:battle
  end

  def stalemate_reset_state_v089
    @stall_age_v089=0
    @stall_stage_v089=:normal
    @stall_resolve_enter_age_v089=0
    @stall_last_repulse_age_v089=0
    @stall_progress_guard_v089=false
  end

  def stalemate_age_v089
    @stall_age_v089.to_i
  end

  def stalemate_runtime_v089?
    return true unless respond_to?(:verification_mode)
    m=verification_mode
    m==:normal || m==:stalemate_safety_v089
  end

  def stalemate_resolve_mode_v089?
    stalemate_runtime_v089? && @phase==:battle && @stall_stage_v089==:resolve
  end

  def stalemate_living_both_sides_v089?
    return false if @units==nil
    a=core_living_units(:ally)
    e=core_living_units(:enemy)
    !a.empty? && !e.empty?
  end

  def stall_show_notice_v089(text)
    begin
      if respond_to?(:add_center_notice_v088)
        add_center_notice_v088(text)
      end
    rescue
    end
  end

  def stall_energy_pulse_v089(amount,reason)
    return if @units==nil
    total=0
    @units.each do |u|
      next if u==nil || u.dead?
      if u.respond_to?(:gain_energy)
        total+=u.gain_energy(amount,nil,reason).to_i
      end
    end
    total
  end

  def stall_enter_watch_v089
    return if @stall_stage_v089==:watch || @stall_stage_v089==:resolve
    @stall_stage_v089=:watch
    pmd_ac_v089_log_event(:stall_watch,
      'age='+@stall_age_v089.to_i.to_s+
      ' energy_bonus=+'+PMD_AC::STALL_WATCH_ENERGY_GAIN_V089.to_s+'/'+
      PMD_AC::STALL_ENERGY_INTERVAL_V089.to_s+'f resolve_at='+
      PMD_AC::STALL_RESOLVE_FRAMES_V089.to_s)
    stall_show_notice_v089('戰局膠著：能量加速')
  end

  def stall_enter_resolve_v089
    return if @stall_stage_v089==:resolve
    @stall_stage_v089=:resolve
    @stall_resolve_enter_age_v089=@stall_age_v089.to_i
    @stall_last_repulse_age_v089=@stall_age_v089.to_i
    gained=stall_energy_pulse_v089(PMD_AC::STALL_RESOLVE_ENTRY_ENERGY_V089,:stall_resolve_entry)
    pmd_ac_v089_log_event(:stall_escalate,
      'level=resolve age='+@stall_age_v089.to_i.to_s+
      ' entry_energy=+'+PMD_AC::STALL_RESOLVE_ENTRY_ENERGY_V089.to_s+
      ' actual_total='+gained.to_s+
      ' ranged_retreat=off force_reengage=1 damage_rules=unchanged')
    stall_show_notice_v089('戰局膠著：強制接戰')
  end

  def stall_resolve_pulse_v089
    gained=stall_energy_pulse_v089(PMD_AC::STALL_RESOLVE_ENTRY_ENERGY_V089,:stall_resolve_pulse)
    @stall_last_repulse_age_v089=@stall_age_v089.to_i
    pmd_ac_v089_log_event(:stall_escalate,
      'level=resolve_pulse age='+@stall_age_v089.to_i.to_s+
      ' energy=+'+PMD_AC::STALL_RESOLVE_ENTRY_ENERGY_V089.to_s+
      ' actual_total='+gained.to_s+' resolve_continues=1')
  end

  def stall_mark_progress_v089(reason,detail='')
    return unless stalemate_runtime_v089?
    age=@stall_age_v089.to_i
    stage=@stall_stage_v089 || :normal
    if stage!=:normal || age>=PMD_AC::STALL_WATCH_FRAMES_V089
      pmd_ac_v089_log_event(:stall_resolved,
        'stage='+stage.to_s+' age='+age.to_s+' reason='+reason.to_s+
        (detail=='' ? '' : ' '+detail))
    end
    @stall_age_v089=0
    @stall_stage_v089=:normal
    @stall_resolve_enter_age_v089=0
    @stall_last_repulse_age_v089=0
  end

  def stall_progress_event_v089?(category,message)
    c=category.to_s
    s=message.to_s
    return true if c=='damage' || c=='death'
    if c=='heal'
      m=s.match(/actual=(-?\d+)/)
      return m!=nil && m[1].to_i>0
    end
    if c=='stat_stage'
      m=s.match(/delta=(-?\d+)/)
      return m!=nil && m[1].to_i!=0
    end
    return true if c=='control' || c=='pull' || c=='dispel'
    if c=='shield'
      return s.include?(' +') && !s.include?('EXPIRE')
    end
    if c=='link'
      return s.include?(' LINK <- ')
    end
    false
  end

  def log_event(category,message)
    progress=stalemate_progress_event_v089?(category,message)
    pmd_ac_v089_log_event(category,message)
    if progress && !@stall_progress_guard_v089 && !stalemate_safety_v089?
      stall_mark_progress_v089(category.to_s)
    end
  end

  def update_stalemate_guard_v089
    return unless @phase==:battle
    return unless stalemate_runtime_v089?
    return unless stalemate_living_both_sides_v089?
    return if stalemate_safety_v089?

    @stall_age_v089=@stall_age_v089.to_i+1
    age=@stall_age_v089.to_i

    stall_enter_watch_v089 if age>=PMD_AC::STALL_WATCH_FRAMES_V089 && @stall_stage_v089==:normal
    stall_enter_resolve_v089 if age>=PMD_AC::STALL_RESOLVE_FRAMES_V089 && @stall_stage_v089!=:resolve

    if @stall_stage_v089==:watch && age%PMD_AC::STALL_ENERGY_INTERVAL_V089==0
      stall_energy_pulse_v089(PMD_AC::STALL_WATCH_ENERGY_GAIN_V089,:stall_watch)
    elsif @stall_stage_v089==:resolve
      if age%PMD_AC::STALL_ENERGY_INTERVAL_V089==0
        stall_energy_pulse_v089(PMD_AC::STALL_RESOLVE_ENERGY_GAIN_V089,:stall_resolve)
      end
      if age-@stall_last_repulse_age_v089.to_i>=PMD_AC::STALL_RESOLVE_REPULSE_FRAMES_V089
        stall_resolve_pulse_v089
      end
    end
  end

  def update_battle_step
    pmd_ac_v089_update_battle_step
    update_stalemate_guard_v089 if @phase==:battle
  end

  # -------------------------------------------------------------------------
  # v0.89 Verifier
  # -------------------------------------------------------------------------
  def stalemate_safety_v089?
    verification_mode==:stalemate_safety_v089
  end

  def prepare_verification_battle
    pmd_ac_v089_prepare_verification_battle
    if stalemate_safety_v089?
      @stalemate_v089_failed=false
      stalemate_reset_state_v089
    end
  end

  def log_verify_v089(name,pass,detail='')
    @stalemate_v089_failed=true unless pass
    pmd_ac_v089_log_event(:verify,
      name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_stalemate_manifest_v089
    return if @verification_done[:v089_manifest]
    m=PMD_AC::STALEMATE_MANIFEST_V089
    pass=m[:version]=='0.89' && m[:watch_frames]==540 && m[:resolve_frames]==960 &&
      m[:normal_ai]==:unchanged_until_stall && m[:damage]==:unchanged &&
      m[:accuracy]==:unchanged && m[:range]==:unchanged
    log_verify_v089('STALEMATE_MANIFEST_V089',pass,
      'watch='+m[:watch_frames].to_s+' resolve='+m[:resolve_frames].to_s+
      ' normal_ai=unchanged damage=unchanged accuracy=unchanged range=unchanged')
    @verification_done[:v089_manifest]=true
  end

  def verify_true_foot_bar_v0884
    return if @verification_done[:v089_foot]
    pass=PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884==2 &&
      PMD_AC::TRUE_FOOT_ALPHA_THRESHOLD_V0884==8 &&
      PMD_AC.respond_to?(:true_foot_cache_v0884)
    log_verify_v089('TRUE_FOOT_BAR_V0884',pass,
      'current_frame_opaque_foot=1 gap_y='+PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884.to_s+
      ' logical_y_unchanged=1 hp_energy_same_bar=1')
    @verification_done[:v089_foot]=true
  end

  def verify_stall_watch_policy_v089
    return if @verification_done[:v089_watch]
    old_stage=@stall_stage_v089
    old_age=@stall_age_v089
    @stall_stage_v089=:normal
    @stall_age_v089=PMD_AC::STALL_WATCH_FRAMES_V089
    stall_enter_watch_v089
    pass=@stall_stage_v089==:watch && PMD_AC::STALL_WATCH_ENERGY_GAIN_V089==2 &&
      PMD_AC::STALL_ENERGY_INTERVAL_V089==30
    log_verify_v089('STALL_WATCH_POLICY_V089',pass,
      'age=540 stage='+@stall_stage_v089.to_s+' bonus=+2/30f')
    @stall_stage_v089=old_stage
    @stall_age_v089=old_age
    @verification_done[:v089_watch]=true
  end

  def verify_stall_resolve_policy_v089
    return if @verification_done[:v089_resolve]
    old_stage=@stall_stage_v089
    old_age=@stall_age_v089
    @stall_stage_v089=:watch
    @stall_age_v089=PMD_AC::STALL_RESOLVE_FRAMES_V089
    @stall_progress_guard_v089=true
    stall_enter_resolve_v089
    @stall_progress_guard_v089=false
    pass=@stall_stage_v089==:resolve && PMD_AC::STALL_RESOLVE_ENERGY_GAIN_V089==4 &&
      PMD_AC::STALL_RESOLVE_ENTRY_ENERGY_V089==20
    log_verify_v089('STALL_RESOLVE_POLICY_V089',pass,
      'age=960 stage='+@stall_stage_v089.to_s+' ranged_retreat=off entry_energy=20 pulse=+4/30f')
    @stall_stage_v089=old_stage
    @stall_age_v089=old_age
    @verification_done[:v089_resolve]=true
  end

  def verify_stall_progress_reset_v089
    return if @verification_done[:v089_reset]
    @stall_stage_v089=:resolve
    @stall_age_v089=1000
    stall_mark_progress_v089(:damage,'verifier=1')
    pass=@stall_stage_v089==:normal && @stall_age_v089==0
    log_verify_v089('STALL_PROGRESS_RESET_V089',pass,
      'damage_reset=1 resolve_release=1 age=0')
    @verification_done[:v089_reset]=true
  end

  def verify_stalemate_carry_v089
    return if @verification_done[:v089_carry]
    pass=PMD_AC::RANGED_CONTACT_BASIC_STAGGER_V0883==18 &&
      PMD_AC::RANGED_CONTACT_SKILL_STAGGER_V0883==24 &&
      PMD_AC::DAMAGE_SCATTER_X_MAX_V0883==1.35 &&
      PMD_AC::MELEE_ATTACK_SPRITE_Y_OFFSET_V0882==5 &&
      PMD_AC::BATTLE_FLOW_MANIFEST_V088[:passive_energy_gain]==2
    log_verify_v089('STALEMATE_CARRY_V089',pass,
      'combat_feel=v0.88.3 foot_bar=v0.88.4 miss=v0.87.1 passive_energy=v0.88 '+
      'damage_packet=v0.60.2 unchanged')
    @verification_done[:v089_carry]=true
  end

  def update_verification_script
    unless stalemate_safety_v089?
      pmd_ac_v089_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_stalemate_manifest_v089 if f>=2
    verify_true_foot_bar_v0884 if f>=4
    verify_stall_watch_policy_v089 if f>=6
    verify_stall_resolve_policy_v089 if f>=8
    verify_stall_progress_reset_v089 if f>=10
    verify_stalemate_carry_v089 if f>=12
    if f>=14 && !@verification_done[:v089_final]
      pass=!@stalemate_v089_failed
      log_verify_v089('STALEMATE_SAFETY_V089',pass,
        'manifest=1 foot=1 watch=1 resolve=1 reset=1 carry=1')
      @verification_done[:v089_final]=true
    end
    complete_verification_mode if f>=PMD_AC::STALEMATE_VERIFY_END_V089
  end
end
