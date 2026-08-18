#==============================================================================
# ■ Guns Action Sequence Addon 1.3 for RPG Tankentai Sideview Battle System
#     12.16.2008 (Only for Kaduki battlers)
#------------------------------------------------------------------------------
#  Script original by: Kylock
#  1.2 By Night'Walker
#==============================================================================
#   Requested by gend0 (rpgrevolution.com)
#   This is a script that adds new functionality to the Sideview battle System
# in the way of an additional animation for gun weapons.
#   To use this script, simply add it below the Sideview Battle System scripts
# and make sure your gun have element 6(Whip) checked in the game database on
# the weapons tab.  This can be changed below if you like your whip element.
#==============================================================================
# ■ Release Notes
#------------------------------------------------------------------------------
# 1.0
# ● Original Release.
# 1.1
# ● Fixed a "Stack Level" error when used with the Bow script.
# 1.2
# ● Remade action sequence.
# 1.3
# ● Made some changes to sequence for consistancy when wielding one or
#   two guns.  Do not use abnormal weapon combinations like gun + melee weapon.
#   It's not going to work like what you think. - Mr. Bubble
#==============================================================================
# ■ Installation Notes
#------------------------------------------------------------------------------
#   You must choose a database element to be used for the animation for guns.
# By default, this script uses element 6: Whip since it's most
# unlikley that any game will have many whips, or monsters vulnerable to whips.
# You can however change it to something else if whips are important to you.
# Also, any whips you have must lose their "gun" attribute, or they will be
# whips that shoot.
#   When you make your gun weapons, you can obtain a nice effect by making the
# Animaiton 79, or any single target elemental aniation.  For normal guns, you
# may want to consider making a custom hit animation in the game database.
# Sicne the script uses the weapon icon to draw the weapon, I also suggest you
# find a good RTP-styled "gun" icon.  By RTP-styled, I mean the
# "diagonal-looking" style.
#==============================================================================

module N01
  # Element used to define a weapon as a gun
  GUN_ELEMENT = 6 # Default is 6: Replaces Whip

  RANGED_ANIME = {
  # Magic Animation
  "FIRE_GUN"       => ["m_a", 87,   4,  0,  12,   0,  0,  0, 2, true,""],
  # Weapon Animations
  "DOWN_TO_LEFT" => [ 3, 0, false, 120, 45, 4, false, 1, 1, 0,  0, false],
  "LEFT_TO_UP" => [ 3, 0, false, 45, -15, 4, false, 1, 1, 0,  0, false],
  "LEFT_TO_UPL" => [ 3, 0, false, 45, -15, 4, false, 1, 1, 0,  0, true],
  "VERT_SWING-"     => [   3,   0,false,-15,  45,  4,false,   1,  1,  0,  0,false],
  # Battler Animations
  "DRAW_WEAPON" => [ 1, 0, 4, 2, 0, -1, 0, true,"DOWN_TO_LEFT"],
  "GUN_FIRE" => [ 3, 0, 1, 2, 0, -1, 0, true,"LEFT_TO_UP"],
  "GUN_FIREL" => [ 3, 0, 1, 2, 0, -1, 0, true,"LEFT_TO_UPL"],
  "WPN_SWING_V-" => [ 1, 0, 4, 2, 0, -1, 0, true,"VERT_SWING-"],}
  ANIME.merge!(RANGED_ANIME)
  # Action Sequence
  RANGED_ATTACK_ACTION = {
    "GUN_ATTACK" => ["FRONT_JUMP","DRAW_WEAPON","14","OBJ_ANIM","6","FIRE_GUN","GUN_FIRE",
    "5","WPN_SWING_V-","20","OBJ_ANIM_L","6","Two Wpn Only","FIRE_GUN",
    "GUN_FIREL","Two Wpn Only",
    "5","Can Collapse","MOVE_TO","COORD_RESET"],}
  ACTION.merge!(RANGED_ATTACK_ACTION)
end

module RPG
  class Weapon
    alias kylock_guns_base_action base_action unless method_defined?(:kylock_guns_base_action)
    def base_action
      # If "Gun" Element is checked on the weapons tab in the database,
      #  the new ranged attack action sequence is used.
      if $data_weapons[@id].element_set.include?(N01::GUN_ELEMENT)
        return "GUN_ATTACK"
      end
      kylock_guns_base_action
    end
  end
end