# encoding: UTF-8
#==============================================================================
# PMD AutoChess UI Readability v0.86
# 全戰鬥 UI 字體放大／可讀性統一層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 使用者希望 PMD AutoChess 目前所有主要 UI 字體都能再大一級。
# 過去 v0.74、v0.78.1、v0.79 是分階段調整，本腳本把常用畫面統一整理：
#
# 1. 戰場浮動文字：傷害、技能名、Threat、AI、Status、MISS。
# 2. 頂部 Header／底部 Footer。
# 3. 隊伍／BOX 編成。
# 4. D 成長／技能／進化面板。
# 5. 戰後結果／招募／Loot。
#
# 【設計原則】
# - 只改文字與 UI 佈局，不改傷害、AI、移動、碰撞、速度、技能機制。
# - Damage Popup v0.74 曾刻意縮小，因此這次只從 10 稍微放到 11，避免又蓋住角色。
# - BOX／成長／結果畫面則提高 2～3 px，因為它們是需要閱讀的資訊 UI。
# - 所有 UI 字型繼續使用 Microsoft JhengHei／微軟正黑體 fallback。
#
# 【最常自行調整的位置】
# 下面 PMD_AC 模組開頭的 *_FONT_V086 常數就是字級。
# 如果你之後覺得某區塊還小，優先只改那些常數，不要去 Runtime 裡逐行找 draw_text。
#
# 例如：
#   UI_HEADER_TITLE_FONT_V086 = 24
#   UI_HEADER_SUB_FONT_V086   = 15
#   UI_BOX_ROW_FONT_V086      = 19
#   UI_RESULT_TITLE_FONT_V086 = 30
#
# 【注意】
# VX 畫面固定 544x416，字不是越大越好。若再提高很多，應同步減少同畫面資訊量，
# 否則會得到非常清楚、但只看得到半句話的 UI。那種進步相當哲學。
#==============================================================================
module PMD_AC
  UI_HEADER_TITLE_FONT_V086 = 24
  UI_HEADER_SUB_FONT_V086   = 15
  UI_FOOTER_FONT_V086       = 14
  UI_FOOTER_LV_FONT_V086    = 14

  UI_DAMAGE_POPUP_W_V086 = 68
  UI_DAMAGE_POPUP_H_V086 = 22
  UI_DAMAGE_FONT_V086 = 11
  UI_CRIT_FONT_V086   = 10
  UI_SKILL_W_V086     = 150
  UI_SKILL_H_V086     = 32
  UI_SKILL_FONT_V086  = 15
  UI_THREAT_W_V086    = 48
  UI_THREAT_H_V086    = 24
  UI_THREAT_FONT_V086 = 16
  UI_AI_W_V086        = 48
  UI_AI_H_V086        = 20
  UI_AI_FONT_V086     = 12
  UI_STATUS_W_V086    = 132
  UI_STATUS_H_V086    = 20
  UI_STATUS_FONT_V086 = 11
  UI_MISS_FONT_V086   = 14

  UI_BOX_TITLE_FONT_V086   = 28
  UI_BOX_META_FONT_V086    = 17
  UI_BOX_SECTION_FONT_V086 = 21
  UI_BOX_NAME_FONT_V086    = 21
  UI_BOX_LEVEL_FONT_V086   = 17
  UI_BOX_MOVES_FONT_V086   = 15
  UI_BOX_MARK_FONT_V086    = 15
  UI_BOX_ROW_FONT_V086     = 19
  UI_BOX_HINT_FONT_V086    = 17
  UI_BOX_FOOTER_FONT_V086  = 15
  UI_BOX_VISIBLE_ROWS_V086 = 6
  UI_BOX_ROW_H_V086        = 40

  UI_PROG_TITLE_FONT_V086 = 25
  UI_PROG_META_FONT_V086  = 15
  UI_PROG_SECTION_FONT_V086 = 17
  UI_PROG_MOVE_FONT_V086  = 18
  UI_PROG_DETAIL_FONT_V086 = 14
  UI_PROG_LIST_FONT_V086 = 15
  UI_PROG_LIST_LV_FONT_V086 = 13
  UI_PROG_NOTE_FONT_V086 = 13
  UI_PROG_ATTENTION_FONT_V086 = 15
  UI_PROG_FOOTER_FONT_V086 = 14

  UI_RESULT_H_V086 = 360
  UI_RESULT_TITLE_FONT_V086 = 30
  UI_RESULT_SUB_FONT_V086 = 19
  UI_RESULT_RECORD_FONT_V086 = 18
  UI_RESULT_SECTION_FONT_V086 = 20
  UI_RESULT_NAME_FONT_V086 = 19
  UI_RESULT_DETAIL_FONT_V086 = 17
  UI_RESULT_TAG_FONT_V086 = 15
  UI_RESULT_RECRUIT_FONT_V086 = 18
  UI_RESULT_LOOT_FONT_V086 = 17
  UI_RESULT_FOOTER_FONT_V086 = 16

  UI_READABILITY_MANIFEST_V086 = {
    :version=>'0.86',
    :scope=>[:battle_float,:header,:footer,:party_box,:progression,:result,:loot],
    :damage_font=>UI_DAMAGE_FONT_V086,
    :header_title=>UI_HEADER_TITLE_FONT_V086,
    :box_name=>UI_BOX_NAME_FONT_V086,
    :progression_title=>UI_PROG_TITLE_FONT_V086,
    :result_title=>UI_RESULT_TITLE_FONT_V086,
    :mechanics_unchanged=>true
  }
