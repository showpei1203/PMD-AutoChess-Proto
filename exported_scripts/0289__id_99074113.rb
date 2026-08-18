#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.78.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PARTY_STORAGE_TITLE_FONT_V0781 / PARTY_STORAGE_SUB_FONT_V0781 / PARTY_STORAGE_SECTION_FONT_V0781 / PARTY_CARD_NAME_FONT_V0781
# - PARTY_CARD_LEVEL_FONT_V0781 / PARTY_CARD_MOVES_FONT_V0781 / PARTY_CARD_MARK_FONT_V0781 / BOX_ROW_FONT_V0781
# - PARTY_STORAGE_HINT_FONT_V0781 / PARTY_STORAGE_FOOTER_FONT_V0781 / PARTY_STORAGE_BOX_ROW_H_V0781 / PARTY_STORAGE_VISIBLE_ROWS_V0781
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ensure_box_scroll_v078 / draw_party_card_v078 / draw_box_row_v078 / refresh
# - start / refresh_header
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.78.1
# Party / BOX manager readability polish
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Enlarges the Party / BOX manager fonts and row heights for readability.
# No gameplay / storage logic changes.
#==============================================================================
module PMD_AC
  PARTY_STORAGE_TITLE_FONT_V0781 = 24
  PARTY_STORAGE_SUB_FONT_V0781   = 14
  PARTY_STORAGE_SECTION_FONT_V0781 = 17
  PARTY_CARD_NAME_FONT_V0781 = 17
  PARTY_CARD_LEVEL_FONT_V0781 = 13
  PARTY_CARD_MOVES_FONT_V0781 = 12
  PARTY_CARD_MARK_FONT_V0781  = 12
  BOX_ROW_FONT_V0781 = 15
  PARTY_STORAGE_HINT_FONT_V0781 = 13
  PARTY_STORAGE_FOOTER_FONT_V0781 = 13
  PARTY_STORAGE_BOX_ROW_H_V0781 = 32
  PARTY_STORAGE_VISIBLE_ROWS_V0781 = 8
end

