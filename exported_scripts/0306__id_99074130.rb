# encoding: UTF-8
#==============================================================================
# PMD AutoChess Proto v0.86
# Region Ecology / Rare Encounter / Elite Reward Runtime
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 讀取前一支「PMD AutoChess Region Ecology Data v0.86」，把區域生態套進
# v0.81 Encounter、v0.84 Scaling/Elite、v0.83 Loot、v0.85 Battle Presentation。
#
# 一般新增／修改區域請不要改本 Runtime，改前一支 Data 即可。
#
# 【執行流程】
# Region Profile
#   ↓ 權重抽 Formation
# Formation 完整 enemy_setup
#   ↓
# v0.84 重算 Lv／判定 Elite
#   ↓
# v0.81 正常建立戰鬥
#   ↓
# 勝利後 v0.83 先發原本 Loot
#   ↓
# v0.86 再追加 Rare／Elite Bonus
#
# 【事件常用 API】
#   PMD_AC.start_region_battle_v086(:forest_edge)
#
# 強制稀有 Formation：
#   PMD_AC.start_region_battle_v086(:forest_edge,
#     {:formation=>:forest_pikachu_rare})
#
# 地圖遇敵：
#   PMD_AC.wild_region_on_v086(:forest_edge,10,18,[1,2])
#
# 關閉：
#   PMD_AC.wild_off_v081
#
# 【重要規則】
# - Boss 不被本系統改成 Elite，也不走 Region Formation；Boss 還是 v0.81。
# - Rare 是「編成稀有度」，Elite 是「單隻 Runtime 強化」，兩者可同時發生。
# - 招募 Pokémon 不繼承 Rare/Elite 戰鬥倍率。
# - v0.75 平衡、v0.76 能力公式、v0.60.2 多段傷害都不修改。
#
# 【驗證模式】
# 布陣按 S 切到 REGION_ECOLOGY_V086，再按 Shift。
# 預期：
#   REGION_ECOLOGY_MANIFEST_V086 pass=1
#   REGION_FORMATION_V086 pass=1
#   REGION_RARE_V086 pass=1
#   REGION_ELITE_REWARD_V086 pass=1
#   REGION_MAP_BRIDGE_V086 pass=1
#   REGION_CARRY_V086 pass=1
#   REGION_ECOLOGY_V086 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  V086_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V086_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:region_ecology_v086] +
    V086_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:region_ecology_v086}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V086_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:region_ecology_v086]='REGION_ECOLOGY_V086'

  class << self
    def region_request_v086(region_key,options=nil,formation_roll=nil)
      region=region_data_v086(region_key)
      return nil if region==nil
      o=options==nil ? {} : options.dup
      base_profile=o[:encounter_profile] || region[:base_profile]
      profile_data=encounter_profile_v084(base_profile)
      return nil if profile_data==nil
      source=profile_data[:source]
      return nil if source==nil
      r=make_battle_request_v081(source,o)
      return nil if r==nil
      r=apply_profile_to_request_v084(r,base_profile,o)
      formation=o[:formation]
      formation=weighted_formation_pick_v086(region_key,formation_roll) if formation==nil
      fd=formation_data_v086(formation)
      return nil if fd==nil
      r[:enemy_setup]=build_formation_setup_v086(formation)
      r[:region_v086]=region_key
      r[:formation_v086]=formation
      r[:rarity_v086]=formation_rarity_v086(formation)
      r[:rare_v086]=formation_rare_v086?(formation)
      r[:difficulty_v086]=(region[:difficulty]||1).to_i
      r[:presentation]=region[:presentation] if region.has_key?(:presentation)
      if region.has_key?(:recruit_rate) && !o.has_key?(:recruit_rate)
        r[:recruit_rate]=region[:recruit_rate].to_i
      end
      r[:recruit_rate]=o[:recruit_rate].to_i if o.has_key?(:recruit_rate)
      r[:recruitable]=o[:recruitable] ? true:false if o.has_key?(:recruitable)
      r[:can_escape]=o[:can_escape] ? true:false if o.has_key?(:can_escape)
      rarity=formation_rarity_label_v086(formation)
      suffix=r[:rare_v086] ? '【'+rarity+'】' : ''
      r[:name]=region[:name].to_s+'・'+fd[:name].to_s+suffix
      r
    end

    def start_region_battle_v086(region_key,options=nil)
      r=region_request_v086(region_key,options,nil)
      return false if r==nil
      return false if respond_to?(:once_switch_blocked_v082?) && once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def wild_region_config_v086(region_key,min_steps=10,max_steps=18,terrain_tags=nil)
      return nil if region_data_v086(region_key)==nil
      mn=[min_steps.to_i,1].max
      mx=[max_steps.to_i,mn].max
      tags=terrain_tags==nil ? [] : terrain_tags.collect{|x|x.to_i}
      {:region_v086=>region_key,:min_steps=>mn,:max_steps=>mx,:terrain_tags=>tags}
    end

    def wild_region_on_v086(region_key,min_steps=10,max_steps=18,terrain_tags=nil,map_id=nil)
      cfg=wild_region_config_v086(region_key,min_steps,max_steps,terrain_tags)
      return false if cfg==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id) : map_id.to_i
      return false if mid<=0
      wild_runtime_maps_v081[mid]=cfg
      if $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
        $game_player.make_pmd_encounter_count_v081(cfg[:min_steps],cfg[:max_steps])
      end
      true
    end

    def region_wild_config_for_map_v086(map_id)
      mid=map_id.to_i
      h=wild_runtime_maps_v081
      cfg=h[mid]
      return cfg if cfg!=nil && cfg[:region_v086]!=nil
      return nil if cfg!=nil
      d=MAP_REGION_DEFAULTS_V086[mid]
      return nil if d==nil
      region=d[:region] || d[:region_v086]
      wild_region_config_v086(region,d[:min_steps]||10,d[:max_steps]||18,d[:terrain_tags])
    end

    def region_request_summary_v086(request)
      return 'none' if request==nil || request[:region_v086]==nil
      request[:region_v086].to_s+'/'+request[:formation_v086].to_s+
        '/'+request[:rarity_v086].to_s+'/difficulty'+request[:difficulty_v086].to_s
    end
  end