end

#==============================================================================
# 戰場浮動文字
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v086_ui_initialize initialize unless method_defined?(:pmd_ac_v086_ui_initialize)
  alias pmd_ac_v086_ui_update_position update_position unless method_defined?(:pmd_ac_v086_ui_update_position)

  def pmd_ac_v086_replace_bitmap(sprite,w,h)
    return if sprite==nil
    old=sprite.bitmap
    sprite.bitmap=Bitmap.new(w,h)
    old.dispose if old!=nil && !old.disposed?
    pmd_ac_v074_set_font(sprite.bitmap) if respond_to?(:pmd_ac_v074_set_font)
  end

  def initialize(viewport,unit)
    pmd_ac_v086_ui_initialize(viewport,unit)
    pmd_ac_v086_replace_bitmap(@popup_sprite,PMD_AC::UI_DAMAGE_POPUP_W_V086,PMD_AC::UI_DAMAGE_POPUP_H_V086)
    pmd_ac_v086_replace_bitmap(@skill_sprite,PMD_AC::UI_SKILL_W_V086,PMD_AC::UI_SKILL_H_V086)
    pmd_ac_v086_replace_bitmap(@threat_sprite,PMD_AC::UI_THREAT_W_V086,PMD_AC::UI_THREAT_H_V086)
    pmd_ac_v086_replace_bitmap(@ai_sprite,PMD_AC::UI_AI_W_V086,PMD_AC::UI_AI_H_V086)
    pmd_ac_v086_replace_bitmap(@status_sprite,PMD_AC::UI_STATUS_W_V086,PMD_AC::UI_STATUS_H_V086)
    @last_popup_frames=-1
    @last_skill_frames=-1
    @last_threat_label=nil
    @last_ai_label=nil
    @last_status_label=nil
  end

  def update_position
    pmd_ac_v086_ui_update_position
    return if @unit==nil
    gx=(@unit.pixel_x+@unit.visual_offset_x).to_i
    @popup_sprite.x=gx-PMD_AC::UI_DAMAGE_POPUP_W_V086/2 if @popup_sprite!=nil
    @skill_sprite.x=gx-PMD_AC::UI_SKILL_W_V086/2 if @skill_sprite!=nil
    @threat_sprite.x=gx-PMD_AC::UI_THREAT_W_V086/2 if @threat_sprite!=nil
    @ai_sprite.x=gx-PMD_AC::UI_AI_W_V086/2 if @ai_sprite!=nil
    @status_sprite.x=gx-PMD_AC::UI_STATUS_W_V086/2 if @status_sprite!=nil
  end

  def update_popup
    frames=@unit.damage_popup_frames
    return if @last_popup_frames==frames
    old_frames=@last_popup_frames
    @last_popup_frames=frames
    if frames>0 && (old_frames<=0 || frames>old_frames)
      self.flash(Color.new(255,255,255,185),6)
    end
    bmp=@popup_sprite.bitmap;bmp.clear
    return if frames<=0
    pmd_ac_v074_set_font(bmp)
    bmp.font.bold=true
    if @unit.last_damage_critical
      bmp.font.size=PMD_AC::UI_CRIT_FONT_V086
      bmp.font.color=Color.new(255,220,90)
      bmp.draw_text(0,0,bmp.width,bmp.height,'CRIT -'+@unit.last_damage.to_s,1)
    else
      bmp.font.size=PMD_AC::UI_DAMAGE_FONT_V086
      bmp.font.color=Color.new(255,245,210)
      bmp.draw_text(0,0,bmp.width,bmp.height,'-'+@unit.last_damage.to_s,1)
    end
    @popup_sprite.opacity=PMD_AC.clamp(frames*10,0,255)
  end

  def update_skill_popup
    frames=@unit.skill_popup_frames
    return if @last_skill_frames==frames
    @last_skill_frames=frames
    bmp=@skill_sprite.bitmap;bmp.clear
    return if frames<=0
    pmd_ac_v074_set_font(bmp)
    bmp.fill_rect(6,5,bmp.width-12,22,Color.new(0,0,0,170))
    bmp.font.size=PMD_AC::UI_SKILL_FONT_V086
    bmp.font.bold=true;bmp.font.color=Color.new(255,235,120)
    bmp.draw_text(2,3,bmp.width-4,25,@unit.skill_name,1)
    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
  end

  def update_threat_debug
    return if @threat_sprite==nil
    unless PMD_AC::SHOW_THREAT_DEBUG
      @threat_sprite.visible=false;return
    end
    label=@unit.threat_debug_label
    if label!=@last_threat_label
      @last_threat_label=label
      bmp=@threat_sprite.bitmap;bmp.clear
      if label!=''
        pmd_ac_v074_set_font(bmp)
        bmp.font.size=PMD_AC::UI_THREAT_FONT_V086
        bmp.font.bold=true
        bmp.font.color=label=='!!' ? Color.new(255,110,80) : Color.new(255,225,90)
        bmp.draw_text(0,0,bmp.width,bmp.height,label,1)
      end
    end
    @threat_sprite.visible=(label!='' && !@unit.dead?)
  end

  def update_ai_debug
    return if @ai_sprite==nil
    unless PMD_AC::SHOW_AI_DEBUG
      @ai_sprite.visible=false;return
    end
    label=@unit.ai_debug_label
    if label!=@last_ai_label
      @last_ai_label=label
      bmp=@ai_sprite.bitmap;bmp.clear
      bmp.fill_rect(2,1,bmp.width-4,bmp.height-2,Color.new(0,0,0,150))
      pmd_ac_v074_set_font(bmp)
      bmp.font.size=PMD_AC::UI_AI_FONT_V086
      bmp.font.bold=true;bmp.font.color=Color.new(190,225,255)
      bmp.draw_text(0,0,bmp.width,bmp.height,label,1)
    end
    @ai_sprite.visible=!@unit.dead?
  end

  def update_status_debug
    return if @status_sprite==nil
    unless PMD_AC::SHOW_STATUS_DEBUG
      @status_sprite.visible=false;return
    end
    label=@unit.status_debug_label
    if label!=@last_status_label
      @last_status_label=label
      bmp=@status_sprite.bitmap;bmp.clear
      if label!=''
        bmp.fill_rect(1,1,bmp.width-2,bmp.height-2,Color.new(0,0,0,145))
        pmd_ac_v074_set_font(bmp)
        bmp.font.size=PMD_AC::UI_STATUS_FONT_V086
        bmp.font.bold=true;bmp.font.color=Color.new(220,245,255)
        bmp.draw_text(2,0,bmp.width-4,bmp.height,label,1)
      end
    end
    @status_sprite.visible=(label!='' && !@unit.dead?)
  end
