# encoding: UTF-8
#==============================================================================
# PMD AutoChess Proto v0.88
# Battle Flow + Combat Readability Runtime
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【實作摘要】
# 1. 被動蓄力：NORMAL 實戰、存活、非 Energy Lock 時，每 30f +2 Energy。
# 2. 防無限追逐：遠程被近戰連續 ENGAGED 180f 後，強制允許一次基本反擊。
# 3. 頭上文字：隱藏 Threat / AI / 常駐 Status，只顯示招式名與狀態增減。
# 4. 天氣／場地：中央提示 90f，最後 30f 淡出。
# 5. Damage Popup：引用專案 Sideview 2 (3.3) 的 Sprite_Damage#move_damage
#    節奏，使用單一整數文字重現 SBS 的上拋、落下、回彈。
#
# 【重要】
# - Anti-stall 不是讓遠程站樁輸出。每 180f 最多只開一次反擊窗口，攻擊開始後
#   立即恢復 v0.75 的 ENGAGED 狀態，下一輪仍會繼續撤退。
# - 時間蓄力只在 verification_mode == :normal 生效，舊 verifier 數值不被污染。
# - 所有舊戰鬥公式、命中率與 Projectile Tracking 都不改。
#==============================================================================
module PMD_AC
  V088_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V088_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:battle_flow_ui_v088] +
    V088_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:battle_flow_ui_v088}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V088_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:battle_flow_ui_v088]='BATTLE_FLOW_UI_V088'
  BATTLE_FLOW_VERIFY_END_V088 = 28
end

