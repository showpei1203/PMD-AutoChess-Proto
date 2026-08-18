#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.27
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - ACCURACY_EVASION_RUNTIME_FILE / USE_EXTERNAL_ACCURACY_EVASION_DB / VERIFICATION_ACCURACY_EVASION_END_FRAME / STAT_STAGE_KEYS
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【PMD_AC 對外／共用方法】
# - accuracy_stage_multiplier
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / loaded? / using_runtime_file? / load_error
# - embedded_data / load! / manifest / move
# - ability / move_keys / ability_keys / move_count
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.27
#    Generation V Accuracy / Evasion Foundation
#------------------------------------------------------------------------------
# Base: verified v0.26.1 FullTestProject. Existing scripts remain byte-identical.
#==============================================================================
module PMD_AC
  ACCURACY_EVASION_RUNTIME_FILE="Data/PMD_AutoChess_AccuracyEvasion_v027_000.rvdata"
  USE_EXTERNAL_ACCURACY_EVASION_DB=true unless const_defined?(:USE_EXTERNAL_ACCURACY_EVASION_DB)
  VERIFICATION_ACCURACY_EVASION_END_FRAME=455

  def self.accuracy_stage_multiplier(stage)
    n=clamp(stage.to_i,-6,6)
    return (3.0+n.to_f)/3.0 if n>=0
    3.0/(3.0-n.to_f)
  end

  remove_const(:STAT_STAGE_KEYS) if const_defined?(:STAT_STAGE_KEYS)
  STAT_STAGE_KEYS=[:atk,:def,:spatk,:spdef,:speed,:accuracy,:evasion]

  module AccuracyEvasionDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def embedded_data;{:manifest=>PMD_AC::ACCURACY_EVASION_MANIFEST_V027,:moves=>PMD_AC::ACCURACY_EVASION_MOVE_V027,:abilities=>PMD_AC::ACCURACY_EVASION_ABILITY_V027};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_ACCURACY_EVASION_DB && FileTest.exist?(PMD_AC::ACCURACY_EVASION_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::ACCURACY_EVASION_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:moves].is_a?(Hash) && c[:abilities].is_a?(Hash) && c[:manifest][:content_version]=="0.27.0"
              data=c;@using_runtime_file=true
            end
          rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        data=embedded_data if data==nil;@data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_ACCURACY_EVASION_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::ACCURACY_EVASION_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def manifest;load! unless loaded?;@data[:manifest]||{};end
      def move(key);load! unless loaded?;(@data[:moves]||{})[key];end
      def ability(key);load! unless loaded?;(@data[:abilities]||{})[key];end
      def move_keys;load! unless loaded?;(@data[:moves]||{}).keys;end
      def ability_keys;load! unless loaded?;(@data[:abilities]||{}).keys;end
      def move_count;move_keys.size;end
      def ability_count;ability_keys.size;end
    end
  end
  AccuracyEvasionDB.load!

  class << self
    alias pmd_ac_v027_move_executable move_executable? unless method_defined?(:pmd_ac_v027_move_executable)
    alias pmd_ac_v027_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v027_move_autochess_hint)
    alias pmd_ac_v027_skill_data skill_data unless method_defined?(:pmd_ac_v027_skill_data)
    alias pmd_ac_v027_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v027_canonical_move_key_from_skill)
    alias pmd_ac_v027_ability_behavior ability_behavior unless method_defined?(:pmd_ac_v027_ability_behavior)
    alias pmd_ac_v027_ability_data ability_data unless method_defined?(:pmd_ac_v027_ability_data)

    def canonical_move_key_from_skill(skill_key)
      k=pmd_ac_v027_canonical_move_key_from_skill(skill_key);return k if k!=nil
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=="mv_"
      key=text[3,text.size-3].to_sym;AccuracyEvasionDB.move(key)==nil ? nil : key
    end
    def move_executable?(move_key);return true if AccuracyEvasionDB.move(move_key)!=nil;pmd_ac_v027_move_executable(move_key);end
    def move_autochess_hint(move_key)
      base=pmd_ac_v027_move_autochess_hint(move_key);b=AccuracyEvasionDB.move(move_key);return base if b==nil
      r=base==nil ? {} : base.dup;r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px];r[:runtime_skill_key]=b[:runtime_skill_key];r
    end
    def skill_data(key)
      old=pmd_ac_v027_skill_data(key);return old if old!=nil && !old.empty?
      mk=canonical_move_key_from_skill(key);return {} if mk==nil;b=AccuracyEvasionDB.move(mk);return {} if b==nil
      r=b.dup;r[:move_type]=b[:type];r[:damage_category]=b[:category];r[:canonical_move_key]=mk;r
    end
    def ability_behavior(key)
      b=AccuracyEvasionDB.ability(key);return b unless b==nil || b.empty?
      pmd_ac_v027_ability_behavior(key)
    end
    def ability_data(key)
      b=AccuracyEvasionDB.ability(key);return b unless b==nil || b.empty?
      pmd_ac_v027_ability_data(key)
    end

    def accuracy_evasion_scalar(v)
      return "" if v==nil
      return v.collect{|x|accuracy_evasion_scalar(x)}.join(",") if v.is_a?(Array)
      v.to_s
    end
    def accuracy_evasion_checksum32
      h=0
      data=AccuracyEvasionDB.instance_variable_get(:@data)
      for k in (data[:moves]||{}).keys.sort{|a,b|a.to_s<=>b.to_s}
        r=data[:moves][k]
        eff=(r[:effects]||[]).collect{|e|[:type,:power,:stat,:stages].collect{|f|accuracy_evasion_scalar(e[f])}.join(",")}.join(";")
        sec=(r[:secondary_effects]||[]).collect{|e|[:type,:stat,:stages,:chance,:receiver].collect{|f|accuracy_evasion_scalar(e[f])}.join(",")}.join(";")
        text=["M",k,r[:runtime_skill_key],r[:type],r[:category],r[:accuracy],r[:target],r[:delivery],r[:range_px],eff,sec].collect{|x|accuracy_evasion_scalar(x)}.join("|")
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      af=[:kind,:num,:den,:stats,:atk_num,:atk_den,:accuracy_num,:accuracy_den,:physical_only,:up_stages,:down_stages]
      for k in (data[:abilities]||{}).keys.sort{|a,b|a.to_s<=>b.to_s}
        r=data[:abilities][k];text=(["A",k]+af.collect{|f|r[f]}).collect{|x|accuracy_evasion_scalar(x)}.join("|")
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_accuracy_evasion_db
      e=[];m=AccuracyEvasionDB.manifest
      e.push("move_count") unless AccuracyEvasionDB.move_count==15
      e.push("ability_count") unless AccuracyEvasionDB.ability_count==7
      e.push("cumulative_moves") unless m[:cumulative_mapped_move_count].to_i==216
      e.push("coverage") unless m[:cumulative_reference_covered].to_i==3648
      e.push("ability_slots") unless m[:implemented_slot_count].to_i==673
      e.push("ability_species") unless m[:species_with_any_implemented_ability].to_i==406
      ss=AccuracyEvasionDB.move(:sweet_scent);se=ss==nil ? nil : (ss[:effects]||[]).find{|x|x[:stat]==:evasion}
      e.push("sweet_scent") unless se!=nil && se[:stages].to_i==-1
      e.push("minimize") unless AccuracyEvasionDB.move(:minimize)==nil
      e.push("defog") unless AccuracyEvasionDB.move(:defog)==nil
      e.push("stage_keys") unless STAT_STAGE_KEYS.include?(:accuracy) && STAT_STAGE_KEYS.include?(:evasion)
      e.push("checksum") unless accuracy_evasion_checksum32==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,:progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary,:speed_status,:action_status,:ability,:ability_trigger,:ability_passive,:accuracy_evasion]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",:ability=>"ABILITY",:ability_trigger=>"ABILITY_TRIGGER",:ability_passive=>"ABILITY_PASSIVE",:accuracy_evasion=>"ACCURACY_EVASION"}
