##################################################
# MOG_BATTLEBACK_XP V1.0                         #
##################################################
# By Moghunter
# http://www.atelier-rgss.com
##################################################
# Allow you to use a picture as a background in battles
##################################################
# Inside the GRAPHICS folder, create a new folder named Battlebacks.
# Put the pictures inside the Battlebacks folder.
# To select an picture as a Battleback, use the command Call Script in a event, 
# with this code:

# $game_system.bb = "FILE_NAME"
#
# In the place of FILE_NAME you have to put the  name of the Battleback picture.
# If you want that the map graphic be your Batteback, just place a name of a absent
# file.
#
##################################################
#############
#   CONFIG    #
#############
module MOG_VX02
# On/OFF Wave Effect 
BB_WAVE_SWITCH = 54
# On/OFF VX Standard
BB_VXEDITION_SWITCH = 55
end
#-------------------------------------------------
$mogscript = {} if $mogscript == nil
$mogscript["battleback_xp"] = true
#-------------------------------------------------
###############
# Game_System #
###############
class Game_System
attr_accessor :bb
alias mog_vx02_initialize initialize unless method_defined?(:mog_vx02_initialize)
def initialize
mog_vx02_initialize
@bb = ""
end
end
###############
# Module Cache #
###############
module Cache  
  def self.battleback(filename)
    load_bitmap("Graphics/battlebacks/", filename)
  end
end
#################
# Spriteset_Battle #
#################
class Spriteset_Battle
include MOG_VX02
  def create_battleback
    @battleback_sprite = Sprite.new(@viewport1)
    source = Cache.battleback($game_system.bb.to_s) rescue empty
    if  $game_switches[BB_WAVE_SWITCH] == true
    bitmap = Bitmap.new(640, 480)
    else
    bitmap = Bitmap.new(544, 416)
    end
    bitmap.stretch_blt(bitmap.rect, source, source.rect)
    bitmap.radial_blur(90, 12) if  $game_switches[BB_VXEDITION_SWITCH] == true
    @battleback_sprite.bitmap = bitmap
    wave_on if  $game_switches[BB_WAVE_SWITCH] == true
 end
def wave_on
    @battleback_sprite.ox = 320
    @battleback_sprite.oy = 240
    @battleback_sprite.x = 272
    @battleback_sprite.y = 176  
    @battleback_sprite.wave_amp = 8
    @battleback_sprite.wave_length = 240
    @battleback_sprite.wave_speed = 120     
end
def empty
   @battleback_sprite.bitmap =  $game_temp.background_bitmap
 end 
def create_battlefloor
    if  $game_switches[BB_VXEDITION_SWITCH] == true 
    @battlefloor_sprite = Sprite.new(@viewport1)
    @battlefloor_sprite.bitmap = Cache.system("BattleFloor")
    @battlefloor_sprite.x = 0
    @battlefloor_sprite.y = 192
    @battlefloor_sprite.z = 1
    @battlefloor_sprite.opacity = 128
    else
    @battlefloor_sprite = Sprite.new(@viewport1)
    end
  end
end