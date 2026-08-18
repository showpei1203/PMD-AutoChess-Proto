#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.24
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - ABILITY_RUNTIME_FILE / USE_EXTERNAL_ABILITY_DB / VERIFICATION_ABILITY_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / embedded_data
# - load! / manifest / behavior / behavior_count
# - species_slots / ability_slots / ability_data / ability_behavior
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.24
#    Generation V Ability Slot + Ability Behavior Foundation
#------------------------------------------------------------------------------
#  Base: verified v0.23.2 FullTestProject.
#  Existing combat layers remain untouched; this file is an adapter.
#==============================================================================
module PMD_AC
  ABILITY_RUNTIME_FILE="Data/PMD_AutoChess_Abilities_v024_000.rvdata"
  USE_EXTERNAL_ABILITY_DB=true unless const_defined?(:USE_EXTERNAL_ABILITY_DB)
  VERIFICATION_ABILITY_END_FRAME=430

  module AbilityDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def embedded_data;{:manifest=>PMD_AC::ABILITY_MANIFEST_V024,:behaviors=>PMD_AC::ABILITY_BEHAVIOR_V024,:species_slots=>PMD_AC::ABILITY_SPECIES_SLOTS_V024};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_ABILITY_DB && FileTest.exist?(PMD_AC::ABILITY_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::ABILITY_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) && c[:species_slots].is_a?(Hash) && c[:manifest][:content_version]=="0.24.0"
              data=c;@using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil;@data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_ABILITY_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::ABILITY_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def manifest;load! unless loaded?;@data[:manifest]||{};end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def behavior_count;load! unless loaded?;(@data[:behaviors]||{}).size;end
      def species_slots(key);load! unless loaded?;(@data[:species_slots]||{})[key]||{};end
    end
  end
  AbilityDB.load!

  class << self
    alias pmd_ac_v024_ability_slots ability_slots unless method_defined?(:pmd_ac_v024_ability_slots)
    alias pmd_ac_v024_ability_data ability_data unless method_defined?(:pmd_ac_v024_ability_data)
    def ability_slots(species_key)
      s=AbilityDB.species_slots(species_key)
      return s unless s==nil || s.empty?
      pmd_ac_v024_ability_slots(species_key)
    end
    def ability_data(key)
      b=AbilityDB.behavior(key)
      return b unless b==nil || b.empty?
      pmd_ac_v024_ability_data(key)
    end
    def ability_behavior(key);AbilityDB.behavior(key);end
    def ability_checksum32
      h=0
      for k in AbilityDB.instance_variable_get(:@data)[:behaviors].keys.sort{|a,b|a.to_s<=>b.to_s}
        d=AbilityDB.behavior(k)
        fields=[k,d[:kind],d[:type],d[:mult],d[:threshold],d[:heal_ratio],d[:boost_mult],d[:max_power],d[:flag],d[:canonical_stab],d[:base_stab],d[:statuses],d[:stats],d[:target],d[:stat],d[:stages],d[:status],d[:chance],d[:form_only]]
        text=fields.collect{|x|x.is_a?(Array) ? x.join(",") : x.to_s}.join("|")
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      keys=AbilityDB.instance_variable_get(:@data)[:species_slots].keys.sort{|a,b|a.to_s<=>b.to_s}
      for sk in keys
        s=AbilityDB.species_slots(sk);text=[sk,s[:primary],s[:secondary],s[:hidden]].collect{|x|x.to_s}.join("|")
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_ability_db
      e=[];m=AbilityDB.manifest
      e.push("count") unless AbilityDB.behavior_count==42
      e.push("species") unless AbilityDB.instance_variable_get(:@data)[:species_slots].size==494
      e.push("slots") unless m[:total_slot_count].to_i==1193 && m[:implemented_slot_count].to_i==403
      e.push("corrections") unless m[:corrected_slot_count].to_i==27
      e.push("gengar") unless ability_slots(:gengar)[:primary]==:levitate
      e.push("koffing") unless ability_slots(:koffing)[:secondary]==nil
      e.push("piplup") unless ability_slots(:piplup)[:hidden]==:defiant
      e.push("checksum") unless ability_checksum32==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,:progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary,:speed_status,:action_status,:ability]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",:ability=>"ABILITY"}
