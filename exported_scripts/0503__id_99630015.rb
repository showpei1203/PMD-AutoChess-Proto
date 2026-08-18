# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Important / Boss Focus Deterministic Fixture I v1.05.19
#===============================================================================
# 【用途】
# 1. 為 v1.05.15 Important / Boss Focus Tier 建立 Windows NORMAL 實機可重複的
#    deterministic presentation fixture，不再只靠 static/profile QA。
# 2. NORMAL 戰鬥按 F6，暫停正常世界邏輯，依序播放：
#    A. Important Focus：亞空裂斬 profile（60f / mask 242 / signature charge）。
#    B. Boss Focus：撞擊 profile（72f / mask 248 / boss charge）。
# 3. Fixture 只測 Focus Presentation，不真正 begin_skill / resolve_skill，因此不造成傷害、
#    不消耗 Energy、不改狀態／能力階級／Spatial endpoint；完成後恢復原 skill / boss flag。
# 4. 同時保留 v1.05.18 Status Result Completion Authority；本版不重新打開狀態 VFX 問題。
#
# 【為什麼使用 Presentation-only Fixture】
# - Phase B1 要驗的是 tier 的 precharge / mask / charge / banner / Result Hold，而不是技能傷害。
# - 若用真實亞空裂斬與 Boss 撞擊強制打正常戰局，會觸發 Damage、Ability、Threat、KO 等
#   額外 Authority，測試證據反而混濁。人類很喜歡在測一顆燈泡時順便拆配電盤，本版拒絕。
#
# 【操作方式】
# - 進 NORMAL battle 後按 F6 一次。
# - Fixture 會自動：Important → Boss → Restore。
# - 測試期間正常 AI / movement / attack clock 暫停；Focus 自身 presentation clock 照跑。
# - 完成後 NORMAL battle 自動恢復，不需重新進戰鬥。
#
# 【預期畫面】
# Important：
# - 技能名：亞空裂斬
# - 60f precharge
# - mask 242
# - signature 雙層收束 charge
# Boss：
# - 技能名：撞擊
# - 72f precharge
# - mask 248
# - boss 雙向旋轉收束 charge
# 兩段皆保留 v1.05.13 18f Result Hold。
#
# 【主要設定】
# FOCUS_TIER_FIXTURE_IMPORTANT_SKILL_V10519 = :mv_spacial_rend
# FOCUS_TIER_FIXTURE_BOSS_SKILL_V10519      = :mv_tackle
# FOCUS_TIER_FIXTURE_INPUT_V10519           = Input::F6
#
# 【依賴／載入順序】
# - 必須置於 v1.05.15 Important Boss Focus Overrides I 之後。
# - 必須置於 v1.05.18 Status Result Completion Authority 之後。
# - 以 trailing alias/hook 插入 Main 前，不修改 Frozen Combat Core。
#
# 【實際範例】
# NORMAL battle 按 F6：
# 1. 取第一隻存活我方作 Important owner，第一隻存活敵方作 target。
# 2. 暫時將 owner skill 顯示為亞空裂斬，只呼叫 Focus presentation lifecycle。
# 3. Important Focus 完成後，取存活敵方作 Boss owner，暫時 boss=true、skill=撞擊。
# 4. Boss Focus 完成後恢復兩位 owner 原本 skill / boss flag，正常戰鬥繼續。
#
# 【LOG】
# BATTLE_FOCUS_TIER_FIXTURE_V10519 READY input=F6 ...
# BATTLE_FOCUS_TIER_FIXTURE_V10519 START ...
# BATTLE_FOCUS_TIER_FIXTURE_CAST_V10519 expected=important observed=important ...
# BATTLE_FOCUS_TIER_FIXTURE_CAST_V10519 expected=boss observed=boss ...
# BATTLE_FOCUS_TIER_FIXTURE_RESULT_V10519 pass=1 ... restored=1
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ImportantBossFocusFixtureI_v10519']=true

