#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.81
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - V081_OLD_VERIFICATION_MODES / V081_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
# - RPG_RESULT_W_V081 / RPG_RESULT_H_V081
#
# 【PMD_AC 對外／共用方法】
# - context_label_v081 / draw_rpg_result_v081
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / make_pmd_encounter_count_v081 / start_combat / apply_encounter_mods_v081
# - boss_phase_rules_v081 / boss_phase_done_v081? / mark_boss_phase_v081 / apply_boss_stat_mult_v081
# - update_scene_change / call_pmd_autochess_v081 / update_encounter / rpg_request_v081
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.81
# RPG Encounter Bridge / Wild / Boss / Scripted Battle
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  V081_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V081_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:rpg_encounter_v081] +
    V081_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:rpg_encounter_v081}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V081_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:rpg_encounter_v081]='RPG_ENCOUNTER_V081'

  RPG_RESULT_W_V081 = 510
  RPG_RESULT_H_V081 = 284

  def self.context_label_v081(kind)
    return '野外遭遇' if kind==:wild
    return 'BOSS 戰' if kind==:boss
    return '事件戰鬥' if kind==:scripted
    return '關卡戰鬥' if kind==:stage
    '戰鬥'
  end

  def self.draw_rpg_result_v081(b,result_text,rows,record,attention,reward)
    return false if b==nil
    begin
      b.font.name=UI_PANEL_FONT_V0741
    rescue
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    b.clear
    b.fill_rect(0,0,b.width,b.height,Color.new(0,0,0,235))
    req=reward==nil ? nil : reward[:request]
    kind=req==nil ? nil : req[:kind]
    b.font.bold=true;b.font.size=28;b.font.color=Color.new(255,255,255)
    b.draw_text(10,7,b.width-20,34,result_text.to_s,1)
    b.font.bold=false;b.font.size=17;b.font.color=Color.new(205,225,245)
    sub=context_label_v081(kind)
    sub+='｜'+req[:name].to_s if req!=nil
    sub+='｜不可招募' if kind==:boss
    b.draw_text(16,42,b.width-32,23,sub,1)

    r=record || battle_loop_default_state_v079
    b.font.size=16;b.font.color=Color.new(180,205,230)
    rec='戰績 '+r[:wins].to_i.to_s+'勝 '+r[:losses].to_i.to_s+'敗｜連勝 '+r[:streak].to_i.to_s+
      '｜最高 '+r[:best_streak].to_i.to_s
    b.draw_text(16,64,b.width-32,22,rec,1)

    b.font.bold=true;b.font.size=18;b.font.color=Color.new(235,240,245)
    b.draw_text(18,87,b.width-36,23,'戰後成長',0)
    b.font.bold=false
    rows=rows || []
    for idx in 0...REWARD_RESULT_ROWS_V079
      row=rows[idx]
      y=110+idx*37
      b.fill_rect(16,y,b.width-32,34,Color.new(24,32,43,225))
      next if row==nil
      name=species_name_reward_v079(row[:species])
      b.font.size=17;b.font.bold=true;b.font.color=Color.new(245,245,245)
      b.draw_text(24,y+1,108,21,name,0)
      b.font.bold=false;b.font.size=15;b.font.color=Color.new(190,215,235)
      lv='Lv'+row[:level_before].to_s
      lv+='→'+row[:level].to_s if row[:level]>row[:level_before]
      b.draw_text(132,y+1,92,21,lv,0)
      b.draw_text(224,y+1,100,21,'EXP +'+row[:exp_gain].to_s,0)
      b.draw_text(324,y+1,120,21,'熟練 +'+row[:mastery_gain].to_s,0)
      tags=[]
      tags.push('NEW招 '+row[:pending_moves].to_s) if row[:pending_moves].to_i>0
      tags.push('進化 '+row[:evolution_choices].to_s) if row[:evolution_choices].to_i>0
      tags.push('已進化') if row[:evolved]
      unless tags.empty?
        b.font.size=13;b.font.color=Color.new(255,220,130)
        b.draw_text(132,y+18,b.width-156,15,tags.join('｜'),0)
      end
    end

    ry=224
    b.fill_rect(16,ry,b.width-32,34,Color.new(38,34,23,230))
    b.font.bold=true;b.font.size=16;b.font.color=Color.new(255,225,145)
    offer=reward==nil ? nil : reward[:offer]
    winner=reward==nil ? nil : reward[:winner]
    if winner==:ally
      if kind==:boss
        text='BOSS 戰勝利｜此戰敵人不可招募'
      elsif offer!=nil
        sp=species_name_reward_v079(offer[:species])
        text=offer[:accepted] ? ('招募完成：'+sp+' Lv'+offer[:level].to_s+' 已加入 BOX') :
          ('招募候選：'+sp+' Lv'+offer[:level].to_s+'｜A 加入 BOX')
      elsif req!=nil && req[:recruitable]
        text='本次沒有出現可招募的寶可夢'
      else
        text='此戰沒有招募獎勵'
      end
    else
      text='戰敗不發 EXP；技能熟練仍依實際使用累積'
    end
    b.draw_text(24,ry+5,b.width-48,23,text,0)
    b.font.bold=false;b.font.size=15
    b.font.color=attention.to_i>0 ? Color.new(255,220,130) : Color.new(185,210,230)
    foot='C 返回地圖'
    foot+='｜A 招募' if offer!=nil && !offer[:accepted]
    foot+='｜成長待處理 '+attention.to_i.to_s if attention.to_i>0
    b.draw_text(10,b.height-25,b.width-20,20,foot,1)
    true
  end
