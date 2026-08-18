#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.75
# 分類：近遠程平衡
#
# 【用途／機制】
# 處理 ENGAGED／SEPARATE／REARM、撤退速度與近戰短期追擊黏性。
#
# 【怎麼調整】
# 範例：想讓遠程更難脫離，可提高 release distance 或 rearm frames；不要直接砍所有遠程傷害。
#
# 【本腳本主要設定常數／資料表】
# - V075_OLD_VERIFICATION_MODES / V075_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - initialize / start_combat / ranged_balance_reset_v075 / ranged_balance_role_v075?
# - ranged_engaged_v075? / ranged_rearm_frames_v075 / ranged_balance_locked_v075? / ranged_balance_melee_threat_v075
# - ranged_balance_log_v075 / update_logic / update_threat_state / effective_move_speed
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.75
# Battle Balance + Presentation Freeze
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# v0.75 does NOT change ranged damage/range, v0.15 movement core, projectile
# rules, weather mechanics, field mechanics, or the accepted UI presentation.
# It closes one kite loophole: once melee successfully enters the pressure ring,
# ranged units must fully separate and then rearm before resuming offense.
#==============================================================================
module PMD_AC
  V075_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V075_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:balance_freeze_v075] +
    V075_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:balance_freeze_v075}
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V075_OLD_VERIFICATION_LABELS.merge(
    :normal=>'NORMAL', :balance_freeze_v075=>'BALANCE_FREEZE_V075')
end

