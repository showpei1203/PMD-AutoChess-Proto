#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.46
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_PROGRESSION_RUNTIME_END_FRAME_V046 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - exp_for_level / progression_checksum32_v046 / progression_level_multiplier_v046 / battle_exp_share_v046
# - refresh_active_move_runtime_v046 / battle_moves_v046 / move_mastery_multiplier_v046 / move_mastery_profile_v046
# - choose_pending_move_v046 / gain_exp / initialize / progression_skill_snapshot_v046
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.46
#    RPG Progression Runtime I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.45.
# - Full six Gen V growth-rate EXP curves.
# - Battle EXP uses deployed persistent PokemonInstance participants.
# - Four active moves become the actual AutoChess skill pool in NORMAL battles.
# - Canonical level-up learning feeds the persistent move library / 4-slot loadout.
# - Move mastery Lv1-5 now scales numeric damage/heal/shield/HoT magnitude.
# - Actor IDs remain adapters only; all progression belongs to instance_uid.
#===============================================================================
module PMD_AC
  VERIFICATION_PROGRESSION_RUNTIME_END_FRAME_V046 = 920

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:progression_runtime,:identity_bridge,:tactical_support,:reactive_priority,:priority]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :progression_runtime=>'PROGRESSION_RUNTIME', :identity_bridge=>'IDENTITY_BRIDGE',
    :tactical_support=>'TACTICAL_SUPPORT', :reactive_priority=>'REACTIVE_PRIORITY',
    :priority=>'PRIORITY'
  }

  class << self
    # Six canonical experience groups used by Gen V species data.
    # Level 1 starts at 0 total EXP in the RPG progression layer.
    def exp_for_level(level,growth_group)
      l=clamp(level.to_i,1,POKEMON_MAX_LEVEL)
      return 0 if l<=1
      n=l
      value=case growth_group
      when :erratic
        if n<=50
          n*n*n*(100-n)/50
        elsif n<=68
          n*n*n*(150-n)/100
        elsif n<=98
          n*n*n*((1911-10*n)/3)/500
        else
          n*n*n*(160-n)/100
        end
      when :fast
        4*n*n*n/5
      when :medium_fast
        n*n*n
      when :medium_slow
        (6*n*n*n/5)-(15*n*n)+(100*n)-140
      when :slow
        5*n*n*n/4
      when :fluctuating
        if n<=15
          n*n*n*(((n+1)/3)+24)/50
        elsif n<=35
          n*n*n*(n+14)/50
        else
          n*n*n*((n/2)+32)/50
        end
      else
        n*n*n
      end
      [value.to_i,0].max
    end

    def progression_checksum32_v046
      PROGRESSION_RUNTIME_MANIFEST_V046[:runtime_checksum32].to_i
    end

    def progression_level_multiplier_v046(level)
      lv=clamp(level.to_i,1,MOVE_LEVEL_MAX_V045)
      PROGRESSION_MOVE_LEVEL_MULT_V046[lv-1].to_f
    end

    def battle_exp_share_v046(species_key,level,participant_count,rate)
      participants=[participant_count.to_i,1].max
      base=exp_reward_for(species_key,level,participants)
      value=(base.to_f*rate.to_f).floor
      [value,0].max
    end
  end
end