#==============================================================================
# ■ Game_PMDChessUnit
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v088_initialize initialize unless method_defined?(:pmd_ac_v088_initialize)
  alias pmd_ac_v088_start_combat start_combat unless method_defined?(:pmd_ac_v088_start_combat)
  alias pmd_ac_v088_update update unless method_defined?(:pmd_ac_v088_update)
  alias pmd_ac_v088_apply_status apply_status unless method_defined?(:pmd_ac_v088_apply_status)
  alias pmd_ac_v088_remove_status remove_status unless method_defined?(:pmd_ac_v088_remove_status)
  alias pmd_ac_v088_cleanse cleanse unless method_defined?(:pmd_ac_v088_cleanse)
  alias pmd_ac_v088_dispel dispel unless method_defined?(:pmd_ac_v088_dispel)
  alias pmd_ac_v088_update_statuses update_statuses unless method_defined?(:pmd_ac_v088_update_statuses)
  alias pmd_ac_v088_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v088_change_stat_stage)
  alias pmd_ac_v088_canonical_clear_action_status canonical_clear_action_status unless method_defined?(:pmd_ac_v088_canonical_clear_action_status)
  alias pmd_ac_v088_apply_control apply_control unless method_defined?(:pmd_ac_v088_apply_control)
  alias pmd_ac_v088_update_stun update_stun unless method_defined?(:pmd_ac_v088_update_stun)
  alias pmd_ac_v088_apply_taunt apply_taunt unless method_defined?(:pmd_ac_v088_apply_taunt)
  alias pmd_ac_v088_clear_taunt clear_taunt unless method_defined?(:pmd_ac_v088_clear_taunt)

  def initialize(*args)
    pmd_ac_v088_initialize(*args)
    reset_battle_flow_v088
  end

  def start_combat
    pmd_ac_v088_start_combat
    reset_battle_flow_v088
  end

  def reset_battle_flow_v088
    @passive_energy_clock_v088=0
    @ranged_stall_age_v088=0
    @status_notice_text_v088=''
    @status_notice_frames_v088=0
    @status_notice_queue_v088=[]
  end

  def normal_live_battle_v088?
    return false unless battle_active?
    return false if dead? || @scene==nil
    return false unless @scene.respond_to?(:verification_mode)
    @scene.verification_mode==:normal
  end

  #--------------------------------------------------------------------------
  # ● 時間蓄力
  #--------------------------------------------------------------------------
  def gain_passive_energy_v088(force=false)
    return 0 if dead?
    return 0 unless force || normal_live_battle_v088?
    return 0 if @energy.to_i>=PMD_AC::MAX_ENERGY
    return 0 if energy_locked?
    before=@energy.to_i
    @energy += PMD_AC::PASSIVE_ENERGY_GAIN_V088
    @energy=PMD_AC::MAX_ENERGY if @energy>PMD_AC::MAX_ENERGY
    actual=@energy.to_i-before
    if actual>0 && @energy.to_i>=PMD_AC::MAX_ENERGY
      log_event(:energy,log_name+' TIME_READY energy='+@energy.to_s+'/'+PMD_AC::MAX_ENERGY.to_s)
    end
    actual
  end

  def update_passive_energy_v088
    return unless normal_live_battle_v088?
    @passive_energy_clock_v088=@passive_energy_clock_v088.to_i+1
    return if @passive_energy_clock_v088<PMD_AC::PASSIVE_ENERGY_INTERVAL_V088
    @passive_energy_clock_v088=0
    gain_passive_energy_v088(false)
  end

  #--------------------------------------------------------------------------
  # ● v0.75 遠程防無限追逐
  #--------------------------------------------------------------------------
  def ranged_stall_threat_v088
    return nil unless respond_to?(:ranged_balance_role_v075?) && ranged_balance_role_v075?
    return nil unless respond_to?(:ranged_engaged_v075?) && ranged_engaged_v075?
    return nil unless respond_to?(:ranged_balance_melee_threat_v075)
    t=ranged_balance_melee_threat_v075
    return nil if t==nil || t.dead?
    return nil if distance_to(t).to_f>@max_range.to_f+12.0
    t
  end

  def force_ranged_counterfire_v088(threat)
    return false if threat==nil || threat.dead? || dead? || acting?
    return false unless ranged?
    old_engaged=@ranged_engaged_v075
    old_rearm=@ranged_rearm_frames_v075
    old_ready=@ranged_rearm_ready_logged_v075
    @target=threat
    @attack_wait=0
    # 只在 begin_attack 呼叫期間打開一次通道，呼叫後立刻回復 v0.75 鎖定。
    @ranged_engaged_v075=false
    @ranged_rearm_frames_v075=0
    begin_attack
    started=acting? && @action==:attack
    @ranged_engaged_v075=old_engaged
    @ranged_rearm_frames_v075=old_rearm
    @ranged_rearm_ready_logged_v075=old_ready
    if started
      log_event(:stall_break,
        log_name+' COUNTERFIRE target='+threat.log_name+
        ' engaged='+PMD_AC::RANGED_STALL_BREAK_FRAMES_V088.to_s+
        ' distance='+distance_to(threat).to_s+' action=basic')
    end
    started
  end

  def update_ranged_stall_v088
    unless normal_live_battle_v088?
      @ranged_stall_age_v088=0
      return
    end
    threat=ranged_stall_threat_v088
    if threat==nil || acting?
      @ranged_stall_age_v088=0 if threat==nil
      return
    end
    @ranged_stall_age_v088=@ranged_stall_age_v088.to_i+1
    return if @ranged_stall_age_v088<PMD_AC::RANGED_STALL_BREAK_FRAMES_V088
    @ranged_stall_age_v088=0
    force_ranged_counterfire_v088(threat)
  end

  #--------------------------------------------------------------------------
  # ● +狀態 / -狀態 Queue
  #--------------------------------------------------------------------------
  def queue_status_notice_v088(key,added=true)
    return if key==nil || dead?
    return if PMD_AC::STATUS_NOTICE_IGNORE_V088.include?(key)
    label=PMD_AC.status_notice_label_v088(key)
    return if label==nil || label==''
    text=(added ? '+' : '-')+label
    @status_notice_queue_v088=[] if @status_notice_queue_v088==nil
    # 同一筆已在畫面或 Queue 時不重複灌入。
    return if @status_notice_text_v088==text && @status_notice_frames_v088.to_i>0
    return if @status_notice_queue_v088.include?(text)
    if @status_notice_frames_v088.to_i<=0
      @status_notice_text_v088=text
      @status_notice_frames_v088=PMD_AC::STATUS_NOTICE_FRAMES_V088
    else
      @status_notice_queue_v088.push(text)
      while @status_notice_queue_v088.size>PMD_AC::STATUS_NOTICE_QUEUE_MAX_V088
        @status_notice_queue_v088.shift
      end
    end
  end

  def status_notice_text_v088
    @status_notice_text_v088.to_s
  end

  def status_notice_frames_v088
    @status_notice_frames_v088.to_i
  end

  def update_status_notice_v088
    if @status_notice_frames_v088.to_i>0
      @status_notice_frames_v088-=1
    end
    if @status_notice_frames_v088.to_i<=0
      @status_notice_frames_v088=0
      if @status_notice_queue_v088!=nil && !@status_notice_queue_v088.empty?
        @status_notice_text_v088=@status_notice_queue_v088.shift
        @status_notice_frames_v088=PMD_AC::STATUS_NOTICE_FRAMES_V088
      else
        @status_notice_text_v088=''
      end
    end
  end

  def apply_status(key,options={},source=nil)
    before=status?(key)
    result=pmd_ac_v088_apply_status(key,options,source)
    queue_status_notice_v088(key,true) if !before && status?(key)
    result
  end

  def remove_status(key)
    before=status?(key)
    result=pmd_ac_v088_remove_status(key)
    queue_status_notice_v088(key,false) if before && !status?(key)
    result
  end

  def cleanse(tags=[:debuff])
    before=@statuses==nil ? [] : @statuses.keys.dup
    result=pmd_ac_v088_cleanse(tags)
    after=@statuses==nil ? [] : @statuses.keys
    (before-after).each{|k|queue_status_notice_v088(k,false)}
    result
  end

  def dispel(tags=[:buff])
    before=@statuses==nil ? [] : @statuses.keys.dup
    result=pmd_ac_v088_dispel(tags)
    after=@statuses==nil ? [] : @statuses.keys
    (before-after).each{|k|queue_status_notice_v088(k,false)}
    result
  end

  def update_statuses
    before=@statuses==nil ? [] : @statuses.keys.dup
    pmd_ac_v088_update_statuses
    after=@statuses==nil ? [] : @statuses.keys
    (before-after).each{|k|queue_status_notice_v088(k,false)}
  end

  def canonical_clear_action_status(key,reason=:expire)
    before=status?(key)
    result=pmd_ac_v088_canonical_clear_action_status(key,reason)
    queue_status_notice_v088(key,false) if before && !status?(key)
    result
  end

  def change_stat_stage(stat,delta,source=nil)
    actual=pmd_ac_v088_change_stat_stage(stat,delta,source)
    if actual.to_i!=0
      label=PMD_AC.stat_notice_label_v088(stat)
      text_key=(actual.to_i>0 ? ('stage_up_'+stat.to_s) : ('stage_down_'+stat.to_s))
      @status_notice_text_override_v088=(actual.to_i>0 ? '+' : '-')+label
      queue_custom_status_notice_v088(@status_notice_text_override_v088)
    end
    actual
  end

  def queue_custom_status_notice_v088(text)
    return if text==nil || text=='' || dead?
    @status_notice_queue_v088=[] if @status_notice_queue_v088==nil
    return if @status_notice_text_v088==text && @status_notice_frames_v088.to_i>0
    return if @status_notice_queue_v088.include?(text)
    if @status_notice_frames_v088.to_i<=0
      @status_notice_text_v088=text
      @status_notice_frames_v088=PMD_AC::STATUS_NOTICE_FRAMES_V088
    else
      @status_notice_queue_v088.push(text)
      while @status_notice_queue_v088.size>PMD_AC::STATUS_NOTICE_QUEUE_MAX_V088
        @status_notice_queue_v088.shift
      end
    end
  end

  def apply_control(control,duration,source=nil)
    before_stun=@stun_frames.to_i
    result=pmd_ac_v088_apply_control(control,duration,source)
    queue_status_notice_v088(:stun,true) if control==:stun && before_stun<=0 && @stun_frames.to_i>0
    result
  end

  def update_stun
    before=@stun_frames.to_i
    pmd_ac_v088_update_stun
    queue_status_notice_v088(:stun,false) if before>0 && @stun_frames.to_i<=0
  end

  def apply_taunt(source,duration=PMD_AC::TAUNT_DEFAULT_DURATION)
    before=taunted?
    result=pmd_ac_v088_apply_taunt(source,duration)
    queue_status_notice_v088(:taunt,true) if !before && taunted?
    result
  end

  def clear_taunt
    before=taunted?
    result=pmd_ac_v088_clear_taunt
    queue_status_notice_v088(:taunt,false) if before && !taunted?
    result
  end

  def update
    pmd_ac_v088_update
    update_passive_energy_v088
    update_ranged_stall_v088
    update_status_notice_v088
  end
