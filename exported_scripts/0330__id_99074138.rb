#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Map Integration Runtime v0.92
# 分類：RPG 地圖事件整合／Scene_Map Bridge／事件作者 API
#
# 【用途】
# 提供正式地圖事件能直接呼叫的高階 API，並把地圖野生遭遇綁定到 v0.86 Region
# Ecology + v0.87 Unlock。所有實際戰鬥仍走 Scene_PMD_AutoChess 與既有 Request，
# 因此 HP Carry、Reward、Rare/Elite、Boss、招募、Once Switch、Common Event 都沿用
# 已驗證系統，不另外製作「地圖專用戰鬥」。
#
# 【主要設定／規則】
# - Runtime Map Binding 優先於 MAP_BINDINGS_V092 靜態表。
# - bind_map_v092 只綁目前／指定 Map ID；不污染其他地圖。
# - Scene_Map 每次進入時會重新套用有效 Binding，但只有 Binding signature 改變時
#   才重設 encounter_count，避免打完一場回地圖後又被重新洗步數。
# - Terrain Tag 使用 v0.81 的野生遭遇判定；Region／Formation Unlock 使用 v0.87。
# - Boss 呼叫強制 recruitable=false、can_escape=false。
# - Scripted／Region／Custom battle 預設 deploy=true，因此先顯示 v0.90 Preview。
# - 事件戰預設 hp_policy=:carry、defeat_policy=:return_heal，可由 options 覆寫。
#
# 【事件／腳本呼叫方式與範例】
# 1. 地圖入口事件（Autorun 後自刪或 Parallel 一次）：
#      PMD_AC.bind_map_v092(:forest_route)
#    若正式使用 MAP_BINDINGS_V092 靜態表，則連這行都不需要。
#
# 2. 檢查點／回復點：
#      PMD_AC.checkpoint_here_v092
#      PMD_AC.heal_party_here_v092
#
# 3. 固定事件戰：
#      PMD_AC.event_battle_v092(:roadside_pikachu,
#        {:once_switch=>81, :result_variable=>21})
#
# 4. 區域隨機編成事件戰：
#      PMD_AC.event_region_v092(:forest_edge,
#        {:deploy=>true, :result_variable=>21})
#
# 5. Boss：
#      PMD_AC.event_boss_v092(:boss_beedrill,
#        {:once_switch=>82, :defeat_policy=>:checkpoint,
#         :result_variable=>21, :win_common_event=>12})
#
# 6. 不新增 DB entry 的臨時戰：
#      PMD_AC.event_custom_v092('路邊伏擊',
#        [[:rattata,14],[:pidgey,15]],
#        {:recruitable=>false, :result_variable=>21})
#
# 7. 回地圖後判斷：
#      PMD_AC.map_result_code_v092        # 1勝 / 2敗 / 3逃 / 0尚無
#      PMD_AC.event_won_v092?
#      PMD_AC.event_lost_v092?
#      PMD_AC.event_escaped_v092?
#
# 【注意事項】
# - 不要用本 API 手動建立 Game_PMDChessUnit；一律讓既有 Encounter Request 建立。
# - Boss Event 仍建議使用有 v0.91 Profile link 的 encounter key。
# - bind_map_v092(nil) 無效；取消請使用 unbind_map_v092。
# - 新增地圖只需設定 Profile／Binding，不需要複製 Scene_Map 程式。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容；避免使用 RGSS2 不支援的新式語法。
#==============================================================================
module PMD_AC
  V092_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V092_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:map_integration_v092] +
    V092_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:map_integration_v092}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V092_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:map_integration_v092]='MAP_INTEGRATION_V092'

  class << self
    def runtime_map_bindings_v092
      return {} if $game_system==nil
      h=$game_system.pmd_autochess_map_bindings_v092
      if h==nil
        h={}
        $game_system.pmd_autochess_map_bindings_v092=h
      end
      h
    end

    def map_binding_signatures_v092
      return {} if $game_system==nil
      h=$game_system.pmd_autochess_map_binding_signatures_v092
      if h==nil
        h={}
        $game_system.pmd_autochess_map_binding_signatures_v092=h
      end
      h
    end

    def effective_map_binding_v092(map_id)
      mid=map_id.to_i
      r=runtime_map_bindings_v092[mid]
      return r if r!=nil
      s=static_map_binding_v092(mid)
      return nil if s==nil
      s.is_a?(Hash) ? s.dup : {:profile=>s}
    end

    def build_map_wild_config_v092(binding)
      return nil if binding==nil
      b=binding.is_a?(Hash) ? binding.dup : {:profile=>binding}
      key=b[:profile]
      row=map_profile_options_v092(key,b)
      return nil if row==nil
      region=row[:region]
      return nil unless region_available_v087?(region)
      cfg=wild_region_config_v087(region,row[:min_steps]||10,row[:max_steps]||18,
        row[:terrain_tags],row[:condition])
      return nil if cfg==nil
      cfg[:map_integration_v092]=true
      cfg[:map_profile_v092]=key
      cfg
    end

    def map_binding_signature_v092(binding)
      return 'none' if binding==nil
      b=binding.is_a?(Hash) ? binding : {:profile=>binding}
      key=b[:profile]
      row=map_profile_options_v092(key,b)
      return 'invalid' if row==nil
      tags=(row[:terrain_tags]||[]).collect{|x|x.to_i}.join(',')
      [key,row[:region],row[:min_steps],row[:max_steps],tags,row[:condition].to_s].join('|')
    end

    def apply_map_binding_v092(map_id=nil,force_reset=false)
      return false if $game_system==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      return false if mid<=0
      binding=effective_map_binding_v092(mid)
      return false if binding==nil
      cfg=build_map_wild_config_v092(binding)
      return false if cfg==nil
      wild_runtime_maps_v081[mid]=cfg
      sig=map_binding_signature_v092(binding)
      old=map_binding_signatures_v092[mid]
      if (force_reset || old!=sig) && $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
        $game_player.make_pmd_encounter_count_v081(cfg[:min_steps],cfg[:max_steps])
      end
      map_binding_signatures_v092[mid]=sig
      true
    end

    def bind_map_v092(profile_key,options=nil,map_id=nil)
      return false if map_profile_v092(profile_key)==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      return false if mid<=0
      row=options==nil ? {} : options.dup
      row[:profile]=profile_key
      runtime_map_bindings_v092[mid]=row
      apply_map_binding_v092(mid,true)
    end

    def unbind_map_v092(map_id=nil)
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      return false if mid<=0
      runtime_map_bindings_v092.delete(mid)
      map_binding_signatures_v092.delete(mid)
      cfg=wild_runtime_maps_v081[mid]
      if cfg!=nil && cfg[:map_integration_v092]
        wild_runtime_maps_v081.delete(mid)
      end
      true
    end

    def current_map_profile_v092
      return nil if $game_map==nil
      b=effective_map_binding_v092($game_map.map_id)
      b==nil ? nil : b[:profile]
    end

    def checkpoint_here_v092
      set_checkpoint_v082
    end

    def heal_party_here_v092
      heal_party_v082
    end

    def heal_all_owned_here_v092
      heal_all_owned_v082
    end

    def event_default_options_v092(options=nil)
      o=options==nil ? {} : options.dup
      o[:source]=:script unless o.has_key?(:source)
      o[:deploy]=true unless o.has_key?(:deploy)
      o[:hp_policy]=:carry unless o.has_key?(:hp_policy)
      o[:defeat_policy]=:return_heal unless o.has_key?(:defeat_policy)
      o
    end

    def event_request_v092(encounter_key,options=nil)
      o=event_default_options_v092(options)
      make_battle_request_v081(encounter_key,o)
    end

    def event_boss_request_v092(encounter_key,options=nil)
      o=event_default_options_v092(options)
      o[:can_escape]=false
      r=make_battle_request_v081(encounter_key,o)
      return nil if r==nil
      r[:kind]=:boss
      r[:boss]=true
      r[:recruitable]=false
      r[:recruit_rate]=0
      r[:can_escape]=false
      r
    end

    def event_region_request_v092(region_key,options=nil,formation_roll=nil)
      o=event_default_options_v092(options)
      region_request_v087(region_key,o,formation_roll)
    end

    def event_custom_request_v092(name,enemy_setup,options=nil,boss=false)
      o=event_default_options_v092(options)
      if boss
        o[:kind]=:boss
        o[:recruitable]=false
        o[:recruit_rate]=0
        o[:can_escape]=false
      end
      custom_battle_request_v082(name,enemy_setup,o)
    end

    def event_battle_v092(encounter_key,options=nil)
      r=event_request_v092(encounter_key,options)
      return false if r==nil
      return false if once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def event_boss_v092(encounter_key,options=nil)
      r=event_boss_request_v092(encounter_key,options)
      return false if r==nil
      return false if once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def event_region_v092(region_key,options=nil)
      r=event_region_request_v092(region_key,options,nil)
      return false if r==nil
      return false if once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def event_stage_v092(stage_id,options=nil)
      o=options==nil ? {} : options.dup
      o[:source]=:script unless o.has_key?(:source)
      o[:deploy]=true unless o.has_key?(:deploy)
      start_stage_battle_v081(stage_id,o)
    end

    def event_custom_v092(name,enemy_setup,options=nil)
      r=event_custom_request_v092(name,enemy_setup,options,false)
      return false if r==nil || r[:enemy_setup].empty?
      return false if once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def event_custom_boss_v092(name,enemy_setup,options=nil)
      r=event_custom_request_v092(name,enemy_setup,options,true)
      return false if r==nil || r[:enemy_setup].empty?
      return false if once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def event_won_v092?; last_battle_result_v081==:win; end
    def event_lost_v092?; last_battle_result_v081==:lose; end
    def event_escaped_v092?; last_battle_result_v081==:escape; end

    def copy_result_to_variable_v092(variable_id)
      return false if $game_variables==nil || variable_id.to_i<=0
      $game_variables[variable_id.to_i]=map_result_code_v092
      true
    end

    def current_terrain_tag_v092
      return 0 if $game_map==nil || $game_player==nil
      $game_map.terrain_tag($game_player.x,$game_player.y).to_i
    end

    def current_map_encounter_allowed_v092?
      return false if $game_map==nil
      cfg=region_wild_config_for_map_v086($game_map.map_id)
      return false if cfg==nil
      terrain_tag_allowed_v092?(cfg,current_terrain_tag_v092)
    end
  end
