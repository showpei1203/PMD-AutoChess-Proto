#==============================================================================
# PMD AutoChess Proto v0.84
# Encounter Configuration / Enemy Scaling / Elite Runtime
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 這是 v0.84 的執行層。一般新增區域／調等級／改精英倍率時，請改前一支：
#   PMD AutoChess Encounter Config Data v0.84
# 本腳本只負責把那些資料套到 v0.81 的 Encounter Request 與敵方 Unit。
#
# 【實際流程】
# Encounter／Stage／Custom Battle 建立 request
#   ↓
# 若 request 指定 Encounter Profile／Scaling Profile
#   ↓
# v0.81 先照原本規則抽出 species／cell／base Lv
#   ↓
# v0.84 重新計算敵人 Lv、套全隊倍率、判定精英
#   ↓
# v0.81 Game_PMDChessUnit 正常建立
#   ↓
# apply_encounter_mods_v081 套 Boss／精英的暫時戰鬥倍率
#
# 【重要規則】
# 1. 沒指定 v0.84 Profile 的舊 Stage／Wild／Boss／Scripted Battle，行為完全照舊。
# 2. Boss 永遠不會被精英化；Boss 繼續使用 v0.81 :stat_mult / :phases / :mechanic。
# 3. 精英倍率只存在敵方 Runtime，不寫回 SpeciesDB，也不寫進招募 Pokémon Instance。
# 4. v0.75 近遠程平衡、v0.76 能力公式、v0.79 EXP、v0.83 Loot 都不在本腳本改寫。
#
# 【最常用事件指令】
# 直接用設定好的區域 Profile：
#   PMD_AC.start_profile_battle_v084(:forest_adaptive)
#
# 臨時提高難度：
#   PMD_AC.start_profile_battle_v084(:forest_adaptive, {
#     :level_offset=>2,
#     :elite_rate=>25
#   })
#
# 地圖開啟自動野怪：
#   PMD_AC.wild_profile_on_v084(:forest_adaptive, 10, 18, [1])
#
# 舊 Encounter API 直接套 Profile：
#   PMD_AC.start_battle_v081(:roadside_pikachu, {
#     :encounter_profile=>:roadside_adaptive
#   })
#
# 自訂戰直接套 Scaling，不一定要建立 Encounter Profile：
#   PMD_AC.start_custom_battle_v082('精英伏擊', [
#     [:rattata,12], [:pidgey,12], [:pikachu,13]
#   ], {
#     :scaling_profile=>:party_hard,
#     :elite_rate=>100,
#     :elite_profile=>:standard_elite,
#     :elite_max=>1
#   })
#
# 【驗證模式】
# 布陣畫面按 S 切到 ENCOUNTER_CONFIG_V084，再按 Shift。
# LOG 應看到：
#   ENCOUNTER_CONFIG_MANIFEST_V084 pass=1
#   ENCOUNTER_SCALING_V084 pass=1
#   ENCOUNTER_ELITE_V084 pass=1
#   ENCOUNTER_BOSS_ISOLATION_V084 pass=1
#   ENCOUNTER_WILD_PROFILE_V084 pass=1
#   ENCOUNTER_CONFIG_CARRY_V084 pass=1
#   ENCOUNTER_CONFIG_V084 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  V084_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V084_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:encounter_config_v084] +
    V084_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:encounter_config_v084}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V084_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:encounter_config_v084]='ENCOUNTER_CONFIG_V084'

  class << self
    def apply_direct_encounter_options_v084(request,options)
      return request if request==nil
      o=options.is_a?(Hash) ? options : {}
      r=request
      r[:scaling_profile_v084]=o[:scaling_profile] if o.has_key?(:scaling_profile)
      r[:level_floor_v084]=o[:level_floor] if o.has_key?(:level_floor)
      r[:level_cap_v084]=o[:level_cap] if o.has_key?(:level_cap)
      r[:level_offset_v084]=o[:level_offset].to_i if o.has_key?(:level_offset)
      r[:elite_rate_v084]=o[:elite_rate].to_i if o.has_key?(:elite_rate)
      r[:elite_profile_v084]=o[:elite_profile] if o.has_key?(:elite_profile)
      r[:elite_max_v084]=o[:elite_max].to_i if o.has_key?(:elite_max)
      r[:enemy_stat_mult_v084]=o[:enemy_stat_mult] if o.has_key?(:enemy_stat_mult)
      r
    end

    def postprocess_enemy_setup_v084(base,request,level_rolls=nil,elite_rolls=nil)
      return base if request==nil
      active=request[:encounter_profile_v084]!=nil || request[:scaling_profile_v084]!=nil ||
        request[:elite_rate_v084]!=nil || request[:enemy_stat_mult_v084]!=nil
      return base unless active
      out=[]
      elite_count=0
      max_elite=request[:elite_max_v084]
      max_elite=99 if max_elite==nil
      base.each_with_index do |row,i|
        r=row.dup
        mods=dup_enemy_mods_v084(row[4]||{})
        lr=level_rolls==nil ? nil : level_rolls[i]
        r[3]=scaled_enemy_level_v084(row[3],request,i,lr)
        if request[:enemy_stat_mult_v084].is_a?(Hash)
          mods[:stat_mult]=merge_stat_mult_v084(mods[:stat_mult],request[:enemy_stat_mult_v084])
        end
        force=mods[:force_elite] ? true : false
        eligible=elite_eligible_v084?(request,mods)
        rate=mods.has_key?(:elite_rate) ? mods[:elite_rate].to_i : (request[:elite_rate_v084]||0).to_i
        roll=elite_rolls==nil ? nil : elite_rolls[i]
        roll=rand(100) if roll==nil
        chosen=eligible && (force || (elite_count<max_elite.to_i && rate>0 && roll.to_i%100<rate))
        if chosen
          ep=mods[:elite_profile] || request[:elite_profile_v084] || :standard_elite
          mods=apply_elite_profile_v084(mods,ep)
          elite_count+=1
        end
        r[4]=mods
        out.push(r)
      end
      out
    end

    alias pmd_ac_v084_make_battle_request_v081 make_battle_request_v081 unless method_defined?(:pmd_ac_v084_make_battle_request_v081)
    def make_battle_request_v081(key,options=nil)
      r=pmd_ac_v084_make_battle_request_v081(key,options)
      return nil if r==nil
      o=options.is_a?(Hash) ? options : {}
      d=encounter_data_v081(key)
      profile=o[:encounter_profile]
      profile=d[:encounter_profile] if profile==nil && d!=nil
      r=apply_profile_to_request_v084(r,profile,o) if profile!=nil
      apply_direct_encounter_options_v084(r,o)
    end

    alias pmd_ac_v084_stage_request_v081 stage_request_v081 unless method_defined?(:pmd_ac_v084_stage_request_v081)
    def stage_request_v081(stage_id,options=nil)
      r=pmd_ac_v084_stage_request_v081(stage_id,options)
      return nil if r==nil
      d=stage_data_v080(stage_id)
      o=options.is_a?(Hash) ? options : {}
      profile=o[:encounter_profile]
      profile=d[:encounter_profile] if profile==nil && d!=nil && d.has_key?(:encounter_profile)
      r=apply_profile_to_request_v084(r,profile,o) if profile!=nil
      if d!=nil
        map={
          :scaling_profile=>:scaling_profile,
          :level_floor=>:level_floor,
          :level_cap=>:level_cap,
          :level_offset=>:level_offset,
          :elite_rate=>:elite_rate,
          :elite_profile=>:elite_profile,
          :elite_max=>:elite_max,
          :enemy_stat_mult=>:enemy_stat_mult
        }
        map.each do |ok,dk|
          o[ok]=d[dk] if !o.has_key?(ok) && d.has_key?(dk)
        end
      end
      apply_direct_encounter_options_v084(r,o)
    end

    alias pmd_ac_v084_custom_battle_request_v082 custom_battle_request_v082 unless method_defined?(:pmd_ac_v084_custom_battle_request_v082)
    def custom_battle_request_v082(name,enemy_setup,options=nil)
      r=pmd_ac_v084_custom_battle_request_v082(name,enemy_setup,options)
      o=options.is_a?(Hash) ? options : {}
      profile=o[:encounter_profile]
      r=apply_profile_to_request_v084(r,profile,o) if profile!=nil
      apply_direct_encounter_options_v084(r,o)
    end

    alias pmd_ac_v084_build_enemy_setup_v081 build_enemy_setup_v081 unless method_defined?(:pmd_ac_v084_build_enemy_setup_v081)
    def build_enemy_setup_v081(request,seed_rolls=nil)
      base=pmd_ac_v084_build_enemy_setup_v081(request,seed_rolls)
      postprocess_enemy_setup_v084(base,request,nil,nil)
    end

    alias pmd_ac_v084_player_status_parts_v0742 player_status_parts_v0742 unless method_defined?(:pmd_ac_v084_player_status_parts_v0742)
    def player_status_parts_v0742(unit)
      parts=pmd_ac_v084_player_status_parts_v0742(unit)
      parts=[] if parts==nil
      if unit!=nil && unit.respond_to?(:elite_v084) && unit.elite_v084
        label=unit.respond_to?(:elite_label_v084) ? unit.elite_label_v084.to_s : '精英'
        label='精英' if label==''
        parts.delete(label)
        parts.unshift(label)
      end
      parts[0,STATUS_MAX_PARTS_V0742]
    end
  end
