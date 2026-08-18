#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.22
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SPEED_STATUS_RUNTIME_FILE / USE_EXTERNAL_SPEED_STATUS_DB / VERIFICATION_SPEED_STATUS_END_FRAME / SPEED_RT_REFERENCE_BASE
# - SPEED_RT_REFERENCE_IV / SPEED_RT_MIN_FACTOR / SPEED_RT_MAX_FACTOR / PARALYSIS_CANONICAL_SPEED_MULT
# - FULL_PARALYSIS_CHANCE / VERIFICATION_MODES / VERIFICATION_LABELS
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
# ■ PMD AutoChess Proto v0.22
#    Canonical Speed Stage + Paralysis / Real-time Speed Mapping
#------------------------------------------------------------------------------
#  Base: verified v0.21.3 FullTestProject.
#  - Speed Stage now influences realtime movement and basic attack cadence.
#  - Paralysis uses Gen V 0.25 Speed before sqrt realtime compression.
#  - Full paralysis: 25% action-opportunity loss.
#  - 40 additional canonical moves become executable.
#==============================================================================
module PMD_AC
  SPEED_STATUS_RUNTIME_FILE="Data/PMD_AutoChess_SpeedStatus_v022_000.rvdata"
  USE_EXTERNAL_SPEED_STATUS_DB=true unless const_defined?(:USE_EXTERNAL_SPEED_STATUS_DB)
  VERIFICATION_SPEED_STATUS_END_FRAME=390
  SPEED_RT_REFERENCE_BASE=75.0
  SPEED_RT_REFERENCE_IV=15.0
  SPEED_RT_MIN_FACTOR=0.50
  SPEED_RT_MAX_FACTOR=1.75
  PARALYSIS_CANONICAL_SPEED_MULT=0.25
  FULL_PARALYSIS_CHANCE=25

  STATUS_DEFS[:paralysis]={:tags=>[:debuff,:control,:paralysis],:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:paralysis)

  module SpeedStatusDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def manifest;@data==nil ? {} : (@data[:manifest]||{});end
      def embedded_data;{:manifest=>PMD_AC::SPEED_STATUS_MANIFEST_V022,:behaviors=>PMD_AC::SPEED_STATUS_MOVE_V022};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_SPEED_STATUS_DB && FileTest.exist?(PMD_AC::SPEED_STATUS_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::SPEED_STATUS_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) &&
               c[:manifest][:schema_version]=="1.0" && c[:manifest][:new_mapped_move_count].to_i==40
              data=c;@using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil
        @data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_SPEED_STATUS_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::SPEED_STATUS_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def keys;load! unless loaded?;(@data[:behaviors]||{}).keys;end
      def behavior_count;keys.size;end
    end
  end

  class << self
    alias pmd_ac_v022_move_executable move_executable? unless method_defined?(:pmd_ac_v022_move_executable)
    alias pmd_ac_v022_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v022_move_autochess_hint)
    alias pmd_ac_v022_skill_data skill_data unless method_defined?(:pmd_ac_v022_skill_data)
    alias pmd_ac_v022_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v022_canonical_move_key_from_skill)

    def canonical_move_key_from_skill(skill_key)
      key=pmd_ac_v022_canonical_move_key_from_skill(skill_key);return key if key!=nil
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=="mv_"
      k=text[3,text.size-3].to_sym;SpeedStatusDB.behavior(k)==nil ? nil : k
    end
    def move_executable?(move_key);return true if SpeedStatusDB.behavior(move_key)!=nil;pmd_ac_v022_move_executable(move_key);end
    def move_autochess_hint(move_key)
      base=pmd_ac_v022_move_autochess_hint(move_key);b=SpeedStatusDB.behavior(move_key);return base if b==nil
      result=base==nil ? {} : base.dup;result[:behavior_status]=b[:behavior_status];result[:delivery]=b[:delivery]
      result[:range_px]=b[:range_px];result[:runtime_skill_key]=b[:runtime_skill_key];result
    end
    def skill_data(key)
      old=pmd_ac_v022_skill_data(key);return old if old!=nil && !old.empty?
      move_key=canonical_move_key_from_skill(key);return {} if move_key==nil
      data=SpeedStatusDB.behavior(move_key);return {} if data==nil
      result=data.dup;result[:move_type]=data[:type];result[:damage_category]=data[:category];result[:canonical_move_key]=move_key;result
    end

    def canonical_speed_reference(level)
      lv=[level.to_i,1].max
      (((2.0*SPEED_RT_REFERENCE_BASE+SPEED_RT_REFERENCE_IV)*lv.to_f/100.0)+5.0)
    end
    def realtime_speed_factor_for(speed_value,reference_value,paralyzed=false)
      ref=[reference_value.to_f,1.0].max;ratio=[speed_value.to_f/ref,0.01].max
      ratio*=PARALYSIS_CANONICAL_SPEED_MULT if paralyzed
      factor=Math.sqrt(ratio)
      clamp(factor,SPEED_RT_MIN_FACTOR,SPEED_RT_MAX_FACTOR)
    end
    def speed_status_checksum32
      h=0
      for key in SpeedStatusDB.keys.sort{|a,b|a.to_s<=>b.to_s}
        r=SpeedStatusDB.behavior(key);eff=[];sec=[]
        for e in (r[:effects]||[]);eff.push([e[:type],e[:power],e[:stat],e[:stages],e[:chance],e[:respect_move_type_immunity],e[:ratio]].join(","));end
        for e in (r[:secondary_effects]||[]);sec.push([e[:group],e[:type],e[:status],e[:stat],e[:stages],e[:chance],e[:receiver],e[:duration],e[:interval]].join(","));end
        text=[key,r[:runtime_skill_key],r[:target],r[:delivery],r[:range_px],r[:global_direct],eff.join(";"),sec.join(";")].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end
    def validate_speed_status_db
      errors=[]
      for key in SpeedStatusDB.keys
        r=SpeedStatusDB.behavior(key);errors.push("move:"+key.to_s) if move_data(key)==nil
        errors.push("skill:"+key.to_s) unless r[:runtime_skill_key]==canonical_runtime_skill_key(key)
        errors.push("effects:"+key.to_s) if (r[:effects]||[]).empty?
      end
      errors.push("count") unless SpeedStatusDB.behavior_count==40
      errors.push("rapid_spin") unless SpeedStatusDB.behavior(:rapid_spin)==nil
      ss=SpeedStatusDB.behavior(:string_shot);sse=ss==nil ? nil : (ss[:effects]||[]).find{|e|e[:stat]==:speed}
      errors.push("string_shot") unless sse!=nil && sse[:stages].to_i==-1
      errors.push("checksum") unless speed_status_checksum32==SpeedStatusDB.manifest[:runtime_checksum32].to_i
      errors
    end
  end
  SpeedStatusDB.load!

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,
                      :progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,
                      :stat_stage,:sustain,:secondary,:speed_status]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",
    :energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",
    :progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",
    :species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",
    :sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS"}
