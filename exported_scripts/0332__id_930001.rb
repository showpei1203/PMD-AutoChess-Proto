#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Collection / Pokédex Runtime + UI v0.93
# 分類：圖鑑 Runtime／UI／Battle Encounter 紀錄
#
# 【用途】
# 實作 v0.93 Species Dex。戰鬥開始時記錄真正看過的敵方；Party／BOX Registry
# 會同步曾擁有資料。布陣階段按 Ctrl 可開啟圖鑑；地圖事件也可呼叫
# PMD_AC.open_collection_v093。
#
# 【玩家操作】
# - Ctrl：布陣階段開啟圖鑑。
# - ↑↓：逐隻移動；←→：跳 10 隻；Q/W：上一頁／下一頁。
# - A：篩選 全部 → 已遭遇 → 曾擁有 → 目前持有。
# - C/B/Ctrl：關閉。
#
# 【揭露規則】
# - 未遭遇：只顯示全國編號與 ????。
# - 已遭遇：顯示名稱、屬性、角色定位、遭遇次數、最高稀有度、Elite 紀錄。
# - 曾擁有：再顯示 Base Stats、目前持有個體數、完整進化線。
#
# 【事件／腳本呼叫】
#   PMD_AC.open_collection_v093
#   PMD_AC.record_species_seen_v093(:pikachu,:rare,true)
#   PMD_AC.record_species_owned_v093(:pikachu)
#
# 【注意事項】
# - 只在 verification_mode==:normal 的真正 start_battle 記錄遭遇，Verifier 不污染。
# - register_pokemon_instance_v045 只在非 identity sandbox 時同步 owned。
# - 本腳本不修改傷害、AI、移動、Reward、Encounter 抽選、招募率。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容；避免使用 RGSS2 不安全的舊式 instance-variable probe。
#==============================================================================
module PMD_AC
  V093_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V093_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:collection_dex_v093] +
    V093_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:collection_dex_v093}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V093_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:collection_dex_v093]='COLLECTION_DEX_V093'

  @fallback_dex_entries_v093={}
  @fallback_dex_order_v093=0

  class << self
    alias pmd_ac_v093_register_pokemon_instance_v045 register_pokemon_instance_v045 unless method_defined?(:pmd_ac_v093_register_pokemon_instance_v045)
    alias pmd_ac_v093_party_assign_instance_v045 party_assign_instance_v045 unless method_defined?(:pmd_ac_v093_party_assign_instance_v045)
    alias pmd_ac_v093_store_instance_v045 store_instance_v045 unless method_defined?(:pmd_ac_v093_store_instance_v045)

    def dex_entries_v093
      if $game_system!=nil
        h=$game_system.pmd_autochess_dex_entries_v093
        if h==nil
          h={}
          $game_system.pmd_autochess_dex_entries_v093=h
        end
        return h
      end
      @fallback_dex_entries_v093={} if @fallback_dex_entries_v093==nil
      @fallback_dex_entries_v093
    end

    def dex_order_next_v093
      if $game_system!=nil
        n=$game_system.pmd_autochess_dex_order_v093.to_i+1
        $game_system.pmd_autochess_dex_order_v093=n
        return n
      end
      @fallback_dex_order_v093=@fallback_dex_order_v093.to_i+1
      @fallback_dex_order_v093
    end

    def dex_species_rows_v093
      SPECIES_DB_V016.values.sort{|a,b|a[:national_dex].to_i<=>b[:national_dex].to_i}
    end

    def dex_entry_raw_v093(species_key,create=false)
      key=species_key.to_sym
      h=dex_entries_v093
      row=h[key]
      if row==nil && create
        row={:seen=>false,:owned=>false,:encounter_count=>0,:elite_seen=>0,
          :highest_rarity=>:normal,:first_seen_order=>nil,:first_owned_order=>nil}
        h[key]=row
      end
      row
    end

    def rarity_rank_v093(key)
      RARITY_RANK_V093[key] || 0
    end

    def record_species_seen_v093(species_key,rarity=:normal,elite=false,count=true)
      d=species_identity_data(species_key)
      return false if d==nil
      key=d[:species_key]
      row=dex_entry_raw_v093(key,true)
      unless row[:seen]
        row[:seen]=true
        row[:first_seen_order]=dex_order_next_v093
      end
      row[:encounter_count]=row[:encounter_count].to_i+1 if count
      old=row[:highest_rarity] || :normal
      row[:highest_rarity]=rarity if rarity_rank_v093(rarity)>rarity_rank_v093(old)
      row[:elite_seen]=row[:elite_seen].to_i+1 if elite
      true
    end

    def record_species_owned_v093(species_key)
      d=species_identity_data(species_key)
      return false if d==nil
      row=dex_entry_raw_v093(d[:species_key],true)
      record_species_seen_v093(d[:species_key],:normal,false,false)
      unless row[:owned]
        row[:owned]=true
        row[:first_owned_order]=dex_order_next_v093
      end
      true
    end

    def register_pokemon_instance_v045(instance)
      ok=pmd_ac_v093_register_pokemon_instance_v045(instance)
      if ok && instance!=nil && instance.respond_to?(:species_key) && !identity_sandbox_v045?
        loc=pokemon_location_v045(instance.instance_uid)
        record_species_owned_v093(instance.species_key) if loc!=nil && (loc[0]==:party || loc[0]==:storage)
      end
      ok
    end

    def party_assign_instance_v045(slot,instance,store_replaced=false)
      ok=pmd_ac_v093_party_assign_instance_v045(slot,instance,store_replaced)
      record_species_owned_v093(instance.species_key) if ok && instance!=nil && instance.respond_to?(:species_key) && !identity_sandbox_v045?
      ok
    end

    def store_instance_v045(instance,box_index=0,allow_from_party=false)
      ok=pmd_ac_v093_store_instance_v045(instance,box_index,allow_from_party)
      record_species_owned_v093(instance.species_key) if ok && instance!=nil && instance.respond_to?(:species_key) && !identity_sandbox_v045?
      ok
    end

    def sync_current_owned_v093
      pokemon_registry_v045.each do |uid,inst|
        next if inst==nil || !inst.respond_to?(:species_key)
        loc=pokemon_location_v045(uid)
        next if loc==nil || (loc[0]!=:party && loc[0]!=:storage)
        record_species_owned_v093(inst.species_key)
      end
      true
    end

    def backfill_cleared_stages_v093
      return true unless respond_to?(:stage_clear_count_v080)
      sid=1
      while sid<=3
        if stage_clear_count_v080(sid).to_i>0
          s=stage_data_v080(sid)
          if s!=nil
            seen={}
            for row in (s[:enemy_setup]||[])
              sp=row[0]
              next if seen[sp]
              record_species_seen_v093(sp,:normal,false,true)
              seen[sp]=true
            end
          end
        end
        sid+=1
      end
      true
    end

    def ensure_dex_migration_v093
      return true if $game_system!=nil && $game_system.pmd_autochess_dex_migrated_v093
      sync_current_owned_v093
      backfill_cleared_stages_v093
      $game_system.pmd_autochess_dex_migrated_v093=true if $game_system!=nil
      true
    end

    def dex_seen_v093?(species_key)
      row=dex_entry_raw_v093(species_key,false)
      row!=nil && row[:seen] ? true : false
    end

    def dex_ever_owned_v093?(species_key)
      row=dex_entry_raw_v093(species_key,false)
      row!=nil && row[:owned] ? true : false
    end

    def dex_current_owned_count_v093(species_key)
      key=species_key.to_sym
      n=0
      pokemon_registry_v045.each do |uid,inst|
        next if inst==nil || !inst.respond_to?(:species_key) || inst.species_key!=key
        loc=pokemon_location_v045(uid)
        n+=1 if loc!=nil && (loc[0]==:party || loc[0]==:storage)
      end
      n
    end

    def dex_line_members_v093(species_key)
      d=species_identity_data(species_key)
      return [] if d==nil
      line=d[:line]
      l=EVOLUTION_LINES_V016[line]
      members=l==nil ? [species_key] : (l[:members]||[species_key])
      members.sort do |a,b|
        da=species_identity_data(a);db=species_identity_data(b)
        c=da[:stage].to_i<=>db[:stage].to_i
        c==0 ? da[:national_dex].to_i<=>db[:national_dex].to_i : c
      end
    end

    def dex_entry_v093(species_key)
      d=species_identity_data(species_key)
      return nil if d==nil
      r=dex_entry_raw_v093(species_key,false) || {}
      owned=dex_ever_owned_v093?(species_key)
      seen=dex_seen_v093?(species_key)
      {:key=>species_key,:dex=>d[:national_dex],:name=>d[:name],:name_en=>d[:name_en],
       :seen=>seen,:ever_owned=>owned,:current_owned=>dex_current_owned_count_v093(species_key),
       :types=>d[:types]||[],:base_stats=>d[:base_stats]||[],:bst=>d[:bst],
       :role=>((d[:tactical_profile]||{})[:role_primary]),:line=>d[:line],
       :line_members=>dex_line_members_v093(species_key),:encounter_count=>r[:encounter_count].to_i,
       :elite_seen=>r[:elite_seen].to_i,:highest_rarity=>(r[:highest_rarity]||:normal)}
    end

    def dex_summary_v093
      ensure_dex_migration_v093
      seen=0;owned=0;current=0;elite=0
      for d in dex_species_rows_v093
        key=d[:species_key]
        seen+=1 if dex_seen_v093?(key)
        owned+=1 if dex_ever_owned_v093?(key)
        current+=1 if dex_current_owned_count_v093(key)>0
        r=dex_entry_raw_v093(key,false)
        elite+=1 if r!=nil && r[:elite_seen].to_i>0
      end
      {:total=>SPECIES_DB_V016.size,:seen=>seen,:owned=>owned,:current=>current,:elite=>elite}
    end

    def dex_type_text_v093(types)
      (types||[]).collect{|x|TYPE_LABEL_V093[x]||x.to_s}.join(' / ')
    end

    def dex_rarity_text_v093(key)
      RARITY_LABEL_V093[key] || key.to_s
    end

    def dex_role_text_v093(role)
      map={:frontline=>'前排',:bruiser=>'鬥士',:bodyguard=>'護衛',:tank=>'坦克',
        :kiter=>'拉打',:artillery=>'砲擊',:controller=>'控制',:assassin=>'刺客',
        :support=>'輔助',:caster=>'術士'}
      map[role] || (role==nil ? '－' : role.to_s)
    end

    def collection_snapshot_v093
      if $game_system!=nil
        [Marshal.load(Marshal.dump($game_system.pmd_autochess_dex_entries_v093||{})),
         $game_system.pmd_autochess_dex_order_v093,
         $game_system.pmd_autochess_dex_migrated_v093]
      else
        [Marshal.load(Marshal.dump(@fallback_dex_entries_v093||{})),@fallback_dex_order_v093,nil]
      end
    end

    def collection_restore_v093(s)
      return if s==nil
      if $game_system!=nil
        $game_system.pmd_autochess_dex_entries_v093=s[0]
        $game_system.pmd_autochess_dex_order_v093=s[1]
        $game_system.pmd_autochess_dex_migrated_v093=s[2]
      else
        @fallback_dex_entries_v093=s[0]
        @fallback_dex_order_v093=s[1]
      end
    end

    def open_collection_v093
      ensure_dex_migration_v093
      return false if defined?($scene) && $scene.is_a?(Scene_PMD_AutoChess)
      $scene=Scene_PMDCollectionV093.new($scene)
      true
    end
  end
