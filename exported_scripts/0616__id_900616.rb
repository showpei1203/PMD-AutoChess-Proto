# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Battle Presentation Authority v1.06.31
#-------------------------------------------------------------------------------
#  1. Carried-faint allies remain in a static faint pose at half opacity in
#     deploy and battle.
#  2. Terminal battle outcome is latched, existing presentation is drained,
#     then a battle-end cue is shown before the original result settlement.
#  3. Compact three-slot team HUD rails occupy the 56px side gutters.
#-------------------------------------------------------------------------------
#  Presentation-only. AI choice, damage, attack speed and spatial endpoints are
#  intentionally unchanged.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BattlePresentationAuthority_v10631']=true

module PMD_AC
  BATTLE_CARRIED_FAINT_OPACITY_V10631 = 128
  BATTLE_FINISH_MIN_DRAIN_V10631 = 42
  BATTLE_FINISH_MAX_DRAIN_V10631 = 180
  BATTLE_END_CUE_FRAMES_V10631 = 54
  BATTLE_END_CUE_SE_V10631 = 'PKSFX_PMD_Magic_Chime_003'
  BATTLE_END_CUE_SE_VOLUME_V10631 = 90
  BATTLE_END_CUE_SE_PITCH_V10631 = 100
  TEAM_HUD_W_V10631 = 54
  TEAM_HUD_H_V10631 = 176
  TEAM_HUD_Y_V10631 = 72

  class << self
    alias pmd_ac_v10631_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10631_write_project_state_log)

    def project_version
      '1.06.31'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10631_write_project_state_log(force)
      return false unless r
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=19')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.31')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=BATTLE_PRESENTATION_AUTHORITY+HUNT_UNLOCK_RETREAT')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=BATTLE_PRESENTATION_WINDOWS_ACCEPTANCE')
      text=text.gsub(/\r?\nBATTLE_PRESENTATION_V10631_BEGIN.*?BATTLE_PRESENTATION_V10631_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'BATTLE_PRESENTATION_V10631_BEGIN'
      lines << 'CARRIED_FAINT_STATIC_POSE=READY'
      lines << 'CARRIED_FAINT_OPACITY='+BATTLE_CARRIED_FAINT_OPACITY_V10631.to_s
      lines << 'BATTLE_FINISH_PRESENTATION_DRAIN=READY'
      lines << 'BATTLE_FINISH_MIN_DRAIN_FRAMES='+BATTLE_FINISH_MIN_DRAIN_V10631.to_s
      lines << 'BATTLE_FINISH_MAX_DRAIN_FRAMES='+BATTLE_FINISH_MAX_DRAIN_V10631.to_s
      lines << 'BATTLE_END_CUE=READY'
      lines << 'BATTLE_END_CUE_SE='+BATTLE_END_CUE_SE_V10631
      lines << 'SIDE_TEAM_HUD=READY'
      lines << 'SIDE_TEAM_HUD_WIDTH='+TEAM_HUD_W_V10631.to_s
      lines << 'BATTLE_PRESENTATION_GAMEPLAY_CHANGE=0'
      lines << 'BATTLE_PRESENTATION_WINDOWS_ACCEPTANCE=PENDING_USER_RUN'
      lines << 'BATTLE_PRESENTATION_V10631_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

#===============================================================================
# ■ Carried faint state authority
#===============================================================================
class Game_PMDChessUnit
  attr_reader :carried_faint_v10631

  alias pmd_ac_v10631_set_current_hp_v082 set_current_hp_v082 unless method_defined?(:pmd_ac_v10631_set_current_hp_v082)
  alias pmd_ac_v10631_start_combat start_combat unless method_defined?(:pmd_ac_v10631_start_combat)
  alias pmd_ac_v10631_start_faint start_faint unless method_defined?(:pmd_ac_v10631_start_faint)
  alias pmd_ac_v10631_update_logic update_logic unless method_defined?(:pmd_ac_v10631_update_logic)
  alias pmd_ac_v10631_receive_damage receive_damage unless method_defined?(:pmd_ac_v10631_receive_damage)
  alias pmd_ac_v10631_heal heal unless method_defined?(:pmd_ac_v10631_heal)

  def carried_faint_v10631?
    @carried_faint_v10631 ? true : false
  end

  def force_carried_faint_pose_v10631
    return false unless dead?
    @carried_faint_v10631=true
    @dead_started=true
    @victory_celebrating=false
    @action=:faint
    @visual_action=:faint
    @action_timer=0
    @action_total_frames=0
    @action_hit_done=false
    @action_lunge=0.0
    @velocity_x=0.0
    @velocity_y=0.0
    @visual_offset_x=0.0
    @visual_offset_y=0.0
    @recoil_x=0.0
    @recoil_y=0.0
    @knockback_frames=0
    clear_move_goal if respond_to?(:clear_move_goal)
    @target=nil
    true
  rescue
    false
  end

  def set_current_hp_v082(value)
    r=pmd_ac_v10631_set_current_hp_v082(value)
    if @hp.to_i<=0
      force_carried_faint_pose_v10631
    else
      @carried_faint_v10631=false
      @dead_started=false if @dead_started && !battle_active?
    end
    r
  end

  def start_combat
    was_dead=dead?
    r=pmd_ac_v10631_start_combat
    if was_dead || dead?
      force_carried_faint_pose_v10631
    end
    r
  end

  def start_faint
    # A fresh KO is not a carried faint until a later encounter reloads HP=0.
    @carried_faint_v10631=false
    pmd_ac_v10631_start_faint
  end

  def update_logic
    s=@scene
    if s!=nil && s.respond_to?(:battle_finish_pending_v10631?) &&
       s.battle_finish_pending_v10631?
      return
    end
    pmd_ac_v10631_update_logic
  end

  def receive_damage(*args)
    s=@scene
    if s!=nil && s.respond_to?(:battle_finish_pending_v10631?) &&
       s.battle_finish_pending_v10631?
      return 0
    end
    pmd_ac_v10631_receive_damage(*args)
  end

  def heal(*args)
    s=@scene
    if s!=nil && s.respond_to?(:battle_finish_pending_v10631?) &&
       s.battle_finish_pending_v10631?
      return 0
    end
    pmd_ac_v10631_heal(*args)
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v10631_refresh_action_bitmap refresh_action_bitmap unless method_defined?(:pmd_ac_v10631_refresh_action_bitmap)
  alias pmd_ac_v10631_update_animation update_animation unless method_defined?(:pmd_ac_v10631_update_animation)
  alias pmd_ac_v10631_update_dead_opacity update_dead_opacity unless method_defined?(:pmd_ac_v10631_update_dead_opacity)

  def carried_faint_sprite_v10631?
    @unit!=nil && @unit.dead? && @unit.respond_to?(:carried_faint_v10631?) &&
      @unit.carried_faint_v10631?
  rescue
    false
  end

  def freeze_faint_last_frame_v10631
    return false if @placeholder || @action_data==nil
    durations=@action_data[:durations]
    frames=@action_data[:frames].to_i
    frames=durations.size if frames<=0 && durations!=nil
    return false if frames<=0
    @frame_index=frames-1
    @frame_wait=999999
    setup_source_rect
    true
  rescue
    false
  end

  def faint_animation_complete_v10631?
    return true if @unit==nil || !@unit.dead?
    return true if carried_faint_sprite_v10631?
    return true if @placeholder || @action_data==nil
    durations=@action_data[:durations]
    frames=@action_data[:frames].to_i
    frames=durations.size if frames<=0 && durations!=nil
    return true if frames<=1
    @frame_index.to_i>=frames-1
  rescue
    true
  end

  def refresh_action_bitmap(force)
    r=pmd_ac_v10631_refresh_action_bitmap(force)
    freeze_faint_last_frame_v10631 if carried_faint_sprite_v10631?
    r
  end

  def update_animation
    if carried_faint_sprite_v10631?
      freeze_faint_last_frame_v10631
      return
    end
    pmd_ac_v10631_update_animation
  end

  def update_dead_opacity
    if @unit!=nil && @unit.dead?
      target=PMD_AC::BATTLE_CARRIED_FAINT_OPACITY_V10631
      if carried_faint_sprite_v10631?
        self.opacity=target
      elsif self.opacity>target
        self.opacity=[self.opacity-4,target].max
      end
      @bar_sprite.opacity=self.opacity if @bar_sprite!=nil
      @skill_sprite.opacity=self.opacity if @skill_sprite!=nil && @unit.skill_popup_frames<=0
      @ai_sprite.opacity=self.opacity if @ai_sprite!=nil
      @status_sprite.opacity=self.opacity if @status_sprite!=nil
      return
    end
    pmd_ac_v10631_update_dead_opacity
  end
end

#===============================================================================
# ■ Compact side team HUD
#===============================================================================
class Sprite_PMDTeamHUDV10631 < Sprite
  def initialize(viewport,scene,team)
    super(viewport)
    @scene=scene
    @team=team
    self.bitmap=Bitmap.new(PMD_AC::TEAM_HUD_W_V10631,PMD_AC::TEAM_HUD_H_V10631)
    self.x=(team==:ally ? 1 : Graphics.width-PMD_AC::TEAM_HUD_W_V10631-1)
    self.y=PMD_AC::TEAM_HUD_Y_V10631
    self.z=8200
    @last_signature=nil
    redraw
  end

  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    super
  end

  def core_units_v10631
    rows=[]
    units=@scene.instance_variable_get(:@units) || []
    for u in units
      next unless u.team==@team
      next if u.respond_to?(:summoned?) && u.summoned?
      rows << u
      break if rows.size>=3
    end
    rows
  rescue
    []
  end

  def signature_v10631
    a=[]
    for u in core_units_v10631
      a << [u.object_id,u.hp.to_i,u.maxhp.to_i,u.dead? ? 1:0,u.name.to_s,u.species.to_s]
    end
    a
  end

  def update
    super
    sig=signature_v10631
    if sig!=@last_signature
      redraw
      @last_signature=sig
    end
    self.visible=true
  end

  def set_font_v10631(b,size,bold=false)
    begin
      b.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    b.font.size=size
    b.font.bold=bold
  end

  def portrait_source_v10631(u)
    action=u.dead? ? :faint : :idle
    data=PMD_AC.action_data(u.species,action)
    return nil if data==nil
    file=data[:file]
    return nil if file==nil
    folder=PMD_AC::PMD_ROOT+u.species+'/'
    return nil unless PMD_AC.bitmap_exists?(folder,file)
    bmp=Cache.load_bitmap(folder,file)
    fw=data[:frame_w].to_i;fh=data[:frame_h].to_i
    return nil if fw<=0 || fh<=0
    frames=data[:frames].to_i
    durs=data[:durations]
    frames=durs.size if frames<=0 && durs!=nil
    fi=u.dead? ? [frames-1,0].max : 0
    dir=(@team==:ally ? 6 : 4)
    row=PMD_AC.direction_row(data,dir)
    [bmp,Rect.new(fi*fw,row*fh,fw,fh)]
  rescue
    nil
  end

  def redraw
    b=self.bitmap
    b.clear
    ally=(@team==:ally)
    edge=ally ? Color.new(65,150,235,220) : Color.new(225,85,90,220)
    fill=Color.new(8,12,18,190)
    b.fill_rect(0,0,b.width,b.height,fill)
    b.fill_rect(ally ? b.width-2 : 0,0,2,b.height,edge)
    set_font_v10631(b,11,true)
    b.font.color=ally ? Color.new(175,225,255) : Color.new(255,195,195)
    b.draw_text(2,1,b.width-4,15,ally ? '我方' : '敵方',1)
    rows=core_units_v10631
    i=0
    for u in rows
      y=17+i*52
      b.fill_rect(3,y,b.width-6,49,Color.new(0,0,0,105))
      src=portrait_source_v10631(u)
      if src!=nil
        op=u.dead? ? PMD_AC::BATTLE_CARRIED_FAINT_OPACITY_V10631 : 255
        b.stretch_blt(Rect.new(13,y+2,28,28),src[0],src[1],op)
      end
      set_font_v10631(b,9,true)
      b.font.color=u.dead? ? Color.new(160,160,160) : Color.new(245,245,245)
      name=u.name.to_s
      b.draw_text(3,y+29,b.width-6,11,name,1)
      bar_x=6;bar_y=y+41;bar_w=b.width-12
      b.fill_rect(bar_x,bar_y,bar_w,4,Color.new(15,15,15,230))
      hpw=0
      hpw=(bar_w-2)*u.hp.to_i/[u.maxhp.to_i,1].max if u.hp.to_i>0
      hpcol=u.dead? ? Color.new(100,100,100,220) : Color.new(80,220,105,235)
      b.fill_rect(bar_x+1,bar_y+1,hpw,2,hpcol) if hpw>0
      set_font_v10631(b,8,false)
      b.font.color=Color.new(220,220,220)
      label=u.dead? ? 'KO' : u.hp.to_i.to_s+'/'+u.maxhp.to_i.to_s
      b.draw_text(2,y+43,b.width-4,9,label,1)
      i+=1
    end
  rescue
  end
end

#===============================================================================
# ■ Battle-end cue
#===============================================================================
class Sprite_PMDBattleEndCueV10631 < Sprite
  attr_reader :finished

  def initialize(viewport,winner)
    super(viewport)
    @winner=winner
    @age=0
    @finished=false
    self.bitmap=Bitmap.new(Graphics.width,96)
    self.x=0
    self.y=(Graphics.height-96)/2
    self.z=9998
    draw_static_v10631
    self.opacity=0
    begin
      RPG::SE.new(PMD_AC::BATTLE_END_CUE_SE_V10631,
                  PMD_AC::BATTLE_END_CUE_SE_VOLUME_V10631,
                  PMD_AC::BATTLE_END_CUE_SE_PITCH_V10631).play
    rescue
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    super
  end

  def draw_static_v10631
    b=self.bitmap
    b.clear
    win=@winner==:ally
    band=win ? Color.new(25,80,145,225) : Color.new(135,40,48,225)
    line=win ? Color.new(130,220,255,245) : Color.new(255,155,155,245)
    b.fill_rect(0,10,b.width,76,Color.new(0,0,0,210))
    b.fill_rect(0,13,b.width,70,band)
    b.fill_rect(0,13,b.width,2,line)
    b.fill_rect(0,81,b.width,2,line)
    begin
      b.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    b.font.bold=true
    b.font.size=30
    b.font.color=Color.new(255,255,255)
    b.draw_text(0,24,b.width,40,win ? '戰鬥勝利' : '戰鬥失敗',1)
    b.font.size=12
    b.font.bold=false
    b.font.color=Color.new(225,240,250)
    b.draw_text(0,62,b.width,18,'BATTLE COMPLETE',1)
  end

  def update
    super
    @age+=1
    total=PMD_AC::BATTLE_END_CUE_FRAMES_V10631
    if @age<=10
      self.opacity=[@age*26,255].min
      self.zoom_x=1.0+(10-@age)*0.006
    elsif @age>=total-14
      remain=total-@age
      self.opacity=[[remain*18,0].max,255].min
      self.zoom_x=1.0
    else
      self.opacity=255
      self.zoom_x=1.0
    end
    @finished=true if @age>=total
  end
end

#===============================================================================
# ■ Scene integration / terminal result drain
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10631_start start unless method_defined?(:pmd_ac_v10631_start)
  alias pmd_ac_v10631_update update unless method_defined?(:pmd_ac_v10631_update)
  alias pmd_ac_v10631_terminate terminate unless method_defined?(:pmd_ac_v10631_terminate)
  alias pmd_ac_v10631_start_battle start_battle unless method_defined?(:pmd_ac_v10631_start_battle)
  alias pmd_ac_v10631_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10631_restart_to_deploy)
  alias pmd_ac_v10631_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v10631_check_battle_end)

  def battle_finish_pending_v10631?
    @battle_finish_pending_v10631 ? true : false
  end

  def battle_presentation_normal_v10631?
    return true unless respond_to?(:verification_mode)
    verification_mode==:normal
  rescue
    true
  end

  def reset_battle_presentation_v10631
    @battle_finish_pending_v10631=false
    @battle_finish_winner_v10631=nil
    @battle_finish_start_frame_v10631=-1
    @battle_finish_cue_started_v10631=false
    @battle_finish_commit_v10631=false
    if @battle_end_cue_v10631!=nil
      @battle_end_cue_v10631.dispose unless @battle_end_cue_v10631.disposed?
    end
    @battle_end_cue_v10631=nil
  rescue
  end

  def create_team_hud_v10631
    dispose_team_hud_v10631
    @team_hud_ally_v10631=Sprite_PMDTeamHUDV10631.new(@viewport,self,:ally)
    @team_hud_enemy_v10631=Sprite_PMDTeamHUDV10631.new(@viewport,self,:enemy)
  rescue
    @team_hud_ally_v10631=nil
    @team_hud_enemy_v10631=nil
  end

  def update_team_hud_v10631
    @team_hud_ally_v10631.update if @team_hud_ally_v10631!=nil && !@team_hud_ally_v10631.disposed?
    @team_hud_enemy_v10631.update if @team_hud_enemy_v10631!=nil && !@team_hud_enemy_v10631.disposed?
  rescue
  end

  def dispose_team_hud_v10631
    if @team_hud_ally_v10631!=nil && !@team_hud_ally_v10631.disposed?
      @team_hud_ally_v10631.dispose
    end
    if @team_hud_enemy_v10631!=nil && !@team_hud_enemy_v10631.disposed?
      @team_hud_enemy_v10631.dispose
    end
    @team_hud_ally_v10631=nil
    @team_hud_enemy_v10631=nil
  rescue
  end

  def start
    pmd_ac_v10631_start
    reset_battle_presentation_v10631
    create_team_hud_v10631
    begin
      log_event(:battle,'BATTLE_PRESENTATION_V10631 READY carried_faint=static_half_opacity'+
        ' result_lock=1 presentation_drain=1 end_cue=1 side_hud=2x3 gameplay_change=0')
    rescue
    end
  end

  def start_battle
    reset_battle_presentation_v10631
    r=pmd_ac_v10631_start_battle
    create_team_hud_v10631 if @team_hud_ally_v10631==nil || @team_hud_enemy_v10631==nil
    begin
      carried=[]
      for u in (@units||[])
        if u.team==:ally && u.respond_to?(:carried_faint_v10631?) && u.carried_faint_v10631?
          carried << u.name.to_s
        end
      end
      log_event(:battle,'BATTLE_CARRIED_FAINT_V10631 count='+carried.size.to_s+
        ' names=['+carried.join(',')+'] opacity='+PMD_AC::BATTLE_CARRIED_FAINT_OPACITY_V10631.to_s+
        ' static_pose=1 combat_motion=0')
    rescue
    end
    r
  end

  def restart_to_deploy
    reset_battle_presentation_v10631
    r=pmd_ac_v10631_restart_to_deploy
    create_team_hud_v10631
    r
  end

  def terminate
    dispose_team_hud_v10631
    reset_battle_presentation_v10631
    pmd_ac_v10631_terminate
  end

  def update
    pmd_ac_v10631_update
    return if $scene!=self
    update_team_hud_v10631
    update_battle_finish_v10631 if battle_finish_pending_v10631?
  end

  def check_battle_end
    return pmd_ac_v10631_check_battle_end if @battle_finish_commit_v10631
    return pmd_ac_v10631_check_battle_end unless battle_presentation_normal_v10631?
    return false if battle_finish_pending_v10631?
    allies=core_living_units(:ally)
    enemies=core_living_units(:enemy)
    return pmd_ac_v10631_check_battle_end if !allies.empty? && !enemies.empty?
    @battle_finish_pending_v10631=true
    @battle_finish_winner_v10631=enemies.empty? ? :ally : :enemy
    @battle_finish_start_frame_v10631=Graphics.frame_count.to_i
    @battle_finish_cue_started_v10631=false
    begin
      log_event(:battle,'BATTLE_FINISH_DRAIN_V10631 BEGIN winner='+@battle_finish_winner_v10631.to_s+
        ' min='+PMD_AC::BATTLE_FINISH_MIN_DRAIN_V10631.to_s+
        ' max='+PMD_AC::BATTLE_FINISH_MAX_DRAIN_V10631.to_s+
        ' ai_locked=1 hp_locked=1')
    rescue
    end
    false
  rescue
    pmd_ac_v10631_check_battle_end
  end

  def battle_finish_visual_busy_v10631?
    return true if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
    return true if respond_to?(:result_feedback_hold_active_v10513?) && result_feedback_hold_active_v10513?
    for u in (@units||[])
      next if u==nil || u.dead?
      timer=u.instance_variable_get(:@action_timer).to_i
      return true if timer>0
      if u.respond_to?(:presentation_motion_active_v055?) && u.presentation_motion_active_v055?
        return true
      end
      if u.respond_to?(:tactical_slide_active_v0914?) && u.tactical_slide_active_v0914?
        return true
      end
    end
    for sp in (@unit_sprites||[])
      if sp.respond_to?(:faint_animation_complete_v10631?) &&
         !sp.faint_animation_complete_v10631?
        return true
      end
    end
    for sp in (@projectile_sprites||[])
      begin
        return true unless sp.finished
      rescue
        return true
      end
    end
    for sp in (@effect_sprites||[])
      begin
        return true unless sp.finished
      rescue
        return true
      end
    end
    false
  rescue
    false
  end

  def start_battle_end_cue_v10631(age,timed_out)
    return if @battle_finish_cue_started_v10631
    @battle_finish_cue_started_v10631=true
    @battle_end_cue_v10631=Sprite_PMDBattleEndCueV10631.new(@viewport,@battle_finish_winner_v10631)
    begin
      log_event(:battle,'BATTLE_FINISH_DRAIN_V10631 COMPLETE age='+age.to_s+
        ' timeout='+(timed_out ? '1':'0')+' cue_frames='+PMD_AC::BATTLE_END_CUE_FRAMES_V10631.to_s)
      log_event(:battle,'BATTLE_END_CUE_V10631 START winner='+@battle_finish_winner_v10631.to_s+
        ' se='+PMD_AC::BATTLE_END_CUE_SE_V10631)
    rescue
    end
  end

  def update_battle_finish_v10631
    age=Graphics.frame_count.to_i-@battle_finish_start_frame_v10631.to_i
    unless @battle_finish_cue_started_v10631
      min_ok=age>=PMD_AC::BATTLE_FINISH_MIN_DRAIN_V10631
      timed_out=age>=PMD_AC::BATTLE_FINISH_MAX_DRAIN_V10631
      if (min_ok && !battle_finish_visual_busy_v10631?) || timed_out
        start_battle_end_cue_v10631(age,timed_out)
      end
      return
    end
    return if @battle_end_cue_v10631==nil
    @battle_end_cue_v10631.update
    return unless @battle_end_cue_v10631.finished
    @battle_end_cue_v10631.dispose unless @battle_end_cue_v10631.disposed?
    @battle_end_cue_v10631=nil
    begin
      log_event(:battle,'BATTLE_END_CUE_V10631 COMPLETE settlement_release=1')
    rescue
    end
    @battle_finish_commit_v10631=true
    @battle_finish_pending_v10631=false
    pmd_ac_v10631_check_battle_end
    @battle_finish_commit_v10631=false
  rescue
    @battle_finish_commit_v10631=true
    @battle_finish_pending_v10631=false
    pmd_ac_v10631_check_battle_end
    @battle_finish_commit_v10631=false
  end
end
