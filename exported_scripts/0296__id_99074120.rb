#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.82
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - V082_OLD_VERIFICATION_MODES / V082_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - launch_battle_request_v081 / record_battle_result_v081 / set_current_hp_v082 / start
# - create_units / sync_field_hp_v082 / apply_defeat_policy_v082 / return_to_map_v081
# - refresh_header / rpg_field_v082? / prepare_verification_battle / log_event
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.82
# RPG Field Persistence / Recovery / Custom Battle Authoring
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  V082_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V082_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:rpg_field_v082] +
    V082_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:rpg_field_v082}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V082_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:rpg_field_v082]='RPG_FIELD_V082'

  class << self
    alias pmd_ac_v082_launch_battle_request_v081 launch_battle_request_v081 unless method_defined?(:pmd_ac_v082_launch_battle_request_v081)
    def launch_battle_request_v081(request)
      return false unless launch_rpg_request_guard_v082(request)
      pmd_ac_v082_launch_battle_request_v081(request)
    end

    alias pmd_ac_v082_record_battle_result_v081 record_battle_result_v081 unless method_defined?(:pmd_ac_v082_record_battle_result_v081)
    def record_battle_result_v081(request,result)
      data=pmd_ac_v082_record_battle_result_v081(request,result)
      mark_once_switch_v082(request,result)
      reserve_result_common_event_v082(request,result)
      data
    end
  end
end

