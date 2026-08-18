# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Result Feedback Semantics II v1.05.12
#===============================================================================
# 【用途】
# 1. 延續 v1.05.11 Result Feedback Semantics I，處理「同一個 Focus 技能在同一目標上
#    同時產生多個結果」時的資訊擁擠問題。
# 2. 建立 target-local Compound Outcome Arbiter：在很短的 Presentation Window 內收集
#    Heal / Buff / Debuff / Status / Cleanse / Shield / Guard / Displacement 等既有提示，
#    最後只留下玩家最需要知道的主要結果；必要時最多合成兩段短詞。
# 3. 多目標技能仍由每一個受影響 battler 各自在頭頂顯示自己的主要結果，不建立
#    上方事件 Feed、不畫長連線，也不新增額外 Sprite。
#
# 【v1.05.11 Windows 實機基線】
# - 2026-08-15 NORMAL 實機兩場：Focus 8/8 + 7/7 完整 complete、timeouts=0。
# - Result Feedback 實際觀察到 knockback=6、ko=1；Damage 繼續由既有數字 Popup 負責。
# - Heal / Guard / Shield / Pull 在該固定 NORMAL 戰局未自然出現，因此本版仍保留
#   v1.05.11 的 static/mock coverage，不把「沒出現」誤判成 Runtime failure。
#
# 【主要設定】
# RESULT_FEEDBACK_COMPOUND_WINDOW_V10512 = 6
#   同一目標收到第一筆結果後等待 6f，讓同一 Hit／同一技能的複合結果有機會合併。
#   這只延後文字 Presentation，不延後 Damage、HP、Spatial 或 Action Lane 完成。
# RESULT_FEEDBACK_COMPOUND_MAX_PARTS_V10512 = 2
#   最多只顯示兩段短語，避免頭頂文字重新變成事件紀錄表。
#
# 【結果優先規則】
# - KO：最高 Authority，沿用 v1.05.11「倒下」，並清掉同一 Focus 尚未顯示的次要提示。
# - Guard：顯示「防禦」，優先於一般 Shield / displacement / stat change。
# - Status / Control：保留具體狀態，例如「+睡眠」「+暈眩」。
# - Cleanse：單一解除保留「-中毒」等；同時解除多個狀態時壓成「淨化」。
# - Shield + Cleanse：合成「+護盾・淨化」。
# - Heal + Buff：合成「+HP N・強化」。
# - 多個純 Buff：壓成「能力上升」；多個純 Debuff：壓成「能力下降」。
# - 同時有 Buff + Debuff：壓成「能力變化」。
# - Displacement：保留「擊退 / 拉近」。Damage 數字仍獨立顯示，因此
#   Damage + Displacement 會是「數字 + 擊退」，不再額外寫「傷害」。
# - 同一 Focus、同一目標若較低優先結果已顯示，後續重複／較低結果不再排 Queue；
#   若後續出現更高優先結果，可覆蓋目前文字一次，而不是新增第二、第三條 Queue。
#
# 【機制規則】
# - 僅在 NORMAL Focus Action Lane 中攔截 v0.88 status notice；Focus 外完全沿用原系統。
# - 只改 Presentation Queue，不改 HP、Damage Formula、AI、Energy、Attack Wait、
#   Priority、logical Spatial x/y/velocity、knockback/pull endpoint、Action Lane timing。
# - 不修改 Frozen Combat Core；本檔為 trailing alias/hook。
# - 不新增 Sprite，直接重用 v0.88 @status_sprite。
# - v1.05.10 shadow target mark Geometry / timing 不變；跨背景 contrast 仍是未來 QA tunable。
#
# 【可調參數】
# - RESULT_FEEDBACK_COMPOUND_WINDOW_V10512：複合結果收集視窗，預設 6f。
# - RESULT_FEEDBACK_COMPOUND_MAX_PARTS_V10512：合成文字最大段數，預設 2。
# - RESULT_FEEDBACK_PRIORITY_*_V10512：各結果的 Presentation 優先度。
#
# 【事件／腳本呼叫】
# 無需事件呼叫。NORMAL battle 的 Focus Action Lane 自動啟用。
# 主要 LOG：
#   BATTLE_RESULT_FEEDBACK_SEMANTICS_II_V10512 START ...
#   BATTLE_RESULT_FEEDBACK_COMPOUND_V10512 target=... text=... kinds=... candidates=...
#   BATTLE_RESULT_FEEDBACK_SEMANTICS_II_SUMMARY_V10512 ...
#
# 【實際範例】
# 1. Damage + Sleep：傷害數字照舊，目標只再顯示「+睡眠」。
# 2. Heal 42 + Attack Up：目標顯示「+HP 42・強化」，不排兩條長 Queue。
# 3. Shield + Cleanse poison/burn：目標顯示「+護盾・淨化」。
# 4. Shell Smash 類多能力變化：不逐條播放五個能力通知，壓成「能力變化」。
# 5. Damage + Knockback：傷害數字 +「擊退」。若同一擊同時 KO，最後只保留「倒下」。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ResultFeedbackSemanticsII_v10512']=true

