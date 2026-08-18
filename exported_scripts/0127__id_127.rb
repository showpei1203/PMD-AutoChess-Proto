#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.20
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SUSTAIN_RECOIL_RUNTIME_FILE / USE_EXTERNAL_SUSTAIN_RECOIL_DB / VERIFICATION_SUSTAIN_END_FRAME / VERIFICATION_MODES
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
# ■ PMD AutoChess Proto v0.20
#    Canonical Recovery + Recoil Move Layer
#------------------------------------------------------------------------------
#  Base: verified v0.19 FullTestProject.
#  Adds max-HP recovery and damage-proportional recoil as thin adapters.
#==============================================================================
module PMD_AC
  SUSTAIN_RECOIL_RUNTIME_FILE="Data/PMD_AutoChess_SustainRecoil_v020_000.rvdata"
  USE_EXTERNAL_SUSTAIN_RECOIL_DB=true unless const_defined?(:USE_EXTERNAL_SUSTAIN_RECOIL_DB)
  VERIFICATION_SUSTAIN_END_FRAME=315

  module SustainRecoilDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def manifest;@data==nil ? {} : (@data[:manifest]||{});end
      def embedded_data;{:manifest=>PMD_AC::SUSTAIN_RECOIL_MANIFEST_V020,:behaviors=>PMD_AC::SUSTAIN_RECOIL_MOVE_V020};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_SUSTAIN_RECOIL_DB && FileTest.exist?(PMD_AC::SUSTAIN_RECOIL_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::SUSTAIN_RECOIL_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) &&
               c[:manifest][:schema_version]=="1.0" && c[:manifest][:new_mapped_move_count].to_i==15
              data=c;@using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil
        @data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_SUSTAIN_RECOIL_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::SUSTAIN_RECOIL_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def keys;load! unless loaded?;(@data[:behaviors]||{}).keys;end
      def behavior_count;keys.size;end
    end
  end

  class << self
    alias pmd_ac_v020_move_executable move_executable? unless method_defined?(:pmd_ac_v020_move_executable)
    alias pmd_ac_v020_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v020_move_autochess_hint)
    alias pmd_ac_v020_skill_data skill_data unless method_defined?(:pmd_ac_v020_skill_data)
    alias pmd_ac_v020_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v020_canonical_move_key_from_skill)

    def canonical_move_key_from_skill(skill_key)
      key=pmd_ac_v020_canonical_move_key_from_skill(skill_key)
      return key if key!=nil
      return nil if skill_key==nil
      text=skill_key.to_s;return nil unless text[0,3]=="mv_"
      k=text[3,text.size-3].to_sym
      SustainRecoilDB.behavior(k)==nil ? nil : k
    end
    def move_executable?(move_key)
      return true if SustainRecoilDB.behavior(move_key)!=nil
      pmd_ac_v020_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      base=pmd_ac_v020_move_autochess_hint(move_key);b=SustainRecoilDB.behavior(move_key)
      return base if b==nil
      result=base==nil ? {} : base.dup
      result[:behavior_status]=b[:behavior_status];result[:delivery]=b[:delivery]
      result[:range_px]=b[:range_px];result[:runtime_skill_key]=b[:runtime_skill_key];result
    end
    def skill_data(key)
      old=pmd_ac_v020_skill_data(key);return old if old!=nil && !old.empty?
      move_key=canonical_move_key_from_skill(key);return {} if move_key==nil
      data=SustainRecoilDB.behavior(move_key);return {} if data==nil
      result=data.dup;result[:move_type]=data[:type];result[:damage_category]=data[:category]
      result[:canonical_move_key]=move_key;result
    end
    def sustain_recoil_checksum32
      h=0
      for key in SustainRecoilDB.keys.sort{|a,b|a.to_s<=>b.to_s}
        r=SustainRecoilDB.behavior(key)
        eff=(r[:effects]||[]).collect{|e|[e[:type],e[:power],e[:ratio]].join(",")}.join(";")
        text=[key,r[:runtime_skill_key],r[:target_type],r[:delivery],r[:range_px],r[:canonical_recoil_percent],eff].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end
    def validate_sustain_recoil_db
      errors=[];skills=[]
      for key in SustainRecoilDB.keys
        r=SustainRecoilDB.behavior(key)
        errors.push("move:"+key.to_s) if move_data(key)==nil
        errors.push("skill:"+key.to_s) unless r[:runtime_skill_key]==canonical_runtime_skill_key(key)
        types=(r[:effects]||[]).collect{|e|e[:type]}
        ok=(types==[:heal_maxhp_ratio] || types==[:damage,:recoil_last_damage])
        errors.push("effects:"+key.to_s) unless ok
        skills.push(r[:runtime_skill_key])
      end
      errors.push("count") unless SustainRecoilDB.behavior_count==15
      errors.push("unique") unless skills.uniq.size==15
      errors.push("checksum") unless sustain_recoil_checksum32==SustainRecoilDB.manifest[:runtime_checksum32].to_i
      errors
    end
  end
  SustainRecoilDB.load!

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,
                      :summon,:identity,:progression,:individual,:mega,:synergy,
                      :species_db,:move_db,:move_runtime,:stat_stage,:sustain]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",
    :energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",
    :identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",
    :mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",
    :move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN"}