end

class Sprite_PMDChessEffect
  alias pmd_ac_v086_ui_draw_effect draw_effect unless method_defined?(:pmd_ac_v086_ui_draw_effect)
  def draw_effect
    pmd_ac_v086_ui_draw_effect
    return unless @type==:miss && self.bitmap!=nil
    bmp=self.bitmap;bmp.clear
    bmp.font.name=PMD_AC::BATTLE_FONT_V074
    bmp.font.size=PMD_AC::UI_MISS_FONT_V086
    bmp.font.bold=true;bmp.font.color=Color.new(220,230,240)
    bmp.draw_text(0,18,bmp.width,24,'MISS',1)
  end
end

#==============================================================================
# 隊伍 / BOX
#==============================================================================
class Sprite_PMDPartyStoragePanelV078
  def ensure_box_scroll_v078
    rows=PMD_AC::UI_BOX_VISIBLE_ROWS_V086
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
    b.font.bold=true;b.font.size=PMD_AC::UI_BOX_NAME_FONT_V086;b.font.color=Color.new(245,245,245)
    b.draw_text(x+8,y,w-16,28,(index+1).to_s+'. '+species_name_v078(instance),0)
    b.font.bold=false;b.font.size=PMD_AC::UI_BOX_LEVEL_FONT_V086;b.font.color=Color.new(175,210,240)
    if instance!=nil
      b.draw_text(x+10,y+27,w-20,22,'Lv'+instance.level.to_s+'  EXP '+instance.exp.to_s,0)
      moves=instance.respond_to?(:battle_moves_v046) ? instance.battle_moves_v046 : instance.active_moves_v045
      names=moves.collect{|mv|move_name_v078(mv)}
      line1=(names[0,2]||[]).join(' / ')
      line2=(names[2,2]||[]).join(' / ')
      b.font.size=PMD_AC::UI_BOX_MOVES_FONT_V086;b.font.color=Color.new(195,205,215)
      b.draw_text(x+10,y+49,w-20,17,line1,0)
      b.draw_text(x+10,y+64,w-20,17,line2,0) if line2!=''
    end
    if marked
      b.font.size=PMD_AC::UI_BOX_MARK_FONT_V086;b.font.color=Color.new(255,225,130)
      b.draw_text(x+w-82,y+5,74,20,'交換中',2)
    end
  end

  def draw_box_row_v078(b,x,y,w,instance,index)
    selected=(@focus==:box && @box_cursor==index)
    b.fill_rect(x,y,w,PMD_AC::UI_BOX_ROW_H_V086,
      selected ? Color.new(68,92,124,235) : Color.new(25,32,42,225))
    b.font.size=PMD_AC::UI_BOX_ROW_FONT_V086;b.font.bold=selected;b.font.color=Color.new(235,238,242)
    if instance==nil
      b.draw_text(x+8,y+7,w-16,26,'－',0)
    else
      text=(index+1).to_s.rjust(2,'0')+'  '+species_name_v078(instance)+'  Lv'+instance.level.to_s
      b.draw_text(x+8,y+7,w-16,26,text,0)
    end
    b.font.bold=false
  end

  def refresh
    b=self.bitmap;b.clear;setup_font_v078
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(7,11,17,248))
    b.fill_rect(10,10,Graphics.width-20,Graphics.height-20,Color.new(18,25,35,248))
    b.font.bold=true;b.font.size=PMD_AC::UI_BOX_TITLE_FONT_V086;b.font.color=Color.new(255,255,255)
    b.draw_text(18,10,300,34,'隊伍 / BOX 編成',0)
    b.font.bold=false;b.font.size=PMD_AC::UI_BOX_META_FONT_V086;b.font.color=Color.new(165,185,205)
    box=PMD_AC.pokemon_storage_boxes_v045[@box_index] || []
    b.draw_text(310,17,218,25,'BOX '+(@box_index+1).to_s.rjust(2,'0')+' / '+
      PMD_AC::STORAGE_BOX_COUNT_V045.to_s+'  '+box.size.to_s+'/'+PMD_AC::STORAGE_BOX_CAPACITY_V045.to_s,2)

    b.font.size=PMD_AC::UI_BOX_SECTION_FONT_V086;b.font.bold=true;b.font.color=Color.new(225,235,245)
    b.draw_text(20,52,190,28,'出戰隊伍 3 隻',0)
    b.draw_text(230,52,294,28,'寶可夢倉庫',0);b.font.bold=false

    party=party_instances
    for i in 0...PMD_AC::PARTY_CAPACITY_V045
      draw_party_card_v078(b,20,82+i*84,190,80,party[i],i)
    end

    a=box_instances;rows=PMD_AC::UI_BOX_VISIBLE_ROWS_V086
    for row in 0...rows
      idx=@box_scroll+row
      inst=idx<a.size ? a[idx] : nil
      draw_box_row_v078(b,230,82+row*42,294,inst,idx)
    end

    b.fill_rect(20,338,504,40,Color.new(25,34,46,230))
    b.font.size=PMD_AC::UI_BOX_HINT_FONT_V086
    b.font.color=@selected_party_slot==nil ? Color.new(165,185,205) : Color.new(255,220,125)
    hint=@selected_party_slot==nil ?
      '先選左側出戰槽，再到 BOX 選擇替換寶可夢。' :
      '已選槽 '+(@selected_party_slot+1).to_s+'，到右側 BOX 按 C 完成交換。'
    b.draw_text(28,345,488,25,hint,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,225))
    b.font.size=PMD_AC::UI_BOX_FOOTER_FONT_V086;b.font.color=Color.new(175,220,255)
    b.draw_text(6,387,532,24,'←→ 區域｜↑↓ 選擇｜C 標記/交換｜Q/W 換 BOX｜B 關閉',1)
  end
