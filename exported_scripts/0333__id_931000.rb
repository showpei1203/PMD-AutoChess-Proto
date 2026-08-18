# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess UI Readability / Pokédex Sprite Hotfix v0.93.1
# 分類：UI 可讀性補丁／圖鑑 PMD 動態預覽
#
# 【用途】
# 依 v0.93 實機截圖修正兩個純視覺問題：
# 1. v0.90 Stage / Region / Encounter Preview 中央資訊字級過小。
# 2. v0.93 全國圖鑑清單與右側詳細資料過小，且右側缺乏 Pokémon 視覺預覽。
#
# 【主要設定項】
# - 圖鑑每頁：12 隻（v0.93 原為 14），以較大的 16px 清單字與 24px 行距換取可讀性。
# - 圖鑑右側 PMD 預覽：Idle 優先，若沒有 Idle 會自動走既有 ACTION_FALLBACKS。
# - 圖鑑預覽方向：方向 1，亦即 PMD 八方向中的左下／左前 45°。
# - PMD 預覽最大約 92px，依原始 frame 寬高自動縮放，避免大型 Pokémon 溢出面板。
# - 未遭遇 Pokémon 不顯示 Sprite，維持 v0.93 的資料揭露規則。
#
# 【機制規則】
# - 本補丁只修改 Bitmap 排版、字級、圖鑑顯示 Sprite 與版本文字。
# - 不修改 v0.93 的 Seen / Owned / Current / Rare / Elite / Evolution 紀錄。
# - 不修改戰鬥、AI、Damage、Range、Energy、Aggro、Peel、Tactical Passive。
# - 圖鑑動態圖直接讀既有 Graphics/PMD/<species>/ 動作圖與 PMD_AC.action_data，
#   不建立第二份 Sprite 素材資料庫。
#
# 【可調參數】
# - DEX_PAGE_SIZE_V0931：圖鑑每頁顯示數量。
# - DEX_PREVIEW_DIRECTION_V0931：PMD 預覽方向；1=左前、3=右前。
# - DEX_PREVIEW_MAX_SIZE_V0931：Sprite 顯示最大尺寸。
# - DEX_PREVIEW_X/Y_V0931：圖鑑右上角預覽的腳底基準位置。
#
# 【事件／腳本呼叫方式】
# 原 v0.93 呼叫完全不變：
#   PMD_AC.open_collection_v093
# Battle Deploy 仍使用 Ctrl 開圖鑑。
# Stage / Region Preview 操作亦不變：Q/W、C/B、Shift、S。
#
# 【實際範例】
# - 已遭遇綠毛蟲：右側顯示綠毛蟲左前 45° Idle 動態圖。
# - 未遭遇 #0027：仍只顯示 #0027 ????，不載入 Sprite，不劇透身份。
# - 若某測試專案沒有該 Species 的 PMD 資料夾，圖鑑仍正常顯示文字，不報錯。
#
# 【注意事項】
# - Cache.load_bitmap 回傳共用 Bitmap，本腳本不 dispose 該 Cache Bitmap。
# - RGSS2 / Ruby 1.8 相容，不使用禁止的舊式 instance variable reflection probe。
# - 以 Main 前追加方式安裝；v0.93 舊 Script entries 保持 byte-for-byte 不動。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0931 = '0.93.1'
  DEX_PAGE_SIZE_V0931 = 12
  DEX_PREVIEW_DIRECTION_V0931 = 1
  DEX_PREVIEW_MAX_SIZE_V0931 = 92.0
  DEX_PREVIEW_X_V0931 = 466
  DEX_PREVIEW_Y_V0931 = 191

  #-------------------------------------------------------------------------
  # v0.90 Preview 重排：保留原資料模型，只放大字級並重新利用垂直空間。
  #-------------------------------------------------------------------------
  def self.draw_preview_panel_v090(bitmap,model)
    return false if bitmap==nil || model==nil
    w=bitmap.width;h=bitmap.height
    bitmap.clear
    bitmap.fill_rect(0,0,w,h,Color.new(8,14,20,247))
    bitmap.fill_rect(1,1,w-2,1,Color.new(120,170,210,200))
    bitmap.fill_rect(1,h-2,w-2,1,Color.new(120,170,210,165))
    bitmap.fill_rect(1,1,1,h-2,Color.new(120,170,210,155))
    bitmap.fill_rect(w-2,1,1,h-2,Color.new(120,170,210,155))

    preview_set_font_v090(bitmap,22,true,Color.new(255,255,255))
    prefix=model[:mode]==:stage ? '關卡預覽｜' : '遭遇預覽｜'
    bitmap.draw_text(14,3,w-28,30,prefix+model[:title].to_s,0)

    bitmap.fill_rect(12,36,238,1,Color.new(80,110,135,175))
    bitmap.fill_rect(260,36,238,1,Color.new(80,110,135,175))

    # 左欄 ---------------------------------------------------------------
    y=41
    preview_set_font_v090(bitmap,16,false,Color.new(210,230,245))
    if model[:mode]==:stage
      info='建議 Lv'+model[:recommended_level].to_i.to_s+
        '｜通關 '+model[:clear_count].to_i.to_s+' 次｜'+
        (model[:first_clear_pending] ? '首通未完成' : '已首通')
      bitmap.draw_text(16,y,232,23,info,0)
    else
      kind=model[:kind].to_s.upcase
      rule=model[:recruitable] ? ('招募 '+model[:recruit_rate].to_i.to_s+'%') : '不可招募'
      esc=model[:can_escape] ? '可逃離' : '不可逃離'
      bitmap.draw_text(16,y,232,23,kind+'｜'+rule+'｜'+esc,0)
    end

    y=65
    preview_set_font_v090(bitmap,18,true,Color.new(255,225,150))
    bitmap.draw_text(16,y,232,24,'敵方預覽',0)
    y=88
    preview_set_font_v090(bitmap,16,false,Color.new(238,243,248))
    enemies=model[:enemies] || []
    if enemies.empty?
      bitmap.draw_text(20,y,228,21,'未知／Runtime 決定',0)
    else
      limit=[enemies.size,4].min
      for i in 0...limit
        row=enemies[i]
        name=preview_species_name_v090(row[:species])
        extra=''
        extra+=' BOSS' if row[:boss]
        extra+=' ELITE' if row[:elite]
        text=(i+1).to_s+'. '+name+' '+preview_enemy_level_text_v090(row)+' '+preview_owned_short_v090(row)+extra
        bitmap.draw_text(20,y+i*20,228,21,text,0)
      end
    end

    if model[:mode]==:stage
      preview_set_font_v090(bitmap,17,true,Color.new(180,235,190))
      bitmap.draw_text(16,171,232,22,'招募候選',0)
      preview_set_font_v090(bitmap,15,false,Color.new(225,240,230))
      recruits=model[:recruits] || []
      texts=[]
      recruits.each do |row|
        texts.push(preview_species_name_v090(row[:species])+(row[:owned] ? '[有]' : '[未]'))
      end
      bitmap.draw_text(20,192,228,21,texts.empty? ? '無' : texts.join('／'),0)
      bitmap.draw_text(20,212,228,21,'首通 '+model[:recruit_first_rate].to_i.to_s+'%｜重複 '+model[:recruit_repeat_rate].to_i.to_s+'%',0)
      preview_set_font_v090(bitmap,15,true,Color.new(255,215,145))
      reward='獎勵  首通 '+preview_join_reward_v090(model[:reward_first])+
        '｜重複 '+preview_join_reward_v090(model[:reward_repeat])
      bitmap.draw_text(16,233,232,21,reward,0)
    else
      preview_set_font_v090(bitmap,16,true,Color.new(255,215,145))
      bitmap.draw_text(16,225,232,22,'勝利：'+preview_join_reward_v090(model[:reward_repeat]),0)
    end

    # 右欄 ---------------------------------------------------------------
    region=model[:region]
    y=41
    if region!=nil
      preview_set_font_v090(bitmap,18,true,Color.new(170,220,255))
      bitmap.draw_text(264,y,232,24,'區域｜'+region[:name].to_s,0)
      preview_set_font_v090(bitmap,16,false,Color.new(220,235,246))
      bitmap.draw_text(268,67,228,21,'難度 '+region[:difficulty].to_i.to_s+'/5｜區域招募 '+region[:recruit_rate].to_i.to_s+'%',0)
      bitmap.draw_text(268,88,228,21,'Elite '+region[:elite_rate].to_i.to_s+'%｜最多 '+region[:elite_max].to_i.to_s+' 隻',0)
      preview_set_font_v090(bitmap,17,true,Color.new(255,225,150))
      bitmap.draw_text(264,113,232,22,'可能 Encounter',0)
      forms=region[:formations] || []
      limit=[forms.size,5].min
      for i in 0...limit
        row=forms[i]
        col=row[:available] ? Color.new(235,241,247) : Color.new(140,150,160)
        preview_set_font_v090(bitmap,15,false,col)
        bitmap.draw_text(268,136+i*20,228,21,preview_region_form_line_v090(row),0)
      end
      if model[:formation]!=nil
        preview_set_font_v090(bitmap,14,true,Color.new(255,205,120))
        bitmap.draw_text(268,237,228,20,'本次 Formation：'+model[:formation].to_s,0)
      end
    else
      preview_set_font_v090(bitmap,18,true,Color.new(170,220,255))
      bitmap.draw_text(264,y,232,24,'區域資料',0)
      preview_set_font_v090(bitmap,16,false,Color.new(195,210,220))
      bitmap.draw_text(268,72,228,22,'此 Encounter 未綁定 Region Ecology',0)
      bitmap.draw_text(268,96,228,22,'Boss：Elite 系統不套用',0) if model[:boss]
    end

    bitmap.fill_rect(12,h-27,w-24,1,Color.new(80,110,135,160))
    preview_set_font_v090(bitmap,15,false,Color.new(180,225,255))
    foot=model[:mode]==:stage ? 'Q/W 切換關卡｜C/B 關閉｜Shift 開戰｜S 驗證' : 'C/B 關閉｜Shift 開戰｜S 驗證'
    bitmap.draw_text(14,h-25,w-28,23,foot,1)
    true
  end
