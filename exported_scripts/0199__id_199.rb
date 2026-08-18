#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.48
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MASTERY_POLICY_END_FRAME_V048 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - mastery_policy_checksum32_v048 / mastery_index_v048 / mastery_magnitude_v048 / mastery_drain_ratio_mult_v048
# - mastery_secondary_bonus_v048 / mastery_status_accuracy_bonus_v048 / mastery_status_energy_refund_v048 / mastery_reactive_energy_refund_v048
# - mastery_field_turn_bonus_v048 / mastery_weather_turn_bonus_v048 / mastery_guard_frame_bonus_v048 / mastery_tactical_frame_bonus_v048
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.48
#    Skill Mastery Policy II
#-------------------------------------------------------------------------------
# Additive layer on verified v0.47.
# - Damage / healing / shield / HoT / max-HP recovery receive Lv1-5 magnitude.
# - Drain receives normal damage growth plus a deliberately smaller ratio bonus.
# - Secondary proc chance receives a small percentage-point bonus.
# - Status moves gain accuracy + a bounded post-cast energy refund instead of
#   increasing hard-control duration or stat-stage size.
# - Field / Weather, Guard and Tactical Support receive bounded duration growth.
# - Priority tier, two-turn phase timing, Helping Hand x1.50 and Counter/Mirror
#   Coat return ratios stay mechanically fixed.
# - Progression UI now shows the current mastery-policy benefit per active move.
#===============================================================================
module PMD_AC
  VERIFICATION_MASTERY_POLICY_END_FRAME_V048 = 860

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:mastery_policy,:progression_ui,:progression_runtime,
                        :identity_bridge,:tactical_support]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :mastery_policy=>'MASTERY_POLICY', :progression_ui=>'PROGRESSION_UI',
    :progression_runtime=>'PROGRESSION_RUNTIME', :identity_bridge=>'IDENTITY_BRIDGE',
    :tactical_support=>'TACTICAL_SUPPORT'
  }

  class << self
    def mastery_policy_checksum32_v048
      h=0
      MASTERY_POLICY_CHECKSUM_TEXT_V048.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      h
    end

    def mastery_index_v048(level)
      clamp(level.to_i,1,5)-1
    end

    def mastery_magnitude_v048(level)
      MASTERY_MAGNITUDE_MULT_V048[mastery_index_v048(level)].to_f
    end
    def mastery_drain_ratio_mult_v048(level)
      MASTERY_DRAIN_RATIO_MULT_V048[mastery_index_v048(level)].to_f
    end
    def mastery_secondary_bonus_v048(level)
      MASTERY_SECONDARY_CHANCE_V048[mastery_index_v048(level)].to_i
    end
    def mastery_status_accuracy_bonus_v048(level)
      MASTERY_STATUS_ACCURACY_V048[mastery_index_v048(level)].to_f
    end
    def mastery_status_energy_refund_v048(level)
      MASTERY_STATUS_ENERGY_REFUND_V048[mastery_index_v048(level)].to_i
    end
    def mastery_reactive_energy_refund_v048(level)
      MASTERY_REACTIVE_ENERGY_REFUND_V048[mastery_index_v048(level)].to_i
    end
    def mastery_field_turn_bonus_v048(level)
      MASTERY_FIELD_TURN_BONUS_V048[mastery_index_v048(level)].to_i
    end
    def mastery_weather_turn_bonus_v048(level)
      MASTERY_WEATHER_TURN_BONUS_V048[mastery_index_v048(level)].to_i
    end
    def mastery_guard_frame_bonus_v048(level)
      MASTERY_GUARD_FRAME_BONUS_V048[mastery_index_v048(level)].to_i
    end
    def mastery_tactical_frame_bonus_v048(level)
      MASTERY_TACTICAL_FRAME_BONUS_V048[mastery_index_v048(level)].to_i
    end

    def mastery_move_key_v048(data)
      return nil if data==nil
      k=data[:canonical_move_key] || data[:move_key]
      k=k.to_sym if k.is_a?(String)
      k
    end

    def mastery_effect_hash_v048(effect)
      return {} if effect==nil
      h={}
      effect.each do |k,v|
        nk=k.is_a?(String) ? k.to_sym : k
        h[nk]=v
      end
      h
    end

    def mastery_effect_type_v048(effect)
      return nil if effect==nil
      t=effect[:type]
      t=effect['type'] if t==nil && effect.respond_to?(:[])
      t=t.to_sym if t.is_a?(String)
      t
    end

    def mastery_move_category_v048(data)
      return :unknown if data==nil || data.empty?
      mk=mastery_move_key_v048(data)
      effects=data[:effects] || []
      secondary=data[:secondary_effects] || []
      return :guard if data[:guard_kind]!=nil
      return :tactical if [:follow_me,:rage_powder,:helping_hand,:ally_switch].include?(mk)
      return :field if effects.any?{|e|mastery_effect_type_v048(e)==:field_effect}
      return :weather if effects.any?{|e|mastery_effect_type_v048(e)==:set_weather}
      return :two_turn if data[:two_turn]
      return :reactive if [:counter,:mirror_coat].include?(mk)
      has_damage=effects.any?{|e|mastery_effect_type_v048(e)==:damage}
      has_drain=effects.any?{|e|mastery_effect_type_v048(e)==:drain}
      has_heal=effects.any?{|e|[:heal,:heal_maxhp_ratio,:hot].include?(mastery_effect_type_v048(e))}
      has_shield=effects.any?{|e|mastery_effect_type_v048(e)==:shield}
      has_secondary=!secondary.empty?
      cat=data[:category] || data[:damage_category]
      cat=cat.to_sym if cat.is_a?(String)
      return :drain if has_drain
      return :damage_status if has_damage && has_secondary
      return :damage if has_damage
      return :heal if has_heal
      return :shield if has_shield
      return :status if cat==:status || effects.any?{|e|[:stat_stage,:canonical_sleep,:canonical_confusion,:canonical_paralysis,:control,:status].include?(mastery_effect_type_v048(e))}
      :utility
    end

    def mastery_scale_channel_v048?(data)
      return false if data==nil
      (data[:effects]||[]).any?{|e|[:damage,:heal_maxhp_ratio].include?(mastery_effect_type_v048(e))}
    end

    def mastery_status_move_v048?(data)
      return false if data==nil
      cat=data[:category] || data[:damage_category]
      cat=cat.to_sym if cat.is_a?(String)
      cat==:status
    end

    def mastery_transform_data_v048(data,level)
      return data if data==nil
      lv=clamp(level.to_i,1,5)
      mag=mastery_magnitude_v048(lv)
      drain_mult=mastery_drain_ratio_mult_v048(lv)
      sec_bonus=mastery_secondary_bonus_v048(lv)
      field_bonus=mastery_field_turn_bonus_v048(lv)
      weather_bonus=mastery_weather_turn_bonus_v048(lv)
      tactical_bonus=mastery_tactical_frame_bonus_v048(lv)
      d=data.dup
      d[:effects]=(data[:effects]||[]).collect do |e|
        x=mastery_effect_hash_v048(e);t=mastery_effect_type_v048(x)
        if [:heal,:shield].include?(t)
          x[:flat]=(x[:flat].to_f*mag).round if x[:flat]!=nil
          x[:power]=(x[:power].to_f*mag).round if x[:power]!=nil
        elsif t==:hot
          x[:value]=(x[:value].to_f*mag).round if x[:value]!=nil
        elsif t==:drain
          x[:ratio]=((x[:ratio]||0.5).to_f*drain_mult)
        elsif t==:field_effect && x[:turns]!=nil
          x[:turns]=[x[:turns].to_i+field_bonus,1].max
        elsif t==:set_weather && x[:turns]!=nil
          x[:turns]=[x[:turns].to_i+weather_bonus,1].max
        end
        x
      end
      d[:secondary_effects]=(data[:secondary_effects]||[]).collect do |e|
        x=mastery_effect_hash_v048(e)
        if x[:chance]!=nil
          x[:chance]=clamp(x[:chance].to_i+sec_bonus,0,100)
        end
        x
      end
      if d[:secondary_paralysis_chance]!=nil
        d[:secondary_paralysis_chance]=clamp(d[:secondary_paralysis_chance].to_i+sec_bonus,0,100)
      end
      mk=mastery_move_key_v048(d)
      if [:follow_me,:rage_powder,:helping_hand].include?(mk) && d[:duration_frames]!=nil
        d[:duration_frames]=[d[:duration_frames].to_i+tactical_bonus,1].max
      end
      d
    end

    def mastery_policy_short_v048(move,level)
      lv=clamp(level.to_i,1,5);key=canonical_runtime_skill_key(move)
      data=skill_data(key);cat=mastery_move_category_v048(data)
      pct=((mastery_magnitude_v048(lv)-1.0)*100.0).round
      sec=mastery_secondary_bonus_v048(lv)
      energy=mastery_status_energy_refund_v048(lv)
      case cat
      when :drain
        drain=((mastery_drain_ratio_mult_v048(lv)-1.0)*100.0).round
        return '傷+'+pct.to_s+'% 吸+'+drain.to_s+'%'
      when :damage_status
        return '傷+'+pct.to_s+'% 副效+'+sec.to_s+'%'
      when :damage
        return '傷害 +'+pct.to_s+'%'
      when :heal
        return '回復 +'+pct.to_s+'%'
      when :shield
        return '護盾 +'+pct.to_s+'%'
      when :field
        return '場地 +'+mastery_field_turn_bonus_v048(lv).to_s+'T 能+'+energy.to_s
      when :weather
        return '天氣 +'+mastery_weather_turn_bonus_v048(lv).to_s+'T 能+'+energy.to_s
      when :guard
        return '防守 +'+mastery_guard_frame_bonus_v048(lv).to_s+'f 能+'+energy.to_s
      when :tactical
        return '支援 +'+mastery_tactical_frame_bonus_v048(lv).to_s+'f 能+'+energy.to_s
      when :two_turn
        return '兩段 傷+'+pct.to_s+'%'
      when :reactive
        return '反應 能+'+mastery_reactive_energy_refund_v048(lv).to_s+' 倍率固定'
      when :status
        return '狀態 命+'+mastery_status_accuracy_bonus_v048(lv).round.to_s+' 能+'+energy.to_s
      else
        return '安全制 Lv'+lv.to_s
      end
    end
  end
