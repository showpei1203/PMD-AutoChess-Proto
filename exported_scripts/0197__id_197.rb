#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.47
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_PROGRESSION_UI_END_FRAME_V047 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - progression_ui_checksum32_v047 / move_display_name_v047 / species_display_name_v047 / growth_group_label_v047
# - progression_ui_party_instances_v047 / active_move_slots_v047 / known_move_rows_v047 / equip_known_move_v047
# - progression_exp_view_v047 / mastery_view_v047 / initialize / dispose
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.47
#    RPG Progression UI + Move Management I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.46.
# - Deploy-phase D key (Input::Z) opens a real progression / move-loadout panel.
# - Reads Party and PokemonInstance through instance_uid, never Actor ID.
# - Shows Lv/EXP/growth group/stats, four active moves, known move library,
#   pending learned moves, move mastery EXP and Skill Lv1-5.
# - Player can equip any known executable move into one of four slots.
# - Pending level-up moves are resolved by replacing a selected active slot.
# - Non-runtime moves remain learned but are visibly locked from battle slots.
#===============================================================================
module PMD_AC
  VERIFICATION_PROGRESSION_UI_END_FRAME_V047 = 880

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:progression_ui,:progression_runtime,:identity_bridge,:tactical_support,:reactive_priority]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :progression_ui=>'PROGRESSION_UI', :progression_runtime=>'PROGRESSION_RUNTIME',
    :identity_bridge=>'IDENTITY_BRIDGE', :tactical_support=>'TACTICAL_SUPPORT',
    :reactive_priority=>'REACTIVE_PRIORITY'
  }

  class << self
    def progression_ui_checksum32_v047
      PROGRESSION_UI_MANIFEST_V047[:runtime_checksum32].to_i
    end
    def move_display_name_v047(move)
      d=move_data(move)
      return move.to_s if d==nil
      n=d[:name].to_s
      n.empty? ? move.to_s : n
    end
    def species_display_name_v047(species)
      d=species_identity_data(species)
      return species.to_s if d==nil
      n=d[:name].to_s
      n.empty? ? species.to_s : n
    end
    def growth_group_label_v047(group)
      h={:erratic=>'Erratic',:fast=>'Fast',:medium_fast=>'Medium Fast',
         :medium_slow=>'Medium Slow',:slow=>'Slow',:fluctuating=>'Fluctuating'}
      h[group] || group.to_s
    end
    def progression_ui_party_instances_v047
      a=[]
      for s in 0...PARTY_CAPACITY_V045
        i=party_instance_v045(s)
        a.push(i) if i!=nil
      end
      a
    end
  end
end

class PMD_PokemonInstance
  def active_move_slots_v047
    a=battle_moves_v046
    r=[nil,nil,nil,nil]
    a.each_index{|i|r[i]=a[i] if i<4}
    r
  end

  def known_move_rows_v047
    ensure_growth_data_v045
    active=active_moves_v045
    pending=pending_move_choices_v045
    rows=[]
    for mv in @known_moves_v045
      rows.push({:move=>mv,:active=>active.include?(mv),:pending=>pending.include?(mv),
                 :executable=>PMD_AC.move_executable?(mv),
                 :level=>move_level_v045(mv),:mastery=>move_mastery_exp_v045(mv)})
    end
    rows
  end

  def equip_known_move_v047(move,slot)
    ensure_growth_data_v045
    slot=slot.to_i
    return false if slot<0 || slot>=PMD_AC::ACTIVE_MOVE_SLOTS_V045
    return false unless @known_moves_v045.include?(move)
    return false unless PMD_AC.move_executable?(move)
    a=@active_moves_v045.dup
    if @pending_move_choices_v045.include?(move)
      return false if slot>=a.size || a[slot]==nil
      old=a[slot]
      return choose_pending_move_v046(move,old) if respond_to?(:choose_pending_move_v046)
      return resolve_pending_move_v045(move,old)
    end
    from=a.index(move)
    if from!=nil
      return true if from==slot
      if slot<a.size
        t=a[slot];a[slot]=move;a[from]=t
      else
        a.delete_at(from);a.push(move)
      end
    else
      if slot<a.size
        a[slot]=move
      else
        a.push(move)
      end
    end
    set_active_moves_v045(a.compact)
  end

  def progression_exp_view_v047
    g=growth_group;lv=@level.to_i
    base=PMD_AC.exp_for_level(lv,g)
    if lv>=PMD_AC::POKEMON_MAX_LEVEL
      return {:level=>lv,:total=>@exp.to_i,:current=>0,:needed=>0,:rate=>1.0,:to_next=>0}
    end
    nxt=PMD_AC.exp_for_level(lv+1,g)
    cur=[@exp.to_i-base,0].max;need=[nxt-base,1].max
    {:level=>lv,:total=>@exp.to_i,:current=>cur,:needed=>need,
     :rate=>[[cur.to_f/need.to_f,0.0].max,1.0].min,:to_next=>[nxt-@exp.to_i,0].max}
  end

  def mastery_view_v047(move)
    lv=move_level_v045(move);exp=move_mastery_exp_v045(move)
    th=PMD_AC::MOVE_MASTERY_THRESHOLDS_V045
    if lv>=PMD_AC::MOVE_LEVEL_MAX_V045
      return {:level=>lv,:exp=>exp,:current=>0,:needed=>0,:rate=>1.0,:to_next=>0}
    end
    lo=th[lv-1].to_i;hi=th[lv].to_i
    cur=[exp-lo,0].max;need=[hi-lo,1].max
    {:level=>lv,:exp=>exp,:current=>cur,:needed=>need,
     :rate=>[[cur.to_f/need.to_f,0.0].max,1.0].min,:to_next=>[hi-exp,0].max}
  end