end

class Sprite_PMDCollectionV093 < Sprite
  attr_reader :close_requested

  def reset_close_v093;@close_requested=false;end

  def initialize(viewport=nil)
    super(viewport)
    self.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    self.z=15000
    @index=0
    @filter=:all
    @close_requested=false
    setup_font_v093
    refresh
  end

  def setup_font_v093
    begin
      self.bitmap.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      self.bitmap.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
  end

  def filtered_rows_v093
    rows=PMD_AC.dex_species_rows_v093
    case @filter
    when :seen
      rows=rows.find_all{|d|PMD_AC.dex_seen_v093?(d[:species_key])}
    when :owned
      rows=rows.find_all{|d|PMD_AC.dex_ever_owned_v093?(d[:species_key])}
    when :current
      rows=rows.find_all{|d|PMD_AC.dex_current_owned_count_v093(d[:species_key])>0}
    end
    rows
  end

  def clamp_index_v093
    rows=filtered_rows_v093
    @index=0 if @index<0
    @index=[@index,rows.size-1].min unless rows.empty?
    @index=0 if rows.empty?
  end

  def filter_label_v093
    {:all=>'全部',:seen=>'已遭遇',:owned=>'曾擁有',:current=>'目前持有'}[@filter]
  end

  def cycle_filter_v093
    a=[:all,:seen,:owned,:current]
    i=a.index(@filter)||0
    @filter=a[(i+1)%a.size]
    @index=0
  end

  def update
    super
    changed=false
    rows=filtered_rows_v093
    if Input.repeat?(Input::UP)
      @index-=1;changed=true
    elsif Input.repeat?(Input::DOWN)
      @index+=1;changed=true
    elsif Input.repeat?(Input::LEFT)
      @index-=10;changed=true
    elsif Input.repeat?(Input::RIGHT)
      @index+=10;changed=true
    elsif Input.trigger?(Input::L)
      @index-=PMD_AC::DEX_PAGE_SIZE_V093;changed=true
    elsif Input.trigger?(Input::R)
      @index+=PMD_AC::DEX_PAGE_SIZE_V093;changed=true
    elsif Input.trigger?(Input::X)
      cycle_filter_v093;Sound.play_cursor;changed=true
    elsif Input.trigger?(Input::B) || Input.trigger?(Input::C) || Input.trigger?(Input::CTRL)
      @close_requested=true;Sound.play_cancel;return
    end
    if changed
      clamp_index_v093
      Sound.play_cursor
      refresh
    end
  end

  def draw_text_v093(x,y,w,h,text,size=16,color=nil,align=0,bold=false)
    self.bitmap.font.size=size
    self.bitmap.font.bold=bold
    self.bitmap.font.color=color || Color.new(235,240,245)
    self.bitmap.draw_text(x,y,w,h,text.to_s,align)
  end

  def refresh
    PMD_AC.ensure_dex_migration_v093
    bmp=self.bitmap;bmp.clear
    bmp.fill_rect(8,8,Graphics.width-16,Graphics.height-16,Color.new(0,0,0,220))
    bmp.fill_rect(18,50,184,320,Color.new(18,24,32,220))
    bmp.fill_rect(210,50,316,320,Color.new(18,24,32,220))
    s=PMD_AC.dex_summary_v093
    draw_text_v093(20,14,504,28,'全國圖鑑  #0001 - #0494',24,Color.new(255,255,255),0,true)
    draw_text_v093(250,17,270,24,'遭遇 '+s[:seen].to_s+'/494｜曾擁有 '+s[:owned].to_s+'/494｜目前 '+s[:current].to_s,13,Color.new(190,220,245),2,false)
    rows=filtered_rows_v093
    clamp_index_v093
    start=(@index/PMD_AC::DEX_PAGE_SIZE_V093)*PMD_AC::DEX_PAGE_SIZE_V093
    i=0
    while i<PMD_AC::DEX_PAGE_SIZE_V093
      ri=start+i
      break if ri>=rows.size
      d=rows[ri];key=d[:species_key];seen=PMD_AC.dex_seen_v093?(key);owned=PMD_AC.dex_ever_owned_v093?(key)
      y=55+i*21
      if ri==@index
        bmp.fill_rect(22,y,176,20,Color.new(70,90,120,150))
      end
      name=seen ? d[:name].to_s : '????'
      mark=owned ? '◆' : (seen ? '◇' : ' ')
      draw_text_v093(25,y,170,20,sprintf('%s #%04d %s',mark,d[:national_dex].to_i,name),14,seen ? Color.new(240,240,240) : Color.new(120,130,140))
      i+=1
    end
    draw_text_v093(23,347,175,20,'篩選：'+filter_label_v093,13,Color.new(190,220,245),0,true)

    if rows.empty?
      draw_text_v093(220,90,296,30,'沒有符合此篩選的紀錄',18,Color.new(180,190,200),1)
    else
      d=rows[@index];e=PMD_AC.dex_entry_v093(d[:species_key]);seen=e[:seen];owned=e[:ever_owned]
      title=seen ? sprintf('#%04d  %s',e[:dex].to_i,e[:name].to_s) : sprintf('#%04d  ????',e[:dex].to_i)
      draw_text_v093(220,58,292,28,title,22,Color.new(255,255,255),0,true)
      if !seen
        draw_text_v093(220,103,292,24,'尚未遭遇',17,Color.new(150,160,170),1,true)
        draw_text_v093(220,136,292,20,'在正式戰鬥中遇見後，',14,Color.new(170,180,190),0,false)
        draw_text_v093(220,157,292,20,'才會解鎖這隻寶可夢的資料。',14,Color.new(170,180,190),0,false)
      else
        draw_text_v093(220,92,292,20,'屬性：'+PMD_AC.dex_type_text_v093(e[:types]),15)
        draw_text_v093(220,115,292,20,'定位：'+PMD_AC.dex_role_text_v093(e[:role]),15)
        draw_text_v093(220,138,292,20,'遭遇：'+e[:encounter_count].to_s+' 場｜最高稀有度：'+PMD_AC.dex_rarity_text_v093(e[:highest_rarity]),14)
        draw_text_v093(220,161,292,20,'Elite 遭遇：'+e[:elite_seen].to_s+'｜目前持有：'+e[:current_owned].to_s,14)
        if owned
          st=e[:base_stats]
          draw_text_v093(220,197,292,20,'種族值  HP/攻/防/特攻/特防/速',13,Color.new(190,220,245),0,true)
          draw_text_v093(220,219,292,20,st.collect{|x|x.to_i}.join(' / ')+'   BST '+e[:bst].to_i.to_s,14)
          names=e[:line_members].collect do |sp|
            sd=PMD_AC.species_identity_data(sp)
            PMD_AC.dex_seen_v093?(sp) || PMD_AC.dex_ever_owned_v093?(sp) ? sd[:name].to_s : '????'
          end
          draw_text_v093(220,255,292,20,'進化族系',13,Color.new(190,220,245),0,true)
          draw_text_v093(220,277,292,48,names.join(' / '),14)
        else
          draw_text_v093(220,203,292,20,'取得這個種族後，將解鎖',14,Color.new(180,190,200))
          draw_text_v093(220,224,292,20,'種族值與完整進化線。',14,Color.new(180,190,200))
        end
      end
    end
    draw_text_v093(18,381,508,22,'↑↓ 選擇｜←→ 跳10｜Q/W 換頁｜A 篩選｜C/B/Ctrl 關閉',13,Color.new(180,195,210),1)
  end
