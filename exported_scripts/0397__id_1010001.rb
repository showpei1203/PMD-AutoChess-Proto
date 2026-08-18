# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Map / NPC / Story Vertical Slice v1.01
# 分類：RPG 主線探索／真實 Scene_Map／NPC／事件遭遇／Boss 路線
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 將 v1.00 的「營地選單 -> 直接戰鬥」Foundation Shell，往真正 RPG 垂直切片推進。
# 本版使用 Map004～Map006 三張真正 Scene_Map：林緣入口、林緣深處、蜂巢林地。
# 玩家可走動、與 NPC／調查點互動、觸發野外戰、特殊皮卡丘、Boss、補給與檢查點，
# 戰鬥後仍回到原本地圖位置。戰鬥、招募、成長、Party/BOX、圖鑑、AI、Boss 等資料
# 全部沿用既有 v0.78～v1.00 runtime，不建立第二套 RPG 或 Combat Logic。
#------------------------------------------------------------------------------
# 【主要設定項】
# VERTICAL_MAPS_V101：Map ID、名稱、背景與入口位置。
# VERTICAL_RANDOM_MIN/MAX_V101：Map004/005 行走隨機遭遇步數。
# VERTICAL_LOG_V101：只記本版地圖流程必要 marker，不輸出歷史流水帳。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. Map004/005 啟用 forest_edge Region Ecology；terrain_tags=[]，因本測試地圖使用
#    Parallax + 空白 Tile Layer。Map006 為 Boss 區，不開隨機遇敵。
# 2. Map004～006 的空白 Tile Layer 只在本三張地圖採「區域內可走」，NPC 仍依
#    Game_Character 原生碰撞阻擋；不影響其他正式地圖 passability。
# 3. Wild / Special / Boss 一律透過 v1.00 Foundation Request，因此 wild_wins、
#    special_cleared、boss_cleared、Recruit、Reward、Field HP Carry 照舊。
# 4. Pokémon 個體身份永遠 instance_uid；本腳本不以 actor id 取代個體。
# 5. 本版不修改 Dynamic Tactical Role、Spatial Framework、Damage Formula、Skill FX。
# 6. v1.00.8 Startup Cooperative Loader 完整保留；不使用 real-time catch-up。
#------------------------------------------------------------------------------
# 【玩家操作】
# - 戰前布陣按 F8 -> 林緣營地。
# - 選「進入林緣調查區」會真正進 Map004。
# - 地圖：方向鍵移動、C 與 NPC／調查點互動、F8 回林緣營地。
# - Map004 補給點：治療目前隊伍並把目前位置設為 checkpoint。
# - Map004/005：走路會依步數觸發 forest_edge 野戰，也可調查可見野戰點。
# - 林緣勝利 1 次：Map005 特殊皮卡丘可挑戰；招募成功後完成該支線。
# - 林緣勝利 2 次：Map005 北側可進 Map006；Map006 挑戰大針蜂 Boss。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式與範例】
# 進入垂直切片入口：
#   PMD_AC.enter_vertical_slice_v101(4)
# 手動野戰：
#   PMD_AC.vertical_wild_v101(:field_marker)
# 補給／檢查點：
#   PMD_AC.vertical_checkpoint_v101
# 特殊皮卡丘：
#   PMD_AC.vertical_special_v101
# Boss：
#   PMD_AC.vertical_boss_v101
# 地圖轉移：
#   PMD_AC.transfer_vertical_v101(5,8,11,8)
#------------------------------------------------------------------------------
# 【注意事項】
# - Map004～006 為 v1.01 垂直切片專用；正式美術地圖可日後直接替換 rvdata，
#   事件與戰鬥橋接 API 不需要重寫。
# - Parallax 目前沿用專案既有林地 Battleback 作為「功能切片」場景底圖，目的先驗證
#   RPG 流程；後續 Map Art Pass 再換正式 Tile/Parallax 美術。
# - 避免直接修改 Frozen Combat Core；本版全部採 trailing alias / content hook。
#==============================================================================
module PMD_AC
  VERTICAL_SLICE_VERSION_V101='1.01'
  VERTICAL_LOG_V101='PMD_MapStoryVerticalSlice_v1.01.log'
  VERTICAL_VERIFY_END_V101=210
  VERTICAL_RANDOM_MIN_V101=12
  VERTICAL_RANDOM_MAX_V101=20

  VERTICAL_MAPS_V101={
    4=>{:name=>'林緣入口',:parallax=>'PMD_ForestEdge',:start=>[8,11,8]},
    5=>{:name=>'林緣深處',:parallax=>'PMD_ForestDeep',:start=>[8,11,8]},
    6=>{:name=>'蜂巢林地',:parallax=>'PMD_ForestEdge',:start=>[8,11,8]}
  }

  VERTICAL_MANIFEST_V101={
    :version=>'1.01.0',
    :maps=>[4,5,6],
    :scene_map=>true,
    :npc=>true,
    :checkpoint=>true,
    :random_encounter=>true,
    :visible_encounter=>true,
    :special=>RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100,
    :boss=>RPG_FOUNDATION_BOSS_ENCOUNTER_V100,
    :identity=>:instance_uid,
    :foundation=>'v1.00',
    :startup=>'v1.00.8',
    :combat_core_direct_modification=>false
  }

  class << self
    def vertical_map_v101?(map_id=nil)
      mid=map_id
      mid=$game_map.map_id if mid==nil && $game_map!=nil
      VERTICAL_MAPS_V101.has_key?(mid.to_i)
    end

    def vertical_map_name_v101(map_id=nil)
      mid=map_id
      mid=$game_map.map_id if mid==nil && $game_map!=nil
      row=VERTICAL_MAPS_V101[mid.to_i]
      row==nil ? '林緣調查區' : row[:name].to_s
    end

    def vertical_log_v101(text)
      mode=@vertical_log_started_v101 ? 'ab' : 'wb'
      File.open(VERTICAL_LOG_V101,mode) do |f|
        unless @vertical_log_started_v101
          f.write("PMD AutoChess Map / NPC / Story Vertical Slice v1.01\r\n")
          f.write("LOG Profile: current-test minimal\r\n")
          f.write("============================================================\r\n")
        end
        f.write('['+(Time.now.strftime('%H:%M:%S') rescue 'time')+'] '+text.to_s+"\r\n")
      end
      @vertical_log_started_v101=true
      true
    rescue
      false
    end

    def vertical_message_v101(lines)
      return false if $game_message==nil || $game_message.busy
      rows=lines.is_a?(Array) ? lines : [lines]
      rows[0,4].each{|line|$game_message.texts.push(line.to_s)}
      $game_message.background=0
      $game_message.position=2
      true
    rescue
      false
    end

    def vertical_objective_v101
      s=rpg_foundation_state_v100
      return '蜂巢霸主已討伐。返回營地整理隊伍與收集成果。' if s[:boss_cleared]
      return '先在林緣取得 1 場勝利，確認野生寶可夢異常。' if s[:wild_wins].to_i<1
      if !s[:special_cleared]
        return '特殊足跡已出現；林緣深處可調查皮卡丘。'
      end
      return '再取得 1 場林緣勝利，找出蜂群來源。' if s[:wild_wins].to_i<2
      '通往蜂巢林地的道路已開放。前往討伐蜂巢霸主。'
    end

    def vertical_status_text_v101
      s=rpg_foundation_state_v100
      '林緣勝利 '+s[:wild_wins].to_i.to_s+'｜皮卡丘 '+(s[:special_cleared] ? '完成':'未完成')+
        '｜Boss '+(s[:boss_cleared] ? 'CLEAR':'未討伐')
    end

    def transfer_vertical_v101(map_id,x,y,direction=2)
      return false if $game_player==nil
      mid=map_id.to_i
      return false unless vertical_map_v101?(mid)
      vertical_log_v101('TRANSFER to='+mid.to_s+' name='+vertical_map_name_v101(mid))
      if defined?(Scene_Map) && $scene.is_a?(Scene_Map)
        $game_player.reserve_transfer(mid,x.to_i,y.to_i,direction.to_i)
      else
        $game_map.setup(mid) if $game_map!=nil
        $game_player.moveto(x.to_i,y.to_i)
        $game_player.set_direction(direction.to_i)
        $game_map.autoplay if $game_map!=nil
        $scene=Scene_Map.new
      end
      true
    end

    def enter_vertical_slice_v101(map_id=4)
      mid=map_id.to_i
      row=VERTICAL_MAPS_V101[mid] || VERTICAL_MAPS_V101[4]
      vertical_log_v101('ENTER_REQUEST map='+mid.to_s+' objective='+vertical_objective_v101)
      transfer_vertical_v101(mid,row[:start][0],row[:start][1],row[:start][2])
    end

    def return_vertical_camp_v101
      vertical_log_v101('RETURN_CAMP '+vertical_status_text_v101)
      $scene=Scene_PMD_RPGFoundationV100.new
      true
    end

    def vertical_checkpoint_v101
      checkpoint_here_v092
      heal_party_here_v092
      vertical_log_v101('CHECKPOINT map='+($game_map==nil ? '0':$game_map.map_id.to_s)+
        ' x='+($game_player==nil ? '0':$game_player.x.to_s)+' y='+($game_player==nil ? '0':$game_player.y.to_s))
      vertical_message_v101(['補給完成。隊伍 HP 已恢復。','目前位置已設為檢查點。'])
      true
    end

    def vertical_guide_v101(zone)
      s=rpg_foundation_state_v100
      case zone
      when :entrance
        if s[:boss_cleared]
          vertical_message_v101(['巡林員：蜂群已經散開了。','這一帶終於恢復安靜，辛苦了。'])
        elsif s[:wild_wins].to_i<=0
          vertical_message_v101(['巡林員：最近蜂群把野生寶可夢逼到道路上。','先在林緣打一場，看看牠們到底在躲什麼。','補給箱可以治療，也會記錄檢查點。'])
        else
          vertical_message_v101(['巡林員：足跡一路往北，蜂群也越來越密。',vertical_objective_v101])
        end
      when :deep
        vertical_message_v101(['調查員：這裡的寶可夢明顯比入口躁動。',vertical_objective_v101])
      when :hive
        vertical_message_v101(['調查員：蜂巢就在前面。','大針蜂不是一般野戰，不能逃跑，也不能招募。'])
      end
      vertical_log_v101('NPC zone='+zone.to_s+' '+vertical_status_text_v101)
      true
    end

    def mark_vertical_request_v101(request)
      return nil if request==nil
      request[:options]={} if request[:options]==nil
      request[:options][:vertical_slice_v101]=true
      request[:options][:vertical_origin_map_v101]=($game_map==nil ? 0:$game_map.map_id.to_i)
      request
    end

    def vertical_wild_v101(source=:field_marker)
      vertical_log_v101('BATTLE_LAUNCH kind=wild source='+source.to_s+' map='+($game_map==nil ? '0':$game_map.map_id.to_s))
      r=mark_vertical_request_v101(rpg_foundation_wild_request_v100)
      launch_rpg_foundation_request_v100(r)
    end

    def vertical_special_v101
      s=rpg_foundation_state_v100
      if s[:special_cleared]
        vertical_message_v101(['皮卡丘留下的足跡已經平靜下來。','這個特殊遭遇已完成。'])
        vertical_log_v101('SPECIAL already_cleared=1')
        return false
      end
      unless rpg_foundation_special_unlocked_v100?
        vertical_message_v101(['草叢裡只有很淡的腳印。','先在林緣取得 1 場勝利，再回來調查。'])
        vertical_log_v101('SPECIAL locked=1 wild_wins='+s[:wild_wins].to_i.to_s)
        return false
      end
      vertical_log_v101('BATTLE_LAUNCH kind=special encounter='+RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100.to_s)
      r=mark_vertical_request_v101(rpg_foundation_special_request_v100)
      launch_rpg_foundation_request_v100(r)
    end

    def vertical_boss_gate_v101
      if rpg_foundation_boss_unlocked_v100?
        transfer_vertical_v101(6,8,11,8)
      else
        s=rpg_foundation_state_v100
        vertical_message_v101(['前方蜂群太密，現在還不能通過。',
          '林緣勝利需要 2 次，目前 '+s[:wild_wins].to_i.to_s+' 次。'])
        vertical_log_v101('BOSS_GATE locked=1 wild_wins='+s[:wild_wins].to_i.to_s)
        false
      end
    end

    def vertical_boss_v101
      s=rpg_foundation_state_v100
      unless rpg_foundation_boss_unlocked_v100?
        vertical_message_v101(['蜂巢周圍還無法安全接近。','先完成更多林緣戰鬥。'])
        vertical_log_v101('BOSS locked=1 wild_wins='+s[:wild_wins].to_i.to_s)
        return false
      end
      vertical_log_v101('BATTLE_LAUNCH kind=boss encounter='+RPG_FOUNDATION_BOSS_ENCOUNTER_V100.to_s+
        ' rematch='+(s[:boss_cleared] ? '1':'0'))
      r=mark_vertical_request_v101(rpg_foundation_boss_request_v100)
      launch_rpg_foundation_request_v100(r)
    end

    def ensure_vertical_binding_v101(map_id)
      mid=map_id.to_i
      return false unless mid==4 || mid==5
      h=runtime_map_bindings_v092
      row=h[mid]
      unless row!=nil && row[:vertical_slice_v101]
        h[mid]={:profile=>:forest_route,:terrain_tags=>[],:min_steps=>VERTICAL_RANDOM_MIN_V101,
          :max_steps=>VERTICAL_RANDOM_MAX_V101,:vertical_slice_v101=>true}
      end
      apply_map_binding_v092(mid,false)
    end

    def vertical_event_v101(id,x,y,name,graphic,trigger,priority,script,through=false)
      ev=RPG::Event.new(x.to_i,y.to_i)
      ev.id=id.to_i
      ev.name=name.to_s
      page=RPG::Event::Page.new
      page.trigger=trigger.to_i
      page.priority_type=priority.to_i
      page.through=through ? true:false
      page.walk_anime=true
      page.step_anime=false
      page.direction_fix=false
      page.move_type=0
      page.move_speed=3
      page.move_frequency=3
      page.graphic.character_name=graphic.to_s if graphic!=nil && graphic.to_s!=''
      page.graphic.character_index=0
      page.graphic.direction=2
      page.graphic.pattern=1
      page.list=[RPG::EventCommand.new(355,0,[script.to_s]),RPG::EventCommand.new(0,0,[])]
      ev.pages=[page]
      ev
    end

    def vertical_event_specs_v101(map_id)
      case map_id.to_i
      when 4
        [
          [1,8,9,'V101_巡林員','$Actor7_3',0,1,"PMD_AC.vertical_guide_v101(:entrance)",false],
          [2,3,10,'V101_補給檢查點','$Actor12_1',0,1,"PMD_AC.vertical_checkpoint_v101",false],
          [3,3,5,'V101_野戰點A','$cat',0,1,"PMD_AC.vertical_wild_v101(:marker_a)",false],
          [4,13,6,'V101_野戰點B','$cat',0,1,"PMD_AC.vertical_wild_v101(:marker_b)",false],
          [5,8,1,'V101_往林緣深處','',1,0,"PMD_AC.transfer_vertical_v101(5,8,11,8)",true],
          [6,8,12,'V101_返回營地','',1,0,"PMD_AC.return_vertical_camp_v101",true]
        ]
      when 5
        [
          [1,4,9,'V101_深處調查員','$Actor4_1',0,1,"PMD_AC.vertical_guide_v101(:deep)",false],
          [2,3,4,'V101_野戰點C','$cat',0,1,"PMD_AC.vertical_wild_v101(:marker_c)",false],
          [3,13,5,'V101_野戰點D','$cat',0,1,"PMD_AC.vertical_wild_v101(:marker_d)",false],
          [4,8,6,'V101_特殊足跡','$Actor19_1',0,1,"PMD_AC.vertical_special_v101",false],
          [5,8,12,'V101_回林緣入口','',1,0,"PMD_AC.transfer_vertical_v101(4,8,2,2)",true],
          [6,8,1,'V101_往蜂巢林地','',1,0,"PMD_AC.vertical_boss_gate_v101",true]
        ]
      when 6
        [
          [1,4,9,'V101_蜂巢調查員','$Actor26_1',0,1,"PMD_AC.vertical_guide_v101(:hive)",false],
          [2,8,5,'V101_蜂巢霸主','$Actor28_1',0,1,"PMD_AC.vertical_boss_v101",false],
          [3,8,12,'V101_回林緣深處','',1,0,"PMD_AC.transfer_vertical_v101(5,8,2,2)",true]
        ]
      else
        []
      end
    end

    def inject_vertical_events_v101(game_map)
      mid=game_map.map_id.to_i
      return false unless vertical_map_v101?(mid)
      specs=vertical_event_specs_v101(mid)
      specs.each do |row|
        ev=vertical_event_v101(*row)
        game_map.events[ev.id]=Game_Event.new(mid,ev)
      end
      true
    end
  end