end

class Game_PMDChessUnit
  alias pmd_ac_v024_initialize initialize unless method_defined?(:pmd_ac_v024_initialize)
  alias pmd_ac_v024_ability_outgoing_multiplier ability_outgoing_multiplier unless method_defined?(:pmd_ac_v024_ability_outgoing_multiplier)
  alias pmd_ac_v024_ability_incoming_multiplier ability_incoming_multiplier unless method_defined?(:pmd_ac_v024_ability_incoming_multiplier)
  alias pmd_ac_v024_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v024_change_stat_stage)
  alias pmd_ac_v024_apply_canonical_recoil apply_canonical_recoil unless method_defined?(:pmd_ac_v024_apply_canonical_recoil)
  alias pmd_ac_v024_canonical_apply_sleep canonical_apply_sleep unless method_defined?(:pmd_ac_v024_canonical_apply_sleep)
  alias pmd_ac_v024_canonical_apply_freeze canonical_apply_freeze unless method_defined?(:pmd_ac_v024_canonical_apply_freeze)
  alias pmd_ac_v024_canonical_apply_confusion canonical_apply_confusion unless method_defined?(:pmd_ac_v024_canonical_apply_confusion)
  alias pmd_ac_v024_canonical_apply_flinch canonical_apply_flinch unless method_defined?(:pmd_ac_v024_canonical_apply_flinch)

  def initialize(*args)
    pmd_ac_v024_initialize(*args)
    @canonical_flash_fire_active=false
  end
  def canonical_ability_behavior;PMD_AC.ability_behavior(ability_key)||{};end
  def canonical_flash_fire_active?;@canonical_flash_fire_active ? true : false;end
  def canonical_ability_status_immune?(status)
    b=canonical_ability_behavior
    return false unless b[:kind]==:status_immunity
    (b[:statuses]||[]).include?(status)
  end
  def canonical_ability_secondary_block?;canonical_ability_behavior[:kind]==:secondary_block;end
  def canonical_ability_crit_immune?;canonical_ability_behavior[:kind]==:critical_immunity;end
  def canonical_ability_sound_immune?;canonical_ability_behavior[:kind]==:sound_immunity;end

  # v0.15 Guts only knew Burn/Poison because other canonical major statuses did
  # not exist yet.  v0.24 upgrades the already-verified hook to the Gen-V set.
  def major_status_for_guts?
    return true if status?(:poison) || status?(:burn) || status?(:paralysis) || status?(:sleep) || status?(:freeze)
    false
  end

  def ability_outgoing_multiplier(move_type,category,effectiveness=1.0)
    base=pmd_ac_v024_ability_outgoing_multiplier(move_type,category,effectiveness)
    b=canonical_ability_behavior
    case b[:kind]
    when :low_hp_type
      # overgrow/blaze/torrent are already handled by the legacy hook.
      if ability_key==:swarm
        rate=@hp.to_f/[maxhp,1].max.to_f
        base*=b[:mult].to_f if move_type==b[:type] && rate<=b[:threshold].to_f
      end
    when :stab_multiplier
      if pokemon_types.include?(move_type)
        den=b[:base_stab].to_f;den=1.5 if den<=0.0;base*=b[:canonical_stab].to_f/den
      end
    when :physical_multiplier
      base*=b[:mult].to_f if category==:physical
    when :type_absorb_boost
      base*=b[:boost_mult].to_f if @canonical_flash_fire_active && move_type==b[:type]
    end
    base
  end

  def ability_incoming_multiplier(move_type,category)
    base=pmd_ac_v024_ability_incoming_multiplier(move_type,category)
    return base if base<=0.0
    b=canonical_ability_behavior
    case b[:kind]
    when :type_immunity
      return 0.0 if move_type==b[:type]
    when :type_absorb
      if move_type==b[:type]
        amount=[(maxhp*b[:heal_ratio].to_f).floor,1].max
        heal(amount)
        log_event(:ability,log_name+" "+ability_key.to_s+" ABSORB type="+move_type.to_s+" heal="+amount.to_s)
        return 0.0
      end
    when :type_absorb_boost
      if move_type==b[:type]
        @canonical_flash_fire_active=true
        log_event(:ability,log_name+" "+ability_key.to_s+" ACTIVATE type="+move_type.to_s)
        return 0.0
      end
    when :super_effective_reduction
      eff=PMD_AC.type_effectiveness(move_type,pokemon_types)
      base*=b[:mult].to_f if eff>1.0
    end
    base
  end

  def canonical_ability_move_power_multiplier(data)
    return 1.0 if data==nil
    b=canonical_ability_behavior;kind=b[:kind]
    case kind
    when :move_power_threshold
      p=(data[:canonical_power]||0).to_i
      return b[:mult].to_f if p>0 && p<=b[:max_power].to_i
    when :move_flag_power
      flag=b[:flag]
      flags=data[:source_move_flags]||[]
      return b[:mult].to_f if flags.include?(flag) || (flag==:contact && data[:contact]) || (flag==:pulse && data[:pulse])
    when :recoil_move_power
      return b[:mult].to_f if (data[:effects]||[]).any?{|e|e[:type]==:recoil_last_damage}
    end
    1.0
  end

  def change_stat_stage(stat,delta,source=nil)
    if delta.to_i<0 && source!=nil && source.respond_to?(:team) && source.team!=team
      b=canonical_ability_behavior
      block=false
      if b[:kind]==:stat_drop_immunity
        stats=b[:stats]
        block=true if stats==:all || (stats.is_a?(Array) && stats.include?(stat))
      end
      if block
        log_event(:ability,log_name+" "+ability_key.to_s+" BLOCK_STAT_DROP stat="+stat.to_s+" src="+source.log_name)
        return 0
      end
    end
    pmd_ac_v024_change_stat_stage(stat,delta,source)
  end

  def apply_canonical_recoil(value)
    if canonical_ability_behavior[:kind]==:recoil_immunity
      log_event(:ability,log_name+" "+ability_key.to_s+" BLOCK_RECOIL value="+value.to_i.to_s)
      return 0
    end
    pmd_ac_v024_apply_canonical_recoil(value)
  end

  def canonical_apply_sleep(source=nil)
    if canonical_ability_status_immune?(:sleep);log_event(:ability,log_name+" "+ability_key.to_s+" IMMUNE status=sleep");return false;end
    pmd_ac_v024_canonical_apply_sleep(source)
  end
  def canonical_apply_freeze(source=nil)
    if canonical_ability_status_immune?(:freeze);log_event(:ability,log_name+" "+ability_key.to_s+" IMMUNE status=freeze");return false;end
    pmd_ac_v024_canonical_apply_freeze(source)
  end
  def canonical_apply_confusion(source=nil)
    if canonical_ability_status_immune?(:confusion);log_event(:ability,log_name+" "+ability_key.to_s+" IMMUNE status=confusion");return false;end
    pmd_ac_v024_canonical_apply_confusion(source)
  end
  def canonical_apply_flinch(source=nil)
    if canonical_ability_status_immune?(:flinch);log_event(:ability,log_name+" "+ability_key.to_s+" IMMUNE status=flinch");return false;end
    pmd_ac_v024_canonical_apply_flinch(source)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v024_start start unless method_defined?(:pmd_ac_v024_start)
  alias pmd_ac_v024_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v024_prepare_verification_battle)
  alias pmd_ac_v024_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v024_deal_direct_damage)
  alias pmd_ac_v024_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v024_apply_skill_effects)
  alias pmd_ac_v024_apply_canonical_secondary_group apply_canonical_secondary_group unless method_defined?(:pmd_ac_v024_apply_canonical_secondary_group)
  alias pmd_ac_v024_canonical_secondary_roll canonical_secondary_roll unless method_defined?(:pmd_ac_v024_canonical_secondary_roll)
  alias pmd_ac_v024_canonical_secondary_status_immune canonical_secondary_status_immune? unless method_defined?(:pmd_ac_v024_canonical_secondary_status_immune)
  alias pmd_ac_v024_start_battle start_battle unless method_defined?(:pmd_ac_v024_start_battle)
  alias pmd_ac_v024_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v024_update_verification_script)
  alias pmd_ac_v024_log_event log_event unless method_defined?(:pmd_ac_v024_log_event)
  alias pmd_ac_v024_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v024_complete_verification_mode)

  def start
    pmd_ac_v024_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.23.2 Battle Verification Log","PMD AutoChess Proto v0.24 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::AbilityDB.manifest
    log_event(:ability,"LOADED behaviors="+PMD_AC::AbilityDB.behavior_count.to_s+
      " gen5_slots="+m[:total_slot_count].to_s+
      " implemented_slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+
      " corrected="+m[:corrected_slot_count].to_s+
      " source="+(PMD_AC::AbilityDB.using_runtime_file? ? "rvdata":"embedded")+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v024_prepare_verification_battle
    if verification_mode==:ability
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages;end
      @ability_verification_failed=false;@ability_verification_rolls=[];@ability_secondary_rolls=[];@ability_test_units=[]
    end
  end

  def ability_verification_unit(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99024000+id.to_i,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(8000+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @ability_test_units=[] if @ability_test_units==nil;@ability_test_units.push(u);u
  end
  def set_ability_verification_rolls(v);@ability_verification_rolls=v.dup;end
  def set_ability_secondary_rolls(v);@ability_secondary_rolls=v.dup;end
  def canonical_ability_roll(chance)
    c=PMD_AC.clamp(chance.to_i,0,100)
    roll=(verification_mode==:ability && @ability_verification_rolls!=nil && !@ability_verification_rolls.empty?) ? @ability_verification_rolls.shift.to_i : rand(100)
    [roll<c,roll]
  end
  def canonical_secondary_roll(chance)
    if verification_mode==:ability && @ability_secondary_rolls!=nil && !@ability_secondary_rolls.empty?
      c=PMD_AC.clamp(chance.to_i,0,100);return [true,0] if c>=100;roll=@ability_secondary_rolls.shift.to_i;return [roll<c,roll]
    end
    pmd_ac_v024_canonical_secondary_roll(chance)
  end

  def canonical_secondary_status_immune?(unit,status)
    return true if unit!=nil && unit.respond_to?(:canonical_ability_status_immune?) && unit.canonical_ability_status_immune?(status)
    pmd_ac_v024_canonical_secondary_status_immune(unit,status)
  end

  def apply_canonical_secondary_group(user,target,data,effects,result)
    list=effects||[]
    if target!=nil && target.respond_to?(:canonical_ability_secondary_block?) && target.canonical_ability_secondary_block? && list.any?{|e|e[:receiver]!=:user}
      log_event(:ability,target.log_name+" shield_dust BLOCK_SECONDARY move="+(data[:canonical_move_key]||:unknown).to_s)
      return
    end
    if user!=nil && user.ability_key==:serene_grace && !list.empty?
      list=list.collect{|e|x=e.dup;x[:chance]=[e[:chance].to_i*2,100].min;x}
      log_event(:ability,user.log_name+" serene_grace SECONDARY_X2 chance="+list[0][:chance].to_s)
    end
    pmd_ac_v024_apply_canonical_secondary_group(user,target,data,list,result)
  end

  def deal_direct_damage(user,target,power,options=nil)
    return 0 if user==nil || target==nil
    options={} if options==nil
    data=options[:skill_data]
    if data!=nil && target.respond_to?(:canonical_ability_sound_immune?) && target.canonical_ability_sound_immune? && (data[:sound] || (data[:source_move_flags]||[]).include?(:sound))
      log_event(:ability,target.log_name+" soundproof IMMUNE sound_move="+(data[:canonical_move_key]||:unknown).to_s)
      return 0
    end
    opts=options.dup
    if target.respond_to?(:canonical_ability_crit_immune?) && target.canonical_ability_crit_immune?
      opts[:can_crit]=false
    end
    mult=user.respond_to?(:canonical_ability_move_power_multiplier) ? user.canonical_ability_move_power_multiplier(data) : 1.0
    if mult!=1.0
      log_event(:ability,user.log_name+" "+user.ability_key.to_s+" MOVE_POWER_X"+sprintf("%.2f",mult)+" move="+(data==nil ? "basic" : (data[:canonical_move_key]||:unknown).to_s))
    end
    result=pmd_ac_v024_deal_direct_damage(user,target,(power.to_f*mult).round,opts)
    canonical_contact_ability_after_hit(user,target,data,result) if result.to_i>0
    result
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if target!=nil && target.respond_to?(:canonical_ability_sound_immune?) && target.canonical_ability_sound_immune? && data!=nil && (data[:sound] || (data[:source_move_flags]||[]).include?(:sound))
      log_event(:ability,target.log_name+" soundproof IMMUNE_EFFECT move="+(data[:canonical_move_key]||:unknown).to_s)
      return 0
    end
    pmd_ac_v024_apply_skill_effects(user,target,data,scale)
  end

  def canonical_contact_ability_after_hit(attacker,defender,data,result)
    return if attacker==nil || defender==nil || attacker.dead?
    contact=false
    if data==nil
      contact=!attacker.ranged?
    else
      contact=true if data[:contact] || (data[:source_move_flags]||[]).include?(:contact)
    end
    return unless contact
    b=defender.canonical_ability_behavior;return unless b[:kind]==:contact_status
    proc_result,roll=canonical_ability_roll(b[:chance])
    log_event(:ability,defender.log_name+" "+defender.ability_key.to_s+" CONTACT chance="+b[:chance].to_s+" roll="+roll.to_s+" proc="+(proc_result ? "1":"0"))
    return unless proc_result
    st=b[:status];return if canonical_secondary_status_immune?(attacker,st)
    case st
    when :paralysis
      attacker.apply_status(:paralysis,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},defender)
    when :poison
      val=[(attacker.maxhp*0.015).round,1].max;attacker.apply_status(:poison,{:duration=>180,:value=>val,:interval=>30,:stack_mode=>:refresh},defender)
    when :burn
      val=[(attacker.maxhp*0.0125).round,1].max;attacker.apply_status(:burn,{:duration=>180,:value=>val,:interval=>30,:stack_mode=>:refresh},defender)
    end
  end

  def apply_canonical_intimidate(user,targets=nil)
    return 0 if user==nil || user.ability_key!=:intimidate
    list=targets || enemies_of(user);n=0
    for t in list
      next if t==nil || t.dead?
      before=t.stat_stage(:atk);t.change_stat_stage(:atk,-1,user);n+=1 if t.stat_stage(:atk)<before
    end
    log_event(:ability,user.log_name+" intimidate targets="+list.size.to_s+" lowered="+n.to_s)
    n
  end
  def apply_canonical_entry_abilities
    return if @units==nil
    for u in @units;apply_canonical_intimidate(u) if u.alive? && u.ability_key==:intimidate;end
  end
  def start_battle
    pmd_ac_v024_start_battle
    apply_canonical_entry_abilities if @phase==:battle
  end

  # --------------------------------------------------------------------------
  # Verification
  # --------------------------------------------------------------------------
  def verify_ability_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::AbilityDB.manifest;e=PMD_AC.validate_ability_db
    pass=e.empty? && m[:implemented_ability_count].to_i==42 && m[:implemented_slot_count].to_i==403 && m[:species_with_any_implemented_ability].to_i==318
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" behaviors=42 slots=403/1193 coverage="+m[:implemented_slot_coverage_percent].to_s+"% species=318/494 corrected=27 checksum32="+m[:runtime_checksum32].to_s+" errors=["+e.join(",")+"]")
    @verification_done[tag]=true
  end
  def verify_ability_gen5_slots(tag)
    return if @verification_done[tag]
    a=PMD_AC.ability_slots(:gengar);b=PMD_AC.ability_slots(:koffing);c=PMD_AC.ability_slots(:piplup);d=PMD_AC.ability_slots(:zapdos);e=PMD_AC.ability_slots(:gallade)
    pass=a[:primary]==:levitate && b[:secondary]==nil && c[:hidden]==:defiant && d[:hidden]==:lightning_rod && e[:secondary]==nil
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" gengar="+a[:primary].to_s+" koffing2="+b[:secondary].to_s+" piplupH="+c[:hidden].to_s+" zapdosH="+d[:hidden].to_s+" gallade2="+e[:secondary].to_s)
    @verification_done[tag]=true
  end
  def verify_ability_damage(tag)
    return if @verification_done[tag]
    t=ability_verification_unit(:rattata,:primary,:enemy,1)
    o=ability_verification_unit(:bulbasaur,:primary,:ally,2);o.verification_set_hp_percent(1.0);full=o.calculate_damage(t,60,:special,:grass,100);o.verification_set_hp_percent(0.30);low=o.calculate_damage(t,60,:special,:grass,100)
    pz=ability_verification_unit(:porygon_z,:primary,:ally,3);pz2=ability_verification_unit(:porygon_z,:secondary,:ally,4);ad=pz.calculate_damage(t,50,:special,:normal,100);normal=pz2.calculate_damage(t,50,:special,:normal,100)
    sc1=ability_verification_unit(:scizor,:secondary,:ally,5);sc2=ability_verification_unit(:scizor,:primary,:ally,6);sd=PMD_AC.skill_data(:mv_rock_smash);tech=deal_direct_damage(sc1,t,40,{:skill_data=>sd,:random_percent=>100,:directional=>false,:can_crit=>false});plain=deal_direct_damage(sc2,t,40,{:skill_data=>sd,:random_percent=>100,:directional=>false,:can_crit=>false})
    pass=low>full && ad>normal && tech>plain
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" overgrow="+full.to_s+"->"+low.to_s+" adaptability="+normal.to_s+"->"+ad.to_s+" technician="+plain.to_s+"->"+tech.to_s)
    @verification_done[tag]=true
  end
  def verify_ability_defense_absorb(tag)
    return if @verification_done[tag]
    atk=ability_verification_unit(:rattata,:primary,:ally,10)
    gen=ability_verification_unit(:gengar,:primary,:enemy,11);lev=atk.calculate_damage(gen,80,:physical,:ground,100)
    vap=ability_verification_unit(:vaporeon,:primary,:enemy,12);vap.verification_set_hp_percent(0.40);vb=vap.hp;wd=atk.calculate_damage(vap,80,:special,:water,100);vh=vap.hp-vb
    fla=ability_verification_unit(:flareon,:primary,:enemy,13);fd=atk.calculate_damage(fla,80,:special,:fire,100);active=fla.canonical_flash_fire_active?
    sn=ability_verification_unit(:snorlax,:secondary,:enemy,14);normal=ability_verification_unit(:snorlax,:primary,:enemy,15);tf=atk.calculate_damage(sn,80,:special,:fire,100);nf=atk.calculate_damage(normal,80,:special,:fire,100)
    pass=lev==0 && wd==0 && vh>0 && fd==0 && active && tf<nf
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" levitate="+lev.to_s+" water_absorb_damage="+wd.to_s+" heal="+vh.to_s+" flash_fire="+(active ? "active":"off")+" thick_fat="+nf.to_s+"->"+tf.to_s)
    @verification_done[tag]=true
  end
  def verify_ability_status(tag)
    return if @verification_done[tag]
    src=ability_verification_unit(:rattata,:primary,:enemy,20)
    own=ability_verification_unit(:lickitung,:primary,:ally,21);conf=own.canonical_apply_confusion(src)
    ins=ability_verification_unit(:drowzee,:primary,:ally,22);slp=ins.canonical_apply_sleep(src)
    inf=ability_verification_unit(:drowzee,:hidden,:ally,23);fl=inf.canonical_apply_flinch(src)
    lim=ability_verification_unit(:persian,:primary,:ally,24);para=canonical_secondary_status_immune?(lim,:paralysis)
    gol=ability_verification_unit(:goldeen,:secondary,:ally,25);burn=canonical_secondary_status_immune?(gol,:burn)
    sno=ability_verification_unit(:snorlax,:primary,:ally,26);pois=canonical_secondary_status_immune?(sno,:poison)
    pass=!conf && !slp && !fl && para && burn && pois
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" own_tempo="+(!conf ? "immune":"fail")+" insomnia="+(!slp ? "immune":"fail")+" inner_focus="+(!fl ? "immune":"fail")+" limber="+(para ? "immune":"fail")+" water_veil="+(burn ? "immune":"fail")+" immunity="+(pois ? "immune":"fail"))
    @verification_done[tag]=true
  end
  def verify_ability_secondary(tag)
    return if @verification_done[tag]
    user=ability_verification_unit(:rattata,:primary,:ally,30);dust=ability_verification_unit(:caterpie,:primary,:enemy,31)
    e=[{:group=>0,:type=>:stat_stage,:stat=>:def,:stages=>-1,:chance=>100,:receiver=>:target}]
    apply_canonical_secondary_group(user,dust,{:canonical_move_key=>:test},e,10);blocked=dust.stat_stage(:def)==0
    grace=ability_verification_unit(:jirachi,:primary,:ally,32);tar=ability_verification_unit(:rattata,:primary,:enemy,33);set_ability_secondary_rolls([50]);e2=[{:group=>0,:type=>:stat_stage,:stat=>:def,:stages=>-1,:chance=>30,:receiver=>:target}];apply_canonical_secondary_group(grace,tar,{:canonical_move_key=>:test},e2,10);doubled=tar.stat_stage(:def)==-1
    pass=blocked && doubled
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" shield_dust_block="+(blocked ? "1":"0")+" serene_grace_roll50_chance30x2="+(doubled ? "proc":"miss"))
    @verification_done[tag]=true
  end
  def verify_ability_contact(tag)
    return if @verification_done[tag]
    atk=ability_verification_unit(:rattata,:primary,:ally,40);pik=ability_verification_unit(:pikachu,:primary,:enemy,41);set_ability_verification_rolls([0]);sd=PMD_AC.skill_data(:mv_tackle);deal_direct_damage(atk,pik,50,{:skill_data=>sd,:random_percent=>100,:directional=>false,:can_crit=>false});proc=atk.status?(:paralysis)
    set_ability_verification_rolls([29,30]);a,r1=canonical_ability_roll(30);b,r2=canonical_ability_roll(30);pass=proc && a && !b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" static="+(proc ? "proc":"miss")+" boundary29="+(a ? "proc":"miss")+" boundary30="+(b ? "proc":"miss"))
    @verification_done[tag]=true
  end
  def verify_ability_intimidate(tag)
    return if @verification_done[tag]
    gy=ability_verification_unit(:gyarados,:primary,:ally,50);rat=ability_verification_unit(:rattata,:primary,:enemy,51);meta=ability_verification_unit(:metagross,:primary,:enemy,52);n=apply_canonical_intimidate(gy,[rat,meta]);pass=rat.stat_stage(:atk)==-1 && meta.stat_stage(:atk)==0 && n==1
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" rattata_atk="+rat.stat_stage(:atk).to_s+" metagross_clear_body="+meta.stat_stage(:atk).to_s+" lowered="+n.to_s)
    @verification_done[tag]=true
  end
  def verify_ability_recoil_crit_sound(tag)
    return if @verification_done[tag]
    rh=ability_verification_unit(:rhydon,:secondary,:ally,60);before=rh.hp;recoil=rh.apply_canonical_recoil(50);rock=(recoil==0 && rh.hp==before)
    atk=ability_verification_unit(:rattata,:primary,:ally,61);lap=ability_verification_unit(:lapras,:secondary,:enemy,62);deal_direct_damage(atk,lap,60,{:modifier=>{:force_crit=>true},:random_percent=>100,:directional=>false});armor=!lap.last_damage_critical
    mime=ability_verification_unit(:mr_mime,:primary,:enemy,63);hb=mime.hp;hv=PMD_AC.skill_data(:mv_hyper_voice);sound=deal_direct_damage(atk,mime,90,{:skill_data=>hv,:random_percent=>100,:directional=>false})==0 && mime.hp==hb
    pass=rock && armor && sound
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" rock_head="+(rock ? "block":"fail")+" shell_armor_crit="+(armor ? "blocked":"crit")+" soundproof="+(sound ? "immune":"hit"))
    @verification_done[tag]=true
  end
  def verify_ability_mega_tags(tag)
    return if @verification_done[tag]
    ci=PMD_PokemonInstance.new(:charizard,50,{:instance_uid=>99024901,:ability_slot=>:primary});ci.mega_evolve!(:mega_x);cu=Game_PMDChessUnit.new(8901,:charizard,:ally,0,0,ci);cu.scene=self
    bi=PMD_PokemonInstance.new(:blastoise,50,{:instance_uid=>99024902,:ability_slot=>:primary});bi.mega_evolve!(:mega);bu=Game_PMDChessUnit.new(8902,:blastoise,:ally,0,0,bi);bu.scene=self
    tc=cu.canonical_ability_move_power_multiplier(PMD_AC.skill_data(:mv_tackle));ml=bu.canonical_ability_move_power_multiplier(PMD_AC.skill_data(:mv_aura_sphere));pass=cu.ability_key==:tough_claws && bu.ability_key==:mega_launcher && (tc-1.30).abs<0.001 && (ml-1.50).abs<0.001
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" charizardX="+cu.ability_key.to_s+" contact_x="+sprintf("%.2f",tc)+" blastoiseMega="+bu.ability_key.to_s+" pulse_x="+sprintf("%.2f",ml))
    @verification_done[tag]=true
  end
  def verify_ability_runtime_file(tag)
    return if @verification_done[tag];p=FileTest.exist?(PMD_AC::ABILITY_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(p ? "1":"0")+" runtime_file="+(p ? "present":"missing")+" source="+(PMD_AC::AbilityDB.using_runtime_file? ? "rvdata":"embedded_first_boot"));@verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v024_update_verification_script;return unless verification_mode==:ability;f=@verification_frame
    verify_ability_manifest(:ability_manifest) if f==4
    verify_ability_gen5_slots(:ability_gen5_slots) if f==30
    verify_ability_damage(:ability_damage) if f==65
    verify_ability_defense_absorb(:ability_defense_absorb) if f==105
    verify_ability_status(:ability_status_immunity) if f==145
    verify_ability_secondary(:ability_secondary) if f==185
    verify_ability_contact(:ability_contact) if f==225
    verify_ability_intimidate(:ability_intimidate) if f==265
    verify_ability_recoil_crit_sound(:ability_defense_rules) if f==305
    verify_ability_mega_tags(:ability_mega_tags) if f==345
    verify_ability_runtime_file(:ability_runtime_file) if f==390
    complete_verification_mode if f==PMD_AC::VERIFICATION_ABILITY_END_FRAME
  end
  def log_event(category,message)
    if category.to_s=="verify";t=message.to_s;@ability_verification_failed=true if t.index("ABILITY_")==0 && t.include?(" pass=0");end
    pmd_ac_v024_log_event(category,message)
  end
  def complete_verification_mode
    if verification_mode==:ability && @ability_verification_failed
      return if @verification_done[:verification_complete]
      for u in @units;u.verification_finish;end
      @verification_done[:verification_complete]=true
      log_event(:verify,"FAILED mode=ABILITY auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v024_complete_verification_mode
  end
end
