# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Boss Verifier Clock Hotfix v0.91.1
# 分類：Boss Framework／Verification Hotfix
#
# 【用途】
# 修正 v0.91 的 BOSS_FRAMEWORK_V091 驗證模式在 Shift 開始後，
# @verification_frame 沒有遞增，導致所有 f>=2 / f>=4... 的驗證永遠不執行。
#
# 【主要設定項】
# - 本補丁沒有戰鬥數值設定。
# - 只在 verification_mode == :boss_framework_v091 時每次更新增加 1 frame。
#
# 【機制規則】
# 1. NORMAL 與其他舊 Verifier 完全不碰，避免造成 double tick。
# 2. BOSS_FRAMEWORK_V091 每次 update_verification_script 先 +1 frame，
#    再交回 v0.91 原本的 verifier 執行。
# 3. 第 1 frame 額外記錄 BOSS_VERIFIER_CLOCK_V0911 pass=1，方便從 LOG 判斷
#    Hotfix 是否確實載入。
#
# 【可調參數】
# 無。若要改 Boss 驗證結束時間，請調整 v0.91 Data 的
# BOSS_FRAMEWORK_VERIFY_END_V091，而不是本補丁。
#
# 【事件／腳本呼叫方式】
# 不需要事件呼叫。
# 測試：布陣畫面切到 BOSS_FRAMEWORK_V091 後按 Shift。
#
# 【實際範例】
# 預期 LOG：
#   BOSS_VERIFIER_CLOCK_V0911 pass=1 frame=1
#   BOSS_FRAMEWORK_MANIFEST_V091 pass=1
#   ...
#   BOSS_FRAMEWORK_V091 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【注意事項】
# - RGSS2 / Ruby 1.8 相容。
# - 不使用專案禁用的舊式 instance-variable probe。
# - 不修改 v0.91 Boss Runtime 本體，舊 Script byte-for-byte 保留。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0911 = '0.91.1'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0911_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0911_update_verification_script)
  def update_verification_script
    if verification_mode==:boss_framework_v091
      @verification_frame=@verification_frame.to_i+1
      if @verification_frame==1 && !@verification_done[:v0911_clock]
        log_event(:verify,'BOSS_VERIFIER_CLOCK_V0911 pass=1 frame=1 source=hotfix')
        @verification_done[:v0911_clock]=true
      end
    end
    pmd_ac_v0911_update_verification_script
  end
end