end

class Game_Player
  def make_pmd_encounter_count_v081(min_steps,max_steps)
    mn=[min_steps.to_i,1].max
    mx=[max_steps.to_i,mn].max
    @encounter_count=mn+(mx>mn ? rand(mx-mn+1) : 0)
  end
end

class Game_PMDChessUnit
  attr_reader :boss_v081
  attr_reader :boss_mechanic_v081

  alias pmd_ac_v081_start_combat start_combat unless method_defined?(:pmd_ac_v081_start_combat)
  def start_combat
    pmd_ac_v081_start_combat
    if @encounter_start_energy_v081!=nil && @encounter_start_energy_v081.to_i>0
      gain_energy(@encounter_start_energy_v081.to_i,self,:boss_start)
    end
  end

  def apply_encounter_mods_v081(mods)
    mods={} if mods==nil
    @boss_v081=mods[:boss] ? true : false
    @boss_mechanic_v081=mods[:mechanic]
    sm=mods[:stat_mult] || {}
    @maxhp=[(@maxhp.to_f*(sm[:hp]||1.0).to_f).round,1].max
    @hp=@maxhp
    @atk=[(@atk.to_f*(sm[:atk]||1.0).to_f).round,1].max
    @def=[(@def.to_f*(sm[:def]||1.0).to_f).round,1].max
    @spatk=[(@spatk.to_f*(sm[:spatk]||1.0).to_f).round,1].max
    @spdef=[(@spdef.to_f*(sm[:spdef]||1.0).to_f).round,1].max
    @speed_stat=[(@speed_stat.to_f*(sm[:speed]||1.0).to_f).round,1].max
    @encounter_start_energy_v081=(mods[:energy_start]||0).to_i
    @boss_phase_rules_v081=(mods[:phases]||[]).collect{|x|x.dup}
    @boss_phase_done_v081={}
    moves=mods[:active_moves] || []
    if @pokemon_instance!=nil && !moves.empty?
      moves.each{|mv|@pokemon_instance.learn_known_move_v045(mv,level,@pokemon_instance.species_key,false) unless @pokemon_instance.knows_move_v045?(mv)}
      @pokemon_instance.set_active_moves_v045(moves)
    end
    true
  end

  def boss_phase_rules_v081; @boss_phase_rules_v081 || []; end
  def boss_phase_done_v081?(key); (@boss_phase_done_v081||{})[key] ? true : false; end
  def mark_boss_phase_v081(key); @boss_phase_done_v081={} if @boss_phase_done_v081==nil;@boss_phase_done_v081[key]=true;end

  def apply_boss_stat_mult_v081(stat,mult)
    m=mult.to_f
    return false if m<=0
    case stat
    when :hp
      old=@maxhp;@maxhp=[(@maxhp*m).round,1].max;@hp += (@maxhp-old);@hp=@maxhp if @hp>@maxhp
    when :atk; @atk=[(@atk*m).round,1].max
    when :def; @def=[(@def*m).round,1].max
    when :spatk; @spatk=[(@spatk*m).round,1].max
    when :spdef; @spdef=[(@spdef*m).round,1].max
    when :speed; @speed_stat=[(@speed_stat*m).round,1].max
    else; return false
    end
    true
  end
