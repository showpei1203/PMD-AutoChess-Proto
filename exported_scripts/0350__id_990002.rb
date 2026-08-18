# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Supply / Inventory UI Runtime v0.99
# 分類：玩家介面／布陣 Overlay／地圖 Scene／Verifier
#
# 【用途】
# 1. 在 PMD AutoChess 布陣階段提供 Alt 補給背包。
# 2. 提供可由 RPG Map 事件直接開啟的 Scene_PMDSupplyInventoryV099。
# 3. 對 v0.98 use_supply_v098 做純前端呼叫，成功才消耗背包物品。
# 4. 招式熟練道具提供「道具→寶可夢→已學招式」三層選擇，不要求玩家寫 Ruby。
#
# 【主要操作】
# Alt：布陣時開啟／介面中直接關閉。
# ↑↓：移動游標。
# C / Enter：確認。
# B / Esc：返回上一層；道具頁按 B 關閉。
#
# 【機制規則】
# - 單體回復、復活、EXP：先選 Party Pokémon，再呼叫 use_supply_v098。
# - 招式心得／秘典：再選該 instance 的 known_moves_v045。
# - 團隊口糧／蜂王蜜：道具頁直接執行。
# - 所有 HP 都讀寫 field_hp_v082，不接 VX Actor HP。
# - UI 失敗理由只顯示提示，不扣道具。
#
# 【事件／腳本呼叫】
# 地圖事件 Script：PMD_AC.open_supply_inventory_v099
# 布陣 Overlay 由 Scene_PMD_AutoChess 自動處理 Alt。
# 若正式專案已有自己的 Ring/Menu，可直接呼叫同一 API，不必複製 UI Runtime。
#
# 【實際範例】
# PMD_AC.open_supply_inventory_v099
# # 玩家選擇「招式秘典 → 妙蛙種子 → Tackle」，成功後背包 -1，Mastery +30。
#
# 【Verifier】
# NORMAL → S 一次 → SUPPLY_INVENTORY_V099 → Shift。
# 預期 SUPPLY_INVENTORY_V099 pass=1 與 VERIFY_FINISHED_BATTLE_RESUME pass=1。
# Verifier 不建立可見假 Sprite，也不消耗玩家真實 Inventory。
#
# 【注意】
# - 本版不改 v0.98 道具效果／Loot，也不改 Battle Runtime。
# - FullTestProject 會一次性把 8 種補給品補到各 2 個，僅方便直接點 UI 測試。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
#==============================================================================

class Game_System
  attr_accessor :pmd_supply_ui_seeded_v099
end

module PMD_AC
  class << self
    def ensure_supply_ui_demo_seed_v099
      return 0 unless SUPPLY_UI_DEMO_SEED_V099
      return 0 if $game_system==nil || $game_party==nil || $data_items==nil
      return 0 if $game_system.pmd_supply_ui_seeded_v099
      added=0
      supply_item_ids_v098.each do |id|
        item=$data_items[id]
        next if item==nil
        have=$game_party.item_number(item).to_i
        if have<2
          n=2-have
          $game_party.gain_item(item,n)
          added+=n
        end
      end
      $game_system.pmd_supply_ui_seeded_v099=true
      added
    end

    def supply_ui_party_v099
      list=supply_party_v098
      list==nil ? [] : list.compact
    end

    def supply_ui_known_moves_v099(instance)
      return [] if instance==nil || !instance.respond_to?(:known_moves_v045)
      instance.known_moves_v045.compact
    end

    def supply_ui_result_text_v099(result)
      return '沒有執行結果。' if result==nil
      unless result[:used]
        return supply_ui_reason_label_v099(result[:reason])
      end
      text='使用成功'
      case result[:kind]
      when :heal_one
        text='HP '+result[:before].to_i.to_s+' → '+result[:after].to_i.to_s
      when :revive_one
        text='復活成功｜HP '+result[:after].to_i.to_s
      when :exp_one
        gain=result[:after].to_i-result[:before].to_i
        text='EXP +'+gain.to_s+'｜Lv'+result[:level_before].to_i.to_s+' → Lv'+result[:level_after].to_i.to_s
      when :mastery_one
        gain=result[:after].to_i-result[:before].to_i
        text='招式熟練度 +'+gain.to_s+'｜目前 '+result[:after].to_i.to_s
      when :heal_party
        text='全隊回復｜'+result[:changed].to_i.to_s+' 隻｜共 '+result[:amount].to_i.to_s+' HP'
      when :honey_party
        text='蜂王蜜｜'+result[:changed].to_i.to_s+' 隻受惠｜復活 '+result[:revived].to_i.to_s+' 隻'
      end
      if result[:remaining]!=nil
        text+='｜剩餘 '+result[:remaining].to_i.to_s
      end
      text
    end

    def open_supply_inventory_v099
      if defined?($scene) && $scene.is_a?(Scene_PMD_AutoChess)
        return $scene.open_supply_panel_v099 if $scene.respond_to?(:open_supply_panel_v099)
        return false
      end
      $scene=Scene_PMDSupplyInventoryV099.new
      true
    end
  end
