#==============================================================================
# ■ Bow Attack Animation Sequence for RPG Tankentai SBS (Kaduki version)
#     9.1.2008
#------------------------------------------------------------------------------
#  Script by Mr. Bubble with basis from Kylock's Bow Addon
#==============================================================================
#   Adds a new bow animation which allows for a much smoother arrow animation
# compared to Kylock's Bow Addon.  This script is designed not to have conflicts
# with Kylock's Bow Addon in case you want to use both.
#==============================================================================
# ■ How to Install
#------------------------------------------------------------------------------
# - Requires Animation 83 from the demo placed in the same ID in your project.
# - Requires "woodarrow.png" in .Graphics\Characters.
#==============================================================================

module N01
  # Weapon element that grants a bow animation.  Default is 5.
  BOW_WEAPON_ELEMENT = 5
  
#------------------------------------------------------------------------------
  # Attack Animation Actions
  BOW_ANIME = {
    "FACE"      => [ 3,  1,  5,   2,   0,  -1,   0, true,"" ],
    "DRAW_BOW"  => ["anime",  83,  0, false, false, false],
    "ARROW_ANGLE"     => [ 30, 60,  11],
  #                    Type  ID Object Pass Time Arc  Xp Yp Start Z Weapon
    "SHOOT_ARROW"  => ["m_a", 0,  0,   0, 15,  -10,  0, 0, 0,false,"ARROW_ANGLE"],
    }
  ANIME.merge!(BOW_ANIME)
  # Action Sequence
  BOW_ATTACK_ACTION = {
    "NEW_BOW_ATTACK" => ["BEFORE_MOVE","DRAW_BOW", "FACE", "16", 
                        "SHOOT_ARROW", "12","OBJ_ANIM","16",
                        "Can Collapse","FLEE_RESET"],
}
  ACTION.merge!(BOW_ATTACK_ACTION)
end

module RPG
  class Weapon
    alias bubs_bow_base_action base_action unless method_defined?(:bubs_bow_base_action)
    def base_action
      # If "Bow" Element is checked on the weapons tab in the database,
      #  the new ranged attack action sequence is used.
      if $data_weapons[@id].element_set.include?(N01::BOW_WEAPON_ELEMENT)
        return "NEW_BOW_ATTACK"
      end
      bubs_bow_base_action
    end
    alias bubs_bow_flying_graphic flying_graphic unless method_defined?(:bubs_bow_flying_graphic)
    def flying_graphic
      if $data_weapons[@id].element_set.include?(N01::BOW_WEAPON_ELEMENT)
        return "woodarrow"
      end
      bubs_bow_flying_graphic
    end
  end
end