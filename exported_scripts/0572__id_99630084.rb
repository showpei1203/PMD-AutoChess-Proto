# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD AutoTest Scene + Native Menu Entry v1.05.87
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDAutoTestScene_v10587']=true

module PMD_AC
  class << self
    def open_vxrd_autotest_scene_v10587(menu_index=nil)
      $scene=Scene_PMD_VXRDAutoTestSelectV10587.new(menu_index==nil ? 11 : menu_index.to_i)
      true
    rescue
      false
    end
  end
end

class Scene_PMD_VXRDAutoTestSelectV10587 < Scene_Base
  def initialize(menu_index=11)
    @menu_index=menu_index
  end
  def start
    super
    create_menu_background
    @presets=PMD_AC.vxrd_autotest_presets_v10586
    cmds=@presets.collect{|p|p[:label].to_s}
    cmds.push('返回 Menu')
    @window=Window_Command.new(420,cmds)
    @window.x=(Graphics.width-420)/2
    @window.y=40
    max_h=Graphics.height-80
    @window.height=max_h if @window.height>max_h
    @window.create_contents
    @window.refresh
  end
  def terminate
    super
    dispose_menu_background
    @window.dispose if @window!=nil
  end
  def update
    super
    update_menu_background
    @window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel;$scene=Scene_Menu.new(@menu_index);return
    end
    return unless Input.trigger?(Input::C)
    idx=@window.index
    if idx>=@presets.size
      Sound.play_cancel;$scene=Scene_Menu.new(@menu_index);return
    end
    p=@presets[idx]
    Sound.play_decision
    PMD_AC.run_vxrd_auto_test_v10586(p[:code],p[:mode],p[:seed])
  end
end

class Scene_Menu
  def create_command_window
    s1=Vocab::item;s2=Vocab::skill;s3=Vocab::equip;s4=Vocab::status
    cmds=[s1,s2,s3,s4,'PMD基地','隊伍／BOX','AI策略','圖鑑','補給品','狩獵','挑戰','隨機地圖測試','素材測試',Vocab::save,Vocab::game_end]
    @command_window=Window_Command.new(160,cmds)
    PMD_AC.command_window_refresh_after_resize_v10562(@command_window,344)
    @command_window.index=@menu_index
    if $game_party.members.size==0
      @command_window.draw_item(0,false);@command_window.draw_item(1,false)
      @command_window.draw_item(2,false);@command_window.draw_item(3,false)
    end
    @command_window.draw_item(13,false) if $game_system.save_disabled
  end

  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel;$scene=Scene_Map.new;return
    end
    return unless Input.trigger?(Input::C)
    idx=@command_window.index
    if $game_party.members.size==0 && idx<4
      Sound.play_buzzer;return
    elsif $game_system.save_disabled && idx==13
      Sound.play_buzzer;return
    end
    Sound.play_decision
    case idx
    when 0
      $scene=Scene_Item.new
    when 1,2,3
      start_actor_selection
    when 4
      PMD_AC.open_pmd_hub_v10561(idx)
    when 5
      PMD_AC.open_party_scene_v10561(idx)
    when 6
      PMD_AC.open_ai_scene_v10561(idx)
    when 7
      PMD_AC.open_collection_scene_v10561(idx)
    when 8
      PMD_AC.open_supply_scene_v10561(idx)
    when 9
      PMD_AC.open_hunt_scene_v10561(idx)
    when 10
      PMD_AC.open_challenge_scene_v10561(idx)
    when 11
      PMD_AC.open_vxrd_autotest_scene_v10587(idx)
    when 12
      PMD_AC.open_visual_test_scene_v10561(idx)
    when 13
      $scene=Scene_File.new(true,false,false)
    when 14
      $scene=Scene_End.new
    end
  end
end