end

#==============================================================================
# ■ Sprite_PMDCollectionPokemonV0931
#------------------------------------------------------------------------------
# 圖鑑右側獨立 PMD 動態預覽。只處理 Idle 動畫，不建立 Game_PMDChessUnit。
#==============================================================================
class Sprite_PMDCollectionPokemonV0931 < Sprite
  def initialize(viewport=nil)
    super(viewport)
    @species_key=nil
    @revealed=false
    @action_data_v0931=nil
    @frame_index_v0931=0
    @frame_wait_v0931=0
    self.visible=false
    self.z=15020
    self.mirror=false
  end

  def clear_species_v0931
    @species_key=nil
    @revealed=false
    @action_data_v0931=nil
    self.bitmap=nil
    self.visible=false
  end

  def set_species_v0931(species_key,revealed)
    reveal=revealed ? true:false
    return if @species_key==species_key && @revealed==reveal && self.bitmap!=nil
    @species_key=species_key
    @revealed=reveal
    if !reveal || species_key==nil
      clear_species_v0931
      return false
    end
    begin
      d=PMD_AC.species_identity_data(species_key)
      if d==nil
        clear_species_v0931
        return false
      end
      species=d[:pmd_species].to_s
      ad=PMD_AC.action_data(species,:idle)
      if ad==nil || ad[:file]==nil
        clear_species_v0931
        return false
      end
      folder=PMD_AC::PMD_ROOT+species+'/'
      if !PMD_AC.bitmap_exists?(folder,ad[:file])
        clear_species_v0931
        return false
      end
      self.bitmap=Cache.load_bitmap(folder,ad[:file])
      @action_data_v0931=ad
      @frame_index_v0931=0
      @frame_wait_v0931=0
      fw=ad[:frame_w].to_i;fh=ad[:frame_h].to_i
      fw=self.bitmap.width if fw<=0
      fh=self.bitmap.height if fh<=0
      maxdim=[fw,fh].max.to_f
      zoom=maxdim<=0.0 ? 1.0 : PMD_AC::DEX_PREVIEW_MAX_SIZE_V0931/maxdim
      zoom=2.15 if zoom>2.15
      zoom=1.00 if zoom<1.00
      self.zoom_x=zoom;self.zoom_y=zoom
      self.ox=fw/2;self.oy=fh
      self.x=PMD_AC::DEX_PREVIEW_X_V0931
      self.y=PMD_AC::DEX_PREVIEW_Y_V0931
      row=PMD_AC.direction_row(ad,PMD_AC::DEX_PREVIEW_DIRECTION_V0931)
      self.src_rect.set(0,row*fh,fw,fh)
      self.visible=true
      return true
    rescue
      clear_species_v0931
      return false
    end
  end

  def update
    super
    return unless self.visible
    ad=@action_data_v0931
    return if ad==nil || self.bitmap==nil
    durations=ad[:durations]
    frames=ad[:frames].to_i
    frames=durations.size if frames<=0 && durations!=nil
    fw=ad[:frame_w].to_i;fh=ad[:frame_h].to_i
    return if frames<=0 || fw<=0 || fh<=0
    if @frame_wait_v0931>0
      @frame_wait_v0931-=1
      return
    end
    duration=8
    if durations!=nil && !durations.empty?
      duration=durations[@frame_index_v0931 % durations.size].to_i
      duration=1 if duration<=0
    end
    @frame_wait_v0931=duration
    @frame_index_v0931+=1
    if @frame_index_v0931>=frames
      @frame_index_v0931=ad[:loop]==false ? frames-1 : 0
    end
    row=PMD_AC.direction_row(ad,PMD_AC::DEX_PREVIEW_DIRECTION_V0931)
    self.src_rect.set(@frame_index_v0931*fw,row*fh,fw,fh)
  end