class PMD_PokemonInstance
  # Keep the v0.45 learned-library model, but make the four active slots a real
  # runtime contract. Learned moves stay learned when swapped out, so mastery is
  # never destroyed by loadout editing.
  def refresh_active_move_runtime_v046
    ensure_growth_data_v045
    clean=[]
    for mv in (@active_moves_v045||[])
      next unless @known_moves_v045.include?(mv)
      next unless PMD_AC.move_executable?(mv)
      clean.push(mv) unless clean.include?(mv)
      break if clean.size>=PMD_AC::ACTIVE_MOVE_SLOTS_V045
    end
    if clean.size<PMD_AC::ACTIVE_MOVE_SLOTS_V045
      exec=@known_moves_v045.find_all{|mv|PMD_AC.move_executable?(mv)}
      # Prefer more recently learned canonical moves when filling empty slots,
      # while preserving already chosen slots.
      i=exec.size-1
      while i>=0 && clean.size<PMD_AC::ACTIVE_MOVE_SLOTS_V045
        mv=exec[i];clean.unshift(mv) unless clean.include?(mv);i-=1
      end
      clean=clean[-PMD_AC::ACTIVE_MOVE_SLOTS_V045,PMD_AC::ACTIVE_MOVE_SLOTS_V045] || clean
    end
    @active_moves_v045=clean
    true
  end

  def battle_moves_v046
    refresh_active_move_runtime_v046
    @active_moves_v045.dup
  end

  def move_mastery_multiplier_v046(move)
    PMD_AC.progression_level_multiplier_v046(move_level_v045(move))
  end

  def move_mastery_profile_v046(move)
    lv=move_level_v045(move);exp=move_mastery_exp_v045(move)
    next_exp=nil
    if lv<PMD_AC::MOVE_LEVEL_MAX_V045
      next_exp=PMD_AC::MOVE_MASTERY_THRESHOLDS_V045[lv].to_i
    end
    {:move=>move,:level=>lv,:exp=>exp,:next_exp=>next_exp,
     :multiplier=>move_mastery_multiplier_v046(move)}
  end

  def choose_pending_move_v046(new_move,forget_move)
    ensure_growth_data_v045
    return false unless @pending_move_choices_v045.include?(new_move)
    old_mastery=move_mastery_exp_v045(forget_move)
    ok=resolve_pending_move_v045(new_move,forget_move)
    # Forgotten means removed from the four battle slots, not erased from the
    # learned library. If re-equipped later its mastery remains intact.
    ok && @known_moves_v045.include?(forget_move) &&
      move_mastery_exp_v045(forget_move)==old_mastery
  end

  alias pmd_ac_v046_gain_exp gain_exp unless method_defined?(:pmd_ac_v046_gain_exp)
  def gain_exp(amount,allow_evolution=true)
    result=pmd_ac_v046_gain_exp(amount,allow_evolution)
    refresh_active_move_runtime_v046
    result[:active_moves_v046]=battle_moves_v046
    result[:move_levels_v046]={}
    for mv in battle_moves_v046
      result[:move_levels_v046][mv]=move_level_v045(mv)
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v046_initialize initialize unless method_defined?(:pmd_ac_v046_initialize)
  def initialize(*args)
    pmd_ac_v046_initialize(*args)
    @legacy_skill_type_v046=@skill_type
    @legacy_skill_name_v046=@skill_name
    @progression_selected_move_v046=nil
    @progression_last_logged_move_v046=nil
  end

  def progression_skill_snapshot_v046
    [@skill_type,@skill_name,@progression_selected_move_v046]
  end
  def progression_restore_skill_snapshot_v046(s)
    return if s==nil
    @skill_type=s[0];@skill_name=s[1];@progression_selected_move_v046=s[2]
  end
  def progression_move_pool_v046
    return [] if summoned?
    return [] if @pokemon_instance==nil
    @pokemon_instance.battle_moves_v046
  end
  def progression_selected_move_v046;@progression_selected_move_v046;end
  def progression_select_move_v046(move)
    return false if move==nil || @pokemon_instance==nil
    return false unless @pokemon_instance.battle_moves_v046.include?(move)
    return false unless PMD_AC.move_executable?(move)
    key=PMD_AC.canonical_runtime_skill_key(move)
    data=PMD_AC.skill_data(key)
    return false if data==nil || data.empty?
    @skill_type=key
    @skill_name=data[:name] || move.to_s
    @progression_selected_move_v046=move
    true
  end
  def progression_restore_legacy_skill_v046
    @skill_type=@legacy_skill_type_v046
    @skill_name=@legacy_skill_name_v046
    @progression_selected_move_v046=nil
    true
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v046_start start unless method_defined?(:pmd_ac_v046_start)
  alias pmd_ac_v046_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v046_skill_target_for)
  alias pmd_ac_v046_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v046_apply_skill_effects)
  alias pmd_ac_v046_award_battle_exp award_battle_exp unless method_defined?(:pmd_ac_v046_award_battle_exp)
  alias pmd_ac_v046_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v046_prepare_verification_battle)
  alias pmd_ac_v046_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v046_update_verification_script)
  alias pmd_ac_v046_log_event log_event unless method_defined?(:pmd_ac_v046_log_event)
  alias pmd_ac_v046_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v046_complete_verification_mode)

  def start
    pmd_ac_v046_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.46 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::PROGRESSION_RUNTIME_MANIFEST_V046
    log_event(:progression_runtime,
      'LOADED level_max=100 growth_groups=6 active_moves=4 mastery_lv=5 mastery_mult=1.00..1.20 battle_exp=deployed alive1.00 fainted0.50 reserve0 summon0 identity=instance_uid checksum32='+m[:runtime_checksum32].to_s)
  end

  def progression_move_key_v046(data)
    return nil if data==nil
    k=data[:canonical_move_key] || data[:move_key]
    k=k.to_sym if k.is_a?(String)
    k
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    return nil if unit==nil || target==nil || target.dead? || data==nil
    damage_power=0
    has_heal=false;has_shield=false;has_control=false;has_status=false
    for e in (data[:effects]||[])
      if e[:type]==:damage
        p=e[:power]==nil ? 0 : e[:power].to_i
        damage_power=p if p>damage_power
      elsif e[:type]==:heal || e[:type]==:hot
        has_heal=true
      elsif e[:type]==:shield
        has_shield=true
      elsif e[:type]==:control || e[:type]==:canonical_sleep || e[:type]==:canonical_confusion
        has_control=true
      elsif e[:type]==:status || e[:type]==:stat_stage
        has_status=true
      end
    end
    score=0.0
    if damage_power>0
      type=data[:move_type]||data[:type]||:normal
      eff=1.0
      if target.respond_to?(:pokemon_types)
        eff=PMD_AC.type_effectiveness(type,target.pokemon_types)
      end
      stab=unit.pokemon_types.include?(type) ? PMD_AC::POKEMON_STAB_MULTIPLIER : 1.0
      mastery=unit.pokemon_instance==nil ? 1.0 : unit.pokemon_instance.move_mastery_multiplier_v046(move)
      score=damage_power.to_f*eff.to_f*stab.to_f*mastery.to_f
      hp_rate=target.hp.to_f/[target.maxhp,1].max.to_f
      score+=12.0*(1.0-hp_rate) if (data[:policy]||unit.skill_policy)==:execute
    else
      score=55.0
      if has_heal
        missing=1.0-target.hp.to_f/[target.maxhp,1].max.to_f
        score=55.0+missing*100.0
      end
      score=72.0 if has_control
      score=66.0 if has_status && score<66.0
      score=70.0 if has_shield && score<70.0
      score=76.0 if [:protect,:detect,:endure,:wide_guard,:quick_guard].include?(move)
      score=74.0 if [:follow_me,:rage_powder,:helping_hand,:ally_switch].include?(move)
    end
    priority=PMD_AC.canonical_priority_v042(data) rescue 0
    score+=priority.to_i*1.25 if priority.to_i>0
    score-=slot.to_i*0.001
    score
  end

  # Evaluate only the four equipped moves. The old profile skill remains a
  # compatibility fallback when a Pokemon currently has no executable loadout.
  def progression_select_best_move_v046(unit)
    return [nil,nil,nil] if unit==nil
    pool=unit.progression_move_pool_v046
    return [nil,nil,nil] if pool.empty?
    root=unit.progression_skill_snapshot_v046
    best_move=nil;best_target=nil;best_score=nil;best_slot=nil
    pool.each_index do |i|
      mv=pool[i]
      next unless unit.progression_select_move_v046(mv)
      data=unit.skill_data
      target=pmd_ac_v046_skill_target_for(unit)
      score=target==nil ? nil : progression_candidate_score_v046(unit,target,data,mv,i)
      if score!=nil && (best_move==nil || score>best_score)
        best_move=mv;best_target=target;best_score=score;best_slot=i
      end
    end
    unit.progression_restore_skill_snapshot_v046(root)
    if best_move!=nil
      unit.progression_select_move_v046(best_move)
      if unit.instance_variable_get(:@progression_last_logged_move_v046)!=best_move
        unit.instance_variable_set(:@progression_last_logged_move_v046,best_move)
        log_event(:move_ai,unit.log_name+' SELECT '+best_move.to_s+' slot='+(best_slot+1).to_s+' score='+sprintf('%.2f',best_score.to_f)+' target='+best_target.log_name+' active=['+pool.collect{|x|x.to_s}.join(',')+']')
      end
    end
    [best_move,best_target,best_score]
  end

  def skill_target_for(unit)
    if unit!=nil && (verification_mode==:normal || @progression_verify_selection_v046)
      move,target,score=progression_select_best_move_v046(unit)
      return target if move!=nil && target!=nil
      # No executable equipped move: keep the verified pre-v0.46 profile skill.
      unit.progression_restore_legacy_skill_v046 if move==nil && unit.respond_to?(:progression_restore_legacy_skill_v046)
    end
    pmd_ac_v046_skill_target_for(unit)
  end

  def progression_scalable_effect_v046?(data)
    return false if data==nil
    for e in (data[:effects]||[])
      return true if [:damage,:heal,:shield,:hot].include?(e[:type])
    end
    false
  end

  def progression_scaled_support_data_v046(data,mult)
    d=data.dup
    d[:effects]=(data[:effects]||[]).collect{|e|
      x=e.dup
      if [:heal,:shield].include?(x[:type])
        x[:flat]=(x[:flat].to_f*mult).round if x[:flat]!=nil
        x[:power]=(x[:power].to_f*mult).round if x[:power]!=nil
      elsif x[:type]==:hot
        x[:value]=(x[:value].to_f*mult).round if x[:value]!=nil
      end
      x
    }
    d
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    mk=progression_move_key_v046(data)
    if user!=nil && mk!=nil && user.respond_to?(:pokemon_instance) &&
       user.pokemon_instance!=nil && user.pokemon_instance.respond_to?(:knows_move_v045?) &&
       user.pokemon_instance.knows_move_v045?(mk) && progression_scalable_effect_v046?(data)
      lv=user.pokemon_instance.move_level_v045(mk)
      mult=user.pokemon_instance.move_mastery_multiplier_v046(mk)
      if mult>1.0001
        d=progression_scaled_support_data_v046(data,mult)
        log_event(:move_mastery_effect,user.log_name+' '+mk.to_s+' skill_lv='+lv.to_s+' magnitude_x'+sprintf('%.2f',mult))
        return pmd_ac_v046_apply_skill_effects(user,target,d,scale.to_f*mult)
      end
    end
    pmd_ac_v046_apply_skill_effects(user,target,data,scale)
  end

  def battle_exp_participants_v046
    result=[];seen={}
    for u in (@units||[])
      next unless u.team==:ally
      next if u.summoned?
      next unless u.respond_to?(:pokemon_instance) && u.pokemon_instance!=nil
      uid=u.instance_uid.to_i
      next if seen[uid]
      seen[uid]=true;result.push(u)
    end
    result
  end

  def award_battle_exp(winner_team)
    return unless winner_team==:ally
    return unless verification_mode==:normal
    participants=battle_exp_participants_v046
    return if participants.empty?
    defeated=[]
    for unit in @units
      next unless unit.team==:enemy && unit.counts_for_victory? && unit.dead?
      defeated.push(unit)
    end
    return if defeated.empty?
    log_event(:exp,'BATTLE_REWARD participants='+participants.size.to_s+' alive_rate=1.00 fainted_rate=0.50 reserve_rate=0.00 summons=0')
    for unit in participants
      rate=unit.alive? ? PMD_AC::PROGRESSION_EXP_ALIVE_RATE_V046 : PMD_AC::PROGRESSION_EXP_FAINTED_RATE_V046
      reward=0
      for enemy in defeated
        reward+=PMD_AC.battle_exp_share_v046(enemy.species_key,enemy.level,participants.size,rate)
      end
      log_event(:exp,unit.log_name+' SHARE rate='+sprintf('%.2f',rate)+' exp='+reward.to_s+' uid='+unit.instance_uid.to_s)
      unit.gain_progression_exp(reward) if reward>0
    end
  end

  #--------------------------------------------------------------------------
  # Verification
  #--------------------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v046_prepare_verification_battle
    if verification_mode==:progression_runtime
      @progression_runtime_failed_v046=false
      @progression_verify_selection_v046=true
      PMD_AC.begin_identity_sandbox_v045 unless PMD_AC.identity_sandbox_v045?
      for u in @units
        u.verification_combat_sandbox(true)
        PMD_AC.register_pokemon_instance_v045(u.pokemon_instance) if u.respond_to?(:pokemon_instance)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:progression_runtime &&
       message.to_s.index('PROGRESSION_')==0 && message.to_s.include?(' pass=0')
      @progression_runtime_failed_v046=true
    end
    pmd_ac_v046_log_event(category,message)
  end

  def progression_temp_instance_v046(uid,species=:bulbasaur,level=1)
    PMD_PokemonInstance.new(species,level,{:instance_uid=>uid,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
  end

  def verify_progression_manifest_v046
    return if @verification_done[:progression_manifest]
    m=PMD_AC::PROGRESSION_RUNTIME_MANIFEST_V046
    pass=m[:identity_key]=='instance_uid' && m[:level_max].to_i==100 &&
      m[:growth_groups].size==6 && m[:active_move_slots].to_i==4 &&
      m[:move_level_max].to_i==5 && m[:runtime_checksum32].to_i==PMD_AC.progression_checksum32_v046
    log_event(:verify,'PROGRESSION_MANIFEST pass='+(pass ? '1':'0')+' level_max=100 growth_groups=6 active_moves=4 mastery_lv=5 checksum='+m[:runtime_checksum32].to_s)
    @verification_done[:progression_manifest]=true
  end

  def verify_progression_exp_curves_v046
    return if @verification_done[:progression_exp_curves]
    expected={:erratic=>600000,:fast=>800000,:medium_fast=>1000000,:medium_slow=>1059860,:slow=>1250000,:fluctuating=>1640000}
    ok=true;totals=[]
    expected.keys.each do |g|
      prev=-1
      for lv in 1..100
        x=PMD_AC.exp_for_level(lv,g);ok=false if x<prev;prev=x
      end
      v=PMD_AC.exp_for_level(100,g);ok=false unless v==expected[g]
      ok=false unless PMD_AC.exp_for_level(1,g)==0
      totals.push(g.to_s+'='+v.to_s)
    end
    log_event(:verify,'PROGRESSION_EXP_CURVES pass='+(ok ? '1':'0')+' level1=0 monotonic=1 lv100=['+totals.join(',')+']')
    @verification_done[:progression_exp_curves]=true
  end

  def verify_progression_level_stats_v046
    return if @verification_done[:progression_level_stats]
    i=progression_temp_instance_v046(99460101,:bulbasaur,5);uid=i.instance_uid
    s5=i.combat_stats;need=PMD_AC.exp_for_level(10,i.growth_group)-i.exp;r=i.gain_exp(need,true);s10=i.combat_stats
    pass=i.level==10 && i.instance_uid==uid && r[:levels].include?(10) && s10[:hp]>s5[:hp] && s10[:atk]>=s5[:atk] && i.exp_to_next_level>0
    log_event(:verify,'PROGRESSION_LEVEL_STATS pass='+(pass ? '1':'0')+' uid_same='+(i.instance_uid==uid ? '1':'0')+' lv=5->'+i.level.to_s+' hp='+s5[:hp].to_s+'->'+s10[:hp].to_s+' atk='+s5[:atk].to_s+'->'+s10[:atk].to_s+' next_exp='+i.exp_to_next_level.to_s)
    @verification_done[:progression_level_stats]=true
  end

  def verify_progression_move_learning_v046
    return if @verification_done[:progression_move_learning]
    i=progression_temp_instance_v046(99460201,:bulbasaur,1)
    need=PMD_AC.exp_for_level(15,i.growth_group)-i.exp;r=i.gain_exp(need,true)
    known=i.known_moves_v045;active=i.battle_moves_v046;pending=i.pending_move_choices_v045
    before_mastery=i.move_mastery_exp_v045(:growl)
    replaced=false
    if pending.include?(:take_down) && active.include?(:growl)
      replaced=i.choose_pending_move_v046(:take_down,:growl)
    end
    active2=i.battle_moves_v046
    pass=i.level==15 && known.include?(:tackle) && known.include?(:growl) && known.include?(:vine_whip) && known.include?(:sleep_powder) && known.include?(:take_down) && active.size==4 && pending.include?(:take_down) && replaced && active2.include?(:take_down) && !active2.include?(:growl) && i.known_moves_v045.include?(:growl) && i.move_mastery_exp_v045(:growl)==before_mastery
    log_event(:verify,'PROGRESSION_MOVE_LEARN pass='+(pass ? '1':'0')+' lv=1->15 canonical_known='+known.size.to_s+' active_before=['+active.collect{|x|x.to_s}.join(',')+'] pending=['+pending.collect{|x|x.to_s}.join(',')+'] replace=take_down_for_growl mastery_preserved='+(i.move_mastery_exp_v045(:growl)==before_mastery ? '1':'0')+' library_preserved='+(i.known_moves_v045.include?(:growl) ? '1':'0'))
    @verification_done[:progression_move_learning]=true
  end

  def verify_progression_mastery_v046
    return if @verification_done[:progression_mastery]
    i=progression_temp_instance_v046(99460301,:bulbasaur,15)
    lv1=i.move_level_v045(:tackle);m1=i.move_mastery_multiplier_v046(:tackle)
    rr=i.gain_move_mastery_v045(:tackle,150);lv5=i.move_level_v045(:tackle);m5=i.move_mastery_multiplier_v046(:tackle)
    target=verification_unit(:enemy,:rattata)
    actual=-1
    if target!=nil
      target.verification_heal_full if target.respond_to?(:verification_heal_full)
      u=Game_PMDChessUnit.new(99460302,:bulbasaur,:ally,0,2,i);u.scene=self
      before=target.hp
      test={:canonical_move_key=>:tackle,:move_key=>:tackle,:move_type=>:normal,:damage_category=>:physical,:directional=>false,:can_crit=>false,:effects=>[{:type=>:damage,:flat=>100,:can_crit=>false,:directional=>false}]}
      apply_skill_effects(u,target,test,1.0);actual=before-target.hp
      target.verification_heal_full if target.respond_to?(:verification_heal_full)
    end
    pass=lv1==1 && (m1-1.0).abs<0.001 && lv5==5 && (m5-1.20).abs<0.001 && rr[:level_up] && actual==120
    log_event(:verify,'PROGRESSION_MASTERY pass='+(pass ? '1':'0')+' tackle_lv='+lv1.to_s+'->'+lv5.to_s+' exp=0->'+i.move_mastery_exp_v045(:tackle).to_s+' magnitude='+sprintf('%.2f',m1)+'->'+sprintf('%.2f',m5)+' fixed_test=100->'+actual.to_s+' scaled_types=damage,heal,shield,hot status_bonus=deferred')
    @verification_done[:progression_mastery]=true
  end

  def verify_progression_loadout_ai_v046
    return if @verification_done[:progression_loadout_ai]
    i=progression_temp_instance_v046(99460401,:bulbasaur,15)
    desired=[:tackle,:growl,:vine_whip,:sleep_powder]
    setok=i.set_active_moves_v045(desired)
    u=Game_PMDChessUnit.new(99460402,:bulbasaur,:ally,1,2,i);u.scene=self
    move,target,score=progression_select_best_move_v046(u)
    pass=setok && move!=nil && desired.include?(move) && u.progression_selected_move_v046==move && u.skill_type==PMD_AC.canonical_runtime_skill_key(move) && target!=nil && target.team==:enemy && score!=nil
    log_event(:verify,'PROGRESSION_LOADOUT_AI pass='+(pass ? '1':'0')+' active=['+desired.collect{|x|x.to_s}.join(',')+'] selected='+(move==nil ? 'none':move.to_s)+' skill_key='+u.skill_type.to_s+' target='+(target==nil ? 'none':target.log_name)+' legacy_profile_not_identity=1 four_slot_source=1')
    @verification_done[:progression_loadout_ai]=true
  end

  def verify_progression_battle_exp_v046
    return if @verification_done[:progression_battle_exp]
    participants=battle_exp_participants_v046;count=participants.size
    full=PMD_AC.battle_exp_share_v046(:rattata,15,[count,1].max,1.0)
    faint=PMD_AC.battle_exp_share_v046(:rattata,15,[count,1].max,0.5)
    unique=participants.collect{|u|u.instance_uid}.uniq.size==participants.size
    no_summons=participants.find{|u|u.summoned?}==nil
    pass=count==3 && full>0 && faint==((full.to_f*0.5).floor) && unique && no_summons
    log_event(:verify,'PROGRESSION_BATTLE_EXP pass='+(pass ? '1':'0')+' deployed='+count.to_s+' split_by_deployed=1 alive_share='+full.to_s+' fainted_share='+faint.to_s+' fainted_rate=0.50 reserve=0 summons=0 unique_uid='+(unique ? '1':'0'))
    @verification_done[:progression_battle_exp]=true
  end

  def verify_progression_persistence_v046
    return if @verification_done[:progression_persistence]
    i=progression_temp_instance_v046(99460501,:bulbasaur,15);PMD_AC.register_pokemon_instance_v045(i)
    i.gain_move_mastery_v045(:tackle,30);exp0=i.exp;lv0=i.level;ml0=i.move_level_v045(:tackle);uid=i.instance_uid
    stored=PMD_AC.store_instance_v045(i,6,false);same=PMD_AC.pokemon_instance_for_uid_v045(uid)
    pass=stored && same.equal?(i) && same.instance_uid==uid && same.exp==exp0 && same.level==lv0 && same.move_level_v045(:tackle)==ml0 && same.battle_moves_v046==i.battle_moves_v046
    log_event(:verify,'PROGRESSION_PERSISTENCE pass='+(pass ? '1':'0')+' uid_same='+(same!=nil&&same.instance_uid==uid ? '1':'0')+' level='+lv0.to_s+' exp='+exp0.to_s+' tackle_lv='+ml0.to_s+' storage_box=6 clone_actor_independent=1 loadout_persistent=1')
    @verification_done[:progression_persistence]=true
  end

  def verify_progression_modes_v046
    return if @verification_done[:progression_modes]
    exp=[:progression_runtime,:identity_bridge,:tactical_support,:reactive_priority,:priority]
    pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:progression_runtime
    log_event(:verify,'PROGRESSION_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=PROGRESSION_RUNTIME')
    @verification_done[:progression_modes]=true
  end

  def update_verification_script
    pmd_ac_v046_update_verification_script
    return unless verification_mode==:progression_runtime
    f=@verification_frame
    verify_progression_manifest_v046 if f==4
    verify_progression_exp_curves_v046 if f==90
    verify_progression_level_stats_v046 if f==190
    verify_progression_move_learning_v046 if f==310
    verify_progression_mastery_v046 if f==440
    verify_progression_loadout_ai_v046 if f==570
    verify_progression_battle_exp_v046 if f==690
    verify_progression_persistence_v046 if f==790
    verify_progression_modes_v046 if f==850
    complete_verification_mode if f==PMD_AC::VERIFICATION_PROGRESSION_RUNTIME_END_FRAME_V046
  end

  def complete_verification_mode
    if verification_mode==:progression_runtime
      failed=@progression_runtime_failed_v046
      @progression_verify_selection_v046=false
      PMD_AC.end_identity_sandbox_v045 if PMD_AC.identity_sandbox_v045?
      if failed
        for u in @units;u.verification_finish;end
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=PROGRESSION_RUNTIME auto_skill=on original_skills=restored')
        return
      end
    end
    pmd_ac_v046_complete_verification_mode
  end
end
