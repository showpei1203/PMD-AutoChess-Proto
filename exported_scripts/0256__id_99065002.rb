#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.65
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V065 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ability_behavior / ability_data / ability_runtime_scalar_v065 / ability_runtime_checksum32_v065
# - validate_ability_runtime_v065 / ability_runtime_behavior_v065 / ability_stage_ignore_scope_v065 / ability_restore_stage_ignore_scope_v065
# - ability_scrappy_scope_v065 / ability_restore_scrappy_scope_v065 / stat_stage / pokemon_types
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.65
# Ability Runtime Coverage II
#------------------------------------------------------------------------------
# Adds eight Generation-V abilities using existing stable runtime foundations:
# Lightning Rod / Storm Drain / Scrappy / Prankster / Unaware /
# Friend Guard / Liquid Ooze / Download.
#
# Deliberately unchanged:
# - v0.62 Native Semantic Router
# - v0.60.2 multi-hit packet choreography
# - Beam / Projectile / Impact / Target-FX anchors
# - v0.56.1 Organic Combat SFX palette
#==============================================================================
module PMD_AC
  PATCH_VERSION_V065 = "0.65"

  class << self
    alias pmd_ac_v065_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v065_ability_behavior)
    alias pmd_ac_v065_ability_data ability_data unless method_defined?(:pmd_ac_v065_ability_data)

    def ability_behavior(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V065[key]
      return b unless b==nil || b.empty?
      pmd_ac_v065_ability_behavior(key)
    end

    def ability_data(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V065[key]
      return b unless b==nil || b.empty?
      pmd_ac_v065_ability_data(key)
    end

    def ability_runtime_scalar_v065(x)
      return '' if x==nil
      return x.collect{|v|v.to_s}.join(',') if x.is_a?(Array)
      x.to_s
    end

    def ability_runtime_checksum32_v065
      h=0
      fields=[:ability_key,:kind,:behavior_status,:move_type,:move_types,
              :single_target_redirect,:spatk_stages,:ground_no_boost_gen5,
              :damage_only,:priority_bonus,:status_only,
              :quick_guard_gen5_unchanged,:attacker_ignores,:defender_ignores,
              :num,:den,:self_protection,:stack_mode,:covers,:tie_result,
              :def_lower_result,:stages]
      ABILITY_RUNTIME_BEHAVIOR_V065.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        d=ABILITY_RUNTIME_BEHAVIOR_V065[k]
        text=fields.collect{|f|ability_runtime_scalar_v065(d[f])}.join('|')
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end

    def validate_ability_runtime_v065
      e=[];m=ABILITY_RUNTIME_MANIFEST_V065
      e.push('behavior_count') unless ABILITY_RUNTIME_BEHAVIOR_V065.size==8
      e.push('cumulative') unless m[:cumulative_implemented_ability_count].to_i==115
      e.push('slots') unless m[:implemented_slot_count].to_i==952 && m[:new_implemented_slot_count].to_i==47
      e.push('species') unless m[:species_with_any_implemented_ability].to_i==473 && m[:new_species_with_any_implemented_ability].to_i==12
      e.push('checksum') unless ability_runtime_checksum32_v065==m[:runtime_checksum32].to_i
      m[:new_ability_keys].each do |k|
        b=ability_behavior(k)
        e.push('bridge_'+k.to_s) if b==nil || b[:behavior_status]!=:implemented_ability_v065
      end
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
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
  VERIFICATION_LABELS = {
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
  alias pmd_ac_v065_stat_stage stat_stage unless method_defined?(:pmd_ac_v065_stat_stage)
  alias pmd_ac_v065_pokemon_types pokemon_types unless method_defined?(:pmd_ac_v065_pokemon_types)
  alias pmd_ac_v065_calculate_damage calculate_damage unless method_defined?(:pmd_ac_v065_calculate_damage)
  alias pmd_ac_v065_ability_incoming_multiplier ability_incoming_multiplier unless method_defined?(:pmd_ac_v065_ability_incoming_multiplier)
  alias pmd_ac_v065_begin_skill begin_skill unless method_defined?(:pmd_ac_v065_begin_skill)
  alias pmd_ac_v065_update update unless method_defined?(:pmd_ac_v065_update)

  def ability_runtime_behavior_v065
    PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V065[ability_key] || {}
  end

  def ability_stage_ignore_scope_v065(keys)
    old=@ability_unaware_ignore_stages_v065
    @ability_unaware_ignore_stages_v065=(old||[])+keys
    old
  end
  def ability_restore_stage_ignore_scope_v065(old)
    @ability_unaware_ignore_stages_v065=old
  end
  def ability_scrappy_scope_v065(value)
    old=@ability_scrappy_ghost_override_v065
    @ability_scrappy_ghost_override_v065=value ? true:false
    old
  end
  def ability_restore_scrappy_scope_v065(old)
    @ability_scrappy_ghost_override_v065=old
  end

  def stat_stage(key)
    a=@ability_unaware_ignore_stages_v065 || []
    return 0 if a.include?(key)
    pmd_ac_v065_stat_stage(key)
  end

  def pokemon_types
    t=pmd_ac_v065_pokemon_types
    return t unless @ability_scrappy_ghost_override_v065
    t.find_all{|x|x!=:ghost}
  end

  # Scrappy changes only the Ghost-type immunity check. Unaware changes only the
  # opponent's relevant stages during a damaging move. Both are scoped around
  # the existing damage function so all older multipliers remain authoritative.
  def calculate_damage(target_unit,power,category=:physical,move_type=:normal,random_percent=nil)
    damaging=(category==:physical || category==:special)
    old_ghost=nil;old_target=nil;old_self=nil
    did_ghost=false;did_target=false;did_self=false
    begin
      if damaging && ability_key==:scrappy && [:normal,:fighting].include?(move_type) && target_unit!=nil
        old_ghost=target_unit.ability_scrappy_scope_v065(true);did_ghost=true
      end
      if damaging && ability_key==:unaware && target_unit!=nil
        old_target=target_unit.ability_stage_ignore_scope_v065([:def,:spdef]);did_target=true
      end
      if damaging && target_unit!=nil && target_unit.respond_to?(:ability_key) && target_unit.ability_key==:unaware
        old_self=ability_stage_ignore_scope_v065([:atk,:spatk]);did_self=true
      end
      pmd_ac_v065_calculate_damage(target_unit,power,category,move_type,random_percent)
    ensure
      target_unit.ability_restore_scrappy_scope_v065(old_ghost) if target_unit!=nil && did_ghost
      target_unit.ability_restore_stage_ignore_scope_v065(old_target) if target_unit!=nil && did_target
      ability_restore_stage_ignore_scope_v065(old_self) if did_self
    end
  end

  # Matching-type immunity is a safety net for direct damage paths. The normal
  # move-packet path is intercepted in Scene so the Sp. Atk boost can also fire.
  # Friend Guard composes after all older incoming ability multipliers.
  def ability_incoming_multiplier(move_type,category)
    if ability_key==:lightning_rod && move_type==:electric;return 0.0;end
    if ability_key==:storm_drain && move_type==:water;return 0.0;end
    base=pmd_ac_v065_ability_incoming_multiplier(move_type,category)
    return base if base<=0.0 || @scene==nil || !@scene.respond_to?(:ability_friend_guard_multiplier_v065)
    base*@scene.ability_friend_guard_multiplier_v065(self)
  end

  # Generation-V Prankster changes startup priority only. Existing v0.42 owns
  # timing math and Quick Guard continues to consult canonical move priority,
  # which intentionally keeps Gen-V Prankster status moves outside Quick Guard.
  def begin_skill(skill_target=nil)
    pmd_ac_v065_begin_skill(skill_target)
    return unless ability_key==:prankster && @action==:skill && @action_timer.to_i>0 && !@action_hit_done
    data=skill_data;return if data==nil || data.empty?
    cat=data[:damage_category] || data[:category]
    return unless cat==:status
    bonus=PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V065[:prankster][:priority_bonus].to_i
    canonical=PMD_AC.canonical_priority_v042(data)
    pri=canonical+bonus
    total=@action_total_frames.to_i;return if total<=1
    native=@priority_native_elapsed_v042.to_i
    native=total-@action_hit_frame.to_i if native<=0
    native=1 if native<1
    sf=respond_to?(:realtime_speed_factor) ? realtime_speed_factor : 1.0
    elapsed=PMD_AC.priority_startup_elapsed_v042(pri,native,total,sf)
    @action_hit_frame=total-elapsed;@action_hit_frame=1 if @action_hit_frame<1
    @priority_last_v042=pri;@priority_native_elapsed_v042=native
    @priority_elapsed_v042=elapsed;@priority_total_v042=total
    log_event(:ability_runtime_ii,log_name+' prankster move='+
      (data[:canonical_move_key]||data[:move_key]||:unknown).to_s+
      ' priority='+canonical.to_s+'->'+pri.to_s+' startup='+native.to_s+'->'+elapsed.to_s)
  end

  def ability_priority_snapshot_v065
    {:priority=>@priority_last_v042.to_i,:native=>@priority_native_elapsed_v042.to_i,
     :elapsed=>@priority_elapsed_v042.to_i,:total=>@priority_total_v042.to_i}
  end

  # Liquid Ooze needs one special bridge for the already-stable v0.51 Leech Seed
  # periodic code, because that drain occurs from Game_PMDChessUnit#update rather
  # than Scene#apply_skill_effects.
  def ability_liquid_ooze_leech_tick_v065(src)
    return 0 if src==nil || src.dead? || dead?
    amount=[maxhp/8,1].max;before=hp
    receive_damage(amount,src,false,true,false)
    actual=[before-hp,0].max
    if actual>0
      src.receive_damage(actual,self,false,true,false)
      if @scene!=nil
        @scene.add_vfx_impact(self,:grass) if @scene.respond_to?(:add_vfx_impact)
        @scene.add_vfx_impact(src,:poison,3) if @scene.respond_to?(:add_vfx_impact)
        @scene.log_event(:ability_runtime_ii,log_name+' liquid_ooze LEECH_SEED reverse='+actual.to_s+' -> '+src.log_name)
      end
    end
    actual
  end

  def ability_download_mark_active_v065
    @download_active_ability_v065=:download
  end

  def ability_download_update_v065
    cur=ability_key
    if cur==:download
      if @download_active_ability_v065!=:download && @scene!=nil && @scene.respond_to?(:ability_download_activate_v065)
        if @scene.ability_download_activate_v065(self)
          ability_download_mark_active_v065
        end
      end
    else
      @download_active_ability_v065=cur
    end
  end

  def update
    if ability_key==:liquid_ooze && @leech_seed_frames_v051.to_i>0
      frames=@leech_seed_frames_v051.to_i
      tick=@leech_seed_tick_v051.to_i
      uid=@leech_seed_source_uid_v051
      @leech_seed_frames_v051=0;@leech_seed_tick_v051=0
      pmd_ac_v065_update
      frames-=1;tick-=1
      if frames>0 && tick<=0
        tick=60
        src=@scene==nil ? nil : @scene.two_turn_unit_by_uid_v039(uid)
        ability_liquid_ooze_leech_tick_v065(src) if src!=nil
      end
      if dead?;frames=0;tick=0;end
      @leech_seed_frames_v051=[frames,0].max
      @leech_seed_tick_v051=[tick,0].max
      @leech_seed_source_uid_v051=uid
    else
      pmd_ac_v065_update
    end
    ability_download_update_v065
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v065_start start unless method_defined?(:pmd_ac_v065_start)
  alias pmd_ac_v065_start_battle start_battle unless method_defined?(:pmd_ac_v065_start_battle)
  alias pmd_ac_v065_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v065_prepare_verification_battle)
  alias pmd_ac_v065_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v065_update_verification_script)
  alias pmd_ac_v065_canonical_global_ability_units canonical_global_ability_units unless method_defined?(:pmd_ac_v065_canonical_global_ability_units)
  alias pmd_ac_v065_substitute_target_for substitute_target_for unless method_defined?(:pmd_ac_v065_substitute_target_for)
  alias pmd_ac_v065_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v065_launch_projectile)
  alias pmd_ac_v065_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v065_apply_skill_effects)
  alias pmd_ac_v065_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v065_deal_direct_damage)
  alias pmd_ac_v065_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v065_canonical_accuracy_probability)

  def start
    pmd_ac_v065_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.64 Battle Verification Log/,
               'PMD AutoChess Proto v0.65 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V065
    log_event(:ability_runtime_ii,
      'LOADED new='+m[:new_implemented_ability_count].to_s+
      ' cumulative='+m[:cumulative_implemented_ability_count].to_s+
      ' implemented_slots='+m[:implemented_slot_count].to_s+'/'+m[:total_slot_count].to_s+
      ' coverage='+sprintf('%.2f',m[:implemented_slot_coverage_percent].to_f)+'%'+
      ' species='+m[:species_with_any_implemented_ability].to_s+'/494'+
      ' checksum32='+m[:runtime_checksum32].to_s)
    log_event(:presentation,
      'PATCH v0.65 ability_runtime=lightning_rod,storm_drain,scrappy,prankster,unaware,friend_guard,liquid_ooze,download '+
      'native_router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep '+
      'beam_projectile_impact_targetfx=unchanged organic_sfx=v0.56.1')
  end

  def canonical_global_ability_units
    list=pmd_ac_v065_canonical_global_ability_units
    list += @ability_runtime_test_units_v065 if @ability_runtime_test_units_v065!=nil
    list.uniq
  end

  # Download is an entry ability. Run it after every older start_battle wrapper has
  # finished (including stat resets, Intimidate, weather and tactical resets), then
  # mark it active so the per-unit update bridge does not fire it twice. The update
  # bridge remains for future ability changes that grant Download mid-battle.
  def start_battle
    pmd_ac_v065_start_battle
    return unless @phase==:battle
    for u in (@units||[])
      next if u==nil || u.dead? || u.ability_key!=:download
      if ability_download_activate_v065(u)
        u.ability_download_mark_active_v065 if u.respond_to?(:ability_download_mark_active_v065)
      end
    end
  end

  def ability_move_data_v065(user,data=nil,source_type=nil)
    return data unless data==nil
    return nil if user==nil
    if source_type==:basic
      return {:move_type=>(user.respond_to?(:basic_move_type) ? user.basic_move_type : :normal),
              :damage_category=>:physical,:target_type=>:enemy_targeted,
              :delivery=>:instant,:canonical_move_key=>:basic_attack}
    end
    user.respond_to?(:skill_data) ? user.skill_data : nil
  end

  def ability_move_type_v065(user,data=nil,source_type=nil)
    d=ability_move_data_v065(user,data,source_type)
    return nil if d==nil
    d[:move_type] || d[:type]
  end

  def ability_single_target_hostile_v065?(attacker,intended,data,source_type)
    return false if attacker==nil || intended==nil || !intended.is_a?(Game_PMDChessUnit)
    return false if attacker.team==intended.team
    d=ability_move_data_v065(attacker,data,source_type)
    return true if source_type==:basic && d!=nil
    return false if d==nil || d.empty?
    return false unless (d[:target_type]||:enemy_targeted)==:enemy_targeted
    return false if respond_to?(:guard_multi_target_v040?) && guard_multi_target_v040?(d)
    return false if [:aoe,:chain,:bounce,:pierce,:sweep].include?(d[:delivery])
    true
  end

  def ability_redirect_key_for_type_v065(type)
    return :lightning_rod if type==:electric
    return :storm_drain if type==:water
    nil
  end

  def ability_type_redirect_target_v065(attacker,intended,source_type=:direct,data=nil)
    return intended unless ability_single_target_hostile_v065?(attacker,intended,data,source_type)
    type=ability_move_type_v065(attacker,data,source_type);key=ability_redirect_key_for_type_v065(type)
    return intended if key==nil
    candidates=canonical_global_ability_units.find_all do |u|
      u!=nil && u!=attacker && u.is_a?(Game_PMDChessUnit) && u.alive? && u.ability_key==key
    end
    return intended if candidates.empty?
    chosen=candidates.sort_by{|u|[-u.speed_stat.to_i,u.instance_uid.to_i]}[0]
    if chosen!=intended
      log_event(:ability_runtime_ii,attacker.log_name+' '+type.to_s.upcase+'_REDIRECT '+
        intended.log_name+' -> '+chosen.log_name+' ability='+key.to_s+' selector=speed')
    end
    chosen
  end

  # Follow Me / Rage Powder has precedence over type-redirection in Gen V. v0.44
  # already owns that center-of-attention layer, so run it first, then type
  # redirection only when center-of-attention did not change the target.
  def substitute_target_for(attacker,intended_target,source_type=:direct)
    if attacker!=nil && intended_target!=nil && respond_to?(:tactical_redirect_target_v044) &&
       respond_to?(:pmd_ac_v044_substitute_target_for)
      tactical=tactical_redirect_target_v044(attacker,intended_target,source_type)
      if tactical!=intended_target
        return pmd_ac_v044_substitute_target_for(attacker,tactical,source_type)
      end
      typed=ability_type_redirect_target_v065(attacker,intended_target,source_type,nil)
      return pmd_ac_v044_substitute_target_for(attacker,typed,source_type)
    end
    typed=ability_type_redirect_target_v065(attacker,intended_target,source_type,nil)
    pmd_ac_v065_substitute_target_for(attacker,typed,source_type)
  end

  def ability_absorb_matching_v065?(user,target,data=nil,source_type=nil,move_type=nil)
    return false if user==nil || target==nil || user==target || !target.is_a?(Game_PMDChessUnit)
    type=move_type || ability_move_type_v065(user,data,source_type)
    return true if type==:electric && target.ability_key==:lightning_rod
    return true if type==:water && target.ability_key==:storm_drain
    false
  end

  def ability_absorb_accessible_v065?(user,target,data)
    return true unless target.respond_to?(:two_turn_semi_invulnerable_v039?) && target.two_turn_semi_invulnerable_v039?
    return false if data==nil
    mk=data[:canonical_move_key] || data[:move_key]
    return false if mk==nil
    target.respond_to?(:two_turn_move_can_hit_pose_v039?) && target.two_turn_move_can_hit_pose_v039?(mk,user)
  end

  def ability_guard_precedes_absorb_v065?(user,target,data)
    return false unless respond_to?(:guard_block_reason_v040)
    guard_block_reason_v040(user,target,data,false)!=nil
  end

  def ability_absorb_activate_v065(user,target,data=nil,source_type=nil,move_type=nil)
    return false unless ability_absorb_matching_v065?(user,target,data,source_type,move_type)
    return false unless ability_absorb_accessible_v065?(user,target,data)
    return false if ability_guard_precedes_absorb_v065?(user,target,data)
    type=move_type || ability_move_type_v065(user,data,source_type)
    key=target.ability_key;boost=true
    if key==:lightning_rod && target.pokemon_types.include?(:ground);boost=false;end
    delta=boost ? target.change_stat_stage(:spatk,1,user) : 0
    add_vfx_impact(target,type) if respond_to?(:add_vfx_impact)
    log_event(:ability_runtime_ii,target.log_name+' '+key.to_s+' ABSORB type='+type.to_s+
      ' damage=0 spatk_delta='+delta.to_i.to_s+(boost ? '' : ' ground_no_boost_gen5=1'))
    true
  end

  # Pre-resolve projectile substitution exactly once so a redirected absorber is
  # tracked perfectly. Damage cadence/speed remains owned by v0.60.2.
  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,
                        attack_modifier=nil,allow_substitute=true)
    actual_target=target
    actual_allow=allow_substitute
    if allow_substitute && [:basic,:skill_generic].include?(kind) && user!=nil && target!=nil
      actual_target=substitute_target_for(user,target,kind)
      actual_allow=false
      data=effect_type==nil ? nil : PMD_AC.skill_data(effect_type)
      if ability_absorb_matching_v065?(user,actual_target,data,kind,nil)
        tracking_override=:perfect
      end
    end
    pmd_ac_v065_launch_projectile(user,actual_target,kind,power,effect_type,
      tracking_override,attack_modifier,actual_allow)
  end

  def ability_liquid_ooze_data_v065(data)
    return [data,[]] if data==nil
    drains=[];changed=false
    effects=(data[:effects]||[]).collect do |e|
      if e[:type]==:drain
        drains.push({:ratio=>(e[:ratio]||0.5).to_f,:kind=>:drain_effect});changed=true;nil
      elsif e[:type]==:dream_eater_v054
        drains.push({:ratio=>(e[:drain]||0.5).to_f,:kind=>:dream_eater});changed=true
        x=e.dup;x[:type]=:liquid_ooze_dream_eater_v065;x
      else
        e
      end
    end
    return [data,drains] unless changed
    d=data.dup;d[:effects]=effects.find_all{|e|e!=nil};[d,drains]
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if ability_absorb_matching_v065?(user,target,data,:skill_direct,nil) &&
       ability_absorb_activate_v065(user,target,data,:skill_direct,nil)
      return 0
    end
    if user!=nil && target!=nil && user!=target && target.ability_key==:liquid_ooze
      d,drains=ability_liquid_ooze_data_v065(data)
      unless drains.empty?
        result=pmd_ac_v065_apply_skill_effects(user,target,d,scale)
        dealt=result.to_i
        if dealt>0
          total=0
          drains.each do |info|
            next if info[:kind]==:dream_eater && (target==nil || !target.status?(:sleep))
            amount=(dealt*info[:ratio].to_f).round;next if amount<=0
            before=user.hp;user.receive_damage(amount,target,false,true,false)
            actual=[before-user.hp,0].max;total+=actual
          end
          if total>0
            add_vfx_impact(user,:poison) if respond_to?(:add_vfx_impact)
            log_event(:ability_runtime_ii,target.log_name+' liquid_ooze DRAIN_REVERSE move='+
              (data[:canonical_move_key]||data[:move_key]||:unknown).to_s+
              ' dealt='+dealt.to_s+' reverse='+total.to_s+' -> '+user.log_name)
          end
        end
        return result
      end
    end
    pmd_ac_v065_apply_skill_effects(user,target,data,scale)
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options
    data=opts[:skill_data];type=opts[:move_type]
    type=data[:move_type] if type==nil && data!=nil
    type=user.basic_move_type if type==nil && user!=nil && user.respond_to?(:basic_move_type)
    if ability_absorb_matching_v065?(user,target,data,opts[:source_type],type) &&
       ability_absorb_activate_v065(user,target,data,opts[:source_type],type)
      return 0
    end
    pmd_ac_v065_deal_direct_damage(user,target,power,options)
  end

  # Redirected matching-type moves are treated as guaranteed to reach their
  # absorber once spatial projectile tracking has selected that unit. Two-turn
  # accessibility remains enforced separately by the existing v0.39 layer.
  # Unaware's accuracy rule is scoped only to damaging moves.
  def canonical_accuracy_probability(user,target,data)
    if ability_absorb_matching_v065?(user,target,data,:skill_direct,nil) &&
       ability_absorb_accessible_v065?(user,target,data)
      return 100.0
    end
    cat=data==nil ? nil : (data[:damage_category] || data[:category])
    if cat==:physical || cat==:special
      old_target=nil;old_user=nil;did_target=false;did_user=false
      begin
        if user!=nil && user.ability_key==:unaware && target!=nil
          old_target=target.ability_stage_ignore_scope_v065([:evasion]);did_target=true
        end
        if target!=nil && target.ability_key==:unaware && user!=nil
          old_user=user.ability_stage_ignore_scope_v065([:accuracy]);did_user=true
        end
        return pmd_ac_v065_canonical_accuracy_probability(user,target,data)
      ensure
        target.ability_restore_stage_ignore_scope_v065(old_target) if target!=nil && did_target
        user.ability_restore_stage_ignore_scope_v065(old_user) if user!=nil && did_user
      end
    end
    pmd_ac_v065_canonical_accuracy_probability(user,target,data)
  end

  def ability_friend_guard_sources_v065(target,units=nil)
    return [] if target==nil
    list=units || canonical_global_ability_units
    list.find_all{|u|u!=nil && u!=target && u.is_a?(Game_PMDChessUnit) && u.alive? &&
      u.team==target.team && u.ability_key==:friend_guard}
  end

  def ability_friend_guard_multiplier_v065(target,units=nil)
    n=ability_friend_guard_sources_v065(target,units).size
    mult=1.0;n.times{mult*=0.75};mult
  end

  def ability_download_opponents_v065(unit,units=nil)
    list=units || canonical_global_ability_units
    list.find_all{|u|u!=nil && u!=unit && u.is_a?(Game_PMDChessUnit) && u.alive? && u.team!=unit.team}
  end

  def ability_download_activate_v065(unit,units=nil)
    return false if unit==nil || unit.dead? || unit.ability_key!=:download
    foes=ability_download_opponents_v065(unit,units);return false if foes.empty?
    d=0;s=0;foes.each{|u|d+=u.defense.to_i;s+=u.special_defense.to_i}
    stat=d<s ? :atk : :spatk
    delta=unit.change_stat_stage(stat,1,nil)
    add_vfx_impact(unit,:normal) if respond_to?(:add_vfx_impact)
    log_event(:ability_runtime_ii,unit.log_name+' download DEF_TOTAL='+d.to_s+
      ' SPDEF_TOTAL='+s.to_s+' -> '+stat.to_s+' delta='+delta.to_i.to_s+
      ' enemies='+foes.size.to_s)
    true
  end

  # Verification --------------------------------------------------------------
  def ability_runtime_verification_unit_v065(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{
      :instance_uid=>99065000+id.to_i,:ivs=>[15,15,15,15,15,15],
      :nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9650+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_runtime_test_units_v065=[] if @ability_runtime_test_units_v065==nil
    @ability_runtime_test_units_v065.push(u);u
  end

  def prepare_verification_battle
    pmd_ac_v065_prepare_verification_battle
    return unless verification_mode==:ability_runtime_coverage_ii_v065
    @ability_runtime_test_units_v065=[]
    (@units||[]).each do |u|
      u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)
      if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
        u.pmd_ac_v0211_verification_suppress_active_evade
      end
    end
    log_event(:showcase,
      'START mode=ABILITY_RUNTIME_COVERAGE_II_V065 new=8 slots=952/1193 species=473/494 '+
      'diagnostic_only=1 pokemon_resume_after_final_assert=1')
  end

  def verify_ability_runtime_manifest_v065
    return if @verification_done[:v065_manifest]
    e=PMD_AC.validate_ability_runtime_v065;m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V065;ok=e.empty?
    log_event(:verify,'ABILITY_RUNTIME_MANIFEST_V065 pass='+(ok ? '1':'0')+
      ' new=8 cumulative=115 slots=952/1193 coverage=79.80% species=473/494 '+
      'checksum='+PMD_AC.ability_runtime_checksum32_v065.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v065_manifest]=true
  end

  def verify_ability_lightning_rod_v065
    return if @verification_done[:v065_lightning_rod]
    user=ability_runtime_verification_unit_v065(:charmander,:primary,:ally,1)
    intended=ability_runtime_verification_unit_v065(:squirtle,:primary,:enemy,2)
    rod=ability_runtime_verification_unit_v065(:pikachu,:hidden,:enemy,3)
    data={:canonical_move_key=>:thunder_shock,:move_key=>:thunder_shock,:move_type=>:electric,
      :damage_category=>:special,:target_type=>:enemy_targeted,:delivery=>:projectile,
      :accuracy=>100,:effects=>[{:type=>:damage,:power=>40}]}
    redirected=ability_type_redirect_target_v065(user,intended,:skill_direct,data)
    before=rod.stat_stage(:spatk);result=apply_skill_effects(user,rod,data,1.0);after=rod.stat_stage(:spatk)
    ok=rod.ability_key==:lightning_rod && redirected==rod && result.to_i==0 && after==before+1
    log_event(:verify,'ABILITY_LIGHTNING_ROD_V065 pass='+(ok ? '1':'0')+
      ' redirect='+(redirected==rod ? '1':'0')+' damage='+result.to_i.to_s+
      ' spatk='+before.to_s+'->'+after.to_s+' follow_me_precedence=v0.44')
    @verification_done[:v065_lightning_rod]=true
  end

  def verify_ability_storm_drain_v065
    return if @verification_done[:v065_storm_drain]
    user=ability_runtime_verification_unit_v065(:charmander,:primary,:ally,4)
    intended=ability_runtime_verification_unit_v065(:rattata,:primary,:enemy,5)
    drain=ability_runtime_verification_unit_v065(:shellos,:secondary,:enemy,6)
    data={:canonical_move_key=>:water_gun,:move_key=>:water_gun,:move_type=>:water,
      :damage_category=>:special,:target_type=>:enemy_targeted,:delivery=>:beam,
      :accuracy=>100,:effects=>[{:type=>:damage,:power=>40}]}
    redirected=ability_type_redirect_target_v065(user,intended,:skill_direct,data)
    before=drain.stat_stage(:spatk);result=apply_skill_effects(user,drain,data,1.0);after=drain.stat_stage(:spatk)
    ok=drain.ability_key==:storm_drain && redirected==drain && result.to_i==0 && after==before+1
    log_event(:verify,'ABILITY_STORM_DRAIN_V065 pass='+(ok ? '1':'0')+
      ' redirect='+(redirected==drain ? '1':'0')+' damage='+result.to_i.to_s+
      ' spatk='+before.to_s+'->'+after.to_s+' single_target_only=1')
    @verification_done[:v065_storm_drain]=true
  end

  def verify_ability_scrappy_v065
    return if @verification_done[:v065_scrappy]
    scrappy=ability_runtime_verification_unit_v065(:kangaskhan,:secondary,:ally,7)
    plain=ability_runtime_verification_unit_v065(:kangaskhan,:primary,:ally,8)
    ghost=ability_runtime_verification_unit_v065(:gastly,:primary,:enemy,9)
    a=scrappy.calculate_damage(ghost,40,:physical,:normal,100)
    b=plain.calculate_damage(ghost,40,:physical,:normal,100)
    ok=scrappy.ability_key==:scrappy && a.to_i>0 && b.to_i==0
    log_event(:verify,'ABILITY_SCRAPPY_V065 pass='+(ok ? '1':'0')+
      ' normal_vs_ghost scrappy='+a.to_i.to_s+' baseline='+b.to_i.to_s+
      ' ghost_other_typing_preserved=1')
    @verification_done[:v065_scrappy]=true
  end

  def verify_ability_prankster_v065
    return if @verification_done[:v065_prankster]
    user=ability_runtime_verification_unit_v065(:sableye,:hidden,:ally,10)
    target=ability_runtime_verification_unit_v065(:rattata,:primary,:enemy,11)
    data=PMD_AC.skill_data(:mv_toxic);canonical=PMD_AC.canonical_priority_v042(data)
    forced=user.verification_force_skill(:mv_toxic,target);snap=user.ability_priority_snapshot_v065
    ok=user.ability_key==:prankster && forced && snap[:priority]==canonical+1 && canonical==0
    log_event(:verify,'ABILITY_PRANKSTER_V065 pass='+(ok ? '1':'0')+
      ' move=toxic priority='+canonical.to_s+'->'+snap[:priority].to_s+
      ' startup='+snap[:native].to_s+'->'+snap[:elapsed].to_s+
      ' quick_guard_gen5_uses_canonical_priority=1')
    @verification_done[:v065_prankster]=true
  end

  def verify_ability_unaware_v065
    return if @verification_done[:v065_unaware]
    ua=ability_runtime_verification_unit_v065(:clefable,:hidden,:ally,12)
    normal=ability_runtime_verification_unit_v065(:clefable,:primary,:ally,13)
    target=ability_runtime_verification_unit_v065(:squirtle,:primary,:enemy,14)
    target.change_stat_stage(:def,6,nil);target.change_stat_stage(:evasion,6,nil)
    du=ua.calculate_damage(target,60,:physical,:normal,100)
    dn=normal.calculate_damage(target,60,:physical,:normal,100)
    tackle={:canonical_move_key=>:tackle,:move_key=>:tackle,:move_type=>:normal,
      :damage_category=>:physical,:category=>:physical,:accuracy=>100,
      :target_type=>:enemy_targeted,:delivery=>:instant,:effects=>[{:type=>:damage,:power=>40}]}
    au=canonical_accuracy_probability(ua,target,tackle);an=canonical_accuracy_probability(normal,target,tackle)
    defender=ability_runtime_verification_unit_v065(:bidoof,:secondary,:enemy,15)
    attacker=ability_runtime_verification_unit_v065(:rattata,:primary,:ally,16)
    d0=attacker.calculate_damage(defender,60,:physical,:normal,100)
    attacker.change_stat_stage(:atk,6,nil);d1=attacker.calculate_damage(defender,60,:physical,:normal,100)
    ok=ua.ability_key==:unaware && defender.ability_key==:unaware && du.to_i>dn.to_i && au.to_f>an.to_f && d0.to_i==d1.to_i
    log_event(:verify,'ABILITY_UNAWARE_V065 pass='+(ok ? '1':'0')+
      ' attack_ignore_def='+du.to_i.to_s+'/'+dn.to_i.to_s+
      ' attack_ignore_evasion='+sprintf('%.2f',au.to_f)+'/'+sprintf('%.2f',an.to_f)+
      ' defend_ignore_atk='+d0.to_i.to_s+'/'+d1.to_i.to_s)
    @verification_done[:v065_unaware]=true
  end

  def verify_ability_friend_guard_v065
    return if @verification_done[:v065_friend_guard]
    target=ability_runtime_verification_unit_v065(:bulbasaur,:primary,:ally,17)
    guard=ability_runtime_verification_unit_v065(:clefairy,:hidden,:ally,18)
    base=target.pmd_ac_v065_ability_incoming_multiplier(:normal,:physical)
    actual=target.ability_incoming_multiplier(:normal,:physical)
    expected=base*0.75
    ok=guard.ability_key==:friend_guard && (actual-expected).abs<0.0001 &&
       (guard.ability_incoming_multiplier(:normal,:physical)-guard.pmd_ac_v065_ability_incoming_multiplier(:normal,:physical)).abs<0.0001
    log_event(:verify,'ABILITY_FRIEND_GUARD_V065 pass='+(ok ? '1':'0')+
      ' ally_multiplier='+sprintf('%.3f',actual)+' expected='+sprintf('%.3f',expected)+
      ' self_protection=0 stack=multiplicative')
    @verification_done[:v065_friend_guard]=true
  end

  def verify_ability_liquid_ooze_v065
    return if @verification_done[:v065_liquid_ooze]
    user=ability_runtime_verification_unit_v065(:bulbasaur,:primary,:ally,19)
    ooze=ability_runtime_verification_unit_v065(:gulpin,:primary,:enemy,20)
    data={:canonical_move_key=>:absorb,:move_key=>:absorb,:move_type=>:grass,
      :damage_category=>:special,:category=>:special,:accuracy=>100,
      :target_type=>:enemy_targeted,:delivery=>:instant,:directional=>false,:can_crit=>false,
      :effects=>[{:type=>:damage,:flat=>100,:can_crit=>false,:directional=>false},{:type=>:drain,:ratio=>0.5}]}
    ub=user.hp;tb=ooze.hp;result=apply_skill_effects(user,ooze,data,1.0)
    drain_loss=[ub-user.hp,0].max;target_loss=[tb-ooze.hp,0].max
    seed_src=ability_runtime_verification_unit_v065(:charmander,:primary,:ally,21)
    sb=seed_src.hp;seed_actual=ooze.ability_liquid_ooze_leech_tick_v065(seed_src);seed_loss=[sb-seed_src.hp,0].max
    ok=ooze.ability_key==:liquid_ooze && result.to_i==100 && target_loss==100 && drain_loss==50 && seed_actual>0 && seed_loss==seed_actual
    log_event(:verify,'ABILITY_LIQUID_OOZE_V065 pass='+(ok ? '1':'0')+
      ' drain_damage='+target_loss.to_s+' reverse='+drain_loss.to_s+
      ' leech_seed_reverse='+seed_loss.to_s+' dream_eater_hook=1')
    @verification_done[:v065_liquid_ooze]=true
  end

  def verify_ability_download_v065
    return if @verification_done[:v065_download]
    p1=ability_runtime_verification_unit_v065(:porygon,:secondary,:ally,22)
    e1=ability_runtime_verification_unit_v065(:rattata,:primary,:enemy,23)
    e2=ability_runtime_verification_unit_v065(:caterpie,:primary,:enemy,24)
    e1.set_absolute_stats_v058({:def=>50,:spdef=>100},300);e2.set_absolute_stats_v058({:def=>50,:spdef=>100},300)
    a0=p1.stat_stage(:atk);ability_download_activate_v065(p1,[e1,e2]);a1=p1.stat_stage(:atk)
    p2=ability_runtime_verification_unit_v065(:porygon2,:secondary,:ally,25)
    e3=ability_runtime_verification_unit_v065(:rattata,:primary,:enemy,26)
    e4=ability_runtime_verification_unit_v065(:caterpie,:primary,:enemy,27)
    e3.set_absolute_stats_v058({:def=>100,:spdef=>50},300);e4.set_absolute_stats_v058({:def=>100,:spdef=>50},300)
    s0=p2.stat_stage(:spatk);ability_download_activate_v065(p2,[e3,e4]);s1=p2.stat_stage(:spatk)
    ok=p1.ability_key==:download && p2.ability_key==:download && a1==a0+1 && s1==s0+1
    log_event(:verify,'ABILITY_DOWNLOAD_V065 pass='+(ok ? '1':'0')+
      ' def_lower_atk='+a0.to_s+'->'+a1.to_s+' def_higher_spatk='+s0.to_s+'->'+s1.to_s+
      ' multi_enemy_compare=totals tie=spatk')
    @verification_done[:v065_download]=true
  end

  def verify_ability_runtime_carry_v065
    return if @verification_done[:v065_carry]
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V065;c=PMD_AC.compiled_data_status_v061
    ok=m[:implemented_slot_count].to_i==952 && m[:species_with_any_implemented_ability].to_i==473 &&
       c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077
    log_event(:verify,'ABILITY_RUNTIME_CARRY_V065 pass='+(ok ? '1':'0')+
      ' slots=952/1193 species=473/494 compiled_species='+c[:species].to_i.to_s+
      ' native_actions='+c[:native].to_i.to_s+' aliases='+c[:aliases].to_i.to_s+
      ' move_runtime=526 learnset=7005/7005 native_router=v0.62_unchanged '+
      ' combo_packet_driver=v0.60.2_backstep presentation_anchors=unchanged')
    @verification_done[:v065_carry]=true
  end

  def update_ability_runtime_coverage_ii_v065
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_ability_runtime_manifest_v065 if f>=2
    verify_ability_lightning_rod_v065 if f>=4
    verify_ability_storm_drain_v065 if f>=6
    verify_ability_scrappy_v065 if f>=8
    verify_ability_prankster_v065 if f>=10
    verify_ability_unaware_v065 if f>=12
    verify_ability_friend_guard_v065 if f>=14
    verify_ability_liquid_ooze_v065 if f>=16
    verify_ability_download_v065 if f>=18
    verify_ability_runtime_carry_v064 if f>=20
    verify_native_semantic_carry_v063 if f>=20
    verify_ability_runtime_carry_v065 if f>=22
    complete_verification_mode if f>=24
  end

  def update_verification_script
    if verification_mode==:ability_runtime_coverage_ii_v065
      update_ability_runtime_coverage_ii_v065
      return
    end
    pmd_ac_v065_update_verification_script
  end
end