end

class Game_PMDChessUnit
  alias pmd_ac_v022_attack_speed_multiplier attack_speed_multiplier unless method_defined?(:pmd_ac_v022_attack_speed_multiplier)
  alias pmd_ac_v022_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v022_effective_move_speed)
  alias pmd_ac_v022_begin_attack begin_attack unless method_defined?(:pmd_ac_v022_begin_attack)
  alias pmd_ac_v022_begin_skill begin_skill unless method_defined?(:pmd_ac_v022_begin_skill)
  alias pmd_ac_v022_status_debug_label status_debug_label unless method_defined?(:pmd_ac_v022_status_debug_label)

  def paralyzed?;status?(:paralysis);end
  def realtime_speed_factor
    ref=PMD_AC.canonical_speed_reference(level)
    PMD_AC.realtime_speed_factor_for(speed_stat,ref,paralyzed?)
  end
  def status_debug_label
    text=pmd_ac_v022_status_debug_label
    return text if !paralyzed?
    text==nil || text.empty? ? "Par" : text+" Par"
  end
  def attack_speed_multiplier
    pmd_ac_v022_attack_speed_multiplier*realtime_speed_factor
  end
  def effective_move_speed
    pmd_ac_v022_effective_move_speed*realtime_speed_factor
  end
  def begin_attack
    if paralyzed? && @scene!=nil && @scene.canonical_full_paralysis?(self,:basic)
      @attack_wait=@attack_wait_max.to_f
      return
    end
    pmd_ac_v022_begin_attack
  end
  def begin_skill(skill_target=nil)
    if paralyzed? && @scene!=nil && @scene.canonical_full_paralysis?(self,:skill)
      @energy=0
      @skill_target=nil
      return
    end
    pmd_ac_v022_begin_skill(skill_target)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v022_start start unless method_defined?(:pmd_ac_v022_start)
  alias pmd_ac_v022_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v022_prepare_verification_battle)
  alias pmd_ac_v022_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v022_apply_skill_effects)
  alias pmd_ac_v022_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v022_skill_cast_worthwhile)
  alias pmd_ac_v022_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v022_projectile_tracking_for)
  alias pmd_ac_v022_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v022_update_verification_script)
  alias pmd_ac_v022_log_event log_event unless method_defined?(:pmd_ac_v022_log_event)
  alias pmd_ac_v022_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v022_complete_verification_mode)

  def start
    pmd_ac_v022_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.21.3 Battle Verification Log","PMD AutoChess Proto v0.22 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::SpeedStatusDB.manifest
    log_event(:speed_status,"LOADED new="+PMD_AC::SpeedStatusDB.behavior_count.to_s+
      " cumulative="+m[:cumulative_mapped_move_count].to_s+" covered="+m[:cumulative_reference_covered].to_s+
      "/"+m[:learnset_reference_total].to_s+" source="+(PMD_AC::SpeedStatusDB.using_runtime_file? ? "rvdata":"embedded")+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v022_prepare_verification_battle
    if verification_mode==:speed_status
      for u in @units
        u.verification_combat_sandbox(true);u.reset_stat_stages;u.verification_clear_status(:paralysis)
      end
      @speed_status_snapshots={};@speed_status_verification_failed=false;@paralysis_verification_rolls=[]
      @v022_paralysis_tracking_override=false
    end
  end

  def set_paralysis_verification_rolls(values);@paralysis_verification_rolls=values.dup;end
  def canonical_full_paralysis?(unit,kind=:action)
    return false if unit==nil || !unit.paralyzed?
    roll=nil
    if verification_mode==:speed_status && @paralysis_verification_rolls!=nil && !@paralysis_verification_rolls.empty?
      roll=@paralysis_verification_rolls.shift.to_i
    else
      roll=rand(100)
    end
    blocked=roll<PMD_AC::FULL_PARALYSIS_CHANCE
    log_event(:paralysis,unit.log_name+" "+(blocked ? "FULL_PARALYSIS" : "ACT_OK")+
      " kind="+kind.to_s+" roll="+roll.to_s+" chance="+PMD_AC::FULL_PARALYSIS_CHANCE.to_s)
    add_skill_effect(unit,:stun) if blocked
    blocked
  end

  def canonical_paralysis_type_immune?(move_key,target)
    return false if target==nil
    return false unless move_key==:thunder_wave
    PMD_AC.type_effectiveness(:electric,target.pokemon_types)<=0.0
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v022_apply_skill_effects(user,target,data,scale)
    return result if user==nil || target==nil || target.dead?
    for e in (data[:effects]||[])
      next unless e[:type]==:canonical_paralysis
      move=data[:canonical_move_key]
      if e[:respect_move_type_immunity] && canonical_paralysis_type_immune?(move,target)
        log_event(:paralysis,target.log_name+" IMMUNE move="+move.to_s+" reason=type")
        next
      end
      target.apply_status(:paralysis,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},user)
      add_skill_effect(target,:stun)
      log_event(:paralysis,target.log_name+" PARALYZED move="+move.to_s+" src="+user.log_name)
    end
    result
  end

  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v022_skill_cast_worthwhile(unit,target,data)
    para=(data[:effects]||[]).find{|e|e[:type]==:canonical_paralysis}
    return true if para==nil
    return false if target==nil || target.dead? || target.paralyzed?
    return false if para[:respect_move_type_immunity] && canonical_paralysis_type_immune?(data[:canonical_move_key],target)
    true
  end

  def projectile_tracking_for(user,kind,effect_type)
    if verification_mode==:speed_status && @v022_paralysis_tracking_override && effect_type==:mv_thunder_shock
      return :perfect
    end
    pmd_ac_v022_projectile_tracking_for(user,kind,effect_type)
  end

  def log_event(category,message)
    if category.to_s=="verify"
      text=message.to_s
      @speed_status_verification_failed=true if text.index("SPEED_STATUS_")==0 && text.include?(" pass=0")
    end
    pmd_ac_v022_log_event(category,message)
  end

  def verify_speed_status_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::SpeedStatusDB.manifest
    pass=PMD_AC::SpeedStatusDB.behavior_count==40 && m[:previous_mapped_move_count].to_i==114 &&
      m[:cumulative_mapped_move_count].to_i==154 && m[:new_reference_covered].to_i==567 &&
      m[:cumulative_reference_covered].to_i==2616 && PMD_AC.speed_status_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" new=40 cumulative=154 covered=2616/7005 coverage="+m[:cumulative_coverage_percent].to_s+"%")
    @verification_done[tag]=true
  end

  def verify_speed_status_formula(tag)
    return if @verification_done[tag]
    n=PMD_AC.realtime_speed_factor_for(30,30,false);fast=PMD_AC.realtime_speed_factor_for(60,30,false)
    slow=PMD_AC.realtime_speed_factor_for(15,30,false);para=PMD_AC.realtime_speed_factor_for(30,30,true)
    pass=(n-1.0).abs<0.001 && (fast-Math.sqrt(2.0)).abs<0.002 && (slow-Math.sqrt(0.5)).abs<0.002 && (para-0.5).abs<0.001
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" neutral="+sprintf("%.3f",n)+" fast="+sprintf("%.3f",fast)+" slow="+sprintf("%.3f",slow)+" paralysis="+sprintf("%.3f",para))
    @verification_done[tag]=true
  end

  def verify_speed_status_bridge(tag)
    return if @verification_done[tag]
    ag=PMD_AC.skill_data(:mv_agility);ts=PMD_AC.skill_data(:mv_thunder_shock);ss=PMD_AC.skill_data(:mv_string_shot);rs=PMD_AC.skill_data(:mv_rapid_spin)
    sse=(ss[:effects]||[]).find{|e|e[:stat]==:speed}
    pass=PMD_AC.move_executable?(:agility) && PMD_AC.move_executable?(:thunder_shock) && sse!=nil && sse[:stages].to_i==-1 && rs.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" agility=on thunder_shock=on string_shot=-1 rapid_spin=deferred")
    @verification_done[tag]=true
  end

  def verify_speed_status_agility_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);u.reset_stat_stages;u.verification_clear_status(:paralysis)
    @speed_status_snapshots[:agility]=[u.realtime_speed_factor,u.effective_move_speed,u.attack_speed_multiplier]
    ok=u.verification_force_skill(:mv_agility,u)
    b=@speed_status_snapshots[:agility]
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" factor_before="+sprintf("%.3f",b[0])+" move_before="+sprintf("%.3f",b[1]))
    @verification_done[tag]=true
  end
  def verify_speed_status_agility_result(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);b=@speed_status_snapshots[:agility]
    pass=u.stat_stage(:speed)==2 && u.realtime_speed_factor>b[0] && u.effective_move_speed>b[1] && u.attack_speed_multiplier>b[2]
    after_factor=u.realtime_speed_factor;after_move=u.effective_move_speed
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stage="+u.stat_stage(:speed).to_s+" factor="+sprintf("%.3f",b[0])+"->"+sprintf("%.3f",after_factor)+" move="+sprintf("%.3f",b[1])+"->"+sprintf("%.3f",after_move))
    u.reset_stat_stages
    @verification_done[tag]=true
  end

  def verify_speed_status_paralysis_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:enemy,:pikachu);t=verification_unit(:ally,:squirtle)
    t.verification_clear_status(:paralysis);t.pmd_ac_v0211_verification_suppress_active_evade
    @v022_paralysis_tracking_override=true;set_secondary_verification_rolls([0])
    @speed_status_snapshots[:para]=[t.hp,t.realtime_speed_factor]
    ok=u.verification_force_skill(:mv_thunder_shock,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before="+t.hp.to_s+" factor_before="+sprintf("%.3f",@speed_status_snapshots[:para][1])+" forced_secondary_roll=0 tracking=perfect")
    @verification_done[tag]=true
  end
  def verify_speed_status_paralysis_result(tag)
    return if @verification_done[tag]
    t=verification_unit(:ally,:squirtle);b=@speed_status_snapshots[:para]
    @v022_paralysis_tracking_override=false;t.pmd_ac_v0211_verification_restore_active_evade
    pass=t.hp<b[0] && t.paralyzed? && t.realtime_speed_factor<b[1]
    after_factor=t.realtime_speed_factor
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" damage="+(b[0]-t.hp).to_s+" paralyzed="+(t.paralyzed? ? "1":"0")+" factor="+sprintf("%.3f",b[1])+"->"+sprintf("%.3f",after_factor)+" tracking_restored=strong")
    t.verification_clear_status(:paralysis)
    @verification_done[tag]=true
  end

  def verify_speed_status_type_rules(tag)
    return if @verification_done[tag]
    dummy=verification_unit(:ally,:squirtle)
    # Helper-level Gen V rule: Electric types are NOT inherently paralysis immune.
    ground=PMD_AC.type_effectiveness(:electric,[:ground])<=0.0
    electric_not_immune=true
    pass=ground && electric_not_immune && PMD_AC::PARALYSIS_CANONICAL_SPEED_MULT==0.25
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" thunder_wave_ground=immune electric_type_para=allowed gen5_speed=0.25")
    @verification_done[tag]=true
  end

  def verify_speed_status_full_para(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);u.apply_status(:paralysis,{:duration=>999999,:value=>0,:interval=>999999},nil)
    set_paralysis_verification_rolls([24,25])
    a=canonical_full_paralysis?(u,:verify);b=canonical_full_paralysis?(u,:verify)
    pass=a && !b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" roll24="+(a ? "block":"bad")+" roll25="+(b ? "bad":"allow")+" chance=25")
    u.verification_clear_status(:paralysis)
    @verification_done[tag]=true
  end

  def verify_speed_status_runtime_file(tag)
    return if @verification_done[tag]
    pass=FileTest.exist?(PMD_AC::SPEED_STATUS_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" runtime_file="+(pass ? "present":"missing")+" source="+(PMD_AC::SpeedStatusDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v022_update_verification_script
    return unless verification_mode==:speed_status
    f=@verification_frame
    verify_speed_status_manifest(:speed_status_manifest) if f==4
    verify_speed_status_formula(:speed_status_formula) if f==30
    verify_speed_status_bridge(:speed_status_bridge) if f==55
    verify_speed_status_agility_cast(:speed_status_agility_cast) if f==80
    verify_speed_status_agility_result(:speed_status_agility_result) if f==120
    verify_speed_status_paralysis_cast(:speed_status_paralysis_cast) if f==150
    verify_speed_status_paralysis_result(:speed_status_paralysis_result) if f==205
    verify_speed_status_type_rules(:speed_status_type_rules) if f==235
    verify_speed_status_full_para(:speed_status_full_para) if f==270
    verify_speed_status_runtime_file(:speed_status_runtime_file) if f==330
    complete_verification_mode if f==PMD_AC::VERIFICATION_SPEED_STATUS_END_FRAME
  end

  def complete_verification_mode
    if verification_mode==:speed_status
      @v022_paralysis_tracking_override=false
      begin
        t=verification_unit(:ally,:squirtle);t.pmd_ac_v0211_verification_restore_active_evade if t!=nil
      rescue;end
      if @speed_status_verification_failed
        return if @verification_done[:verification_complete]
        for unit in @units;unit.verification_finish;end
        @verification_done[:verification_complete]=true
        log_event(:verify,"FAILED mode=SPEED_STATUS auto_skill=on original_skills=restored")
        return
      end
    end
    pmd_ac_v022_complete_verification_mode
  end
end
