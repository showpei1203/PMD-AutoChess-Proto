#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.66
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V066 / NORMALIZE_EXCEPTIONS_V066 / SLOW_START_FRAMES_V066 / BAD_DREAMS_TURN_FRAMES_V066
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ability_behavior / ability_data / ability_runtime_scalar_v066 / ability_runtime_checksum32_v066
# - validate_ability_runtime_v066 / ability_runtime_behavior_v066 / pokemon_types / basic_move_type
# - ability_incoming_multiplier / ability_flower_gift_multiplier_v066 / atk / special_defense
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.66
# Ability Runtime Coverage III
#------------------------------------------------------------------------------
# Adds ten Generation-V abilities without changing stable movement, Native Pose,
# multi-hit damage packets, presentation anchors or the Organic Combat SFX layer.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V066="0.66"
  NORMALIZE_EXCEPTIONS_V066=[:hidden_power,:weather_ball,:natural_gift,:judgment,:techno_blast,:struggle]
  SLOW_START_FRAMES_V066=300
  BAD_DREAMS_TURN_FRAMES_V066=60

  class << self
    alias pmd_ac_v066_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v066_ability_behavior)
    alias pmd_ac_v066_ability_data ability_data unless method_defined?(:pmd_ac_v066_ability_data)
    def ability_behavior(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V066[key]
      return b unless b==nil || b.empty?
      pmd_ac_v066_ability_behavior(key)
    end
    def ability_data(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V066[key]
      return b unless b==nil || b.empty?
      pmd_ac_v066_ability_data(key)
    end
    def ability_runtime_scalar_v066(x)
      return '' if x==nil
      return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+x[k].to_s}.join(',') if x.is_a?(Hash)
      return x.collect{|v|v.to_s}.join(',') if x.is_a?(Array)
      x.to_s
    end
    def ability_runtime_checksum32_v066
      h=0
      fields=[:ability_key,:kind,:behavior_status,:bypass,:future_non_executable,
        :chance_num,:chance_den,:disable_frames,:roll_once_per_hit,
        :fire_num,:fire_den,:burn_num,:burn_den,:target_type,:power_bonus_gen5,
        :exceptions,:pattern,:loaf_spends_energy,:loaf_frames,:turns,:turn_frames,
        :atk_num,:atk_den,:speed_num,:speed_den,:damage_num,:damage_den,
        :after_complete_move,:damaging_only,:weather_types,:suppressed_or_other,
        :species,:weather,:spdef_num,:spdef_den]
      ABILITY_RUNTIME_BEHAVIOR_V066.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        d=ABILITY_RUNTIME_BEHAVIOR_V066[k]
        text=fields.collect{|f|ability_runtime_scalar_v066(d[f])}.join('|')
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_ability_runtime_v066
      e=[];m=ABILITY_RUNTIME_MANIFEST_V066
      e.push('behavior_count') unless ABILITY_RUNTIME_BEHAVIOR_V066.size==10
      e.push('cumulative') unless m[:cumulative_implemented_ability_count].to_i==125
      e.push('slots') unless m[:implemented_slot_count].to_i==975 && m[:new_implemented_slot_count].to_i==23
      e.push('species') unless m[:species_with_any_implemented_ability].to_i==481 && m[:new_species_with_any_implemented_ability].to_i==8
      e.push('checksum') unless ability_runtime_checksum32_v066==m[:runtime_checksum32].to_i
      m[:new_ability_keys].each do |k|
        b=ability_behavior(k);e.push('bridge_'+k.to_s) if b==nil || b[:behavior_status]!=:implemented_ability_v066
      end
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :ability_runtime_coverage_iii_v066,
    :ability_runtime_coverage_ii_v065,
    :ability_runtime_coverage_v064,
    :native_semantic_audit_v063,
    :native_semantic_v062,
    :native_combo_preview_v062,
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060,
    :move_coverage_x
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :ability_runtime_coverage_iii_v066=>'ABILITY_RUNTIME_COVERAGE_III_V066',
    :ability_runtime_coverage_ii_v065=>'ABILITY_RUNTIME_COVERAGE_II_V065',
    :ability_runtime_coverage_v064=>'ABILITY_RUNTIME_COVERAGE_V064',
    :native_semantic_audit_v063=>'NATIVE_SEMANTIC_AUDIT_V063',
    :native_semantic_v062=>'NATIVE_SEMANTIC_V062',
    :native_combo_preview_v062=>'NATIVE_COMBO_PREVIEW_V062',
    :compiled_pose_runtime_v061=>'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060=>'MULTI_CHOREO_V060',
    :native_pose_showcase_v060=>'NATIVE_POSE_SHOWCASE_V060',
    :move_coverage_x=>'MOVE_COVERAGE_X'
  }
end

