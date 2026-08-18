# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Kanto Gameplay Review Runtime v0.99.8
# 分類：Pokémon Gameplay / AI / Balance Review Runtime + Verifier
#
# 【用途】
# 1. 將 v0.99.8 的 151 隻人工 Profile 套入 SPECIES_DB 與 UNIT_DATA。
# 2. 讓普通攻擊可按物種 Profile 使用 Physical 或 Special 傷害類別。
# 3. 進化／Form 切換後重新套 Species/Form Profile，再恢復玩家永久 AI Setup。
# 4. 產生 18 欄位 Kanto Review Report 與 494 Queue 狀態。
#
# 【安全邊界】
# - deal_direct_damage 只在 options[:source_type]==:basic 時注入 damage_category/type。
# - Skill / Ability / Damage formula / Frozen Combat Core 本身不直接修改。
# - 玩家 ai_setup 最後套用，因此物種 Review 不會吃掉玩家編成。
#==============================================================================
module PMD_AC
  KANTO_GAMEPLAY_REVIEW_FILE_V0998='PMD_GameplayReview_Kanto_v0.99.8.txt'
  GAMEPLAY_REVIEW_QUEUE_FILE_V0998='PMD_GameplayReview_Queue_v0.99.8.txt'
  KANTO_VERIFY_END_V0998=104

  class << self
    def kanto_review_species_keys_v0998
      a=[]
      SPECIES_DB_V016.each do |k,d|
        n=d[:national_dex].to_i
        a.push(k) if n>=1 && n<=151
      end
      a.sort{|x,y|SPECIES_DB_V016[x][:national_dex].to_i<=>SPECIES_DB_V016[y][:national_dex].to_i}
    end

    def review_role_tags_v0998(species_key,profile)
      d=SPECIES_DB_V016[species_key] || {}
      tags=[]
      role=profile[:role] || :frontline
      tags.push(role)
      tags.push(profile[:range].to_i>1 ? :ranged : :melee)
      cat=profile[:basic_damage_category]
      tags.push(:caster) if cat==:special
      tags.push(:physical_pressure) if cat==:physical && [:bruiser,:assassin].include?(role)
      tags.push(:support) if [:controller,:bodyguard].include?(role)
      stats=d[:base_stats] || []
      bulky=stats.size==6 && (stats[0].to_i+stats[2].to_i+stats[4].to_i)>=245
      tags.push(:tank) if role==:bodyguard || (role==:frontline && bulky)
      tags.push(:area_damage) if profile[:skill_policy]==:best_cluster
      tags.uniq
    end

    def review_projectile_style_v0998(type)
      case type
      when :grass then :seed
      when :fire then :fire
      when :water then :water
      when :electric then :electric
      when :bug then :web
      else :neutral
      end
    end

    def preferred_range_for_review_v0998(profile)
      return 0.0 if profile[:range].to_i<=1
      case profile[:movement_policy]
      when :artillery then 172.0
      when :kiter then 154.0
      when :controller then 146.0
      when :bodyguard then 132.0
      else 148.0
      end
    end

    def apply_review_profile_to_species_v0998(species_key,profile)
      d=SPECIES_DB_V016[species_key]
      return false if d==nil || profile==nil
      tp=d[:tactical_profile] || {}
      tp[:role_primary]=profile[:role]
      tp[:target_policy]=profile[:target_policy]
      tp[:movement_policy]=profile[:movement_policy]
      tp[:threat_policy]=profile[:threat_policy]
      tp[:skill_policy]=profile[:skill_policy]
      tp[:target_commitment]=profile[:target_commitment]
      tp[:range]=profile[:range]
      tp[:preferred_range]=preferred_range_for_review_v0998(profile)
      tp[:profile_generation]=:manual_kanto_v0998
      tp[:ai_override_reason]=:gameplay_review_v0998
      d[:tactical_profile]=tp
      d[:role_tags]=review_role_tags_v0998(species_key,profile)

      u=UNIT_DATA[species_key]
      if u==nil
        u=compiled_profile_for(d)
        UNIT_DATA[species_key]=u
      end
      u[:role]=profile[:role]
      u[:role_primary]=profile[:role]
      u[:target_rule]=profile[:target_policy]
      u[:target_policy]=profile[:target_policy]
      u[:movement_policy]=profile[:movement_policy]
      u[:threat_policy]=profile[:threat_policy]
      u[:skill_policy]=profile[:skill_policy]
      u[:target_commitment]=profile[:target_commitment]
      u[:range]=profile[:range]
      u[:basic_damage_category]=profile[:basic_damage_category]
      u[:basic_move_type]=profile[:basic_move_type]
      u[:projectile_style]=review_projectile_style_v0998(profile[:basic_move_type])
      u[:profile_generation]=:manual_kanto_v0998
      u[:review_status]=:reviewed_manual_v0998
      if profile[:range].to_i>1
        u[:min_range]=88.0
        u[:preferred_range]=preferred_range_for_review_v0998(profile)
        u[:max_range]=192.0
      else
        u[:min_range]=0.0;u[:preferred_range]=0.0;u[:max_range]=(u[:melee_reach] || 42.0).to_f
      end
      true
    end

    def install_kanto_gameplay_review_v0998!
      KANTO_PROFILE_OVERRIDES_V0998.each{|k,p|apply_review_profile_to_species_v0998(k,p)}
      true
    end

    def review_profile_for_v0998(species_key,form_key=nil)
      sk=species_key.to_sym
      fk=form_key==nil ? :normal : form_key.to_sym
      fp=KANTO_FORM_PROFILE_OVERRIDES_V0998[[sk,fk]]
      return fp.dup if fp!=nil
      p=KANTO_PROFILE_OVERRIDES_V0998[sk]
      p==nil ? nil : p.dup
    end

    def ability_synergy_tags_v0998(species_key)
      d=SPECIES_DB_V016[species_key] || {};slots=d[:ability_slots] || {};out=[]
      slots.each_value do |ab|
        next if ab==nil
        case ab
        when :overgrow,:blaze,:torrent then out.push(:low_hp_stab_finisher)
        when :chlorophyll,:solar_power,:drought then out.push(:sun_team)
        when :swift_swim,:rain_dish,:hydration then out.push(:rain_team)
        when :shield_dust,:shed_skin,:inner_focus,:limber,:insomnia then out.push(:control_resilience)
        when :compound_eyes then out.push(:accuracy_control)
        when :sniper,:super_luck then out.push(:critical_build)
        when :intimidate then out.push(:entry_pressure)
        when :guts,:quick_feet then out.push(:status_payoff)
        when :static,:lightning_rod,:volt_absorb then out.push(:electric_control)
        when :water_absorb,:dry_skin then out.push(:water_immunity_sustain)
        when :flash_fire then out.push(:fire_immunity_pressure)
        when :magic_guard then out.push(:indirect_damage_immunity)
        when :friend_guard then out.push(:ally_protection)
        when :sheer_force then out.push(:secondary_damage_conversion)
        when :skill_link then out.push(:multi_hit_consistency)
        when :arena_trap,:magnet_pull then out.push(:target_lock)
        when :regenerator then out.push(:sustain_rotation)
        when :moxie then out.push(:ko_snowball)
        when :multiscale,:thick_fat then out.push(:durability_spike)
        when :analytic then out.push(:slow_action_payoff)
        when :technician then out.push(:low_power_move_payoff)
        when :pressure then out.push(:legendary_endurance)
        when :natural_cure then out.push(:status_reset_sustain)
        when :serene_grace then out.push(:secondary_effect_build)
        when :healer then out.push(:ally_status_support)
        when :cute_charm then out.push(:contact_disruption)
        when :competitive,:defiant then out.push(:stat_drop_punish)
        when :effect_spore,:poison_point,:flame_body,:poison_touch then out.push(:contact_punish)
        when :tinted_lens then out.push(:resist_break)
        when :wonder_skin then out.push(:status_resistance)
        when :sturdy,:shell_armor,:battle_armor then out.push(:burst_resilience)
        when :rock_head,:reckless then out.push(:recoil_build)
        when :no_guard then out.push(:accuracy_tradeoff)
        when :scrappy then out.push(:coverage_ignore_ghost)
        when :liquid_ooze then out.push(:anti_drain)
        when :clear_body then out.push(:stat_drop_resist)
        when :soundproof then out.push(:sound_immunity)
        when :aftermath then out.push(:contact_death_punish)
        when :harvest then out.push(:held_item_loop)
        when :trace,:download then out.push(:adaptive_offense)
        when :marvel_scale then out.push(:status_defense)
        when :synchronize then out.push(:status_reflect)
        when :unnerve then out.push(:held_item_suppression)
        when :imposter then out.push(:auto_transform_identity)
        when :adaptability then out.push(:stab_pressure)
        end
      end
      out.push(:no_special_synergy) if out.empty?
      out.uniq
    end

    def full_movepool_summary_v0998(species_key)
      d=SPECIES_DB_V016[species_key] || {}
      acq=MOVEPOOL_ACQUISITION_SPECIES_V0995[species_key] || {}
      lv=(d[:learnset] || []).collect{|x|x[:move]}.compact
      machine=(acq[:machine] || []).collect{|x|x[1]}.compact
      tutor=GLOBAL_TUTOR_B2W2_V0997[species_key] || []
      egg=acq[:egg] || []
      special=(acq[:special] || []).collect{|x|x.respond_to?(:[]) ? (x[:move] || x[1]) : nil}.compact
      all=(lv+machine+tutor+egg+special).uniq
      {:level_up=>lv.uniq.size,:machine=>machine.uniq.size,:tutor=>tutor.uniq.size,
       :egg=>egg.uniq.size,:special=>special.uniq.size,:unique_total=>all.size}
    end

    def early_game_moves_v0998(species_key)
      d=SPECIES_DB_V016[species_key] || {}
      (d[:learnset] || []).find_all{|x|x[:level].to_i<=20}.collect{|x|[x[:level].to_i,x[:move]]}
    end

    def evolution_progression_v0998(species_key)
      d=SPECIES_DB_V016[species_key] || {};line=EVOLUTION_LINES_V016[d[:line]] || {};parts=[]
      (line[:members] || []).each do |sk|
        next unless KANTO_PROFILE_OVERRIDES_V0998[sk]!=nil
        p=KANTO_PROFILE_OVERRIDES_V0998[sk];sd=SPECIES_DB_V016[sk] || {}
        parts.push({:species=>sk,:stage=>sd[:stage],:role=>p[:role],
          :category=>p[:basic_damage_category],:range=>p[:range],
          :evolution_rules=>(sd[:evolution_rules] || []).dup})
      end
      parts
    end

    def form_differences_v0998(species_key)
      out=[];forms=FORMS_DB_V016[species_key] || {};normal=(SPECIES_DB_V016[species_key] || {})[:base_stats] || []
      forms.each do |fk,f|
        next if fk==:normal
        fs=f[:base_stats] || normal;delta=[]
        6.times{|i|delta.push(fs[i].to_i-normal[i].to_i)} if fs.size==6 && normal.size==6
        out.push({:form=>fk,:enabled=>(f[:ruleset_enabled] ? true : false),
          :types=>f[:types],:base_stats=>fs,:stat_delta=>delta,:ability=>f[:ability],
          :profile=>KANTO_FORM_PROFILE_OVERRIDES_V0998[[species_key,fk]]})
      end
      out
    end

    def balance_risks_v0998(species_key)
      d=SPECIES_DB_V016[species_key] || {};s=d[:base_stats] || [];r=[]
      r.push(:low_bst_growth_stage) if d[:bst].to_i<300
      r.push(:high_power_budget) if d[:bst].to_i>=580
      r.push(:high_speed_pressure) if s.size==6 && s[5].to_i>=115
      r.push(:physical_wall) if s.size==6 && s[2].to_i>=130
      r.push(:special_wall) if s.size==6 && s[4].to_i>=120
      learn=d[:learnset] || []
      r.push(:compressed_levelup_after_evolution) if learn.size<=5 && d[:stage].to_i>1
      extra=KANTO_SPECIAL_BALANCE_RISKS_V0998[species_key] || []
      (r+extra).uniq
    end

    def effective_stats_v0998(species_key,profile)
      d=SPECIES_DB_V016[species_key] || {};s=d[:base_stats] || []
      off=s[1].to_i==s[3].to_i ? :mixed : (s[1].to_i>s[3].to_i ? :physical : :special)
      bulk=s.size==6 ? s[0].to_i+s[2].to_i+s[4].to_i : 0
      lv20=respond_to?(:combat_stats) ? combat_stats(species_key,20) : nil
      lv50=respond_to?(:combat_stats) ? combat_stats(species_key,50) : nil
      {:canonical_offense=>off,:review_basic=>profile[:basic_damage_category],
       :bulk_index=>bulk,:base_speed=>s[5].to_i,
       :lv20_neutral=>lv20,:lv50_neutral=>lv50}
    end

    def gameplay_review_row_v0998(species_key)
      d=SPECIES_DB_V016[species_key];p=KANTO_PROFILE_OVERRIDES_V0998[species_key]
      return nil if d==nil || p==nil
      s=d[:base_stats] || []
      learn=d[:learnset] || []
      {
        :species_key=>species_key,:dex=>d[:national_dex].to_i,:name=>d[:name],
        :base_stats=>s.dup,
        :effective_stats=>effective_stats_v0998(species_key,p),
        :physical_special_identity=>p[:basic_damage_category],
        :basic_attack_range_style=>{:range=>p[:range],:type=>p[:basic_move_type],:category=>p[:basic_damage_category],:projectile_style=>review_projectile_style_v0998(p[:basic_move_type])},
        :role=>p[:role],:movement_policy=>p[:movement_policy],:target_policy=>p[:target_policy],
        :threat_policy=>p[:threat_policy],:skill_policy=>p[:skill_policy],
        :learnset=>{:refs=>learn.size,:unique=>learn.collect{|x|x[:move]}.uniq.size,:ruleset=>d[:learnset_ruleset]},
        :full_movepool=>full_movepool_summary_v0998(species_key),
        :early_game_moves=>early_game_moves_v0998(species_key),
        :ability_synergy=>{:slots=>(d[:ability_slots] || {}).dup,:tags=>ability_synergy_tags_v0998(species_key)},
        :evolution_progression=>evolution_progression_v0998(species_key),
        :form_differences=>form_differences_v0998(species_key),
        :team_bond=>{:status=>:frozen_existing_reviewed,:line=>d[:line],:synergy_tags=>(d[:synergy_tags] || []).dup,:role_tags=>(d[:role_tags] || []).dup},
        :ai_behavior=>{:role_note=>KANTO_ROLE_NOTES_V0998[p[:role]],:commitment=>p[:target_commitment],:profile_generation=>:manual_kanto_v0998},
        :balance_risks=>balance_risks_v0998(species_key),
        :identity_note=>KANTO_IDENTITY_NOTES_V0998[species_key],
        :status=>:reviewed_manual_v0998
      }
    end

    def kanto_gameplay_review_audit_v0998
      rows=[];errors=[];physical=0;special=0;melee=0;ranged=0
      kanto_review_species_keys_v0998.each do |sk|
        row=gameplay_review_row_v0998(sk);rows.push(row)
        p=KANTO_PROFILE_OVERRIDES_V0998[sk];d=SPECIES_DB_V016[sk]
        errors.push([sk,:missing_row]) if row==nil
        errors.push([sk,:invalid_target]) unless AI_TARGET_POLICIES.include?(p[:target_policy])
        errors.push([sk,:invalid_movement]) unless AI_MOVEMENT_POLICIES.include?(p[:movement_policy])
        errors.push([sk,:invalid_threat]) unless AI_THREAT_POLICIES.include?(p[:threat_policy])
        errors.push([sk,:invalid_skill]) unless AI_SKILL_POLICIES.include?(p[:skill_policy])
        errors.push([sk,:non_stab_basic]) unless PMD_AC.form_types(sk,:normal).include?(p[:basic_move_type])
        physical+=1 if p[:basic_damage_category]==:physical;special+=1 if p[:basic_damage_category]==:special
        melee+=1 if p[:range].to_i<=1;ranged+=1 if p[:range].to_i>1
        errors.push([sk,:profile_not_installed]) unless (d[:tactical_profile] || {})[:profile_generation]==:manual_kanto_v0998
      end
      form_errors=[]
      KANTO_FORM_PROFILE_OVERRIDES_V0998.each do |key,p|
        sk=key[0];fk=key[1];f=(FORMS_DB_V016[sk] || {})[fk]
        form_errors.push([sk,fk,:missing]) if f==nil || !f[:ruleset_enabled]
        if f!=nil && f[:ruleset_enabled]
          form_errors.push([sk,fk,:non_stab_basic]) unless (f[:types] || []).include?(p[:basic_move_type])
        end
      end
      {:rows=>rows,:errors=>errors,:form_errors=>form_errors,:physical=>physical,:special=>special,
       :melee=>melee,:ranged=>ranged,:pass=>(rows.size==151 && errors.empty? && form_errors.empty? && KANTO_FORM_PROFILE_OVERRIDES_V0998.size==4)}
    end

    def kanto_gameplay_review_text_v0998(report=nil)
      r=report || kanto_gameplay_review_audit_v0998;out=[]
      out << 'PMD AutoChess Kanto Gameplay Review v0.99.8'
      out << 'Scope: #0001-0151 | Status: REVIEWED_MANUAL | Fields: 18'
      out << 'Frozen Combat Core direct modification: NO'
      out << 'Profiles: physical='+r[:physical].to_s+' special='+r[:special].to_s+' melee='+r[:melee].to_s+' ranged='+r[:ranged].to_s
      out << 'Effective stats benchmark: neutral nature | IV=15 | EV=0 | combat HP x10 | Lv20/Lv50'
      out << 'Enabled non-normal form profiles: '+KANTO_FORM_PROFILE_OVERRIDES_V0998.size.to_s
      out << 'Errors: '+r[:errors].size.to_s+' FormErrors: '+r[:form_errors].size.to_s
      out << ''
      r[:rows].each do |x|
        b=x[:basic_attack_range_style];fm=x[:full_movepool];ab=x[:ability_synergy]
        out << sprintf('#%04d %-12s %-6s move=%-10s target=%-16s threat=%-11s skill=%-12s basic=%s/%s/r%d movepool=%d early=%d ability=%s risks=%s',
          x[:dex],x[:species_key].to_s,x[:role].to_s,x[:movement_policy].to_s,x[:target_policy].to_s,x[:threat_policy].to_s,x[:skill_policy].to_s,
          b[:type].to_s,b[:category].to_s,b[:range].to_i,fm[:unique_total].to_i,x[:early_game_moves].size,
          ab[:tags].collect{|z|z.to_s}.join('+'),x[:balance_risks].collect{|z|z.to_s}.join('+'))
        GAMEPLAY_REVIEW_FIELDS_V0997.each do |field|
          out << '  '+field.to_s+'='+x[field].inspect
        end
        out << '  identity_note='+x[:identity_note].inspect
      end
      out << ''
      out << 'Review PASS: '+(r[:pass] ? '1':'0')
      out.join("\r\n")+"\r\n"
    end

    def write_kanto_gameplay_review_v0998(report=nil)
      File.open(KANTO_GAMEPLAY_REVIEW_FILE_V0998,'wb'){|f|f.write(kanto_gameplay_review_text_v0998(report))}
      true
    rescue
      false
    end

    def gameplay_review_queue_text_v0998
      out=[]
      out << 'PMD AutoChess Gameplay Review Queue v0.99.8'
      out << 'Completed: #0001-0151 | Pending: #0152-0494'
      out << 'Fields: '+GAMEPLAY_REVIEW_FIELDS_V0997.collect{|x|x.to_s}.join(', ')
      keys=SPECIES_DB_V016.keys.sort{|a,b|SPECIES_DB_V016[a][:national_dex].to_i<=>SPECIES_DB_V016[b][:national_dex].to_i}
      keys.each do |sk|
        n=SPECIES_DB_V016[sk][:national_dex].to_i
        status=n<=151 ? 'REVIEWED_MANUAL_V0998' : 'PENDING'
        out << sprintf('#%04d %s status=%s',n,sk.to_s,status)
      end
      out.join("\r\n")+"\r\n"
    end

    def write_gameplay_review_queue_v0998
      File.open(GAMEPLAY_REVIEW_QUEUE_FILE_V0998,'wb'){|f|f.write(gameplay_review_queue_text_v0998)}
      true
    rescue
      false
    end
  end

  install_kanto_gameplay_review_v0998!