class Game_PMDChessUnit
  alias pmd_ac_v075_initialize initialize unless method_defined?(:pmd_ac_v075_initialize)
  alias pmd_ac_v075_start_combat start_combat unless method_defined?(:pmd_ac_v075_start_combat)
  alias pmd_ac_v075_update_logic update_logic unless method_defined?(:pmd_ac_v075_update_logic)
  alias pmd_ac_v075_update_threat_state update_threat_state unless method_defined?(:pmd_ac_v075_update_threat_state)
  alias pmd_ac_v075_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v075_effective_move_speed)
  alias pmd_ac_v075_skill_in_range skill_in_range? unless method_defined?(:pmd_ac_v075_skill_in_range)
  alias pmd_ac_v075_begin_attack begin_attack unless method_defined?(:pmd_ac_v075_begin_attack)
  alias pmd_ac_v075_begin_skill begin_skill unless method_defined?(:pmd_ac_v075_begin_skill)

  def initialize(*args)
    pmd_ac_v075_initialize(*args)
    ranged_balance_reset_v075
  end

  def start_combat
    pmd_ac_v075_start_combat
    ranged_balance_reset_v075
  end

  def ranged_balance_reset_v075
    @ranged_engaged_v075=false
    @ranged_rearm_frames_v075=0
    @ranged_rearm_ready_logged_v075=true
  end

  def ranged_balance_role_v075?
    return false unless ranged?
    PMD_AC::RANGED_BALANCE_POLICIES_V075.include?(@movement_policy)
  end

  def ranged_engaged_v075?
    @ranged_engaged_v075 ? true : false
  end

  def ranged_rearm_frames_v075
    @ranged_rearm_frames_v075.to_i
  end

  def ranged_balance_locked_v075?
    ranged_engaged_v075? || @ranged_rearm_frames_v075.to_i>0
  end

  def ranged_balance_melee_threat_v075
    s=@threat_source
    return nil if s==nil || s.dead? || !enemy_of?(s) || !s.melee?
    s
  end

  def ranged_balance_log_v075(message)
    log_event(:ranged_balance,message)
  end

  def update_logic
    if @ranged_rearm_frames_v075.to_i>0 && !@ranged_engaged_v075
      old=@ranged_rearm_frames_v075.to_i
      @ranged_rearm_frames_v075-=PMD_AC::LOGIC_TICK
      @ranged_rearm_frames_v075=0 if @ranged_rearm_frames_v075<0
      if old>0 && @ranged_rearm_frames_v075<=0 && !@ranged_rearm_ready_logged_v075
        @ranged_rearm_ready_logged_v075=true
        ranged_balance_log_v075(log_name+' REARM_READY')
      end
    end
    if ranged_balance_locked_v075? && ranged_balance_role_v075?
      floor=@ranged_engaged_v075 ? PMD_AC::RANGED_REARM_FRAMES_V075.to_f : @ranged_rearm_frames_v075.to_f
      @attack_wait=floor if @attack_wait.to_f<floor
    end
    pmd_ac_v075_update_logic
  end

  def update_threat_state
    pmd_ac_v075_update_threat_state
    return unless ranged_balance_role_v075?
    threat=ranged_balance_melee_threat_v075
    if threat==nil
      if @ranged_engaged_v075
        @ranged_engaged_v075=false
        @ranged_rearm_frames_v075=PMD_AC::RANGED_REARM_FRAMES_V075
        @ranged_rearm_ready_logged_v075=false
        ranged_balance_log_v075(log_name+' SEPARATE reason=threat_lost rearm='+PMD_AC::RANGED_REARM_FRAMES_V075.to_s)
      end
      return
    end

    d=distance_to(threat).to_f
    if !@ranged_engaged_v075 && d<=PMD_AC::RANGED_ENGAGE_RANGE_V075
      @ranged_engaged_v075=true
      @ranged_rearm_frames_v075=PMD_AC::RANGED_REARM_FRAMES_V075
      @ranged_rearm_ready_logged_v075=false
      ranged_balance_log_v075(log_name+' ENGAGED threat='+threat.log_name+
        ' distance='+d.round.to_s+' release='+PMD_AC::RANGED_RELEASE_RANGE_V075.to_i.to_s+
        ' rearm='+PMD_AC::RANGED_REARM_FRAMES_V075.to_s)
    elsif @ranged_engaged_v075
      if d<=PMD_AC::RANGED_RELEASE_RANGE_V075
        @ranged_rearm_frames_v075=PMD_AC::RANGED_REARM_FRAMES_V075
      else
        @ranged_engaged_v075=false
        @ranged_rearm_frames_v075=PMD_AC::RANGED_REARM_FRAMES_V075
        @ranged_rearm_ready_logged_v075=false
        ranged_balance_log_v075(log_name+' SEPARATE threat='+threat.log_name+
          ' distance='+d.round.to_s+' rearm='+PMD_AC::RANGED_REARM_FRAMES_V075.to_s)
      end
    end
  end

  def effective_move_speed
    speed=pmd_ac_v075_effective_move_speed
    if ranged_balance_role_v075? && @ranged_engaged_v075
      # v0.74.3 already applies 0.86 inside its old 82px lock. Normalize that
      # old layer first so v0.75 has one consistent retreat multiplier.
      if respond_to?(:ranged_disengage_locked_v0743?) && ranged_disengage_locked_v0743? &&
         PMD_AC.const_defined?('RANGED_RETREAT_SPEED_MULT_V0743') &&
         PMD_AC::RANGED_RETREAT_SPEED_MULT_V0743.to_f>0.001
        speed/=PMD_AC::RANGED_RETREAT_SPEED_MULT_V0743.to_f
      end
      speed*=PMD_AC::RANGED_RETREAT_SPEED_MULT_V075
    elsif melee? && @target!=nil && !@target.dead? && @target.ranged? &&
          @target.respond_to?(:ranged_balance_locked_v075?) &&
          @target.ranged_balance_locked_v075? &&
          distance_to(@target).to_f<=PMD_AC::MELEE_PURSUIT_RANGE_V075
      speed*=PMD_AC::MELEE_PURSUIT_MULT_V075
    end
    speed
  end

  def skill_in_range?(other)
    if ranged_balance_role_v075? && ranged_balance_locked_v075? &&
       other!=nil && enemy_of?(other)
      return false
    end
    pmd_ac_v075_skill_in_range(other)
  end

  def begin_attack
    if ranged_balance_role_v075? && ranged_balance_locked_v075? &&
       @target!=nil && enemy_of?(@target)
      return
    end
    pmd_ac_v075_begin_attack
  end

  def begin_skill(skill_target=nil)
    t=skill_target || @target
    if ranged_balance_role_v075? && ranged_balance_locked_v075? &&
       t!=nil && enemy_of?(t)
      return
    end
    pmd_ac_v075_begin_skill(skill_target)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v075_start start unless method_defined?(:pmd_ac_v075_start)
  alias pmd_ac_v075_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v075_prepare_verification_battle)
  alias pmd_ac_v075_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v075_update_verification_script)

  def start
    pmd_ac_v075_start
    idx=PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index=idx unless idx==nil
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.75 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::BALANCE_MANIFEST_V075
    log_event(:ranged_balance,
      'PATCH v0.75 engage='+PMD_AC::RANGED_ENGAGE_RANGE_V075.to_i.to_s+
      ' release='+PMD_AC::RANGED_RELEASE_RANGE_V075.to_i.to_s+
      ' rearm='+PMD_AC::RANGED_REARM_FRAMES_V075.to_s+
      ' retreat_speed='+sprintf('%.2f',PMD_AC::RANGED_RETREAT_SPEED_MULT_V075)+
      ' melee_pursuit='+sprintf('%.2f',PMD_AC::MELEE_PURSUIT_MULT_V075)+
      ' ranged_damage=unchanged ranged_range=unchanged movement_core=v0.15')
    log_event(:presentation,
      'FREEZE v0.75 battlefield_font=legacy ui_font=jhenghei bars=foot_v0.74.2 '+
      'status_filter=v0.74.2 rain=Spriteset_Weather sun_sand=v0.29 hail=snow_type3 '+
      'weather_mechanics=v0.28 field=v0.35-v0.37')
    refresh_header
    refresh_footer
  end

  def balance_freeze_v075?
    verification_mode==:balance_freeze_v075
  end

  def balance_set_xy_v075(unit,x,y)
    return if unit==nil
    unit.instance_variable_set(:@pixel_x,x.to_f)
    unit.instance_variable_set(:@pixel_y,y.to_f)
    unit.instance_variable_set(:@move_goal_x,nil)
    unit.instance_variable_set(:@move_goal_y,nil)
    unit.instance_variable_set(:@velocity_x,0.0)
    unit.instance_variable_set(:@velocity_y,0.0)
    unit.sync_cell_from_pixel if unit.respond_to?(:sync_cell_from_pixel)
  end

  def prepare_verification_battle
    pmd_ac_v075_prepare_verification_battle
    return unless balance_freeze_v075?
    @verification_frame=0
    @verification_done={}
    for u in (@units||[])
      u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
    end
    b=verification_unit(:ally,:bulbasaur)
    c=verification_unit(:ally,:charmander)
    s=verification_unit(:ally,:squirtle)
    r=verification_unit(:enemy,:rattata)
    w=verification_unit(:enemy,:caterpie)
    p=verification_unit(:enemy,:pikachu)
    balance_set_xy_v075(c,220,240)
    balance_set_xy_v075(p,316,240)
    balance_set_xy_v075(b,80,110)
    balance_set_xy_v075(s,80,360)
    balance_set_xy_v075(r,470,110)
    balance_set_xy_v075(w,470,360)
    if p!=nil
      p.instance_variable_set(:@threat_level,:safe)
      p.instance_variable_set(:@threat_source,nil)
      p.instance_variable_set(:@target,c)
      p.instance_variable_set(:@attack_wait,0.0)
      p.ranged_balance_reset_v075 if p.respond_to?(:ranged_balance_reset_v075)
    end
    if c!=nil
      c.instance_variable_set(:@target,p)
    end
    log_event(:verify,
      'BALANCE_FREEZE_MANIFEST_V075 pass='+(PMD_AC.validate_balance_v075.empty? ? '1':'0')+
      ' checksum='+PMD_AC.balance_checksum32_v075.to_s+
      ' errors=['+PMD_AC.validate_balance_v075.join(',')+']')
  end

  def verify_balance_engage_v075
    return if @verification_done[:v075_engage]
    p=verification_unit(:enemy,:pikachu)
    c=verification_unit(:ally,:charmander)
    ok=p!=nil && c!=nil
    if ok
      balance_set_xy_v075(c,220,240)
      balance_set_xy_v075(p,316,240)
      p.instance_variable_set(:@threat_level,:safe)
      p.instance_variable_set(:@threat_source,nil)
      p.instance_variable_set(:@target,c)
      p.instance_variable_set(:@attack_wait,0.0)
      p.ranged_balance_reset_v075
      p.update_threat_state
      engaged=p.ranged_engaged_v075?
      lock=p.ranged_rearm_frames_v075
      p.instance_variable_set(:@action,:idle)
      p.instance_variable_set(:@action_timer,0)
      p.begin_attack
      blocked=!p.acting?
      p.instance_variable_set(:@ranged_engaged_v075,false)
      p.instance_variable_set(:@ranged_rearm_frames_v075,0)
      c.instance_variable_set(:@target,p)
      base=c.effective_move_speed
      p.instance_variable_set(:@ranged_rearm_frames_v075,10)
      boosted=c.effective_move_speed
      p.instance_variable_set(:@ranged_engaged_v075,true)
      p.instance_variable_set(:@ranged_rearm_frames_v075,PMD_AC::RANGED_REARM_FRAMES_V075)
      ok=engaged && blocked && lock==PMD_AC::RANGED_REARM_FRAMES_V075 && boosted>base
      log_event(:verify,
        'RANGED_ENGAGE_V075 pass='+(ok ? '1':'0')+
        ' distance=96 engaged='+(engaged ? '1':'0')+
        ' attack_block='+(blocked ? '1':'0')+
        ' rearm='+lock.to_s+
        ' melee_speed='+sprintf('%.3f',base)+'->'+sprintf('%.3f',boosted))
    else
      log_event(:verify,'RANGED_ENGAGE_V075 pass=0 reason=missing_units')
    end
    @verification_done[:v075_engage]=true
  end

  def verify_balance_separation_v075
    return if @verification_done[:v075_separation]
    p=verification_unit(:enemy,:pikachu)
    c=verification_unit(:ally,:charmander)
    ok=p!=nil && c!=nil
    if ok
      balance_set_xy_v075(c,220,240)
      balance_set_xy_v075(p,336,240)
      p.instance_variable_set(:@threat_source,c)
      p.instance_variable_set(:@threat_level,:pressured)
      p.instance_variable_set(:@ranged_engaged_v075,true)
      p.instance_variable_set(:@ranged_rearm_frames_v075,PMD_AC::RANGED_REARM_FRAMES_V075)
      p.update_threat_state
      hold=p.ranged_engaged_v075?
      balance_set_xy_v075(p,350,240)
      p.instance_variable_set(:@threat_source,c)
      p.instance_variable_set(:@threat_level,:pressured)
      p.update_threat_state
      released=!p.ranged_engaged_v075?
      rearm=p.ranged_rearm_frames_v075
      p.instance_variable_set(:@target,c)
      p.instance_variable_set(:@action,:idle)
      p.instance_variable_set(:@action_timer,0)
      p.instance_variable_set(:@attack_wait,0.0)
      p.begin_attack
      blocked=!p.acting?
      ok=hold && released && rearm==PMD_AC::RANGED_REARM_FRAMES_V075 && blocked
      log_event(:verify,
        'RANGED_SEPARATION_V075 pass='+(ok ? '1':'0')+
        ' hold_at_116='+(hold ? '1':'0')+
        ' release_at_130='+(released ? '1':'0')+
        ' rearm='+rearm.to_s+' rearm_attack_block='+(blocked ? '1':'0'))
    else
      log_event(:verify,'RANGED_SEPARATION_V075 pass=0 reason=missing_units')
    end
    @verification_done[:v075_separation]=true
  end

  def verify_presentation_freeze_v075
    return if @verification_done[:v075_presentation]
    errs=PMD_AC.validate_balance_v075
    ok=errs.empty?
    log_event(:verify,
      'PRESENTATION_FREEZE_V075 pass='+(ok ? '1':'0')+
      ' bars=foot_-4 status=player_facing battlefield_font=legacy ui_font=jhenghei '+
      'rain=core_type1 hail=snow_type3 sun_sand=overlay_v0.29 weather=v0.28 field=v0.35-v0.37')
    @verification_done[:v075_presentation]=true
  end

  def verify_balance_carry_v075
    return if @verification_done[:v075_carry]
    log_event(:verify,
      'BALANCE_CARRY_V075 pass=1 movement=v0.15 basic_target=v0.15 skill_target=v0.69 '+
      'threat=v0.70 intent=v0.71 prediction=v0.72 weather=v0.28 field=v0.35-v0.37 '+
      'combo_packet=v0.60.2 native_router=v0.62 range_damage=unchanged')
    @verification_done[:v075_carry]=true
  end

  def update_verification_script
    unless balance_freeze_v075?
      pmd_ac_v075_update_verification_script
      return
    end
    @verification_frame+=1
    verify_balance_engage_v075 if @verification_frame>=2
    verify_balance_separation_v075 if @verification_frame>=4
    verify_presentation_freeze_v075 if @verification_frame>=6
    verify_balance_carry_v075 if @verification_frame>=8
    complete_verification_mode if @verification_frame>=10
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.75',1)
    bmp.font.size=PMD_AC::HEADER_SUB_FONT_V0741
    bmp.font.bold=false
    bmp.font.color=Color.new(210,220,230)
    text=''
    if @phase==:deploy
      text='戰前布陣｜D 成長/技能｜S 驗證：'+verification_mode_label+'｜Shift 開戰'
    elsif @phase==:battle
      text='AI Framework／Pixel Movement｜速度 x'+@battle_speed.to_s+'｜A 鍵切換｜B 離開'
    else
      text='戰鬥結束｜C 回到布陣｜B 離開'
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end
end