end

#==============================================================================
# 成長／技能／進化
#==============================================================================
class Sprite_PMDProgressionPanelV047
  def draw_move_summary(x,y,w,mv,selected=false)
    bitmap.fill_rect(x,y,w,42,selected ? Color.new(65,95,130,230) : Color.new(28,36,48,220))
    if mv==nil
      bitmap.font.color=Color.new(130,140,150);bitmap.font.size=PMD_AC::UI_PROG_MOVE_FONT_V086
      bitmap.draw_text(x+8,y,w-16,24,'－ 空白 －',0);return
    end
    name=PMD_AC.move_display_name_v047(mv);mastery=@instance.mastery_view_v047(mv)
    bitmap.font.size=PMD_AC::UI_PROG_MOVE_FONT_V086;bitmap.font.bold=true;bitmap.font.color=Color.new(245,245,245)
    bitmap.draw_text(x+8,y,w-16,23,name,0)
    bitmap.font.bold=false;bitmap.font.size=PMD_AC::UI_PROG_DETAIL_FONT_V086;bitmap.font.color=Color.new(175,215,255)
    detail='Lv'+mastery[:level].to_s+'  '+PMD_AC.mastery_policy_short_v048(mv,mastery[:level])
    bitmap.draw_text(x+8,y+21,w-112,19,detail,0)
    draw_bar(x+w-102,y+28,90,6,mastery[:rate],Color.new(45,50,58),Color.new(110,200,255))
  end

  def draw_evolution_modal_v086
    rows=@instance.evolution_choice_rows_v077
    return if rows.empty?
    b=bitmap;x=78;y=38;w=388;h=334
    b.fill_rect(x,y,w,h,Color.new(5,8,12,245))
    b.fill_rect(x+2,y+2,w-4,h-4,Color.new(24,31,42,248))
    b.font.bold=true;b.font.size=22;b.font.color=Color.new(255,235,150)
    b.draw_text(x+14,y+8,w-28,30,'分歧進化',0)
    b.font.bold=false;b.font.size=14;b.font.color=Color.new(170,190,210)
    b.draw_text(x+14,y+39,w-28,21,
      PMD_AC.species_display_name_v047(@instance.species_key)+'  Lv'+@instance.level.to_s+'｜由玩家選擇進化分支',0)
    yy=y+66
    for i in 0...rows.size
      row=rows[i];sel=(i==evolution_index_v077)
      b.fill_rect(x+12,yy,w-24,28,sel ? Color.new(70,100,135,235) : Color.new(30,38,50,225))
      b.font.size=16;b.font.color=Color.new(240,245,250);b.font.bold=sel
      b.draw_text(x+20,yy+2,180,22,row[:name],0)
      b.font.bold=false;b.font.size=13;b.font.color=Color.new(160,205,240)
      types=row[:types].collect{|t|t.to_s}.join('/')
      b.draw_text(x+202,yy+3,92,20,types,0)
      b.font.color=Color.new(220,190,135)
      b.draw_text(x+296,yy+3,74,20,row[:hint],2)
      yy+=30
    end
    b.font.size=14;b.font.color=Color.new(175,220,255)
    b.draw_text(x+12,y+h-30,w-24,22,'↑↓ 選擇｜C 確認進化｜B 返回',1)
  end

  def refresh
    return if @instance==nil
    b=bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(8,12,18,245))
    b.fill_rect(10,10,Graphics.width-20,Graphics.height-20,Color.new(18,25,35,245))
    expv=@instance.progression_exp_view_v047;stats=@instance.combat_stats
    b.font.bold=true;b.font.size=PMD_AC::UI_PROG_TITLE_FONT_V086;b.font.color=Color.new(255,255,255)
    b.draw_text(20,13,310,32,PMD_AC.species_display_name_v047(@instance.species_key)+'  Lv'+@instance.level.to_s,0)
    b.font.bold=false;b.font.size=PMD_AC::UI_PROG_META_FONT_V086;b.font.color=Color.new(160,180,200)
    b.draw_text(318,17,206,25,'成長：'+PMD_AC.growth_group_label_v047(@instance.growth_group),2)
    b.draw_text(20,44,500,22,'EXP '+@instance.exp.to_s+'  下一級 '+expv[:to_next].to_s,0)
    draw_bar(20,67,500,8,expv[:rate],Color.new(45,50,58),Color.new(120,210,130))

    b.fill_rect(20,86,150,242,Color.new(25,32,43,230))
    b.font.size=PMD_AC::UI_PROG_SECTION_FONT_V086;b.font.color=Color.new(220,230,240);b.font.bold=true
    b.draw_text(30,92,130,24,'能力',0);b.font.bold=false
    rows=[['HP',stats[:hp]],['ATK',stats[:atk]],['DEF',stats[:def]],['SPA',stats[:spatk]],['SPD',stats[:spdef]],['SPE',stats[:speed]]]
    b.font.size=16;b.font.color=Color.new(215,225,235)
    rows.each_index{|i|b.draw_text(32,119+i*27,126,23,rows[i][0]+'  '+rows[i][1].to_s,0)}
    b.font.size=PMD_AC::UI_PROG_NOTE_FONT_V086;b.font.color=Color.new(150,205,235)
    b.draw_text(30,288,132,18,'即時速度 ×'+PMD_AC.realtime_speed_label_v076(@instance),0)
    b.font.color=Color.new(140,160,180)
    b.draw_text(30,307,132,18,'個體／性格已計入',0)

    b.font.size=PMD_AC::UI_PROG_SECTION_FONT_V086;b.font.bold=true;b.font.color=Color.new(230,240,250)
    b.draw_text(184,87,170,24,'戰鬥技能 4 格',0);b.font.bold=false
    slots=@instance.active_move_slots_v047
    for i in 0...4
      draw_move_summary(184,112+i*48,170,slots[i],@mode==:slots && i==@slot_index)
      b.font.size=13;b.font.color=Color.new(130,150,170)
      b.draw_text(187,114+i*48,20,17,(i+1).to_s,2)
    end

    b.font.size=PMD_AC::UI_PROG_SECTION_FONT_V086;b.font.bold=true;b.font.color=Color.new(230,240,250)
    b.draw_text(366,87,158,24,'已學技能',0);b.font.bold=false
    known=@instance.known_move_rows_v047
    start=@move_scroll;finish=[start+7,known.size-1].min;yy=112
    if known.empty?
      b.font.size=16;b.font.color=Color.new(150,160,170);b.draw_text(370,yy,150,24,'尚無技能',0)
    else
      for i in start..finish
        row=known[i];sel=(@mode==:moves && i==@move_index)
        b.fill_rect(366,yy,158,26,sel ? Color.new(70,90,120,230) : Color.new(24,31,40,220))
        prefix=row[:pending] ? 'NEW ' : (row[:active] ? '● ' : '  ')
        b.font.size=PMD_AC::UI_PROG_LIST_FONT_V086;b.font.color=row[:executable] ? Color.new(235,235,235) : Color.new(120,125,135)
        b.draw_text(370,yy,110,20,prefix+PMD_AC.move_display_name_v047(row[:move]),0)
        b.font.size=PMD_AC::UI_PROG_LIST_LV_FONT_V086;b.font.color=Color.new(155,200,245)
        b.draw_text(478,yy+1,42,19,'Lv'+row[:level].to_s,2)
        unless row[:executable]
          b.font.size=11;b.font.color=Color.new(200,120,120)
          b.draw_text(370,yy+15,148,12,'未實裝：保留，不能裝備',0)
        end
        yy+=28
      end
    end

    attention=@instance.progression_attention_v077
    b.fill_rect(20,338,504,34,Color.new(26,36,48,230))
    has_attention=attention[:pending_moves].to_i>0 || attention[:evolution_choices].to_i>0
    b.font.size=PMD_AC::UI_PROG_ATTENTION_FONT_V086
    b.font.color=has_attention ? Color.new(255,220,120) : Color.new(150,165,180)
    text='待處理：新技能 '+attention[:pending_moves].to_s+'｜分歧進化 '+attention[:evolution_choices].to_s
    text+='（A 選擇）' if attention[:evolution_choices].to_i>0
    b.draw_text(28,343,488,24,text,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,220))
    b.font.size=PMD_AC::UI_PROG_FOOTER_FONT_V086;b.font.color=Color.new(175,220,255)
    help=''
    if @mode==:slots
      help='↑↓ 技能格｜C 選技能｜A 進化｜L/R 換寶可夢｜D/B 關閉'
    elsif @mode==:moves
      help='↑↓ 技能｜C 裝備｜Shift 清除NEW｜B 返回｜L/R 換寶可夢'
    else
      help='↑↓ 選擇｜C 確認進化｜B 返回'
    end
    b.draw_text(8,387,528,24,help,1)
    draw_evolution_modal_v086 if @mode==:evolution_v077
  end