end

class Game_PMDChessUnit
  # Recoil is self-inflicted HP damage: no shield, no damage-link, no energy gain.
  # Unlike pay_hp_cost it may faint the user, which canonical recoil can do.
  def apply_canonical_recoil(value)
    return 0 if dead?
    amount=[value.to_i,1].max;before=@hp
    @hp-=amount;@hp=0 if @hp<0
    @last_damage=amount;@last_damage_critical=false;@damage_popup_frames=30
    log_event(:recoil,log_name+" RECOIL -"+amount.to_s+" hp="+before.to_s+"->"+@hp.to_s)
    if dead?;start_faint;else;@hurt_frames=[@hurt_frames,8].max;end
    amount
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v020_start start unless method_defined?(:pmd_ac_v020_start)
  alias pmd_ac_v020_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v020_prepare_verification_battle)
  alias pmd_ac_v020_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v020_apply_skill_effects)
  alias pmd_ac_v020_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v020_skill_cast_worthwhile)
  alias pmd_ac_v020_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v020_update_verification_script)
  alias pmd_ac_v020_log_event log_event unless method_defined?(:pmd_ac_v020_log_event)
  alias pmd_ac_v020_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v020_complete_verification_mode)

  def start
    pmd_ac_v020_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.19 Battle Verification Log","PMD AutoChess Proto v0.20 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::SustainRecoilDB.manifest
    log_event(:sustain,"LOADED new="+PMD_AC::SustainRecoilDB.behavior_count.to_s+
      " cumulative="+m[:cumulative_mapped_move_count].to_s+
      " covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+
      " source="+(PMD_AC::SustainRecoilDB.using_runtime_file? ? "rvdata":"embedded")+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v020_prepare_verification_battle
    if verification_mode==:sustain
      for u in @units;u.verification_combat_sandbox(true);end
      @sustain_snapshots={};@sustain_verification_failed=false
    end
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v020_apply_skill_effects(user,target,data,scale)
    return result if user==nil || target==nil
    for e in (data[:effects]||[])
      case e[:type]
      when :heal_maxhp_ratio
        next if target.dead?
        amount=[(target.maxhp*e[:ratio].to_f*scale.to_f).floor,1].max
        target.heal(amount);add_skill_effect(target,:heal)
      when :recoil_last_damage
        next if result.to_i<=0 || user.dead?
        amount=[(result.to_i*e[:ratio].to_f).floor,1].max
        user.apply_canonical_recoil(amount)
      end
    end
    result
  end

  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v020_skill_cast_worthwhile(unit,target,data)
    heals=(data[:effects]||[]).find_all{|e|e[:type]==:heal_maxhp_ratio}
    return true if heals.empty?
    return false if target==nil || target.dead?
    target.hp<target.maxhp
  end

  def log_event(category,message)
    if category.to_s=="verify"
      text=message.to_s
      @sustain_verification_failed=true if text.index("SUSTAIN_")==0 && text.include?(" pass=0")
    end
    pmd_ac_v020_log_event(category,message)
  end

  def verify_sustain_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::SustainRecoilDB.manifest
    pass=PMD_AC::SustainRecoilDB.behavior_count==15 && m[:previous_mapped_move_count].to_i==55 &&
         m[:cumulative_mapped_move_count].to_i==70 && m[:new_reference_covered].to_i==205 &&
         m[:cumulative_reference_covered].to_i==1605 && PMD_AC.sustain_recoil_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " new=15 cumulative=70 covered=1605/7005 coverage="+m[:cumulative_coverage_percent].to_s+"%")
    @verification_done[tag]=true
  end

  def verify_sustain_bridge(tag)
    return if @verification_done[tag]
    recover=PMD_AC.skill_data(:mv_recover);take=PMD_AC.skill_data(:mv_take_down)
    roost=PMD_AC.skill_data(:mv_roost);blitz=PMD_AC.skill_data(:mv_flare_blitz)
    old=PMD_AC.skill_data(:mv_calm_mind)
    pass=recover[:effects][0][:type]==:heal_maxhp_ratio && take[:effects][1][:type]==:recoil_last_damage &&
         old[:canonical_move_key]==:calm_mind && roost.empty? && blitz.empty? &&
         PMD_AC.move_executable?(:recover) && PMD_AC.move_executable?(:take_down) && !PMD_AC.move_executable?(:roost)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " recovery=8 recoil=7 roost=deferred flare_blitz=deferred")
    @verification_done[tag]=true
  end

  def verify_sustain_recover_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);u.verification_set_hp_percent(0.35)
    @sustain_snapshots[:recover]=[u.hp,u.maxhp]
    ok=u.verification_force_skill(:mv_recover,u)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" hp_before="+u.hp.to_s+" max="+u.maxhp.to_s)
    @verification_done[tag]=true
  end
  def verify_sustain_recover_result(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);b=@sustain_snapshots[:recover];expected=[b[0]+(b[1]*0.5).floor,b[1]].min
    pass=u.hp==expected
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" hp="+b[0].to_s+"->"+u.hp.to_s+" expected="+expected.to_s)
    @verification_done[tag]=true
  end

  def verify_sustain_recoil_cast(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata)
    u.deploy_to_cell(1,1);t.deploy_to_cell(2,1);t.deploy_to_pixel(u.pixel_x+48.0,u.pixel_y)
    @sustain_snapshots[:recoil]=[u.hp,t.hp]
    ok=u.verification_force_skill(:mv_take_down,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" user_before="+u.hp.to_s+" target_before="+t.hp.to_s+" ratio=0.25")
    @verification_done[tag]=true
  end
  def verify_sustain_recoil_result(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata);b=@sustain_snapshots[:recoil]
    dealt=b[1]-t.hp;recoil=b[0]-u.hp;expected=[(dealt*0.25).floor,1].max
    pass=dealt>0 && recoil==expected
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" dealt="+dealt.to_s+" recoil="+recoil.to_s+" expected="+expected.to_s)
    @verification_done[tag]=true
  end

  def verify_sustain_head_smash_data(tag)
    return if @verification_done[tag]
    d=PMD_AC.skill_data(:mv_head_smash);e=(d[:effects]||[])[1]
    pass=d[:canonical_recoil_percent].to_i==50 && e!=nil && (e[:ratio].to_f-0.5).abs<0.0001
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" recoil_percent="+d[:canonical_recoil_percent].to_s)
    @verification_done[tag]=true
  end

  def verify_sustain_ai(tag)
    return if @verification_done[tag]
    u=verification_unit(:ally,:bulbasaur);data=PMD_AC.skill_data(:mv_recover)
    u.verification_set_hp_percent(1.0);blocked=!skill_cast_worthwhile?(u,u,data)
    u.verification_set_hp_percent(0.8);allowed=skill_cast_worthwhile?(u,u,data)
    pass=blocked&&allowed
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" full_hp_block="+(blocked ? "1":"0")+" injured_allow="+(allowed ? "1":"0"))
    @verification_done[tag]=true
  end

  def verify_sustain_runtime_file(tag)
    return if @verification_done[tag]
    pass=FileTest.exist?(PMD_AC::SUSTAIN_RECOIL_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" runtime_file="+(pass ? "present":"missing")+
      " source="+(PMD_AC::SustainRecoilDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  def update_verification_script
    pmd_ac_v020_update_verification_script
    return unless verification_mode==:sustain
    f=@verification_frame
    verify_sustain_manifest(:sustain_manifest) if f==4
    verify_sustain_bridge(:sustain_bridge) if f==30
    verify_sustain_recover_cast(:sustain_recover_cast) if f==60
    verify_sustain_recover_result(:sustain_recover_result) if f==95
    verify_sustain_recoil_cast(:sustain_recoil_cast) if f==125
    verify_sustain_recoil_result(:sustain_recoil_result) if f==165
    verify_sustain_head_smash_data(:sustain_head_smash_data) if f==200
    verify_sustain_ai(:sustain_ai) if f==235
    verify_sustain_runtime_file(:sustain_runtime_file) if f==275
    complete_verification_mode if f==PMD_AC::VERIFICATION_SUSTAIN_END_FRAME
  end

  def complete_verification_mode
    if verification_mode==:sustain && @sustain_verification_failed
      return if @verification_done[:verification_complete]
      for unit in @units;unit.verification_finish;end
      @verification_done[:verification_complete]=true
      log_event(:verify,"FAILED mode=SUSTAIN auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v020_complete_verification_mode
  end
end