end

class Game_System
  attr_accessor :pmd_autochess_map_bindings_v092
  attr_accessor :pmd_autochess_map_binding_signatures_v092
end

class Scene_Map
  alias pmd_ac_v092_start start unless method_defined?(:pmd_ac_v092_start)
  def start
    pmd_ac_v092_start
    PMD_AC.apply_map_binding_v092($game_map.map_id,false) if $game_map!=nil
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v092_start start unless method_defined?(:pmd_ac_v092_start)
  alias pmd_ac_v092_refresh_header refresh_header unless method_defined?(:pmd_ac_v092_refresh_header)
  alias pmd_ac_v092_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v092_prepare_verification_battle)
  alias pmd_ac_v092_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v092_update_verification_script)
  alias pmd_ac_v092_log_event log_event unless method_defined?(:pmd_ac_v092_log_event)

  def map_integration_v092?
    verification_mode==:map_integration_v092
  end

  def start
    pmd_ac_v092_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.92 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::MAP_INTEGRATION_MANIFEST_V092
    log_event(:map_integration,
      'FLOW v0.92 profiles='+m[:profiles].to_s+
      ' static_bindings='+m[:static_bindings].to_s+
      ' runtime_bind=1 region=v0.86-v0.87 terrain=v0.81 field=v0.82 reward=v0.83 boss=v0.91 tactical=v0.91.4')
    refresh_header
  end

  def refresh_header
    pmd_ac_v092_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.size=size
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.92',1)
  end

  def prepare_verification_battle
    pmd_ac_v092_prepare_verification_battle
    if map_integration_v092?
      @map_integration_failed_v092=false
      @map_integration_saved_checkpoint_v092=nil
      if $game_system!=nil
        @map_integration_saved_checkpoint_v092=$game_system.pmd_autochess_checkpoint_v082
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && map_integration_v092? &&
       message.to_s.index('MAP_')==0 && message.to_s.include?(' pass=0')
      @map_integration_failed_v092=true
    end
    pmd_ac_v092_log_event(category,message)
  end

  def log_verify_v092(name,pass,detail='')
    @map_integration_failed_v092=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_map_manifest_v092
    return if @verification_done[:v092_manifest]
    e=PMD_AC.map_profile_errors_v092
    m=PMD_AC::MAP_INTEGRATION_MANIFEST_V092
    pass=e.empty? && m[:profiles]==3 && m[:event_api] && m[:runtime_binding]
    log_verify_v092('MAP_INTEGRATION_MANIFEST_V092',pass,
      'profiles='+m[:profiles].to_s+' static='+m[:static_bindings].to_s+
      ' errors=['+e.join(',')+'] checksum32='+m[:runtime_checksum32].to_s)
    @verification_done[:v092_manifest]=true
  end

  def verify_map_binding_v092
    return if @verification_done[:v092_binding]
    b={:profile=>:forest_route}
    c=PMD_AC.build_map_wild_config_v092(b)
    pass=c!=nil && c[:region_v086]==:forest_edge && c[:min_steps]==10 && c[:max_steps]==18 &&
      c[:terrain_tags]==[1,2] && c[:map_integration_v092] && c[:map_profile_v092]==:forest_route
    log_verify_v092('MAP_REGION_BINDING_V092',pass,
      'profile=forest_route region='+(c==nil ? 'nil' : c[:region_v086].to_s)+
      ' steps='+(c==nil ? 'nil' : c[:min_steps].to_s+'..'+c[:max_steps].to_s)+' terrain=1,2')
    @verification_done[:v092_binding]=true
  end

  def verify_map_terrain_v092
    return if @verification_done[:v092_terrain]
    c={:terrain_tags=>[1,2]}
    pass=PMD_AC.terrain_tag_allowed_v092?(c,1) && PMD_AC.terrain_tag_allowed_v092?(c,2) &&
      !PMD_AC.terrain_tag_allowed_v092?(c,3) && PMD_AC.terrain_tag_allowed_v092?({:terrain_tags=>[]},99)
    log_verify_v092('MAP_TERRAIN_RULE_V092',pass,'allow=1,2 deny=3 empty=all legacy_check=v0.81')
    @verification_done[:v092_terrain]=true
  end

  def verify_map_event_api_v092
    return if @verification_done[:v092_api]
    a=PMD_AC.event_request_v092(:roadside_pikachu,{:result_variable=>21})
    r=PMD_AC.event_region_request_v092(:forest_edge,{:formation=>:forest_mixed},0)
    pass=a!=nil && a[:deploy] && a[:options][:hp_policy]==:carry &&
      a[:options][:defeat_policy]==:return_heal && a[:options][:result_variable]==21 &&
      r!=nil && r[:region_v086]==:forest_edge && r[:formation_v086]==:forest_mixed
    log_verify_v092('MAP_EVENT_API_V092',pass,
      'scripted=roadside_pikachu region=forest_edge deploy=1 hp=carry defeat=return_heal result_var=21')
    @verification_done[:v092_api]=true
  end

  def verify_map_result_bridge_v092
    return if @verification_done[:v092_result]
    pass=PMD_AC.map_result_code_v092(:win)==1 && PMD_AC.map_result_code_v092(:lose)==2 &&
      PMD_AC.map_result_code_v092(:escape)==3 && PMD_AC.map_result_code_v092(:none)==0
    log_verify_v092('MAP_RESULT_BRIDGE_V092',pass,'win=1 lose=2 escape=3 none=0 switches+common_event=v0.81-v0.82')
    @verification_done[:v092_result]=true
  end

  def verify_map_checkpoint_heal_v092
    return if @verification_done[:v092_checkpoint]
    old=$game_system==nil ? nil : $game_system.pmd_autochess_checkpoint_v082
    ok=PMD_AC.set_checkpoint_v082(999,3,4,2)
    cp=PMD_AC.checkpoint_v082
    pass=ok && cp!=nil && cp[:map_id]==999 && cp[:x]==3 && cp[:y]==4 && cp[:direction]==2 &&
      PMD_AC.respond_to?(:heal_party_v082) && PMD_AC.respond_to?(:heal_all_owned_v082)
    $game_system.pmd_autochess_checkpoint_v082=old if $game_system!=nil
    log_verify_v092('MAP_CHECKPOINT_HEAL_V092',pass,'checkpoint=999,3,4 dir=2 heal_party=1 heal_owned=1 restored=1')
    @verification_done[:v092_checkpoint]=true
  end

  def verify_map_boss_custom_v092
    return if @verification_done[:v092_boss]
    b=PMD_AC.event_boss_request_v092(:boss_beedrill,{:defeat_policy=>:checkpoint})
    c=PMD_AC.event_custom_request_v092('驗證伏擊',[[:rattata,14],[:pidgey,15]],{:recruitable=>false},false)
    pass=b!=nil && b[:kind]==:boss && !b[:recruitable] && !b[:can_escape] &&
      b[:boss_profile_v091]==:hive_overlord && b[:options][:defeat_policy]==:checkpoint &&
      c!=nil && c[:enemy_setup].size==2 && c[:deploy]
    log_verify_v092('MAP_BOSS_SCRIPTED_V092',pass,
      'boss=beedrill profile='+(b==nil ? 'nil' : b[:boss_profile_v091].to_s)+
      ' recruit=0 escape=0 custom_enemies='+(c==nil ? '0' : c[:enemy_setup].size.to_s))
    @verification_done[:v092_boss]=true
  end

  def verify_map_carry_v092
    return if @verification_done[:v092_carry]
    pass=PMD_AC::RPG_FIELD_MANIFEST_V082[:checkpoint] &&
      PMD_AC::REGION_ECOLOGY_MANIFEST_V086[:regions]>=3 &&
      PMD_AC::ENCOUNTER_UNLOCK_MANIFEST_V087[:condition_presets]>=1 &&
      PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091[:profiles]>=1 &&
      PMD_AC::TACTICAL_PASSIVES_V0914.size>=1 && PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size>=1
    log_verify_v092('MAP_INTEGRATION_CARRY_V092',pass,
      'encounter=v0.81 field=v0.82 reward=v0.83 elite=v0.84 region=v0.86 unlock=v0.87 preview=v0.90 boss=v0.91 tactical=v0.91.4 battle_rules=unchanged')
    @verification_done[:v092_carry]=true
  end

  def update_verification_script
    unless map_integration_v092?
      pmd_ac_v092_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_map_manifest_v092 if f>=2
    verify_map_binding_v092 if f>=4
    verify_map_terrain_v092 if f>=6
    verify_map_event_api_v092 if f>=8
    verify_map_result_bridge_v092 if f>=10
    verify_map_checkpoint_heal_v092 if f>=12
    verify_map_boss_custom_v092 if f>=14
    verify_map_carry_v092 if f>=16
    if f>=20 && !@verification_done[:v092_final]
      pass=!@map_integration_failed_v092
      log_verify_v092('MAP_INTEGRATION_V092',pass,
        'profile=1 binding=1 terrain=1 event_api=1 result=1 checkpoint=1 boss=1 custom=1 carry=1')
      @verification_done[:v092_final]=true
    end
    complete_verification_mode if f>=PMD_AC::MAP_INTEGRATION_VERIFY_END_V092
  end
end
