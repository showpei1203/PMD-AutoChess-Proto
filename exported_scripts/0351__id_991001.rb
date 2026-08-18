# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Supply UI Readability Hotfix v0.99.1
# 分類：玩家介面／補給背包／純顯示修正
#
# 【用途】
# 1. 放大 v0.99 補給背包所有主要文字，改善 RPG Maker VX 544×416 畫面可讀性。
# 2. 同步調整道具列、寶可夢列、招式列的高度與座標，避免放大後文字重疊。
# 3. 修正 v0.99 說明文字換行時，未先套用目標字級就計算文字寬度的問題。
# 4. 保持 v0.98 道具效果、Loot、Inventory 消耗與 v0.99 操作流程完全不變。
#
# 【主要設定項】
# SUPPLY_UI_FONT_*_V0991：標題、提示、道具、說明、隊伍、招式與狀態列字級。
# SUPPLY_UI_ITEM_ROW_H_V0991：左側 8 種道具列高。
# SUPPLY_UI_MOVE_ROW_H_V0991：招式選擇列高。
#
# 【機制規則】
# - 8 種道具仍一頁全部顯示，不增加道具捲動層。
# - 招式頁仍保留 v0.99 的 7 列可視量與既有捲動規則。
# - Party 仍固定顯示 3 隻；HP 仍來自 field_hp_v082。
# - 本腳本只覆寫 Sprite_PMDSupplyInventoryV099 的繪圖方法，不改 use_supply_v098。
#
# 【可調參數】
# 若日後要再放大，優先調整下方 FONT 常數；若超過目前版面，必須同步調整列高與座標。
# 不建議只提高 font.size 而不改列高，否則會造成文字互相覆蓋。
#
# 【事件／腳本呼叫】
# 與 v0.99 完全相同：PMD_AC.open_supply_inventory_v099
# 布陣階段：Alt 開啟；↑↓ 選擇；Enter/C 確認；B 返回；Alt 關閉。
#
# 【實際範例】
# PMD_AC.open_supply_inventory_v099
# # 開啟後，道具名稱採 18px、說明 16px、目標名稱 19px、招式名稱 17px。
#
# 【Verifier】
# NORMAL → S 一次 → SUPPLY_INVENTORY_V099 → Shift。
# 除原 v0.99 markers 外，會新增：
# SUPPLY_UI_READABILITY_V0991 pass=1
#
# 【注意】
# - 不修改 Item ID 6～13、掉落 Pool、Production Binding、Ability、AI、Damage、Energy。
# - 不修改 v0.99 Demo Seed 與背包資料。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
#==============================================================================

module PMD_AC
  SUPPLY_UI_READABILITY_VERSION_V0991='0.99.1'
  SUPPLY_UI_FONT_TITLE_V0991=27
  SUPPLY_UI_FONT_HINT_V0991=15
  SUPPLY_UI_FONT_ITEM_V0991=18
  SUPPLY_UI_FONT_COUNT_V0991=17
  SUPPLY_UI_FONT_DETAIL_TITLE_V0991=22
  SUPPLY_UI_FONT_META_V0991=16
  SUPPLY_UI_FONT_DESC_V0991=16
  SUPPLY_UI_FONT_SECTION_V0991=17
  SUPPLY_UI_FONT_PARTY_SUMMARY_V0991=16
  SUPPLY_UI_FONT_PARTY_HP_V0991=15
  SUPPLY_UI_FONT_TARGET_NAME_V0991=19
  SUPPLY_UI_FONT_TARGET_HP_V0991=17
  SUPPLY_UI_FONT_MOVE_V0991=17
  SUPPLY_UI_FONT_MOVE_INFO_V0991=14
  SUPPLY_UI_FONT_STATUS_V0991=16
  SUPPLY_UI_ITEM_ROW_H_V0991=36
  SUPPLY_UI_MOVE_ROW_H_V0991=34
end