end

#==============================================================================
# ■ Sprite_PMDCollectionV093 v0.93.1 視覺覆寫
#==============================================================================
class Sprite_PMDCollectionV093
  alias pmd_ac_v0931_initialize initialize unless method_defined?(:pmd_ac_v0931_initialize)
  alias pmd_ac_v0931_update update unless method_defined?(:pmd_ac_v0931_update)

  def initialize(viewport=nil)
    @pokemon_preview_v0931=nil
    pmd_ac_v0931_initialize(viewport)
    @pokemon_preview_v0931=Sprite_PMDCollectionPokemonV0931.new(viewport)
    @pokemon_preview_v0931.z=self.z+10
    refresh
  end

  def visible=(value)
    super(value)
    if @pokemon_preview_v0931!=nil && !@pokemon_preview_v0931.disposed?
      @pokemon_preview_v0931.visible=value && @pokemon_preview_v0931.bitmap!=nil
    end
  end

  def dispose
    if @pokemon_preview_v0931!=nil && !@pokemon_preview_v0931.disposed?
      @pokemon_preview_v0931.dispose
    end
    super
  end

  def update
    pmd_ac_v0931_update
    if @pokemon_preview_v0931!=nil && !@pokemon_preview_v0931.disposed?
      @pokemon_preview_v0931.update
    end
  end

  def current_preview_entry_v0931
    rows=filtered_rows_v093
    return nil if rows.empty?
    clamp_index_v093
    PMD_AC.dex_entry_v093(rows[@index][:species_key])
  end

  def refresh_preview_sprite_v0931(entry)
    return if @pokemon_preview_v0931==nil || @pokemon_preview_v0931.disposed?
    if entry==nil || !entry[:seen]
      @pokemon_preview_v0931.set_species_v0931(nil,false)
    else
      @pokemon_preview_v0931.set_species_v0931(entry[:key],true)
      @pokemon_preview_v0931.visible=self.visible && @pokemon_preview_v0931.bitmap!=nil
    end
  end

  def refresh
    PMD_AC.ensure_dex_migration_v093
    bmp=self.bitmap;bmp.clear
    # 更高不透明度，避免戰場 Sprite 透過文字區造成閱讀干擾。
    bmp.fill_rect(8,8,Graphics.width-16,Graphics.height-16,Color.new(0,0,0,235))
    bmp.fill_rect(16,50,194,320,Color.new(18,24,32,240))
    bmp.fill_rect(216,50,312,320,Color.new(18,24,32,240))
    s=PMD_AC.dex_summary_v093
    draw_text_v093(20,14,504,30,'全國圖鑑  #0001 - #0494',24,Color.new(255,255,255),0,true)
    draw_text_v093(246,17,274,24,'遭遇 '+s[:seen].to_s+'/494｜曾擁有 '+s[:owned].to_s+'/494｜目前 '+s[:current].to_s,14,Color.new(195,225,248),2,false)

    rows=filtered_rows_v093
    clamp_index_v093
    page=PMD_AC::DEX_PAGE_SIZE_V0931
    start=(@index/page)*page
    i=0
    while i<page
      ri=start+i
      break if ri>=rows.size
      d=rows[ri];key=d[:species_key]
      seen=PMD_AC.dex_seen_v093?(key);owned=PMD_AC.dex_ever_owned_v093?(key)
      y=57+i*24
      if ri==@index
        bmp.fill_rect(20,y-1,186,23,Color.new(75,100,135,175))
      end
      name=seen ? d[:name].to_s : '????'
      mark=owned ? '◆' : (seen ? '◇' : ' ')
      draw_text_v093(24,y,178,22,sprintf('%s #%04d %s',mark,d[:national_dex].to_i,name),16,
        seen ? Color.new(242,245,248) : Color.new(130,140,150))
      i+=1
    end
    draw_text_v093(22,347,182,22,'篩選：'+filter_label_v093,15,Color.new(195,225,248),0,true)

    entry=nil
    if rows.empty?
      draw_text_v093(225,95,292,32,'沒有符合此篩選的紀錄',19,Color.new(185,195,205),1,true)
    else
      d=rows[@index];entry=PMD_AC.dex_entry_v093(d[:species_key])
      seen=entry[:seen];owned=entry[:ever_owned]
      title=seen ? sprintf('#%04d  %s',entry[:dex].to_i,entry[:name].to_s) : sprintf('#%04d  ????',entry[:dex].to_i)
      draw_text_v093(225,57,286,30,title,23,Color.new(255,255,255),0,true)

      if !seen
        draw_text_v093(225,105,286,26,'尚未遭遇',19,Color.new(155,165,175),1,true)
        draw_text_v093(225,143,286,22,'在正式戰鬥中遇見後，',16,Color.new(185,195,205))
        draw_text_v093(225,168,286,22,'才會解鎖這隻寶可夢的資料。',16,Color.new(185,195,205))
      else
        # Sprite 預覽框；實際 Sprite 是獨立 Sprite，畫在此框上方。
        bmp.fill_rect(410,88,106,112,Color.new(10,16,23,190))
        bmp.fill_rect(410,88,106,1,Color.new(70,100,125,150))
        bmp.fill_rect(410,199,106,1,Color.new(70,100,125,120))
        bmp.fill_rect(410,88,1,112,Color.new(70,100,125,120))
        bmp.fill_rect(515,88,1,112,Color.new(70,100,125,120))
        draw_text_v093(414,90,98,19,'左前｜動態',13,Color.new(150,190,220),1,false)

        draw_text_v093(225,94,180,22,'屬性：'+PMD_AC.dex_type_text_v093(entry[:types]),17)
        draw_text_v093(225,120,180,22,'定位：'+PMD_AC.dex_role_text_v093(entry[:role]),17)
        draw_text_v093(225,146,180,22,'遭遇 '+entry[:encounter_count].to_s+' 場｜'+PMD_AC.dex_rarity_text_v093(entry[:highest_rarity]),16)
        draw_text_v093(225,172,180,22,'Elite '+entry[:elite_seen].to_s+'｜持有 '+entry[:current_owned].to_s,16)

        if owned
          st=entry[:base_stats]
          draw_text_v093(225,210,286,22,'種族值  HP / 攻 / 防 / 特攻 / 特防 / 速',15,Color.new(195,225,248),0,true)
          draw_text_v093(225,234,286,24,st.collect{|x|x.to_i}.join(' / ')+'   BST '+entry[:bst].to_i.to_s,16)
          names=entry[:line_members].collect do |sp|
            sd=PMD_AC.species_identity_data(sp)
            PMD_AC.dex_seen_v093?(sp) || PMD_AC.dex_ever_owned_v093?(sp) ? sd[:name].to_s : '????'
          end
          draw_text_v093(225,270,286,22,'進化族系',15,Color.new(195,225,248),0,true)
          draw_text_v093(225,294,286,50,names.join(' / '),16)
        else
          draw_text_v093(225,218,286,22,'取得這個種族後，將解鎖',16,Color.new(185,195,205))
          draw_text_v093(225,244,286,22,'種族值與完整進化線。',16,Color.new(185,195,205))
        end
      end
    end

    draw_text_v093(18,381,508,22,'↑↓ 選擇｜←→ 跳10｜Q/W 換頁｜A 篩選｜C/B/Ctrl 關閉',14,Color.new(190,205,220),1)
    refresh_preview_sprite_v0931(entry)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess v0.93.1 版本標記與 Verifier 補充
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0931_start start unless method_defined?(:pmd_ac_v0931_start)
  alias pmd_ac_v0931_refresh_header refresh_header unless method_defined?(:pmd_ac_v0931_refresh_header)

  def start
    pmd_ac_v0931_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.93.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.93.1 preview_font=15..22 dex_list=16 dex_detail=16..23 dex_page=12 pmd_preview=idle_left_front dynamic=1 mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0931_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.93.1',1)
  end

  # v0.93 Collection verifier 原本只確認 Overlay 存在；v0.93.1 同時記錄
  # 新頁數與 PMD 動態預覽規則，方便實機 LOG 確認補丁已載入。
  def verify_collection_ui_v093
    return if @verification_done[:v093_ui]
    pass=defined?(Sprite_PMDCollectionV093) && defined?(Scene_PMDCollectionV093) &&
      defined?(Sprite_PMDCollectionPokemonV0931) && PMD_AC::DEX_PAGE_SIZE_V0931==12
    log_verify_v093('COLLECTION_UI_V093',pass,'overlay=1 map_scene=1 open=Ctrl filter=A page=12')
    log_verify_v093('COLLECTION_UI_READABILITY_V0931',pass,
      'preview_font=15..22 dex_list=16 dex_detail=16..23 pmd_idle=1 facing=left_front direction=1 unseen_hidden=1')
    @verification_done[:v093_ui]=true
  end
end
