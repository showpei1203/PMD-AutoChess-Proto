# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Result Impact Hold + Stat Stage FX v1.05.13
#===============================================================================
# 【用途】
# 1. 延續 v1.05.11～v1.05.12 Result Feedback Semantics，補足「結果雖然有文字，
#    但戰場恢復太快、能力升降缺少統一動態語言、KO 常發生在非 Focus 路徑而看不到」
#    三個 Windows 實機可讀性缺口。
# 2. 能力實際上升時，在該 battler 身上播放統一紅色橢圓光圈「由下往上」；
#    能力實際下降時，播放統一藍色橢圓光圈「由上往下」。
# 3. 任何 NORMAL battle 中真正進入 faint 的 battler 都顯示「KO」，不再限定必須
#    剛好死於 Focus Action Lane。死亡 Authority 仍是原 start_faint，本版只做 Presentation。
# 4. Focus 技能的 Action / Projectile / Effect / Displacement 全部完成後，在世界恢復前
#    額外保留 18f Result Hold，讓 Damage / Stat FX / Status / KO 有清楚的閱讀拍點。
#
# 【Windows 實機依據】
# - v1.05.12 NORMAL LOG 已確認：吐絲對三隻我方實際產生 -速度，叫聲產生 -攻擊；
#   Guard「防禦」與 Knockback「擊退」也正常進入 Result Feedback。
# - 同一份 LOG 的兩場 summary 都是 ko=0 / ko_dominant=0，說明當場死亡發生在
#   非 Focus 路徑，因此舊版「只在 Focus context 顯示 KO」會自然漏看。
#
# 【主要設定】
# RESULT_IMPACT_HOLD_FRAMES_V10513 = 18
#   技能完整作用結束後額外 freeze 18f（60fps 約 0.30 秒）。此期間不推進 AI、
#   Energy、Attack Wait、owner action clock 或 logical Spatial；只讓既有 sprite presentation
#   與本版 stat ring 依 Graphics.frame_count 顯示。
# RESULT_STAT_FX_FRAMES_V10513 = 28
#   能力升降光圈存續 28f。
# RESULT_KO_FRAMES_V10513 = 42
#   KO target-local 文字顯示 42f，沿用既有 v1.05.11 dead-unit status sprite，不新增 KO sprite。
#
# 【能力升降視覺規則】
# - 實際 stage change > 0：紅色 additive 橢圓光圈，從腳邊向上移動並淡出。
# - 實際 stage change < 0：藍色 additive 橢圓光圈，從上方向腳邊下降並淡出。
# - 只看 effective change_stat_stage 的前後結果，不看技能名稱；Contrary、Simple、
#   Keen Eye、stage clamp 等既有 Authority 全部先執行，本版只在「真的變了」之後播放。
# - 同一招同時有上升與下降（例如 Shell Smash 類）時，紅／藍兩個 channel 可各自播放。
# - 光圈為 Presentation child sprite，不改 logical x/y，不冒充 dash / knockback / pull。
#
# 【KO 規則】
# - NORMAL battle 中 start_faint 真正被呼叫後，dead unit 頭頂顯示「KO」。
# - Focus KO 仍讓 v1.05.12 Compound Arbiter 清掉次要結果；本版只把最終文字改成更醒目的 KO。
# - 非 Focus 普攻／被動／其他合法傷害造成的 KO 也能顯示，不再依賴 Focus context。
#
# 【Result Hold 規則】
# - 只攔截 reason=:skill_visual_complete；timeout / owner_gone 等 safety completion 不延長。
# - 第一次收到 completion request 時，先強制 flush v1.05.12 尚未滿 6f 的結果文字，
#   再開始 18f hold。hold 完才呼叫原 complete chain 並恢復世界。
# - 這是使用者明確要求的 Presentation freeze 延長；Damage、HP、AI choice、Energy amount、
#   Attack Wait 數值、Priority、logical Spatial endpoint 與技能 hit timing 不變。
#
# 【可調參數】
# - RESULT_IMPACT_HOLD_FRAMES_V10513：結果停頓長度，預設 18f。
# - RESULT_STAT_FX_FRAMES_V10513：能力光圈長度，預設 28f。
# - RESULT_STAT_RING_W/H_V10513：光圈 bitmap 尺寸。
# - RESULT_KO_FRAMES_V10513：KO 文字停留長度，預設 42f。
#
# 【事件／腳本呼叫】
# 無需事件呼叫。NORMAL battle 自動啟用。
# 主要 LOG：
#   BATTLE_RESULT_IMPACT_HOLD_STAT_FX_V10513 START ...
#   BATTLE_STAT_STAGE_FX_V10513 target=... dir=up/down stat=... delta=...
#   BATTLE_KO_FEEDBACK_V10513 target=... focus=0/1 text=KO
#   BATTLE_RESULT_HOLD_V10513 START ... / COMPLETE ...
#   BATTLE_RESULT_IMPACT_HOLD_STAT_FX_SUMMARY_V10513 ...
#
# 【實際範例】
# 1. 叫聲成功讓波波攻擊下降：波波顯示「-攻擊」，同時藍色光圈由上往下。
# 2. 劍舞成功提高攻擊：施放者顯示「+攻擊」，同時紅色光圈由腳邊往上。
# 3. Shell Smash 同時有能力下降與上升：藍／紅 channel 都可觸發，不把其中一類吃掉。
# 4. 普攻打倒敵人：即使當下沒有 Focus，也會在 faint sprite 上顯示「KO」。
# 5. 水槍命中＋擊退完成：等 projectile / effect / displacement 完成後，再停 18f 才恢復全場。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ResultImpactHoldStatFX_v10513']=true

