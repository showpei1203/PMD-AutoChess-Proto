# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Result Feedback Semantics I v1.05.11
#===============================================================================
# 【用途】
# 1. 延續 v1.05.8 Focus Cast Action Lane，讓玩家在技能命中／生效後，不只看得懂
#    「誰用了什麼招、打到誰」，也能在受影響的 Pokémon 附近快速看懂主要結果。
# 2. 優先重用既有 v0.88 target-local UI，不建立上方事件 Feed、不畫 source-target
#    長連線，也不新增第二條大型文字軌道。
# 3. 傷害、能力階級、異常／控制等已經有成熟提示時，本版不重複顯示；只補上
#    現有語言缺口：治療、護盾／格擋、強制位移、KO。
#
# 【結果語言 Authority】
# - Damage：沿用既有 SBS-style Damage Popup 數字；不再額外顯示「傷害」二字。
# - Heal：實際 HP 有增加時，目標頭頂短暫顯示「+HP N」。
# - Buff / Debuff：沿用 v0.88 change_stat_stage 的「+攻擊 / -防禦 ...」。
# - Status / Control：沿用 v0.88「+中毒 / +睡眠 / +暈眩 ...」。
# - Shield setup：既有 add_skill_effect(:shield/:guard) 生效時顯示「+護盾」。
# - Shield absorb / Guard block：本次 Focus 中盾值被消耗時顯示「防禦」。
# - Displacement：真正建立 knockback / pull movement 時顯示「擊退 / 拉近」。
# - KO：Focus 技能造成單位進入 faint 時顯示「倒下」。使用中性文字，避免把
#   Healing Wish、recoil 等自我倒下錯誤描述成「被擊倒」。
#
# 【主要設定】
# RESULT_FEEDBACK_DEDUP_FRAMES_V10511 = 12
#   同一目標、同一語義在 12f 內只送一次，避免 multi-hit / guard 重複洗字。
# RESULT_FEEDBACK_KO_FRAMES_V10511 = 32
#   「倒下」在 faint sprite 上保留的最長時間；只改 Presentation。
# RESULT_FEEDBACK_SCOPE_V10511 = :focus_action_lane
#   本版新增 Heal / Shield / Displacement / KO 文字只在 NORMAL 的 Focus Action Lane
#   內生效，避免被動回血、場地 tick、一般移動把畫面塞滿。既有 Damage / Status
#   UI 仍照原規則運作。
#
# 【機制規則】
# - 不更改 Damage Formula、HP 結果、AI、Energy、Attack Wait、命中、Priority、
#   logical Spatial x/y/velocity、knockback 距離、Action Lane timing。
# - heal / receive_damage / apply_knockback / apply_pull / start_faint 都使用 trailing alias
#   只觀察呼叫前後結果，再送出 UI 語義；原方法回傳值原樣傳回。
# - Suction Cups 等若真正擋住 knockback / pull，前後 movement state 不變，因此不會
#   假顯示「擊退 / 拉近」。
# - KO 因 v0.88 status notice 對 dead unit 會自動隱藏，所以只對「倒下」做一個很小的
#   trailing Sprite override，沿用同一個 @status_sprite bitmap / 位置 / 字體，不新增 Sprite。
# - v1.05.10 shadow target mark 的 Geometry / timing 完全不動；跨背景 Alpha 仍保留為
#   未來 Background Contrast Tunable。
#
# 【可調參數】
# - RESULT_FEEDBACK_DEDUP_FRAMES_V10511：同類提示去重時間。
# - RESULT_FEEDBACK_KO_FRAMES_V10511：KO 提示時間。
# - RESULT_FEEDBACK_KO_TEXT_V10511：KO 中性文字。
# - RESULT_FEEDBACK_SCOPE_V10511：目前固定 Focus Action Lane，不建議在本版擴成全場。
#
# 【事件／腳本呼叫】
# 無需事件呼叫。NORMAL battle 自動生效。
# 主要 LOG：
#   BATTLE_RESULT_FEEDBACK_SEMANTICS_I_V10511 START ...
#   BATTLE_RESULT_FEEDBACK_V10511 target=... kind=... text=...
#   BATTLE_RESULT_FEEDBACK_SEMANTICS_I_SUMMARY_V10511 ...
#
# 【實際範例】
# 1. 傑尼龜 Focus「水槍」命中波波：仍只顯示既有傷害數字，不多疊「傷害」。
# 2. 吸取類技能回復 42 HP：施放者附近顯示「+HP 42」。
# 3. Growl 降攻擊：沿用既有「-攻擊」，本版不再疊「Debuff」。
# 4. Protect 建立防禦：顯示「+護盾」；後續技能被盾吸收時顯示「防禦」。
# 5. Roar / Whirlwind 真正建立 knockback：目標附近顯示「擊退」。
# 6. Focus 技能讓目標 HP 歸零：faint 開始時顯示「倒下」，不阻擋原 faint 動畫。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ResultFeedbackSemanticsI_v10511']=true