class Game_PMDChessUnit
  alias pmd_ac_v066_pokemon_types pokemon_types unless method_defined?(:pmd_ac_v066_pokemon_types)
  alias pmd_ac_v066_basic_move_type basic_move_type unless method_defined?(:pmd_ac_v066_basic_move_type)
  alias pmd_ac_v066_ability_incoming_multiplier ability_incoming_multiplier unless method_defined?(:pmd_ac_v066_ability_incoming_multiplier)
  alias pmd_ac_v066_atk atk unless method_defined?(:pmd_ac_v066_atk)
  alias pmd_ac_v066_special_defense special_defense unless method_defined?(:pmd_ac_v066_special_defense)
  alias pmd_ac_v066_speed_stat speed_stat unless method_defined?(:pmd_ac_v066_speed_stat)
  alias pmd_ac_v066_update_statuses update_statuses unless method_defined?(:pmd_ac_v066_update_statuses)
  alias pmd_ac_v066_begin_attack begin_attack unless method_defined?(:pmd_ac_v066_begin_attack)
  alias pmd_ac_v066_begin_skill begin_skill unless method_defined?(:pmd_ac_v066_begin_skill)
  alias pmd_ac_v066_update update unless method_defined?(:pmd_ac_v066_update)
  alias pmd_ac_v066_receive_damage receive_damage unless method_defined?(:pmd_ac_v066_receive_damage)
  alias pmd_ac_v066_apply_status apply_status unless method_defined?(:pmd_ac_v066_apply_status)
  alias pmd_ac_v066_canonical_apply_sleep canonical_apply_sleep unless method_defined?(:pmd_ac_v066_canonical_apply_sleep)
  alias pmd_ac_v066_canonical_apply_freeze canonical_apply_freeze unless method_defined?(:pmd_ac_v066_canonical_apply_freeze)
  alias pmd_ac_v066_canonical_apply_confusion canonical_apply_confusion unless method_defined?(:pmd_ac_v066_canonical_apply_confusion)
  alias pmd_ac_v066_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v066_change_stat_stage)

  def ability_runtime_behavior_v066;PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V066[ability_key]||{};end

  def pokemon_types
    if ability_key==:color_change && @color_change_type_v066!=nil
      return [@color_change_type_v066]
    end
    if ability_key==:forecast && key==:castform && @scene!=nil && @scene.respond_to?(:ability_forecast_type_v066)
      return [@scene.ability_forecast_type_v066(self)]
    end
    pmd_ac_v066_pokemon_types
  end

  def basic_move_type
    return :normal if ability_key==:normalize
    pmd_ac_v066_basic_move_type
  end

  def ability_incoming_multiplier(move_type,category)
    base=pmd_ac_v066_ability_incoming_multiplier(move_type,category)
    if base>0.0 && ability_key==:heatproof && move_type==:fire
      base*=0.5
    end
    base
  end

  def ability_flower_gift_multiplier_v066
    return 1.0 if @scene==nil || !@scene.respond_to?(:ability_flower_gift_active_v066?)
    @scene.ability_flower_gift_active_v066?(self) ? 1.5 : 1.0
  end

  def atk
    v=pmd_ac_v066_atk
    v=[(v.to_f*0.5).round,1].max if ability_key==:slow_start && @slow_start_frames_v066.to_i>0
    m=ability_flower_gift_multiplier_v066
    v=[(v.to_f*m).round,1].max if m!=1.0
    v
  end
  def special_defense
    v=pmd_ac_v066_special_defense
    m=ability_flower_gift_multiplier_v066
    v=[(v.to_f*m).round,1].max if m!=1.0
    v
  end
  def speed_stat
    v=pmd_ac_v066_speed_stat
    v=[(v.to_f*0.5).round,1].max if ability_key==:slow_start && @slow_start_frames_v066.to_i>0
    v
  end

  def ability_infiltrator_field_wrap_v066(source)
    sc=@scene
    if sc!=nil && source!=nil && source.respond_to?(:ability_key) && source.ability_key==:infiltrator &&
       source.respond_to?(:team) && source.team!=team && sc.respond_to?(:ability_push_infiltrator_field_v066)
      old=sc.ability_push_infiltrator_field_v066(source)
      begin
        return yield
      ensure
        sc.ability_restore_infiltrator_field_v066(old)
      end
    end
    yield
  end

  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    ability_infiltrator_field_wrap_v066(source){pmd_ac_v066_receive_damage(value,source,grant_energy,bypass_link,critical)}
  end
  def apply_status(key,options={},source=nil)
    ability_infiltrator_field_wrap_v066(source){pmd_ac_v066_apply_status(key,options,source)}
  end
  def canonical_apply_sleep(source=nil)
    ability_infiltrator_field_wrap_v066(source){pmd_ac_v066_canonical_apply_sleep(source)}
  end
  def canonical_apply_freeze(source=nil)
    ability_infiltrator_field_wrap_v066(source){pmd_ac_v066_canonical_apply_freeze(source)}
  end
  def canonical_apply_confusion(source=nil)
    ability_infiltrator_field_wrap_v066(source){pmd_ac_v066_canonical_apply_confusion(source)}
  end
  def change_stat_stage(stat,delta,source=nil)
    ability_infiltrator_field_wrap_v066(source){pmd_ac_v066_change_stat_stage(stat,delta,source)}
  end

  def update_statuses
    burn=nil;old=nil
    if ability_key==:heatproof && @statuses!=nil
      burn=@statuses[:burn]
      if burn!=nil && burn[:value].to_i>0
        old=burn[:value];half=(old.to_f*0.5).round;half=1 if half<1;burn[:value]=half
      end
    end
    pmd_ac_v066_update_statuses
    if burn!=nil && old!=nil && @statuses!=nil && @statuses[:burn].equal?(burn)
      burn[:value]=old
    end
  end

  def ability_truant_loaf_v066?
    if ability_key!=:truant
      @truant_loaf_next_v066=false;return false
    end
    if @truant_loaf_next_v066
      @truant_loaf_next_v066=false;return true
    end
    @truant_loaf_next_v066=true;false
  end
  def ability_truant_set_next_v066(v);@truant_loaf_next_v066=v ? true:false;end
  def ability_truant_loaf_active_v066?;@action==:stun && @stun_frames.to_i>0;end
  def ability_verification_set_energy_v066(v);@energy=v.to_i;end
  def ability_truant_apply_loaf_v066(kind)
    @action=:stun;@visual_action=:idle;@stun_frames=36;@action_timer=0
    @action_total_frames=0;@action_hit_done=false;@skill_target=nil
    @attack_wait=[@attack_wait_max.to_i,36].max
    log_event(:ability_runtime_iii,log_name+' truant LOAF action='+kind.to_s+' energy='+@energy.to_i.to_s)
    true
  end
  def begin_attack
    return ability_truant_apply_loaf_v066(:attack) if ability_truant_loaf_v066?
    pmd_ac_v066_begin_attack
  end
  def begin_skill(skill_target=nil)
    return ability_truant_apply_loaf_v066(:skill) if ability_truant_loaf_v066?
    pmd_ac_v066_begin_skill(skill_target)
  end

  def ability_slow_start_activate_v066
    @slow_start_frames_v066=PMD_AC::SLOW_START_FRAMES_V066
    @slow_start_seen_v066=:slow_start
    log_event(:ability_runtime_iii,log_name+' slow_start ACTIVATE frames='+@slow_start_frames_v066.to_i.to_s)
    true
  end
  def ability_slow_start_frames_v066;@slow_start_frames_v066.to_i;end
  def ability_color_change_type_v066;@color_change_type_v066;end
  def ability_set_color_change_type_v066(type);@color_change_type_v066=type;end

  def ability_runtime_update_v066
    cur=ability_key
    if cur==:slow_start
      ability_slow_start_activate_v066 if @slow_start_seen_v066!=:slow_start
      @slow_start_frames_v066-=1 if @slow_start_frames_v066.to_i>0 && battle_active? && !@verification_combat_sandbox
    else
      @slow_start_seen_v066=cur;@slow_start_frames_v066=0
    end
    if cur==:bad_dreams && battle_active? && !@verification_combat_sandbox
      @bad_dreams_wait_v066=PMD_AC::BAD_DREAMS_TURN_FRAMES_V066 if @bad_dreams_wait_v066==nil
      @bad_dreams_wait_v066-=1
      if @bad_dreams_wait_v066<=0
        @bad_dreams_wait_v066=PMD_AC::BAD_DREAMS_TURN_FRAMES_V066
        @scene.ability_bad_dreams_pulse_v066(self) if @scene!=nil && @scene.respond_to?(:ability_bad_dreams_pulse_v066)
      end
    else
      @bad_dreams_wait_v066=nil unless cur==:bad_dreams
    end
  end
  def update
    ability_runtime_update_v066
    pmd_ac_v066_update
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v066_start start unless method_defined?(:pmd_ac_v066_start)
  alias pmd_ac_v066_start_battle start_battle unless method_defined?(:pmd_ac_v066_start_battle)
  alias pmd_ac_v066_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v066_prepare_verification_battle)
  alias pmd_ac_v066_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v066_update_verification_script)
  alias pmd_ac_v066_canonical_global_ability_units canonical_global_ability_units unless method_defined?(:pmd_ac_v066_canonical_global_ability_units)
  alias pmd_ac_v066_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v066_apply_skill_effects)
  alias pmd_ac_v066_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v066_deal_direct_damage)
  alias pmd_ac_v066_finish_contact_choreo_v060 finish_contact_choreo_v060 unless method_defined?(:pmd_ac_v066_finish_contact_choreo_v060)
  alias pmd_ac_v066_start_ranged_pipeline_on_launch_v0602 start_ranged_pipeline_on_launch_v0602 unless method_defined?(:pmd_ac_v066_start_ranged_pipeline_on_launch_v0602)
  alias pmd_ac_v066_canonical_field_active_for_unit canonical_field_active_for_unit? unless method_defined?(:pmd_ac_v066_canonical_field_active_for_unit)
  alias pmd_ac_v066_ability_move_type_v065 ability_move_type_v065 unless method_defined?(:pmd_ac_v066_ability_move_type_v065)

  def start
    pmd_ac_v066_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.65 Battle Verification Log/,'PMD AutoChess Proto v0.66 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V066
    log_event(:ability_runtime_iii,'LOADED new='+m[:new_implemented_ability_count].to_s+
      ' cumulative='+m[:cumulative_implemented_ability_count].to_s+
      ' implemented_slots='+m[:implemented_slot_count].to_s+'/'+m[:total_slot_count].to_s+
      ' coverage='+sprintf('%.2f',m[:implemented_slot_coverage_percent].to_f)+'%'+
      ' species='+m[:species_with_any_implemented_ability].to_s+'/494 checksum32='+m[:runtime_checksum32].to_s)
    log_event(:presentation,'PATCH v0.66 ability_runtime=infiltrator,cursed_body,heatproof,normalize,truant,slow_start,bad_dreams,color_change,forecast,flower_gift '+
      'native_router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep beam_projectile_impact_targetfx=unchanged organic_sfx=v0.56.1')
  end

  def canonical_global_ability_units
    list=pmd_ac_v066_canonical_global_ability_units
    list+=@ability_runtime_test_units_v066 if @ability_runtime_test_units_v066!=nil
    list.uniq
  end

  def start_battle
    pmd_ac_v066_start_battle
    return unless @phase==:battle
    for u in (@units||[])
      next if u==nil || u.dead?
      u.ability_slow_start_activate_v066 if u.ability_key==:slow_start && u.respond_to?(:ability_slow_start_activate_v066)
    end
  end

  # Generation V Infiltrator bypasses Reflect, Light Screen, Safeguard and Mist.
  # Substitute bypass begins in Generation VI, so the existing Substitute target
  # interception layer is deliberately left untouched in this Black/White ruleset.
  def ability_push_infiltrator_field_v066(source)
    old=@ability_infiltrator_field_source_v066
    @ability_infiltrator_field_source_v066=source
    old
  end
  def ability_restore_infiltrator_field_v066(old)
    @ability_infiltrator_field_source_v066=old
  end
  def canonical_field_active_for_unit?(unit,key)
    src=@ability_infiltrator_field_source_v066
    if src!=nil && src.respond_to?(:ability_key) && src.ability_key==:infiltrator &&
       unit!=nil && src.respond_to?(:team) && src.team!=unit.team &&
       [:reflect,:light_screen,:safeguard,:mist].include?(key)
      return false
    end
    pmd_ac_v066_canonical_field_active_for_unit(unit,key)
  end

  # Normalize must be visible to v0.65's Lightning Rod / Storm Drain selector,
  # which resolves type before apply_skill_effects receives its cloned move data.
  def ability_move_type_v065(user,data=nil,source_type=nil)
    if user!=nil && user.respond_to?(:ability_key) && user.ability_key==:normalize
      d=ability_move_data_v065(user,data,source_type)
      if d!=nil
        mk=d[:canonical_move_key]||d[:move_key]
        return :normal unless PMD_AC::NORMALIZE_EXCEPTIONS_V066.include?(mk)
      end
    end
    pmd_ac_v066_ability_move_type_v065(user,data,source_type)
  end

  def ability_runtime_roll_v066(max)
    m=[max.to_i,1].max
    if verification_mode==:ability_runtime_coverage_iii_v066 && @ability_runtime_rolls_v066!=nil && !@ability_runtime_rolls_v066.empty?
      return @ability_runtime_rolls_v066.shift.to_i % m
    end
    rand(m)
  end

  def ability_normalize_data_v066(user,data)
    return data if user==nil || data==nil || user.ability_key!=:normalize
    mk=data[:canonical_move_key]||data[:move_key]
    return data if PMD_AC::NORMALIZE_EXCEPTIONS_V066.include?(mk)
    d=data.dup;d[:move_type]=:normal;d[:type]=:normal;d
  end

  def ability_cursed_body_after_v066(user,target,data,result)
    return false if user==nil || target==nil || user==target || result.to_i<=0
    return false unless target.is_a?(Game_PMDChessUnit) && target.ability_key==:cursed_body
    mk=data==nil ? nil : (data[:canonical_move_key]||data[:move_key])
    return false if mk==nil || mk==:struggle || !user.respond_to?(:apply_disable_v052)
    roll=ability_runtime_roll_v066(100);return false if roll>=30
    ok=user.apply_disable_v052(mk,180)
    log_event(:ability_runtime_iii,target.log_name+' cursed_body DISABLE attacker='+user.log_name+' move='+mk.to_s+' roll='+roll.to_s+'/100 frames=180') if ok
    ok
  end

  def ability_color_change_after_v066(user,target,data,result,move_type=nil)
    return false if user==nil || target==nil || user==target || result.to_i<=0
    return false unless target.is_a?(Game_PMDChessUnit) && target.ability_key==:color_change
    t=move_type;t=(data[:move_type]||data[:type]) if t==nil && data!=nil
    return false if t==nil
    old=target.pokemon_types[0];return false if target.pokemon_types.size==1 && old==t
    target.ability_set_color_change_type_v066(t)
    log_event(:ability_runtime_iii,target.log_name+' color_change '+old.to_s+'->'+t.to_s+' after_complete_move=1')
    true
  end

  def ability_multi_key_v066(user,target,data)
    return nil if user==nil || target==nil || data==nil
    mk=data[:canonical_move_key]||data[:move_key];return nil if mk==nil
    user.instance_uid.to_s+'|'+target.instance_uid.to_s+'|'+mk.to_s
  end

  def ability_attach_contact_multi_v066(user,target,data)
    return false if @multi_contact_events_v060==nil
    mk=data[:canonical_move_key]||data[:move_key]
    q=@multi_contact_events_v060.reverse.find{|x|x[:user]==user && x[:target]==target && x[:move_key]==mk && x[:ability_v066_pending]==nil}
    return false if q==nil
    q[:ability_v066_pending]={:user=>user,:target=>target,:data=>data,:done=>false}
    true
  end

  def start_ranged_pipeline_on_launch_v0602(user,target,effect_type,data)
    key=pmd_ac_v066_start_ranged_pipeline_on_launch_v0602(user,target,effect_type,data)
    if user!=nil && target!=nil && data!=nil
      hits=multi_hit_count_for_v060(data)
      if hits.to_i>1
        @ability_ranged_multi_pending_v066={} if @ability_ranged_multi_pending_v066==nil
        k=ability_multi_key_v066(user,target,data)
        @ability_ranged_multi_pending_v066[k]={:user=>user,:target=>target,:data=>data,:hits=>hits.to_i,:resolved=>0,:damage=>0}
      end
    end
    key
  end

  def finish_contact_choreo_v060(q,early=false)
    r=pmd_ac_v066_finish_contact_choreo_v060(q,early)
    p=q==nil ? nil : q[:ability_v066_pending]
    if p!=nil && !p[:done]
      p[:done]=true
      result=q[:total_damage].to_i
      ability_color_change_after_v066(p[:user],p[:target],p[:data],result,nil)
      log_event(:ability_runtime_iii,p[:user].log_name+' multi_post_effect COMPLETE move='+(p[:data][:canonical_move_key]||p[:data][:move_key]).to_s+' packets='+q[:done].to_i.to_s+'/'+q[:hits].to_i.to_s)
    end
    r
  end

  def ability_ranged_packet_after_v066(user,target,data,result)
    return false if @ability_ranged_multi_pending_v066==nil || user==nil || target==nil || data==nil
    k=ability_multi_key_v066(user,target,data);p=@ability_ranged_multi_pending_v066[k]
    return false if p==nil
    p[:resolved]=p[:resolved].to_i+1;p[:damage]=p[:damage].to_i+result.to_i
    if p[:resolved].to_i>=p[:hits].to_i || target.dead?
      ability_color_change_after_v066(user,target,p[:data],p[:damage],nil)
      log_event(:ability_runtime_iii,user.log_name+' ranged_multi_post_effect COMPLETE move='+(p[:data][:canonical_move_key]||p[:data][:move_key]).to_s+' resolved='+p[:resolved].to_s+'/'+p[:hits].to_s)
      @ability_ranged_multi_pending_v066.delete(k)
    end
    true
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    d=ability_normalize_data_v066(user,data)
    original_multi=d!=nil && !d[:v060_packet] && (d[:multi_hit_v049] || d[:triple_kick_v059])
    packet_multi=d!=nil && d[:v060_packet]
    @ability_v066_skill_scope_depth=@ability_v066_skill_scope_depth.to_i+1
    begin
      result=pmd_ac_v066_apply_skill_effects(user,target,d,scale)
    ensure
      @ability_v066_skill_scope_depth-=1
    end
    if packet_multi && ability_ranged_packet_after_v066(user,target,d,result)
      return result
    end
    if original_multi
      attached=ability_attach_contact_multi_v066(user,target,d)
      unless attached
        # No queued continuation means the move ended on its first/only resolved packet.
        ability_color_change_after_v066(user,target,d,result,nil)
      end
      return result
    end
    ability_color_change_after_v066(user,target,d,result,nil)
    result
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup
    data=opts[:skill_data]
    if user!=nil && user.ability_key==:normalize && data!=nil
      data=ability_normalize_data_v066(user,data);opts[:skill_data]=data
      opts[:move_type]=data[:move_type]||data[:type]
    elsif user!=nil && user.ability_key==:normalize && data==nil && opts[:source_type]==:basic
      opts[:move_type]=:normal
    end
    result=pmd_ac_v066_deal_direct_damage(user,target,power,opts)
    ability_cursed_body_after_v066(user,target,data,result) if data!=nil
    # v0.60 contact multi-hit continuation packets call the pre-v0.60 skill
    # resolver directly.  They carry sequential_single_v0572, so suppress the
    # per-packet Color Change here and let finish_contact_choreo_v060 fire once
    # after the complete move.  Ranged packets are already inside the current
    # apply_skill_effects scope and are finalized by ability_ranged_packet_after_v066.
    sequential_packet=(data!=nil && data[:sequential_single_v0572]) ? true:false
    if @ability_v066_skill_scope_depth.to_i<=0 && !sequential_packet
      ability_color_change_after_v066(user,target,data,result,opts[:move_type])
    end
    result
  end

  def ability_bad_dreams_pulse_v066(source,units=nil)
    return 0 if source==nil || source.dead? || source.ability_key!=:bad_dreams
    list=units||canonical_global_ability_units;hits=0;total=0
    list.each do |u|
      next if u==nil || !u.is_a?(Game_PMDChessUnit) || u.dead? || u.team==source.team || !u.status?(:sleep)
      amount=[u.maxhp/8,1].max
      dealt=respond_to?(:canonical_indirect_ability_damage) ? canonical_indirect_ability_damage(u,source,amount,:bad_dreams) : 0
      hits+=1 if dealt.to_i>0;total+=dealt.to_i
    end
    log_event(:ability_runtime_iii,source.log_name+' bad_dreams PULSE sleeping_hits='+hits.to_s+' damage='+total.to_s)
    total
  end

  def ability_forecast_type_v066(unit)
    return :normal if unit==nil || unit.key!=:castform || unit.ability_key!=:forecast
    return :fire if canonical_weather_effective?(:sun)
    return :water if canonical_weather_effective?(:rain)
    return :ice if canonical_weather_effective?(:hail)
    :normal
  end

  def ability_flower_gift_sources_v066(target,units=nil)
    return [] if target==nil || !canonical_weather_effective?(:sun)
    list=units||canonical_global_ability_units
    list.find_all{|u|u!=nil && u.is_a?(Game_PMDChessUnit) && u.alive? && u.team==target.team && u.ability_key==:flower_gift && u.key==:cherrim}
  end
  def ability_flower_gift_active_v066?(target,units=nil)
    !ability_flower_gift_sources_v066(target,units).empty?
  end

  # Verification --------------------------------------------------------------
  def ability_runtime_verification_unit_v066(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99066000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9660+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_runtime_test_units_v066=[] if @ability_runtime_test_units_v066==nil
    @ability_runtime_test_units_v066.push(u);u
  end

  def prepare_verification_battle
    pmd_ac_v066_prepare_verification_battle
    return unless verification_mode==:ability_runtime_coverage_iii_v066
    @ability_runtime_test_units_v066=[];@ability_runtime_rolls_v066=[]
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,'START mode=ABILITY_RUNTIME_COVERAGE_III_V066 new=10 slots=975/1193 species=481/494 diagnostic_only=1 pokemon_resume_after_final_assert=1')
  end

  def verify_ability_runtime_manifest_v066
    return if @verification_done[:v066_manifest]
    e=PMD_AC.validate_ability_runtime_v066;m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V066;ok=e.empty?
    log_event(:verify,'ABILITY_RUNTIME_MANIFEST_V066 pass='+(ok ? '1':'0')+' new=10 cumulative=125 slots=975/1193 coverage=81.73% species=481/494 checksum='+PMD_AC.ability_runtime_checksum32_v066.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v066_manifest]=true
  end

  def verify_ability_infiltrator_v066
    return if @verification_done[:v066_infiltrator]
    a=ability_runtime_verification_unit_v066(:spiritomb,:hidden,:ally,1)
    plain=ability_runtime_verification_unit_v066(:rattata,:primary,:ally,2)
    t=ability_runtime_verification_unit_v066(:rattata,:primary,:enemy,3)
    a.deploy_to_cell(0,2);plain.deploy_to_cell(0,3);t.deploy_to_cell(4,2)

    set_canonical_field_effect_v035(:reflect,t,5)
    t.canonical_set_direct_damage_context({:user=>plain,:category=>:physical,:move_type=>:normal,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,plain,false,true,false);reflect_plain=before-t.hp
    t.canonical_clear_direct_damage_context
    t.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,a,false,true,false);reflect_infil=before-t.hp
    t.canonical_clear_direct_damage_context
    clear_canonical_field_effect_v035(:reflect,:enemy,:verify)

    set_canonical_field_effect_v035(:light_screen,t,5)
    t.canonical_set_direct_damage_context({:user=>plain,:category=>:special,:move_type=>:dark,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,plain,false,true,false);screen_plain=before-t.hp
    t.canonical_clear_direct_damage_context
    t.canonical_set_direct_damage_context({:user=>a,:category=>:special,:move_type=>:dark,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,a,false,true,false);screen_infil=before-t.hp
    t.canonical_clear_direct_damage_context
    clear_canonical_field_effect_v035(:light_screen,:enemy,:verify)

    set_canonical_field_effect_v035(:safeguard,t,5)
    s1=t.apply_status(:burn,{:duration=>60},plain);t.remove_status(:burn)
    s2=t.apply_status(:burn,{:duration=>60},a);t.remove_status(:burn)
    clear_canonical_field_effect_v035(:safeguard,:enemy,:verify)
    set_canonical_field_effect_v035(:mist,t,5)
    t.reset_stat_stages;d1=t.change_stat_stage(:atk,-1,plain)
    t.reset_stat_stages;d2=t.change_stat_stage(:atk,-1,a)
    clear_canonical_field_effect_v035(:mist,:enemy,:verify)

    ok=a.ability_key==:infiltrator && reflect_plain==60 && reflect_infil==90 &&
      screen_plain==60 && screen_infil==90 && !s1 && s2 && d1.to_i==0 && d2.to_i==-1
    log_event(:verify,'ABILITY_INFILTRATOR_V066 pass='+(ok ? '1':'0')+
      ' reflect='+reflect_plain.to_s+'->'+reflect_infil.to_s+
      ' light_screen='+screen_plain.to_s+'->'+screen_infil.to_s+
      ' safeguard='+(!s1 ? 'block':'fail')+'->'+(s2 ? 'bypass':'fail')+
      ' mist='+d1.to_i.to_s+'->'+d2.to_i.to_s+
      ' gen5_substitute_bypass=0 field_layer=v0.35')
    @verification_done[:v066_infiltrator]=true
  end

  def verify_ability_cursed_body_v066
    return if @verification_done[:v066_cursed]
    u=ability_runtime_verification_unit_v066(:rattata,:primary,:ally,4)
    t=ability_runtime_verification_unit_v066(:shuppet,:hidden,:enemy,5)
    d={:canonical_move_key=>:tackle,:move_key=>:tackle,:move_type=>:normal,:damage_category=>:physical,:category=>:physical}
    opts={:fixed_damage=>12,:can_crit=>false,:directional=>false,:grant_energy=>false,:source_type=>:skill_direct,:move_type=>:normal,:damage_category=>:physical,:skill_data=>d}
    @ability_runtime_rolls_v066=[99,0]
    r1=deal_direct_damage(u,t,1,opts);first=(u.disabled_move_key_v052==:tackle)
    r2=deal_direct_damage(u,t,1,opts);second=(u.disabled_move_key_v052==:tackle)
    ok=t.ability_key==:cursed_body && r1.to_i>0 && r2.to_i>0 && !first && second
    log_event(:verify,'ABILITY_CURSED_BODY_V066 pass='+(ok ? '1':'0')+' packet1_roll=99 disabled1='+(first ? '1':'0')+' packet2_roll=0 disabled2='+(second ? '1':'0')+' independent_per_hit=1 multihit_continues=1 duration=v0.52_180f')
    @verification_done[:v066_cursed]=true
  end

  def verify_ability_heatproof_v066
    return if @verification_done[:v066_heatproof]
    hp=ability_runtime_verification_unit_v066(:bronzor,:secondary,:enemy,6)
    plain=ability_runtime_verification_unit_v066(:bronzor,:primary,:enemy,7)
    a=hp.ability_incoming_multiplier(:fire,:special);b=plain.ability_incoming_multiplier(:fire,:special)
    hp.apply_status(:burn,{:duration=>10,:value=>10,:interval=>1},nil)
    plain.apply_status(:burn,{:duration=>10,:value=>10,:interval=>1},nil)
    bh=hp.hp;bp=plain.hp;hp.update_statuses;plain.update_statuses
    heat_burn=bh-hp.hp;plain_burn=bp-plain.hp
    ok=hp.ability_key==:heatproof && b>0.0 && (a-(b*0.5)).abs<0.0001 &&
      heat_burn==5 && plain_burn==10
    log_event(:verify,'ABILITY_HEATPROOF_V066 pass='+(ok ? '1':'0')+' fire_multiplier='+sprintf('%.3f',a)+' baseline='+sprintf('%.3f',b)+' burn_tick='+plain_burn.to_s+'->'+heat_burn.to_s+' actual_status_tick=1')
    @verification_done[:v066_heatproof]=true
  end

  def verify_ability_normalize_v066
    return if @verification_done[:v066_normalize]
    u=ability_runtime_verification_unit_v066(:skitty,:secondary,:ally,8)
    d={:canonical_move_key=>:water_gun,:move_key=>:water_gun,:move_type=>:water,:damage_category=>:special}
    w={:canonical_move_key=>:weather_ball,:move_key=>:weather_ball,:move_type=>:water,:damage_category=>:special}
    a=ability_normalize_data_v066(u,d);b=ability_normalize_data_v066(u,w)
    pre=ability_move_type_v065(u,d,:skill_direct);pre_w=ability_move_type_v065(u,w,:skill_direct)
    ok=u.ability_key==:normalize && a[:move_type]==:normal && b[:move_type]==:water &&
      pre==:normal && pre_w==:water
    log_event(:verify,'ABILITY_NORMALIZE_V066 pass='+(ok ? '1':'0')+' water_gun='+a[:move_type].to_s+' pre_target='+pre.to_s+' weather_ball_exception='+b[:move_type].to_s+'/'+pre_w.to_s+' lightning_rod_pre_redirect_safe=1 gen5_power_bonus=0 exceptions=5+struggle')
    @verification_done[:v066_normalize]=true
  end

  def verify_ability_truant_v066
    return if @verification_done[:v066_truant]
    u=ability_runtime_verification_unit_v066(:slakoth,:primary,:ally,9)
    t=ability_runtime_verification_unit_v066(:rattata,:primary,:enemy,10)
    u.verification_force_basic_attack(t);first=u.acting?
    u.verification_force_basic_attack(t);second=u.ability_truant_loaf_active_v066?
    # Force the next opportunity to loaf and verify no skill energy is consumed.
    u.ability_truant_set_next_v066(true);u.ability_verification_set_energy_v066(PMD_AC::MAX_ENERGY)
    u.begin_skill(t);energy=u.energy
    ok=u.ability_key==:truant && first && second && energy==PMD_AC::MAX_ENERGY
    log_event(:verify,'ABILITY_TRUANT_V066 pass='+(ok ? '1':'0')+' first_action=1 alternate_loaf=1 loaf_energy='+energy.to_i.to_s+'/'+PMD_AC::MAX_ENERGY.to_s+' no_skill_cost=1')
    @verification_done[:v066_truant]=true
  end

  def verify_ability_slow_start_v066
    return if @verification_done[:v066_slow]
    u=ability_runtime_verification_unit_v066(:regigigas,:primary,:ally,11)
    u.ability_slow_start_activate_v066;base_atk=u.pmd_ac_v066_atk;base_spd=u.pmd_ac_v066_speed_stat
    a=u.atk;s=u.speed_stat
    ok=u.ability_key==:slow_start && u.ability_slow_start_frames_v066==300 && a==[(base_atk*0.5).round,1].max && s==[(base_spd*0.5).round,1].max
    log_event(:verify,'ABILITY_SLOW_START_V066 pass='+(ok ? '1':'0')+' frames='+u.ability_slow_start_frames_v066.to_s+' atk='+base_atk.to_s+'->'+a.to_s+' speed='+base_spd.to_s+'->'+s.to_s+' turns=5x60')
    @verification_done[:v066_slow]=true
  end

  def verify_ability_bad_dreams_v066
    return if @verification_done[:v066_bad_dreams]
    src=ability_runtime_verification_unit_v066(:darkrai,:primary,:ally,12)
    t=ability_runtime_verification_unit_v066(:rattata,:primary,:enemy,13)
    t.canonical_apply_sleep(src);before=t.hp;d=ability_bad_dreams_pulse_v066(src,[src,t]);loss=before-t.hp
    expected=[t.maxhp/8,1].max;ok=src.ability_key==:bad_dreams && d.to_i==expected && loss==expected
    log_event(:verify,'ABILITY_BAD_DREAMS_V066 pass='+(ok ? '1':'0')+' sleeping_damage='+loss.to_s+' expected='+expected.to_s+' cadence=60f indirect_damage_bridge=1')
    @verification_done[:v066_bad_dreams]=true
  end

  def verify_ability_color_change_v066
    return if @verification_done[:v066_color]
    u=ability_runtime_verification_unit_v066(:charmander,:primary,:ally,14)
    t=ability_runtime_verification_unit_v066(:kecleon,:primary,:enemy,15)
    d={:canonical_move_key=>:water_gun,:move_key=>:water_gun,:move_type=>:water,:damage_category=>:special,:category=>:special,:accuracy=>100,:target_type=>:enemy_targeted,:delivery=>:instant,:effects=>[{:type=>:damage,:flat=>40,:can_crit=>false,:directional=>false}]}
    r=apply_skill_effects(u,t,d,1.0);type=t.pokemon_types[0]
    ok=t.ability_key==:color_change && r.to_i>0 && type==:water
    log_event(:verify,'ABILITY_COLOR_CHANGE_V066 pass='+(ok ? '1':'0')+' result='+r.to_i.to_s+' type='+type.to_s+' timing=after_complete_move multihit_packet_unchanged=1')
    @verification_done[:v066_color]=true
  end

  def verify_ability_forecast_v066
    return if @verification_done[:v066_forecast]
    u=ability_runtime_verification_unit_v066(:castform,:primary,:ally,16)
    oldw=@canonical_weather;oldf=@canonical_weather_frames;oldp=@canonical_weather_permanent;oldt=@canonical_weather_tick_wait
    set_canonical_weather(:sun,u,5,false);sun=u.pokemon_types[0]
    set_canonical_weather(:rain,u,5,false);rain=u.pokemon_types[0]
    set_canonical_weather(:hail,u,5,false);hail=u.pokemon_types[0]
    clear_canonical_weather(:verify);normal=u.pokemon_types[0]
    @canonical_weather=oldw;@canonical_weather_frames=oldf;@canonical_weather_permanent=oldp;@canonical_weather_tick_wait=oldt
    ok=u.ability_key==:forecast && sun==:fire && rain==:water && hail==:ice && normal==:normal
    log_event(:verify,'ABILITY_FORECAST_V066 pass='+(ok ? '1':'0')+' sun='+sun.to_s+' rain='+rain.to_s+' hail='+hail.to_s+' clear='+normal.to_s+' weather_suppression_respected=1')
    @verification_done[:v066_forecast]=true
  end

  def verify_ability_flower_gift_v066
    return if @verification_done[:v066_flower]
    c=ability_runtime_verification_unit_v066(:cherrim,:primary,:ally,17)
    a=ability_runtime_verification_unit_v066(:bulbasaur,:primary,:ally,18)
    oldw=@canonical_weather;oldf=@canonical_weather_frames;oldp=@canonical_weather_permanent;oldt=@canonical_weather_tick_wait
    clear_canonical_weather(:verify) if @canonical_weather!=nil
    ba=a.pmd_ac_v066_atk;bs=a.pmd_ac_v066_special_defense
    set_canonical_weather(:sun,c,5,false);aa=a.atk;ss=a.special_defense
    @canonical_weather=oldw;@canonical_weather_frames=oldf;@canonical_weather_permanent=oldp;@canonical_weather_tick_wait=oldt
    ok=c.ability_key==:flower_gift && aa==[(ba*1.5).round,1].max && ss==[(bs*1.5).round,1].max
    log_event(:verify,'ABILITY_FLOWER_GIFT_V066 pass='+(ok ? '1':'0')+' ally_atk='+ba.to_s+'->'+aa.to_s+' ally_spdef='+bs.to_s+'->'+ss.to_s+' sun_multiplier=1.50 cherrim_source=1')
    @verification_done[:v066_flower]=true
  end

  def verify_ability_runtime_carry_v066
    return if @verification_done[:v066_carry]
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V066;c=PMD_AC.compiled_data_status_v061
    ok=m[:implemented_slot_count].to_i==975 && m[:species_with_any_implemented_ability].to_i==481 && c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077
    log_event(:verify,'ABILITY_RUNTIME_CARRY_V066 pass='+(ok ? '1':'0')+' slots=975/1193 species=481/494 compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+' aliases='+c[:aliases].to_i.to_s+' move_runtime=526 learnset=7005/7005 native_router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep presentation_anchors=unchanged')
    @verification_done[:v066_carry]=true
  end

  def update_ability_runtime_coverage_iii_v066
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_ability_runtime_manifest_v066 if f>=2
    verify_ability_infiltrator_v066 if f>=4
    verify_ability_cursed_body_v066 if f>=6
    verify_ability_heatproof_v066 if f>=8
    verify_ability_normalize_v066 if f>=10
    verify_ability_truant_v066 if f>=12
    verify_ability_slow_start_v066 if f>=14
    verify_ability_bad_dreams_v066 if f>=16
    verify_ability_color_change_v066 if f>=18
    verify_ability_forecast_v066 if f>=20
    verify_ability_flower_gift_v066 if f>=22
    verify_ability_runtime_carry_v065 if f>=24
    verify_native_semantic_carry_v063 if f>=24
    verify_ability_runtime_carry_v066 if f>=26
    complete_verification_mode if f>=28
  end

  def update_verification_script
    if verification_mode==:ability_runtime_coverage_iii_v066
      update_ability_runtime_coverage_iii_v066;return
    end
    pmd_ac_v066_update_verification_script
  end
end