end

class PMD_PokemonInstance
  def move_mastery_policy_profile_v048(move)
    lv=move_level_v045(move)
    data=PMD_AC.skill_data(PMD_AC.canonical_runtime_skill_key(move))
    {:move=>move,:level=>lv,:category=>PMD_AC.mastery_move_category_v048(data),
     :magnitude=>PMD_AC.mastery_magnitude_v048(lv),
     :summary=>PMD_AC.mastery_policy_short_v048(move,lv)}
  end
end

# Replace only the compact active-slot summary. The underlying v0.47 panel,
# navigation and move-management logic stay untouched.
class Sprite_PMDProgressionPanelV047
  def draw_move_summary(x,y,w,mv,selected=false)
    bitmap.fill_rect(x,y,w,42,selected ? Color.new(65,95,130,230) : Color.new(28,36,48,220))
    if mv==nil
      bitmap.font.color=Color.new(130,140,150);bitmap.font.size=16
      bitmap.draw_text(x+8,y+2,w-16,20,'－ 空白 －',0);return
    end
    name=PMD_AC.move_display_name_v047(mv);mastery=@instance.mastery_view_v047(mv)
    bitmap.font.size=16;bitmap.font.bold=true;bitmap.font.color=Color.new(245,245,245)
    bitmap.draw_text(x+8,y+1,w-16,20,name,0)
    bitmap.font.bold=false;bitmap.font.size=12;bitmap.font.color=Color.new(175,215,255)
    detail='Lv'+mastery[:level].to_s+'  '+PMD_AC.mastery_policy_short_v048(mv,mastery[:level])
    bitmap.draw_text(x+8,y+20,w-112,18,detail,0)
    draw_bar(x+w-102,y+26,90,6,mastery[:rate],Color.new(45,50,58),Color.new(110,200,255))
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v048_start start unless method_defined?(:pmd_ac_v048_start)
  alias pmd_ac_v048_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v048_prepare_verification_battle)
  alias pmd_ac_v048_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v048_update_verification_script)
  alias pmd_ac_v048_log_event log_event unless method_defined?(:pmd_ac_v048_log_event)
  alias pmd_ac_v048_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v048_complete_verification_mode)
  alias pmd_ac_v048_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v048_canonical_accuracy_probability)
  alias pmd_ac_v048_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v048_resolve_skill)
  alias pmd_ac_v048_activate_guard_v040 activate_guard_v040 unless method_defined?(:pmd_ac_v048_activate_guard_v040)

  def start
    pmd_ac_v048_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.48 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::MASTERY_POLICY_MANIFEST_V048
    log_event(:mastery_policy,
      'LOADED skill_lv=1..5 magnitude=1.00..1.20 drain_ratio_max=1.05 secondary_pp_max=5 status_acc_pp_max=8 status_energy_max=8 reactive_energy_max=5 field_turn_max=+1 weather_turn_max=+1 guard_frames_max=+8 tactical_frames_max=+8 safety=stage/control/priority/two_turn/helping/reactive_ratio_locked checksum32='+m[:runtime_checksum32].to_s)
  end

  def mastery_level_for_user_v048(user,data)
    return 1 if user==nil || data==nil || !user.respond_to?(:pokemon_instance)
    inst=user.pokemon_instance;return 1 if inst==nil
    mk=PMD_AC.mastery_move_key_v048(data);return 1 if mk==nil
    return 1 unless inst.respond_to?(:knows_move_v045?) && inst.knows_move_v045?(mk)
    inst.move_level_v045(mk)
  end

  # Bypass the old blanket v0.46 wrapper and feed the already-verified pre-v046
  # effect chain a policy-transformed data copy. This avoids double scaling.
  def apply_skill_effects(user,target,data,scale=1.0)
    lv=mastery_level_for_user_v048(user,data)
    d=PMD_AC.mastery_transform_data_v048(data,lv)
    mag=PMD_AC.mastery_magnitude_v048(lv)
    use_scale=PMD_AC.mastery_scale_channel_v048?(d) ? scale.to_f*mag : scale.to_f
    if lv>1 && data!=nil
      mk=PMD_AC.mastery_move_key_v048(data)
      log_event(:move_mastery_effect,user.log_name+' '+mk.to_s+' skill_lv='+lv.to_s+' policy='+PMD_AC.mastery_move_category_v048(data).to_s+' magnitude_x'+sprintf('%.2f',mag)) if user!=nil
    end
    pmd_ac_v046_apply_skill_effects(user,target,d,use_scale)
  end

  # Status mastery improves reliability, not control duration. Bonus is applied
  # after the complete accuracy/evasion/weather/ability calculation and capped.
  def canonical_accuracy_probability(user,target,data)
    chance=pmd_ac_v048_canonical_accuracy_probability(user,target,data)
    return chance unless PMD_AC.mastery_status_move_v048?(data)
    lv=mastery_level_for_user_v048(user,data);bonus=PMD_AC.mastery_status_accuracy_bonus_v048(lv)
    PMD_AC.clamp(chance.to_f+bonus,0.0,100.0)
  end

  # Guard gets only a bounded frame bonus. Priority stays exactly as authored.
  def activate_guard_v040(unit,data)
    lv=mastery_level_for_user_v048(unit,data);d=data==nil ? {} : data.dup
    if d[:duration_frames]!=nil
      d[:duration_frames]=[d[:duration_frames].to_i+PMD_AC.mastery_guard_frame_bonus_v048(lv),1].max
    end
    pmd_ac_v048_activate_guard_v040(unit,d)
  end

  # Pure status/support mastery also grants a small energy head-start. Capture
  # the level before resolution so a mastery level-up from this same cast does
  # not retroactively improve the cast that caused it.
  def resolve_skill(unit)
    data=unit==nil ? nil : unit.skill_data
    lv=mastery_level_for_user_v048(unit,data)
    status=PMD_AC.mastery_status_move_v048?(data)
    category=PMD_AC.mastery_move_category_v048(data)
    target_ok=unit!=nil && unit.skill_target!=nil && unit.skill_target.alive?
    result=pmd_ac_v048_resolve_skill(unit)
    if target_ok && unit!=nil && unit.alive?
      refund=0;reason=:mastery_status_refund;label='status_energy_refund'
      if status
        refund=PMD_AC.mastery_status_energy_refund_v048(lv)
      elsif category==:reactive
        refund=PMD_AC.mastery_reactive_energy_refund_v048(lv);reason=:mastery_reactive_refund;label='reactive_energy_refund'
      end
      if refund>0
        gained=unit.gain_energy(refund,unit,reason)
        mk=PMD_AC.mastery_move_key_v048(data)
        log_event(:move_mastery_effect,unit.log_name+' '+mk.to_s+' skill_lv='+lv.to_s+' '+label+'='+gained.to_i.to_s)
      end
    end
    result
  end

  # Verification --------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v048_prepare_verification_battle
    if verification_mode==:mastery_policy
      @mastery_policy_failed_v048=false
      PMD_AC.begin_identity_sandbox_v045 unless PMD_AC.identity_sandbox_v045?
      for u in @units
        u.verification_combat_sandbox(true)
        PMD_AC.register_pokemon_instance_v045(u.pokemon_instance) if u.respond_to?(:pokemon_instance)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:mastery_policy &&
       message.to_s.index('MASTERY_POLICY_')==0 && message.to_s.include?(' pass=0')
      @mastery_policy_failed_v048=true
    end
    pmd_ac_v048_log_event(category,message)
  end

  def mastery_temp_instance_v048(uid,level=15)
    PMD_PokemonInstance.new(:bulbasaur,level,{:instance_uid=>uid,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
  end

  def verify_mastery_manifest_v048
    return if @verification_done[:mastery_policy_manifest]
    m=PMD_AC::MASTERY_POLICY_MANIFEST_V048;s=PMD_AC::MASTERY_POLICY_SAFETY_V048
    pass=m[:identity_key]=='instance_uid' && m[:move_level_max].to_i==5 &&
      PMD_AC::MASTERY_MAGNITUDE_MULT_V048==[1.0,1.05,1.10,1.15,1.20] &&
      !s[:stat_stage_amplification] && !s[:hard_control_duration_scaling] &&
      !s[:priority_tier_scaling] && !s[:two_turn_phase_reduction] &&
      PMD_AC.mastery_policy_checksum32_v048==m[:runtime_checksum32].to_i
    log_event(:verify,'MASTERY_POLICY_MANIFEST pass='+(pass ? '1':'0')+' skill_lv=5 identity=instance_uid checksum='+PMD_AC.mastery_policy_checksum32_v048.to_s+' safety_locks=6')
    @verification_done[:mastery_policy_manifest]=true
  end

  def verify_mastery_magnitude_v048
    return if @verification_done[:mastery_policy_magnitude]
    i=mastery_temp_instance_v048(99480101,15);i.gain_move_mastery_v045(:tackle,150)
    lv=i.move_level_v045(:tackle);mult=PMD_AC.mastery_magnitude_v048(lv)
    recover=PMD_AC.skill_data(:mv_recover);r0=(recover[:effects]||[]).find{|e|PMD_AC.mastery_effect_type_v048(e)==:heal_maxhp_ratio}
    pass=lv==5 && (mult-1.20).abs<0.0001 && r0!=nil && (r0[:ratio].to_f-0.50).abs<0.0001 &&
      PMD_AC.mastery_scale_channel_v048?(recover)
    log_event(:verify,'MASTERY_POLICY_MAGNITUDE pass='+(pass ? '1':'0')+' tackle_lv=5 magnitude=1.20 recover_ratio=0.50 scale_channel=1 expected_recover_effective=0.60')
    @verification_done[:mastery_policy_magnitude]=true
  end

  def verify_mastery_drain_secondary_v048
    return if @verification_done[:mastery_policy_drain_secondary]
    gd=PMD_AC.mastery_transform_data_v048(PMD_AC.skill_data(:mv_giga_drain),5)
    dr=(gd[:effects]||[]).find{|e|PMD_AC.mastery_effect_type_v048(e)==:drain}
    em=PMD_AC.mastery_transform_data_v048(PMD_AC.skill_data(:mv_ember),5)
    sec=(em[:secondary_effects]||[])[0]
    pass=dr!=nil && (dr[:ratio].to_f-0.525).abs<0.0001 && sec!=nil && sec[:chance].to_i==15
    log_event(:verify,'MASTERY_POLICY_DRAIN_SECONDARY pass='+(pass ? '1':'0')+' giga_drain_ratio=0.500->'+sprintf('%.3f',dr==nil ? 0.0 : dr[:ratio].to_f)+' ember_secondary=10->'+(sec==nil ? '0' : sec[:chance].to_s)+' cap=100')
    @verification_done[:mastery_policy_drain_secondary]=true
  end

  def verify_mastery_status_safety_v048
    return if @verification_done[:mastery_policy_status_safety]
    gr=PMD_AC.skill_data(:mv_growl);gx=PMD_AC.mastery_transform_data_v048(gr,5)
    a=(gr[:effects]||[]).find{|e|PMD_AC.mastery_effect_type_v048(e)==:stat_stage}
    b=(gx[:effects]||[]).find{|e|PMD_AC.mastery_effect_type_v048(e)==:stat_stage}
    pass=a!=nil && b!=nil && a[:stages].to_i==b[:stages].to_i &&
      PMD_AC.mastery_status_accuracy_bonus_v048(5)==8.0 &&
      PMD_AC.mastery_status_energy_refund_v048(5)==8 && PMD_AC.mastery_reactive_energy_refund_v048(5)==5 &&
      !PMD_AC::MASTERY_POLICY_SAFETY_V048[:hard_control_duration_scaling]
    log_event(:verify,'MASTERY_POLICY_STATUS_SAFETY pass='+(pass ? '1':'0')+' stat_stage='+a[:stages].to_i.to_s+'->'+b[:stages].to_i.to_s+' accuracy_pp=+8 status_energy=8 reactive_energy=5 control_duration_growth=0')
    @verification_done[:mastery_policy_status_safety]=true
  end

  def verify_mastery_field_guard_tactical_v048
    return if @verification_done[:mastery_policy_field_guard_tactical]
    ref=PMD_AC.mastery_transform_data_v048(PMD_AC.skill_data(:mv_reflect),5)
    fe=(ref[:effects]||[]).find{|e|PMD_AC.mastery_effect_type_v048(e)==:field_effect}
    hh=PMD_AC.mastery_transform_data_v048(PMD_AC.skill_data(:mv_helping_hand),5)
    q=PMD_AC.skill_data(:mv_quick_attack);qx=PMD_AC.mastery_transform_data_v048(q,5)
    guard=60+PMD_AC.mastery_guard_frame_bonus_v048(5)
    pass=fe!=nil && fe[:turns].to_i==6 && hh[:duration_frames].to_i==68 && guard==68 &&
      (hh[:damage_multiplier].to_f-1.50).abs<0.001 && (q[:priority]||0).to_i==(qx[:priority]||0).to_i
    log_event(:verify,'MASTERY_POLICY_UTILITY pass='+(pass ? '1':'0')+' reflect_turns=5->'+(fe==nil ? '0' : fe[:turns].to_s)+' guard_frames=60->'+guard.to_s+' helping_frames=60->'+hh[:duration_frames].to_s+' helping_mult=1.50 priority_unchanged=1')
    @verification_done[:mastery_policy_field_guard_tactical]=true
  end

  def verify_mastery_ui_v048
    return if @verification_done[:mastery_policy_ui]
    i=mastery_temp_instance_v048(99480601,15);i.gain_move_mastery_v045(:tackle,150)
    p=i.move_mastery_policy_profile_v048(:tackle);s=p[:summary].to_s
    panel=nil;ok=false
    begin
      panel=Sprite_PMDProgressionPanelV047.new(@viewport,i,nil)
      ok=panel.bitmap!=nil && panel.bitmap.width==Graphics.width && s.include?('20')
    rescue => e
      log_event(:mastery_policy,'UI_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s);ok=false
    ensure
      panel.dispose if panel!=nil && !panel.disposed?
    end
    log_event(:verify,'MASTERY_POLICY_UI pass='+(ok ? '1':'0')+' active_summary='+s+' panel=544x416 policy_visible=1')
    @verification_done[:mastery_policy_ui]=true
  end

  def verify_mastery_modes_v048
    return if @verification_done[:mastery_policy_modes]
    exp=[:mastery_policy,:progression_ui,:progression_runtime,:identity_bridge,:tactical_support]
    pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:mastery_policy
    log_event(:verify,'MASTERY_POLICY_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=MASTERY_POLICY')
    @verification_done[:mastery_policy_modes]=true
  end

  def update_verification_script
    pmd_ac_v048_update_verification_script
    return unless verification_mode==:mastery_policy
    f=@verification_frame
    verify_mastery_manifest_v048 if f==4
    verify_mastery_magnitude_v048 if f==120
    verify_mastery_drain_secondary_v048 if f==250
    verify_mastery_status_safety_v048 if f==380
    verify_mastery_field_guard_tactical_v048 if f==510
    verify_mastery_ui_v048 if f==650
    verify_mastery_modes_v048 if f==770
    complete_verification_mode if f==PMD_AC::VERIFICATION_MASTERY_POLICY_END_FRAME_V048
  end

  def complete_verification_mode
    if verification_mode==:mastery_policy
      failed=@mastery_policy_failed_v048
      PMD_AC.end_identity_sandbox_v045 if PMD_AC.identity_sandbox_v045?
      if failed
        for u in @units;u.verification_finish;end
        @verification_done[:verification_complete]=true
        log_event(:verify,'FAILED mode=MASTERY_POLICY auto_skill=on original_skills=restored')
        return
      end
    end
    pmd_ac_v048_complete_verification_mode
  end
end
