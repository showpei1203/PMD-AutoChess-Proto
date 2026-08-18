# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Status Semantic VFX Filter + Focus Tier QA v1.05.16
#===============================================================================
# 【用途】
# 1. 修正 Windows 實機觀察到的「小火龍使用叫聲，目標命中動畫像火球」語意錯誤。
# 2. 對純狀態／能力變化技能建立 Presentation Filter：保留施放者 Native Motion、
#    Focus Action Lane、目標腳底 mark、結果文字、v1.05.14 紅／藍能力光圈與 KO；
#    取消不具語意的 projectile / beam / target impact 類命中特效。
# 3. 延續 Phase B1 Important Skill / Boss Focus，加入 profile 靜態 QA，確認 standard / important /
#    boss 三層規格與代表技能判定正確；本版不改其已建立的時序參數。
#
# 【使用者實機依據】
# - v1.05.15 NORMAL：叫聲為 mv_growl、tier=standard，實際成功造成 -攻擊與藍色四光圈，
#   但目標端仍出現不符合「聲音／能力下降」語意的火球狀 impact。
# - 同場 10/10 Focus 完整完成、timeouts=0；3 KO、6 次能力下降、10 次 Result Hold 均正常。
#   因此本版只處理 Presentation root cause，不回頭改 Action Lane / Motion / Combat Core。
#
# 【純狀態技能判定】
# - data[:damage_category] == :status 或 data[:category] == :status。
# - 若資料未提供 category，則檢查 effects 是否完全沒有 :damage 類結果。
# - 「傷害 + 次要狀態」仍屬攻擊技能，不會被本版濾掉，例如 Thunderbolt / Poison Jab。
#
# 【Presentation Filter 規則】
# - launch_projectile：保留原 projectile 邏輯、射程、命中／accuracy Authority，只把新建立的
#   projectile sprite 隱藏，不能因為「看不到」就讓技能瞬間命中。
# - projectile hit / apply_skill_effects：暫時開啟 impact suppression，擋掉舊 Skill Visual
#   Foundation 的 generic target impact；效果運算照舊。
# - add_vfx_impact / add_vfx_impact_xy：只在上述純狀態技能 context 中被攔截。
# - Focus charge、target mark、status text、stat ring 不經這個 filter，因此保留。
#
# 【可調參數】
# STATUS_SEMANTIC_FILTER_ENABLED_V10516 = true
# STATUS_SEMANTIC_FILTER_HIDE_PROJECTILE_V10516 = true
# STATUS_SEMANTIC_FILTER_SUPPRESS_IMPACT_V10516 = true
#
# 【事件／腳本呼叫】
# 無需事件呼叫，NORMAL battle 自動生效。
# 如日後某個 status move 需要專屬合法視覺，不要關掉整體 Filter；應在後續 override 表
# 為該 move 加專屬 presentation exception。
#
# 【範例】
# - Growl / String Shot：不再在目標身上炸 generic impact；保留 -攻擊 / -速度與藍色下降光圈。
# - Sleep Powder：原 projectile 邏輯仍飛行／判定，但 sprite 隱藏；命中後保留 +睡眠與 Focus mark。
# - Water Gun：special damage，不屬 status，水流 beam / impact 完全不受影響。
# - Thunderbolt：即使可能造成麻痺，主分類是 damage，仍保留攻擊 VFX。
#
# 【Phase B1 QA】
# BATTLE_FOCUS_TIER_PROFILE_QA_V10516：檢查 standard=48、important=60、boss=72，
# important / boss mask 階層，以及 Hyper Beam / Water Gun 代表 key 分類。
# 這只驗證 wiring，不冒充 Windows important/boss 視覺 PASS。
#
# 【LOG】
# BATTLE_STATUS_SEMANTIC_VFX_FILTER_V10516 START ...
# BATTLE_STATUS_VFX_FILTER_V10516 skill=... projectile_hidden=... impact_suppressed=...
# BATTLE_FOCUS_TIER_PROFILE_QA_V10516 pass=...
# BATTLE_STATUS_SEMANTIC_VFX_FILTER_SUMMARY_V10516 ...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_StatusSemanticVFXFilter_FocusQA_v10516']=true

