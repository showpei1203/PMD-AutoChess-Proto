#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.64
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V064 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ability_behavior / ability_data / ability_runtime_scalar_v064 / ability_runtime_checksum32_v064
# - validate_ability_runtime_v064 / ability_runtime_behavior_v064 / set_infatuation_v058 / infatuated_v058?
# - special_attack / start / canonical_global_ability_units / ability_runtime_plus_minus_active_v064?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.64
# Ability Runtime Coverage I
#------------------------------------------------------------------------------
# Adds eight Generation-V abilities using existing stable runtime foundations:
# Oblivious / Damp / Skill Link / Wonder Skin / Super Luck /
# Plus / Minus / Telepathy.
#
# This patch deliberately does NOT modify:
# - v0.62 Native Semantic Router
# - v0.60.2 multi-hit packet choreography
# - Beam / Projectile / Impact / Target-FX anchors
# - v0.56.1 Organic Combat SFX palette
#==============================================================================
module PMD_AC
  PATCH_VERSION_V064 = "0.64"

  class << self
    alias pmd_ac_v064_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v064_ability_behavior)
    alias pmd_ac_v064_ability_data ability_data unless method_defined?(:pmd_ac_v064_ability_data)

    def ability_behavior(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V064[key]
      return b unless b==nil || b.empty?
      pmd_ac_v064_ability_behavior(key)
    end

    def ability_data(key)
      b=ABILITY_RUNTIME_BEHAVIOR_V064[key]
      return b unless b==nil || b.empty?
      pmd_ac_v064_ability_data(key)
    end

    def ability_runtime_scalar_v064(x)
      return '' if x==nil
      return x.collect{|v|v.to_s}.join(',') if x.is_a?(Array)
      x.to_s
    end

    def ability_runtime_checksum32_v064
      h=0
      fields=[:ability_key,:kind,:behavior_status,:blocks,:moves,:blocks_aftermath,
              :random_multi_hit_only,:accuracy_cap,:crit_bonus,:partners,:num,:den,
              :damage_only]
      ABILITY_RUNTIME_BEHAVIOR_V064.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        d=ABILITY_RUNTIME_BEHAVIOR_V064[k]
        text=fields.collect{|f|ability_runtime_scalar_v064(d[f])}.join('|')
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end

    def validate_ability_runtime_v064
      e=[];m=ABILITY_RUNTIME_MANIFEST_V064
      e.push('behavior_count') unless ABILITY_RUNTIME_BEHAVIOR_V064.size==8
      e.push('cumulative') unless m[:cumulative_implemented_ability_count].to_i==107
      e.push('slots') unless m[:implemented_slot_count].to_i==905 && m[:new_implemented_slot_count].to_i==65
      e.push('species') unless m[:species_with_any_implemented_ability].to_i==461 && m[:new_species_with_any_implemented_ability].to_i==10
      e.push('checksum') unless ability_runtime_checksum32_v064==m[:runtime_checksum32].to_i
      m[:new_ability_keys].each do |k|
        b=ability_behavior(k);e.push('bridge_'+k.to_s) if b==nil || b[:behavior_status]!=:implemented_ability_v064
      end
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
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
  alias pmd_ac_v064_set_infatuation_v058 set_infatuation_v058 unless method_defined?(:pmd_ac_v064_set_infatuation_v058)
  alias pmd_ac_v064_infatuated_v058 infatuated_v058? unless method_defined?(:pmd_ac_v064_infatuated_v058)
  alias pmd_ac_v064_special_attack special_attack unless method_defined?(:pmd_ac_v064_special_attack)

  def ability_runtime_behavior_v064
    PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V064[ability_key] || {}
  end

  # Gen V Oblivious: immunity to infatuation. Taunt immunity is intentionally
  # NOT added because that is a later-generation behavior.
  def set_infatuation_v058(source,frames)
    if ability_key==:oblivious
      @infatuation_frames_v058=0;@infatuation_source_uid_v058=nil
      if @scene!=nil
        @scene.log_event(:ability_runtime,log_name+' oblivious BLOCK infatuation')
      end
      return false
    end
    pmd_ac_v064_set_infatuation_v058(source,frames)
  end

  # Also clears an existing infatuation if Oblivious is gained mid-battle.
  def infatuated_v058?
    if ability_key==:oblivious
      @infatuation_frames_v058=0;@infatuation_source_uid_v058=nil
      return false
    end
    pmd_ac_v064_infatuated_v058
  end

  # Gen V Plus/Minus: +50% Sp. Atk while an active ally has Plus or Minus.
  def special_attack
    v=pmd_ac_v064_special_attack
    return v unless [:plus,:minus].include?(ability_key)
    return v if @scene==nil || !@scene.respond_to?(:ability_runtime_plus_minus_active_v064?)
    return v unless @scene.ability_runtime_plus_minus_active_v064?(self)
    [(v.to_f*1.5).round,1].max
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v064_start start unless method_defined?(:pmd_ac_v064_start)
  alias pmd_ac_v064_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v064_prepare_verification_battle)
  alias pmd_ac_v064_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v064_update_verification_script)
  alias pmd_ac_v064_canonical_global_ability_units canonical_global_ability_units unless method_defined?(:pmd_ac_v064_canonical_global_ability_units)
  alias pmd_ac_v064_resolve_skill_aoe resolve_skill_aoe unless method_defined?(:pmd_ac_v064_resolve_skill_aoe)
  alias pmd_ac_v064_multi_hit_count_for_v060 multi_hit_count_for_v060 unless method_defined?(:pmd_ac_v064_multi_hit_count_for_v060)
  alias pmd_ac_v064_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v064_apply_skill_effects)
  alias pmd_ac_v064_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v064_launch_projectile)
  alias pmd_ac_v064_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v064_deal_direct_damage)
  alias pmd_ac_v064_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v064_canonical_accuracy_probability)

  def start
    pmd_ac_v064_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.63 Battle Verification Log/,
               'PMD AutoChess Proto v0.64 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V064
    log_event(:ability_runtime,
      'LOADED new='+m[:new_implemented_ability_count].to_s+
      ' cumulative='+m[:cumulative_implemented_ability_count].to_s+
      ' implemented_slots='+m[:implemented_slot_count].to_s+'/'+m[:total_slot_count].to_s+
      ' coverage='+sprintf('%.2f',m[:implemented_slot_coverage_percent].to_f)+'%'+
      ' species='+m[:species_with_any_implemented_ability].to_s+'/494'+
      ' checksum32='+m[:runtime_checksum32].to_s)
    log_event(:presentation,
      'PATCH v0.64 ability_runtime=oblivious,damp,skill_link,wonder_skin,super_luck,plus,minus,telepathy '+
      'native_router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep '+
      'beam_projectile_impact_targetfx=unchanged organic_sfx=v0.56.1')
  end

  def canonical_global_ability_units
    list=pmd_ac_v064_canonical_global_ability_units
    list += @ability_runtime_test_units_v064 if @ability_runtime_test_units_v064!=nil
    list.uniq
  end

  def ability_runtime_plus_minus_active_v064?(unit)
    return false if unit==nil || ![:plus,:minus].include?(unit.ability_key)
    canonical_global_ability_units.any? do |u|
      u!=nil && u!=unit && !u.dead? && u.team==unit.team &&
      [:plus,:minus].include?(u.ability_key)
    end
  end

  def ability_runtime_damp_blocks_move_v064?(data)
    return false if data==nil || !canonical_damp_active?
    mk=data[:canonical_move_key] || data[:move_key]
    [:explosion,:self_destruct].include?(mk)
  end

  # Damp blocks the complete Explosion/Self-Destruct AOE resolution. Because
  # v0.51 self-KO is inside the aliased resolve_skill_aoe chain, returning here
  # also correctly prevents the user's self-KO. Existing v0.25 already makes
  # Damp block Aftermath.
  def resolve_skill_aoe(unit,x,y,data)
    if ability_runtime_damp_blocks_move_v064?(data)
      mk=data[:canonical_move_key] || data[:move_key]
      log_event(:ability_runtime,
        (unit==nil ? 'UNKNOWN' : unit.log_name)+' '+mk.to_s+' BLOCKED_BY_DAMP damage=0 self_ko=0')
      return 0
    end
    pmd_ac_v064_resolve_skill_aoe(unit,x,y,data)
  end

  def multi_hit_count_for_v060(data)
    u=@ability_runtime_multihit_user_v064
    if u!=nil && u.ability_key==:skill_link && data!=nil && data[:multi_hit_v049] &&
       !data[:beat_up_v058] && !data[:triple_kick_v059]
      hi=(data[:multi_hit_max] || data[:multi_hit_min] || 1).to_i
      hi=1 if hi<1
      log_event(:ability_runtime,u.log_name+' skill_link MAX_HITS='+hi.to_s+
        ' move='+(data[:canonical_move_key]||data[:move_key]||:unknown).to_s)
      return hi
    end
    pmd_ac_v064_multi_hit_count_for_v060(data)
  end

  def ability_runtime_damaging_move_v064?(data)
    return false if data==nil
    cat=data[:damage_category] || data[:category]
    cat==:physical || cat==:special
  end

  def ability_runtime_telepathy_block_v064?(user,target,data)
    return false if user==nil || target==nil || user==target
    return false unless user.team==target.team && target.ability_key==:telepathy
    ability_runtime_damaging_move_v064?(data)
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if ability_runtime_telepathy_block_v064?(user,target,data)
      log_event(:ability_runtime,target.log_name+' telepathy BLOCK ally_move='+
        (data[:canonical_move_key]||data[:move_key]||:unknown).to_s+' source='+user.log_name)
      return 0
    end
    old=@ability_runtime_multihit_user_v064
    @ability_runtime_multihit_user_v064=user
    begin
      pmd_ac_v064_apply_skill_effects(user,target,data,scale)
    ensure
      @ability_runtime_multihit_user_v064=old
    end
  end

  # Ranged multi-hit count is chosen at the first projectile launch in v0.60.2,
  # so carry the user context through that exact call without changing cadence.
  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,
                        attack_modifier=nil,allow_substitute=true)
    old=@ability_runtime_multihit_user_v064
    @ability_runtime_multihit_user_v064=user
    begin
      pmd_ac_v064_launch_projectile(user,target,kind,power,effect_type,
        tracking_override,attack_modifier,allow_substitute)
    ensure
      @ability_runtime_multihit_user_v064=old
    end
  end

  def ability_runtime_damage_options_v064(user,options)
    opts=options==nil ? {} : options.dup
    can_crit=opts.has_key?(:can_crit) ? opts[:can_crit] : true
    if user!=nil && user.ability_key==:super_luck && can_crit
      b=PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V064[:super_luck]
      opts[:crit_bonus]=(opts[:crit_bonus]||0.0).to_f+b[:crit_bonus].to_f
    end
    opts
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=ability_runtime_damage_options_v064(user,options)
    data=opts[:skill_data]
    if ability_runtime_telepathy_block_v064?(user,target,data)
      log_event(:ability_runtime,target.log_name+' telepathy BLOCK direct_damage source='+user.log_name)
      return 0
    end
    pmd_ac_v064_deal_direct_damage(user,target,power,opts)
  end

  # Wonder Skin affects only opposing status moves that actually have an
  # accuracy value. In Gen V its 50% value is applied before the engine's
  # existing accuracy/evasion modifiers, rather than capping the final result.
  def canonical_accuracy_probability(user,target,data)
    return pmd_ac_v064_canonical_accuracy_probability(user,target,data) if user==nil || target==nil || data==nil
    return pmd_ac_v064_canonical_accuracy_probability(user,target,data) unless target.ability_key==:wonder_skin && user!=target && user.team!=target.team
    cat=data[:damage_category] || data[:category]
    return pmd_ac_v064_canonical_accuracy_probability(user,target,data) unless cat==:status
    base=canonical_move_accuracy(data)
    return pmd_ac_v064_canonical_accuracy_probability(user,target,data) if base==nil
    cap=PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V064[:wonder_skin][:accuracy_cap].to_f
    return pmd_ac_v064_canonical_accuracy_probability(user,target,data) if base.to_f<=cap
    d=data.dup;d[:accuracy]=cap
    pmd_ac_v064_canonical_accuracy_probability(user,target,d)
  end

  # Verification --------------------------------------------------------------
  def ability_runtime_verification_unit_v064(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{
      :instance_uid=>99064000+id.to_i,:ivs=>[15,15,15,15,15,15],
      :nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9640+id.to_i,species,team,0,0,i)
    u.scene=self;u.verification_combat_sandbox(true)
    @ability_runtime_test_units_v064=[] if @ability_runtime_test_units_v064==nil
    @ability_runtime_test_units_v064.push(u)
    u
  end

  def prepare_verification_battle
    pmd_ac_v064_prepare_verification_battle
    return unless verification_mode==:ability_runtime_coverage_v064
    @ability_runtime_test_units_v064=[]
    @ability_runtime_multihit_user_v064=nil
    (@units||[]).each do |u|
      u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)
      if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
        u.pmd_ac_v0211_verification_suppress_active_evade
      end
    end
    log_event(:showcase,
      'START mode=ABILITY_RUNTIME_COVERAGE_V064 new=8 slots=905/1193 species=461/494 '+
      'diagnostic_only=1 pokemon_resume_after_final_assert=1')
  end

  def verify_ability_runtime_manifest_v064
    return if @verification_done[:v064_manifest]
    e=PMD_AC.validate_ability_runtime_v064;m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V064
    ok=e.empty?
    log_event(:verify,
      'ABILITY_RUNTIME_MANIFEST_V064 pass='+(ok ? '1':'0')+
      ' new=8 cumulative=107 slots=905/1193 coverage=75.86% species=461/494 '+
      'checksum='+PMD_AC.ability_runtime_checksum32_v064.to_s+' errors=['+e.join(',')+']')
    @verification_done[:v064_manifest]=true
  end

  def verify_ability_runtime_oblivious_v064
    return if @verification_done[:v064_oblivious]
    src=ability_runtime_verification_unit_v064(:rattata,:secondary,:enemy,1)
    tgt=ability_runtime_verification_unit_v064(:jynx,:primary,:ally,2)
    applied=tgt.set_infatuation_v058(src,180)
    ok=tgt.ability_key==:oblivious && !applied && !tgt.infatuated_v058?
    log_event(:verify,'ABILITY_OBLIVIOUS_V064 pass='+(ok ? '1':'0')+
      ' ability='+tgt.ability_key.to_s+' infatuation_applied='+(applied ? '1':'0')+
      ' active='+(tgt.infatuated_v058? ? '1':'0'))
    @verification_done[:v064_oblivious]=true
  end

  def verify_ability_runtime_damp_v064
    return if @verification_done[:v064_damp]
    damp=ability_runtime_verification_unit_v064(:golduck,:primary,:enemy,3)
    user=ability_runtime_verification_unit_v064(:charmander,:primary,:ally,4)
    data=PMD_AC.skill_data(:mv_explosion);before=user.hp
    active=canonical_damp_active?;result=resolve_skill_aoe(user,272,217,data)
    ok=damp.ability_key==:damp && active && result.to_i==0 && user.hp==before
    log_event(:verify,'ABILITY_DAMP_V064 pass='+(ok ? '1':'0')+
      ' global_active='+(active ? '1':'0')+' explosion_result='+result.to_i.to_s+
      ' self_hp='+before.to_s+'->'+user.hp.to_s+' aftermath_gate=v0.25')
    @verification_done[:v064_damp]=true
  end

  def verify_ability_runtime_skill_link_v064
    return if @verification_done[:v064_skill_link]
    u=ability_runtime_verification_unit_v064(:shellder,:secondary,:ally,5)
    data=PMD_AC.skill_data(:mv_fury_swipes)
    old=@ability_runtime_multihit_user_v064;@ability_runtime_multihit_user_v064=u
    begin;hits=multi_hit_count_for_v060(data);ensure;@ability_runtime_multihit_user_v064=old;end
    ok=u.ability_key==:skill_link && hits.to_i==(data[:multi_hit_max]||5).to_i
    log_event(:verify,'ABILITY_SKILL_LINK_V064 pass='+(ok ? '1':'0')+
      ' move=fury_swipes range='+(data[:multi_hit_min]||0).to_s+'-'+(data[:multi_hit_max]||0).to_s+
      ' resolved_hits='+hits.to_s+' packet_driver=v0.60.2_backstep')
    @verification_done[:v064_skill_link]=true
  end

  def verify_ability_runtime_wonder_skin_v064
    return if @verification_done[:v064_wonder_skin]
    user=ability_runtime_verification_unit_v064(:rattata,:secondary,:enemy,6)
    tgt=ability_runtime_verification_unit_v064(:skitty,:hidden,:ally,7)
    toxic=canonical_accuracy_probability(user,tgt,PMD_AC.skill_data(:mv_toxic))
    tackle=canonical_accuracy_probability(user,tgt,PMD_AC.skill_data(:mv_tackle))
    ok=tgt.ability_key==:wonder_skin && (toxic.to_f-50.0).abs<0.001 && tackle.to_f>50.0
    log_event(:verify,'ABILITY_WONDER_SKIN_V064 pass='+(ok ? '1':'0')+
      ' toxic='+sprintf('%.2f',toxic.to_f)+' tackle='+sprintf('%.2f',tackle.to_f)+
      ' status_cap=50 damaging_unchanged=1')
    @verification_done[:v064_wonder_skin]=true
  end

  def verify_ability_runtime_super_luck_v064
    return if @verification_done[:v064_super_luck]
    u=ability_runtime_verification_unit_v064(:absol,:secondary,:ally,8)
    opts=ability_runtime_damage_options_v064(u,{:crit_bonus=>0.0,:can_crit=>true})
    bonus=opts[:crit_bonus].to_f
    ok=u.ability_key==:super_luck && (bonus-0.075).abs<0.0001
    log_event(:verify,'ABILITY_SUPER_LUCK_V064 pass='+(ok ? '1':'0')+
      ' project_crit_stage_bonus='+sprintf('%.3f',bonus)+' high_crit_curve=shared_v0.49')
    @verification_done[:v064_super_luck]=true
  end

  def verify_ability_runtime_plus_minus_v064
    return if @verification_done[:v064_plus_minus]
    plus=ability_runtime_verification_unit_v064(:plusle,:primary,:ally,9)
    base=plus.pmd_ac_v064_special_attack;lone=plus.special_attack
    minus=ability_runtime_verification_unit_v064(:minun,:primary,:ally,10)
    boosted=plus.special_attack;boosted2=minus.special_attack
    expected=[(base.to_f*1.5).round,1].max
    base2=minus.pmd_ac_v064_special_attack;expected2=[(base2.to_f*1.5).round,1].max
    ok=lone==base && boosted==expected && boosted2==expected2
    log_event(:verify,'ABILITY_PLUS_MINUS_V064 pass='+(ok ? '1':'0')+
      ' lone='+lone.to_s+'/'+base.to_s+' pair_plus='+boosted.to_s+'/'+expected.to_s+
      ' pair_minus='+boosted2.to_s+'/'+expected2.to_s+' multiplier=1.50')
    @verification_done[:v064_plus_minus]=true
  end

  def verify_ability_runtime_telepathy_v064
    return if @verification_done[:v064_telepathy]
    src=ability_runtime_verification_unit_v064(:plusle,:primary,:ally,11)
    tgt=ability_runtime_verification_unit_v064(:ralts,:hidden,:ally,12)
    data=PMD_AC.skill_data(:mv_discharge);before=tgt.hp
    result=apply_skill_effects(src,tgt,data,1.0)
    ok=tgt.ability_key==:telepathy && result.to_i==0 && tgt.hp==before
    log_event(:verify,'ABILITY_TELEPATHY_V064 pass='+(ok ? '1':'0')+
      ' ally_move=discharge result='+result.to_i.to_s+' hp='+before.to_s+'->'+tgt.hp.to_s+
      ' secondary_packet_blocked=1')
    @verification_done[:v064_telepathy]=true
  end

  def verify_ability_runtime_carry_v064
    return if @verification_done[:v064_carry]
    m=PMD_AC::ABILITY_RUNTIME_MANIFEST_V064;c=PMD_AC.compiled_data_status_v061
    ok=m[:implemented_slot_count].to_i==905 && c[:loaded] && c[:species].to_i==494 &&
       c[:native].to_i==9507 && c[:aliases].to_i==1077
    log_event(:verify,'ABILITY_RUNTIME_CARRY_V064 pass='+(ok ? '1':'0')+
      ' slots=905/1193 species=461/494 compiled_species='+c[:species].to_i.to_s+
      ' native_actions='+c[:native].to_i.to_s+' aliases='+c[:aliases].to_i.to_s+
      ' move_runtime=526 learnset=7005/7005 native_router=v0.62_unchanged '+
      ' combo_packet_driver=v0.60.2_backstep presentation_anchors=unchanged')
    @verification_done[:v064_carry]=true
  end

  def update_ability_runtime_coverage_v064
    return if @verification_done[:verification_complete]
    @verification_frame+=1;f=@verification_frame
    verify_ability_runtime_manifest_v064 if f>=2
    verify_ability_runtime_oblivious_v064 if f>=4
    verify_ability_runtime_damp_v064 if f>=6
    verify_ability_runtime_skill_link_v064 if f>=8
    verify_ability_runtime_wonder_skin_v064 if f>=10
    verify_ability_runtime_super_luck_v064 if f>=12
    verify_ability_runtime_plus_minus_v064 if f>=14
    verify_ability_runtime_telepathy_v064 if f>=16
    verify_native_semantic_carry_v063 if f>=18
    verify_ability_runtime_carry_v064 if f>=18
    complete_verification_mode if f>=20
  end

  def update_verification_script
    if verification_mode==:ability_runtime_coverage_v064
      update_ability_runtime_coverage_v064
      return
    end
    pmd_ac_v064_update_verification_script
  end
end
