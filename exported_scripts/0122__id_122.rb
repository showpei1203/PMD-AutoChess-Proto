#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.18
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_BEHAVIOR_RUNTIME_FILE / USE_EXTERNAL_MOVE_BEHAVIOR_DB / VERIFICATION_MOVE_RUNTIME_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / manifest
# - behavior_count / embedded_data / load! / behavior
# - keys / canonical_runtime_skill_key / canonical_move_key_from_skill / move_behavior
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.18
#    Canonical Move Runtime Bridge - Tier 1
#------------------------------------------------------------------------------
#  Base: verified v0.17 FullTestProject.
#  No rewrite of v0.15 combat Core / v0.16.1 SpeciesDB / v0.17 MoveDB.
#  Canonical runtime skills live in :mv_* namespace.
#==============================================================================
module PMD_AC
  MOVE_BEHAVIOR_RUNTIME_FILE = "Data/PMD_AutoChess_MoveBehaviors_v018_000.rvdata"
  USE_EXTERNAL_MOVE_BEHAVIOR_DB = true unless const_defined?(:USE_EXTERNAL_MOVE_BEHAVIOR_DB)
  VERIFICATION_MOVE_RUNTIME_END_FRAME = 390

  module MoveBehaviorDB
    @loaded=false
    @using_runtime_file=false
    @load_error=nil
    @data=nil
    class << self
      def loaded?; @loaded ? true : false; end
      def using_runtime_file?; @using_runtime_file ? true : false; end
      def load_error; @load_error; end
      def manifest; @data==nil ? {} : (@data[:manifest] || {}); end
      def behavior_count; @data==nil ? 0 : (@data[:behaviors] || {}).size; end
      def embedded_data
        {:manifest=>PMD_AC::MOVE_BEHAVIOR_MANIFEST_V018,
         :behaviors=>PMD_AC::MOVE_BEHAVIOR_V018}
      end
      def load!
        return true if @loaded
        @load_error=nil; @using_runtime_file=false; data=nil
        if PMD_AC::USE_EXTERNAL_MOVE_BEHAVIOR_DB &&
           FileTest.exist?(PMD_AC::MOVE_BEHAVIOR_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::MOVE_BEHAVIOR_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) &&
               c[:manifest][:schema_version]=="1.0" &&
               c[:manifest][:mapped_move_count].to_i==39
              data=c; @using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil
        @data=data; @loaded=true
        if PMD_AC::USE_EXTERNAL_MOVE_BEHAVIOR_DB && !@using_runtime_file
          begin
            save_data(@data,PMD_AC::MOVE_BEHAVIOR_RUNTIME_FILE)
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        true
      end
      def behavior(move_key)
        load! unless loaded?
        (@data[:behaviors] || {})[move_key]
      end
      def keys
        load! unless loaded?
        (@data[:behaviors] || {}).keys
      end
    end
  end

  class << self
    alias pmd_ac_v018_move_executable move_executable? unless method_defined?(:pmd_ac_v018_move_executable)
    alias pmd_ac_v018_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v018_move_autochess_hint)
    alias pmd_ac_v018_skill_data skill_data unless method_defined?(:pmd_ac_v018_skill_data)

    def canonical_runtime_skill_key(move_key)
      return ("mv_"+move_key.to_s).to_sym
    end

    def canonical_move_key_from_skill(skill_key)
      return nil if skill_key == nil
      text=skill_key.to_s
      return nil unless text[0,3]=="mv_"
      key=text[3,text.size-3].to_sym
      return MoveBehaviorDB.behavior(key)==nil ? nil : key
    end

    def move_behavior(move_key)
      MoveBehaviorDB.behavior(move_key)
    end

    def move_runtime_mapped?(move_key)
      MoveBehaviorDB.behavior(move_key)!=nil
    end

    def move_executable?(move_key)
      return move_runtime_mapped?(move_key)
    end

    def move_autochess_hint(move_key)
      base=pmd_ac_v018_move_autochess_hint(move_key)
      behavior=MoveBehaviorDB.behavior(move_key)
      return base if behavior==nil
      result=base==nil ? {} : base.dup
      result[:behavior_status]=behavior[:behavior_status]
      result[:delivery]=behavior[:delivery]
      result[:range_px]=behavior[:range_px]
      result[:runtime_skill_key]=behavior[:runtime_skill_key]
      return result
    end

    # Legacy custom skills always win their original namespace.
    # Canonical moves must explicitly use :mv_<move_key>.
    def skill_data(key)
      old=pmd_ac_v018_skill_data(key)
      return old if old!=nil && !old.empty?
      move_key=canonical_move_key_from_skill(key)
      return {} if move_key==nil
      data=MoveBehaviorDB.behavior(move_key)
      return {} if data==nil
      result=data.dup
      result[:move_type]=data[:type]
      result[:damage_category]=data[:category]
      result[:canonical_move_key]=move_key
      return result
    end

    def move_behavior_checksum32
      h=0
      list=MoveBehaviorDB.keys.sort{|a,b|a.to_s<=>b.to_s}
      for key in list
        r=MoveBehaviorDB.behavior(key)
        effect_text=(r[:effects] || []).collect{|e|
          [e[:type],e[:power],e[:ratio],e[:object],e[:hp_cost_ratio]].join(",")
        }.join(";")
        text=[key,r[:runtime_skill_key],r[:type],r[:category],r[:delivery],
              r[:projectile_tracking],r[:range_px],effect_text].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_move_behavior_db
      errors=[]; skill_keys=[]
      for key in MoveBehaviorDB.keys
        r=MoveBehaviorDB.behavior(key)
        errors.push("move:"+key.to_s) if move_data(key)==nil
        errors.push("skill:"+key.to_s) unless r[:runtime_skill_key]==canonical_runtime_skill_key(key)
        errors.push("effects:"+key.to_s) if (r[:effects] || []).empty?
        errors.push("delivery:"+key.to_s) unless [:instant,:projectile,:aoe].include?(r[:delivery])
        errors.push("range:"+key.to_s) if r[:range_px].to_f<0.0
        skill_keys.push(r[:runtime_skill_key])
      end
      errors.push("count") unless MoveBehaviorDB.behavior_count==39
      errors.push("skill_unique") unless skill_keys.uniq.size==39
      errors.push("checksum") unless move_behavior_checksum32==MoveBehaviorDB.manifest[:runtime_checksum32].to_i
      errors
    end
  end

  MoveBehaviorDB.load!
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,
                      :summon,:identity,:progression,:individual,:mega,:synergy,
                      :species_db,:move_db,:move_runtime]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",
    :hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",
    :summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",
    :individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",
    :species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME"}
