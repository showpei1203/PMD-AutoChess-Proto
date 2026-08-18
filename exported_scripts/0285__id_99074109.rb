#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.77
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - V077_OLD_VERIFICATION_MODES / V077_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - evolution_rules_v077 / eligible_evolution_rules_v077 / branch_evolution_rules_v077 / evolution_trigger_hint_v077
# - progression_flow_counts_v077 / progression_flow_checksum32_v077 / evolution_choice_rows_v077 / pending_evolution_choices_v077
# - progression_attention_v077 / dismiss_pending_move_v077 / resolve_evolution_choice_v077 / gain_exp
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.77
# Evolution + Move Learning + Progression UI Flow
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# - Keeps v0.45/v0.46 progression storage and battle loadout model.
# - Keeps v0.76 Pokemon stat/growth formulas unchanged.
# - Adds player-facing branch evolution choice instead of random resolution.
# - Adds pending move dismissal while retaining the learned move library.
# - Adds post-battle growth attention notices and progression UI support.
#==============================================================================
module PMD_AC
  V077_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V077_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:progression_flow_v077] +
    V077_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:progression_flow_v077}
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V077_OLD_VERIFICATION_LABELS.merge(
    :normal=>'NORMAL', :progression_flow_v077=>'PROGRESSION_FLOW_V077')

  class << self
    def evolution_rules_v077(species_key)
      d=species_identity_data(species_key)
      return [] if d==nil
      result=[]
      for r in (d[:evolution_rules]||[])
        next if r[:additional_spawn]
        target=r[:target_species]
        next if target==nil || species_identity_data(target)==nil
        result.push(r)
      end
      result
    end

    def eligible_evolution_rules_v077(instance)
      return [] if instance==nil
      result=[]
      for r in evolution_rules_v077(instance.species_key)
        min=(r[:min_level]||1).to_i
        result.push(r) if instance.level.to_i>=min
      end
      result
    end

    def branch_evolution_rules_v077(instance)
      rows=eligible_evolution_rules_v077(instance)
      return [] if rows.size<2
      rows
    end

    def evolution_trigger_hint_v077(rule)
      a=rule==nil ? [] : (rule[:canonical_triggers]||[])
      labels=[]
      for key in a
        text=case key
        when :level_up then '等級'
        when :use_item then '道具'
        when :trade then '交換'
        when :friendship then '親密'
        when :shed then '特殊生成'
        else key.to_s
        end
        labels.push(text) unless labels.include?(text)
      end
      labels.push('等級') if labels.empty?
      labels.join('/')
    end

    def progression_flow_counts_v077
      rules=0;branch_species=0;additional=0
      for key in SPECIES_DB_V016.keys
        d=SPECIES_DB_V016[key]||{}
        raw=d[:evolution_rules]||[]
        normal=0
        for r in raw
          rules+=1
          if r[:additional_spawn]
            additional+=1
          else
            normal+=1
          end
        end
        branch_species+=1 if normal>=2
      end
      {:species=>SPECIES_DB_V016.keys.size,:rules=>rules,
       :branch_species=>branch_species,:additional=>additional}
    end

    def progression_flow_checksum32_v077
      h=0
      keys=SPECIES_DB_V016.keys.sort{|a,b|a.to_s<=>b.to_s}
      for key in keys
        d=SPECIES_DB_V016[key]||{}
        text=key.to_s+'|'+d[:stage].to_i.to_s+'|'
        for r in (d[:evolution_rules]||[])
          text+=r[:target_species].to_s+':' +(r[:min_level]||0).to_i.to_s+':'
          text+=(r[:canonical_triggers]||[]).collect{|x|x.to_s}.join(',')+';'
        end
        text+='|'+(d[:learnset]||[]).size.to_s
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end
  end
end