end

class Game_PMDChessUnit
  attr_reader :elite_v084
  attr_reader :elite_profile_v084
  attr_reader :elite_label_v084

  alias pmd_ac_v084_apply_encounter_mods_v081 apply_encounter_mods_v081 unless method_defined?(:pmd_ac_v084_apply_encounter_mods_v081)
  def apply_encounter_mods_v081(mods)
    pmd_ac_v084_apply_encounter_mods_v081(mods)
    mods={} if mods==nil
    @elite_v084=mods[:elite_v084] ? true : false
    @elite_profile_v084=mods[:elite_profile_v084]
    @elite_label_v084=mods[:elite_label_v084]
    true
  end
end

class Scene_Map
  alias pmd_ac_v084_update_encounter update_encounter unless method_defined?(:pmd_ac_v084_update_encounter)
  def update_encounter
    cfg=PMD_AC.wild_config_for_map_v081($game_map.map_id)
    if cfg==nil || cfg[:profile]==nil
      pmd_ac_v084_update_encounter
      return
    end
    return if $game_player.encounter_count>0
    return if $game_map.interpreter.running?
    return if $game_system.encounter_disabled
    return unless PMD_AC.wild_terrain_valid_v081(cfg)
    mn=(cfg[:min_steps]||10).to_i
    mx=(cfg[:max_steps]||18).to_i
    $game_player.make_pmd_encounter_count_v081(mn,mx)
    PMD_AC.start_profile_battle_v084(cfg[:profile],{:source=>:wild,:deploy=>false})
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v084_start start unless method_defined?(:pmd_ac_v084_start)
  alias pmd_ac_v084_create_units create_units unless method_defined?(:pmd_ac_v084_create_units)
  alias pmd_ac_v084_refresh_header refresh_header unless method_defined?(:pmd_ac_v084_refresh_header)
  alias pmd_ac_v084_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v084_prepare_verification_battle)
  alias pmd_ac_v084_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v084_update_verification_script)
  alias pmd_ac_v084_log_event log_event unless method_defined?(:pmd_ac_v084_log_event)

  def start
    pmd_ac_v084_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.84 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::ENCOUNTER_CONFIG_MANIFEST_V084
    log_event(:encounter_config,
      'FLOW v0.84 scaling='+m[:scaling_profiles].to_s+
      ' elite_profiles='+m[:elite_profiles].to_s+
      ' encounter_profiles='+m[:encounter_profiles].to_s+
      ' boss_elite=off recruit_elite_mods=off base=v0.81')
    req=rpg_request_v081
    if req!=nil && req[:encounter_profile_v084]!=nil
      log_event(:encounter_config,
        'REQUEST profile='+req[:encounter_profile_v084].to_s+
        ' scaling='+(req[:scaling_profile_v084]||:fixed).to_s+
        ' elite_rate='+(req[:elite_rate_v084]||0).to_s+
        ' elite_max='+(req[:elite_max_v084]==nil ? 'unlimited' : req[:elite_max_v084].to_s))
    end
    refresh_header
  end

  def create_units
    pmd_ac_v084_create_units
    (@units||[]).each do |u|
      next unless u.team==:enemy && u.respond_to?(:elite_v084) && u.elite_v084
      log_event(:encounter_config,
        'ELITE unit='+u.log_name+' profile='+u.elite_profile_v084.to_s+
        ' label='+u.elite_label_v084.to_s+' lv='+u.level.to_s)
    end
  end

  def refresh_header
    pmd_ac_v084_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.84',1)
  end

  def encounter_config_v084?
    verification_mode==:encounter_config_v084
  end

  def prepare_verification_battle
    pmd_ac_v084_prepare_verification_battle
    @encounter_config_v084_failed=false if encounter_config_v084?
  end

  def log_event(category,message)
    if category.to_s=='verify' && encounter_config_v084? &&
       message.to_s.index('ENCOUNTER_')==0 && message.to_s.include?(' pass=0')
      @encounter_config_v084_failed=true
    end
    pmd_ac_v084_log_event(category,message)
  end

  def log_verify_v084(name,pass,detail='')
    @encounter_config_v084_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_encounter_manifest_v084
    return if @verification_done[:v084_manifest]
    e=PMD_AC.encounter_config_errors_v084
    m=PMD_AC::ENCOUNTER_CONFIG_MANIFEST_V084
    pass=e.empty? && m[:scaling_profiles]>=5 && m[:elite_profiles]>=3 && m[:encounter_profiles]>=4
    log_verify_v084('ENCOUNTER_CONFIG_MANIFEST_V084',pass,
      'scaling='+m[:scaling_profiles].to_s+' elite='+m[:elite_profiles].to_s+
      ' profiles='+m[:encounter_profiles].to_s+' errors=['+e.join(',')+']')
    @verification_done[:v084_manifest]=true
  end

  def verify_encounter_scaling_v084
    return if @verification_done[:v084_scaling]
    avg=PMD_AC.party_average_level_v084
    req={:scaling_profile_v084=>:party_hard,:level_floor_v084=>1,:level_cap_v084=>100,
      :level_offset_v084=>0}
    lv=PMD_AC.scaled_enemy_level_v084(5,req,0,1)
    pass=lv==avg+2
    log_verify_v084('ENCOUNTER_SCALING_V084',pass,
      'party_avg='+avg.to_s+' profile=party_hard expected='+(avg+2).to_s+' actual='+lv.to_s)
    @verification_done[:v084_scaling]=true
  end

  def verify_encounter_elite_v084
    return if @verification_done[:v084_elite]
    req={:kind=>:wild,:scaling_profile_v084=>:fixed,:elite_rate_v084=>100,
      :elite_profile_v084=>:standard_elite,:elite_max_v084=>1}
    base=[[:pikachu,5,2,15,{}],[:rattata,5,3,15,{}]]
    out=PMD_AC.postprocess_enemy_setup_v084(base,req,[0,0],[0,0])
    a=out[0][4];b=out[1][4]
    hp=a[:stat_mult]==nil ? 1.0 : a[:stat_mult][:hp].to_f
    pass=a[:elite_v084] && !b[:elite_v084] && hp>1.40 && (a[:energy_start]||0).to_i>0
    log_verify_v084('ENCOUNTER_ELITE_V084',pass,
      'first_elite='+(a[:elite_v084] ? '1':'0')+' second_elite='+(b[:elite_v084] ? '1':'0')+
      ' hp_mult='+sprintf('%.2f',hp)+' max=1')
    @verification_done[:v084_elite]=true
  end

  def verify_encounter_boss_isolation_v084
    return if @verification_done[:v084_boss]
    req={:kind=>:boss,:boss=>true,:scaling_profile_v084=>:fixed,:elite_rate_v084=>100,
      :elite_profile_v084=>:veteran_elite,:elite_max_v084=>3}
    base=[[:beedrill,5,2,18,{:boss=>true,:stat_mult=>{:hp=>2.6}}]]
    out=PMD_AC.postprocess_enemy_setup_v084(base,req,[0],[0])
    mods=out[0][4]
    pass=!mods[:elite_v084] && mods[:boss] && (mods[:stat_mult][:hp].to_f-2.6).abs<0.001
    log_verify_v084('ENCOUNTER_BOSS_ISOLATION_V084',pass,
      'boss_elite='+(mods[:elite_v084] ? '1':'0')+' boss_hp='+mods[:stat_mult][:hp].to_s+
      ' boss_runtime=v0.81')
    @verification_done[:v084_boss]=true
  end

  def verify_encounter_wild_profile_v084
    return if @verification_done[:v084_wild]
    cfg=PMD_AC.wild_profile_config_v084(:forest_adaptive,9,15,[1,2])
    p=PMD_AC.encounter_profile_v084(:forest_adaptive)
    pass=cfg!=nil && cfg[:encounter]==:forest_wild && cfg[:profile]==:forest_adaptive &&
      cfg[:min_steps]==9 && cfg[:max_steps]==15 && cfg[:terrain_tags]==[1,2] && p[:elite_rate]==10
    log_verify_v084('ENCOUNTER_WILD_PROFILE_V084',pass,
      'profile=forest_adaptive source='+(cfg==nil ? 'nil':cfg[:encounter].to_s)+
      ' steps=9..15 terrain=1,2 elite_rate='+(p==nil ? 'nil':p[:elite_rate].to_s))
    @verification_done[:v084_wild]=true
  end

  def verify_encounter_carry_v084
    return if @verification_done[:v084_carry]
    pass=PMD_AC::RPG_ENCOUNTER_MANIFEST_V081[:boss_recruitable]==false &&
      PMD_AC::REWARD_LOOT_MANIFEST_V083[:boss_recruitable]==false &&
      PMD_AC::PARTY_CAPACITY_V045==3
    log_verify_v084('ENCOUNTER_CONFIG_CARRY_V084',pass,
      'encounter=v0.81 field=v0.82 loot=v0.83 party=v0.78 progression=v0.77.1 stats=v0.76 balance=v0.75')
    @verification_done[:v084_carry]=true
  end

  def update_verification_script
    unless encounter_config_v084?
      pmd_ac_v084_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_encounter_manifest_v084 if f>=2
    verify_encounter_scaling_v084 if f>=4
    verify_encounter_elite_v084 if f>=6
    verify_encounter_boss_isolation_v084 if f>=8
    verify_encounter_wild_profile_v084 if f>=10
    verify_encounter_carry_v084 if f>=12
    if f>=16 && !@verification_done[:v084_final]
      pass=!@encounter_config_v084_failed
      log_verify_v084('ENCOUNTER_CONFIG_V084',pass,
        'manifest=1 scaling=1 elite=1 boss=1 wild=1 carry=1')
      @verification_done[:v084_final]=true
    end
    complete_verification_mode if f>=PMD_AC::ENCOUNTER_CONFIG_VERIFY_END_V084
  end
end
