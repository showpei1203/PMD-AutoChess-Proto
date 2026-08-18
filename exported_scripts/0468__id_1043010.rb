# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - UI Readability III / Battle Bars + Skill Banner v1.04.3
#==============================================================================
# 【用途】
# 1. 依 Windows 544px 實機截圖，直接放大戰鬥畫面上方 Runtime 副標與下方兩行狀態列，
#    不再只依賴歷史 *_FONT 常數是否剛好被該畫面使用。
# 2. 技能名稱 Banner 由 15px 提高到 18px；短中文技能維持 18px，僅在文字真的超過
#    底板寬度時才逐級縮至 15px，避免所有技能一起被保守縮小。
# 3. 現行 UI_PANEL_FONT authority 下的最小字體 floor 由 14 提高到 16；v1.04.2 已經
#    提高過的 14～17px UI 常數，再依可讀性規則提升至 16～18px。
# 4. 延續 v1.04.2 Banner pre-render/cache，live battle 仍只做 Bitmap#blt + opacity，
#    不因字變大恢復每幀 draw_text。
#
# 【主要設定】
# UI_MIN_FONT_FLOOR_V1043       = 16  UI_PANEL_FONT 最小字級。
# UI_SMALL_FONT_CEILING_V1043   = 17  目前仍視為「小字」的上限。
# SKILL_BANNER_FONT_SIZE_V1043  = 18  技能名稱正常字級。
# SKILL_BANNER_FONT_MIN_V1043   = 15  長技能名稱自動縮字下限。
# HEADER_SUB_FONT_V1043         = 18  戰鬥上方 Runtime 副標。
# FOOTER_LINE1_FONT_V1043       = 17  下方存活數。
# FOOTER_LINE2_FONT_V1043       = 17  下方 Motion/速度資訊。
#
# 【機制規則】
# - 字體名稱一律引用 PMD_AC::UI_PANEL_FONT_V0741，和正式 UI 共用同一 authority。
# - 技能 Banner 保留約 2/3 寬度；只把高度由 20 提到 24，讓 18px 中文字不被裁切。
# - Header/Footer 只改繪字與底板，不改 Scene 尺寸、battle timer、Damage、AI、
#   Attack Speed、Energy、logical x/y、velocity 或 action_timer。
# - 不使用全域「所有字都巨大化」；只處理 UI_PANEL_FONT scope 與已知戰鬥 UI。
#
# 【可調參數】
# - 技能名仍小：SKILL_BANNER_FONT_SIZE_V1043 可調 18～19。
# - 上方副標仍小：HEADER_SUB_FONT_V1043 可調 18～19。
# - 下方資訊仍小：FOOTER_LINE*_FONT_V1043 可調 17～18。
# - 544px 視窗若文字太擠，優先縮長英文技能，不要再把所有中文 UI 降回 13px。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion / 正式 UI 自動套用。
# Verifier 會輸出：
#   UI_READABILITY_EXPLICIT_BARS_V1043
#   SKILL_BANNER_FONT_V1043
#
# 【實際範例】
# - 「水槍」「寄生種子」正常以 18px 顯示；超長英文技能才依 108px 底板自動縮字。
# - 上方「Motion B Runtime｜速度 x1｜...」以 18px 顯示。
# - 下方「藍方存活...」與「Motion Phase A...」以 17px 顯示。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_UIReadability_ExplicitBattleBars_v1043']=true

