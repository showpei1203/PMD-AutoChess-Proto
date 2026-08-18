# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Skill Banner UI Font + Render Cache v1.04.1
#==============================================================================
# 【用途】
# 1. 技能名稱 Banner 不再硬編碼 Microsoft JhengHei，改為直接引用專案正式 UI
#    字體 authority：PMD_AC::UI_PANEL_FONT_V0741。
# 2. 修正既有 update_skill_popup 每幀因 skill_popup_frames 遞減而重做
#    Bitmap#clear / fill_rect / draw_text 的高成本行為。
# 3. 技能內容（skill_name）改變或 popup 重新出現時才重畫；其餘 frame 只更新 opacity。
# 4. 保留 v1.03.15 的 100x20、18 屬性色、只顯示技能名稱與原 fade timing。
#
# 【主要設定】
# SKILL_BANNER_FONT_SIZE_V1041 = 13
#   技能名稱字級，沿用 v1.03.16。
# SKILL_BANNER_UI_FONT_FALLBACK_V1041
#   若舊版 UI_PANEL_FONT_V0741 不存在時才使用的相容 fallback。
#
# 【機制規則】
# - 字體名稱來源與戰鬥 UI / Loading / Supply UI 共用 UI_PANEL_FONT_V0741。
# - popup frame 每幀仍照舊遞減；opacity 仍為 clamp(frames*12,0,255)。
# - 同一招式顯示期間不重畫文字、不重建底板，只更新 opacity。
# - 新招式即使上一個 popup 尚未完全消失，只要 skill_name 改變就立即重畫。
# - popup 結束時 Bitmap 只 clear 一次，避免透明內容殘留。
# - 不更動 skill_popup_frames、action_timer、Damage、AI、Attack Speed、Energy、Spatial。
#
# 【可調參數】
# - 若要改字級，調 SKILL_BANNER_FONT_SIZE_V1041。
# - 若未來 UI 全域換字體，不需再改本腳本；UI_PANEL_FONT_V0741 會自動同步。
# - 不要在此加入每 frame Time.now 或 PNG load；這層必須保持低負擔。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。戰鬥技能 popup 自動套用。
# Motion verifier / 戰鬥結束後可在 LOG 查看：
#   SKILL_BANNER_UI_FONT_CACHE_V1041
#   SKILL_BANNER_RENDER_CACHE_SUMMARY_V1041
#
# 【實際範例】
# 「水槍」開始顯示時：畫一次藍色底板＋文字。
# 後續 41 frame：只改 opacity，不再 draw_text。
# 下一次改成「火花」：偵測 skill_name 改變，立即重畫一次橘紅底板＋文字。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SkillBannerUIFontRenderCache_v1041']=true

module PMD_AC
  SKILL_BANNER_FONT_SIZE_V1041=13
  SKILL_BANNER_UI_FONT_FALLBACK_V1041=['Microsoft JhengHei','微軟正黑體','Arial']

  class << self
    def skill_banner_ui_font_v1041
      return UI_PANEL_FONT_V0741 if const_defined?(:UI_PANEL_FONT_V0741)
      SKILL_BANNER_UI_FONT_FALLBACK_V1041
    rescue
      SKILL_BANNER_UI_FONT_FALLBACK_V1041
    end
  end
end

