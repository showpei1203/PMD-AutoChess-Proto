#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.79
# 分類：戰後成長／Reward Loop
#
# 【用途／機制】
# 整理戰後 EXP、技能熟練、成長提醒與戰績。
#
# 【怎麼調整】
# 若要改 EXP 分配比例，請優先找 REWARD_POLICY_* 或 v0.46 的 PROGRESSION_EXP_* 常數。
#
# 【本腳本主要設定常數／資料表】
# - V079_OLD_VERIFICATION_MODES / V079_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
# - REWARD_RESULT_W_V079 / REWARD_RESULT_H_V079 / REWARD_RESULT_ROWS_V079 / REWARD_POLICY_ALIVE_V079
# - REWARD_POLICY_FAINTED_V079 / REWARD_POLICY_RESERVE_V079 / PARTY_STORAGE_TITLE_FONT_V079 / PARTY_STORAGE_BOX_META_FONT_V079
# - PARTY_STORAGE_SECTION_FONT_V079 / PARTY_CARD_NAME_FONT_V079 / PARTY_CARD_LEVEL_FONT_V079 / PARTY_CARD_MOVES_FONT_V079
# - PARTY_CARD_MARK_FONT_V079 / BOX_ROW_FONT_V079 / PARTY_STORAGE_HINT_FONT_V079 / PARTY_STORAGE_FOOTER_FONT_V079
# - PARTY_STORAGE_BOX_ROW_H_V079 / PARTY_STORAGE_VISIBLE_ROWS_V079
#
# 【PMD_AC 對外／共用方法】
# - reward_loop_checksum32_v079 / battle_loop_default_state_v079 / battle_loop_state_v079 / record_battle_result_in_state_v079
# - record_battle_result_v079 / progress_snapshot_for_instance_v079 / reward_row_from_snapshots_v079 / species_name_reward_v079
# - draw_reward_result_v079
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / ensure_box_scroll_v078 / draw_party_card_v078 / draw_box_row_v078
# - refresh / start / capture_battle_progress_v079 / start_battle
# - award_battle_exp / show_result / refresh_header / reward_loop_v079?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.79
# Battle Reward Loop + Party/BOX Readability II
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Formalizes the first playable RPG loop:
# Formation -> Battle -> EXP/Mastery -> Growth attention -> Formation.
# No item drops, currency, capture rewards or economy are introduced here.
#==============================================================================
module PMD_AC
  V079_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V079_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:reward_loop_v079] +
    V079_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:reward_loop_v079}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V079_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:reward_loop_v079]='REWARD_LOOP_V079'

  REWARD_RESULT_W_V079 = 500
  REWARD_RESULT_H_V079 = 230
  REWARD_RESULT_ROWS_V079 = 3
  REWARD_POLICY_ALIVE_V079 = PROGRESSION_EXP_ALIVE_RATE_V046
  REWARD_POLICY_FAINTED_V079 = PROGRESSION_EXP_FAINTED_RATE_V046
  REWARD_POLICY_RESERVE_V079 = PROGRESSION_EXP_RESERVE_RATE_V046

  # Party / BOX readability pass II.
  PARTY_STORAGE_TITLE_FONT_V079 = 26
  PARTY_STORAGE_BOX_META_FONT_V079 = 15
  PARTY_STORAGE_SECTION_FONT_V079 = 19
  PARTY_CARD_NAME_FONT_V079 = 19
  PARTY_CARD_LEVEL_FONT_V079 = 15
  PARTY_CARD_MOVES_FONT_V079 = 13
  PARTY_CARD_MARK_FONT_V079 = 13
  BOX_ROW_FONT_V079 = 17
  PARTY_STORAGE_HINT_FONT_V079 = 15
  PARTY_STORAGE_FOOTER_FONT_V079 = 14
  PARTY_STORAGE_BOX_ROW_H_V079 = 36
  PARTY_STORAGE_VISIBLE_ROWS_V079 = 7

  def self.reward_loop_checksum32_v079
    s='reward_loop_v079|deployed_exp|alive1.00|fainted0.50|reserve0|'+
      'mastery_summary|level_summary|pending_move|branch_evolution|'+
      'record_wins_losses_streak|party_storage_font2'
    v=0
    s.each_byte{|b|v=((v*131)+b)&0x7fffffff}
    v
  end

  def self.battle_loop_default_state_v079
    {:battles=>0,:wins=>0,:losses=>0,:streak=>0,:best_streak=>0}
  end

  def self.battle_loop_state_v079
    if $game_system!=nil && $game_system.respond_to?(:pmd_autochess_loop_v079)
      h=$game_system.pmd_autochess_loop_v079
      if h==nil
        h=battle_loop_default_state_v079
        $game_system.pmd_autochess_loop_v079=h
      end
      return h
    end
    @battle_loop_fallback_v079=battle_loop_default_state_v079 if @battle_loop_fallback_v079==nil
    @battle_loop_fallback_v079
  end

  def self.record_battle_result_in_state_v079(state,winner_team)
    state=battle_loop_default_state_v079 if state==nil
    state[:battles]=state[:battles].to_i+1
    if winner_team==:ally
      state[:wins]=state[:wins].to_i+1
      state[:streak]=state[:streak].to_i+1
      state[:best_streak]=[state[:best_streak].to_i,state[:streak].to_i].max
    else
      state[:losses]=state[:losses].to_i+1
      state[:streak]=0
    end
    state
  end

  def self.record_battle_result_v079(winner_team)
    record_battle_result_in_state_v079(battle_loop_state_v079,winner_team)
  end

  def self.progress_snapshot_for_instance_v079(i)
    return nil if i==nil
    known=i.respond_to?(:known_moves_v045) ? i.known_moves_v045 : []
    mastery={}
    for mv in known
      mastery[mv]=i.move_mastery_exp_v045(mv) if i.respond_to?(:move_mastery_exp_v045)
    end
    attention={:pending_moves=>0,:evolution_choices=>0}
    if i.respond_to?(:progression_attention_v077)
      a=i.progression_attention_v077
      attention[:pending_moves]=a[:pending_moves].to_i
      attention[:evolution_choices]=a[:evolution_choices].to_i
    end
    {:uid=>i.instance_uid.to_i,:species=>i.species_key,:level=>i.level.to_i,
     :exp=>i.exp.to_i,:known=>known,:mastery=>mastery,
     :pending_moves=>attention[:pending_moves],
     :evolution_choices=>attention[:evolution_choices]}
  end

  def self.reward_row_from_snapshots_v079(before,after)
    return nil if after==nil
    before={} if before==nil
    bm=before[:mastery] || {}
    am=after[:mastery] || {}
    mg=0
    am.keys.each do |mv|
      d=am[mv].to_i-(bm[mv]||0).to_i
      mg+=d if d>0
    end
    bk=before[:known] || []
    ak=after[:known] || []
    learned=ak.find_all{|mv|!bk.include?(mv)}
    {:uid=>after[:uid],:species_before=>before[:species],:species=>after[:species],
     :level_before=>(before[:level]||after[:level]).to_i,:level=>after[:level].to_i,
     :exp_gain=>[after[:exp].to_i-(before[:exp]||after[:exp]).to_i,0].max,
     :mastery_gain=>mg,:learned_moves=>learned,
     :pending_moves=>after[:pending_moves].to_i,
     :evolution_choices=>after[:evolution_choices].to_i,
     :evolved=>(before[:species]!=nil && before[:species]!=after[:species])}
  end

  def self.species_name_reward_v079(key)
    begin
      species_display_name_v047(key)
    rescue
      key.to_s
    end
  end

  def self.draw_reward_result_v079(b,result_text,rows,record,attention)
    return false if b==nil
    begin
      b.font.name=UI_PANEL_FONT_V0741
    rescue
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    b.clear
    b.fill_rect(0,0,b.width,b.height,Color.new(0,0,0,232))
    b.font.bold=true;b.font.size=26;b.font.color=Color.new(255,255,255)
    b.draw_text(10,8,b.width-20,32,result_text.to_s,1)
    r=record || battle_loop_default_state_v079
    b.font.bold=false;b.font.size=14;b.font.color=Color.new(180,205,230)
    rec='戰績 '+r[:wins].to_i.to_s+'勝 '+r[:losses].to_i.to_s+'敗｜連勝 '+r[:streak].to_i.to_s+
      '｜最高 '+r[:best_streak].to_i.to_s
    b.draw_text(16,41,b.width-32,22,rec,1)
    b.font.bold=true;b.font.size=16;b.font.color=Color.new(235,240,245)
    b.draw_text(18,65,b.width-36,22,'戰後成長',0)
    b.font.bold=false
    rows=rows || []
    for idx in 0...REWARD_RESULT_ROWS_V079
      row=rows[idx]
      y=87+idx*36
      b.fill_rect(16,y,b.width-32,33,Color.new(24,32,43,225))
      next if row==nil
      name=species_name_reward_v079(row[:species])
      b.font.size=15;b.font.bold=true;b.font.color=Color.new(245,245,245)
      b.draw_text(24,y+2,106,19,name,0)
      b.font.bold=false;b.font.size=14;b.font.color=Color.new(190,215,235)
      lv='Lv'+row[:level_before].to_s
      lv+='→'+row[:level].to_s if row[:level]>row[:level_before]
      b.draw_text(130,y+2,90,19,lv,0)
      b.draw_text(220,y+2,98,19,'EXP +'+row[:exp_gain].to_s,0)
      b.draw_text(318,y+2,110,19,'熟練 +'+row[:mastery_gain].to_s,0)
      tags=[]
      tags.push('NEW招 '+row[:pending_moves].to_s) if row[:pending_moves].to_i>0
      tags.push('進化 '+row[:evolution_choices].to_s) if row[:evolution_choices].to_i>0
      tags.push('已進化') if row[:evolved]
      tags.push('新招 '+row[:learned_moves].size.to_s) if row[:learned_moves]!=nil && !row[:learned_moves].empty?
      if !tags.empty?
        b.font.size=12;b.font.color=Color.new(255,220,130)
        b.draw_text(130,y+17,b.width-154,14,tags.join('｜'),0)
      end
    end
    b.font.size=14;b.font.bold=false
    b.font.color=attention.to_i>0 ? Color.new(255,220,130) : Color.new(180,205,225)
    foot=attention.to_i>0 ? 'C 回布陣｜成長待處理 '+attention.to_i.to_s+'，回去後按 D' : 'C 回布陣｜A 隊伍/BOX｜D 成長'
    b.draw_text(12,b.height-25,b.width-24,20,foot,1)
    true
  end