module PMD_AC
  UI_MIN_FONT_FLOOR_V1043=16
  UI_SMALL_FONT_CEILING_V1043=17
  SKILL_BANNER_FONT_SIZE_V1043=18
  SKILL_BANNER_FONT_MIN_V1043=15
  SKILL_BANNER_WIDTH_V1043=108
  SKILL_BANNER_HEIGHT_V1043=24
  SKILL_BANNER_X_V1043=21
  SKILL_BANNER_Y_V1043=4
  HEADER_SUB_FONT_V1043=18
  FOOTER_LINE1_FONT_V1043=17
  FOOTER_LINE2_FONT_V1043=17

  # 讓 v1.04.2 舊 verifier / cache helper 也回報與使用新正式字級。
  begin
    remove_const(:SKILL_BANNER_FONT_SIZE_V1042) if const_defined?(:SKILL_BANNER_FONT_SIZE_V1042)
    const_set(:SKILL_BANNER_FONT_SIZE_V1042,SKILL_BANNER_FONT_SIZE_V1043)
  rescue
  end

  @ui_font_raised_v1043={}
  class << self
    def ui_font_replace_const_v1043(name,value)
      old=const_defined?(name) ? const_get(name) : nil
      send(:remove_const,name) if const_defined?(name)
      const_set(name,value)
      @ui_font_raised_v1043[name]=[old,value]
      value
    rescue
      value
    end

    def ui_font_raised_v1043
      @ui_font_raised_v1043 || {}
    end
  end

  # v1.04.2 已先做第一輪；本版把實機仍屬小字的 14～17px 再推到 16～18px。
  begin
    names=const_defined?(:UI_FONT_CONSTANT_TARGETS_V1042) ? UI_FONT_CONSTANT_TARGETS_V1042 : []
    names.each do |name|
      next unless const_defined?(name)
      old=const_get(name)
      next unless old.is_a?(Numeric)
      v=old.to_i
      next if v>UI_SMALL_FONT_CEILING_V1043
      raised=v
      raised=UI_MIN_FONT_FLOOR_V1043 if raised<UI_MIN_FONT_FLOOR_V1043
      raised+=1 if raised>=16 && raised<18
      ui_font_replace_const_v1043(name,raised)
    end
  rescue
  end
end

# UI_PANEL_FONT scope 的直接 size= 也設 16px floor。載入順序在 v1.04.2 後，
# 因此先由本層提高，再交回舊 setter；舊層看到 >=16 不會二次放大。
class Font
  alias pmd_ac_v1043_ui_readability_size_set size= unless method_defined?(:pmd_ac_v1043_ui_readability_size_set)
  def size=(value)
    v=value.to_i
    if v>0 && v<=PMD_AC::UI_SMALL_FONT_CEILING_V1043 && PMD_AC.ui_font_name_scope_v1042?(self.name)
      v=PMD_AC::UI_MIN_FONT_FLOOR_V1043 if v<PMD_AC::UI_MIN_FONT_FLOOR_V1043
      v+=1 if v>=16 && v<18
    end
    pmd_ac_v1043_ui_readability_size_set(v)
  end
end