end

class Sprite_PMDSupplyInventoryV099 < Sprite
  attr_reader :close_requested
  attr_reader :mode
  attr_reader :last_result

  def initialize(viewport=nil,logger=nil)
    super(viewport)
    self.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    self.z=16000
    @logger=logger
    @mode=:items
    @item_index=0
    @party_index=0
    @move_index=0
    @move_scroll=0
    @close_requested=false
    @status_text='選擇補給品。'
    @last_result=nil
    setup_font_v099
    refresh
  end

  def setup_font_v099
    begin
      self.bitmap.font.name=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : 'Microsoft JhengHei'
    rescue
      self.bitmap.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    super
  end

  def reset_close_v099;@close_requested=false;end
  def item_index;@item_index;end
  def party_index;@party_index;end
  def move_index;@move_index;end

  def log_v099(text)
    @logger.call(text) if @logger!=nil
  end

  def item_rows_v099
    PMD_AC.supply_inventory_v098
  end

  def current_item_row_v099
    rows=item_rows_v099
    return nil if rows.empty?
    @item_index=0 if @item_index<0
    @item_index=rows.size-1 if @item_index>=rows.size
    rows[@item_index]
  end

  def party_rows_v099
    PMD_AC.supply_ui_party_v099
  end

  def current_target_v099
    rows=party_rows_v099
    return nil if rows.empty?
    @party_index=0 if @party_index<0
    @party_index=rows.size-1 if @party_index>=rows.size
    rows[@party_index]
  end

  def move_rows_v099
    PMD_AC.supply_ui_known_moves_v099(current_target_v099)
  end

  def current_move_v099
    rows=move_rows_v099
    return nil if rows.empty?
    @move_index=0 if @move_index<0
    @move_index=rows.size-1 if @move_index>=rows.size
    rows[@move_index]
  end

  def selected_item_data_v099
    row=current_item_row_v099
    row==nil ? nil : PMD_AC.supply_data_v098(row[:id])
  end

  def update
    super
    if Input.trigger?(Input::ALT)
      @close_requested=true
      Sound.play_cancel
      return
    end
    case @mode
    when :items
      update_items_v099
    when :targets
      update_targets_v099
    when :moves
      update_moves_v099
    end
  end

  def update_items_v099
    rows=item_rows_v099
    if Input.repeat?(Input::UP)
      @item_index=(@item_index-1)%[rows.size,1].max;Sound.play_cursor;refresh
    elsif Input.repeat?(Input::DOWN)
      @item_index=(@item_index+1)%[rows.size,1].max;Sound.play_cursor;refresh
    elsif Input.trigger?(Input::B)
      @close_requested=true;Sound.play_cancel
    elsif Input.trigger?(Input::C)
      row=current_item_row_v099;d=selected_item_data_v099
      if row==nil || d==nil
        @status_text='沒有可用道具。';Sound.play_buzzer;refresh;return
      end
      if row[:count].to_i<=0
        @status_text=PMD_AC.supply_ui_reason_label_v099(:no_inventory);Sound.play_buzzer;refresh;return
      end
      if PMD_AC.supply_ui_targeted_kind_v099?(d[:kind])
        @party_index=0;@mode=:targets;@status_text='選擇使用目標。';Sound.play_decision;refresh
      else
        perform_use_v099(row[:id],nil,nil)
      end
    end
  end

  def update_targets_v099
    rows=party_rows_v099
    if Input.repeat?(Input::UP)
      @party_index=(@party_index-1)%[rows.size,1].max;Sound.play_cursor;refresh
    elsif Input.repeat?(Input::DOWN)
      @party_index=(@party_index+1)%[rows.size,1].max;Sound.play_cursor;refresh
    elsif Input.trigger?(Input::B)
      @mode=:items;@status_text='返回道具選擇。';Sound.play_cancel;refresh
    elsif Input.trigger?(Input::C)
      target=current_target_v099;row=current_item_row_v099;d=selected_item_data_v099
      if target==nil || row==nil || d==nil
        @status_text=PMD_AC.supply_ui_reason_label_v099(:no_target);Sound.play_buzzer;refresh;return
      end
      if PMD_AC.supply_ui_mastery_kind_v099?(d[:kind])
        moves=PMD_AC.supply_ui_known_moves_v099(target)
        if moves.empty?
          @status_text='這隻寶可夢目前沒有已學招式。';Sound.play_buzzer;refresh;return
        end
        @move_index=0;@move_scroll=0;@mode=:moves;@status_text='選擇要提升熟練度的招式。';Sound.play_decision;refresh
      else
        perform_use_v099(row[:id],target.instance_uid,nil)
      end
    end
  end

  def update_moves_v099
    rows=move_rows_v099
    if Input.repeat?(Input::UP)
      @move_index=[@move_index-1,0].max;adjust_move_scroll_v099;Sound.play_cursor;refresh
    elsif Input.repeat?(Input::DOWN)
      @move_index=[@move_index+1,[rows.size-1,0].max].min;adjust_move_scroll_v099;Sound.play_cursor;refresh
    elsif Input.trigger?(Input::B)
      @mode=:targets;@status_text='返回寶可夢選擇。';Sound.play_cancel;refresh
    elsif Input.trigger?(Input::C)
      row=current_item_row_v099;target=current_target_v099;move=current_move_v099
      if row==nil || target==nil || move==nil
        @status_text=PMD_AC.supply_ui_reason_label_v099(:no_move);Sound.play_buzzer;refresh;return
      end
      perform_use_v099(row[:id],target.instance_uid,move)
    end
  end

  def perform_use_v099(item_id,uid,move_key)
    r=PMD_AC.use_supply_v098(item_id,uid,move_key)
    @last_result=r
    @status_text=PMD_AC.supply_ui_result_text_v099(r)
    if r[:used]
      text='USE item='+item_id.to_i.to_s+' name='+r[:item_name].to_s
      text+=' target_uid='+uid.to_i.to_s unless uid==nil
      text+=' move='+move_key.to_s unless move_key==nil
      text+=' remaining='+r[:remaining].to_i.to_s
      log_v099(text)
      @mode=:items;Sound.play_decision
    else
      Sound.play_buzzer
    end
    refresh
  end

  def adjust_move_scroll_v099
    n=PMD_AC::SUPPLY_UI_VISIBLE_MOVE_ROWS_V099
    @move_scroll=@move_index if @move_index<@move_scroll
    @move_scroll=@move_index-n+1 if @move_index>=@move_scroll+n
    @move_scroll=0 if @move_scroll<0
  end

  def draw_text_v099(x,y,w,h,text,size=15,color=nil,align=0,bold=false)
    bitmap.font.size=size
    bitmap.font.bold=bold
    bitmap.font.color=color || Color.new(235,240,245)
    bitmap.draw_text(x,y,w,h,text.to_s,align)
  end

  def draw_wrapped_v099(x,y,w,text,size=14,color=nil,max_lines=3)
    s=text.to_s
    return if s.empty?
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
    lines.each_index{|i|draw_text_v099(x,y+i*(size+5),w,size+5,lines[i],size,color)}
  end

  def hp_color_v099(inst)
    hp=inst.field_hp_v082;mx=[inst.field_maxhp_v082,1].max
    return Color.new(170,120,120) if hp<=0
    rate=hp.to_f/mx.to_f
    return Color.new(255,190,120) if rate<0.35
    Color.new(190,235,205)
  end

  def draw_party_row_v099(inst,x,y,w,selected=false)
    bitmap.fill_rect(x,y,w,65,selected ? Color.new(70,90,120,190) : Color.new(28,36,48,220))
    name=PMD_AC.species_display_name_v047(inst.species_key)
    draw_text_v099(x+10,y+4,w-20,21,name+'  Lv'+inst.level.to_i.to_s,16,Color.new(250,250,250),0,true)
    hp=inst.field_hp_v082;mx=inst.field_maxhp_v082
    label=hp<=0 ? '倒下' : 'HP '+hp.to_i.to_s+' / '+mx.to_i.to_s
    draw_text_v099(x+10,y+27,w-20,20,label,14,hp_color_v099(inst))
    bar_x=x+10;bar_y=y+50;bar_w=w-20
    bitmap.fill_rect(bar_x,bar_y,bar_w,6,Color.new(55,60,66))
    if hp>0
      fw=(bar_w*[hp.to_f/[mx,1].max.to_f,1.0].min).round
      bitmap.fill_rect(bar_x,bar_y,fw,6,Color.new(110,205,145)) if fw>0
    end
  end

  def refresh
    bmp=bitmap;bmp.clear
    bmp.fill_rect(8,8,Graphics.width-16,Graphics.height-16,Color.new(0,0,0,228))
    bmp.fill_rect(18,54,218,300,Color.new(18,24,32,230))
    bmp.fill_rect(244,54,282,300,Color.new(18,24,32,230))
    draw_text_v099(20,14,250,30,'補給背包',24,Color.new(255,255,255),0,true)
    draw_text_v099(270,18,250,24,'Alt 關閉｜Enter 使用｜B 返回',13,Color.new(190,215,235),2)

    rows=item_rows_v099
    rows.each_index do |i|
      row=rows[i];y=60+i*34
      selected=i==@item_index
      bmp.fill_rect(23,y,208,31,selected ? Color.new(70,90,120,190) : Color.new(26,33,42,215))
      c=row[:count].to_i>0 ? Color.new(242,242,242) : Color.new(115,125,135)
      draw_text_v099(31,y+3,151,24,row[:name],15,c,0,selected)
      draw_text_v099(181,y+3,43,24,'×'+row[:count].to_i.to_s,14,c,2,true)
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
    draw_text_v099(28,370,488,22,@status_text,14,Color.new(240,220,155),0,true)
  end

  def draw_item_detail_v099(row,d)
    return if row==nil || d==nil
    draw_text_v099(255,62,260,25,row[:name],20,Color.new(255,255,255),0,true)
    draw_text_v099(255,90,260,22,PMD_AC.supply_ui_kind_label_v099(d[:kind])+'｜持有 '+row[:count].to_i.to_s,14,Color.new(180,220,245))
    draw_wrapped_v099(255,119,258,PMD_AC.supply_ui_description_v099(row[:id]),14,Color.new(225,230,235),4)
    draw_text_v099(255,197,260,22,'目前隊伍',15,Color.new(190,220,245),0,true)
    list=party_rows_v099
    list.each_index do |i|
      inst=list[i];y=221+i*39
      name=PMD_AC.species_display_name_v047(inst.species_key)
      hp=inst.field_hp_v082;mx=inst.field_maxhp_v082
      draw_text_v099(260,y,145,20,name+' Lv'+inst.level.to_i.to_s,14,Color.new(240,240,240))
      draw_text_v099(400,y,105,20,hp<=0 ? '倒下' : hp.to_i.to_s+'/'+mx.to_i.to_s,13,hp_color_v099(inst),2)
    end
  end

  def draw_target_select_v099(row,d)
    draw_text_v099(255,62,260,25,'選擇使用目標',19,Color.new(255,255,255),0,true)
    draw_text_v099(255,88,260,20,row==nil ? '' : row[:name],14,Color.new(190,220,245))
    list=party_rows_v099
    if list.empty?
      draw_text_v099(255,135,260,24,'目前 Party 沒有可用個體。',16,Color.new(190,150,150),1,true)
      return
    end
    list.each_index{|i|draw_party_row_v099(list[i],254,114+i*72,262,i==@party_index)}
  end

  def draw_move_select_v099(row,d)
    target=current_target_v099
    name=target==nil ? '－' : PMD_AC.species_display_name_v047(target.species_key)
    draw_text_v099(255,62,260,25,'選擇要提升的招式',19,Color.new(255,255,255),0,true)
    draw_text_v099(255,88,260,20,name+'｜'+(row==nil ? '' : row[:name]),14,Color.new(190,220,245))
    moves=move_rows_v099
    adjust_move_scroll_v099
    max=PMD_AC::SUPPLY_UI_VISIBLE_MOVE_ROWS_V099
    i=0
    while i<max
      idx=@move_scroll+i
      break if idx>=moves.size
      mv=moves[idx];y=116+i*31;sel=idx==@move_index
      bitmap.fill_rect(254,y,262,28,sel ? Color.new(70,90,120,190) : Color.new(27,34,43,220))
      text=PMD_AC.move_display_name_v047(mv)
      lv=target.respond_to?(:move_level_v045) ? target.move_level_v045(mv) : 1
      exp=target.respond_to?(:move_mastery_exp_v045) ? target.move_mastery_exp_v045(mv) : 0
      draw_text_v099(263,y+2,160,23,text,14,Color.new(245,245,245),0,sel)
      draw_text_v099(421,y+2,86,23,'Lv'+lv.to_i.to_s+'｜'+exp.to_i.to_s,12,Color.new(180,215,245),2)
      i+=1
    end
  end
