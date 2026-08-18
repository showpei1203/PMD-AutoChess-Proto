# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Status VFX Ownership Seal v1.05.17
#===============================================================================
# 【用途】
# 1. 修正 v1.05.16 後 Growl（叫聲）仍會短暫出現火系小光球的 Windows 實機問題。
# 2. 根因確認為舊 begin_skill 對所有技能無條件呼叫 add_cast_effect(self)，而該函式
#    會依 battler projectile_style 建立 elemental muzzle；小火龍因此即使使用 Growl，
#    仍會產生 fire muzzle。這不是 Growl canonical data 錯誤。
# 3. 封完整「純 Status 技能」Presentation Ownership：保留 Focus、技能名稱、目標 mark、
#    Result Hold、狀態／能力文字、v1.05.14 紅／藍多光圈、KO、音效與所有 Combat Authority；
#    取消 elemental cast muzzle、舊 VFX event burst、v1.05.4 target impact pulse。
# 4. v1.05.15 Important / Boss Focus Tier 架構全部保留，本版不改其時序數值。
#
# 【Windows 實機證據】
# - v1.05.16 LOG：Growl apply 已顯示 projectile_hidden=0 impact_suppressed=1，證明上一版
#   已封 target impact，但仍有肉眼可見小火球；因此殘留來源必須在 apply impact 之外。
# - 舊 begin_skill 每次 CAST 都呼叫 add_cast_effect(self)；add_cast_effect 以 unit.projectile_style
#   建立 muzzle。Charmander 的 projectile style 為 fire，符合肉眼看到的小火球。
#
# 【純 Status Presentation 規則】
# 1. add_cast_effect：若目前 @skill_type 的 canonical/runtime data 是 category=:status，直接略過
#    elemental muzzle。play_skill_se(:cast) 不受影響。
# 2. add_vfx_event_xy：當 v1.05.16 pure-status apply context 開啟時，略過舊 buff/debuff/stun
#    burst sprite；Result Feedback text 與 stat ring 由獨立 Authority 顯示，不依賴此 burst。
# 3. skill_focus_spawn_impact_v1054：pure status 不建立 impact pulse；原 target mark 仍保留。
# 4. Damage skill、Damage+Status skill 完全不進本 Filter。
#
# 【不修改】
# - Damage / HP / AI / Energy / Attack Wait / Priority / hit timing
# - logical Spatial x/y/velocity/endpoints
# - projectile logical travel / accuracy / target selection
# - v1.05.13 KO / 18f Result Hold
# - v1.05.14 多光圈能力升降
# - v1.05.15 standard / important / boss Focus tier
#
# 【事件／腳本呼叫】
# 無需事件呼叫。NORMAL battle 自動生效。
# 若未來某個純 Status move 需要合法專屬視覺，應在後續 override 層加 explicit exception，
# 不要恢復「所有 Status 都使用 battler projectile_style muzzle」的舊規則。
#
# 【實際範例】
# - 小火龍 Growl：Focus + 技能名 + target mark + -攻擊 + 藍色多光圈；不再噴 fire muzzle。
# - String Shot：保留 -速度 + 藍色多光圈，不使用 generic burst。
# - Sleep Powder：logical projectile 仍照舊計算；視覺 projectile / generic impact / burst 隱藏。
# - Water Gun：special damage，cast / beam / impact 全部維持原樣。
#
# 【LOG】
# BATTLE_STATUS_VFX_OWNERSHIP_SEAL_V10517 START ...
# BATTLE_STATUS_VFX_SEAL_V10517 skill=... cast_muzzle=1/vfx_event=1/focus_impact=1
# BATTLE_STATUS_VFX_OWNERSHIP_SEAL_SUMMARY_V10517 ...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_StatusVFXOwnershipSeal_v10517']=true