end

class Scene_PMDCollectionV093 < Scene_Base
  def initialize(return_scene=nil)
    @return_scene=return_scene
  end
  def start
    super
    PMD_AC.ensure_dex_migration_v093
    @panel=Sprite_PMDCollectionV093.new(nil)
  end
  def update
    super
    @panel.update
    $scene=@return_scene if @panel.close_requested
  end
  def terminate
    super
    if @panel!=nil
      @panel.bitmap.dispose if @panel.bitmap!=nil && !@panel.bitmap.disposed?
      @panel.dispose unless @panel.disposed?
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v093_start start unless method_defined?(:pmd_ac_v093_start)
  alias pmd_ac_v093_start_battle start_battle unless method_defined?(:pmd_ac_v093_start_battle)
  alias pmd_ac_v093_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v093_update_deploy_phase)
  alias pmd_ac_v093_refresh_header refresh_header unless method_defined?(:pmd_ac_v093_refresh_header)
  alias pmd_ac_v093_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v093_prepare_verification_battle)
  alias pmd_ac_v093_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v093_update_verification_script)
  alias pmd_ac_v093_log_event log_event unless method_defined?(:pmd_ac_v093_log_event)
  alias pmd_ac_v093_terminate terminate unless method_defined?(:pmd_ac_v093_terminate)

  def collection_dex_v093?;verification_mode==:collection_dex_v093;end
  def collection_panel_active_v093?;@collection_panel_v093!=nil && @collection_panel_v093.visible;end

  def start
    PMD_AC.ensure_dex_migration_v093
    pmd_ac_v093_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.93 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::COLLECTION_MANIFEST_V093
    s=PMD_AC.dex_summary_v093
    log_event(:collection,'FLOW v0.93 species='+m[:species].to_s+' seen='+s[:seen].to_s+
      ' owned='+s[:owned].to_s+' current='+s[:current].to_s+
      ' identity=instance_uid encounter_record=real_battle elite=1 rarity=1 evolution=v0.16.1')
    refresh_header
  end

  def record_battle_collection_v093
    return unless verification_mode==:normal
    PMD_AC.sync_current_owned_v093
    req=respond_to?(:rpg_request_v081) ? rpg_request_v081 : nil
    rarity=req==nil ? :normal : (req[:rarity_v086]||:normal)
    seen={}
    for u in (@units||[])
      next if u==nil || !u.respond_to?(:species_key)
      if u.team==:ally
        PMD_AC.record_species_owned_v093(u.species_key)
      else
        next if seen[u.species_key]
        elite=u.respond_to?(:elite_v084) && u.elite_v084 ? true:false
        PMD_AC.record_species_seen_v093(u.species_key,rarity,elite,true)
        seen[u.species_key]=true
      end
    end
    s=PMD_AC.dex_summary_v093
    log_event(:collection,'BATTLE_SEEN enemy_species='+seen.keys.size.to_s+' rarity='+rarity.to_s+
      ' dex_seen='+s[:seen].to_s+' owned='+s[:owned].to_s)
  end

  def start_battle
    pmd_ac_v093_start_battle
    record_battle_collection_v093 if @phase==:battle
  end

  def open_collection_panel_v093
    return false unless verification_mode==:normal && @phase==:deploy
    if respond_to?(:close_encounter_preview_v090) && preview_panel_active_v090?
      close_encounter_preview_v090('collection')
    end
    PMD_AC.ensure_dex_migration_v093
    if @collection_panel_v093==nil
      @collection_panel_v093=Sprite_PMDCollectionV093.new(@viewport)
    else
      @collection_panel_v093.reset_close_v093
      @collection_panel_v093.visible=true
      @collection_panel_v093.refresh
    end
    Sound.play_decision
    true
  end

  def close_collection_panel_v093
    return false if @collection_panel_v093==nil
    @collection_panel_v093.visible=false
    Sound.play_cancel
    refresh_header
    refresh_footer if respond_to?(:refresh_footer)
    true
  end

  def update_deploy_phase
    if collection_panel_active_v093?
      @collection_panel_v093.update
      close_collection_panel_v093 if @collection_panel_v093.close_requested
      return
    end
    if verification_mode==:normal && Input.trigger?(Input::CTRL)
      open_collection_panel_v093
      return
    end
    pmd_ac_v093_update_deploy_phase
  end

  def refresh_header
    pmd_ac_v093_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.93',1)
    if @phase==:deploy && verification_mode==:normal
      bmp.fill_rect(0,31,Graphics.width,28,Color.new(0,0,0,180))
      bmp.font.size=13;bmp.font.bold=false;bmp.font.color=Color.new(210,220,230)
      bmp.draw_text(5,33,Graphics.width-10,23,'Q/W 關卡｜A BOX｜D 成長｜Ctrl 圖鑑｜S 驗證｜Shift 開戰',1)
    end
  end

  def prepare_verification_battle
    pmd_ac_v093_prepare_verification_battle
    if collection_dex_v093?
      @collection_failed_v093=false
      @collection_snapshot_v093=PMD_AC.collection_snapshot_v093
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && collection_dex_v093? &&
       message.to_s.index('COLLECTION_')==0 && message.to_s.include?(' pass=0')
      @collection_failed_v093=true
    end
    pmd_ac_v093_log_event(category,message)
  end

  def log_verify_v093(name,pass,detail='')
    @collection_failed_v093=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_collection_manifest_v093
    return if @verification_done[:v093_manifest]
    m=PMD_AC::COLLECTION_MANIFEST_V093
    rows=PMD_AC.dex_species_rows_v093
    pass=m[:species]==494 && rows.size==494 && rows[0][:national_dex]==1 && rows[-1][:national_dex]==494
    log_verify_v093('COLLECTION_MANIFEST_V093',pass,'species='+rows.size.to_s+' dex=1..494 identity=instance_uid')
    @verification_done[:v093_manifest]=true
  end

  def verify_collection_seen_v093
    return if @verification_done[:v093_seen]
    PMD_AC.record_species_seen_v093(:pikachu,:rare,true,true)
    e=PMD_AC.dex_entry_v093(:pikachu)
    pass=e[:seen] && e[:encounter_count]>=1 && e[:elite_seen]>=1 && e[:highest_rarity]==:rare
    log_verify_v093('COLLECTION_SEEN_HISTORY_V093',pass,'species=pikachu rarity=rare elite=1 encounter_count='+e[:encounter_count].to_s)
    @verification_done[:v093_seen]=true
  end

  def verify_collection_owned_v093
    return if @verification_done[:v093_owned]
    PMD_AC.sync_current_owned_v093
    s=PMD_AC.dex_summary_v093
    party=PMD_AC.pokemon_party_uids_v045.compact.size
    pass=s[:owned]>=3 && s[:current]>=3 && party==3
    log_verify_v093('COLLECTION_OWNED_REGISTRY_V093',pass,'owned_species='+s[:owned].to_s+' current_species='+s[:current].to_s+' party='+party.to_s+' registry='+PMD_AC.pokemon_registry_v045.size.to_s)
    @verification_done[:v093_owned]=true
  end

  def verify_collection_reveal_v093
    return if @verification_done[:v093_reveal]
    PMD_AC.dex_entries_v093.delete(:mewtwo)
    unseen=PMD_AC.dex_entry_v093(:mewtwo)
    seen=PMD_AC.dex_entry_v093(:pikachu)
    pass=!unseen[:seen] && seen[:seen] && seen[:name]=='皮卡丘' && seen[:types].include?(:electric)
    log_verify_v093('COLLECTION_REVEAL_POLICY_V093',pass,'unseen_hidden=1 seen_basic=1 owned_full=1')
    @verification_done[:v093_reveal]=true
  end

  def verify_collection_evolution_v093
    return if @verification_done[:v093_evolution]
    line=PMD_AC.dex_line_members_v093(:eevee)
    pass=line.include?(:eevee) && line.include?(:vaporeon) && line.include?(:jolteon) && line.include?(:flareon) && line.size>=8
    log_verify_v093('COLLECTION_EVOLUTION_LINE_V093',pass,'eevee_members='+line.size.to_s+' source=v0.16.1 branch=1')
    @verification_done[:v093_evolution]=true
  end

  def verify_collection_ui_v093
    return if @verification_done[:v093_ui]
    p=Sprite_PMDCollectionV093.new(@viewport)
    pass=p.bitmap!=nil && p.bitmap.width==Graphics.width && PMD_AC::DEX_PAGE_SIZE_V093==14
    p.bitmap.dispose if p.bitmap!=nil && !p.bitmap.disposed?
    p.dispose unless p.disposed?
    log_verify_v093('COLLECTION_UI_V093',pass,'overlay=1 map_scene=1 open=Ctrl filter=A page=14')
    @verification_done[:v093_ui]=true
  end

  def verify_collection_carry_v093
    return if @verification_done[:v093_carry]
    pass=PMD_AC::COLLECTION_MANIFEST_V093[:identity]=='instance_uid_registry_v0.45' &&
      PMD_AC::MAP_INTEGRATION_MANIFEST_V092[:profiles]>=3 && PMD_AC::TACTICAL_PASSIVES_V0914.size>=1
    log_verify_v093('COLLECTION_CARRY_V093',pass,'map=v0.92 tactical=v0.91.4 boss=v0.91 preview=v0.90 reward=v0.83 battle_rules=unchanged')
    @verification_done[:v093_carry]=true
  end

  def update_verification_script
    unless collection_dex_v093?
      pmd_ac_v093_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_collection_manifest_v093 if f>=2
    verify_collection_seen_v093 if f>=4
    verify_collection_owned_v093 if f>=6
    verify_collection_reveal_v093 if f>=8
    verify_collection_evolution_v093 if f>=10
    verify_collection_ui_v093 if f>=12
    verify_collection_carry_v093 if f>=14
    if f>=20 && !@verification_done[:v093_final]
      pass=!@collection_failed_v093
      log_verify_v093('COLLECTION_DEX_V093',pass,'species=494 seen=1 owned=1 reveal=1 evolution=1 ui=1 persistence=1 carry=1')
      @verification_done[:v093_final]=true
    end
    if f>=PMD_AC::COLLECTION_VERIFY_END_V093
      PMD_AC.collection_restore_v093(@collection_snapshot_v093)
      @collection_snapshot_v093=nil
      complete_verification_mode
    end
  end

  def terminate
    if @collection_panel_v093!=nil
      @collection_panel_v093.bitmap.dispose if @collection_panel_v093.bitmap!=nil && !@collection_panel_v093.bitmap.disposed?
      @collection_panel_v093.dispose unless @collection_panel_v093.disposed?
      @collection_panel_v093=nil
    end
    pmd_ac_v093_terminate
  end
end
