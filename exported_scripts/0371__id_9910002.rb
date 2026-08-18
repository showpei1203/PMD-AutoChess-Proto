# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Hoenn Gameplay Review Runtime v0.99.10
# 分類：Pokémon Gameplay / AI / Balance Review Runtime + Verifier
#
# 【用途】
# 1. 將 #0252-0386 的 135 隻人工 Profile 套入 Species / Unit Runtime。
# 2. 將 Basic Attack Physical/Special Content Bridge 擴充到 Hoenn。
# 3. 進化後重新套 Species Profile，最後恢復玩家永久 ai_setup。
# 4. 產生 18 欄 Hoenn Review Report 與 494 隻最新 Review Queue。
# 5. 對 Castform / Deoxys disabled forms 保存 Review Profile，但不啟用 Runtime Form。
# 6. 提供 GAMEPLAY_REVIEW_HOENN_V09910 verifier。
#
# 【安全邊界】
# - 普攻 category/type 只在 source_type=:basic 時注入。
# - Kanto v0.99.8 / Johto v0.99.9 Profile 保留並 fallback。
# - Skill、Ability、傷害公式、Frozen Combat Core 不直接修改。
# - Slaking Truant、Shedinja Wonder Guard、Nincada additional spawn 使用既有 Runtime，
#   本腳本只做 Gameplay Content Review，不重寫核心。
#==============================================================================
module PMD_AC
  HOENN_GAMEPLAY_REVIEW_FILE_V09910='PMD_GameplayReview_Hoenn_v0.99.10.txt'
  GAMEPLAY_REVIEW_QUEUE_FILE_V09910='PMD_GameplayReview_Queue_v0.99.10.txt'
  HOENN_VERIFY_END_V09910=120

  class << self
    def hoenn_review_species_keys_v09910
      a=[]
      SPECIES_DB_V016.each do |k,d|
        n=d[:national_dex].to_i
        a.push(k) if n>=252 && n<=386
      end
      a.sort{|x,y|SPECIES_DB_V016[x][:national_dex].to_i<=>SPECIES_DB_V016[y][:national_dex].to_i}
    end

    def review_profile_for_v09910(species_key,form_key=nil)
      sk=species_key.to_sym;fk=(form_key || :normal).to_sym
      p=HOENN_PROFILE_OVERRIDES_V09910[sk]
      if p!=nil
        fp=HOENN_FORM_REVIEW_PROFILES_V09910[[sk,fk]]
        f=(FORMS_DB_V016[sk] || {})[fk]
        return fp.dup if fp!=nil && f!=nil && f[:ruleset_enabled]
        return p.dup
      end
      review_profile_for_v0999(sk,fk)
    end

    def apply_review_profile_to_species_v09910(species_key,profile)
      d=SPECIES_DB_V016[species_key]
      return false if d==nil || profile==nil
      tp=d[:tactical_profile] || {}
      tp[:role_primary]=profile[:role];tp[:target_policy]=profile[:target_policy]
      tp[:movement_policy]=profile[:movement_policy];tp[:threat_policy]=profile[:threat_policy]
      tp[:skill_policy]=profile[:skill_policy];tp[:target_commitment]=profile[:target_commitment]
      tp[:range]=profile[:range];tp[:preferred_range]=preferred_range_for_review_v0998(profile)
      tp[:profile_generation]=:manual_hoenn_v09910;tp[:ai_override_reason]=:gameplay_review_v09910
      d[:tactical_profile]=tp;d[:role_tags]=review_role_tags_v0998(species_key,profile)
      u=UNIT_DATA[species_key]
      if u==nil
        u=compiled_profile_for(d);UNIT_DATA[species_key]=u
      end
      u[:role]=profile[:role];u[:role_primary]=profile[:role]
      u[:target_rule]=profile[:target_policy];u[:target_policy]=profile[:target_policy]
      u[:movement_policy]=profile[:movement_policy];u[:threat_policy]=profile[:threat_policy]
      u[:skill_policy]=profile[:skill_policy];u[:target_commitment]=profile[:target_commitment]
      u[:range]=profile[:range];u[:basic_damage_category]=profile[:basic_damage_category]
      u[:basic_move_type]=profile[:basic_move_type];u[:projectile_style]=review_projectile_style_v0998(profile[:basic_move_type])
      u[:profile_generation]=:manual_hoenn_v09910;u[:review_status]=:reviewed_manual_v09910
      if profile[:range].to_i>1
        u[:min_range]=88.0;u[:preferred_range]=preferred_range_for_review_v0998(profile);u[:max_range]=192.0
      else
        u[:min_range]=0.0;u[:preferred_range]=0.0;u[:max_range]=(u[:melee_reach] || 42.0).to_f
      end
      true
    end

    def install_hoenn_gameplay_review_v09910!
      HOENN_PROFILE_OVERRIDES_V09910.each{|k,p|apply_review_profile_to_species_v09910(k,p)}
      true
    end

    def ability_synergy_tags_v09910(species_key)
      out=ability_synergy_tags_v0999(species_key).dup;out.delete(:no_special_synergy)
      d=SPECIES_DB_V016[species_key] || {};slots=d[:ability_slots] || {}
      slots.each_value do |ab|
        next if ab==nil
        tag=HOENN_ABILITY_SYNERGY_EXTRA_V09910[ab];out.push(tag) if tag!=nil
      end
      out.push(:no_special_synergy) if out.empty?;out.uniq
    end

    def evolution_progression_v09910(species_key)
      d=SPECIES_DB_V016[species_key] || {};line=EVOLUTION_LINES_V016[d[:line]] || {};parts=[]
      (line[:members] || []).each do |sk|
        p=review_profile_for_v09910(sk,:normal);next if p==nil
        sd=SPECIES_DB_V016[sk] || {}
        parts.push({:species=>sk,:stage=>sd[:stage],:role=>p[:role],:category=>p[:basic_damage_category],:range=>p[:range],:evolution_rules=>(sd[:evolution_rules] || []).dup})
      end
      parts
    end

    def form_differences_v09910(species_key)
      out=[];forms=FORMS_DB_V016[species_key] || {};normal=(SPECIES_DB_V016[species_key] || {})[:base_stats] || []
      forms.each do |fk,f|
        next if fk==:normal
        fs=f[:base_stats] || normal;delta=[]
        6.times{|i|delta.push(fs[i].to_i-normal[i].to_i)} if fs.size==6 && normal.size==6
        rp=HOENN_FORM_REVIEW_PROFILES_V09910[[species_key,fk]]
        out.push({:form=>fk,:enabled=>(f[:ruleset_enabled] ? true : false),:types=>f[:types],:base_stats=>fs,:stat_delta=>delta,
          :ability=>f[:ability],:review_profile=>(rp==nil ? nil : rp.dup),:runtime_profile=>(f[:ruleset_enabled] && rp!=nil ? rp.dup : nil)})
      end
      out
    end

    def balance_risks_v09910(species_key)
      d=SPECIES_DB_V016[species_key] || {};s=d[:base_stats] || [];r=[]
      r.push(:low_bst_growth_stage) if d[:bst].to_i<300
      r.push(:high_power_budget) if d[:bst].to_i>=580
      r.push(:high_speed_pressure) if s.size==6 && s[5].to_i>=115
      r.push(:physical_wall) if s.size==6 && s[2].to_i>=130
      r.push(:special_wall) if s.size==6 && s[4].to_i>=120
      learn=d[:learnset] || [];r.push(:compressed_levelup_after_evolution) if learn.size<=5 && d[:stage].to_i>1
      extra=HOENN_SPECIAL_BALANCE_RISKS_V09910[species_key] || [];(r+extra).uniq
    end

    def gameplay_review_row_v09910(species_key)
      d=SPECIES_DB_V016[species_key];p=HOENN_PROFILE_OVERRIDES_V09910[species_key]
      return nil if d==nil || p==nil
      learn=d[:learnset] || []
      {:species_key=>species_key,:dex=>d[:national_dex].to_i,:name=>d[:name],:base_stats=>(d[:base_stats] || []).dup,
        :effective_stats=>effective_stats_v0998(species_key,p),:physical_special_identity=>p[:basic_damage_category],
        :basic_attack_range_style=>{:range=>p[:range],:type=>p[:basic_move_type],:category=>p[:basic_damage_category],:projectile_style=>review_projectile_style_v0998(p[:basic_move_type])},
        :role=>p[:role],:movement_policy=>p[:movement_policy],:target_policy=>p[:target_policy],:threat_policy=>p[:threat_policy],:skill_policy=>p[:skill_policy],
        :learnset=>{:refs=>learn.size,:unique=>learn.collect{|x|x[:move]}.uniq.size,:ruleset=>d[:learnset_ruleset]},
        :full_movepool=>full_movepool_summary_v0998(species_key),:early_game_moves=>early_game_moves_v0998(species_key),
        :ability_synergy=>{:slots=>(d[:ability_slots] || {}).dup,:tags=>ability_synergy_tags_v09910(species_key)},
        :evolution_progression=>evolution_progression_v09910(species_key),:form_differences=>form_differences_v09910(species_key),
        :team_bond=>{:status=>:frozen_existing_reviewed,:line=>d[:line],:synergy_tags=>(d[:synergy_tags] || []).dup,:role_tags=>(d[:role_tags] || []).dup},
        :ai_behavior=>{:role_note=>KANTO_ROLE_NOTES_V0998[p[:role]],:commitment=>p[:target_commitment],:profile_generation=>:manual_hoenn_v09910},
        :balance_risks=>balance_risks_v09910(species_key),:identity_note=>HOENN_IDENTITY_NOTES_V09910[species_key],:status=>:reviewed_manual_v09910}
    end

    def hoenn_gameplay_review_audit_v09910
      rows=[];errors=[];physical=0;special=0;melee=0;ranged=0;enabled_forms=[];review_form_profiles=[]
      hoenn_review_species_keys_v09910.each do |sk|
        row=gameplay_review_row_v09910(sk);rows.push(row);p=HOENN_PROFILE_OVERRIDES_V09910[sk];d=SPECIES_DB_V016[sk]
        errors.push([sk,:missing_row]) if row==nil
        errors.push([sk,:invalid_target]) unless AI_TARGET_POLICIES.include?(p[:target_policy])
        errors.push([sk,:invalid_movement]) unless AI_MOVEMENT_POLICIES.include?(p[:movement_policy])
        errors.push([sk,:invalid_threat]) unless AI_THREAT_POLICIES.include?(p[:threat_policy])
        errors.push([sk,:invalid_skill]) unless AI_SKILL_POLICIES.include?(p[:skill_policy])
        errors.push([sk,:non_stab_basic]) unless PMD_AC.form_types(sk,:normal).include?(p[:basic_move_type])
        physical+=1 if p[:basic_damage_category]==:physical;special+=1 if p[:basic_damage_category]==:special
        melee+=1 if p[:range].to_i<=1;ranged+=1 if p[:range].to_i>1
        errors.push([sk,:profile_not_installed]) unless (d[:tactical_profile] || {})[:profile_generation]==:manual_hoenn_v09910
        (FORMS_DB_V016[sk] || {}).each do |fk,f|
          next if fk==:normal
          enabled_forms.push([sk,fk]) if f[:ruleset_enabled]
          rp=HOENN_FORM_REVIEW_PROFILES_V09910[[sk,fk]];review_form_profiles.push([sk,fk]) if rp!=nil
        end
      end
      HOENN_FORM_REVIEW_PROFILES_V09910.each_key do |pair|
        sk=pair[0];fk=pair[1];f=(FORMS_DB_V016[sk] || {})[fk]
        errors.push([pair,:missing_form_source]) if f==nil
        errors.push([pair,:review_profile_accidentally_enabled]) if f!=nil && f[:ruleset_enabled]
      end
      pass=rows.size==135 && errors.empty? && enabled_forms.empty? && review_form_profiles.size==6 && physical==70 && special==65 && melee==68 && ranged==67
      {:rows=>rows,:errors=>errors,:enabled_forms=>enabled_forms,:review_form_profiles=>review_form_profiles,:physical=>physical,:special=>special,:melee=>melee,:ranged=>ranged,:pass=>pass}
    end

    def hoenn_gameplay_review_text_v09910(report=nil)
      r=report || hoenn_gameplay_review_audit_v09910;out=[]
      out << 'PMD AutoChess Hoenn Gameplay Review v0.99.10'
      out << 'Scope: #0252-0386 | Status: REVIEWED_MANUAL | Fields: 18'
      out << 'Previous reviewed: #0001-0251 Kanto v0.99.8 + Johto v0.99.9 preserved'
      out << 'Frozen Combat Core direct modification: NO'
      out << 'Profiles: physical='+r[:physical].to_s+' special='+r[:special].to_s+' melee='+r[:melee].to_s+' ranged='+r[:ranged].to_s
      out << 'Effective stats benchmark: neutral nature | IV=15 | EV=0 | combat HP x10 | Lv20/Lv50'
      out << 'Ruleset-enabled non-normal Hoenn forms: '+r[:enabled_forms].size.to_s
      out << 'Review-only disabled form profiles: '+r[:review_form_profiles].size.to_s+' (Castform 3 + Deoxys 3)'
      out << 'Errors: '+r[:errors].size.to_s;out << ''
      r[:rows].each do |x|
        b=x[:basic_attack_range_style];fm=x[:full_movepool];ab=x[:ability_synergy]
        out << sprintf('#%04d %-12s %-9s move=%-10s target=%-16s threat=%-11s skill=%-12s basic=%s/%s/r%d movepool=%d early=%d ability=%s risks=%s',
          x[:dex],x[:species_key].to_s,x[:role].to_s,x[:movement_policy].to_s,x[:target_policy].to_s,x[:threat_policy].to_s,x[:skill_policy].to_s,
          b[:type].to_s,b[:category].to_s,b[:range].to_i,fm[:unique_total].to_i,x[:early_game_moves].size,ab[:tags].collect{|z|z.to_s}.join('+'),x[:balance_risks].collect{|z|z.to_s}.join('+'))
        GAMEPLAY_REVIEW_FIELDS_V0997.each{|field|out << '  '+field.to_s+'='+x[field].inspect}
        out << '  identity_note='+x[:identity_note].inspect
      end
      out << '';out << 'Review PASS: '+(r[:pass] ? '1':'0');out.join("
")+"
"
    end

    def write_hoenn_gameplay_review_v09910(report=nil)
      File.open(HOENN_GAMEPLAY_REVIEW_FILE_V09910,'wb'){|f|f.write(hoenn_gameplay_review_text_v09910(report))};true
    rescue;false;end

    def gameplay_review_queue_text_v09910
      out=[];out << 'PMD AutoChess Gameplay Review Queue v0.99.10';out << 'Completed: #0001-0386 | Pending: #0387-0494'
      out << 'Fields: '+GAMEPLAY_REVIEW_FIELDS_V0997.collect{|x|x.to_s}.join(', ')
      ks=SPECIES_DB_V016.keys.sort{|a,b|SPECIES_DB_V016[a][:national_dex].to_i<=>SPECIES_DB_V016[b][:national_dex].to_i}
      ks.each do |sk|
        n=SPECIES_DB_V016[sk][:national_dex].to_i
        status=n<=151 ? 'REVIEWED_MANUAL_V0998' : (n<=251 ? 'REVIEWED_MANUAL_V0999' : (n<=386 ? 'REVIEWED_MANUAL_V09910' : 'PENDING'))
        out << sprintf('#%04d %s status=%s',n,sk.to_s,status)
      end
      out.join("
")+"
"
    end

    def write_gameplay_review_queue_v09910
      File.open(GAMEPLAY_REVIEW_QUEUE_FILE_V09910,'wb'){|f|f.write(gameplay_review_queue_text_v09910)};true
    rescue;false;end
  end
  install_hoenn_gameplay_review_v09910!
end

class Scene_PMD_AutoChess
  alias pmd_ac_v09910_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v09910_deal_direct_damage)
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup
    if opts[:source_type]==:basic && user!=nil && user.respond_to?(:species_key)
      fk=user.respond_to?(:form_key) ? user.form_key : :normal;p=PMD_AC.review_profile_for_v09910(user.species_key,fk)
      if p!=nil
        opts[:damage_category]=p[:basic_damage_category] if opts[:damage_category]==nil
        opts[:move_type]=p[:basic_move_type] if opts[:move_type]==nil
      end
    end
    pmd_ac_v09910_deal_direct_damage(user,target,power,opts)
  end
end

class Game_PMDChessUnit
  def apply_species_review_profile_v09910
    return false if @pokemon_instance==nil
    p=PMD_AC.review_profile_for_v09910(species_key,form_key);return false if p==nil
    @role=p[:role];@target_rule=p[:target_policy];@target_policy=p[:target_policy];@movement_policy=p[:movement_policy]
    @threat_policy=p[:threat_policy];@skill_policy=p[:skill_policy];@target_commitment=p[:target_commitment].to_i
    @range=p[:range].to_i;@projectile_style=PMD_AC.review_projectile_style_v0998(p[:basic_move_type])
    @min_range=@range>1 ? 88.0 : 0.0;@preferred_range=PMD_AC.preferred_range_for_review_v0998(p);@max_range=@range>1 ? 192.0 : @melee_reach.to_f
    @identity.refresh_review_role_tags_v0998 if @identity!=nil && @identity.respond_to?(:refresh_review_role_tags_v0998)
    apply_persistent_ai_setup if respond_to?(:apply_persistent_ai_setup);true
  end
  alias pmd_ac_v09910_sync_from_pokemon_instance sync_from_pokemon_instance unless method_defined?(:pmd_ac_v09910_sync_from_pokemon_instance)
  def sync_from_pokemon_instance
    ok=pmd_ac_v09910_sync_from_pokemon_instance;apply_species_review_profile_v09910 if ok;ok
  end
end

module PMD_AC
  old_labels=VERIFICATION_LABELS.dup;remove_const(:VERIFICATION_LABELS);VERIFICATION_LABELS=old_labels
  VERIFICATION_LABELS.delete(:gameplay_review_johto_v0999);VERIFICATION_LABELS[:gameplay_review_hoenn_v09910]='GAMEPLAY_REVIEW_HOENN_V09910'
  old_modes=VERIFICATION_MODES.dup;remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:gameplay_review_hoenn_v09910]+old_modes.reject{|x|x==:normal || x==:gameplay_review_hoenn_v09910 || x==:gameplay_review_johto_v0999 || x==:gameplay_review_kanto_v0998 || x==:movepool_production_v0997}
