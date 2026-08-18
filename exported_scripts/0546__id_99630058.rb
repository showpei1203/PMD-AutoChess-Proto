# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - VX Native Menu Scene Router v1.05.61
#------------------------------------------------------------------------------
# Adds PMD user-facing scenes to RPG Maker VX's built-in Scene_Menu.
# Functional layout only; visual redesign remains deferred.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXNativeMenuSceneRouter_v10561']=true

module PMD_AC
  class << self
    def pmd_menu_mark_return_v10561(owner,index)
      return if $game_temp==nil
      $game_temp.pmd_vx_menu_return_owner_v10561=owner
      $game_temp.pmd_vx_menu_return_index_v10561=index.to_i
    end
    def pmd_menu_return_owner_v10561
      $game_temp==nil ? nil : $game_temp.pmd_vx_menu_return_owner_v10561
    end
    def pmd_menu_return_scene_v10561
      idx=$game_temp==nil ? 4 : $game_temp.pmd_vx_menu_return_index_v10561.to_i
      if $game_temp!=nil
        $game_temp.pmd_vx_menu_return_owner_v10561=nil
        $game_temp.pmd_vx_menu_return_index_v10561=nil
      end
      Scene_Menu.new(idx)
    end

    def open_pmd_hub_v10561(menu_index=nil)
      pmd_menu_mark_return_v10561(:hub,menu_index) if menu_index!=nil
      $scene=Scene_PMD_RPGFoundationV100.new;true
    end
    def open_party_scene_v10561(menu_index=nil)
      pmd_menu_mark_return_v10561(:party,menu_index) if menu_index!=nil
      $scene=Scene_PMD_RPGPartyV1004.new;true
    end
    def open_ai_scene_v10561(menu_index=nil)
      pmd_menu_mark_return_v10561(:ai,menu_index) if menu_index!=nil
      $scene=Scene_PMD_RPGAIStrategyV1004.new;true
    end
    def open_collection_scene_v10561(menu_index=nil)
      back=(menu_index==nil ? Scene_Map.new : Scene_Menu.new(menu_index))
      $scene=Scene_PMDCollectionV093.new(back);true
    end
    def open_supply_scene_v10561(menu_index=nil)
      pmd_menu_mark_return_v10561(:supply,menu_index) if menu_index!=nil
      $scene=Scene_PMDSupplyInventoryV099.new;true
    end
    def open_hunt_scene_v10561(menu_index=nil)
      back=(menu_index==nil ? Scene_Map.new : Scene_Menu.new(menu_index))
      $scene=Scene_PMD_HuntSelectV10560.new(back);true
    end
    def open_challenge_scene_v10561(menu_index=nil)
      back=(menu_index==nil ? Scene_Map.new : Scene_Menu.new(menu_index))
      $scene=Scene_PMD_ChallengeSelectV10560.new(back);true
    end
    def open_visual_test_scene_v10561(menu_index=nil)
      pmd_menu_mark_return_v10561(:visual_test,menu_index) if menu_index!=nil
      start_visual_test_v10559
    end
  end
end

class Game_Temp
  attr_accessor :pmd_vx_menu_return_owner_v10561
  attr_accessor :pmd_vx_menu_return_index_v10561
end

class Scene_Menu
  def create_command_window
    s1=Vocab::item;s2=Vocab::skill;s3=Vocab::equip;s4=Vocab::status
    cmds=[s1,s2,s3,s4,'PMD基地','隊伍／BOX','AI策略','圖鑑','補給品','狩獵','挑戰','素材測試',Vocab::save,Vocab::game_end]
    @command_window=Window_Command.new(160,cmds)
    # 14 rows do not quite fit above the native gold window; make it scroll.
    @command_window.height=344
    @command_window.create_contents
    @command_window.index=@menu_index
    if $game_party.members.size==0
      @command_window.draw_item(0,false);@command_window.draw_item(1,false)
      @command_window.draw_item(2,false);@command_window.draw_item(3,false)
    end
    @command_window.draw_item(12,false) if $game_system.save_disabled
  end

  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel;$scene=Scene_Map.new;return
    end
    return unless Input.trigger?(Input::C)
    idx=@command_window.index
    if $game_party.members.size==0 && idx<4
      Sound.play_buzzer;return
    elsif $game_system.save_disabled && idx==12
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
      PMD_AC.open_visual_test_scene_v10561(idx)
    when 12
      $scene=Scene_File.new(true,false,false)
    when 13
      $scene=Scene_End.new
    end
  end
end

class Scene_PMD_RPGFoundationV100
  alias pmd_ac_v10561_hub_update update unless method_defined?(:pmd_ac_v10561_hub_update)
  def update
    if PMD_AC.pmd_menu_return_owner_v10561==:hub && (Input.trigger?(Input::B) || Input.trigger?(Input::F8))
      Sound.play_cancel;$scene=PMD_AC.pmd_menu_return_scene_v10561;return
    end
    pmd_ac_v10561_hub_update
  end
end

class Scene_PMD_RPGPartyV1004
  alias pmd_ac_v10561_party_update update unless method_defined?(:pmd_ac_v10561_party_update)
  def update
    pmd_ac_v10561_party_update
    if PMD_AC.pmd_menu_return_owner_v10561==:party && $scene!=nil && $scene.is_a?(Scene_PMD_RPGFoundationV100)
      $scene=PMD_AC.pmd_menu_return_scene_v10561
    end
  end
end

class Scene_PMD_RPGAIStrategyV1004
  alias pmd_ac_v10561_ai_update update unless method_defined?(:pmd_ac_v10561_ai_update)
  def update
    pmd_ac_v10561_ai_update
    if PMD_AC.pmd_menu_return_owner_v10561==:ai && $scene!=nil && $scene.is_a?(Scene_PMD_RPGFoundationV100)
      $scene=PMD_AC.pmd_menu_return_scene_v10561
    end
  end
end

class Scene_PMDSupplyInventoryV099
  alias pmd_ac_v10561_supply_update update unless method_defined?(:pmd_ac_v10561_supply_update)
  def update
    pmd_ac_v10561_supply_update
    if PMD_AC.pmd_menu_return_owner_v10561==:supply && $scene!=nil && $scene.is_a?(Scene_Map)
      $scene=PMD_AC.pmd_menu_return_scene_v10561
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10561_deploy_update update_deploy_phase unless method_defined?(:pmd_ac_v10561_deploy_update)
  alias pmd_ac_v10561_result_update update_result_phase unless method_defined?(:pmd_ac_v10561_result_update)
  def update_deploy_phase
    pmd_ac_v10561_deploy_update
    if PMD_AC.pmd_menu_return_owner_v10561==:visual_test && $scene!=nil && $scene.is_a?(Scene_Map)
      $scene=PMD_AC.pmd_menu_return_scene_v10561
    end
  end
  def update_result_phase
    pmd_ac_v10561_result_update
    if PMD_AC.pmd_menu_return_owner_v10561==:visual_test && $scene!=nil && $scene.is_a?(Scene_Map)
      $scene=PMD_AC.pmd_menu_return_scene_v10561
    end
  end
end