module PMD_AC
  FOCUS_TIER_FIXTURE_IMPORTANT_SKILL_V10519 = :mv_spacial_rend
  FOCUS_TIER_FIXTURE_BOSS_SKILL_V10519 = :mv_tackle
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10519_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10519_update_battle_input)
  alias pmd_ac_v10519_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10519_update_battle_step)
  alias pmd_ac_v10519_start_battle start_battle unless method_defined?(:pmd_ac_v10519_start_battle)
  alias pmd_ac_v10519_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10519_focus_summary)

  def focus_tier_fixture_reset_v10519
    @focus_tier_fixture_active_v10519=false
    @focus_tier_fixture_stage_v10519=:idle
    @focus_tier_fixture_snapshots_v10519={}
    @focus_tier_fixture_important_ok_v10519=false
    @focus_tier_fixture_boss_ok_v10519=false
    @focus_tier_fixture_restored_v10519=false
    @focus_tier_fixture_runs_v10519=0
    @focus_tier_fixture_passes_v10519=0
    @focus_tier_fixture_summary_logged_v10519=false
  end

  def focus_tier_fixture_normal_v10519?
    @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
  rescue
    false
  end

  def focus_tier_fixture_focus_active_v10519?
    respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
  rescue
    false
  end

  def focus_tier_fixture_alive_v10519(team)
    (@units || []).select{|u|u!=nil && u.team==team && !u.dead?}
  rescue
    []
  end

  def focus_tier_fixture_snapshot_owner_v10519(u)
    return if u==nil
    @focus_tier_fixture_snapshots_v10519={} if @focus_tier_fixture_snapshots_v10519==nil
    return if @focus_tier_fixture_snapshots_v10519.has_key?(u.object_id)
    @focus_tier_fixture_snapshots_v10519[u.object_id]={
      :unit=>u,
      :skill_type=>u.instance_variable_get(:@skill_type),
      :skill_name=>u.instance_variable_get(:@skill_name),
      :skill_popup_frames=>u.instance_variable_get(:@skill_popup_frames),
      :boss=>u.instance_variable_get(:@boss)
    }
  rescue
  end

  def focus_tier_fixture_restore_v10519
    (@focus_tier_fixture_snapshots_v10519 || {}).each_value do |s|
      u=s[:unit]
      next if u==nil
      u.instance_variable_set(:@skill_type,s[:skill_type])
      u.instance_variable_set(:@skill_name,s[:skill_name])
      u.instance_variable_set(:@skill_popup_frames,s[:skill_popup_frames].to_i)
      u.instance_variable_set(:@boss,s[:boss])
    end
    @focus_tier_fixture_restored_v10519=true
    true
  rescue
    false
  end

  def focus_tier_fixture_set_skill_v10519(u,key)
    return false if u==nil
    focus_tier_fixture_snapshot_owner_v10519(u)
    data=PMD_AC.skill_data(key)
    return false if data==nil || data.empty?
    u.instance_variable_set(:@skill_type,key)
    u.instance_variable_set(:@skill_name,(data[:name] || key.to_s))
    u.instance_variable_set(:@skill_popup_frames,0)
    true
  rescue
    false
  end

  def focus_tier_fixture_begin_focus_v10519(owner,target,key,expected,boss_flag=false)
    return false if owner==nil || target==nil
    return false unless focus_tier_fixture_set_skill_v10519(owner,key)
    owner.instance_variable_set(:@boss,true) if boss_flag
    before_standard=@focus_tier_standard_count_v10515.to_i
    before_important=@focus_tier_important_count_v10515.to_i
    before_boss=@focus_tier_boss_count_v10515.to_i
    # Direct presentation fixture 也先建立 v1.05.8 baseline snapshot，避免把場上既存
    # effect / projectile 誤判成本次 Focus-owned。
    focus_cast_pre_begin_skill_v1058(owner) if respond_to?(:focus_cast_pre_begin_skill_v1058)
    ok=focus_cast_begin_v1055(owner,target)
    observed=(respond_to?(:focus_tier_v10515) ? focus_tier_v10515(owner) : :unknown)
    p=@focus_cast_profile_v1055 || {}
    profile_ok=false
    if expected==:important
      profile_ok=(observed==:important && p[:intro_frames].to_i==PMD_AC::IMPORTANT_FOCUS_PRECHARGE_V10515 &&
        p[:mask_opacity].to_i==PMD_AC::IMPORTANT_FOCUS_MASK_V10515 && p[:charge_style]==:signature)
      profile_ok &&=(@focus_tier_important_count_v10515.to_i==before_important+1)
    elsif expected==:boss
      profile_ok=(observed==:boss && p[:intro_frames].to_i==PMD_AC::BOSS_FOCUS_PRECHARGE_V10515 &&
        p[:mask_opacity].to_i==PMD_AC::BOSS_FOCUS_MASK_V10515 && p[:charge_style]==:boss)
      profile_ok &&=(@focus_tier_boss_count_v10515.to_i==before_boss+1)
    end
    log_event(:battle,'BATTLE_FOCUS_TIER_FIXTURE_CAST_V10519 expected='+expected.to_s+
      ' observed='+observed.to_s+' skill='+key.to_s+
      ' precharge='+p[:intro_frames].to_i.to_s+' mask='+p[:mask_opacity].to_i.to_s+
      ' charge='+(p[:charge_style]||:none).to_s+' begin='+(ok ? '1':'0')+
      ' profile_pass='+(profile_ok ? '1':'0')+
      ' standard_delta='+(@focus_tier_standard_count_v10515.to_i-before_standard).to_s)
    ok && profile_ok
  rescue
    false
  end

  def focus_tier_fixture_start_v10519
    return false unless focus_tier_fixture_normal_v10519?
    return false if @focus_tier_fixture_active_v10519
    return false if focus_tier_fixture_focus_active_v10519?
    allies=focus_tier_fixture_alive_v10519(:ally)
    enemies=focus_tier_fixture_alive_v10519(:enemy)
    if allies.empty? || enemies.empty?
      log_event(:battle,'BATTLE_FOCUS_TIER_FIXTURE_RESULT_V10519 pass=0 reason=no_alive_units restored=1')
      return false
    end
    @focus_tier_fixture_active_v10519=true
    @focus_tier_fixture_stage_v10519=:important_start
    @focus_tier_fixture_snapshots_v10519={}
    @focus_tier_fixture_important_owner_v10519=allies[0]
    @focus_tier_fixture_important_target_v10519=enemies[0]
    @focus_tier_fixture_boss_owner_v10519=enemies.size>1 ? enemies[1] : enemies[0]
    @focus_tier_fixture_boss_target_v10519=allies.size>1 ? allies[1] : allies[0]
    @focus_tier_fixture_important_ok_v10519=false
    @focus_tier_fixture_boss_ok_v10519=false
    @focus_tier_fixture_restored_v10519=false
    @focus_tier_fixture_runs_v10519=@focus_tier_fixture_runs_v10519.to_i+1
    log_event(:battle,'BATTLE_FOCUS_TIER_FIXTURE_V10519 START mode=presentation_only'+
      ' important_skill='+PMD_AC::FOCUS_TIER_FIXTURE_IMPORTANT_SKILL_V10519.to_s+
      ' boss_skill='+PMD_AC::FOCUS_TIER_FIXTURE_BOSS_SKILL_V10519.to_s+
      ' damage=0 energy_change=0 ai_frozen=1')
    true
  rescue
    @focus_tier_fixture_active_v10519=false
    false
  end

  def focus_tier_fixture_finish_v10519
    focus_tier_fixture_restore_v10519
    pass=@focus_tier_fixture_important_ok_v10519 && @focus_tier_fixture_boss_ok_v10519 && @focus_tier_fixture_restored_v10519
    @focus_tier_fixture_passes_v10519=@focus_tier_fixture_passes_v10519.to_i+1 if pass
    log_event(:battle,'BATTLE_FOCUS_TIER_FIXTURE_RESULT_V10519 pass='+(pass ? '1':'0')+
      ' important='+(@focus_tier_fixture_important_ok_v10519 ? '1':'0')+
      ' boss='+(@focus_tier_fixture_boss_ok_v10519 ? '1':'0')+
      ' expected_precharge=60,72 expected_mask=242,248 restored='+(@focus_tier_fixture_restored_v10519 ? '1':'0'))
    @focus_tier_fixture_active_v10519=false
    @focus_tier_fixture_stage_v10519=:done
    pass
  rescue
    @focus_tier_fixture_active_v10519=false
    false
  end

  def focus_tier_fixture_update_v10519
    return unless @focus_tier_fixture_active_v10519
    case @focus_tier_fixture_stage_v10519
    when :important_start
      @focus_tier_fixture_important_ok_v10519=focus_tier_fixture_begin_focus_v10519(
        @focus_tier_fixture_important_owner_v10519,@focus_tier_fixture_important_target_v10519,
        PMD_AC::FOCUS_TIER_FIXTURE_IMPORTANT_SKILL_V10519,:important,false)
      unless @focus_tier_fixture_important_ok_v10519
        focus_tier_fixture_finish_v10519
        return
      end
      @focus_tier_fixture_stage_v10519=:important_wait
    when :important_wait
      return if focus_tier_fixture_focus_active_v10519?
      @focus_tier_fixture_stage_v10519=:boss_start
    when :boss_start
      @focus_tier_fixture_boss_ok_v10519=focus_tier_fixture_begin_focus_v10519(
        @focus_tier_fixture_boss_owner_v10519,@focus_tier_fixture_boss_target_v10519,
        PMD_AC::FOCUS_TIER_FIXTURE_BOSS_SKILL_V10519,:boss,true)
      unless @focus_tier_fixture_boss_ok_v10519
        focus_tier_fixture_finish_v10519
        return
      end
      @focus_tier_fixture_stage_v10519=:boss_wait
    when :boss_wait
      return if focus_tier_fixture_focus_active_v10519?
      focus_tier_fixture_finish_v10519
    end
  rescue
    focus_tier_fixture_finish_v10519
  end

  def update_battle_input
    pmd_ac_v10519_update_battle_input
    return if $scene!=self || @phase!=:battle
    if Input.trigger?(Input::F6) && focus_tier_fixture_normal_v10519?
      focus_tier_fixture_start_v10519
    end
    focus_tier_fixture_update_v10519
  rescue
    pmd_ac_v10519_update_battle_input
  end

  def update_battle_step
    if @focus_tier_fixture_active_v10519
      # Focus active 時只讓既有 Action Lane / Focus lifecycle 推進；兩段之間完全凍結世界。
      if focus_tier_fixture_focus_active_v10519?
        return pmd_ac_v10519_update_battle_step
      end
      return nil
    end
    pmd_ac_v10519_update_battle_step
  rescue
    nil
  end

  def start_battle
    r=pmd_ac_v10519_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      focus_tier_fixture_reset_v10519
      important_data=PMD_AC.skill_data(PMD_AC::FOCUS_TIER_FIXTURE_IMPORTANT_SKILL_V10519)
      boss_data=PMD_AC.skill_data(PMD_AC::FOCUS_TIER_FIXTURE_BOSS_SKILL_V10519)
      ready=important_data!=nil && !important_data.empty? && boss_data!=nil && !boss_data.empty?
      log_event(:battle,'BATTLE_FOCUS_TIER_FIXTURE_V10519 READY input=F6'+
        ' ready='+(ready ? '1':'0')+' presentation_only=1 damage=0'+
        ' important_expected=60/242/signature boss_expected=72/248/boss')
    end
    r
  end

  def focus_tier_fixture_summary_v10519
    return false if @focus_tier_fixture_summary_logged_v10519
    @focus_tier_fixture_summary_logged_v10519=true
    log_event(:battle,'BATTLE_FOCUS_TIER_FIXTURE_SUMMARY_V10519 runs='+@focus_tier_fixture_runs_v10519.to_i.to_s+
      ' passes='+@focus_tier_fixture_passes_v10519.to_i.to_s+
      ' active_at_summary='+(@focus_tier_fixture_active_v10519 ? '1':'0')+
      ' presentation_only=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10519_focus_summary
    focus_tier_fixture_summary_v10519
    r
  rescue
    false
  end
end
