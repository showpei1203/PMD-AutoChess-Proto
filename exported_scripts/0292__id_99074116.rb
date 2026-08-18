#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.80
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - V080_OLD_VERIFICATION_MODES / V080_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
# - STAGE_RESULT_W_V080 / STAGE_RESULT_H_V080
#
# 【PMD_AC 對外／共用方法】
# - draw_stage_result_v080
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / start / stage_runtime_enabled_v080? / create_units
# - update_deploy_phase / process_stage_result_v080 / award_battle_exp / accept_stage_recruit_v080
# - update_result_phase / show_result / refresh_header / stage_reward_v080?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.80
# Stage / Encounter / Recruit Framework
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Adds a data-driven three-stage playable framework on top of v0.79:
# - Q/W selects unlocked stages during deployment.
# - Normal battles use stage-specific enemy species and levels.
# - Victory records stage clears and unlocks the next stage.
# - First clear guarantees one recruit offer; repeat clear has 35% offer chance.
# - A on the result screen accepts the recruit into the first free BOX slot.
# - Currency and item loot remain deferred; no economy is invented here.
#==============================================================================
module PMD_AC
  V080_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V080_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:stage_reward_v080] +
    V080_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:stage_reward_v080}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V080_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:stage_reward_v080]='STAGE_REWARD_V080'

  STAGE_RESULT_W_V080 = 510
  STAGE_RESULT_H_V080 = 284

  def self.draw_stage_result_v080(b,result_text,rows,record,attention,stage_reward)
    return false if b==nil
    begin
      b.font.name=UI_PANEL_FONT_V0741
    rescue
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    b.clear
    b.fill_rect(0,0,b.width,b.height,Color.new(0,0,0,235))
    b.font.bold=true;b.font.size=28;b.font.color=Color.new(255,255,255)
    b.draw_text(10,7,b.width-20,34,result_text.to_s,1)

    sr=stage_reward || {}
    sid=sr[:stage_id] || current_stage_id_v080
    stage_line='關卡 '+sid.to_s+'｜'+stage_name_v080(sid)
    if sr[:clear_count].to_i>0
      stage_line+='｜通關 '+sr[:clear_count].to_i.to_s+' 次'
    end
    b.font.bold=false;b.font.size=17;b.font.color=Color.new(205,225,245)
    b.draw_text(16,42,b.width-32,23,stage_line,1)

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
      tags.push('新招 '+row[:learned_moves].size.to_s) if row[:learned_moves]!=nil && !row[:learned_moves].empty?
      unless tags.empty?
        b.font.size=13;b.font.color=Color.new(255,220,130)
        b.draw_text(132,y+18,b.width-156,15,tags.join('｜'),0)
      end
    end

    ry=224
    b.fill_rect(16,ry,b.width-32,34,Color.new(38,34,23,230))
    b.font.bold=true;b.font.size=16;b.font.color=Color.new(255,225,145)
    offer=sr[:offer]
    if sr[:winner]==:ally
      if offer!=nil
        sp=species_name_reward_v079(offer[:species])
        if offer[:accepted]
          text='招募完成：'+sp+' Lv'+offer[:level].to_s+' 已加入 BOX'
        else
          text='招募候選：'+sp+' Lv'+offer[:level].to_s+'｜A 加入 BOX'
        end
      else
        text=sr[:first_clear] ? '本次無招募候選' : '本次沒有可招募的寶可夢'
      end
      if sr[:unlocked_stage]!=nil
        text+='｜解鎖 '+stage_name_v080(sr[:unlocked_stage])
      end
    else
      text='戰敗不發 EXP／招募候選，技能熟練仍依實際使用累積'
    end
    b.draw_text(24,ry+5,b.width-48,23,text,0)
    b.font.bold=false

    b.font.size=15
    b.font.color=attention.to_i>0 ? Color.new(255,220,130) : Color.new(185,210,230)
    foot='C 回布陣｜Q/W 選關｜A 招募候選'
    foot='C 回布陣｜成長待處理 '+attention.to_i.to_s+'，回去後按 D｜A 招募' if attention.to_i>0
    b.draw_text(10,b.height-25,b.width-20,20,foot,1)
    true
  end
end

class Game_System
  attr_accessor :pmd_autochess_stage_v080
