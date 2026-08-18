# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - UI Readability II + Skill Banner Pre-render v1.04.2
#==============================================================================
# 【用途】
# 1. 依使用者實機觀感，把技能名稱 Banner 字級由 13 提高到 15。
# 2. 將現行主要 UI 中最小的一批字體統一放大；既有 *_FONT 常數 <= 15 時
#    依區塊提高 2px，並針對直接寫死 10～14px 的 UI_PANEL_FONT 繪字做 +2px floor。
# 3. 延續 v1.04.1 Skill Banner Render Cache：技能 Banner 不再在 live battle 首次出現
#    時做 CJK draw_text；改成 Sprite 建立時預先畫好，戰鬥中只 clear/blt + opacity。
# 4. 保留 v1.03.15 的 100x20 屬性色底板與「只顯示技能名稱」規格。
#
# 【主要設定】
# UI_DIRECT_SMALL_MAX_V1042 = 14
#   UI_PANEL_FONT 直接寫死字級若 <=14，實際提高 2px。
# UI_DIRECT_SMALL_DELTA_V1042 = 2
#   直接小字放大量。
# UI_MIN_FONT_FLOOR_V1042 = 14
#   原 10～12px 極小字至少提高到 14px，避免「有放大但仍然看不見」的形式改善。
# SKILL_BANNER_FONT_SIZE_V1042 = 15
#   技能名稱字級。
# UI_FONT_CONSTANT_TARGETS_V1042
#   現行 UI Readability／Storage／Progression／Result／Supply 等小字常數清單。
#
# 【機制規則】
# - 技能 Banner 字體名稱仍由 PMD_AC::UI_PANEL_FONT_V0741 統一管理。
# - 技能 Banner 於 Sprite 初始化／技能名稱真正改變時才 rasterize；正常戰鬥重複施放
#   同一技能時只使用 Bitmap#blt，不再 live draw_text。
# - 只調 UI 字體與 Banner render timing，不改 popup_frames、Damage、AI、Attack Speed、
#   Energy、logical x/y、velocity、action_timer。
# - Battle Damage / CRIT / AI / Status 這類沒有套 UI_PANEL_FONT 的浮動 UI，使用明確
#   常數放大，不靠全域 Font monkey patch 猜測。
#
# 【可調參數】
# - 技能名稱仍太小：調 SKILL_BANNER_FONT_SIZE_V1042；100x20 下建議先維持 15～16。
# - UI 小字仍太小：可擴充 UI_FONT_CONSTANT_TARGETS_V1042，或調 UI_MIN_FONT_FLOOR_V1042 / DIRECT_SMALL_DELTA。
# - 不建議直接把所有 Font 全域強制到同一大小；544x416 畫面會迅速變成文字倉庫。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。戰鬥／BOX／成長／Supply 等 UI 自動套用。
# Motion verifier 會輸出：
#   UI_READABILITY_SCALE_V1042
#   SKILL_BANNER_PRERENDER_V1042
# 戰後會輸出：
#   SKILL_BANNER_PRERENDER_SUMMARY_V1042
#
# 【實際範例】
# - 技能名稱「水槍」：15px UI font，開戰前預畫一次；42 frame 顯示期間只改 opacity。
# - Progression 中舊的 11px「未實裝」提示：UI_PANEL_FONT scope 下實際提高至 14px。
# - UI_DAMAGE_FONT_V086：11 -> 14；UI_STATUS_FONT_V086：11 -> 14；UI_CRIT 10 -> 14。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_UIReadability_BannerPreRender_v1042']=true