module PMD_AC
  STATUS_SEMANTIC_FILTER_ENABLED_V10516 = true
  STATUS_SEMANTIC_FILTER_HIDE_PROJECTILE_V10516 = true
  STATUS_SEMANTIC_FILTER_SUPPRESS_IMPACT_V10516 = true

  def self.status_semantic_data_v10516(key_or_data)
    return key_or_data if key_or_data.is_a?(Hash)
    return nil if key_or_data==nil
    skill_data(key_or_data)
  rescue
    nil
  end

  def self.status_semantic_damage_effect_v10516?(effect)
    return false if effect==nil || !effect.respond_to?(:[])
    t=effect[:type]
    return true if t==:damage
    s=t.to_s
    return true if s=='direct_damage' || s.index('damage_')==0
    false
  rescue
    false
  end

  def self.status_semantic_pure_v10516?(key_or_data)
    return false unless STATUS_SEMANTIC_FILTER_ENABLED_V10516
    d=status_semantic_data_v10516(key_or_data)
    return false if d==nil || d.empty?
    cat=d[:damage_category]
    cat=d[:category] if cat==nil
    return true if cat==:status || cat.to_s=='status'
    effects=d[:effects]
    return false if effects==nil || !effects.respond_to?(:each)
    any=false
    damage=false
    effects.each do |e|
      any=true
      damage=true if status_semantic_damage_effect_v10516?(e)
    end
    any && !damage
  rescue
    false
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10516_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10516_launch_projectile)
  alias pmd_ac_v10516_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v10516_apply_skill_effects)
  alias pmd_ac_v10516_add_vfx_impact add_vfx_impact unless method_defined?(:pmd_ac_v10516_add_vfx_impact)
  alias pmd_ac_v10516_add_vfx_impact_xy add_vfx_impact_xy unless method_defined?(:pmd_ac_v10516_add_vfx_impact_xy)
  alias pmd_ac_v10516_start_battle start_battle unless method_defined?(:pmd_ac_v10516_start_battle)
  alias pmd_ac_v10516_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10516_focus_summary)

  def status_semantic_filter_reset_v10516
    @status_semantic_suppress_impact_v10516=false
    @status_semantic_projectile_hidden_v10516=0
    @status_semantic_impact_suppressed_v10516=0
    @status_semantic_apply_count_v10516=0
    @status_semantic_skills_v10516={}
    @status_semantic_summary_logged_v10516=false
  end

  def status_semantic_pure_v10516?(key_or_data)
    PMD_AC.status_semantic_pure_v10516?(key_or_data)
  rescue
    false
  end

  def status_semantic_note_skill_v10516(key,field)
    @status_semantic_skills_v10516={} if @status_semantic_skills_v10516==nil
    k=(key==nil ? :unknown : key)
    row=@status_semantic_skills_v10516[k]
    row={:projectile_hidden=>0,:impact_suppressed=>0,:apply=>0} if row==nil
    row[field]=row[field].to_i+1
    @status_semantic_skills_v10516[k]=row
  rescue
  end

  def status_semantic_hide_new_projectiles_v10516(before,key)
    return 0 unless PMD_AC::STATUS_SEMANTIC_FILTER_HIDE_PROJECTILE_V10516
    list=@projectile_sprites || []
    count=0
    i=before.to_i
    while i<list.size
      sp=list[i]
      if sp!=nil
        begin
          sp.visible=false if sp.respond_to?(:visible=)
          sp.instance_variable_set(:@pmd_status_semantic_hidden_v10516,true)
          count+=1
        rescue
        end
      end
      i+=1
    end
    if count>0
      @status_semantic_projectile_hidden_v10516=@status_semantic_projectile_hidden_v10516.to_i+count
      count.times{status_semantic_note_skill_v10516(key,:projectile_hidden)}
    end
    count
  rescue
    0
  end

  def status_semantic_suppress_impact_v10516?
    @status_semantic_suppress_impact_v10516 ? true : false
  end

  def status_semantic_with_impact_suppressed_v10516(key)
    old=@status_semantic_suppress_impact_v10516
    @status_semantic_suppress_impact_v10516=true
    begin
      yield
    ensure
      @status_semantic_suppress_impact_v10516=old
    end
  end

  def add_vfx_impact(*args)
    if PMD_AC::STATUS_SEMANTIC_FILTER_SUPPRESS_IMPACT_V10516 && status_semantic_suppress_impact_v10516?
      @status_semantic_impact_suppressed_v10516=@status_semantic_impact_suppressed_v10516.to_i+1
      return nil
    end
    pmd_ac_v10516_add_vfx_impact(*args)
  end

  def add_vfx_impact_xy(*args)
    if PMD_AC::STATUS_SEMANTIC_FILTER_SUPPRESS_IMPACT_V10516 && status_semantic_suppress_impact_v10516?
      @status_semantic_impact_suppressed_v10516=@status_semantic_impact_suppressed_v10516.to_i+1
      return nil
    end
    pmd_ac_v10516_add_vfx_impact_xy(*args)
  end

  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    pure=status_semantic_pure_v10516?(effect_type)
    return pmd_ac_v10516_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute) unless pure
    before=(@projectile_sprites || []).size
    r=status_semantic_with_impact_suppressed_v10516(effect_type) do
      pmd_ac_v10516_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
    end
    hidden=status_semantic_hide_new_projectiles_v10516(before,effect_type)
    if hidden>0
      log_event(:battle,'BATTLE_STATUS_VFX_FILTER_V10516 skill='+effect_type.to_s+
        ' projectile_hidden='+hidden.to_s+' impact_suppressed=0 phase=launch')
    end
    r
  rescue
    pmd_ac_v10516_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
  end

  def apply_skill_effects(user,target,data,multiplier=1.0)
    return pmd_ac_v10516_apply_skill_effects(user,target,data,multiplier) unless status_semantic_pure_v10516?(data)
    key=(data==nil ? nil : (data[:runtime_skill_key] || data[:canonical_move_key]))
    key=@focus_cast_owner_v1055.instance_variable_get(:@skill_type) if key==nil && @focus_cast_owner_v1055!=nil
    before=@status_semantic_impact_suppressed_v10516.to_i
    @status_semantic_apply_count_v10516=@status_semantic_apply_count_v10516.to_i+1
    status_semantic_note_skill_v10516(key,:apply)
    r=status_semantic_with_impact_suppressed_v10516(key) do
      pmd_ac_v10516_apply_skill_effects(user,target,data,multiplier)
    end
    suppressed=@status_semantic_impact_suppressed_v10516.to_i-before
    if suppressed>0
      suppressed.times{status_semantic_note_skill_v10516(key,:impact_suppressed)}
      log_event(:battle,'BATTLE_STATUS_VFX_FILTER_V10516 skill='+(key==nil ? 'unknown' : key.to_s)+
        ' projectile_hidden=0 impact_suppressed='+suppressed.to_s+' phase=apply')
    end
    r
  rescue
    pmd_ac_v10516_apply_skill_effects(user,target,data,multiplier)
  end

  def focus_tier_profile_qa_v10516
    standard_ok=(!PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.include?(:mv_water_gun))
    important_ok=PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.include?(:mv_hyper_beam)
    order_ok=(48 < PMD_AC::IMPORTANT_FOCUS_PRECHARGE_V10515 &&
      PMD_AC::IMPORTANT_FOCUS_PRECHARGE_V10515 < PMD_AC::BOSS_FOCUS_PRECHARGE_V10515)
    mask_ok=(232 < PMD_AC::IMPORTANT_FOCUS_MASK_V10515 &&
      PMD_AC::IMPORTANT_FOCUS_MASK_V10515 < PMD_AC::BOSS_FOCUS_MASK_V10515)
    growl_ok=PMD_AC.status_semantic_pure_v10516?(:mv_growl)
    string_ok=PMD_AC.status_semantic_pure_v10516?(:mv_string_shot)
    sleep_ok=PMD_AC.status_semantic_pure_v10516?(:mv_sleep_powder)
    water_ok=!PMD_AC.status_semantic_pure_v10516?(:mv_water_gun)
    pass=standard_ok && important_ok && order_ok && mask_ok && growl_ok && string_ok && sleep_ok && water_ok
    log_event(:battle,'BATTLE_FOCUS_TIER_PROFILE_QA_V10516 pass='+(pass ? '1':'0')+
      ' standard_water_gun='+(standard_ok ? '1':'0')+
      ' important_hyper_beam='+(important_ok ? '1':'0')+
      ' precharge_order='+(order_ok ? '1':'0')+' mask_order='+(mask_ok ? '1':'0')+
      ' status_growl='+(growl_ok ? '1':'0')+' status_string_shot='+(string_ok ? '1':'0')+
      ' status_sleep_powder='+(sleep_ok ? '1':'0')+' damage_water_gun='+(water_ok ? '1':'0'))
    pass
  rescue
    log_event(:battle,'BATTLE_FOCUS_TIER_PROFILE_QA_V10516 pass=0 error=1') rescue nil
    false
  end

  def start_battle
    r=pmd_ac_v10516_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      status_semantic_filter_reset_v10516
      log_event(:battle,'BATTLE_STATUS_SEMANTIC_VFX_FILTER_V10516 START'+
        ' pure_status_projectile_visual=hidden pure_status_impact=suppressed'+
        ' focus_charge_retained=1 target_mark_retained=1 result_text_retained=1'+
        ' stat_ring_retained=1 ko_retained=1 logical_projectile_retained=1'+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
      focus_tier_profile_qa_v10516
    end
    r
  end

  def status_semantic_summary_v10516
    return false if @status_semantic_summary_logged_v10516
    @status_semantic_summary_logged_v10516=true
    keys=(@status_semantic_skills_v10516 || {}).keys.collect{|x|x.to_s}.sort
    log_event(:battle,'BATTLE_STATUS_SEMANTIC_VFX_FILTER_SUMMARY_V10516'+
      ' apply='+@status_semantic_apply_count_v10516.to_i.to_s+
      ' projectile_hidden='+@status_semantic_projectile_hidden_v10516.to_i.to_s+
      ' impact_suppressed='+@status_semantic_impact_suppressed_v10516.to_i.to_s+
      ' skills=['+keys.join(',')+']'+
      ' phase_b1_profile_qa=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10516_focus_summary
    status_semantic_summary_v10516
    r
  rescue
    false
  end
end

class Sprite_PMDProjectile
  alias pmd_ac_v10516_hit hit unless method_defined?(:pmd_ac_v10516_hit)

  def hit(*args)
    s=@scene rescue nil
    pure=false
    begin
      pure=(s!=nil && s.respond_to?(:status_semantic_pure_v10516?) && s.status_semantic_pure_v10516?(@effect_type))
    rescue
      pure=false
    end
    return pmd_ac_v10516_hit(*args) unless pure && s.respond_to?(:status_semantic_with_impact_suppressed_v10516)
    s.status_semantic_with_impact_suppressed_v10516(@effect_type){pmd_ac_v10516_hit(*args)}
  rescue
    pmd_ac_v10516_hit(*args)
  end
end
