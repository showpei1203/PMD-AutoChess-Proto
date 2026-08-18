#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.25
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_TRIGGER_RUNTIME_FILE / USE_EXTERNAL_ABILITY_TRIGGER_DB / VERIFICATION_ABILITY_TRIGGER_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / embedded_data
# - load! / manifest / behavior / behavior_count
# - ability_behavior / ability_data / ability_trigger_checksum_scalar / ability_trigger_checksum32
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.25
#    Generation V Trigger Ability Layer
#------------------------------------------------------------------------------
# Base: verified v0.24.1. Existing scripts remain byte-identical.
#==============================================================================
module PMD_AC
  ABILITY_TRIGGER_RUNTIME_FILE="Data/PMD_AutoChess_AbilityTriggers_v025_000.rvdata"
  USE_EXTERNAL_ABILITY_TRIGGER_DB=true unless const_defined?(:USE_EXTERNAL_ABILITY_TRIGGER_DB)
  VERIFICATION_ABILITY_TRIGGER_END_FRAME=450

  module AbilityTriggerDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def embedded_data;{:manifest=>PMD_AC::ABILITY_TRIGGER_MANIFEST_V025,:behaviors=>PMD_AC::ABILITY_TRIGGER_BEHAVIOR_V025};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_ABILITY_TRIGGER_DB && FileTest.exist?(PMD_AC::ABILITY_TRIGGER_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::ABILITY_TRIGGER_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) && c[:manifest][:content_version]=="0.25.0"
              data=c;@using_runtime_file=true
            end
          rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        data=embedded_data if data==nil;@data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_ABILITY_TRIGGER_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::ABILITY_TRIGGER_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def manifest;load! unless loaded?;@data[:manifest]||{};end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def behavior_count;load! unless loaded?;(@data[:behaviors]||{}).size;end
    end
  end
  AbilityTriggerDB.load!

  class << self
    alias pmd_ac_v025_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v025_ability_behavior)
    alias pmd_ac_v025_ability_data ability_data unless method_defined?(:pmd_ac_v025_ability_data)
    def ability_behavior(key)
      b=AbilityTriggerDB.behavior(key);return b unless b==nil || b.empty?
      pmd_ac_v025_ability_behavior(key)
    end
    def ability_data(key)
      b=AbilityTriggerDB.behavior(key);return b unless b==nil || b.empty?
      pmd_ac_v025_ability_data(key)
    end
    def ability_trigger_checksum_scalar(x)
      return x.collect{|v|v.is_a?(Hash) ? v.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|v[k].to_s}.join(",") : v.to_s}.join(";") if x.is_a?(Array)
      return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|x[k].to_s}.join(",") if x.is_a?(Hash)
      x.to_s
    end
    def ability_trigger_checksum32
      h=0;fields=[:ability_key,:kind,:chance_num,:chance_den,:statuses,:stat,:stages,:move_types,:category,:changes,:direct_damage_only,:roll_max,:distribution,:stage,:ratio_num,:ratio_den,:damp_blocks,:remain_hp,:confusion_eligible,:mold_breaker_ignored]
      data=AbilityTriggerDB.instance_variable_get(:@data)[:behaviors]
      for k in data.keys.sort{|a,b|a.to_s<=>b.to_s}
        d=data[k];text=fields.collect{|f|ability_trigger_checksum_scalar(d[f])}.join("|")
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_ability_trigger_db
      e=[];m=AbilityTriggerDB.manifest
      e.push("count") unless AbilityTriggerDB.behavior_count==14
      e.push("cumulative") unless m[:cumulative_ability_behavior_count].to_i==56
      e.push("slots") unless m[:implemented_slot_count].to_i==523 && m[:new_implemented_slot_count].to_i==120
      e.push("species") unless m[:species_with_any_implemented_ability].to_i==364
      e.push("shed_skin") unless AbilityTriggerDB.behavior(:shed_skin)[:chance_den].to_i==3
      e.push("weak_armor") unless AbilityTriggerDB.behavior(:weak_armor)[:changes][1][:stages].to_i==1
      e.push("checksum") unless ability_trigger_checksum32==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,:progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary,:speed_status,:action_status,:ability,:ability_trigger]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",:ability=>"ABILITY",:ability_trigger=>"ABILITY_TRIGGER"}