end

class Scene_Map
  alias pmd_ac_v081_update_encounter update_encounter unless method_defined?(:pmd_ac_v081_update_encounter)
  alias pmd_ac_v081_update_scene_change update_scene_change unless method_defined?(:pmd_ac_v081_update_scene_change)

  def update_scene_change
    if $game_temp.next_scene=='pmd_autochess'
      call_pmd_autochess_v081
      return
    end
    pmd_ac_v081_update_scene_change
  end

  def call_pmd_autochess_v081
    @spriteset.update if @spriteset!=nil
    Graphics.update
    $game_player.straighten if $game_player!=nil
    begin
      $game_temp.map_bgm=RPG::BGM.last
      $game_temp.map_bgs=RPG::BGS.last
      RPG::BGM.stop
      RPG::BGS.stop
      Sound.play_battle_start
      $game_system.battle_bgm.play if $game_system!=nil
    rescue
    end
    $game_temp.next_scene=nil
    $scene=Scene_PMD_AutoChess.new
  end

  def update_encounter
    cfg=PMD_AC.wild_config_for_map_v081($game_map.map_id)
    if cfg==nil
      pmd_ac_v081_update_encounter
      return
    end
    return if $game_player.encounter_count>0
    return if $game_map.interpreter.running?
    return if $game_system.encounter_disabled
    return unless PMD_AC.wild_terrain_valid_v081(cfg)
    mn=(cfg[:min_steps]||10).to_i;mx=(cfg[:max_steps]||18).to_i
    $game_player.make_pmd_encounter_count_v081(mn,mx)
    PMD_AC.start_battle_v081(cfg[:encounter],{:source=>:wild,:deploy=>false})
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v081_start start unless method_defined?(:pmd_ac_v081_start)
  alias pmd_ac_v081_create_units create_units unless method_defined?(:pmd_ac_v081_create_units)
  alias pmd_ac_v081_start_battle start_battle unless method_defined?(:pmd_ac_v081_start_battle)
  alias pmd_ac_v081_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v081_update_deploy_phase)
  alias pmd_ac_v081_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v081_update_battle_input)
  alias pmd_ac_v081_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v081_update_battle_step)
  alias pmd_ac_v081_process_stage_result_v080 process_stage_result_v080 unless method_defined?(:pmd_ac_v081_process_stage_result_v080)
  alias pmd_ac_v081_update_result_phase update_result_phase unless method_defined?(:pmd_ac_v081_update_result_phase)
  alias pmd_ac_v081_show_result show_result unless method_defined?(:pmd_ac_v081_show_result)
  alias pmd_ac_v081_refresh_header refresh_header unless method_defined?(:pmd_ac_v081_refresh_header)
  alias pmd_ac_v081_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v081_prepare_verification_battle)
  alias pmd_ac_v081_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v081_update_verification_script)
  alias pmd_ac_v081_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v081_complete_verification_mode)
  alias pmd_ac_v081_log_event log_event unless method_defined?(:pmd_ac_v081_log_event)
  alias pmd_ac_v081_terminate terminate unless method_defined?(:pmd_ac_v081_terminate)

  def rpg_request_v081
    @rpg_request_v081 || PMD_AC.battle_request_v081
  end

  def rpg_external_battle_v081?
    r=rpg_request_v081
    r!=nil
  end

  def start
    pmd_ac_v081_start
    @rpg_request_v081=PMD_AC.battle_request_v081
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.81 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::RPG_ENCOUNTER_MANIFEST_V081
    log_event(:rpg_encounter,
      'FLOW v0.81 contexts=stage,wild,boss,scripted stage=v0.80 wild_map=1 terrain=1 '+
      'boss_stats=1 boss_phases=1 boss_recruit=off script_call=1 result=win,lose,escape checksum32='+m[:runtime_checksum32].to_s)
    if @rpg_request_v081!=nil
      log_event(:rpg_encounter,'REQUEST key='+@rpg_request_v081[:key].to_s+' kind='+@rpg_request_v081[:kind].to_s+
        ' source='+@rpg_request_v081[:source].to_s+' deploy='+(@rpg_request_v081[:deploy] ? '1':'0')+
        ' escape='+(@rpg_request_v081[:can_escape] ? '1':'0'))
      start_battle unless @rpg_request_v081[:deploy]
    end
    refresh_header
  end

  def create_units
    pmd_ac_v081_create_units
    req=PMD_AC.battle_request_v081
    return if req==nil
    allies=(@units||[]).find_all{|u|u.team==:ally}
    @units=allies
    id=allies.size
    setup=PMD_AC.build_enemy_setup_v081(req)
    setup.each do |row|
      sp=row[0];cx=row[1];cy=row[2];lv=row[3];mods=row[4]||{}
      instance=PMD_PokemonInstance.new(sp,lv)
      unit=Game_PMDChessUnit.new(id,sp,:enemy,cx,cy,instance)
      unit.scene=self
      unit.apply_encounter_mods_v081(mods)
      @units.push(unit);id+=1
    end
    @next_unit_id=id
    @active_stage_id_v080=req[:stage_id] if req[:kind]==:stage
  end

  def start_battle
    pmd_ac_v081_start_battle
    req=rpg_request_v081
    if req!=nil && req[:weather]!=nil && respond_to?(:set_canonical_weather)
      set_canonical_weather(req[:weather],nil,99,true)
      log_event(:rpg_encounter,'ENV weather='+req[:weather].to_s+' permanent=1')
    end
  end

  def update_deploy_phase
    req=rpg_request_v081
    if req!=nil && (Input.trigger?(Input::L) || Input.trigger?(Input::R))
      Sound.play_buzzer
      return
    end
    if req!=nil && Input.trigger?(Input::B) && @selected_unit==nil
      if req[:can_escape]
        Sound.play_cancel
        PMD_AC.record_battle_result_v081(req,:escape)
        log_event(:rpg_encounter,'ESCAPE phase=deploy')
        return_to_map_v081
      else
        Sound.play_buzzer
        log_event(:rpg_encounter,'ESCAPE_BLOCK kind='+req[:kind].to_s+' phase=deploy')
      end
      return
    end
    pmd_ac_v081_update_deploy_phase
  end

  def update_battle_input
    req=rpg_request_v081
    if req!=nil && Input.trigger?(Input::B)
      if req[:can_escape]
        Sound.play_cancel
        PMD_AC.record_battle_result_v081(req,:escape)
        log_event(:rpg_encounter,'ESCAPE phase=battle')
        return_to_map_v081
      else
        Sound.play_buzzer
        log_event(:rpg_encounter,'ESCAPE_BLOCK kind='+req[:kind].to_s+' phase=battle')
      end
      return
    end
    pmd_ac_v081_update_battle_input
  end

  def update_battle_step
    pmd_ac_v081_update_battle_step
    update_boss_phases_v081 if @phase==:battle
  end

  def update_boss_phases_v081
    (@units||[]).each do |u|
      next unless u.team==:enemy && u.boss_v081 && u.alive?
      update_boss_custom_mechanic_v081(u)
      u.boss_phase_rules_v081.each do |rule|
        key=rule[:key] || ('phase_'+rule[:hp_below].to_s).to_sym
        next if u.boss_phase_done_v081?(key)
        rate=u.maxhp.to_i<=0 ? 0.0 : u.hp.to_f/u.maxhp.to_f
        next unless rate <= (rule[:hp_below]||0.0).to_f
        u.mark_boss_phase_v081(key)
        effects=rule[:effects] || []
        effects.each do |ef|
          case ef[0]
          when :shield_rate
            u.add_shield([(u.maxhp.to_f*ef[1].to_f).round,1].max,180,nil,u)
          when :stat_mult
            u.apply_boss_stat_mult_v081(ef[1],ef[2])
          when :energy
            u.gain_energy(ef[1].to_i,u,:boss_phase)
          when :heal_rate
            u.heal([(u.maxhp.to_f*ef[1].to_f).round,1].max)
          when :weather
            set_canonical_weather(ef[1],u,99,true) if respond_to?(:set_canonical_weather)
          end
        end
        log_event(:boss_phase,u.log_name+' PHASE key='+key.to_s+' text='+rule[:text].to_s+
          ' hp_rate='+sprintf('%.3f',rate)+' effects='+effects.collect{|x|x[0].to_s}.join(','))
      end
    end
  end

  # Optional per-boss code hook. Put :mechanic=>:my_boss in the boss mods,
  # then define boss_mechanic_my_boss_v081(unit) in a later script.
  def update_boss_custom_mechanic_v081(unit)
    key=unit.boss_mechanic_v081
    return if key==nil
    meth=('boss_mechanic_'+key.to_s+'_v081').to_sym
    send(meth,unit) if respond_to?(meth)
  end

  def process_stage_result_v080(winner_team)
    req=rpg_request_v081
    if req==nil
      pmd_ac_v081_process_stage_result_v080(winner_team)
      return
    end
    result=winner_team==:ally ? :win : :lose
    if req[:kind]==:stage
      @active_stage_id_v080=req[:stage_id]
      pmd_ac_v081_process_stage_result_v080(winner_team)
      PMD_AC.record_battle_result_v081(req,result)
      return
    end
    enemies=(@units||[]).find_all{|u|u.team==:enemy && u.counts_for_victory?}
    offer=winner_team==:ally ? PMD_AC.recruit_offer_for_request_v081(req,enemies) : nil
    @rpg_reward_v081={:request=>req,:winner=>winner_team,:offer=>offer}
    @stage_reward_v080=nil
    PMD_AC.record_battle_result_v081(req,result)
    log_event(:rpg_encounter,'RESULT key='+req[:key].to_s+' kind='+req[:kind].to_s+' result='+result.to_s+
      ' recruit='+(offer==nil ? 'none' : offer[:species].to_s)+' rate='+(offer==nil ? (req[:recruit_rate]||0).to_s : offer[:chance].to_s))
  end

  def accept_rpg_recruit_v081
    rr=@rpg_reward_v081
    return false if rr==nil || rr[:winner]!=:ally
    offer=rr[:offer]
    return false if offer==nil || offer[:accepted]
    if PMD_AC.first_available_box_v078==nil
      Sound.play_buzzer
      log_event(:rpg_encounter,'RECRUIT_FAIL reason=box_full species='+offer[:species].to_s)
      return false
    end
    inst=PMD_AC.accept_recruit_offer_v080(offer)
    if inst==nil
      Sound.play_buzzer
      return false
    end
    Sound.play_equip
    log_event(:rpg_encounter,'RECRUIT_ACCEPT species='+inst.species_key.to_s+' lv='+inst.level.to_s+
      ' uid='+inst.instance_uid.to_s+' storage='+PMD_AC.storage_count_v078.to_s)
    show_result
    true
  end

  def update_result_phase
    if rpg_external_battle_v081?
      if Input.trigger?(Input::X)
        accept_rpg_recruit_v081
        return
      elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
        Sound.play_decision
        return_to_map_v081
        return
      end
    end
    pmd_ac_v081_update_result_phase
  end

  def return_to_map_v081
    PMD_AC.clear_battle_request_v081
    begin
      $game_temp.map_bgm.play if $game_temp!=nil && $game_temp.map_bgm!=nil
      $game_temp.map_bgs.play if $game_temp!=nil && $game_temp.map_bgs!=nil
    rescue
    end
    $scene=Scene_Map.new
  end

  def show_result
    pmd_ac_v081_show_result
    req=rpg_request_v081
    return if req==nil || req[:kind]==:stage
    return if @result_sprite==nil
    old=@result_sprite.bitmap
    old.dispose if old!=nil && !old.disposed?
    @result_sprite.bitmap=Bitmap.new(PMD_AC::RPG_RESULT_W_V081,PMD_AC::RPG_RESULT_H_V081)
    @result_sprite.x=(Graphics.width-PMD_AC::RPG_RESULT_W_V081)/2
    @result_sprite.y=(Graphics.height-PMD_AC::RPG_RESULT_H_V081)/2-2
    @result_sprite.z=9999
    record=@battle_record_after_v079 || PMD_AC.battle_loop_state_v079
    attention=progression_attention_total_v077
    rr=@rpg_reward_v081 || {:request=>req,:winner=>nil,:offer=>nil}
    PMD_AC.draw_rpg_result_v081(@result_sprite.bitmap,@result_text,
      @battle_reward_rows_v079||[],record,attention,rr)
  end

  def refresh_header
    req=rpg_request_v081
    if req==nil
      pmd_ac_v081_refresh_header
      return if @header_sprite==nil
      bmp=@header_sprite.bitmap
      # repaint only title version, keeping v0.80 stage behavior text
      bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
      pmd_ac_v074_font(bmp)
      bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
      bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.81',1)
      return
    end
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap;bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.81',1)
    bmp.font.size=14;bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
    ctx=PMD_AC.context_label_v081(req[:kind])+'｜'+req[:name].to_s
    if @phase==:deploy
      text=ctx+'｜A BOX｜D 成長｜Shift 開戰'+(req[:can_escape] ? '｜B 返回地圖' : '｜不可逃跑')
    elsif @phase==:battle
      text=ctx+'｜速度 x'+@battle_speed.to_s+(req[:can_escape] ? '｜B 逃離' : '｜BOSS 不可逃跑')
    else
      text=ctx+'｜C 返回地圖｜A 招募候選'
    end
    bmp.draw_text(8,32,Graphics.width-16,23,text,1)
  end

  def rpg_encounter_v081?; verification_mode==:rpg_encounter_v081; end

  def prepare_verification_battle
    pmd_ac_v081_prepare_verification_battle
    @rpg_v081_failed=false if rpg_encounter_v081?
  end

  def log_event(category,message)
    if category.to_s=='verify' && rpg_encounter_v081? && message.to_s.index('RPG_')==0 && message.to_s.include?(' pass=0')
      @rpg_v081_failed=true
    end
    pmd_ac_v081_log_event(category,message)
  end

  def log_verify_v081(name,pass,detail='')
    @rpg_v081_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_rpg_manifest_v081
    return if @verification_done[:v081_manifest]
    e=PMD_AC.rpg_encounter_manifest_errors_v081
    pass=e.empty? && PMD_AC::RPG_ENCOUNTER_MANIFEST_V081[:contexts].size==4
    log_verify_v081('RPG_ENCOUNTER_MANIFEST_V081',pass,'contexts=stage,wild,boss,scripted errors=['+e.join(',')+']')
    @verification_done[:v081_manifest]=true
  end

  def verify_rpg_stage_bridge_v081
    return if @verification_done[:v081_stage]
    r=PMD_AC.stage_request_v081(2)
    pass=r!=nil && r[:kind]==:stage && r[:stage_id]==2 && r[:enemy_setup].size==3 && r[:recruitable]
    log_verify_v081('RPG_STAGE_BRIDGE_V081',pass,'stage=2 enemy_slots='+(r==nil ? '0':r[:enemy_setup].size.to_s)+' stage_runtime=v0.80')
    @verification_done[:v081_stage]=true
  end

  def verify_rpg_wild_v081
    return if @verification_done[:v081_wild]
    r=PMD_AC.make_battle_request_v081(:forest_wild,{:source=>:wild})
    setup=PMD_AC.build_enemy_setup_v081(r,[0,40,90])
    sp=setup.collect{|x|x[0]}
    PMD_AC.wild_on_v081(:forest_wild,7,11,[1,2],999)
    cfg=PMD_AC.wild_config_for_map_v081(999)
    PMD_AC.wild_off_v081(999)
    pass=sp==[:caterpie,:rattata,:pikachu] && cfg!=nil && cfg[:min_steps]==7 && cfg[:max_steps]==11 && cfg[:terrain_tags]==[1,2]
    log_verify_v081('RPG_WILD_ENCOUNTER_V081',pass,'weighted='+sp.join(',')+' steps=7..11 terrain=1,2 runtime_map=1')
    @verification_done[:v081_wild]=true
  end

  def verify_rpg_boss_v081
    return if @verification_done[:v081_boss]
    r=PMD_AC.make_battle_request_v081(:boss_beedrill)
    setup=PMD_AC.build_enemy_setup_v081(r)
    row=setup[1];mods=row==nil ? {} : (row[4]||{})
    inst=PMD_PokemonInstance.new(:beedrill,18)
    u=Game_PMDChessUnit.new(98,:beedrill,:enemy,5,2,inst);u.scene=self
    before=u.maxhp;u.apply_encounter_mods_v081(mods);after=u.maxhp
    pass=r!=nil && r[:kind]==:boss && !r[:recruitable] && !r[:can_escape] && mods[:phases].size==2 && after>before*2
    log_verify_v081('RPG_BOSS_PROFILE_V081',pass,'recruit=0 escape=0 hp='+before.to_s+'->'+after.to_s+' phases='+(mods[:phases]||[]).size.to_s+' custom_moves=1')
    @verification_done[:v081_boss]=true
  end

  def verify_rpg_script_result_v081
    return if @verification_done[:v081_script]
    old=PMD_AC.battle_result_state_v081
    r=PMD_AC.make_battle_request_v081(:roadside_pikachu)
    setup=PMD_AC.build_enemy_setup_v081(r)
    PMD_AC.record_battle_result_v081(r,:win)
    pass=setup.size==1 && setup[0][0]==:pikachu && PMD_AC.battle_won_v081?
    $game_system.pmd_autochess_last_result_v081=old if $game_system!=nil
    log_verify_v081('RPG_SCRIPT_CALL_V081',pass,'battle=:roadside_pikachu enemy=pikachu result_bridge=win,lose,escape')
    @verification_done[:v081_script]=true
  end

  def verify_rpg_recruit_policy_v081
    return if @verification_done[:v081_recruit]
    w=PMD_AC.make_battle_request_v081(:forest_wild)
    b=PMD_AC.make_battle_request_v081(:boss_beedrill)
    wo=PMD_AC.recruit_offer_for_request_v081(w,nil,0,0)
    bo=PMD_AC.recruit_offer_for_request_v081(b,nil,0,0)
    pass=wo!=nil && bo==nil && wo[:chance]==30
    log_verify_v081('RPG_RECRUIT_POLICY_V081',pass,'wild_rate=30 boss_offer=nil boss_never_recruit=1')
    @verification_done[:v081_recruit]=true
  end

  def verify_rpg_carry_v081
    return if @verification_done[:v081_carry]
    pass=PMD_AC::STAGE_DB_V080.size==3 && PMD_AC::PARTY_CAPACITY_V045==3 && PMD_AC::STORAGE_BOX_COUNT_V045==24
    log_verify_v081('RPG_ENCOUNTER_CARRY_V081',pass,'stage=v0.80 reward=v0.79 party=v0.78 progression=v0.77.1 stats=v0.76 balance=v0.75 weather=v0.28 field=v0.35-v0.37')
    @verification_done[:v081_carry]=true
  end

  def update_verification_script
    unless rpg_encounter_v081?
      pmd_ac_v081_update_verification_script
      return
    end
    @verification_frame+=1;f=@verification_frame
    verify_rpg_manifest_v081 if f>=2
    verify_rpg_stage_bridge_v081 if f>=4
    verify_rpg_wild_v081 if f>=6
    verify_rpg_boss_v081 if f>=8
    verify_rpg_script_result_v081 if f>=10
    verify_rpg_recruit_policy_v081 if f>=12
    verify_rpg_carry_v081 if f>=14
    if f>=16 && !@verification_done[:v081_final]
      pass=!@rpg_v081_failed
      log_verify_v081('RPG_ENCOUNTER_V081',pass,'manifest=1 stage=1 wild=1 boss=1 script=1 recruit=1 carry=1')
      @verification_done[:v081_final]=true
    end
    complete_verification_mode if f>=PMD_AC::RPG_ENCOUNTER_VERIFY_END_V081
  end

  def complete_verification_mode
    pmd_ac_v081_complete_verification_mode
  end

  def terminate
    pmd_ac_v081_terminate
  end
end