module PMD_AC
  STATUS_VFX_SEAL_CAST_MUZZLE_V10517 = true
  STATUS_VFX_SEAL_EVENT_BURST_V10517 = true
  STATUS_VFX_SEAL_FOCUS_IMPACT_V10517 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10517_status_with_impact status_semantic_with_impact_suppressed_v10516 unless method_defined?(:pmd_ac_v10517_status_with_impact)
  alias pmd_ac_v10517_add_cast_effect add_cast_effect unless method_defined?(:pmd_ac_v10517_add_cast_effect)
  alias pmd_ac_v10517_add_vfx_event_xy add_vfx_event_xy unless method_defined?(:pmd_ac_v10517_add_vfx_event_xy)
  alias pmd_ac_v10517_skill_focus_spawn_impact skill_focus_spawn_impact_v1054 unless method_defined?(:pmd_ac_v10517_skill_focus_spawn_impact)
  alias pmd_ac_v10517_start_battle start_battle unless method_defined?(:pmd_ac_v10517_start_battle)
  alias pmd_ac_v10517_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10517_focus_summary)

  def status_vfx_seal_skill_key_v10517(unit=nil)
    return nil if unit==nil
    unit.instance_variable_get(:@skill_type)
  rescue
    nil
  end

  def status_vfx_seal_pure_v10517?(key_or_data)
    if respond_to?(:status_semantic_pure_v10516?)
      return status_semantic_pure_v10516?(key_or_data)
    end
    PMD_AC.status_semantic_pure_v10516?(key_or_data)
  rescue
    false
  end

  def status_vfx_seal_note_v10517(key,kind)
    @status_vfx_seal_skills_v10517={} if @status_vfx_seal_skills_v10517==nil
    k=(key==nil ? :unknown : key)
    row=@status_vfx_seal_skills_v10517[k]
    row={:cast_muzzle=>0,:vfx_event=>0,:focus_impact=>0} if row==nil
    row[kind]=row[kind].to_i+1
    @status_vfx_seal_skills_v10517[k]=row
    case kind
    when :cast_muzzle
      @status_vfx_seal_cast_count_v10517=@status_vfx_seal_cast_count_v10517.to_i+1
    when :vfx_event
      @status_vfx_seal_event_count_v10517=@status_vfx_seal_event_count_v10517.to_i+1
    when :focus_impact
      @status_vfx_seal_focus_impact_count_v10517=@status_vfx_seal_focus_impact_count_v10517.to_i+1
    end
    log_event(:battle,'BATTLE_STATUS_VFX_SEAL_V10517 skill='+k.to_s+' '+kind.to_s+'=1')
    true
  rescue
    false
  end

  def status_semantic_with_impact_suppressed_v10516(key)
    old=@status_vfx_seal_context_key_v10517
    @status_vfx_seal_context_key_v10517=key
    begin
      pmd_ac_v10517_status_with_impact(key){yield}
    ensure
      @status_vfx_seal_context_key_v10517=old
    end
  end

  def add_cast_effect(unit)
    key=status_vfx_seal_skill_key_v10517(unit)
    if PMD_AC::STATUS_VFX_SEAL_CAST_MUZZLE_V10517 && status_vfx_seal_pure_v10517?(key)
      status_vfx_seal_note_v10517(key,:cast_muzzle)
      return nil
    end
    pmd_ac_v10517_add_cast_effect(unit)
  rescue
    pmd_ac_v10517_add_cast_effect(unit)
  end

  def add_vfx_event_xy(x,y,type,delay=0)
    if PMD_AC::STATUS_VFX_SEAL_EVENT_BURST_V10517 &&
       respond_to?(:status_semantic_suppress_impact_v10516?) && status_semantic_suppress_impact_v10516?
      key=@status_vfx_seal_context_key_v10517
      if key==nil
        owner=@focus_cast_owner_v1055
        key=status_vfx_seal_skill_key_v10517(owner)
      end
      if status_vfx_seal_pure_v10517?(key)
        status_vfx_seal_note_v10517(key,:vfx_event)
        return nil
      end
    end
    pmd_ac_v10517_add_vfx_event_xy(x,y,type,delay)
  rescue
    pmd_ac_v10517_add_vfx_event_xy(x,y,type,delay)
  end

  def skill_focus_spawn_impact_v1054(user,target)
    key=status_vfx_seal_skill_key_v10517(user)
    if PMD_AC::STATUS_VFX_SEAL_FOCUS_IMPACT_V10517 && status_vfx_seal_pure_v10517?(key)
      status_vfx_seal_note_v10517(key,:focus_impact)
      return false
    end
    pmd_ac_v10517_skill_focus_spawn_impact(user,target)
  rescue
    pmd_ac_v10517_skill_focus_spawn_impact(user,target)
  end

  def status_vfx_seal_reset_v10517
    @status_vfx_seal_cast_count_v10517=0
    @status_vfx_seal_event_count_v10517=0
    @status_vfx_seal_focus_impact_count_v10517=0
    @status_vfx_seal_skills_v10517={}
    @status_vfx_seal_context_key_v10517=nil
    @status_vfx_seal_summary_logged_v10517=false
  end

  def start_battle
    r=pmd_ac_v10517_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      status_vfx_seal_reset_v10517
      log_event(:battle,'BATTLE_STATUS_VFX_OWNERSHIP_SEAL_V10517 START'+
        ' pure_status_cast_muzzle=suppressed pure_status_vfx_event=suppressed'+
        ' pure_status_focus_impact=suppressed target_mark_retained=1 focus_charge_retained=1'+
        ' result_text_retained=1 stat_ring_retained=1 audio_retained=1 logical_projectile_retained=1'+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
    end
    r
  end

  def status_vfx_seal_summary_v10517
    return false if @status_vfx_seal_summary_logged_v10517
    @status_vfx_seal_summary_logged_v10517=true
    keys=(@status_vfx_seal_skills_v10517 || {}).keys.collect{|x|x.to_s}.sort
    log_event(:battle,'BATTLE_STATUS_VFX_OWNERSHIP_SEAL_SUMMARY_V10517'+
      ' cast_muzzle_suppressed='+@status_vfx_seal_cast_count_v10517.to_i.to_s+
      ' vfx_event_suppressed='+@status_vfx_seal_event_count_v10517.to_i.to_s+
      ' focus_impact_suppressed='+@status_vfx_seal_focus_impact_count_v10517.to_i.to_s+
      ' skills=['+keys.join(',')+']'+
      ' important_boss_focus_v10515_retained=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10517_focus_summary
    status_vfx_seal_summary_v10517
    r
  rescue
    false
  end
end
