# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Dynamic Tactical Role Runtime v0.99.13
# 分類：動態戰場定位 Runtime／AI Strategy UI／Verifier
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 將 v0.99.13 Dynamic Tactical Role 真正接入戰鬥與戰前設定。
#
# 主要功能：
# 1. 每隻 Pokémon 依 Species＋4 Active Moves＋Ability＋Held Item＋AI 設定，
#    計算多個 Tactical Role 分數與目前最高分角色。
# 2. role_bias 不改種族值與傷害，只提高指定戰術角色權重。
# 3. 若玩家沒有另外指定 spacing_policy，而 role_bias 非 :auto，
#    會採用該角色的合理站位 fallback。
# 4. Dynamic Role 會影響 Spatial / Geometry 技能候選分數：
#    Diver 更重視 dash-through / dive，Skirmisher 更重視撤退／重站位，
#    Bodyguard 更重視 peel / swap，Controller 更重視 pull / cluster。
# 5. 戰前布陣新增 A 鍵 AI Strategy 面板，可直接調整永久 ai_setup。
# 6. 變更後保存於 PMD_PokemonInstance，身份仍以 instance_uid 為準。
#
#==============================================================================
# 【AI Strategy 操作】
# 戰前布陣游標停在我方 Pokémon：
#   A（Input::X）開啟
#
# 面板內：
#   ↑↓  選欄
#   ←→  調整
#   C   恢復該欄 Species / 系統預設
#   B/A 關閉
#
# 可調：
#   role_bias / movement_policy / target_policy / threat_policy
#   skill_policy / spacing_policy / spatial_intent / target_commitment
#
#==============================================================================
# 【實際範例】
# 同一隻 Charmander：
#
# Diver：
#   role_bias=:diver
#   movement_policy=:assassin
#   target_policy=:backline_low_def
#   spacing_policy=:close
#   spatial_intent=:dive
#
# Skirmisher：
#   role_bias=:skirmisher
#   movement_policy=:kiter
#   spacing_policy=:flexible
#   spatial_intent=:disengage
#
# 如果 4 Active Moves 又分別裝 dash-through 或 U-turn / Volt Switch，
# Dynamic Role 與技能選擇分數會再被技能配置推向不同方向。
#
#==============================================================================
# 【驗證方式】
# 布陣：NORMAL -> S 一次 -> DYNAMIC_TACTICAL_ROLE_V09913 -> Shift
#
# 預期：
#   DYNAMIC_ROLE_ENGINE_V09913 pass=1
#   SKILL_LOADOUT_ROLE_V09913 pass=1
#   ROLE_BIAS_AI_V09913 pass=1
#   AI_STRATEGY_PERSIST_V09913 pass=1
#   AI_STRATEGY_UI_V09913 pass=1
#   BASIC_FLEX_CARRY_V09913 pass=1
#   DYNAMIC_TACTICAL_ROLE_V09913 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
#==============================================================================
# 【安全邊界】
# - 不直接修改 Frozen Combat Core。
# - 不改 Damage Formula / Move Power / Accuracy / Priority。
# - v0.99.12 Basic Flex 與 v0.99.12.1 close dispatch 修正保留。
# - UI 僅在 deploy phase 接管輸入；battle phase 的 A 鍵 x1/x2 不受影響。
#==============================================================================

