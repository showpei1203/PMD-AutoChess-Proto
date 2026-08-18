#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.17
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - MOVE_DB_RUNTIME_FILE / USE_EXTERNAL_MOVE_DB / VERIFICATION_MOVE_DB_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / manifest
# - move_count / embedded_data / load! / move
# - keys / move_data / move_executable? / move_flags
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.17
#    Move Database Foundation
#------------------------------------------------------------------------------
#  Base: verified v0.16.1 full test project.
#  Does NOT rewrite v0.15 combat Core or v0.16.1 Species/Evolution layer.
#  Canonical moves are DATA-ONLY; Runtime does not auto-execute them.
#==============================================================================
module PMD_AC
  MOVE_DB_RUNTIME_FILE = "Data/PMD_AutoChess_Moves_v017_000.rvdata"
  USE_EXTERNAL_MOVE_DB = true unless const_defined?(:USE_EXTERNAL_MOVE_DB)
  VERIFICATION_MOVE_DB_END_FRAME = 285

  module MoveDB
    @loaded=false
    @using_runtime_file=false
    @load_error=nil
    @data=nil
    class << self
      def loaded?; @loaded ? true : false; end
      def using_runtime_file?; @using_runtime_file ? true : false; end
      def load_error; @load_error; end
      def manifest; @data==nil ? {} : (@data[:manifest] || {}); end
      def move_count; @data==nil ? 0 : (@data[:moves] || {}).size; end
      def embedded_data
        {:manifest=>PMD_AC::MOVE_DB_MANIFEST_V017,:moves=>PMD_AC::MOVE_DB_V017}
      end
      def load!
        return true if @loaded
        @load_error=nil; @using_runtime_file=false; data=nil
        if PMD_AC::USE_EXTERNAL_MOVE_DB && FileTest.exist?(PMD_AC::MOVE_DB_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::MOVE_DB_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:moves].is_a?(Hash) &&
               c[:manifest][:schema_version]=="1.0" && c[:manifest][:move_count].to_i==559
              data=c; @using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil
        @data=data; @loaded=true
        if PMD_AC::USE_EXTERNAL_MOVE_DB && !@using_runtime_file
          begin
            save_data(@data,PMD_AC::MOVE_DB_RUNTIME_FILE)
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        true
      end
      def move(key)
        load! unless loaded?
        (@data[:moves] || {})[key]
      end
      def keys
        load! unless loaded?
        (@data[:moves] || {}).keys
      end
    end
  end

  class << self
    def move_data(move_key); MoveDB.move(move_key); end
    def move_executable?(move_key)
      d=MoveDB.move(move_key); d!=nil && d[:runtime_executable] ? true : false
    end
    def move_flags(move_key)
      d=MoveDB.move(move_key); d==nil ? [] : (d[:flags] || [])
    end
    def move_autochess_hint(move_key)
      d=MoveDB.move(move_key); return nil if d==nil
      {:targeting=>d[:targeting_hint],:delivery=>d[:delivery_hint],
       :range=>d[:range_hint],:energy_cost=>d[:energy_cost_hint],
       :power=>d[:autochess_power_hint],:behavior_status=>d[:behavior_status]}
    end
    def move_runtime_checksum32
      h=0
      list=MOVE_DB_V017.values.sort{|a,b|a[:move_id].to_i<=>b[:move_id].to_i}
      for r in list
        text=[r[:move_id],r[:move_key],r[:type],r[:category],r[:canonical_power],
              r[:accuracy],r[:priority],r[:target],(r[:flags]||[]).join(",")].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end
    def validate_move_db
      errors=[]; ids=[]; keys=[]
      valid_types=[:normal,:fire,:water,:electric,:grass,:ice,:fighting,:poison,:ground,:flying,:psychic,:bug,:rock,:ghost,:dragon,:dark,:steel,:fairy]
      valid_cat=[:physical,:special,:status]
      for key in MoveDB.keys
        r=MoveDB.move(key); keys.push(key); ids.push(r[:move_id].to_i)
        errors.push("key:"+key.to_s) unless r[:move_key]==key
        errors.push("id:"+key.to_s) unless r[:move_id].to_i>=1 && r[:move_id].to_i<=559
        errors.push("type:"+key.to_s) unless valid_types.include?(r[:type])
        errors.push("cat:"+key.to_s) unless valid_cat.include?(r[:category])
        errors.push("name:"+key.to_s) if r[:name].to_s.empty? || r[:name_en].to_s.empty?
        errors.push("exec:"+key.to_s) if r[:runtime_executable]
      end
      errors.push("count") unless keys.size==559
      errors.push("id_continuity") unless ids.sort==(1..559).to_a
      errors.push("key_unique") unless keys.uniq.size==559
      errors.push("checksum") unless move_runtime_checksum32==MoveDB.manifest[:runtime_checksum32].to_i
      errors
    end
  end

  MoveDB.load!
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,
                      :summon,:identity,:progression,:individual,:mega,:synergy,
                      :species_db,:move_db]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",
    :hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",
    :summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",
    :individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",
    :species_db=>"SPECIES_DB",:move_db=>"MOVE_DB"}