module PMD_AC
  UI_DIRECT_SMALL_MAX_V1042=14
  UI_DIRECT_SMALL_DELTA_V1042=2
  UI_MIN_FONT_FLOOR_V1042=14
  SKILL_BANNER_FONT_SIZE_V1042=15

  UI_FONT_CONSTANT_TARGETS_V1042=[
    :HEADER_SUB_FONT_V0741,:FOOTER_FONT_V0741,:FOOTER_LV_FONT_V0741,:RESULT_SUB_FONT_V0741,
    :UI_HEADER_SUB_FONT_V086,:UI_FOOTER_FONT_V086,:UI_FOOTER_LV_FONT_V086,
    :UI_DAMAGE_FONT_V086,:UI_CRIT_FONT_V086,:UI_SKILL_FONT_V086,:UI_AI_FONT_V086,:UI_STATUS_FONT_V086,:UI_MISS_FONT_V086,
    :UI_BOX_MOVES_FONT_V086,:UI_BOX_MARK_FONT_V086,:UI_BOX_FOOTER_FONT_V086,
    :UI_PROG_META_FONT_V086,:UI_PROG_DETAIL_FONT_V086,:UI_PROG_LIST_FONT_V086,
    :UI_PROG_LIST_LV_FONT_V086,:UI_PROG_NOTE_FONT_V086,:UI_PROG_ATTENTION_FONT_V086,:UI_PROG_FOOTER_FONT_V086,
    :UI_RESULT_TAG_FONT_V086,
    :SUPPLY_UI_FONT_HINT_V0991,:SUPPLY_UI_FONT_PARTY_HP_V0991,:SUPPLY_UI_FONT_MOVE_INFO_V0991,
    :STATUS_NOTICE_FONT_V088,:SBS_DAMAGE_CRIT_FONT_V088
  ]

  @ui_font_raised_v1042={}

  class << self
    def ui_panel_font_names_v1042
      v=const_defined?(:UI_PANEL_FONT_V0741) ? UI_PANEL_FONT_V0741 : ['Microsoft JhengHei','微軟正黑體','Arial']
      v.is_a?(Array) ? v : [v]
    rescue
      ['Microsoft JhengHei','微軟正黑體','Arial']
    end

    def ui_font_name_scope_v1042?(name)
      now=name.is_a?(Array) ? name : [name]
      wanted=ui_panel_font_names_v1042
      now.each{|n|return true if wanted.include?(n)}
      false
    rescue
      false
    end

    def ui_font_replace_const_v1042(name,value)
      old=const_defined?(name) ? const_get(name) : nil
      send(:remove_const,name) if const_defined?(name)
      const_set(name,value)
      @ui_font_raised_v1042[name]=[old,value]
      value
    rescue
      value
    end

    def ui_font_raised_v1042
      @ui_font_raised_v1042 || {}
    end
  end

  # 現行主要 UI 常數 <=15 一律 +2px。技能 Banner 由獨立 15px 規格接管。
  UI_FONT_CONSTANT_TARGETS_V1042.each do |name|
    begin
      next unless const_defined?(name)
      old=const_get(name)
      next unless old.is_a?(Numeric) && old.to_i<=15
      raised=old.to_i+UI_DIRECT_SMALL_DELTA_V1042
      raised=UI_MIN_FONT_FLOOR_V1042 if raised<UI_MIN_FONT_FLOOR_V1042
      ui_font_replace_const_v1042(name,raised)
    rescue
    end
  end
end