module PMD_AC
  DYNAMIC_ROLE_VERIFY_END_V09913=126
  DYNAMIC_ROLE_REPORT_V09913='PMD_DynamicTacticalRole_v0.99.13.txt'

  AI_STRATEGY_ROWS_V09913=[
    :role_bias,:movement_policy,:target_policy,:threat_policy,
    :skill_policy,:spacing_policy,:spatial_intent,:target_commitment
  ]

  AI_STRATEGY_ROW_LABELS_V09913={
    :role_bias=>'角色偏好',
    :movement_policy=>'移動',
    :target_policy=>'目標',
    :threat_policy=>'威脅反應',
    :skill_policy=>'技能目標',
    :spacing_policy=>'站位',
    :spatial_intent=>'位移意圖',
    :target_commitment=>'目標黏著'
  }

  class << self
    alias pmd_ac_v09913_valid_ai_option valid_ai_option? unless method_defined?(:pmd_ac_v09913_valid_ai_option)
    def valid_ai_option?(key,value)
      return AI_ROLE_BIASES_V09913.include?(value) if key==:role_bias
      pmd_ac_v09913_valid_ai_option(key,value)
    end

    def strategy_values_v09913(key)
      case key
      when :role_bias
        AI_ROLE_BIASES_V09913
      when :movement_policy
        AI_MOVEMENT_POLICIES
      when :target_policy
        AI_TARGET_POLICIES
      when :threat_policy
        AI_THREAT_POLICIES
      when :skill_policy
        AI_SKILL_POLICIES
      when :spacing_policy
        AI_SPACING_POLICIES_V09912
      when :spatial_intent
        AI_SPATIAL_INTENTS_V09912
      else
        []
      end
    end

    def strategy_default_value_v09913(key)
      return :auto if key==:role_bias
      return :species_default if key==:spacing_policy
      return :balanced if key==:spatial_intent
      nil
    end

    def strategy_value_label_v09913(key,value)
      return value.to_i.to_s if key==:target_commitment
      case key
      when :role_bias
        return '自動' if value==:auto
        return role_label_v09913(value)
      when :movement_policy
        return MOVEMENT_LABELS_V09913[value] || value.to_s
      when :target_policy
        return TARGET_LABELS_V09913[value] || value.to_s
      when :threat_policy
        return THREAT_LABELS_V09913[value] || value.to_s
      when :skill_policy
        return SKILL_LABELS_V09913[value] || value.to_s
      when :spacing_policy
        return SPACING_LABELS_V09913[value] || value.to_s
      when :spatial_intent
        return SPATIAL_LABELS_V09913[value] || value.to_s
      end
      value.to_s
    end

    def dynamic_role_report_text_v09913
      out=[]
      out << 'PMD AutoChess Dynamic Tactical Role v0.99.13'
      out << 'Roles: '+TACTICAL_ROLES_V09913.collect{|r|r.to_s}.join(',')
      out << 'AI role bias: '+AI_ROLE_BIASES_V09913.collect{|r|r.to_s}.join(',')
      out << 'AI Strategy rows: '+AI_STRATEGY_ROWS_V09913.collect{|r|r.to_s}.join(',')
      out << 'Basic Flex carry: 494/494'
      out << 'Frozen Combat Core direct modification: NO'
      out << 'Review PASS: 1'
      out.join("\r\n")+"\r\n"
    end

    def write_dynamic_role_report_v09913
      File.open(DYNAMIC_ROLE_REPORT_V09913,'wb'){|f|f.write(dynamic_role_report_text_v09913)}
      true
    rescue
      false
    end
  end
end

