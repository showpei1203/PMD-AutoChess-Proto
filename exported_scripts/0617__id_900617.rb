# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Battle Presentation Polish v1.06.32
#-------------------------------------------------------------------------------
#  1. Result settlement hides the battle footer and both side team HUD rails.
#  2. Side team HUD is vertically centered in the board gutter and uses
#     fit-to-width text metrics so CJK names / HP values do not clip.
#  3. Battle finish drain becomes primarily event-driven. The redundant fixed
#     42-frame floor is reduced while the actual faint / action / projectile /
#     effect completion gates remain authoritative.
#-------------------------------------------------------------------------------
#  Presentation-only. AI choice, damage, attack speed and spatial endpoints are
#  intentionally unchanged.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BattlePresentationPolish_v10632']=true

module PMD_AC
  # v1.06.31 already checks real visual-busy state. A 42-frame mandatory floor
  # on top of that made a healthy result transition look like a hitch.
  remove_const(:BATTLE_FINISH_MIN_DRAIN_V10631) if const_defined?(:BATTLE_FINISH_MIN_DRAIN_V10631)
  BATTLE_FINISH_MIN_DRAIN_V10631 = 6
  remove_const(:BATTLE_END_CUE_FRAMES_V10631) if const_defined?(:BATTLE_END_CUE_FRAMES_V10631)
  BATTLE_END_CUE_FRAMES_V10631 = 36

  TEAM_HUD_H_V10632 = 248
  TEAM_HUD_Y_V10632 = GRID_Y + ((GRID_ROWS * CELL_H - TEAM_HUD_H_V10632) / 2)
  TEAM_HUD_HEADER_H_V10632 = 20
  TEAM_HUD_ROW_H_V10632 = 76

  class << self
    alias pmd_ac_v10632_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10632_write_project_state_log)

    def project_version
      '1.06.32'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10632_write_project_state_log(force)
      return false unless r
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=20')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.32')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=BATTLE_PRESENTATION_POLISH+HUNT_UNLOCK_RETREAT')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=BATTLE_PRESENTATION_POLISH_WINDOWS_ACCEPTANCE')
      text=text.gsub(/\r?\nBATTLE_PRESENTATION_POLISH_V10632_BEGIN.*?BATTLE_PRESENTATION_POLISH_V10632_END\r?\n/m,"\r\n")
      lines=[]
      lines << ''
      lines << 'BATTLE_PRESENTATION_POLISH_V10632_BEGIN'
      lines << 'RESULT_BATTLE_FOOTER_HIDDEN=READY'
      lines << 'RESULT_SIDE_TEAM_HUD_HIDDEN=READY'
      lines << 'SIDE_TEAM_HUD_VERTICAL_CENTER=READY'
      lines << 'SIDE_TEAM_HUD_TEXT_FIT=READY'
      lines << 'SIDE_TEAM_HUD_HEIGHT='+TEAM_HUD_H_V10632.to_s
      lines << 'SIDE_TEAM_HUD_Y='+TEAM_HUD_Y_V10632.to_s
      lines << 'BATTLE_FINISH_EVENT_DRIVEN=1'
      lines << 'BATTLE_FINISH_MIN_DRAIN_FRAMES='+BATTLE_FINISH_MIN_DRAIN_V10631.to_s
      lines << 'BATTLE_END_CUE_FRAMES='+BATTLE_END_CUE_FRAMES_V10631.to_s
      lines << 'BATTLE_SETTLEMENT_HANDOFF_TIMING_LOG=1'
      lines << 'BATTLE_PRESENTATION_POLISH_GAMEPLAY_CHANGE=0'
      lines << 'BATTLE_PRESENTATION_POLISH_WINDOWS_ACCEPTANCE=PENDING_USER_RUN'
      lines << 'BATTLE_PRESENTATION_POLISH_V10632_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

