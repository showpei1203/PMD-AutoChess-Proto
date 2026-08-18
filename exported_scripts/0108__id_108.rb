#==============================================================================
# ■ Default Scope Options Addon for RPG Tankentai Sideview Battle System
# 12.16.2008
#------------------------------------------------------------------------------
# Original Script Addons by Kylock
# Script Overhaul by Mr. Bubble
#==============================================================================
#   This script is a single compilation of Kylock's original animation scripts
# which reproduce some "Scope" options for skills.  This has been completely
# overhauled from the original script.  Not only are you not limited to several
# skill IDs, you no longer need to manually input items into this script.  It
# is plug and play which is great for new people.
#
# ▼ How to use:
#   
#   Several "Scope" options are disabled in the Skills Tab because of this
# script. They are One Enemy Dual, One Random Enemy, 2 Random Enemies and 
# 3 Random Enemies.  However, with this script all you need to do is assign
# a skill any one of those Scope options to reproduce the same effect for the
# Sideview script.
#
#   There are two animations possible for each Scope.  A melee attack animation
# and a spell cast animation.  If the "Attack F" value is more than 0, it will
# return the melee attack animation.  Otherwise, it will be a spell cast
# Animation.
#
#   DO NOT use this script with Dual Attack Fix Addon, Double Attack Fix Addon,
# and Triple Attack Fix Addon.  You do not need those anymore if you use this.
#
#   DO NOT use Animation: "Same as Normal Atk"!  It does not function normally
# with the Sideview script. Use any other Animation except "Same as Normal Atk".
#==============================================================================

module N01
  new_action_sequence = {
  # This sequence is used if Scope is One Enemy Dual and Attack F > 0
  "ONE_ENEMY_DUAL_A" => ["PREV_STEP_ATTACK","WPN_SWING_V","OBJ_ANIM_WEAPON",
                    "WAIT(FIXED)","16", "PREV_STEP_ATTACK","WPN_SWING_V",
                    "OBJ_ANIM_WEAPON","Can Collapse","COORD_RESET"],
                    
  # This sequence is used if Scope is 2 Random Enemies and Attack F > 0
  "ONE_RANDOM_ENEMY_A" => ["PREV_STEP_ATTACK","WPN_SWING_V","OBJ_ANIM_WEAPON",
                      "WAIT(FIXED)","16","Can Collapse","COORD_RESET"],
                    
  # This sequence is used if Scope is 2 Random Enemies and Attack F > 0
  "2_RANDOM_ENEMIES_A" => ["PREV_STEP_ATTACK","WPN_SWING_V","OBJ_ANIM_WEAPON",
                      "WAIT(FIXED)","16","PREV_STEP_ATTACK","WPN_SWING_V",
                      "OBJ_ANIM_WEAPON","Can Collapse","COORD_RESET"],
                      
  # This sequence is used if Scope is 3 Random Enemies and Attack F > 0
  "3_RANDOM_ENEMIES_A" => ["PREV_STEP_ATTACK","WPN_SWING_V","OBJ_ANIM_WEAPON",
                      "WAIT(FIXED)","16", "PREV_STEP_ATTACK","WPN_SWING_V",
                      "OBJ_ANIM_WEAPON","WAIT(FIXED)","16","PREV_STEP_ATTACK",
                      "WPN_SWING_V","OBJ_ANIM_WEAPON","Can Collapse","COORD_RESET"],
                      
  # This sequence is used if Scope is One Enemy Dual
  "ONE_ENEMY_DUAL_S" => ["BEFORE_MOVE","WAIT(FIXED)","START_MAGIC_ANIM",
                          "WPN_SWING_UNDER","WPN_RAISED","WPN_SWING_V",
                          "OBJ_ANIM_WEIGHT","OBJ_ANIM_WEIGHT",
                          "Can Collapse","24","COORD_RESET"],
                          
  # This sequence is used if Scope is One Enemy Random
  "ONE_RANDOM_ENEMY_S" => ["BEFORE_MOVE","WAIT(FIXED)","START_MAGIC_ANIM",
                          "WPN_SWING_UNDER","WPN_RAISED","WPN_SWING_V",
                          "OBJ_ANIM_WEIGHT","Can Collapse","24","COORD_RESET"],
                          
  # This sequence is used if Scope is 2 Random Enemies
  "2_RANDOM_ENEMIES_S" => ["BEFORE_MOVE","WAIT(FIXED)","START_MAGIC_ANIM",
                          "WPN_SWING_UNDER","WPN_RAISED","WPN_SWING_V",
                          "OBJ_ANIM_WEIGHT","OBJ_ANIM_WEIGHT",
                          "Can Collapse","24","COORD_RESET"],
                          
  # This sequence is used if Scope is 3 Random Enemies
  "3_RANDOM_ENEMIES_S" => ["BEFORE_MOVE","WAIT(FIXED)","START_MAGIC_ANIM",
                          "WPN_SWING_UNDER","WPN_RAISED","WPN_SWING_V",
                          "OBJ_ANIM_WEIGHT","OBJ_ANIM_WEIGHT","OBJ_ANIM_WEIGHT",
                          "Can Collapse","24","COORD_RESET"],
                    }
  # Merges new hash with the script
  ACTION.merge!(new_action_sequence)
end

module RPG
  class Skill
    alias default_scope_options_base_action base_action unless method_defined?(:default_scope_options_base_action)
    def base_action  # ● Skill ID Sequence Assignments
      if self.scope == 3 # If Scope is set to One Enemy Dual
        return "ONE_ENEMY_DUAL_A" if self.atk_f > 0
        return "ONE_ENEMY_DUAL_S"
      end
      if self.scope == 4 # If Scope is set to One Enemy Random
        return "ONE_RANDOM_ENEMY_A" if self.atk_f > 0
        return "ONE_RANDOM_ENEMY_S"
      end
      if self.scope == 5 # If Scope is set to 2 Random Enemies
        return "2_RANDOM_ENEMIES_A" if self.atk_f > 0
        return "2_RANDOM_ENEMIES_S"
      end
      if self.scope == 6 # If Scope is set to 3 Random Enemies
        return "3_RANDOM_ENEMIES_A" if self.atk_f > 0
        return "3_RANDOM_ENEMIES_S"
      end
    default_scope_options_base_action
  end
    alias default_scope_options_extension extension unless method_defined?(:default_scope_options_extension)
    def extension  # ● Skill Enhancement Extension Settings
      if self.scope == 4 # If Scope is set to One Enemy Random
        return ["RANDOMTARGET"]
      end
      if self.scope == 5 # If Scope is set to 2 Random Enemies
        return ["RANDOMTARGET"]
      end
      if self.scope == 6 # If Scope is set to 3 Random Enemies
        return ["RANDOMTARGET"]
      end
      default_scope_options_extension
    end
  end
end