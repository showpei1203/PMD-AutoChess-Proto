# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Stage / Region / Encounter Preview UI v0.90
# 分類：戰前資訊 UI／Runtime Verifier
#
# 【用途】
# 在 Scene_PMD_AutoChess 的布陣階段提供玩家真正可讀的戰前資訊面板。
# v0.80～v0.87 已經有 Stage、Region、Formation、Rare、Elite、Reward、Unlock，
# 但玩家以前只能從 Header 或 LOG 猜發生什麼；v0.90 把這些資料整理成一張面板。
#
# 【主要設定項】
# - 面板尺寸／位置來自 Preview Data v0.90：PREVIEW_W/H/Y_V090。
# - UI 使用半透明深色底，字體沿用 v0.74.1／v0.86 的 JhengHei UI 規則。
# - v0.90 驗證模式：ENCOUNTER_PREVIEW_V090。
#
# 【玩家操作規則】
# 一般 Stage 模式：
# - 進入 Scene 時自動開啟一次預覽。
# - Q/W：切換已解鎖 Stage，並立即刷新敵方／Region／Reward 預覽。
# - C 或 B：關閉預覽，回到原本布陣。
# - Shift：從預覽直接開始戰鬥。
# - S：關閉預覽並切到下一個 Verifier，方便測試專案繼續使用。
#
# RPG Encounter／Boss：
# - 若該 Request 允許 Deploy，進入布陣時也會顯示 Encounter Preview。
# - 不允許 Deploy 的 Wild Encounter 仍照 v0.81 直接開戰，不插入額外等待。
#
# 【顯示內容】
# - Stage／Encounter 名稱、建議等級或敵方等級。
# - 固定敵方編成；每隻顯示「已持有／未持有」。
# - Stage 招募池與首通／重複招募率。
# - 首通／重複 Reward Table 預覽。
# - 對應 Region、難度、區域招募率。
# - v0.84 Elite 率／最大 Elite 數。
# - v0.86 Formation 名稱、rarity、目前有效抽取率。
# - v0.87 尚未解鎖的 Formation 顯示「鎖定」，不假裝它仍有機率。
#
# 【事件／腳本呼叫方式】
# 原本事件 API 不變，例如：
#   PMD_AC.start_region_battle_v086(:forest_edge, {:deploy=>true})
#   PMD_AC.start_battle_v081(:boss_beedrill)
# 只要 Request 的 :deploy 為 true，Scene 會在開戰前顯示本 Preview。
#
# 【實際範例】
# Stage 1：
#   Q/W 切到「林緣演習」後，可看到 Lv12 敵方三隻、100G 首通、35G 重複、
#   林緣 Formation 權重與 Elite 10%／最多 1 隻；若皮卡丘傳聞 Switch 尚未開啟，
#   雷光林群會直接標成「鎖定」。
#
# 【注意事項】
# - 本腳本只讀資料、畫 UI，不改任何戰鬥計算。
# - 不使用禁止的舊式 instance variable probe。
# - Q/W 原本就是 Stage 切換鍵；v0.90 只是把切換結果做成可讀面板。
# - Main 前追加，不改寫舊 v0.89.2 Script entries。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V090 = '0.90'

  V090_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V090_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:encounter_preview_v090] +
    V090_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:encounter_preview_v090}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V090_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:encounter_preview_v090]='ENCOUNTER_PREVIEW_V090'

  def self.preview_set_font_v090(bitmap,size,bold=false,color=nil)
    return if bitmap==nil
    begin
      bitmap.font.name=defined?(UI_PANEL_FONT_V0741) ? UI_PANEL_FONT_V0741 : ['Microsoft JhengHei','微軟正黑體','Arial']
    rescue
      bitmap.font.name='Arial'
    end
    bitmap.font.size=size.to_i
    bitmap.font.bold=bold ? true:false
    bitmap.font.color=color || Color.new(235,240,245)
  end

  def self.preview_enemy_level_text_v090(row)
    return '' if row==nil
    if row[:level]!=nil
      return 'Lv'+row[:level].to_i.to_s
    end
    mn=(row[:min_level]||1).to_i
    mx=(row[:max_level]||mn).to_i
    mn==mx ? 'Lv'+mn.to_s : 'Lv'+mn.to_s+'-'+mx.to_s
  end

  def self.preview_owned_short_v090(row)
    row!=nil && row[:owned] ? '[已持有]' : '[未持有]'
  end

  def self.preview_join_reward_v090(lines)
    a=lines || []
    a.empty? ? '無' : a.join('｜')
  end

  def self.preview_region_form_line_v090(row)
    return '' if row==nil
    rarity='【'+row[:rarity_label].to_s+'】'
    chance=row[:available] ? row[:chance].to_i.to_s+'%' : '鎖定'
    rarity+chance+' '+row[:name].to_s
  end

  def self.draw_preview_panel_v090(bitmap,model)
    return false if bitmap==nil || model==nil
    w=bitmap.width;h=bitmap.height
    bitmap.clear
    bitmap.fill_rect(0,0,w,h,Color.new(8,14,20,244))
    bitmap.fill_rect(1,1,w-2,1,Color.new(120,170,210,190))
    bitmap.fill_rect(1,h-2,w-2,1,Color.new(120,170,210,150))
    bitmap.fill_rect(1,1,1,h-2,Color.new(120,170,210,140))
    bitmap.fill_rect(w-2,1,1,h-2,Color.new(120,170,210,140))

    preview_set_font_v090(bitmap,20,true,Color.new(255,255,255))
    prefix=model[:mode]==:stage ? '關卡預覽｜' : '遭遇預覽｜'
    bitmap.draw_text(14,5,w-28,28,prefix+model[:title].to_s,0)

    bitmap.fill_rect(12,36,238,1,Color.new(80,110,135,150))
    bitmap.fill_rect(260,36,238,1,Color.new(80,110,135,150))

    # 左欄：Stage/Encounter 本體
    y=42
    preview_set_font_v090(bitmap,15,false,Color.new(205,225,240))
    if model[:mode]==:stage
      info='建議 Lv'+model[:recommended_level].to_i.to_s+
        '｜通關 '+model[:clear_count].to_i.to_s+' 次｜'+
        (model[:first_clear_pending] ? '首通未完成' : '已首通')
      bitmap.draw_text(16,y,230,21,info,0)
    else
      kind=model[:kind].to_s.upcase
      rule=model[:recruitable] ? ('招募 '+model[:recruit_rate].to_i.to_s+'%') : '不可招募'
      esc=model[:can_escape] ? '可逃離' : '不可逃離'
      bitmap.draw_text(16,y,230,21,kind+'｜'+rule+'｜'+esc,0)
    end

    y=65
    preview_set_font_v090(bitmap,16,true,Color.new(255,225,150))
    bitmap.draw_text(16,y,230,22,'敵方預覽',0)
    y+=22
    preview_set_font_v090(bitmap,14,false,Color.new(235,240,245))
    enemies=model[:enemies] || []
    if enemies.empty?
      bitmap.draw_text(20,y,226,19,'未知／Runtime 決定',0)
      y+=19
    else
      limit=[enemies.size,4].min
      for i in 0...limit
        row=enemies[i]
        name=preview_species_name_v090(row[:species])
        extra=''
        extra+=' BOSS' if row[:boss]
        extra+=' ELITE' if row[:elite]
        text=(i+1).to_s+'. '+name+' '+preview_enemy_level_text_v090(row)+' '+preview_owned_short_v090(row)+extra
        bitmap.draw_text(20,y,226,19,text,0)
        y+=19
      end
    end

    if model[:mode]==:stage
      y=166
      preview_set_font_v090(bitmap,15,true,Color.new(180,235,190))
      bitmap.draw_text(16,y,230,21,'招募候選',0)
      y+=20
      preview_set_font_v090(bitmap,13,false,Color.new(220,238,225))
      recruits=model[:recruits] || []
      texts=[]
      recruits.each do |row|
        texts.push(preview_species_name_v090(row[:species])+(row[:owned] ? '[有]' : '[未]'))
      end
      bitmap.draw_text(20,y,226,18,texts.empty? ? '無' : texts.join('／'),0)
      y+=19
      bitmap.draw_text(20,y,226,18,'首通 '+model[:recruit_first_rate].to_i.to_s+'%｜重複 '+model[:recruit_repeat_rate].to_i.to_s+'%',0)
    end

    y=211
    preview_set_font_v090(bitmap,14,true,Color.new(255,215,145))
    if model[:mode]==:stage
      bitmap.draw_text(16,y,230,19,'首通：'+preview_join_reward_v090(model[:reward_first]),0)
      bitmap.draw_text(16,y+19,230,19,'重複：'+preview_join_reward_v090(model[:reward_repeat]),0)
    else
      bitmap.draw_text(16,y,230,19,'勝利：'+preview_join_reward_v090(model[:reward_repeat]),0)
    end

    # 右欄：Region / Ecology / Rare / Elite
    region=model[:region]
    y=42
    if region!=nil
      preview_set_font_v090(bitmap,16,true,Color.new(170,220,255))
      bitmap.draw_text(264,y,230,22,'區域｜'+region[:name].to_s,0)
      y+=23
      preview_set_font_v090(bitmap,14,false,Color.new(215,230,242))
      diff=region[:difficulty].to_i
      info='難度 '+diff.to_s+'/5｜區域招募 '+region[:recruit_rate].to_i.to_s+'%'
      bitmap.draw_text(268,y,226,19,info,0)
      y+=19
      elite='Elite '+region[:elite_rate].to_i.to_s+'%｜最多 '+region[:elite_max].to_i.to_s+' 隻'
      bitmap.draw_text(268,y,226,19,elite,0)
      y+=23
      preview_set_font_v090(bitmap,15,true,Color.new(255,225,150))
      bitmap.draw_text(264,y,230,20,'可能 Encounter',0)
      y+=20
      preview_set_font_v090(bitmap,13,false,Color.new(232,238,245))
      forms=region[:formations] || []
      limit=[forms.size,5].min
      for i in 0...limit
        row=forms[i]
        col=row[:available] ? Color.new(232,238,245) : Color.new(135,145,155)
        preview_set_font_v090(bitmap,13,false,col)
        bitmap.draw_text(268,y,226,18,preview_region_form_line_v090(row),0)
        y+=18
      end
      if model[:formation]!=nil
        y=[y+2,217].min
        preview_set_font_v090(bitmap,13,true,Color.new(255,205,120))
        bitmap.draw_text(268,y,226,18,'本次 Formation：'+model[:formation].to_s,0)
      end
    else
      preview_set_font_v090(bitmap,16,true,Color.new(170,220,255))
      bitmap.draw_text(264,y,230,22,'區域資料',0)
      y+=27
      preview_set_font_v090(bitmap,14,false,Color.new(190,205,215))
      bitmap.draw_text(268,y,226,20,'此 Encounter 未綁定 Region Ecology',0)
      y+=22
      if model[:boss]
        bitmap.draw_text(268,y,226,20,'Boss：Elite 系統不套用',0)
      end
    end

    bitmap.fill_rect(12,h-30,w-24,1,Color.new(80,110,135,150))
    preview_set_font_v090(bitmap,14,false,Color.new(170,220,255))
    foot=model[:mode]==:stage ? 'Q/W 切換關卡｜C/B 關閉預覽｜Shift 直接開戰｜S 驗證' : 'C/B 關閉預覽｜Shift 直接開戰｜S 驗證'
    bitmap.draw_text(14,h-27,w-28,23,foot,1)
    true
  end
