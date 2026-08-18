#==============================================================================
# PMD AutoChess Gameplay Review Verifier Mode Hotfix v0.99.8.1
#------------------------------------------------------------------------------
# 【用途】
# 修正 v0.99.8 已建立 GAMEPLAY_REVIEW_KANTO_V0998 驗證標籤與驗證邏輯，
# 但漏將 :gameplay_review_kanto_v0998 插入 VERIFICATION_MODES 的問題。
#
# 【問題症狀】
# - 戰前布陣畫面即使反覆按 S，也無法切到 GAMEPLAY_REVIEW_KANTO_V0998。
# - 直接按 Shift 只會進入 NORMAL 一般戰鬥，因此 LOG 不會出現 Kanto verifier。
#
# 【本版正式規則】
# - 進入布陣畫面預設仍為 NORMAL。
# - 按 S 一次：GAMEPLAY_REVIEW_KANTO_V0998。
# - 再按 S：依既有舊驗證模式繼續輪播。
# - v0.99.7 的 MOVEPOOL_PRODUCTION_V0997 從輪播移除，因 v0.99.8 已完成其驗收。
#
# 【戰鬥機制影響】
# 無。只修正驗證模式註冊、版本顯示與 LOG 標題。
# Frozen Combat Core、Species Profile、傷害公式、AI、Move Runtime 均不修改。
#
# 【操作範例】
# 1. 開啟 Game.exe 進入測試戰鬥布陣畫面。
# 2. 按 S 一次，畫面應顯示 GAMEPLAY_REVIEW_KANTO_V0998。
# 3. 按 Shift 開戰並等待 verifier 自動完成。
# 4. LOG 最後必須出現 VERIFY_FINISHED_BATTLE_RESUME pass=1。
#==============================================================================

module PMD_AC
  old_modes = VERIFICATION_MODES.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal, :gameplay_review_kanto_v0998] + old_modes.reject { |x|
    x == :normal || x == :gameplay_review_kanto_v0998 || x == :movepool_production_v0997
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v09981_start start unless method_defined?(:pmd_ac_v09981_start)
  alias pmd_ac_v09981_refresh_header refresh_header unless method_defined?(:pmd_ac_v09981_refresh_header)

  def start
    pmd_ac_v09981_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, 'rb') { |f| f.read }
        text.sub!(/PMD AutoChess Proto v0\.99\.8 Battle Verification Log/,
                  'PMD AutoChess Proto v0.99.8.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE, 'wb') { |f| f.write(text) }
      end
    rescue
    end
    log_event(:gameplay_review,
      'PATCH v0.99.8.1 verifier_mode_registration=1 s_once=GAMEPLAY_REVIEW_KANTO_V0998 combat_core_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09981_refresh_header
    return if @header_sprite == nil || @header_sprite.bitmap == nil
    bmp = @header_sprite.bitmap
    bmp.fill_rect(0, 0, Graphics.width, 28, Color.new(0, 0, 0, 180))
    pmd_ac_v074_font(bmp)
    bmp.font.size = PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold = true
    bmp.font.color = Color.new(255, 255, 255)
    bmp.draw_text(16, 1, Graphics.width - 32, 30, 'PMD 自走棋原型 v0.99.8.1', 1)
  end
end