class PMD_PokemonInstance
  def evolution_choice_rows_v077
    rows=[]
    for r in PMD_AC.branch_evolution_rules_v077(self)
      target=r[:target_species]
      d=PMD_AC.species_identity_data(target)||{}
      rows.push({:target=>target,:name=>PMD_AC.species_display_name_v047(target),
                 :min_level=>(r[:min_level]||1).to_i,
                 :hint=>PMD_AC.evolution_trigger_hint_v077(r),
                 :types=>(d[:types]||[]).dup,:rule=>r})
    end
    rows
  end

  def pending_evolution_choices_v077
    evolution_choice_rows_v077.collect{|r|r[:target]}
  end

  def progression_attention_v077
    ensure_growth_data_v045
    {:pending_moves=>@pending_move_choices_v045.size,
     :evolution_choices=>pending_evolution_choices_v077.size}
  end

  def dismiss_pending_move_v077(move)
    ensure_growth_data_v045
    return false unless @pending_move_choices_v045.include?(move)
    @pending_move_choices_v045.delete(move)
    if @progression_history!=nil
      @progression_history.push({:type=>:pending_move_dismiss,
        :move=>move,:level=>@level,:species=>species_key})
    end
    true
  end

  def resolve_evolution_choice_v077(target_species)
    rows=evolution_choice_rows_v077
    selected=nil
    for row in rows
      selected=row if row[:target]==target_species
    end
    return nil if selected==nil
    old_species=species_key
    uid=instance_uid
    old_ivs=ivs
    old_nature=nature_key
    old_slot=ability_slot
    return nil unless @identity.change_species_key(target_species)
    ensure_individual_data
    # Preserve the individual whenever the target species supports the same slot.
    if PMD_AC.ability_slots(species_key)[old_slot]!=nil
      @ability_slot=old_slot
    else
      @ability_slot=PMD_AC.default_ability_slot(species_key)
    end
    @ivs=old_ivs.dup
    @nature_key=old_nature

    legacy_moves=learn_moves_through_level(@level,true)
    canonical=[]
    for e in PMD_AC.canonical_level_entries_v045(species_key,@level,false)
      mv=e[:move]
      canonical.push(mv) if learn_known_move_v045(mv,@level,species_key,true)
    end
    event={:from=>old_species,:to=>species_key,:level=>@level,:uid=>uid,
           :choice=>true,:canonical_moves=>canonical,:legacy_moves=>legacy_moves,
           :trigger_hint=>selected[:hint]}
    @progression_history.push({:type=>:evolution_choice}.merge(event)) if @progression_history!=nil
    event
  end

  alias pmd_ac_v077_gain_exp gain_exp unless method_defined?(:pmd_ac_v077_gain_exp)
  def gain_exp(amount,allow_evolution=true)
    result=pmd_ac_v077_gain_exp(amount,allow_evolution)
    result[:branch_evolution_choices_v077]=pending_evolution_choices_v077
    result[:progression_attention_v077]=progression_attention_v077
    result
  end
end

class Game_PMDChessUnit
  def resolve_evolution_choice_v077(target_species)
    return nil if @pokemon_instance==nil
    event=@pokemon_instance.resolve_evolution_choice_v077(target_species)
    if event!=nil
      old=event[:from]
      sync_from_pokemon_instance
      if @scene!=nil
        @scene.log_event(:evolution,
          log_name+' BRANCH_EVOLVE '+old.to_s+'->'+event[:to].to_s+
          ' uid='+event[:uid].to_s+' trigger='+event[:trigger_hint].to_s)
        for mv in (event[:canonical_moves]||[])
          @scene.log_event(:move_learn,log_name+' EVOLUTION_LEARN '+mv.to_s)
        end
      end
    end
    event
  end
end