module PMD_AC
  RESULT_IMPACT_HOLD_FRAMES_V10513 = 18
  RESULT_STAT_FX_FRAMES_V10513 = 28
  RESULT_STAT_RING_W_V10513 = 72
  RESULT_STAT_RING_H_V10513 = 24
  RESULT_KO_FRAMES_V10513 = 42
  RESULT_KO_TEXT_V10513 = 'KO'
end

class Game_PMDChessUnit
  alias pmd_ac_v10513_result_initialize initialize unless method_defined?(:pmd_ac_v10513_result_initialize)
  alias pmd_ac_v10513_result_start_combat start_combat unless method_defined?(:pmd_ac_v10513_result_start_combat)
  alias pmd_ac_v10513_result_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v10513_result_change_stat_stage)
  alias pmd_ac_v10513_result_start_faint start_faint unless method_defined?(:pmd_ac_v10513_result_start_faint)

  def result_feedback_reset_v10513
    @result_stat_up_start_v10513=-999999
    @result_stat_down_start_v10513=-999999
    @result_ko_latched_v10513=false
  end

  def initialize(*args)
    pmd_ac_v10513_result_initialize(*args)
    result_feedback_reset_v10513
  end

  def start_combat
    r=pmd_ac_v10513_result_start_combat
    result_feedback_reset_v10513
    r
  end

  def result_feedback_presentation_context_v10513?
    s=@scene
    return false if s==nil || !s.respond_to?(:result_feedback_presentation_context_v10513?)
    s.result_feedback_presentation_context_v10513?(self)
  rescue
    false
  end

  def result_feedback_stat_fx_trigger_v10513(direction,stat,actual)
    return false unless result_feedback_presentation_context_v10513?
    now=Graphics.frame_count.to_i
    if direction==:up
      @result_stat_up_start_v10513=now
    elsif direction==:down
      @result_stat_down_start_v10513=now
    else
      return false
    end
    s=@scene
    if s!=nil
      s.result_feedback_register_reaction_v10513(self) if s.respond_to?(:result_feedback_register_reaction_v10513)
      s.result_feedback_stat_fx_note_v10513(self,direction,stat,actual) if s.respond_to?(:result_feedback_stat_fx_note_v10513)
    end
    true
  rescue
    false
  end

  def change_stat_stage(stat,delta,source=nil)
    before=respond_to?(:stat_stage) ? stat_stage(stat).to_i : 0
    r=pmd_ac_v10513_result_change_stat_stage(stat,delta,source)
    after=respond_to?(:stat_stage) ? stat_stage(stat).to_i : before
    actual=after-before
    if actual>0
      result_feedback_stat_fx_trigger_v10513(:up,stat,actual)
    elsif actual<0
      result_feedback_stat_fx_trigger_v10513(:down,stat,actual)
    end
    r
  rescue
    pmd_ac_v10513_result_change_stat_stage(stat,delta,source)
  end

  def result_feedback_stat_fx_age_v10513(direction)
    start=(direction==:up ? @result_stat_up_start_v10513 : @result_stat_down_start_v10513).to_i
    Graphics.frame_count.to_i-start
  rescue
    999999
  end

  def result_feedback_force_ko_v10513
    return false unless result_feedback_presentation_context_v10513?
    return false if @result_ko_latched_v10513
    @result_ko_latched_v10513=true
    # 沿用 v1.05.11 dead-unit status sprite Authority；只改內容與停留時間。
    @result_feedback_ko_frames_v10511=PMD_AC::RESULT_KO_FRAMES_V10513
    @result_feedback_ko_text_v10511=PMD_AC::RESULT_KO_TEXT_V10513
    s=@scene
    s.result_feedback_ko_note_v10513(self) if s!=nil && s.respond_to?(:result_feedback_ko_note_v10513)
    true
  rescue
    false
  end

  def start_faint
    r=pmd_ac_v10513_result_start_faint
    result_feedback_force_ko_v10513
    r
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v10513_result_initialize initialize unless method_defined?(:pmd_ac_v10513_result_initialize)
  alias pmd_ac_v10513_result_update update unless method_defined?(:pmd_ac_v10513_result_update)
  alias pmd_ac_v10513_result_dispose dispose unless method_defined?(:pmd_ac_v10513_result_dispose)

  def initialize(*args)
    pmd_ac_v10513_result_initialize(*args)
    result_feedback_build_stat_fx_v10513
  end

  def result_feedback_draw_ring_bitmap_v10513(bmp,r,g,b)
    return if bmp==nil || bmp.disposed?
    bmp.clear
    w=bmp.width.to_i
    h=bmp.height.to_i
    cx=(w-1).to_f/2.0
    cy=(h-1).to_f/2.0
    rx=[cx-2.0,1.0].max
    ry=[cy-2.0,1.0].max
    for yy in 0...h
      for xx in 0...w
        dx=(xx.to_f-cx)/rx
        dy=(yy.to_f-cy)/ry
        q=dx*dx+dy*dy
        next if q>1.0 || q<0.50
        alpha=(q>0.82 ? 225 : (q>0.65 ? 150 : 70))
        bmp.set_pixel(xx,yy,Color.new(r,g,b,alpha))
      end
    end
  rescue
  end

  def result_feedback_make_ring_sprite_v10513(r,g,b)
    sp=Sprite.new(self.viewport)
    sp.bitmap=Bitmap.new(PMD_AC::RESULT_STAT_RING_W_V10513,PMD_AC::RESULT_STAT_RING_H_V10513)
    result_feedback_draw_ring_bitmap_v10513(sp.bitmap,r,g,b)
    sp.ox=sp.bitmap.width/2
    sp.oy=sp.bitmap.height/2
    sp.visible=false
    sp.opacity=0
    sp.blend_type=1
    sp
  rescue
    nil
  end

  def result_feedback_build_stat_fx_v10513
    @result_stat_up_sprite_v10513=result_feedback_make_ring_sprite_v10513(255,70,55)
    @result_stat_down_sprite_v10513=result_feedback_make_ring_sprite_v10513(60,135,255)
  rescue
  end

  def result_feedback_update_one_ring_v10513(sp,direction)
    return if sp==nil || sp.disposed? || @unit==nil
    age=@unit.respond_to?(:result_feedback_stat_fx_age_v10513) ? @unit.result_feedback_stat_fx_age_v10513(direction) : 999999
    frames=PMD_AC::RESULT_STAT_FX_FRAMES_V10513
    if age<0 || age>=frames || @unit.dead?
      sp.visible=false
      return
    end
    t=age.to_f/[frames-1,1].max.to_f
    if direction==:up
      offset=14.0-(44.0*t)
    else
      offset=-30.0+(44.0*t)
    end
    sp.x=self.x
    sp.y=self.y+offset.round
    sp.z=self.z+28
    sp.zoom_x=0.72+(0.36*t)
    sp.zoom_y=0.72+(0.36*t)
    fade=(1.0-(t-0.55).abs/0.55)
    fade=0.0 if fade<0.0
    sp.opacity=PMD_AC.clamp((90+165*fade).round,0,255)
    sp.visible=true
  rescue
    sp.visible=false if sp!=nil && !sp.disposed?
  end

  def result_feedback_update_stat_fx_v10513
    result_feedback_update_one_ring_v10513(@result_stat_up_sprite_v10513,:up)
    result_feedback_update_one_ring_v10513(@result_stat_down_sprite_v10513,:down)
  rescue
  end

  def update
    r=pmd_ac_v10513_result_update
    result_feedback_update_stat_fx_v10513
    r
  end

  def result_feedback_dispose_ring_v10513(sp)
    return if sp==nil
    begin
      bmp=sp.bitmap
      bmp.dispose if bmp!=nil && !bmp.disposed?
    rescue
    end
    begin
      sp.dispose unless sp.disposed?
    rescue
    end
  end

  def dispose
    result_feedback_dispose_ring_v10513(@result_stat_up_sprite_v10513)
    result_feedback_dispose_ring_v10513(@result_stat_down_sprite_v10513)
    @result_stat_up_sprite_v10513=nil
    @result_stat_down_sprite_v10513=nil
    pmd_ac_v10513_result_dispose
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10513_result_start_battle start_battle unless method_defined?(:pmd_ac_v10513_result_start_battle)
  alias pmd_ac_v10513_result_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10513_result_update_battle_step)
  alias pmd_ac_v10513_result_focus_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v10513_result_focus_complete)
  alias pmd_ac_v10513_result_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10513_result_focus_summary)

  def result_feedback_presentation_context_v10513?(unit=nil)
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    true
  rescue
    false
  end

  def result_feedback_reset_v10513
    @result_hold_active_v10513=false
    @result_hold_start_frame_v10513=-1
    @result_hold_count_v10513=0
    @result_hold_total_frames_v10513=0
    @result_stat_up_count_v10513=0
    @result_stat_down_count_v10513=0
    @result_ko_count_v10513=0
    @result_feedback_summary_logged_v10513=false
  end

  def result_feedback_register_reaction_v10513(unit)
    return false if unit==nil
    if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
      @focus_cast_reaction_units_v1058=[] if @focus_cast_reaction_units_v1058==nil
      @focus_cast_reaction_units_v1058.push(unit) unless @focus_cast_reaction_units_v1058.include?(unit)
    end
    true
  rescue
    false
  end

  def result_feedback_stat_fx_note_v10513(unit,direction,stat,actual)
    if direction==:up
      @result_stat_up_count_v10513=@result_stat_up_count_v10513.to_i+1
    else
      @result_stat_down_count_v10513=@result_stat_down_count_v10513.to_i+1
    end
    log_event(:battle,'BATTLE_STAT_STAGE_FX_V10513 target='+(unit==nil ? 'NONE' : unit.log_name.to_s)+
      ' dir='+direction.to_s+' stat='+stat.to_s+' delta='+actual.to_i.to_s)
    true
  rescue
    false
  end

  def result_feedback_ko_note_v10513(unit)
    @result_ko_count_v10513=@result_ko_count_v10513.to_i+1
    focus=(respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?)
    log_event(:battle,'BATTLE_KO_FEEDBACK_V10513 target='+(unit==nil ? 'NONE' : unit.log_name.to_s)+
      ' focus='+(focus ? '1' : '0')+' text='+PMD_AC::RESULT_KO_TEXT_V10513)
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10513_result_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      result_feedback_reset_v10513
      log_event(:battle,'BATTLE_RESULT_IMPACT_HOLD_STAT_FX_V10513 START'+
        ' result_hold_frames='+PMD_AC::RESULT_IMPACT_HOLD_FRAMES_V10513.to_s+
        ' stat_fx_frames='+PMD_AC::RESULT_STAT_FX_FRAMES_V10513.to_s+
        ' stat_up=red_ring_rise stat_down=blue_ring_fall ko_text=KO ko_scope=normal_battle'+
        ' result_hold_scope=skill_visual_complete world_frozen_during_hold=1 owner_clock_frozen_during_hold=1'+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_choice_unchanged=1 energy_amount_unchanged=1'+
        ' attack_wait_value_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
    end
    r
  end

  def result_feedback_hold_active_v10513?
    @result_hold_active_v10513 ? true : false
  end

  # Result Hold 期間 owner action clock 也不再推進；reaction sprites 仍由既有 Focus
  # update_unit_sprites 更新，因此 Result text / KO / stat ring 可以正常被看見。
  def update_battle_step
    if result_feedback_hold_active_v10513? && respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
      return nil
    end
    pmd_ac_v10513_result_update_battle_step
  end

  def result_feedback_begin_hold_v10513
    @result_hold_active_v10513=true
    @result_hold_start_frame_v10513=Graphics.frame_count.to_i
    @result_hold_count_v10513=@result_hold_count_v10513.to_i+1
    result_feedback_compound_update_v10512(true) if respond_to?(:result_feedback_compound_update_v10512)
    log_event(:battle,'BATTLE_RESULT_HOLD_V10513 START frames='+PMD_AC::RESULT_IMPACT_HOLD_FRAMES_V10513.to_s+
      ' owner='+( @focus_cast_owner_v1055==nil ? 'NONE' : @focus_cast_owner_v1055.log_name.to_s))
    true
  rescue
    false
  end

  def focus_cast_complete_lock_v1055(reason)
    unless reason==:skill_visual_complete
      @result_hold_active_v10513=false
      @result_hold_start_frame_v10513=-1
      return pmd_ac_v10513_result_focus_complete(reason)
    end

    unless @result_hold_active_v10513
      result_feedback_begin_hold_v10513
      return false
    end

    age=Graphics.frame_count.to_i-@result_hold_start_frame_v10513.to_i
    if age<PMD_AC::RESULT_IMPACT_HOLD_FRAMES_V10513
      return false
    end

    @result_hold_total_frames_v10513=@result_hold_total_frames_v10513.to_i+age
    log_event(:battle,'BATTLE_RESULT_HOLD_V10513 COMPLETE held_frames='+age.to_s+
      ' owner='+( @focus_cast_owner_v1055==nil ? 'NONE' : @focus_cast_owner_v1055.log_name.to_s))
    @result_hold_active_v10513=false
    @result_hold_start_frame_v10513=-1
    pmd_ac_v10513_result_focus_complete(reason)
  rescue
    @result_hold_active_v10513=false
    pmd_ac_v10513_result_focus_complete(reason)
  end

  def result_feedback_log_summary_v10513
    return false if @result_feedback_summary_logged_v10513
    @result_feedback_summary_logged_v10513=true
    log_event(:battle,'BATTLE_RESULT_IMPACT_HOLD_STAT_FX_SUMMARY_V10513'+
      ' holds='+@result_hold_count_v10513.to_i.to_s+
      ' hold_frames='+@result_hold_total_frames_v10513.to_i.to_s+
      ' stat_up='+@result_stat_up_count_v10513.to_i.to_s+
      ' stat_down='+@result_stat_down_count_v10513.to_i.to_s+
      ' ko='+@result_ko_count_v10513.to_i.to_s+
      ' red_ring_rise=1 blue_ring_fall=1 ko_scope=normal_battle')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10513_result_focus_summary
    result_feedback_log_summary_v10513
    r
  rescue
    false
  end
end
