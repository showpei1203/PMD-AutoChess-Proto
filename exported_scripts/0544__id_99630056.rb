# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Imported PMD Visual Test Roster v1.05.59
#------------------------------------------------------------------------------
# Development visual fixture after full PMD asset import.
# Keeps Caterpie specifically to verify String Shot status charge, while adding
# five different body/animation profiles.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ImportedPMDVisualTestRoster_v10559']=true

module PMD_AC
  VISUAL_TEST_ALLY_V10559=[[:scyther,0,2],[:gardevoir,1,1],[:lucario,0,3]]
  VISUAL_TEST_ENEMY_V10559=[[:garchomp,5,2],[:caterpie,4,1],[:rotom,5,3]]

  class << self
    def request_visual_test_v10559
      return false if $game_temp==nil
      clear_battle_request_v081 if respond_to?(:clear_battle_request_v081)
      $game_temp.pmd_visual_test_roster_v10559=true
      true
    rescue
      false
    end

    def start_visual_test_v10559
      return false unless request_visual_test_v10559
      $scene=Scene_PMD_AutoChess.new
      true
    rescue
      false
    end
  end
end

class Game_Temp
  attr_accessor :pmd_visual_test_roster_v10559
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10559_create_units create_units unless method_defined?(:pmd_ac_v10559_create_units)
  alias pmd_ac_v10559_start_battle start_battle unless method_defined?(:pmd_ac_v10559_start_battle)

  def create_units
    use=($game_temp!=nil && $game_temp.pmd_visual_test_roster_v10559)
    unless use
      pmd_ac_v10559_create_units
      return
    end
    $game_temp.pmd_visual_test_roster_v10559=false
    @visual_test_roster_v10559=true
    @units=[];id=0
    PMD_AC::VISUAL_TEST_ALLY_V10559.each do |entry|
      u=Game_PMDChessUnit.new(id,entry[0],:ally,entry[1],entry[2]);u.scene=self;@units.push(u);id+=1
    end
    PMD_AC::VISUAL_TEST_ENEMY_V10559.each do |entry|
      u=Game_PMDChessUnit.new(id,entry[0],:enemy,entry[1],entry[2]);u.scene=self;@units.push(u);id+=1
    end
    @next_unit_id=id
  rescue
    pmd_ac_v10559_create_units
  end

  def start_battle
    r=pmd_ac_v10559_start_battle
    begin
      if @visual_test_roster_v10559 && @phase==:battle
        log_event(:battle,'BATTLE_IMPORTED_PMD_VISUAL_ROSTER_V10559 allies=scyther,gardevoir,lucario enemies=garchomp,caterpie,rotom string_shot_probe=1 imported_asset_fixture=1')
      end
    rescue
    end
    r
  end
end