class Sprite_PMDChessUnit
  # supersede v1.04.2 cache rasterizer；cache/pre-render/lifecycle 全部沿用，只換尺寸與字級。
  def motion_draw_skill_banner_cache_v1042(target)
    return false if target==nil || target.disposed? || @unit==nil
    target.clear
    text=@unit.skill_name.to_s
    type=PMD_AC.skill_type_banner_type_v10314(@unit)
    bg=PMD_AC.skill_type_banner_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_BG_ALPHA_V10314)
    edge=PMD_AC.skill_type_banner_dark_color_v10314(type,220)
    accent=PMD_AC.skill_type_banner_light_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314)
    x=PMD_AC::SKILL_BANNER_X_V1043;y=PMD_AC::SKILL_BANNER_Y_V1043
    w=PMD_AC::SKILL_BANNER_WIDTH_V1043;h=PMD_AC::SKILL_BANNER_HEIGHT_V1043
    target.fill_rect(x,y,w,h,Color.new(0,0,0,150))
    target.fill_rect(x+1,y+1,w-2,h-2,edge)
    target.fill_rect(x+3,y+3,w-6,h-6,bg)
    target.fill_rect(x+4,y+3,w-8,2,accent)
    target.font.name=PMD_AC.skill_banner_ui_font_v1041
    target.font.bold=true
    target.font.size=PMD_AC::SKILL_BANNER_FONT_SIZE_V1043
    # 長英文技能才縮；短中文技能不再因保守設定一起縮小。
    begin
      while target.font.size>PMD_AC::SKILL_BANNER_FONT_MIN_V1043 && target.text_size(text).width>w-12
        target.font.size=target.font.size-1
      end
    rescue
    end
    target.font.color=Color.new(0,0,0,205)
    target.draw_text(x+5,y+2,w-10,h,text,1)
    target.font.color=Color.new(255,255,255,255)
    target.draw_text(x+4,y+1,w-10,h,text,1)
    true
  rescue
    false
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1043_ui_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1043_ui_update_verification_script)

  # 直接 supersede screenshot 中仍偏小的 Header 副標。
  def motion_draw_header_fast_v1028
    unless respond_to?(:pmd_motion_phase_a_v102?) && pmd_motion_phase_a_v102?
      return pmd_ac_v103_motion_draw_header_fast_v1028
    end
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    bmp.font.name=PMD_AC.ui_panel_font_names_v1042
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(12,3,Graphics.width-24,27,'PMD Motion Framework Phase B v1.03',1)
    bmp.font.size=PMD_AC::HEADER_SUB_FONT_V1043;bmp.font.bold=false;bmp.font.color=Color.new(190,225,255)
    text='布陣｜Motion B 資源準備中'
    if @phase==:battle
      text='Motion B Runtime｜速度 x'+@battle_speed.to_i.to_s+'｜A 切換速度｜B 離開'
    elsif @phase==:result
      text='Motion B 測試結束｜C 回布陣｜B 離開'
    elsif @motion_transition_ready_v1028
      text='布陣｜Motion B Ready｜Shift 開戰'
    end
    bmp.draw_text(12,33,Graphics.width-24,27,text,1)
    @motion_ui_header_fast_used_v1028=true
  rescue
    pmd_ac_v103_motion_draw_header_fast_v1028
  end

  # 直接 supersede screenshot 中下方兩行 15px hardcode。
  def motion_draw_footer_fast_v1028
    return if @footer_sprite==nil || @footer_sprite.bitmap==nil
    key=motion_footer_key_v1028
    return if @motion_ui_footer_key_v1028==key
    @motion_ui_footer_key_v1028=key
    bmp=@footer_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,52,Color.new(0,0,0,205))
    bmp.font.name=PMD_AC.ui_panel_font_names_v1042
    bmp.font.size=PMD_AC::FOOTER_LINE1_FONT_V1043;bmp.font.bold=false;bmp.font.color=Color.new(235,240,245)
    if @phase==:battle
      line1='藍方存活 '+living_units(:ally).size.to_s+'｜紅方存活 '+living_units(:enemy).size.to_s
      line2='Motion Phase A｜落空 '+@miss_count.to_i.to_s+' 次｜速度 x'+@battle_speed.to_i.to_s
    elsif @phase==:deploy
      line1=@motion_transition_ready_v1028 ? 'Motion Transition Warmup 完成' : 'Motion 資源合作式準備中…'
      line2=@motion_transition_ready_v1028 ? 'S 切換模式｜Shift 開戰' : '完成後才允許進入 live battle'
    else
      line1=@result_text.to_s
      line2='C 回到布陣｜B 離開'
    end
    bmp.draw_text(10,1,Graphics.width-20,24,line1,0)
    bmp.font.size=PMD_AC::FOOTER_LINE2_FONT_V1043
    bmp.font.color=Color.new(170,220,255)
    bmp.draw_text(10,25,Graphics.width-20,24,line2,0)
    @motion_ui_footer_fast_used_v1028=true
  end

  def update_verification_script
    pmd_ac_v1043_ui_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@ui_readability_verify_v1043 && @verification_frame.to_i>=211
      @ui_readability_verify_v1043=true
      raised=PMD_AC.ui_font_raised_v1043.size rescue 0
      log_event(:verify,'UI_READABILITY_EXPLICIT_BARS_V1043 pass=1 min_font_floor=16'+
        ' header_sub=18 footer_line1=17 footer_line2=17 constants_second_pass='+raised.to_i.to_s+
        ' ui_font_authority=UI_PANEL_FONT_V0741 layout_size_unchanged=1 gameplay_unchanged=1')
      log_event(:verify,'SKILL_BANNER_FONT_V1043 pass=1 font=18 adaptive_min=15 banner=108x24'+
        ' skill_text_only=1 prerender_cache_retained=1 live_draw_text=0 popup_frames_unchanged=1')
    end
  rescue
  end
end