end

class Scene_Map
  alias pmd_ac_v086_update_encounter update_encounter unless method_defined?(:pmd_ac_v086_update_encounter)
  def update_encounter
    cfg=PMD_AC.region_wild_config_for_map_v086($game_map.map_id)
    if cfg==nil
      pmd_ac_v086_update_encounter
      return
    end
    return if $game_player.encounter_count>0
    return if $game_map.interpreter.running?
    return if $game_system.encounter_disabled
    return unless PMD_AC.wild_terrain_valid_v081(cfg)
    mn=(cfg[:min_steps]||10).to_i
    mx=(cfg[:max_steps]||18).to_i
    $game_player.make_pmd_encounter_count_v081(mn,mx)
    PMD_AC.start_region_battle_v086(cfg[:region_v086],{:source=>:wild,:deploy=>false})
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v086_start start unless method_defined?(:pmd_ac_v086_start)
  alias pmd_ac_v086_create_units create_units unless method_defined?(:pmd_ac_v086_create_units)
  alias pmd_ac_v086_process_loot_reward_v083 process_loot_reward_v083 unless method_defined?(:pmd_ac_v086_process_loot_reward_v083)
  alias pmd_ac_v086_refresh_header refresh_header unless method_defined?(:pmd_ac_v086_refresh_header)
  alias pmd_ac_v086_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v086_prepare_verification_battle)
  alias pmd_ac_v086_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v086_update_verification_script)
  alias pmd_ac_v086_log_event log_event unless method_defined?(:pmd_ac_v086_log_event)

  def start
    pmd_ac_v086_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.86 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::REGION_ECOLOGY_MANIFEST_V086
    log_event(:region_ecology,
      'FLOW v0.86 formations='+m[:formations].to_s+' regions='+m[:regions].to_s+
      ' rarity=formation_weight elite=v0.84 rare_reward=1 elite_reward=1 presentation=v0.85')
    req=rpg_request_v081
    if req!=nil && req[:region_v086]!=nil
      log_event(:region_ecology,
        'REQUEST '+PMD_AC.region_request_summary_v086(req)+
        ' rare='+(req[:rare_v086] ? '1':'0')+
        ' recruit_rate='+(req[:recruit_rate]||0).to_s)
    end
    refresh_header
  end

  def create_units
    pmd_ac_v086_create_units
    req=rpg_request_v081
    if req!=nil && req[:region_v086]!=nil
      log_event(:region_ecology,
        'FORMATION region='+req[:region_v086].to_s+' key='+req[:formation_v086].to_s+
        ' rarity='+req[:rarity_v086].to_s+' enemies='+(@units||[]).select{|u|u.team==:enemy}.size.to_s)
    end
  end

  def process_loot_reward_v083(winner_team)
    loot=pmd_ac_v086_process_loot_reward_v083(winner_team)
    return loot unless verification_mode==:normal && winner_team==:ally
    req=rpg_request_v081
    return loot if req==nil || req[:region_v086]==nil
    elite_count=0
    (@units||[]).each do |u|
      if u.team==:enemy && u.respond_to?(:elite_v084) && u.elite_v084
        elite_count+=1
      end
    end
    bonus=PMD_AC.apply_region_bonus_rewards_v086(req,elite_count,false,nil)
    return loot if bonus.empty?
    loot={:table=>nil,:results=>[],:labels=>[],:winner=>winner_team} if loot==nil
    loot[:results]||=[]
    loot[:labels]||=[]
    bonus.each do |r|
      loot[:results].push(r)
      loot[:labels].push(r[:label].to_s)
    end
    @loot_reward_v083=loot
    log_event(:region_ecology,
      'BONUS rare='+(req[:rare_v086] ? '1':'0')+' elite_count='+elite_count.to_s+
      ' rewards='+bonus.collect{|x|x[:label].to_s}.join('|'))
    loot
  end

  def refresh_header
    pmd_ac_v086_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.86',1)
  end

  def region_ecology_v086?
    verification_mode==:region_ecology_v086
  end

  def prepare_verification_battle
    pmd_ac_v086_prepare_verification_battle
    @region_ecology_v086_failed=false if region_ecology_v086?
  end

  def log_event(category,message)
    if category.to_s=='verify' && region_ecology_v086? &&
       message.to_s.index('REGION_')==0 && message.to_s.include?(' pass=0')
      @region_ecology_v086_failed=true
    end
    pmd_ac_v086_log_event(category,message)
  end

  def log_verify_v086(name,pass,detail='')
    @region_ecology_v086_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_region_manifest_v086
    return if @verification_done[:v086_manifest]
    m=PMD_AC::REGION_ECOLOGY_MANIFEST_V086
    e=PMD_AC.region_config_errors_v086
    pass=e.empty? && m[:formations]>=8 && m[:regions]>=4 && m[:rarities]==4
    log_verify_v086('REGION_ECOLOGY_MANIFEST_V086',pass,
      'formations='+m[:formations].to_s+' regions='+m[:regions].to_s+
      ' rarities='+m[:rarities].to_s+' errors=['+e.join(',')+']')
    @verification_done[:v086_manifest]=true
  end

  def verify_region_formation_v086
    return if @verification_done[:v086_formation]
    req=PMD_AC.region_request_v086(:forest_edge,{:formation=>:forest_mixed,:elite_rate=>0},0)
    setup=req==nil ? [] : PMD_AC.build_enemy_setup_v081(req,[0,0,0])
    species=setup.collect{|r|r[0]}
    pass=req!=nil && setup.size==3 && species==[:caterpie,:rattata,:pidgey] && !req[:rare_v086]
    log_verify_v086('REGION_FORMATION_V086',pass,
      'region=forest_edge formation='+(req==nil ? 'nil':req[:formation_v086].to_s)+
      ' species='+species.join(',')+' rare='+(req!=nil && req[:rare_v086] ? '1':'0'))
    @verification_done[:v086_formation]=true
  end

  def verify_region_rare_v086
    return if @verification_done[:v086_rare]
    common=PMD_AC.weighted_formation_pick_v086(:forest_edge,0)
    rare=PMD_AC.weighted_formation_pick_v086(:forest_edge,99)
    req=PMD_AC.region_request_v086(:forest_edge,{:formation=>rare,:elite_rate=>0},99)
    pass=common==:forest_mixed && rare==:forest_pikachu_rare && req!=nil && req[:rare_v086]
    log_verify_v086('REGION_RARE_V086',pass,
      'roll0='+common.to_s+' roll99='+rare.to_s+' rarity='+(req==nil ? 'nil':req[:rarity_v086].to_s))
    @verification_done[:v086_rare]=true
  end

  def verify_region_elite_reward_v086
    return if @verification_done[:v086_reward]
    req=PMD_AC.region_request_v086(:forest_edge,{:formation=>:forest_pikachu_rare,:elite_rate=>0},99)
    rows=PMD_AC.apply_region_bonus_rewards_v086(req,2,true,[0,0,0])
    total=0
    rows.each{|r|total+=r[:amount].to_i if r[:type]==:gold}
    pass=rows.size==3 && total==70 && rows[2][:label].to_s.index('精英獎勵')==0
    log_verify_v086('REGION_ELITE_REWARD_V086',pass,
      'rare_plus_formation_plus_elite2='+total.to_s+'G labels='+rows.collect{|r|r[:label]}.join('|'))
    @verification_done[:v086_reward]=true
  end

  def verify_region_map_bridge_v086
    return if @verification_done[:v086_map]
    cfg=PMD_AC.wild_region_config_v086(:forest_edge,9,15,[1,2])
    pass=cfg!=nil && cfg[:region_v086]==:forest_edge && cfg[:min_steps]==9 &&
      cfg[:max_steps]==15 && cfg[:terrain_tags]==[1,2]
    log_verify_v086('REGION_MAP_BRIDGE_V086',pass,
      'region='+(cfg==nil ? 'nil':cfg[:region_v086].to_s)+' steps='+
      (cfg==nil ? 'nil' : cfg[:min_steps].to_s+'..'+cfg[:max_steps].to_s)+
      ' terrain='+(cfg==nil ? 'nil':cfg[:terrain_tags].join(',')))
    @verification_done[:v086_map]=true
  end

  def verify_region_ui_v086
    return if @verification_done[:v086_ui]
    m=PMD_AC::UI_READABILITY_MANIFEST_V086
    pass=m[:mechanics_unchanged] && m[:header_title].to_i>=24 &&
      m[:box_name].to_i>=21 && m[:progression_title].to_i>=25 &&
      m[:result_title].to_i>=30 && m[:damage_font].to_i>=11
    log_verify_v086('REGION_UI_READABILITY_V086',pass,
      'header='+m[:header_title].to_s+' box='+m[:box_name].to_s+
      ' progression='+m[:progression_title].to_s+' result='+m[:result_title].to_s+
      ' damage='+m[:damage_font].to_s)
    @verification_done[:v086_ui]=true
  end

  def verify_region_carry_v086
    return if @verification_done[:v086_carry]
    pass=PMD_AC::ENCOUNTER_CONFIG_MANIFEST_V084[:boss_elite]==false &&
      PMD_AC::BATTLE_PRESENTATION_MANIFEST_V085[:supports].include?(:boss) &&
      PMD_AC::REWARD_LOOT_MANIFEST_V083[:boss_recruitable]==false &&
      PMD_AC::PARTY_CAPACITY_V045==3
    log_verify_v086('REGION_CARRY_V086',pass,
      'encounter=v0.81 field=v0.82 loot=v0.83 config=v0.84 presentation=v0.85 party=v0.78 progression=v0.77.1')
    @verification_done[:v086_carry]=true
  end

  def update_verification_script
    unless region_ecology_v086?
      pmd_ac_v086_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_region_manifest_v086 if f>=2
    verify_region_formation_v086 if f>=4
    verify_region_rare_v086 if f>=6
    verify_region_elite_reward_v086 if f>=8
    verify_region_map_bridge_v086 if f>=10
    verify_region_carry_v086 if f>=12
    verify_region_ui_v086 if f>=14
    if f>=16 && !@verification_done[:v086_final]
      pass=!@region_ecology_v086_failed
      log_verify_v086('REGION_ECOLOGY_V086',pass,
        'manifest=1 formation=1 rare=1 reward=1 map=1 carry=1 ui=1')
      @verification_done[:v086_final]=true
    end
    complete_verification_mode if f>=PMD_AC::REGION_ECOLOGY_VERIFY_END_V086
  end
end
