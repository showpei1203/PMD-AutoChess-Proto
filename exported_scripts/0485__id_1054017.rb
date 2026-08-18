# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Batch IX Visual Harness Performance Isolation Load Fix v1.04.17
#==============================================================================
# 【用途】
# 修正 v1.04.16「Batch IX Visual Harness Performance Isolation」在 RGSS2 載入階段
# 發生的 NameError。v1.04.16 第 50 行原本要保存 v1.02.3 的
# motion_perf_capture_active_v1023?，但 alias 目標誤寫成沒有問號的
# motion_perf_capture_active_v1023，導致 Scene_PMD_AutoChess 類別定義當場中止。
# 本層只建立載入相容別名，不修改 v1.04.16 舊 payload，也不改任何正式戰鬥規則。
#
# 【主要設定】
# - 載入位置：必須位於 v1.04.16 Performance Isolation 腳本之前。
# - 若 motion_perf_capture_active_v1023 已存在，則不重複建立。
# - 相容方法直接 alias-copy 自既有 motion_perf_capture_active_v1023?。
#
# 【機制規則】
# 1. Ruby alias 在建立當下保存既有 method entry，因此後續 v1.04.16 再覆寫
#    motion_perf_capture_active_v1023? 時，相容別名仍保留原 v1.02.3 capture gate。
# 2. v1.04.16 隨後可安全執行：
#      alias pmd_ac_v10416_motion_perf_capture_active_v1023 motion_perf_capture_active_v1023
# 3. Harness active 期間仍由 v1.04.16 正式 override 關閉 Performance capture；
#    Harness 結束後仍呼叫保存的原 gate，沒有改 50ms threshold。
# 4. 不修改 Damage / AI / Attack Speed / Energy / logical x/y / velocity /
#    action_timer / Hitstop / Hurt / Faint / Projectile / Zone / Skill Banner。
#
# 【可調參數】
# 無。這是單一 NameError 載入相容修正，不提供 gameplay 或 profiler tuning。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。正常進入 PMD Motion verifier 即自動生效。
#
# 【實際範例】
# v1.04.16：
#   NameError: undefined method `motion_perf_capture_active_v1023' for class
#   `Scene_PMD_AutoChess'
# v1.04.17：
#   先把既有 motion_perf_capture_active_v1023? alias-copy 成相容舊名，
#   再載入 v1.04.16，Harness Performance Isolation 可正常啟動。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_BatchIXVisualHarness_PerformanceIsolationLoadFix_v10417']=true

class Scene_PMD_AutoChess
  unless method_defined?(:motion_perf_capture_active_v1023)
    alias motion_perf_capture_active_v1023 motion_perf_capture_active_v1023? unless method_defined?(:motion_perf_capture_active_v1023)
  end
end
