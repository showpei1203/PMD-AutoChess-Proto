# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Focus Cast Readability + Queue Guard v1.05.7
#==============================================================================
# 【用途】
# 1. 延續 v1.05.5／v1.05.6 的技能 Focus Cast 方向，修正實機回饋：Focus 太短、
#    技能名稱幾乎一閃而過，玩家來不及讀懂技能；同時修正 Focus 畫面可能殘留
#    舊式技能 Banner（尤其亮色／黃色底板）造成重複文字與視覺誤讀。
# 2. 修正 v1.05.6 FIFO Queue 與既有 Attack Cadence stale_action_timer 看門狗衝突：
#    Queue 故意暫停技能 action_timer 時，不應被「8 frame 沒下降＝卡死」規則取消。
# 3. 不改 HP、Damage、Attack Wait、Energy 數量、AI 決策、技能 Target、Spatial、
#    Projectile 速度或技能本身 hitFrame；只有 Focus Intro 的 Presentation Pause 延長。
#
# 【正式 Focus 時序】
# - 硬 Freeze：36 frame（約 0.60 秒 @60fps）。
# - Overlay 漸入：8 frame。
# - 技能名稱：第 10 frame 出現，因此硬停期間至少可完整閱讀約 26 frame。
# - Intro 結束後：Gameplay 恢復，Overlay 用 18 frame 漸退。
# - Focus Title 不立即消失：恢復 Gameplay 後再完整保留 8 frame，接著 12 frame 漸退。
# - v1.05.4 Source/Target Cue 在 Intro 結束時重新起算，讓「目標鎖定」不會因為
#   Intro 變長而在技能真正開始動作前就過期。
#
# 【黃色／固定技能 Banner 修正】
# - Full Focus 期間，所有 Sprite_PMDChessUnit 既有 @skill_sprite opacity 強制為 0。
# - Full Focus 成功取得 ownership 時，會把當下所有舊 skill_popup_frames 清為 0；
#   這只消除重複／殘留的技能名稱 UI，不碰技能 action timer。Full Focus 專用 Title 成為
#   此次技能唯一文字 authority；非 Full Focus 的舊 54f Skill Banner 系統仍保留。
# - Focus 專用 Title 改為 300x44：深色中性底、白字、Type 色細邊。只顯示當前技能名。
# - 每次新 Full Focus 開始與 Title fade 完成時都清空專用 bitmap，避免前一招殘影。
#
# 【Queue Guard 修正】
# - v1.05.6 Queue pending 時，action_timer 不下降是「刻意等待 Focus」，不是卡死。
# - 因此只在 focus_cast_queue_pending_v1056? == true 時略過
#   cadence_stale_action_guard_v099142，並重置 stale counter。
# - Queue 之外完全沿用原 cadence recovery；死亡仍由 v1.05.6 owner_faint 正常移除。
# - 不重新呼叫 begin_skill、不重扣 Energy、不重新骰狀態／Target。
#
# 【可調參數】
# FOCUS_CAST_INTRO_FRAMES_V1057 = 36
# FOCUS_CAST_FADE_IN_FRAMES_V1057 = 8
# FOCUS_CAST_TITLE_FRAME_V1057 = 10
# FOCUS_CAST_FADE_OUT_FRAMES_V1057 = 18
# FOCUS_CAST_TITLE_POST_HOLD_V1057 = 8
# FOCUS_CAST_TITLE_POST_FADE_V1057 = 12
# FOCUS_CAST_TITLE_W_V1057 = 300
# FOCUS_CAST_TITLE_H_V1057 = 44
# FOCUS_CAST_TITLE_FONT_V1057 = 24
#
# 【專屬 Species／Skill／Boss】
# - v1.05.5 的 FOCUS_CAST_SPECIES_OVERRIDES_V1055、
#   FOCUS_CAST_SKILL_OVERRIDES_V1055、FOCUS_CAST_BOSS_OVERRIDE_V1055 繼續有效。
# - 本版對一般值採「最低可讀時間」保護；若未來需要某隻 Boss 更長，直接在舊
#   override 中設定更大的 intro / fade / title_frame 即可。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。NORMAL → Shift 開戰後自動啟用。
# 主要 LOG：
#   BATTLE_FOCUS_CAST_READABILITY_V1057 START ...
#   BATTLE_FOCUS_CAST_BEGIN_V1055 ... intro_frames=36 ...
#   BATTLE_FOCUS_CAST_QUEUE_RELEASE_V1056 ...
#   BATTLE_FOCUS_CAST_READABILITY_QUEUE_SUMMARY_V1057 ...
#
# 【實際範例】
# 1. 傑尼龜準備水槍：Overlay 8f 漸入，全場硬停。
# 2. 第 10f 顯示「水槍」，之後還有約 26f 可在靜止畫面閱讀。
# 3. 第 36f Gameplay 恢復；遮罩 18f 漸退，Title 再維持 8f 後 12f 漸退。
# 4. Target Cue 從恢復 Gameplay 的瞬間重新起算，玩家可追到真正飛行／命中。
# 5. 同時準備技能的第二隻 Pokémon 進 FIFO Queue；其 timer 暫停不再被 stale guard
#    誤判，前一招完成後才取得自己的完整 Focus。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusCastReadabilityQueueGuard_v1057']=true

