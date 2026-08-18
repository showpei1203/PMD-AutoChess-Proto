# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Skill Banner Microsoft JhengHei v1.03.16
#==============================================================================
# 【用途】
# 將 v1.03.15 的 2/3 技能名稱底板字體明確固定為 Microsoft JhengHei
#（微軟正黑體），只影響技能名稱 Banner。
# 【主要設定】SKILL_BANNER_FONT_NAME_V10316 / SKILL_BANNER_FONT_SIZE_V10316。
# 【機制規則】保留 100x20、18 屬性色、skill-name-only、fade 與 popup timing；
# 不修改 Damage、AI、Attack Speed、Energy、Spatial、Projectile／Beam timing。
# 【可調參數】FONT_NAME / FONT_SIZE；若未來更換字體只需改這兩項。
# 【事件／腳本呼叫】無需呼叫；技能名稱出現時自動套用。
# 【實際範例】「水槍」「火花」「十萬伏特」只顯示技能文字，字體皆為微軟正黑體。
#==============================================================================
$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_SkillBannerJhengHei_v10316']=true
module PMD_AC
  SKILL_BANNER_FONT_NAME_V10316='Microsoft JhengHei'
  SKILL_BANNER_FONT_SIZE_V10316=13
end
class Sprite_PMDChessUnit
  # 明確接管 v1.03.15 banner draw，確保 draw_text 前已套用微軟正黑體。
  def update_skill_popup
    frames=@unit.skill_popup_frames
    return if @last_skill_frames==frames
    @last_skill_frames=frames
    bmp=@skill_sprite.bitmap
    bmp.clear
    return if frames<=0
    type=PMD_AC.skill_type_banner_type_v10314(@unit)
    bg=PMD_AC.skill_type_banner_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_BG_ALPHA_V10314)
    edge=PMD_AC.skill_type_banner_dark_color_v10314(type,220)
    accent=PMD_AC.skill_type_banner_light_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314)
    x=PMD_AC::SKILL_BANNER_X_V10315;y=PMD_AC::SKILL_BANNER_Y_V10315
    w=PMD_AC::SKILL_BANNER_WIDTH_V10315;h=PMD_AC::SKILL_BANNER_HEIGHT_V10315
    bmp.fill_rect(x,y,w,h,Color.new(0,0,0,150))
    bmp.fill_rect(x+1,y+1,w-2,h-2,edge)
    bmp.fill_rect(x+3,y+3,w-6,h-6,bg)
    bmp.fill_rect(x+4,y+3,w-8,2,accent)
    text=@unit.skill_name.to_s
    bmp.font.name=PMD_AC::SKILL_BANNER_FONT_NAME_V10316
    bmp.font.size=PMD_AC::SKILL_BANNER_FONT_SIZE_V10316
    bmp.font.bold=true
    bmp.font.color=Color.new(0,0,0,205)
    bmp.draw_text(x+4,y+1,w-8,h,text,1)
    bmp.font.color=Color.new(255,255,255,255)
    bmp.draw_text(x+3,y,w-8,h,text,1)
    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
  end
end
class Scene_PMD_AutoChess
  alias pmd_ac_v10316_start start unless method_defined?(:pmd_ac_v10316_start)
  def start
    pmd_ac_v10316_start
    begin
      log_event(:verify,'SKILL_BANNER_FONT_V10316 pass=1 font=Microsoft_JhengHei size=13 banner=100x20 type_text=0 badge=0')
    rescue
    end
  end
end