end

#==============================================================================
# ■ Game_Map：三張垂直切片地圖 runtime event + parallax + 空白層可走
#==============================================================================
class Game_Map
  alias pmd_ac_v101_setup setup unless method_defined?(:pmd_ac_v101_setup)
  alias pmd_ac_v101_passable passable? unless method_defined?(:pmd_ac_v101_passable)

  def setup(map_id)
    pmd_ac_v101_setup(map_id)
    if PMD_AC.vertical_map_v101?(@map_id)
      row=PMD_AC::VERTICAL_MAPS_V101[@map_id]
      @parallax_name=row[:parallax].to_s
      @parallax_loop_x=false
      @parallax_loop_y=false
      @parallax_sx=0
      @parallax_sy=0
      PMD_AC.inject_vertical_events_v101(self)
    end
  end

  def passable?(x,y,flag=0x01)
    if PMD_AC.vertical_map_v101?(@map_id)
      return valid?(x,y)
    end
    pmd_ac_v101_passable(x,y,flag)
  end
end

#==============================================================================
# ■ Scene_Map：地圖 binding、HUD、F8 回營地、垂直切片隨機遭遇
#==============================================================================
class Scene_Map
  alias pmd_ac_v101_start start unless method_defined?(:pmd_ac_v101_start)
  alias pmd_ac_v101_terminate terminate unless method_defined?(:pmd_ac_v101_terminate)
  alias pmd_ac_v101_update update unless method_defined?(:pmd_ac_v101_update)
  alias pmd_ac_v101_update_encounter update_encounter unless method_defined?(:pmd_ac_v101_update_encounter)
  alias pmd_ac_v101_update_transfer_player update_transfer_player unless method_defined?(:pmd_ac_v101_update_transfer_player)

  def start
    pmd_ac_v101_start
    return unless PMD_AC.vertical_map_v101?
    PMD_AC.ensure_vertical_binding_v101($game_map.map_id)
    create_vertical_hud_v101
    PMD_AC.vertical_log_v101('MAP_ENTER id='+$game_map.map_id.to_s+' name='+PMD_AC.vertical_map_name_v101+
      ' '+PMD_AC.vertical_status_text_v101+' last_result='+PMD_AC.rpg_foundation_state_v100[:last_result].to_s)
  end

  def terminate
    dispose_vertical_hud_v101
    pmd_ac_v101_terminate
  end

  def create_vertical_hud_v101
    dispose_vertical_hud_v101 if @pmd_vertical_hud_v101!=nil
    @pmd_vertical_hud_v101=Sprite.new
    @pmd_vertical_hud_v101.bitmap=Bitmap.new(Graphics.width,54)
    @pmd_vertical_hud_v101.x=0
    @pmd_vertical_hud_v101.y=0
    @pmd_vertical_hud_v101.z=9000
    refresh_vertical_hud_v101
  end

  def dispose_vertical_hud_v101
    return if @pmd_vertical_hud_v101==nil
    if @pmd_vertical_hud_v101.bitmap!=nil && !@pmd_vertical_hud_v101.bitmap.disposed?
      @pmd_vertical_hud_v101.bitmap.dispose
    end
    @pmd_vertical_hud_v101.dispose unless @pmd_vertical_hud_v101.disposed?
    @pmd_vertical_hud_v101=nil
  end

  def refresh_vertical_hud_v101
    return if @pmd_vertical_hud_v101==nil || @pmd_vertical_hud_v101.bitmap==nil
    b=@pmd_vertical_hud_v101.bitmap
    b.clear
    b.fill_rect(0,0,Graphics.width,54,Color.new(5,13,18,205))
    begin
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    rescue
    end
    b.font.size=18;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(12,2,200,24,PMD_AC.vertical_map_name_v101,0)
    b.font.size=12;b.font.bold=false;b.font.color=Color.new(205,225,232)
    b.draw_text(205,3,Graphics.width-217,22,PMD_AC.vertical_status_text_v101,2)
    b.font.size=12;b.font.color=Color.new(240,220,165)
    b.draw_text(12,27,Graphics.width-24,22,PMD_AC.vertical_objective_v101+'｜F8 營地',0)
  end

  def update
    pmd_ac_v101_update
    return unless PMD_AC.vertical_map_v101?
    refresh_vertical_hud_v101 if Graphics.frame_count % 30==0
    if Input.trigger?(Input::F8) && !$game_map.interpreter.running? && ($game_message==nil || !$game_message.busy)
      Sound.play_cancel
      PMD_AC.return_vertical_camp_v101
    end
  end

  def update_transfer_player
    old_mid=$game_map==nil ? 0 : $game_map.map_id.to_i
    pmd_ac_v101_update_transfer_player
    new_mid=$game_map==nil ? 0 : $game_map.map_id.to_i
    if new_mid!=old_mid && PMD_AC.vertical_map_v101?(new_mid)
      PMD_AC.ensure_vertical_binding_v101(new_mid)
      create_vertical_hud_v101
      PMD_AC.vertical_log_v101('MAP_ENTER id='+new_mid.to_s+' name='+PMD_AC.vertical_map_name_v101(new_mid)+
        ' '+PMD_AC.vertical_status_text_v101+' last_result='+PMD_AC.rpg_foundation_state_v100[:last_result].to_s)
    end
  end

  def update_encounter
    unless PMD_AC.vertical_map_v101? || $game_map==nil || ($game_map.map_id!=4 && $game_map.map_id!=5)
      pmd_ac_v101_update_encounter
      return
    end
    cfg=PMD_AC.wild_config_for_map_v081($game_map.map_id)
    return if cfg==nil
    return if $game_player.encounter_count>0
    return if $game_map.interpreter.running?
    return if $game_system.encounter_disabled
    return unless PMD_AC.current_map_encounter_allowed_v092?
    mn=(cfg[:min_steps]||PMD_AC::VERTICAL_RANDOM_MIN_V101).to_i
    mx=(cfg[:max_steps]||PMD_AC::VERTICAL_RANDOM_MAX_V101).to_i
    $game_player.make_pmd_encounter_count_v081(mn,mx)
    PMD_AC.vertical_wild_v101(:walking)
  end