end

class Scene_PMD_AutoChess
  alias pmd_ac_v09910_start start unless method_defined?(:pmd_ac_v09910_start)
  alias pmd_ac_v09910_refresh_header refresh_header unless method_defined?(:pmd_ac_v09910_refresh_header)
  alias pmd_ac_v09910_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v09910_prepare_verification_battle)
  alias pmd_ac_v09910_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09910_update_verification_script)
  alias pmd_ac_v09910_log_event log_event unless method_defined?(:pmd_ac_v09910_log_event)

  def start
    pmd_ac_v09910_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.99.10 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    log_event(:gameplay_review,'FLOW v0.99.10 hoenn=135 manual_profiles=135 enabled_forms=0 review_only_forms=6 basic_category_bridge=1 cumulative_reviewed=386 next=0387-0494')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09910_refresh_header;return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap;bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180));pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255);bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.10',1)
  end

  def gameplay_review_hoenn_v09910?;verification_mode==:gameplay_review_hoenn_v09910;end

  def prepare_verification_battle
    pmd_ac_v09910_prepare_verification_battle;return unless gameplay_review_hoenn_v09910?
    @hoenn_review_failed_v09910=false;@hoenn_review_report_v09910=PMD_AC.hoenn_gameplay_review_audit_v09910
    @hoenn_review_written_v09910=PMD_AC.write_hoenn_gameplay_review_v09910(@hoenn_review_report_v09910)
    @hoenn_queue_written_v09910=PMD_AC.write_gameplay_review_queue_v09910
    log_event(:showcase,'START mode=GAMEPLAY_REVIEW_HOENN_V09910 species=135 manual=135 cumulative=386 forms_enabled=0 review_only_forms=6')
  end

  def log_event(category,message)
    if category.to_s=='verify' && gameplay_review_hoenn_v09910? && message.to_s.index('V09910')!=nil && message.to_s.index(' pass=0')!=nil
      @hoenn_review_failed_v09910=true
    end
    pmd_ac_v09910_log_event(category,message)
  end

  def log_hoenn_verify_v09910(name,pass,detail)
    @hoenn_review_failed_v09910=true unless pass;log_event(:verify,name+' pass='+(pass ? '1':'0')+' '+detail)
  end

  def update_verification_script
    unless gameplay_review_hoenn_v09910?;pmd_ac_v09910_update_verification_script;return;end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1;f=@verification_frame;r=@hoenn_review_report_v09910 || PMD_AC.hoenn_gameplay_review_audit_v09910
    if f>=2 && !@verification_done[:v09910_coverage]
      pass=r[:pass] && r[:rows].size==135;log_hoenn_verify_v09910('HOENN_REVIEW_COVERAGE_V09910',pass,'reviewed=135/135 cumulative=386 pending=108 fields=18');@verification_done[:v09910_coverage]=true
    end
    if f>=10 && !@verification_done[:v09910_profile]
      sl=PMD_AC.gameplay_review_row_v09910(:slaking);sh=PMD_AC.gameplay_review_row_v09910(:shedinja);mi=PMD_AC.gameplay_review_row_v09910(:milotic);mg=PMD_AC.gameplay_review_row_v09910(:metagross)
      pass=sl[:role]==:bruiser && sl[:movement_policy]==:berserker && sh[:role]==:assassin && sh[:basic_attack_range_style][:range]==1 && mi[:role]==:bodyguard && mi[:physical_special_identity]==:special && mg[:role]==:bodyguard && mg[:physical_special_identity]==:physical
      log_hoenn_verify_v09910('HOENN_PROFILE_IDENTITY_V09910',pass,'slaking=physical_berserker shedinja=melee_assassin milotic=ranged_bodyguard metagross=physical_bodyguard');@verification_done[:v09910_profile]=true
    end
    if f>=18 && !@verification_done[:v09910_basic]
      tr=PMD_AC.review_profile_for_v09910(:treecko,:normal);bl=PMD_AC.review_profile_for_v09910(:blaziken,:normal);sw=PMD_AC.review_profile_for_v09910(:swampert,:normal);ga=PMD_AC.review_profile_for_v09910(:gardevoir,:normal);jo=PMD_AC.review_profile_for_v09910(:chikorita,:normal)
      pass=tr[:basic_damage_category]==:special && tr[:basic_move_type]==:grass && bl[:basic_damage_category]==:physical && bl[:basic_move_type]==:fighting && sw[:basic_damage_category]==:physical && sw[:basic_move_type]==:ground && ga[:basic_damage_category]==:special && jo[:basic_damage_category]==:special
      log_hoenn_verify_v09910('HOENN_BASIC_CATEGORY_BRIDGE_V09910',pass,'treecko=grass_special blaziken=fighting_physical swampert=ground_physical gardevoir=psychic_special johto_fallback=1');@verification_done[:v09910_basic]=true
    end
    if f>=26 && !@verification_done[:v09910_evolution]
      az=PMD_AC.gameplay_review_row_v09910(:azurill);wy=PMD_AC.gameplay_review_row_v09910(:wynaut);ro=PMD_AC.gameplay_review_row_v09910(:roselia);du=PMD_AC.gameplay_review_row_v09910(:dusclops)
      rkeys=ro[:evolution_progression].collect{|x|x[:species]};dkeys=du[:evolution_progression].collect{|x|x[:species]}
      pass=az[:evolution_progression].size>=3 && wy[:evolution_progression].size>=2 && !rkeys.include?(:budew) && !rkeys.include?(:roserade) && !dkeys.include?(:dusknoir)
      log_hoenn_verify_v09910('HOENN_CROSSGEN_EVOLUTION_V09910',pass,'azurill_marill_line=1 wynaut_wobbuffet_line=1 future_budew_roserade_dusknoir_pending=1');@verification_done[:v09910_evolution]=true
    end
    if f>=34 && !@verification_done[:v09910_special]
      ks=[:wurmple,:slaking,:nincada,:shedinja,:feebas,:castform,:wynaut,:beldum,:deoxys]
      pass=ks.all?{|sk|PMD_AC.gameplay_review_row_v09910(sk)[:identity_note]!=nil}
      log_hoenn_verify_v09910('HOENN_SPECIAL_IDENTITY_V09910',pass,'wurmple=branch slaking=truant nincada=shedinja_spawn shedinja=1hp_wonder_guard feebas=growth castform=forecast wynaut=counter beldum=sparse deoxys=forms');@verification_done[:v09910_special]=true
    end
    if f>=42 && !@verification_done[:v09910_forms]
      cf=PMD_AC.gameplay_review_row_v09910(:castform)[:form_differences];dx=PMD_AC.gameplay_review_row_v09910(:deoxys)[:form_differences]
      reviewed=(cf+dx).find_all{|x|x[:review_profile]!=nil}
      pass=r[:enabled_forms].empty? && r[:review_form_profiles].size==6 && reviewed.size==6 && reviewed.all?{|x|x[:runtime_profile]==nil}
      log_hoenn_verify_v09910('HOENN_FORM_REVIEW_V09910',pass,'ruleset_enabled_non_normal=0 review_only_profiles=6 castform=3 deoxys=3 runtime_profiles=0');@verification_done[:v09910_forms]=true
    end
    if f>=50 && !@verification_done[:v09910_report]
      pass=@hoenn_review_written_v09910 && @hoenn_queue_written_v09910 && FileTest.exist?(PMD_AC::HOENN_GAMEPLAY_REVIEW_FILE_V09910) && FileTest.exist?(PMD_AC::GAMEPLAY_REVIEW_QUEUE_FILE_V09910)
      log_hoenn_verify_v09910('HOENN_REVIEW_REPORT_V09910',pass,'review_file='+PMD_AC::HOENN_GAMEPLAY_REVIEW_FILE_V09910+' queue=386_reviewed_108_pending');@verification_done[:v09910_report]=true
    end
    if f>=58 && !@verification_done[:v09910_final]
      pass=!@hoenn_review_failed_v09910 && r[:pass];log_hoenn_verify_v09910('GAMEPLAY_REVIEW_HOENN_V09910',pass,'species=135/135 manual_profiles=135 cumulative=386 core_direct_modification=0 next=0387-0494');@verification_done[:v09910_final]=true
    end
    complete_verification_mode if f>=PMD_AC::HOENN_VERIFY_END_V09910
  end
end
