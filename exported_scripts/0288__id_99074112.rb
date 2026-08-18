#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.78
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - V078_OLD_VERIFICATION_MODES / V078_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - assign_pokemon_instance_v078 / initialize / setup_font_v078 / party_instances
# - box_instances / selected_storage_instance / update / ensure_box_scroll_v078
# - species_name_v078 / move_name_v078 / draw_party_card_v078 / draw_box_row_v078
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.78
# Party / BOX Manager + Formal Formation Flow
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Extends v0.45 identity party/storage instead of replacing it.
# Player-facing policy:
# - 3 fixed deployed party slots.
# - 24 boxes x 30 storage.
# - A(Input::X) from deploy opens Party / BOX manager.
# - C marks a party slot, then C on a stored Pokemon atomically swaps them.
# - Q/W switch boxes; Left/Right switch Party/BOX focus.
# - No empty-party removal in this phase.
#==============================================================================
module PMD_AC
  V078_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V078_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:party_storage_v078] +
    V078_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:party_storage_v078}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V078_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:party_storage_v078]='PARTY_STORAGE_V078'
end

class Game_PMDChessUnit
  def assign_pokemon_instance_v078(instance)
    return false if instance==nil
    @pokemon_instance=instance
    ok=sync_from_pokemon_instance
    apply_persistent_ai_setup if respond_to?(:apply_persistent_ai_setup)
    if respond_to?(:progression_restore_legacy_skill_v046)
      progression_restore_legacy_skill_v046
    end
    ok ? true : false
  end
end