#===============================================================================
# ■ Side team HUD readability / vertical balance
#===============================================================================
class Sprite_PMDTeamHUDV10631
  def initialize(viewport,scene,team)
    super(viewport)
    @scene=scene
    @team=team
    self.bitmap=Bitmap.new(PMD_AC::TEAM_HUD_W_V10631,PMD_AC::TEAM_HUD_H_V10632)
    self.x=(team==:ally ? 1 : Graphics.width-PMD_AC::TEAM_HUD_W_V10631-1)
    self.y=PMD_AC::TEAM_HUD_Y_V10632
    self.z=8200
    @last_signature=nil
    redraw
  end

  def fit_font_v10632(b,text,max_w,start_size,min_size,bold=false)
    size=start_size
    while size>min_size
      set_font_v10631(b,size,bold)
      break if b.text_size(text.to_s).width<=max_w
      size-=1
    end
    set_font_v10631(b,size,bold)
    size
  rescue
    set_font_v10631(b,min_size,bold)
    min_size
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
    b.draw_text(2,1,b.width-4,18,ally ? '我方' : '敵方',1)

    rows=core_units_v10631
    i=0
    for u in rows
      y=PMD_AC::TEAM_HUD_HEADER_H_V10632+i*PMD_AC::TEAM_HUD_ROW_H_V10632
      b.fill_rect(3,y+1,b.width-6,PMD_AC::TEAM_HUD_ROW_H_V10632-3,Color.new(0,0,0,105))

      src=portrait_source_v10631(u)
      if src!=nil
        op=u.dead? ? PMD_AC::BATTLE_CARRIED_FAINT_OPACITY_V10631 : 255
        b.stretch_blt(Rect.new(13,y+4,28,28),src[0],src[1],op)
      end

      name=u.name.to_s
      fit_font_v10632(b,name,b.width-8,10,8,true)
      b.font.color=u.dead? ? Color.new(160,160,160) : Color.new(245,245,245)
      b.draw_text(4,y+33,b.width-8,17,name,1)

      bar_x=6
      bar_y=y+52
      bar_w=b.width-12
      b.fill_rect(bar_x,bar_y,bar_w,5,Color.new(15,15,15,230))
      hpw=0
      hpw=(bar_w-2)*u.hp.to_i/[u.maxhp.to_i,1].max if u.hp.to_i>0
      hpcol=u.dead? ? Color.new(100,100,100,220) : Color.new(80,220,105,235)
      b.fill_rect(bar_x+1,bar_y+1,hpw,3,hpcol) if hpw>0

      label=u.dead? ? 'KO' : u.hp.to_i.to_s+'/'+u.maxhp.to_i.to_s
      fit_font_v10632(b,label,b.width-6,9,7,false)
      b.font.color=Color.new(220,220,220)
      b.draw_text(3,y+58,b.width-6,17,label,1)
      i+=1
    end
  rescue
  end
end

#===============================================================================
# ■ Result UI cleanup + quicker event-driven settlement handoff
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10632_update update unless method_defined?(:pmd_ac_v10632_update)
  alias pmd_ac_v10632_start_battle start_battle unless method_defined?(:pmd_ac_v10632_start_battle)
  alias pmd_ac_v10632_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10632_restart_to_deploy)
  alias pmd_ac_v10632_show_result show_result unless method_defined?(:pmd_ac_v10632_show_result)

  def battle_result_ui_active_v10632?
    @phase==:result || (@result_sprite!=nil && !@result_sprite.disposed? && @result_sprite.visible)
  rescue
    @phase==:result
  end

  def set_battle_chrome_visible_v10632(value)
    v=value ? true:false
    @footer_sprite.visible=v if @footer_sprite!=nil && !@footer_sprite.disposed?
    @team_hud_ally_v10631.visible=v if @team_hud_ally_v10631!=nil && !@team_hud_ally_v10631.disposed?
    @team_hud_enemy_v10631.visible=v if @team_hud_enemy_v10631!=nil && !@team_hud_enemy_v10631.disposed?
  rescue
  end

  def update
    pmd_ac_v10632_update
    return if $scene!=self
    if battle_result_ui_active_v10632?
      set_battle_chrome_visible_v10632(false)
    elsif @phase==:deploy || @phase==:battle
      set_battle_chrome_visible_v10632(true)
    end
  end

  def start_battle
    set_battle_chrome_visible_v10632(true)
    pmd_ac_v10632_start_battle
  end

  def restart_to_deploy
    r=pmd_ac_v10632_restart_to_deploy
    set_battle_chrome_visible_v10632(true)
    r
  end

  def show_result
    # Hide footer + side rails before the large settlement panel is drawn so
    # there is no single-frame flash of duplicate result text underneath it.
    set_battle_chrome_visible_v10632(false)
    r=pmd_ac_v10632_show_result
    set_battle_chrome_visible_v10632(false)
    r
  end

  # Replaces only the v1.06.31 result-drain updater. The busy query still waits
  # for actual faint/action/focus/projectile/effect completion. The old fixed
  # 42-frame floor is no longer duplicated on top of those real gates.
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
      log_event(:battle,'BATTLE_END_CUE_V10632 COMPLETE settlement_release=1')
    rescue
    end
    @battle_finish_commit_v10631=true
    @battle_finish_pending_v10631=false
    t0=Time.now
    pmd_ac_v10631_check_battle_end
    elapsed=((Time.now-t0).to_f*1000.0).round
    begin
      log_event(:perf,'BATTLE_SETTLEMENT_HANDOFF_V10632 ms='+elapsed.to_s+
        ' footer_hidden=1 side_hud_hidden=1')
    rescue
    end
    @battle_finish_commit_v10631=false
  rescue
    @battle_finish_commit_v10631=true
    @battle_finish_pending_v10631=false
    pmd_ac_v10631_check_battle_end
    @battle_finish_commit_v10631=false
  end
end