module PMD_AC
  RESULT_FEEDBACK_COMPOUND_WINDOW_V10512 = 6
  RESULT_FEEDBACK_COMPOUND_MAX_PARTS_V10512 = 2

  RESULT_FEEDBACK_PRIORITY_MISC_V10512 = 35
  RESULT_FEEDBACK_PRIORITY_BUFF_V10512 = 45
  RESULT_FEEDBACK_PRIORITY_DEBUFF_V10512 = 50
  RESULT_FEEDBACK_PRIORITY_HEAL_V10512 = 60
  RESULT_FEEDBACK_PRIORITY_DISPLACEMENT_V10512 = 65
  RESULT_FEEDBACK_PRIORITY_SHIELD_V10512 = 70
  RESULT_FEEDBACK_PRIORITY_CLEANSE_V10512 = 80
  RESULT_FEEDBACK_PRIORITY_STATUS_V10512 = 90
  RESULT_FEEDBACK_PRIORITY_GUARD_V10512 = 100
  RESULT_FEEDBACK_PRIORITY_KO_V10512 = 1000
end

class Game_PMDChessUnit
  alias pmd_ac_v10512_compound_initialize initialize unless method_defined?(:pmd_ac_v10512_compound_initialize)
  alias pmd_ac_v10512_compound_start_combat start_combat unless method_defined?(:pmd_ac_v10512_compound_start_combat)
  alias pmd_ac_v10512_compound_queue_status_notice_v088 queue_status_notice_v088 unless method_defined?(:pmd_ac_v10512_compound_queue_status_notice_v088)
  alias pmd_ac_v10512_compound_queue_custom_status_notice_v088 queue_custom_status_notice_v088 unless method_defined?(:pmd_ac_v10512_compound_queue_custom_status_notice_v088)
  alias pmd_ac_v10512_compound_start_faint start_faint unless method_defined?(:pmd_ac_v10512_compound_start_faint)

  def result_feedback_compound_reset_v10512
    @result_feedback_compound_pending_v10512={}
    @result_feedback_compound_first_frame_v10512=-1
    @result_feedback_compound_token_v10512=-1
    @result_feedback_compound_shown_token_v10512=-1
    @result_feedback_compound_shown_priority_v10512=-1
    @result_feedback_compound_shown_text_v10512=''
    @result_feedback_compound_ko_token_v10512=-1
  end

  def initialize(*args)
    pmd_ac_v10512_compound_initialize(*args)
    result_feedback_compound_reset_v10512
  end

  def start_combat
    r=pmd_ac_v10512_compound_start_combat
    result_feedback_compound_reset_v10512
    r
  end

  def result_feedback_compound_scene_v10512
    s=@scene
    return nil if s==nil
    return nil unless s.respond_to?(:result_feedback_compound_context_v10512?)
    s
  rescue
    nil
  end

  def result_feedback_compound_context_v10512?
    s=result_feedback_compound_scene_v10512
    s!=nil && s.result_feedback_compound_context_v10512?(self)
  rescue
    false
  end

  def result_feedback_compound_current_token_v10512
    s=result_feedback_compound_scene_v10512
    return -1 if s==nil || !s.respond_to?(:result_feedback_compound_token_v10512)
    s.result_feedback_compound_token_v10512.to_i
  rescue
    -1
  end

  def result_feedback_compound_prepare_token_v10512
    token=result_feedback_compound_current_token_v10512
    if @result_feedback_compound_token_v10512.to_i!=token
      @result_feedback_compound_pending_v10512={}
      @result_feedback_compound_first_frame_v10512=-1
      @result_feedback_compound_token_v10512=token
      @result_feedback_compound_shown_token_v10512=token
      @result_feedback_compound_shown_priority_v10512=-1
      @result_feedback_compound_shown_text_v10512=''
      @result_feedback_compound_ko_token_v10512=-1
    end
    token
  end

  def result_feedback_compound_register_v10512(kind,text,priority)
    return false if text==nil || text.to_s==''
    return false unless result_feedback_compound_context_v10512?
    token=result_feedback_compound_prepare_token_v10512
    return false if @result_feedback_compound_ko_token_v10512.to_i==token

    shown=@result_feedback_compound_shown_priority_v10512.to_i
    if @result_feedback_compound_shown_token_v10512.to_i==token && shown>=0 && priority.to_i<=shown
      s=result_feedback_compound_scene_v10512
      s.result_feedback_compound_suppressed_v10512(self,kind,text,priority) if
        s!=nil && s.respond_to?(:result_feedback_compound_suppressed_v10512)
      return true
    end

    @result_feedback_compound_pending_v10512={} if @result_feedback_compound_pending_v10512==nil
    item=@result_feedback_compound_pending_v10512[kind]
    if item==nil
      item={:texts=>[],:count=>0,:priority=>priority.to_i}
      @result_feedback_compound_pending_v10512[kind]=item
    end
    item[:count]=item[:count].to_i+1
    item[:priority]=priority.to_i if priority.to_i>item[:priority].to_i
    item[:texts].push(text.to_s) unless item[:texts].include?(text.to_s)
    @result_feedback_compound_first_frame_v10512=Graphics.frame_count.to_i if
      @result_feedback_compound_first_frame_v10512.to_i<0
    s=result_feedback_compound_scene_v10512
    s.result_feedback_compound_candidate_v10512(self,kind,text,priority) if
      s!=nil && s.respond_to?(:result_feedback_compound_candidate_v10512)
    true
  rescue
    false
  end

  def result_feedback_stat_label_v10512?(body)
    return false if body==nil || body==''
    if PMD_AC.const_defined?('STAT_STAGE_KEYS') && PMD_AC.respond_to?(:stat_notice_label_v088)
      PMD_AC::STAT_STAGE_KEYS.each do |k|
        begin
          return true if PMD_AC.stat_notice_label_v088(k).to_s==body.to_s
        rescue
        end
      end
    end
    false
  rescue
    false
  end

  def result_feedback_classify_custom_v10512(text)
    t=text.to_s
    return [:heal,PMD_AC::RESULT_FEEDBACK_PRIORITY_HEAL_V10512] if t.index('+HP ')==0
    return [:shield,PMD_AC::RESULT_FEEDBACK_PRIORITY_SHIELD_V10512] if t=='+護盾'
    return [:guard,PMD_AC::RESULT_FEEDBACK_PRIORITY_GUARD_V10512] if t=='防禦'
    return [:displacement,PMD_AC::RESULT_FEEDBACK_PRIORITY_DISPLACEMENT_V10512] if t=='擊退' || t=='拉近'
    if t.size>1 && (t[0,1]=='+' || t[0,1]=='-') && result_feedback_stat_label_v10512?(t[1,t.size-1])
      return [t[0,1]=='+' ? :buff : :debuff,
        t[0,1]=='+' ? PMD_AC::RESULT_FEEDBACK_PRIORITY_BUFF_V10512 : PMD_AC::RESULT_FEEDBACK_PRIORITY_DEBUFF_V10512]
    end
    [:misc,PMD_AC::RESULT_FEEDBACK_PRIORITY_MISC_V10512]
  rescue
    [:misc,PMD_AC::RESULT_FEEDBACK_PRIORITY_MISC_V10512]
  end

  # v0.88 的 status/control Queue 在 Focus 期間改交給 Compound Arbiter。
  # Focus 外完全走原方法，避免改變一般戰鬥 UI 行為。
  def queue_status_notice_v088(key,added=true)
    unless result_feedback_compound_context_v10512?
      return pmd_ac_v10512_compound_queue_status_notice_v088(key,added)
    end
    return if key==nil || dead?
    return if PMD_AC.const_defined?('STATUS_NOTICE_IGNORE_V088') && PMD_AC::STATUS_NOTICE_IGNORE_V088.include?(key)
    return pmd_ac_v10512_compound_queue_status_notice_v088(key,added) unless PMD_AC.respond_to?(:status_notice_label_v088)
    label=PMD_AC.status_notice_label_v088(key)
    return if label==nil || label.to_s==''
    text=(added ? '+' : '-')+label.to_s
    kind=added ? :status_control : :cleanse
    pri=added ? PMD_AC::RESULT_FEEDBACK_PRIORITY_STATUS_V10512 : PMD_AC::RESULT_FEEDBACK_PRIORITY_CLEANSE_V10512
    result_feedback_compound_register_v10512(kind,text,pri)
    nil
  rescue
    pmd_ac_v10512_compound_queue_status_notice_v088(key,added)
  end

  # v1.05.11 Heal / Shield / Guard / Displacement 與 v0.88 Stat Stage 都會進到這裡。
  def queue_custom_status_notice_v088(text)
    unless result_feedback_compound_context_v10512?
      return pmd_ac_v10512_compound_queue_custom_status_notice_v088(text)
    end
    kind,pri=result_feedback_classify_custom_v10512(text)
    result_feedback_compound_register_v10512(kind,text.to_s,pri)
    nil
  rescue
    pmd_ac_v10512_compound_queue_custom_status_notice_v088(text)
  end

  def result_feedback_compound_item_v10512(kind)
    p=@result_feedback_compound_pending_v10512 || {}
    p[kind]
  end

  def result_feedback_compound_item_count_v10512(kind)
    x=result_feedback_compound_item_v10512(kind)
    x==nil ? 0 : x[:count].to_i
  end

  def result_feedback_compound_item_text_v10512(kind)
    x=result_feedback_compound_item_v10512(kind)
    return '' if x==nil || x[:texts]==nil || x[:texts].empty?
    x[:texts][0].to_s
  end

  def result_feedback_compound_total_candidates_v10512
    n=0
    (@result_feedback_compound_pending_v10512 || {}).each_value{|x|n+=x[:count].to_i if x!=nil}
    n
  rescue
    0
  end

  def result_feedback_compound_max_priority_v10512
    p=-1
    (@result_feedback_compound_pending_v10512 || {}).each_value do |x|
      p=x[:priority].to_i if x!=nil && x[:priority].to_i>p
    end
    p
  rescue
    -1
  end

  def result_feedback_compound_compose_v10512
    p=@result_feedback_compound_pending_v10512 || {}
    return ['',[]] if p.empty?

    # Guard 代表技能結果被防禦 Authority 吃掉，直接壓過次要提示。
    if p[:guard]!=nil
      return ['防禦',[:guard]]
    end

    # 具體 Status / Control 比一般 stat change 更重要；Damage 數字仍獨立存在。
    if p[:status_control]!=nil
      return [result_feedback_compound_item_text_v10512(:status_control),[:status_control]]
    end

    # Roadmap 指定複合：Shield + Cleanse。
    if p[:shield]!=nil && p[:cleanse]!=nil
      return ['+護盾・淨化',[:shield,:cleanse]]
    end

    # Roadmap 指定複合：Heal + Buff。
    if p[:heal]!=nil && p[:buff]!=nil && p[:debuff]==nil
      return [result_feedback_compound_item_text_v10512(:heal)+'・強化',[:heal,:buff]]
    end

    # 多能力變化不逐條 Queue。
    if p[:buff]!=nil && p[:debuff]!=nil
      return ['能力變化',[:buff,:debuff]]
    end
    if p[:buff]!=nil && result_feedback_compound_item_count_v10512(:buff)>1
      return ['能力上升',[:buff]]
    end
    if p[:debuff]!=nil && result_feedback_compound_item_count_v10512(:debuff)>1
      return ['能力下降',[:debuff]]
    end

    # 多個狀態解除統一收斂成「淨化」。
    if p[:cleanse]!=nil
      if result_feedback_compound_item_count_v10512(:cleanse)>1
        return ['淨化',[:cleanse]]
      else
        return [result_feedback_compound_item_text_v10512(:cleanse),[:cleanse]]
      end
    end

    # 其餘選最高優先單項。
    best_kind=nil
    best_pri=-1
    p.each do |k,x|
      next if x==nil
      if x[:priority].to_i>best_pri
        best_pri=x[:priority].to_i
        best_kind=k
      end
    end
    return ['',[]] if best_kind==nil
    [result_feedback_compound_item_text_v10512(best_kind),[best_kind]]
  rescue
    ['',[]]
  end

  def result_feedback_compound_clear_visual_queue_v10512
    # 只清 target-local Presentation Queue，確保同一次 Focus 不會把舊細節逐條播完。
    @status_notice_queue_v088=[]
    @status_notice_text_v088=''
    @status_notice_frames_v088=0
  rescue
  end

  def result_feedback_compound_flush_v10512(force=false)
    p=@result_feedback_compound_pending_v10512 || {}
    return false if p.empty?
    token=result_feedback_compound_prepare_token_v10512
    return false if @result_feedback_compound_ko_token_v10512.to_i==token
    age=Graphics.frame_count.to_i-@result_feedback_compound_first_frame_v10512.to_i
    return false if !force && age<PMD_AC::RESULT_FEEDBACK_COMPOUND_WINDOW_V10512

    total=result_feedback_compound_total_candidates_v10512
    pri=result_feedback_compound_max_priority_v10512
    text,kinds=result_feedback_compound_compose_v10512
    @result_feedback_compound_pending_v10512={}
    @result_feedback_compound_first_frame_v10512=-1
    return false if text==nil || text.to_s==''

    replacement=(@result_feedback_compound_shown_priority_v10512.to_i>=0)
    result_feedback_compound_clear_visual_queue_v10512
    pmd_ac_v10512_compound_queue_custom_status_notice_v088(text.to_s) unless dead?
    @result_feedback_compound_shown_token_v10512=token
    @result_feedback_compound_shown_priority_v10512=pri
    @result_feedback_compound_shown_text_v10512=text.to_s

    s=result_feedback_compound_scene_v10512
    s.result_feedback_compound_flushed_v10512(self,text,kinds,total,replacement) if
      s!=nil && s.respond_to?(:result_feedback_compound_flushed_v10512)
    true
  rescue
    false
  end

  def result_feedback_compound_ko_dominant_v10512
    return false unless result_feedback_compound_context_v10512?
    token=result_feedback_compound_prepare_token_v10512
    @result_feedback_compound_pending_v10512={}
    @result_feedback_compound_first_frame_v10512=-1
    @result_feedback_compound_ko_token_v10512=token
    @result_feedback_compound_shown_priority_v10512=PMD_AC::RESULT_FEEDBACK_PRIORITY_KO_V10512
    @result_feedback_compound_shown_text_v10512=PMD_AC.const_defined?('RESULT_FEEDBACK_KO_TEXT_V10511') ? PMD_AC::RESULT_FEEDBACK_KO_TEXT_V10511 : '倒下'
    result_feedback_compound_clear_visual_queue_v10512
    s=result_feedback_compound_scene_v10512
    s.result_feedback_compound_ko_v10512(self) if s!=nil && s.respond_to?(:result_feedback_compound_ko_v10512)
    true
  rescue
    false
  end

  def start_faint
    result_feedback_compound_ko_dominant_v10512 if result_feedback_compound_context_v10512?
    pmd_ac_v10512_compound_start_faint
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10512_compound_start_battle start_battle unless method_defined?(:pmd_ac_v10512_compound_start_battle)
  alias pmd_ac_v10512_compound_update_unit_sprites update_unit_sprites unless method_defined?(:pmd_ac_v10512_compound_update_unit_sprites)
  alias pmd_ac_v10512_compound_focus_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v10512_compound_focus_complete)
  alias pmd_ac_v10512_compound_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10512_compound_focus_summary)

  def result_feedback_compound_context_v10512?(unit=nil)
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    return false unless respond_to?(:focus_cast_action_lane_active_v1058?)
    focus_cast_action_lane_active_v1058?
  rescue
    false
  end

  def result_feedback_compound_token_v10512
    return -1 unless result_feedback_compound_context_v10512?
    @focus_cast_start_frame_v1055.to_i
  rescue
    -1
  end

  def result_feedback_compound_reset_v10512
    @result_feedback_compound_counts_v10512={
      :candidates=>0,:flushes=>0,:collapsed=>0,:composites=>0,
      :replacements=>0,:suppressed=>0,:ko_dominant=>0
    }
    @result_feedback_compound_summary_logged_v10512=false
  end

  def result_feedback_compound_candidate_v10512(unit,kind,text,priority)
    c=@result_feedback_compound_counts_v10512 || {}
    c[:candidates]=c[:candidates].to_i+1
    @result_feedback_compound_counts_v10512=c
    true
  rescue
    false
  end

  def result_feedback_compound_suppressed_v10512(unit,kind,text,priority)
    c=@result_feedback_compound_counts_v10512 || {}
    c[:suppressed]=c[:suppressed].to_i+1
    @result_feedback_compound_counts_v10512=c
    true
  rescue
    false
  end

  def result_feedback_compound_flushed_v10512(unit,text,kinds,total,replacement=false)
    c=@result_feedback_compound_counts_v10512 || {}
    c[:flushes]=c[:flushes].to_i+1
    c[:collapsed]=c[:collapsed].to_i+[total.to_i-1,0].max
    c[:composites]=c[:composites].to_i+1 if kinds!=nil && kinds.size>1
    c[:replacements]=c[:replacements].to_i+1 if replacement
    @result_feedback_compound_counts_v10512=c
    log_event(:battle,'BATTLE_RESULT_FEEDBACK_COMPOUND_V10512 target='+
      (unit==nil ? 'NONE' : unit.log_name.to_s)+' text='+text.to_s+
      ' kinds='+(kinds||[]).map{|k|k.to_s}.join('+')+
      ' candidates='+total.to_i.to_s+' composite='+(kinds!=nil && kinds.size>1 ? '1' : '0')+
      ' replacement='+(replacement ? '1' : '0'))
    true
  rescue
    false
  end

  def result_feedback_compound_ko_v10512(unit)
    c=@result_feedback_compound_counts_v10512 || {}
    c[:ko_dominant]=c[:ko_dominant].to_i+1
    @result_feedback_compound_counts_v10512=c
    true
  rescue
    false
  end

  def result_feedback_compound_update_v10512(force=false)
    return false if @units==nil
    (@units||[]).each do |u|
      next if u==nil || !u.respond_to?(:result_feedback_compound_flush_v10512)
      u.result_feedback_compound_flush_v10512(force)
    end
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10512_compound_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      result_feedback_compound_reset_v10512
      log_event(:battle,'BATTLE_RESULT_FEEDBACK_SEMANTICS_II_V10512 START'+
        ' scope=focus_action_lane compound_window=6 max_parts=2 target_local=1'+
        ' damage_authority=existing_numeric_popup ko_authority=v10511_down'+
        ' heal_buff_compose=1 shield_cleanse_compose=1 stat_multi_compress=1'+
        ' per_target_once_with_priority_replace=1 top_feed=0 tether_line=0 new_sprite=0'+
        ' target_mark_geometry_unchanged=1 hp_unchanged=1 damage_formula_unchanged=1'+
        ' ai_unchanged=1 energy_unchanged=1 attack_wait_unchanged=1'+
        ' spatial_endpoint_unchanged=1 action_timing_unchanged=1')
    end
    r
  end

  # 先讓 6f Arbiter 到期，再更新 reaction target sprite，文字能在同一畫面 frame 被讀到。
  def update_unit_sprites
    result_feedback_compound_update_v10512(false) if result_feedback_compound_context_v10512?
    pmd_ac_v10512_compound_update_unit_sprites
  end

  # Action Lane 解鎖前強制 flush 尚未到 6f 的最後一筆，避免結果被帶到下一個 Focus。
  def focus_cast_complete_lock_v1055(reason)
    result_feedback_compound_update_v10512(true) if result_feedback_compound_context_v10512?
    pmd_ac_v10512_compound_focus_complete(reason)
  end

  def result_feedback_compound_log_summary_v10512
    return false if @result_feedback_compound_summary_logged_v10512
    @result_feedback_compound_summary_logged_v10512=true
    c=@result_feedback_compound_counts_v10512 || {}
    log_event(:battle,'BATTLE_RESULT_FEEDBACK_SEMANTICS_II_SUMMARY_V10512'+
      ' candidates='+c[:candidates].to_i.to_s+
      ' flushes='+c[:flushes].to_i.to_s+
      ' collapsed='+c[:collapsed].to_i.to_s+
      ' composites='+c[:composites].to_i.to_s+
      ' replacements='+c[:replacements].to_i.to_s+
      ' suppressed='+c[:suppressed].to_i.to_s+
      ' ko_dominant='+c[:ko_dominant].to_i.to_s+
      ' top_feed=0 new_sprite=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10512_compound_focus_summary
    result_feedback_compound_log_summary_v10512
    r
  rescue
    false
  end
end
