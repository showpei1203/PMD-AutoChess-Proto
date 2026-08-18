#==============================================================================
# ■ PMD AutoChess - Target Mark Shadow Fade v1.05.10
#==============================================================================
# 【用途】
# 1. 將技能對象腳底的 target mark，從 v1.05.4 以來的四角框樣式，改成更接近
#    「腳底影子」的扁橢圓形狀。
# 2. 外圈使用多層透明度遞減，形成往外漸隱的 shadow fade；內圈保留技能屬性顏色，
#    玩家仍能一眼辨識這次技能的 type / 影響對象。
# 3. 不改變 skill focus cue 的邏輯、存在時間、可見數量、目標選取、Damage / AI /
#    Energy / Attack Wait / Spatial 等任何 Frozen Combat Core 權威。
#
# 【設計原則】
# - 使用者要求：「技能對象腳底的 mark，改為像影子那樣的形狀，並且往外漸隱」。
# - 因此本版只處理 bitmap 繪製樣式，不更改 cue timing，也不把 mark 做成過亮的實心圓。
# - 內圈：type tint；外圈：柔和陰影 / 漸隱，避免像準心或硬框。
# - impact=true 時略亮、略大；context target 時略淡、略扁。
#
# 【主要設定】
# TARGET_MARK_SHADOW_OUTER_ALPHA_V10510
#   外層陰影最大透明度。
# TARGET_MARK_COLOR_ALPHA_V10510
#   內圈 type 色透明度。
# TARGET_MARK_IMPACT_BOOST_V10510
#   impact hit 時的亮度加成。
#
# 【事件／操作】
# 無。NORMAL battle 自動生效。
#
# 【實際範例】
# - 皮卡丘使用電擊，目標腳底不再出現四個角，而是出現扁平的電系色陰影橢圓；
#   外圈柔和淡出，較像站位陰影上的戰術提示。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_TargetMarkShadowFade_v10510']=true

module PMD_AC
  TARGET_MARK_SHADOW_OUTER_ALPHA_V10510 = 92
  TARGET_MARK_COLOR_ALPHA_V10510 = 152
  TARGET_MARK_IMPACT_BOOST_V10510 = 28
end

class Scene_PMD_AutoChess
  def skill_focus_shadow_row_v10510(bitmap,cx,cy,rx,ry,color)
    return if bitmap==nil || rx<=0 || ry<=0
    y=-ry
    while y<=ry
      ratio = 1.0 - (y.abs.to_f / [ry,1].max.to_f)
      ratio = 0.0 if ratio < 0.0
      span = (rx * Math.sqrt(ratio)).to_i
      span = 0 if span < 0
      if span > 0
        x0 = cx - span
        w = span * 2 + 1
        bitmap.fill_rect(x0, cy + y, w, 1, color)
      end
      y += 1
    end
  rescue
  end

  def skill_focus_draw_shadow_oval_v10510(bitmap,cx,cy,rx,ry,base_color,impact=false)
    return if bitmap==nil
    outer = PMD_AC::TARGET_MARK_SHADOW_OUTER_ALPHA_V10510
    inner = PMD_AC::TARGET_MARK_COLOR_ALPHA_V10510
    inner += PMD_AC::TARGET_MARK_IMPACT_BOOST_V10510 if impact
    inner = 255 if inner > 255

    # outer fade shadow: 由外到內遞減，形狀接近腳底影子
    skill_focus_shadow_row_v10510(bitmap,cx,cy,rx+4,ry+2,Color.new(0,0,0,(outer*0.38).to_i))
    skill_focus_shadow_row_v10510(bitmap,cx,cy,rx+3,ry+1,Color.new(0,0,0,(outer*0.62).to_i))
    skill_focus_shadow_row_v10510(bitmap,cx,cy,rx+2,ry+1,Color.new(0,0,0,outer))

    # colored soft body
    skill_focus_shadow_row_v10510(bitmap,cx,cy,rx+1,ry,Color.new(base_color.red,base_color.green,base_color.blue,(inner*0.48).to_i))
    skill_focus_shadow_row_v10510(bitmap,cx,cy,rx,ry,Color.new(base_color.red,base_color.green,base_color.blue,(inner*0.78).to_i))
    skill_focus_shadow_row_v10510(bitmap,cx,cy,[rx-2,1].max,[ry-1,1].max,Color.new(base_color.red,base_color.green,base_color.blue,inner))

    # center subtle highlight，避免整塊太死黑
    skill_focus_shadow_row_v10510(bitmap,cx,cy,[rx-5,1].max,[ry-2,1].max,Color.new(255,255,255,impact ? 46 : 28))
  rescue
  end

  # v1.05.4 的四角準心改為扁平 shadow-like 橢圓；只改 bitmap 樣式。
  def skill_focus_draw_target_v1054(sp,type,impact=false)
    return if sp==nil || sp.bitmap==nil
    b=sp.bitmap
    b.clear
    c=skill_focus_color_v1054(type,impact ? 255 : 220)
    cx=b.width/2
    cy=impact ? (b.height/2) : (b.height/2 + 1)
    rx=impact ? [b.width/2 - 4, 8].max : [b.width/2 - 5, 7].max
    ry=impact ? [b.height/2 - 4, 3].max : [b.height/2 - 5, 2].max
    skill_focus_draw_shadow_oval_v10510(b,cx,cy,rx,ry,c,impact)
  rescue
  end
end