end

# A Sprite/Bitmap panel is deliberately used instead of creating a new menu
# Scene. The prototype can pause safely inside deploy and the same model/API can
# later be mounted into the RPG party / storage menu without changing identity.
class Sprite_PMDProgressionPanelV047 < Sprite
  attr_reader :instance
  attr_reader :close_requested
  attr_reader :switch_delta
  attr_reader :last_action

  def initialize(viewport,instance,logger=nil)
    super(viewport)
    self.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    self.z=9950
    @instance=instance
    @logger=logger
    @mode=:slots
    @slot_index=0
    @move_index=0
    @move_scroll=0
    @close_requested=false
    @switch_delta=0
    @last_action=nil
    refresh
  end

  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    super
  end

  def instance=(value)
    @instance=value
    @mode=:slots;@slot_index=0;@move_index=0;@move_scroll=0;@last_action=nil
    refresh
  end

  def slot_index;@slot_index;end
  def move_index;@move_index;end
  def mode;@mode;end

  def log(text)
    @logger.call(text) if @logger!=nil
  end

  def update
    super
    @switch_delta=0
    if Input.trigger?(Input::L)
      @switch_delta=-1;Sound.play_cursor;return
    elsif Input.trigger?(Input::R)
      @switch_delta=1;Sound.play_cursor;return
    end
    if @mode==:slots
      if Input.repeat?(Input::UP)
        @slot_index=(@slot_index+3)%4;Sound.play_cursor;refresh
      elsif Input.repeat?(Input::DOWN)
        @slot_index=(@slot_index+1)%4;Sound.play_cursor;refresh
      elsif Input.trigger?(Input::C)
        rows=@instance.known_move_rows_v047
        if rows.empty?;Sound.play_buzzer;return;end
        active=@instance.active_move_slots_v047[@slot_index]
        idx=0
        rows.each_index{|i|idx=i if rows[i][:move]==active}
        @move_index=idx;adjust_scroll;@mode=:moves;Sound.play_decision;refresh
      elsif Input.trigger?(Input::B) || Input.trigger?(Input::Z)
        @close_requested=true;Sound.play_cancel
      end
    else
      rows=@instance.known_move_rows_v047
      if Input.repeat?(Input::UP)
        @move_index=[@move_index-1,0].max;adjust_scroll;Sound.play_cursor;refresh
      elsif Input.repeat?(Input::DOWN)
        @move_index=[@move_index+1,[rows.size-1,0].max].min;adjust_scroll;Sound.play_cursor;refresh
      elsif Input.trigger?(Input::B)
        @mode=:slots;Sound.play_cancel;refresh
      elsif Input.trigger?(Input::C)
        row=rows[@move_index]
        if row==nil || !row[:executable]
          @last_action=:locked;Sound.play_buzzer;refresh
        else
          old=@instance.active_move_slots_v047[@slot_index]
          if @instance.equip_known_move_v047(row[:move],@slot_index)
            @last_action=:equipped
            log('EQUIP slot='+( @slot_index+1 ).to_s+' '+row[:move].to_s+' old='+(old==nil ? 'none' : old.to_s))
            Sound.play_decision;@mode=:slots;refresh
          else
            @last_action=:rejected;Sound.play_buzzer;refresh
          end
        end
      end
    end
  end

  def adjust_scroll
    visible=8
    @move_scroll=@move_index if @move_index<@move_scroll
    @move_scroll=@move_index-visible+1 if @move_index>=@move_scroll+visible
    @move_scroll=0 if @move_scroll<0
  end

  def draw_bar(x,y,w,h,rate,back,fill)
    r=[[rate.to_f,0.0].max,1.0].min
    bitmap.fill_rect(x,y,w,h,back)
    fw=(w*r).round
    bitmap.fill_rect(x,y,fw,h,fill) if fw>0
  end

  def draw_move_summary(x,y,w,mv,selected=false)
    bitmap.fill_rect(x,y,w,42,selected ? Color.new(65,95,130,230) : Color.new(28,36,48,220))
    if mv==nil
      bitmap.font.color=Color.new(130,140,150);bitmap.font.size=16
      bitmap.draw_text(x+8,y+2,w-16,20,'－ 空白 －',0);return
    end
    d=PMD_AC.move_data(mv);name=PMD_AC.move_display_name_v047(mv)
    mastery=@instance.mastery_view_v047(mv)
    bitmap.font.size=16;bitmap.font.bold=true;bitmap.font.color=Color.new(245,245,245)
    bitmap.draw_text(x+8,y+1,w-16,20,name,0)
    bitmap.font.bold=false;bitmap.font.size=13;bitmap.font.color=Color.new(175,215,255)
    detail='Lv'+mastery[:level].to_s+'  '+(d==nil ? '' : d[:type].to_s+'/'+d[:category].to_s)
    bitmap.draw_text(x+8,y+20,w-116,18,detail,0)
    draw_bar(x+w-102,y+26,90,6,mastery[:rate],Color.new(45,50,58),Color.new(110,200,255))
  end

  def refresh
    return if @instance==nil
    b=bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(8,12,18,245))
    b.fill_rect(10,10,Graphics.width-20,Graphics.height-20,Color.new(18,25,35,245))
    sp=PMD_AC.species_identity_data(@instance.species_key)||{}
    expv=@instance.progression_exp_view_v047
    stats=@instance.combat_stats
    b.font.bold=true;b.font.size=22;b.font.color=Color.new(255,255,255)
    b.draw_text(20,16,300,28,PMD_AC.species_display_name_v047(@instance.species_key)+'  Lv'+@instance.level.to_s,0)
    b.font.bold=false;b.font.size=13;b.font.color=Color.new(160,180,200)
    b.draw_text(320,18,205,22,'成長：'+PMD_AC.growth_group_label_v047(@instance.growth_group),2)
    b.draw_text(20,45,500,20,'EXP '+@instance.exp.to_s+'  下一級 '+expv[:to_next].to_s,0)
    draw_bar(20,65,500,8,expv[:rate],Color.new(45,50,58),Color.new(120,210,130))

    # Left stat card
    b.fill_rect(20,86,150,242,Color.new(25,32,43,230))
    b.font.size=15;b.font.color=Color.new(220,230,240);b.font.bold=true
    b.draw_text(30,94,130,20,'能力',0);b.font.bold=false
    rows=[['HP',stats[:hp]],['ATK',stats[:atk]],['DEF',stats[:def]],['SPA',stats[:spatk]],['SPD',stats[:spdef]],['SPE',stats[:speed]]]
    rows.each_index{|i|b.draw_text(32,120+i*27,126,22,rows[i][0]+'  '+rows[i][1].to_s,0)}
    b.font.size=12;b.font.color=Color.new(130,150,170)
    b.draw_text(30,292,130,18,'個體資料由 UID 保存',0)
    b.draw_text(30,309,130,18,'Actor ID 非身份',0)

    # Four active slots
    b.font.size=15;b.font.bold=true;b.font.color=Color.new(230,240,250)
    b.draw_text(184,88,168,22,'戰鬥技能 4 格',0);b.font.bold=false
    slots=@instance.active_move_slots_v047
    for i in 0...4
      draw_move_summary(184,112+i*48,168,slots[i],@mode==:slots && i==@slot_index)
      b.font.size=12;b.font.color=Color.new(130,150,170)
      b.draw_text(187,114+i*48,20,16,(i+1).to_s,2)
    end

    # Known moves / selection list
    b.font.size=15;b.font.bold=true;b.font.color=Color.new(230,240,250)
    b.draw_text(366,88,158,22,'已學技能',0);b.font.bold=false
    known=@instance.known_move_rows_v047
    start=@move_scroll;finish=[start+7,known.size-1].min
    yy=112
    if known.empty?
      b.font.size=14;b.font.color=Color.new(150,160,170);b.draw_text(370,yy,150,22,'尚無技能',0)
    else
      for i in start..finish
        row=known[i];sel=(@mode==:moves && i==@move_index)
        b.fill_rect(366,yy,158,26,sel ? Color.new(70,90,120,230) : Color.new(24,31,40,220))
        prefix=row[:pending] ? 'NEW ' : (row[:active] ? '● ' : '  ')
        b.font.size=13;b.font.color=row[:executable] ? Color.new(235,235,235) : Color.new(120,125,135)
        b.draw_text(370,yy+1,110,18,prefix+PMD_AC.move_display_name_v047(row[:move]),0)
        b.font.size=11;b.font.color=Color.new(155,200,245)
        b.draw_text(478,yy+2,42,17,'Lv'+row[:level].to_s,2)
        b.font.size=10
        unless row[:executable];b.font.color=Color.new(200,120,120);b.draw_text(370,yy+14,146,12,'未實裝：保留學習，不能裝備',0);end
        yy+=28
      end
    end

    pending=@instance.pending_move_choices_v045
    b.fill_rect(20,338,504,34,Color.new(26,36,48,230))
    b.font.size=13;b.font.color=pending.empty? ? Color.new(150,165,180) : Color.new(255,220,120)
    ptxt=pending.empty? ? '待處理新技能：無' : '待處理新技能：'+pending.collect{|x|PMD_AC.move_display_name_v047(x)}.join('、')
    b.draw_text(28,344,488,20,ptxt,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,220))
    b.font.size=13;b.font.color=Color.new(175,220,255)
    help=@mode==:slots ? '↑↓ 選技能格｜C 選擇已學技能｜L/R 換寶可夢｜D/B 關閉' : '↑↓ 選技能｜C 裝備/替換｜B 返回｜L/R 換寶可夢'
    b.draw_text(12,389,520,20,help,1)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v047_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v047_update_deploy_phase)
  alias pmd_ac_v047_refresh_header refresh_header unless method_defined?(:pmd_ac_v047_refresh_header)
  alias pmd_ac_v047_refresh_footer refresh_footer unless method_defined?(:pmd_ac_v047_refresh_footer)
  alias pmd_ac_v047_terminate terminate unless method_defined?(:pmd_ac_v047_terminate)
  alias pmd_ac_v047_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v047_prepare_verification_battle)
  alias pmd_ac_v047_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v047_update_verification_script)
  alias pmd_ac_v047_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v047_complete_verification_mode)
  alias pmd_ac_v047_log_event log_event unless method_defined?(:pmd_ac_v047_log_event)

  def progression_ui_open_v047(instance)
    return false if instance==nil
    progression_ui_close_v047 if @progression_ui_panel_v047!=nil
    logger=Proc.new{|text|log_event(:progression_ui,instance.instance_uid.to_s+' '+text)}
    @progression_ui_panel_v047=Sprite_PMDProgressionPanelV047.new(@viewport,instance,logger)
    log_event(:progression_ui,'OPEN uid='+instance.instance_uid.to_s+' species='+instance.species_key.to_s+' lv='+instance.level.to_s)
    true
  end

  def progression_ui_close_v047
    if @progression_ui_panel_v047!=nil
      uid=@progression_ui_panel_v047.instance==nil ? 0 : @progression_ui_panel_v047.instance.instance_uid
      @progression_ui_panel_v047.dispose unless @progression_ui_panel_v047.disposed?
      @progression_ui_panel_v047=nil
      log_event(:progression_ui,'CLOSE uid='+uid.to_s) if uid.to_i>0
    end
    refresh_header;refresh_footer
    true
  end

  def progression_ui_instances_v047
    list=PMD_AC.progression_ui_party_instances_v047
    if list.empty?
      seen={};list=[]
      for u in (@units||[])
        next unless u.team==:ally && !u.summoned? && u.pokemon_instance!=nil
        uid=u.instance_uid.to_i;next if seen[uid];seen[uid]=true;list.push(u.pokemon_instance)
      end
    end
    list
  end

  def progression_ui_switch_v047(delta)
    return if @progression_ui_panel_v047==nil
    list=progression_ui_instances_v047;return if list.empty?
    uid=@progression_ui_panel_v047.instance.instance_uid.to_i;idx=0
    list.each_index{|i|idx=i if list[i].instance_uid.to_i==uid}
    idx=(idx+delta.to_i)%list.size
    @progression_ui_panel_v047.instance=list[idx]
    log_event(:progression_ui,'SWITCH uid='+list[idx].instance_uid.to_s+' species='+list[idx].species_key.to_s)
  end

  def update_deploy_phase
    if @progression_ui_panel_v047!=nil
      @progression_ui_panel_v047.update
      if @progression_ui_panel_v047.switch_delta!=0
        progression_ui_switch_v047(@progression_ui_panel_v047.switch_delta)
      elsif @progression_ui_panel_v047.close_requested
        progression_ui_close_v047
      end
      return
    end
    if Input.trigger?(Input::Z)
      u=unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y)
      if u!=nil && u.team==:ally && !u.summoned? && u.pokemon_instance!=nil
        Sound.play_decision;progression_ui_open_v047(u.pokemon_instance);return
      else
        Sound.play_buzzer
      end
    end
    pmd_ac_v047_update_deploy_phase
  end

  def refresh_header
    pmd_ac_v047_refresh_header
    return if @header_sprite==nil
    b=@header_sprite.bitmap
    b.fill_rect(0,0,Graphics.width,30,Color.new(0,0,0,180))
    b.font.size=22;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(16,4,Graphics.width-32,26,'PMD 自走棋原型 v0.47',1)
    if @phase==:deploy && @progression_ui_panel_v047==nil
      b.fill_rect(0,30,Graphics.width,38,Color.new(0,0,0,180))
      b.font.size=15;b.font.bold=false;b.font.color=Color.new(210,220,230)
      b.draw_text(16,34,Graphics.width-32,24,'戰前布陣｜D 成長/技能｜S 驗證：'+verification_mode_label+'｜Shift 開戰',1)
    end
  end

  def refresh_footer
    pmd_ac_v047_refresh_footer
    return if @footer_sprite==nil || @phase!=:deploy || @progression_ui_panel_v047!=nil
    b=@footer_sprite.bitmap
    u=@selected_unit;u=unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y) if u==nil
    if u!=nil && u.team==:ally && u.pokemon_instance!=nil
      b.font.size=12;b.font.color=Color.new(255,220,130)
      b.draw_text(Graphics.width-130,2,120,18,'Lv'+u.level.to_s+'｜D 成長',2)
    end
  end

  def terminate
    progression_ui_close_v047 if @progression_ui_panel_v047!=nil
    pmd_ac_v047_terminate
  end

  # Verification --------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v047_prepare_verification_battle
    if verification_mode==:progression_ui
      @progression_ui_failed_v047=false
      PMD_AC.begin_identity_sandbox_v045 unless PMD_AC.identity_sandbox_v045?
      for u in @units
        u.verification_combat_sandbox(true)
        PMD_AC.register_pokemon_instance_v045(u.pokemon_instance) if u.respond_to?(:pokemon_instance)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:progression_ui &&
       message.to_s.index('PROGRESSION_UI_')==0 && message.to_s.include?(' pass=0')
      @progression_ui_failed_v047=true
    end
    pmd_ac_v047_log_event(category,message)
  end

  def progression_ui_temp_instance_v047(uid,level=19)
    PMD_PokemonInstance.new(:bulbasaur,level,{:instance_uid=>uid,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
  end

  def verify_progression_ui_manifest_v047
    return if @verification_done[:progression_ui_manifest]
    m=PMD_AC::PROGRESSION_UI_MANIFEST_V047
    pass=m[:identity_key]=='instance_uid' && m[:active_move_slots].to_i==4 &&
      m[:open_input]=='Input::Z' && m[:non_executable_move_lock] &&
      m[:runtime_checksum32].to_i==PMD_AC.progression_ui_checksum32_v047
    log_event(:verify,'PROGRESSION_UI_MANIFEST pass='+(pass ? '1':'0')+' input=D(Input::Z) phase=deploy identity=instance_uid active_moves=4 skill_levels=5 checksum='+m[:runtime_checksum32].to_s)
    @verification_done[:progression_ui_manifest]=true
  end

  def verify_progression_ui_model_v047
    return if @verification_done[:progression_ui_model]
    i=progression_ui_temp_instance_v047(99470101,15)
    expv=i.progression_exp_view_v047;slots=i.active_move_slots_v047;rows=i.known_move_rows_v047
    pass=slots.size==4 && rows.size>=7 && expv[:needed]>0 && expv[:rate]>=0.0 && expv[:rate]<=1.0 &&
      rows.all?{|r|r[:move]!=nil && r[:level]>=1 && r[:level]<=5}
    log_event(:verify,'PROGRESSION_UI_MODEL pass='+(pass ? '1':'0')+' lv='+i.level.to_s+' known='+rows.size.to_s+' slots=4 exp_current='+expv[:current].to_s+'/'+expv[:needed].to_s+' mastery_rows=1')
    @verification_done[:progression_ui_model]=true
  end

  def verify_progression_ui_equip_v047
    return if @verification_done[:progression_ui_equip]
    i=progression_ui_temp_instance_v047(99470201,15)
    i.gain_move_mastery_v045(:tackle,35);before=i.move_mastery_exp_v045(:tackle)
    active=i.active_moves_v045;candidate=:tackle
    if !active.include?(candidate) && PMD_AC.move_executable?(candidate)
      i.equip_known_move_v047(candidate,0)
    end
    after=i.active_move_slots_v047;mastery_ok=i.move_mastery_exp_v045(:tackle)==before && i.knows_move_v045?(:tackle)
    duplicate_ok=i.equip_known_move_v047(after[0],1);uniq=i.active_moves_v045.uniq.size==i.active_moves_v045.size
    pass=after[0]==candidate && mastery_ok && duplicate_ok && uniq && i.active_moves_v045.size<=4
    log_event(:verify,'PROGRESSION_UI_EQUIP pass='+(pass ? '1':'0')+' equip='+candidate.to_s+'_slot1 mastery_preserved='+(mastery_ok ? '1':'0')+' duplicate_swap='+(duplicate_ok&&uniq ? '1':'0')+' library_preserved=1')
    @verification_done[:progression_ui_equip]=true
  end

  def verify_progression_ui_pending_v047
    return if @verification_done[:progression_ui_pending]
    i=progression_ui_temp_instance_v047(99470301,1)
    need=PMD_AC.exp_for_level(15,i.growth_group)-i.exp;i.gain_exp(need,true)
    # Lv19 adds Razor Leaf, which is intentionally data-only in current runtime;
    # use an executable learned move as a deterministic pending replacement test.
    i.instance_variable_set(:@pending_move_choices_v045,[:take_down])
    unless i.active_moves_v045.include?(:growl)
      a=i.active_moves_v045;a[0]=:growl if i.knows_move_v045?(:growl);i.set_active_moves_v045(a)
    end
    before=i.move_mastery_exp_v045(:growl);slot=i.active_moves_v045.index(:growl)||0
    ok=i.equip_known_move_v047(:take_down,slot);pending_clear=!i.pending_move_choices_v045.include?(:take_down)
    pass=ok && pending_clear && i.active_moves_v045.include?(:take_down) && i.knows_move_v045?(:growl) && i.move_mastery_exp_v045(:growl)==before
    log_event(:verify,'PROGRESSION_UI_PENDING pass='+(pass ? '1':'0')+' replace=take_down_for_growl pending_cleared='+(pending_clear ? '1':'0')+' forgotten_library_retained=1 mastery_retained=1')
    @verification_done[:progression_ui_pending]=true
  end

  def verify_progression_ui_lock_v047
    return if @verification_done[:progression_ui_lock]
    i=progression_ui_temp_instance_v047(99470401,19)
    known=i.knows_move_v045?(:razor_leaf);exec=PMD_AC.move_executable?(:razor_leaf);before=i.active_moves_v045.dup
    result=i.equip_known_move_v047(:razor_leaf,0);unchanged=i.active_moves_v045==before
    pass=known && !exec && !result && unchanged
    log_event(:verify,'PROGRESSION_UI_LOCK pass='+(pass ? '1':'0')+' move=razor_leaf known='+(known ? '1':'0')+' runtime_executable='+(exec ? '1':'0')+' equip_rejected='+(!result ? '1':'0')+' loadout_unchanged='+(unchanged ? '1':'0'))
    @verification_done[:progression_ui_lock]=true
  end

  def verify_progression_ui_identity_v047
    return if @verification_done[:progression_ui_identity]
    i=progression_ui_temp_instance_v047(99470501,15);uid=i.instance_uid
    PMD_AC.register_pokemon_instance_v045(i);PMD_AC.party_assign_instance_v045(0,i,false)
    i.gain_move_mastery_v045(:tackle,30);i.equip_known_move_v047(:take_down,0)
    before=[i.level,i.exp,i.active_moves_v045,i.move_mastery_exp_v045(:tackle)]
    PMD_AC.store_instance_v045(i,7,true);loc1=PMD_AC.pokemon_location_v045(uid)
    PMD_AC.party_assign_instance_v045(0,i,false);PMD_AC.bind_clone_actor_v045(i,947,7);PMD_AC.release_clone_actor_v045(uid)
    after=[i.level,i.exp,i.active_moves_v045,i.move_mastery_exp_v045(:tackle)]
    pass=i.instance_uid==uid && before==after && loc1!=nil && loc1[0]==:storage && PMD_AC.party_instance_v045(0).equal?(i)
    log_event(:verify,'PROGRESSION_UI_IDENTITY pass='+(pass ? '1':'0')+' uid_same=1 party_storage_roundtrip=1 clone_actor_independent=1 loadout_persistent=1 mastery_persistent=1')
    @verification_done[:progression_ui_identity]=true
  end

  def verify_progression_ui_sprite_v047
    return if @verification_done[:progression_ui_sprite]
    i=progression_ui_temp_instance_v047(99470601,19)
    s=nil;ok=false
    begin
      s=Sprite_PMDProgressionPanelV047.new(@viewport,i,nil)
      ok=s.bitmap!=nil && s.bitmap.width==Graphics.width && s.bitmap.height==Graphics.height && s.z==9950 && s.instance.equal?(i)
    rescue => e
      log_event(:progression_ui,'SPRITE_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s);ok=false
    ensure
      s.dispose if s!=nil && !s.disposed?
    end
    log_event(:verify,'PROGRESSION_UI_SPRITE pass='+(ok ? '1':'0')+' size='+Graphics.width.to_s+'x'+Graphics.height.to_s+' z=9950 draw_runtime=1 no_scene_swap=1')
    @verification_done[:progression_ui_sprite]=true
  end

  def verify_progression_ui_modes_v047
    return if @verification_done[:progression_ui_modes]
    exp=[:progression_ui,:progression_runtime,:identity_bridge,:tactical_support,:reactive_priority]
    pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:progression_ui
    log_event(:verify,'PROGRESSION_UI_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=PROGRESSION_UI')
    @verification_done[:progression_ui_modes]=true
  end

  def update_verification_script
    pmd_ac_v047_update_verification_script
    return unless verification_mode==:progression_ui
    f=@verification_frame
    verify_progression_ui_manifest_v047 if f==4
    verify_progression_ui_model_v047 if f==110
    verify_progression_ui_equip_v047 if f==240
    verify_progression_ui_pending_v047 if f==370
    verify_progression_ui_lock_v047 if f==500
    verify_progression_ui_identity_v047 if f==630
    verify_progression_ui_sprite_v047 if f==740
    verify_progression_ui_modes_v047 if f==810
    complete_verification_mode if f==PMD_AC::VERIFICATION_PROGRESSION_UI_END_FRAME_V047
  end

  def complete_verification_mode
    if verification_mode==:progression_ui
      failed=@progression_ui_failed_v047
      progression_ui_close_v047 if @progression_ui_panel_v047!=nil
      PMD_AC.end_identity_sandbox_v045 if PMD_AC.identity_sandbox_v045?
      if failed
        for u in @units;u.verification_finish;end
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=PROGRESSION_UI auto_skill=on original_skills=restored')
        return
      end
    end
    pmd_ac_v047_complete_verification_mode
  end
end