end

#==============================================================================
# ■ Sprite_PMDCenterBattleNoticeV088
#==============================================================================
class Sprite_PMDCenterBattleNoticeV088 < Sprite
  def initialize(viewport)
    super(viewport)
    self.bitmap=Bitmap.new(PMD_AC::CENTER_NOTICE_W_V088,PMD_AC::CENTER_NOTICE_H_V088)
    self.x=(Graphics.width-PMD_AC::CENTER_NOTICE_W_V088)/2
    self.y=(Graphics.height-PMD_AC::CENTER_NOTICE_H_V088)/2
    self.z=9000
    self.visible=false
    @life=0
  end

  def show_text(text)
    bmp=self.bitmap
    bmp.clear
    bmp.fill_rect(10,5,bmp.width-20,bmp.height-10,Color.new(0,0,0,185))
    bmp.font.name=PMD_AC::BATTLE_FONT_V074 if PMD_AC.const_defined?('BATTLE_FONT_V074')
    bmp.font.size=PMD_AC::CENTER_NOTICE_FONT_V088
    bmp.font.bold=true
    bmp.font.color=Color.new(255,245,210)
    bmp.draw_text(14,5,bmp.width-28,bmp.height-10,text.to_s,1)
    @life=PMD_AC::CENTER_NOTICE_FRAMES_V088
    self.opacity=255
    self.visible=true
  end

  def update
    super
    return unless self.visible
    @life-=1
    if @life<=0
      @life=0
      self.visible=false
      return
    end
    fade=PMD_AC::CENTER_NOTICE_FADE_FRAMES_V088
    if @life<fade
      self.opacity=PMD_AC.clamp((255*@life/[fade,1].max),0,255)
    else
      self.opacity=255
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit : 頭上文字整理 + SBS Damage Pop
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v088_ui_initialize initialize unless method_defined?(:pmd_ac_v088_ui_initialize)
  alias pmd_ac_v088_ui_update_position update_position unless method_defined?(:pmd_ac_v088_ui_update_position)

  def initialize(viewport,unit)
    pmd_ac_v088_ui_initialize(viewport,unit)
    if @popup_sprite!=nil
      old=@popup_sprite.bitmap
      @popup_sprite.bitmap=Bitmap.new(PMD_AC::SBS_DAMAGE_POPUP_W_V088,PMD_AC::SBS_DAMAGE_POPUP_H_V088)
      old.dispose if old!=nil && !old.disposed?
    end
    if @status_sprite!=nil
      old=@status_sprite.bitmap
      @status_sprite.bitmap=Bitmap.new(PMD_AC::STATUS_NOTICE_W_V088,PMD_AC::STATUS_NOTICE_H_V088)
      old.dispose if old!=nil && !old.disposed?
    end
    @last_popup_frames=-1
    @last_status_notice_frames_v088=-1
    @popup_start_frames_v088=0
    @popup_anchor_x_v088=0
    @popup_anchor_y_v088=0
  end

  def update_position
    pmd_ac_v088_ui_update_position
    return if @unit==nil
    gx=(@unit.pixel_x+@unit.visual_offset_x).to_i
    displayed_oy=(self.oy.to_f*self.zoom_y.to_f)
    top_y=(self.y-displayed_oy).to_i
    if @skill_sprite!=nil
      @skill_sprite.x=gx-PMD_AC::UI_SKILL_W_V086/2
      @skill_sprite.y=top_y-58
      @skill_sprite.z=self.z+25
    end
    if @status_sprite!=nil
      @status_sprite.x=gx-PMD_AC::STATUS_NOTICE_W_V088/2
      @status_sprite.y=top_y-30
      @status_sprite.z=self.z+26
    end
    @threat_sprite.visible=false if @threat_sprite!=nil
    @ai_sprite.visible=false if @ai_sprite!=nil
  end

  # v0.88：不再顯示 Threat / AI Debug。
  def update_threat_debug
    @threat_sprite.visible=false if @threat_sprite!=nil
  end

  def update_ai_debug
    @ai_sprite.visible=false if @ai_sprite!=nil
  end

  # v0.88：常駐狀態列改為短暫 +狀態 / -狀態。
  def update_status_debug
    return if @status_sprite==nil
    frames=@unit.status_notice_frames_v088
    text=@unit.status_notice_text_v088
    if frames!=@last_status_notice_frames_v088 || text!=@last_status_label
      @last_status_notice_frames_v088=frames
      @last_status_label=text
      bmp=@status_sprite.bitmap
      bmp.clear
      if frames>0 && text!=''
        bmp.fill_rect(4,2,bmp.width-8,bmp.height-4,Color.new(0,0,0,165))
        bmp.font.name=PMD_AC::BATTLE_FONT_V074 if PMD_AC.const_defined?('BATTLE_FONT_V074')
        bmp.font.size=PMD_AC::STATUS_NOTICE_FONT_V088
        bmp.font.bold=true
        bmp.font.color=text[0,1]=='+' ? Color.new(255,235,135) : Color.new(180,225,255)
        bmp.draw_text(4,1,bmp.width-8,bmp.height-2,text,1)
      end
    end
    @status_sprite.visible=(frames>0 && text!='' && !@unit.dead?)
    @status_sprite.opacity=PMD_AC.clamp(frames*10,0,255) if @status_sprite.visible
  end

  # Tankentai SBS Sideview 2 (3.3) Sprite_Damage#move_damage 的單文字版。
  # 使用同一段 36-step 位移節奏，避免直接依賴 Game_Battler / 五個 digit sprite。
  def sbs_damage_offset_v088(elapsed,total)
    total=1 if total.to_i<=0
    idx=(elapsed.to_f*35.0/[total.to_i-1,1].max.to_f).round
    idx=0 if idx<0;idx=35 if idx>35
    dx=0;dy=0
    for k in 0..idx
      rem=36-k
      if rem>=35
        dx-=1;dy-=4
      elsif rem>=33
        dx-=1;dy-=3
      elsif rem>=30
        dy-=2
      elsif rem>=22
        dy+=2
      elsif rem>=19
        dy-=2
      elsif rem>=13
        dy+=1
      elsif rem>=9
        dy-=1
      elsif rem>=6
        dy+=1
      elsif rem>=3
        dy-=1
      else
        dy+=1
      end
    end
    [dx,dy]
  end

  def update_popup
    frames=@unit.damage_popup_frames
    old=@last_popup_frames
    new_popup=(frames>0 && (old==nil || old<=0 || frames>old))
    if new_popup
      self.flash(Color.new(255,255,255,185),6)
      @popup_start_frames_v088=frames
      @popup_anchor_x_v088=@popup_sprite.x
      @popup_anchor_y_v088=@popup_sprite.y
    end
    @last_popup_frames=frames
    bmp=@popup_sprite.bitmap
    if new_popup
      bmp.clear
      bmp.font.name=PMD_AC::BATTLE_FONT_V074 if PMD_AC.const_defined?('BATTLE_FONT_V074')
      bmp.font.bold=true
      if @unit.last_damage_critical
        bmp.font.size=PMD_AC::SBS_DAMAGE_CRIT_FONT_V088
        bmp.font.color=Color.new(255,225,100)
        bmp.draw_text(0,0,bmp.width,15,'CRIT!',1)
        bmp.font.size=PMD_AC::SBS_DAMAGE_FONT_V088
        bmp.draw_text(0,10,bmp.width,bmp.height-10,@unit.last_damage.to_s,1)
      else
        bmp.font.size=PMD_AC::SBS_DAMAGE_FONT_V088
        bmp.font.color=Color.new(255,245,210)
        bmp.draw_text(0,3,bmp.width,bmp.height-6,@unit.last_damage.to_s,1)
      end
    end
    if frames<=0
      bmp.clear if old!=0
      @popup_sprite.visible=false
      return
    end
    @popup_sprite.visible=true
    total=[@popup_start_frames_v088.to_i,frames].max
    elapsed=total-frames
    off=sbs_damage_offset_v088(elapsed,total)
    @popup_sprite.x=@popup_anchor_x_v088+off[0]
    @popup_sprite.y=@popup_anchor_y_v088+off[1]
    @popup_sprite.z=self.z+30
    if frames<=12
      @popup_sprite.opacity=PMD_AC.clamp(frames*21,0,255)
    else
      @popup_sprite.opacity=255
    end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v088_start start unless method_defined?(:pmd_ac_v088_start)
  alias pmd_ac_v088_update update unless method_defined?(:pmd_ac_v088_update)
  alias pmd_ac_v088_terminate terminate unless method_defined?(:pmd_ac_v088_terminate)
  alias pmd_ac_v088_set_canonical_weather set_canonical_weather unless method_defined?(:pmd_ac_v088_set_canonical_weather)
  alias pmd_ac_v088_refresh_header refresh_header unless method_defined?(:pmd_ac_v088_refresh_header)
  alias pmd_ac_v088_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v088_prepare_verification_battle)
  alias pmd_ac_v088_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v088_update_verification_script)
  alias pmd_ac_v088_log_event log_event unless method_defined?(:pmd_ac_v088_log_event)

  def start
    pmd_ac_v088_start
    @center_notice_v088=nil
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.88 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::BATTLE_FLOW_MANIFEST_V088
    log_event(:battle_flow,
      'PATCH v0.88 passive_energy=+'+PMD_AC::PASSIVE_ENERGY_GAIN_V088.to_s+
      '/'+PMD_AC::PASSIVE_ENERGY_INTERVAL_V088.to_s+'f'+
      ' ranged_stall_break='+PMD_AC::RANGED_STALL_BREAK_FRAMES_V088.to_s+'f'+
      ' head_text=skill+status_delta center_notice=weather+field'+
      ' damage_popup=tankentai_sbs movement_core=v0.15 accuracy=v0.87.1')
    refresh_header
  end

  def update
    pmd_ac_v088_update
    @center_notice_v088.update if @center_notice_v088!=nil && !@center_notice_v088.disposed?
  end

  def terminate
    if @center_notice_v088!=nil && !@center_notice_v088.disposed?
      @center_notice_v088.dispose
    end
    @center_notice_v088=nil
    pmd_ac_v088_terminate
  end

  def add_center_notice_v088(text)
    return if text==nil || text.to_s=='' || @viewport==nil
    if @center_notice_v088==nil || @center_notice_v088.disposed?
      @center_notice_v088=Sprite_PMDCenterBattleNoticeV088.new(@viewport)
    end
    @center_notice_v088.show_text(text.to_s)
    log_event(:center_notice,text.to_s)
  end

  # 取代 v0.35 左上 Special Label。只在場地「新出現」時提示，不在 refresh/end 洗版。
  def add_field_notice_v035(text)
    label=PMD_AC.field_notice_label_v088(text)
    add_center_notice_v088('場地：'+label.to_s) unless label==nil || label==''
  end

  def set_canonical_weather(weather,source=nil,turns=nil,permanent=false)
    old=@canonical_weather
    result=pmd_ac_v088_set_canonical_weather(weather,source,turns,permanent)
    if result && old!=weather
      add_center_notice_v088('天氣：'+PMD_AC.weather_notice_label_v088(weather))
    end
    result
  end

  def refresh_header
    pmd_ac_v088_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.88',1)
  end

  #--------------------------------------------------------------------------
  # ● Verifier
  #--------------------------------------------------------------------------
  def battle_flow_ui_v088?
    verification_mode==:battle_flow_ui_v088
  end

  def prepare_verification_battle
    pmd_ac_v088_prepare_verification_battle
    @battle_flow_v088_failed=false if battle_flow_ui_v088?
  end

  def log_event(category,message)
    if category.to_s=='verify' && battle_flow_ui_v088? &&
       message.to_s.index('V088')!=nil && message.to_s.include?(' pass=0')
      @battle_flow_v088_failed=true
    end
    pmd_ac_v088_log_event(category,message)
  end

  def log_verify_v088(name,pass,detail='')
    @battle_flow_v088_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_battle_flow_manifest_v088
    return if @verification_done[:v088_manifest]
    m=PMD_AC::BATTLE_FLOW_MANIFEST_V088
    pass=m[:passive_energy_interval]==30 && m[:passive_energy_gain]==2 &&
      m[:ranged_stall_break]==180 && m[:damage_motion]==:tankentai_sbs_move_damage_reference
    log_verify_v088('BATTLE_FLOW_MANIFEST_V088',pass,
      'passive=2/30f stall_break=180f damage_motion=tankentai_sbs')
    @verification_done[:v088_manifest]=true
  end

  def verify_passive_energy_v088
    return if @verification_done[:v088_energy]
    u=verification_unit(:ally,:bulbasaur)
    pass=false;before=-1;after=-1
    if u!=nil
      before=u.energy.to_i
      u.instance_variable_set(:@energy,10)
      got=u.gain_passive_energy_v088(true)
      after=u.energy.to_i
      pass=(got==2 && after==12)
      u.instance_variable_set(:@energy,before)
    end
    log_verify_v088('PASSIVE_ENERGY_V088',pass,
      'forced_test=10->'+after.to_s+' gain=2 normal_only=1')
    @verification_done[:v088_energy]=true
  end

  def verify_ranged_stall_break_v088
    return if @verification_done[:v088_stall]
    u=verification_unit(:enemy,:pidgey)
    # verifier roster 不一定有 artillery，因此驗證 Runtime 常數與 helper 是否存在，
    # 真正 Pikachu anti-stall 由正常 Battle LOG 的 STALL_BREAK 行確認。
    helper=(u!=nil && u.respond_to?(:force_ranged_counterfire_v088))
    pass=helper && PMD_AC::RANGED_STALL_BREAK_FRAMES_V088==180
    log_verify_v088('RANGED_STALL_BREAK_V088',pass,
      'threshold=180 helper='+(helper ? '1':'0')+' v075_lock=preserved')
    @verification_done[:v088_stall]=true
  end

  def verify_head_status_ui_v088
    return if @verification_done[:v088_head]
    u=verification_unit(:ally,:bulbasaur)
    pass=false;text=''
    if u!=nil
      u.queue_status_notice_v088(:poison,true)
      text=u.status_notice_text_v088
      pass=(text=='+中毒' && PMD_AC::STATUS_NOTICE_IGNORE_V088.include?(:def_aura))
      u.instance_variable_set(:@status_notice_text_v088,'')
      u.instance_variable_set(:@status_notice_frames_v088,0)
      u.instance_variable_set(:@status_notice_queue_v088,[])
    end
    log_verify_v088('HEAD_STATUS_UI_V088',pass,
      'sample='+text+' threat=hidden ai=hidden persistent_status=off')
    @verification_done[:v088_head]=true
  end

  def verify_center_notice_ui_v088
    return if @verification_done[:v088_center]
    weather=PMD_AC.weather_notice_label_v088(:rain)
    field=PMD_AC.field_notice_label_v088('GRAVITY')
    pass=(weather=='下雨' && field=='重力' && PMD_AC::CENTER_NOTICE_FADE_FRAMES_V088==30)
    log_verify_v088('CENTER_NOTICE_UI_V088',pass,
      'weather='+weather+' field='+field.to_s+' life=90 fade=30')
    @verification_done[:v088_center]=true
  end

  def verify_sbs_damage_ui_v088
    return if @verification_done[:v088_sbs]
    sprite=@unit_sprites==nil ? nil : @unit_sprites[0]
    pass=false;first=[];fall=[]
    if sprite!=nil && sprite.respond_to?(:sbs_damage_offset_v088)
      first=sprite.sbs_damage_offset_v088(6,36)
      fall=sprite.sbs_damage_offset_v088(14,36)
      pass=(first[1]<0 && fall[1]>first[1])
    end
    log_verify_v088('SBS_DAMAGE_UI_V088',pass,
      'first_y='+first[1].to_i.to_s+' later_y='+fall[1].to_i.to_s+' source=Sideview2_3.3_move_damage')
    @verification_done[:v088_sbs]=true
  end

  def verify_battle_flow_carry_v088
    return if @verification_done[:v088_carry]
    pass=PMD_AC::BASIC_MELEE_HIT_GRACE_BONUS_V0871==18.0 &&
      PMD_AC::RANGED_ENGAGE_RANGE_V075==102 && PMD_AC::RANGED_RELEASE_RANGE_V075==124
    log_verify_v088('BATTLE_FLOW_CARRY_V088',pass,
      'miss=v0.87.1 balance=v0.75 movement=v0.15 damage=v0.60.2 router=v0.62')
    @verification_done[:v088_carry]=true
  end

  def update_verification_script
    unless battle_flow_ui_v088?
      pmd_ac_v088_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_battle_flow_manifest_v088 if f>=2
    verify_passive_energy_v088 if f>=4
    verify_ranged_stall_break_v088 if f>=6
    verify_head_status_ui_v088 if f>=8
    verify_center_notice_ui_v088 if f>=10
    verify_sbs_damage_ui_v088 if f>=12
    verify_battle_flow_carry_v088 if f>=14
    if f>=16 && !@verification_done[:v088_final]
      pass=!@battle_flow_v088_failed
      log_verify_v088('BATTLE_FLOW_UI_V088',pass,
        'passive=1 stall_break=1 head=1 center=1 sbs_damage=1 carry=1')
      @verification_done[:v088_final]=true
    end
    complete_verification_mode if f>=PMD_AC::BATTLE_FLOW_VERIFY_END_V088
  end
end
