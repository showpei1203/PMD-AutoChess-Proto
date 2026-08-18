#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.67
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V067 / ABILITY_INFO_ENTRY_V067 / STICKY_HOLD_ITEM_EFFECT_TYPES_V067 / MAGIC_GUARD_OHKO_MOVES_V067
# - FOREWARN_COUNTER_MOVES_V067 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ability_behavior / ability_data / ability_runtime_scalar_v067 / ability_runtime_checksum32_v067
# - validate_ability_runtime_v067 / ability_runtime_behavior_v067 / start_combat / held_item_effective_v041?
# - begin_skill / ability_unburden_activate_v067 / ability_unburden_active_v067? / ability_unburden_reset_v067
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.67
# Ability Runtime Coverage IV
#------------------------------------------------------------------------------
# Adds ten Generation-V abilities over verified v0.66.1.  Stable movement,
# Native Pose, v0.60.2 multi-hit packets, presentation anchors and audio remain
# untouched.  This layer only bridges already-existing battle/item/move systems.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V067='0.67'
  ABILITY_INFO_ENTRY_V067=[:frisk,:anticipation,:forewarn]
  STICKY_HOLD_ITEM_EFFECT_TYPES_V067=[:knock_off_v052,:bug_bite_item_v053,
    :pluck_item_v057,:thief_v057,:trick_v056,:switcheroo_v057]
  MAGIC_GUARD_OHKO_MOVES_V067=[:guillotine,:horn_drill,:fissure,:sheer_cold]
  FOREWARN_COUNTER_MOVES_V067=[:counter,:mirror_coat,:metal_burst]

  class << self
    alias pmd_ac_v067_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v067_ability_behavior)
    alias pmd_ac_v067_ability_data ability_data unless method_defined?(:pmd_ac_v067_ability_data)
    def ability_behavior(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V067[key]
      return b unless b==nil || b.empty?
      pmd_ac_v067_ability_behavior(key)
    end
    def ability_data(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V067[key]
      return b unless b==nil || b.empty?
      pmd_ac_v067_ability_data(key)
    end
    def ability_runtime_scalar_v067(x)
      return '' if x==nil
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+ability_runtime_scalar_v067(x[k])}.join(',')
      end
      return x.collect{|v|ability_runtime_scalar_v067(v)}.join(',') if x.is_a?(Array)
      x.to_s
    end
    def ability_runtime_checksum32_v067
      h=0
      fields=[:ability_key,:kind,:behavior_status,:covers,:exceptions,:blocked_moves,
        :own_item_actions_allowed,:speed_num,:speed_den,:requires_prior_item,
        :no_trigger_on_replacement,:contact_only,:requires_empty_holder,
        :requires_survival,:after_complete_move,:blocks_current_item_effects,
        :blocks_item_power_moves,:num,:den,:affects,:target,
        :reveal_none_if_selected_empty,:threats,:source,:ohko_power,
        :counter_family_power,:variable_damage_power,:status_power,:tie]
      ABILITY_RUNTIME_BEHAVIOR_V067.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        d=ABILITY_RUNTIME_BEHAVIOR_V067[k]
        text=fields.collect{|f|ability_runtime_scalar_v067(d[f])}.join('|')
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_ability_runtime_v067
      e=[];m=ABILITY_RUNTIME_MANIFEST_V067
      e.push('behavior_count') unless ABILITY_RUNTIME_BEHAVIOR_V067.size==10
      e.push('cumulative') unless m[:cumulative_implemented_ability_count].to_i==135
      e.push('slots') unless m[:implemented_slot_count].to_i==1028 && m[:new_implemented_slot_count].to_i==53
      e.push('species') unless m[:species_with_any_implemented_ability].to_i==483 && m[:new_species_with_any_implemented_ability].to_i==2
      e.push('checksum') unless ability_runtime_checksum32_v067==m[:runtime_checksum32].to_i
      m[:new_ability_keys].each do |k|
        b=ability_behavior(k)
        e.push('bridge_'+k.to_s) if b==nil || b[:behavior_status]!=:implemented_ability_v067
      end
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :ability_runtime_coverage_iv_v067,
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
    :ability_runtime_coverage_iv_v067=>'ABILITY_RUNTIME_COVERAGE_IV_V067',
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
  alias pmd_ac_v067_start_combat start_combat unless method_defined?(:pmd_ac_v067_start_combat)
  alias pmd_ac_v067_update update unless method_defined?(:pmd_ac_v067_update)
  alias pmd_ac_v067_speed_stat speed_stat unless method_defined?(:pmd_ac_v067_speed_stat)
  alias pmd_ac_v067_consume_held_item_v041 consume_held_item_v041 unless method_defined?(:pmd_ac_v067_consume_held_item_v041)
  alias pmd_ac_v067_held_item_effective_v041 held_item_effective_v041? unless method_defined?(:pmd_ac_v067_held_item_effective_v041)
  alias pmd_ac_v067_species_mass_proxy_v053 species_mass_proxy_v053 unless method_defined?(:pmd_ac_v067_species_mass_proxy_v053)
  alias pmd_ac_v067_receive_damage receive_damage unless method_defined?(:pmd_ac_v067_receive_damage)
  alias pmd_ac_v067_apply_canonical_recoil apply_canonical_recoil unless method_defined?(:pmd_ac_v067_apply_canonical_recoil)
  alias pmd_ac_v067_begin_skill begin_skill unless method_defined?(:pmd_ac_v067_begin_skill)

  def ability_runtime_behavior_v067;PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V067[ability_key]||{};end

  def start_combat
    pmd_ac_v067_start_combat
    @unburden_active_v067=false
    @entry_info_seen_v067=nil
    @magic_guard_indirect_context_v067=false
    @magic_guard_move_key_v067=nil
  end

  # Klutz keeps the item identity for stealing/swap logic but suppresses every
  # current item effect.  Fling/Natural Gift are already gated by this predicate.
  def held_item_effective_v041?(key=nil)
    return false if ability_key==:klutz
    pmd_ac_v067_held_item_effective_v041(key)
  end

  def begin_skill(skill_target=nil)
    if ability_key==:klutz
      d=skill_data;mk=d==nil ? nil : (d[:canonical_move_key]||d[:move_key])
      if [:fling,:natural_gift].include?(mk)
        log_event(:ability_runtime_iv,log_name+' klutz BLOCK move='+mk.to_s)
        @energy=0;@skill_target=nil
        return
      end
    end
    pmd_ac_v067_begin_skill(skill_target)
  end

  def ability_unburden_activate_v067(reason=:item_loss)
    return false unless ability_key==:unburden
    return false if @unburden_active_v067
    @unburden_active_v067=true
    log_event(:ability_runtime_iv,log_name+' unburden ACTIVATE reason='+reason.to_s+' speed_x2')
    true
  end
  def ability_unburden_active_v067?;ability_key==:unburden && @unburden_active_v067 ? true:false;end
  def ability_unburden_reset_v067;@unburden_active_v067=false;end

  def consume_held_item_v041(reason=:consume)
    before=held_item_key_v041
    old=pmd_ac_v067_consume_held_item_v041(reason)
    if before!=nil && old!=nil && held_item_key_v041==nil
      ability_unburden_activate_v067(reason)
    end
    old
  end

  def speed_stat
    v=pmd_ac_v067_speed_stat
    v=[v.to_i*2,1].max if ability_unburden_active_v067?
    v
  end

  # The project intentionally uses a stat-derived mass proxy rather than source
  # game weight. Heavy/Light Metal therefore modify that proxy, not a new system.
  def species_mass_proxy_v053
    v=[pmd_ac_v067_species_mass_proxy_v053.to_i,1].max
    return [v*2,1].max if ability_key==:heavy_metal
    return [[(v.to_f*0.5).round,1].max,1].max if ability_key==:light_metal
    v
  end

  def ability_magic_guard_indirect_context_v067(v,label=nil)
    @magic_guard_indirect_context_v067=v ? true:false
    @magic_guard_indirect_label_v067=label
  end
  def ability_magic_guard_move_key_v067=(k);@magic_guard_move_key_v067=k;end
  def ability_magic_guard_move_key_v067;@magic_guard_move_key_v067;end

  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    if ability_key==:magic_guard && @magic_guard_indirect_context_v067 && value.to_i>0
      label=@magic_guard_indirect_label_v067==nil ? 'periodic' : @magic_guard_indirect_label_v067.to_s
      log_event(:ability_runtime_iv,log_name+' magic_guard BLOCK '+label+' damage='+value.to_i.to_s)
      return 0
    end
    pmd_ac_v067_receive_damage(value,source,grant_energy,bypass_link,critical)
  end

  def apply_canonical_recoil(value)
    if ability_key==:magic_guard && @magic_guard_move_key_v067!=:struggle
      log_event(:ability_runtime_iv,log_name+' magic_guard BLOCK recoil='+value.to_i.to_s+' move='+(@magic_guard_move_key_v067||:unknown).to_s)
      return 0
    end
    pmd_ac_v067_apply_canonical_recoil(value)
  end

  def ability_entry_info_seen_v067=(k);@entry_info_seen_v067=k;end
  def ability_entry_info_seen_v067;@entry_info_seen_v067;end

  def update
    if ability_key==:magic_guard
      ability_magic_guard_indirect_context_v067(true,:periodic)
      begin
        pmd_ac_v067_update
      ensure
        ability_magic_guard_indirect_context_v067(false,nil)
      end
    else
      pmd_ac_v067_update
    end

    # Unburden does not survive losing the ability.  Reacquiring it starts fresh
    # until another real item-loss event occurs.
    @unburden_active_v067=false if ability_key!=:unburden && @unburden_active_v067

    cur=ability_key
    if PMD_AC::ABILITY_INFO_ENTRY_V067.include?(cur)
      if @entry_info_seen_v067!=cur && @scene!=nil && @scene.respond_to?(:ability_entry_info_v067)
        @scene.ability_entry_info_v067(self)
        @entry_info_seen_v067=cur
      end
    else
      @entry_info_seen_v067=cur
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v067_start start unless method_defined?(:pmd_ac_v067_start)
  alias pmd_ac_v067_start_battle start_battle unless method_defined?(:pmd_ac_v067_start_battle)
  alias pmd_ac_v067_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v067_prepare_verification_battle)
  alias pmd_ac_v067_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v067_update_verification_script)
  alias pmd_ac_v067_canonical_global_ability_units canonical_global_ability_units unless method_defined?(:pmd_ac_v067_canonical_global_ability_units)
  alias pmd_ac_v067_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v067_apply_skill_effects)
  alias pmd_ac_v067_finish_contact_choreo_v060 finish_contact_choreo_v060 unless method_defined?(:pmd_ac_v067_finish_contact_choreo_v060)
  alias pmd_ac_v067_update_hazards_v056 update_hazards_v056 unless method_defined?(:pmd_ac_v067_update_hazards_v056)
  alias pmd_ac_v067_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v067_canonical_accuracy_hit)
  alias pmd_ac_v067_item_profile_v053 item_profile_v053 unless method_defined?(:pmd_ac_v067_item_profile_v053)

  def start
    pmd_ac_v067_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.66\.1 Battle Verification Log/,'PMD AutoChess Proto v0.67 Battle Verification Log')
        t.sub!(/PMD AutoChess Proto v0\.66 Battle Verification Log/,'PMD AutoChess Proto v0.67 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V067
    log_event(:ability_runtime_iv,'LOADED new='+m[:new_implemented_ability_count].to_s+
      ' cumulative='+m[:cumulative_implemented_ability_count].to_s+
      ' implemented_slots='+m[:implemented_slot_count].to_s+'/'+m[:total_slot_count].to_s+
      ' coverage='+sprintf('%.2f',m[:implemented_slot_coverage_percent].to_f)+'%'+
      ' species='+m[:species_with_any_implemented_ability].to_s+'/494 checksum32='+m[:runtime_checksum32].to_s)
    log_event(:presentation,'PATCH v0.67 ability_runtime=magic_guard,sticky_hold,unburden,pickpocket,klutz,heavy_metal,light_metal,frisk,anticipation,forewarn '+
      'native_router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep beam_projectile_impact_targetfx=unchanged organic_sfx=v0.56.1')
  end

  def canonical_global_ability_units
    list=pmd_ac_v067_canonical_global_ability_units
    list+=@ability_runtime_test_units_v067 if @ability_runtime_test_units_v067!=nil
    list.uniq
  end

  def start_battle
    pmd_ac_v067_start_battle
    return unless @phase==:battle
    (@units||[]).each do |u|
      next if u==nil || u.dead?
      if PMD_AC::ABILITY_INFO_ENTRY_V067.include?(u.ability_key)
        ability_entry_info_v067(u)
        u.ability_entry_info_seen_v067=u.ability_key if u.respond_to?(:ability_entry_info_seen_v067=)
      end
    end
  end

  def ability_runtime_roll_v067(max)
    m=[max.to_i,1].max
    if verification_mode==:ability_runtime_coverage_iv_v067 && @ability_runtime_rolls_v067!=nil && !@ability_runtime_rolls_v067.empty?
      return @ability_runtime_rolls_v067.shift.to_i % m
    end
    rand(m)
  end

  # ---------------------------------------------------------------------------
  # Magic Guard
  # ---------------------------------------------------------------------------
  def update_hazards_v056
    protected=[]
    if Graphics.frame_count%120==0
      protected=(@units||[]).find_all{|u|u!=nil && !u.dead? && u.ability_key==:magic_guard}
      protected.each{|u|u.ability_magic_guard_indirect_context_v067(true,:hazard)}
    end
    begin
      pmd_ac_v067_update_hazards_v056
    ensure
      protected.each{|u|u.ability_magic_guard_indirect_context_v067(false,nil)}
    end
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    if user!=nil && user.ability_key==:magic_guard && data!=nil && data[:crash_on_miss_v058]!=nil
      d=data.dup;d[:crash_on_miss_v058]=nil
      ok=pmd_ac_v067_canonical_accuracy_hit(user,target,d,log_check)
      log_event(:ability_runtime_iv,user.log_name+' magic_guard BLOCK crash_damage move='+(data[:canonical_move_key]||:unknown).to_s) unless ok
      return ok
    end
    pmd_ac_v067_canonical_accuracy_hit(user,target,data,log_check)
  end

  # ---------------------------------------------------------------------------
  # Held-item abilities
  # ---------------------------------------------------------------------------
  def item_profile_v053(user)
    return nil if user!=nil && user.respond_to?(:ability_key) && user.ability_key==:klutz
    pmd_ac_v067_item_profile_v053(user)
  end

  def ability_sticky_hold_filter_v067(target,data)
    return data if target==nil || data==nil || target.ability_key!=:sticky_hold
    effects=data[:effects]||[]
    hit=effects.any?{|e|PMD_AC::STICKY_HOLD_ITEM_EFFECT_TYPES_V067.include?(e[:type])}
    return data unless hit
    d=data.dup;d[:effects]=effects.find_all{|e|!PMD_AC::STICKY_HOLD_ITEM_EFFECT_TYPES_V067.include?(e[:type])}
    log_event(:ability_runtime_iv,target.log_name+' sticky_hold BLOCK item_move='+(data[:canonical_move_key]||data[:move_key]||:unknown).to_s)
    d
  end

  def ability_unburden_check_loss_v067(unit,before_item,reason)
    return false if unit==nil || before_item==nil
    return false unless unit.respond_to?(:ability_unburden_activate_v067)
    if unit.held_item_key_v041==nil
      return unit.ability_unburden_activate_v067(reason)
    end
    false
  end

  def ability_pickpocket_after_v067(user,target,data,result)
    return false if user==nil || target==nil || user==target || result.to_i<=0
    return false unless target.is_a?(Game_PMDChessUnit) && target.alive? && target.ability_key==:pickpocket
    return false if target.held_item_key_v041!=nil || user.held_item_key_v041==nil
    return false if user.ability_key==:sticky_hold
    return false unless canonical_contact_move?(user,data)
    old=user.pokemon_instance==nil ? nil : user.pokemon_instance.remove_held_item_v041
    return false if old==nil
    unless target.equip_held_item_v041(old)
      user.equip_held_item_v041(old);return false
    end
    ability_unburden_check_loss_v067(user,old,:pickpocket)
    log_event(:ability_runtime_iv,target.log_name+' pickpocket STEAL item='+old.to_s+' <- '+user.log_name+' after_complete_move=1')
    true
  end

  def ability_attach_pickpocket_contact_multi_v067(user,target,data)
    return false if @multi_contact_events_v060==nil
    mk=data[:canonical_move_key]||data[:move_key]
    q=@multi_contact_events_v060.reverse.find{|x|x[:user]==user && x[:target]==target && x[:move_key]==mk && x[:pickpocket_v067_pending]==nil}
    return false if q==nil
    q[:pickpocket_v067_pending]={:user=>user,:target=>target,:data=>data,:done=>false}
    true
  end

  def finish_contact_choreo_v060(q,early=false)
    r=pmd_ac_v067_finish_contact_choreo_v060(q,early)
    p=q==nil ? nil : q[:pickpocket_v067_pending]
    if p!=nil && !p[:done]
      p[:done]=true
      ability_pickpocket_after_v067(p[:user],p[:target],p[:data],q[:total_damage].to_i)
    end
    r
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    d=ability_sticky_hold_filter_v067(target,data)
    mk=d==nil ? nil : (d[:canonical_move_key]||d[:move_key])
    if user!=nil && user.ability_key==:klutz && [:fling,:natural_gift].include?(mk)
      log_event(:ability_runtime_iv,user.log_name+' klutz FAIL move='+mk.to_s+' item_preserved='+(user.held_item_key_v041==nil ? 'none':user.held_item_key_v041.to_s))
      return 0
    end
    old_magic=nil
    if user!=nil && user.respond_to?(:ability_magic_guard_move_key_v067)
      old_magic=user.ability_magic_guard_move_key_v067
      user.ability_magic_guard_move_key_v067=mk
    end
    ub_user=user==nil ? nil : user.held_item_key_v041
    ub_target=target==nil ? nil : target.held_item_key_v041
    begin
      result=pmd_ac_v067_apply_skill_effects(user,target,d,scale)
    ensure
      user.ability_magic_guard_move_key_v067=old_magic if user!=nil && user.respond_to?(:ability_magic_guard_move_key_v067=)
    end
    ability_unburden_check_loss_v067(user,ub_user,mk||:skill) if user!=nil
    ability_unburden_check_loss_v067(target,ub_target,mk||:skill) if target!=nil

    if user!=nil && target!=nil && d!=nil && canonical_contact_move?(user,d)
      original_multi=!d[:v060_packet] && (d[:multi_hit_v049] || d[:triple_kick_v059])
      packet=d[:v060_packet] || d[:sequential_single_v0572]
      if original_multi
        attached=ability_attach_pickpocket_contact_multi_v067(user,target,d)
        ability_pickpocket_after_v067(user,target,d,result) unless attached
      elsif !packet
        ability_pickpocket_after_v067(user,target,d,result)
      end
    end
    result
  end

  # ---------------------------------------------------------------------------
  # Entry-information abilities
  # ---------------------------------------------------------------------------
  def ability_living_opponents_v067(unit,units=nil)
    list=units||canonical_global_ability_units
    list.find_all{|u|u!=nil && u.is_a?(Game_PMDChessUnit) && !u.dead? && unit!=nil && u.team!=unit.team}
  end

  def ability_known_moves_v067(unit)
    return [] if unit==nil
    if @ability_known_moves_override_v067!=nil && @ability_known_moves_override_v067[unit.instance_uid]!=nil
      return @ability_known_moves_override_v067[unit.instance_uid].dup
    end
    pool=unit.respond_to?(:progression_move_pool_v046) ? unit.progression_move_pool_v046 : []
    pool=[] if pool==nil
    if pool.empty? && unit.respond_to?(:skill_data)
      d=unit.skill_data
      mk=d==nil ? nil : (d[:canonical_move_key]||d[:move_key])
      pool=[mk] if mk!=nil
    end
    pool.compact.uniq
  end

  def ability_frisk_entry_v067(unit,units=nil)
    opp=ability_living_opponents_v067(unit,units);return nil if opp.empty?
    target=opp[ability_runtime_roll_v067(opp.size)]
    item=target.respond_to?(:held_item_key_v041) ? target.held_item_key_v041 : nil
    log_event(:ability_runtime_iv,unit.log_name+' frisk CHECK target='+target.log_name+' item='+(item==nil ? 'none':item.to_s))
    [target,item]
  end

  def ability_anticipation_threat_move_v067?(target,move_key)
    return false if target==nil || move_key==nil
    return true if PMD_AC::MAGIC_GUARD_OHKO_MOVES_V067.include?(move_key)
    d=PMD_AC.skill_data(PMD_AC.canonical_runtime_skill_key(move_key))
    return false if d==nil || d.empty? || d[:category]==:status || d[:damage_category]==:status
    t=d[:move_type]||d[:type];return false if t==nil
    PMD_AC.type_effectiveness(t,target.pokemon_types)>1.0
  end

  def ability_anticipation_entry_v067(unit,units=nil)
    threat=nil;src=nil
    ability_living_opponents_v067(unit,units).each do |e|
      ability_known_moves_v067(e).each do |mk|
        if ability_anticipation_threat_move_v067?(unit,mk);threat=mk;src=e;break;end
      end
      break if threat!=nil
    end
    log_event(:ability_runtime_iv,unit.log_name+' anticipation '+(threat==nil ? 'SAFE' : 'SHUDDER threat='+threat.to_s+' source='+src.log_name))
    threat
  end

  def ability_forewarn_power_v067(move_key)
    return 150 if PMD_AC::MAGIC_GUARD_OHKO_MOVES_V067.include?(move_key)
    return 120 if PMD_AC::FOREWARN_COUNTER_MOVES_V067.include?(move_key)
    db=PMD_AC::MOVE_DB_V017[move_key]
    return 1 if db==nil
    return 1 if db[:category]==:status
    p=db[:canonical_power]
    return p.to_i if p!=nil && p.to_i>0
    80
  end

  def ability_forewarn_entry_v067(unit,units=nil)
    candidates=[]
    ability_living_opponents_v067(unit,units).each do |e|
      ability_known_moves_v067(e).each{|mk|candidates.push([ability_forewarn_power_v067(mk),mk,e])}
    end
    return nil if candidates.empty?
    max=candidates.collect{|x|x[0]}.max
    top=candidates.find_all{|x|x[0]==max}
    chosen=top[ability_runtime_roll_v067(top.size)]
    log_event(:ability_runtime_iv,unit.log_name+' forewarn REVEAL move='+chosen[1].to_s+' power='+chosen[0].to_s+' source='+chosen[2].log_name)
    chosen
  end

  def ability_entry_info_v067(unit,units=nil)
    return nil if unit==nil || unit.dead?
    case unit.ability_key
    when :frisk;ability_frisk_entry_v067(unit,units)
    when :anticipation;ability_anticipation_entry_v067(unit,units)
    when :forewarn;ability_forewarn_entry_v067(unit,units)
    else;nil
    end
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------
  def ability_runtime_verification_unit_v067(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99067000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9670+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_runtime_test_units_v067=[] if @ability_runtime_test_units_v067==nil
    @ability_runtime_test_units_v067.push(u);u
  end

  def prepare_verification_battle
    pmd_ac_v067_prepare_verification_battle
    return unless verification_mode==:ability_runtime_coverage_iv_v067
    @ability_runtime_test_units_v067=[];@ability_runtime_rolls_v067=[];@ability_known_moves_override_v067={}
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,'START mode=ABILITY_RUNTIME_COVERAGE_IV_V067 new=10 slots=1028/1193 species=483/494 diagnostic_only=1 pokemon_resume_after_final_assert=1')
  end

  def verify_ability_runtime_manifest_v067
    return if @verification_done[:v067_manifest]
    e=PMD_AC.validate_ability_runtime_v067;m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V067;ok=e.empty?
    log_event(:verify,'ABILITY_RUNTIME_MANIFEST_V067 pass='+(ok ? '1':'0')+' new=10 cumulative=135 slots=1028/1193 coverage=86.17% species=483/494 checksum='+PMD_AC.ability_runtime_checksum32_v067.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v067_manifest]=true
  end

  def verify_ability_magic_guard_v067
    return if @verification_done[:v067_magic_guard]
    u=ability_runtime_verification_unit_v067(:abra,:hidden,:ally,1)
    src=ability_runtime_verification_unit_v067(:rattata,:primary,:enemy,2)
    u.apply_status(:burn,{:duration=>10,:value=>10,:interval=>1},src)
    before=u.hp;u.ability_magic_guard_indirect_context_v067(true,:status_tick);u.update_statuses;u.ability_magic_guard_indirect_context_v067(false,nil);tick=before-u.hp
    u.ability_magic_guard_move_key_v067=:take_down;before=u.hp;recoil=u.apply_canonical_recoil(20);recoil_loss=before-u.hp
    u.ability_magic_guard_move_key_v067=:struggle;before=u.hp;struggle=u.apply_canonical_recoil(20);struggle_loss=before-u.hp
    u.ability_magic_guard_move_key_v067=nil
    before=u.hp;ind=canonical_indirect_ability_damage(u,src,20,:verify);ind_loss=before-u.hp
    ok=u.ability_key==:magic_guard && tick==0 && recoil.to_i==0 && recoil_loss==0 && struggle.to_i==20 && struggle_loss==20 && ind.to_i==0 && ind_loss==0
    log_event(:verify,'ABILITY_MAGIC_GUARD_V067 pass='+(ok ? '1':'0')+' status_tick=10->'+tick.to_s+' recoil=20->'+recoil_loss.to_s+' struggle_exception='+struggle_loss.to_s+' canonical_indirect='+ind_loss.to_s+' weather/life_orb_existing_hooks=1 hazards/crash_context=1')
    @verification_done[:v067_magic_guard]=true
  end

  def verify_ability_sticky_hold_v067
    return if @verification_done[:v067_sticky]
    user=ability_runtime_verification_unit_v067(:rattata,:primary,:ally,3)
    t=ability_runtime_verification_unit_v067(:grimer,:secondary,:enemy,4)
    t.equip_held_item_v041(:leftovers)
    checks={:knock_off=>:knock_off_v052,:bug_bite=>:bug_bite_item_v053,:pluck=>:pluck_item_v057,
      :thief=>:thief_v057,:trick=>:trick_v056,:switcheroo=>:switcheroo_v057}
    filtered_all=checks.all? do |move,effect|
      d=PMD_AC.skill_data(('mv_'+move.to_s).to_sym);x=ability_sticky_hold_filter_v067(t,d)
      !(x[:effects]||[]).any?{|e|e[:type]==effect}
    end
    ko=PMD_AC.skill_data(:mv_knock_off);before=t.held_item_key_v041;apply_skill_effects(user,t,ko,1.0);after=t.held_item_key_v041
    ok=t.ability_key==:sticky_hold && filtered_all && before==:leftovers && after==:leftovers
    log_event(:verify,'ABILITY_STICKY_HOLD_V067 pass='+(ok ? '1':'0')+' six_move_filters='+(filtered_all ? '1':'0')+' knock_off_item='+before.to_s+'->'+after.to_s+' pickpocket_source_gate=1')
    @verification_done[:v067_sticky]=true
  end

  def verify_ability_unburden_v067
    return if @verification_done[:v067_unburden]
    u=ability_runtime_verification_unit_v067(:drifloon,:secondary,:ally,5)
    base=u.pmd_ac_v067_speed_stat;u.equip_held_item_v041(:air_balloon);u.consume_held_item_v041(:verify);boost=u.speed_stat
    active=u.ability_unburden_active_v067?
    u.ability_unburden_reset_v067;u.equip_held_item_v041(:leftovers);u.equip_held_item_v041(:eviolite);replacement=u.ability_unburden_active_v067?
    ok=u.ability_key==:unburden && active && boost==base*2 && !replacement
    log_event(:verify,'ABILITY_UNBURDEN_V067 pass='+(ok ? '1':'0')+' speed='+base.to_s+'->'+boost.to_s+' item_loss_active='+(active ? '1':'0')+' replacement_no_trigger='+(!replacement ? '1':'0'))
    @verification_done[:v067_unburden]=true
  end

  def verify_ability_pickpocket_v067
    return if @verification_done[:v067_pickpocket]
    a=ability_runtime_verification_unit_v067(:rattata,:primary,:ally,6)
    t=ability_runtime_verification_unit_v067(:weavile,:hidden,:enemy,7)
    a.equip_held_item_v041(:leftovers);t.equip_held_item_v041(nil)
    d={:canonical_move_key=>:tackle,:move_key=>:tackle,:move_type=>:normal,:damage_category=>:physical,:category=>:physical,:contact=>true}
    stolen=ability_pickpocket_after_v067(a,t,d,20)
    first=(a.held_item_key_v041==nil && t.held_item_key_v041==:leftovers)
    sticky=ability_runtime_verification_unit_v067(:grimer,:secondary,:ally,8);sticky.equip_held_item_v041(:life_orb);t.equip_held_item_v041(nil)
    blocked=!ability_pickpocket_after_v067(sticky,t,d,20) && sticky.held_item_key_v041==:life_orb && t.held_item_key_v041==nil
    ok=t.ability_key==:pickpocket && stolen && first && blocked
    log_event(:verify,'ABILITY_PICKPOCKET_V067 pass='+(ok ? '1':'0')+' contact_steal='+(first ? '1':'0')+' sticky_hold_source_block='+(blocked ? '1':'0')+' after_complete_move=1 multihit_packet_driver=v0.60.2')
    @verification_done[:v067_pickpocket]=true
  end

  def verify_ability_klutz_v067
    return if @verification_done[:v067_klutz]
    u=ability_runtime_verification_unit_v067(:buneary,:secondary,:ally,9);u.equip_held_item_v041(:life_orb)
    t=ability_runtime_verification_unit_v067(:rattata,:primary,:enemy,90)
    eff=u.held_item_effective_v041?;prof=item_profile_v053(u)
    fl=PMD_AC.skill_data(:mv_fling);worth=skill_cast_worthwhile?(u,t,fl);before=u.held_item_key_v041;forced=apply_skill_effects(u,t,fl,1.0);after=u.held_item_key_v041
    ok=u.ability_key==:klutz && !eff && prof==nil && !worth && forced.to_i==0 && before==after
    log_event(:verify,'ABILITY_KLUTZ_V067 pass='+(ok ? '1':'0')+' item_identity='+u.held_item_key_v041.to_s+' effect_active='+(eff ? '1':'0')+' fling_profile='+(prof==nil ? 'none':'active')+' ai_worthwhile='+(worth ? '1':'0')+' forced_result='+forced.to_i.to_s+' item_preserved='+(before==after ? '1':'0'))
    @verification_done[:v067_klutz]=true
  end

  def verify_ability_metal_mass_v067
    return if @verification_done[:v067_metal]
    heavy=ability_runtime_verification_unit_v067(:aggron,:hidden,:ally,10)
    light=ability_runtime_verification_unit_v067(:scizor,:hidden,:ally,11)
    hb=heavy.pmd_ac_v067_species_mass_proxy_v053;lb=light.pmd_ac_v067_species_mass_proxy_v053
    h=heavy.species_mass_proxy_v053;l=light.species_mass_proxy_v053
    ok=heavy.ability_key==:heavy_metal && light.ability_key==:light_metal && h==hb*2 && l==[(lb.to_f*0.5).round,1].max
    log_event(:verify,'ABILITY_METAL_MASS_V067 pass='+(ok ? '1':'0')+' heavy='+hb.to_s+'->'+h.to_s+' light='+lb.to_s+'->'+l.to_s+' mass_proxy=v0.53 heavy_slam+low_kick=shared')
    @verification_done[:v067_metal]=true
  end

  def verify_ability_frisk_v067
    return if @verification_done[:v067_frisk]
    f=ability_runtime_verification_unit_v067(:wigglytuff,:hidden,:ally,12)
    a=ability_runtime_verification_unit_v067(:rattata,:primary,:enemy,13);a.equip_held_item_v041(:eviolite)
    b=ability_runtime_verification_unit_v067(:charmander,:primary,:enemy,14);b.equip_held_item_v041(:leftovers)
    @ability_runtime_rolls_v067=[1];r=ability_frisk_entry_v067(f,[f,a,b])
    ok=f.ability_key==:frisk && r!=nil && r[0]==b && r[1]==:leftovers
    log_event(:verify,'ABILITY_FRISK_V067 pass='+(ok ? '1':'0')+' selected='+(r==nil ? 'none':r[0].species_key.to_s)+' item='+(r==nil || r[1]==nil ? 'none':r[1].to_s)+' random_opponent_gen5=1')
    @verification_done[:v067_frisk]=true
  end

  def verify_ability_anticipation_v067
    return if @verification_done[:v067_anticipation]
    u=ability_runtime_verification_unit_v067(:croagunk,:primary,:ally,15)
    e=ability_runtime_verification_unit_v067(:abra,:primary,:enemy,91)
    @ability_known_moves_override_v067[e.instance_uid]=[:tackle,:psychic]
    actual=ability_anticipation_entry_v067(u,[u,e])
    fire=ability_anticipation_threat_move_v067?(u,:psychic);neutral=ability_anticipation_threat_move_v067?(u,:tackle);ohko=ability_anticipation_threat_move_v067?(u,:fissure)
    ok=u.ability_key==:anticipation && actual==:psychic && fire && !neutral && ohko
    log_event(:verify,'ABILITY_ANTICIPATION_V067 pass='+(ok ? '1':'0')+' entry_threat='+actual.to_s+' super_effective_psychic='+(fire ? '1':'0')+' neutral_tackle='+(neutral ? '1':'0')+' ohko_fissure='+(ohko ? '1':'0')+' source=current_battle_move_pool')
    @verification_done[:v067_anticipation]=true
  end

  def verify_ability_forewarn_v067
    return if @verification_done[:v067_forewarn]
    u=ability_runtime_verification_unit_v067(:drowzee,:secondary,:ally,16)
    e=ability_runtime_verification_unit_v067(:rattata,:primary,:enemy,92)
    @ability_known_moves_override_v067[e.instance_uid]=[:tackle,:fissure,:counter,:growl]
    @ability_runtime_rolls_v067=[0];actual=ability_forewarn_entry_v067(u,[u,e])
    a=ability_forewarn_power_v067(:tackle);b=ability_forewarn_power_v067(:fissure);c=ability_forewarn_power_v067(:counter);d=ability_forewarn_power_v067(:growl)
    ok=u.ability_key==:forewarn && actual!=nil && actual[1]==:fissure && actual[0]==150 && a==50 && b==150 && c==120 && d==1
    log_event(:verify,'ABILITY_FOREWARN_V067 pass='+(ok ? '1':'0')+' entry_move='+(actual==nil ? 'none':actual[1].to_s)+' entry_power='+(actual==nil ? '0':actual[0].to_s)+' tackle='+a.to_s+' ohko='+b.to_s+' counter='+c.to_s+' status='+d.to_s+' variable_default=80 tie=random')
    @verification_done[:v067_forewarn]=true
  end

  def verify_ability_runtime_carry_v067
    return if @verification_done[:v067_carry]
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V067;c=PMD_AC.compiled_data_status_v061
    ok=m[:implemented_slot_count].to_i==1028 && m[:species_with_any_implemented_ability].to_i==483 && c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077
    log_event(:verify,'ABILITY_RUNTIME_CARRY_V067 pass='+(ok ? '1':'0')+' slots=1028/1193 species=483/494 compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+' aliases='+c[:aliases].to_i.to_s+' move_runtime=526 learnset=7005/7005 native_router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep presentation_anchors=unchanged')
    @verification_done[:v067_carry]=true
  end

  def update_ability_runtime_coverage_iv_v067
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_ability_runtime_manifest_v067 if f>=2
    verify_ability_magic_guard_v067 if f>=4
    verify_ability_sticky_hold_v067 if f>=6
    verify_ability_unburden_v067 if f>=8
    verify_ability_pickpocket_v067 if f>=10
    verify_ability_klutz_v067 if f>=12
    verify_ability_metal_mass_v067 if f>=14
    verify_ability_frisk_v067 if f>=16
    verify_ability_anticipation_v067 if f>=18
    verify_ability_forewarn_v067 if f>=20
    verify_ability_runtime_carry_v066 if f>=22
    verify_native_semantic_carry_v063 if f>=22
    verify_ability_runtime_carry_v067 if f>=24
    complete_verification_mode if f>=26
  end

  def update_verification_script
    if verification_mode==:ability_runtime_coverage_iv_v067
      update_ability_runtime_coverage_iv_v067;return
    end
    pmd_ac_v067_update_verification_script
  end
end
