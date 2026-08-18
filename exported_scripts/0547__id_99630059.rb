# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - VX Menu / Selector Render Fix v1.05.62
#------------------------------------------------------------------------------
# Fixes blank Window_Command contents after manual resize + create_contents.
# Root cause in v1.05.61/v1.05.60: new Bitmap was created but commands were not
# refreshed afterward. Gameplay logic is unchanged.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXMenuSelectorRenderFix_v10562']=true

module PMD_AC
  class << self
    def command_window_refresh_after_resize_v10562(window,new_height=nil)
      return false if window==nil
      window.height=new_height.to_i if new_height!=nil && new_height.to_i>0
      window.create_contents
      window.refresh if window.respond_to?(:refresh)
      true
    rescue
      false
    end

    def menu_render_fix_ready_v10562
      true
    end
  end
end

class Scene_Menu
  def create_command_window
    s1=Vocab::item;s2=Vocab::skill;s3=Vocab::equip;s4=Vocab::status
    cmds=[s1,s2,s3,s4,'PMD基地','隊伍／BOX','AI策略','圖鑑','補給品','狩獵','挑戰','素材測試',Vocab::save,Vocab::game_end]
    @command_window=Window_Command.new(160,cmds)
    PMD_AC.command_window_refresh_after_resize_v10562(@command_window,344)
    @command_window.index=@menu_index
    if $game_party.members.size==0
      @command_window.draw_item(0,false);@command_window.draw_item(1,false)
      @command_window.draw_item(2,false);@command_window.draw_item(3,false)
    end
    @command_window.draw_item(12,false) if $game_system.save_disabled
  end
end

class Scene_PMD_HuntSelectV10560
  alias pmd_ac_v10562_renderfix_start start unless method_defined?(:pmd_ac_v10562_renderfix_start)
  def start
    pmd_ac_v10562_renderfix_start
    @window.refresh if @window!=nil && @window.respond_to?(:refresh)
  rescue
    raise
  end
end

class Scene_PMD_ChallengeSelectV10560
  alias pmd_ac_v10562_renderfix_start start unless method_defined?(:pmd_ac_v10562_renderfix_start)
  def start
    pmd_ac_v10562_renderfix_start
    @window.refresh if @window!=nil && @window.respond_to?(:refresh)
  rescue
    raise
  end
end
