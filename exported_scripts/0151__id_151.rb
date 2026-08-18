#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.28
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - WEATHER_RUNTIME_FILE / USE_EXTERNAL_WEATHER_DB / WEATHER_TURN_FRAMES / WEATHER_MOVE_TURNS
# - VERIFICATION_WEATHER_END_FRAME / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / embedded_data / load!
# - manifest / move / ability / move_keys
# - ability_keys / move_count / ability_count / canonical_move_key_from_skill
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.28
#    Generation V Weather Foundation
#==============================================================================
module PMD_AC
  WEATHER_RUNTIME_FILE="Data/PMD_AutoChess_Weather_v028_000.rvdata"
  USE_EXTERNAL_WEATHER_DB=true unless const_defined?(:USE_EXTERNAL_WEATHER_DB)
  WEATHER_TURN_FRAMES=60
  WEATHER_MOVE_TURNS=5
  VERIFICATION_WEATHER_END_FRAME=485

  module WeatherDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def embedded_data;{:manifest=>PMD_AC::WEATHER_MANIFEST_V028,:moves=>PMD_AC::WEATHER_MOVE_V028,:abilities=>PMD_AC::WEATHER_ABILITY_V028};end
      def load!
        return true if @loaded
        @using_runtime_file=false;@load_error=nil;d=nil
        if PMD_AC::USE_EXTERNAL_WEATHER_DB && FileTest.exist?(PMD_AC::WEATHER_RUNTIME_FILE)
          begin;c=load_data(PMD_AC::WEATHER_RUNTIME_FILE);if c.is_a?(Hash) && c[:manifest] && c[:moves].is_a?(Hash) && c[:abilities].is_a?(Hash) && c[:manifest][:content_version]=="0.28.0";d=c;@using_runtime_file=true;end;rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        d=embedded_data if d==nil;@data=d;@loaded=true
        if PMD_AC::USE_EXTERNAL_WEATHER_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::WEATHER_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def manifest;load! unless loaded?;@data[:manifest]||{};end
      def move(k);load! unless loaded?;(@data[:moves]||{})[k];end
      def ability(k);load! unless loaded?;(@data[:abilities]||{})[k];end
      def move_keys;load! unless loaded?;(@data[:moves]||{}).keys;end
      def ability_keys;load! unless loaded?;(@data[:abilities]||{}).keys;end
      def move_count;move_keys.size;end
      def ability_count;ability_keys.size;end
    end
  end
  WeatherDB.load!

  class << self
    alias pmd_ac_v028_move_executable move_executable? unless method_defined?(:pmd_ac_v028_move_executable)
    alias pmd_ac_v028_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v028_move_autochess_hint)
    alias pmd_ac_v028_skill_data skill_data unless method_defined?(:pmd_ac_v028_skill_data)
    alias pmd_ac_v028_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v028_canonical_move_key_from_skill)
    alias pmd_ac_v028_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v028_ability_behavior)
    alias pmd_ac_v028_ability_data ability_data unless method_defined?(:pmd_ac_v028_ability_data)
    def canonical_move_key_from_skill(skill_key)
      k=pmd_ac_v028_canonical_move_key_from_skill(skill_key);return k if k!=nil;return nil if skill_key==nil;t=skill_key.to_s;return nil unless t[0,3]=="mv_";x=t[3,t.size-3].to_sym;WeatherDB.move(x)==nil ? nil : x
    end
    def move_executable?(move_key);return true if WeatherDB.move(move_key)!=nil;pmd_ac_v028_move_executable(move_key);end
    def move_autochess_hint(move_key);b=WeatherDB.move(move_key);return pmd_ac_v028_move_autochess_hint(move_key) if b==nil;r=pmd_ac_v028_move_autochess_hint(move_key)||{};r=r.dup;r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px];r[:runtime_skill_key]=b[:runtime_skill_key];r;end
    def skill_data(key);old=pmd_ac_v028_skill_data(key);return old if old!=nil && !old.empty?;mk=canonical_move_key_from_skill(key);return {} if mk==nil;b=WeatherDB.move(mk);return {} if b==nil;r=b.dup;r[:move_type]=b[:type];r[:damage_category]=b[:category];r[:canonical_move_key]=mk;r;end
    def ability_behavior(key);b=WeatherDB.ability(key);return b unless b==nil || b.empty?;pmd_ac_v028_ability_behavior(key);end
    def ability_data(key);b=WeatherDB.ability(key);return b unless b==nil || b.empty?;pmd_ac_v028_ability_data(key);end
    def weather_scalar(v);return "" if v==nil;return v.collect{|x|weather_scalar(x)}.join(",") if v.is_a?(Array);v.to_s;end
    def weather_checksum32
      h=0;d=WeatherDB.instance_variable_get(:@data)
      for k in (d[:moves]||{}).keys.sort{|a,b|a.to_s<=>b.to_s}
        r=d[:moves][k];eff=(r[:effects]||[]).collect{|e|[:type,:weather,:turns,:power,:stat,:stages].collect{|f|weather_scalar(e[f])}.join(",")}.join(";");text=["M",k,r[:runtime_skill_key],r[:type],r[:category],r[:accuracy],r[:target],r[:delivery],r[:range_px],r[:dynamic_weather_ball],r[:sun_stages],eff].collect{|x|weather_scalar(x)}.join("|");text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      af=[:kind,:weather,:permanent,:num,:den,:spatk_num,:spatk_den,:damage_num,:damage_den,:accuracy_num,:accuracy_den,:types,:statuses,:water_heal_num,:water_heal_den,:fire_num,:fire_den,:rain_heal_num,:rain_heal_den,:sun_damage_num,:sun_damage_den]
      for k in (d[:abilities]||{}).keys.sort{|a,b|a.to_s<=>b.to_s};r=d[:abilities][k];text=(["A",k]+af.collect{|f|r[f]}).collect{|x|weather_scalar(x)}.join("|");text.each_byte{|by|h=((h*33)+by)&0x7fffffff};end
      h
    end
    def validate_weather_db
      e=[];m=WeatherDB.manifest;e.push("move_count") unless WeatherDB.move_count==6;e.push("ability_count") unless WeatherDB.ability_count==19;e.push("moves") unless m[:cumulative_mapped_move_count].to_i==222;e.push("refs") unless m[:cumulative_reference_covered].to_i==3754;e.push("slots") unless m[:implemented_slot_count].to_i==840;e.push("species") unless m[:species_with_any_implemented_ability].to_i==451;e.push("solar_beam") unless WeatherDB.move(:solar_beam)==nil;e.push("forecast") unless WeatherDB.ability(:forecast)==nil;e.push("checksum") unless weather_checksum32==m[:runtime_checksum32].to_i;e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,:progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary,:speed_status,:action_status,:ability,:ability_trigger,:ability_passive,:accuracy_evasion,:weather]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",:ability=>"ABILITY",:ability_trigger=>"ABILITY_TRIGGER",:ability_passive=>"ABILITY_PASSIVE",:accuracy_evasion=>"ACCURACY_EVASION",:weather=>"WEATHER"}
