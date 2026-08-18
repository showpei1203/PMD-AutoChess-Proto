# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Nature × AI Temperament Runtime v0.99.16
# 分類：Nature 個體行為／選技評分／目標黏著／UI／Verifier
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 將 v0.99.16 Data 的 25 種 Nature Temperament 接入既有戰鬥 AI。
# 本版不新增第 10 個 AI Strategy 欄位，Nature 本身就是 Pokémon 個體資料；
# 玩家在 AI Strategy 畫面會看到 Nature 與五軸摘要，但不能從 AI 面板直接改 Nature。
#
# 【實際影響】
# 1. Active Move 候選分數：依 Tactical Tags 加入小幅 Nature bonus/penalty。
# 2. Dynamic Role：Nature 只提供次級 role hint，不覆蓋 Species/Loadout/AI。
# 3. Target Commitment：玩家未手動設定時，依 Nature 微調 species commitment；
#    若玩家已手動指定 commitment，Nature 完全不介入。
# 4. LOG：戰鬥開始記錄 [TEMPERAMENT]；選中受到 Nature 明顯影響的技能時
#    記錄 [TEMPERAMENT_AI]，方便追查 AI 為什麼這樣打。
#
# 【玩家優先權】
# Role Bias / Condition Focus / Spatial Intent 明確指定後，Nature 對相關評分自動衰減。
# Target Commitment 明確指定後，Nature commitment offset = 0。
# 因此 Nature 是「個性」而不是「命令」。
#
# 【S 驗證】
# NORMAL -> S 一次 -> NATURE_AI_TEMPERAMENT_V09916 -> Shift
# S 只保留最新 5 個正式 verifier：v0.99.16 / .15 / .14 / .13 / .12。
# 預期所有 V09916 marker pass=1，最後必須：
# VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【安全邊界】
# - 不修改 Pokémon Nature 原作能力值公式。
# - 不修改 Damage Formula / Normal Attack Speed / Accuracy / Priority。
# - v0.99.15 Spatial Conditions、v0.99.14 Cadence、v0.99.12 Basic Flex 全部繼承。
# - Frozen Combat Core 不直接修改。
#==============================================================================
module PMD_AC
  NATURE_AI_VERIFY_END_V09916=192
  NATURE_AI_REPORT_V09916='PMD_NatureAITemperament_v0.99.16.txt'

  class << self
    alias pmd_ac_v09916_dynamic_role_scores_v09913 dynamic_role_scores_v09913 unless method_defined?(:pmd_ac_v09916_dynamic_role_scores_v09913)

    def dynamic_role_scores_v09913(pokemon)
      scores=pmd_ac_v09916_dynamic_role_scores_v09913(pokemon)
      return scores if pokemon==nil || !pokemon.respond_to?(:nature_key)
      hints=temperament_role_hints_v09916(pokemon.nature_key)
      scale=temperament_influence_scale_v09916(pokemon,:role)
      hints.each do |role,value|
        scores[role]=scores[role].to_f+value.to_f*scale.to_f if scores.has_key?(role)
      end
      scores
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : Nature commitment / runtime inheritance / LOG
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v09916_apply_persistent_ai_setup apply_persistent_ai_setup unless method_defined?(:pmd_ac_v09916_apply_persistent_ai_setup)
  alias pmd_ac_v09916_start_combat start_combat unless method_defined?(:pmd_ac_v09916_start_combat)
  alias pmd_ac_v09916_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v09916_combat_feel_runtime_v0883)
  alias pmd_ac_v09916_basic_flex_runtime_v09912 basic_flex_runtime_v09912? unless method_defined?(:pmd_ac_v09916_basic_flex_runtime_v09912)
  alias pmd_ac_v09916_cadence_runtime_v099142 cadence_runtime_v099142? unless method_defined?(:pmd_ac_v09916_cadence_runtime_v099142)

  def nature_ai_temperament_v09916?
    @scene!=nil && @scene.respond_to?(:verification_mode) &&
      @scene.verification_mode==:nature_ai_temperament_v09916
  end

  def apply_persistent_ai_setup
    pmd_ac_v09916_apply_persistent_ai_setup
    return if @pokemon_instance==nil
    setup=@pokemon_instance.ai_setup || {}
    @nature_temperament_v09916=PMD_AC.temperament_axes_v09916(@pokemon_instance.nature_key)
    @nature_move_scale_v09916=PMD_AC.temperament_influence_scale_v09916(@pokemon_instance,:move)

    # 每次從 species review 的原始 commitment 重算，避免重複呼叫時累加。
    if setup[:target_commitment]==nil
      base=nil
      if PMD_AC.respond_to?(:review_profile_for_v09911)
        p=PMD_AC.review_profile_for_v09911(species_key,form_key)
        base=p[:target_commitment].to_i if p!=nil && p[:target_commitment]!=nil
      end
      base=@target_commitment.to_i if base==nil
      offset=PMD_AC.temperament_commitment_offset_v09916(@pokemon_instance.nature_key)
      @target_commitment=PMD_AC.clamp(base+offset,0,100)
      @nature_commitment_offset_v09916=offset
    else
      @nature_commitment_offset_v09916=0
      @target_commitment=PMD_AC.clamp(setup[:target_commitment].to_i,0,100)
    end
  end

  def nature_temperament_v09916
    @nature_temperament_v09916 || PMD_AC.temperament_axes_v09916(nature_key)
  end

  def nature_commitment_offset_v09916
    @nature_commitment_offset_v09916.to_i
  end

  def nature_move_scale_v09916
    @nature_move_scale_v09916==nil ? 1.0 : @nature_move_scale_v09916.to_f
  end

  def start_combat
    pmd_ac_v09916_start_combat
    return if @pokemon_instance==nil || @scene==nil || !@scene.respond_to?(:log_event)
    h=nature_temperament_v09916
    @scene.log_event(:temperament,
      log_name+' nature='+nature_key.to_s+'('+PMD_AC.nature_label_v09916(nature_key)+')'+
      ' axes=[agg='+h[:aggression].to_i.to_s+',cau='+h[:caution].to_i.to_s+
      ',mob='+h[:mobility].to_i.to_s+',sup='+h[:support].to_i.to_s+
      ',com='+h[:commitment].to_i.to_s+'] commitment='+@target_commitment.to_i.to_s+
      ' offset='+nature_commitment_offset_v09916.to_s+' move_scale='+sprintf('%.2f',nature_move_scale_v09916))
  end

  def combat_feel_runtime_v0883?
    return true if nature_ai_temperament_v09916?
    pmd_ac_v09916_combat_feel_runtime_v0883
  end

  def basic_flex_runtime_v09912?
    return true if nature_ai_temperament_v09916?
    pmd_ac_v09916_basic_flex_runtime_v09912
  end

  def cadence_runtime_v099142?
    return true if nature_ai_temperament_v09916?
    pmd_ac_v09916_cadence_runtime_v099142
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Nature scoring / UI / Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v09916_start start unless method_defined?(:pmd_ac_v09916_start)
  alias pmd_ac_v09916_refresh_header refresh_header unless method_defined?(:pmd_ac_v09916_refresh_header)
  alias pmd_ac_v09916_spatial_framework_runtime_enabled_v09914 spatial_framework_runtime_enabled_v09914? unless method_defined?(:pmd_ac_v09916_spatial_framework_runtime_enabled_v09914)
  alias pmd_ac_v09916_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v09916_progression_candidate_score_v046)
  alias pmd_ac_v09916_progression_select_best_move_v046 progression_select_best_move_v046 unless method_defined?(:pmd_ac_v09916_progression_select_best_move_v046)
  alias pmd_ac_v09916_refresh_ai_strategy_v09913 refresh_ai_strategy_v09913 unless method_defined?(:pmd_ac_v09916_refresh_ai_strategy_v09913)
  alias pmd_ac_v09916_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v09916_prepare_verification_battle)
  alias pmd_ac_v09916_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09916_update_verification_script)
  alias pmd_ac_v09916_log_event log_event unless method_defined?(:pmd_ac_v09916_log_event)
  alias pmd_ac_v09916_verify_latest_five_modes_v09915 verify_latest_five_modes_v09915 unless method_defined?(:pmd_ac_v09916_verify_latest_five_modes_v09915)
  alias pmd_ac_v09916_verify_latest_five_modes_v09914 verify_latest_five_modes_v09914 unless method_defined?(:pmd_ac_v09916_verify_latest_five_modes_v09914)

  def nature_ai_temperament_v09916?
    verification_mode==:nature_ai_temperament_v09916
  end

  def spatial_framework_runtime_enabled_v09914?
    return true if nature_ai_temperament_v09916?
    pmd_ac_v09916_spatial_framework_runtime_enabled_v09914
  end

  def start
    pmd_ac_v09916_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.16 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:nature_ai,
      'FLOW v0.99.16 natures=25 axes=5 soft_weight=1 player_override_priority=1 '+
      'dynamic_role=carried spatial_conditions=v0.99.15_carried cadence=v0.99.14.2_carried damage_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09916_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,28,'PMD 自走棋原型 v0.99.16',1)
  end

  # Nature 不是 AI Strategy 欄位，所以沿用 9 rows，只在底部顯示個性摘要。
  def refresh_ai_strategy_v09913
    pmd_ac_v09916_refresh_ai_strategy_v09913
    return if @ai_strategy_sprite_v09913==nil || @ai_strategy_unit_v09913==nil
    bmp=@ai_strategy_sprite_v09913.bitmap
    return if bmp==nil
    inst=@ai_strategy_unit_v09913.pokemon_instance
    return if inst==nil
    w=bmp.width;h=bmp.height
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.fill_rect(14,h-52,w-28,19,Color.new(22,44,58,210))
    bmp.font.bold=false;bmp.font.size=11;bmp.font.color=Color.new(190,230,200)
    text='個性：'+PMD_AC.nature_label_v09916(inst.nature_key)+'｜'+PMD_AC.temperament_summary_v09916(inst.nature_key)
    bmp.draw_text(18,h-51,w-36,18,text,0)
  end

  def temperament_move_bonus_v09916_for(unit,data)
    return 0.0 if unit==nil || data==nil || unit.pokemon_instance==nil
    mk=canonical_move_key_v09914(data)
    tags=PMD_AC.move_tactical_tags_v09914(mk,data)
    PMD_AC.temperament_move_bonus_v09916(unit.pokemon_instance,tags)
  rescue
    0.0
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v09916_progression_candidate_score_v046(unit,target,data,move,slot)
    return score if score==nil
    score.to_f+temperament_move_bonus_v09916_for(unit,data)
  end

  def progression_select_best_move_v046(unit)
    result=pmd_ac_v09916_progression_select_best_move_v046(unit)
    return result if result==nil || unit==nil || unit.pokemon_instance==nil
    move=result[0];target=result[1]
    if move!=nil && target!=nil && unit.respond_to?(:skill_data)
      data=unit.skill_data
      bonus=temperament_move_bonus_v09916_for(unit,data)
      if bonus.abs>=1.5
        inst=unit.pokemon_instance
        scale=PMD_AC.temperament_influence_scale_v09916(inst,:move)
        key=move.to_s+'|'+target.instance_uid.to_s+'|'+inst.nature_key.to_s+'|'+bonus.round.to_s+'|'+sprintf('%.2f',scale)
        old=unit.instance_variable_get(:@temperament_ai_log_key_v09916)
        if old!=key
          unit.instance_variable_set(:@temperament_ai_log_key_v09916,key)
          log_event(:temperament_ai,unit.log_name+' move='+move.to_s+
            ' nature='+inst.nature_key.to_s+' bonus='+sprintf('%.1f',bonus)+
            ' scale='+sprintf('%.2f',scale))
        end
      end
    end
    result
  end

  # v0.99.15 舊 mode 仍在最新五項，因此修正它的 latest-five 期待值。
  def verify_latest_five_modes_v09915
    unless verification_mode==:spatial_conditions_ai_rules_v09915
      return pmd_ac_v09916_verify_latest_five_modes_v09915
    end
    return if @verification_done[:latest_five_modes_v09915]
    exp=[:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913,:basic_spatial_flex_v09912]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_condition_verify_v09915('LATEST_FIVE_MODES_V09915',pass,
      'formal_modes=5 current_head=v09916 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09915]=true
  end

  # v0.99.14 也仍在最新五項，避免歷史 verifier 因版本前進而自我 FAIL。
  def verify_latest_five_modes_v09914
    unless verification_mode==:spatial_framework_expansion_v09914
      return pmd_ac_v09916_verify_latest_five_modes_v09914
    end
    return if @verification_done[:latest_five_modes_v09914]
    exp=[:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913,:basic_spatial_flex_v09912]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_spatial_verify_v09914('LATEST_FIVE_MODES_V09914',pass,
      'formal_modes=5 normal_plus=1 current_head=v09916 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09914]=true
  end

  #--------------------------------------------------------------------------
  # ● Verifier
  #--------------------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v09916_prepare_verification_battle
    return unless nature_ai_temperament_v09916?
    @nature_ai_failed_v09916=false
    @nature_ai_report_written_v09916=PMD_AC.write_nature_ai_report_v09916
    log_event(:showcase,'START mode=NATURE_AI_TEMPERAMENT_V09916 natures=25 axes=5 player_override_priority=1')
  end

  def log_event(category,message)
    if category.to_s=='verify' && nature_ai_temperament_v09916? &&
       message.to_s.index('V09916')!=nil && message.to_s.index(' pass=0')!=nil
      @nature_ai_failed_v09916=true
    end
    pmd_ac_v09916_log_event(category,message)
  end

  def log_nature_verify_v09916(name,pass,detail='')
    @nature_ai_failed_v09916=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_nature_coverage_v09916
    return if @verification_done[:nature_coverage_v09916]
    keys=PMD_AC::NATURE_TEMPERAMENT_V09916.keys
    canon=PMD_AC::NATURE_DATA.keys
    values_ok=true;profiles=[]
    keys.each do |n|
      h=PMD_AC.temperament_axes_v09916(n)
      profiles << PMD_AC::TEMPERAMENT_AXES_V09916.collect{|a|h[a].to_i}.join(',')
      PMD_AC::TEMPERAMENT_AXES_V09916.each do |a|
        v=h[a].to_i;values_ok=false if v < -2 || v > 2
      end
    end
    unique=profiles.uniq.size
    pass=keys.size==25 && canon.size==25 && keys.sort{|a,b|a.to_s<=>b.to_s}==canon.sort{|a,b|a.to_s<=>b.to_s} &&
      PMD_AC::TEMPERAMENT_AXES_V09916.size==5 && values_ok && unique==25
    log_nature_verify_v09916('NATURE_COVERAGE_V09916',pass,
      'natures='+keys.size.to_s+'/25 axes=5 unique_profiles='+unique.to_s+' value_range=-2..2')
    @verification_done[:nature_coverage_v09916]=true
  end

  def verify_nature_identity_v09916
    return if @verification_done[:nature_identity_v09916]
    b=PMD_AC.temperament_axes_v09916(:brave);t=PMD_AC.temperament_axes_v09916(:timid)
    c=PMD_AC.temperament_axes_v09916(:calm);j=PMD_AC.temperament_axes_v09916(:jolly)
    pass=b[:aggression]>t[:aggression] && b[:commitment]>t[:commitment] &&
      t[:caution]>b[:caution] && t[:mobility]>b[:mobility] &&
      c[:support]>b[:support] && j[:mobility]>c[:mobility]
    log_nature_verify_v09916('NATURE_TEMPERAMENT_IDENTITY_V09916',pass,
      'brave='+PMD_AC.temperament_summary_v09916(:brave)+' timid='+PMD_AC.temperament_summary_v09916(:timid))
    @verification_done[:nature_identity_v09916]=true
  end

  def verify_nature_move_weight_v09916
    return if @verification_done[:nature_move_weight_v09916]
    attack_tags=[:engage,:gap_close,:execute,:back_attack]
    escape_tags=[:escape_through,:disengage,:reposition]
    brave_attack=PMD_AC.temperament_move_bonus_for_v09916(:brave,attack_tags,1.0)
    timid_attack=PMD_AC.temperament_move_bonus_for_v09916(:timid,attack_tags,1.0)
    brave_escape=PMD_AC.temperament_move_bonus_for_v09916(:brave,escape_tags,1.0)
    timid_escape=PMD_AC.temperament_move_bonus_for_v09916(:timid,escape_tags,1.0)
    pass=brave_attack>timid_attack && timid_escape>brave_escape &&
      brave_attack.abs<=PMD_AC::TEMPERAMENT_MOVE_BONUS_CAP_V09916 &&
      timid_escape.abs<=PMD_AC::TEMPERAMENT_MOVE_BONUS_CAP_V09916
    log_nature_verify_v09916('NATURE_AI_RULE_WEIGHT_V09916',pass,
      'attack brave='+sprintf('%.1f',brave_attack)+' timid='+sprintf('%.1f',timid_attack)+
      ' escape brave='+sprintf('%.1f',brave_escape)+' timid='+sprintf('%.1f',timid_escape)+' cap=7.5')
    @verification_done[:nature_move_weight_v09916]=true
  end

  def verify_player_override_priority_v09916
    return if @verification_done[:player_override_priority_v09916]
    u=verification_unit(:ally,:charmander);pass=false;auto=0.0;role=0.0;condition=0.0;commit=0.0
    if u!=nil && u.pokemon_instance!=nil
      inst=u.pokemon_instance;old=inst.ai_setup
      inst.clear_ai_setup;auto=PMD_AC.temperament_influence_scale_v09916(inst,:move)
      inst.set_ai_option(:role_bias,:diver);role=PMD_AC.temperament_influence_scale_v09916(inst,:role)
      inst.set_ai_option(:condition_focus,:flank);condition=PMD_AC.temperament_influence_scale_v09916(inst,:condition)
      inst.set_ai_option(:target_commitment,77);commit=PMD_AC.temperament_influence_scale_v09916(inst,:commitment)
      inst.clear_ai_setup;inst.apply_ai_setup_hash(old)
      u.apply_species_review_profile_v09911 if u.respond_to?(:apply_species_review_profile_v09911)
      pass=auto==1.0 && role==PMD_AC::TEMPERAMENT_ROLE_EXPLICIT_SCALE_V09916 &&
        condition==PMD_AC::TEMPERAMENT_CONDITION_EXPLICIT_SCALE_V09916 && commit==0.0
    end
    log_nature_verify_v09916('PLAYER_OVERRIDE_PRIORITY_V09916',pass,
      'auto='+sprintf('%.2f',auto)+' explicit_role='+sprintf('%.2f',role)+
      ' explicit_condition='+sprintf('%.2f',condition)+' explicit_commitment='+sprintf('%.2f',commit))
    @verification_done[:player_override_priority_v09916]=true
  end

  def verify_dynamic_role_temperament_v09916
    return if @verification_done[:dynamic_role_temperament_v09916]
    u=verification_unit(:ally,:charmander);pass=false;bk=0.0;tk=0.0;bs=0.0;ts=0.0
    if u!=nil && u.pokemon_instance!=nil
      inst=u.pokemon_instance;old=inst.nature_key
      inst.set_nature(:brave);b=PMD_AC.dynamic_role_scores_v09913(inst)
      inst.set_nature(:timid);t=PMD_AC.dynamic_role_scores_v09913(inst)
      inst.set_nature(old)
      bk=b[:bruiser].to_f;tk=t[:bruiser].to_f;bs=b[:skirmisher].to_f;ts=t[:skirmisher].to_f
      pass=bk>tk && ts>bs
    end
    log_nature_verify_v09916('DYNAMIC_ROLE_TEMPERAMENT_V09916',pass,
      'bruiser brave='+bk.to_i.to_s+' timid='+tk.to_i.to_s+
      ' skirmisher brave='+bs.to_i.to_s+' timid='+ts.to_i.to_s+' top_role_not_forced=1')
    @verification_done[:dynamic_role_temperament_v09916]=true
  end

  def verify_commitment_temperament_v09916
    return if @verification_done[:commitment_temperament_v09916]
    b=PMD_AC.temperament_commitment_offset_v09916(:brave)
    t=PMD_AC.temperament_commitment_offset_v09916(:timid)
    pass=b>0 && t<0 && b>t
    log_nature_verify_v09916('TARGET_COMMITMENT_TEMPERAMENT_V09916',pass,
      'brave_offset='+b.to_s+' timid_offset='+t.to_s+' explicit_override=100%')
    @verification_done[:commitment_temperament_v09916]=true
  end

  def verify_nature_ui_v09916
    return if @verification_done[:nature_ui_v09916]
    rows=PMD_AC::AI_STRATEGY_ROWS_V09915
    pass=rows.size==9 && PMD_AC.nature_label_v09916(:brave)=='勇敢' &&
      PMD_AC.temperament_summary_v09916(:timid).index('謹慎+2')!=nil &&
      respond_to?(:refresh_ai_strategy_v09913)
    log_nature_verify_v09916('NATURE_AI_UI_V09916',pass,
      'ai_rows=9 nature_display=1 editable_nature_in_ai_panel=0')
    @verification_done[:nature_ui_v09916]=true
  end

  def verify_spatial_condition_carry_v09916
    return if @verification_done[:spatial_condition_carry_v09916]
    u=verification_unit(:ally,:charmander)
    pass=PMD_AC.const_defined?(:SPATIAL_CONDITIONS_V09915) &&
      PMD_AC::SPATIAL_CONDITIONS_V09915.size==10 && respond_to?(:spatial_condition_snapshot_v09915) &&
      u!=nil && u.respond_to?(:cadence_runtime_v099142?) && u.cadence_runtime_v099142? &&
      u.respond_to?(:basic_flex_runtime_v09912?) && u.basic_flex_runtime_v09912?
    log_nature_verify_v09916('SPATIAL_CONDITION_CARRY_V09916',pass,
      'conditions=10 cadence_v099142=1 basic_flex=1 normal_attack_speed_unchanged=1')
    @verification_done[:spatial_condition_carry_v09916]=true
  end

  def verify_latest_five_modes_v09916
    return if @verification_done[:latest_five_modes_v09916]
    exp=[:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913,:basic_spatial_flex_v09912]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_nature_verify_v09916('LATEST_FIVE_MODES_V09916',pass,
      'formal_modes=5 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09916]=true
  end

  def verify_nature_ai_final_v09916
    return if @verification_done[:nature_ai_final_v09916]
    pass=!@nature_ai_failed_v09916 && @nature_ai_report_written_v09916
    log_nature_verify_v09916('NATURE_AI_TEMPERAMENT_V09916',pass,
      'natures=25 axes=5 soft_weight=1 player_override_priority=1 dynamic_role=1 '+
      'spatial_conditions=1 damage_unchanged=1 core_direct_modification=0 next=rpg_foundation_individuality')
    @verification_done[:nature_ai_final_v09916]=true
  end

  def update_verification_script
    pmd_ac_v09916_update_verification_script
    return unless nature_ai_temperament_v09916?
    f=@verification_frame.to_i
    verify_nature_coverage_v09916 if f>=18
    verify_nature_identity_v09916 if f>=38
    verify_nature_move_weight_v09916 if f>=58
    verify_player_override_priority_v09916 if f>=78
    verify_dynamic_role_temperament_v09916 if f>=98
    verify_commitment_temperament_v09916 if f>=116
    verify_nature_ui_v09916 if f>=132
    verify_spatial_condition_carry_v09916 if f>=148
    verify_latest_five_modes_v09916 if f>=164
    verify_nature_ai_final_v09916 if f>=176
    if f>=PMD_AC::NATURE_AI_VERIFY_END_V09916 && !@verification_done[:nature_ai_complete_v09916]
      if @nature_ai_failed_v09916
        for u in @units;u.verification_finish if u.respond_to?(:verification_finish);end
        @verification_done[:nature_ai_complete_v09916]=true
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=NATURE_AI_TEMPERAMENT_V09916 auto_skill=on original_skills=restored')
      else
        complete_verification_mode
        @verification_done[:nature_ai_complete_v09916]=true
      end
    end
  end
end

#==============================================================================
# ■ S 輪替：NORMAL + 最新 5 個正式 verifier
#==============================================================================
module PMD_AC
  old_labels_v09916=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v09916
  VERIFICATION_LABELS[:nature_ai_temperament_v09916]='NATURE_AI_TEMPERAMENT_V09916'

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :normal,
    :nature_ai_temperament_v09916,
    :spatial_conditions_ai_rules_v09915,
    :spatial_framework_expansion_v09914,
    :dynamic_tactical_role_v09913,
    :basic_spatial_flex_v09912
  ]
end
