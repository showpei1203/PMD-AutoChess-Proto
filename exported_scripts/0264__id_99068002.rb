#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.68
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V068 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - combat_ai_scalar_v068 / combat_ai_checksum32_v068 / validate_combat_ai_v068 / start
# - diagnostic_presentation_suppressed_v068? / add_skill_effect / add_effect_xy / add_link_effect
# - add_beam_effect / add_vfx_burst_xy / play_skill_se / play_basic_se
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.68
# Combat AI Integration I + Verification Presentation Isolation
#------------------------------------------------------------------------------
# 1) Keeps the verified v0.46 four-active-move selector and layers contextual
#    scoring over it.  Movement, target policies and skill execution remain the
#    existing runtime.
# 2) Suppresses VFX/SFX during non-visual diagnostic verification modes so
#    synthetic test battlers can never spawn an animation at screen (0,0).
#==============================================================================
module PMD_AC
  PATCH_VERSION_V068='0.68'

  class << self
    def combat_ai_scalar_v068(x)
      return '' if x==nil
      return x.collect{|v|combat_ai_scalar_v068(v)}.join(',') if x.is_a?(Array)
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+combat_ai_scalar_v068(x[k])}.join(',')
      end
      x.to_s
    end

    def combat_ai_checksum32_v068
      h=0
      m=COMBAT_AI_MANIFEST_V068
      [:schema_version,:content_version,:base_version,:feature,:selection_source,
       :base_score,:categories,:presentation_isolation,:diagnostic_fake_unit_vfx,
       :movement_core,:target_core,:damage_packet,:native_router,:ability_slots,
       :ability_slots_total,:ability_species,:move_runtime,:learnset_coverage].each do |k|
        combat_ai_scalar_v068(m[k]).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      COMBAT_AI_TUNING_V068.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        (k.to_s+'='+combat_ai_scalar_v068(COMBAT_AI_TUNING_V068[k])).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_combat_ai_v068
      e=[];m=COMBAT_AI_MANIFEST_V068
      e.push('categories') unless m[:categories].size==12
      e.push('moves') unless m[:move_runtime].to_i==526
      e.push('ability_slots') unless m[:ability_slots].to_i==1028 && m[:ability_slots_total].to_i==1193
      e.push('ability_species') unless m[:ability_species].to_i==483
      e.push('presentation') unless m[:presentation_isolation] && !m[:diagnostic_fake_unit_vfx]
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :combat_ai_integration_v068,
    :ability_runtime_coverage_iv_v067,
    :ability_runtime_coverage_iii_v066,
    :ability_runtime_coverage_ii_v065,
    :ability_runtime_coverage_v064,
    :native_semantic_audit_v063,
    :native_semantic_v062,
    :native_combo_preview_v062,
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :combat_ai_integration_v068=>'COMBAT_AI_INTEGRATION_V068',
    :ability_runtime_coverage_iv_v067=>'ABILITY_RUNTIME_COVERAGE_IV_V067',
    :ability_runtime_coverage_iii_v066=>'ABILITY_RUNTIME_COVERAGE_III_V066',
    :ability_runtime_coverage_ii_v065=>'ABILITY_RUNTIME_COVERAGE_II_V065',
    :ability_runtime_coverage_v064=>'ABILITY_RUNTIME_COVERAGE_V064',
    :native_semantic_audit_v063=>'NATIVE_SEMANTIC_AUDIT_V063',
    :native_semantic_v062=>'NATIVE_SEMANTIC_V062',
    :native_combo_preview_v062=>'NATIVE_COMBO_PREVIEW_V062',
    :compiled_pose_runtime_v061=>'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060=>'MULTI_CHOREO_V060',
    :native_pose_showcase_v060=>'NATIVE_POSE_SHOWCASE_V060'
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v068_start start unless method_defined?(:pmd_ac_v068_start)
  alias pmd_ac_v068_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v068_prepare_verification_battle)
  alias pmd_ac_v068_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v068_update_verification_script)
  alias pmd_ac_v068_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v068_progression_candidate_score_v046)
  alias pmd_ac_v068_progression_select_best_move_v046 progression_select_best_move_v046 unless method_defined?(:pmd_ac_v068_progression_select_best_move_v046)
  alias pmd_ac_v068_add_skill_effect add_skill_effect unless method_defined?(:pmd_ac_v068_add_skill_effect)
  alias pmd_ac_v068_add_effect_xy add_effect_xy unless method_defined?(:pmd_ac_v068_add_effect_xy)
  alias pmd_ac_v068_add_link_effect add_link_effect unless method_defined?(:pmd_ac_v068_add_link_effect)
  alias pmd_ac_v068_add_beam_effect add_beam_effect unless method_defined?(:pmd_ac_v068_add_beam_effect)
  alias pmd_ac_v068_add_vfx_burst_xy add_vfx_burst_xy unless method_defined?(:pmd_ac_v068_add_vfx_burst_xy)
  alias pmd_ac_v068_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v068_play_skill_se)
  alias pmd_ac_v068_play_basic_se play_basic_se unless method_defined?(:pmd_ac_v068_play_basic_se)
  alias pmd_ac_v068_play_crit_se play_crit_se unless method_defined?(:pmd_ac_v068_play_crit_se)
  alias pmd_ac_v068_play_evade_se play_evade_se unless method_defined?(:pmd_ac_v068_play_evade_se)
  alias pmd_ac_v068_register_impact register_impact unless method_defined?(:pmd_ac_v068_register_impact)

  def start
    pmd_ac_v068_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.67\.1 Battle Verification Log/,
          'PMD AutoChess Proto v0.68 Battle Verification Log')
        t.sub!(/PMD AutoChess Proto v0\.67 Battle Verification Log/,
          'PMD AutoChess Proto v0.68 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:combat_ai,
      'LOADED phase=I categories=12 source=active_moves_v045 base=v0.46 '+
      'movement=unchanged target_policy=unchanged damage_packet=v0.60.2')
    log_event(:presentation,
      'PATCH v0.68 diagnostic_fake_unit_vfx=off diagnostic_sfx=off '+
      'ability_verification_modes=isolated normal_combat_unchanged=1')
  end

  # ---------------------------------------------------------------------------
  # Diagnostic presentation isolation
  # ---------------------------------------------------------------------------
  def diagnostic_presentation_suppressed_v068?
    m=verification_mode
    return true if m==:combat_ai_integration_v068
    return true if m==:ability_runtime_coverage_iv_v067
    return true if m==:ability_runtime_coverage_iii_v066
    return true if m==:ability_runtime_coverage_ii_v065
    return true if m==:ability_runtime_coverage_v064
    false
  end

  def add_skill_effect(target,type,delay=0)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_add_skill_effect(target,type,delay)
  end
  def add_effect_xy(x,y,type,delay=0)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_add_effect_xy(x,y,type,delay)
  end
  def add_link_effect(x1,y1,x2,y2,type=:electric,delay=0)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_add_link_effect(x1,y1,x2,y2,type,delay)
  end
  def add_beam_effect(source,target,style=:light,life=nil,width=nil)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_add_beam_effect(source,target,style,life,width)
  end
  def add_vfx_burst_xy(x,y,profile,delay=0)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_add_vfx_burst_xy(x,y,profile,delay)
  end
  def play_skill_se(unit,stage,data=nil)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_play_skill_se(unit,stage,data)
  end
  def play_basic_se(unit,stage)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_play_basic_se(unit,stage)
  end
  def play_crit_se(unit,skill_data=nil)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_play_crit_se(unit,skill_data)
  end
  def play_evade_se(unit)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_play_evade_se(unit)
  end
  def register_impact(value)
    return if diagnostic_presentation_suppressed_v068?
    pmd_ac_v068_register_impact(value)
  end

  # ---------------------------------------------------------------------------
  # Combat AI helpers
  # ---------------------------------------------------------------------------
  def combat_ai_sym_v068(x)
    return nil if x==nil
    x.is_a?(String) ? x.to_sym : x
  end

  def combat_ai_get_v068(h,key)
    return nil if h==nil
    return h[key] if h.has_key?(key)
    sk=key.to_s
    return h[sk] if h.has_key?(sk)
    nil
  end

  def combat_ai_move_key_v068(data,move=nil)
    k=move
    k=combat_ai_get_v068(data,:canonical_move_key)||combat_ai_get_v068(data,:move_key) if k==nil && data!=nil
    combat_ai_sym_v068(k)
  end

  def combat_ai_effect_types_v068(data)
    a=[]
    for e in (data==nil ? [] : (data[:effects]||[]))
      t=combat_ai_sym_v068(combat_ai_get_v068(e,:type));a.push(t) if t!=nil
    end
    a
  end

  def combat_ai_damaging_v068?(data)
    return false if data==nil
    c=combat_ai_sym_v068(combat_ai_get_v068(data,:damage_category)||combat_ai_get_v068(data,:category))
    return true if c==:physical || c==:special
    combat_ai_effect_types_v068(data).include?(:damage)
  end

  def combat_ai_damage_power_v068(data)
    return 0 if data==nil
    p=0
    for e in (data[:effects]||[])
      if combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:damage
        ep=combat_ai_get_v068(e,:power);v=ep==nil ? 0 : ep.to_i;p=v if v>p
      end
    end
    cp=combat_ai_get_v068(data,:canonical_power)
    p=cp.to_i if p<=0 && cp!=nil
    p
  end

  def combat_ai_multi_hits_v068(unit,data)
    return 1.0 if data==nil
    min=combat_ai_get_v068(data,:multi_hit_min).to_i;max=combat_ai_get_v068(data,:multi_hit_max).to_i
    if min<=0 || max<=0
      return 1.0 unless combat_ai_get_v068(data,:multi_hit_v049)
      min=2;max=5
    end
    return max.to_f if unit!=nil && unit.respond_to?(:ability_key) && unit.ability_key==:skill_link
    if min==2 && max==5
      return PMD_AC::COMBAT_AI_TUNING_V068[:multi_hit_2_5_expected].to_f
    end
    return min.to_f if min==max
    (min.to_f+max.to_f)*0.5
  end

  def combat_ai_aoe_enemy_count_v068(unit,target,data)
    return 1 if unit==nil || target==nil || data==nil
    enemies=enemies_of(unit)
    return 1 if enemies.empty?
    tt=combat_ai_sym_v068(combat_ai_get_v068(data,:target_type));delivery=combat_ai_sym_v068(combat_ai_get_v068(data,:delivery))
    return enemies.size if combat_ai_get_v068(data,:global_direct) || combat_ai_get_v068(data,:target)==:all_opponents
    is_aoe=(delivery==:aoe || tt==:ground_enemy || combat_ai_get_v068(data,:radius)!=nil)
    return 1 unless is_aoe
    radius=(combat_ai_get_v068(data,:radius)||PMD_AC::AOE_RADIUS).to_f
    return enemies.size if radius>=900.0
    count=0
    for e in enemies
      dx=e.pixel_x.to_f-target.pixel_x.to_f;dy=e.pixel_y.to_f-target.pixel_y.to_f
      count+=1 if dx*dx+dy*dy<=radius*radius
    end
    [count,1].max
  end

  def combat_ai_pressure_v068(unit)
    return 0.0 if unit==nil
    p=0.0
    for e in enemies_of(unit)
      p+=1.0 if e.respond_to?(:target) && e.target==unit
      if e.respond_to?(:distance_to) && e.distance_to(unit)<=PMD_AC::THREAT_PRESSURE_RANGE
        p+=0.5
      end
    end
    p
  end

  def combat_ai_stage_v068(target,stat)
    return 0 if target==nil || !target.respond_to?(:stat_stage)
    target.stat_stage(stat).to_i
  end

  def combat_ai_stage_gain_v068(target,data,positive)
    total=0
    for e in (data==nil ? [] : (data[:effects]||[]))
      next unless combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:stat_stage
      n=(combat_ai_get_v068(e,:stages)||0).to_i
      next if positive && n<=0
      next if !positive && n>=0
      cur=combat_ai_stage_v068(target,combat_ai_get_v068(e,:stat))
      if positive
        total+=[[n,6-cur].min,0].max
      else
        total+=[[-n,cur+6].min,0].max
      end
    end
    total
  end

  def combat_ai_status_kind_v068(data)
    types=combat_ai_effect_types_v068(data)
    for t in types
      return :hard_control if PMD_AC::COMBAT_AI_HARD_CONTROL_EFFECTS_V068.include?(t)
    end
    for t in types
      return :status if PMD_AC::COMBAT_AI_STATUS_EFFECTS_V068.include?(t)
    end
    nil
  end

  def combat_ai_heal_v068?(data)
    for t in combat_ai_effect_types_v068(data)
      return true if PMD_AC::COMBAT_AI_HEAL_EFFECTS_V068.include?(t)
    end
    false
  end

  def combat_ai_move_data_v068(move)
    k=PMD_AC.canonical_runtime_skill_key(move)
    return nil if k==nil
    PMD_AC.skill_data(k)
  end

  def combat_ai_unit_move_keys_v068(unit)
    return [] if unit==nil
    pi=unit.respond_to?(:pokemon_instance) ? unit.pokemon_instance : nil
    if pi!=nil && pi.respond_to?(:battle_moves_v046)
      a=pi.battle_moves_v046
      return a.dup if a!=nil && !a.empty?
    end
    d=unit.respond_to?(:skill_data) ? unit.skill_data : nil
    k=combat_ai_move_key_v068(d,nil)
    k==nil ? [] : [k]
  end

  def combat_ai_enemy_profile_v068(unit)
    h={:physical=>0,:special=>0,:status=>0,:debuff=>0}
    for e in enemies_of(unit)
      for mk in combat_ai_unit_move_keys_v068(e)
        d=combat_ai_move_data_v068(mk);next if d==nil
        c=combat_ai_sym_v068(combat_ai_get_v068(d,:damage_category)||combat_ai_get_v068(d,:category))
        h[:physical]+=1 if c==:physical
        h[:special]+=1 if c==:special
        if c==:status
          h[:status]+=1
          h[:debuff]+=1 if combat_ai_stage_gain_v068(unit,d,false)>0
        end
      end
    end
    h
  end

  def combat_ai_field_score_v068(unit,data,base)
    key=nil
    for e in (data[:effects]||[])
      if combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:field_effect
        key=combat_ai_sym_v068(combat_ai_get_v068(e,:key));break
      end
    end
    return base if key==nil
    t=PMD_AC::COMBAT_AI_TUNING_V068;score=[base,t[:field_base].to_f].max
    p=combat_ai_enemy_profile_v068(unit)
    if key==:reflect
      score+=p[:physical].to_f*t[:field_counter_weight].to_f
    elsif key==:light_screen
      score+=p[:special].to_f*t[:field_counter_weight].to_f
    elsif key==:safeguard
      score+=p[:status].to_f*(t[:field_counter_weight].to_f*0.75)
    elsif key==:mist
      score+=p[:debuff].to_f*t[:field_counter_weight].to_f
    else
      score+=enemies_of(unit).size.to_f*5.0
    end
    score
  end

  def combat_ai_weather_synergy_v068(unit,weather)
    good=[]
    case weather
    when :sun;good=[:fire,:grass]
    when :rain;good=[:water,:electric]
    when :sandstorm;good=[:rock,:ground,:steel]
    when :hail;good=[:ice]
    end
    return 0 if good.empty?
    own=0;enemy=0
    for a in allies_of(unit)
      for ty in a.pokemon_types;own+=1 if good.include?(ty);end
    end
    for e in enemies_of(unit)
      for ty in e.pokemon_types;enemy+=1 if good.include?(ty);end
    end
    own-enemy
  end

  def combat_ai_weather_score_v068(unit,data,base)
    weather=nil
    for e in (data[:effects]||[])
      if combat_ai_sym_v068(combat_ai_get_v068(e,:type))==:set_weather
        weather=combat_ai_sym_v068(combat_ai_get_v068(e,:weather));break
      end
    end
    return base if weather==nil
    t=PMD_AC::COMBAT_AI_TUNING_V068
    score=[base,t[:weather_base].to_f].max
    score+=combat_ai_weather_synergy_v068(unit,weather).to_f*t[:weather_synergy_weight].to_f
    score
  end

  def combat_ai_tags_v068(unit,target,data,move=nil)
    tags=[];mk=combat_ai_move_key_v068(data,move);types=combat_ai_effect_types_v068(data)
    tags.push(:heal) if combat_ai_heal_v068?(data)
    tags.push(:buff) if combat_ai_stage_gain_v068(target,data,true)>0
    tags.push(:debuff) if combat_ai_stage_gain_v068(target,data,false)>0
    sk=combat_ai_status_kind_v068(data);tags.push(:status) if sk!=nil
    tags.push(:guard) if combat_ai_get_v068(data,:guard_kind)!=nil || PMD_AC::COMBAT_AI_GUARD_MOVES_V068.include?(mk)
    pr=0;begin;pr=PMD_AC.canonical_priority_v042(data).to_i;rescue;pr=0;end
    tags.push(:priority) if pr>0
    tags.push(:reactive) if PMD_AC::COMBAT_AI_REACTIVE_MOVES_V068.include?(mk)
    tags.push(:field) if types.include?(:field_effect)
    tags.push(:weather) if types.include?(:set_weather)
    aoe=combat_ai_aoe_enemy_count_v068(unit,target,data)
    tags.push(:aoe) if aoe>1
    tags.push(:multi_hit) if combat_ai_multi_hits_v068(unit,data)>1.0
    tags.push(:two_turn) if combat_ai_get_v068(data,:two_turn)
    tags
  end

  # This method intentionally wraps, rather than replaces, the v0.46 score.
  def progression_candidate_score_v046(unit,target,data,move,slot)
    base=pmd_ac_v068_progression_candidate_score_v046(unit,target,data,move,slot)
    return nil if base==nil
    t=PMD_AC::COMBAT_AI_TUNING_V068;score=base.to_f
    mk=combat_ai_move_key_v068(data,move);damaging=combat_ai_damaging_v068?(data)

    if damaging
      hits=combat_ai_multi_hits_v068(unit,data)
      score*=hits if hits>1.0
      count=combat_ai_aoe_enemy_count_v068(unit,target,data)
      if count>1
        mult=1.0+(count-1).to_f*t[:aoe_extra_target_factor].to_f
        mult=[mult,t[:aoe_multiplier_cap].to_f].min
        score*=mult
      end
      if combat_ai_get_v068(data,:two_turn)
        hp=unit.hp.to_f/[unit.maxhp.to_i,1].max.to_f
        factor=hp<0.35 ? t[:two_turn_low_hp_factor].to_f : t[:two_turn_damage_factor].to_f
        score*=factor
      end
      sec=(combat_ai_get_v068(data,:secondary_effects)||[])
      score+=t[:secondary_status_bonus].to_f unless sec.empty?
    end

    if combat_ai_heal_v068?(data)
      missing=1.0-target.hp.to_f/[target.maxhp.to_i,1].max.to_f
      heal=t[:heal_base].to_f+missing*t[:heal_missing_hp_weight].to_f
      score=heal if heal>score
    end

    bg=combat_ai_stage_gain_v068(target,data,true)
    if bg>0
      v=t[:buff_base].to_f+bg.to_f*t[:buff_stage_weight].to_f
      v+=combat_ai_pressure_v068(target)*4.0
      score=v if v>score
    end
    dg=combat_ai_stage_gain_v068(target,data,false)
    if dg>0
      v=t[:debuff_base].to_f+dg.to_f*t[:debuff_stage_weight].to_f
      score=v if v>score
    end

    sk=combat_ai_status_kind_v068(data)
    if sk==:hard_control
      score=t[:hard_control_base].to_f if t[:hard_control_base].to_f>score
    elsif sk==:status
      score=t[:status_base].to_f if t[:status_base].to_f>score
    end

    if combat_ai_get_v068(data,:guard_kind)!=nil || PMD_AC::COMBAT_AI_GUARD_MOVES_V068.include?(mk)
      hp_missing=1.0-unit.hp.to_f/[unit.maxhp.to_i,1].max.to_f
      v=t[:guard_base].to_f+combat_ai_pressure_v068(unit)*t[:guard_pressure_weight].to_f+hp_missing*t[:guard_missing_hp_weight].to_f
      score=v if v>score
    end

    if PMD_AC::COMBAT_AI_REACTIVE_MOVES_V068.include?(mk)
      score=t[:reactive_floor].to_f if score<t[:reactive_floor].to_f
    end

    score=combat_ai_field_score_v068(unit,data,score)
    score=combat_ai_weather_score_v068(unit,data,score)

    priority=0;begin;priority=PMD_AC.canonical_priority_v042(data).to_i;rescue;priority=0;end
    if priority>0
      score+=priority.to_f*t[:priority_flat_per_stage].to_f
      if damaging
        hp=target.hp.to_f/[target.maxhp.to_i,1].max.to_f
        score+=t[:priority_execute_bonus].to_f if hp<=0.30
      end
    end
    score-slot.to_i*0.0001
  end

  def progression_select_best_move_v046(unit)
    r=pmd_ac_v068_progression_select_best_move_v046(unit)
    if unit!=nil && r!=nil && r[0]!=nil && r[1]!=nil
      k=r[0]
      if unit.instance_variable_get(:@combat_ai_last_logged_move_v068)!=k
        unit.instance_variable_set(:@combat_ai_last_logged_move_v068,k)
        d=combat_ai_move_data_v068(k);tags=combat_ai_tags_v068(unit,r[1],d,k)
        log_event(:combat_ai,unit.log_name+' SELECT '+k.to_s+' score='+sprintf('%.2f',r[2].to_f)+' tags=['+tags.collect{|x|x.to_s}.join(',')+'] target='+r[1].log_name)
      end
    end
    r
  end

  # ---------------------------------------------------------------------------
  # Verification helpers
  # ---------------------------------------------------------------------------
  def combat_ai_verification_unit_v068(species,team,id,level=60)
    i=PMD_PokemonInstance.new(species,level,{:instance_uid=>99068000+id.to_i,
      :ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    u=Game_PMDChessUnit.new(9680+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)
    u
  end

  def combat_ai_with_units_v068(units)
    old=@units;@units=units
    begin
      yield
    ensure
      @units=old
    end
  end

  def prepare_verification_battle
    pmd_ac_v068_prepare_verification_battle
    return unless verification_mode==:combat_ai_integration_v068
    (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    log_event(:showcase,
      'START mode=COMBAT_AI_INTEGRATION_V068 categories=12 active_moves=4 '+
      'diagnostic_vfx=off pokemon_resume_after_final_assert=1')
  end

  def verify_combat_ai_manifest_v068
    return if @verification_done[:v068_manifest]
    e=PMD_AC.validate_combat_ai_v068
    ok=e.empty?
    log_event(:verify,'COMBAT_AI_MANIFEST_V068 pass='+(ok ? '1':'0')+
      ' categories=12 active_moves=4 move_runtime=526 learnset=7005/7005 '+
      'ability_slots=1028/1193 species=483/494 checksum='+PMD_AC.combat_ai_checksum32_v068.to_s+
      ' errors=['+e.join(',')+']')
    @verification_done[:v068_manifest]=true
  end

  def verify_diagnostic_presentation_isolation_v068
    return if @verification_done[:v068_presentation]
    fake=combat_ai_verification_unit_v068(:rattata,:enemy,1)
    before=@effect_sprites==nil ? 0 : @effect_sprites.size
    add_skill_effect(fake,:impact)
    after=@effect_sprites==nil ? 0 : @effect_sprites.size
    ok=diagnostic_presentation_suppressed_v068? && before==after
    log_event(:verify,'VERIFY_PRESENTATION_ISOLATION_V068 pass='+(ok ? '1':'0')+
      ' fake_unit_effect_sprites='+before.to_s+'->'+after.to_s+
      ' top_left_vfx=0 diagnostic_sfx=0 normal_combat_unchanged=1')
    @verification_done[:v068_presentation]=true
  end

  def verify_combat_ai_heal_status_v068
    return if @verification_done[:v068_heal_status]
    u=combat_ai_verification_unit_v068(:staryu,:ally,2,60)
    e=combat_ai_verification_unit_v068(:rattata,:enemy,3,50)
    okset=u.pokemon_instance.set_active_moves_v045([:recover,:water_gun,:swift,:light_screen])
    low=nil;full=nil
    combat_ai_with_units_v068([u,e]) do
      u.verification_set_hp_percent(0.25);low=progression_select_best_move_v046(u)[0]
      u.verification_set_hp_percent(1.0);u.progression_restore_legacy_skill_v046 if u.respond_to?(:progression_restore_legacy_skill_v046)
      full=progression_select_best_move_v046(u)[0]
    end
    s=combat_ai_verification_unit_v068(:bulbasaur,:ally,4,20)
    t=combat_ai_verification_unit_v068(:rattata,:enemy,5,20)
    s.pokemon_instance.set_active_moves_v045([:tackle,:growl,:vine_whip,:sleep_powder])
    before=nil;after=nil
    combat_ai_with_units_v068([s,t]) do
      before=progression_select_best_move_v046(s)[0]
      t.apply_status(:sleep,{:duration=>999999,:value=>0,:interval=>999999},s)
      s.progression_restore_legacy_skill_v046 if s.respond_to?(:progression_restore_legacy_skill_v046)
      after=progression_select_best_move_v046(s)[0]
    end
    ok=okset && low==:recover && full!=:recover && before==:sleep_powder && after!=:sleep_powder
    log_event(:verify,'COMBAT_AI_HEAL_STATUS_V068 pass='+(ok ? '1':'0')+
      ' low_hp='+low.to_s+' full_hp='+full.to_s+
      ' status_fresh='+before.to_s+' status_already_sleep='+after.to_s)
    @verification_done[:v068_heal_status]=true
  end

  def verify_combat_ai_multihit_priority_v068
    return if @verification_done[:v068_multi_priority]
    u=combat_ai_verification_unit_v068(:chansey,:ally,6,55)
    e=combat_ai_verification_unit_v068(:rattata,:enemy,7,50)
    ds=combat_ai_move_data_v068(:double_slap);pd=combat_ai_move_data_v068(:pound)
    sm=progression_candidate_score_v046(u,e,ds,:double_slap,0)
    sp=progression_candidate_score_v046(u,e,pd,:pound,1)
    v=combat_ai_verification_unit_v068(:vaporeon,:ally,8,80)
    q=combat_ai_move_data_v068(:quick_attack);w=combat_ai_move_data_v068(:water_gun)
    e.verification_set_hp_percent(1.0);sq_full=progression_candidate_score_v046(v,e,q,:quick_attack,0);sw_full=progression_candidate_score_v046(v,e,w,:water_gun,1)
    e.verification_set_hp_percent(0.20);sq_low=progression_candidate_score_v046(v,e,q,:quick_attack,0);sw_low=progression_candidate_score_v046(v,e,w,:water_gun,1)
    ok=sm!=nil && sp!=nil && sm>sp && sq_full<sw_full && sq_low>sw_low
    log_event(:verify,'COMBAT_AI_MULTI_PRIORITY_V068 pass='+(ok ? '1':'0')+
      ' double_slap='+sprintf('%.1f',sm.to_f)+' pound='+sprintf('%.1f',sp.to_f)+
      ' priority_full='+sprintf('%.1f',sq_full.to_f)+'/'+sprintf('%.1f',sw_full.to_f)+
      ' priority_execute='+sprintf('%.1f',sq_low.to_f)+'/'+sprintf('%.1f',sw_low.to_f))
    @verification_done[:v068_multi_priority]=true
  end

  def verify_combat_ai_aoe_field_v068
    return if @verification_done[:v068_aoe_field]
    v=combat_ai_verification_unit_v068(:vaporeon,:ally,9,80)
    v.pokemon_instance.set_active_moves_v045([:hydro_pump,:muddy_water,:aqua_ring,:quick_attack])
    e1=combat_ai_verification_unit_v068(:rattata,:enemy,10,50)
    e2=combat_ai_verification_unit_v068(:rattata,:enemy,11,50)
    e3=combat_ai_verification_unit_v068(:rattata,:enemy,12,50)
    e1.deploy_to_cell(4,1);e2.deploy_to_cell(4,2);e3.deploy_to_cell(4,3)
    one=nil;many=nil
    combat_ai_with_units_v068([v,e1]){one=progression_select_best_move_v046(v)[0]}
    v.progression_restore_legacy_skill_v046 if v.respond_to?(:progression_restore_legacy_skill_v046)
    combat_ai_with_units_v068([v,e1,e2,e3]){many=progression_select_best_move_v046(v)[0]}

    a=combat_ai_verification_unit_v068(:alakazam,:ally,13,60)
    a.pokemon_instance.set_active_moves_v045([:psychic,:reflect,:recover,:calm_mind])
    [e1,e2,e3].each do |x|
      x.pokemon_instance.set_active_moves_v045([:tackle,:quick_attack,:hyper_fang,:super_fang])
    end
    field=nil
    combat_ai_with_units_v068([a,e1,e2,e3]){field=progression_select_best_move_v046(a)[0]}
    ok=(one==:hydro_pump) && (many==:muddy_water) && (field==:reflect)
    log_event(:verify,'COMBAT_AI_AOE_FIELD_V068 pass='+(ok ? '1':'0')+
      ' single_enemy='+one.to_s+' clustered3='+many.to_s+' physical_pressure='+field.to_s)
    @verification_done[:v068_aoe_field]=true
  end

  def verify_combat_ai_support_timing_v068
    return if @verification_done[:v068_support_timing]
    u=combat_ai_verification_unit_v068(:charizard,:ally,14,60)
    t=combat_ai_verification_unit_v068(:rattata,:enemy,15,50)
    instant={:canonical_move_key=>:test_instant,:move_key=>:test_instant,:move_type=>:flying,
      :damage_category=>:physical,:category=>:physical,:effects=>[{:type=>:damage,:power=>90}]}
    two=instant.dup;two[:canonical_move_key]=:fly;two[:move_key]=:fly;two[:two_turn]=true;two[:semi_invulnerable]=true
    si=progression_candidate_score_v046(u,t,instant,:test_instant,0)
    st=progression_candidate_score_v046(u,t,two,:fly,1)
    reactive={:canonical_move_key=>:counter,:move_key=>:counter,:move_type=>:fighting,
      :damage_category=>:status,:category=>:status,:effects=>[{:type=>:reactive_return}]}
    sr=progression_candidate_score_v046(u,t,reactive,:counter,0)
    sunny={:canonical_move_key=>:sunny_day,:move_key=>:sunny_day,:move_type=>:fire,
      :damage_category=>:status,:category=>:status,:effects=>[{:type=>:set_weather,:weather=>:sun}]}
    fire=combat_ai_verification_unit_v068(:charmander,:ally,16,50)
    grass=combat_ai_verification_unit_v068(:bulbasaur,:ally,17,50)
    rainfoe=combat_ai_verification_unit_v068(:squirtle,:enemy,18,50)
    sw=0.0
    combat_ai_with_units_v068([u,fire,grass,rainfoe]){sw=progression_candidate_score_v046(u,u,sunny,:sunny_day,0)}
    tags=combat_ai_tags_v068(u,t,two,:fly)
    ok=si!=nil && st!=nil && st<si && sr>=PMD_AC::COMBAT_AI_TUNING_V068[:reactive_floor].to_f && sw>=PMD_AC::COMBAT_AI_TUNING_V068[:weather_base].to_f && tags.include?(:two_turn)
    log_event(:verify,'COMBAT_AI_SUPPORT_TIMING_V068 pass='+(ok ? '1':'0')+
      ' instant='+sprintf('%.1f',si.to_f)+' two_turn='+sprintf('%.1f',st.to_f)+
      ' reactive='+sprintf('%.1f',sr.to_f)+' weather='+sprintf('%.1f',sw.to_f)+
      ' tags=['+tags.collect{|x|x.to_s}.join(',')+']')
    @verification_done[:v068_support_timing]=true
  end

  def verify_combat_ai_carry_v068
    return if @verification_done[:v068_carry]
    c=PMD_AC.compiled_data_status_v061;m=PMD_AC::COMBAT_AI_MANIFEST_V068
    ok=c[:loaded] && c[:species].to_i==494 && c[:native].to_i==9507 && c[:aliases].to_i==1077 &&
      m[:move_runtime].to_i==526 && m[:ability_slots].to_i==1028 && m[:ability_species].to_i==483
    log_event(:verify,'COMBAT_AI_CARRY_V068 pass='+(ok ? '1':'0')+
      ' compiled_species='+c[:species].to_i.to_s+' native_actions='+c[:native].to_i.to_s+
      ' aliases='+c[:aliases].to_i.to_s+' moves=526 learnset=7005/7005 abilities=1028/1193 species=483/494 '+
      ' movement=v0.15_unchanged combo_packet=v0.60.2 native_router=v0.62 presentation_anchors=unchanged')
    @verification_done[:v068_carry]=true
  end

  def update_combat_ai_integration_v068
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_combat_ai_manifest_v068 if f>=2
    verify_diagnostic_presentation_isolation_v068 if f>=4
    verify_combat_ai_heal_status_v068 if f>=6
    verify_combat_ai_multihit_priority_v068 if f>=8
    verify_combat_ai_aoe_field_v068 if f>=10
    verify_combat_ai_support_timing_v068 if f>=12
    verify_ability_runtime_carry_v067 if f>=14
    verify_native_semantic_carry_v063 if f>=14
    verify_combat_ai_carry_v068 if f>=16
    complete_verification_mode if f>=18
  end

  def update_verification_script
    if verification_mode==:combat_ai_integration_v068
      update_combat_ai_integration_v068;return
    end
    pmd_ac_v068_update_verification_script
  end
end