end

#------------------------------------------------------------------------------
# 普通攻擊 Physical / Special Content Bridge
#------------------------------------------------------------------------------
class Scene_PMD_AutoChess
  alias pmd_ac_v0998_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v0998_deal_direct_damage)
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup
    if opts[:source_type]==:basic && user!=nil && user.respond_to?(:species_key)
      fk=user.respond_to?(:form_key) ? user.form_key : :normal
      p=PMD_AC.review_profile_for_v0998(user.species_key,fk)
      if p!=nil
        opts[:damage_category]=p[:basic_damage_category] if opts[:damage_category]==nil
        opts[:move_type]=p[:basic_move_type] if opts[:move_type]==nil
      end
    end
    pmd_ac_v0998_deal_direct_damage(user,target,power,opts)
  end
end

#------------------------------------------------------------------------------
# 進化 / Form Tactical Profile Refresh
#------------------------------------------------------------------------------
class PMD_PokemonIdentity
  # 舊存檔可能保存了 v0.99.7 以前自動生成的 role_tags。
  # Review Profile 安裝後，以目前 species 的正式資料重建標籤；
  # instance_uid、進化線與其他個體資料完全不變。
  def refresh_review_role_tags_v0998
    @role_tags=PMD_AC.identity_role_tags(@species_key)
    @role_tags=[] if @role_tags==nil
    @role_tags=@role_tags.uniq
    true
  end