class Sprite_PMDPartyStoragePanelV078
  def ensure_box_scroll_v078
    rows=PMD_AC::PARTY_STORAGE_VISIBLE_ROWS_V0781
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
    b.font.bold=true
    b.font.size=PMD_AC::PARTY_CARD_NAME_FONT_V0781
    b.font.color=Color.new(245,245,245)
    label=(index+1).to_s+'. '+species_name_v078(instance)
    b.draw_text(x+8,y+2,w-16,24,label,0)
    b.font.bold=false
    b.font.size=PMD_AC::PARTY_CARD_LEVEL_FONT_V0781
    b.font.color=Color.new(175,210,240)
    if instance!=nil
      b.draw_text(x+10,y+27,w-20,20,'Lv'+instance.level.to_s+'  EXP '+instance.exp.to_s,0)
      moves=instance.respond_to?(:battle_moves_v046) ? instance.battle_moves_v046 : instance.active_moves_v045
      names=moves.collect{|mv|move_name_v078(mv)}
      b.font.size=PMD_AC::PARTY_CARD_MOVES_FONT_V0781
      b.font.color=Color.new(190,200,210)
      b.draw_text(x+10,y+47,w-20,18,names.join(' / '),0)
    end
    if marked
      b.font.size=PMD_AC::PARTY_CARD_MARK_FONT_V0781
      b.font.color=Color.new(255,225,130)
      b.draw_text(x+w-74,y+4,66,18,'交換中',2)
    end
  end

  def draw_box_row_v078(b,x,y,w,instance,index)
    selected=(@focus==:box && @box_cursor==index)
    b.fill_rect(x,y,w,PMD_AC::PARTY_STORAGE_BOX_ROW_H_V0781,
      selected ? Color.new(68,92,124,235) : Color.new(25,32,42,225))
    b.font.size=PMD_AC::BOX_ROW_FONT_V0781
    b.font.bold=selected
    b.font.color=Color.new(235,238,242)
    if instance==nil
      b.draw_text(x+8,y+4,w-16,22,'－',0)
    else
      text=(index+1).to_s.rjust(2,'0')+'  '+species_name_v078(instance)+'  Lv'+instance.level.to_s
      b.draw_text(x+8,y+4,w-16,22,text,0)
    end
    b.font.bold=false
  end

  def refresh
    b=self.bitmap
    b.clear
    setup_font_v078
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(7,11,17,248))
    b.fill_rect(10,10,Graphics.width-20,Graphics.height-20,Color.new(18,25,35,248))
    b.font.bold=true
    b.font.size=PMD_AC::PARTY_STORAGE_TITLE_FONT_V0781
    b.font.color=Color.new(255,255,255)
    b.draw_text(18,14,300,30,'隊伍 / BOX 編成',0)
    b.font.bold=false
    b.font.size=PMD_AC::PARTY_STORAGE_SUB_FONT_V0781
    b.font.color=Color.new(165,185,205)
    box=PMD_AC.pokemon_storage_boxes_v045[@box_index] || []
    b.draw_text(318,18,210,24,'BOX '+(@box_index+1).to_s.rjust(2,'0')+
      ' / '+PMD_AC::STORAGE_BOX_COUNT_V045.to_s+'  '+box.size.to_s+'/'+PMD_AC::STORAGE_BOX_CAPACITY_V045.to_s,2)

    b.font.size=PMD_AC::PARTY_STORAGE_SECTION_FONT_V0781
    b.font.bold=true
    b.font.color=Color.new(225,235,245)
    b.draw_text(20,56,190,24,'出戰隊伍 3 隻',0)
    b.draw_text(230,56,294,24,'寶可夢倉庫',0)
    b.font.bold=false

    party=party_instances
    for i in 0...PMD_AC::PARTY_CAPACITY_V045
      draw_party_card_v078(b,20,84+i*78,190,68,party[i],i)
    end

    a=box_instances
    rows=PMD_AC::PARTY_STORAGE_VISIBLE_ROWS_V0781
    for row in 0...rows
      idx=@box_scroll+row
      inst=idx<a.size ? a[idx] : nil
      draw_box_row_v078(b,230,84+row*32,294,inst,idx)
    end

    b.fill_rect(20,340,504,36,Color.new(25,34,46,230))
    b.font.size=PMD_AC::PARTY_STORAGE_HINT_FONT_V0781
    b.font.color=@selected_party_slot==nil ? Color.new(155,175,195) : Color.new(255,220,125)
    hint=@selected_party_slot==nil ?
      '先在左側選一個出戰槽，再到 BOX 選擇替換寶可夢。' :
      '已選出戰槽 '+(@selected_party_slot+1).to_s+'，到右側 BOX 按 C 完成交換。'
    b.draw_text(28,348,488,22,hint,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,225))
    b.font.size=PMD_AC::PARTY_STORAGE_FOOTER_FONT_V0781
    b.font.color=Color.new(175,220,255)
    b.draw_text(8,389,528,20,'←→ 區域｜↑↓ 選擇｜C 標記/交換｜Q/W 換 BOX｜B 關閉',1)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0781_start start unless method_defined?(:pmd_ac_v0781_start)
  alias pmd_ac_v0781_refresh_header refresh_header unless method_defined?(:pmd_ac_v0781_refresh_header)

  def start
    pmd_ac_v0781_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.78.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:party_storage,
      'PATCH v0.78.1 manager_font_scale=up title=24 section=17 party_name=17 box_row=15 hint=13 footer=13 rows=8 logic_unchanged=1')
  end

  def refresh_header
    pmd_ac_v0781_refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    return if bmp==nil
    # only swap the version string while preserving v0.78 layout
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.78.1',1)
    bmp.font.size=13
    bmp.font.bold=false
    bmp.font.color=Color.new(210,220,230)
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
end
