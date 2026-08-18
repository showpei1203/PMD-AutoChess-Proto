#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.21
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SECONDARY_EFFECT_RUNTIME_FILE / USE_EXTERNAL_SECONDARY_EFFECT_DB / VERIFICATION_SECONDARY_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / manifest
# - embedded_data / load! / behavior / keys
# - behavior_count / canonical_move_key_from_skill / move_executable? / move_autochess_hint
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.21
#    Canonical Secondary Effect Chance Layer
#------------------------------------------------------------------------------
#  Base: verified v0.20 FullTestProject.
#  Adds canonical proc chances for supported burn/poison and stat-stage effects.
#  Unsupported status families remain deferred rather than approximated.
#==============================================================================
module PMD_AC
  SECONDARY_EFFECT_RUNTIME_FILE="Data/PMD_AutoChess_SecondaryEffects_v021_000.rvdata"
  USE_EXTERNAL_SECONDARY_EFFECT_DB=true unless const_defined?(:USE_EXTERNAL_SECONDARY_EFFECT_DB)
  VERIFICATION_SECONDARY_END_FRAME=385

  module SecondaryEffectDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def manifest;@data==nil ? {} : (@data[:manifest]||{});end
      def embedded_data;{:manifest=>PMD_AC::SECONDARY_EFFECT_MANIFEST_V021,:behaviors=>PMD_AC::SECONDARY_EFFECT_MOVE_V021};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_SECONDARY_EFFECT_DB && FileTest.exist?(PMD_AC::SECONDARY_EFFECT_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::SECONDARY_EFFECT_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) &&
               c[:manifest][:schema_version]=="1.0" && c[:manifest][:new_mapped_move_count].to_i==44
              data=c;@using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil
        @data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_SECONDARY_EFFECT_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::SECONDARY_EFFECT_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def keys;load! unless loaded?;(@data[:behaviors]||{}).keys;end
      def behavior_count;keys.size;end
    end
  end

  class << self
    alias pmd_ac_v021_move_executable move_executable? unless method_defined?(:pmd_ac_v021_move_executable)
    alias pmd_ac_v021_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v021_move_autochess_hint)
    alias pmd_ac_v021_skill_data skill_data unless method_defined?(:pmd_ac_v021_skill_data)
    alias pmd_ac_v021_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v021_canonical_move_key_from_skill)

    def canonical_move_key_from_skill(skill_key)
      key=pmd_ac_v021_canonical_move_key_from_skill(skill_key)
      return key if key!=nil
      return nil if skill_key==nil
      text=skill_key.to_s;return nil unless text[0,3]=="mv_"
      k=text[3,text.size-3].to_sym
      SecondaryEffectDB.behavior(k)==nil ? nil : k
    end
    def move_executable?(move_key)
      return true if SecondaryEffectDB.behavior(move_key)!=nil
      pmd_ac_v021_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      base=pmd_ac_v021_move_autochess_hint(move_key);b=SecondaryEffectDB.behavior(move_key)
      return base if b==nil
      result=base==nil ? {} : base.dup
      result[:behavior_status]=b[:behavior_status];result[:delivery]=b[:delivery]
      result[:range_px]=b[:range_px];result[:runtime_skill_key]=b[:runtime_skill_key];result
    end
    def skill_data(key)
      old=pmd_ac_v021_skill_data(key);return old if old!=nil && !old.empty?
      move_key=canonical_move_key_from_skill(key);return {} if move_key==nil
      data=SecondaryEffectDB.behavior(move_key);return {} if data==nil
      result=data.dup;result[:move_type]=data[:type];result[:damage_category]=data[:category]
      result[:canonical_move_key]=move_key;result
    end
    def secondary_effect_checksum32
      h=0
      for key in SecondaryEffectDB.keys.sort{|a,b|a.to_s<=>b.to_s}
        r=SecondaryEffectDB.behavior(key);sec=[]
        for e in (r[:secondary_effects]||[])
          sec.push([e[:group],e[:type],e[:status],e[:stat],e[:stages],e[:chance],e[:receiver],e[:duration],e[:interval],e[:tick_maxhp_ratio]].join(","))
        end
        text=[key,r[:runtime_skill_key],r[:target],r[:delivery],r[:range_px],r[:global_direct],sec.join(";")].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end
    def validate_secondary_effect_db
      errors=[];skills=[]
      for key in SecondaryEffectDB.keys
        r=SecondaryEffectDB.behavior(key);errors.push("move:"+key.to_s) if move_data(key)==nil
        errors.push("skill:"+key.to_s) unless r[:runtime_skill_key]==canonical_runtime_skill_key(key)
        errors.push("secondary:"+key.to_s) if (r[:secondary_effects]||[]).empty?
        for e in (r[:secondary_effects]||[])
          errors.push("chance:"+key.to_s) if e[:chance].to_i<1 || e[:chance].to_i>100
          if e[:type]==:stat_stage && ![:atk,:def,:spatk,:spdef].include?(e[:stat]);errors.push("stat:"+key.to_s);end
          if e[:type]==:ailment && ![:burn,:poison].include?(e[:status]);errors.push("ailment:"+key.to_s);end
        end
        skills.push(r[:runtime_skill_key])
      end
      errors.push("count") unless SecondaryEffectDB.behavior_count==44
      errors.push("unique") unless skills.uniq.size==44
      errors.push("checksum") unless secondary_effect_checksum32==SecondaryEffectDB.manifest[:runtime_checksum32].to_i
      errors
    end
  end
  SecondaryEffectDB.load!

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,
                      :summon,:identity,:progression,:individual,:mega,:synergy,
                      :species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",
    :energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",
    :identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",
    :mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",
    :move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",
    :secondary=>"SECONDARY"}