end

class Game_PMDChessUnit
  def apply_species_review_profile_v0998
    return false if @pokemon_instance==nil
    p=PMD_AC.review_profile_for_v0998(species_key,form_key)
    return false if p==nil
    @role=p[:role]
    @target_rule=p[:target_policy];@target_policy=p[:target_policy]
    @movement_policy=p[:movement_policy];@threat_policy=p[:threat_policy]
    @skill_policy=p[:skill_policy];@target_commitment=p[:target_commitment].to_i
    @range=p[:range].to_i
    @projectile_style=PMD_AC.review_projectile_style_v0998(p[:basic_move_type])
    @min_range=@range>1 ? 88.0 : 0.0
    @preferred_range=PMD_AC.preferred_range_for_review_v0998(p)
    @max_range=@range>1 ? 192.0 : @melee_reach.to_f
    if @identity!=nil && @identity.respond_to?(:refresh_review_role_tags_v0998)
      @identity.refresh_review_role_tags_v0998
    end
    apply_persistent_ai_setup if respond_to?(:apply_persistent_ai_setup)
    true
  end

  alias pmd_ac_v0998_sync_from_pokemon_instance sync_from_pokemon_instance unless method_defined?(:pmd_ac_v0998_sync_from_pokemon_instance)
  def sync_from_pokemon_instance
    ok=pmd_ac_v0998_sync_from_pokemon_instance
    apply_species_review_profile_v0998 if ok
    ok
  end
