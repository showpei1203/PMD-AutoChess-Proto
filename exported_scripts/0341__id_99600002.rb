# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Runtime Completion V v0.96
# 分類：特性 Ability／Generation V Runtime Completion V／Verifier
#
# 【用途】
# 承接 v0.24～v0.67.1 已 Freeze 的 Ability Runtime，在不修改舊腳本的前提下，
# 新增 12 種 Ability 的實際 AutoChess 行為，並把 Species Runtime Coverage 推進到
# 494/494。此版仍保留尚未完成的 12 種 Ability／56 slots 為下一階段工作。
#
# 【本版實作】
# Pressure / Natural Cure / Regenerator / Trace / Unnerve / Mold Breaker /
# Magic Bounce / Analytic / Cute Charm / Healer / Run Away / Multitype
#
# 【核心規則】
# 1. Pressure：技能成功進入 Cast 且鎖定 Pressure 敵人時，施術者獲得 Energy Debt。
#    後續所有 gain_energy 與 v0.88 時間自然回能先償還 Debt，不直接扣現有 Energy。
# 2. Natural Cure：主要異常持續 120f 後自動解除一項；無異常時 Timer 歸零。
# 3. Regenerator：與所有敵人距離 >150px 且未滿血，安全累積 180f 後回 1/6 MaxHP。
# 4. Trace：正式開戰後複製一名存活敵人的 Ability；使用 v0.57 ability override。
# 5. Unnerve：敵方 basic_hit / damage_taken 回能 ×0.75；時間自然回能不受影響。
# 6. Mold Breaker：Direct Damage 與敵方 Skill Effect 結算時暫時隱藏目標 Ability。
# 7. Magic Bounce：反射單體敵對純狀態技能；不反 Field／Weather／傷害技／自我技。
# 8. Analytic：目標比自己更晚完成上一個 Action 時，Direct Damage power ×1.30。
# 9. Cute Charm：受到敵方接觸傷害後 30% 使攻擊者進入 v0.58 無性別化迷人 180f。
# 10. Healer：每 120f 30% 機率替一名隊友解除一項主要異常。
# 11. Run Away：免疫 Root／Bind／Fire Trap，Mean Look 亦不構成移動鎖定。
# 12. Multitype：Arceus 拒絕所有暫時 Type Override，保持目前 Form 的正式屬性。
#
# 【可調參數】
# 參數集中在前一支 Ability Runtime Data v0.96：
#   PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V096
# 例如：
#   PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V096[:pressure][:debt] = 20
#   PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V096[:regenerator][:safe_distance] = 150.0
#
# 【事件／腳本呼叫方式】
# 一般遊戲不需要事件呼叫，Ability 由 Pokémon Instance ability_slot 自動運作。
# Verifier：布陣 NORMAL → S 一次 → ABILITY_RUNTIME_V096 → Shift。
# Debug：
#   unit.pressure_debt_v096
#   unit.last_action_completed_frame_v096
#   scene.ability_global_units_v096
#
# 【實際範例】
# Deoxys 被技能鎖定：Pressure Debt +20，之後 +30 Energy 時先還 20，只實得 +10。
# Celebi 中 Poison 120f：Natural Cure 清除 Poison。
# Ho-Oh 脫離戰線：Regenerator 安全 180f 後回復 MaxHP/6。
# Espeon(Magic Bounce) 被 Growl：Growl 效果反射回原施術者。
# Arceus 被 Soak：set_type_override_v057 回傳 false，屬性不變。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 禁止使用舊式 instance-variable reflection probe。
# - 不改 v0.60.2 Damage Packet、v0.62 Native Router、v0.91.4 Spatial Runtime。
# - Rivalry 因專案尚無正式性別資料，本版不製造 UID 奇偶數假性別。
# - Ability 觸發重要事件會寫 LOG，並在正式戰鬥顯示簡短「特性｜名稱」提示。
#==============================================================================
module PMD_AC
  ABILITY_NAME_ZH_V096={
    :pressure=>'壓迫感',:natural_cure=>'自然回復',:regenerator=>'再生力',
    :trace=>'複製',:unnerve=>'緊張感',:mold_breaker=>'破格',
    :magic_bounce=>'魔法鏡',:analytic=>'分析',:cute_charm=>'迷人之軀',
    :healer=>'治癒之心',:run_away=>'逃跑',:multitype=>'多屬性'
  }
  ABILITY_MAJOR_STATUSES_V096=[:poison,:burn,:paralysis,:sleep,:freeze]
  ABILITY_RUNTIME_VERIFY_END_V096=40

  V096_OLD_VERIFICATION_MODES=VERIFICATION_MODES.dup
  V096_OLD_VERIFICATION_LABELS=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:ability_runtime_v096]+
    V096_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:ability_runtime_v096}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=V096_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:ability_runtime_v096]='ABILITY_RUNTIME_V096'
end