end

class Game_PMDChessUnit
  alias pmd_ac_v027_atk atk unless method_defined?(:pmd_ac_v027_atk)
  alias pmd_ac_v027_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v027_change_stat_stage)
  alias pmd_ac_v027_canonical_update_trigger_cycle canonical_update_trigger_cycle unless method_defined?(:pmd_ac_v027_canonical_update_trigger_cycle)
  alias pmd_ac_v027_canonical_trigger_turn_end canonical_trigger_turn_end unless method_defined?(:pmd_ac_v027_canonical_trigger_turn_end)

  def canonical_accuracy_behavior;PMD_AC::AccuracyEvasionDB.ability(ability_key)||{};end
  def atk
    v=pmd_ac_v027_atk;b=canonical_accuracy_behavior
    if b[:kind]==:hustle
      v=[v.to_i*b[:atk_num].to_i/[b[:atk_den].to_i,1].max,1].max
    end
    v
  end
  def change_stat_stage(stat,delta,source=nil)
    if delta.to_i<0 && stat==:accuracy && ability_key==:keen_eye && source!=nil && source.respond_to?(:team) && source.team!=team
      log_event(:accuracy_evasion,log_name+" keen_eye BLOCK_STAT_DROP stat=accuracy src="+source.log_name)
      return 0
    end
    pmd_ac_v027_change_stat_stage(stat,delta,source)
  end
  def canonical_update_trigger_cycle
    if ability_key==:moody
      return unless @battle_active && !dead? && !@verification_combat_sandbox
      @canonical_trigger_cycle_wait=canonical_trigger_cycle_length if @canonical_trigger_cycle_wait==nil
      @canonical_trigger_cycle_wait-=1;return if @canonical_trigger_cycle_wait>0
      @canonical_trigger_cycle_wait=canonical_trigger_cycle_length;canonical_trigger_turn_end;return
    end
    pmd_ac_v027_canonical_update_trigger_cycle
  end
  def canonical_trigger_turn_end
    if ability_key==:moody
      b=canonical_accuracy_behavior;stats=b[:stats]||PMD_AC::STAT_STAGE_KEYS
      up=stats.find_all{|s|stat_stage(s)<PMD_AC::STAT_STAGE_MAX}
      down=stats.find_all{|s|stat_stage(s)>PMD_AC::STAT_STAGE_MIN}
      raised=nil;lowered=nil
      if !up.empty?
        roll=@scene!=nil && @scene.respond_to?(:canonical_accuracy_ability_roll) ? @scene.canonical_accuracy_ability_roll(up.size) : rand(up.size)
        raised=up[roll%up.size];change_stat_stage(raised,b[:up_stages].to_i,self)
      end
      down=down.find_all{|s|s!=raised}
      if !down.empty?
        roll=@scene!=nil && @scene.respond_to?(:canonical_accuracy_ability_roll) ? @scene.canonical_accuracy_ability_roll(down.size) : rand(down.size)
        lowered=down[roll%down.size];change_stat_stage(lowered,b[:down_stages].to_i,self)
      end
      log_event(:accuracy_evasion,log_name+" moody TURN_END up="+(raised==nil ? "none" : raised.to_s)+" down="+(lowered==nil ? "none" : lowered.to_s))
      return raised!=nil || lowered!=nil
    end
    pmd_ac_v027_canonical_trigger_turn_end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v027_start start unless method_defined?(:pmd_ac_v027_start)
  alias pmd_ac_v027_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v027_prepare_verification_battle)
  alias pmd_ac_v027_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v027_apply_skill_effects)
  alias pmd_ac_v027_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v027_projectile_tracking_for)
  alias pmd_ac_v027_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v027_launch_projectile)
  alias pmd_ac_v027_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v027_update_verification_script)
  alias pmd_ac_v027_log_event log_event unless method_defined?(:pmd_ac_v027_log_event)
  alias pmd_ac_v027_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v027_complete_verification_mode)

  def start
    pmd_ac_v027_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read};text.sub!("PMD AutoChess Proto v0.26.1 Battle Verification Log","PMD AutoChess Proto v0.27 Battle Verification Log");File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::AccuracyEvasionDB.manifest
    log_event(:accuracy_evasion,"LOADED moves="+PMD_AC::AccuracyEvasionDB.move_count.to_s+" cumulative_moves="+m[:cumulative_mapped_move_count].to_s+" covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+" abilities="+PMD_AC::AccuracyEvasionDB.ability_count.to_s+" slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+" species="+m[:species_with_any_implemented_ability].to_s+"/494 source="+(PMD_AC::AccuracyEvasionDB.using_runtime_file? ? "rvdata":"embedded")+" checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v027_prepare_verification_battle
    if verification_mode==:accuracy_evasion
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages;end
      @accuracy_evasion_failed=false;@accuracy_evasion_rolls=[];@accuracy_ability_rolls=[];@accuracy_test_units=[];@v027_force_tracking_skill=nil;@accuracy_snapshots={}
    end
  end

  def set_accuracy_verification_rolls(v);@accuracy_evasion_rolls=v.dup;end
  def canonical_accuracy_roll_value
    if verification_mode==:accuracy_evasion && @accuracy_evasion_rolls!=nil && !@accuracy_evasion_rolls.empty?;return @accuracy_evasion_rolls.shift.to_f;end
    return 0.0 if verification_mode!=:normal
    rand*100.0
  end
  def set_accuracy_ability_rolls(v);@accuracy_ability_rolls=v.dup;end
  def canonical_accuracy_ability_roll(max)
    m=[max.to_i,1].max
    if verification_mode==:accuracy_evasion && @accuracy_ability_rolls!=nil && !@accuracy_ability_rolls.empty?;return @accuracy_ability_rolls.shift.to_i%m;end
    rand(m)
  end
  def canonical_team_accuracy_multiplier(user)
    return 1.0 if user==nil
    list=[];list+=@units if @units!=nil;list+=@accuracy_test_units if @accuracy_test_units!=nil
    count=0;seen={}
    for u in list
      next if u==nil || u.dead? || u.team!=user.team || seen[u.object_id]
      seen[u.object_id]=true;count+=1 if u.ability_key==:victory_star
    end
    mult=1.0;count.times{mult*=1.1};mult
  end
  def canonical_move_accuracy(data)
    return nil if data==nil
    return data[:accuracy] if data.has_key?(:accuracy)
    mk=data[:canonical_move_key];md=mk==nil ? nil : PMD_AC.move_data(mk);md==nil ? nil : md[:accuracy]
  end
  def canonical_accuracy_probability(user,target,data)
    return 100.0 if user==nil || target==nil || data==nil
    ub=user.respond_to?(:canonical_accuracy_behavior) ? user.canonical_accuracy_behavior : {}
    tb=target.respond_to?(:canonical_accuracy_behavior) ? target.canonical_accuracy_behavior : {}
    return 100.0 if ub[:kind]==:no_guard || tb[:kind]==:no_guard
    base=canonical_move_accuracy(data);return 100.0 if base==nil
    chance=base.to_f
    chance*=PMD_AC.accuracy_stage_multiplier(user.stat_stage(:accuracy)) if user.respond_to?(:stat_stage)
    chance/=PMD_AC.accuracy_stage_multiplier(target.stat_stage(:evasion)) if target.respond_to?(:stat_stage)
    if ub[:kind]==:accuracy_multiplier;chance*=ub[:num].to_f/[ub[:den].to_i,1].max.to_f;end
    cat=data[:damage_category]||data[:category]
    if ub[:kind]==:hustle && cat==:physical;chance*=ub[:accuracy_num].to_f/[ub[:accuracy_den].to_i,1].max.to_f;end
    chance*=canonical_team_accuracy_multiplier(user)
    if tb[:kind]==:confused_evasion_multiplier && target.status?(:confusion);chance/=tb[:num].to_f/[tb[:den].to_i,1].max.to_f;end
    PMD_AC.clamp(chance,0.0,100.0)
  end
  def canonical_accuracy_hit?(user,target,data,log_check=true)
    ub=user.respond_to?(:canonical_accuracy_behavior) ? user.canonical_accuracy_behavior : {}
    tb=target.respond_to?(:canonical_accuracy_behavior) ? target.canonical_accuracy_behavior : {}
    base=canonical_move_accuracy(data)
    if base==nil || ub[:kind]==:no_guard || tb[:kind]==:no_guard
      if log_check && verification_mode==:accuracy_evasion
        reason=base==nil ? "never_miss" : "no_guard";log_event(:accuracy_evasion,user.log_name+" -> "+target.log_name+" move="+(data[:canonical_move_key]||:unknown).to_s+" chance=100.00 result=hit reason="+reason)
      end
      return true
    end
    chance=canonical_accuracy_probability(user,target,data);return false if chance<=0.0
    return true if chance>=100.0
    roll=canonical_accuracy_roll_value;hit=roll<chance
    if log_check && (verification_mode==:accuracy_evasion || !hit)
      log_event(:accuracy_evasion,user.log_name+" -> "+target.log_name+" move="+(data[:canonical_move_key]||:unknown).to_s+" chance="+sprintf("%.2f",chance)+" roll="+sprintf("%.2f",roll)+" result="+(hit ? "hit":"miss"))
    end
    hit
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if data!=nil && data[:canonical_move_key]!=nil && user!=nil && target!=nil && user.team!=target.team
      unless canonical_accuracy_hit?(user,target,data,true)
        user.register_miss(target);return false
      end
    end
    pmd_ac_v027_apply_skill_effects(user,target,data,scale)
  end

  def projectile_tracking_for(user,kind,effect_type)
    data=PMD_AC.skill_data(effect_type)
    if data!=nil && data[:canonical_move_key]!=nil
      return :perfect if canonical_move_accuracy(data)==nil
      b=user.respond_to?(:canonical_accuracy_behavior) ? user.canonical_accuracy_behavior : {}
      return :perfect if b[:kind]==:no_guard
    end
    return :perfect if verification_mode==:accuracy_evasion && @v027_force_tracking_skill==effect_type
    pmd_ac_v027_projectile_tracking_for(user,kind,effect_type)
  end
  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    if target!=nil && target.respond_to?(:canonical_accuracy_behavior) && target.canonical_accuracy_behavior[:kind]==:no_guard
      tracking_override=:perfect
    end
    pmd_ac_v027_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
  end

  def accuracy_verification_unit(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99027000+id.to_i,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9300+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);u.reset_stat_stages
    @accuracy_test_units=[] if @accuracy_test_units==nil;@accuracy_test_units.push(u);u
  end

  def log_event(category,message)
    text=message.to_s
    if category.to_s=="verify" && verification_mode==:accuracy_evasion && text.index("ACCURACY_EVASION_")==0 && text.include?(" pass=0");@accuracy_evasion_failed=true;end
    pmd_ac_v027_log_event(category,message)
  end

  def verify_accuracy_evasion_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::AccuracyEvasionDB.manifest;e=PMD_AC.validate_accuracy_evasion_db;actual=PMD_AC.accuracy_evasion_checksum32;pass=e.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" moves="+m[:new_mapped_move_count].to_s+" cumulative="+m[:cumulative_mapped_move_count].to_s+" covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+" coverage="+m[:cumulative_coverage_percent].to_s+"% abilities="+m[:new_ability_behavior_count].to_s+" slots="+m[:implemented_slot_count].to_s+"/"+m[:total_slot_count].to_s+" species="+m[:species_with_any_implemented_ability].to_s+"/494 checksum="+actual.to_s+" errors=["+e.join(",")+"]");@verification_done[tag]=true
  end
  def verify_accuracy_evasion_formula(tag)
    return if @verification_done[tag];vals={-6=>1.0/3.0,-1=>0.75,1=>4.0/3.0,6=>3.0};ok=true;for k in vals.keys;ok=false if (PMD_AC.accuracy_stage_multiplier(k)-vals[k]).abs>0.0001;end
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" m-6="+sprintf("%.3f",PMD_AC.accuracy_stage_multiplier(-6))+" m-1="+sprintf("%.3f",PMD_AC.accuracy_stage_multiplier(-1))+" m+1="+sprintf("%.3f",PMD_AC.accuracy_stage_multiplier(1))+" m+6="+sprintf("%.3f",PMD_AC.accuracy_stage_multiplier(6)));@verification_done[tag]=true
  end
  def verify_accuracy_evasion_bridge(tag)
    return if @verification_done[tag];ss=PMD_AC.skill_data(:mv_sweet_scent);se=(ss[:effects]||[]).find{|e|e[:stat]==:evasion};pass=PMD_AC.move_executable?(:sand_attack) && PMD_AC.move_executable?(:coil) && !PMD_AC.move_executable?(:minimize) && !PMD_AC.move_executable?(:defog) && se!=nil && se[:stages].to_i==-1 && PMD_AC::STAT_STAGE_KEYS.include?(:accuracy) && PMD_AC::STAT_STAGE_KEYS.include?(:evasion)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" sand_attack=on coil=on sweet_scent="+(se==nil ? "nil" : se[:stages].to_s)+" minimize=deferred defog=deferred");@verification_done[tag]=true
  end
  def verify_accuracy_evasion_sand_cast(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata);u.deploy_to_cell(1,1);t.deploy_to_cell(2,1);t.reset_stat_stages;t.pmd_ac_v0211_verification_suppress_active_evade if t.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade);@v027_force_tracking_skill=:mv_sand_attack;set_accuracy_verification_rolls([0]);ok=u.verification_force_skill(:mv_sand_attack,t);@accuracy_snapshots[:sand]=t.stat_stage(:accuracy)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before="+@accuracy_snapshots[:sand].to_s+" tracking=perfect");@verification_done[tag]=true
  end
  def verify_accuracy_evasion_sand_result(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);pass=t.stat_stage(:accuracy)==-1;t.pmd_ac_v0211_verification_restore_active_evade if t.respond_to?(:pmd_ac_v0211_verification_restore_active_evade);@v027_force_tracking_skill=nil
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" accuracy_stage="+t.stat_stage(:accuracy).to_s+" next_100_chance="+sprintf("%.2f",100.0*PMD_AC.accuracy_stage_multiplier(t.stat_stage(:accuracy))));@verification_done[tag]=true
  end
  def verify_accuracy_evasion_double_team(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:charmander);u.reset_stat_stages;ok=u.verification_force_skill(:mv_double_team,u);@accuracy_snapshots[:double_ok]=ok
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before=0");@verification_done[tag]=true
  end
  def verify_accuracy_evasion_double_team_result(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:charmander);pass=@accuracy_snapshots[:double_ok] && u.stat_stage(:evasion)==1
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" evasion_stage="+u.stat_stage(:evasion).to_s);@verification_done[tag]=true
  end
  def verify_accuracy_evasion_boundary(tag)
    return if @verification_done[tag];u=accuracy_verification_unit(:rattata,:primary,:ally,20);t=accuracy_verification_unit(:rattata,:primary,:enemy,21);t.change_stat_stage(:evasion,1,t);d=PMD_AC.skill_data(:mv_tackle);chance=canonical_accuracy_probability(u,t,d);set_accuracy_verification_rolls([74,75]);a=canonical_accuracy_hit?(u,t,d,false);b=canonical_accuracy_hit?(u,t,d,false);pass=(chance-75.0).abs<0.01 && a && !b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" chance="+sprintf("%.2f",chance)+" roll74="+(a ? "hit":"miss")+" roll75="+(b ? "hit":"miss"));@verification_done[tag]=true
  end
  def verify_accuracy_evasion_abilities(tag)
    return if @verification_done[tag];dummy=accuracy_verification_unit(:rattata,:primary,:enemy,30);kin=PMD_AC.skill_data(:mv_kinesis);tackle=PMD_AC.skill_data(:mv_tackle)
    ce=accuracy_verification_unit(:butterfree,:primary,:ally,31);c1=canonical_accuracy_probability(ce,dummy,kin)
    hu=accuracy_verification_unit(:rattata,:hidden,:ally,32);normal=accuracy_verification_unit(:rattata,:primary,:ally,33);c2=canonical_accuracy_probability(hu,dummy,tackle);atk_ok=hu.atk>normal.atk
    ng=accuracy_verification_unit(:machop,:secondary,:ally,34);dummy.change_stat_stage(:evasion,6,dummy);c3=canonical_accuracy_probability(ng,dummy,tackle)
    tf=accuracy_verification_unit(:pidgey,:secondary,:enemy,35);tf.apply_status(:confusion,{:duration=>999999,:value=>0,:stack_mode=>:refresh},ng);c4=canonical_accuracy_probability(normal,tf,tackle)
    dummy.reset_stat_stages
    vs=accuracy_verification_unit(:victini,:primary,:ally,36);ally=accuracy_verification_unit(:pidgey,:primary,:ally,37);c5=canonical_accuracy_probability(ally,dummy,kin)
    pass=c1>=99.99 && (c2-80.0).abs<0.01 && atk_ok && c3>=99.99 && (c4-50.0).abs<0.01 && (c5-88.0).abs<0.01
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" compound_eyes="+sprintf("%.2f",c1)+" hustle="+sprintf("%.2f",c2)+" hustle_atk="+(atk_ok ? "up":"bad")+" no_guard="+sprintf("%.2f",c3)+" tangled_feet="+sprintf("%.2f",c4)+" victory_star="+sprintf("%.2f",c5));@verification_done[tag]=true
  end
  def verify_accuracy_evasion_keen_moody(tag)
    return if @verification_done[tag];foe=accuracy_verification_unit(:rattata,:primary,:enemy,40);ke=accuracy_verification_unit(:pidgey,:primary,:ally,41);ke.change_stat_stage(:accuracy,-1,foe);keen=ke.stat_stage(:accuracy)==0
    mo=accuracy_verification_unit(:smeargle,:hidden,:ally,42);set_accuracy_ability_rolls([5,5]);mo.canonical_trigger_turn_end;moody=mo.stat_stage(:accuracy)==2 && mo.stat_stage(:evasion)==-1
    pass=keen&&moody;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" keen_eye_acc="+ke.stat_stage(:accuracy).to_s+" moody_acc="+mo.stat_stage(:accuracy).to_s+" moody_eva="+mo.stat_stage(:evasion).to_s);@verification_done[tag]=true
  end
  def verify_accuracy_evasion_mud_slap_cast(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:squirtle);t=verification_unit(:enemy,:rattata);u.deploy_to_cell(1,3);t.deploy_to_cell(2,3);t.reset_stat_stages;t.pmd_ac_v0211_verification_suppress_active_evade if t.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade);@v027_force_tracking_skill=:mv_mud_slap;@accuracy_snapshots[:mud_hp]=t.hp;ok=u.verification_force_skill(:mv_mud_slap,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" hp_before="+t.hp.to_s+" tracking=perfect");@verification_done[tag]=true
  end
  def verify_accuracy_evasion_mud_slap_result(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);b=@accuracy_snapshots[:mud_hp].to_i;pass=t.hp<b && t.stat_stage(:accuracy)==-1;t.pmd_ac_v0211_verification_restore_active_evade if t.respond_to?(:pmd_ac_v0211_verification_restore_active_evade);@v027_force_tracking_skill=nil
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" damage="+(b-t.hp).to_s+" accuracy_stage="+t.stat_stage(:accuracy).to_s);@verification_done[tag]=true
  end
  def verify_accuracy_evasion_never_miss(tag)
    return if @verification_done[tag];u=accuracy_verification_unit(:rattata,:primary,:ally,50);t=accuracy_verification_unit(:rattata,:primary,:enemy,51);t.change_stat_stage(:evasion,6,t);d=PMD_AC.skill_data(:mv_aerial_ace);set_accuracy_verification_rolls([99]);hit=canonical_accuracy_hit?(u,t,d,false);tracking=projectile_tracking_for(u,:skill_generic,:mv_swift);pass=hit && tracking==:perfect && PMD_AC.move_data(:aerial_ace)[:accuracy]==nil
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" aerial_ace_hit="+(hit ? "1":"0")+" target_eva=6 swift_tracking="+tracking.to_s);@verification_done[tag]=true
  end
  def verify_accuracy_evasion_runtime_file(tag)
    return if @verification_done[tag];pass=FileTest.exist?(PMD_AC::ACCURACY_EVASION_RUNTIME_FILE);log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" runtime_file="+(pass ? "present":"missing")+" source="+(PMD_AC::AccuracyEvasionDB.using_runtime_file? ? "rvdata":"embedded_first_boot"));@verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v027_update_verification_script
    return unless verification_mode==:accuracy_evasion
    f=@verification_frame
    verify_accuracy_evasion_manifest(:accuracy_evasion_manifest) if f==4
    verify_accuracy_evasion_formula(:accuracy_evasion_formula) if f==30
    verify_accuracy_evasion_bridge(:accuracy_evasion_bridge) if f==55
    verify_accuracy_evasion_sand_cast(:accuracy_evasion_sand_cast) if f==80
    verify_accuracy_evasion_sand_result(:accuracy_evasion_sand_result) if f==125
    verify_accuracy_evasion_double_team(:accuracy_evasion_double_team_cast) if f==145
    verify_accuracy_evasion_double_team_result(:accuracy_evasion_double_team_result) if f==180
    verify_accuracy_evasion_boundary(:accuracy_evasion_boundary) if f==210
    verify_accuracy_evasion_abilities(:accuracy_evasion_abilities) if f==255
    verify_accuracy_evasion_keen_moody(:accuracy_evasion_keen_moody) if f==300
    verify_accuracy_evasion_mud_slap_cast(:accuracy_evasion_mud_slap_cast) if f==325
    verify_accuracy_evasion_mud_slap_result(:accuracy_evasion_mud_slap_result) if f==375
    verify_accuracy_evasion_never_miss(:accuracy_evasion_never_miss) if f==400
    verify_accuracy_evasion_runtime_file(:accuracy_evasion_runtime_file) if f==430
    complete_verification_mode if f==PMD_AC::VERIFICATION_ACCURACY_EVASION_END_FRAME
  end
  def complete_verification_mode
    if verification_mode==:accuracy_evasion && @accuracy_evasion_failed
      for u in @units;u.verification_finish;end
      @verification_done[:complete]=true;log_event(:verify,"FAILED mode=ACCURACY_EVASION auto_skill=on original_skills=restored");return
    end
    pmd_ac_v027_complete_verification_mode
  end
end
