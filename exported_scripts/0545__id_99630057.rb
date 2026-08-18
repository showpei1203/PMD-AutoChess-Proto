# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Hunt / Challenge Tool Scenes + Challenge C03-C06 v1.05.60
#------------------------------------------------------------------------------
# Functional Scene layer only.  UI polish remains deferred.
# - Hunt selector: H01-H21, launches one encounter from current Hunt authority.
# - Challenge selector: C01-C06 executable; C07-C16 remain visible but disabled.
# - C03-C06 enemy compositions are added without changing fixed reward data.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntChallengeToolScenes_v10560']=true

module PMD_AC
  PHASE_DIV_EARLY_CHALLENGES_V10554['C03']={:name=>'孢粉控制演習',:ai_tier=>2,:presentation=>'forest_demo',:lesson=>'status_control_chain',
    :enemy_setup=>[['butterfree',20],['gloom',21],['kadabra',21]],:reward=>'C03',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C04']={:name=>'突破護衛演習',:ai_tier=>2,:presentation=>'story_demo',:lesson=>'diver_vs_bodyguard',
    :enemy_setup=>[['machoke',25],['kadabra',26],['graveler',26]],:reward=>'C04',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C05']={:name=>'磁場空間演習',:ai_tier=>2,:presentation=>'story_demo',:lesson=>'space_control_priority',
    :enemy_setup=>[['magneton',31],['haunter',32],['golbat',32]],:reward=>'C05',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C06']={:name=>'斬首壓力演習',:ai_tier=>3,:presentation=>'story_demo',:lesson=>'assassin_pressure',
    :enemy_setup=>[['scyther',37],['hypno',38],['rhydon',39]],:reward=>'C06',:recruitable=>false}

  class << self
    def phase_div_hunt_scene_enabled_v10560(code)
      !(phase_div_hunt_catalog_v10555(code)||[]).empty?
    rescue
      false
    end

    def phase_div_challenge_scene_enabled_v10560(code)
      phase_div_early_challenge_v10554(code)!=nil
    rescue
      false
    end

    def phase_div_start_hunt_scene_battle_v10560(code)
      c=code.to_s.upcase
      s=phase_div_begin_hunt_run_v10555(c,0,nil,{:scene_selector=>true})
      return false if s==nil
      r=phase_div_hunt_request_v10555(s);return false if r==nil
      r[:pmd_return_scene_v10560]=:hunt
      s[:encounters]=s[:encounters].to_i+1
      launch_battle_request_v081(r)
    rescue
      false
    end

    def phase_div_start_challenge_scene_battle_v10560(code)
      c=code.to_s.upcase
      r=phase_div_challenge_request_v10556(c);return false if r==nil
      r[:pmd_return_scene_v10560]=:challenge
      launch_battle_request_v081(r)
    rescue
      false
    end
  end
end

class Game_Temp
  attr_accessor :pmd_phase_div_selector_return_scene_v10560
end

class Scene_PMD_HuntSelectV10560 < Scene_Base
  def initialize(return_scene=nil)
    @return_scene=return_scene
  end
  def start
    super
    commands=[]
    @codes=[]
    (1..21).each do |i|
      c='H'+sprintf('%02d',i);h=PMD_AC.phase_div_hunt_v10553(c)||{}
      enabled=PMD_AC.phase_div_hunt_scene_enabled_v10560(c)
      lv='Lv'+h[:level_min].to_i.to_s+'-'+h[:level_max].to_i.to_s
      label=c+' '+h[:name].to_s+'｜'+lv+'｜AI'+h[:ai_tier].to_i.to_s
      label+='［未解鎖］' unless enabled
      commands.push(label);@codes.push(c)
    end
    @window=Window_Command.new(Graphics.width,commands)
    @window.height=Graphics.height
    @window.create_contents
    @window.index=0
  end
  def update
    super;@window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $game_temp.pmd_phase_div_selector_return_scene_v10560=nil if $game_temp!=nil
      $scene=@return_scene || Scene_Map.new;return
    elsif Input.trigger?(Input::C)
      c=@codes[@window.index]
      unless PMD_AC.phase_div_hunt_scene_enabled_v10560(c)
        Sound.play_buzzer;return
      end
      Sound.play_decision
      $game_temp.pmd_phase_div_selector_return_scene_v10560=@return_scene if $game_temp!=nil
      ok=PMD_AC.phase_div_start_hunt_scene_battle_v10560(c)
      Sound.play_buzzer unless ok
    end
  end
  def terminate
    @window.dispose if @window!=nil && !@window.disposed?
    super
  end
end

class Scene_PMD_ChallengeSelectV10560 < Scene_Base
  def initialize(return_scene=nil)
    @return_scene=return_scene
  end
  def start
    super
    commands=[];@codes=[]
    (1..16).each do |i|
      c='C'+sprintf('%02d',i);ch=PMD_AC.phase_div_challenge_v10553(c)||{}
      enabled=PMD_AC.phase_div_challenge_scene_enabled_v10560(c)
      clear=PMD_AC.respond_to?(:phase_div_challenge_clear_count_v10556) ? PMD_AC.phase_div_challenge_clear_count_v10556(c) : 0
      label=c+' '+ch[:name].to_s+'｜AI'+ch[:ai_tier].to_i.to_s
      label+=(clear.to_i>0 ? '［CLEAR］' : '')
      label+='［Runtime待接］' unless enabled
      commands.push(label);@codes.push(c)
    end
    @window=Window_Command.new(Graphics.width,commands)
    @window.height=Graphics.height
    @window.create_contents
    @window.index=0
  end
  def update
    super;@window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $game_temp.pmd_phase_div_selector_return_scene_v10560=nil if $game_temp!=nil
      $scene=@return_scene || Scene_Map.new;return
    elsif Input.trigger?(Input::C)
      c=@codes[@window.index]
      unless PMD_AC.phase_div_challenge_scene_enabled_v10560(c)
        Sound.play_buzzer;return
      end
      Sound.play_decision
      $game_temp.pmd_phase_div_selector_return_scene_v10560=@return_scene if $game_temp!=nil
      ok=PMD_AC.phase_div_start_challenge_scene_battle_v10560(c)
      Sound.play_buzzer unless ok
    end
  end
  def terminate
    @window.dispose if @window!=nil && !@window.disposed?
    super
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10560_return_to_map_v081 return_to_map_v081 unless method_defined?(:pmd_ac_v10560_return_to_map_v081)
  def return_to_map_v081
    req=rpg_request_v081 rescue nil
    ret=req==nil ? nil : req[:pmd_return_scene_v10560]
    if ret==:hunt || ret==:challenge
      PMD_AC.clear_battle_request_v081
      PMD_AC.phase_div_end_hunt_run_v10555 if ret==:hunt
      back=($game_temp==nil ? nil : $game_temp.pmd_phase_div_selector_return_scene_v10560)
      back=Scene_Map.new if back==nil
      $scene=(ret==:hunt ? Scene_PMD_HuntSelectV10560.new(back) : Scene_PMD_ChallengeSelectV10560.new(back))
      return
    end
    pmd_ac_v10560_return_to_map_v081
  end
end