end

class Game_System
  attr_accessor :pmd_autochess_loop_v079
end

#==============================================================================
# Party / BOX readability II
#==============================================================================
class Sprite_PMDPartyStoragePanelV078
  def ensure_box_scroll_v078
    rows=PMD_AC::PARTY_STORAGE_VISIBLE_ROWS_V079
    @box_scroll=@box_cursor if @box_cursor<@box_scroll
    @box_scroll=@box_cursor-rows+1 if @box_cursor>=@box_scroll+rows
    @box_scroll=0 if @box_scroll<0
  end

  def draw_party_card_v078(b,x,y,w,h,instance,index)
    selected=(@focus==:party && @party_index==index)
    marked=(@selected_party_slot==index)
    bg=selected ? Color.new(68,92,124,235) : Color.new(28,36,48,230)
    bg=Color.new(105,83,45,240) if marked
    b.fill_rect(x,y,w,h,bg)
    b.font.bold=true;b.font.size=PMD_AC::PARTY_CARD_NAME_FONT_V079
    b.font.color=Color.new(245,245,245)
    b.draw_text(x+8,y+1,w-16,25,(index+1).to_s+'. '+species_name_v078(instance),0)
    b.font.bold=false;b.font.size=PMD_AC::PARTY_CARD_LEVEL_FONT_V079
    b.font.color=Color.new(175,210,240)
    if instance!=nil
      b.draw_text(x+10,y+27,w-20,20,'Lv'+instance.level.to_s+'  EXP '+instance.exp.to_s,0)
      moves=instance.respond_to?(:battle_moves_v046) ? instance.battle_moves_v046 : instance.active_moves_v045
      names=moves.collect{|mv|move_name_v078(mv)}
      line1=(names[0,2]||[]).join(' / ')
      line2=(names[2,2]||[]).join(' / ')
      b.font.size=PMD_AC::PARTY_CARD_MOVES_FONT_V079;b.font.color=Color.new(195,205,215)
      b.draw_text(x+10,y+48,w-20,15,line1,0)
      b.draw_text(x+10,y+61,w-20,15,line2,0) if line2!=''
    end
    if marked
      b.font.size=PMD_AC::PARTY_CARD_MARK_FONT_V079;b.font.color=Color.new(255,225,130)
      b.draw_text(x+w-78,y+4,70,18,'交換中',2)
    end
  end

  def draw_box_row_v078(b,x,y,w,instance,index)
    selected=(@focus==:box && @box_cursor==index)
    b.fill_rect(x,y,w,PMD_AC::PARTY_STORAGE_BOX_ROW_H_V079,
      selected ? Color.new(68,92,124,235) : Color.new(25,32,42,225))
    b.font.size=PMD_AC::BOX_ROW_FONT_V079;b.font.bold=selected;b.font.color=Color.new(235,238,242)
    if instance==nil
      b.draw_text(x+8,y+6,w-16,23,'－',0)
    else
      text=(index+1).to_s.rjust(2,'0')+'  '+species_name_v078(instance)+'  Lv'+instance.level.to_s
      b.draw_text(x+8,y+6,w-16,23,text,0)
    end
    b.font.bold=false
  end

  def refresh
    b=self.bitmap;b.clear;setup_font_v078
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(7,11,17,248))
    b.fill_rect(10,10,Graphics.width-20,Graphics.height-20,Color.new(18,25,35,248))
    b.font.bold=true;b.font.size=PMD_AC::PARTY_STORAGE_TITLE_FONT_V079;b.font.color=Color.new(255,255,255)
    b.draw_text(18,12,300,32,'隊伍 / BOX 編成',0)
    b.font.bold=false;b.font.size=PMD_AC::PARTY_STORAGE_BOX_META_FONT_V079;b.font.color=Color.new(165,185,205)
    box=PMD_AC.pokemon_storage_boxes_v045[@box_index] || []
    b.draw_text(314,18,214,24,'BOX '+(@box_index+1).to_s.rjust(2,'0')+' / '+
      PMD_AC::STORAGE_BOX_COUNT_V045.to_s+'  '+box.size.to_s+'/'+PMD_AC::STORAGE_BOX_CAPACITY_V045.to_s,2)

    b.font.size=PMD_AC::PARTY_STORAGE_SECTION_FONT_V079;b.font.bold=true;b.font.color=Color.new(225,235,245)
    b.draw_text(20,55,190,25,'出戰隊伍 3 隻',0)
    b.draw_text(230,55,294,25,'寶可夢倉庫',0);b.font.bold=false

    party=party_instances
    for i in 0...PMD_AC::PARTY_CAPACITY_V045
      draw_party_card_v078(b,20,84+i*82,190,76,party[i],i)
    end

    a=box_instances;rows=PMD_AC::PARTY_STORAGE_VISIBLE_ROWS_V079
    for row in 0...rows
      idx=@box_scroll+row
      inst=idx<a.size ? a[idx] : nil
      draw_box_row_v078(b,230,84+row*36,294,inst,idx)
    end

    b.fill_rect(20,338,504,40,Color.new(25,34,46,230))
    b.font.size=PMD_AC::PARTY_STORAGE_HINT_FONT_V079
    b.font.color=@selected_party_slot==nil ? Color.new(165,185,205) : Color.new(255,220,125)
    hint=@selected_party_slot==nil ?
      '先在左側選出戰槽，再到 BOX 選擇替換寶可夢。' :
      '已選出戰槽 '+(@selected_party_slot+1).to_s+'，到右側 BOX 按 C 完成交換。'
    b.draw_text(28,347,488,22,hint,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,225))
    b.font.size=PMD_AC::PARTY_STORAGE_FOOTER_FONT_V079;b.font.color=Color.new(175,220,255)
    b.draw_text(6,389,532,20,'←→ 區域｜↑↓ 選擇｜C 標記/交換｜Q/W 換 BOX｜B 關閉',1)
  end