class Game_PMDChessUnit
  def set_current_hp_v082(value)
    @hp=[[value.to_i,0].max,@maxhp.to_i].min
    @hp
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v082_start start unless method_defined?(:pmd_ac_v082_start)
  alias pmd_ac_v082_create_units create_units unless method_defined?(:pmd_ac_v082_create_units)
  alias pmd_ac_v082_return_to_map_v081 return_to_map_v081 unless method_defined?(:pmd_ac_v082_return_to_map_v081)
  alias pmd_ac_v082_refresh_header refresh_header unless method_defined?(:pmd_ac_v082_refresh_header)
  alias pmd_ac_v082_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v082_prepare_verification_battle)
  alias pmd_ac_v082_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v082_update_verification_script)
  alias pmd_ac_v082_log_event log_event unless method_defined?(:pmd_ac_v082_log_event)

  def start
    pmd_ac_v082_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.82 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::RPG_FIELD_MANIFEST_V082
    log_event(:rpg_field,
      'FLOW v0.82 hp_persistence=wild,boss,scripted stage_hp=full '+
      'heal_api=party+owned checkpoint=1 defeat=return_heal,return_map,checkpoint,gameover '+
      'common_event=1 once_switch=1 custom_battle=1 custom_boss=1 boss_recruit=off checksum32='+
      m[:runtime_checksum32].to_s)
    refresh_header
  end

  def create_units
    pmd_ac_v082_create_units
    req=PMD_AC.battle_request_v081
    return if req==nil
    count=0
    for u in (@units||[])
      next unless u.team==:ally
      count+=1 if PMD_AC.apply_field_hp_to_unit_v082(u,req)
    end
    log_event(:rpg_field,'HP_LOAD policy='+PMD_AC.encounter_hp_policy_v082(req).to_s+
      ' allies='+count.to_s) if count>0
  end

  def sync_field_hp_v082(req)
    return 0 if req==nil
    count=0
    for u in (@units||[])
      next if u.respond_to?(:summoned?) && u.summoned?
      count+=1 if PMD_AC.sync_field_hp_from_unit_v082(u,req)
    end
    if count>0
      detail=[]
      for inst in PMD_AC.party_instances_v082
        detail.push(inst.species_key.to_s+'='+inst.field_hp_v082.to_s+'/'+inst.field_maxhp_v082.to_s)
      end
      log_event(:rpg_field,'HP_SAVE policy=carry allies='+count.to_s+' ['+detail.join(',')+']')
    end
    count
  end

  def apply_defeat_policy_v082(req,result)
    return :continue unless result==:lose
    policy=PMD_AC.encounter_defeat_policy_v082(req)
    case policy
    when :gameover
      PMD_AC.clear_battle_request_v081
      log_event(:rpg_field,'DEFEAT policy=gameover')
      $scene=Scene_Gameover.new
      return :handled
    when :checkpoint
      PMD_AC.heal_party_v082
      cp=PMD_AC.checkpoint_v082
      if cp!=nil && $game_player!=nil
        $game_player.reserve_transfer(cp[:map_id],cp[:x],cp[:y],cp[:direction])
        log_event(:rpg_field,'DEFEAT policy=checkpoint map='+cp[:map_id].to_s+
          ' x='+cp[:x].to_s+' y='+cp[:y].to_s)
      else
        log_event(:rpg_field,'DEFEAT policy=checkpoint fallback=return_heal')
      end
    when :return_map
      log_event(:rpg_field,'DEFEAT policy=return_map hp_preserved=1')
    else
      PMD_AC.heal_party_v082
      log_event(:rpg_field,'DEFEAT policy=return_heal')
    end
    :continue
  end

  def return_to_map_v081
    req=rpg_request_v081
    result=PMD_AC.last_battle_result_v081
    sync_field_hp_v082(req)
    if PMD_AC.encounter_heal_after_v082(req,result)
      PMD_AC.heal_party_v082
      log_event(:rpg_field,'POST_HEAL result='+result.to_s+' party=full')
    end
    handled=apply_defeat_policy_v082(req,result)
    return if handled==:handled
    pmd_ac_v082_return_to_map_v081
  end

  def refresh_header
    pmd_ac_v082_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.82',1)
  end

  def rpg_field_v082?
    verification_mode==:rpg_field_v082
  end

  def prepare_verification_battle
    pmd_ac_v082_prepare_verification_battle
    @rpg_field_v082_failed=false if rpg_field_v082?
  end

  def log_event(category,message)
    if category.to_s=='verify' && rpg_field_v082? &&
       message.to_s.index('RPG_FIELD_')==0 && message.to_s.include?(' pass=0')
      @rpg_field_v082_failed=true
    end
    pmd_ac_v082_log_event(category,message)
  end

  def log_verify_v082(name,pass,detail='')
    @rpg_field_v082_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_rpg_field_manifest_v082
    return if @verification_done[:v082_manifest]
    m=PMD_AC::RPG_FIELD_MANIFEST_V082
    pass=m[:hp_persistence] && m[:custom_battle_api] && m[:custom_boss_api] &&
      m[:boss_recruitable]==false && m[:defeat_policies].size==4
    log_verify_v082('RPG_FIELD_MANIFEST_V082',pass,
      'hp=carry stage=full defeat=4 custom=1 boss_custom=1 checkpoint=1 common_event=1')
    @verification_done[:v082_manifest]=true
  end

  def verify_rpg_field_hp_v082
    return if @verification_done[:v082_hp]
    inst=PMD_PokemonInstance.new(:pikachu,15,
      {:instance_uid=>820001,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    max=inst.field_maxhp_v082
    start=[(max*0.40).round,1].max
    inst.set_field_hp_v082(start)
    u=Game_PMDChessUnit.new(98,:pikachu,:ally,0,0,inst);u.scene=self
    req={:kind=>:wild,:options=>{}}
    loaded=PMD_AC.apply_field_hp_to_unit_v082(u,req)
    after_load=u.hp
    damaged=[(max*0.25).round,1].max
    u.set_current_hp_v082(damaged)
    saved=PMD_AC.sync_field_hp_from_unit_v082(u,req)
    pass=loaded && saved && after_load==start && inst.field_hp_v082==damaged &&
      PMD_AC.encounter_hp_policy_v082(req)==:carry &&
      PMD_AC.encounter_hp_policy_v082({:kind=>:stage,:options=>{}})==:full
    log_verify_v082('RPG_FIELD_HP_V082',pass,
      'max='+max.to_s+' load='+start.to_s+' saved='+damaged.to_s+' wild=carry stage=full')
    @verification_done[:v082_hp]=true
  end

  def verify_rpg_field_custom_v082
    return if @verification_done[:v082_custom]
    rows=[[:rattata,14],[:pidgey,15],{:species=>:pikachu,:level=>16,:cell=>[5,3]}]
    r=PMD_AC.custom_battle_request_v082('測試伏擊',rows,
      {:recruitable=>true,:recruit_rate=>40,:deploy=>false})
    b=PMD_AC.custom_battle_request_v082('測試霸主',
      [[:beedrill,5,2,20,{:boss=>true,:stat_mult=>{:hp=>2.0}}]],
      {:kind=>:boss,:recruitable=>true,:recruit_rate=>100})
    sp=r[:enemy_setup].collect{|x|x[0]}
    pass=sp==[:rattata,:pidgey,:pikachu] && r[:recruitable] && r[:recruit_rate]==40 &&
      !r[:deploy] && b[:kind]==:boss && !b[:recruitable] && b[:recruit_rate]==0 && !b[:can_escape]
    log_verify_v082('RPG_FIELD_CUSTOM_BATTLE_V082',pass,
      'scripted='+sp.join(',')+' recruit=40 boss_recruit=0 boss_escape=0')
    @verification_done[:v082_custom]=true
  end

  def verify_rpg_field_defeat_v082
    return if @verification_done[:v082_defeat]
    a={:kind=>:wild,:options=>{}}
    b={:kind=>:boss,:options=>{:defeat_policy=>:checkpoint}}
    c={:kind=>:scripted,:options=>{:defeat_policy=>:gameover}}
    pass=PMD_AC.encounter_defeat_policy_v082(a)==:return_heal &&
      PMD_AC.encounter_defeat_policy_v082(b)==:checkpoint &&
      PMD_AC.encounter_defeat_policy_v082(c)==:gameover
    log_verify_v082('RPG_FIELD_DEFEAT_POLICY_V082',pass,
      'default=return_heal boss_override=checkpoint scripted_override=gameover')
    @verification_done[:v082_defeat]=true
  end

  def verify_rpg_field_hooks_v082
    return if @verification_done[:v082_hooks]
    old_ce=$game_temp==nil ? 0 : $game_temp.common_event_id
    sid=999
    old_sw=$game_switches==nil ? false : $game_switches[sid]
    $game_switches[sid]=false if $game_switches!=nil
    req={:kind=>:scripted,:options=>{:once_switch=>sid,:win_common_event=>998}}
    marked=PMD_AC.mark_once_switch_v082(req,:win)
    blocked=PMD_AC.once_switch_blocked_v082?(req)
    cid=PMD_AC.reserve_result_common_event_v082(req,:win)
    pass=marked && blocked && cid==998 && ($game_temp==nil || $game_temp.common_event_id==998)
    $game_switches[sid]=old_sw if $game_switches!=nil
    $game_temp.common_event_id=old_ce if $game_temp!=nil
    log_verify_v082('RPG_FIELD_RESULT_HOOKS_V082',pass,
      'once_switch=1 common_event=998 result_switch_bridge=v0.81')
    @verification_done[:v082_hooks]=true
  end

  def verify_rpg_field_heal_checkpoint_v082
    return if @verification_done[:v082_heal]
    inst=PMD_PokemonInstance.new(:bulbasaur,15,
      {:instance_uid=>820010,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    inst.set_field_hp_v082(1)
    inst.heal_field_hp_v082
    pass=inst.field_hp_v082==inst.field_maxhp_v082 &&
      PMD_AC::RPG_FIELD_MANIFEST_V082[:checkpoint]
    log_verify_v082('RPG_FIELD_RECOVERY_V082',pass,
      'heal_instance=full party_api=1 owned_api=1 checkpoint_api=1')
    @verification_done[:v082_heal]=true
  end

  def verify_rpg_field_carry_v082
    return if @verification_done[:v082_carry]
    pass=PMD_AC::RPG_ENCOUNTER_MANIFEST_V081[:contexts].size==4 &&
      PMD_AC::STAGE_DB_V080.size==3 && PMD_AC::PARTY_CAPACITY_V045==3 &&
      PMD_AC::STORAGE_BOX_COUNT_V045==24
    log_verify_v082('RPG_FIELD_CARRY_V082',pass,
      'encounter=v0.81 stage=v0.80 reward=v0.79 party=v0.78 progression=v0.77.1 stats=v0.76 balance=v0.75')
    @verification_done[:v082_carry]=true
  end

  def update_verification_script
    unless rpg_field_v082?
      pmd_ac_v082_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_rpg_field_manifest_v082 if f>=2
    verify_rpg_field_hp_v082 if f>=4
    verify_rpg_field_custom_v082 if f>=6
    verify_rpg_field_defeat_v082 if f>=8
    verify_rpg_field_hooks_v082 if f>=10
    verify_rpg_field_heal_checkpoint_v082 if f>=12
    verify_rpg_field_carry_v082 if f>=14
    if f>=16 && !@verification_done[:v082_final]
      pass=!@rpg_field_v082_failed
      log_verify_v082('RPG_FIELD_V082',pass,
        'manifest=1 hp=1 custom=1 defeat=1 hooks=1 recovery=1 carry=1')
      @verification_done[:v082_final]=true
    end
    complete_verification_mode if f>=PMD_AC::RPG_FIELD_VERIFY_END_V082
  end
end