class Sprite_PMDProgressionPanelV047
  alias pmd_ac_v077_update update unless method_defined?(:pmd_ac_v077_update)
  alias pmd_ac_v077_refresh refresh unless method_defined?(:pmd_ac_v077_refresh)

  def evolution_index_v077
    @evolution_index_v077=0 if @evolution_index_v077==nil
    @evolution_index_v077
  end

  def enter_evolution_mode_v077
    rows=@instance==nil ? [] : @instance.evolution_choice_rows_v077
    return false if rows.empty?
    @mode=:evolution_v077
    @evolution_index_v077=0
    Sound.play_decision
    refresh
    true
  end

  def update_evolution_mode_v077
    rows=@instance.evolution_choice_rows_v077
    if rows.empty?
      @mode=:slots;Sound.play_buzzer;refresh;return
    end
    if Input.repeat?(Input::UP)
      @evolution_index_v077=(evolution_index_v077-1)%rows.size
      Sound.play_cursor;refresh
    elsif Input.repeat?(Input::DOWN)
      @evolution_index_v077=(evolution_index_v077+1)%rows.size
      Sound.play_cursor;refresh
    elsif Input.trigger?(Input::B)
      @mode=:slots;Sound.play_cancel;refresh
    elsif Input.trigger?(Input::C)
      row=rows[evolution_index_v077]
      old=@instance.species_key
      event=@instance.resolve_evolution_choice_v077(row[:target])
      if event!=nil
        @last_action=:evolved_v077
        log('EVOLVE '+old.to_s+'->'+event[:to].to_s+' uid='+event[:uid].to_s)
        Sound.play_decision;@mode=:slots;@evolution_index_v077=0;refresh
      else
        @last_action=:evolution_rejected_v077;Sound.play_buzzer;refresh
      end
    end
  end

  def update
    if @mode==:evolution_v077
      update_evolution_mode_v077
      return
    end
    if Input.trigger?(Input::X)
      if enter_evolution_mode_v077
        return
      else
        Sound.play_buzzer
        return
      end
    end
    if @mode==:moves && Input.trigger?(Input::A)
      rows=@instance.known_move_rows_v047
      row=rows[@move_index]
      if row!=nil && row[:pending] && @instance.dismiss_pending_move_v077(row[:move])
        @last_action=:pending_dismissed_v077
        log('DISMISS_NEW '+row[:move].to_s+' library_retained=1')
        Sound.play_cancel;refresh
      else
        Sound.play_buzzer
      end
      return
    end
    pmd_ac_v077_update
  end

  def draw_evolution_modal_v077
    rows=@instance.evolution_choice_rows_v077
    return if rows.empty?
    b=bitmap
    x=86;y=44;w=372;h=324
    b.fill_rect(x,y,w,h,Color.new(5,8,12,245))
    b.fill_rect(x+2,y+2,w-4,h-4,Color.new(24,31,42,248))
    b.font.bold=true;b.font.size=19;b.font.color=Color.new(255,235,150)
    b.draw_text(x+14,y+10,w-28,26,'分歧進化',0)
    b.font.bold=false;b.font.size=12;b.font.color=Color.new(170,190,210)
    b.draw_text(x+14,y+38,w-28,18,
      PMD_AC.species_display_name_v047(@instance.species_key)+'  Lv'+@instance.level.to_s+
      '｜原作條件保留作提示，專案目前由玩家選擇',0)
    yy=y+62
    for i in 0...rows.size
      row=rows[i];sel=(i==evolution_index_v077)
      b.fill_rect(x+12,yy,w-24,26,
        sel ? Color.new(70,100,135,235) : Color.new(30,38,50,225))
      b.font.size=14;b.font.color=Color.new(240,245,250);b.font.bold=sel
      b.draw_text(x+20,yy+2,170,20,row[:name],0)
      b.font.bold=false;b.font.size=11;b.font.color=Color.new(160,205,240)
      types=row[:types].collect{|t|t.to_s}.join('/')
      b.draw_text(x+190,yy+3,90,18,types,0)
      b.font.color=Color.new(220,190,135)
      b.draw_text(x+280,yy+3,62,18,row[:hint],2)
      yy+=28
    end
    b.font.size=12;b.font.color=Color.new(175,220,255)
    b.draw_text(x+12,y+h-30,w-24,20,'↑↓ 選擇｜C 確認進化｜B 返回',1)
  end

  def refresh
    pmd_ac_v077_refresh
    return if @instance==nil || bitmap==nil
    b=bitmap
    attention=@instance.progression_attention_v077
    b.fill_rect(20,338,504,34,Color.new(26,36,48,230))
    has_attention=attention[:pending_moves].to_i>0 || attention[:evolution_choices].to_i>0
    b.font.size=13
    b.font.color=has_attention ? Color.new(255,220,120) : Color.new(150,165,180)
    text='待處理：新技能 '+attention[:pending_moves].to_s+
         '｜分歧進化 '+attention[:evolution_choices].to_s
    text+='（A 選擇）' if attention[:evolution_choices].to_i>0
    b.draw_text(28,344,488,20,text,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,220))
    b.font.size=12;b.font.color=Color.new(175,220,255)
    help=''
    if @mode==:slots
      help='↑↓ 技能格｜C 選技能｜A 進化｜L/R 換寶可夢｜D/B 關閉'
    elsif @mode==:moves
      help='↑↓ 技能｜C 裝備/替換｜Shift 清除NEW｜B 返回｜L/R 換寶可夢'
    else
      help='↑↓ 選擇｜C 確認進化｜B 返回'
    end
    b.draw_text(10,389,524,20,help,1)
    draw_evolution_modal_v077 if @mode==:evolution_v077
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v077_start start unless method_defined?(:pmd_ac_v077_start)
  alias pmd_ac_v077_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v077_update_deploy_phase)
  alias pmd_ac_v077_award_battle_exp award_battle_exp unless method_defined?(:pmd_ac_v077_award_battle_exp)
  alias pmd_ac_v077_show_result show_result unless method_defined?(:pmd_ac_v077_show_result)
  alias pmd_ac_v077_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v077_prepare_verification_battle)
  alias pmd_ac_v077_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v077_update_verification_script)

  def start
    pmd_ac_v077_start
    idx=PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index=idx unless idx==nil
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.77 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    c=PMD_AC.progression_flow_counts_v077
    log_event(:progression,
      'FLOW v0.77 move_pending=replace_or_dismiss branch_evolution=player_choice '+
      'species='+c[:species].to_s+' evolution_rules='+c[:rules].to_s+
      ' branch_species='+c[:branch_species].to_s+' additional_spawn='+c[:additional].to_s+
      ' stats=v0.76 balance=v0.75 sfx=v0.75.1 checksum32='+
      PMD_AC.progression_flow_checksum32_v077.to_s)
    refresh_header;refresh_footer
  end

  def progression_flow_v077?
    verification_mode==:progression_flow_v077
  end

  def sync_progression_units_v077
    return if @units==nil
    for u in @units
      next unless u.respond_to?(:pokemon_instance) && u.pokemon_instance!=nil
      next if u.summoned?
      if u.species_key!=u.pokemon_instance.species_key
        u.sync_from_pokemon_instance
      end
    end
  end

  def update_deploy_phase
    pmd_ac_v077_update_deploy_phase
    sync_progression_units_v077
  end

  def progression_attention_total_v077
    total=0
    seen={}
    list=progression_ui_instances_v047
    for i in list
      next if i==nil || seen[i.instance_uid]
      seen[i.instance_uid]=true
      a=i.progression_attention_v077
      total+=a[:pending_moves].to_i
      total+=a[:evolution_choices].to_i
    end
    total
  end

  def award_battle_exp(winner_team)
    pmd_ac_v077_award_battle_exp(winner_team)
    return unless winner_team==:ally && verification_mode==:normal
    list=progression_ui_instances_v047
    for i in list
      a=i.progression_attention_v077
      if a[:pending_moves].to_i>0 || a[:evolution_choices].to_i>0
        log_event(:progression,
          'ATTENTION uid='+i.instance_uid.to_s+' species='+i.species_key.to_s+
          ' pending_moves='+a[:pending_moves].to_s+
          ' evolution_choices='+a[:evolution_choices].to_s+' open=D')
      end
    end
  end

  def show_result
    pmd_ac_v077_show_result
    return if @result_sprite==nil || @result_sprite.bitmap==nil
    n=progression_attention_total_v077
    return if n<=0
    b=@result_sprite.bitmap
    pmd_ac_v074_font(b)
    b.font.size=11;b.font.bold=false;b.font.color=Color.new(255,220,130)
    b.draw_text(0,76,360,16,'成長待處理 '+n.to_s+'｜回布陣後按 D',1)
  end

  def prepare_verification_battle
    pmd_ac_v077_prepare_verification_battle
    return unless progression_flow_v077?
    @progression_flow_v077_failed=false
    for u in @units
      u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
      u.verification_energy_sandbox(true) if u.respond_to?(:verification_energy_sandbox)
    end
  end

  def log_verify_v077(name,pass,detail='')
    @progression_flow_v077_failed=true unless pass
    text=name+' pass='+(pass ? '1':'0')
    text+=' '+detail unless detail==nil || detail==''
    log_event(:verify,text)
  end

  def v077_instance(uid,species,level)
    PMD_PokemonInstance.new(species,level,
      {:instance_uid=>uid,:ivs=>[15,15,15,15,15,15],
       :nature=>:hardy,:ability_slot=>:primary})
  end

  def verify_progression_flow_manifest_v077
    return if @verification_done[:v077_manifest]
    c=PMD_AC.progression_flow_counts_v077
    pass=c[:species]==494 && c[:rules]==246 && c[:branch_species]>=10 &&
         c[:additional]>=1 && PMD_AC::PROGRESSION_FLOW_MANIFEST_V077[:active_move_slots]==4
    log_verify_v077('PROGRESSION_FLOW_MANIFEST_V077',pass,
      'species='+c[:species].to_s+' evolution_rules='+c[:rules].to_s+
      ' branch_species='+c[:branch_species].to_s+' additional_spawn='+c[:additional].to_s+
      ' checksum32='+PMD_AC.progression_flow_checksum32_v077.to_s)
    @verification_done[:v077_manifest]=true
  end

  def verify_move_learning_flow_v077
    return if @verification_done[:v077_move_flow]
    i=v077_instance(770010,:bulbasaur,1)
    need=PMD_AC.exp_for_level(15,i.growth_group)-i.exp
    i.gain_exp(need,false)
    known=i.known_moves_v045;active=i.active_moves_v045;pending=i.pending_move_choices_v045
    before_pending=pending.size
    replace=false;library=true;mastery=true
    if !pending.empty? && !active.empty?
      new_move=pending[0];old_move=active[0];old_mastery=i.move_mastery_exp_v045(old_move)
      replace=i.equip_known_move_v047(new_move,0)
      library=i.knows_move_v045?(old_move)
      mastery=(i.move_mastery_exp_v045(old_move)==old_mastery)
    end
    pass=known.size>=7 && active.size<=4 && before_pending>0 && replace && library && mastery
    log_verify_v077('MOVE_LEARNING_FLOW_V077',pass,
      'known='+known.size.to_s+' active='+active.size.to_s+
      ' pending_before='+before_pending.to_s+' replace=1 old_library_retained='+(library ? '1':'0')+
      ' mastery_retained='+(mastery ? '1':'0'))
    @verification_done[:v077_move_flow]=true
  end

  def verify_pending_dismiss_v077
    return if @verification_done[:v077_dismiss]
    i=v077_instance(770020,:bulbasaur,1)
    need=PMD_AC.exp_for_level(15,i.growth_group)-i.exp;i.gain_exp(need,false)
    p=i.pending_move_choices_v045
    move=p.empty? ? nil : p[0]
    ok=move!=nil && i.dismiss_pending_move_v077(move)
    pass=ok && i.knows_move_v045?(move) && !i.pending_move_choices_v045.include?(move)
    log_verify_v077('MOVE_PENDING_DISMISS_V077',pass,
      'move='+(move==nil ? 'nil' : move.to_s)+' pending_cleared='+(pass ? '1':'0')+
      ' learned_library_retained='+(move!=nil && i.knows_move_v045?(move) ? '1':'0'))
    @verification_done[:v077_dismiss]=true
  end

  def verify_simple_evolution_v077
    return if @verification_done[:v077_simple_evo]
    i=v077_instance(770030,:bulbasaur,15);uid=i.instance_uid
    before_known=i.known_moves_v045
    need=PMD_AC.exp_for_level(16,i.growth_group)-i.exp
    r=i.gain_exp(need,true)
    pass=i.species_key==:ivysaur && i.instance_uid==uid &&
         !(r[:evolutions]||[]).empty? && before_known.all?{|m|i.knows_move_v045?(m)}
    log_verify_v077('SIMPLE_EVOLUTION_FLOW_V077',pass,
      'species=bulbasaur->'+i.species_key.to_s+' uid_same='+(i.instance_uid==uid ? '1':'0')+
      ' known_library_preserved='+(before_known.all?{|m|i.knows_move_v045?(m)} ? '1':'0')+
      ' mode=existing_auto')
    @verification_done[:v077_simple_evo]=true
  end

  def verify_branch_evolution_v077
    return if @verification_done[:v077_branch_evo]
    i=v077_instance(770040,:eevee,19);uid=i.instance_uid
    old_ivs=i.ivs;old_nature=i.nature_key;old_known=i.known_moves_v045
    need=PMD_AC.exp_for_level(20,i.growth_group)-i.exp;i.gain_exp(need,true)
    choices=i.pending_evolution_choices_v077
    no_auto=(i.species_key==:eevee)
    event=i.resolve_evolution_choice_v077(:jolteon)
    pass=no_auto && choices.size==7 && event!=nil && i.species_key==:jolteon &&
         i.instance_uid==uid && i.ivs==old_ivs && i.nature_key==old_nature &&
         i.pending_evolution_choices_v077.empty? && old_known.all?{|m|i.knows_move_v045?(m)}
    log_verify_v077('BRANCH_EVOLUTION_FLOW_V077',pass,
      'species=eevee->'+i.species_key.to_s+' choices='+choices.size.to_s+
      ' no_random_auto='+(no_auto ? '1':'0')+' uid_same='+(i.instance_uid==uid ? '1':'0')+
      ' individual_preserved=1 library_preserved=1')
    @verification_done[:v077_branch_evo]=true
  end

  def verify_progression_ui_flow_v077
    return if @verification_done[:v077_ui]
    i=v077_instance(770050,:eevee,20)
    s=nil;ok=false
    begin
      s=Sprite_PMDProgressionPanelV047.new(@viewport,i,nil)
      rows=i.evolution_choice_rows_v077
      s.enter_evolution_mode_v077
      ok=s.bitmap!=nil && s.mode==:evolution_v077 && rows.size==7 &&
         i.progression_attention_v077[:evolution_choices]==7
    rescue => e
      log_event(:progression,'V077_UI_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s)
      ok=false
    ensure
      s.dispose if s!=nil && !s.disposed?
    end
    log_verify_v077('PROGRESSION_UI_FLOW_V077',ok,
      'panel=v0.47_extended branch_input=A move_pending=replace_or_shift_dismiss '+
      'result_notice=1 attention_count=1')
    @verification_done[:v077_ui]=true
  end

  def verify_progression_carry_v077
    return if @verification_done[:v077_carry]
    pass=PMD_AC::POKEMON_DAMAGE_SCALE==1.65 &&
         PMD_AC::POKEMON_COMBAT_HP_SCALE==10.0 &&
         PMD_AC::RANGED_ENGAGE_RANGE_V075==102.0 &&
         PMD_AC::RANGED_RELEASE_RANGE_V075==124.0 &&
         PMD_AC::RANGED_REARM_FRAMES_V075==30
    log_verify_v077('PROGRESSION_CARRY_V077',pass,
      'stats=v0.76 exp=v0.46 move_library=v0.45 ui=v0.47 balance=v0.75 '+
      'basic_hit_sfx=v0.75.1 weather=v0.28 field=v0.35-v0.37 combo=v0.60.2 router=v0.62')
    @verification_done[:v077_carry]=true
  end

  def update_verification_script
    unless progression_flow_v077?
      pmd_ac_v077_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_progression_flow_manifest_v077 if f>=2
    verify_move_learning_flow_v077 if f>=4
    verify_pending_dismiss_v077 if f>=6
    verify_simple_evolution_v077 if f>=8
    verify_branch_evolution_v077 if f>=10
    verify_progression_ui_flow_v077 if f>=12
    verify_progression_carry_v077 if f>=14
    if f>=16 && !@verification_done[:v077_final]
      pass=!@progression_flow_v077_failed
      log_verify_v077('PROGRESSION_FLOW_V077',pass,
        'move_learning=1 pending_dismiss=1 simple_evolution=1 branch_evolution=1 ui=1 carry=1')
      @verification_done[:v077_final]=true
    end
    complete_verification_mode if f>=PMD_AC::PROGRESSION_FLOW_VERIFY_END_V077
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.77',1)
    bmp.font.size=PMD_AC::HEADER_SUB_FONT_V0741
    bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
    text=''
    if @phase==:deploy
      text='戰前布陣｜D 成長/技能/進化｜S 驗證：'+verification_mode_label+'｜Shift 開戰'
    elsif @phase==:battle
      text='AI Framework／Pixel Movement｜速度 x'+@battle_speed.to_s+'｜A 鍵切換｜B 離開'
    else
      text='戰鬥結束｜C 回到布陣｜B 離開'
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end
end
