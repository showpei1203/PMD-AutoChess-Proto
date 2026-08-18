#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.31.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - bitmap_for / start / verify_v0311_compatibility / update_verification_script
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.31.1
#    RGSS2 Compatibility Fix + Recent-5 Verification Selector
#------------------------------------------------------------------------------
#  Additive patch on v0.31. Does not edit any previous script payload.
#==============================================================================
module PMD_AC
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :skill_visual_expansion,
    :skill_visual,
    :weather_visual,
    :weather,
    :accuracy_evasion
  ]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :skill_visual_expansion => "SKILL_VISUAL_EXPANSION",
    :skill_visual           => "SKILL_VISUAL",
    :weather_visual         => "WEATHER_VISUAL",
    :weather                => "WEATHER",
    :accuracy_evasion       => "ACCURACY_EVASION"
  }
end

# Ruby 1.8 / RGSS2 compatibility:
# Module#class_variable_get is not available in the target runtime used by VX.
# Reimplement the v0.31 extended trail palette with direct @@bitmaps access.
class Sprite_PMDSkillTrailV030
  class << self
    def bitmap_for(style)
      return pmd_ac_v031_bitmap_for(style) if [:fire,:water,:electric,:seed].include?(style)
      return @@bitmaps[style] if @@bitmaps[style] != nil && !@@bitmaps[style].disposed?
      rgb = case style
      when :normal; [225,220,190]
      when :grass; [95,210,95]
      when :ice,:aurora; [125,225,255]
      when :fighting; [235,150,95]
      when :poison; [180,85,220]
      when :ground,:rock; [190,145,75]
      when :flying; [170,225,255]
      when :psychic,:psychic_beam; [245,100,220]
      when :bug,:signal; [165,215,80]
      when :ghost; [135,95,200]
      when :dragon; [110,130,255]
      when :dark; [105,90,125]
      when :steel,:steel_beam; [195,210,220]
      when :fairy; [255,155,220]
      when :sound; [210,120,255]
      else; [220,235,255]
      end
      b = Bitmap.new(12,12)
      c = Color.new(rgb[0],rgb[1],rgb[2],185)
      b.fill_rect(3,3,6,6,Color.new(c.red,c.green,c.blue,65))
      b.fill_rect(4,4,4,4,c)
      @@bitmaps[style] = b
      b
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0311_start start unless method_defined?(:pmd_ac_v0311_start)
  alias pmd_ac_v0311_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0311_update_verification_script)

  def start
    pmd_ac_v0311_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE,"rb") { |f| f.read }
        text.sub!(/PMD AutoChess Proto v0\.31 Battle Verification Log/,
                  "PMD AutoChess Proto v0.31.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb") { |f| f.write(text) }
      end
    rescue
    end
    log_event(:skill_visual_expansion,
      "PATCH v0.31.1 ruby18_trail=direct_class_variable verification_modes=" +
      PMD_AC::VERIFICATION_MODES.size.to_s +
      " default=" + verification_mode_label)
  end

  def verify_v0311_compatibility
    return if @verification_done[:v0311_compatibility]
    trail_ok = false
    begin
      b = Sprite_PMDSkillTrailV030.bitmap_for(:grass)
      trail_ok = (b != nil && !b.disposed?)
    rescue
      trail_ok = false
    end
    modes_ok = PMD_AC::VERIFICATION_MODES.size == 5 &&
      PMD_AC::VERIFICATION_MODES[0] == :skill_visual_expansion &&
      PMD_AC::VERIFICATION_MODES[1] == :skill_visual &&
      PMD_AC::VERIFICATION_MODES[2] == :weather_visual &&
      PMD_AC::VERIFICATION_MODES[3] == :weather &&
      PMD_AC::VERIFICATION_MODES[4] == :accuracy_evasion
    pass = trail_ok && modes_ok
    log_event(:verify,
      "SKILL_VISUAL_EXPANSION_COMPAT pass=" + (pass ? "1" : "0") +
      " ruby18_trail=" + (trail_ok ? "1" : "0") +
      " modes=" + PMD_AC::VERIFICATION_MODES.size.to_s +
      " default=" + PMD_AC::VERIFICATION_LABELS[PMD_AC::VERIFICATION_MODES[0]].to_s)
    @verification_done[:v0311_compatibility] = true
  end

  def update_verification_script
    pmd_ac_v0311_update_verification_script
    return unless verification_mode == :skill_visual_expansion
    verify_v0311_compatibility if @verification_frame == 20
  end
end
