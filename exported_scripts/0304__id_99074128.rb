#==============================================================================
# PMD AutoChess Proto v0.85
# Battle Presentation Profile Runtime（戰鬥背景／BGM）
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 讀取前一支「PMD AutoChess Battle Presentation Data v0.85」，把背景與 BGM
# 實際套到 Scene_PMD_AutoChess。一般要換圖／換歌，請改 Data，不要直接改這支 Runtime。
#
# 【執行順序】
# Battle Request 建立
#   ↓
# 解析：全域 < 地圖 < Encounter Profile < Stage/Boss/Encounter < 單場 options
#   ↓
# create_background 載入 Graphics/Battlebacks 圖片
#   ↓
# Scene_Map 進戰鬥時播放指定 BGM
#   ↓
# 打完後仍由 v0.81 還原原地圖 BGM / BGS
#
# 【常用設定】
# 1. 地圖預設：改 MAP_BATTLE_PRESENTATION_V085。
# 2. Boss／事件戰：資料 Hash 加 :presentation=>:boss_demo。
# 3. 單場覆蓋：
#      PMD_AC.start_battle_v081(:roadside_pikachu,{
#        :battleback=>'bg_002.jpg', :bgm=>'Battle',
#        :bgm_volume=>90, :bgm_pitch=>100
#      })
#
# 【背景找不到時】
# 不 Crash，退回原本 PMD AutoChess 深色背景，並在 Battle LOG 記錄 missing。
#
# 【Stage】
# Stage Data 寫 :presentation 後，Q/W 換關卡會同步刷新背景與 BGM。
#
# 【BGM 特殊值】
# nil=VX 系統 Battle BGM；false=靜音；:map=沿用進戰前地圖 BGM。
#
# 【驗證】
# S 切到 BATTLE_PRESENTATION_V085，再 Shift：
#   BATTLE_PRESENTATION_MANIFEST_V085 pass=1
#   BATTLE_PRESENTATION_MAP_V085 pass=1
#   BATTLE_PRESENTATION_OVERRIDE_V085 pass=1
#   BATTLE_PRESENTATION_BOSS_V085 pass=1
#   BATTLE_PRESENTATION_ASSET_V085 pass=1
#   BATTLE_PRESENTATION_CARRY_V085 pass=1
#   BATTLE_PRESENTATION_V085 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  V085_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V085_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:battle_presentation_v085] +
    V085_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:battle_presentation_v085}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V085_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:battle_presentation_v085]='BATTLE_PRESENTATION_V085'

  class << self
    def play_battle_presentation_bgm_v085(request=nil,map_id=nil,force=false)
      p=resolve_battle_presentation_v085(request,map_id)
      bgm=p[:bgm]
      begin
        if bgm==false
          RPG::BGM.stop
          return true
        elsif bgm==:map
          if $game_temp!=nil && $game_temp.map_bgm!=nil
            cur=RPG::BGM.last
            target=$game_temp.map_bgm
            same=cur!=nil && cur.name.to_s==target.name.to_s &&
              cur.volume.to_i==target.volume.to_i && cur.pitch.to_i==target.pitch.to_i
            target.play if force || !same
          end
          return true
        elsif bgm==nil
          # nil = VX 系統 Battle BGM。Scene_Map 的 v0.81 流程通常已播放；
          # 直接進 Scene 時也在這裡補播。
          if $game_system!=nil && $game_system.battle_bgm!=nil
            cur=RPG::BGM.last
            target=$game_system.battle_bgm
            same=cur!=nil && cur.name.to_s==target.name.to_s &&
              cur.volume.to_i==target.volume.to_i && cur.pitch.to_i==target.pitch.to_i
            target.play if force || !same
          end
          return true
        end
        name=bgm.to_s
        vol=[[p[:bgm_volume].to_i,0].max,100].min
        pitch=[[p[:bgm_pitch].to_i,50].max,150].min
        cur=RPG::BGM.last
        same=cur!=nil && cur.name.to_s==name && cur.volume.to_i==vol && cur.pitch.to_i==pitch
        RPG::BGM.new(name,vol,pitch).play if force || !same
        true
      rescue
        false
      end
    end

    def stage_presentation_request_v085(stage_id=nil)
      return nil unless respond_to?(:stage_data_v080)
      sid=stage_id==nil ? current_stage_id_v080 : stage_id
      d=stage_data_v080(sid)
      return nil if d==nil
      {:kind=>:stage,:stage_id=>sid,:key=>('stage_'+sid.to_i.to_s).to_sym,
       :name=>d[:name],:options=>{}}
    end
  end