end

class Game_PMDChessUnit
  alias pmd_ac_v018_skill_in_range skill_in_range? unless method_defined?(:pmd_ac_v018_skill_in_range)
  alias pmd_ac_v018_melee melee? unless method_defined?(:pmd_ac_v018_melee)

  # Canonical skills own their runtime reach. Actor/unit profile range is still
  # the basic-attack/movement profile, not Pokémon move range.
  def skill_in_range?(other)
    return false if other==nil || other.dead?
    data=skill_data
    if data!=nil && data[:canonical_move_key]!=nil && data[:range_px]!=nil
      return true if data[:global_range]
      distance=distance_to(other).to_f
      return distance <= data[:range_px].to_f + other.collision_radius
    end
    pmd_ac_v018_skill_in_range(other)
  end

  # During a canonical contact skill, ranged species still use the existing
  # melee lunge/range recheck. Outside that action their original profile is unchanged.
  def melee?
    if @action==:skill
      data=skill_data
      return true if data!=nil && data[:force_contact_range]
    end
    pmd_ac_v018_melee
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v018_start start unless method_defined?(:pmd_ac_v018_start)
  alias pmd_ac_v018_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v018_prepare_verification_battle)
  alias pmd_ac_v018_projectile_style projectile_style unless method_defined?(:pmd_ac_v018_projectile_style)
  alias pmd_ac_v018_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v018_update_verification_script)

  def start
    pmd_ac_v018_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.17 Battle Verification Log",
                  "PMD AutoChess Proto v0.18 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    refresh_header
    m=PMD_AC::MoveBehaviorDB.manifest
    log_event(:move_runtime,"LOADED mapped="+PMD_AC::MoveBehaviorDB.behavior_count.to_s+
      " source="+(PMD_AC::MoveBehaviorDB.using_runtime_file? ? "rvdata":"embedded")+
      " content="+m[:content_version].to_s+
      " covered="+m[:learnset_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+
      " checksum32="+m[:runtime_checksum32].to_s)
    log_event(:move_runtime,"LOAD_WARNING "+PMD_AC::MoveBehaviorDB.load_error.to_s) if
      PMD_AC::MoveBehaviorDB.load_error
  end

  # Move type can choose visual style without touching PMD combat geometry.
  def projectile_style(user,kind,effect_type)
    data=PMD_AC.skill_data(effect_type)
    if data!=nil && data[:canonical_move_key]!=nil && data[:vfx_style]!=nil
      return data[:vfx_style]
    end
    pmd_ac_v018_projectile_style(user,kind,effect_type)
  end

  def prepare_verification_battle
    pmd_ac_v018_prepare_verification_battle
    if verification_mode==:move_runtime
      for unit in @units
        unit.verification_combat_sandbox(true)
      end
      @move_runtime_snapshots={}
    end
  end

  # v0.17 expected zero executable canonical moves. In v0.18 that expectation
  # legitimately changes to 39 while legacy collision isolation must still pass.
  def verify_move_db_legacy_isolation(tag)
    return if @verification_done[tag]
    keys=[:vine_drain,:flame_burst,:guardian_tide,:web_pierce,:rending_assault,
          :chain_lightning,:frost_beam,:water_lance,:fire_sweep,:tidal_push,
          :dash_strike,:healing_field,:ricochet_seed]
    intact=true
    for k in keys
      intact=false if PMD_AC::SKILL_DATA[k]==nil
    end
    mapped=PMD_AC::MoveBehaviorDB.behavior_count
    collision_ok=PMD_AC.move_data(:flame_burst)!=nil &&
                 PMD_AC::SKILL_DATA[:flame_burst][:delivery]==:aoe &&
                 PMD_AC.skill_data(:flame_burst)[:delivery]==:aoe &&
                 PMD_AC.skill_data(:mv_tackle)[:canonical_move_key]==:tackle
    pass=intact && collision_ok && mapped==39 &&
         PMD_AC::SKILL_DATA[:vine_drain][:delivery]==:projectile &&
         PMD_AC::SKILL_DATA[:chain_lightning][:delivery]==:chain
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " legacy_custom="+keys.size.to_s+" canonical_mapped="+mapped.to_s+
      " namespace="+(collision_ok ? "isolated":"broken"))
    @verification_done[tag]=true
  end

  def verify_move_runtime_manifest(tag)
    return if @verification_done[tag]
    m=PMD_AC::MoveBehaviorDB.manifest
    pass=PMD_AC::MoveBehaviorDB.behavior_count==39 &&
         m[:learnset_reference_total].to_i==7005 &&
         m[:learnset_reference_covered].to_i==816 &&
         PMD_AC.move_behavior_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " mapped="+PMD_AC::MoveBehaviorDB.behavior_count.to_s+
      " covered="+m[:learnset_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+
      " coverage="+m[:coverage_percent].to_s+"% checksum32="+m[:runtime_checksum32].to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_integrity(tag)
    return if @verification_done[tag]
    errors=PMD_AC.validate_move_behavior_db
    log_event(:verify,tag.to_s.upcase+" pass="+(errors.empty? ? "1":"0")+
      " errors=["+errors[0,8].join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_move_runtime_namespace(tag)
    return if @verification_done[tag]
    legacy=PMD_AC.skill_data(:flame_burst)
    canon=PMD_AC.skill_data(:mv_tackle)
    missing=PMD_AC.skill_data(:mv_flame_burst)
    pass=legacy[:delivery]==:aoe && canon[:canonical_move_key]==:tackle &&
         canon[:effects][0][:power].to_i==50 && missing.empty? &&
         PMD_AC.canonical_move_key_from_skill(:mv_tackle)==:tackle
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " legacy_flame="+legacy[:delivery].to_s+
      " mv_tackle="+canon[:canonical_move_key].to_s+
      " mv_flame_burst="+(missing.empty? ? "unmapped":"collision"))
    @verification_done[tag]=true
  end

  def verify_move_runtime_tags(tag)
    return if @verification_done[tag]
    tackle=PMD_AC.skill_data(:mv_tackle)
    aura=PMD_AC.skill_data(:mv_aura_sphere)
    pulse=PMD_AC.skill_data(:mv_dragon_pulse)
    voice=PMD_AC.skill_data(:mv_hyper_voice)
    pass=tackle[:contact] && tackle[:force_contact_range] &&
         aura[:pulse] && aura[:projectile_tracking]==:perfect &&
         pulse[:pulse] && voice[:sound] && voice[:delivery]==:aoe
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " contact="+(tackle[:contact] ? "1":"0")+
      " aura_tracking="+aura[:projectile_tracking].to_s+
      " pulse="+(pulse[:pulse] ? "1":"0")+
      " sound="+(voice[:sound] ? "1":"0"))
    @verification_done[tag]=true
  end

  def verify_move_runtime_tackle_cast(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:bulbasaur)
    target=verification_unit(:enemy,:rattata)
    caster.deploy_to_cell(1,1); target.deploy_to_cell(2,1)
    @move_runtime_snapshots[:tackle_hp]=target.hp
    ok=caster.verification_force_skill(:mv_tackle,target)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " skill="+caster.skill_name.to_s+" before="+target.hp.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_tackle_result(tag)
    return if @verification_done[tag]
    target=verification_unit(:enemy,:rattata)
    before=@move_runtime_snapshots[:tackle_hp].to_i
    pass=before>0 && target.hp<before
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " before="+before.to_s+" after="+target.hp.to_s+
      " damage="+(before-target.hp).to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_water_cast(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:squirtle)
    target=verification_unit(:enemy,:caterpie)
    caster.deploy_to_cell(1,3); target.deploy_to_cell(4,3)
    @move_runtime_snapshots[:water_hp]=target.hp
    ok=caster.verification_force_skill(:mv_water_gun,target)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " tracking="+PMD_AC.skill_data(:mv_water_gun)[:projectile_tracking].to_s+
      " range="+PMD_AC.skill_data(:mv_water_gun)[:range_px].to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_water_result(tag)
    return if @verification_done[tag]
    target=verification_unit(:enemy,:caterpie)
    before=@move_runtime_snapshots[:water_hp].to_i
    pass=before>0 && target.hp<before
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " before="+before.to_s+" after="+target.hp.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_drain_cast(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:bulbasaur)
    target=verification_unit(:enemy,:rattata)
    caster.deploy_to_cell(1,2); target.deploy_to_cell(3,2)
    caster.verification_set_hp_percent(0.45)
    @move_runtime_snapshots[:drain_user]=caster.hp
    @move_runtime_snapshots[:drain_target]=target.hp
    ok=caster.verification_force_skill(:mv_giga_drain,target)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " user_before="+caster.hp.to_s+" target_before="+target.hp.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_drain_result(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:bulbasaur)
    target=verification_unit(:enemy,:rattata)
    ub=@move_runtime_snapshots[:drain_user].to_i
    tb=@move_runtime_snapshots[:drain_target].to_i
    pass=caster.hp>ub && target.hp<tb
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " user="+ub.to_s+"->"+caster.hp.to_s+
      " target="+tb.to_s+"->"+target.hp.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_area_cast(tag)
    return if @verification_done[tag]
    caster=verification_unit(:enemy,:pikachu)
    target=verification_unit(:ally,:charmander)
    caster.deploy_to_cell(4,2); target.deploy_to_cell(1,2)
    @move_runtime_snapshots[:area_hps]=living_units(:ally).collect{|u|[u.id,u.hp]}
    ok=caster.verification_force_skill(:mv_hyper_voice,target)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " targets_before="+@move_runtime_snapshots[:area_hps].size.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_area_result(tag)
    return if @verification_done[tag]
    before={}
    for pair in (@move_runtime_snapshots[:area_hps] || [])
      before[pair[0]]=pair[1]
    end
    hit=[]
    for u in living_units(:ally)
      hit.push(u.log_name) if before[u.id]!=nil && u.hp<before[u.id]
    end
    pass=hit.size==3
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " hit=["+hit.join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_move_runtime_substitute_cast(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:squirtle)
    @move_runtime_snapshots[:sub_hp]=caster.hp
    @move_runtime_snapshots[:sub_count]=@battle_objects==nil ? 0 : @battle_objects.size
    ok=caster.verification_force_skill(:mv_substitute,caster)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " hp_before="+caster.hp.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_substitute_result(tag)
    return if @verification_done[tag]
    caster=verification_unit(:ally,:squirtle)
    before_hp=@move_runtime_snapshots[:sub_hp].to_i
    before_count=@move_runtime_snapshots[:sub_count].to_i
    subs=[]
    for obj in (@battle_objects || [])
      subs.push(obj) if obj.kind==:substitute && !obj.expired?
    end
    pass=caster.hp<before_hp && (@battle_objects || []).size>before_count && !subs.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " hp="+before_hp.to_s+"->"+caster.hp.to_s+
      " substitutes="+subs.size.to_s)
    @verification_done[tag]=true
  end

  def verify_move_runtime_runtime_file(tag)
    return if @verification_done[tag]
    exists=FileTest.exist?(PMD_AC::MOVE_BEHAVIOR_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(exists ? "1":"0")+
      " runtime_file="+(exists ? "present":"missing")+
      " source="+(PMD_AC::MoveBehaviorDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  def update_verification_script
    if verification_mode!=:move_runtime
      pmd_ac_v018_update_verification_script
      return
    end
    @verification_frame += 1
    verify_move_runtime_manifest(:move_runtime_manifest) if @verification_frame>=4
    verify_move_runtime_integrity(:move_runtime_integrity) if @verification_frame>=25
    verify_move_runtime_namespace(:move_runtime_namespace) if @verification_frame>=45
    verify_move_runtime_tags(:move_runtime_tags) if @verification_frame>=65

    verify_move_runtime_tackle_cast(:move_runtime_tackle_cast) if @verification_frame>=85
    verify_move_runtime_tackle_result(:move_runtime_tackle_result) if @verification_frame>=120

    verify_move_runtime_water_cast(:move_runtime_water_cast) if @verification_frame>=135
    verify_move_runtime_water_result(:move_runtime_water_result) if @verification_frame>=180

    verify_move_runtime_drain_cast(:move_runtime_drain_cast) if @verification_frame>=195
    verify_move_runtime_drain_result(:move_runtime_drain_result) if @verification_frame>=245

    verify_move_runtime_area_cast(:move_runtime_area_cast) if @verification_frame>=255
    verify_move_runtime_area_result(:move_runtime_area_result) if @verification_frame>=315

    verify_move_runtime_substitute_cast(:move_runtime_substitute_cast) if @verification_frame>=325
    verify_move_runtime_substitute_result(:move_runtime_substitute_result) if @verification_frame>=365

    verify_move_runtime_runtime_file(:move_runtime_runtime_file) if @verification_frame>=375
    complete_verification_mode if @verification_frame>=PMD_AC::VERIFICATION_MOVE_RUNTIME_END_FRAME
  end
end