end

#==============================================================================
# 戰後結果／Loot
#==============================================================================
module PMD_AC
  def self.draw_result_growth_rows_v086(b,rows)
    rows=rows || []
    for idx in 0...REWARD_RESULT_ROWS_V079
      row=rows[idx];y=118+idx*42
      b.fill_rect(16,y,b.width-32,39,Color.new(24,32,43,225))
      next if row==nil
      name=species_name_reward_v079(row[:species])
      b.font.size=UI_RESULT_NAME_FONT_V086;b.font.bold=true;b.font.color=Color.new(245,245,245)
      b.draw_text(24,y+1,110,23,name,0)
      b.font.bold=false;b.font.size=UI_RESULT_DETAIL_FONT_V086;b.font.color=Color.new(190,215,235)
      lv='Lv'+row[:level_before].to_s;lv+='→'+row[:level].to_s if row[:level]>row[:level_before]
      b.draw_text(134,y+1,92,23,lv,0)
      b.draw_text(226,y+1,102,23,'EXP +'+row[:exp_gain].to_s,0)
      b.draw_text(328,y+1,118,23,'熟練 +'+row[:mastery_gain].to_s,0)
      tags=[]
      tags.push('NEW招 '+row[:pending_moves].to_s) if row[:pending_moves].to_i>0
      tags.push('進化 '+row[:evolution_choices].to_s) if row[:evolution_choices].to_i>0
      tags.push('已進化') if row[:evolved]
      tags.push('新招 '+row[:learned_moves].size.to_s) if row[:learned_moves]!=nil && !row[:learned_moves].empty?
      unless tags.empty?
        b.font.size=UI_RESULT_TAG_FONT_V086;b.font.color=Color.new(255,220,130)
        b.draw_text(134,y+21,b.width-158,17,tags.join('｜'),0)
      end
    end
  end

  def self.draw_stage_result_v086(b,result_text,rows,record,attention,stage_reward)
    return false if b==nil
    b.font.name=UI_PANEL_FONT_V0741 rescue b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    b.clear;b.fill_rect(0,0,b.width,b.height,Color.new(0,0,0,235))
    b.font.bold=true;b.font.size=UI_RESULT_TITLE_FONT_V086;b.font.color=Color.new(255,255,255)
    b.draw_text(10,4,b.width-20,38,result_text.to_s,1)
    sr=stage_reward || {};sid=sr[:stage_id] || current_stage_id_v080
    stage_line='關卡 '+sid.to_s+'｜'+stage_name_v080(sid)
    stage_line+='｜通關 '+sr[:clear_count].to_i.to_s+' 次' if sr[:clear_count].to_i>0
    b.font.bold=false;b.font.size=UI_RESULT_SUB_FONT_V086;b.font.color=Color.new(205,225,245)
    b.draw_text(16,43,b.width-32,26,stage_line,1)
    r=record || battle_loop_default_state_v079
    b.font.size=UI_RESULT_RECORD_FONT_V086;b.font.color=Color.new(180,205,230)
    rec='戰績 '+r[:wins].to_i.to_s+'勝 '+r[:losses].to_i.to_s+'敗｜連勝 '+r[:streak].to_i.to_s+'｜最高 '+r[:best_streak].to_i.to_s
    b.draw_text(16,69,b.width-32,25,rec,1)
    b.font.bold=true;b.font.size=UI_RESULT_SECTION_FONT_V086;b.font.color=Color.new(235,240,245)
    b.draw_text(18,93,b.width-36,26,'戰後成長',0);b.font.bold=false
    draw_result_growth_rows_v086(b,rows)
    ry=246;b.fill_rect(16,ry,b.width-32,36,Color.new(38,34,23,230))
    b.font.bold=true;b.font.size=UI_RESULT_RECRUIT_FONT_V086;b.font.color=Color.new(255,225,145)
    offer=sr[:offer]
    if sr[:winner]==:ally
      if offer!=nil
        sp=species_name_reward_v079(offer[:species])
        text=offer[:accepted] ? ('招募完成：'+sp+' Lv'+offer[:level].to_s+' 已加入 BOX') : ('招募候選：'+sp+' Lv'+offer[:level].to_s+'｜A 加入 BOX')
      else
        text=sr[:first_clear] ? '本次無招募候選' : '本次沒有可招募的寶可夢'
      end
      text+='｜解鎖 '+stage_name_v080(sr[:unlocked_stage]) if sr[:unlocked_stage]!=nil
    else
      text='戰敗不發 EXP／招募候選；技能熟練仍依實際使用累積'
    end
    b.draw_text(24,ry+5,b.width-48,26,text,0);b.font.bold=false
    b.font.size=UI_RESULT_FOOTER_FONT_V086
    b.font.color=attention.to_i>0 ? Color.new(255,220,130) : Color.new(185,210,230)
    foot=attention.to_i>0 ? ('C 回布陣｜成長待處理 '+attention.to_i.to_s+'，回去後按 D｜A 招募') : 'C 回布陣｜Q/W 選關｜A 招募候選'
    b.draw_text(10,b.height-30,b.width-20,25,foot,1)
    true
  end

  def self.draw_rpg_result_v086(b,result_text,rows,record,attention,reward)
    return false if b==nil
    b.font.name=UI_PANEL_FONT_V0741 rescue b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    b.clear;b.fill_rect(0,0,b.width,b.height,Color.new(0,0,0,235))
    req=reward==nil ? nil : reward[:request];kind=req==nil ? nil : req[:kind]
    b.font.bold=true;b.font.size=UI_RESULT_TITLE_FONT_V086;b.font.color=Color.new(255,255,255)
    b.draw_text(10,4,b.width-20,38,result_text.to_s,1)
    b.font.bold=false;b.font.size=UI_RESULT_SUB_FONT_V086;b.font.color=Color.new(205,225,245)
    sub=context_label_v081(kind);sub+='｜'+req[:name].to_s if req!=nil;sub+='｜不可招募' if kind==:boss
    b.draw_text(16,43,b.width-32,26,sub,1)
    r=record || battle_loop_default_state_v079
    b.font.size=UI_RESULT_RECORD_FONT_V086;b.font.color=Color.new(180,205,230)
    rec='戰績 '+r[:wins].to_i.to_s+'勝 '+r[:losses].to_i.to_s+'敗｜連勝 '+r[:streak].to_i.to_s+'｜最高 '+r[:best_streak].to_i.to_s
    b.draw_text(16,69,b.width-32,25,rec,1)
    b.font.bold=true;b.font.size=UI_RESULT_SECTION_FONT_V086;b.font.color=Color.new(235,240,245)
    b.draw_text(18,93,b.width-36,26,'戰後成長',0);b.font.bold=false
    draw_result_growth_rows_v086(b,rows)
    ry=246;b.fill_rect(16,ry,b.width-32,36,Color.new(38,34,23,230))
    b.font.bold=true;b.font.size=UI_RESULT_RECRUIT_FONT_V086;b.font.color=Color.new(255,225,145)
    offer=reward==nil ? nil : reward[:offer];winner=reward==nil ? nil : reward[:winner]
    if winner==:ally
      if kind==:boss
        text='BOSS 戰勝利｜此戰敵人不可招募'
      elsif offer!=nil
        sp=species_name_reward_v079(offer[:species])
        text=offer[:accepted] ? ('招募完成：'+sp+' Lv'+offer[:level].to_s+' 已加入 BOX') : ('招募候選：'+sp+' Lv'+offer[:level].to_s+'｜A 加入 BOX')
      elsif req!=nil && req[:recruitable]
        text='本次沒有出現可招募的寶可夢'
      else
        text='此戰沒有招募獎勵'
      end
    else
      text='戰敗不發 EXP；技能熟練仍依實際使用累積'
    end
    b.draw_text(24,ry+5,b.width-48,26,text,0);b.font.bold=false
    b.font.size=UI_RESULT_FOOTER_FONT_V086
    b.font.color=attention.to_i>0 ? Color.new(255,220,130) : Color.new(185,210,230)
    foot='C 返回地圖';foot+='｜A 招募' if offer!=nil && !offer[:accepted];foot+='｜成長待處理 '+attention.to_i.to_s if attention.to_i>0
    b.draw_text(10,b.height-30,b.width-20,25,foot,1)
    true
  end

  def self.draw_loot_summary_v083(bitmap,loot,winner_team)
    return false if bitmap==nil
    y=286
    bitmap.fill_rect(16,y,bitmap.width-32,34,Color.new(27,42,28,232))
    bitmap.font.name=UI_PANEL_FONT_V0741 rescue bitmap.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    bitmap.font.size=UI_RESULT_LOOT_FONT_V086;bitmap.font.bold=true;bitmap.font.color=Color.new(205,240,190)
    labels=loot==nil ? [] : (loot[:labels]||[])
    text=winner_team!=:ally ? '戰利品：戰敗不發放' : (labels.empty? ? '戰利品：無' : '戰利品：'+labels.join('｜'))
    bitmap.draw_text(24,y+4,bitmap.width-48,26,text,0)
    true
  end