end

#==============================================================================
# ■ v1.00 Hub：探索／特殊／Boss 選項改成真正 Scene_Map，而非直接開戰
#==============================================================================
module PMD_AC
  RPG_FOUNDATION_MENU_LABEL_V100[:wild]='進入林緣調查區（地圖探索）'
  RPG_FOUNDATION_MENU_LABEL_V100[:special]='追蹤特殊足跡（林緣深處）'
  RPG_FOUNDATION_MENU_LABEL_V100[:boss]='前往蜂巢林地（Boss 區）'
end

class Scene_PMD_RPGFoundationV100
  alias pmd_ac_v101_execute_v100 execute_v100 unless method_defined?(:pmd_ac_v101_execute_v100)
  def execute_v100
    key=PMD_AC::RPG_FOUNDATION_MENU_V100[@index]
    unless item_enabled_v100(key)
      Sound.play_buzzer
      return
    end
    case key
    when :wild
      Sound.play_decision
      PMD_AC.enter_vertical_slice_v101(4)
    when :special
      Sound.play_decision
      PMD_AC.enter_vertical_slice_v101(5)
    when :boss
      Sound.play_decision
      PMD_AC.enter_vertical_slice_v101(6)
    else
      pmd_ac_v101_execute_v100
    end
  end
end