class Sprite_PMDSupplyInventoryV099
  # v0.99 的 wrap 先用上一個 font.size 做 text_size，放大字後可能產生錯誤斷行。
  # v0.99.1 先套用本次 size，再依實際字寬斷行。
  def draw_wrapped_v099(x,y,w,text,size=16,color=nil,max_lines=4)
    s=text.to_s
    return if s.empty?
    bitmap.font.size=size
    bitmap.font.bold=false
    bitmap.font.color=color || Color.new(235,240,245)
    chars=s.split(//)
    line='';lines=[]
    chars.each do |ch|
      test=line+ch
      if bitmap.text_size(test).width>w && !line.empty?
        lines.push(line);line=ch
      else
        line=test
      end
    end
    lines.push(line) unless line.empty?
    lines=lines[0,max_lines]
    line_h=size+6
    lines.each_index{|i|draw_text_v099(x,y+i*line_h,w,line_h,lines[i],size,color)}
  end

  def draw_party_row_v099(inst,x,y,w,selected=false)
    bitmap.fill_rect(x,y,w,68,selected ? Color.new(70,90,120,190) : Color.new(28,36,48,220))
    name=PMD_AC.species_display_name_v047(inst.species_key)
    draw_text_v099(x+10,y+3,w-20,26,name+'  Lv'+inst.level.to_i.to_s,
      PMD_AC::SUPPLY_UI_FONT_TARGET_NAME_V0991,Color.new(250,250,250),0,true)
    hp=inst.field_hp_v082;mx=inst.field_maxhp_v082
    label=hp<=0 ? '倒下' : 'HP '+hp.to_i.to_s+' / '+mx.to_i.to_s
    draw_text_v099(x+10,y+29,w-20,24,label,
      PMD_AC::SUPPLY_UI_FONT_TARGET_HP_V0991,hp_color_v099(inst))
    bar_x=x+10;bar_y=y+56;bar_w=w-20
    bitmap.fill_rect(bar_x,bar_y,bar_w,7,Color.new(55,60,66))
    if hp>0
      fw=(bar_w*[hp.to_f/[mx,1].max.to_f,1.0].min).round
      bitmap.fill_rect(bar_x,bar_y,fw,7,Color.new(110,205,145)) if fw>0
    end
  end

  def refresh
    bmp=bitmap;bmp.clear
    bmp.fill_rect(8,8,Graphics.width-16,Graphics.height-16,Color.new(0,0,0,228))
    bmp.fill_rect(18,54,218,300,Color.new(18,24,32,230))
    bmp.fill_rect(244,54,282,300,Color.new(18,24,32,230))
    draw_text_v099(20,11,250,34,'補給背包',PMD_AC::SUPPLY_UI_FONT_TITLE_V0991,
      Color.new(255,255,255),0,true)
    draw_text_v099(264,16,256,27,'Alt 關閉｜Enter 使用｜B 返回',PMD_AC::SUPPLY_UI_FONT_HINT_V0991,
      Color.new(190,215,235),2)

    rows=item_rows_v099
    row_h=PMD_AC::SUPPLY_UI_ITEM_ROW_H_V0991
    rows.each_index do |i|
      row=rows[i];y=59+i*row_h
      selected=i==@item_index
      bmp.fill_rect(23,y,208,row_h-3,selected ? Color.new(70,90,120,190) : Color.new(26,33,42,215))
      c=row[:count].to_i>0 ? Color.new(242,242,242) : Color.new(115,125,135)
      draw_text_v099(31,y+3,151,row_h-7,row[:name],PMD_AC::SUPPLY_UI_FONT_ITEM_V0991,c,0,selected)
      draw_text_v099(181,y+3,43,row_h-7,'×'+row[:count].to_i.to_s,PMD_AC::SUPPLY_UI_FONT_COUNT_V0991,c,2,true)
    end

    row=current_item_row_v099;d=selected_item_data_v099
    if @mode==:items
      draw_item_detail_v099(row,d)
    elsif @mode==:targets
      draw_target_select_v099(row,d)
    else
      draw_move_select_v099(row,d)
    end

    bmp.fill_rect(18,362,508,38,Color.new(24,31,40,235))
    draw_text_v099(28,367,488,28,@status_text,PMD_AC::SUPPLY_UI_FONT_STATUS_V0991,
      Color.new(240,220,155),0,true)
  end

  def draw_item_detail_v099(row,d)
    return if row==nil || d==nil
    draw_text_v099(255,59,260,30,row[:name],PMD_AC::SUPPLY_UI_FONT_DETAIL_TITLE_V0991,
      Color.new(255,255,255),0,true)
    draw_text_v099(255,88,260,25,PMD_AC.supply_ui_kind_label_v099(d[:kind])+'｜持有 '+row[:count].to_i.to_s,
      PMD_AC::SUPPLY_UI_FONT_META_V0991,Color.new(180,220,245))
    draw_wrapped_v099(255,116,258,PMD_AC.supply_ui_description_v099(row[:id]),
      PMD_AC::SUPPLY_UI_FONT_DESC_V0991,Color.new(225,230,235),4)
    draw_text_v099(255,210,260,25,'目前隊伍',PMD_AC::SUPPLY_UI_FONT_SECTION_V0991,
      Color.new(190,220,245),0,true)
    list=party_rows_v099
    list.each_index do |i|
      inst=list[i];y=238+i*33
      name=PMD_AC.species_display_name_v047(inst.species_key)
      hp=inst.field_hp_v082;mx=inst.field_maxhp_v082
      draw_text_v099(260,y,145,25,name+' Lv'+inst.level.to_i.to_s,
        PMD_AC::SUPPLY_UI_FONT_PARTY_SUMMARY_V0991,Color.new(240,240,240))
      draw_text_v099(400,y,105,25,hp<=0 ? '倒下' : hp.to_i.to_s+'/'+mx.to_i.to_s,
        PMD_AC::SUPPLY_UI_FONT_PARTY_HP_V0991,hp_color_v099(inst),2)
    end
  end

  def draw_target_select_v099(row,d)
    draw_text_v099(255,59,260,30,'選擇使用目標',PMD_AC::SUPPLY_UI_FONT_DETAIL_TITLE_V0991,
      Color.new(255,255,255),0,true)
    draw_text_v099(255,88,260,25,row==nil ? '' : row[:name],PMD_AC::SUPPLY_UI_FONT_META_V0991,
      Color.new(190,220,245))
    list=party_rows_v099
    if list.empty?
      draw_text_v099(255,135,260,28,'目前 Party 沒有可用個體。',18,Color.new(190,150,150),1,true)
      return
    end
    list.each_index{|i|draw_party_row_v099(list[i],254,113+i*76,262,i==@party_index)}
  end

  def draw_move_select_v099(row,d)
    target=current_target_v099
    name=target==nil ? '－' : PMD_AC.species_display_name_v047(target.species_key)
    draw_text_v099(255,59,260,30,'選擇要提升的招式',PMD_AC::SUPPLY_UI_FONT_DETAIL_TITLE_V0991,
      Color.new(255,255,255),0,true)
    draw_text_v099(255,88,260,25,name+'｜'+(row==nil ? '' : row[:name]),PMD_AC::SUPPLY_UI_FONT_META_V0991,
      Color.new(190,220,245))
    moves=move_rows_v099
    adjust_move_scroll_v099
    max=PMD_AC::SUPPLY_UI_VISIBLE_MOVE_ROWS_V099
    row_h=PMD_AC::SUPPLY_UI_MOVE_ROW_H_V0991
    i=0
    while i<max
      idx=@move_scroll+i
      break if idx>=moves.size
      mv=moves[idx];y=114+i*row_h;sel=idx==@move_index
      bitmap.fill_rect(254,y,262,row_h-3,sel ? Color.new(70,90,120,190) : Color.new(27,34,43,220))
      text=PMD_AC.move_display_name_v047(mv)
      lv=target.respond_to?(:move_level_v045) ? target.move_level_v045(mv) : 1
      exp=target.respond_to?(:move_mastery_exp_v045) ? target.move_mastery_exp_v045(mv) : 0
      draw_text_v099(263,y+2,158,row_h-6,text,PMD_AC::SUPPLY_UI_FONT_MOVE_V0991,
        Color.new(245,245,245),0,sel)
      draw_text_v099(421,y+2,86,row_h-6,'Lv'+lv.to_i.to_s+'｜'+exp.to_i.to_s,
        PMD_AC::SUPPLY_UI_FONT_MOVE_INFO_V0991,Color.new(180,215,245),2)
      i+=1
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0991_start start unless method_defined?(:pmd_ac_v0991_start)
  alias pmd_ac_v0991_refresh_header refresh_header unless method_defined?(:pmd_ac_v0991_refresh_header)
  alias pmd_ac_v0991_verify_supply_ui_manifest_v099 verify_supply_ui_manifest_v099 unless method_defined?(:pmd_ac_v0991_verify_supply_ui_manifest_v099)

  def start
    pmd_ac_v0991_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.99 Battle Verification Log/,'PMD AutoChess Proto v0.99.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:supply_ui,'PATCH v0.99.1 readability=larger item=18 desc=16 target=19/17 move=17/14 status=16 rows=8/7 wrap_measure=target_font mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0991_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.1',1)
  end

  def verify_supply_ui_manifest_v099
    was_done=@verification_done[:v099_manifest]
    pmd_ac_v0991_verify_supply_ui_manifest_v099
    unless was_done || @verification_done[:v0991_readability]
      pass=PMD_AC::SUPPLY_UI_FONT_ITEM_V0991>=18 &&
           PMD_AC::SUPPLY_UI_FONT_DESC_V0991>=16 &&
           PMD_AC::SUPPLY_UI_FONT_TARGET_NAME_V0991>=19 &&
           PMD_AC::SUPPLY_UI_FONT_MOVE_V0991>=17 &&
           PMD_AC::SUPPLY_UI_VISIBLE_ITEM_ROWS_V099==8 &&
           PMD_AC::SUPPLY_UI_VISIBLE_MOVE_ROWS_V099==7
      log_verify_v099('SUPPLY_UI_READABILITY_V0991',pass,
        'item_font=18 desc_font=16 target_font=19/17 move_font=17/14 status_font=16 visible_items=8 visible_moves=7 wrap_measure=target_font mechanics_unchanged=1')
      @verification_done[:v0991_readability]=true
    end
  end
end