end

#==============================================================================
# Header / Footer / 結果 Bitmap 尺寸
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v086_ui_start start unless method_defined?(:pmd_ac_v086_ui_start)

  def start
    pmd_ac_v086_ui_start
    log_event(:presentation,
      'PATCH v0.86 ui_readability=global_up battle_float=up header_footer=up box=up progression=up result=up mechanics_unchanged=1')
    refresh_header;refresh_footer
  end

  def refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap;bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.86',1)
    bmp.font.size=PMD_AC::UI_HEADER_SUB_FONT_V086;bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
    req=rpg_request_v081
    text=''
    if req!=nil
      ctx=PMD_AC.context_label_v081(req[:kind])+'｜'+req[:name].to_s
      if @phase==:deploy
        text=ctx+'｜A BOX｜D成長｜Shift開戰'+(req[:can_escape] ? '｜B返回' : '｜不可逃跑')
      elsif @phase==:battle
        text=ctx+'｜速度 x'+@battle_speed.to_s+(req[:can_escape] ? '｜B逃離' : '｜不可逃跑')
      else
        text=ctx+'｜C返回｜A招募'
      end
    else
      if @phase==:deploy
        if verification_mode==:normal && PMD_AC.respond_to?(:current_stage_id_v080)
          sid=PMD_AC.current_stage_id_v080;d=PMD_AC.stage_data_v080(sid);rec=d==nil ? 0 : d[:recommended_level].to_i
          text='Q/W '+PMD_AC.stage_name_v080(sid)+' Lv'+rec.to_s+'｜A BOX｜D成長｜S驗證｜Shift開戰'
        else
          text='S 驗證：'+verification_mode_label+'｜Shift 開戰'
        end
      elsif @phase==:battle
        sid=@active_stage_id_v080 || PMD_AC.current_stage_id_v080
        text=PMD_AC.stage_name_v080(sid)+'｜速度 x'+@battle_speed.to_s+'｜A切換｜B離開'
      else
        text='戰鬥結束｜A招募｜C回布陣｜B離開'
      end
    end
    bmp.draw_text(8,32,Graphics.width-16,25,text,1)
  end

  def refresh_footer
    return if @footer_sprite==nil || @footer_sprite.bitmap==nil
    bmp=@footer_sprite.bitmap;bmp.clear
    bmp.fill_rect(0,0,Graphics.width,52,Color.new(0,0,0,205))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::UI_FOOTER_FONT_V086;bmp.font.bold=false;bmp.font.color=Color.new(235,240,245)
    if @phase==:deploy
      unit=@selected_unit;unit=unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y) if unit==nil
      line1='空白棋格'
      if unit!=nil
        line1=unit.name+'  HP '+unit.maxhp.to_s+'  ATK '+unit.atk.to_s+'  DEF '+unit.defense.to_s+'  '+unit.role_label+'／'+unit.range_label+'  AI：'+unit.movement_policy_label+'／'+unit.target_policy_label
      end
      line2=@selected_unit!=nil ? ('已選取 '+@selected_unit.name+'｜C放置/交換｜S '+verification_mode_label+'｜B取消｜Shift開戰') : ('方向鍵移動｜C選取｜S驗證：'+verification_mode_label+'｜Shift開戰｜B離開')
      bmp.draw_text(10,1,Graphics.width-20,22,line1,0)
      if unit!=nil && unit.team==:ally && unit.pokemon_instance!=nil
        bmp.font.size=PMD_AC::UI_FOOTER_LV_FONT_V086;bmp.font.color=Color.new(255,220,130)
        bmp.draw_text(Graphics.width-132,1,122,21,'Lv'+unit.level.to_s+'｜D成長',2)
        bmp.font.size=PMD_AC::UI_FOOTER_FONT_V086
      end
      bmp.font.color=Color.new(170,220,255);bmp.draw_text(10,26,Graphics.width-20,22,line2,0)
    elsif @phase==:battle
      allies=living_units(:ally).size;enemies=living_units(:enemy).size
      bmp.draw_text(10,1,Graphics.width-20,22,'藍方存活 '+allies.to_s+'｜紅方存活 '+enemies.to_s,0)
      bmp.font.color=Color.new(170,220,255)
      bmp.draw_text(10,26,Graphics.width-20,22,'AI策略／威脅反應｜落空 '+@miss_count.to_s+' 次｜A x1/x2｜'+verification_mode_label,0)
    else
      bmp.draw_text(10,10,Graphics.width-20,28,@result_text+'｜C回到布陣｜B離開',1)
    end
  end

  def redraw_result_with_loot_v083
    return false if verification_mode!=:normal
    return false if @result_sprite==nil
    req=rpg_request_v081
    old=@result_sprite.bitmap;old.dispose if old!=nil && !old.disposed?
    @result_sprite.bitmap=Bitmap.new(510,PMD_AC::UI_RESULT_H_V086)
    @result_sprite.x=(Graphics.width-510)/2
    @result_sprite.y=(Graphics.height-PMD_AC::UI_RESULT_H_V086)/2-2
    @result_sprite.z=9999
    record=@battle_record_after_v079 || PMD_AC.battle_loop_state_v079
    attention=progression_attention_total_v077
    winner=nil
    if req!=nil && req[:kind]!=:stage
      rr=@rpg_reward_v081 || {:request=>req,:winner=>nil,:offer=>nil};winner=rr[:winner]
      PMD_AC.draw_rpg_result_v086(@result_sprite.bitmap,@result_text,@battle_reward_rows_v079||[],record,attention,rr)
    else
      sid=req!=nil ? req[:stage_id] : (@active_stage_id_v080||PMD_AC.current_stage_id_v080)
      sr=@stage_reward_v080 || {:stage_id=>sid,:winner=>nil,:offer=>nil,:clear_count=>PMD_AC.stage_clear_count_v080(sid)};winner=sr[:winner]
      PMD_AC.draw_stage_result_v086(@result_sprite.bitmap,@result_text,@battle_reward_rows_v079||[],record,attention,sr)
    end
    PMD_AC.draw_loot_summary_v083(@result_sprite.bitmap,@loot_reward_v083,winner)
    true
  end
end