#==============================================================================
# ■ v1.01 Formal Verifier
#==============================================================================
module PMD_AC
  old_labels_v101=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v101
  VERIFICATION_LABELS[:map_story_vertical_slice_v101]='MAP_STORY_VERTICAL_SLICE_V101'

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :normal,
    :map_story_vertical_slice_v101,
    :rpg_foundation_v100,
    :nature_ai_temperament_v09916,
    :spatial_conditions_ai_rules_v09915,
    :spatial_framework_expansion_v09914
  ]
end

class Scene_PMD_AutoChess
  alias pmd_ac_v101_return_to_map_v081 return_to_map_v081 unless method_defined?(:pmd_ac_v101_return_to_map_v081)
  alias pmd_ac_v101_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v101_prepare_verification_battle)
  alias pmd_ac_v101_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v101_update_verification_script)
  alias pmd_ac_v101_log_event log_event unless method_defined?(:pmd_ac_v101_log_event)

  def map_story_vertical_slice_v101?
    verification_mode==:map_story_vertical_slice_v101
  end

  def vertical_request_v101?
    r=rpg_request_v081
    r!=nil && (r[:options]||{})[:vertical_slice_v101] ? true:false
  end

  def return_to_map_v081
    if vertical_request_v101? && respond_to?(:pmd_ac_v100_return_to_map_v081)
      PMD_AC.vertical_log_v101('BATTLE_RETURN map='+(($game_map==nil) ? '0':$game_map.map_id.to_s)+
        ' result='+PMD_AC.rpg_foundation_state_v100[:last_result].to_s)
      pmd_ac_v100_return_to_map_v081
      return
    end
    pmd_ac_v101_return_to_map_v081
  end

  def prepare_verification_battle
    pmd_ac_v101_prepare_verification_battle
    if map_story_vertical_slice_v101?
      @map_story_failed_v101=false
      log_event(:showcase,'START mode=MAP_STORY_VERTICAL_SLICE_V101 maps=3 scene_map=1 npc=1 encounters=1 boss=1')
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && map_story_vertical_slice_v101? &&
       message.to_s.index('MAP_STORY_')==0 && message.to_s.include?(' pass=0')
      @map_story_failed_v101=true
    end
    pmd_ac_v101_log_event(category,message)
  end

  def log_map_story_v101(name,pass,detail='')
    @map_story_failed_v101=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_map_story_manifest_v101
    return if @verification_done[:map_story_manifest_v101]
    m=PMD_AC::VERTICAL_MANIFEST_V101
    pass=m[:maps]==[4,5,6] && m[:scene_map] && m[:npc] && m[:checkpoint] &&
      m[:random_encounter] && m[:visible_encounter] && !m[:combat_core_direct_modification]
    log_map_story_v101('MAP_STORY_MANIFEST_V101',pass,'maps=4,5,6 scene_map=1 npc=1 checkpoint=1 random=1 marker=1 core_direct=0')
    @verification_done[:map_story_manifest_v101]=true
  end

  def verify_map_story_assets_v101
    return if @verification_done[:map_story_assets_v101]
    maps=[4,5,6].all?{|mid|FileTest.exist?(sprintf('Data/Map%03d.rvdata',mid))}
    para=FileTest.exist?('Graphics/Parallaxes/PMD_ForestEdge.jpg') && FileTest.exist?('Graphics/Parallaxes/PMD_ForestDeep.jpg')
    pass=maps && para
    log_map_story_v101('MAP_STORY_ASSETS_V101',pass,'map004=1 map005=1 map006=1 parallax_edge=1 parallax_deep=1')
    @verification_done[:map_story_assets_v101]=true
  end

  def verify_map_story_events_v101
    return if @verification_done[:map_story_events_v101]
    counts=[4,5,6].collect{|mid|PMD_AC.vertical_event_specs_v101(mid).size}
    ids_ok=true
    [4,5,6].each do |mid|
      ids=PMD_AC.vertical_event_specs_v101(mid).collect{|r|r[0]}
      ids_ok=false if ids.uniq.size!=ids.size
    end
    pass=counts==[6,6,3] && ids_ok
    log_map_story_v101('MAP_STORY_EVENTS_V101',pass,'counts='+counts.join(',')+' unique_ids='+(ids_ok ? '1':'0')+' npc+wild+special+boss+transfer=1')
    @verification_done[:map_story_events_v101]=true
  end

  def verify_map_story_binding_v101
    return if @verification_done[:map_story_binding_v101]
    c=PMD_AC.build_map_wild_config_v092({:profile=>:forest_route,:terrain_tags=>[],
      :min_steps=>PMD_AC::VERTICAL_RANDOM_MIN_V101,:max_steps=>PMD_AC::VERTICAL_RANDOM_MAX_V101})
    r=PMD_AC.mark_vertical_request_v101(PMD_AC.rpg_foundation_wild_request_v100)
    marked=r!=nil && (r[:options]||{})[:vertical_slice_v101]
    pass=c!=nil && c[:region_v086]==:forest_edge && c[:terrain_tags]==[] &&
      c[:min_steps]==PMD_AC::VERTICAL_RANDOM_MIN_V101 && c[:max_steps]==PMD_AC::VERTICAL_RANDOM_MAX_V101 && marked
    log_map_story_v101('MAP_STORY_BINDING_V101',pass,'region=forest_edge terrain=all steps=12..20 foundation_request=1 return_to_map=1')
    @verification_done[:map_story_binding_v101]=true
  end

  def verify_map_story_progress_v101
    return if @verification_done[:map_story_progress_v101]
    s=PMD_AC.rpg_foundation_state_v100
    old=s.dup
    s[:wild_wins]=0;s[:special_cleared]=false;s[:boss_cleared]=false
    a=!PMD_AC.rpg_foundation_special_unlocked_v100? && !PMD_AC.rpg_foundation_boss_unlocked_v100?
    s[:wild_wins]=1
    b=PMD_AC.rpg_foundation_special_unlocked_v100? && !PMD_AC.rpg_foundation_boss_unlocked_v100?
    s[:wild_wins]=2
    c=PMD_AC.rpg_foundation_special_unlocked_v100? && PMD_AC.rpg_foundation_boss_unlocked_v100?
    s.clear;old.each_pair{|k,v|s[k]=v}
    pass=a && b && c
    log_map_story_v101('MAP_STORY_PROGRESS_V101',pass,'wins0=locked wins1=special wins2=boss restored=1')
    @verification_done[:map_story_progress_v101]=true
  end

  def verify_map_story_carry_v101
    return if @verification_done[:map_story_carry_v101]
    pass=PMD_AC.respond_to?(:party_instances_v078) && PMD_AC.respond_to?(:open_collection_v093) &&
      PMD_AC.respond_to?(:temperament_axes_v09916) && PMD_AC.respond_to?(:event_region_request_v092) &&
      PMD_AC.respond_to?(:start_rpg_foundation_boss_v100) && PMD_AC.respond_to?(:startup_last_session_v1008)
    log_map_story_v101('MAP_STORY_CARRY_V101',pass,'party_box=1 pokedex=1 nature_ai=1 map_api=1 boss=1 startup_v1008=1 damage_unchanged=1')
    @verification_done[:map_story_carry_v101]=true
  end

  def verify_latest_five_modes_v101
    return if @verification_done[:latest_five_modes_v101]
    exp=[:map_story_vertical_slice_v101,:rpg_foundation_v100,:nature_ai_temperament_v09916,
      :spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_map_story_v101('MAP_STORY_LATEST_FIVE_V101',pass,'formal_modes=5 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v101]=true
  end

  def verify_map_story_final_v101
    return if @verification_done[:map_story_final_v101]
    pass=!@map_story_failed_v101
    log_map_story_v101('MAP_STORY_VERTICAL_SLICE_V101',pass,
      'real_map=1 npc=1 random_encounter=1 visible_encounter=1 special=1 boss=1 checkpoint=1 foundation_carried=1 core_direct_modification=0')
    @verification_done[:map_story_final_v101]=true
  end

  def update_verification_script
    pmd_ac_v101_update_verification_script
    return unless map_story_vertical_slice_v101?
    f=@verification_frame.to_i
    verify_map_story_manifest_v101 if f>=20
    verify_map_story_assets_v101 if f>=44
    verify_map_story_events_v101 if f>=68
    verify_map_story_binding_v101 if f>=92
    verify_map_story_progress_v101 if f>=116
    verify_map_story_carry_v101 if f>=140
    verify_latest_five_modes_v101 if f>=164
    verify_map_story_final_v101 if f>=184
    if f>=PMD_AC::VERTICAL_VERIFY_END_V101 && !@verification_done[:map_story_complete_v101]
      if @map_story_failed_v101
        for u in @units;u.verification_finish if u.respond_to?(:verification_finish);end
        @verification_done[:map_story_complete_v101]=true
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=MAP_STORY_VERTICAL_SLICE_V101 auto_skill=on original_skills=restored')
      else
        complete_verification_mode
        @verification_done[:map_story_complete_v101]=true
      end
    end
  end

  # v1.00 / v0.99.16 / .15 / .14 仍留在 S 最新五項，更新它們對 latest-five 的期待值。
  def verify_latest_five_modes_v100
    unless verification_mode==:rpg_foundation_v100
      return pmd_ac_v100_verify_latest_five_modes_v100 if respond_to?(:pmd_ac_v100_verify_latest_five_modes_v100)
      return
    end
    return if @verification_done[:latest_five_modes_v100]
    exp=[:map_story_vertical_slice_v101,:rpg_foundation_v100,:nature_ai_temperament_v09916,
      :spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_rpg_verify_v100('LATEST_FIVE_MODES_V100',pass,'formal_modes=5 current_head=v101 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v100]=true
  end

  def verify_latest_five_modes_v09916
    unless verification_mode==:nature_ai_temperament_v09916
      return pmd_ac_v100_verify_latest_five_modes_v09916
    end
    return if @verification_done[:latest_five_modes_v09916]
    exp=[:map_story_vertical_slice_v101,:rpg_foundation_v100,:nature_ai_temperament_v09916,
      :spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_nature_verify_v09916('LATEST_FIVE_MODES_V09916',pass,'formal_modes=5 current_head=v101 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09916]=true
  end

  def verify_latest_five_modes_v09915
    unless verification_mode==:spatial_conditions_ai_rules_v09915
      return pmd_ac_v100_verify_latest_five_modes_v09915
    end
    return if @verification_done[:latest_five_modes_v09915]
    exp=[:map_story_vertical_slice_v101,:rpg_foundation_v100,:nature_ai_temperament_v09916,
      :spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_condition_verify_v09915('LATEST_FIVE_MODES_V09915',pass,'formal_modes=5 current_head=v101 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09915]=true
  end

  def verify_latest_five_modes_v09914
    unless verification_mode==:spatial_framework_expansion_v09914
      return pmd_ac_v100_verify_latest_five_modes_v09914
    end
    return if @verification_done[:latest_five_modes_v09914]
    exp=[:map_story_vertical_slice_v101,:rpg_foundation_v100,:nature_ai_temperament_v09916,
      :spatial_conditions_ai_rules_v09915,:spatial_framework_expansion_v09914]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_spatial_verify_v09914('LATEST_FIVE_MODES_V09914',pass,'formal_modes=5 current_head=v101 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09914]=true
  end
end
