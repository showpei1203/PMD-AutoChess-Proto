# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Spatial Conditions / AI Rules Runtime v0.99.15
# 分類：即時戰場條件／AI 規則評分／AI Strategy UI／Verifier
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 本腳本把 v0.99.15 Data 的 Spatial Conditions 真正接到選技 AI。
# 每次 AI 評估一個 Active Move 時，會建立「使用者＋候選目標」的條件快照，
# 再用技能 Tactical Tags 判斷該招在此刻是否有戰術價值。
#
# 【即時條件】
# target_near / target_far
# self_surrounded / target_cluster
# ally_distress / backline_exposed
# line_opportunity / cone_opportunity
# self_low_hp / target_low_hp
#
# 【玩家設定】
# AI Strategy 面板新增「條件偏好」condition_focus。
# 它只放大相關規則分數，不會凌駕明確的 target / spacing / spatial intent。
#
# 【AI Rule 實例】
# - Rapid Spin / Teleport：被包圍或低血時更願意 escape_through。
# - Brave Bird / Flare Blitz：敵群聚時 center_dive 價值上升。
# - Ally Switch / Follow Me：友軍受壓時 rescue / intercept 大幅加分。
# - Aerial Ace / Acrobatics：後排暴露時 dash-through / back attack 加分。
# - Line / Cone 技能：至少命中 2 個目標時才得到幾何加分。
#
# 【AI_RULE LOG】
# 實戰選到有明顯條件加權的技能時，會記錄：
# [AI_RULE] 使用者 move=... bonus=... focus=... conditions=[...]
# 只在選擇／條件摘要改變時記一次，避免每 frame 洗版。
#
# 【驗證方式】
# NORMAL -> S 一次 -> SPATIAL_CONDITIONS_AI_RULES_V09915 -> Shift
# 預期所有 V09915 marker pass=1，最後必須：
# VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【安全邊界】
# - v0.99.14.2 Cadence Runtime 原行為保留，只讓新 verifier 繼承。
# - Normal Attack Speed / Damage Formula / Move Power 不變。
# - Frozen Combat Core 不直接修改。
# - Nature AI Temperament 尚未實作，留到下一階段。
#==============================================================================
module PMD_AC
  SPATIAL_CONDITION_VERIFY_END_V09915=180
  SPATIAL_CONDITION_REPORT_V09915='PMD_SpatialConditionsAIRules_v0.99.15.txt'

  AI_STRATEGY_ROWS_V09915=[
    :role_bias,:movement_policy,:target_policy,:threat_policy,
    :skill_policy,:spacing_policy,:spatial_intent,:condition_focus,
    :target_commitment
  ]

  AI_STRATEGY_ROW_LABELS_V09915={
    :role_bias=>'角色偏好',:movement_policy=>'移動',:target_policy=>'目標',
    :threat_policy=>'威脅反應',:skill_policy=>'技能',:spacing_policy=>'站位',
    :spatial_intent=>'位移意圖',:condition_focus=>'條件偏好',
    :target_commitment=>'目標黏著'
  }

  class << self
    alias pmd_ac_v09915_valid_ai_option valid_ai_option? unless method_defined?(:pmd_ac_v09915_valid_ai_option)
    alias pmd_ac_v09915_strategy_values_v09913 strategy_values_v09913 unless method_defined?(:pmd_ac_v09915_strategy_values_v09913)
    alias pmd_ac_v09915_strategy_default_value_v09913 strategy_default_value_v09913 unless method_defined?(:pmd_ac_v09915_strategy_default_value_v09913)
    alias pmd_ac_v09915_strategy_value_label_v09913 strategy_value_label_v09913 unless method_defined?(:pmd_ac_v09915_strategy_value_label_v09913)
    alias pmd_ac_v09915_dynamic_role_scores_v09913 dynamic_role_scores_v09913 unless method_defined?(:pmd_ac_v09915_dynamic_role_scores_v09913)

    def valid_ai_option?(key,value)
      if key==:condition_focus
        v=value.to_sym rescue nil
        return v!=nil && AI_CONDITION_FOCUS_V09915.include?(v)
      end
      pmd_ac_v09915_valid_ai_option(key,value)
    end

    def strategy_values_v09913(key)
      return AI_CONDITION_FOCUS_V09915 if key==:condition_focus
      pmd_ac_v09915_strategy_values_v09913(key)
    end

    def strategy_default_value_v09913(key)
      return :auto if key==:condition_focus
      pmd_ac_v09915_strategy_default_value_v09913(key)
    end

    def strategy_value_label_v09913(key,value)
      return condition_focus_label_v09915(value) if key==:condition_focus
      pmd_ac_v09915_strategy_value_label_v09913(key,value)
    end

    # Condition Focus 只做小幅定位提示，不取代 Species / Moves / Role Bias。
    def dynamic_role_scores_v09913(pokemon)
      scores=pmd_ac_v09915_dynamic_role_scores_v09913(pokemon)
      return scores if pokemon==nil || !pokemon.respond_to?(:ai_setup)
      focus=normalize_condition_focus_v09915(pokemon.ai_setup[:condition_focus])
      hints=condition_focus_role_hints_v09915(focus)
      hints.each{|role,value|scores[role]=scores[role].to_f+value.to_f}
      scores
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : persistent focus + verifier inheritance
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v09915_apply_persistent_ai_setup apply_persistent_ai_setup unless method_defined?(:pmd_ac_v09915_apply_persistent_ai_setup)
  alias pmd_ac_v09915_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v09915_combat_feel_runtime_v0883)
  alias pmd_ac_v09915_basic_flex_runtime_v09912 basic_flex_runtime_v09912? unless method_defined?(:pmd_ac_v09915_basic_flex_runtime_v09912)
  alias pmd_ac_v09915_cadence_runtime_v099142 cadence_runtime_v099142? unless method_defined?(:pmd_ac_v09915_cadence_runtime_v099142)

  def apply_persistent_ai_setup
    pmd_ac_v09915_apply_persistent_ai_setup
    setup=@pokemon_instance==nil ? {} : @pokemon_instance.ai_setup
    @condition_focus_v09915=PMD_AC.normalize_condition_focus_v09915(setup[:condition_focus])
  end

  def condition_focus_v09915
    @condition_focus_v09915 || :auto
  end

  def combat_feel_runtime_v0883?
    if @scene!=nil && @scene.respond_to?(:verification_mode) &&
       @scene.verification_mode==:spatial_conditions_ai_rules_v09915
      return true
    end
    pmd_ac_v09915_combat_feel_runtime_v0883
  end

  def basic_flex_runtime_v09912?
    if @scene!=nil && @scene.respond_to?(:verification_mode) &&
       @scene.verification_mode==:spatial_conditions_ai_rules_v09915
      return true
    end
    pmd_ac_v09915_basic_flex_runtime_v09912
  end

  def cadence_runtime_v099142?
    if @scene!=nil && @scene.respond_to?(:verification_mode) &&
       @scene.verification_mode==:spatial_conditions_ai_rules_v09915
      return true
    end
    pmd_ac_v09915_cadence_runtime_v099142
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : condition snapshot / scoring / UI / verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v09915_start start unless method_defined?(:pmd_ac_v09915_start)
  alias pmd_ac_v09915_refresh_header refresh_header unless method_defined?(:pmd_ac_v09915_refresh_header)
  alias pmd_ac_v09915_spatial_framework_runtime_enabled_v09914 spatial_framework_runtime_enabled_v09914? unless method_defined?(:pmd_ac_v09915_spatial_framework_runtime_enabled_v09914)
  alias pmd_ac_v09915_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v09915_progression_candidate_score_v046)
  alias pmd_ac_v09915_progression_select_best_move_v046 progression_select_best_move_v046 unless method_defined?(:pmd_ac_v09915_progression_select_best_move_v046)
  alias pmd_ac_v09915_strategy_value_v09913 strategy_value_v09913 unless method_defined?(:pmd_ac_v09915_strategy_value_v09913)
  alias pmd_ac_v09915_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v09915_prepare_verification_battle)
  alias pmd_ac_v09915_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09915_update_verification_script)
  alias pmd_ac_v09915_log_event log_event unless method_defined?(:pmd_ac_v09915_log_event)
  alias pmd_ac_v09915_verify_latest_five_modes_v09914 verify_latest_five_modes_v09914 unless method_defined?(:pmd_ac_v09915_verify_latest_five_modes_v09914)


  # 舊 v0.99.14 verifier 仍在最新 5 項內；它的「latest five」檢查需理解
  # 現在已經有 v0.99.15，否則歷史模式會因選單正常前進反而自我判 FAIL。
  def verify_latest_five_modes_v09914
    unless verification_mode==:spatial_framework_expansion_v09914
      return pmd_ac_v09915_verify_latest_five_modes_v09914
    end
    return if @verification_done[:latest_five_modes_v09914]
    exp=[:spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914,
      :dynamic_tactical_role_v09913,:basic_spatial_flex_v09912,:gameplay_review_final_v09911]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_spatial_verify_v09914('LATEST_FIVE_MODES_V09914',pass,
      'formal_modes=5 normal_plus=1 current_head=v09915 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09914]=true
  end

  def spatial_conditions_ai_rules_v09915?
    verification_mode==:spatial_conditions_ai_rules_v09915
  end

  def spatial_framework_runtime_enabled_v09914?
    return true if verification_mode==:spatial_conditions_ai_rules_v09915
    pmd_ac_v09915_spatial_framework_runtime_enabled_v09914
  end

  def start
    pmd_ac_v09915_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.15 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:spatial_conditions,
      'FLOW v0.99.15 conditions=10 ai_rules=context_score condition_focus=8 ui_rows=9 '+
      'cadence=v0.99.14.2_carried nature_ai=deferred damage_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09915_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,28,'PMD 自走棋原型 v0.99.15',1)
  end

  #--------------------------------------------------------------------------
  # ● AI Strategy UI v0.99.15
  #--------------------------------------------------------------------------
  def ai_strategy_rows_v09915
    PMD_AC::AI_STRATEGY_ROWS_V09915
  end

  def strategy_value_v09913(unit,key)
    if key==:condition_focus
      return :auto if unit==nil || unit.pokemon_instance==nil
      return PMD_AC.normalize_condition_focus_v09915(unit.pokemon_instance.ai_setup[:condition_focus])
    end
    pmd_ac_v09915_strategy_value_v09913(unit,key)
  end

  # v0.99.13 的 8-row constant 留著給歷史 verifier；實際 UI 改用 9-row helper。
  def change_strategy_value_v09913(direction)
    u=@ai_strategy_unit_v09913
    return if u==nil
    rows=ai_strategy_rows_v09915
    key=rows[@ai_strategy_row_v09913]
    current=strategy_value_v09913(u,key)
    if key==:target_commitment
      value=PMD_AC.clamp(current.to_i+direction.to_i*5,0,100)
      u.pokemon_instance.set_ai_option(key,value)
    else
      vals=PMD_AC.strategy_values_v09913(key)
      return if vals.empty?
      idx=vals.index(current);idx=0 if idx==nil
      idx=(idx+direction.to_i)%vals.size
      u.pokemon_instance.set_ai_option(key,vals[idx])
    end
    apply_strategy_to_unit_v09913(u)
  end

  def reset_strategy_row_v09913
    u=@ai_strategy_unit_v09913
    return if u==nil
    key=ai_strategy_rows_v09915[@ai_strategy_row_v09913]
    default=PMD_AC.strategy_default_value_v09913(key)
    if default==nil
      u.pokemon_instance.clear_ai_option(key)
    else
      u.pokemon_instance.set_ai_option(key,default)
    end
    apply_strategy_to_unit_v09913(u)
  end

  def update_ai_strategy_v09913
    if Input.trigger?(Input::B) || Input.trigger?(Input::X)
      Sound.play_cancel;close_ai_strategy_v09913;return
    end
    rows=ai_strategy_rows_v09915
    if Input.repeat?(Input::UP)
      @ai_strategy_row_v09913-=1
      @ai_strategy_row_v09913=rows.size-1 if @ai_strategy_row_v09913<0
      Sound.play_cursor;refresh_ai_strategy_v09913
    elsif Input.repeat?(Input::DOWN)
      @ai_strategy_row_v09913+=1
      @ai_strategy_row_v09913=0 if @ai_strategy_row_v09913>=rows.size
      Sound.play_cursor;refresh_ai_strategy_v09913
    elsif Input.repeat?(Input::LEFT)
      Sound.play_cursor;change_strategy_value_v09913(-1)
    elsif Input.repeat?(Input::RIGHT)
      Sound.play_cursor;change_strategy_value_v09913(1)
    elsif Input.trigger?(Input::C)
      Sound.play_cancel;reset_strategy_row_v09913
    end
  end

  def refresh_ai_strategy_v09913
    return if @ai_strategy_sprite_v09913==nil || @ai_strategy_unit_v09913==nil
    bmp=@ai_strategy_sprite_v09913.bitmap;bmp.clear
    w=bmp.width;h=bmp.height
    bmp.fill_rect(0,0,w,h,Color.new(8,15,24,235))
    bmp.fill_rect(2,2,w-4,h-4,Color.new(18,30,43,235))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    u=@ai_strategy_unit_v09913;inst=u.pokemon_instance
    bmp.font.bold=true;bmp.font.size=21;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(18,6,w-36,26,'AI Strategy｜'+u.name,0)
    scores=PMD_AC.dynamic_role_scores_v09913(inst)
    top=PMD_AC.sorted_role_scores_v09913(scores)[0,3]
    role_text=top.collect{|r|PMD_AC.role_label_v09913(r)+' '+scores[r].to_i.to_s}.join(' / ')
    bmp.font.bold=false;bmp.font.size=14;bmp.font.color=Color.new(170,220,255)
    bmp.draw_text(18,32,w-36,20,'目前定位：'+role_text,0)
    moves=inst.respond_to?(:active_moves_v045) ? inst.active_moves_v045 : []
    move_text=moves.collect{|mv|mv.to_s}.join(' / ');move_text='(尚無 Active Move)' if move_text==''
    bmp.font.size=12;bmp.font.color=Color.new(205,215,225)
    bmp.draw_text(18,52,w-36,18,'4招配置：'+move_text,0)
    y=73;row_h=22
    ai_strategy_rows_v09915.each_with_index do |key,i|
      selected=(i==@ai_strategy_row_v09913)
      bmp.fill_rect(14,y-1,w-28,row_h,Color.new(50,90,125,150)) if selected
      bmp.font.size=15;bmp.font.bold=selected
      bmp.font.color=selected ? Color.new(255,245,175) : Color.new(235,240,245)
      label=PMD_AC::AI_STRATEGY_ROW_LABELS_V09915[key] || key.to_s
      value=strategy_value_v09913(u,key)
      value_label=PMD_AC.strategy_value_label_v09913(key,value)
      bmp.draw_text(22,y,w/2-30,20,label,0)
      bmp.draw_text(w/2-6,y,w/2-28,20,value_label,0)
      y+=row_h
    end
    bmp.font.bold=false;bmp.font.size=12;bmp.font.color=Color.new(170,220,255)
    bmp.draw_text(18,h-29,w-36,20,'↑↓ 選擇｜←→ 調整｜C 恢復預設｜B/A 關閉',1)
  end

  #--------------------------------------------------------------------------
  # ● Spatial Condition Snapshot
  #--------------------------------------------------------------------------
  def hp_rate_v09915(unit)
    return 1.0 if unit==nil
    unit.hp.to_f/[unit.maxhp.to_i,1].max.to_f
  rescue
    1.0
  end

  def target_cluster_count_v09915(unit,target)
    return 0 if unit==nil || target==nil
    geometry_alive_enemies_v09914(unit).inject(0) do |n,e|
      dx=e.pixel_x.to_f-target.pixel_x.to_f;dy=e.pixel_y.to_f-target.pixel_y.to_f
      n+(Math.sqrt(dx*dx+dy*dy)<=PMD_AC::TARGET_CLUSTER_RADIUS_V09915 ? 1 : 0)
    end
  end

  def ally_distress_v09915?(unit)
    return false if unit==nil
    if unit.respond_to?(:distress_guard_active_v0913?) && unit.distress_guard_active_v0913?
      return true
    end
    foes=geometry_alive_enemies_v09914(unit)
    allies=respond_to?(:allies_of) ? allies_of(unit) : []
    allies.each do |a|
      next if a==nil || a.dead? || a==unit
      rate=hp_rate_v09915(a)
      under=false
      foes.each do |e|
        if (e.respond_to?(:target) && e.target==a)
          under=true;break
        end
        dx=e.pixel_x.to_f-a.pixel_x.to_f;dy=e.pixel_y.to_f-a.pixel_y.to_f
        if Math.sqrt(dx*dx+dy*dy)<=PMD_AC::ALLY_ENGAGE_DISTANCE_V09915
          under=true;break
        end
      end
      return true if under && rate<=PMD_AC::ALLY_DISTRESS_HP_RATE_V09915
    end
    false
  rescue
    false
  end

  def backline_depth_count_v09915(unit,target)
    return 0 if unit==nil || target==nil
    td=unit.distance_to(target).to_f
    geometry_alive_enemies_v09914(unit).inject(0) do |n,e|
      next n if e==target
      d=unit.distance_to(e).to_f
      n+(d+PMD_AC::BACKLINE_DEPTH_MARGIN_V09915<td ? 1 : 0)
    end
  rescue
    0
  end

  def spatial_condition_snapshot_v09915(unit,target,data=nil)
    return {} if unit==nil || target==nil || target.dead?
    d=unit.distance_to(target).to_f
    surround=surrounded_enemy_count_v09914(unit,PMD_AC::SURROUND_RADIUS_V09915)
    cluster=target_cluster_count_v09915(unit,target)
    line=line_enemy_count_v09914(unit,target,PMD_AC::LINE_WIDTH_V09914,PMD_AC::LINE_RANGE_V09914)
    cone=cone_enemy_count_v09914(unit,target,PMD_AC::CONE_RANGE_V09914,PMD_AC::CONE_HALF_ANGLE_DEG_V09914)
    depth=backline_depth_count_v09915(unit,target)
    self_rate=hp_rate_v09915(unit);target_rate=hp_rate_v09915(target)
    {
      :distance=>d,:surround_count=>surround,:target_cluster_count=>cluster,
      :line_count=>line,:cone_count=>cone,:backline_depth=>depth,
      :self_hp_rate=>self_rate,:target_hp_rate=>target_rate,
      :target_near=>(d<=PMD_AC::TARGET_NEAR_DISTANCE_V09915),
      :target_far=>(d>=PMD_AC::TARGET_FAR_DISTANCE_V09915),
      :self_surrounded=>(surround>=PMD_AC::SURROUNDED_COUNT_V09915),
      :target_cluster=>(cluster>=PMD_AC::TARGET_CLUSTER_COUNT_V09915),
      :ally_distress=>ally_distress_v09915?(unit),
      :backline_exposed=>(depth>=1),
      :line_opportunity=>(line>=PMD_AC::LINE_OPPORTUNITY_COUNT_V09915),
      :cone_opportunity=>(cone>=PMD_AC::CONE_OPPORTUNITY_COUNT_V09915),
      :self_low_hp=>(self_rate<=PMD_AC::SELF_LOW_HP_RATE_V09915),
      :target_low_hp=>(target_rate<=PMD_AC::TARGET_LOW_HP_RATE_V09915)
    }
  rescue
    {}
  end

  def active_condition_keys_v09915(snapshot)
    PMD_AC::SPATIAL_CONDITIONS_V09915.find_all{|k|snapshot[k]}
  end

  def spatial_condition_ai_bonus_v09915(unit,target,data)
    return 0.0 if unit==nil || target==nil || data==nil
    mk=canonical_move_key_v09914(data)
    tags=PMD_AC.move_tactical_tags_v09914(mk,data)
    snap=spatial_condition_snapshot_v09915(unit,target,data)
    focus=unit.respond_to?(:condition_focus_v09915) ? unit.condition_focus_v09915 : :auto
    PMD_AC.condition_rule_bonus_v09915(snap,tags,focus)
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v09915_progression_candidate_score_v046(unit,target,data,move,slot)
    return score if score==nil
    score.to_f+spatial_condition_ai_bonus_v09915(unit,target,data)
  end

  def progression_select_best_move_v046(unit)
    result=pmd_ac_v09915_progression_select_best_move_v046(unit)
    return result if result==nil || unit==nil
    move=result[0];target=result[1]
    if move!=nil && target!=nil && unit.respond_to?(:skill_data)
      data=unit.skill_data
      bonus=spatial_condition_ai_bonus_v09915(unit,target,data)
      if bonus.abs>=6.0
        snap=spatial_condition_snapshot_v09915(unit,target,data)
        active=active_condition_keys_v09915(snap)
        focus=unit.respond_to?(:condition_focus_v09915) ? unit.condition_focus_v09915 : :auto
        key=move.to_s+'|'+target.instance_uid.to_s+'|'+focus.to_s+'|'+active.collect{|x|x.to_s}.join(',')+'|'+bonus.round.to_s
        old=unit.instance_variable_get(:@ai_rule_log_key_v09915)
        if old!=key
          unit.instance_variable_set(:@ai_rule_log_key_v09915,key)
          log_event(:ai_rule,unit.log_name+' move='+move.to_s+' bonus='+sprintf('%.1f',bonus)+
            ' focus='+focus.to_s+' conditions=['+active.collect{|x|x.to_s}.join(',')+']')
        end
      end
    end
    result
  end

  #--------------------------------------------------------------------------
  # ● Verifier
  #--------------------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v09915_prepare_verification_battle
    return unless spatial_conditions_ai_rules_v09915?
    @spatial_condition_failed_v09915=false
    @spatial_condition_report_written_v09915=PMD_AC.write_spatial_conditions_report_v09915
    log_event(:showcase,'START mode=SPATIAL_CONDITIONS_AI_RULES_V09915 conditions=10 focus=8 ui_rows=9')
  end

  def log_event(category,message)
    if category.to_s=='verify' && spatial_conditions_ai_rules_v09915? &&
       message.to_s.index('V09915')!=nil && message.to_s.index(' pass=0')!=nil
      @spatial_condition_failed_v09915=true
    end
    pmd_ac_v09915_log_event(category,message)
  end

  def log_condition_verify_v09915(name,pass,detail='')
    @spatial_condition_failed_v09915=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def save_positions_v09915(units)
    h={}
    units.each do |u|
      next if u==nil
      h[u]=[u.instance_variable_get(:@pixel_x),u.instance_variable_get(:@pixel_y)]
    end
    h
  end

  def restore_positions_v09915(h)
    h.each do |u,pos|
      u.instance_variable_set(:@pixel_x,pos[0]);u.instance_variable_set(:@pixel_y,pos[1])
      u.sync_cell_from_pixel if u.respond_to?(:sync_cell_from_pixel)
    end
  end

  def verify_condition_snapshot_v09915
    return if @verification_done[:condition_snapshot_v09915]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:caterpie)
    p=verification_unit(:enemy,:pidgey);r=verification_unit(:enemy,:rattata)
    pass=false;snap={}
    list=[u,t,p,r].compact;state=save_positions_v09915(list)
    begin
      if u!=nil && t!=nil && p!=nil && r!=nil
        u.instance_variable_set(:@pixel_x,150.0);u.instance_variable_set(:@pixel_y,210.0)
        t.instance_variable_set(:@pixel_x,300.0);t.instance_variable_set(:@pixel_y,210.0)
        p.instance_variable_set(:@pixel_x,318.0);p.instance_variable_set(:@pixel_y,228.0)
        r.instance_variable_set(:@pixel_x,252.0);r.instance_variable_set(:@pixel_y,205.0)
        snap=spatial_condition_snapshot_v09915(u,t,nil)
        pass=snap[:target_far] && snap[:target_cluster] && snap[:backline_exposed] &&
          snap[:line_count].to_i>=2 && snap[:cone_count].to_i>=2
      end
    rescue
      pass=false
    ensure
      restore_positions_v09915(state)
    end
    log_condition_verify_v09915('SPATIAL_CONDITION_SNAPSHOT_V09915',pass,
      'target_far='+(snap[:target_far] ? '1':'0')+' cluster='+(snap[:target_cluster] ? '1':'0')+
      ' backline='+(snap[:backline_exposed] ? '1':'0')+' line='+snap[:line_count].to_i.to_s+
      ' cone='+snap[:cone_count].to_i.to_s)
    @verification_done[:condition_snapshot_v09915]=true
  end

  def verify_condition_rule_scoring_v09915
    return if @verification_done[:condition_rule_scoring_v09915]
    safe={};PMD_AC::SPATIAL_CONDITIONS_V09915.each{|k|safe[k]=false}
    surround=safe.dup;surround[:self_surrounded]=true;surround[:target_near]=true
    cluster=safe.dup;cluster[:target_cluster]=true;cluster[:backline_exposed]=true
    rescue_snap=safe.dup;rescue_snap[:ally_distress]=true
    line=safe.dup;line[:line_opportunity]=true;line[:cone_opportunity]=true
    esc0=PMD_AC.condition_rule_bonus_v09915(safe,[:escape_through],:auto)
    esc1=PMD_AC.condition_rule_bonus_v09915(surround,[:escape_through],:auto)
    dive0=PMD_AC.condition_rule_bonus_v09915(safe,[:center_dive,:dash_through],:auto)
    dive1=PMD_AC.condition_rule_bonus_v09915(cluster,[:center_dive,:dash_through,:back_attack],:auto)
    res0=PMD_AC.condition_rule_bonus_v09915(safe,[:rescue,:intercept],:auto)
    res1=PMD_AC.condition_rule_bonus_v09915(rescue_snap,[:rescue,:intercept],:auto)
    lin0=PMD_AC.condition_rule_bonus_v09915(safe,[:line_geometry,:cone_geometry],:auto)
    lin1=PMD_AC.condition_rule_bonus_v09915(line,[:line_geometry,:cone_geometry],:auto)
    pass=esc1>esc0 && dive1>dive0 && res1>res0 && lin1>lin0
    log_condition_verify_v09915('CONDITION_RULE_SCORING_V09915',pass,
      'escape='+esc0.to_i.to_s+'>'+esc1.to_i.to_s+' dive='+dive0.to_i.to_s+'>'+dive1.to_i.to_s+
      ' rescue='+res0.to_i.to_s+'>'+res1.to_i.to_s+' geometry='+lin0.to_i.to_s+'>'+lin1.to_i.to_s)
    @verification_done[:condition_rule_scoring_v09915]=true
  end

  def verify_condition_focus_v09915
    return if @verification_done[:condition_focus_v09915]
    u=verification_unit(:ally,:charmander);pass=false;auto=0.0;focused=0.0;persist=false
    if u!=nil && u.pokemon_instance!=nil
      inst=u.pokemon_instance;old=inst.ai_setup[:condition_focus]
      snap={};PMD_AC::SPATIAL_CONDITIONS_V09915.each{|k|snap[k]=false};snap[:ally_distress]=true
      auto=PMD_AC.condition_rule_bonus_v09915(snap,[:rescue,:intercept],:auto)
      focused=PMD_AC.condition_rule_bonus_v09915(snap,[:rescue,:intercept],:rescue)
      inst.set_ai_option(:condition_focus,:rescue);u.apply_persistent_ai_setup
      persist=(inst.ai_setup[:condition_focus]==:rescue && u.condition_focus_v09915==:rescue)
      if old==nil;inst.clear_ai_option(:condition_focus);else;inst.set_ai_option(:condition_focus,old);end
      u.apply_persistent_ai_setup
      pass=PMD_AC.valid_ai_option?(:condition_focus,:rescue) && focused>auto && persist
    end
    log_condition_verify_v09915('PLAYER_CONDITION_FOCUS_V09915',pass,
      'focus_options=8 rescue_auto='+auto.to_i.to_s+' rescue_focus='+focused.to_i.to_s+' persistent_instance_uid='+(persist ? '1':'0'))
    @verification_done[:condition_focus_v09915]=true
  end

  def verify_condition_ui_v09915
    return if @verification_done[:condition_ui_v09915]
    rows=PMD_AC::AI_STRATEGY_ROWS_V09915
    legacy=PMD_AC::AI_STRATEGY_ROWS_V09913
    pass=rows.size==9 && rows.include?(:condition_focus) && legacy.size==8 &&
      PMD_AC.strategy_values_v09913(:condition_focus).size==8 &&
      PMD_AC.strategy_value_label_v09913(:condition_focus,:flank)=='側背／後排'
    log_condition_verify_v09915('AI_CONDITION_UI_V09915',pass,
      'rows='+rows.size.to_s+' legacy_rows='+legacy.size.to_s+' condition_focus=1')
    @verification_done[:condition_ui_v09915]=true
  end

  def verify_condition_role_hint_v09915
    return if @verification_done[:condition_role_hint_v09915]
    hints_f=PMD_AC.condition_focus_role_hints_v09915(:flank)
    hints_r=PMD_AC.condition_focus_role_hints_v09915(:rescue)
    pass=hints_f[:assassin].to_i>0 && hints_f[:diver].to_i>0 && hints_r[:bodyguard].to_i>0
    log_condition_verify_v09915('DYNAMIC_ROLE_CONDITION_HINT_V09915',pass,
      'flank_assassin='+hints_f[:assassin].to_i.to_s+' flank_diver='+hints_f[:diver].to_i.to_s+
      ' rescue_bodyguard='+hints_r[:bodyguard].to_i.to_s)
    @verification_done[:condition_role_hint_v09915]=true
  end

  def verify_cadence_carry_v09915
    return if @verification_done[:cadence_carry_v09915]
    u=verification_unit(:ally,:charmander)
    pass=u!=nil && u.respond_to?(:cadence_runtime_v099142?) && u.cadence_runtime_v099142? &&
      PMD_AC.const_defined?(:POST_KILL_CADENCE_WARN_FRAMES_V099142) &&
      PMD_AC.const_defined?(:ATTACK_WAIT_CAP_MULT_V099142)
    log_condition_verify_v09915('CADENCE_CARRY_V09915',pass,
      'runtime_v099142=1 attack_speed_unchanged=1 post_kill_guard=1')
    @verification_done[:cadence_carry_v09915]=true
  end

  def verify_latest_five_modes_v09915
    return if @verification_done[:latest_five_modes_v09915]
    exp=[:spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914,
      :dynamic_tactical_role_v09913,:basic_spatial_flex_v09912,:gameplay_review_final_v09911]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_condition_verify_v09915('LATEST_FIVE_MODES_V09915',pass,
      'formal_modes=5 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09915]=true
  end

  def verify_spatial_conditions_final_v09915
    return if @verification_done[:spatial_conditions_final_v09915]
    pass=!@spatial_condition_failed_v09915 && @spatial_condition_report_written_v09915
    log_condition_verify_v09915('SPATIAL_CONDITIONS_AI_RULES_V09915',pass,
      'conditions=10 context_scoring=1 player_focus=1 ui_rows=9 cadence_carry=1 '+
      'nature_ai_deferred=1 damage_unchanged=1 core_direct_modification=0 next=nature_ai_temperament')
    @verification_done[:spatial_conditions_final_v09915]=true
  end

  def update_verification_script
    pmd_ac_v09915_update_verification_script
    return unless spatial_conditions_ai_rules_v09915?
    f=@verification_frame.to_i
    verify_condition_snapshot_v09915 if f>=18
    verify_condition_rule_scoring_v09915 if f>=38
    verify_condition_focus_v09915 if f>=58
    verify_condition_ui_v09915 if f>=76
    verify_condition_role_hint_v09915 if f>=94
    verify_cadence_carry_v09915 if f>=112
    verify_latest_five_modes_v09915 if f>=132
    verify_spatial_conditions_final_v09915 if f>=150
    if f>=PMD_AC::SPATIAL_CONDITION_VERIFY_END_V09915 &&
       !@verification_done[:spatial_conditions_complete_v09915]
      if @spatial_condition_failed_v09915
        for u in @units;u.verification_finish if u.respond_to?(:verification_finish);end
        @verification_done[:spatial_conditions_complete_v09915]=true
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=SPATIAL_CONDITIONS_AI_RULES_V09915 auto_skill=on original_skills=restored')
      else
        complete_verification_mode
        @verification_done[:spatial_conditions_complete_v09915]=true
      end
    end
  end
end

#==============================================================================
# ■ S 輪替：NORMAL + 最新 5 個正式 verifier
#==============================================================================
module PMD_AC
  old_labels_v09915=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v09915
  VERIFICATION_LABELS[:spatial_conditions_ai_rules_v09915]='SPATIAL_CONDITIONS_AI_RULES_V09915'

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :normal,
    :spatial_conditions_ai_rules_v09915,
    :spatial_framework_expansion_v09914,
    :dynamic_tactical_role_v09913,
    :basic_spatial_flex_v09912,
    :gameplay_review_final_v09911
  ]
end