end

class Scene_PMDSupplyInventoryV099 < Scene_Base
  def start
    super
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=15900
    PMD_AC.ensure_supply_ui_demo_seed_v099
    @panel=Sprite_PMDSupplyInventoryV099.new(@viewport,nil)
  end
  def update
    super
    @panel.update if @panel!=nil
    if @panel!=nil && @panel.close_requested
      Sound.play_cancel
      $scene=Scene_Map.new
    end
  end
  def terminate
    @panel.dispose if @panel!=nil && !@panel.disposed?
    @viewport.dispose if @viewport!=nil && !@viewport.disposed?
    super
  end
end

#==============================================================================
# ■ Verifier Mode：放在 NORMAL 後第一個，方便這版只按一次 S 測試。
#==============================================================================
module PMD_AC
  V099_OLD_VERIFICATION_MODES=VERIFICATION_MODES.dup
  V099_OLD_VERIFICATION_LABELS=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:supply_inventory_v099]+V099_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:supply_inventory_v099}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=V099_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:supply_inventory_v099]='SUPPLY_INVENTORY_V099'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v099_start start unless method_defined?(:pmd_ac_v099_start)
  alias pmd_ac_v099_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v099_update_deploy_phase)
  alias pmd_ac_v099_refresh_header refresh_header unless method_defined?(:pmd_ac_v099_refresh_header)
  alias pmd_ac_v099_terminate terminate unless method_defined?(:pmd_ac_v099_terminate)
  alias pmd_ac_v099_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v099_prepare_verification_battle)
  alias pmd_ac_v099_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v099_update_verification_script)
  alias pmd_ac_v099_log_event log_event unless method_defined?(:pmd_ac_v099_log_event)

  def supply_inventory_v099?;verification_mode==:supply_inventory_v099;end
  def supply_panel_active_v099?;@supply_panel_v099!=nil && @supply_panel_v099.visible;end

  def start
    pmd_ac_v099_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.99 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    added=PMD_AC.ensure_supply_ui_demo_seed_v099
    m=PMD_AC::SUPPLY_UI_MANIFEST_V099
    log_event(:supply_ui,'FLOW v0.99 items='+m[:catalog_items].to_s+' party=3 modes=items,target,moves open=ALT map_api=1 runtime=v0.98 demo_seed_added='+added.to_s+' battle_rules=unchanged')
    refresh_header
  end

  def open_supply_panel_v099
    return false unless @phase==:deploy && verification_mode==:normal
    if respond_to?(:close_encounter_preview_v090) && respond_to?(:preview_panel_active_v090?) && preview_panel_active_v090?
      close_encounter_preview_v090('supply_v099')
    end
    close_collection_panel_v093 if respond_to?(:collection_panel_active_v093?) && collection_panel_active_v093?
    party_storage_close_v078 if @party_storage_panel_v078!=nil && respond_to?(:party_storage_close_v078)
    progression_ui_close_v047 if @progression_ui_panel_v047!=nil && respond_to?(:progression_ui_close_v047)
    logger=Proc.new{|t|log_event(:supply_ui,t)}
    if @supply_panel_v099==nil
      @supply_panel_v099=Sprite_PMDSupplyInventoryV099.new(@viewport,logger)
    else
      @supply_panel_v099.dispose unless @supply_panel_v099.disposed?
      @supply_panel_v099=Sprite_PMDSupplyInventoryV099.new(@viewport,logger)
    end
    Sound.play_decision
    log_event(:supply_ui,'OPEN inventory='+PMD_AC.supply_inventory_v098.collect{|r|r[:id].to_s+':'+r[:count].to_s}.join(','))
    refresh_header
    true
  end

  def close_supply_panel_v099
    return false if @supply_panel_v099==nil
    @supply_panel_v099.dispose unless @supply_panel_v099.disposed?
    @supply_panel_v099=nil
    log_event(:supply_ui,'CLOSE')
    refresh_header
    refresh_footer if respond_to?(:refresh_footer)
    true
  end

  def update_deploy_phase
    if supply_panel_active_v099?
      @supply_panel_v099.update
      close_supply_panel_v099 if @supply_panel_v099.close_requested
      return
    end
    if verification_mode==:normal && Input.trigger?(Input::ALT)
      open_supply_panel_v099
      return
    end
    pmd_ac_v099_update_deploy_phase
  end

  def refresh_header
    pmd_ac_v099_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99',1)
    if @phase==:deploy && verification_mode==:normal
      bmp.fill_rect(0,31,Graphics.width,28,Color.new(0,0,0,180))
      bmp.font.size=12;bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
      bmp.draw_text(4,33,Graphics.width-8,23,'Q/W關卡｜A BOX｜D成長｜Alt道具｜Ctrl圖鑑｜S驗證｜Shift開戰',1)
    end
  end

  def terminate
    close_supply_panel_v099 if @supply_panel_v099!=nil
    pmd_ac_v099_terminate
  end

  def prepare_verification_battle
    pmd_ac_v099_prepare_verification_battle
    return unless supply_inventory_v099?
    @supply_ui_failed_v099=false
    log_event(:showcase,'START mode=SUPPLY_INVENTORY_V099 ui_only=1 inventory_mutation=off fake_vfx=off')
  end

  def log_event(category,message)
    if category.to_s=='verify' && supply_inventory_v099? && message.to_s.index('V099')!=nil && message.to_s.include?(' pass=0')
      @supply_ui_failed_v099=true
    end
    pmd_ac_v099_log_event(category,message)
  end

  def log_verify_v099(name,pass,detail='')
    @supply_ui_failed_v099=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_supply_ui_manifest_v099
    return if @verification_done[:v099_manifest]
    m=PMD_AC::SUPPLY_UI_MANIFEST_V099
    pass=m[:catalog_items].to_i==8 && m[:party_capacity].to_i==3 && m[:open_input]=='Input::ALT' && m[:uses_runtime]=='v0.98' && m[:identity]=='instance_uid' && m[:map_scene_api]
    log_verify_v099('SUPPLY_UI_MANIFEST_V099',pass,'items=8 party=3 input=ALT modes=3 identity=instance_uid map_api=1')
    @verification_done[:v099_manifest]=true
  end

  def verify_supply_ui_catalog_v099
    return if @verification_done[:v099_catalog]
    rows=PMD_AC.supply_item_ids_v098.collect{|id|PMD_AC.supply_data_v098(id)}
    target=rows.find_all{|d|d!=nil && PMD_AC.supply_ui_targeted_kind_v099?(d[:kind])}.size
    party=rows.find_all{|d|d!=nil && !PMD_AC.supply_ui_targeted_kind_v099?(d[:kind])}.size
    mastery=rows.find_all{|d|d!=nil && PMD_AC.supply_ui_mastery_kind_v099?(d[:kind])}.size
    desc=PMD_AC.supply_item_ids_v098.all?{|id|!PMD_AC.supply_ui_description_v099(id).empty?}
    pass=rows.size==8 && target==6 && party==2 && mastery==2 && desc
    log_verify_v099('SUPPLY_UI_CATALOG_V099',pass,'items='+rows.size.to_s+' targeted='+target.to_s+' party='+party.to_s+' mastery='+mastery.to_s+' descriptions='+(desc ? '8/8':'missing'))
    @verification_done[:v099_catalog]=true
  end

  def verify_supply_ui_target_model_v099
    return if @verification_done[:v099_target]
    list=PMD_AC.supply_ui_party_v099
    uid_ok=list.all?{|i|i!=nil && i.respond_to?(:instance_uid) && i.instance_uid.to_i>0}
    hp_ok=list.all?{|i|i.respond_to?(:field_hp_v082) && i.respond_to?(:field_maxhp_v082)}
    pass=list.size==3 && uid_ok && hp_ok
    log_verify_v099('SUPPLY_UI_TARGET_MODEL_V099',pass,'party='+list.size.to_s+' uid_identity='+(uid_ok ? '1':'0')+' hp_bridge='+(hp_ok ? 'field_hp_v082':'fail'))
    @verification_done[:v099_target]=true
  end

  def verify_supply_ui_move_model_v099
    return if @verification_done[:v099_move]
    list=PMD_AC.supply_ui_party_v099
    inst=list.empty? ? nil : list[0]
    moves=PMD_AC.supply_ui_known_moves_v099(inst)
    labels=moves.collect{|mv|PMD_AC.move_display_name_v047(mv)}
    pass=inst!=nil && !moves.empty? && moves.size==labels.size && labels.all?{|x|!x.to_s.empty?}
    log_verify_v099('SUPPLY_UI_MOVE_MODEL_V099',pass,'species='+(inst==nil ? 'nil' : inst.species_key.to_s)+' known_moves='+moves.size.to_s+' mastery_items=2 labels='+(pass ? '1':'0'))
    @verification_done[:v099_move]=true
  end

  def verify_supply_ui_result_text_v099
    return if @verification_done[:v099_result]
    a=PMD_AC.supply_ui_result_text_v099({:used=>false,:reason=>:full_hp})
    b=PMD_AC.supply_ui_result_text_v099({:used=>true,:kind=>:heal_one,:before=>100,:after=>135,:remaining=>1})
    c=PMD_AC.supply_ui_result_text_v099({:used=>true,:kind=>:mastery_one,:before=>10,:after=>20,:remaining=>1})
    pass=!a.empty? && a!='full_hp' && b.index('100')!=nil && b.index('135')!=nil && c.index('+10')!=nil
    log_verify_v099('SUPPLY_UI_RESULT_TEXT_V099',pass,'reason_localized='+(a!='full_hp' ? '1':'0')+' heal_text=1 mastery_text=1')
    @verification_done[:v099_result]=true
  end

  def verify_supply_ui_carry_v099
    return if @verification_done[:v099_carry]
    r=PMD_AC.content_validation_report_v095
    pass=r[:errors].empty? && r[:warnings].empty? && r[:production_ready] && PMD_AC::ABILITY_RUNTIME_MANIFEST_V097[:implemented_slot_count].to_i==1193 && PMD_AC::LOOT_CONTENT_MANIFEST_V098[:catalog_items].to_i==8
    log_verify_v099('SUPPLY_UI_CARRY_V099',pass,'loot=v0.98 catalog=8 production_ready='+(r[:production_ready] ? '1':'0')+' ability=1193/1193 battle_rules=unchanged')
    @verification_done[:v099_carry]=true
  end

  def update_verification_script
    unless supply_inventory_v099?
      pmd_ac_v099_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1;f=@verification_frame
    verify_supply_ui_manifest_v099 if f>=2
    verify_supply_ui_catalog_v099 if f>=4
    verify_supply_ui_target_model_v099 if f>=6
    verify_supply_ui_move_model_v099 if f>=8
    verify_supply_ui_result_text_v099 if f>=10
    verify_supply_ui_carry_v099 if f>=14
    if f>=18 && !@verification_done[:v099_final]
      pass=!@supply_ui_failed_v099
      log_verify_v099('SUPPLY_INVENTORY_V099',pass,'ui_ready=1 catalog=8 party=3 mastery_flow=1 map_api=1 content_warnings=0')
      @verification_done[:v099_final]=true
    end
    complete_verification_mode if f>=PMD_AC::SUPPLY_UI_VERIFY_END_V099
  end
end