end

class Scene_Map
  alias pmd_ac_v085_call_pmd_autochess_v081 call_pmd_autochess_v081 unless method_defined?(:pmd_ac_v085_call_pmd_autochess_v081)
  def call_pmd_autochess_v081
    req=PMD_AC.battle_request_v081
    map_id=$game_map==nil ? nil : $game_map.map_id
    pmd_ac_v085_call_pmd_autochess_v081
    PMD_AC.play_battle_presentation_bgm_v085(req,map_id,false)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v085_start start unless method_defined?(:pmd_ac_v085_start)
  alias pmd_ac_v085_create_background create_background unless method_defined?(:pmd_ac_v085_create_background)
  alias pmd_ac_v085_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v085_update_deploy_phase)
  alias pmd_ac_v085_refresh_header refresh_header unless method_defined?(:pmd_ac_v085_refresh_header)
  alias pmd_ac_v085_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v085_prepare_verification_battle)
  alias pmd_ac_v085_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v085_update_verification_script)
  alias pmd_ac_v085_log_event log_event unless method_defined?(:pmd_ac_v085_log_event)

  def presentation_request_v085
    req=PMD_AC.battle_request_v081
    return req if req!=nil
    return PMD_AC.stage_presentation_request_v085 if PMD_AC.respond_to?(:current_stage_id_v080)
    nil
  end

  def resolved_presentation_v085
    PMD_AC.resolve_battle_presentation_v085(presentation_request_v085,
      $game_map==nil ? nil : $game_map.map_id)
  end

  def default_background_bitmap_v085
    bmp=Bitmap.new(Graphics.width,Graphics.height)
    bmp.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(18,26,36))
    bmp.fill_rect(0,0,Graphics.width/2,Graphics.height,Color.new(25,47,68,120))
    bmp.fill_rect(Graphics.width/2,0,Graphics.width/2,Graphics.height,Color.new(68,31,31,120))
    bmp
  end

  def apply_background_presentation_v085(presentation=nil,write_log=true)
    return false if @background_sprite==nil
    p=presentation || resolved_presentation_v085
    file=PMD_AC.battleback_file_v085(p[:battleback])
    old=@background_sprite.bitmap
    bmp=nil
    if file!=nil
      begin
        source=Cache.load_bitmap('Graphics/Battlebacks/',file)
        bmp=Bitmap.new(Graphics.width,Graphics.height)
        bmp.stretch_blt(bmp.rect,source,source.rect)
      rescue
        bmp=nil
      end
    end
    bmp=default_background_bitmap_v085 if bmp==nil
    @background_sprite.bitmap=bmp
    if old!=nil && old!=bmp && !old.disposed?
      begin
        old.dispose
      rescue
      end
    end
    if write_log && respond_to?(:log_event)
      text=file==nil ? 'default' : file
      text+=' requested_missing='+p[:battleback].to_s if file==nil && p[:battleback]!=nil
      log_event(:battle_presentation,'BACKGROUND '+text)
    end
    file!=nil || p[:battleback]==nil
  end

  def create_background
    pmd_ac_v085_create_background
    apply_background_presentation_v085(resolved_presentation_v085,false)
  end

  def apply_full_presentation_v085(force_bgm=false)
    p=resolved_presentation_v085
    apply_background_presentation_v085(p,true)
    PMD_AC.play_battle_presentation_bgm_v085(presentation_request_v085,
      $game_map==nil ? nil : $game_map.map_id,force_bgm)
    @presentation_signature_v085=[p[:battleback],p[:bgm],p[:bgm_volume],p[:bgm_pitch]]
    log_event(:battle_presentation,
      'APPLY battleback='+(p[:battleback]==nil ? 'default' : p[:battleback].to_s)+
      ' bgm='+(p[:bgm]==nil ? 'system' : p[:bgm].to_s)+
      ' volume='+p[:bgm_volume].to_i.to_s+' pitch='+p[:bgm_pitch].to_i.to_s)
    true
  end

  def start
    pmd_ac_v085_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.85 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::BATTLE_PRESENTATION_MANIFEST_V085
    log_event(:battle_presentation,
      'FLOW v0.85 profiles='+m[:profiles].to_s+' map_defaults='+m[:map_defaults].to_s+
      ' contexts=map,stage,wild,boss,scripted,custom priority=direct>battle>profile>map>default')
    apply_full_presentation_v085(false)
    refresh_header
  end

  def update_deploy_phase
    before=nil
    if !rpg_external_battle_v081? && verification_mode==:normal && PMD_AC.respond_to?(:current_stage_id_v080)
      before=PMD_AC.current_stage_id_v080
    end
    pmd_ac_v085_update_deploy_phase
    if before!=nil
      after=PMD_AC.current_stage_id_v080
      apply_full_presentation_v085(false) if after!=before
    end
  end

  def refresh_header
    pmd_ac_v085_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.85',1)
  end

  def battle_presentation_v085?
    verification_mode==:battle_presentation_v085
  end

  def prepare_verification_battle
    pmd_ac_v085_prepare_verification_battle
    @battle_presentation_v085_failed=false if battle_presentation_v085?
  end

  def log_event(category,message)
    if category.to_s=='verify' && battle_presentation_v085? &&
       message.to_s.index('BATTLE_PRESENTATION_')==0 && message.to_s.include?(' pass=0')
      @battle_presentation_v085_failed=true
    end
    pmd_ac_v085_log_event(category,message)
  end

  def log_verify_v085(name,pass,detail='')
    @battle_presentation_v085_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_battle_presentation_manifest_v085
    return if @verification_done[:v085_manifest]
    m=PMD_AC::BATTLE_PRESENTATION_MANIFEST_V085
    e=PMD_AC.battle_presentation_errors_v085
    pass=m[:profiles]>=4 && e.empty?
    log_verify_v085('BATTLE_PRESENTATION_MANIFEST_V085',pass,
      'profiles='+m[:profiles].to_s+' supports='+m[:supports].join(',')+' errors=['+e.join(',')+']')
    @verification_done[:v085_manifest]=true
  end

  def verify_battle_presentation_map_v085
    return if @verification_done[:v085_map]
    had=PMD_AC::MAP_BATTLE_PRESENTATION_V085.has_key?(999)
    old=PMD_AC::MAP_BATTLE_PRESENTATION_V085[999]
    PMD_AC::MAP_BATTLE_PRESENTATION_V085[999]=:forest_demo
    p=PMD_AC.resolve_battle_presentation_v085({:kind=>:wild,:key=>:none,:options=>{}},999)
    if had
      PMD_AC::MAP_BATTLE_PRESENTATION_V085[999]=old
    else
      PMD_AC::MAP_BATTLE_PRESENTATION_V085.delete(999)
    end
    pass=p[:battleback]=='bg_001.jpg' && p[:bgm]=='Battle'
    log_verify_v085('BATTLE_PRESENTATION_MAP_V085',pass,
      'map=999 profile=forest_demo bg='+p[:battleback].to_s+' bgm='+p[:bgm].to_s)
    @verification_done[:v085_map]=true
  end

  def verify_battle_presentation_override_v085
    return if @verification_done[:v085_override]
    req={:kind=>:scripted,:key=>:none,:presentation=>:forest_demo,
      :options=>{:presentation=>:story_demo,:battleback=>'bg_002.jpg',:bgm=>'Battle',
        :bgm_volume=>77,:bgm_pitch=>105}}
    p=PMD_AC.resolve_battle_presentation_v085(req,nil)
    pass=p[:battleback]=='bg_002.jpg' && p[:bgm]=='Battle' &&
      p[:bgm_volume].to_i==77 && p[:bgm_pitch].to_i==105
    log_verify_v085('BATTLE_PRESENTATION_OVERRIDE_V085',pass,
      'direct=1 bg='+p[:battleback].to_s+' bgm='+p[:bgm].to_s+
      ' vol='+p[:bgm_volume].to_s+' pitch='+p[:bgm_pitch].to_s)
    @verification_done[:v085_override]=true
  end

  def verify_battle_presentation_boss_v085
    return if @verification_done[:v085_boss]
    req={:kind=>:boss,:key=>:none,:presentation=>:boss_demo,:options=>{}}
    p=PMD_AC.resolve_battle_presentation_v085(req,nil)
    pass=p[:battleback]=='bg_002.jpg' && p[:bgm]=='lotr-ttt'
    log_verify_v085('BATTLE_PRESENTATION_BOSS_V085',pass,
      'profile=boss_demo bg='+p[:battleback].to_s+' bgm='+p[:bgm].to_s+' recruit=off_v0.81')
    @verification_done[:v085_boss]=true
  end

  def verify_battle_presentation_asset_v085
    return if @verification_done[:v085_asset]
    a=PMD_AC.battleback_file_v085('bg_001.jpg')
    b=PMD_AC.battleback_file_v085('bg_002.jpg')
    music=PMD_AC.bgm_file_exists_v085('Battle') && PMD_AC.bgm_file_exists_v085('lotr-ttt')
    pass=a!=nil && b!=nil && music
    log_verify_v085('BATTLE_PRESENTATION_ASSET_V085',pass,
      'bg1='+(a==nil ? 'missing':a)+' bg2='+(b==nil ? 'missing':b)+' bgm='+(music ? '1':'0'))
    @verification_done[:v085_asset]=true
  end

  def verify_battle_presentation_carry_v085
    return if @verification_done[:v085_carry]
    pass=PMD_AC::RPG_ENCOUNTER_MANIFEST_V081[:boss_recruitable]==false &&
      PMD_AC::ENCOUNTER_CONFIG_MANIFEST_V084[:boss_elite]==false &&
      PMD_AC::PARTY_CAPACITY_V045==3
    log_verify_v085('BATTLE_PRESENTATION_CARRY_V085',pass,
      'encounter=v0.81 field=v0.82 loot=v0.83 config=v0.84 party=v0.78 progression=v0.77.1 balance=v0.75')
    @verification_done[:v085_carry]=true
  end

  def update_verification_script
    unless battle_presentation_v085?
      pmd_ac_v085_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_battle_presentation_manifest_v085 if f>=2
    verify_battle_presentation_map_v085 if f>=4
    verify_battle_presentation_override_v085 if f>=6
    verify_battle_presentation_boss_v085 if f>=8
    verify_battle_presentation_asset_v085 if f>=10
    verify_battle_presentation_carry_v085 if f>=12
    if f>=16 && !@verification_done[:v085_final]
      pass=!@battle_presentation_v085_failed
      log_verify_v085('BATTLE_PRESENTATION_V085',pass,
        'manifest=1 map=1 override=1 boss=1 asset=1 carry=1')
      @verification_done[:v085_final]=true
    end
    complete_verification_mode if f>=PMD_AC::BATTLE_PRESENTATION_VERIFY_END_V085
  end
end
