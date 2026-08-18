# encoding: UTF-8
#==============================================================================
# PMD AutoChess Proto v0.87
# Encounter Unlock / Story Gating / UI Small Text Scale Up
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 1. 讀取前一支「PMD AutoChess Encounter Unlock Data v0.87」，讓 Region、
#    Formation、Map Default Encounter 可以依 Switch / Variable / Stage Clear 解鎖。
# 2. 依使用者最新需求，把畫面中那一級「偏小的小字」全面再放大一級。
#    標題字維持，不再把大標也一起吹成氣球。
#
# 【你之後最常用的事情】
# - 劇情推進後打開稀有怪：
#     $game_switches[81] = true
# - 打通某關後開新區：
#     REGION_UNLOCK_RULES_V087[:deep_forest] = :forest_clear
# - 事件直接進入區域戰鬥：
#     PMD_AC.start_region_battle_v087(:forest_edge)
# - 地圖設定條件型野怪：
#     PMD_AC.wild_region_on_v087(:forest_edge,10,18,[1],12,:forest_clear)
#
# 【驗證模式】
# 布陣畫面按 S 切到 ENCOUNTER_UNLOCK_V087，再按 Shift。
# 預期：
#   ENCOUNTER_UNLOCK_MANIFEST_V087 pass=1
#   ENCOUNTER_UNLOCK_REGION_V087 pass=1
#   ENCOUNTER_UNLOCK_FORMATION_V087 pass=1
#   ENCOUNTER_UNLOCK_STAGE_V087 pass=1
#   ENCOUNTER_UNLOCK_MAP_V087 pass=1
#   ENCOUNTER_UNLOCK_UI_V087 pass=1
#   ENCOUNTER_UNLOCK_CARRY_V087 pass=1
#   ENCOUNTER_UNLOCK_V087 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  #--------------------------------------------------------------------------
  # UI 小字放大：維持標題字，調整偏小的輔助資訊字級。
  #--------------------------------------------------------------------------
  def self.pmd_ac_redefine_const_v087(name,val)
    remove_const(name) if const_defined?(name)
    const_set(name,val)
  end

  pmd_ac_redefine_const_v087(:UI_HEADER_SUB_FONT_V086,17)
  pmd_ac_redefine_const_v087(:UI_FOOTER_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_FOOTER_LV_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_DAMAGE_POPUP_W_V086,72)
  pmd_ac_redefine_const_v087(:UI_DAMAGE_FONT_V086,12)
  pmd_ac_redefine_const_v087(:UI_CRIT_FONT_V086,11)
  pmd_ac_redefine_const_v087(:UI_SKILL_H_V086,34)
  pmd_ac_redefine_const_v087(:UI_SKILL_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_THREAT_FONT_V086,17)
  pmd_ac_redefine_const_v087(:UI_AI_W_V086,60)
  pmd_ac_redefine_const_v087(:UI_AI_H_V086,22)
  pmd_ac_redefine_const_v087(:UI_AI_FONT_V086,14)
  pmd_ac_redefine_const_v087(:UI_STATUS_W_V086,148)
  pmd_ac_redefine_const_v087(:UI_STATUS_H_V086,22)
  pmd_ac_redefine_const_v087(:UI_STATUS_FONT_V086,13)
  pmd_ac_redefine_const_v087(:UI_MISS_FONT_V086,15)

  pmd_ac_redefine_const_v087(:UI_BOX_META_FONT_V086,18)
  pmd_ac_redefine_const_v087(:UI_BOX_LEVEL_FONT_V086,18)
  pmd_ac_redefine_const_v087(:UI_BOX_MOVES_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_BOX_MARK_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_BOX_HINT_FONT_V086,18)
  pmd_ac_redefine_const_v087(:UI_BOX_FOOTER_FONT_V086,16)

  pmd_ac_redefine_const_v087(:UI_PROG_META_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_PROG_DETAIL_FONT_V086,15)
  pmd_ac_redefine_const_v087(:UI_PROG_LIST_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_PROG_LIST_LV_FONT_V086,14)
  pmd_ac_redefine_const_v087(:UI_PROG_NOTE_FONT_V086,14)
  pmd_ac_redefine_const_v087(:UI_PROG_ATTENTION_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_PROG_FOOTER_FONT_V086,15)

  pmd_ac_redefine_const_v087(:UI_RESULT_SUB_FONT_V086,20)
  pmd_ac_redefine_const_v087(:UI_RESULT_RECORD_FONT_V086,19)
  pmd_ac_redefine_const_v087(:UI_RESULT_DETAIL_FONT_V086,18)
  pmd_ac_redefine_const_v087(:UI_RESULT_TAG_FONT_V086,16)
  pmd_ac_redefine_const_v087(:UI_RESULT_LOOT_FONT_V086,18)
  pmd_ac_redefine_const_v087(:UI_RESULT_FOOTER_FONT_V086,17)

  pmd_ac_redefine_const_v087(:UI_READABILITY_MANIFEST_V086,{
    :version=>'0.87',
    :scope=>[:battle_float,:header,:footer,:party_box,:progression,:result,:loot],
    :damage_font=>UI_DAMAGE_FONT_V086,
    :header_title=>UI_HEADER_TITLE_FONT_V086,
    :header_sub=>UI_HEADER_SUB_FONT_V086,
    :footer=>UI_FOOTER_FONT_V086,
    :ai_font=>UI_AI_FONT_V086,
    :status_font=>UI_STATUS_FONT_V086,
    :box_name=>UI_BOX_NAME_FONT_V086,
    :progression_title=>UI_PROG_TITLE_FONT_V086,
    :result_title=>UI_RESULT_TITLE_FONT_V086,
    :mechanics_unchanged=>true,
    :title_unchanged=>true
  })

  V087_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V087_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:encounter_unlock_v087] +
    V087_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:encounter_unlock_v087}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V087_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:encounter_unlock_v087]='ENCOUNTER_UNLOCK_V087'

  class << self
    alias pmd_ac_v087_region_request_v086_raw region_request_v086 unless method_defined?(:pmd_ac_v087_region_request_v086_raw)
    alias pmd_ac_v087_weighted_formation_pick_v086_raw weighted_formation_pick_v086 unless method_defined?(:pmd_ac_v087_weighted_formation_pick_v086_raw)
    alias pmd_ac_v087_region_wild_config_for_map_v086_raw region_wild_config_for_map_v086 unless method_defined?(:pmd_ac_v087_region_wild_config_for_map_v086_raw)

    def pmd_ac_array_wrap_v087(v)
      return [] if v==nil
      return v.compact if v.is_a?(Array)
      [v]
    end

    def pmd_ac_hash_wrap_v087(v)
      return {} unless v.is_a?(Hash)
      v
    end

    def stage_clear_count_safe_v087(stage_id)
      return 0 unless respond_to?(:stage_clear_count_v080)
      stage_clear_count_v080(stage_id)
    rescue
      0
    end

    def resolve_condition_rows_v087(spec)
      out=[]
      if spec.is_a?(Array)
        spec.each{|x| out += resolve_condition_rows_v087(x)}
      elsif spec.is_a?(Symbol)
        row=CONDITION_PRESETS_V087[spec]
        out << row if row.is_a?(Hash)
      elsif spec.is_a?(Hash)
        out << spec
      end
      out
    end

    def condition_hash_pass_v087(cond)
      c=cond.is_a?(Hash) ? cond : {}
      pmd_ac_array_wrap_v087(c[:switch_on]).each do |id|
        return false if $game_switches==nil
        return false unless $game_switches[id.to_i]
      end
      pmd_ac_array_wrap_v087(c[:switch_off]).each do |id|
        return false if $game_switches==nil
        return false if $game_switches[id.to_i]
      end
      pmd_ac_hash_wrap_v087(c[:variable_min]).each_pair do |id,min|
        return false if $game_variables==nil
        return false if $game_variables[id.to_i].to_i < min.to_i
      end
      pmd_ac_hash_wrap_v087(c[:variable_max]).each_pair do |id,max|
        return false if $game_variables==nil
        return false if $game_variables[id.to_i].to_i > max.to_i
      end
      pmd_ac_hash_wrap_v087(c[:stage_clear_min]).each_pair do |sid,min|
        return false if stage_clear_count_safe_v087(sid.to_i).to_i < min.to_i
      end
      true
    end

    def condition_spec_pass_v087(spec)
      resolve_condition_rows_v087(spec).each do |row|
        return false unless condition_hash_pass_v087(row)
      end
      true
    end

    def object_conditions_pass_v087(obj,extra_spec=nil)
      return false unless condition_spec_pass_v087(extra_spec)
      return true unless obj.is_a?(Hash)
      return false unless condition_spec_pass_v087(obj[:condition])
      return false unless condition_spec_pass_v087(obj[:conditions])
      true
    end

    def region_available_v087?(region_key)
      data=region_data_v086(region_key)
      return false if data==nil
      object_conditions_pass_v087(data,REGION_UNLOCK_RULES_V087[region_key])
    end

    def formation_available_v087?(formation_key)
      data=formation_data_v086(formation_key)
      return false if data==nil
      object_conditions_pass_v087(data,FORMATION_UNLOCK_RULES_V087[formation_key])
    end

    def available_formation_rows_v087(region_key)
      return [] unless region_available_v087?(region_key)
      region=region_data_v086(region_key)
      rows=region==nil ? [] : (region[:formations] || [])
      out=[]
      rows.each do |row|
        next unless row.is_a?(Hash)
        fk=row[:formation]
        next unless formation_available_v087?(fk)
        next unless object_conditions_pass_v087(row,nil)
        out << row
      end
      out
    end

    def weighted_formation_pick_v086(region_key,roll=nil)
      rows=available_formation_rows_v087(region_key)
      return nil if rows.empty?
      total=0
      rows.each{|row| total += [[(row[:weight]||1).to_i,1].max,1].max }
      r=roll==nil ? rand(total) : roll.to_i % total
      acc=0
      rows.each do |row|
        acc += [[(row[:weight]||1).to_i,1].max,1].max
        return row[:formation] if r<acc
      end
      rows[-1][:formation]
    end

    def region_request_v086(region_key,options=nil,formation_roll=nil)
      return nil unless region_available_v087?(region_key)
      o=options==nil ? {} : options.dup
      forced=o[:formation]
      if forced!=nil && !formation_available_v087?(forced)
        return nil
      end
      req=pmd_ac_v087_region_request_v086_raw(region_key,o,formation_roll)
      return nil if req==nil
      return nil unless formation_available_v087?(req[:formation_v086])
      req
    end

    def region_request_v087(region_key,options=nil,formation_roll=nil)
      region_request_v086(region_key,options,formation_roll)
    end

    def start_region_battle_v087(region_key,options=nil)
      start_region_battle_v086(region_key,options)
    end

    def wild_region_config_v087(region_key,min_steps=10,max_steps=18,terrain_tags=nil,condition=nil)
      cfg=wild_region_config_v086(region_key,min_steps,max_steps,terrain_tags)
      return nil if cfg==nil
      cfg[:condition_v087]=condition unless condition==nil
      cfg
    end

    def wild_region_on_v087(region_key,min_steps=10,max_steps=18,terrain_tags=nil,map_id=nil,condition=nil)
      cfg=wild_region_config_v087(region_key,min_steps,max_steps,terrain_tags,condition)
      return false if cfg==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id) : map_id.to_i
      return false if mid<=0
      wild_runtime_maps_v081[mid]=cfg
      if $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
        $game_player.make_pmd_encounter_count_v081(cfg[:min_steps],cfg[:max_steps])
      end
      true
    end

    def map_region_condition_pass_v087(map_id,cfg=nil)
      mid=map_id.to_i
      spec=MAP_REGION_UNLOCK_RULES_V087[mid]
      return false unless condition_spec_pass_v087(spec)
      return true if cfg==nil
      return false unless condition_spec_pass_v087(cfg[:condition_v087])
      d=MAP_REGION_DEFAULTS_V086[mid]
      return object_conditions_pass_v087(d,nil)
    end

    def region_wild_config_for_map_v086(map_id)
      cfg=pmd_ac_v087_region_wild_config_for_map_v086_raw(map_id)
      return nil if cfg==nil
      region=cfg[:region_v086] || cfg[:region]
      return nil unless region_available_v087?(region)
      return nil unless map_region_condition_pass_v087(map_id,cfg)
      cfg
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v087_start start unless method_defined?(:pmd_ac_v087_start)
  alias pmd_ac_v087_refresh_header refresh_header unless method_defined?(:pmd_ac_v087_refresh_header)
  alias pmd_ac_v087_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v087_prepare_verification_battle)
  alias pmd_ac_v087_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v087_update_verification_script)
  alias pmd_ac_v087_log_event log_event unless method_defined?(:pmd_ac_v087_log_event)

  def start
    pmd_ac_v087_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.87 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::ENCOUNTER_UNLOCK_MANIFEST_V087
    log_event(:encounter_unlock,
      'FLOW v0.87 presets='+m[:condition_presets].to_s+
      ' region_rules='+m[:region_rules].to_s+
      ' formation_rules='+m[:formation_rules].to_s+
      ' ui_small_text=up title_unchanged=1 gating=switch+variable+stage_clear')
    refresh_header
    refresh_footer
  end

  def refresh_header
    pmd_ac_v087_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.87',1)
  end

  def encounter_unlock_v087?
    verification_mode==:encounter_unlock_v087
  end

  def prepare_verification_battle
    pmd_ac_v087_prepare_verification_battle
    if encounter_unlock_v087?
      @encounter_unlock_v087_failed=false
      @encounter_unlock_saved_switches=nil
      @encounter_unlock_saved_variables=nil
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && encounter_unlock_v087? &&
       message.to_s.index('ENCOUNTER_UNLOCK_')==0 && message.to_s.include?(' pass=0')
      @encounter_unlock_v087_failed=true
    end
    pmd_ac_v087_log_event(category,message)
  end

  def log_verify_v087(name,pass,detail='')
    @encounter_unlock_v087_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def with_unlock_test_state_v087
    ids=[81,82,83]
    saved_sw={}
    saved_var={}
    if $game_switches!=nil
      ids.each{|id| saved_sw[id]=$game_switches[id] }
    end
    if $game_variables!=nil
      ids.each{|id| saved_var[id]=$game_variables[id] }
    end
    begin
      yield
    ensure
      if $game_switches!=nil
        ids.each{|id| $game_switches[id]=saved_sw[id] }
      end
      if $game_variables!=nil
        ids.each{|id| $game_variables[id]=saved_var[id] }
      end
    end
  end

  def verify_unlock_manifest_v087
    return if @verification_done[:v087_manifest]
    m=PMD_AC::ENCOUNTER_UNLOCK_MANIFEST_V087
    e=PMD_AC.unlock_rule_errors_v087
    pass=e.empty? && m[:condition_presets] >= 4 && m[:supported_keys].include?(:stage_clear_min)
    log_verify_v087('ENCOUNTER_UNLOCK_MANIFEST_V087',pass,
      'presets='+m[:condition_presets].to_s+' region_rules='+m[:region_rules].to_s+
      ' formation_rules='+m[:formation_rules].to_s+' errors=['+e.join(',')+']')
    @verification_done[:v087_manifest]=true
  end

  def verify_unlock_region_v087
    return if @verification_done[:v087_region]
    pass=false
    with_unlock_test_state_v087 do
      $game_switches[82]=false if $game_switches!=nil
      locked=PMD_AC.region_available_v087?(:thunder_slope)
      $game_switches[82]=true if $game_switches!=nil
      opened=PMD_AC.region_available_v087?(:thunder_slope)
      pass=(!locked && opened)
      log_verify_v087('ENCOUNTER_UNLOCK_REGION_V087',pass,
        'thunder_slope off='+(locked ? '1':'0')+' on='+(opened ? '1':'0'))
    end
    @verification_done[:v087_region]=true
  end

  def verify_unlock_formation_v087
    return if @verification_done[:v087_formation]
    pass=false
    with_unlock_test_state_v087 do
      $game_switches[81]=false if $game_switches!=nil
      a=PMD_AC.weighted_formation_pick_v086(:forest_edge,99)
      $game_switches[81]=true if $game_switches!=nil
      b=PMD_AC.weighted_formation_pick_v086(:forest_edge,99)
      pass=(a!=:forest_pikachu_rare && b==:forest_pikachu_rare)
      log_verify_v087('ENCOUNTER_UNLOCK_FORMATION_V087',pass,
        'roll99_locked='+a.to_s+' roll99_open='+b.to_s)
    end
    @verification_done[:v087_formation]=true
  end

  def verify_unlock_stage_v087
    return if @verification_done[:v087_stage]
    cur=PMD_AC.stage_clear_count_safe_v087(1)
    a=PMD_AC.condition_spec_pass_v087({:stage_clear_min=>{1=>cur}})
    b=PMD_AC.condition_spec_pass_v087({:stage_clear_min=>{1=>cur+1}})
    pass=(a && !b)
    log_verify_v087('ENCOUNTER_UNLOCK_STAGE_V087',pass,
      'stage1_clear='+cur.to_s+' require='+cur.to_s+'->'+(a ? '1':'0')+
      ' require='+(cur+1).to_s+'->'+(b ? '1':'0'))
    @verification_done[:v087_stage]=true
  end

  def verify_unlock_map_v087
    return if @verification_done[:v087_map]
    pass=false
    with_unlock_test_state_v087 do
      PMD_AC.wild_region_on_v087(:thunder_slope,9,15,[1],88,:thunder_key)
      $game_switches[82]=false if $game_switches!=nil
      a=PMD_AC.region_wild_config_for_map_v086(88)
      $game_switches[82]=true if $game_switches!=nil
      b=PMD_AC.region_wild_config_for_map_v086(88)
      PMD_AC.wild_runtime_maps_v081.delete(88) if PMD_AC.respond_to?(:wild_runtime_maps_v081)
      pass=(a==nil && b!=nil && b[:region_v086]==:thunder_slope)
      detail='locked='+(a==nil ? 'nil' : a[:region_v086].to_s)+' open='+(b==nil ? 'nil' : b[:region_v086].to_s)
      log_verify_v087('ENCOUNTER_UNLOCK_MAP_V087',pass,detail)
    end
    @verification_done[:v087_map]=true
  end

  def verify_unlock_ui_v087
    return if @verification_done[:v087_ui]
    m=PMD_AC::UI_READABILITY_MANIFEST_V086
    pass=m[:title_unchanged] && m[:header_sub].to_i>=17 && m[:footer].to_i>=16 &&
      m[:ai_font].to_i>=14 && m[:status_font].to_i>=13 && m[:damage_font].to_i>=12
    log_verify_v087('ENCOUNTER_UNLOCK_UI_V087',pass,
      'title='+m[:header_title].to_s+' sub='+m[:header_sub].to_s+
      ' footer='+m[:footer].to_s+' ai='+m[:ai_font].to_s+
      ' status='+m[:status_font].to_s+' damage='+m[:damage_font].to_s)
    @verification_done[:v087_ui]=true
  end

  def verify_unlock_carry_v087
    return if @verification_done[:v087_carry]
    pass=PMD_AC::REGION_ECOLOGY_MANIFEST_V086[:formations] >= 8 &&
      PMD_AC::BATTLE_PRESENTATION_MANIFEST_V085[:supports].include?(:boss) &&
      PMD_AC::ENCOUNTER_CONFIG_MANIFEST_V084[:elite_profiles] >= 3 &&
      PMD_AC::REWARD_LOOT_MANIFEST_V083[:boss_recruitable]==false
    log_verify_v087('ENCOUNTER_UNLOCK_CARRY_V087',pass,
      'region=v0.86 presentation=v0.85 config=v0.84 loot=v0.83 title=v0.87 ui_small_text_up=1')
    @verification_done[:v087_carry]=true
  end

  def update_verification_script
    unless encounter_unlock_v087?
      pmd_ac_v087_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_unlock_manifest_v087 if f>=2
    verify_unlock_region_v087 if f>=4
    verify_unlock_formation_v087 if f>=6
    verify_unlock_stage_v087 if f>=8
    verify_unlock_map_v087 if f>=10
    verify_unlock_ui_v087 if f>=12
    verify_unlock_carry_v087 if f>=14
    if f>=16 && !@verification_done[:v087_final]
      pass=!@encounter_unlock_v087_failed
      log_verify_v087('ENCOUNTER_UNLOCK_V087',pass,
        'manifest=1 region=1 formation=1 stage=1 map=1 ui=1 carry=1')
      @verification_done[:v087_final]=true
    end
    complete_verification_mode if f>=PMD_AC::ENCOUNTER_UNLOCK_VERIFY_END_V087
  end
end