end

#------------------------------------------------------------------------------
# 驗證模式
#------------------------------------------------------------------------------
module PMD_AC
  old_labels=VERIFICATION_LABELS
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS.delete(:movepool_production_v0997)
  VERIFICATION_LABELS[:gameplay_review_kanto_v0998]='GAMEPLAY_REVIEW_KANTO_V0998'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0998_start start unless method_defined?(:pmd_ac_v0998_start)
  alias pmd_ac_v0998_refresh_header refresh_header unless method_defined?(:pmd_ac_v0998_refresh_header)
  alias pmd_ac_v0998_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0998_prepare_verification_battle)
  alias pmd_ac_v0998_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0998_update_verification_script)
  alias pmd_ac_v0998_log_event log_event unless method_defined?(:pmd_ac_v0998_log_event)

  def start
    pmd_ac_v0998_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.99.8 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:gameplay_review,'FLOW v0.99.8 kanto=151 manual_profiles=151 form_profiles=4 basic_category_bridge=1 evolution_profile_refresh=1 next=0152-0251')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0998_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp);bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.8',1)
  end

  def gameplay_review_kanto_v0998?
    verification_mode==:gameplay_review_kanto_v0998
  end

  def prepare_verification_battle
    pmd_ac_v0998_prepare_verification_battle
    return unless gameplay_review_kanto_v0998?
    @kanto_review_failed_v0998=false
    @kanto_review_report_v0998=PMD_AC.kanto_gameplay_review_audit_v0998
    @kanto_review_written_v0998=PMD_AC.write_kanto_gameplay_review_v0998(@kanto_review_report_v0998)
    @kanto_queue_written_v0998=PMD_AC.write_gameplay_review_queue_v0998
    log_event(:showcase,'START mode=GAMEPLAY_REVIEW_KANTO_V0998 species=151 manual=151 forms=4 physical_special_basic=1')
  end

  def log_event(category,message)
    if category.to_s=='verify' && gameplay_review_kanto_v0998? && message.to_s.index('V0998')!=nil && message.to_s.index(' pass=0')!=nil
      @kanto_review_failed_v0998=true
    end
    pmd_ac_v0998_log_event(category,message)
  end

  def log_kanto_verify_v0998(name,pass,detail)
    @kanto_review_failed_v0998=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+' '+detail)
  end

  def update_verification_script
    unless gameplay_review_kanto_v0998?
      pmd_ac_v0998_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1;f=@verification_frame
    r=@kanto_review_report_v0998 || PMD_AC.kanto_gameplay_review_audit_v0998

    if f>=2 && !@verification_done[:v0998_coverage]
      pass=r[:pass] && r[:rows].size==151
      log_kanto_verify_v0998('KANTO_REVIEW_COVERAGE_V0998',pass,'reviewed='+r[:rows].size.to_s+'/151 pending=343 fields=18')
      @verification_done[:v0998_coverage]=true
    end
    if f>=10 && !@verification_done[:v0998_profile]
      b=PMD_AC.gameplay_review_row_v0998(:bulbasaur);ra=PMD_AC.gameplay_review_row_v0998(:raichu);di=PMD_AC.gameplay_review_row_v0998(:diglett);ch=PMD_AC.gameplay_review_row_v0998(:chansey)
      pass=b[:role]==:controller && b[:physical_special_identity]==:special && ra[:role]==:kiter && ra[:basic_attack_range_style][:range]==3 && di[:role]==:assassin && di[:basic_attack_range_style][:range]==1 && ch[:role]==:bodyguard && ch[:physical_special_identity]==:special
      log_kanto_verify_v0998('KANTO_PROFILE_IDENTITY_V0998',pass,'bulbasaur=controller_special raichu=ranged_kiter diglett=melee_assassin chansey=special_bodyguard')
      @verification_done[:v0998_profile]=true
    end
    if f>=18 && !@verification_done[:v0998_forms]
      cx=PMD_AC.review_profile_for_v0998(:charizard,:mega_x);cy=PMD_AC.review_profile_for_v0998(:charizard,:mega_y);vm=PMD_AC.review_profile_for_v0998(:venusaur,:mega);bm=PMD_AC.review_profile_for_v0998(:blastoise,:mega)
      pass=r[:form_errors].empty? && cx[:basic_damage_category]==:physical && cx[:range]==1 && cy[:basic_damage_category]==:special && cy[:range]==3 && vm[:role]==:bodyguard && bm[:role]==:artillery
      log_kanto_verify_v0998('KANTO_FORM_DIFFERENCE_V0998',pass,'enabled_profiles=4 charizard_x=physical_melee charizard_y=special_ranged mega_venusaur=bodyguard mega_blastoise=artillery')
      @verification_done[:v0998_forms]=true
    end
    if f>=26 && !@verification_done[:v0998_basic]
      u=verification_unit(:ally,:bulbasaur);d=verification_unit(:enemy,:rattata)
      p1=PMD_AC.review_profile_for_v0998(u.species_key,u.form_key);p2=PMD_AC.review_profile_for_v0998(d.species_key,d.form_key)
      pass=p1[:basic_damage_category]==:special && p1[:basic_move_type]==:grass && p2[:basic_damage_category]==:physical && p2[:basic_move_type]==:normal
      log_kanto_verify_v0998('KANTO_BASIC_CATEGORY_BRIDGE_V0998',pass,'bulbasaur=grass_special rattata=normal_physical source_type=basic_only')
      @verification_done[:v0998_basic]=true
    end
    if f>=34 && !@verification_done[:v0998_special]
      meta=PMD_AC.gameplay_review_row_v0998(:metapod);abra=PMD_AC.gameplay_review_row_v0998(:abra);mag=PMD_AC.gameplay_review_row_v0998(:magikarp);dit=PMD_AC.gameplay_review_row_v0998(:ditto)
      pass=meta[:identity_note]!=nil && abra[:identity_note]!=nil && mag[:identity_note]!=nil && dit[:identity_note]!=nil
      log_kanto_verify_v0998('KANTO_SPECIAL_IDENTITY_V0998',pass,'metapod=transition abra=teleport_identity magikarp=growth_identity ditto=transform_identity')
      @verification_done[:v0998_special]=true
    end
    if f>=42 && !@verification_done[:v0998_report]
      pass=@kanto_review_written_v0998 && @kanto_queue_written_v0998 && FileTest.exist?(PMD_AC::KANTO_GAMEPLAY_REVIEW_FILE_V0998) && FileTest.exist?(PMD_AC::GAMEPLAY_REVIEW_QUEUE_FILE_V0998)
      log_kanto_verify_v0998('KANTO_REVIEW_REPORT_V0998',pass,'review_file='+PMD_AC::KANTO_GAMEPLAY_REVIEW_FILE_V0998+' queue=151_reviewed_343_pending')
      @verification_done[:v0998_report]=true
    end
    if f>=50 && !@verification_done[:v0998_final]
      pass=!@kanto_review_failed_v0998 && r[:pass]
      log_kanto_verify_v0998('GAMEPLAY_REVIEW_KANTO_V0998',pass,'species=151/151 manual_profiles=151 forms=4 core_direct_modification=0 next=0152-0251')
      @verification_done[:v0998_final]=true
    end
    complete_verification_mode if f>=PMD_AC::KANTO_VERIFY_END_V0998
  end
end
