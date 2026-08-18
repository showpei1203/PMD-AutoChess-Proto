#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.16.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SPECIES_DB_RUNTIME_FILE / USE_EXTERNAL_SPECIES_DB / VERIFICATION_SPECIES_DB_END_FRAME / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / manifest
# - species_count / line_count / form_count / embedded_data
# - load! / species / line / form
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.16.1
#    Pokémon Species Data Layer / Database Expansion
#------------------------------------------------------------------------------
#  v0.15 is the only base. This extension does NOT rebuild combat Core.
#  It hydrates the existing legacy registries from a generated 0001-0494 layer,
#  adds explicit form_kind semantics, deterministic evolution-rule selection,
#  complete growth-group EXP curves, and SPECIES_DB Verification.
#==============================================================================
module PMD_AC
  SPECIES_DB_RUNTIME_FILE = "Data/PMD_AutoChess_Species_v0161_000.rvdata"
  USE_EXTERNAL_SPECIES_DB = true unless const_defined?(:USE_EXTERNAL_SPECIES_DB)
  VERIFICATION_SPECIES_DB_END_FRAME = 330

  module SpeciesDB
    @loaded = false
    @using_runtime_file = false
    @load_error = nil
    @data = nil

    class << self
      def loaded?; @loaded ? true : false; end
      def using_runtime_file?; @using_runtime_file ? true : false; end
      def load_error; @load_error; end
      def manifest; @data == nil ? {} : (@data[:manifest] || {}); end
      def species_count; @data == nil ? 0 : (@data[:species] || {}).size; end
      def line_count; @data == nil ? 0 : (@data[:lines] || {}).size; end
      def form_count
        return 0 if @data == nil
        total = 0
        for key in (@data[:forms] || {}).keys
          total += (@data[:forms][key] || {}).size
        end
        total
      end

      def embedded_data
        {:manifest=>PMD_AC::SPECIES_DB_MANIFEST_V016,
         :species=>PMD_AC::SPECIES_DB_V016,
         :lines=>PMD_AC::EVOLUTION_LINES_V016,
         :forms=>PMD_AC::FORMS_DB_V016}
      end

      def load!
        return true if @loaded
        @load_error = nil
        @using_runtime_file = false
        data = nil
        if PMD_AC::USE_EXTERNAL_SPECIES_DB &&
           FileTest.exist?(PMD_AC::SPECIES_DB_RUNTIME_FILE)
          begin
            candidate = load_data(PMD_AC::SPECIES_DB_RUNTIME_FILE)
            if candidate.is_a?(Hash) && candidate[:manifest] &&
               candidate[:manifest][:schema_version] == "1.0" &&
               candidate[:species].is_a?(Hash)
              data = candidate
              @using_runtime_file = true
            end
          rescue => e
            @load_error = e.class.to_s + ":" + e.message.to_s
          end
        end
        data = embedded_data if data == nil
        @data = data
        @loaded = true
        # First boot creates the final .rvdata through RGSS2's own save_data,
        # avoiding Ruby-version Marshal incompatibility. Failure is non-fatal.
        if PMD_AC::USE_EXTERNAL_SPECIES_DB && !@using_runtime_file
          begin
            save_data(@data, PMD_AC::SPECIES_DB_RUNTIME_FILE)
          rescue => e
            @load_error = e.class.to_s + ":" + e.message.to_s
          end
        end
        true
      end

      def species(key)
        load! unless loaded?
        (@data[:species] || {})[key]
      end
      def line(key)
        load! unless loaded?
        (@data[:lines] || {})[key]
      end
      def form(species_key, form_key)
        load! unless loaded?
        forms = (@data[:forms] || {})[species_key] || {}
        forms[form_key || :normal]
      end
      def profile(species_key, form_key = :normal)
        data = species(species_key)
        return nil if data == nil
        data[:tactical_profile]
      end
      def ability_slots(species_key)
        data = species(species_key)
        return {} if data == nil
        data[:ability_slots] || {}
      end
      def evolution_rules(species_key)
        data = species(species_key)
        return [] if data == nil
        data[:evolution_rules] || []
      end
    end
  end

  class << self
    #----------------------------------------------------------------------
    # Compatibility facade. Existing PokemonInstance / Battle Core continue
    # calling the old interfaces; data origin is now SpeciesDB.
    #----------------------------------------------------------------------
    def species_identity_data(species_key)
      data = SpeciesDB.species(species_key)
      return data if data != nil
      POKEMON_SPECIES_DATA[species_key]
    end

    def evolution_line_data(line_key)
      data = SpeciesDB.line(line_key)
      return data if data != nil
      EVOLUTION_LINE_DATA[line_key]
    end

    def ability_slots(species_key)
      data = SpeciesDB.ability_slots(species_key)
      return data unless data.empty?
      SPECIES_ABILITY_SLOTS[species_key] || {}
    end

    def unit_profile(species_key)
      direct = UNIT_DATA[species_key]
      return direct if direct != nil
      data = SpeciesDB.species(species_key)
      return nil if data == nil
      compiled_profile_for(data)
    end

    def compiled_profile_for(data)
      p = (data[:tactical_profile] || {}).dup
      range = (p[:range] || 1).to_i
      skill = p[:legacy_skill_bridge]
      result = {
        :name=>data[:name], :mark=>data[:name_en].to_s[0,1].to_s.upcase,
        :species=>data[:pmd_species], :maxhp=>500, :atk=>50, :def=>50,
        :range=>range, :attack_wait=>(p[:attack_wait] || 54),
        :move_speed=>(p[:move_speed] || 2.0),
        :collision_radius=>(p[:collision_radius] || 13.0),
        :melee_reach=>(p[:melee_reach] || 42.0),
        :role=>(p[:role_primary] || :frontline),
        :target_rule=>(p[:target_policy] || :nearest),
        :target_policy=>(p[:target_policy] || :nearest),
        :movement_policy=>(p[:movement_policy] || :frontline),
        :threat_policy=>(p[:threat_policy] || :normal),
        :skill_policy=>(p[:skill_policy] || :current_target),
        :target_commitment=>(p[:target_commitment] || 60),
        :crit_rate=>0.05, :crit_multiplier=>1.50,
        :projectile_tracking=>:weak,
        :projectile_style=>:neutral,
        :basic_action=>:attack, :skill_action=>(p[:legacy_skill_action] || :shoot),
        :skill=>skill, :skill_power=>100,
        :compiled_species_profile=>true,
        :battle_ready=>(skill != nil),
        :visual_candidates=>(data[:visual_candidates] || [data[:pmd_species]])
      }
      if range > 1
        result[:min_range] = 88.0
        result[:preferred_range] = p[:preferred_range] || 148.0
        result[:max_range] = 192.0
      end
      result
    end

    def install_species_db_compatibility!
      SpeciesDB.load!
      for key in SPECIES_DB_V016.keys
        record = SPECIES_DB_V016[key]
        POKEMON_SPECIES_DATA[key] = record
        SPECIES_ABILITY_SLOTS[key] = record[:ability_slots] || {}
        UNIT_DATA[key] = compiled_profile_for(record) if UNIT_DATA[key] == nil
      end
      for key in EVOLUTION_LINES_V016.keys
        EVOLUTION_LINE_DATA[key] = EVOLUTION_LINES_V016[key]
      end
      true
    end

    def pmd_visual_species(species_key, profile = nil)
      data = species_identity_data(species_key)
      candidates = []
      candidates.concat(data[:visual_candidates] || []) if data != nil
      candidates.concat(profile[:visual_candidates] || []) if profile != nil
      candidates.push(data[:pmd_species]) if data != nil
      candidates = candidates.compact.collect{|x|x.to_s}.uniq
      for id in candidates
        return id if FileTest.exist?(PMD_ROOT + id + "/Idle-Anim.png")
      end
      return candidates[0] unless candidates.empty?
      profile != nil ? profile[:species].to_s : species_key.to_s
    end

    #----------------------------------------------------------------------
    # Forms / Mega semantics. A non-normal form is NOT automatically Mega.
    #----------------------------------------------------------------------
    def form_data(species_key, form_key)
      SpeciesDB.form(species_key, form_key || :normal)
    end
    def form_kind(species_key, form_key)
      data = form_data(species_key,form_key)
      data == nil ? nil : data[:form_kind]
    end
    def transformed_form?(species_key, form_key)
      form_key != nil && form_key != :normal
    end
    def form_enabled?(species_key, form_key)
      data = form_data(species_key,form_key)
      data != nil && data[:ruleset_enabled] ? true : false
    end
    def mega_form_data(species_key, form_key)
      data = form_data(species_key,form_key)
      return nil if data == nil || data[:form_kind] != :mega
      return nil unless data[:ruleset_enabled]
      data
    end
    def mega_forms_for(species_key)
      result = {}
      data = SpeciesDB.species(species_key)
      return result if data == nil
      forms = FORMS_DB_V016[species_key] || {}
      for key in forms.keys
        f = forms[key]
        if f[:form_kind] == :mega && f[:ruleset_enabled]
          result[key] = f
        end
      end
      result
    end
    def mega_available?(species_key); !mega_forms_for(species_key).empty?; end
    def default_mega_form(species_key)
      keys = mega_forms_for(species_key).keys
      keys.size == 1 ? keys[0] : nil
    end
    def form_base_stats(species_key, form_key)
      data = form_data(species_key,form_key)
      return data[:base_stats] if data != nil && data[:base_stats] != nil
      base_stats(species_key)
    end
    def form_types(species_key, form_key)
      data = form_data(species_key,form_key)
      return (data[:types] || []).dup if data != nil
      s = species_identity_data(species_key)
      s == nil ? [] : (s[:types] || []).dup
    end
    def form_ability(species_key, form_key)
      return nil if form_key == nil || form_key == :normal
      data = form_data(species_key,form_key)
      data == nil ? nil : data[:ability]
    end
    def form_visual_species(instance)
      data = form_data(instance.species_key,instance.form_key)
      if data != nil
        for key in (data[:visual_candidates] || [])
          return key if compiled_visual_species?(key)
        end
      end
      pmd_visual_species(instance.species_key,unit_profile(instance.species_key))
    end

    #----------------------------------------------------------------------
    # All six official growth groups. Existing v0.15 medium-slow behavior is
    # preserved; the other groups are needed by the 494-species data layer.
    #----------------------------------------------------------------------
    def exp_for_level(level, growth_group)
      l = clamp(level.to_i,1,POKEMON_MAX_LEVEL)
      l3 = l*l*l
      value = case growth_group
      when :fast
        4*l3/5
      when :medium_fast
        l3
      when :medium_slow
        (6*l3/5) - (15*l*l) + (100*l) - 140
      when :slow
        5*l3/4
      when :erratic
        if l <= 50
          l3*(100-l)/50
        elsif l <= 68
          l3*(150-l)/100
        elsif l <= 98
          l3*(1274 + (l%3)*(l%3) - 9*(l%3) - 20*(l/3))/1000
        else
          l3*(160-l)/100
        end
      when :fluctuating
        if l <= 15
          l3*(24 + ((l+1)/3))/50
        elsif l <= 35
          l3*(14+l)/50
        else
          l3*(32 + (l/2))/50
        end
      else
        l3
      end
      [value,0].max
    end

    #----------------------------------------------------------------------
    # Evolution policy v0.16.1: level-only + per-instance random branch.
    # Actor IDs are never used. A stable integer mixer turns instance_uid into
    # a branch roll, giving Clone Actors independent choices while preventing
    # save/load rerolls and evolution_ready?/evolve_if_ready disagreement.
    #----------------------------------------------------------------------
    def evolution_rules(species_key); SpeciesDB.evolution_rules(species_key); end

    def evolution_rule_matches?(instance, rule, trigger, context = nil)
      return false if rule == nil
      return false unless trigger == :level && rule[:trigger] == :level
      return false if rule[:min_level] != nil && instance.level < rule[:min_level].to_i
      true
    end

    def evolution_branch_roll(instance, species_key = nil)
      x = instance.instance_uid.to_i & 0x7fffffff
      data = SpeciesDB.species(species_key || instance.species_key)
      dex = data == nil ? 0 : data[:national_dex].to_i
      x = (x ^ ((x >> 16) & 0x7fff) ^ ((dex * 2654435761) & 0x7fffffff)) & 0x7fffffff
      x = ((x * 1103515245) + 12345) & 0x7fffffff
      x = (x ^ ((x >> 11) & 0xfffff) ^ ((x << 7) & 0x7fffffff)) & 0x7fffffff
      x
    end

    def select_evolution_rule(instance, trigger, context = nil)
      eligible = []
      for rule in evolution_rules(instance.species_key)
        next if rule[:additional_spawn]
        eligible.push(rule) if evolution_rule_matches?(instance,rule,trigger,context)
      end
      return nil if eligible.empty?
      eligible.sort!{|a,b| (a[:priority] || 0).to_i <=> (b[:priority] || 0).to_i}
      return eligible[0] if eligible.size == 1
      eligible[evolution_branch_roll(instance) % eligible.size]
    end

    def special_spawn_rules(instance, context = nil)
      result = []
      for rule in evolution_rules(instance.species_key)
        next unless rule[:additional_spawn]
        result.push(rule) if evolution_rule_matches?(instance,rule,:level,context)
      end
      result
    end

    # ASCII-only checksum, same algorithm as compiler. No Digest dependency.
    def species_runtime_checksum32
      h = 0
      keys = SPECIES_DB_V016.keys.sort{|a,b|
        SPECIES_DB_V016[a][:national_dex] <=> SPECIES_DB_V016[b][:national_dex]}
      for key in keys
        r = SPECIES_DB_V016[key]
        slots = r[:ability_slots] || {}
        text = r[:national_dex].to_s+"|"+key.to_s+"|"+
               (r[:types] || []).collect{|x|x.to_s}.join(",")+"|"+
               (r[:base_stats] || []).join(",")+"|"+r[:line].to_s+"|"+
               r[:growth_group].to_s+"|"+
               [:primary,:secondary,:hidden].collect{|s|slots[s].to_s}.join(",")
        text.each_byte{|b| h = ((h*33)+b) & 0x7fffffff}
      end
      h
    end

    def validate_species_db
      errors = []
      SpeciesDB.load!
      m = SpeciesDB.manifest
      errors.push("count") unless SpeciesDB.species_count == 494
      dexes = SPECIES_DB_V016.values.collect{|r|r[:national_dex]}.sort
      errors.push("dex_range") unless dexes[0] == 1 && dexes[-1] == 494
      errors.push("dex_continuity") unless dexes == (1..494).to_a
      errors.push("key_unique") unless SPECIES_DB_V016.keys.uniq.size == 494
      valid_types = TYPE_CHART.keys
      for key in SPECIES_DB_V016.keys
        r = SPECIES_DB_V016[key]
        errors.push("stats:"+key.to_s) if r[:base_stats] == nil || r[:base_stats].size != 6
        errors.push("bst:"+key.to_s) if r[:base_stats] != nil && r[:bst].to_i != r[:base_stats].inject(0){|s,x|s+x.to_i}
        errors.push("types:"+key.to_s) if r[:types] == nil || r[:types].empty? || r[:types].size > 2
        if r[:types] != nil
          for type in r[:types]
            errors.push("type:"+key.to_s+":"+type.to_s) unless valid_types.include?(type)
          end
        end
        errors.push("pmd_id:"+key.to_s) unless r[:pmd_species].to_s =~ /^\d{4}$/
        line = SpeciesDB.line(r[:line])
        errors.push("line:"+key.to_s) if line == nil
        errors.push("line_member:"+key.to_s) if line != nil && !(line[:members] || []).include?(key)
        forms = FORMS_DB_V016[key] || {}
        errors.push("normal_form:"+key.to_s) if forms[:normal] == nil
        for form_key in forms.keys
          f = forms[form_key] || {}
          errors.push("form_kind:"+key.to_s+":"+form_key.to_s) if f[:form_kind] == nil
          for type in (f[:types] || [])
            errors.push("form_type:"+key.to_s+":"+form_key.to_s+":"+type.to_s) unless valid_types.include?(type)
          end
        end
        ls = r[:learnset]
        errors.push("learnset:"+key.to_s) if ls == nil || !ls.is_a?(Array) || ls.empty?
        if ls != nil && ls.is_a?(Array)
          for entry in ls
            errors.push("learnset_entry:"+key.to_s) if entry[:level] == nil || entry[:move] == nil || entry[:method] != :level_up
          end
        end
        p = r[:tactical_profile] || {}
        errors.push("target:"+key.to_s) unless AI_TARGET_POLICIES.include?(p[:target_policy])
        errors.push("move:"+key.to_s) unless AI_MOVEMENT_POLICIES.include?(p[:movement_policy])
        errors.push("threat:"+key.to_s) unless AI_THREAT_POLICIES.include?(p[:threat_policy])
        errors.push("skill:"+key.to_s) unless AI_SKILL_POLICIES.include?(p[:skill_policy])
      end
      errors.push("checksum") unless species_runtime_checksum32 == m[:runtime_checksum32].to_i
      errors
    end
  end

  install_species_db_compatibility!

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal, :control, :beam, :zone, :hit, :energy,
                        :direction, :object, :summon, :identity,
                        :progression, :individual, :mega, :synergy,
                        :species_db]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :normal=>"NORMAL", :control=>"CONTROL", :beam=>"BEAM", :zone=>"ZONE",
    :hit=>"HIT", :energy=>"ENERGY", :direction=>"DIRECTION",
    :object=>"OBJECT", :summon=>"SUMMON", :identity=>"IDENTITY",
    :progression=>"PROGRESSION", :individual=>"INDIVIDUAL",
    :mega=>"MEGA", :synergy=>"SYNERGY", :species_db=>"SPECIES_DB"
  }