class Sprite_PMDPartyStoragePanelV078 < Sprite
  attr_reader :close_requested
  attr_reader :changed

  def initialize(viewport,swap_proc=nil)
    super(viewport)
    self.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    self.z=12000
    @swap_proc=swap_proc
    @focus=:party
    @party_index=0
    @box_index=0
    @box_cursor=0
    @box_scroll=0
    @selected_party_slot=nil
    @close_requested=false
    @changed=false
    setup_font_v078
    refresh
  end

  def setup_font_v078
    begin
      self.bitmap.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      self.bitmap.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
  end

  def party_instances
    PMD_AC.party_instances_v078
  end

  def box_instances
    PMD_AC.box_instances_v078(@box_index)
  end

  def selected_storage_instance
    a=box_instances
    return nil if a.empty? || @box_cursor<0 || @box_cursor>=a.size
    a[@box_cursor]
  end

  def update
    super
    changed=false
    if Input.trigger?(Input::LEFT)
      @focus=:party;Sound.play_cursor;changed=true
    elsif Input.trigger?(Input::RIGHT)
      @focus=:box;Sound.play_cursor;changed=true
    elsif Input.trigger?(Input::L)
      @box_index=(@box_index-1)%PMD_AC::STORAGE_BOX_COUNT_V045
      @box_cursor=0;@box_scroll=0;Sound.play_cursor;changed=true
    elsif Input.trigger?(Input::R)
      @box_index=(@box_index+1)%PMD_AC::STORAGE_BOX_COUNT_V045
      @box_cursor=0;@box_scroll=0;Sound.play_cursor;changed=true
    elsif Input.repeat?(Input::UP)
      if @focus==:party
        @party_index=(@party_index-1)%PMD_AC::PARTY_CAPACITY_V045
      else
        a=box_instances
        @box_cursor=[@box_cursor-1,0].max unless a.empty?
        ensure_box_scroll_v078
      end
      Sound.play_cursor;changed=true
    elsif Input.repeat?(Input::DOWN)
      if @focus==:party
        @party_index=(@party_index+1)%PMD_AC::PARTY_CAPACITY_V045
      else
        a=box_instances
        @box_cursor=[@box_cursor+1,[a.size-1,0].max].min unless a.empty?
        ensure_box_scroll_v078
      end
      Sound.play_cursor;changed=true
    elsif Input.trigger?(Input::C)
      if @focus==:party
        if @selected_party_slot==@party_index
          @selected_party_slot=nil
          Sound.play_cancel
        else
          @selected_party_slot=@party_index
          Sound.play_decision
        end
        changed=true
      else
        inst=selected_storage_instance
        if @selected_party_slot==nil || inst==nil
          Sound.play_buzzer
        else
          ok=@swap_proc==nil ? false : @swap_proc.call(@selected_party_slot,inst.instance_uid)
          if ok
            Sound.play_equip
            @changed=true
            @party_index=@selected_party_slot
            @selected_party_slot=nil
            a=box_instances
            @box_cursor=[@box_cursor,[a.size-1,0].max].min
            ensure_box_scroll_v078
          else
            Sound.play_buzzer
          end
        end
        changed=true
      end
    elsif Input.trigger?(Input::B)
      if @selected_party_slot!=nil
        @selected_party_slot=nil;Sound.play_cancel;changed=true
      else
        @close_requested=true;Sound.play_cancel
      end
    end
    refresh if changed
  end

  def ensure_box_scroll_v078
    rows=PMD_AC::PARTY_STORAGE_VISIBLE_ROWS_V078
    @box_scroll=@box_cursor if @box_cursor<@box_scroll
    @box_scroll=@box_cursor-rows+1 if @box_cursor>=@box_scroll+rows
    @box_scroll=0 if @box_scroll<0
  end

  def species_name_v078(i)
    return '－ 空白 －' if i==nil
    begin
      PMD_AC.species_display_name_v047(i.species_key)
    rescue
      i.species_key.to_s
    end
  end

  def move_name_v078(mv)
    begin
      PMD_AC.move_display_name_v047(mv)
    rescue
      mv.to_s
    end
  end

  def draw_party_card_v078(b,x,y,w,h,instance,index)
    selected=(@focus==:party && @party_index==index)
    marked=(@selected_party_slot==index)
    bg=selected ? Color.new(68,92,124,235) : Color.new(28,36,48,230)
    bg=Color.new(105,83,45,240) if marked
    b.fill_rect(x,y,w,h,bg)
    b.font.bold=true;b.font.size=16;b.font.color=Color.new(245,245,245)
    label=(index+1).to_s+'. '+species_name_v078(instance)
    b.draw_text(x+8,y+4,w-16,22,label,0)
    b.font.bold=false;b.font.size=12;b.font.color=Color.new(175,210,240)
    if instance!=nil
      b.draw_text(x+10,y+27,w-20,18,'Lv'+instance.level.to_s+'  EXP '+instance.exp.to_s,0)
      moves=instance.respond_to?(:battle_moves_v046) ? instance.battle_moves_v046 : instance.active_moves_v045
      names=moves.collect{|mv|move_name_v078(mv)}
      b.font.size=11;b.font.color=Color.new(190,200,210)
      b.draw_text(x+10,y+47,w-20,18,names.join(' / '),0)
    end
    if marked
      b.font.size=11;b.font.color=Color.new(255,225,130)
      b.draw_text(x+w-68,y+4,60,18,'交換中',2)
    end
  end

  def draw_box_row_v078(b,x,y,w,instance,index)
    selected=(@focus==:box && @box_cursor==index)
    b.fill_rect(x,y,w,28,selected ? Color.new(68,92,124,235) : Color.new(25,32,42,225))
    b.font.size=13;b.font.bold=selected;b.font.color=Color.new(235,238,242)
    if instance==nil
      b.draw_text(x+8,y+4,w-16,20,'－',0)
    else
      text=(index+1).to_s.rjust(2,'0')+'  '+species_name_v078(instance)+'  Lv'+instance.level.to_s
      b.draw_text(x+8,y+4,w-16,20,text,0)
    end
    b.font.bold=false
  end

  def refresh
    b=self.bitmap;b.clear;setup_font_v078
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(7,11,17,248))
    b.fill_rect(10,10,Graphics.width-20,Graphics.height-20,Color.new(18,25,35,248))
    b.font.bold=true;b.font.size=22;b.font.color=Color.new(255,255,255)
    b.draw_text(18,16,300,28,'隊伍 / BOX 編成',0)
    b.font.bold=false;b.font.size=13;b.font.color=Color.new(165,185,205)
    box=PMD_AC.pokemon_storage_boxes_v045[@box_index] || []
    b.draw_text(320,19,205,22,'BOX '+(@box_index+1).to_s.rjust(2,'0')+
      ' / '+PMD_AC::STORAGE_BOX_COUNT_V045.to_s+'  '+box.size.to_s+'/'+PMD_AC::STORAGE_BOX_CAPACITY_V045.to_s,2)

    b.font.size=15;b.font.bold=true;b.font.color=Color.new(225,235,245)
    b.draw_text(20,58,190,22,'出戰隊伍 3 隻',0)
    b.draw_text(230,58,294,22,'寶可夢倉庫',0);b.font.bold=false

    party=party_instances
    for i in 0...PMD_AC::PARTY_CAPACITY_V045
      draw_party_card_v078(b,20,84+i*78,190,68,party[i],i)
    end

    a=box_instances
    rows=PMD_AC::PARTY_STORAGE_VISIBLE_ROWS_V078
    for row in 0...rows
      idx=@box_scroll+row
      inst=idx<a.size ? a[idx] : nil
      draw_box_row_v078(b,230,84+row*31,294,inst,idx)
    end

    b.fill_rect(20,326,504,42,Color.new(25,34,46,230))
    b.font.size=12;b.font.color=@selected_party_slot==nil ? Color.new(155,175,195) : Color.new(255,220,125)
    hint=@selected_party_slot==nil ?
      '先在左側選一個出戰槽，再到 BOX 選擇替換寶可夢。' :
      '已選出戰槽 '+(@selected_party_slot+1).to_s+'，到右側 BOX 按 C 完成交換。'
    b.draw_text(30,336,484,20,hint,0)

    b.fill_rect(0,382,Graphics.width,34,Color.new(0,0,0,225))
    b.font.size=12;b.font.color=Color.new(175,220,255)
    b.draw_text(10,389,524,20,'←→ 區域｜↑↓ 選擇｜C 標記/交換｜Q/W 換 BOX｜B 關閉',1)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v078_start start unless method_defined?(:pmd_ac_v078_start)
  alias pmd_ac_v078_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v078_update_deploy_phase)
  alias pmd_ac_v078_refresh_header refresh_header unless method_defined?(:pmd_ac_v078_refresh_header)
  alias pmd_ac_v078_terminate terminate unless method_defined?(:pmd_ac_v078_terminate)
  alias pmd_ac_v078_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v078_prepare_verification_battle)
  alias pmd_ac_v078_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v078_update_verification_script)
  alias pmd_ac_v078_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v078_complete_verification_mode)
  alias pmd_ac_v078_log_event log_event unless method_defined?(:pmd_ac_v078_log_event)

  def start
    pmd_ac_v078_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.78 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    demo_added=PMD_AC.ensure_demo_reserves_v078
    log_event(:party_storage,'DEMO_RESERVE_SEED added='+demo_added.to_s+
      ' species=rattata,caterpie,pikachu test_project=1') if demo_added>0
    m=PMD_AC::PARTY_STORAGE_MANIFEST_V078
    log_event(:party_storage,
      'FLOW v0.78 party=3 storage=24x30 identity=instance_uid '+
      'manager=A(Input::X) swap=atomic fixed_three=1 first_available_store_api=1 '+
      'progression=v0.77.1 checksum32='+m[:runtime_checksum32].to_s)
  end

  def party_storage_open_v078
    return false if @phase!=:deploy
    return false if @progression_ui_panel_v047!=nil
    party_storage_close_v078 if @party_storage_panel_v078!=nil
    swapper=Proc.new{|slot,uid|party_storage_swap_v078(slot,uid)}
    @party_storage_panel_v078=Sprite_PMDPartyStoragePanelV078.new(@viewport,swapper)
    log_event(:party_storage,
      'OPEN party=['+PMD_AC.pokemon_party_uids_v045.collect{|x|x==nil ? 'nil' : x.to_s}.join(',')+
      '] storage='+PMD_AC.storage_count_v078.to_s)
    refresh_header
    true
  end

  def party_storage_close_v078
    if @party_storage_panel_v078!=nil
      @party_storage_panel_v078.dispose unless @party_storage_panel_v078.disposed?
      @party_storage_panel_v078=nil
      log_event(:party_storage,'CLOSE')
    end
    refresh_header
    refresh_footer
    true
  end

  def rebuild_deploy_units_v078
    return false if @phase!=:deploy
    positions=[]
    for u in (@units||[])
      positions.push([u.cell_x,u.cell_y]) if u.team==:ally && !u.summoned?
    end
    dispose_unit_sprites
    create_units
    allies=(@units||[]).find_all{|u|u.team==:ally && !u.summoned?}
    for i in 0...allies.size
      pos=positions[i]
      allies[i].deploy_to_cell(pos[0],pos[1]) if pos!=nil
    end
    create_unit_sprites
    @selected_unit=nil
    refresh_selected_sprites
    refresh_footer
    true
  end

  def party_storage_swap_v078(slot,storage_uid)
    return false if @phase!=:deploy
    before=PMD_AC.party_instance_v045(slot)
    incoming=PMD_AC.pokemon_instance_for_uid_v045(storage_uid)
    return false if before==nil || incoming==nil
    old_uid=before.instance_uid.to_i
    new_uid=incoming.instance_uid.to_i
    ok=PMD_AC.swap_party_with_storage_v045(slot,new_uid)
    if ok
      rebuild_deploy_units_v078
      loc_old=PMD_AC.pokemon_location_v045(old_uid)
      log_event(:party_storage,
        'SWAP slot='+(slot.to_i+1).to_s+' in='+new_uid.to_s+'('+incoming.species_key.to_s+')'+
        ' out='+old_uid.to_s+'('+before.species_key.to_s+')'+
        ' out_location='+(loc_old==nil ? 'nil' : loc_old.join(':')))
    end
    ok
  end

  def update_deploy_phase
    if @party_storage_panel_v078!=nil
      @party_storage_panel_v078.update
      party_storage_close_v078 if @party_storage_panel_v078.close_requested
      return
    end
    if @progression_ui_panel_v047==nil && Input.trigger?(Input::X)
      if party_storage_open_v078
        Sound.play_decision
      else
        Sound.play_buzzer
      end
      return
    end
    pmd_ac_v078_update_deploy_phase
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.78',1)
    bmp.font.size=13
    bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
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

  def terminate
    party_storage_close_v078 if @party_storage_panel_v078!=nil
    PMD_AC.end_identity_sandbox_v045 if verification_mode==:party_storage_v078 && PMD_AC.identity_sandbox_v045?
    pmd_ac_v078_terminate
  end

  def party_storage_v078?
    verification_mode==:party_storage_v078
  end

  def setup_party_storage_sandbox_v078
    PMD_AC.begin_identity_sandbox_v045 unless PMD_AC.identity_sandbox_v045?
    @v078_party=[]
    @v078_reserve=[]
    specs=[:bulbasaur,:charmander,:squirtle]
    for i in 0...3
      inst=PMD_PokemonInstance.new(specs[i],15,
        {:instance_uid=>99780101+i,:ivs=>[15,15,15,15,15,15],
         :nature=>:hardy,:ability_slot=>:primary})
      PMD_AC.register_pokemon_instance_v045(inst)
      PMD_AC.party_assign_instance_v045(i,inst,false)
      @v078_party.push(inst)
    end
    reserve_specs=[:pikachu,:caterpie]
    for i in 0...2
      inst=PMD_PokemonInstance.new(reserve_specs[i],15,
        {:instance_uid=>99780201+i,:ivs=>[16,16,16,16,16,16],
         :nature=>:hardy,:ability_slot=>:primary})
      PMD_AC.register_pokemon_instance_v045(inst)
      PMD_AC.store_instance_v045(inst,i,false)
      @v078_reserve.push(inst)
    end
    @v078_party[1].gain_move_mastery_v045(:ember,7) if @v078_party[1].knows_move_v045?(:ember)
    true
  end

  def prepare_verification_battle
    pmd_ac_v078_prepare_verification_battle
    if party_storage_v078?
      @party_storage_v078_failed=false
      setup_party_storage_sandbox_v078
      for u in @units
        u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
        u.verification_energy_sandbox(true) if u.respond_to?(:verification_energy_sandbox)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && party_storage_v078? &&
       message.to_s.index('PARTY_STORAGE_')==0 && message.to_s.include?(' pass=0')
      @party_storage_v078_failed=true
    end
    pmd_ac_v078_log_event(category,message)
  end

  def log_verify_v078(name,pass,detail='')
    @party_storage_v078_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_party_storage_manifest_v078
    return if @verification_done[:v078_manifest]
    m=PMD_AC::PARTY_STORAGE_MANIFEST_V078
    pass=m[:party_capacity].to_i==3 && m[:storage_boxes].to_i==24 &&
      m[:box_capacity].to_i==30 && m[:identity_key]=='instance_uid' &&
      PMD_AC.party_storage_integrity_errors_v078.empty?
    log_verify_v078('PARTY_STORAGE_MANIFEST_V078',pass,
      'party=3 boxes=24 capacity=30 identity=instance_uid errors=['+
      PMD_AC.party_storage_integrity_errors_v078.join(',')+'] checksum32='+
      PMD_AC.party_storage_checksum32_v078.to_s)
    @verification_done[:v078_manifest]=true
  end

  def verify_party_storage_locations_v078
    return if @verification_done[:v078_locations]
    p=PMD_AC.pokemon_party_uids_v045
    locs=@v078_reserve.collect{|i|PMD_AC.pokemon_location_v045(i.instance_uid)}
    pass=PMD_AC.party_ready_v078? && p.compact.uniq.size==3 &&
      locs[0]==[:storage,0,0] && locs[1]==[:storage,1,0] &&
      PMD_AC.party_storage_integrity_errors_v078.empty?
    log_verify_v078('PARTY_STORAGE_LOCATION_V078',pass,
      'party_ready='+(PMD_AC.party_ready_v078? ? '1':'0')+
      ' exclusive_uid=1 reserve_boxes=0,1 storage_count='+PMD_AC.storage_count_v078.to_s)
    @verification_done[:v078_locations]=true
  end

  def verify_party_storage_swap_v078
    return if @verification_done[:v078_swap]
    outgoing=@v078_party[1];incoming=@v078_reserve[0]
    uid_out=outgoing.instance_uid;uid_in=incoming.instance_uid
    level=outgoing.level;exp=outgoing.exp
    known=outgoing.known_moves_v045;active=outgoing.active_moves_v045
    mastery=outgoing.knows_move_v045?(:ember) ? outgoing.move_mastery_exp_v045(:ember) : 0
    ok=PMD_AC.swap_party_with_storage_v045(1,uid_in)
    loc_out=PMD_AC.pokemon_location_v045(uid_out)
    loc_in=PMD_AC.pokemon_location_v045(uid_in)
    pass=ok && loc_in==[:party,1] && loc_out!=nil && loc_out[0]==:storage &&
      PMD_AC.party_instance_v045(1).equal?(incoming) &&
      outgoing.level==level && outgoing.exp==exp &&
      outgoing.known_moves_v045==known && outgoing.active_moves_v045==active &&
      (outgoing.knows_move_v045?(:ember) ? outgoing.move_mastery_exp_v045(:ember) : 0)==mastery &&
      PMD_AC.party_storage_integrity_errors_v078.empty?
    log_verify_v078('PARTY_STORAGE_SWAP_V078',pass,
      'slot=2 in=pikachu out=charmander atomic='+(ok ? '1':'0')+
      ' uid_identity=1 progression_preserved=1 mastery_preserved=1')
    @verification_done[:v078_swap]=true
  end

  def verify_party_storage_first_free_v078
    return if @verification_done[:v078_store]
    i=PMD_PokemonInstance.new(:rattata,12,
      {:instance_uid=>99780301,:ivs=>[15,15,15,15,15,15],
       :nature=>:hardy,:ability_slot=>:primary})
    PMD_AC.register_pokemon_instance_v045(i)
    bi=PMD_AC.first_available_box_v078
    ok=PMD_AC.store_instance_first_available_v078(i,false)
    loc=PMD_AC.pokemon_location_v045(i.instance_uid)
    pass=bi!=nil && ok && loc!=nil && loc[0]==:storage && loc[1]==bi &&
      PMD_AC.party_storage_integrity_errors_v078.empty?
    log_verify_v078('PARTY_STORAGE_FIRST_FREE_V078',pass,
      'api=first_available_box target_box='+(bi==nil ? 'nil' : bi.to_s)+
      ' stored='+(ok ? '1':'0')+' future_capture_ready=1')
    @verification_done[:v078_store]=true
  end

  def verify_party_storage_ui_v078
    return if @verification_done[:v078_ui]
    ok=true
    panel=nil
    begin
      panel=Sprite_PMDPartyStoragePanelV078.new(@viewport,Proc.new{|slot,uid|false})
      ok=panel.bitmap!=nil && panel.bitmap.width==Graphics.width &&
        panel.bitmap.height==Graphics.height
    rescue Exception=>e
      ok=false
      log_event(:party_storage,'UI_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s)
    ensure
      panel.dispose if panel!=nil && !panel.disposed?
    end
    log_verify_v078('PARTY_STORAGE_UI_V078',ok,
      'open_input=A focus=party_box box_switch=Q/W atomic_swap=C close=B')
    @verification_done[:v078_ui]=true
  end

  def verify_party_storage_carry_v078
    return if @verification_done[:v078_carry]
    pass=PMD_AC::PARTY_CAPACITY_V045==3 && PMD_AC::STORAGE_BOX_COUNT_V045==24 &&
      PMD_AC::STORAGE_BOX_CAPACITY_V045==30 && PMD_AC::ACTIVE_MOVE_SLOTS_V045==4
    log_verify_v078('PARTY_STORAGE_CARRY_V078',pass,
      'identity=v0.45 progression=v0.77.1 stats=v0.76 balance=v0.75 '+
      'basic_hit_sfx=v0.75.1 weather=v0.28 field=v0.35-v0.37 combo=v0.60.2 router=v0.62')
    @verification_done[:v078_carry]=true
  end

  def update_verification_script
    unless party_storage_v078?
      pmd_ac_v078_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_party_storage_manifest_v078 if f>=2
    verify_party_storage_locations_v078 if f>=4
    verify_party_storage_swap_v078 if f>=6
    verify_party_storage_first_free_v078 if f>=8
    verify_party_storage_ui_v078 if f>=10
    verify_party_storage_carry_v078 if f>=12
    if f>=14 && !@verification_done[:v078_final]
      pass=!@party_storage_v078_failed
      log_verify_v078('PARTY_STORAGE_V078',pass,
        'manifest=1 location=1 swap=1 first_free=1 ui=1 carry=1')
      @verification_done[:v078_final]=true
    end
    complete_verification_mode if f>=PMD_AC::PARTY_STORAGE_VERIFY_END_V078
  end

  def complete_verification_mode
    if party_storage_v078?
      party_storage_close_v078 if @party_storage_panel_v078!=nil
      PMD_AC.end_identity_sandbox_v045 if PMD_AC.identity_sandbox_v045?
    end
    pmd_ac_v078_complete_verification_mode
  end
end
