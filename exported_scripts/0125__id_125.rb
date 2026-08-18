#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.19
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - STAT_STAGE_MIN / STAT_STAGE_MAX / STAT_STAGE_KEYS / STAT_STAGE_RUNTIME_FILE
# - USE_EXTERNAL_STAT_STAGE_DB / VERIFICATION_STAT_STAGE_END_FRAME / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【PMD_AC 對外／共用方法】
# - stat_stage_multiplier
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / loaded? / using_runtime_file? / load_error
# - manifest / embedded_data / load! / behavior
# - keys / behavior_count / stat_stage_move_behavior / canonical_move_key_from_skill
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.19
#    Pokemon Stat Stage Layer + Canonical Status Move Bridge
#------------------------------------------------------------------------------
#  Base: verified v0.18.1 FullTestProject.
#  Adds standard -6..+6 Pokemon stat stages without rewriting v0.15 Core.
#  Mapped now: Attack / Defense / Sp.Atk / Sp.Def status-stage moves.
#  Speed stages are stored by the stage system but intentionally do not alter
#  real-time cadence until the dedicated Real-time Speed Mapping phase.
#==============================================================================
module PMD_AC
  STAT_STAGE_MIN=-6
  STAT_STAGE_MAX=6
  STAT_STAGE_KEYS=[:atk,:def,:spatk,:spdef,:speed]
  STAT_STAGE_RUNTIME_FILE="Data/PMD_AutoChess_StatStages_v019_000.rvdata"
  USE_EXTERNAL_STAT_STAGE_DB=true unless const_defined?(:USE_EXTERNAL_STAT_STAGE_DB)
  VERIFICATION_STAT_STAGE_END_FRAME=330

  def self.stat_stage_multiplier(stage)
    n=PMD_AC.clamp(stage.to_i,STAT_STAGE_MIN,STAT_STAGE_MAX)
    return (2.0+n.to_f)/2.0 if n>=0
    return 2.0/(2.0-n.to_f)
  end

  module StatStageMoveDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def manifest;@data==nil ? {} : (@data[:manifest]||{});end
      def embedded_data;{:manifest=>PMD_AC::STAT_STAGE_MANIFEST_V019,:behaviors=>PMD_AC::STAT_STAGE_MOVE_V019};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_STAT_STAGE_DB && FileTest.exist?(PMD_AC::STAT_STAGE_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::STAT_STAGE_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) &&
               c[:manifest][:schema_version]=="1.0" && c[:manifest][:new_mapped_move_count].to_i==16
              data=c;@using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil
        @data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_STAT_STAGE_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::STAT_STAGE_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def keys;load! unless loaded?;(@data[:behaviors]||{}).keys;end
      def behavior_count;keys.size;end
    end
  end

  class << self
    alias pmd_ac_v019_move_executable move_executable? unless method_defined?(:pmd_ac_v019_move_executable)
    alias pmd_ac_v019_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v019_move_autochess_hint)
    alias pmd_ac_v019_skill_data skill_data unless method_defined?(:pmd_ac_v019_skill_data)
    alias pmd_ac_v019_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v019_canonical_move_key_from_skill)

    def stat_stage_move_behavior(move_key);StatStageMoveDB.behavior(move_key);end

    def canonical_move_key_from_skill(skill_key)
      key=pmd_ac_v019_canonical_move_key_from_skill(skill_key)
      return key if key!=nil
      return nil if skill_key==nil
      text=skill_key.to_s
      return nil unless text[0,3]=="mv_"
      k=text[3,text.size-3].to_sym
      return StatStageMoveDB.behavior(k)==nil ? nil : k
    end

    def move_executable?(move_key)
      return true if StatStageMoveDB.behavior(move_key)!=nil
      return pmd_ac_v019_move_executable(move_key)
    end

    def move_autochess_hint(move_key)
      base=pmd_ac_v019_move_autochess_hint(move_key)
      b=StatStageMoveDB.behavior(move_key)
      return base if b==nil
      result=base==nil ? {} : base.dup
      result[:behavior_status]=b[:behavior_status];result[:delivery]=b[:delivery]
      result[:range_px]=b[:range_px];result[:runtime_skill_key]=b[:runtime_skill_key]
      result
    end

    def skill_data(key)
      old=pmd_ac_v019_skill_data(key)
      return old if old!=nil && !old.empty?
      move_key=canonical_move_key_from_skill(key)
      return {} if move_key==nil
      data=StatStageMoveDB.behavior(move_key)
      return {} if data==nil
      result=data.dup;result[:move_type]=data[:type];result[:damage_category]=data[:category]
      result[:canonical_move_key]=move_key;result
    end

    def stat_stage_behavior_checksum32
      h=0
      for key in StatStageMoveDB.keys.sort{|a,b|a.to_s<=>b.to_s}
        r=StatStageMoveDB.behavior(key)
        eff=(r[:effects]||[]).collect{|e|[e[:type],e[:stat],e[:stages]].join(",")}.join(";")
        text=[key,r[:runtime_skill_key],r[:target_type],r[:delivery],r[:range_px],r[:global_direct],eff].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_stat_stage_db
      errors=[];skills=[]
      for key in StatStageMoveDB.keys
        r=StatStageMoveDB.behavior(key)
        errors.push("move:"+key.to_s) if move_data(key)==nil
        errors.push("skill:"+key.to_s) unless r[:runtime_skill_key]==canonical_runtime_skill_key(key)
        for e in (r[:effects]||[])
          errors.push("effect:"+key.to_s) unless e[:type]==:stat_stage && [:atk,:def,:spatk,:spdef].include?(e[:stat])
          errors.push("delta:"+key.to_s) if e[:stages].to_i<-6 || e[:stages].to_i>6
        end
        skills.push(r[:runtime_skill_key])
      end
      errors.push("count") unless StatStageMoveDB.behavior_count==16
      errors.push("unique") unless skills.uniq.size==16
      errors.push("checksum") unless stat_stage_behavior_checksum32==StatStageMoveDB.manifest[:runtime_checksum32].to_i
      errors
    end
  end
  StatStageMoveDB.load!

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,
                      :summon,:identity,:progression,:individual,:mega,:synergy,
                      :species_db,:move_db,:move_runtime,:stat_stage]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",
    :energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",
    :identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",
    :mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",
    :move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE"}