end

class PMD_PokemonInstance
  # v0.15 battle/progression code expects an executable {level=>move} Hash.
  # v0.16 keeps canonical level-up references as an Array in SpeciesDB and
  # exposes them separately, so unimplemented moves can never execute by accident.
  def learnset
    data = species_data
    return {} if data == nil
    data[:legacy_executable_learnset] || {}
  end
  def canonical_learnset
    data = species_data
    return [] if data == nil
    (data[:learnset] || []).dup
  end

  def transformed_form?; form_key != nil && form_key != :normal; end
  def mega?; PMD_AC.form_kind(species_key,form_key) == :mega && PMD_AC.form_enabled?(species_key,form_key); end

  def evolution_ready?
    PMD_AC.select_evolution_rule(self,:level,{}) != nil
  end

  def evolve_if_ready
    source = species_key
    rule = PMD_AC.select_evolution_rule(self,:level,{})
    return nil if rule == nil
    spawns = PMD_AC.special_spawn_rules(self,{})
    target = rule[:target_species]
    return nil unless @identity.change_species_key(target)
    event = {:from=>source,:to=>target,:level=>@level,:uid=>instance_uid,
             :rule=>rule,:additional_spawns=>spawns.collect{|r|r[:target_species]}}
    @progression_history.push({:type=>:evolution}.merge(event))
    event
  end

  # Backward-compatible API only. Items no longer trigger evolution.
  def evolve_with_item(item_key)
    nil
  end

  def evolution_rule_for(trigger, context = nil)
    PMD_AC.select_evolution_rule(self,trigger,context || {})
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v016_start start unless method_defined?(:pmd_ac_v016_start)
  def start
    pmd_ac_v016_start
    # Cosmetic version marker only; combat Core remains v0.15 underneath.
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") {|f| f.read }
        text.sub!("PMD AutoChess Proto v0.15 Battle Verification Log",
                  "PMD AutoChess Proto v0.16.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") {|f| f.write(text) }
      end
    rescue
    end
    refresh_header
    m = PMD_AC::SpeciesDB.manifest
    log_event(:species_db,
      "LOADED count="+PMD_AC::SpeciesDB.species_count.to_s+
      " lines="+PMD_AC::SpeciesDB.line_count.to_s+
      " forms="+PMD_AC::SpeciesDB.form_count.to_s+
      " source="+(PMD_AC::SpeciesDB.using_runtime_file? ? "rvdata" : "embedded")+
      " schema="+m[:schema_version].to_s+
      " content="+m[:content_version].to_s+
      " checksum32="+m[:runtime_checksum32].to_s)
    if PMD_AC::SpeciesDB.load_error != nil
      log_event(:species_db,"LOAD_WARNING "+PMD_AC::SpeciesDB.load_error.to_s)
    end
  end

  alias pmd_ac_v016_refresh_header refresh_header unless method_defined?(:pmd_ac_v016_refresh_header)
  def refresh_header
    pmd_ac_v016_refresh_header
    return if @header_sprite == nil || @header_sprite.bitmap == nil
    bmp = @header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,31,Color.new(0,0,0,180))
    bmp.font.size = 22
    bmp.font.bold = true
    bmp.font.color = Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,26,"PMD 自走棋原型 v0.16",1)
  end

  alias pmd_ac_v016_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v016_prepare_verification_battle)
  def prepare_verification_battle
    pmd_ac_v016_prepare_verification_battle
    if verification_mode == :species_db
      for unit in @units
        unit.verification_energy_sandbox(true)
        unit.verification_combat_sandbox(true)
      end
    end
  end

  alias pmd_ac_v016_update_auras update_auras unless method_defined?(:pmd_ac_v016_update_auras)
  def update_auras
    return if verification_mode == :species_db
    pmd_ac_v016_update_auras
  end

  def verify_species_db_manifest(tag)
    return if @verification_done[tag]
    m = PMD_AC::SpeciesDB.manifest
    pass = m[:species_count].to_i == 494 && m[:schema_version] == "1.0" &&
           m[:ruleset_id] == "pmd_ac_v016_legacy_mega"
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " count="+m[:species_count].to_s+" lines="+m[:line_count].to_s+
      " alt_forms="+m[:alternate_form_count].to_s+
      " checksum32="+m[:runtime_checksum32].to_s)
    @verification_done[tag]=true
  end

  def verify_species_db_integrity(tag)
    return if @verification_done[tag]
    errors = PMD_AC.validate_species_db
    pass = errors.empty?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " species="+PMD_AC::SpeciesDB.species_count.to_s+
      " lines="+PMD_AC::SpeciesDB.line_count.to_s+
      " forms="+PMD_AC::SpeciesDB.form_count.to_s+
      " errors=["+errors[0,12].join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_species_db_golden(tag)
    return if @verification_done[tag]
    b=PMD_AC.species_identity_data(:bulbasaur)
    p=PMD_AC.species_identity_data(:pikachu)
    v=PMD_AC.species_identity_data(:victini)
    pass = b && p && v && b[:base_stats]==[45,49,49,65,65,45] &&
           p[:base_stats]==[35,55,40,50,50,90] &&
           v[:national_dex]==494 && v[:pmd_species]=="0494" &&
           b[:line]==:bulbasaur_line && p[:line]==:pikachu_line
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " bulba_line="+(b ? b[:line].to_s : "nil")+
      " pikachu_line="+(p ? p[:line].to_s : "nil")+
      " victini="+(v ? v[:pmd_species].to_s : "nil"))
    @verification_done[tag]=true
  end

  def verify_species_db_learnsets(tag)
    return if @verification_done[tag]
    b=PMD_AC.species_identity_data(:bulbasaur)
    v=PMD_AC.species_identity_data(:victini)
    same13=(b[:learnset] || []).select{|e|e[:level].to_i==13}
    count=0
    for key in PMD_AC::SPECIES_DB_V016.keys
      count += 1 unless (PMD_AC::SPECIES_DB_V016[key][:learnset] || []).empty?
    end
    pass=count==494 && same13.size>=2 && v && !(v[:learnset] || []).empty? &&
         b[:learnset_ruleset]==:black_white
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " species_with_learnset="+count.to_s+
      " bulba_lv13="+same13.size.to_s+
      " ruleset="+b[:learnset_ruleset].to_s)
    @verification_done[tag]=true
  end

  def verify_species_db_profiles(tag)
    return if @verification_done[tag]
    keys=[:ivysaur,:deoxys,:rotom,:giratina,:victini]
    ok=true; values=[]
    for key in keys
      p=PMD_AC.unit_profile(key)
      ok=false if p==nil || !p[:compiled_species_profile]
      values.push(key.to_s+":"+(p ? p[:movement_policy].to_s : "nil"))
    end
    # Direct v0.15 test units remain their exact legacy UNIT_DATA entries.
    ok=false unless PMD_AC.unit_profile(:bulbasaur).equal?(PMD_AC::UNIT_DATA[:bulbasaur])
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+
      " profiles=["+values.join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_species_db_forms(tag)
    return if @verification_done[tag]
    d=PMD_PokemonInstance.new(:deoxys,50,{:instance_uid=>160386,:ivs=>[15,15,15,15,15,15],:nature=>:hardy})
    d.identity.set_form_key(:attack)
    nonmega = d.transformed_form? && !d.mega? && PMD_AC.form_kind(:deoxys,:attack)==:normal_variant
    v=PMD_PokemonInstance.new(:venusaur,50,{:instance_uid=>160003,:ivs=>[15,15,15,15,15,15],:nature=>:hardy})
    meg=v.mega_evolve!(:mega)
    megaok=meg && v.mega? && PMD_AC.form_kind(:venusaur,:mega)==:mega
    cx=PMD_AC.form_data(:charizard,:mega_x); cy=PMD_AC.form_data(:charizard,:mega_y)
    pass=nonmega && megaok && cx!=nil && cy!=nil &&
         PMD_AC.default_mega_form(:charizard)==nil
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " deoxys_attack_mega="+(d.mega? ? "1":"0")+
      " venusaur_mega="+(v.mega? ? "1":"0")+
      " charizard_forms="+PMD_AC.mega_forms_for(:charizard).keys.collect{|x|x.to_s}.sort.join("/"))
    @verification_done[tag]=true
  end

  def verify_species_db_evolution_rules(tag)
    return if @verification_done[tag]
    all_level=true
    branch_level_consistent=true
    for key in PMD_AC::SPECIES_DB_V016.keys
      main=[]
      for rule in PMD_AC.evolution_rules(key)
        all_level=false unless rule[:trigger] == :level
        main.push(rule) unless rule[:additional_spawn]
      end
      if main.size > 1
        levels=main.collect{|r|r[:min_level].to_i}.uniq
        branch_level_consistent=false unless levels.size == 1
      end
    end
    eevee_rules=PMD_AC.evolution_rules(:eevee).select{|r|!r[:additional_spawn]}
    eevee_level=eevee_rules.empty? ? 0 : eevee_rules[0][:min_level].to_i
    # Clone Actor compatibility: same Actor binding, different PokemonInstance UID.
    clone_targets=[]
    stable=true
    21.times do |i|
      uid=266001+i*2
      e=PMD_PokemonInstance.new(:eevee,eevee_level,
        {:instance_uid=>uid,:runtime_actor_id=>501,:template_actor_id=>7,
         :ivs=>[15,15,15,15,15,15],:nature=>:hardy})
      r1=e.evolution_rule_for(:level,{})
      r2=e.evolution_rule_for(:level,{})
      stable=false if r1==nil || r2==nil || r1[:target_species]!=r2[:target_species]
      clone_targets.push(r1[:target_species]) if r1
    end
    clone_unique=clone_targets.uniq
    actor_independent=clone_unique.size > 1
    # Tyrogue conditions are no longer stat-gated: all 3 are same-level random branches.
    ty=PMD_AC.evolution_rules(:tyrogue).select{|r|!r[:additional_spawn]}
    ty_ok=ty.size==3 && ty.collect{|r|r[:min_level].to_i}.uniq.size==1
    # Nincada keeps Shedinja as an additional level-gated spawn, not branch consumption.
    nincada=PMD_PokemonInstance.new(:nincada,20,{:instance_uid=>290001,:ivs=>[15,15,15,15,15,15],:nature=>:hardy})
    spawns=PMD_AC.special_spawn_rules(nincada,{})
    pass=all_level && branch_level_consistent && eevee_rules.size>=7 &&
         eevee_level>0 && stable && actor_independent && ty_ok &&
         spawns.any?{|r|r[:target_species]==:shedinja}
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " all_level="+(all_level ? "1":"0")+
      " branch_level_same="+(branch_level_consistent ? "1":"0")+
      " eevee_level="+eevee_level.to_s+
      " clone_actor_branches=["+clone_unique.collect{|x|x.to_s}.sort.join(",")+"]"+
      " stable_uid_roll="+(stable ? "1":"0")+
      " nincada_spawn=["+spawns.collect{|r|r[:target_species].to_s}.join(",")+"]")
    @verification_done[tag]=true
  end

  def verify_species_db_growth(tag)
    return if @verification_done[tag]
    vals={:fast=>PMD_AC.exp_for_level(50,:fast),
          :medium_fast=>PMD_AC.exp_for_level(50,:medium_fast),
          :medium_slow=>PMD_AC.exp_for_level(50,:medium_slow),
          :slow=>PMD_AC.exp_for_level(50,:slow),
          :erratic=>PMD_AC.exp_for_level(50,:erratic),
          :fluctuating=>PMD_AC.exp_for_level(50,:fluctuating)}
    pass = vals[:fast]==100000 && vals[:medium_fast]==125000 &&
           vals[:medium_slow]==117360 && vals[:slow]==156250 &&
           vals[:erratic]==125000 && vals[:fluctuating]==142500
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " values="+vals.collect{|k,v|k.to_s+"="+v.to_s}.join(","))
    @verification_done[tag]=true
  end

  def verify_species_db_legacy_progression(tag)
    return if @verification_done[tag]
    b=PMD_PokemonInstance.new(:bulbasaur,15,{:instance_uid=>160001,:ivs=>[15,15,15,15,15,15],:nature=>:hardy})
    result=b.gain_exp(b.exp_to_next_level,true)
    p19=PMD_PokemonInstance.new(:pikachu,19,{:instance_uid=>160024,:ivs=>[15,15,15,15,15,15],:nature=>:hardy})
    p=PMD_PokemonInstance.new(:pikachu,20,{:instance_uid=>160025,:ivs=>[15,15,15,15,15,15],:nature=>:hardy})
    before=p19.evolve_if_ready; item_disabled=p.evolve_with_item(:thunder_stone); good=p.evolve_if_ready
    pass=b.species_key==:ivysaur && result[:moves].include?(:ricochet_seed) &&
         before==nil && item_disabled==nil && good!=nil && p.species_key==:raichu
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+
      " bulba="+b.species_key.to_s+" learned=["+result[:moves].collect{|x|x.to_s}.join(",")+"]"+
      " pikachu="+p.species_key.to_s)
    @verification_done[tag]=true
  end

  def verify_species_db_runtime_file(tag)
    return if @verification_done[tag]
    exists=FileTest.exist?(PMD_AC::SPECIES_DB_RUNTIME_FILE)
    log_event(:verify,tag.to_s.upcase+" pass="+(exists ? "1":"0")+
      " runtime_file="+(exists ? "present":"missing")+
      " source="+(PMD_AC::SpeciesDB.using_runtime_file? ? "rvdata":"embedded_first_boot"))
    @verification_done[tag]=true
  end

  alias pmd_ac_v016_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v016_update_verification_script)
  def update_verification_script
    if verification_mode != :species_db
      pmd_ac_v016_update_verification_script
      return
    end
    @verification_frame += 1
    verify_species_db_manifest(:species_db_manifest) if @verification_frame >= 4
    verify_species_db_integrity(:species_db_integrity) if @verification_frame >= 30
    verify_species_db_golden(:species_db_golden) if @verification_frame >= 70
    verify_species_db_learnsets(:species_db_learnsets) if @verification_frame >= 95
    verify_species_db_profiles(:species_db_profiles) if @verification_frame >= 120
    verify_species_db_forms(:species_db_forms) if @verification_frame >= 155
    verify_species_db_evolution_rules(:species_db_evolution_rules) if @verification_frame >= 195
    verify_species_db_growth(:species_db_growth) if @verification_frame >= 235
    verify_species_db_legacy_progression(:species_db_legacy_progression) if @verification_frame >= 270
    verify_species_db_runtime_file(:species_db_runtime_file) if @verification_frame >= 300
    complete_verification_mode if @verification_frame >= PMD_AC::VERIFICATION_SPECIES_DB_END_FRAME
  end
end