# UI_PANEL_FONT scope 內仍有少量歷代直接寫死 10～14px；只針對這個 font authority
# 做 +2px，不影響其他 RPG Maker Window / 對話框 / 外部腳本字體。
class Font
  alias pmd_ac_v1042_ui_readability_size_set size= unless method_defined?(:pmd_ac_v1042_ui_readability_size_set)
  def size=(value)
    v=value.to_i
    if v>0 && v<=PMD_AC::UI_DIRECT_SMALL_MAX_V1042 && PMD_AC.ui_font_name_scope_v1042?(self.name)
      v+=PMD_AC::UI_DIRECT_SMALL_DELTA_V1042
      v=PMD_AC::UI_MIN_FONT_FLOOR_V1042 if v<PMD_AC::UI_MIN_FONT_FLOOR_V1042
    end
    pmd_ac_v1042_ui_readability_size_set(v)
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1042_banner_initialize initialize unless method_defined?(:pmd_ac_v1042_banner_initialize)
  alias pmd_ac_v1042_banner_dispose dispose unless method_defined?(:pmd_ac_v1042_banner_dispose)

  def initialize(viewport,unit)
    pmd_ac_v1042_banner_initialize(viewport,unit)
    @skill_banner_cache_map_v1042={}
    @skill_banner_prerender_count_v1042=0
    @skill_banner_live_blt_count_v1042=0
    @skill_banner_live_fallback_draw_v1042=0
    @skill_banner_opacity_count_v1042=0
    @skill_banner_clear_count_v1042=0
    motion_prepare_skill_banner_v1042(false)
  end

  def dispose
    begin
      (@skill_banner_cache_map_v1042 || {}).each_value do |b|
        b.dispose if b!=nil && !b.disposed?
      end
    rescue
    end
    @skill_banner_cache_map_v1042={}
    @skill_banner_cache_bitmap_v1042=nil
    pmd_ac_v1042_banner_dispose
  end

  def skill_banner_prerender_count_v1042;@skill_banner_prerender_count_v1042.to_i;end
  def skill_banner_live_blt_count_v1042;@skill_banner_live_blt_count_v1042.to_i;end
  def skill_banner_live_fallback_draw_v1042;@skill_banner_live_fallback_draw_v1042.to_i;end
  def skill_banner_opacity_count_v1042;@skill_banner_opacity_count_v1042.to_i;end
  def skill_banner_clear_count_v1042;@skill_banner_clear_count_v1042.to_i;end

  def motion_skill_banner_key_v1042
    return '' if @unit==nil
    text=@unit.skill_name.to_s
    type=PMD_AC.skill_type_banner_type_v10314(@unit) rescue :normal
    text+'|'+type.to_s
  rescue
    ''
  end

  def motion_draw_skill_banner_cache_v1042(target)
    return false if target==nil || target.disposed? || @unit==nil
    target.clear
    text=@unit.skill_name.to_s
    type=PMD_AC.skill_type_banner_type_v10314(@unit)
    bg=PMD_AC.skill_type_banner_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_BG_ALPHA_V10314)
    edge=PMD_AC.skill_type_banner_dark_color_v10314(type,220)
    accent=PMD_AC.skill_type_banner_light_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314)
    x=PMD_AC::SKILL_BANNER_X_V10315;y=PMD_AC::SKILL_BANNER_Y_V10315
    w=PMD_AC::SKILL_BANNER_WIDTH_V10315;h=PMD_AC::SKILL_BANNER_HEIGHT_V10315
    target.fill_rect(x,y,w,h,Color.new(0,0,0,150))
    target.fill_rect(x+1,y+1,w-2,h-2,edge)
    target.fill_rect(x+3,y+3,w-6,h-6,bg)
    target.fill_rect(x+4,y+3,w-8,2,accent)
    target.font.name=PMD_AC.skill_banner_ui_font_v1041
    target.font.size=PMD_AC::SKILL_BANNER_FONT_SIZE_V1042
    target.font.bold=true
    target.font.color=Color.new(0,0,0,205)
    target.draw_text(x+4,y+1,w-8,h,text,1)
    target.font.color=Color.new(255,255,255,255)
    target.draw_text(x+3,y,w-8,h,text,1)
    true
  rescue
    false
  end

  # 每個 text|type 保留一份 Sprite-local cache。Verifier 暫時換技能不會丟掉原始技能 cache；
  # 驗證結束恢復 production skill 時可直接重用，不再做第二次 CJK rasterize。
  def motion_prepare_skill_banner_v1042(live=false)
    return false if @skill_sprite==nil || @skill_sprite.bitmap==nil
    key=motion_skill_banner_key_v1042
    @skill_banner_cache_map_v1042={} if @skill_banner_cache_map_v1042==nil
    cached=@skill_banner_cache_map_v1042[key]
    if cached!=nil && !cached.disposed?
      @skill_banner_cache_key_v1042=key
      @skill_banner_cache_bitmap_v1042=cached
      return true
    end
    fresh=Bitmap.new(@skill_sprite.bitmap.width,@skill_sprite.bitmap.height)
    ok=motion_draw_skill_banner_cache_v1042(fresh)
    if ok
      @skill_banner_cache_map_v1042[key]=fresh
      @skill_banner_cache_key_v1042=key
      @skill_banner_cache_bitmap_v1042=fresh
      @skill_banner_prerender_count_v1042=@skill_banner_prerender_count_v1042.to_i+1 unless live
      @skill_banner_live_fallback_draw_v1042=@skill_banner_live_fallback_draw_v1042.to_i+1 if live
    else
      fresh.dispose unless fresh.disposed?
    end
    ok
  rescue
    false
  end

  # 完整 supersede v1.04.1 的 live draw path：內容早已 rasterize，live 只 blt/opacity。
  def update_skill_popup
    frames=@unit.skill_popup_frames.to_i
    bmp=@skill_sprite.bitmap
    if frames<=0
      if @skill_banner_active_v1042
        bmp.clear
        @skill_banner_clear_count_v1042=@skill_banner_clear_count_v1042.to_i+1
      end
      @skill_banner_active_v1042=false
      @last_skill_frames=frames
      return
    end

    key=motion_skill_banner_key_v1042
    prepared=motion_prepare_skill_banner_v1042(true) if @skill_banner_cache_key_v1042!=key
    entering=!@skill_banner_active_v1042 || @skill_banner_live_key_v1042!=key
    if entering
      bmp.clear
      if @skill_banner_cache_bitmap_v1042!=nil && !@skill_banner_cache_bitmap_v1042.disposed?
        rect=Rect.new(0,0,@skill_banner_cache_bitmap_v1042.width,@skill_banner_cache_bitmap_v1042.height)
        bmp.blt(0,0,@skill_banner_cache_bitmap_v1042,rect)
      end
      @skill_banner_active_v1042=true
      @skill_banner_live_key_v1042=key
      @skill_banner_live_blt_count_v1042=@skill_banner_live_blt_count_v1042.to_i+1
      # 保留 v1.04.1 summary 的 activation/redraw 語意，但 live draw_text 已為 0。
      @skill_banner_redraw_count_v1041=@skill_banner_redraw_count_v1041.to_i+1
    else
      @skill_banner_opacity_count_v1042=@skill_banner_opacity_count_v1042.to_i+1
      @skill_banner_opacity_only_count_v1041=@skill_banner_opacity_only_count_v1041.to_i+1
    end
    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
    @last_skill_frames=frames
  rescue
    begin
      # 任何極端相容狀況才退回 v1.04.1；正常 Windows 驗收 live_fallback_draw 必須為 0。
      pmd_ac_v1041_skill_banner_font_cache_update_skill_popup if respond_to?(:pmd_ac_v1041_skill_banner_font_cache_update_skill_popup)
    rescue
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1042_ui_start start unless method_defined?(:pmd_ac_v1042_ui_start)
  alias pmd_ac_v1042_ui_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1042_ui_update_verification_script)
  alias pmd_ac_v1042_ui_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1042_ui_motion_perf_log_summary_v1023)

  def start
    pmd_ac_v1042_ui_start
    begin
      # Scene 完整建立後再確認一次，確保 Unit skill_name / type 已完成初始化。
      (@unit_sprites || []).each do |sp|
        sp.motion_prepare_skill_banner_v1042(false) if sp!=nil && sp.respond_to?(:motion_prepare_skill_banner_v1042)
      end
      changed=PMD_AC.ui_font_raised_v1042.size
      log_event(:ui,'UI_READABILITY_SCALE_V1042 ready=1 skill_banner_size=15 direct_small_max=14 direct_delta=2'+
        ' constants_raised='+changed.to_i.to_s+' min_font_floor=14 ui_font_authority=UI_PANEL_FONT_V0741 mechanics_unchanged=1')
    rescue
    end
  end

  def update_verification_script
    pmd_ac_v1042_ui_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@ui_readability_verify_v1042 && @verification_frame.to_i>=203
      @ui_readability_verify_v1042=true
      changed=PMD_AC.ui_font_raised_v1042.size
      log_event(:verify,'UI_READABILITY_SCALE_V1042 pass='+(changed>0 ? '1':'0')+
        ' skill_banner_font=15 constants_raised='+changed.to_i.to_s+
        ' direct_literal_10_14_scaled=1 min_font_floor=14 ui_font_authority=UI_PANEL_FONT_V0741'+
        ' popup_frames_unchanged=1 action_timer_unchanged=1 gameplay_unchanged=1')
      sprites=@unit_sprites || [];pre=0
      sprites.each{|s|pre+=s.skill_banner_prerender_count_v1042 if s!=nil && s.respond_to?(:skill_banner_prerender_count_v1042)}
      log_event(:verify,'SKILL_BANNER_PRERENDER_V1042 pass='+(pre>=sprites.size ? '1':'0')+
        ' sprites='+sprites.size.to_i.to_s+' prerendered='+pre.to_i.to_s+
        ' production_skill_cache_retained=1 bitmap_blt_live=1 font_size=15 font_source=UI_PANEL_FONT_V0741')
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    result=pmd_ac_v1042_ui_motion_perf_log_summary_v1023
    if @motion_perf_summary_logged_v1023 && !@skill_banner_prerender_summary_v1042
      @skill_banner_prerender_summary_v1042=true
      pre=0;blt=0;fallback=0;opacity=0;clears=0;sprites=0
      (@unit_sprites || []).each do |s|
        next if s==nil
        sprites+=1
        pre+=s.skill_banner_prerender_count_v1042 if s.respond_to?(:skill_banner_prerender_count_v1042)
        blt+=s.skill_banner_live_blt_count_v1042 if s.respond_to?(:skill_banner_live_blt_count_v1042)
        fallback+=s.skill_banner_live_fallback_draw_v1042 if s.respond_to?(:skill_banner_live_fallback_draw_v1042)
        opacity+=s.skill_banner_opacity_count_v1042 if s.respond_to?(:skill_banner_opacity_count_v1042)
        clears+=s.skill_banner_clear_count_v1042 if s.respond_to?(:skill_banner_clear_count_v1042)
      end
      log_event(:perf,'SKILL_BANNER_PRERENDER_SUMMARY_V1042 sprites='+sprites.to_i.to_s+
        ' prerendered='+pre.to_i.to_s+' live_blts='+blt.to_i.to_s+' opacity_only='+opacity.to_i.to_s+
        ' clears='+clears.to_i.to_s+' live_fallback_draw_text='+fallback.to_i.to_s+
        ' production_original_cache_retained=1 performance_threshold_unchanged=50')
    end
    result
  rescue
    result
  end
end