end

class Game_PMDChessUnit
  alias pmd_ac_v025_initialize initialize unless method_defined?(:pmd_ac_v025_initialize)
  alias pmd_ac_v025_update update unless method_defined?(:pmd_ac_v025_update)
  alias pmd_ac_v025_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v025_change_stat_stage)
  alias pmd_ac_v025_canonical_apply_flinch canonical_apply_flinch unless method_defined?(:pmd_ac_v025_canonical_apply_flinch)
  alias pmd_ac_v025_apply_status apply_status unless method_defined?(:pmd_ac_v025_apply_status)
  alias pmd_ac_v025_receive_damage receive_damage unless method_defined?(:pmd_ac_v025_receive_damage)

  def initialize(*args)
    pmd_ac_v025_initialize(*args)
    @canonical_trigger_cycle_wait=canonical_trigger_cycle_length
    @canonical_direct_damage_context=nil
  end
  def canonical_trigger_behavior;PMD_AC::AbilityTriggerDB.behavior(ability_key)||{};end
  def canonical_trigger_cycle_length
    v=(@attack_wait_max||54).to_i;v=36 if v<36;v
  end
  def canonical_update_trigger_cycle
    return unless @battle_active && !dead? && !@verification_combat_sandbox
    b=canonical_trigger_behavior;return unless [:turn_end_status_cure,:turn_end_stage].include?(b[:kind])
    @canonical_trigger_cycle_wait=canonical_trigger_cycle_length if @canonical_trigger_cycle_wait==nil
    @canonical_trigger_cycle_wait-=1
    return if @canonical_trigger_cycle_wait>0
    @canonical_trigger_cycle_wait=canonical_trigger_cycle_length
    canonical_trigger_turn_end
  end
  def update
    canonical_update_trigger_cycle
    pmd_ac_v025_update
  end
  def canonical_trigger_roll(max)
    return @scene.canonical_trigger_ability_roll(max) if @scene!=nil && @scene.respond_to?(:canonical_trigger_ability_roll)
    rand(max)
  end
  def canonical_trigger_turn_end
    b=canonical_trigger_behavior
    case b[:kind]
    when :turn_end_status_cure
      key=nil;for k in (b[:statuses]||[]);if status?(k);key=k;break;end;end
      return false if key==nil
      roll=canonical_trigger_roll(b[:chance_den].to_i)
      if roll<b[:chance_num].to_i
        if [:sleep,:freeze].include?(key);canonical_clear_action_status(key,:shed_skin);else;remove_status(key);end
        log_event(:ability_trigger,log_name+" shed_skin CURE status="+key.to_s+" roll="+roll.to_s+"/"+b[:chance_den].to_s)
        return true
      end
      log_event(:ability_trigger,log_name+" shed_skin NO_CURE status="+key.to_s+" roll="+roll.to_s+"/"+b[:chance_den].to_s)
      return false
    when :turn_end_stage
      actual=change_stat_stage(b[:stat],b[:stages].to_i,self)
      log_event(:ability_trigger,log_name+" speed_boost TURN_END actual="+actual.to_s)
      return actual!=0
    end
    false
  end
  def change_stat_stage(stat,delta,source=nil)
    actual=pmd_ac_v025_change_stat_stage(stat,delta,source)
    if actual<0 && ability_key==:defiant && source!=nil && source.respond_to?(:team) && source.team!=team
      b=canonical_trigger_behavior;boost=pmd_ac_v025_change_stat_stage(b[:stat],b[:stages].to_i,self)
      log_event(:ability_trigger,log_name+" defiant TRIGGER drop="+stat.to_s+" boost="+boost.to_s)
    end
    actual
  end
  def canonical_apply_flinch(source=nil)
    applied=pmd_ac_v025_canonical_apply_flinch(source)
    if applied && ability_key==:steadfast
      b=canonical_trigger_behavior;boost=change_stat_stage(b[:stat],b[:stages].to_i,self)
      log_event(:ability_trigger,log_name+" steadfast TRIGGER speed="+boost.to_s)
    end
    applied
  end
  def apply_status(key,options={},source=nil)
    before=status?(key)
    result=pmd_ac_v025_apply_status(key,options,source)
    if !before && status?(key) && ability_key==:synchronize && [:burn,:poison,:paralysis].include?(key) && source!=nil && source!=self && source.respond_to?(:team) && source.team!=team && @scene!=nil
      @scene.canonical_synchronize_status(self,source,key)
    end
    result
  end
  def canonical_set_direct_damage_context(ctx);@canonical_direct_damage_context=ctx;end
  def canonical_clear_direct_damage_context;@canonical_direct_damage_context=nil;end
  def canonical_sturdy_eligible_source?(source)
    return false if source!=nil && [:mold_breaker,:teravolt,:turboblaze].include?(source.ability_key)
    return true if @canonical_direct_damage_context!=nil
    return true if source==self && confused?
    false
  end
  def canonical_preview_local_hp_damage(raw,bypass_link=false)
    value=[raw.to_i,1].max;absorbed=[@shield.to_i,value].min;value-=absorbed
    if value>0 && !bypass_link && @damage_link_frames.to_i>0 && @damage_link_source!=nil && @damage_link_source.alive?
      redirected=(value*@damage_link_ratio.to_f).round;redirected=value if redirected>value;value-=redirected
    end
    value
  end
  def canonical_cap_sturdy_raw(raw,bypass_link=false)
    shield=@shield.to_i;after=[raw.to_i-shield,0].max;target=[@hp.to_i-1,0].max
    if !bypass_link && @damage_link_frames.to_i>0 && @damage_link_source!=nil && @damage_link_source.alive? && after>0
      r=@damage_link_ratio.to_f
      while after>0 && (after-(after*r).round)>target;after-=1;end
    else
      after=target if after>target
    end
    shield+after
  end
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    raw=value.to_i
    if ability_key==:sturdy && @hp.to_i==@maxhp.to_i && @hp.to_i>0 && canonical_sturdy_eligible_source?(source) && canonical_preview_local_hp_damage(raw,bypass_link)>=@hp.to_i
      capped=canonical_cap_sturdy_raw(raw,bypass_link);capped=1 if capped<1
      log_event(:ability_trigger,log_name+" sturdy ENDURE raw="+raw.to_s+"->"+capped.to_s+" hp="+@hp.to_s)
      value=capped
    end
    pmd_ac_v025_receive_damage(value,source,grant_energy,bypass_link,critical)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v025_start start unless method_defined?(:pmd_ac_v025_start)
  alias pmd_ac_v025_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v025_prepare_verification_battle)
  alias pmd_ac_v025_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v025_deal_direct_damage)
  alias pmd_ac_v025_canonical_contact_ability_after_hit canonical_contact_ability_after_hit unless method_defined?(:pmd_ac_v025_canonical_contact_ability_after_hit)
  alias pmd_ac_v025_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v025_update_verification_script)
  alias pmd_ac_v025_log_event log_event unless method_defined?(:pmd_ac_v025_log_event)
  alias pmd_ac_v025_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v025_complete_verification_mode)

  def start
    pmd_ac_v025_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read};text.sub!("PMD AutoChess Proto v0.24.1 Battle Verification Log","PMD AutoChess Proto v0.25 Battle Verification Log");File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::AbilityTriggerDB.manifest
    log_event(:ability_trigger,"LOADED new="+PMD_AC::AbilityTriggerDB.behavior_count.to_s+" cumulative="+m[:cumulative_ability_behavior_count].to_s+" implemented_slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+" species="+m[:species_with_any_implemented_ability].to_s+"/494 source="+(PMD_AC::AbilityTriggerDB.using_runtime_file? ? "rvdata":"embedded")+" checksum32="+m[:runtime_checksum32].to_s)
  end
  def prepare_verification_battle
    pmd_ac_v025_prepare_verification_battle
    if verification_mode==:ability_trigger
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages;end
      @ability_trigger_failed=false;@ability_trigger_rolls=[];@ability_trigger_test_units=[];@canonical_synchronize_active=false
    end
  end
  def ability_trigger_verification_unit(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99025000+id.to_i,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9000+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_trigger_test_units=[] if @ability_trigger_test_units==nil;@ability_trigger_test_units.push(u);u
  end
  def set_ability_trigger_rolls(v);@ability_trigger_rolls=v.dup;end
  def canonical_trigger_ability_roll(max)
    m=[max.to_i,1].max
    return @ability_trigger_rolls.shift.to_i%m if verification_mode==:ability_trigger && @ability_trigger_rolls!=nil && !@ability_trigger_rolls.empty?
    rand(m)
  end
  def canonical_apply_trigger_major_status(target,status,source)
    return false if target==nil || target.dead?
    case status
    when :sleep
      return target.canonical_apply_sleep(source)
    when :paralysis
      return false if canonical_secondary_status_immune?(target,:paralysis);target.apply_status(:paralysis,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},source);return target.status?(:paralysis)
    when :poison
      return false if canonical_secondary_status_immune?(target,:poison);v=[(target.maxhp*0.015).round,1].max;target.apply_status(:poison,{:duration=>180,:value=>v,:interval=>30,:stack_mode=>:refresh},source);return target.status?(:poison)
    when :burn
      return false if canonical_secondary_status_immune?(target,:burn);v=[(target.maxhp*0.0125).round,1].max;target.apply_status(:burn,{:duration=>180,:value=>v,:interval=>30,:stack_mode=>:refresh},source);return target.status?(:burn)
    end
    false
  end
  def canonical_synchronize_status(holder,source,status)
    return false if @canonical_synchronize_active || holder==nil || source==nil || source.dead?
    @canonical_synchronize_active=true
    begin
      applied=canonical_apply_trigger_major_status(source,status,holder)
      log_event(:ability_trigger,holder.log_name+" synchronize REFLECT status="+status.to_s+" target="+source.log_name+" applied="+(applied ? "1":"0"))
      applied
    ensure
      @canonical_synchronize_active=false
    end
  end
  def canonical_damage_type_and_category(user,options)
    data=options==nil ? nil : options[:skill_data];type=options==nil ? nil : options[:move_type];cat=options==nil ? nil : options[:damage_category]
    type=data[:move_type] if type==nil && data!=nil;cat=data[:damage_category] if cat==nil && data!=nil
    type=user.basic_move_type if type==nil && user.respond_to?(:basic_move_type);type=:normal if type==nil;cat=:physical if cat==nil
    [type,cat,data]
  end
  def deal_direct_damage(user,target,power,options=nil)
    return 0 if user==nil || target==nil
    options={} if options==nil;type,cat,data=canonical_damage_type_and_category(user,options);before=target.hp;was_alive=target.alive?
    target.canonical_set_direct_damage_context({:user=>user,:move_type=>type,:category=>cat,:skill_data=>data}) if target.respond_to?(:canonical_set_direct_damage_context)
    begin
      result=pmd_ac_v025_deal_direct_damage(user,target,power,options)
    ensure
      target.canonical_clear_direct_damage_context if target.respond_to?(:canonical_clear_direct_damage_context)
    end
    hp_damage=[before-target.hp,0].max
    canonical_trigger_after_direct_hit(user,target,type,cat,data,hp_damage,target.last_damage_critical) if hp_damage>0
    if was_alive && target.dead? && user.alive? && user.ability_key==:moxie
      b=user.canonical_trigger_behavior
      if user.can_change_stat_stage?(b[:stat],b[:stages].to_i)
        actual=user.change_stat_stage(b[:stat],b[:stages].to_i,user);log_event(:ability_trigger,user.log_name+" moxie KO boost="+actual.to_s+" target="+target.log_name)
      end
    end
    result
  end
  def canonical_trigger_after_direct_hit(attacker,target,type,category,data,hp_damage,critical)
    return if target==nil || target.dead?
    b=target.canonical_trigger_behavior
    case b[:kind]
    when :on_hit_type_stage
      if (b[:move_types]||[]).include?(type)
        a=target.change_stat_stage(b[:stat],b[:stages].to_i,target);log_event(:ability_trigger,target.log_name+" "+target.ability_key.to_s+" HIT_TYPE="+type.to_s+" stage="+a.to_s)
      end
    when :on_hit_category_multi
      if category==b[:category]
        vals=[];for c in (b[:changes]||[]);vals.push(c[:stat].to_s+":"+target.change_stat_stage(c[:stat],c[:stages].to_i,target).to_s);end
        log_event(:ability_trigger,target.log_name+" weak_armor PHYSICAL ["+vals.join(",")+"]")
      end
    when :on_critical_set_stage
      if critical
        delta=b[:stage].to_i-target.stat_stage(b[:stat]);a=target.change_stat_stage(b[:stat],delta,target);log_event(:ability_trigger,target.log_name+" anger_point CRIT set="+target.stat_stage(b[:stat]).to_s+" actual="+a.to_s)
      end
    end
  end
  def canonical_contact_move?(attacker,data)
    return !attacker.ranged? if data==nil
    data[:contact] || (data[:source_move_flags]||[]).include?(:contact)
  end
  def canonical_indirect_ability_damage(target,source,amount,label)
    return 0 if target==nil || target.dead? || amount.to_i<=0
    if target.ability_key==:magic_guard
      log_event(:ability_trigger,target.log_name+" magic_guard BLOCK "+label);return 0
    end
    before=target.hp;target.receive_damage(amount,source,false,true,false);before-target.hp
  end
  def canonical_global_ability_units
    list=[];list+=@units if @units!=nil;list+=@ability_trigger_test_units if @ability_trigger_test_units!=nil;list.uniq
  end
  def canonical_damp_active?
    canonical_global_ability_units.any?{|u|u!=nil && u.alive? && u.ability_key==:damp}
  end
  def canonical_contact_ability_after_hit(attacker,defender,data,result)
    pmd_ac_v025_canonical_contact_ability_after_hit(attacker,defender,data,result)
    return if attacker==nil || defender==nil || attacker.dead? || !canonical_contact_move?(attacker,data)
    b=defender.canonical_trigger_behavior
    case b[:kind]
    when :contact_random_status
      roll=canonical_trigger_ability_roll(b[:roll_max].to_i);status=nil
      for x in (b[:distribution]||[]);status=x[:status] if roll>=x[:from].to_i && roll<=x[:to].to_i;end
      log_event(:ability_trigger,defender.log_name+" effect_spore roll="+roll.to_s+" status="+(status||:none).to_s)
      canonical_apply_trigger_major_status(attacker,status,defender) if status!=nil
    when :contact_indirect_damage
      amount=[attacker.maxhp*b[:ratio_num].to_i/b[:ratio_den].to_i,1].max;dmg=canonical_indirect_ability_damage(attacker,defender,amount,:rough_skin)
      log_event(:ability_trigger,defender.log_name+" rough_skin damage="+dmg.to_s)
    when :contact_faint_indirect_damage
      if defender.dead?
        if canonical_damp_active?;log_event(:ability_trigger,defender.log_name+" aftermath BLOCKED_BY_DAMP")
        else
          amount=[attacker.maxhp*b[:ratio_num].to_i/b[:ratio_den].to_i,1].max;dmg=canonical_indirect_ability_damage(attacker,defender,amount,:aftermath);log_event(:ability_trigger,defender.log_name+" aftermath damage="+dmg.to_s)
        end
      end
    end
  end

  # Verification -------------------------------------------------------------
  def verify_ability_trigger_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::AbilityTriggerDB.manifest;e=PMD_AC.validate_ability_trigger_db;actual=PMD_AC.ability_trigger_checksum32;pass=e.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" new="+m[:new_trigger_ability_count].to_s+" cumulative="+m[:cumulative_ability_behavior_count].to_s+" slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+" coverage="+m[:implemented_slot_coverage_percent].to_s+"% species="+m[:species_with_any_implemented_ability].to_s+"/494 checksum="+actual.to_s+" errors=["+e.join(",")+"]");@verification_done[tag]=true
  end
  def verify_ability_trigger_turn_end(tag)
    return if @verification_done[tag]
    shed=ability_trigger_verification_unit(:metapod,:primary,:ally,1);src=ability_trigger_verification_unit(:rattata,:primary,:enemy,2);canonical_apply_trigger_major_status(shed,:burn,src);set_ability_trigger_rolls([0]);cured=shed.canonical_trigger_turn_end && !shed.status?(:burn);canonical_apply_trigger_major_status(shed,:burn,src);set_ability_trigger_rolls([1]);held=!shed.canonical_trigger_turn_end && shed.status?(:burn)
    spd=ability_trigger_verification_unit(:ninjask,:primary,:ally,3);before=spd.stat_stage(:speed);spd.canonical_trigger_turn_end;boost=spd.stat_stage(:speed)==before+1
    pass=cured && held && boost;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" shed_roll0_cure="+(cured ? "1":"0")+" shed_roll1_hold="+(held ? "1":"0")+" speed_boost="+before.to_s+"->"+spd.stat_stage(:speed).to_s);@verification_done[tag]=true
  end
  def verify_ability_trigger_response(tag)
    return if @verification_done[tag]
    foe=ability_trigger_verification_unit(:rattata,:primary,:enemy,10);defi=ability_trigger_verification_unit(:piplup,:hidden,:ally,11);defi.change_stat_stage(:def,-1,foe);defiant=defi.stat_stage(:def)==-1 && defi.stat_stage(:atk)==2
    steady=ability_trigger_verification_unit(:gallade,:primary,:ally,12);fl=steady.canonical_apply_flinch(foe);steadfast=fl && steady.stat_stage(:speed)==1
    pass=defiant && steadfast;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" defiant_def="+defi.stat_stage(:def).to_s+" atk="+defi.stat_stage(:atk).to_s+" steadfast_speed="+steady.stat_stage(:speed).to_s);@verification_done[tag]=true
  end
  def verify_ability_trigger_on_hit(tag)
    return if @verification_done[tag]
    atk=ability_trigger_verification_unit(:rattata,:primary,:ally,20)
    weak=ability_trigger_verification_unit(:skarmory,:hidden,:enemy,21);deal_direct_damage(atk,weak,40,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false});w=weak.stat_stage(:def)==-1 && weak.stat_stage(:speed)==1
    rat=ability_trigger_verification_unit(:magikarp,:hidden,:enemy,22);deal_direct_damage(atk,rat,40,{:move_type=>:dark,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false});r=rat.stat_stage(:speed)==1
    just=ability_trigger_verification_unit(:absol,:hidden,:enemy,23);deal_direct_damage(atk,just,40,{:move_type=>:dark,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false});j=just.stat_stage(:atk)==1
    anger=ability_trigger_verification_unit(:tauros,:secondary,:enemy,24);deal_direct_damage(atk,anger,40,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:modifier=>{:force_crit=>true}});a=anger.stat_stage(:atk)==6
    pass=w&&r&&j&&a;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" weak_armor="+weak.stat_stage(:def).to_s+"/"+weak.stat_stage(:speed).to_s+" rattled="+rat.stat_stage(:speed).to_s+" justified="+just.stat_stage(:atk).to_s+" anger_point="+anger.stat_stage(:atk).to_s);@verification_done[tag]=true
  end
  def verify_ability_trigger_synchronize(tag)
    return if @verification_done[tag]
    src=ability_trigger_verification_unit(:rattata,:primary,:enemy,30);sync=ability_trigger_verification_unit(:espeon,:primary,:ally,31);canonical_apply_trigger_major_status(sync,:burn,src);pass=sync.status?(:burn)&&src.status?(:burn)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" holder_burn="+(sync.status?(:burn) ? "1":"0")+" reflected="+(src.status?(:burn) ? "1":"0"));@verification_done[tag]=true
  end
  def verify_ability_trigger_contact(tag)
    return if @verification_done[tag]
    atk=ability_trigger_verification_unit(:rattata,:primary,:ally,40);rough=ability_trigger_verification_unit(:gible,:hidden,:enemy,41);before=atk.hp;deal_direct_damage(atk,rough,30,{:skill_data=>{:canonical_move_key=>:verify_contact,:move_type=>:normal,:damage_category=>:physical,:contact=>true},:random_percent=>100,:directional=>false,:can_crit=>false});expected=[atk.maxhp/8,1].max;rs=(before-atk.hp)==expected
    atk2=ability_trigger_verification_unit(:rattata,:primary,:ally,42);spore=ability_trigger_verification_unit(:paras,:primary,:enemy,43);set_ability_trigger_rolls([0]);deal_direct_damage(atk2,spore,30,{:skill_data=>{:canonical_move_key=>:verify_contact,:move_type=>:normal,:damage_category=>:physical,:contact=>true},:random_percent=>100,:directional=>false,:can_crit=>false});poison=atk2.status?(:poison)
    atk3=ability_trigger_verification_unit(:rattata,:primary,:ally,44);spore2=ability_trigger_verification_unit(:paras,:primary,:enemy,45);set_ability_trigger_rolls([9]);deal_direct_damage(atk3,spore2,30,{:skill_data=>{:canonical_move_key=>:verify_contact,:move_type=>:normal,:damage_category=>:physical,:contact=>true},:random_percent=>100,:directional=>false,:can_crit=>false});para=atk3.status?(:paralysis)
    atk4=ability_trigger_verification_unit(:rattata,:primary,:ally,46);spore3=ability_trigger_verification_unit(:paras,:primary,:enemy,47);set_ability_trigger_rolls([19]);deal_direct_damage(atk4,spore3,30,{:skill_data=>{:canonical_move_key=>:verify_contact,:move_type=>:normal,:damage_category=>:physical,:contact=>true},:random_percent=>100,:directional=>false,:can_crit=>false});sleep=atk4.sleeping?
    pass=rs&&poison&&para&&sleep;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" rough_skin="+(before-atk.hp).to_s+" expected="+expected.to_s+" effect_spore_roll0="+(poison ? "poison":"fail")+" roll9="+(para ? "paralysis":"fail")+" roll19="+(sleep ? "sleep":"fail"));@verification_done[tag]=true
  end
  def verify_ability_trigger_ko_sturdy(tag)
    return if @verification_done[tag]
    mox=ability_trigger_verification_unit(:gyarados,:hidden,:ally,50);victim=ability_trigger_verification_unit(:rattata,:primary,:enemy,51);victim.instance_variable_set(:@hp,1);deal_direct_damage(mox,victim,50,{:fixed_damage=>50,:move_type=>:normal,:damage_category=>:physical,:directional=>false,:can_crit=>false});mx=victim.dead? && mox.stat_stage(:atk)==1
    atk=ability_trigger_verification_unit(:rattata,:primary,:ally,52);st=ability_trigger_verification_unit(:aggron,:primary,:enemy,53);deal_direct_damage(atk,st,50,{:fixed_damage=>st.maxhp*2,:move_type=>:fighting,:damage_category=>:physical,:directional=>false,:can_crit=>false});sd=st.hp==1
    st2=ability_trigger_verification_unit(:aggron,:primary,:enemy,54);st2.apply_status(:confusion,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},atk);st2.receive_damage(st2.maxhp*2,st2,false,true,false);sc=st2.hp==1
    pass=mx&&sd&&sc;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" moxie_atk="+mox.stat_stage(:atk).to_s+" sturdy_direct_hp="+st.hp.to_s+" sturdy_confusion_hp="+st2.hp.to_s);@verification_done[tag]=true
  end
  def verify_ability_trigger_aftermath(tag)
    return if @verification_done[tag]
    atk=ability_trigger_verification_unit(:rattata,:primary,:ally,60);aft=ability_trigger_verification_unit(:drifloon,:primary,:enemy,61);aft.instance_variable_set(:@hp,1);before=atk.hp;deal_direct_damage(atk,aft,30,{:skill_data=>{:canonical_move_key=>:verify_contact,:move_type=>:normal,:damage_category=>:physical,:contact=>true},:fixed_damage=>30,:directional=>false,:can_crit=>false});expected=[atk.maxhp/4,1].max;normal=(before-atk.hp)==expected
    damp=ability_trigger_verification_unit(:psyduck,:primary,:ally,62);atk2=ability_trigger_verification_unit(:rattata,:primary,:ally,63);aft2=ability_trigger_verification_unit(:drifloon,:primary,:enemy,64);aft2.instance_variable_set(:@hp,1);b2=atk2.hp;deal_direct_damage(atk2,aft2,30,{:skill_data=>{:canonical_move_key=>:verify_contact,:move_type=>:normal,:damage_category=>:physical,:contact=>true},:fixed_damage=>30,:directional=>false,:can_crit=>false});blocked=atk2.hp==b2
    pass=normal&&blocked;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" aftermath="+(before-atk.hp).to_s+" expected="+expected.to_s+" damp_block="+(blocked ? "1":"0")+" damp="+damp.ability_key.to_s);@verification_done[tag]=true
  end
  def verify_ability_trigger_runtime_file(tag)
    return if @verification_done[tag];p=FileTest.exist?(PMD_AC::ABILITY_TRIGGER_RUNTIME_FILE);log_event(:verify,tag.to_s.upcase+" pass="+(p ? "1":"0")+" runtime_file="+(p ? "present":"missing")+" source="+(PMD_AC::AbilityTriggerDB.using_runtime_file? ? "rvdata":"embedded_first_boot"));@verification_done[tag]=true
  end
  def update_verification_script
    pmd_ac_v025_update_verification_script;return unless verification_mode==:ability_trigger;f=@verification_frame
    verify_ability_trigger_manifest(:ability_trigger_manifest) if f==4
    verify_ability_trigger_turn_end(:ability_trigger_turn_end) if f==45
    verify_ability_trigger_response(:ability_trigger_response) if f==90
    verify_ability_trigger_on_hit(:ability_trigger_on_hit) if f==140
    verify_ability_trigger_synchronize(:ability_trigger_synchronize) if f==190
    verify_ability_trigger_contact(:ability_trigger_contact) if f==245
    verify_ability_trigger_ko_sturdy(:ability_trigger_ko_sturdy) if f==310
    verify_ability_trigger_aftermath(:ability_trigger_aftermath) if f==365
    verify_ability_trigger_runtime_file(:ability_trigger_runtime_file) if f==410
    complete_verification_mode if f==PMD_AC::VERIFICATION_ABILITY_TRIGGER_END_FRAME
  end
  def log_event(category,message)
    if category.to_s=="verify";t=message.to_s;@ability_trigger_failed=true if t.index("ABILITY_TRIGGER_")==0 && t.include?(" pass=0");end
    pmd_ac_v025_log_event(category,message)
  end
  def complete_verification_mode
    if verification_mode==:ability_trigger && @ability_trigger_failed
      return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;log_event(:verify,"FAILED mode=ABILITY_TRIGGER auto_skill=on original_skills=restored");return
    end
    pmd_ac_v025_complete_verification_mode
  end
end