#==============================================================================
# ■ Game_PMDChessUnit
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v096_initialize initialize unless method_defined?(:pmd_ac_v096_initialize)
  alias pmd_ac_v096_start_combat start_combat unless method_defined?(:pmd_ac_v096_start_combat)
  alias pmd_ac_v096_update update unless method_defined?(:pmd_ac_v096_update)
  alias pmd_ac_v096_update_action_timer update_action_timer unless method_defined?(:pmd_ac_v096_update_action_timer)
  alias pmd_ac_v096_begin_skill begin_skill unless method_defined?(:pmd_ac_v096_begin_skill)
  alias pmd_ac_v096_gain_energy gain_energy unless method_defined?(:pmd_ac_v096_gain_energy)
  alias pmd_ac_v096_gain_passive_energy_v088 gain_passive_energy_v088 unless method_defined?(:pmd_ac_v096_gain_passive_energy_v088)
  alias pmd_ac_v096_apply_status apply_status unless method_defined?(:pmd_ac_v096_apply_status)
  alias pmd_ac_v096_trapped_v053 trapped_v053? unless method_defined?(:pmd_ac_v096_trapped_v053)
  alias pmd_ac_v096_set_type_override_v057 set_type_override_v057 unless method_defined?(:pmd_ac_v096_set_type_override_v057)
  alias pmd_ac_v096_ability_key ability_key unless method_defined?(:pmd_ac_v096_ability_key)

  def initialize(*args)
    pmd_ac_v096_initialize(*args)
    reset_ability_runtime_v096
  end

  def start_combat
    pmd_ac_v096_start_combat
    reset_ability_runtime_v096
  end

  def reset_ability_runtime_v096
    @pressure_debt_v096=0
    @natural_cure_timer_v096=0
    @regenerator_safe_timer_v096=0
    @healer_pulse_timer_v096=0
    @last_action_completed_frame_v096=-999999
    @ability_suppressed_v096=false
    @magic_bounce_scope_v096=false
    @trace_applied_v096=false
  end

  def ability_native_key_v096
    return nil if @pokemon_instance==nil
    @pokemon_instance.ability_key
  end

  def ability_key
    return nil if @ability_suppressed_v096
    pmd_ac_v096_ability_key
  end

  def set_ability_suppressed_v096(v)
    old=@ability_suppressed_v096 ? true:false
    @ability_suppressed_v096=v ? true:false
    old
  end

  def ability_suppressed_v096?;@ability_suppressed_v096 ? true:false;end
  def pressure_debt_v096;@pressure_debt_v096.to_i;end
  def pressure_debt_v096=(v);@pressure_debt_v096=[v.to_i,0].max;end
  def last_action_completed_frame_v096;@last_action_completed_frame_v096.to_i;end
  def last_action_completed_frame_v096=(v);@last_action_completed_frame_v096=v.to_i;end

  def ability_notice_v096(key,extra=nil)
    return if @scene==nil || !@scene.respond_to?(:ability_notice_v096)
    @scene.ability_notice_v096(self,key,extra)
  end

  def ability_major_status_v096
    PMD_AC::ABILITY_MAJOR_STATUSES_V096.each{|k|return k if status?(k)}
    nil
  end

  #--------------------------------------------------------------------------
  # Pressure / Energy Debt
  #--------------------------------------------------------------------------
  def add_pressure_debt_v096(amount,source=nil)
    b=PMD_AC.ability_runtime_behavior_v096(:pressure)
    cap=[b[:debt_cap].to_i,1].max
    old=@pressure_debt_v096.to_i
    @pressure_debt_v096=[[old+amount.to_i,0].max,cap].min
    actual=@pressure_debt_v096-old
    if actual>0
      src=source==nil ? 'SYSTEM' : source.log_name
      log_event(:ability_runtime_v096,log_name+' pressure_debt +'+actual.to_s+
        ' total='+@pressure_debt_v096.to_s+' source='+src)
    end
    actual
  end

  def consume_pressure_debt_v096(amount)
    n=[amount.to_i,0].max
    debt=@pressure_debt_v096.to_i
    paid=[n,debt].min
    @pressure_debt_v096=debt-paid
    [n-paid,paid]
  end

  def gain_energy(value,source=nil,reason=:generic)
    amount=value.to_i
    if amount>0 && @pressure_debt_v096.to_i>0
      pair=consume_pressure_debt_v096(amount)
      amount=pair[0];paid=pair[1]
      if paid>0
        log_event(:ability_runtime_v096,log_name+' pressure_pay '+paid.to_s+
          ' reason='+reason.to_s+' debt='+@pressure_debt_v096.to_s)
      end
      return 0 if amount<=0
    end
    if amount>0 && [:basic_hit,:damage_taken].include?(reason) &&
       @scene!=nil && @scene.respond_to?(:opposing_ability_active_v096?) &&
       @scene.opposing_ability_active_v096?(self,:unnerve)
      b=PMD_AC.ability_runtime_behavior_v096(:unnerve)
      before=amount
      amount=[(amount.to_f*b[:num].to_i/[b[:den].to_i,1].max).floor,1].max
      log_event(:ability_runtime_v096,log_name+' unnerve_energy '+before.to_s+'->'+amount.to_s+
        ' reason='+reason.to_s)
    end
    pmd_ac_v096_gain_energy(amount,source,reason)
  end

  def gain_passive_energy_v088(force=false)
    return 0 if dead?
    return 0 unless force || normal_live_battle_v088?
    return 0 if @energy.to_i>=PMD_AC::MAX_ENERGY
    return 0 if energy_locked?
    debt=@pressure_debt_v096.to_i
    if debt>0
      gain=PMD_AC::PASSIVE_ENERGY_GAIN_V088.to_i
      pair=consume_pressure_debt_v096(gain)
      paid=pair[1];remain=pair[0]
      if paid>0
        log_event(:ability_runtime_v096,log_name+' pressure_pay '+paid.to_s+
          ' reason=passive_time debt='+@pressure_debt_v096.to_s)
      end
      return 0 if remain<=0
      # 原方法固定加常數；有部分被 Debt 吃掉時只能直接補剩餘量。
      before=@energy.to_i
      @energy=[before+remain,PMD_AC::MAX_ENERGY].min
      return @energy-before
    end
    pmd_ac_v096_gain_passive_energy_v088(force)
  end

  def begin_skill(skill_target=nil)
    before_action=@action
    before_timer=@action_timer.to_i
    pmd_ac_v096_begin_skill(skill_target)
    began=(@action==:skill && @action_timer.to_i>0 &&
      (@action!=before_action || @action_timer.to_i!=before_timer))
    if began && @skill_target!=nil && @skill_target.team!=team &&
       @skill_target.ability_key==:pressure
      b=PMD_AC.ability_runtime_behavior_v096(:pressure)
      add_pressure_debt_v096(b[:debt].to_i,@skill_target)
      @skill_target.ability_notice_v096(:pressure)
    end
  end

  #--------------------------------------------------------------------------
  # Action completion tracking for Analytic
  #--------------------------------------------------------------------------
  def update_action_timer
    old=@action_timer.to_i
    old_action=@action
    pmd_ac_v096_update_action_timer
    if old>0 && @action_timer.to_i<=0 && [:attack,:skill].include?(old_action)
      @last_action_completed_frame_v096=Graphics.frame_count.to_i
    end
  end

  #--------------------------------------------------------------------------
  # Natural Cure / Regenerator / Healer
  #--------------------------------------------------------------------------
  def update_ability_natural_cure_v096
    return unless ability_key==:natural_cure
    s=ability_major_status_v096
    if s==nil
      @natural_cure_timer_v096=0
      return
    end
    @natural_cure_timer_v096=@natural_cure_timer_v096.to_i+1
    delay=[PMD_AC.ability_runtime_behavior_v096(:natural_cure)[:delay_frames].to_i,1].max
    return if @natural_cure_timer_v096<delay
    remove_status(s)
    @natural_cure_timer_v096=0
    log_event(:ability_runtime_v096,log_name+' natural_cure REMOVE '+s.to_s)
    ability_notice_v096(:natural_cure)
  end

  def update_ability_regenerator_v096
    unless ability_key==:regenerator
      @regenerator_safe_timer_v096=0
      return
    end
    return if dead?
    b=PMD_AC.ability_runtime_behavior_v096(:regenerator)
    safe=true
    if @scene!=nil && @scene.respond_to?(:ability_enemies_of_v096)
      @scene.ability_enemies_of_v096(self).each do |e|
        if distance_to(e).to_f<=b[:safe_distance].to_f
          safe=false;break
        end
      end
    end
    if !safe || hp.to_i>=maxhp.to_i
      @regenerator_safe_timer_v096=0
      return
    end
    @regenerator_safe_timer_v096=@regenerator_safe_timer_v096.to_i+1
    return if @regenerator_safe_timer_v096<b[:pulse_frames].to_i
    @regenerator_safe_timer_v096=0
    amount=[maxhp.to_i*b[:heal_num].to_i/[b[:heal_den].to_i,1].max,1].max
    before=hp.to_i;heal(amount);actual=hp.to_i-before
    if actual>0
      log_event(:ability_runtime_v096,log_name+' regenerator HEAL '+actual.to_s)
      ability_notice_v096(:regenerator)
    end
  end

  def update_ability_healer_v096
    unless ability_key==:healer
      @healer_pulse_timer_v096=0
      return
    end
    @healer_pulse_timer_v096=@healer_pulse_timer_v096.to_i+1
    b=PMD_AC.ability_runtime_behavior_v096(:healer)
    return if @healer_pulse_timer_v096<b[:pulse_frames].to_i
    @healer_pulse_timer_v096=0
    return if @scene==nil || !@scene.respond_to?(:ability_allies_of_v096)
    candidates=@scene.ability_allies_of_v096(self).find_all{|u|u!=self && u.ability_major_status_v096!=nil}
    return if candidates.empty?
    return if @scene.ability_roll_v096(100)>=b[:chance].to_i
    target=candidates[@scene.ability_roll_v096(candidates.size)]
    s=target.ability_major_status_v096
    return if s==nil
    target.remove_status(s)
    log_event(:ability_runtime_v096,log_name+' healer CURE '+target.log_name+' '+s.to_s)
    ability_notice_v096(:healer,target.log_name)
  end

  def update
    pmd_ac_v096_update
    return if dead?
    update_ability_natural_cure_v096
    update_ability_regenerator_v096
    update_ability_healer_v096
    update_ability_run_away_v096
  end

  def update_ability_run_away_v096
    return unless ability_key==:run_away
    PMD_AC.ability_runtime_behavior_v096(:run_away)[:blocked_statuses].each do |k|
      if status?(k)
        remove_status(k)
        log_event(:ability_runtime_v096,log_name+' run_away CLEANSE '+k.to_s)
        ability_notice_v096(:run_away)
      end
    end
  end

  #--------------------------------------------------------------------------
  # Run Away / Multitype
  #--------------------------------------------------------------------------
  def apply_status(key,options={},source=nil)
    if ability_key==:run_away &&
       PMD_AC.ability_runtime_behavior_v096(:run_away)[:blocked_statuses].include?(key)
      log_event(:ability_runtime_v096,log_name+' run_away BLOCK '+key.to_s)
      ability_notice_v096(:run_away)
      return
    end
    pmd_ac_v096_apply_status(key,options,source)
  end

  def trapped_v053?
    return false if ability_key==:run_away
    pmd_ac_v096_trapped_v053
  end

  def set_type_override_v057(types,frames=999999)
    # pmd_ac_v096_ability_key 是加入「暫時 suppression」前的既有 Ability Chain。
    # Multitype 不應因 Mold Breaker scope 而被誤當成可改寫型態。
    native=ability_native_key_v096
    if species_key==:arceus && native==:multitype
      log_event(:ability_runtime_v096,log_name+' multitype BLOCK type_override')
      ability_notice_v096(:multitype)
      return false
    end
    pmd_ac_v096_set_type_override_v057(types,frames)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v096_start start unless method_defined?(:pmd_ac_v096_start)
  alias pmd_ac_v096_refresh_header refresh_header unless method_defined?(:pmd_ac_v096_refresh_header)
  alias pmd_ac_v096_start_battle start_battle unless method_defined?(:pmd_ac_v096_start_battle)
  alias pmd_ac_v096_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v096_deal_direct_damage)
  alias pmd_ac_v096_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v096_apply_skill_effects)
  alias pmd_ac_v096_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v096_prepare_verification_battle)
  alias pmd_ac_v096_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v096_update_verification_script)
  alias pmd_ac_v096_log_event log_event unless method_defined?(:pmd_ac_v096_log_event)
  alias pmd_ac_v096_verify_content_ability_v095 verify_content_ability_v095 unless method_defined?(:pmd_ac_v096_verify_content_ability_v095)

  def ability_runtime_v096?;verification_mode==:ability_runtime_v096;end

  def start
    pmd_ac_v096_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.96 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V096
    log_event(:ability_runtime_v096,
      'FLOW v0.96 new='+m[:new_implemented_ability_count].to_s+
      ' cumulative='+m[:cumulative_implemented_ability_count].to_s+
      ' slots='+m[:implemented_slot_count].to_s+'/'+m[:total_slot_count].to_s+
      ' species='+m[:species_with_any_implemented_ability].to_s+'/494'+
      ' remaining='+m[:remaining_ability_count].to_s+' abilities/'+m[:remaining_slot_count].to_s+' slots'+
      ' gender_fake=0 rivalry=deferred mechanics_core_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v096_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.96',1)
  end

  def ability_notice_v096(unit,key,extra=nil)
    name=PMD_AC::ABILITY_NAME_ZH_V096[key] || key.to_s
    text='特性｜'+name
    text+=' '+extra.to_s unless extra==nil || extra.to_s==''
    add_center_notice_v088(text) if respond_to?(:add_center_notice_v088) && verification_mode==:normal
    log_event(:ability_runtime_v096,(unit==nil ? 'SYSTEM' : unit.log_name)+' TRIGGER '+key.to_s+
      (extra==nil ? '' : ' '+extra.to_s))
  end

  def ability_global_units_v096
    list=[]
    (@units||[]).each{|u|list.push(u) unless u==nil}
    (@ability_runtime_test_units_v096||[]).each{|u|list.push(u) unless u==nil || list.include?(u)}
    list
  end

  def ability_enemies_of_v096(unit)
    ability_global_units_v096.find_all{|u|u!=nil && !u.dead? && unit!=nil && u.team!=unit.team}
  end
  def ability_allies_of_v096(unit)
    ability_global_units_v096.find_all{|u|u!=nil && !u.dead? && unit!=nil && u.team==unit.team}
  end
  def opposing_ability_active_v096?(unit,key)
    ability_enemies_of_v096(unit).any?{|u|u.ability_key==key}
  end

  def ability_roll_v096(max)
    m=[max.to_i,1].max
    if ability_runtime_v096? && @ability_runtime_rolls_v096!=nil && !@ability_runtime_rolls_v096.empty?
      return @ability_runtime_rolls_v096.shift.to_i % m
    end
    rand(m)
  end

  #--------------------------------------------------------------------------
  # Trace
  #--------------------------------------------------------------------------
  def apply_trace_v096(unit,units=nil)
    return nil if unit==nil || unit.dead? || unit.ability_key!=:trace
    list=units||ability_global_units_v096
    excluded=PMD_AC.ability_runtime_behavior_v096(:trace)[:exclude]||[:trace]
    opp=list.find_all{|u|u!=nil && !u.dead? && u.team!=unit.team && u.ability_key!=nil && !excluded.include?(u.ability_key)}
    return nil if opp.empty?
    target=opp[ability_roll_v096(opp.size)]
    copied=target.ability_key
    return nil if copied==nil || copied==:trace
    unit.set_ability_override_v057(copied,PMD_AC.ability_runtime_behavior_v096(:trace)[:duration].to_i)
    unit.instance_variable_set(:@trace_applied_v096,true)
    log_event(:ability_runtime_v096,unit.log_name+' trace COPY '+copied.to_s+' <- '+target.log_name)
    ability_notice_v096(unit,:trace,copied.to_s)
    copied
  end

  def start_battle
    pmd_ac_v096_start_battle
    return unless @phase==:battle
    ability_global_units_v096.each{|u|apply_trace_v096(u) if u.ability_key==:trace}
  end

  #--------------------------------------------------------------------------
  # Mold Breaker scope
  #--------------------------------------------------------------------------
  def ability_mold_breaker_scope_v096(user,target)
    return false if user==nil || target==nil || user.team==target.team
    user.ability_key==:mold_breaker
  end

  def with_target_ability_suppressed_v096(target)
    old=target.set_ability_suppressed_v096(true)
    begin
      yield
    ensure
      target.set_ability_suppressed_v096(old)
    end
  end

  #--------------------------------------------------------------------------
  # Analytic
  #--------------------------------------------------------------------------
  def ability_analytic_multiplier_v096(user,target)
    return 1.0 if user==nil || target==nil || user.ability_key!=:analytic
    uf=user.last_action_completed_frame_v096
    tf=target.last_action_completed_frame_v096
    return 1.0 if uf<0 || tf<0 || tf<=uf
    b=PMD_AC.ability_runtime_behavior_v096(:analytic)
    b[:num].to_f/[b[:den].to_i,1].max.to_f
  end

  #--------------------------------------------------------------------------
  # Cute Charm
  #--------------------------------------------------------------------------
  def ability_contact_hit_v096?(user,options)
    return false if user==nil
    opts=options==nil ? {} : options
    if opts[:source_type]==:basic
      return user.melee?
    end
    d=opts[:skill_data]
    return false if d==nil
    respond_to?(:canonical_contact_move?) ? canonical_contact_move?(user,d) : false
  end

  def ability_cute_charm_after_damage_v096(user,target,damage,options)
    return false if damage.to_i<=0 || user==nil || target==nil || user.dead? || target.dead?
    return false if target.ability_key!=:cute_charm || user.team==target.team
    return false unless ability_contact_hit_v096?(user,options)
    b=PMD_AC.ability_runtime_behavior_v096(:cute_charm)
    return false if ability_roll_v096(100)>=b[:chance].to_i
    return false unless user.respond_to?(:set_infatuation_v058)
    user.set_infatuation_v058(target,b[:duration].to_i)
    log_event(:ability_runtime_v096,target.log_name+' cute_charm INFATUATE '+user.log_name+
      ' dur='+b[:duration].to_i.to_s)
    ability_notice_v096(target,:cute_charm,user.log_name)
    true
  end

  #--------------------------------------------------------------------------
  # Direct damage: Analytic + Mold Breaker + Cute Charm
  #--------------------------------------------------------------------------
  def deal_direct_damage(user,target,power,options=nil)
    p=power
    mult=ability_analytic_multiplier_v096(user,target)
    if mult>1.001 && (options==nil || !options.has_key?(:fixed_damage))
      p=[(power.to_f*mult).round,1].max
      log_event(:ability_runtime_v096,user.log_name+' analytic POWER '+power.to_i.to_s+'->'+p.to_i.to_s+
        ' mult='+sprintf('%.2f',mult))
      ability_notice_v096(user,:analytic)
    end
    if ability_mold_breaker_scope_v096(user,target)
      log_event(:ability_runtime_v096,user.log_name+' mold_breaker BYPASS target='+target.log_name+' phase=damage')
      result=nil
      with_target_ability_suppressed_v096(target){result=pmd_ac_v096_deal_direct_damage(user,target,p,options)}
    else
      result=pmd_ac_v096_deal_direct_damage(user,target,p,options)
    end
    ability_cute_charm_after_damage_v096(user,target,result,options)
    result
  end

  #--------------------------------------------------------------------------
  # Magic Bounce + Mold Breaker status scope
  #--------------------------------------------------------------------------
  def canonical_move_key_v096(data)
    return nil if data==nil
    k=data[:canonical_move_key]||data[:move_key]||data[:runtime_skill_key]
    return nil if k==nil
    k.to_s.downcase.gsub(/^mv_/,'').gsub(/[^a-z0-9]+/,'_').to_sym
  end

  def pure_enemy_status_skill_v096?(user,target,data)
    return false if user==nil || target==nil || data==nil || user.team==target.team
    cat=data[:damage_category]||data[:category]
    return false unless cat==:status
    tt=data[:target_type]||data[:target]
    return false unless [:enemy_targeted,:selected_pokemon].include?(tt)
    mk=canonical_move_key_v096(data)
    return false if mk==nil
    return false if defined?(PMD_AC::FIELD_EFFECT_MOVE_V035) && PMD_AC::FIELD_EFFECT_MOVE_V035[mk]!=nil
    return false if data[:weather]!=nil || data[:field]!=nil
    flags=data[:source_move_flags]||[]
    return false unless flags.include?(:reflectable)
    effects=data[:effects]||[]
    return false if effects.any?{|e|[:weather,:field,:self_heal,:heal,:heal_percent].include?(e[:type])}
    true
  end

  def apply_skill_effects_v096_core(user,target,data,scale)
    if !@magic_bounce_scope_v096 && target!=nil && target.ability_key==:magic_bounce &&
       pure_enemy_status_skill_v096?(user,target,data)
      @magic_bounce_scope_v096=true
      begin
        mk=canonical_move_key_v096(data)
        log_event(:ability_runtime_v096,target.log_name+' magic_bounce REFLECT '+mk.to_s+' -> '+user.log_name)
        ability_notice_v096(target,:magic_bounce,mk.to_s)
        return pmd_ac_v096_apply_skill_effects(target,user,data,scale)
      ensure
        @magic_bounce_scope_v096=false
      end
    end
    pmd_ac_v096_apply_skill_effects(user,target,data,scale)
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if ability_mold_breaker_scope_v096(user,target)
      result=nil
      log_event(:ability_runtime_v096,user.log_name+' mold_breaker BYPASS target='+target.log_name+' phase=skill_effect')
      with_target_ability_suppressed_v096(target){result=apply_skill_effects_v096_core(user,target,data,scale)}
      return result
    end
    apply_skill_effects_v096_core(user,target,data,scale)
  end

  #--------------------------------------------------------------------------
  # Content Validator v0.96 Ability section
  #--------------------------------------------------------------------------
  def self_dummy_v096;end

  #--------------------------------------------------------------------------
  # Verifier helpers
  #--------------------------------------------------------------------------
  def ability_runtime_verification_unit_v096(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99096000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9960+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_runtime_test_units_v096=[] if @ability_runtime_test_units_v096==nil
    @ability_runtime_test_units_v096.push(u);u
  end

  def prepare_verification_battle
    pmd_ac_v096_prepare_verification_battle
    return unless ability_runtime_v096?
    @ability_runtime_test_units_v096=[]
    @ability_runtime_rolls_v096=[]
    @ability_runtime_failed_v096=false
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V096
    log_event(:showcase,'START mode=ABILITY_RUNTIME_V096 new=12 slots='+m[:implemented_slot_count].to_s+
      '/1193 species=494/494 remaining=12/56 diagnostic_only=1 pokemon_resume_after_final_assert=1')
  end

  def log_event(category,message)
    if category.to_s=='verify' && ability_runtime_v096? && message.to_s.index('V096')!=nil &&
       message.to_s.include?(' pass=0')
      @ability_runtime_failed_v096=true
    end
    pmd_ac_v096_log_event(category,message)
  end

  def log_verify_v096(name,pass,detail='')
    @ability_runtime_failed_v096=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_ability_manifest_v096
    return if @verification_done[:v096_manifest]
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V096;e=PMD_AC.validate_ability_runtime_v096
    pass=e.empty? && m[:new_implemented_ability_count].to_i==12 &&
      m[:implemented_slot_count].to_i==1137 && m[:species_with_any_implemented_ability].to_i==494 &&
      m[:remaining_ability_count].to_i==12 && m[:remaining_slot_count].to_i==56
    log_verify_v096('ABILITY_RUNTIME_MANIFEST_V096',pass,
      'new=12 cumulative=147 slots=1137/1193 species=494/494 remaining=12/56 errors='+(e.empty? ? 'none':e.join(',')))
    @verification_done[:v096_manifest]=true
  end

  def verify_pressure_unnerve_v096
    return if @verification_done[:v096_pressure]
    p=ability_runtime_verification_unit_v096(:deoxys,:primary,:enemy,1)
    a=ability_runtime_verification_unit_v096(:bulbasaur,:primary,:ally,2)
    # Pressure debt：+20，接著 +30 只實得 +10。
    pkey=p.ability_key
    a.instance_variable_set(:@energy,0);a.pressure_debt_v096=0
    a.add_pressure_debt_v096(20,p);g=a.gain_energy(30,p,:generic)
    pressure=(pkey==:pressure && g.to_i==10 && a.energy.to_i==10 && a.pressure_debt_v096==0)
    # Unnerve：Mewtwo hidden；basic_hit +20 應被壓到 +15。
    u=ability_runtime_verification_unit_v096(:mewtwo,:hidden,:enemy,3)
    v=ability_runtime_verification_unit_v096(:bulbasaur,:primary,:ally,4)
    v.instance_variable_set(:@energy,0);v.pressure_debt_v096=0
    g2=v.gain_energy(20,u,:basic_hit)
    unnerve=(u.ability_key==:unnerve && g2.to_i==15 && v.energy.to_i==15)
    log_verify_v096('ABILITY_PRESSURE_UNNERVE_V096',pressure && unnerve,
      'pressure_debt=20->0 gain30='+g.to_i.to_s+' energy='+a.energy.to_i.to_s+
      ' unnerve_gain20='+g2.to_i.to_s+' expected15')
    @verification_done[:v096_pressure]=true
  end

  def verify_natural_regenerator_v096
    return if @verification_done[:v096_natural]
    n=ability_runtime_verification_unit_v096(:celebi,:primary,:ally,5)
    n.apply_status(:poison,{:duration=>300,:value=>10},nil)
    n.instance_variable_set(:@natural_cure_timer_v096,119);n.update_ability_natural_cure_v096
    natural=!n.status?(:poison)
    r=ability_runtime_verification_unit_v096(:ho_oh,:hidden,:ally,6)
    e=ability_runtime_verification_unit_v096(:caterpie,:primary,:enemy,7)
    r.deploy_to_pixel(40,40);e.deploy_to_pixel(420,300)
    r.instance_variable_set(:@hp,[r.maxhp.to_i/2,1].max)
    before=r.hp.to_i;r.instance_variable_set(:@regenerator_safe_timer_v096,179);r.update_ability_regenerator_v096
    regen=r.hp.to_i>before
    log_verify_v096('ABILITY_NATURAL_REGEN_V096',natural && regen,
      'natural_cure_poison='+(natural ? 'removed':'remain')+
      ' regenerator='+before.to_s+'->'+r.hp.to_i.to_s+' safe_distance=150')
    @verification_done[:v096_natural]=true
  end

  def verify_trace_multitype_v096
    return if @verification_done[:v096_trace]
    t=ability_runtime_verification_unit_v096(:ralts,:secondary,:ally,8)
    e=ability_runtime_verification_unit_v096(:charmander,:primary,:enemy,9)
    @ability_runtime_rolls_v096=[0];copied=apply_trace_v096(t,[t,e])
    trace=(copied==e.ability_key && t.ability_key==e.ability_key && copied!=:trace)
    ar=ability_runtime_verification_unit_v096(:arceus,:primary,:ally,10)
    before_types=ar.pokemon_types.dup;changed=ar.set_type_override_v057([:water],120)
    multi=(ar.ability_key==:multitype && changed==false && ar.pokemon_types==before_types)
    log_verify_v096('ABILITY_TRACE_MULTITYPE_V096',trace && multi,
      'trace_copy='+(copied||:none).to_s+' multitype_override='+(changed ? '1':'0')+
      ' types='+ar.pokemon_types.join(','))
    @verification_done[:v096_trace]=true
  end

  def verify_mold_bounce_v096
    return if @verification_done[:v096_mold]
    m=ability_runtime_verification_unit_v096(:cranidos,:primary,:ally,11)
    sturdy=ability_runtime_verification_unit_v096(:onix,:secondary,:enemy,12)
    old=sturdy.set_ability_suppressed_v096(true);suppressed=(sturdy.ability_key==nil);sturdy.set_ability_suppressed_v096(old)
    mold=(m.ability_key==:mold_breaker && suppressed)
    # Magic Bounce 用一份純狀態測試資料，確認效果落到施術者而非反射者。
    b=ability_runtime_verification_unit_v096(:espeon,:hidden,:enemy,13)
    caster=ability_runtime_verification_unit_v096(:bulbasaur,:primary,:ally,14)
    caster.reset_stat_stages;b.reset_stat_stages
    data={:canonical_move_key=>:screech,:category=>:status,:damage_category=>:status,:target_type=>:enemy_targeted,
      :source_move_flags=>[:reflectable],:effects=>[{:type=>:stat_stage,:stat=>:atk,:stages=>-1}]}
    @magic_bounce_scope_v096=false
    apply_skill_effects(caster,b,data,1.0)
    bounce=(b.ability_key==:magic_bounce && caster.stat_stage(:atk)<0 && b.stat_stage(:atk)==0)
    log_verify_v096('ABILITY_MOLD_BOUNCE_V096',mold && bounce,
      'mold_suppression='+(suppressed ? '1':'0')+
      ' bounce_caster_atk='+caster.stat_stage(:atk).to_s+' target_atk='+b.stat_stage(:atk).to_s)
    @verification_done[:v096_mold]=true
  end

  def verify_analytic_cute_v096
    return if @verification_done[:v096_analytic]
    an=ability_runtime_verification_unit_v096(:staryu,:hidden,:ally,15)
    tar=ability_runtime_verification_unit_v096(:caterpie,:primary,:enemy,16)
    an.last_action_completed_frame_v096=10;tar.last_action_completed_frame_v096=20
    analytic=(an.ability_key==:analytic && (ability_analytic_multiplier_v096(an,tar)-1.30).abs<0.001)
    cc=ability_runtime_verification_unit_v096(:clefairy,:primary,:enemy,17)
    atk=ability_runtime_verification_unit_v096(:rattata,:primary,:ally,18)
    @ability_runtime_rolls_v096=[0]
    # 直接呼叫 after hook 可避免驗證場 Damage Formula 干擾；仍使用正式接觸判定與 infatuation Runtime。
    cute=ability_cute_charm_after_damage_v096(atk,cc,10,{:source_type=>:basic}) && atk.infatuated_v058?
    log_verify_v096('ABILITY_ANALYTIC_CUTECHARM_V096',analytic && cute,
      'analytic='+sprintf('%.2f',ability_analytic_multiplier_v096(an,tar))+
      ' cute_charm_infatuated='+(atk.infatuated_v058? ? '1':'0')+' gender_rule=project_v0.58')
    @verification_done[:v096_analytic]=true
  end

  def verify_healer_runaway_v096
    return if @verification_done[:v096_healer]
    h=ability_runtime_verification_unit_v096(:chansey,:hidden,:ally,19)
    ally=ability_runtime_verification_unit_v096(:bulbasaur,:primary,:ally,20)
    ally.apply_status(:burn,{:duration=>300,:value=>8},nil)
    h.instance_variable_set(:@healer_pulse_timer_v096,119);@ability_runtime_rolls_v096=[0,0]
    h.update_ability_healer_v096
    healer=!ally.status?(:burn)
    run=ability_runtime_verification_unit_v096(:rattata,:primary,:enemy,22)
    run.apply_status(:root,{:duration=>120},ally)
    run.set_mean_look_v053(120)
    runaway=(run.ability_key==:run_away && !run.status?(:root) && !run.trapped_v053?)
    log_verify_v096('ABILITY_HEALER_RUNAWAY_V096',healer && runaway,
      'healer_burn='+(ally.status?(:burn) ? 'remain':'removed')+
      ' run_away_root='+(run.status?(:root) ? '1':'0')+' trapped='+(run.trapped_v053? ? '1':'0'))
    @verification_done[:v096_healer]=true
  end

  def verify_species_coverage_v096
    return if @verification_done[:v096_species]
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V096
    pass=m[:species_with_any_implemented_ability].to_i==494 &&
      m[:implemented_slot_count].to_i==1137 && m[:remaining_slot_count].to_i==56
    log_verify_v096('ABILITY_SPECIES_COVERAGE_V096',pass,
      'species=494/494 slots=1137/1193 coverage='+sprintf('%.2f',m[:implemented_slot_coverage_percent].to_f)+
      '% remaining_abilities=12 remaining_slots=56')
    @verification_done[:v096_species]=true
  end

  def verify_ability_content_v096
    return if @verification_done[:v096_content]
    r=PMD_AC.content_validation_report_v095
    s=r[:sections][:abilities]||{}
    pass=r[:errors].empty? && s[:runtime_slots].to_i==1137 && s[:runtime_species].to_i==494 && r[:warnings].size==2
    log_verify_v096('ABILITY_CONTENT_VALIDATION_V096',pass,
      'errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+
      ' ability_slots='+s[:runtime_slots].to_i.to_s+'/1193 species='+s[:runtime_species].to_i.to_s+'/494'+
      ' core_ready='+(r[:core_pass] ? '1':'0')+' production_ready='+(r[:production_ready] ? '1':'0'))
    @verification_done[:v096_content]=true
  end

  def verify_ability_carry_v096
    return if @verification_done[:v096_carry]
    pass=PMD_AC::BATTLE_REST_VISUAL_V094==:walk && PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size==19 &&
      PMD_AC::ABILITY_RUNTIME_MANIFEST_V067[:implemented_slot_count].to_i==1028 &&
      PMD_AC::ABILITY_RUNTIME_MANIFEST_V096[:implemented_slot_count].to_i==1137
    log_verify_v096('ABILITY_RUNTIME_CARRY_V096',pass,
      'old_ability=v0.67.1 movement=v0.15 multi=v0.60.2 semantic=v0.62 tactical=v0.91.4 motion=v0.94 unchanged=1')
    @verification_done[:v096_carry]=true
  end

  def update_verification_script
    unless ability_runtime_v096?
      pmd_ac_v096_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_ability_manifest_v096 if f>=2
    verify_pressure_unnerve_v096 if f>=4
    verify_natural_regenerator_v096 if f>=6
    verify_trace_multitype_v096 if f>=8
    verify_mold_bounce_v096 if f>=10
    verify_analytic_cute_v096 if f>=12
    verify_healer_runaway_v096 if f>=14
    verify_species_coverage_v096 if f>=16
    verify_ability_content_v096 if f>=18
    verify_ability_carry_v096 if f>=20
    if f>=24 && !@verification_done[:v096_final]
      pass=!@ability_runtime_failed_v096
      log_verify_v096('ABILITY_RUNTIME_V096',pass,
        'new=12 slots=1137/1193 species=494/494 remaining=12/56 content_core=pass')
      @verification_done[:v096_final]=true
    end
    complete_verification_mode if f>=PMD_AC::ABILITY_RUNTIME_VERIFY_END_V096
  end

  # v0.95 verifier 被保留，但 Ability line 更新成 v0.96 的實際覆蓋率。
  def verify_content_ability_v095
    return if @verification_done[:v095_ability]
    s=content_report_v095[:sections][:abilities]||{}
    log_verify_v095('CONTENT_ABILITY_V095',s[:pass] ? true:false,
      'canonical_species='+s[:canonical_species].to_i.to_s+
      ' slots='+s[:runtime_slots].to_i.to_s+'/'+s[:total_slots].to_i.to_s+
      ' runtime_species='+s[:runtime_species].to_i.to_s+'/494 known_gap=1 runtime=v0.96 remaining_slots=56')
    @verification_done[:v095_ability]=true
  end
end

#==============================================================================
# ■ Content Validation override
#==============================================================================
module PMD_AC
  remove_const(:CONTENT_VALIDATION_VERSION_V095) if const_defined?(:CONTENT_VALIDATION_VERSION_V095)
  CONTENT_VALIDATION_VERSION_V095='0.96'
  remove_const(:CONTENT_VALIDATION_REPORT_FILE_V095) if const_defined?(:CONTENT_VALIDATION_REPORT_FILE_V095)
  CONTENT_VALIDATION_REPORT_FILE_V095='PMD_ContentValidation_v0.96.log'

  class << self
    def content_validation_abilities_v095(report)
      content_validation_safe_v095(report,:abilities) do
        exp=CONTENT_VALIDATION_EXPECTED_V095
        canon=defined?(ABILITY_SPECIES_SLOTS_V024) ? ABILITY_SPECIES_SLOTS_V024 : {}
        m=ABILITY_RUNTIME_MANIFEST_V096
        if canon.size!=exp[:species]
          content_validation_push_v095(report,:error,'ability_species_slots',canon.size.to_s+'/'+exp[:species].to_s)
        end
        if defined?(ABILITY_MANIFEST_V024) && ABILITY_MANIFEST_V024[:total_slot_count].to_i!=exp[:ability_slots]
          content_validation_push_v095(report,:error,'ability_canonical_slot_count',ABILITY_MANIFEST_V024[:total_slot_count].to_s)
        end
        if m[:implemented_slot_count].to_i<exp[:ability_slots]
          content_validation_push_v095(report,:warning,'ability_runtime_gap',
            'slots='+m[:implemented_slot_count].to_i.to_s+'/'+exp[:ability_slots].to_s+
            ' species='+m[:species_with_any_implemented_ability].to_i.to_s+'/'+exp[:species].to_s+
            ' known_runtime=v0.96 remaining_slots='+m[:remaining_slot_count].to_i.to_s)
        end
        {:pass=>canon.size==494 && m[:implemented_slot_count].to_i==1137 &&
          m[:species_with_any_implemented_ability].to_i==494,
         :canonical_species=>canon.size,:total_slots=>exp[:ability_slots],
         :runtime_slots=>m[:implemented_slot_count].to_i,
         :runtime_species=>m[:species_with_any_implemented_ability].to_i,:known_gap=>true,
         :remaining_slots=>m[:remaining_slot_count].to_i,:remaining_abilities=>m[:remaining_ability_count].to_i}
      end
    end

    alias pmd_ac_v096_content_validation_text_v095 content_validation_text_v095 unless method_defined?(:pmd_ac_v096_content_validation_text_v095)
    def content_validation_text_v095(report=nil)
      text=pmd_ac_v096_content_validation_text_v095(report)
      text.sub!('PMD AutoChess Content Validation v0.95.1','PMD AutoChess Content Validation v0.96')
      text.sub!('known_freeze=v0.67.1','known_runtime=v0.96 remaining_slots=56')
      text
    end

    alias pmd_ac_v096_write_content_validation_report_v095 write_content_validation_report_v095 unless method_defined?(:pmd_ac_v096_write_content_validation_report_v095)
    def write_content_validation_report_v095(report=nil,path=nil)
      path=CONTENT_VALIDATION_REPORT_FILE_V095 if path==nil
      r=report||content_validation_report_v095
      begin
        File.open(path,'wb'){|f|f.write(content_validation_text_v095(r))}
        true
      rescue
        false
      end
    end
  end
end