end

class Scene_PMD_AutoChess
  alias pmd_ac_v017_start start unless method_defined?(:pmd_ac_v017_start)
  def start
    pmd_ac_v017_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.16.1 Battle Verification Log",
                  "PMD AutoChess Proto v0.17 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    refresh_header
    m=PMD_AC::MoveDB.manifest
    log_event(:move_db,"LOADED count="+PMD_AC::MoveDB.move_count.to_s+
      " source="+(PMD_AC::MoveDB.using_runtime_file? ? "rvdata":"embedded")+
      " schema="+m[:schema_version].to_s+" content="+m[:content_version].to_s+
      " ruleset="+m[:stats_ruleset].to_s+" checksum32="+m[:runtime_checksum32].to_s)
    log_event(:move_db,"LOAD_WARNING "+PMD_AC::MoveDB.load_error.to_s) if PMD_AC::MoveDB.load_error
  end

  def verify_move_db_manifest(tag)
    return if @verification_done[tag]
    m=PMD_AC::MoveDB.manifest
    pass=PMD_AC::MoveDB.move_count==559 && m[:move_id_min].to_i==1 &&
         m[:move_id_max].to_i==559 && m[:learnset_reference_count].to_i==7005 &&
         m[:unresolved_learnset_moves].to_i==0 &&
         PMD_AC.move_runtime_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " count="+PMD_AC::MoveDB.move_count.to_s+
      " learnset_refs="+m[:learnset_reference_count].to_s+
      " unique_refs="+m[:learnset_unique_move_count].to_s+
      " checksum32="+m[:runtime_checksum32].to_s)
    @verification_done[tag]=true
  end

  def verify_move_db_integrity(tag)
    return if @verification_done[tag]
    errors=PMD_AC.validate_move_db
    log_event(:verify,tag.to_s.upcase+" pass="+(errors.empty? ? "1":"0")+
      " errors=["+errors[0,8].join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_move_db_golden(tag)
    return if @verification_done[tag]
    t=PMD_AC.move_data(:tackle); f=PMD_AC.move_data(:flamethrower)
    c=PMD_AC.move_data(:charm); fs=PMD_AC.move_data(:future_sight)
    pass=t && t[:type]==:normal && t[:category]==:physical && t[:canonical_power].to_i==50 && t[:accuracy].to_i==100 &&
         f && f[:type]==:fire && f[:category]==:special && f[:canonical_power].to_i==95 &&
         c && c[:type]==:normal && c[:category]==:status &&
         fs && fs[:canonical_power].to_i==100 && fs[:accuracy].to_i==100
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " tackle="+(t ? t[:canonical_power].to_s : "nil")+
      " flamethrower="+(f ? f[:canonical_power].to_s : "nil")+
      " charm_type="+(c ? c[:type].to_s : "nil")+
      " future_sight="+(fs ? fs[:canonical_power].to_s : "nil"))
    @verification_done[tag]=true
  end

  def verify_move_db_flags(tag)
    return if @verification_done[tag]
    tackle=PMD_AC.move_data(:tackle); aura=PMD_AC.move_data(:aura_sphere)
    voice=PMD_AC.move_data(:hyper_voice); recover=PMD_AC.move_data(:recover)
    pass=tackle[:contact] && aura[:pulse] && voice[:sound] && PMD_AC.move_flags(:recover).include?(:heal)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " tackle_contact="+(tackle[:contact] ? "1":"0")+
      " aura_pulse="+(aura[:pulse] ? "1":"0")+
      " hyper_voice_sound="+(voice[:sound] ? "1":"0")+
      " recover_heal="+(PMD_AC.move_flags(:recover).include?(:heal) ? "1":"0"))
    @verification_done[tag]=true
  end

  def verify_move_db_learnset_links(tag)
    return if @verification_done[tag]
    refs=0; unique={}; missing=[]
    for skey in PMD_AC::SPECIES_DB_V016.keys
      r=PMD_AC::SPECIES_DB_V016[skey]
      for e in (r[:learnset] || [])
        refs+=1; unique[e[:move]]=true
        missing.push(e[:move]) if PMD_AC.move_data(e[:move])==nil
      end
    end
    pass=refs==7005 && unique.keys.size==512 && missing.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " refs="+refs.to_s+" unique="+unique.keys.size.to_s+
      " unresolved="+missing.uniq.size.to_s)
    @verification_done[tag]=true
  end

  def verify_move_db_hints(tag)
    return if @verification_done[tag]
    tackle=PMD_AC.move_autochess_hint(:tackle)
    aura=PMD_AC.move_autochess_hint(:aura_sphere)
    growl=PMD_AC.move_autochess_hint(:growl)
    recover=PMD_AC.move_autochess_hint(:recover)
    pass=tackle && tackle[:delivery]==:melee_contact && tackle[:range].to_i==1 &&
         aura && aura[:delivery]==:pulse_projectile &&
         growl && growl[:behavior_status]==:data_only &&
         recover && recover[:energy_cost].to_i>0
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " tackle="+tackle[:delivery].to_s+"/"+tackle[:energy_cost].to_s+
      " aura="+aura[:delivery].to_s+"/"+aura[:energy_cost].to_s+
      " recover="+recover[:delivery].to_s+"/"+recover[:energy_cost].to_s)
    @verification_done[tag]=true
  end

  def verify_move_db_legacy_isolation(tag)
    return if @verification_done[tag]
    keys=[:vine_drain,:flame_burst,:guardian_tide,:web_pierce,:rending_assault,
          :chain_lightning,:frost_beam,:water_lance,:fire_sweep,:tidal_push,
          :dash_strike,:healing_field,:ricochet_seed]
    intact=true
    for k in keys
      intact=false if PMD_AC::SKILL_DATA[k]==nil
    end
    # :flame_burst is also an official Gen5 move key. Namespaces must remain
    # separate: canonical MoveDB data must never overwrite legacy SKILL_DATA.
    collision_ok=PMD_AC.move_data(:flame_burst)!=nil &&
                 PMD_AC::SKILL_DATA[:flame_burst][:delivery]==:aoe &&
                 PMD_AC.move_data(:vine_drain)==nil &&
                 PMD_AC.move_data(:chain_lightning)==nil
    canonical_exec=0
    for k in PMD_AC::MOVE_DB_V017.keys
      canonical_exec+=1 if PMD_AC.move_executable?(k)
    end
    pass=intact && collision_ok && canonical_exec==0 && PMD_AC::SKILL_DATA[:vine_drain][:delivery]==:projectile &&
         PMD_AC::SKILL_DATA[:chain_lightning][:delivery]==:chain
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " legacy_custom="+keys.size.to_s+" canonical_executable="+canonical_exec.to_s+
      " flame_burst_namespace="+(collision_ok ? "isolated":"broken")+
      " vine="+PMD_AC::SKILL_DATA[:vine_drain][:delivery].to_s+
      " chain="+PMD_AC::SKILL_DATA[:chain_lightning][:delivery].to_s)
    @verification_done[tag]=true
  end

  def verify_move_db_runtime_file(tag)
    return if @verification_done[tag]
    exists=FileTest.exist?(PMD_AC::MOVE_DB_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(exists ? "1":"0")+
      " runtime_file="+(exists ? "present":"missing")+
      " source="+(PMD_AC::MoveDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  alias pmd_ac_v017_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v017_update_verification_script)
  def update_verification_script
    if verification_mode != :move_db
      pmd_ac_v017_update_verification_script
      return
    end
    @verification_frame += 1
    verify_move_db_manifest(:move_db_manifest) if @verification_frame>=4
    verify_move_db_integrity(:move_db_integrity) if @verification_frame>=35
    verify_move_db_golden(:move_db_golden) if @verification_frame>=75
    verify_move_db_flags(:move_db_flags) if @verification_frame>=110
    verify_move_db_learnset_links(:move_db_learnset_links) if @verification_frame>=145
    verify_move_db_hints(:move_db_hints) if @verification_frame>=185
    verify_move_db_legacy_isolation(:move_db_legacy_isolation) if @verification_frame>=225
    verify_move_db_runtime_file(:move_db_runtime_file) if @verification_frame>=255
    complete_verification_mode if @verification_frame>=PMD_AC::VERIFICATION_MOVE_DB_END_FRAME
  end
end