end

class Game_PMDChessUnit
  alias pmd_ac_v028_update update unless method_defined?(:pmd_ac_v028_update)
  alias pmd_ac_v028_ability_outgoing_multiplier ability_outgoing_multiplier unless method_defined?(:pmd_ac_v028_ability_outgoing_multiplier)
  alias pmd_ac_v028_ability_incoming_multiplier ability_incoming_multiplier unless method_defined?(:pmd_ac_v028_ability_incoming_multiplier)
  alias pmd_ac_v028_canonical_ability_move_power_multiplier canonical_ability_move_power_multiplier unless method_defined?(:pmd_ac_v028_canonical_ability_move_power_multiplier)
  alias pmd_ac_v028_special_attack special_attack unless method_defined?(:pmd_ac_v028_special_attack)
  alias pmd_ac_v028_special_defense special_defense unless method_defined?(:pmd_ac_v028_special_defense)
  alias pmd_ac_v028_realtime_speed_factor realtime_speed_factor unless method_defined?(:pmd_ac_v028_realtime_speed_factor)
  alias pmd_ac_v028_canonical_apply_sleep canonical_apply_sleep unless method_defined?(:pmd_ac_v028_canonical_apply_sleep)
  alias pmd_ac_v028_canonical_apply_freeze canonical_apply_freeze unless method_defined?(:pmd_ac_v028_canonical_apply_freeze)

  def canonical_weather_behavior;PMD_AC::WeatherDB.ability(ability_key)||{};end
  def canonical_weather_effective?(weather=nil);return false if @scene==nil || !@scene.respond_to?(:canonical_weather_effective?);@scene.canonical_weather_effective?(weather);end
  def update
    old=@canonical_weather_seen_ability;cur=ability_key
    if old!=cur
      @canonical_weather_seen_ability=cur
      @scene.canonical_weather_entry_ability(self) if @scene!=nil && @scene.respond_to?(:canonical_weather_entry_ability) && @battle_active
    end
    pmd_ac_v028_update
  end
  def ability_outgoing_multiplier(move_type,category,effectiveness=1.0)
    base=pmd_ac_v028_ability_outgoing_multiplier(move_type,category,effectiveness)
    if canonical_weather_effective?(:sun);base*=1.5 if move_type==:fire;base*=0.5 if move_type==:water;end
    if canonical_weather_effective?(:rain);base*=1.5 if move_type==:water;base*=0.5 if move_type==:fire;end
    b=canonical_weather_behavior
    if b[:kind]==:weather_move_power && canonical_weather_effective?(b[:weather]) && (b[:types]||[]).include?(move_type);base*=b[:num].to_f/[b[:den].to_i,1].max.to_f;end
    base
  end
  def ability_incoming_multiplier(move_type,category)
    base=pmd_ac_v028_ability_incoming_multiplier(move_type,category);return base if base<=0.0;b=canonical_weather_behavior
    if b[:kind]==:dry_skin
      if move_type==:water
        amount=[maxhp*b[:water_heal_num].to_i/[b[:water_heal_den].to_i,1].max,1].max;heal(amount);log_event(:weather,log_name+" dry_skin WATER_ABSORB heal="+amount.to_s);return 0.0
      elsif move_type==:fire;base*=b[:fire_num].to_f/[b[:fire_den].to_i,1].max.to_f;end
    end
    base
  end
  def canonical_ability_move_power_multiplier(data)
    pmd_ac_v028_canonical_ability_move_power_multiplier(data)
  end
  def special_attack
    v=pmd_ac_v028_special_attack;b=canonical_weather_behavior
    if b[:kind]==:weather_spatk_and_damage && canonical_weather_effective?(b[:weather]);v=[(v.to_f*b[:spatk_num].to_f/[b[:spatk_den].to_i,1].max.to_f).round,1].max;end
    v
  end
  def special_defense
    v=pmd_ac_v028_special_defense
    if canonical_weather_effective?(:sandstorm) && pokemon_types.include?(:rock);v=[(v.to_f*1.5).round,1].max;end
    v
  end
  def realtime_speed_factor
    base=pmd_ac_v028_realtime_speed_factor;b=canonical_weather_behavior
    if b[:kind]==:weather_speed && canonical_weather_effective?(b[:weather]);base*=Math.sqrt(b[:num].to_f/[b[:den].to_i,1].max.to_f);base=PMD_AC.clamp(base,0.5,1.75);end
    base
  end
  def canonical_leaf_guard_block?(status)
    b=canonical_weather_behavior;b[:kind]==:weather_status_immunity && canonical_weather_effective?(b[:weather]) && (b[:statuses]||[]).include?(status)
  end
  def canonical_apply_sleep(source=nil);if canonical_leaf_guard_block?(:sleep);log_event(:weather,log_name+" leaf_guard IMMUNE status=sleep");return false;end;pmd_ac_v028_canonical_apply_sleep(source);end
  def canonical_apply_freeze(source=nil);if canonical_leaf_guard_block?(:freeze);log_event(:weather,log_name+" leaf_guard IMMUNE status=freeze");return false;end;pmd_ac_v028_canonical_apply_freeze(source);end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v028_start start unless method_defined?(:pmd_ac_v028_start)
  alias pmd_ac_v028_start_battle start_battle unless method_defined?(:pmd_ac_v028_start_battle)
  alias pmd_ac_v028_update update unless method_defined?(:pmd_ac_v028_update)
  alias pmd_ac_v028_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v028_prepare_verification_battle)
  alias pmd_ac_v028_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v028_apply_skill_effects)
  alias pmd_ac_v028_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v028_canonical_accuracy_probability)
  alias pmd_ac_v028_canonical_apply_trigger_major_status canonical_apply_trigger_major_status unless method_defined?(:pmd_ac_v028_canonical_apply_trigger_major_status)
  alias pmd_ac_v028_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v028_skill_cast_worthwhile)
  alias pmd_ac_v028_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v028_update_verification_script)
  alias pmd_ac_v028_log_event log_event unless method_defined?(:pmd_ac_v028_log_event)
  alias pmd_ac_v028_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v028_complete_verification_mode)

  def start
    pmd_ac_v028_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);t=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read};t.sub!("PMD AutoChess Proto v0.27 Battle Verification Log","PMD AutoChess Proto v0.28 Battle Verification Log");File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(t)};end
    rescue;end
    m=PMD_AC::WeatherDB.manifest;log_event(:weather,"LOADED moves="+PMD_AC::WeatherDB.move_count.to_s+" cumulative_moves="+m[:cumulative_mapped_move_count].to_s+" covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+" abilities="+PMD_AC::WeatherDB.ability_count.to_s+" slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+" species="+m[:species_with_any_implemented_ability].to_s+"/494 source="+(PMD_AC::WeatherDB.using_runtime_file? ? "rvdata":"embedded")+" checksum32="+m[:runtime_checksum32].to_s)
  end
  def canonical_weather;@canonical_weather;end
  def canonical_weather_frames;@canonical_weather_frames.to_i;end
  def canonical_weather_permanent?;@canonical_weather_permanent ? true : false;end
  def canonical_weather_units
    a=[];a+=@units if @units!=nil;a+=@weather_test_units if @weather_test_units!=nil;a.compact.uniq
  end
  def canonical_weather_suppressed?
    canonical_weather_units.any?{|u|u.alive? && [:cloud_nine,:air_lock].include?(u.ability_key)}
  end
  def canonical_weather_effective?(weather=nil)
    return false if @canonical_weather==nil || canonical_weather_suppressed?;weather==nil || @canonical_weather==weather
  end
  def set_canonical_weather(weather,source=nil,turns=nil,permanent=false)
    @canonical_weather=weather;@canonical_weather_permanent=permanent ? true : false;@canonical_weather_frames=@canonical_weather_permanent ? -1 : [turns.to_i,1].max*PMD_AC::WEATHER_TURN_FRAMES;@canonical_weather_tick_wait=PMD_AC::WEATHER_TURN_FRAMES
    log_event(:weather,"SET weather="+weather.to_s+" source="+(source==nil ? "SYSTEM" : source.log_name)+" permanent="+(@canonical_weather_permanent ? "1":"0")+" frames="+@canonical_weather_frames.to_s);true
  end
  def clear_canonical_weather(reason=:expire);old=@canonical_weather;@canonical_weather=nil;@canonical_weather_frames=0;@canonical_weather_permanent=false;@canonical_weather_tick_wait=PMD_AC::WEATHER_TURN_FRAMES;log_event(:weather,"CLEAR weather="+old.to_s+" reason="+reason.to_s) if old!=nil;true;end
  def canonical_weather_entry_ability(unit)
    return false if unit==nil || unit.dead?;b=PMD_AC::WeatherDB.ability(unit.ability_key);return false if b==nil || b[:kind]!=:entry_weather;set_canonical_weather(b[:weather],unit,nil,true);true
  end
  def apply_canonical_weather_entry_abilities
    list=canonical_weather_units.find_all{|u|u.alive? && (b=PMD_AC::WeatherDB.ability(u.ability_key))!=nil && b[:kind]==:entry_weather}
    list.sort!{|a,b|x=b.speed_stat<=>a.speed_stat;x==0 ? (a.object_id<=>b.object_id) : x}
    for u in list;canonical_weather_entry_ability(u);end
  end
  def start_battle
    pmd_ac_v028_start_battle
    if @phase==:battle;@canonical_weather=nil;@canonical_weather_frames=0;@canonical_weather_permanent=false;@canonical_weather_tick_wait=PMD_AC::WEATHER_TURN_FRAMES;apply_canonical_weather_entry_abilities;end
  end
  def canonical_weather_indirect_damage(unit,amount,label)
    return 0 if unit==nil || unit.dead? || amount.to_i<=0;return 0 if unit.ability_key==:magic_guard || unit.ability_key==:overcoat
    before=unit.hp;unit.receive_damage(amount,nil,false,true,false);d=before-unit.hp;log_event(:weather,unit.log_name+" "+label.to_s+" damage="+d.to_s) if d>0;d
  end
  def canonical_weather_turn_tick
    return false unless canonical_weather_effective?;w=@canonical_weather
    for u in canonical_weather_units
      next if u.dead?;types=u.pokemon_types
      if w==:sandstorm && !(types.include?(:rock)||types.include?(:ground)||types.include?(:steel));canonical_weather_indirect_damage(u,[u.maxhp/16,1].max,:sandstorm);end
      if w==:hail && !types.include?(:ice);canonical_weather_indirect_damage(u,[u.maxhp/16,1].max,:hail);end
    end
    for u in canonical_weather_units
      next if u.dead?;b=PMD_AC::WeatherDB.ability(u.ability_key);next if b==nil
      if b[:kind]==:weather_turn_heal && w==b[:weather];a=[u.maxhp*b[:num].to_i/[b[:den].to_i,1].max,1].max;before=u.hp;u.heal(a);log_event(:weather,u.log_name+" "+u.ability_key.to_s+" TURN_HEAL actual="+(u.hp-before).to_s)
      elsif b[:kind]==:weather_spatk_and_damage && w==b[:weather];canonical_weather_indirect_damage(u,[u.maxhp*b[:damage_num].to_i/[b[:damage_den].to_i,1].max,1].max,:solar_power)
      elsif b[:kind]==:weather_status_cure && w==b[:weather]
        key=[:burn,:poison,:paralysis,:sleep,:freeze].find{|k|u.status?(k)}
        if key!=nil;if [:sleep,:freeze].include?(key);u.canonical_clear_action_status(key,:hydration);else;u.remove_status(key);end;log_event(:weather,u.log_name+" hydration CURE status="+key.to_s);end
      elsif b[:kind]==:dry_skin
        if w==:rain;a=[u.maxhp*b[:rain_heal_num].to_i/[b[:rain_heal_den].to_i,1].max,1].max;before=u.hp;u.heal(a);log_event(:weather,u.log_name+" dry_skin RAIN_HEAL actual="+(u.hp-before).to_s)
        elsif w==:sun;canonical_weather_indirect_damage(u,[u.maxhp*b[:sun_damage_num].to_i/[b[:sun_damage_den].to_i,1].max,1].max,:dry_skin_sun);end
      end
    end
    true
  end
  def canonical_update_weather
    return if @phase!=:battle || @canonical_weather==nil
    unless @canonical_weather_permanent;@canonical_weather_frames-=1;if @canonical_weather_frames<=0;clear_canonical_weather(:duration);return;end;end
    @canonical_weather_tick_wait=PMD_AC::WEATHER_TURN_FRAMES if @canonical_weather_tick_wait==nil;@canonical_weather_tick_wait-=1;if @canonical_weather_tick_wait<=0;@canonical_weather_tick_wait=PMD_AC::WEATHER_TURN_FRAMES;canonical_weather_turn_tick;end
  end
  def update;pmd_ac_v028_update;canonical_update_weather;end

  def canonical_weather_adjust_skill_data(data)
    return data if data==nil || data.empty?;mk=data[:canonical_move_key];r=data.dup
    if mk==:weather_ball
      e=(data[:effects]||[]).collect{|x|x.dup};r[:effects]=e;w=canonical_weather_effective? ? @canonical_weather : nil;map={:sun=>:fire,:rain=>:water,:sandstorm=>:rock,:hail=>:ice};r[:move_type]=map[w]||:normal;r[:type]=r[:move_type];for x in e;if x[:type]==:damage;x[:power]=(w==nil ? 50 : 100);end;end;r[:canonical_power]=(w==nil ? 50 : 100)
    elsif mk==:growth && canonical_weather_effective?(:sun)
      r[:effects]=(data[:effects]||[]).collect{|x|y=x.dup;y[:stages]=2 if y[:type]==:stat_stage && [:atk,:spatk].include?(y[:stat]);y}
    elsif [:morning_sun,:synthesis,:moonlight].include?(mk)
      ratio=0.5;if canonical_weather_effective?(:sun);ratio=2.0/3.0;elsif canonical_weather_effective?;ratio=0.25;end;r[:effects]=(data[:effects]||[]).collect{|x|y=x.dup;y[:ratio]=ratio if y[:type]==:heal_maxhp_ratio;y}
    end
    r
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    d=canonical_weather_adjust_skill_data(data);result=pmd_ac_v028_apply_skill_effects(user,target,d,scale)
    for e in (d[:effects]||[]);if e[:type]==:set_weather;set_canonical_weather(e[:weather],user,e[:turns].to_i,false);end;end
    result
  end
  def canonical_accuracy_probability(user,target,data)
    chance=pmd_ac_v028_canonical_accuracy_probability(user,target,data);return chance if data==nil || user==nil || target==nil
    ub=user.respond_to?(:canonical_accuracy_behavior) ? user.canonical_accuracy_behavior : {};tb=target.respond_to?(:canonical_accuracy_behavior) ? target.canonical_accuracy_behavior : {};return 100.0 if ub[:kind]==:no_guard || tb[:kind]==:no_guard
    mk=data[:canonical_move_key]
    if canonical_weather_effective?(:rain) && [:thunder,:hurricane].include?(mk);return 100.0;end
    if canonical_weather_effective?(:sun) && [:thunder,:hurricane].include?(mk);chance=50.0;end
    if canonical_weather_effective?(:hail) && mk==:blizzard;return 100.0;end
    b=PMD_AC::WeatherDB.ability(target.ability_key)
    if b!=nil && b[:kind]==:weather_evasion && canonical_weather_effective?(b[:weather]);chance*=b[:accuracy_num].to_f/[b[:accuracy_den].to_i,1].max.to_f;end
    PMD_AC.clamp(chance,0.0,100.0)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v028_skill_cast_worthwhile(unit,target,data)
    if data!=nil
      e=(data[:effects]||[]).find{|x|x[:type]==:set_weather}
      if e!=nil && @canonical_weather==e[:weather] && !canonical_weather_suppressed?
        return false if canonical_weather_permanent? || @canonical_weather_frames>PMD_AC::WEATHER_TURN_FRAMES
      end
    end
    true
  end
  def canonical_apply_trigger_major_status(target,status,source)
    if target!=nil && target.respond_to?(:canonical_leaf_guard_block?) && target.canonical_leaf_guard_block?(status);log_event(:weather,target.log_name+" leaf_guard IMMUNE status="+status.to_s);return false;end
    pmd_ac_v028_canonical_apply_trigger_major_status(target,status,source)
  end

  def prepare_verification_battle
    pmd_ac_v028_prepare_verification_battle
    if verification_mode==:weather
      for u in @units;u.verification_combat_sandbox(true);end
      @weather_failed=false;@weather_test_units=[];@canonical_weather=nil;@canonical_weather_frames=0;@canonical_weather_permanent=false;@canonical_weather_tick_wait=PMD_AC::WEATHER_TURN_FRAMES
    end
  end
  def weather_verification_unit(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99028000+id.to_i,:ability_slot=>slot});u=Game_PMDChessUnit.new(9280+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);@weather_test_units.push(u);u
  end
  def verify_weather_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::WeatherDB.manifest;e=PMD_AC.validate_weather_db;pass=e.empty?;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" moves=6 cumulative=222 covered=3754/7005 coverage="+m[:cumulative_coverage_percent].to_s+"% abilities=19 slots=840/1193 species=451/494 checksum="+PMD_AC.weather_checksum32.to_s+" errors=["+e.join(",")+"]");@verification_done[tag]=true
  end
  def verify_weather_setters(tag)
    return if @verification_done[tag];u=weather_verification_unit(:bulbasaur,:primary,:ally,1);d=PMD_AC.skill_data(:mv_sunny_day);apply_skill_effects(u,u,d,1.0);a=@canonical_weather==:sun && @canonical_weather_frames==300 && !canonical_weather_permanent?;n=weather_verification_unit(:ninetales,:hidden,:ally,2);canonical_weather_entry_ability(n);b=@canonical_weather==:sun && canonical_weather_permanent?;pass=a&&b;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" move_sun_frames="+(a ? "300":"bad")+" drought_permanent="+(b ? "1":"0"));@verification_done[tag]=true
  end
  def verify_weather_damage(tag)
    return if @verification_done[tag];atk=weather_verification_unit(:charizard,:primary,:ally,10);t=weather_verification_unit(:rattata,:primary,:enemy,11);clear_canonical_weather(:verify);fire0=atk.calculate_damage(t,60,:special,:fire,100);water0=atk.calculate_damage(t,60,:special,:water,100);set_canonical_weather(:sun,nil,5,false);fire1=atk.calculate_damage(t,60,:special,:fire,100);water1=atk.calculate_damage(t,60,:special,:water,100);set_canonical_weather(:rain,nil,5,false);fire2=atk.calculate_damage(t,60,:special,:fire,100);water2=atk.calculate_damage(t,60,:special,:water,100);rock=weather_verification_unit(:tyranitar,:hidden,:enemy,12);clear_canonical_weather(:verify);s0=rock.special_defense;set_canonical_weather(:sandstorm,nil,5,false);s1=rock.special_defense;pass=fire1>fire0 && water1<water0 && fire2<fire0 && water2>water0 && s1>s0;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" sun_fire="+fire0.to_s+"->"+fire1.to_s+" sun_water="+water0.to_s+"->"+water1.to_s+" rain_fire="+fire0.to_s+"->"+fire2.to_s+" rain_water="+water0.to_s+"->"+water2.to_s+" rock_spdef="+s0.to_s+"->"+s1.to_s);@verification_done[tag]=true
  end
  def verify_weather_accuracy(tag)
    return if @verification_done[tag];u=weather_verification_unit(:pikachu,:primary,:ally,20);t=weather_verification_unit(:rattata,:primary,:enemy,21);th=PMD_AC.skill_data(:mv_thunder);bl=PMD_AC.skill_data(:mv_blizzard);set_canonical_weather(:rain,nil,5,false);r=canonical_accuracy_probability(u,t,th);set_canonical_weather(:sun,nil,5,false);s=canonical_accuracy_probability(u,t,th);set_canonical_weather(:hail,nil,5,false);h=canonical_accuracy_probability(u,t,bl);pass=(r-100.0).abs<0.01 && (s-50.0).abs<0.01 && (h-100.0).abs<0.01;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" thunder_rain="+sprintf("%.1f",r)+" thunder_sun="+sprintf("%.1f",s)+" blizzard_hail="+sprintf("%.1f",h));@verification_done[tag]=true
  end
  def verify_weather_moves(tag)
    return if @verification_done[tag];set_canonical_weather(:sun,nil,5,false);wb=canonical_weather_adjust_skill_data(PMD_AC.skill_data(:mv_weather_ball));gr=canonical_weather_adjust_skill_data(PMD_AC.skill_data(:mv_growth));sy=canonical_weather_adjust_skill_data(PMD_AC.skill_data(:mv_synthesis));set_canonical_weather(:rain,nil,5,false);wb2=canonical_weather_adjust_skill_data(PMD_AC.skill_data(:mv_weather_ball));sy2=canonical_weather_adjust_skill_data(PMD_AC.skill_data(:mv_synthesis));g=gr[:effects].find{|e|e[:stat]==:atk};heal1=sy[:effects].find{|e|e[:type]==:heal_maxhp_ratio};heal2=sy2[:effects].find{|e|e[:type]==:heal_maxhp_ratio};pass=wb[:move_type]==:fire && wb[:canonical_power]==100 && wb2[:move_type]==:water && wb2[:canonical_power]==100 && g[:stages]==2 && (heal1[:ratio]-2.0/3.0).abs<0.001 && (heal2[:ratio]-0.25).abs<0.001;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" weather_ball=sun:"+wb[:move_type].to_s+"/"+wb[:canonical_power].to_s+" rain:"+wb2[:move_type].to_s+"/"+wb2[:canonical_power].to_s+" growth_sun="+g[:stages].to_s+" synthesis="+sprintf("%.3f",heal1[:ratio])+"/"+sprintf("%.2f",heal2[:ratio]));@verification_done[tag]=true
  end
  def verify_weather_abilities(tag)
    return if @verification_done[tag];sw=weather_verification_unit(:kingdra,:primary,:ally,30);set_canonical_weather(:rain,nil,5,false);a=sw.realtime_speed_factor;clear_canonical_weather(:verify);b=sw.realtime_speed_factor;sv=weather_verification_unit(:garchomp,:primary,:enemy,31);user=weather_verification_unit(:rattata,:primary,:ally,32);tk=PMD_AC.skill_data(:mv_tackle);set_canonical_weather(:sandstorm,nil,5,false);acc=canonical_accuracy_probability(user,sv,tk);sf=weather_verification_unit(:hippowdon,:hidden,:ally,33);m=sf.canonical_ability_move_power_multiplier({:move_type=>:rock,:type=>:rock});# scene weather multiplier is on outgoing, not move power
    om=sf.ability_outgoing_multiplier(:rock,:physical,1.0);pass=a>b && (acc-80.0).abs<0.01 && om>1.29;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" swift_swim="+sprintf("%.3f",b)+"->"+sprintf("%.3f",a)+" sand_veil_accuracy="+sprintf("%.1f",acc)+" sand_force="+sprintf("%.2f",om));@verification_done[tag]=true
  end
  def verify_weather_turn_tick(tag)
    return if @verification_done[tag];sand=weather_verification_unit(:rattata,:primary,:ally,40);rock=weather_verification_unit(:tyranitar,:hidden,:ally,41);rain=weather_verification_unit(:ludicolo,:secondary,:ally,42);hyd=weather_verification_unit(:vaporeon,:hidden,:ally,43);solar=weather_verification_unit(:tropius,:secondary,:ally,44);rain.verification_set_hp_percent(0.5);hyd.apply_status(:burn,{:duration=>180,:value=>10,:interval=>30,:stack_mode=>:refresh},sand);set_canonical_weather(:sandstorm,nil,5,false);h0=sand.hp;r0=rock.hp;canonical_weather_turn_tick;sand_hit=sand.hp<h0;rock_safe=rock.hp==r0;set_canonical_weather(:rain,nil,5,false);rh0=rain.hp;canonical_weather_turn_tick;rain_heal=rain.hp>rh0;hyd_cure=!hyd.status?(:burn);set_canonical_weather(:sun,nil,5,false);sh0=solar.hp;sp0=pmd_ac_v028_special_attack_for_verify(solar);canonical_weather_turn_tick;solar_hurt=solar.hp<sh0;sp1=solar.special_attack;pass=sand_hit&&rock_safe&&rain_heal&&hyd_cure&&solar_hurt&&sp1>sp0;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" sand_damage="+(sand_hit ? "1":"0")+" rock_immune="+(rock_safe ? "1":"0")+" rain_dish="+(rain_heal ? "heal":"no")+" hydration="+(hyd_cure ? "cure":"no")+" solar_power="+sp0.to_s+"->"+sp1.to_s+" hp_loss="+(sh0-solar.hp).to_s);@verification_done[tag]=true
  end
  def pmd_ac_v028_special_attack_for_verify(u);u.send(:pmd_ac_v028_special_attack);end
  def verify_weather_suppression(tag)
    return if @verification_done[tag];atk=weather_verification_unit(:charizard,:primary,:ally,50);t=weather_verification_unit(:rattata,:primary,:enemy,51);set_canonical_weather(:sun,nil,5,false);normal=atk.calculate_damage(t,60,:special,:fire,100);cn=weather_verification_unit(:golduck,:secondary,:ally,52);supp=atk.calculate_damage(t,60,:special,:fire,100);active=@canonical_weather==:sun;suppressed=canonical_weather_suppressed?;pass=supp<normal && active && suppressed;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" weather_state="+@canonical_weather.to_s+" suppressed="+(suppressed ? "1":"0")+" fire="+normal.to_s+"->"+supp.to_s+" cloud_nine="+cn.ability_key.to_s);@weather_test_units.delete(cn);@verification_done[tag]=true
  end
  def verify_weather_dry_skin_leaf_guard(tag)
    return if @verification_done[tag];src=weather_verification_unit(:rattata,:primary,:enemy,60);dry=weather_verification_unit(:parasect,:secondary,:ally,61);leaf=weather_verification_unit(:leafeon,:primary,:ally,62);dry.verification_set_hp_percent(0.5);before=dry.hp;dmg=deal_direct_damage(src,dry,60,{:move_type=>:water,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false});absorbed=dmg.to_i==0 && dry.hp>before;set_canonical_weather(:sun,nil,5,false);blocked=!canonical_apply_trigger_major_status(leaf,:burn,src);pass=absorbed&&blocked;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" dry_skin_absorb="+(absorbed ? "1":"0")+" leaf_guard="+(blocked ? "block":"fail"));@verification_done[tag]=true
  end
  def verify_weather_runtime_file(tag);return if @verification_done[tag];pass=FileTest.exist?(PMD_AC::WEATHER_RUNTIME_FILE);log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" runtime_file="+(pass ? "present":"missing")+" source="+(PMD_AC::WeatherDB.using_runtime_file? ? "rvdata":"embedded_first_boot"));@verification_done[tag]=true;end

  def log_event(category,message);if category.to_s=="verify" && verification_mode==:weather && message.to_s.index("WEATHER_")==0 && message.to_s.include?(" pass=0");@weather_failed=true;end;pmd_ac_v028_log_event(category,message);end
  def update_verification_script
    pmd_ac_v028_update_verification_script;return unless verification_mode==:weather;f=@verification_frame
    verify_weather_manifest(:weather_manifest) if f==4
    verify_weather_setters(:weather_setters) if f==45
    verify_weather_damage(:weather_damage) if f==95
    verify_weather_accuracy(:weather_accuracy) if f==145
    verify_weather_moves(:weather_moves) if f==195
    verify_weather_abilities(:weather_abilities) if f==250
    verify_weather_turn_tick(:weather_turn_tick) if f==315
    verify_weather_suppression(:weather_suppression) if f==375
    verify_weather_dry_skin_leaf_guard(:weather_status_rules) if f==420
    verify_weather_runtime_file(:weather_runtime_file) if f==455
    complete_verification_mode if f==PMD_AC::VERIFICATION_WEATHER_END_FRAME
  end
  def complete_verification_mode
    if verification_mode==:weather && @weather_failed;for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,"FAILED mode=WEATHER auto_skill=on original_skills=restored");return;end
    pmd_ac_v028_complete_verification_mode
  end
end
