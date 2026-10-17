# Pokémon Living World | G2.3 v0.4.2 物種站姿／動作節奏候選

**狀態：Python 離線 146/146 PASS；Godot 4.7.2 Surface 執行尚未驗收。**

## 已完成實機驗收的上一階段

使用者回報 G2.2 動作方向和待機切換可見且操作正常，並提交 `PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip`。此次證據包含 `PLW_G22_DIRECT_LAUNCH_REPORT.txt`：`scene=res://scenes/ecology_animation_lab.tscn`、`godot_exit_code=0`、`g22_runtime_log_created=True`、`LOGGER_READY build=G2.2-v0.4.1.1`。約 48 秒，tick 到 472；皮卡丘最後 ~975px、耿鬼 ~790px、卡比獸 ~46px，自主探索與方向、待機／MICRO_IDE 事件記錄正常。這證明 G2.2 基礎呈現運作，不代表每種 PMD 動作的最佳節奏已驗收。

本次 LOG ZIP SHA256：`327bde3971df51c6ed0e6e7471c8019324fc5cca9d6c1ab033ec319b62ccd191`。不將使用者私有設備執行紀錄或 Pokémon 原始圖片寫入 GitHub。

## 本輪改動

獨立 `scenes/ecology_ambient_lab.tscn`（根節點 `EcologyAmbientLab`，含 Diagnostics），新腳本繼承原 G2.2 `ecology_animation_lab.gd`。**沒有修改 G2.2 的程式與場景**，因此仍可使用原 G22 direct launcher 比較。

- 正常不移動時改用 **真正循環播放、降低倍率的 `Walk`**，不再固定停在第一格；速度各物種不同：皮卡丘 0.26、耿鬼 0.17、卡比獸 0.09。此數值是視覺調校的首次候選，不是 Gen1 Recomp 精確複製。
- 真正 `ROAM / RETURN` 立刻使用原 G2.2 的移動方向 row 與走路速度，不修改 AI 決策、座標與物理更新。`Idle` 等偶發短動作會立即被行走中斷。
- 皮卡丘約 5～8.5 秒穿插一次短動作，優先 Idle，若安全才嘗試 Pose；耿鬼約 8～13.5 秒，以 Float／Idle／Pose 為候選；卡比獸約 18～28 秒，優先 Nod，偶爾 Idle 或保持安靜。實際是按**連續不移動時間**計，不會反覆跳動。
- 跨動畫切換腳點：只有符合「PMD 原生陰影中心存在、與 Walk 首格定位差不超過 5 px」的額外 `Float`、`Pose`、`Nod` 才能使用；缺素材或不安全則回退 `Idle`／維持慢速 Walk。保留 PMD 素材自己的浮空/跳躍意圖。
- 保留 8 方向與影格位置計算，並讓快取沿用 G2.2 的物種圖片。
- 新獨立 `PLW_G23_RUNTIME_LAST.log`、`PLW_G23_GODOT_BOOT_LAST.log`、`PLW_G23_GODOT_CONSOLE_LAST.log`，直接啟動器會產出 `reports/PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip`，即使場景無法載入也能取得錯誤。直接啟動器沿用 G22 選過的 Godot 執行檔路徑，不必再找一次。

## Surface 驗收步驟

1. GitHub Desktop，選 `planning/pokemon-living-world-godot`，Fetch/Pull，先關閉正在執行的 Godot 遊戲視窗；無需重新下載 151 隻素材。
2. 雙擊專案根目錄 **`RUN_G23_DIRECT_SCENE_WINDOWS.bat`**。會直接啟動 `scenes/ecology_ambient_lab.tscn`，不必在編輯器切分頁或按 F6。
3. **觀察 60～90 秒**：靜止時 Walk 應慢速循環，但不會每個影格重頭播放；皮卡丘比較有活力、耿鬼緩慢，卡比獸最慢。若物種缺少安全 Float/Nod/Pose 而改用 Idle 是預期回退，不應冒出紅色錯誤。移動時朝向應正確、行走速度恢復，地面定位不跳。
4. 關閉遊戲視窗，等待 CMD 顯示 `DIAGNOSTIC ZIP READY`，上傳 `reports/PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip`，如有視覺不自然另附截圖/短影片。

## 風險、未完成

- 實機尚未確認 `super._ready()` 與 `_spawn/_row_frames` 覆寫都能在 Godot 4.7.2 正常解析；離線 Python 測試只能驗證原始碼契約，不能替代 F6。
- Extra action 的安全門檻會把部分有意識的浮空動作擋掉；這是保守策略，後續可在 151 物種稽核後逐種調整。
- 151 隻完整個性表、物種尺寸/腳點/陰影、地形避障及戰鬥 AI 都不是本輪的已驗收範圍。

## 持續交付規範

此輪須留完整原始碼 ZIP、Windows BAT、Python test logs、SHA256 manifest、`docs/CURRENT_HANDOFF_PLW.md`、`docs/HANDOFF_HISTORY_PLW.md`，同步 GitHub、Drive 及 Issue #15。成功與失敗證據不得覆寫先前歷史。
