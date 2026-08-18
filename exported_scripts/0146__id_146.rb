#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.26
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_PASSIVE_RUNTIME_FILE / USE_EXTERNAL_ABILITY_PASSIVE_DB / VERIFICATION_ABILITY_PASSIVE_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / embedded_data
# - load! / manifest / behavior / behavior_count
# - ability_behavior / ability_data / ability_passive_scalar / ability_passive_checksum32
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.26
#    Generation V Passive / Conditional Ability Layer
#------------------------------------------------------------------------------
# Base: verified v0.25. Existing scripts remain byte-identical.
#==============================================================================
module PMD_AC
  ABILITY_PASSIVE_RUNTIME_FILE="Data/PMD_AutoChess_AbilityPassive_v026_000.rvdata"
  USE_EXTERNAL_ABILITY_PASSIVE_DB=true unless const_defined?(:USE_EXTERNAL_ABILITY_PASSIVE_DB)
  VERIFICATION_ABILITY_PASSIVE_END_FRAME=455

  module AbilityPassiveDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def embedded_data;{:manifest=>PMD_AC::ABILITY_PASSIVE_MANIFEST_V026,:behaviors=>PMD_AC::ABILITY_PASSIVE_BEHAVIOR_V026};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_ABILITY_PASSIVE_DB && FileTest.exist?(PMD_AC::ABILITY_PASSIVE_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::ABILITY_PASSIVE_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) && c[:manifest][:content_version]=="0.26.0"
              data=c;@using_runtime_file=true
            end
          rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        data=embedded_data if data==nil;@data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_ABILITY_PASSIVE_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::ABILITY_PASSIVE_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def manifest;load! unless loaded?;@data[:manifest]||{};end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def behavior_count;load! unless loaded?;(@data[:behaviors]||{}).size;end
    end
  end
  AbilityPassiveDB.load!

  class << self
    alias pmd_ac_v026_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v026_ability_behavior)
    alias pmd_ac_v026_ability_data ability_data unless method_defined?(:pmd_ac_v026_ability_data)
    def ability_behavior(key)
      b=AbilityPassiveDB.behavior(key);return b unless b==nil || b.empty?
      pmd_ac_v026_ability_behavior(key)
    end
    def ability_data(key)
      b=AbilityPassiveDB.behavior(key);return b unless b==nil || b.empty?
      pmd_ac_v026_ability_data(key)
    end
    def ability_passive_scalar(x)
      return "" if x==nil
      return x.collect{|v|v.to_s}.join(",") if x.is_a?(Array)
      x.to_s
    end
    def ability_passive_checksum32
      h=0
      fields=[:ability_key,:kind,:stats,:num,:den,:rounding,:status,:category,:type,:stat,:stages,
              :suppress_poison_tick,:chance,:ignore_paralysis_speed,:target_secondary_only,:multiplier,
              :exclude_existing_flinch]
      data=AbilityPassiveDB.instance_variable_get(:@data)[:behaviors]
      for k in data.keys.sort{|a,b|a.to_s<=>b.to_s}
        d=data[k];text=fields.collect{|f|ability_passive_scalar(d[f])}.join("|")
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_ability_passive_db
      e=[];m=AbilityPassiveDB.manifest
      e.push("count") unless AbilityPassiveDB.behavior_count==17
      e.push("cumulative") unless m[:cumulative_ability_behavior_count].to_i==73
      e.push("slots") unless m[:implemented_slot_count].to_i==614 && m[:new_implemented_slot_count].to_i==91
      e.push("species") unless m[:species_with_any_implemented_ability].to_i==396
      e.push("sheer_force") unless AbilityPassiveDB.behavior(:sheer_force)[:kind]==:secondary_power_suppress
      e.push("quick_feet") unless AbilityPassiveDB.behavior(:quick_feet)[:ignore_paralysis_speed]
      e.push("checksum") unless ability_passive_checksum32==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,:progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary,:speed_status,:action_status,:ability,:ability_trigger,:ability_passive]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",:ability=>"ABILITY",:ability_trigger=>"ABILITY_TRIGGER",:ability_passive=>"ABILITY_PASSIVE"}
end