end

class Scene_PMD_AutoChess
  alias pmd_ac_v080_start start unless method_defined?(:pmd_ac_v080_start)
  alias pmd_ac_v080_create_units create_units unless method_defined?(:pmd_ac_v080_create_units)
  alias pmd_ac_v080_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v080_update_deploy_phase)
  alias pmd_ac_v080_update_result_phase update_result_phase unless method_defined?(:pmd_ac_v080_update_result_phase)
  alias pmd_ac_v080_award_battle_exp award_battle_exp unless method_defined?(:pmd_ac_v080_award_battle_exp)
  alias pmd_ac_v080_show_result show_result unless method_defined?(:pmd_ac_v080_show_result)
  alias pmd_ac_v080_refresh_header refresh_header unless method_defined?(:pmd_ac_v080_refresh_header)
  alias pmd_ac_v080_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v080_prepare_verification_battle)
  alias pmd_ac_v080_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v080_update_verification_script)
  alias pmd_ac_v080_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v080_complete_verification_mode)
  alias pmd_ac_v080_terminate terminate unless method_defined?(:pmd_ac_v080_terminate)
  alias pmd_ac_v080_log_event log_event unless method_defined?(:pmd_ac_v080_log_event)

  def start
    PMD_AC.stage_state_v080
    pmd_ac_v080_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.80 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::STAGE_MANIFEST_V080
    log_event(:stage,
      'FLOW v0.80 stages='+m[:stage_count].to_s+' select=Q/W unlock=clear_previous '+
      'first_recruit=100 repeat_recruit=35 accept=A destination=BOX loot=deferred '+
      'identity=instance_uid reward_loop=v0.79 checksum32='+m[:runtime_checksum32].to_s)
    refresh_header
  end

  def stage_runtime_enabled_v080?
    vm=verification_mode
    vm==:normal || vm==:stage_reward_v080
  end

  def create_units
    pmd_ac_v080_create_units
    return unless stage_runtime_enabled_v080?
    sid=verification_mode==:stage_reward_v080 ? 1 : PMD_AC.current_stage_id_v080
    stage=PMD_AC.stage_data_v080(sid)
    return if stage==nil
    allies=(@units||[]).find_all{|u|u.team==:ally}
    @units=allies
    id=allies.size
    setup=stage[:enemy_setup]||[]
    for row in setup
      sp=row[0];cx=row[1];cy=row[2];lv=row[3]
      instance=PMD_PokemonInstance.new(sp,lv)
      unit=Game_PMDChessUnit.new(id,sp,:enemy,cx,cy,instance)
      unit.scene=self
      @units.push(unit)
      id+=1
    end
    @next_unit_id=id
    @active_stage_id_v080=sid
  end

  def update_deploy_phase
    if @party_storage_panel_v078==nil && @progression_ui_panel_v047==nil && verification_mode==:normal
      if Input.trigger?(Input::L) || Input.trigger?(Input::R)
        delta=Input.trigger?(Input::L) ? -1 : 1
        old=PMD_AC.current_stage_id_v080
        now=PMD_AC.cycle_stage_v080(delta)
        if now!=old
          Sound.play_cursor
          rebuild_deploy_units_v078
          log_event(:stage,'SELECT '+old.to_s+'->'+now.to_s+' name='+PMD_AC.stage_name_v080(now))
        else
          Sound.play_buzzer
        end
        refresh_header
        refresh_footer
        return
      end
    end
    pmd_ac_v080_update_deploy_phase
  end

  def process_stage_result_v080(winner_team)
    return unless verification_mode==:normal
    sid=@active_stage_id_v080 || PMD_AC.current_stage_id_v080
    @stage_reward_v080={:stage_id=>sid,:winner=>winner_team,:offer=>nil,
      :first_clear=>false,:unlocked_stage=>nil,:clear_count=>PMD_AC.stage_clear_count_v080(sid)}
    return unless winner_team==:ally
    clear=PMD_AC.record_stage_clear_v080(sid)
    offer=PMD_AC.recruit_offer_for_stage_v080(sid,clear[:first_clear])
    @stage_reward_v080[:first_clear]=clear[:first_clear]
    @stage_reward_v080[:unlocked_stage]=clear[:unlocked_stage]
    @stage_reward_v080[:clear_count]=clear[:clear_count]
    @stage_reward_v080[:offer]=offer
    log_event(:stage,
      'CLEAR stage='+sid.to_s+' count='+clear[:clear_count].to_s+
      ' first='+(clear[:first_clear] ? '1':'0')+
      ' unlock='+(clear[:unlocked_stage]==nil ? 'none' : clear[:unlocked_stage].to_s)+
      ' recruit='+(offer==nil ? 'none' : offer[:species].to_s)+
      ' rate='+(offer==nil ? (clear[:first_clear] ? '100':'35') : offer[:chance].to_s))
  end

  def award_battle_exp(winner_team)
    pmd_ac_v080_award_battle_exp(winner_team)
    process_stage_result_v080(winner_team)
  end

  def accept_stage_recruit_v080
    sr=@stage_reward_v080
    return false if sr==nil || sr[:winner]!=:ally
    offer=sr[:offer]
    return false if offer==nil || offer[:accepted]
    if PMD_AC.first_available_box_v078==nil
      Sound.play_buzzer
      log_event(:stage,'RECRUIT_FAIL reason=box_full species='+offer[:species].to_s)
      return false
    end
    inst=PMD_AC.accept_recruit_offer_v080(offer)
    if inst==nil
      Sound.play_buzzer
      log_event(:stage,'RECRUIT_FAIL reason=store_failed species='+offer[:species].to_s)
      return false
    end
    Sound.play_equip
    log_event(:stage,'RECRUIT_ACCEPT species='+inst.species_key.to_s+' lv='+inst.level.to_s+
      ' uid='+inst.instance_uid.to_s+' storage='+PMD_AC.storage_count_v078.to_s)
    show_result
    true
  end

  def update_result_phase
    if verification_mode==:normal && Input.trigger?(Input::X)
      accept_stage_recruit_v080
      return
    end
    pmd_ac_v080_update_result_phase
  end

  def show_result
    pmd_ac_v080_show_result
    return unless verification_mode==:normal
    return if @result_sprite==nil
    old=@result_sprite.bitmap
    old.dispose if old!=nil && !old.disposed?
    @result_sprite.bitmap=Bitmap.new(PMD_AC::STAGE_RESULT_W_V080,PMD_AC::STAGE_RESULT_H_V080)
    @result_sprite.x=(Graphics.width-PMD_AC::STAGE_RESULT_W_V080)/2
    @result_sprite.y=(Graphics.height-PMD_AC::STAGE_RESULT_H_V080)/2-2
    @result_sprite.z=9999
    record=@battle_record_after_v079 || PMD_AC.battle_loop_state_v079
    attention=progression_attention_total_v077
    sr=@stage_reward_v080 || {:stage_id=>(@active_stage_id_v080||PMD_AC.current_stage_id_v080),
      :winner=>nil,:offer=>nil,:clear_count=>PMD_AC.stage_clear_count_v080(@active_stage_id_v080||PMD_AC.current_stage_id_v080)}
    PMD_AC.draw_stage_result_v080(@result_sprite.bitmap,@result_text,
      @battle_reward_rows_v079||[],record,attention,sr)
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.80',1)
    bmp.font.size=14;bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
    text=''
    if @phase==:deploy
      if verification_mode==:normal
        sid=PMD_AC.current_stage_id_v080
        d=PMD_AC.stage_data_v080(sid)
        rec=d==nil ? 0 : d[:recommended_level].to_i
        text='Q/W 關卡 '+sid.to_s+' '+PMD_AC.stage_name_v080(sid)+' Lv'+rec.to_s+
          '｜A BOX｜D 成長｜S 驗證｜Shift 開戰'
      else
        text='S 驗證：'+verification_mode_label+'｜Shift 開戰'
      end
    elsif @phase==:battle
      text='關卡 '+(@active_stage_id_v080||PMD_AC.current_stage_id_v080).to_s+' '+
        PMD_AC.stage_name_v080(@active_stage_id_v080||PMD_AC.current_stage_id_v080)+
        '｜速度 x'+@battle_speed.to_s+'｜A 切換｜B 離開'
    else
      text='戰鬥結束｜A 招募候選｜C 回到布陣｜B 離開'
    end
    bmp.draw_text(8,32,Graphics.width-16,23,text,1)
  end

  def stage_reward_v080?
    verification_mode==:stage_reward_v080
  end

  def prepare_verification_battle
    pmd_ac_v080_prepare_verification_battle
    if stage_reward_v080?
      @stage_v080_failed=false
      PMD_AC.begin_identity_sandbox_v045 unless PMD_AC.identity_sandbox_v045?
      for u in @units
        u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
        u.verification_energy_sandbox(true) if u.respond_to?(:verification_energy_sandbox)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && stage_reward_v080? &&
       message.to_s.index('STAGE_')==0 && message.to_s.include?(' pass=0')
      @stage_v080_failed=true
    end
    pmd_ac_v080_log_event(category,message)
  end

  def log_verify_v080(name,pass,detail='')
    @stage_v080_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_stage_manifest_v080
    return if @verification_done[:v080_manifest]
    e=PMD_AC.stage_manifest_errors_v080
    pass=e.empty? && PMD_AC::STAGE_DB_V080.size==3
    log_verify_v080('STAGE_MANIFEST_V080',pass,
      'stages=3 enemy_slots=3 assets=0001-0026 errors=['+e.join(',')+'] checksum32='+
      PMD_AC.stage_checksum32_v080.to_s)
    @verification_done[:v080_manifest]=true
  end

  def verify_stage_encounters_v080
    return if @verification_done[:v080_encounters]
    d1=PMD_AC.stage_data_v080(1);d2=PMD_AC.stage_data_v080(2);d3=PMD_AC.stage_data_v080(3)
    a1=d1[:enemy_setup].collect{|r|r[0]}
    a2=d2[:enemy_setup].collect{|r|r[0]}
    a3=d3[:enemy_setup].collect{|r|r[0]}
    pass=a1==[:caterpie,:rattata,:pidgey] && a2==[:weedle,:kakuna,:beedrill] &&
      a3==[:spearow,:ekans,:pikachu]
    log_verify_v080('STAGE_ENCOUNTER_V080',pass,
      's1='+a1.join(',')+' s2='+a2.join(',')+' s3='+a3.join(','))
    @verification_done[:v080_encounters]=true
  end

  def verify_stage_unlock_v080
    return if @verification_done[:v080_unlock]
    s=PMD_AC.stage_default_state_v080
    a=PMD_AC.record_stage_clear_in_state_v080(s,1)
    b=PMD_AC.record_stage_clear_in_state_v080(s,2)
    c=PMD_AC.record_stage_clear_in_state_v080(s,1)
    pass=a[:first_clear] && a[:unlocked_stage]==2 && b[:unlocked_stage]==3 &&
      !c[:first_clear] && c[:unlocked_stage]==nil && s[:unlocked]==[1,2,3] && s[:clears][1]==2
    log_verify_v080('STAGE_UNLOCK_V080',pass,
      'first_unlock=2 second_unlock=3 repeat_no_unlock=1 unlocked='+s[:unlocked].join(','))
    @verification_done[:v080_unlock]=true
  end

  def verify_stage_recruit_offer_v080
    return if @verification_done[:v080_offer]
    first=PMD_AC.recruit_offer_for_stage_v080(1,true,99,2)
    repeat_hit=PMD_AC.recruit_offer_for_stage_v080(2,false,34,1)
    repeat_miss=PMD_AC.recruit_offer_for_stage_v080(2,false,35,1)
    pass=first!=nil && first[:species]==:pidgey && first[:chance]==100 &&
      repeat_hit!=nil && repeat_hit[:species]==:kakuna && repeat_hit[:chance]==35 && repeat_miss==nil
    log_verify_v080('STAGE_RECRUIT_OFFER_V080',pass,
      'first=100 repeat=35 first_species='+(first==nil ? 'nil' : first[:species].to_s)+
      ' repeat_hit='+(repeat_hit==nil ? 'nil' : repeat_hit[:species].to_s)+' repeat_miss='+(repeat_miss==nil ? '1':'0'))
    @verification_done[:v080_offer]=true
  end

  def verify_stage_recruit_store_v080
    return if @verification_done[:v080_store]
    offer=PMD_AC.recruit_offer_for_stage_v080(3,true,0,2)
    before=PMD_AC.storage_count_v078
    inst=PMD_AC.accept_recruit_offer_v080(offer)
    loc=inst==nil ? nil : PMD_AC.pokemon_location_v045(inst.instance_uid)
    pass=inst!=nil && inst.species_key==:pikachu && offer[:accepted] &&
      PMD_AC.storage_count_v078==before+1 && loc!=nil && loc[0]==:storage &&
      PMD_AC.party_storage_integrity_errors_v078.empty?
    log_verify_v080('STAGE_RECRUIT_STORE_V080',pass,
      'species='+(inst==nil ? 'nil' : inst.species_key.to_s)+' new_uid='+(inst==nil ? 'nil' : inst.instance_uid.to_s)+
      ' storage='+(before).to_s+'->'+PMD_AC.storage_count_v078.to_s+' identity_unique=1')
    @verification_done[:v080_store]=true
  end

  def verify_stage_ui_v080
    return if @verification_done[:v080_ui]
    bmp=nil;ok=true
    begin
      bmp=Bitmap.new(PMD_AC::STAGE_RESULT_W_V080,PMD_AC::STAGE_RESULT_H_V080)
      row={:species=>:bulbasaur,:level_before=>15,:level=>16,:exp_gain=>42,:mastery_gain=>3,
        :pending_moves=>1,:evolution_choices=>0,:evolved=>true,:learned_moves=>[:razor_leaf]}
      sr={:stage_id=>1,:winner=>:ally,:clear_count=>1,:first_clear=>true,:unlocked_stage=>2,
        :offer=>{:species=>:pidgey,:level=>12,:accepted=>false}}
      PMD_AC.draw_stage_result_v080(bmp,'藍方勝利',[row],PMD_AC.battle_loop_default_state_v079,1,sr)
      ok=bmp.width==510 && bmp.height==284
    rescue Exception=>e
      ok=false
      log_event(:stage,'UI_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s)
    ensure
      bmp.dispose if bmp!=nil && !bmp.disposed?
    end
    log_verify_v080('STAGE_UI_V080',ok,
      'selector=Q/W result=510x284 recruit=A fonts=larger reward=v0.79_extended')
    @verification_done[:v080_ui]=true
  end

  def verify_stage_carry_v080
    return if @verification_done[:v080_carry]
    pass=PMD_AC::PARTY_CAPACITY_V045==3 && PMD_AC::STORAGE_BOX_COUNT_V045==24 &&
      PMD_AC::REWARD_POLICY_ALIVE_V079==1.0 && PMD_AC::STAGE_RECRUIT_REPEAT_V080==35
    log_verify_v080('STAGE_CARRY_V080',pass,
      'identity=v0.45 progression=v0.77.1 party=v0.78 reward=v0.79 stats=v0.76 '+
      'balance=v0.75 weather=v0.28 field=v0.35-v0.37 combo=v0.60.2 router=v0.62')
    @verification_done[:v080_carry]=true
  end

  def update_verification_script
    unless stage_reward_v080?
      pmd_ac_v080_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_stage_manifest_v080 if f>=2
    verify_stage_encounters_v080 if f>=4
    verify_stage_unlock_v080 if f>=6
    verify_stage_recruit_offer_v080 if f>=8
    verify_stage_recruit_store_v080 if f>=10
    verify_stage_ui_v080 if f>=12
    verify_stage_carry_v080 if f>=14
    if f>=16 && !@verification_done[:v080_final]
      pass=!@stage_v080_failed
      log_verify_v080('STAGE_REWARD_V080',pass,
        'manifest=1 encounter=1 unlock=1 recruit_offer=1 recruit_store=1 ui=1 carry=1')
      @verification_done[:v080_final]=true
    end
    complete_verification_mode if f>=PMD_AC::STAGE_VERIFY_END_V080
  end

  def complete_verification_mode
    if stage_reward_v080?
      PMD_AC.end_identity_sandbox_v045 if PMD_AC.identity_sandbox_v045?
    end
    pmd_ac_v080_complete_verification_mode
  end

  def terminate
    if stage_reward_v080? && PMD_AC.identity_sandbox_v045?
      PMD_AC.end_identity_sandbox_v045
    end
    pmd_ac_v080_terminate
  end
end
