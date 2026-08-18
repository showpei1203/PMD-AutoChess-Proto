module N01
  NW_CUSTOM_ANIME = {
  
  # Battler Action Definition
  "FIRE_SWORD_ASSIST_ANIME"      => ["SEQUENCE",    21, "COORD_RESET",  "FIRE_ASSIST"],
  # Action Condition
  "FIRE_STATECHECK"  => ["nece",   3,   0,  21,    1],
  # State Granting Effect "Fire Bless"
  "FIRE_GRANT"       => ["sta+",  1,  21],
  # State Removal Effect "Fire Bless"
  "FIRE_REVOKE"       => ["sta-",  3,  21],
  # Target Modification
  "FIRE_SWORD_TARGET"      => ["target",   21,  1],
  # Attack Animation Settings
  "FIRE_ANIM" => ["anime", 88,  0, false,false, false],
  "FIRE_ANIM2" => ["anime", 89,  0, false,false, false],
  # Horizontal Movements of Battler Animations
  "FIRE_ATK1" => [1,  28, 0, 27, 0, 0, "ATTACK_MOVE"],
  "FIRE_ATK0" => [3, -64, 0, 20, 0, -5, "JUMP_ATTACK"],
  
  # Cut-in Start
  "FROUST_PIC_START"  => ["pic",   -200,  0,   0,  90, 20,false,"Froust"],
  # Cut-in End
  "FROUST_PIC_END"    => ["pic",   0,  80,   544,  90, 10,false,"Froust"],
  # Attack Animation Settings
  "FROUST_ANIM" => ["anime", 90, 0, false, false, false],
  # Battler Animations
  "FROUST_SPECIAL"   => [ 3, 0, 10,  -1,  0, -1,   0,  true, "OVER_SWING" ],
  "FROUST_SPECIAL2"   => [ 1, 3, 10,  2,  0, 1,   0,  true, "NO_SWING" ],
  }
ANIME.merge!(NW_CUSTOM_ANIME)

  NW_CUSTOM_SEQUENCE = {
  #Attack Action Sequence
  "FIRE_ATTACK" => ["FIRE_STATECHECK","FIRE_SWORD_TARGET","FIRE_SWORD_ASSIST_ANIME",
                    "WAIT(FIXED)","FIRE_ATK0","WAIT","75","FIRE_ANIM","20","FIRE_ANIM2","20",
                    "FIRE_ATK1","WPN_SWING_V","OBJ_ANIM_WEIGHT","40","One Wpn Only",
                    "16","FLEE_RESET","FIRE_REVOKE"],

  # Assist Action Sequence
  "FIRE_ASSIST" => ["WAIT(FIXED)","BEFORE_MOVE","SKILL_POSE","24","START_MAGIC_ANIM",
                    "160","FLEE_RESET", "Can Collapse"],

  # State grant action sequence
  "FIRE_STATE_GRANT" => ["FIRE_GRANT"],
  
  # Froust Cut-In Attack Action Sequence
  "FROUST"        => ["BEFORE_MOVE","FROUST_SPECIAL","5","FROUST_ANIM","FROUST_SPECIAL2",
                      "10","FROUST_PIC_START",
                      "100","FROUST_PIC_END","20","Clear image","10","PREV_MOVING_TARGET",
                      "WPN_SWING_V","10","OBJ_ANIM_WEIGHT","20","Can Collapse",
                      "FLEE_RESET"],

  }
  ACTION.merge!(NW_CUSTOM_SEQUENCE)
  
  end

module RPG
  class Skill
    alias nw_custom_skills_base_action base_action unless method_defined?(:nw_custom_skills_base_action)
    def base_action
      case @id
      when 105 # ID of the skill Flamus in the database
        return "FIRE_ATTACK"
      when 106 # ID of the skill Fire Blessing in the database
        return "FIRE_STATE_GRANT"
      when 93 # ID of the skill Froust in the database
        return "FROUST"
      end
      nw_custom_skills_base_action
    end
    alias nw_custom_skills_skill_extension extension unless method_defined?(:nw_custom_skills_skill_extension)
    def extension
      case @id
      when 106 # Fire Blessing Enhancement Extension Settings
        return ["HELPHIDE","NOFLASH"]
      end
      nw_custom_skills_skill_extension
    end
  end
  class State
    alias nw_custom_skills_state_extension extension unless method_defined?(:nw_custom_skills_state_extension)
    def extension
    case @id
      when 21 # Fire Bless State Enhancement Extension Settings
        return ["ZEROTURNLIFT","HIDEICON"]
      end
      nw_custom_skills_state_extension
    end
  end
end