end

class Game_PMDChessUnit
  def verification_clear_status(key)
    @statuses.delete(key) if @statuses!=nil
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v021_start start unless method_defined?(:pmd_ac_v021_start)
  alias pmd_ac_v021_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v021_prepare_verification_battle)
  alias pmd_ac_v021_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v021_apply_skill_effects)
  alias pmd_ac_v021_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v021_update_verification_script)
  alias pmd_ac_v021_log_event log_event unless method_defined?(:pmd_ac_v021_log_event)
  alias pmd_ac_v021_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v021_complete_verification_mode)

  def start
    pmd_ac_v021_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.20 Battle Verification Log","PMD AutoChess Proto v0.21 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::SecondaryEffectDB.manifest
    log_event(:secondary,"LOADED new="+PMD_AC::SecondaryEffectDB.behavior_count.to_s+
      " cumulative="+m[:cumulative_mapped_move_count].to_s+
      " covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+
      " source="+(PMD_AC::SecondaryEffectDB.using_runtime_file? ? "rvdata":"embedded")+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v021_prepare_verification_battle
    if verification_mode==:secondary
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages;u.verification_clear_status(:burn);u.verification_clear_status(:poison);end
      @secondary_snapshots={};@secondary_verification_failed=false;@secondary_verification_rolls=[]
    end
  end

  def set_secondary_verification_rolls(values)
    @secondary_verification_rolls=values.dup
  end
  def canonical_secondary_roll(chance)
    c=PMD_AC.clamp(chance.to_i,0,100)
    return [true,0] if c>=100
    roll=nil
    if verification_mode==:secondary && @secondary_verification_rolls!=nil && !@secondary_verification_rolls.empty?
      roll=@secondary_verification_rolls.shift.to_i
    else
      roll=rand(100)
    end
    [roll<c,roll]
  end
  def canonical_secondary_status_immune?(unit,status)
    return false if unit==nil
    types=unit.respond_to?(:pokemon_types) ? unit.pokemon_types : []
    return types.include?(:fire) if status==:burn
    return (types.include?(:poison) || types.include?(:steel)) if status==:poison
    false
  end

  def apply_canonical_secondary_group(user,target,data,effects,result)
    return if effects==nil || effects.empty? || result.to_i<=0
    chance=effects[0][:chance].to_i;proc_result,roll=canonical_secondary_roll(chance)
    move=(data[:canonical_move_key]||:unknown).to_s
    log_event(:secondary,user.log_name+" move="+move+" chance="+chance.to_s+" roll="+roll.to_s+" proc="+(proc_result ? "1":"0"))
    return unless proc_result
    for e in effects
      receiver=e[:receiver]==:user ? user : target
      next if receiver==nil || receiver.dead?
      case e[:type]
      when :stat_stage
        receiver.change_stat_stage(e[:stat],e[:stages].to_i,user)
        add_skill_effect(receiver,e[:stages].to_i>=0 ? :buff : :debuff)
      when :ailment
        status=e[:status]
        if canonical_secondary_status_immune?(receiver,status)
          log_event(:secondary,receiver.log_name+" IMMUNE status="+status.to_s+" move="+move)
          next
        end
        value=[(receiver.maxhp*e[:tick_maxhp_ratio].to_f).round,1].max
        receiver.apply_status(status,{:duration=>e[:duration].to_i,:value=>value,
          :interval=>e[:interval].to_i,:stack_mode=>:refresh},user)
        add_skill_effect(receiver,status)
      end
    end
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v021_apply_skill_effects(user,target,data,scale)
    return result if user==nil || target==nil
    groups={}
    for e in (data[:secondary_effects]||[])
      gid=e[:group]||0;groups[gid]=[] if groups[gid]==nil;groups[gid].push(e)
    end
    for gid in groups.keys.sort
      apply_canonical_secondary_group(user,target,data,groups[gid],result)
    end
    result
  end

  def log_event(category,message)
    if category.to_s=="verify"
      text=message.to_s
      @secondary_verification_failed=true if text.index("SECONDARY_")==0 && text.include?(" pass=0")
    end
    pmd_ac_v021_log_event(category,message)
  end

  def verify_secondary_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::SecondaryEffectDB.manifest
    pass=PMD_AC::SecondaryEffectDB.behavior_count==44 && m[:previous_mapped_move_count].to_i==70 &&
         m[:cumulative_mapped_move_count].to_i==114 && m[:new_reference_covered].to_i==444 &&
         m[:cumulative_reference_covered].to_i==2049 && PMD_AC.secondary_effect_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " new=44 cumulative=114 covered=2049/7005 coverage="+m[:cumulative_coverage_percent].to_s+"%")
    @verification_done[tag]=true
  end

  def verify_secondary_bridge(tag)
    return if @verification_done[tag]
    ember=PMD_AC.skill_data(:mv_ember);crunch=PMD_AC.skill_data(:mv_crunch);old=PMD_AC.skill_data(:mv_recover)
    thunder=PMD_AC.skill_data(:mv_thunder_punch);bug=PMD_AC.skill_data(:mv_bug_buzz)
    pass=ember[:secondary_effects][0][:status]==:burn && ember[:secondary_effects][0][:chance].to_i==10 &&
         crunch[:secondary_effects][0][:stat]==:def && crunch[:secondary_effects][0][:chance].to_i==20 &&
         old[:canonical_move_key]==:recover && thunder.empty? && bug.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " ember=burn10 crunch=def20 thunder_punch=deferred bug_buzz=deferred")
    @verification_done[tag]=true
  end

  def verify_secondary_chance(tag)
    return if @verification_done[tag]
    set_secondary_verification_rolls([9,10])
    a=canonical_secondary_roll(10);b=canonical_secondary_roll(10);c=canonical_secondary_roll(100)
    pass=a[0] && !b[0] && c[0] && a[1]==9 && b[1]==10
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" roll9="+(a[0] ? "proc":"miss")+" roll10="+(b[0] ? "proc":"miss")+" chance100="+(c[0] ? "proc":"miss"))
    @verification_done[tag]=true
  end

  def verify_secondary_ember_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata)
    t.verification_clear_status(:burn);u.deploy_to_cell(1,1);t.deploy_to_cell(3,1)
    set_secondary_verification_rolls([0]);@secondary_snapshots[:ember]=t.hp
    ok=u.verification_force_skill(:mv_ember,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before="+t.hp.to_s+" forced_roll=0 chance=10")
    @verification_done[tag]=true
  end
  def verify_secondary_ember_result(tag)
    return if @verification_done[tag]
    t=verification_unit(:enemy,:rattata);b=@secondary_snapshots[:ember].to_i
    pass=t.hp<b && t.status?(:burn)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" damage="+(b-t.hp).to_s+" burn="+(t.status?(:burn) ? "1":"0"))
    @verification_done[tag]=true
  end

  def verify_secondary_crunch_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata)
    t.reset_stat_stages;u.deploy_to_cell(1,1);t.deploy_to_cell(2,1);t.deploy_to_pixel(u.pixel_x+48.0,u.pixel_y)
    set_secondary_verification_rolls([0]);@secondary_snapshots[:crunch]=t.defense
    ok=u.verification_force_skill(:mv_crunch,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" def_before="+t.defense.to_s+" forced_roll=0 chance=20")
    @verification_done[tag]=true
  end
  def verify_secondary_crunch_result(tag)
    return if @verification_done[tag]
    t=verification_unit(:enemy,:rattata);b=@secondary_snapshots[:crunch].to_i
    pass=t.stat_stage(:def)==-1 && t.defense<b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stage="+t.stat_stage(:def).to_s+" def="+b.to_s+"->"+t.defense.to_s)
    @verification_done[tag]=true
  end

  def verify_secondary_leaf_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata)
    u.reset_stat_stages;u.deploy_to_cell(1,2);t.deploy_to_cell(3,2);@secondary_snapshots[:leaf]=u.special_attack
    ok=u.verification_force_skill(:mv_leaf_storm,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" spatk_before="+u.special_attack.to_s+" chance=100")
    @verification_done[tag]=true
  end
  def verify_secondary_leaf_result(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);b=@secondary_snapshots[:leaf].to_i
    pass=u.stat_stage(:spatk)==-2 && u.special_attack<b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stage="+u.stat_stage(:spatk).to_s+" spatk="+b.to_s+"->"+u.special_attack.to_s)
    @verification_done[tag]=true
  end

  def verify_secondary_area_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata)
    for e in living_units(:enemy);e.reset_stat_stages;end
    @secondary_snapshots[:area]=living_units(:enemy).collect{|e|e.id}
    ok=u.verification_force_skill(:mv_struggle_bug,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" enemies="+living_units(:enemy).size.to_s+" chance=100")
    @verification_done[tag]=true
  end
  def verify_secondary_area_result(tag)
    return if @verification_done[tag]
    hit=[];ok=true
    for e in living_units(:enemy)
      good=e.stat_stage(:spatk)==-1;ok=false unless good;hit.push(e.log_name) if good
    end
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" hit=["+hit.join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_secondary_immunity(tag)
    return if @verification_done[tag]
    fire=verification_unit(:ally,:charmander);poison=verification_unit(:ally,:bulbasaur);water=verification_unit(:ally,:squirtle)
    a=canonical_secondary_status_immune?(fire,:burn);b=canonical_secondary_status_immune?(poison,:poison);c=!canonical_secondary_status_immune?(water,:burn) && !canonical_secondary_status_immune?(water,:poison)
    pass=a&&b&&c
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" fire_burn="+(a ? "immune":"bad")+" poison_poison="+(b ? "immune":"bad")+" squirtle="+(c ? "normal":"bad"))
    @verification_done[tag]=true
  end

  def verify_secondary_runtime_file(tag)
    return if @verification_done[tag]
    pass=FileTest.exist?(PMD_AC::SECONDARY_EFFECT_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" runtime_file="+(pass ? "present":"missing")+
      " source="+(PMD_AC::SecondaryEffectDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v021_update_verification_script
    return unless verification_mode==:secondary
    f=@verification_frame
    verify_secondary_manifest(:secondary_manifest) if f==4
    verify_secondary_bridge(:secondary_bridge) if f==30
    verify_secondary_chance(:secondary_chance) if f==55
    verify_secondary_ember_cast(:secondary_ember_cast) if f==80
    verify_secondary_ember_result(:secondary_ember_result) if f==125
    verify_secondary_crunch_cast(:secondary_crunch_cast) if f==145
    verify_secondary_crunch_result(:secondary_crunch_result) if f==180
    verify_secondary_leaf_cast(:secondary_leaf_cast) if f==200
    verify_secondary_leaf_result(:secondary_leaf_result) if f==245
    verify_secondary_area_cast(:secondary_area_cast) if f==265
    verify_secondary_area_result(:secondary_area_result) if f==305
    verify_secondary_immunity(:secondary_immunity) if f==330
    verify_secondary_runtime_file(:secondary_runtime_file) if f==355
    complete_verification_mode if f==PMD_AC::VERIFICATION_SECONDARY_END_FRAME
  end

  def complete_verification_mode
    if verification_mode==:secondary && @secondary_verification_failed
      return if @verification_done[:verification_complete]
      for unit in @units;unit.verification_finish;end
      @verification_done[:verification_complete]=true
      log_event(:verify,"FAILED mode=SECONDARY auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v021_complete_verification_mode
  end
end