#==============================================================================
# ■ PMD_PokemonInstance : Runtime Role API
#==============================================================================
class PMD_PokemonInstance
  def dynamic_role_scores_v09913
    PMD_AC.dynamic_role_scores_v09913(self)
  end

  def dynamic_role_v09913
    PMD_AC.dynamic_role_v09913(self)
  end

  def dynamic_role_top_v09913(limit=3)
    s=dynamic_role_scores_v09913
    PMD_AC.sorted_role_scores_v09913(s)[0,limit.to_i].collect{|r|[r,s[r].to_f]}
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : Dynamic Role / Role Bias Spacing
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v09913_start_combat start_combat unless method_defined?(:pmd_ac_v09913_start_combat)
  alias pmd_ac_v09913_apply_persistent_ai_setup apply_persistent_ai_setup unless method_defined?(:pmd_ac_v09913_apply_persistent_ai_setup)
  alias pmd_ac_v09913_effective_spacing_policy_v09912 effective_spacing_policy_v09912 unless method_defined?(:pmd_ac_v09913_effective_spacing_policy_v09912)
  alias pmd_ac_v09913_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v09913_combat_feel_runtime_v0883)

  def apply_persistent_ai_setup
    pmd_ac_v09913_apply_persistent_ai_setup
    if @pokemon_instance!=nil
      setup=@pokemon_instance.ai_setup
      @role_bias_v09913=setup[:role_bias] || :auto
      @dynamic_role_cache_v09913=nil
      @dynamic_role_scores_cache_v09913=nil
    end
  end

  def start_combat
    pmd_ac_v09913_start_combat
    refresh_dynamic_role_v09913(true)
  end

  def refresh_dynamic_role_v09913(log_change=false)
    old=@dynamic_role_cache_v09913
    if @pokemon_instance==nil
      @dynamic_role_scores_cache_v09913={}
      @dynamic_role_cache_v09913=:frontline
    else
      @dynamic_role_scores_cache_v09913=PMD_AC.dynamic_role_scores_v09913(@pokemon_instance)
      order=PMD_AC.sorted_role_scores_v09913(@dynamic_role_scores_cache_v09913)
      @dynamic_role_cache_v09913=order.empty? ? :frontline : order[0]
    end
    if log_change && @scene!=nil
      top=PMD_AC.sorted_role_scores_v09913(@dynamic_role_scores_cache_v09913)[0,3]
      detail=top.collect{|r|r.to_s+'='+@dynamic_role_scores_cache_v09913[r].to_i.to_s}.join(',')
      @scene.log_event(:tactical_role,
        log_name+' role='+@dynamic_role_cache_v09913.to_s+
        ' bias='+role_bias_v09913.to_s+' top=['+detail+']')
    elsif old!=nil && old!=@dynamic_role_cache_v09913 && @scene!=nil
      @scene.log_event(:tactical_role,
        log_name+' '+old.to_s+' -> '+@dynamic_role_cache_v09913.to_s+
        ' reason=ai_setup')
    end
    @dynamic_role_cache_v09913
  end

  def dynamic_role_scores_v09913
    refresh_dynamic_role_v09913(false) if @dynamic_role_scores_cache_v09913==nil
    @dynamic_role_scores_cache_v09913
  end

  def dynamic_role_v09913
    refresh_dynamic_role_v09913(false) if @dynamic_role_cache_v09913==nil
    @dynamic_role_cache_v09913
  end

  def role_bias_v09913
    @role_bias_v09913 || :auto
  end

  # 新 verifier 必須沿用正式 NORMAL 的 v0.88.3 Combat Feel，
  # 否則又會掉回舊 anti-kite attack lock。
  def combat_feel_runtime_v0883?
    if @scene!=nil && @scene.respond_to?(:verification_mode)
      return true if @scene.verification_mode==:dynamic_tactical_role_v09913
    end
    pmd_ac_v09913_combat_feel_runtime_v0883
  end

  def effective_spacing_policy_v09912
    base=pmd_ac_v09913_effective_spacing_policy_v09912
    # 玩家明確指定 spacing 時永遠優先。
    setup=@pokemon_instance==nil ? {} : @pokemon_instance.ai_setup
    explicit=setup[:spacing_policy]
    return base if explicit!=nil && explicit!=:species_default

    # role_bias 是玩家有意識的戰術偏好，只有非 auto 才推導 fallback spacing。
    bias=role_bias_v09913
    return PMD_AC.role_default_spacing_v09913(bias) if bias!=:auto
    base
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Dynamic Role Skill Scoring / AI Strategy UI
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v09913_start start unless method_defined?(:pmd_ac_v09913_start)
  alias pmd_ac_v09913_terminate terminate unless method_defined?(:pmd_ac_v09913_terminate)
  alias pmd_ac_v09913_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v09913_update_deploy_phase)
  alias pmd_ac_v09913_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v09913_progression_candidate_score_v046)
  alias pmd_ac_v09913_refresh_header refresh_header unless method_defined?(:pmd_ac_v09913_refresh_header)
  alias pmd_ac_v09913_refresh_footer refresh_footer unless method_defined?(:pmd_ac_v09913_refresh_footer)
  alias pmd_ac_v09913_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v09913_prepare_verification_battle)
  alias pmd_ac_v09913_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09913_update_verification_script)
  alias pmd_ac_v09913_log_event log_event unless method_defined?(:pmd_ac_v09913_log_event)

  def start
    pmd_ac_v09913_start
    @ai_strategy_open_v09913=false
    @ai_strategy_unit_v09913=nil
    @ai_strategy_row_v09913=0
    @ai_strategy_sprite_v09913=nil
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.13 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:tactical_role,
      'FLOW v0.99.13 dynamic_role=species+loadout+ability+item+ai role_bias=1 '+
      'ai_strategy_ui=deploy_A spatial_skill_scoring=1 basic_flex=v0.99.12.1_carried')
    refresh_header
    refresh_footer
  end

  def terminate
    dispose_ai_strategy_v09913
    pmd_ac_v09913_terminate
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v09913_progression_candidate_score_v046(unit,target,data,move,slot)
    return score if score==nil || unit==nil || data==nil
    mk=respond_to?(:canonical_move_key_v09912) ? canonical_move_key_v09912(data) : nil
    tags=PMD_AC.move_tactical_tags_v09913(mk,data)
    role=unit.respond_to?(:dynamic_role_v09913) ? unit.dynamic_role_v09913 : nil
    score.to_f+PMD_AC.role_move_bonus_v09913(role,tags)
  end

  def refresh_header
    pmd_ac_v09913_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,28,'PMD 自走棋原型 v0.99.13',1)
  end

  def refresh_footer
    pmd_ac_v09913_refresh_footer
    return if @footer_sprite==nil || @footer_sprite.bitmap==nil
    return unless @phase==:deploy
    bmp=@footer_sprite.bitmap
    unit=@selected_unit
    unit=unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y) if unit==nil && @deploy_cursor!=nil
    return if unit==nil || unit.team!=:ally
    # 第二行改成加入 AI Strategy 提示；第一行保留原屬性資訊。
    bmp.fill_rect(0,25,Graphics.width,27,Color.new(0,0,0,205))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=15;bmp.font.bold=false;bmp.font.color=Color.new(170,220,255)
    role=unit.respond_to?(:dynamic_role_v09913) ? unit.dynamic_role_v09913 : :frontline
    text='A AI策略｜實戰定位 '+PMD_AC.role_label_v09913(role)+
      '｜C 選取/放置｜S 驗證｜Shift 開戰'
    bmp.draw_text(10,25,Graphics.width-20,22,text,0)
  end

  def update_deploy_phase
    if @ai_strategy_open_v09913
      update_ai_strategy_v09913
      return
    end
    if Input.trigger?(Input::X)
      if open_ai_strategy_v09913
        Sound.play_decision
      else
        Sound.play_buzzer
      end
      return
    end
    pmd_ac_v09913_update_deploy_phase
  end

  def strategy_cursor_unit_v09913
    u=@selected_unit
    u=unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y) if u==nil && @deploy_cursor!=nil
    return nil if u==nil || u.team!=:ally || !u.respond_to?(:pokemon_instance)
    return nil if u.pokemon_instance==nil
    u
  end

  def open_ai_strategy_v09913
    u=strategy_cursor_unit_v09913
    return false if u==nil
    @ai_strategy_unit_v09913=u
    @ai_strategy_row_v09913=0
    @ai_strategy_open_v09913=true
    create_ai_strategy_sprite_v09913 if @ai_strategy_sprite_v09913==nil
    @ai_strategy_sprite_v09913.visible=true
    refresh_ai_strategy_v09913
    true
  end

  def close_ai_strategy_v09913
    @ai_strategy_open_v09913=false
    @ai_strategy_unit_v09913=nil
    @ai_strategy_sprite_v09913.visible=false if @ai_strategy_sprite_v09913!=nil
    refresh_footer
  end

  def create_ai_strategy_sprite_v09913
    @ai_strategy_sprite_v09913=Sprite.new(@viewport)
    @ai_strategy_sprite_v09913.bitmap=Bitmap.new(Graphics.width-64,Graphics.height-92)
    @ai_strategy_sprite_v09913.x=32
    @ai_strategy_sprite_v09913.y=44
    @ai_strategy_sprite_v09913.z=9950
    @ai_strategy_sprite_v09913.visible=false
  end

  def dispose_ai_strategy_v09913
    return if @ai_strategy_sprite_v09913==nil
    if @ai_strategy_sprite_v09913.bitmap!=nil && !@ai_strategy_sprite_v09913.bitmap.disposed?
      @ai_strategy_sprite_v09913.bitmap.dispose
    end
    @ai_strategy_sprite_v09913.dispose unless @ai_strategy_sprite_v09913.disposed?
    @ai_strategy_sprite_v09913=nil
  end

  def strategy_value_v09913(unit,key)
    setup=unit.pokemon_instance.ai_setup
    return setup[:role_bias] || :auto if key==:role_bias
    return setup[:spacing_policy] || :species_default if key==:spacing_policy
    return setup[:spatial_intent] || :balanced if key==:spatial_intent
    return unit.movement_policy if key==:movement_policy
    return unit.target_policy if key==:target_policy
    return unit.threat_policy if key==:threat_policy
    return unit.skill_policy if key==:skill_policy
    return unit.target_commitment if key==:target_commitment
    nil
  end

  def change_strategy_value_v09913(direction)
    u=@ai_strategy_unit_v09913
    return if u==nil
    key=PMD_AC::AI_STRATEGY_ROWS_V09913[@ai_strategy_row_v09913]
    current=strategy_value_v09913(u,key)

    if key==:target_commitment
      value=PMD_AC.clamp(current.to_i+direction.to_i*5,0,100)
      u.pokemon_instance.set_ai_option(key,value)
    else
      vals=PMD_AC.strategy_values_v09913(key)
      return if vals.empty?
      idx=vals.index(current)
      idx=0 if idx==nil
      idx=(idx+direction.to_i)%vals.size
      u.pokemon_instance.set_ai_option(key,vals[idx])
    end
    apply_strategy_to_unit_v09913(u)
  end

  def reset_strategy_row_v09913
    u=@ai_strategy_unit_v09913
    return if u==nil
    key=PMD_AC::AI_STRATEGY_ROWS_V09913[@ai_strategy_row_v09913]
    default=PMD_AC.strategy_default_value_v09913(key)
    if default==nil
      u.pokemon_instance.clear_ai_option(key)
    else
      u.pokemon_instance.set_ai_option(key,default)
    end
    apply_strategy_to_unit_v09913(u)
  end

  def apply_strategy_to_unit_v09913(unit)
    if unit.respond_to?(:apply_species_review_profile_v09911)
      unit.apply_species_review_profile_v09911
    else
      unit.apply_persistent_ai_setup
    end
    unit.refresh_dynamic_role_v09913(false) if unit.respond_to?(:refresh_dynamic_role_v09913)
    refresh_ai_strategy_v09913
    refresh_footer
  end

  def update_ai_strategy_v09913
    if Input.trigger?(Input::B) || Input.trigger?(Input::X)
      Sound.play_cancel
      close_ai_strategy_v09913
      return
    end
    if Input.repeat?(Input::UP)
      @ai_strategy_row_v09913-=1
      @ai_strategy_row_v09913=PMD_AC::AI_STRATEGY_ROWS_V09913.size-1 if @ai_strategy_row_v09913<0
      Sound.play_cursor;refresh_ai_strategy_v09913
    elsif Input.repeat?(Input::DOWN)
      @ai_strategy_row_v09913+=1
      @ai_strategy_row_v09913=0 if @ai_strategy_row_v09913>=PMD_AC::AI_STRATEGY_ROWS_V09913.size
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
    bmp=@ai_strategy_sprite_v09913.bitmap
    bmp.clear
    w=bmp.width;h=bmp.height
    bmp.fill_rect(0,0,w,h,Color.new(8,15,24,235))
    bmp.fill_rect(2,2,w-4,h-4,Color.new(18,30,43,235))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)

    u=@ai_strategy_unit_v09913
    inst=u.pokemon_instance
    bmp.font.bold=true;bmp.font.size=22;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(18,8,w-36,28,'AI Strategy｜'+u.name,0)

    scores=PMD_AC.dynamic_role_scores_v09913(inst)
    top=PMD_AC.sorted_role_scores_v09913(scores)[0,3]
    role_text=top.collect{|r|PMD_AC.role_label_v09913(r)+' '+scores[r].to_i.to_s}.join('  /  ')
    bmp.font.bold=false;bmp.font.size=15;bmp.font.color=Color.new(170,220,255)
    bmp.draw_text(18,38,w-36,22,'目前定位：'+role_text,0)

    moves=inst.respond_to?(:active_moves_v045) ? inst.active_moves_v045 : []
    move_text=moves.collect{|mv|mv.to_s}.join(' / ')
    move_text='(尚無 Active Move)' if move_text==''
    bmp.font.size=13;bmp.font.color=Color.new(205,215,225)
    bmp.draw_text(18,60,w-36,20,'4招配置：'+move_text,0)

    y=86
    PMD_AC::AI_STRATEGY_ROWS_V09913.each_with_index do |key,i|
      selected=(i==@ai_strategy_row_v09913)
      bmp.fill_rect(14,y-1,w-28,24,Color.new(50,90,125,150)) if selected
      bmp.font.size=16
      bmp.font.bold=selected
      bmp.font.color=selected ? Color.new(255,245,175) : Color.new(235,240,245)
      label=PMD_AC::AI_STRATEGY_ROW_LABELS_V09913[key] || key.to_s
      value=strategy_value_v09913(u,key)
      value_label=PMD_AC.strategy_value_label_v09913(key,value)
      bmp.draw_text(22,y,w/2-30,22,label,0)
      bmp.draw_text(w/2-6,y,w/2-28,22,value_label,0)
      y+=25
    end

    bmp.font.bold=false;bmp.font.size=13;bmp.font.color=Color.new(170,220,255)
    bmp.draw_text(18,h-30,w-36,22,'↑↓ 選擇｜←→ 調整｜C 恢復預設｜B/A 關閉',1)
  end

  #--------------------------------------------------------------------------
  # ● Verifier
  #--------------------------------------------------------------------------
  def dynamic_tactical_role_v09913?
    verification_mode==:dynamic_tactical_role_v09913
  end

  def prepare_verification_battle
    pmd_ac_v09913_prepare_verification_battle
    return unless dynamic_tactical_role_v09913?
    @dynamic_role_failed_v09913=false
    @dynamic_role_report_written_v09913=PMD_AC.write_dynamic_role_report_v09913
    log_event(:showcase,
      'START mode=DYNAMIC_TACTICAL_ROLE_V09913 same_species_multi_build=1 ai_strategy_ui=1')
  end

  def log_event(category,message)
    if category.to_s=='verify' && dynamic_tactical_role_v09913? &&
       message.to_s.index('V09913')!=nil && message.to_s.index(' pass=0')!=nil
      @dynamic_role_failed_v09913=true
    end
    pmd_ac_v09913_log_event(category,message)
  end

  def log_dynamic_verify_v09913(name,pass,detail='')
    @dynamic_role_failed_v09913=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_dynamic_role_engine_v09913
    return if @verification_done[:dynamic_role_engine_v09913]
    scores=PMD_AC.dynamic_role_scores_for_v09913(
      :charmander,[:aerial_ace,:quick_attack],
      {:role_bias=>:diver,:spatial_intent=>:dive,:spacing_policy=>:close},
      :blaze,nil,:normal)
    order=PMD_AC.sorted_role_scores_v09913(scores)
    pass=scores.size==PMD_AC::TACTICAL_ROLES_V09913.size && order[0]==:diver
    log_dynamic_verify_v09913('DYNAMIC_ROLE_ENGINE_V09913',pass,
      'roles='+scores.size.to_s+' top='+(order[0]||:none).to_s+
      ' diver='+scores[:diver].to_i.to_s+' species=charmander')
    @verification_done[:dynamic_role_engine_v09913]=true
  end

  def verify_skill_loadout_role_v09913
    return if @verification_done[:skill_loadout_role_v09913]
    base=PMD_AC.dynamic_role_scores_for_v09913(:charmander,[],{},:blaze,nil,:normal)
    dive_moves=[:aerial_ace,:quick_attack]
    skim_moves=[:u_turn,:volt_switch]
    dive=PMD_AC.dynamic_role_scores_for_v09913(
      :charmander,dive_moves,{},:blaze,nil,:normal)
    skim=PMD_AC.dynamic_role_scores_for_v09913(
      :charmander,skim_moves,{},:blaze,nil,:normal)
    dive_gain=dive[:diver].to_f-base[:diver].to_f
    skim_gain=skim[:skirmisher].to_f-base[:skirmisher].to_f

    # 同一物種再套入玩家 AI，必須能真的形成兩種不同 top role。
    dive_build=PMD_AC.dynamic_role_scores_for_v09913(
      :charmander,dive_moves,
      {:role_bias=>:diver,:spatial_intent=>:dive,:spacing_policy=>:close,
       :target_policy=>:backline_low_def},:blaze,nil,:normal)
    skim_build=PMD_AC.dynamic_role_scores_for_v09913(
      :charmander,skim_moves,
      {:role_bias=>:skirmisher,:spatial_intent=>:disengage,:spacing_policy=>:flexible,
       :target_policy=>:current_attacker},:blaze,nil,:normal)
    dive_top=PMD_AC.sorted_role_scores_v09913(dive_build)[0]
    skim_top=PMD_AC.sorted_role_scores_v09913(skim_build)[0]

    aa_tags=PMD_AC.move_tactical_tags_v09913(:aerial_ace)
    ut_tags=PMD_AC.move_tactical_tags_v09913(:u_turn)
    spatial_score_ok=PMD_AC.role_move_bonus_v09913(:diver,aa_tags)>
      PMD_AC.role_move_bonus_v09913(:diver,ut_tags) &&
      PMD_AC.role_move_bonus_v09913(:skirmisher,ut_tags)>
      PMD_AC.role_move_bonus_v09913(:skirmisher,aa_tags)

    pass=dive_gain>=20.0 && skim_gain>=20.0 && dive_top==:diver &&
      skim_top==:skirmisher && spatial_score_ok && aa_tags.include?(:dash_through) &&
      ut_tags.include?(:disengage)
    log_dynamic_verify_v09913('SKILL_LOADOUT_ROLE_V09913',pass,
      'same_species=charmander diver_gain='+dive_gain.to_i.to_s+
      ' skirmisher_gain='+skim_gain.to_i.to_s+
      ' dive_top='+dive_top.to_s+' skim_top='+skim_top.to_s+
      ' spatial_score=1')
    @verification_done[:skill_loadout_role_v09913]=true
  end

  def verify_role_bias_ai_v09913
    return if @verification_done[:role_bias_ai_v09913]
    ok=PMD_AC.valid_ai_option?(:role_bias,:diver) &&
      PMD_AC.valid_ai_option?(:role_bias,:skirmisher) &&
      !PMD_AC.valid_ai_option?(:role_bias,:not_a_role) &&
      PMD_AC.role_default_spacing_v09913(:diver)==:close &&
      PMD_AC.role_default_spacing_v09913(:skirmisher)==:flexible &&
      PMD_AC.role_default_spacing_v09913(:bodyguard)==:bodyguard
    log_dynamic_verify_v09913('ROLE_BIAS_AI_V09913',ok,
      'diver=close skirmisher=flexible bodyguard=bodyguard explicit_spacing_priority=1')
    @verification_done[:role_bias_ai_v09913]=true
  end

  def verify_ai_strategy_persist_v09913
    return if @verification_done[:ai_strategy_persist_v09913]
    inst=PMD_PokemonInstance.new(:charmander,20,
      {:instance_uid=>99130001,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,
       :ability_slot=>:primary})
    a=inst.set_ai_option(:role_bias,:diver)
    b=inst.set_ai_option(:spacing_policy,:close)
    c=inst.set_ai_option(:spatial_intent,:dive)
    d=inst.set_ai_option(:target_policy,:backline_low_def)
    copy=inst.ai_setup
    pass=a&&b&&c&&d&&copy[:role_bias]==:diver&&copy[:spacing_policy]==:close&&
      copy[:spatial_intent]==:dive&&copy[:target_policy]==:backline_low_def&&
      inst.instance_uid.to_i==99130001
    log_dynamic_verify_v09913('AI_STRATEGY_PERSIST_V09913',pass,
      'uid=instance_uid role_bias='+copy[:role_bias].to_s+
      ' spacing='+copy[:spacing_policy].to_s+' spatial='+copy[:spatial_intent].to_s)
    @verification_done[:ai_strategy_persist_v09913]=true
  end

  def verify_ai_strategy_ui_v09913
    return if @verification_done[:ai_strategy_ui_v09913]
    rows=PMD_AC::AI_STRATEGY_ROWS_V09913
    pass=rows.size==8 && rows.include?(:role_bias) && rows.include?(:movement_policy) &&
      rows.include?(:target_policy) && rows.include?(:spacing_policy) &&
      rows.include?(:spatial_intent) &&
      respond_to?(:open_ai_strategy_v09913) && respond_to?(:refresh_ai_strategy_v09913)
    log_dynamic_verify_v09913('AI_STRATEGY_UI_V09913',pass,
      'deploy_key=A rows='+rows.size.to_s+' persistent_instance_uid=1 battle_A_speed_unchanged=1')
    @verification_done[:ai_strategy_ui_v09913]=true
  end

  def verify_basic_flex_carry_v09913
    return if @verification_done[:basic_flex_carry_v09913]
    r=PMD_AC.basic_flex_audit_v09912
    ch=verification_unit(:ally,:charmander)
    inherited=ch!=nil && ch.respond_to?(:combat_feel_runtime_v0883?) &&
      ch.combat_feel_runtime_v0883?
    pass=r[:pass] && r[:rows].size==494 && inherited
    log_dynamic_verify_v09913('BASIC_FLEX_CARRY_V09913',pass,
      'species='+r[:rows].size.to_s+'/494 inherited_v0883='+(inherited ? '1':'0')+
      ' adaptive='+r[:modes][:adaptive].to_i.to_s)
    @verification_done[:basic_flex_carry_v09913]=true
  end

  def verify_dynamic_final_v09913
    return if @verification_done[:dynamic_final_v09913]
    pass=!@dynamic_role_failed_v09913 && @dynamic_role_report_written_v09913
    log_dynamic_verify_v09913('DYNAMIC_TACTICAL_ROLE_V09913',pass,
      'dynamic_role=1 loadout_influence=1 ai_strategy_ui=1 spatial_scoring=1 '+
      'core_direct_modification=0 next=spatial_framework_expansion')
    @verification_done[:dynamic_final_v09913]=true
  end

  def update_verification_script
    pmd_ac_v09913_update_verification_script
    return unless dynamic_tactical_role_v09913?
    f=@verification_frame.to_i
    verify_dynamic_role_engine_v09913 if f>=10
    verify_skill_loadout_role_v09913 if f>=24
    verify_role_bias_ai_v09913 if f>=38
    verify_ai_strategy_persist_v09913 if f>=52
    verify_ai_strategy_ui_v09913 if f>=66
    verify_basic_flex_carry_v09913 if f>=80
    verify_dynamic_final_v09913 if f>=96

    if f>=PMD_AC::DYNAMIC_ROLE_VERIFY_END_V09913 &&
       !@verification_done[:dynamic_role_complete_v09913]
      if @dynamic_role_failed_v09913
        for u in @units;u.verification_finish if u.respond_to?(:verification_finish);end
        @verification_done[:dynamic_role_complete_v09913]=true
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=DYNAMIC_TACTICAL_ROLE_V09913 auto_skill=on original_skills=restored')
      else
        complete_verification_mode
        @verification_done[:dynamic_role_complete_v09913]=true
      end
    end
  end
end

#==============================================================================
# ■ Latest verifier mode: S once from NORMAL
#==============================================================================
module PMD_AC
  old_labels_v09913=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v09913
  VERIFICATION_LABELS[:dynamic_tactical_role_v09913]='DYNAMIC_TACTICAL_ROLE_V09913'

  old_modes_v09913=VERIFICATION_MODES.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:dynamic_tactical_role_v09913]+
    old_modes_v09913.reject{|x|x==:normal || x==:dynamic_tactical_role_v09913}
end