module PMD_AC
  FOCUS_CAST_INTRO_FRAMES_V1057 = 36
  FOCUS_CAST_FADE_IN_FRAMES_V1057 = 8
  FOCUS_CAST_TITLE_FRAME_V1057 = 10
  FOCUS_CAST_FADE_OUT_FRAMES_V1057 = 18
  FOCUS_CAST_TITLE_POST_HOLD_V1057 = 8
  FOCUS_CAST_TITLE_POST_FADE_V1057 = 12
  FOCUS_CAST_TITLE_W_V1057 = 300
  FOCUS_CAST_TITLE_H_V1057 = 44
  FOCUS_CAST_TITLE_FONT_V1057 = 24
end

class Game_PMDChessUnit
  alias pmd_ac_v1057_queue_guard_cadence_stale_action_guard_v099142 cadence_stale_action_guard_v099142 unless method_defined?(:pmd_ac_v1057_queue_guard_cadence_stale_action_guard_v099142)

  def cadence_stale_action_guard_v099142
    if respond_to?(:focus_cast_queue_pending_v1056?) && focus_cast_queue_pending_v1056?
      @cadence_timer_last_value_v099142=@action_timer.to_i
      @cadence_timer_stale_frames_v099142=0
      return false
    end
    pmd_ac_v1057_queue_guard_cadence_stale_action_guard_v099142
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1057_readability_focus_cast_profile_v1055 focus_cast_profile_v1055 unless method_defined?(:pmd_ac_v1057_readability_focus_cast_profile_v1055)
  alias pmd_ac_v1057_readability_focus_cast_create_v1055 focus_cast_create_v1055 unless method_defined?(:pmd_ac_v1057_readability_focus_cast_create_v1055)
  alias pmd_ac_v1057_readability_focus_cast_begin_v1055 focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v1057_readability_focus_cast_begin_v1055)
  alias pmd_ac_v1057_readability_focus_cast_release_intro_v1055 focus_cast_release_intro_v1055 unless method_defined?(:pmd_ac_v1057_readability_focus_cast_release_intro_v1055)
  alias pmd_ac_v1057_readability_start_battle start_battle unless method_defined?(:pmd_ac_v1057_readability_start_battle)
  alias pmd_ac_v1057_readability_update update unless method_defined?(:pmd_ac_v1057_readability_update)
  alias pmd_ac_v1057_readability_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1057_readability_check_battle_end)
  alias pmd_ac_v1057_readability_focus_cast_queue_log_summary_v1056 focus_cast_queue_log_summary_v1056 unless method_defined?(:pmd_ac_v1057_readability_focus_cast_queue_log_summary_v1056)

  def focus_cast_profile_v1055(user)
    p=pmd_ac_v1057_readability_focus_cast_profile_v1055(user)
    p={} if p==nil
    p[:intro_frames]=PMD_AC::FOCUS_CAST_INTRO_FRAMES_V1057 if p[:intro_frames].to_i<PMD_AC::FOCUS_CAST_INTRO_FRAMES_V1057
    p[:fade_in_frames]=PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1057 if p[:fade_in_frames].to_i<PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1057
    p[:title_frame]=PMD_AC::FOCUS_CAST_TITLE_FRAME_V1057 if p[:title_frame].to_i<PMD_AC::FOCUS_CAST_TITLE_FRAME_V1057
    p[:fade_out_frames]=PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1057 if p[:fade_out_frames].to_i<PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1057
    p
  rescue
    {
      :intro_frames=>PMD_AC::FOCUS_CAST_INTRO_FRAMES_V1057,
      :fade_in_frames=>PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1057,
      :title_frame=>PMD_AC::FOCUS_CAST_TITLE_FRAME_V1057,
      :fade_out_frames=>PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1057,
      :mask_opacity=>232,
      :charge_style=>:orbit
    }
  end

  def focus_cast_create_v1055
    r=pmd_ac_v1057_readability_focus_cast_create_v1055
    sp=@focus_cast_title_v1055
    if sp!=nil
      if sp.bitmap!=nil && !sp.bitmap.disposed?
        sp.bitmap.dispose
      end
      sp.bitmap=Bitmap.new(PMD_AC::FOCUS_CAST_TITLE_W_V1057,PMD_AC::FOCUS_CAST_TITLE_H_V1057)
      sp.ox=PMD_AC::FOCUS_CAST_TITLE_W_V1057/2
      sp.oy=PMD_AC::FOCUS_CAST_TITLE_H_V1057/2
      sp.opacity=0
      sp.visible=false
    end
    @focus_cast_title_post_age_v1057=-1
    @focus_cast_title_owner_v1057=nil
    r
  rescue
    r
  end

  def focus_cast_clear_title_v1057
    sp=@focus_cast_title_v1055
    return false if sp==nil
    sp.visible=false
    sp.opacity=0
    sp.bitmap.clear if sp.bitmap!=nil && !sp.bitmap.disposed?
    true
  rescue
    false
  end

  def focus_cast_draw_title_v1055(user,type)
    sp=@focus_cast_title_v1055
    return false if sp==nil || sp.bitmap==nil
    b=sp.bitmap
    b.clear
    w=PMD_AC::FOCUS_CAST_TITLE_W_V1057
    h=PMD_AC::FOCUS_CAST_TITLE_H_V1057
    name=(user!=nil && user.respond_to?(:skill_name)) ? user.skill_name.to_s : 'SKILL'
    accent=focus_cast_color_v1055(type,235)
    b.fill_rect(4,4,w-8,h-8,Color.new(0,0,0,220))
    b.fill_rect(7,5,w-14,3,accent)
    b.fill_rect(7,h-8,w-14,2,accent)
    begin
      names=defined?(PMD_AC::UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei','微軟正黑體','Arial']
      b.font.name=names
    rescue
    end
    b.font.size=PMD_AC::FOCUS_CAST_TITLE_FONT_V1057
    b.font.bold=true
    b.font.color=Color.new(0,0,0,230)
    b.draw_text(12,7,w-24,h-12,name,1)
    b.font.color=Color.new(255,255,255,255)
    b.draw_text(12,6,w-24,h-12,name,1)
    true
  rescue
    false
  end

  def focus_cast_position_title_v1057
    owner=@focus_cast_owner_v1055 || @focus_cast_title_owner_v1057
    return false if @focus_cast_title_v1055==nil || owner==nil
    a=focus_cast_anchor_v1055(owner)
    half=PMD_AC::FOCUS_CAST_TITLE_W_V1057/2
    x=a[0].to_i
    y=a[1].to_i+52
    x=half if x<half
    x=Graphics.width-half if x>Graphics.width-half
    y=30 if y<30
    y=Graphics.height-30 if y>Graphics.height-30
    @focus_cast_title_v1055.x=x
    @focus_cast_title_v1055.y=y
    true
  rescue
    false
  end

  def focus_cast_show_title_v1055
    return if @focus_cast_title_v1055==nil || @focus_cast_owner_v1055==nil
    focus_cast_draw_title_v1055(@focus_cast_owner_v1055,@focus_cast_type_v1055)
    focus_cast_position_title_v1057
    @focus_cast_title_v1055.opacity=255
    @focus_cast_title_v1055.visible=true
  rescue
  end

  def focus_cast_clear_legacy_popups_v1057
    (@unit_sprites || []).each do |usp|
      next if usp==nil
      begin
        u=usp.respond_to?(:unit) ? usp.unit : usp.instance_variable_get(:@unit)
        if u!=nil
          u.instance_variable_set(:@skill_popup_frames,0)
        end
        s=usp.instance_variable_get(:@skill_sprite)
        s.opacity=0 if s!=nil && !s.disposed?
      rescue
      end
    end
    true
  rescue
    false
  end

  def focus_cast_suppress_legacy_banners_v1057
    (@unit_sprites || []).each do |usp|
      next if usp==nil
      begin
        s=usp.instance_variable_get(:@skill_sprite)
        s.opacity=0 if s!=nil && !s.disposed?
      rescue
      end
    end
    true
  rescue
    false
  end

  def focus_cast_refresh_target_context_v1057(user,target)
    return false if user==nil
    now=Graphics.frame_count.to_i
    ctx=nil
    (@skill_focus_contexts_v1054 || []).reverse_each do |c|
      if c!=nil && c[:user]==user
        ctx=c
        break
      end
    end
    return false if ctx==nil
    ctx[:target]=target
    ctx[:start]=now
    ctx[:impact_at]=nil
    true
  rescue
    false
  end

  def focus_cast_begin_v1055(user,target)
    ok=pmd_ac_v1057_readability_focus_cast_begin_v1055(user,target)
    if ok
      @focus_cast_title_post_age_v1057=-1
      @focus_cast_title_owner_v1057=user
      focus_cast_clear_title_v1057
      focus_cast_clear_legacy_popups_v1057
    end
    ok
  rescue
    false
  end

  def focus_cast_release_intro_v1055
    user=@focus_cast_owner_v1055
    target=@focus_cast_target_v1055
    r=pmd_ac_v1057_readability_focus_cast_release_intro_v1055
    if r && user!=nil
      focus_cast_show_title_v1055
      @focus_cast_title_post_age_v1057=0
      @focus_cast_title_owner_v1057=user
      focus_cast_refresh_target_context_v1057(user,target)
    end
    r
  rescue
    false
  end

  def focus_cast_update_title_post_v1057
    age=@focus_cast_title_post_age_v1057.to_i
    return if age<0
    sp=@focus_cast_title_v1055
    if sp==nil || (@focus_cast_owner_v1055==nil && @focus_cast_title_owner_v1057==nil)
      @focus_cast_title_post_age_v1057=-1
      @focus_cast_title_owner_v1057=nil
      focus_cast_clear_title_v1057
      return
    end
    hold=PMD_AC::FOCUS_CAST_TITLE_POST_HOLD_V1057
    fade=PMD_AC::FOCUS_CAST_TITLE_POST_FADE_V1057
    total=hold+fade
    if age<hold
      op=255
    else
      left=total-age
      op=(255*[left,0].max/fade.to_f).to_i
    end
    focus_cast_position_title_v1057
    sp.opacity=PMD_AC.clamp(op,0,255)
    sp.visible=op>0
    age+=1
    if age>=total
      @focus_cast_title_post_age_v1057=-1
      @focus_cast_title_owner_v1057=nil
      focus_cast_clear_title_v1057
    else
      @focus_cast_title_post_age_v1057=age
    end
  rescue
  end

  def start_battle
    r=pmd_ac_v1057_readability_start_battle
    if respond_to?(:focus_cast_normal_v1055?) && focus_cast_normal_v1055?
      @focus_cast_title_post_age_v1057=-1
      log_event(:battle,'BATTLE_FOCUS_CAST_READABILITY_V1057 START intro_frames=36 fade_in=8 title_frame=10'+
        ' title_static_read_frames=26 fade_out=18 title_post_hold=8 title_post_fade=12'+
        ' title=neutral_dark_type_accent legacy_skill_banners_suppressed=1 legacy_popups_cleared_on_full_focus=1'+
        ' target_context_restart_on_release=1 queue_stale_guard_bypass=1'+
        ' hp_unchanged=1 damage_unchanged=1 attack_wait_unchanged=1 energy_amount_unchanged=1'+
        ' ai_decision_unchanged=1 spatial_unchanged=1')
    end
    r
  end

  def update
    r=pmd_ac_v1057_readability_update
    if $scene==self
      if @focus_cast_intro_active_v1055 || @focus_cast_title_post_age_v1057.to_i>=0
        focus_cast_suppress_legacy_banners_v1057
      end
      focus_cast_update_title_post_v1057 unless @focus_cast_intro_active_v1055
    end
    r
  end

  def focus_cast_queue_log_summary_v1056
    r=pmd_ac_v1057_readability_focus_cast_queue_log_summary_v1056
    unless @focus_cast_readability_queue_summary_v1057
      @focus_cast_readability_queue_summary_v1057=true
      log_event(:battle,'BATTLE_FOCUS_CAST_READABILITY_QUEUE_SUMMARY_V1057 queued='+@focus_cast_queue_total_v1056.to_i.to_s+
        ' released='+@focus_cast_queue_release_count_v1056.to_i.to_s+
        ' dropped='+@focus_cast_queue_drop_count_v1056.to_i.to_s+
        ' pending='+((@focus_cast_queue_v1056 || []).size).to_s+
        ' stale_action_guard_bypass=1 expected_surviving_queue_release=1')
    end
    r
  rescue
    false
  end

  def check_battle_end
    before=@phase
    r=pmd_ac_v1057_readability_check_battle_end
    if before==:battle && @phase!=:battle
      @focus_cast_title_post_age_v1057=-1
      @focus_cast_title_owner_v1057=nil
      focus_cast_clear_title_v1057
    end
    r
  end
end