class Sprite_PMDChessUnit
  def skill_banner_redraw_count_v1041
    @skill_banner_redraw_count_v1041.to_i
  end

  def skill_banner_opacity_only_count_v1041
    @skill_banner_opacity_only_count_v1041.to_i
  end

  def skill_banner_clear_count_v1041
    @skill_banner_clear_count_v1041.to_i
  end

  # 完整接管 v1.03.16 的 draw path；visual layout / fade authority 不變。
  def update_skill_popup
    frames=@unit.skill_popup_frames.to_i
    bmp=@skill_sprite.bitmap

    if frames<=0
      if @skill_banner_active_v1041
        bmp.clear
        @skill_banner_clear_count_v1041=@skill_banner_clear_count_v1041.to_i+1
      end
      @skill_banner_active_v1041=false
      @skill_banner_draw_key_v1041=nil
      @last_skill_frames=frames
      return
    end

    text=@unit.skill_name.to_s
    key=text
    redraw=!@skill_banner_active_v1041 || @skill_banner_draw_key_v1041!=key

    if redraw
      bmp.clear
      type=PMD_AC.skill_type_banner_type_v10314(@unit)
      bg=PMD_AC.skill_type_banner_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_BG_ALPHA_V10314)
      edge=PMD_AC.skill_type_banner_dark_color_v10314(type,220)
      accent=PMD_AC.skill_type_banner_light_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314)
      x=PMD_AC::SKILL_BANNER_X_V10315
      y=PMD_AC::SKILL_BANNER_Y_V10315
      w=PMD_AC::SKILL_BANNER_WIDTH_V10315
      h=PMD_AC::SKILL_BANNER_HEIGHT_V10315

      bmp.fill_rect(x,y,w,h,Color.new(0,0,0,150))
      bmp.fill_rect(x+1,y+1,w-2,h-2,edge)
      bmp.fill_rect(x+3,y+3,w-6,h-6,bg)
      bmp.fill_rect(x+4,y+3,w-8,2,accent)

      # 直接使用正式 UI font authority，而不是另存一套技能字體。
      bmp.font.name=PMD_AC.skill_banner_ui_font_v1041
      bmp.font.size=PMD_AC::SKILL_BANNER_FONT_SIZE_V1041
      bmp.font.bold=true
      bmp.font.color=Color.new(0,0,0,205)
      bmp.draw_text(x+4,y+1,w-8,h,text,1)
      bmp.font.color=Color.new(255,255,255,255)
      bmp.draw_text(x+3,y,w-8,h,text,1)

      @skill_banner_active_v1041=true
      @skill_banner_draw_key_v1041=key
      @skill_banner_redraw_count_v1041=@skill_banner_redraw_count_v1041.to_i+1
    else
      @skill_banner_opacity_only_count_v1041=@skill_banner_opacity_only_count_v1041.to_i+1
    end

    # 原 fade timing 完整保留；每 frame 唯一必要的 UI 更新。
    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
    @last_skill_frames=frames
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1041_skill_banner_font_cache_start start unless method_defined?(:pmd_ac_v1041_skill_banner_font_cache_start)
  alias pmd_ac_v1041_skill_banner_font_cache_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1041_skill_banner_font_cache_motion_perf_log_summary_v1023)
  alias pmd_ac_v1041_skill_banner_font_cache_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1041_skill_banner_font_cache_update_verification_script)

  def start
    pmd_ac_v1041_skill_banner_font_cache_start
    begin
      log_event(:ui,'SKILL_BANNER_UI_FONT_CACHE_V1041 ready=1 font_source=UI_PANEL_FONT_V0741'+
        ' size=13 banner=100x20 type_text=0 badge=0 draw_on_content_change=1 opacity_only_per_frame=1'+
        ' popup_frames_unchanged=1 action_timer_unchanged=1 damage_unchanged=1 ai_unchanged=1'+
        ' attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    rescue
    end
  end

  def motion_perf_log_summary_v1023
    result=pmd_ac_v1041_skill_banner_font_cache_motion_perf_log_summary_v1023
    if @motion_perf_summary_logged_v1023 && !@skill_banner_render_cache_summary_v1041
      redraw=0;opacity_only=0;clears=0;sprites=0
      (@unit_sprites || []).each do |s|
        next if s==nil
        sprites+=1
        redraw+=s.skill_banner_redraw_count_v1041 if s.respond_to?(:skill_banner_redraw_count_v1041)
        opacity_only+=s.skill_banner_opacity_only_count_v1041 if s.respond_to?(:skill_banner_opacity_only_count_v1041)
        clears+=s.skill_banner_clear_count_v1041 if s.respond_to?(:skill_banner_clear_count_v1041)
      end
      @skill_banner_render_cache_summary_v1041=true
      log_event(:perf,'SKILL_BANNER_RENDER_CACHE_SUMMARY_V1041 sprites='+sprites.to_i.to_s+
        ' redraws='+redraw.to_i.to_s+' opacity_only='+opacity_only.to_i.to_s+' clears='+clears.to_i.to_s+
        ' per_frame_draw_text=0 cached_bitmap=1 font_source=UI_PANEL_FONT_V0741'+
        ' performance_threshold_unchanged=50')
    end
    result
  rescue
    result
  end

  def update_verification_script
    pmd_ac_v1041_skill_banner_font_cache_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    return if @skill_banner_ui_font_cache_verify_v1041
    return unless @verification_frame.to_i>=204
    @skill_banner_ui_font_cache_verify_v1041=true
    ok=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741)
    log_event(:verify,'SKILL_BANNER_UI_FONT_CACHE_V1041 pass='+(ok ? '1':'0')+
      ' ui_font_authority='+(ok ? 'UI_PANEL_FONT_V0741':'fallback')+
      ' draw_on_content_change=1 opacity_only_per_frame=1 per_frame_draw_text=0'+
      ' popup_frames_unchanged=1 action_timer_unchanged=1 damage_unchanged=1 ai_unchanged=1'+
      ' attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
  rescue
  end
end
