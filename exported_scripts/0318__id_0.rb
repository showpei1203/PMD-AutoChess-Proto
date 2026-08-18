# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Stalemate Safety Net Hotfix v0.89.1
# 分類：v0.89 緊急相容修正／方法名稱修正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 v0.89 Battle Stalemate Safety Net 的方法名稱不一致問題。
# v0.89 內部真正定義的是：
#   stall_progress_event_v089?(category, message)
# 但 Scene_PMD_AutoChess#log_event 誤呼叫：
#   stalemate_progress_event_v089?(category, message)
# 因此一進入 Scene_PMD_AutoChess，只要任何 LOG 事件發生，就會觸發 NoMethodError。
#
# 本 Hotfix 不直接修改 v0.89 原腳本，而是在 Main 前新增相容方法，讓舊腳本保持
# byte-for-byte 不變，方便後續版本追蹤與回歸驗證。
#==============================================================================
# 【修正內容】
# 1. 新增 Scene_PMD_AutoChess#stalemate_progress_event_v089?
#    直接轉送到原本正確存在的 stall_progress_event_v089?。
# 2. 戰鬥標頭顯示更新為 v0.89.1。
# 3. Battle Verification Log 標頭更新為 v0.89.1。
# 4. STALEMATE_SAFETY_V089 驗證開始時額外寫入：
#      STALEMATE_HOTFIX_V0891 pass=1
#    確認兩個方法都存在且相容轉送正常。
#==============================================================================
# 【事件／腳本使用方式】
# 不需要事件頁或 Script Call，載入後自動生效。
#
# 若要手動查詢：
#   $scene.respond_to?(:stalemate_progress_event_v089?)
# 正常應回傳 true。
#==============================================================================
# 【驗證方式】
# 1. 直接進入 PMD AutoChess 戰鬥，不應再出現：
#      undefined method `stalemate_progress_event_v089?'
# 2. 切換至 STALEMATE_SAFETY_V089 後執行 Shift，LOG 應包含：
#      STALEMATE_HOTFIX_V0891 pass=1
#      STALEMATE_MANIFEST_V089 pass=1
#      TRUE_FOOT_BAR_V0884 pass=1
#      STALL_WATCH_POLICY_V089 pass=1
#      STALL_RESOLVE_POLICY_V089 pass=1
#      STALL_PROGRESS_RESET_V089 pass=1
#      STALEMATE_CARRY_V089 pass=1
#      STALEMATE_SAFETY_V089 pass=1
#      VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
# 【不修改內容】
# - 不改 v0.89 Stalemate Watch / Resolve 門檻與 Energy 數值。
# - 不改 v0.88.4 True Foot Bar。
# - 不改 v0.88.3 Audio / Ranged Stagger / Kiting。
# - 不改 v0.60.2 Multi-hit choreography。
# - 不改 Damage / Accuracy / Evasion / Projectile Tracking。
# - 不改 Pokémon 數值、成長、技能、招募、RPG Encounter。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0891 = '0.89.1'
end

class Scene_PMD_AutoChess
  # v0.89 typo compatibility bridge.
  def stalemate_progress_event_v089?(category, message)
    stall_progress_event_v089?(category, message)
  end

  alias pmd_ac_v0891_start start unless method_defined?(:pmd_ac_v0891_start)
  alias pmd_ac_v0891_refresh_header refresh_header unless method_defined?(:pmd_ac_v0891_refresh_header)
  alias pmd_ac_v0891_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0891_prepare_verification_battle)

  def start
    pmd_ac_v0891_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.89.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.89.1 stalemate_progress_method_bridge=1 '+
      'v0.89_logic=unchanged true_foot=v0.88.4 combat_feel=v0.88.3')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0891_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.89.1',1)
  end

  def prepare_verification_battle
    pmd_ac_v0891_prepare_verification_battle
    if respond_to?(:stalemate_safety_v089?) && stalemate_safety_v089?
      pass=respond_to?(:stall_progress_event_v089?) &&
        respond_to?(:stalemate_progress_event_v089?) &&
        (stalemate_progress_event_v089?(:damage,'test')==true) &&
        (stalemate_progress_event_v089?(:presentation,'test')==false)
      pmd_ac_v089_log_event(:verify,
        'STALEMATE_HOTFIX_V0891 pass='+(pass ? '1':'0')+
        ' method_bridge=1 v0.89_logic=unchanged')
      @stalemate_v089_failed=true unless pass
    end
  end
end