class Game_PMDChessUnit
  alias pmd_ac_v026_ability_outgoing_multiplier ability_outgoing_multiplier unless method_defined?(:pmd_ac_v026_ability_outgoing_multiplier)
  alias pmd_ac_v026_ability_incoming_multiplier ability_incoming_multiplier unless method_defined?(:pmd_ac_v026_ability_incoming_multiplier)
  alias pmd_ac_v026_canonical_ability_move_power_multiplier canonical_ability_move_power_multiplier unless method_defined?(:pmd_ac_v026_canonical_ability_move_power_multiplier)
  alias pmd_ac_v026_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v026_change_stat_stage)
  alias pmd_ac_v026_defense defense unless method_defined?(:pmd_ac_v026_defense)
  alias pmd_ac_v026_realtime_speed_factor realtime_speed_factor unless method_defined?(:pmd_ac_v026_realtime_speed_factor)
  alias pmd_ac_v026_canonical_apply_sleep canonical_apply_sleep unless method_defined?(:pmd_ac_v026_canonical_apply_sleep)
  alias pmd_ac_v026_apply_status apply_status unless method_defined?(:pmd_ac_v026_apply_status)
  alias pmd_ac_v026_canonical_update_trigger_cycle canonical_update_trigger_cycle unless method_defined?(:pmd_ac_v026_canonical_update_trigger_cycle)
  alias pmd_ac_v026_canonical_trigger_turn_end canonical_trigger_turn_end unless method_defined?(:pmd_ac_v026_canonical_trigger_turn_end)

  def canonical_passive_behavior;PMD_AC::AbilityPassiveDB.behavior(ability_key)||{};end
  def canonical_any_major_status?
    status?(:burn) || status?(:poison) || status?(:paralysis) || status?(:sleep) || status?(:freeze)
  end
  def canonical_sheer_force_qualifies?(data)
    return false if data==nil
    list=data[:secondary_effects]||[]
    list.any?{|e|e[:receiver]!=:user && e[:chance].to_i>0}
  end

  def ability_outgoing_multiplier(move_type,category,effectiveness=1.0)
    base=pmd_ac_v026_ability_outgoing_multiplier(move_type,category,effectiveness)
    b=canonical_passive_behavior
    if b[:kind]==:status_category_multiplier && status?(b[:status]) && category==b[:category]
      base*=b[:num].to_f/[b[:den].to_i,1].max.to_f
    end
    base
  end

  def ability_incoming_multiplier(move_type,category)
    base=pmd_ac_v026_ability_incoming_multiplier(move_type,category)
    return base if base<=0.0
    b=canonical_passive_behavior
    if b[:kind]==:full_hp_incoming_multiplier && @hp.to_i>=@maxhp.to_i
      base*=b[:num].to_f/[b[:den].to_i,1].max.to_f
    end
    base
  end

  def canonical_ability_move_power_multiplier(data)
    base=pmd_ac_v026_canonical_ability_move_power_multiplier(data)
    b=canonical_passive_behavior
    if b[:kind]==:secondary_power_suppress && canonical_sheer_force_qualifies?(data)
      base*=b[:num].to_f/[b[:den].to_i,1].max.to_f
    end
    base
  end

  def change_stat_stage(stat,delta,source=nil)
    b=canonical_passive_behavior;d=delta.to_i
    if b[:kind]==:reverse_stat_change && d!=0
      d=-d
      log_event(:ability_passive,log_name+" contrary REVERSE stat="+stat.to_s+" delta="+delta.to_i.to_s+"->"+d.to_s)
    elsif b[:kind]==:stat_change_multiplier && d!=0
      d*=b[:multiplier].to_i
      log_event(:ability_passive,log_name+" simple DOUBLE stat="+stat.to_s+" delta="+delta.to_i.to_s+"->"+d.to_s)
    end
    pmd_ac_v026_change_stat_stage(stat,d,source)
  end

  def defense
    base=pmd_ac_v026_defense
    b=canonical_passive_behavior
    if b[:kind]==:status_defense_multiplier && canonical_any_major_status?
      base=[(base.to_f*b[:num].to_f/[b[:den].to_i,1].max.to_f).round,1].max
    end
    base
  end

  def realtime_speed_factor
    b=canonical_passive_behavior
    if b[:kind]==:status_speed_multiplier && canonical_any_major_status?
      ref=PMD_AC.canonical_speed_reference(level)
      stat=(speed_stat.to_f*b[:num].to_f/[b[:den].to_i,1].max.to_f).round
      return PMD_AC.realtime_speed_factor_for(stat,ref,false)
    end
    pmd_ac_v026_realtime_speed_factor
  end

  def canonical_apply_sleep(source=nil)
    result=pmd_ac_v026_canonical_apply_sleep(source)
    b=canonical_passive_behavior
    if result && b[:kind]==:sleep_block_reduction
      old=@canonical_sleep_turns.to_i;blocked=[old-1,0].max
      reduced=(blocked*b[:num].to_i+b[:den].to_i-1)/[b[:den].to_i,1].max
      @canonical_sleep_turns=reduced+1
      log_event(:ability_passive,log_name+" early_bird SLEEP turns="+old.to_s+"->"+@canonical_sleep_turns.to_s+" blocked="+blocked.to_s+"->"+reduced.to_s)
    end
    result
  end

  def apply_status(key,options={},source=nil)
    result=pmd_ac_v026_apply_status(key,options,source)
    b=canonical_passive_behavior
    if status?(key)
      if b[:kind]==:poison_turn_heal && key==:poison && b[:suppress_poison_tick]
        d=@statuses[:poison];if d!=nil;d[:interval]=999999;d[:tick]=999999;end
        log_event(:ability_passive,log_name+" poison_heal SUPPRESS_POISON_TICK")
      end
    end
    result
  end

  def canonical_update_trigger_cycle
    if ability_key==:poison_heal
      return unless @battle_active && !dead? && !@verification_combat_sandbox
      @canonical_trigger_cycle_wait=canonical_trigger_cycle_length if @canonical_trigger_cycle_wait==nil
      @canonical_trigger_cycle_wait-=1
      return if @canonical_trigger_cycle_wait>0
      @canonical_trigger_cycle_wait=canonical_trigger_cycle_length
      canonical_trigger_turn_end
      return
    end
    pmd_ac_v026_canonical_update_trigger_cycle
  end

  def canonical_trigger_turn_end
    b=canonical_passive_behavior
    if b[:kind]==:poison_turn_heal
      return false unless status?(:poison)
      amount=[maxhp*b[:num].to_i/[b[:den].to_i,1].max,1].max
      before=@hp;heal(amount);actual=@hp-before
      log_event(:ability_passive,log_name+" poison_heal TURN_HEAL attempted="+amount.to_s+" actual="+actual.to_s)
      return true
    end
    pmd_ac_v026_canonical_trigger_turn_end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v026_start start unless method_defined?(:pmd_ac_v026_start)
  alias pmd_ac_v026_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v026_prepare_verification_battle)
  alias pmd_ac_v026_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v026_deal_direct_damage)
  alias pmd_ac_v026_apply_canonical_secondary_group apply_canonical_secondary_group unless method_defined?(:pmd_ac_v026_apply_canonical_secondary_group)
  alias pmd_ac_v026_canonical_action_status_roll canonical_action_status_roll unless method_defined?(:pmd_ac_v026_canonical_action_status_roll)
  alias pmd_ac_v026_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v026_update_verification_script)
  alias pmd_ac_v026_log_event log_event unless method_defined?(:pmd_ac_v026_log_event)
  alias pmd_ac_v026_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v026_complete_verification_mode)

  def start
    pmd_ac_v026_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.25 Battle Verification Log","PMD AutoChess Proto v0.26 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::AbilityPassiveDB.manifest
    log_event(:ability_passive,"LOADED new="+PMD_AC::AbilityPassiveDB.behavior_count.to_s+
      " cumulative="+m[:cumulative_ability_behavior_count].to_s+
      " implemented_slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+
      " species="+m[:species_with_any_implemented_ability].to_s+"/494 source="+
      (PMD_AC::AbilityPassiveDB.using_runtime_file? ? "rvdata":"embedded")+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v026_prepare_verification_battle
    if verification_mode==:ability_passive
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages;end
      @ability_passive_failed=false;@ability_passive_rolls=[];@ability_passive_action_rolls={};@ability_passive_test_units=[]
    end
  end

  def ability_passive_verification_unit(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99026000+id.to_i,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9200+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_passive_test_units=[] if @ability_passive_test_units==nil;@ability_passive_test_units.push(u);u
  end
  def set_ability_passive_rolls(v);@ability_passive_rolls=v.dup;end
  def canonical_passive_roll(chance)
    c=PMD_AC.clamp(chance.to_i,0,100)
    roll=(verification_mode==:ability_passive && @ability_passive_rolls!=nil && !@ability_passive_rolls.empty?) ? @ability_passive_rolls.shift.to_i : rand(100)
    [roll<c,roll]
  end
  def set_ability_passive_action_rolls(key,values)
    @ability_passive_action_rolls={} if @ability_passive_action_rolls==nil;@ability_passive_action_rolls[key]=values.dup
  end
  def canonical_action_status_roll(key,max)
    a=@ability_passive_action_rolls==nil ? nil : @ability_passive_action_rolls[key]
    return a.shift.to_i if verification_mode==:ability_passive && a!=nil && !a.empty?
    pmd_ac_v026_canonical_action_status_roll(key,max)
  end

  def canonical_sheer_force_target_secondary?(data)
    return false if data==nil
    (data[:secondary_effects]||[]).any?{|e|e[:receiver]!=:user && e[:chance].to_i>0}
  end
  def apply_canonical_secondary_group(user,target,data,effects,result)
    if user!=nil && user.ability_key==:sheer_force && canonical_sheer_force_target_secondary?(data)
      kept=(effects||[]).select{|e|e[:receiver]==:user}
      log_event(:ability_passive,user.log_name+" sheer_force SUPPRESS_SECONDARY move="+(data[:canonical_move_key]||:unknown).to_s+" removed="+((effects||[]).size-kept.size).to_s)
      return if kept.empty?
      return pmd_ac_v026_apply_canonical_secondary_group(user,target,data,kept,result)
    end
    pmd_ac_v026_apply_canonical_secondary_group(user,target,data,effects,result)
  end

  def canonical_move_has_flinch_secondary?(data)
    return false if data==nil
    (data[:secondary_effects]||[]).any?{|e|e[:type]==:canonical_flinch}
  end
  def canonical_passive_contact_move?(user,data)
    return !user.ranged? if data==nil
    data[:contact] || (data[:source_move_flags]||[]).include?(:contact)
  end

  def deal_direct_damage(user,target,power,options=nil)
    return 0 if user==nil || target==nil || target.dead?
    options={} if options==nil
    type,cat,data=canonical_damage_type_and_category(user,options)
    tb=target.respond_to?(:canonical_passive_behavior) ? target.canonical_passive_behavior : {}
    if tb[:kind]==:type_immunity_stage && type==tb[:type]
      actual=target.change_stat_stage(tb[:stat],tb[:stages].to_i,target)
      log_event(:ability_passive,target.log_name+" "+target.ability_key.to_s+" IMMUNE type="+type.to_s+" stage="+actual.to_s)
      return 0
    end
    if tb[:kind]==:non_super_effective_immunity
      eff=PMD_AC.type_effectiveness(type,target.pokemon_types)
      if eff<=1.0
        log_event(:ability_passive,target.log_name+" wonder_guard IMMUNE type="+type.to_s+" effectiveness="+sprintf("%.2f",eff))
        return 0
      end
    end
    opts=options.dup
    ub=user.respond_to?(:canonical_passive_behavior) ? user.canonical_passive_behavior : {}
    if ub[:kind]==:critical_damage_multiplier
      base=opts.has_key?(:crit_multiplier) ? opts[:crit_multiplier].to_f : user.crit_multiplier.to_f
      opts[:crit_multiplier]=base*ub[:num].to_f/[ub[:den].to_i,1].max.to_f
    end
    result=pmd_ac_v026_deal_direct_damage(user,target,power,opts)
    if result.to_i>0 && target.alive?
      if ub[:kind]==:damage_flinch_chance && !canonical_move_has_flinch_secondary?(data)
        ok,roll=canonical_passive_roll(ub[:chance])
        log_event(:ability_passive,user.log_name+" stench chance="+ub[:chance].to_s+" roll="+roll.to_s+" proc="+(ok ? "1":"0"))
        target.canonical_apply_flinch(user) if ok
      elsif ub[:kind]==:contact_inflict_status && canonical_passive_contact_move?(user,data)
        ok,roll=canonical_passive_roll(ub[:chance])
        log_event(:ability_passive,user.log_name+" poison_touch chance="+ub[:chance].to_s+" roll="+roll.to_s+" proc="+(ok ? "1":"0"))
        canonical_apply_trigger_major_status(target,ub[:status],user) if ok
      end
    end
    result
  end

  # Verification -------------------------------------------------------------
  def verify_ability_passive_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::AbilityPassiveDB.manifest;e=PMD_AC.validate_ability_passive_db;actual=PMD_AC.ability_passive_checksum32;pass=e.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" new="+m[:new_passive_ability_count].to_s+" cumulative="+m[:cumulative_ability_behavior_count].to_s+" slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+" coverage="+m[:implemented_slot_coverage_percent].to_s+"% species="+m[:species_with_any_implemented_ability].to_s+"/494 checksum="+actual.to_s+" errors=["+e.join(",")+"]");@verification_done[tag]=true
  end

  def verify_ability_passive_stages(tag)
    return if @verification_done[tag]
    foe=ability_passive_verification_unit(:rattata,:primary,:enemy,1)
    con=ability_passive_verification_unit(:shuckle,:hidden,:ally,2);con.change_stat_stage(:def,-1,foe);c=con.stat_stage(:def)==1
    sim=ability_passive_verification_unit(:bidoof,:primary,:ally,3);sim.change_stat_stage(:atk,1,sim);s=sim.stat_stage(:atk)==2
    bp=ability_passive_verification_unit(:pidgey,:hidden,:ally,4);bp.change_stat_stage(:def,-1,foe);b=bp.stat_stage(:def)==0
    pass=c&&s&&b;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" contrary_def="+con.stat_stage(:def).to_s+" simple_atk="+sim.stat_stage(:atk).to_s+" big_pecks_def="+bp.stat_stage(:def).to_s);@verification_done[tag]=true
  end

  def verify_ability_passive_status_scaling(tag)
    return if @verification_done[tag]
    src=ability_passive_verification_unit(:rattata,:primary,:enemy,10)
    q=ability_passive_verification_unit(:granbull,:secondary,:ally,11);n=ability_passive_verification_unit(:granbull,:primary,:ally,12)
    canonical_apply_trigger_major_status(q,:paralysis,src);canonical_apply_trigger_major_status(n,:paralysis,src);qf=q.realtime_speed_factor;nf=n.realtime_speed_factor
    m=ability_passive_verification_unit(:milotic,:primary,:ally,13);d0=m.defense;canonical_apply_trigger_major_status(m,:burn,src);d1=m.defense
    eb=ability_passive_verification_unit(:doduo,:secondary,:ally,14);set_ability_passive_action_rolls(:sleep_turns,[2]);eb.canonical_apply_sleep(src);turns=eb.instance_variable_get(:@canonical_sleep_turns).to_i
    pass=qf>nf && d1>d0 && turns==3
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" quick_feet="+sprintf("%.3f",nf)+"->"+sprintf("%.3f",qf)+" marvel_def="+d0.to_s+"->"+d1.to_s+" early_bird_turns="+turns.to_s);@verification_done[tag]=true
  end

  def verify_ability_passive_offense(tag)
    return if @verification_done[tag]
    data=PMD_AC.skill_data(:mv_crunch)
    sf=ability_passive_verification_unit(:nidoking,:hidden,:ally,20);plain=ability_passive_verification_unit(:nidoking,:primary,:ally,21)
    t1=ability_passive_verification_unit(:rattata,:primary,:enemy,22);t2=ability_passive_verification_unit(:rattata,:primary,:enemy,23)
    d_sf=deal_direct_damage(sf,t1,80,{:skill_data=>data,:random_percent=>100,:directional=>false,:can_crit=>false})
    apply_canonical_secondary_group(sf,t1,data,data[:secondary_effects],d_sf)
    d_pl=deal_direct_damage(plain,t2,80,{:skill_data=>data,:random_percent=>100,:directional=>false,:can_crit=>false})
    sheer=d_sf>d_pl && t1.stat_stage(:def)==0

    sn=ability_passive_verification_unit(:kingdra,:secondary,:ally,24);sn0=ability_passive_verification_unit(:kingdra,:primary,:ally,25)
    st1=ability_passive_verification_unit(:rattata,:primary,:enemy,26);st2=ability_passive_verification_unit(:rattata,:primary,:enemy,27)
    crit1=deal_direct_damage(sn,st1,60,{:move_type=>:water,:damage_category=>:special,:random_percent=>100,:directional=>false,:modifier=>{:force_crit=>true}})
    crit0=deal_direct_damage(sn0,st2,60,{:move_type=>:water,:damage_category=>:special,:random_percent=>100,:directional=>false,:modifier=>{:force_crit=>true}})

    tox=ability_passive_verification_unit(:zangoose,:hidden,:ally,28);tt1=ability_passive_verification_unit(:rattata,:primary,:enemy,29);tt2=ability_passive_verification_unit(:rattata,:primary,:enemy,30)
    pre=deal_direct_damage(tox,tt1,50,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false});tox.apply_status(:poison,{:duration=>180,:value=>10,:interval=>30,:stack_mode=>:refresh},nil);post=deal_direct_damage(tox,tt2,50,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false})
    fl=ability_passive_verification_unit(:drifblim,:hidden,:ally,31);ft1=ability_passive_verification_unit(:rattata,:primary,:enemy,32);ft2=ability_passive_verification_unit(:rattata,:primary,:enemy,33)
    fpre=deal_direct_damage(fl,ft1,50,{:move_type=>:ghost,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false});fl.apply_status(:burn,{:duration=>180,:value=>10,:interval=>30,:stack_mode=>:refresh},nil);fpost=deal_direct_damage(fl,ft2,50,{:move_type=>:ghost,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false})
    pass=sheer && crit1>crit0 && post>pre && fpost>fpre
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" sheer_force="+d_pl.to_s+"->"+d_sf.to_s+" suppressed="+(t1.stat_stage(:def)==0 ? "1":"0")+" sniper="+crit0.to_s+"->"+crit1.to_s+" toxic="+pre.to_s+"->"+post.to_s+" flare="+fpre.to_s+"->"+fpost.to_s);@verification_done[tag]=true
  end

  def verify_ability_passive_defense(tag)
    return if @verification_done[tag]
    atk=ability_passive_verification_unit(:rattata,:primary,:ally,40)
    full=ability_passive_verification_unit(:dragonite,:hidden,:enemy,41);hurt=ability_passive_verification_unit(:dragonite,:hidden,:enemy,42);hurt.instance_variable_set(:@hp,hurt.maxhp-1)
    d1=deal_direct_damage(atk,full,80,{:move_type=>:ice,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false});d2=deal_direct_damage(atk,hurt,80,{:move_type=>:ice,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false})
    wg1=ability_passive_verification_unit(:shedinja,:primary,:enemy,43);wg2=ability_passive_verification_unit(:shedinja,:primary,:enemy,44);w1=deal_direct_damage(atk,wg1,40,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false});w2=deal_direct_damage(atk,wg2,40,{:move_type=>:fire,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false})
    pass=d1<d2 && w1==0 && w2>0
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" multiscale="+d2.to_s+"->"+d1.to_s+" wonder_guard_normal="+w1.to_s+" fire="+w2.to_s);@verification_done[tag]=true
  end

  def verify_ability_passive_absorb_stage(tag)
    return if @verification_done[tag]
    atk=ability_passive_verification_unit(:rattata,:primary,:ally,50)
    sap=ability_passive_verification_unit(:marill,:hidden,:enemy,51);s=deal_direct_damage(atk,sap,60,{:move_type=>:grass,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false})
    mot=ability_passive_verification_unit(:electivire,:primary,:enemy,52);m=deal_direct_damage(atk,mot,60,{:move_type=>:electric,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false})
    pass=s==0 && sap.stat_stage(:atk)==1 && m==0 && mot.stat_stage(:speed)==1
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" sap_sipper_damage="+s.to_s+" atk="+sap.stat_stage(:atk).to_s+" motor_drive_damage="+m.to_s+" speed="+mot.stat_stage(:speed).to_s);@verification_done[tag]=true
  end

  def verify_ability_passive_contact(tag)
    return if @verification_done[tag]
    data=PMD_AC.skill_data(:mv_tackle)
    st=ability_passive_verification_unit(:grimer,:primary,:ally,60);t=ability_passive_verification_unit(:rattata,:primary,:enemy,61);set_ability_passive_rolls([0]);deal_direct_damage(st,t,50,{:skill_data=>data,:random_percent=>100,:directional=>false,:can_crit=>false});fl=t.canonical_flinch_pending?
    pt=ability_passive_verification_unit(:grimer,:hidden,:ally,62);p=ability_passive_verification_unit(:rattata,:primary,:enemy,63);set_ability_passive_rolls([0]);deal_direct_damage(pt,p,50,{:skill_data=>data,:random_percent=>100,:directional=>false,:can_crit=>false});po=p.status?(:poison)
    set_ability_passive_rolls([9,10]);a,r1=canonical_passive_roll(10);b,r2=canonical_passive_roll(10)
    pass=fl&&po&&a&&!b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stench_flinch="+(fl ? "1":"0")+" poison_touch="+(po ? "1":"0")+" stench_boundary9="+(a ? "proc":"miss")+" boundary10="+(b ? "proc":"miss"));@verification_done[tag]=true
  end

  def verify_ability_passive_poison_heal(tag)
    return if @verification_done[tag]
    src=ability_passive_verification_unit(:rattata,:primary,:enemy,70);ph=ability_passive_verification_unit(:breloom,:secondary,:ally,71);ph.verification_set_hp_percent(0.40);before=ph.hp
    canonical_apply_trigger_major_status(ph,:poison,src);d=ph.instance_variable_get(:@statuses)[:poison];suppressed=d!=nil && d[:tick].to_i>=999999
    ph.canonical_trigger_turn_end;expected=[ph.maxhp/8,1].max;actual=ph.hp-before
    pass=ph.status?(:poison)&&suppressed&&actual==expected
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" poisoned="+(ph.status?(:poison) ? "1":"0")+" tick_suppressed="+(suppressed ? "1":"0")+" heal="+actual.to_s+" expected="+expected.to_s);@verification_done[tag]=true
  end

  def verify_ability_passive_runtime_file(tag)
    return if @verification_done[tag];p=FileTest.exist?(PMD_AC::ABILITY_PASSIVE_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(p ? "1":"0")+" runtime_file="+(p ? "present":"missing")+" source="+(PMD_AC::AbilityPassiveDB.using_runtime_file? ? "rvdata":"embedded_first_boot"));@verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v026_update_verification_script;return unless verification_mode==:ability_passive;f=@verification_frame
    verify_ability_passive_manifest(:ability_passive_manifest) if f==4
    verify_ability_passive_stages(:ability_passive_stages) if f==50
    verify_ability_passive_status_scaling(:ability_passive_status) if f==105
    verify_ability_passive_offense(:ability_passive_offense) if f==165
    verify_ability_passive_defense(:ability_passive_defense) if f==230
    verify_ability_passive_absorb_stage(:ability_passive_absorb) if f==285
    verify_ability_passive_contact(:ability_passive_contact) if f==340
    verify_ability_passive_poison_heal(:ability_passive_poison_heal) if f==395
    verify_ability_passive_runtime_file(:ability_passive_runtime_file) if f==430
    complete_verification_mode if f==PMD_AC::VERIFICATION_ABILITY_PASSIVE_END_FRAME
  end

  def log_event(category,message)
    if category.to_s=="verify";t=message.to_s;@ability_passive_failed=true if t.index("ABILITY_PASSIVE_")==0 && t.include?(" pass=0");end
    pmd_ac_v026_log_event(category,message)
  end

  def complete_verification_mode
    if verification_mode==:ability_passive && @ability_passive_failed
      return if @verification_done[:verification_complete]
      for u in @units;u.verification_finish;end
      @verification_done[:verification_complete]=true
      log_event(:verify,"FAILED mode=ABILITY_PASSIVE auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v026_complete_verification_mode
  end
end
