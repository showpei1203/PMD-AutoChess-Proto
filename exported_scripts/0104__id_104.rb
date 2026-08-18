#==============================================================================
# ■ Enemy Animated Battlers for RPG Tankentai Sideview Battle System
#     7.28.2008
#------------------------------------------------------------------------------
#  Script by: Kylock 
#==============================================================================
#   Easy to implement interface to specify animated battlers for enemies.  Note
# enemy batters must be formatted THE SAME as your character battlers.  Also,
# you must have 2 copies of your enemy battler:
#   <game folder>\Graphics\Battlers\$<enemy name>.png
#   <game folder>\Graphics\Characters\$<enemy name>_1.png
#------------------------------------------------------------------------------
# ● Adjusting Enemy Positioning ( position_plus alias altered by Mr. Bubble )
#------------------------------------------------------------------------------
#   What I've realized is that a single universal position change in Kylock's
# original Enemy Animated Battlers Addon will not suffice.  If you use the
# popular 11-row pose animated battlers, you may notice that their sprites will
# appear much farther up on your screen than what you assigned in your enemy 
# troops tab in your Database.  Generally, the larger a battler sprite's cell 
# is, the more "up" the sprite will appear in the battle scene.
#
#   In order to better accommodate animated battlers, I've changed
# Kylock's original script to allow specified adjustment for a specified enemy.
#
#   You will need to add each case to your list like this:
#
#   when enemyID#
#     return [ X, Y ]
#
#   X = Pixels sprite will move on the x-axis.  
#   Y = Pixels sprite will move on the y-axis.
#
#   You won't need to make X anything else besides zero.  For Y, positive
# values will move the sprite down on your screen.  It will likely take a few
# tries in battle test to get the position of the battler down where you want.

module K_ENEMY_BATTLERS
  ENEMY_ID = [1,2,3] # list of enemies with batter sprites(ex. [1,24])
end

class Game_Enemy < Game_Battler
  alias bubs_position_plus position_plus unless method_defined?(:bubs_position_plus)
  def position_plus
    case @enemy_id
    when 1
      return [0, 0]
    when 2
      return [0, 0]
    when 3
      return [0, 0]
#   when enemyID#            <--Example of how you add a new adjustment in
#     return [ X, Y ]        <--the script.





#===================== STOP ===================================================
    end
    bubs_position_plus
  end
  alias keb_anime_on anime_on unless method_defined?(:keb_anime_on)
  def anime_on
    for x in K_ENEMY_BATTLERS::ENEMY_ID
      return true if @enemy_id == x
    end
    keb_anime_on
  end
  alias keb_action_mirror action_mirror unless method_defined?(:keb_action_mirror)
  def action_mirror
    for x in K_ENEMY_BATTLERS::ENEMY_ID
      return true if @enemy_id == x
    end
    keb_action_mirror
  end
end