end

class Sprite_PMDEncounterPreviewV090 < Sprite
  attr_reader :model
  def initialize(viewport,model=nil)
    super(viewport)
    self.bitmap=Bitmap.new(PMD_AC::PREVIEW_W_V090,PMD_AC::PREVIEW_H_V090)
    self.x=(Graphics.width-PMD_AC::PREVIEW_W_V090)/2
    self.y=PMD_AC::PREVIEW_Y_V090
    self.z=13000
    @model=nil
    refresh_model(model)
  end

  def refresh_model(model)
    @model=model
    PMD_AC.draw_preview_panel_v090(self.bitmap,@model) if self.bitmap!=nil
  end

  def dispose
    if self.bitmap!=nil && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    super
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v090_start start unless method_defined?(:pmd_ac_v090_start)
  alias pmd_ac_v090_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v090_update_deploy_phase)
  alias pmd_ac_v090_start_battle start_battle unless method_defined?(:pmd_ac_v090_start_battle)
  alias pmd_ac_v090_refresh_header refresh_header unless method_defined?(:pmd_ac_v090_refresh_header)
  alias pmd_ac_v090_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v090_prepare_verification_battle)
  alias pmd_ac_v090_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v090_update_verification_script)
  alias pmd_ac_v090_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v090_complete_verification_mode)
  alias pmd_ac_v090_log_event log_event unless method_defined?(:pmd_ac_v090_log_event)
  alias pmd_ac_v090_terminate terminate unless method_defined?(:pmd_ac_v090_terminate)

  def encounter_preview_v090?
    verification_mode==:encounter_preview_v090
  end

  def preview_panel_active_v090?
    @encounter_preview_panel_v090!=nil && @encounter_preview_panel_v090.visible
  end

  def preview_model_for_scene_v090
    req=respond_to?(:rpg_request_v081) ? rpg_request_v081 : nil
    return PMD_AC.request_preview_model_v090(req) if req!=nil
    PMD_AC.stage_preview_model_v090(PMD_AC.current_stage_id_v080)
  end

  def preview_can_open_v090?
    return false unless @phase==:deploy
    return false unless verification_mode==:normal
    return false if @party_storage_panel_v078!=nil
    return false if @progression_ui_panel_v047!=nil
    req=respond_to?(:rpg_request_v081) ? rpg_request_v081 : nil
    return false if req!=nil && !req[:deploy]
    true
  end

  def open_encounter_preview_v090(reason='manual')
    return false unless preview_can_open_v090?
    model=preview_model_for_scene_v090
    return false if model==nil
    if @encounter_preview_panel_v090==nil
      @encounter_preview_panel_v090=Sprite_PMDEncounterPreviewV090.new(@viewport,model)
    else
      @encounter_preview_panel_v090.visible=true
      @encounter_preview_panel_v090.refresh_model(model)
    end
    log_event(:preview,'OPEN reason='+reason.to_s+' mode='+model[:mode].to_s+
      ' title='+model[:title].to_s)
    true
  end

  def close_encounter_preview_v090(reason='close')
    return false if @encounter_preview_panel_v090==nil
    @encounter_preview_panel_v090.visible=false
    log_event(:preview,'CLOSE reason='+reason.to_s)
    true
  end

  def refresh_encounter_preview_v090
    return false unless @encounter_preview_panel_v090!=nil
    model=preview_model_for_scene_v090
    return false if model==nil
    @encounter_preview_panel_v090.refresh_model(model)
    true
  end

  def cycle_stage_from_preview_v090(delta)
    req=respond_to?(:rpg_request_v081) ? rpg_request_v081 : nil
    return false if req!=nil
    old=PMD_AC.current_stage_id_v080
    now=PMD_AC.cycle_stage_v080(delta)
    if now==old
      Sound.play_buzzer
      refresh_encounter_preview_v090
      return false
    end
    Sound.play_cursor
    rebuild_deploy_units_v078 if respond_to?(:rebuild_deploy_units_v078)
    log_event(:preview,'STAGE_SELECT '+old.to_s+'->'+now.to_s+' name='+PMD_AC.stage_name_v080(now))
    refresh_header
    refresh_footer
    refresh_encounter_preview_v090
    true
  end

  def update_active_preview_v090
    if Input.trigger?(Input::L) || Input.trigger?(Input::R)
      delta=Input.trigger?(Input::L) ? -1 : 1
      cycle_stage_from_preview_v090(delta)
      return
    end
    if Input.trigger?(Input::C) || Input.trigger?(Input::B)
      Sound.play_cancel
      close_encounter_preview_v090('player')
      refresh_header
      refresh_footer
      return
    end
    if Input.trigger?(Input::Y)
      Sound.play_cursor
      close_encounter_preview_v090('verifier')
      cycle_verification_mode
      refresh_header
      refresh_footer
      return
    end
    if Input.trigger?(Input::A)
      Sound.play_decision
      close_encounter_preview_v090('battle_start')
      start_battle
      return
    end
  end

  def start
    pmd_ac_v090_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.90 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::PREVIEW_MANIFEST_V090
    log_event(:preview,'FLOW v0.90 stage_region_links='+m[:stage_region_links].to_s+
      ' stage=1 region=1 encounter=1 rarity=1 elite=1 recruit=1 reward=1 owned=1 unlock=v0.87')
    refresh_header
    open_encounter_preview_v090('scene_start') if preview_can_open_v090?
  end

  def update_deploy_phase
    if preview_panel_active_v090?
      update_active_preview_v090
      return
    end
    if preview_can_open_v090? && (Input.trigger?(Input::L) || Input.trigger?(Input::R))
      delta=Input.trigger?(Input::L) ? -1 : 1
      cycle_stage_from_preview_v090(delta)
      open_encounter_preview_v090('stage_change')
      return
    end
    pmd_ac_v090_update_deploy_phase
  end

  def start_battle
    close_encounter_preview_v090('battle_start') if preview_panel_active_v090?
    pmd_ac_v090_start_battle
  end

  def refresh_header
    pmd_ac_v090_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,31,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=defined?(PMD_AC::UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 24
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.90',1)
  end

  def prepare_verification_battle
    pmd_ac_v090_prepare_verification_battle
    @encounter_preview_v090_failed=false if encounter_preview_v090?
  end

  def log_event(category,message)
    if category.to_s=='verify' && encounter_preview_v090? &&
       message.to_s.index('PREVIEW_')==0 && message.to_s.include?(' pass=0')
      @encounter_preview_v090_failed=true
    end
    pmd_ac_v090_log_event(category,message)
  end

  def log_verify_v090(name,pass,detail='')
    @encounter_preview_v090_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_preview_manifest_v090
    return if @verification_done[:v090_manifest]
    e=PMD_AC.preview_manifest_errors_v090
    m=PMD_AC::PREVIEW_MANIFEST_V090
    pass=e.empty? && m[:stage_region_links]==3 && PMD_AC::PREVIEW_W_V090==510 && PMD_AC::PREVIEW_H_V090==280
    log_verify_v090('PREVIEW_MANIFEST_V090',pass,
      'stage_region_links='+m[:stage_region_links].to_s+' panel=510x280 errors=['+e.join(',')+'] checksum32='+m[:runtime_checksum32].to_s)
    @verification_done[:v090_manifest]=true
  end

  def verify_preview_stage_model_v090
    return if @verification_done[:v090_stage]
    m=PMD_AC.stage_preview_model_v090(1)
    pass=m!=nil && m[:title]=='林緣演習' && m[:recommended_level]==12 &&
      m[:enemies].size==3 && m[:recruits].size==3 && m[:region]!=nil &&
      m[:region][:key]==:forest_edge && m[:reward_first].include?('100G') && m[:reward_repeat].include?('35G')
    log_verify_v090('PREVIEW_STAGE_MODEL_V090',pass,
      'stage=1 enemies='+(m==nil ? 'nil' : m[:enemies].size.to_s)+' recruits='+(m==nil ? 'nil' : m[:recruits].size.to_s)+
      ' region='+(m==nil || m[:region]==nil ? 'nil' : m[:region][:key].to_s)+' reward=100G/35G')
    @verification_done[:v090_stage]=true
  end

  def verify_preview_unlock_aware_v090
    return if @verification_done[:v090_unlock]
    old=$game_switches==nil ? nil : $game_switches[81]
    locked=false;opened=false
    begin
      if $game_switches!=nil
        $game_switches[81]=false
        a=PMD_AC.preview_region_model_v090(:forest_edge)
        row=a==nil ? nil : a[:formations].find{|x|x[:key]==:forest_pikachu_rare}
        locked=row!=nil && !row[:available] && row[:chance]==0
        $game_switches[81]=true
        b=PMD_AC.preview_region_model_v090(:forest_edge)
        row2=b==nil ? nil : b[:formations].find{|x|x[:key]==:forest_pikachu_rare}
        opened=row2!=nil && row2[:available] && row2[:chance]>0
      end
    ensure
      $game_switches[81]=old if $game_switches!=nil
    end
    pass=locked && opened
    log_verify_v090('PREVIEW_UNLOCK_AWARE_V090',pass,
      'pikachu_rumor locked='+(locked ? '1':'0')+' opened='+(opened ? '1':'0')+' actual_rate_recomputed=1')
    @verification_done[:v090_unlock]=true
  end

  def verify_preview_region_model_v090
    return if @verification_done[:v090_region]
    r=PMD_AC.preview_region_model_v090(:forest_edge)
    pass=r!=nil && r[:difficulty]==1 && r[:elite_rate]==10 && r[:elite_max]==1 && r[:formations].size==4
    log_verify_v090('PREVIEW_REGION_MODEL_V090',pass,
      'region=forest_edge difficulty='+(r==nil ? 'nil' : r[:difficulty].to_s)+
      ' elite='+(r==nil ? 'nil' : r[:elite_rate].to_s)+'%/'+(r==nil ? 'nil' : r[:elite_max].to_s)+
      ' formations='+(r==nil ? 'nil' : r[:formations].size.to_s))
    @verification_done[:v090_region]=true
  end

  def verify_preview_request_model_v090
    return if @verification_done[:v090_request]
    req=PMD_AC.region_request_v086(:forest_edge,{:formation=>:forest_mixed,:elite_rate=>0},0)
    m=PMD_AC.request_preview_model_v090(req)
    pass=req!=nil && m!=nil && m[:mode]==:request && m[:enemies].size==3 && m[:region]!=nil &&
      m[:region][:key]==:forest_edge && m[:recruitable] && m[:recruit_rate]==30
    log_verify_v090('PREVIEW_REQUEST_MODEL_V090',pass,
      'region_request=1 formation='+(req==nil ? 'nil' : req[:formation_v086].to_s)+
      ' enemies='+(m==nil ? 'nil' : m[:enemies].size.to_s)+' recruit='+(m==nil ? 'nil' : m[:recruit_rate].to_s)+'%')
    @verification_done[:v090_request]=true
  end

  def verify_preview_owned_v090
    return if @verification_done[:v090_owned]
    inst=PMD_AC.party_instance_v045(0)
    sp=inst==nil ? nil : inst.species_key
    owned=sp==nil ? false : PMD_AC.species_owned_v090?(sp)
    registry=PMD_AC.pokemon_registry_v045
    pass=sp!=nil && owned && registry.size>=3
    log_verify_v090('PREVIEW_OWNED_V090',pass,
      'party_species='+(sp==nil ? 'nil' : sp.to_s)+' owned='+(owned ? '1':'0')+' registry='+registry.size.to_s+' identity=instance_uid')
    @verification_done[:v090_owned]=true
  end

  def verify_preview_ui_v090
    return if @verification_done[:v090_ui]
    bmp=nil;ok=true
    begin
      bmp=Bitmap.new(PMD_AC::PREVIEW_W_V090,PMD_AC::PREVIEW_H_V090)
      model=PMD_AC.stage_preview_model_v090(1)
      ok=PMD_AC.draw_preview_panel_v090(bmp,model) && bmp.width==510 && bmp.height==280
    rescue Exception=>e
      ok=false
      log_event(:preview,'UI_SMOKE_ERROR '+e.class.to_s+':'+e.message.to_s)
    ensure
      bmp.dispose if bmp!=nil && !bmp.disposed?
    end
    log_verify_v090('PREVIEW_UI_V090',ok,
      'panel=510x280 modal=deploy auto_open=1 QW=stage C/B=close Shift=start S=verify')
    @verification_done[:v090_ui]=true
  end

  def verify_preview_carry_v090
    return if @verification_done[:v090_carry]
    pass=PMD_AC::STALL_WATCH_FRAMES_V089==540 && PMD_AC::STALL_RESOLVE_FRAMES_V089==960 &&
      PMD_AC::STAGE_DB_V080.size==3 && PMD_AC::REGION_ECOLOGY_PROFILES_V086.size>=4 &&
      PMD_AC::STAGE_RECRUIT_REPEAT_V080==35
    log_verify_v090('PREVIEW_CARRY_V090',pass,
      'stalemate=v0.89 foot=v0.89.2 combat_feel=v0.88.3 unlock=v0.87 region=v0.86 elite=v0.84 reward=v0.83 battle_rules=unchanged')
    @verification_done[:v090_carry]=true
  end

  def update_verification_script
    unless encounter_preview_v090?
      pmd_ac_v090_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_preview_manifest_v090 if f>=2
    verify_preview_stage_model_v090 if f>=4
    verify_preview_unlock_aware_v090 if f>=6
    verify_preview_region_model_v090 if f>=8
    verify_preview_request_model_v090 if f>=10
    verify_preview_owned_v090 if f>=12
    verify_preview_ui_v090 if f>=14
    verify_preview_carry_v090 if f>=16
    if f>=18 && !@verification_done[:v090_final]
      pass=!@encounter_preview_v090_failed
      log_verify_v090('ENCOUNTER_PREVIEW_V090',pass,
        'manifest=1 stage=1 unlock=1 region=1 request=1 owned=1 ui=1 carry=1')
      @verification_done[:v090_final]=true
    end
    complete_verification_mode if f>=PMD_AC::PREVIEW_VERIFY_END_V090
  end

  def complete_verification_mode
    pmd_ac_v090_complete_verification_mode
  end

  def terminate
    if @encounter_preview_panel_v090!=nil
      @encounter_preview_panel_v090.dispose unless @encounter_preview_panel_v090.disposed?
      @encounter_preview_panel_v090=nil
    end
    pmd_ac_v090_terminate
  end
end