module PMD_AC
  RESULT_FEEDBACK_DEDUP_FRAMES_V10511 = 12
  RESULT_FEEDBACK_KO_FRAMES_V10511 = 32
  RESULT_FEEDBACK_KO_TEXT_V10511 = '倒下'
  RESULT_FEEDBACK_SCOPE_V10511 = :focus_action_lane
end

class Game_PMDChessUnit
  alias pmd_ac_v10511_result_initialize initialize unless method_defined?(:pmd_ac_v10511_result_initialize)
  alias pmd_ac_v10511_result_start_combat start_combat unless method_defined?(:pmd_ac_v10511_result_start_combat)
  alias pmd_ac_v10511_result_heal heal unless method_defined?(:pmd_ac_v10511_result_heal)
  alias pmd_ac_v10511_result_add_shield add_shield unless method_defined?(:pmd_ac_v10511_result_add_shield)
  alias pmd_ac_v10511_result_receive_damage receive_damage unless method_defined?(:pmd_ac_v10511_result_receive_damage)
  alias pmd_ac_v10511_result_apply_knockback apply_knockback unless method_defined?(:pmd_ac_v10511_result_apply_knockback)
  alias pmd_ac_v10511_result_apply_pull apply_pull unless method_defined?(:pmd_ac_v10511_result_apply_pull)
  alias pmd_ac_v10511_result_start_faint start_faint unless method_defined?(:pmd_ac_v10511_result_start_faint)

  def result_feedback_reset_v10511
    @result_feedback_recent_v10511={}
    @result_feedback_ko_frames_v10511=0
    @result_feedback_ko_text_v10511=''
  end

  def initialize(*args)
    pmd_ac_v10511_result_initialize(*args)
    result_feedback_reset_v10511
  end

  def start_combat
    r=pmd_ac_v10511_result_start_combat
    result_feedback_reset_v10511
    r
  end

  def result_feedback_focus_context_v10511?
    s=@scene
    return false if s==nil
    return false unless s.respond_to?(:result_feedback_focus_context_v10511?)
    s.result_feedback_focus_context_v10511?(self)
  rescue
    false
  end

  def result_feedback_emit_v10511(kind,text)
    return false if text==nil || text.to_s==''
    return false unless result_feedback_focus_context_v10511?
    @result_feedback_recent_v10511={} if @result_feedback_recent_v10511==nil
    key=kind.to_sym
    now=Graphics.frame_count.to_i
    last=@result_feedback_recent_v10511[key]
    return false if last!=nil && now-last.to_i<PMD_AC::RESULT_FEEDBACK_DEDUP_FRAMES_V10511
    @result_feedback_recent_v10511[key]=now
    if respond_to?(:queue_custom_status_notice_v088) && !dead?
      queue_custom_status_notice_v088(text.to_s)
    end
    s=@scene
    if s!=nil && s.respond_to?(:result_feedback_note_v10511)
      s.result_feedback_note_v10511(self,key,text.to_s)
    end
    true
  rescue
    false
  end

  def heal(*args)
    before=@hp.to_i
    r=pmd_ac_v10511_result_heal(*args)
    actual=@hp.to_i-before
    result_feedback_emit_v10511(:heal,'+HP '+actual.to_s) if actual>0
    r
  end

  def add_shield(*args)
    before=@shield.to_i
    r=pmd_ac_v10511_result_add_shield(*args)
    gained=@shield.to_i-before
    result_feedback_emit_v10511(:shield,'+護盾') if gained>0
    r
  end

  def receive_damage(*args)
    before_hp=@hp.to_i
    before_shield=@shield.to_i rescue 0
    r=pmd_ac_v10511_result_receive_damage(*args)
    after_hp=@hp.to_i
    after_shield=@shield.to_i rescue 0
    if before_shield>after_shield
      result_feedback_emit_v10511(:guard,'防禦')
    end
    # Damage 本身沿用既有數字 popup；這裡只做 authority observation，不追加文字。
    if before_hp>after_hp
      s=@scene
      s.result_feedback_observe_damage_v10511(self,before_hp-after_hp) if
        s!=nil && s.respond_to?(:result_feedback_observe_damage_v10511)
    end
    r
  end

  def apply_knockback(*args)
    before_f=@knockback_frames.to_i
    before_x=@knockback_x.to_f
    before_y=@knockback_y.to_f
    r=pmd_ac_v10511_result_apply_knockback(*args)
    changed=@knockback_frames.to_i>0 &&
      (@knockback_frames.to_i!=before_f || @knockback_x.to_f!=before_x || @knockback_y.to_f!=before_y)
    result_feedback_emit_v10511(:knockback,'擊退') if changed
    r
  end

  def apply_pull(*args)
    before_f=@knockback_frames.to_i
    before_x=@knockback_x.to_f
    before_y=@knockback_y.to_f
    r=pmd_ac_v10511_result_apply_pull(*args)
    changed=@knockback_frames.to_i>0 &&
      (@knockback_frames.to_i!=before_f || @knockback_x.to_f!=before_x || @knockback_y.to_f!=before_y)
    result_feedback_emit_v10511(:pull,'拉近') if changed
    r
  end

  def start_faint
    if result_feedback_focus_context_v10511? && @result_feedback_ko_frames_v10511.to_i<=0
      @result_feedback_ko_frames_v10511=PMD_AC::RESULT_FEEDBACK_KO_FRAMES_V10511
      @result_feedback_ko_text_v10511=PMD_AC::RESULT_FEEDBACK_KO_TEXT_V10511
      s=@scene
      s.result_feedback_note_v10511(self,:ko,@result_feedback_ko_text_v10511) if
        s!=nil && s.respond_to?(:result_feedback_note_v10511)
    end
    pmd_ac_v10511_result_start_faint
  end

  def result_feedback_ko_frames_v10511
    @result_feedback_ko_frames_v10511.to_i
  end

  def result_feedback_ko_text_v10511
    @result_feedback_ko_text_v10511.to_s
  end

  def result_feedback_tick_ko_v10511
    f=@result_feedback_ko_frames_v10511.to_i
    if f>0
      f-=1
      @result_feedback_ko_frames_v10511=f
      @result_feedback_ko_text_v10511='' if f<=0
    end
    f
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v10511_result_update_status_debug update_status_debug unless method_defined?(:pmd_ac_v10511_result_update_status_debug)

  # dead unit 原本會隱藏 v0.88 status sprite；KO 是唯一例外。
  # 仍沿用同一張 bitmap / 同一位置，因此不增加 Sprite 數量與 lifecycle 負擔。
  def update_status_debug
    pmd_ac_v10511_result_update_status_debug
    return if @unit==nil || @status_sprite==nil
    frames=@unit.respond_to?(:result_feedback_ko_frames_v10511) ?
      @unit.result_feedback_ko_frames_v10511 : 0
    return if frames.to_i<=0
    bmp=@status_sprite.bitmap
    return if bmp==nil || bmp.disposed?
    text=@unit.result_feedback_ko_text_v10511
    bmp.clear
    bmp.fill_rect(4,2,bmp.width-8,bmp.height-4,Color.new(0,0,0,180))
    bmp.font.name=PMD_AC::BATTLE_FONT_V074 if PMD_AC.const_defined?('BATTLE_FONT_V074')
    bmp.font.size=PMD_AC::STATUS_NOTICE_FONT_V088
    bmp.font.bold=true
    bmp.font.color=Color.new(255,195,175)
    bmp.draw_text(4,1,bmp.width-8,bmp.height-2,text,1)
    @status_sprite.visible=true
    @status_sprite.opacity=PMD_AC.clamp(frames.to_i*12,0,255)
    @unit.result_feedback_tick_ko_v10511 if @unit.respond_to?(:result_feedback_tick_ko_v10511)
  rescue
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10511_result_start_battle start_battle unless method_defined?(:pmd_ac_v10511_result_start_battle)
  alias pmd_ac_v10511_result_add_skill_effect add_skill_effect unless method_defined?(:pmd_ac_v10511_result_add_skill_effect)
  alias pmd_ac_v10511_result_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10511_result_focus_summary)

  def result_feedback_focus_context_v10511?(unit=nil)
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    return false unless respond_to?(:focus_cast_action_lane_active_v1058?)
    focus_cast_action_lane_active_v1058?
  rescue
    false
  end

  def result_feedback_reset_v10511
    @result_feedback_counts_v10511={
      :heal=>0,:guard=>0,:shield=>0,:knockback=>0,:pull=>0,:ko=>0,:damage_observed=>0
    }
    @result_feedback_summary_logged_v10511=false
  end

  def result_feedback_note_v10511(target,kind,text)
    @result_feedback_counts_v10511={} if @result_feedback_counts_v10511==nil
    @result_feedback_counts_v10511[kind]=@result_feedback_counts_v10511[kind].to_i+1
    log_event(:battle,'BATTLE_RESULT_FEEDBACK_V10511 target='+(target==nil ? 'NONE' : target.log_name.to_s)+
      ' kind='+kind.to_s+' text='+text.to_s)
    true
  rescue
    false
  end

  def result_feedback_observe_damage_v10511(target,amount)
    return false unless result_feedback_focus_context_v10511?(target)
    @result_feedback_counts_v10511={} if @result_feedback_counts_v10511==nil
    @result_feedback_counts_v10511[:damage_observed]=@result_feedback_counts_v10511[:damage_observed].to_i+1
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10511_result_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      result_feedback_reset_v10511
      log_event(:battle,'BATTLE_RESULT_FEEDBACK_SEMANTICS_I_V10511 START scope=focus_action_lane'+
        ' damage=existing_numeric_popup heal=+HP buff=existing_stage_notice debuff=existing_stage_notice'+
        ' status_control=existing_status_notice shield=+shield_or_guard displacement=knockback_pull ko=down'+
        ' top_feed=0 tether_line=0 new_sprite=0 target_mark_geometry_unchanged=1'+
        ' hp_unchanged=1 damage_formula_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 action_timing_unchanged=1')
    end
    r
  end

  def add_skill_effect(target,type,delay=0)
    r=pmd_ac_v10511_result_add_skill_effect(target,type,delay)
    if target!=nil && result_feedback_focus_context_v10511?(target) &&
       (type==:shield || type==:guard) && target.respond_to?(:result_feedback_emit_v10511)
      owner=@focus_cast_owner_v1055
      if target==owner
        target.result_feedback_emit_v10511(:shield,'+護盾')
      else
        target.result_feedback_emit_v10511(:guard,'防禦')
      end
    end
    r
  end

  def result_feedback_log_summary_v10511
    return false if @result_feedback_summary_logged_v10511
    @result_feedback_summary_logged_v10511=true
    c=@result_feedback_counts_v10511 || {}
    log_event(:battle,'BATTLE_RESULT_FEEDBACK_SEMANTICS_I_SUMMARY_V10511'+
      ' damage_observed='+c[:damage_observed].to_i.to_s+
      ' heal='+c[:heal].to_i.to_s+' guard='+c[:guard].to_i.to_s+
      ' shield='+c[:shield].to_i.to_s+' knockback='+c[:knockback].to_i.to_s+
      ' pull='+c[:pull].to_i.to_s+' ko='+c[:ko].to_i.to_s+
      ' existing_buff_debuff_status_authority=v088 new_sprite=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10511_result_focus_summary
    result_feedback_log_summary_v10511
    r
  rescue
    false
  end
end