end

#==============================================================================
# Reward loop scene integration
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v079_start start unless method_defined?(:pmd_ac_v079_start)
  alias pmd_ac_v079_start_battle start_battle unless method_defined?(:pmd_ac_v079_start_battle)
  alias pmd_ac_v079_award_battle_exp award_battle_exp unless method_defined?(:pmd_ac_v079_award_battle_exp)
  alias pmd_ac_v079_show_result show_result unless method_defined?(:pmd_ac_v079_show_result)
  alias pmd_ac_v079_refresh_header refresh_header unless method_defined?(:pmd_ac_v079_refresh_header)
  alias pmd_ac_v079_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v079_prepare_verification_battle)
  alias pmd_ac_v079_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v079_update_verification_script)

  def start
    pmd_ac_v079_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.79 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:reward_loop,
      'FLOW v0.79 formation=v0.78 battle=normal reward=exp+mastery+growth_attention '+
      'alive_rate='+sprintf('%.2f',PMD_AC::REWARD_POLICY_ALIVE_V079)+' fainted_rate='+
      sprintf('%.2f',PMD_AC::REWARD_POLICY_FAINTED_V079)+' reserve_rate='+
      sprintf('%.2f',PMD_AC::REWARD_POLICY_RESERVE_V079)+' record=wins,losses,streak,best '+
      'drops=deferred capture_reward=deferred checksum32='+PMD_AC.reward_loop_checksum32_v079.to_s)
    log_event(:party_storage,
      'PATCH v0.79 font_scale=larger title=26 section=19 party_name=19 level=15 moves=13x2 box=17 hint=15 footer=14 rows=7 logic_unchanged=1')
    refresh_header
  end

  def capture_battle_progress_v079
    h={}
    for i in PMD_AC.party_instances_v078
      next if i==nil
      h[i.instance_uid.to_i]=PMD_AC.progress_snapshot_for_instance_v079(i)
    end
    h
  end

  def start_battle
    if verification_mode==:normal
      @battle_progress_before_v079=capture_battle_progress_v079
      @battle_reward_rows_v079=nil
      @battle_record_after_v079=nil
      @battle_loop_recorded_v079=false
    end
    pmd_ac_v079_start_battle
  end

  def award_battle_exp(winner_team)
    before=@battle_progress_before_v079 || capture_battle_progress_v079
    pmd_ac_v079_award_battle_exp(winner_team)
    return unless verification_mode==:normal
    after=capture_battle_progress_v079
    rows=[]
    for i in PMD_AC.party_instances_v078
      next if i==nil
      a=after[i.instance_uid.to_i]
      b=before[i.instance_uid.to_i]
      row=PMD_AC.reward_row_from_snapshots_v079(b,a)
      rows.push(row) if row!=nil
    end
    @battle_reward_rows_v079=rows
    unless @battle_loop_recorded_v079
      @battle_record_after_v079=PMD_AC.record_battle_result_v079(winner_team).dup
      @battle_loop_recorded_v079=true
    end
    total_exp=rows.inject(0){|sum,r|sum+r[:exp_gain].to_i}
    total_mastery=rows.inject(0){|sum,r|sum+r[:mastery_gain].to_i}
    attention=progression_attention_total_v077
    log_event(:reward_loop,
      'RESULT winner='+winner_team.to_s+' party_rows='+rows.size.to_s+' total_exp='+total_exp.to_s+
      ' mastery_gain='+total_mastery.to_s+' attention='+attention.to_s+
      ' record='+@battle_record_after_v079[:wins].to_s+'W/'+@battle_record_after_v079[:losses].to_s+'L'+
      ' streak='+@battle_record_after_v079[:streak].to_s)
    for r in rows
      log_event(:reward_loop,
        'ROW uid='+r[:uid].to_s+' species='+r[:species].to_s+' lv='+r[:level_before].to_s+'->'+r[:level].to_s+
        ' exp=+'+r[:exp_gain].to_s+' mastery=+'+r[:mastery_gain].to_s+
        ' learned='+r[:learned_moves].size.to_s+' pending='+r[:pending_moves].to_s+
        ' evolution_choices='+r[:evolution_choices].to_s+' evolved='+(r[:evolved] ? '1':'0'))
    end
  end

  def show_result
    pmd_ac_v079_show_result
    return unless verification_mode==:normal
    return if @result_sprite==nil
    old=@result_sprite.bitmap
    old.dispose if old!=nil && !old.disposed?
    @result_sprite.bitmap=Bitmap.new(PMD_AC::REWARD_RESULT_W_V079,PMD_AC::REWARD_RESULT_H_V079)
    @result_sprite.x=(Graphics.width-PMD_AC::REWARD_RESULT_W_V079)/2
    @result_sprite.y=(Graphics.height-PMD_AC::REWARD_RESULT_H_V079)/2-4
    @result_sprite.z=9999
    record=@battle_record_after_v079 || PMD_AC.battle_loop_state_v079
    attention=progression_attention_total_v077
    PMD_AC.draw_reward_result_v079(@result_sprite.bitmap,@result_text,
      @battle_reward_rows_v079||[],record,attention)
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear;bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.79',1)
    bmp.font.size=13;bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
    text=''
    if @phase==:deploy
      text='A 隊伍/BOX｜D 成長｜S 驗證：'+verification_mode_label+'｜Shift 開戰'
    elsif @phase==:battle
      text='AI Framework／Pixel Movement｜速度 x'+@battle_speed.to_s+'｜A 鍵切換｜B 離開'
    else
      text='戰鬥結束｜C 回到布陣｜B 離開'
    end
    bmp.draw_text(12,33,Graphics.width-24,21,text,1)
  end

  def reward_loop_v079?
    verification_mode==:reward_loop_v079
  end

  def prepare_verification_battle
    pmd_ac_v079_prepare_verification_battle
    if reward_loop_v079?
      @reward_loop_v079_failed=false
      for u in @units
        u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
        u.verification_energy_sandbox(true) if u.respond_to?(:verification_energy_sandbox)
      end
    end
  end

  def log_verify_v079(name,pass,detail='')
    @reward_loop_v079_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def v079_instance(uid,species,level)
    PMD_PokemonInstance.new(species,level,
      {:instance_uid=>uid,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
  end

  def verify_reward_manifest_v079
    return if @verification_done[:v079_manifest]
    pass=PMD_AC::REWARD_RESULT_ROWS_V079==3 && PMD_AC::REWARD_POLICY_ALIVE_V079.to_f==1.0 &&
      PMD_AC::REWARD_POLICY_FAINTED_V079.to_f==0.5 && PMD_AC::REWARD_POLICY_RESERVE_V079.to_f==0.0
    log_verify_v079('REWARD_LOOP_MANIFEST_V079',pass,
      'party=3 alive=1.00 fainted=0.50 reserve=0 drops=deferred capture=deferred checksum32='+
      PMD_AC.reward_loop_checksum32_v079.to_s)
    @verification_done[:v079_manifest]=true
  end

  def verify_reward_growth_v079
    return if @verification_done[:v079_growth]
    i=v079_instance(790010,:bulbasaur,1)
    before=PMD_AC.progress_snapshot_for_instance_v079(i)
    need=PMD_AC.exp_for_level(15,i.growth_group)-i.exp
    i.gain_exp(need,true)
    after=PMD_AC.progress_snapshot_for_instance_v079(i)
    row=PMD_AC.reward_row_from_snapshots_v079(before,after)
    pass=row[:level_before]==1 && row[:level]==15 && row[:exp_gain]==need &&
      row[:learned_moves].size>0 && row[:pending_moves]>0
    log_verify_v079('REWARD_GROWTH_SUMMARY_V079',pass,
      'lv=1->'+row[:level].to_s+' exp=+'+row[:exp_gain].to_s+' learned='+row[:learned_moves].size.to_s+
      ' pending='+row[:pending_moves].to_s)
    @verification_done[:v079_growth]=true
  end

  def verify_reward_mastery_v079
    return if @verification_done[:v079_mastery]
    i=v079_instance(790011,:bulbasaur,15)
    before=PMD_AC.progress_snapshot_for_instance_v079(i)
    mv=i.known_moves_v045[0]
    i.gain_move_mastery_v045(mv,3) if mv!=nil
    after=PMD_AC.progress_snapshot_for_instance_v079(i)
    row=PMD_AC.reward_row_from_snapshots_v079(before,after)
    pass=mv!=nil && row[:mastery_gain]==3 && row[:exp_gain]==0
    log_verify_v079('REWARD_MASTERY_SUMMARY_V079',pass,
      'move='+(mv==nil ? 'nil' : mv.to_s)+' mastery=+'+row[:mastery_gain].to_s+' exp=0')
    @verification_done[:v079_mastery]=true
  end

  def verify_reward_attention_v079
    return if @verification_done[:v079_attention]
    i=v079_instance(790012,:eevee,20)
    snap=PMD_AC.progress_snapshot_for_instance_v079(i)
    pass=snap[:evolution_choices].to_i>=7
    log_verify_v079('REWARD_ATTENTION_V079',pass,
      'species=eevee evolution_choices='+snap[:evolution_choices].to_s+' result_prompt=D')
    @verification_done[:v079_attention]=true
  end

  def verify_reward_record_v079
    return if @verification_done[:v079_record]
    s=PMD_AC.battle_loop_default_state_v079
    PMD_AC.record_battle_result_in_state_v079(s,:ally)
    PMD_AC.record_battle_result_in_state_v079(s,:ally)
    mid=s[:streak].to_i==2 && s[:best_streak].to_i==2
    PMD_AC.record_battle_result_in_state_v079(s,:enemy)
    pass=mid && s[:battles].to_i==3 && s[:wins].to_i==2 && s[:losses].to_i==1 &&
      s[:streak].to_i==0 && s[:best_streak].to_i==2
    log_verify_v079('REWARD_RECORD_V079',pass,
      'battles='+s[:battles].to_s+' wins='+s[:wins].to_s+' losses='+s[:losses].to_s+
      ' streak='+s[:streak].to_s+' best='+s[:best_streak].to_s)
    @verification_done[:v079_record]=true
  end

  def verify_reward_ui_v079
    return if @verification_done[:v079_ui]
    ok=true;b=nil
    begin
      b=Bitmap.new(PMD_AC::REWARD_RESULT_W_V079,PMD_AC::REWARD_RESULT_H_V079)
      sample={:uid=>1,:species=>:bulbasaur,:level_before=>14,:level=>15,:exp_gain=>88,
        :mastery_gain=>2,:learned_moves=>[:take_down],:pending_moves=>1,
        :evolution_choices=>0,:evolved=>false}
      ok=PMD_AC.draw_reward_result_v079(b,'藍方勝利',[sample],
        {:wins=>1,:losses=>0,:streak=>1,:best_streak=>1},1)
      ok=ok && PMD_AC::PARTY_STORAGE_TITLE_FONT_V079>=26 && PMD_AC::BOX_ROW_FONT_V079>=17
    rescue Exception=>e
      ok=false;log_event(:reward_loop,'UI_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s)
    ensure
      b.dispose if b!=nil && !b.disposed?
    end
    log_verify_v079('REWARD_UI_V079',ok,
      'result=500x230 party_storage_font=larger2 title=26 party=19 box=17 moves=13x2')
    @verification_done[:v079_ui]=true
  end

  def verify_reward_carry_v079
    return if @verification_done[:v079_carry]
    pass=PMD_AC::PARTY_CAPACITY_V045==3 && PMD_AC::ACTIVE_MOVE_SLOTS_V045==4 &&
      PMD_AC::STORAGE_BOX_COUNT_V045==24 && PMD_AC::STORAGE_BOX_CAPACITY_V045==30
    log_verify_v079('REWARD_CARRY_V079',pass,
      'identity=v0.45 exp=v0.46 ui=v0.47 progression=v0.77.1 party=v0.78 '+
      'stats=v0.76 balance=v0.75 sfx=v0.75.1 weather=v0.28 field=v0.35-v0.37 combo=v0.60.2 router=v0.62')
    @verification_done[:v079_carry]=true
  end

  def update_verification_script
    unless reward_loop_v079?
      pmd_ac_v079_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_reward_manifest_v079 if f>=2
    verify_reward_growth_v079 if f>=4
    verify_reward_mastery_v079 if f>=6
    verify_reward_attention_v079 if f>=8
    verify_reward_record_v079 if f>=10
    verify_reward_ui_v079 if f>=12
    verify_reward_carry_v079 if f>=14
    if f>=16 && !@verification_done[:v079_final]
      pass=!@reward_loop_v079_failed
      log_verify_v079('REWARD_LOOP_V079',pass,
        'manifest=1 growth=1 mastery=1 attention=1 record=1 ui=1 carry=1')
      @verification_done[:v079_final]=true
    end
    complete_verification_mode if f>=18
  end
end