end

class Game_PMDChessUnit
  alias pmd_ac_v019_initialize initialize unless method_defined?(:pmd_ac_v019_initialize)
  alias pmd_ac_v019_ranged ranged? unless method_defined?(:pmd_ac_v019_ranged)

  def initialize(*args)
    pmd_ac_v019_initialize(*args)
    @stat_stages={:atk=>0,:def=>0,:spatk=>0,:spdef=>0,:speed=>0}
  end

  def ensure_stat_stages
    @stat_stages={} if @stat_stages==nil
    for k in PMD_AC::STAT_STAGE_KEYS;@stat_stages[k]=0 if @stat_stages[k]==nil;end
  end
  def stat_stage(stat);ensure_stat_stages;@stat_stages[stat].to_i;end
  def stat_stage_multiplier(stat);PMD_AC.stat_stage_multiplier(stat_stage(stat));end
  def reset_stat_stages;ensure_stat_stages;for k in PMD_AC::STAT_STAGE_KEYS;@stat_stages[k]=0;end;true;end
  def can_change_stat_stage?(stat,delta)
    return false unless PMD_AC::STAT_STAGE_KEYS.include?(stat)
    old=stat_stage(stat);newv=PMD_AC.clamp(old+delta.to_i,PMD_AC::STAT_STAGE_MIN,PMD_AC::STAT_STAGE_MAX)
    newv!=old
  end
  def change_stat_stage(stat,delta,source=nil)
    return 0 unless PMD_AC::STAT_STAGE_KEYS.include?(stat)
    ensure_stat_stages;old=@stat_stages[stat].to_i
    newv=PMD_AC.clamp(old+delta.to_i,PMD_AC::STAT_STAGE_MIN,PMD_AC::STAT_STAGE_MAX)
    @stat_stages[stat]=newv
    actual=newv-old
    log_event(:stat_stage,log_name+" "+stat.to_s+" "+old.to_s+"->"+newv.to_s+
      " delta="+actual.to_s+" mult="+sprintf("%.3f",PMD_AC.stat_stage_multiplier(newv))+
      (source==nil ? "" : " src="+source.log_name))
    actual
  end

  # Stage multipliers compose with the existing temporary status multipliers.
  def atk
    value=@atk.to_f*PMD_AC.stat_stage_multiplier(stat_stage(:atk))*status_stat_multiplier(:atk)
    [value.round,1].max
  end
  def defense
    value=@def.to_f*PMD_AC.stat_stage_multiplier(stat_stage(:def))*status_stat_multiplier(:def)
    [value.round,0].max
  end
  def special_attack
    value=@spatk.to_f*PMD_AC.stat_stage_multiplier(stat_stage(:spatk))*status_stat_multiplier(:spatk)
    [value.round,1].max
  end
  def special_defense
    value=@spdef.to_f*PMD_AC.stat_stage_multiplier(stat_stage(:spdef))*status_stat_multiplier(:spdef)
    [value.round,1].max
  end
  def speed_stat
    value=@speed_stat.to_f*PMD_AC.stat_stage_multiplier(stat_stage(:speed))
    [value.round,1].max
  end

  def pmd_ac_v019_direct_global_stage_aoe?
    return false unless @action==:skill
    data=skill_data
    return false if data==nil || data.empty? || data[:canonical_move_key]==nil
    data[:delivery]==:aoe && data[:target]==:all_opponents && data[:global_direct]
  end
  def ranged?
    return false if pmd_ac_v019_direct_global_stage_aoe?
    pmd_ac_v019_ranged
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v019_start start unless method_defined?(:pmd_ac_v019_start)
  alias pmd_ac_v019_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v019_prepare_verification_battle)
  alias pmd_ac_v019_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v019_apply_skill_effects)
  alias pmd_ac_v019_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v019_skill_cast_worthwhile)
  alias pmd_ac_v019_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v019_update_verification_script)
  alias pmd_ac_v019_log_event log_event unless method_defined?(:pmd_ac_v019_log_event)
  alias pmd_ac_v019_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v019_complete_verification_mode)

  def start
    pmd_ac_v019_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.18.1 Battle Verification Log",
                  "PMD AutoChess Proto v0.19 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::StatStageMoveDB.manifest
    log_event(:stat_stage,"LOADED new="+PMD_AC::StatStageMoveDB.behavior_count.to_s+
      " cumulative="+m[:cumulative_mapped_move_count].to_s+
      " covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+
      " source="+(PMD_AC::StatStageMoveDB.using_runtime_file? ? "rvdata":"embedded")+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v019_prepare_verification_battle
    if verification_mode==:stat_stage
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages;end
      @stat_stage_snapshots={};@stat_stage_verification_failed=false
    end
  end

  # Existing effect vocabulary remains responsible for everything else. v0.19
  # only consumes :stat_stage entries after the original resolver has run.
  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v019_apply_skill_effects(user,target,data,scale)
    return result if user==nil || target==nil || target.dead?
    for e in (data[:effects]||[])
      if e[:type]==:stat_stage
        target.change_stat_stage(e[:stat],e[:stages].to_i,user)
        add_skill_effect(target,e[:stages].to_i>=0 ? :buff : :debuff)
      end
    end
    result
  end

  # Do not waste a full energy bar on a pure stage move if every requested
  # stage is already clamped at +6/-6.
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v019_skill_cast_worthwhile(unit,target,data)
    stage_effects=(data[:effects]||[]).find_all{|e|e[:type]==:stat_stage}
    return true if stage_effects.empty?
    candidates=data[:target]==:all_opponents ? enemies_of(unit) : [target]
    for candidate in candidates
      next if candidate==nil || candidate.dead?
      for e in stage_effects
        return true if candidate.can_change_stat_stage?(e[:stat],e[:stages])
      end
    end
    false
  end

  def log_event(category,message)
    if category.to_s=="verify"
      text=message.to_s
      @stat_stage_verification_failed=true if text.index("STAT_STAGE_")==0 && text.include?(" pass=0")
    end
    pmd_ac_v019_log_event(category,message)
  end

  def verify_stat_stage_manifest(tag)
    return if @verification_done[tag]
    m=PMD_AC::StatStageMoveDB.manifest
    pass=PMD_AC::StatStageMoveDB.behavior_count==16 && m[:previous_mapped_move_count].to_i==39 &&
         m[:cumulative_mapped_move_count].to_i==55 && m[:new_reference_covered].to_i==584 &&
         m[:cumulative_reference_covered].to_i==1400 &&
         PMD_AC.stat_stage_behavior_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " new=16 cumulative=55 covered=1400/7005 coverage="+m[:cumulative_coverage_percent].to_s+"%")
    @verification_done[tag]=true
  end

  def verify_stat_stage_formula(tag)
    return if @verification_done[tag]
    vals={-6=>0.25,-2=>0.5,-1=>(2.0/3.0),0=>1.0,1=>1.5,2=>2.0,6=>4.0};ok=true
    for k in vals.keys;ok=false if (PMD_AC.stat_stage_multiplier(k)-vals[k]).abs>0.0001;end
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " m-6="+sprintf("%.2f",PMD_AC.stat_stage_multiplier(-6))+" m-1="+sprintf("%.3f",PMD_AC.stat_stage_multiplier(-1))+
      " m+1="+sprintf("%.2f",PMD_AC.stat_stage_multiplier(1))+" m+6="+sprintf("%.2f",PMD_AC.stat_stage_multiplier(6)))
    @verification_done[tag]=true
  end

  def verify_stat_stage_bridge(tag)
    return if @verification_done[tag]
    old=PMD_AC.skill_data(:mv_water_gun);growl=PMD_AC.skill_data(:mv_growl);speed=PMD_AC.skill_data(:mv_agility)
    pass=old[:canonical_move_key]==:water_gun && growl[:canonical_move_key]==:growl &&
         growl[:effects][0][:type]==:stat_stage && speed.empty? && PMD_AC.move_executable?(:growl) && !PMD_AC.move_executable?(:agility)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " old39="+PMD_AC::MoveBehaviorDB.behavior_count.to_s+" new16="+PMD_AC::StatStageMoveDB.behavior_count.to_s+
      " agility=deferred")
    @verification_done[tag]=true
  end

  def verify_stat_stage_growl_cast(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:bulbasaur);target=verification_unit(:enemy,:rattata)
    for u in living_units(:enemy);u.reset_stat_stages;end
    @stat_stage_snapshots[:growl]=living_units(:enemy).collect{|u|[u.id,u.atk]}
    ok=caster.verification_force_skill(:mv_growl,target)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" enemies="+living_units(:enemy).size.to_s)
    @verification_done[tag]=true
  end
  def verify_stat_stage_growl_result(tag)
    return if @verification_done[tag]
    before={};for p in @stat_stage_snapshots[:growl];before[p[0]]=p[1];end
    hit=[];ok=true
    for u in living_units(:enemy)
      good=u.stat_stage(:atk)==-1 && u.atk<before[u.id].to_i;ok=false unless good;hit.push(u.log_name) if good
    end
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" hit=["+hit.join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_stat_stage_swords_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);u.reset_stat_stages;@stat_stage_snapshots[:swords]=u.atk
    ok=u.verification_force_skill(:mv_swords_dance,u)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before="+@stat_stage_snapshots[:swords].to_s)
    @verification_done[tag]=true
  end
  def verify_stat_stage_swords_result(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);b=@stat_stage_snapshots[:swords].to_i
    pass=u.stat_stage(:atk)==2 && u.atk>=b*2-1
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stage="+u.stat_stage(:atk).to_s+" atk="+b.to_s+"->"+u.atk.to_s)
    @verification_done[tag]=true
  end

  def verify_stat_stage_screech_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata);t.reset_stat_stages
    @stat_stage_snapshots[:screech]=t.defense
    ok=u.verification_force_skill(:mv_screech,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before="+@stat_stage_snapshots[:screech].to_s)
    @verification_done[tag]=true
  end
  def verify_stat_stage_screech_result(tag)
    return if @verification_done[tag]
    t=verification_unit(:enemy,:rattata);b=@stat_stage_snapshots[:screech].to_i
    pass=t.stat_stage(:def)==-2 && t.defense< b && (t.defense-b*0.5).abs<=2
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stage="+t.stat_stage(:def).to_s+" def="+b.to_s+"->"+t.defense.to_s)
    @verification_done[tag]=true
  end

  def verify_stat_stage_calm_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);u.reset_stat_stages
    @stat_stage_snapshots[:calm]=[u.special_attack,u.special_defense]
    ok=u.verification_force_skill(:mv_calm_mind,u)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" before="+@stat_stage_snapshots[:calm].join("/"))
    @verification_done[tag]=true
  end
  def verify_stat_stage_calm_result(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);b=@stat_stage_snapshots[:calm]
    pass=u.stat_stage(:spatk)==1 && u.stat_stage(:spdef)==1 && u.special_attack>b[0] && u.special_defense>b[1]
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" stages="+u.stat_stage(:spatk).to_s+"/"+u.stat_stage(:spdef).to_s+
      " stats="+b.join("/")+"->"+u.special_attack.to_s+"/"+u.special_defense.to_s)
    @verification_done[tag]=true
  end

  def verify_stat_stage_clamp_ai(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);u.reset_stat_stages;u.change_stat_stage(:atk,6,nil)
    data=PMD_AC.skill_data(:mv_swords_dance)
    blocked=!skill_cast_worthwhile?(u,u,data);u.change_stat_stage(:atk,-1,nil);allowed=skill_cast_worthwhile?(u,u,data)
    u.change_stat_stage(:atk,20,nil);clamp_hi=(u.stat_stage(:atk)==6);u.change_stat_stage(:atk,-20,nil);clamp_lo=(u.stat_stage(:atk)==-6)
    pass=blocked && allowed && clamp_hi && clamp_lo
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" at+6_block="+(blocked ? "1":"0")+
      " at+5_allow="+(allowed ? "1":"0")+" clamp="+(clamp_hi&&clamp_lo ? "ok":"bad"))
    @verification_done[tag]=true
  end

  def verify_stat_stage_runtime_file(tag)
    return if @verification_done[tag]
    pass=FileTest.exist?(PMD_AC::STAT_STAGE_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" runtime_file="+(pass ? "present":"missing")+
      " source="+(PMD_AC::StatStageMoveDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v019_update_verification_script
    return unless verification_mode==:stat_stage
    f=@verification_frame
    verify_stat_stage_manifest(:stat_stage_manifest) if f==4
    verify_stat_stage_formula(:stat_stage_formula) if f==25
    verify_stat_stage_bridge(:stat_stage_bridge) if f==50
    verify_stat_stage_growl_cast(:stat_stage_growl_cast) if f==75
    verify_stat_stage_growl_result(:stat_stage_growl_result) if f==105
    verify_stat_stage_swords_cast(:stat_stage_swords_cast) if f==125
    verify_stat_stage_swords_result(:stat_stage_swords_result) if f==155
    verify_stat_stage_screech_cast(:stat_stage_screech_cast) if f==175
    verify_stat_stage_screech_result(:stat_stage_screech_result) if f==205
    verify_stat_stage_calm_cast(:stat_stage_calm_cast) if f==225
    verify_stat_stage_calm_result(:stat_stage_calm_result) if f==255
    verify_stat_stage_clamp_ai(:stat_stage_clamp_ai) if f==280
    verify_stat_stage_runtime_file(:stat_stage_runtime_file) if f==305
    complete_verification_mode if f==PMD_AC::VERIFICATION_STAT_STAGE_END_FRAME
  end

  def complete_verification_mode
    if verification_mode==:stat_stage && @stat_stage_verification_failed
      return if @verification_done[:verification_complete]
      for unit in @units;unit.verification_finish;end
      @verification_done[:verification_complete]=true
      log_event(:verify,"FAILED mode=STAT_STAGE auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v019_complete_verification_mode
  end
end
