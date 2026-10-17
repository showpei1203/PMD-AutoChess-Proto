# G2.0 三物種自主生態原型 | 2026-10-17

**狀態：程式候選，Surface F6 實機待驗收。** G1.2.1 素材錨點掃描工具由使用者回報「驗收 OK」，但尚未提供 CSV/JSON 的具體 PASS/REVIEW/ERROR 計數；此處不宣稱全部 453 個樣本與八方向已校準。

## 範圍
- 獨立 Godot 場景 `scenes/ecology_lab.tscn`，不修改正式 `project.godot`、G1 三隻展示、151 圖鑑巡覽、腳點校準場。
- 皮卡丘 #025 = CURIOUS（活躍、巡遊幅度大）；耿鬼 #094 = PROWL（探索／觀察）；卡比獸 #143 = ANCHOR（低速、常休息）。**這些都是第一版設計偏好，不代表官方設定或實際機器學習心智。**
- 共用一個可重現的 0.1 秒生態決策時鐘，單次物理幀至多補算四步。五種狀態：IDLE、ROAM、OBSERVE、RETURN、REST，每種動作都有終止條件。
- 角色本體使用 PMDCollab 本地 `Idle`、`Walk`，優先沿用先前的逐格 `get_frame_alignment()` PMD Shadow 座標；沒有原生 Shadow 時仍會使用 ALPHA 底部備援，飛行／跳躍仍需視覺驗收。
- 使用種子固定的 `RandomNumberGenerator`，R 重置相同種子；N 更換種子。觀察附近同伴使用 tick 開始前的座標快照，減少迭代順序影響。
- 角色只是自發探索與休息的**情境示範**；尚無觸碰避障、真正視線遮擋、地形導航、戰鬥技能、攻擊命中、個體長期記憶。

## Surface 驗收
1. Godot / GitHub Desktop 停止執行並關閉編輯器，Fetch/Pull `planning/pokemon-living-world-godot`。
2. 雙擊 `RUN_G20_TESTS_WINDOWS.bat`，觀察所有 Python 測試通過（包含新的 9 項 source contract）；這不等於 Godot 解析通過。
3. Godot 左下角打開 `scenes/ecology_lab.tscn`，按 F6。確認三隻角色都顯示、有動作、五種 state 在幾十秒內可切換，沒有紅色 parser errors。
4. `Space` 暫停、`R` 相同種子重置、`N` 換種子、`1/2/3` 選取寶可夢、`D` 顯示路徑和局部領域。
5. 觀察 1 分鐘：皮卡丘移動範圍大、耿鬼探索／觀察較多、卡比獸活動幅度小且常休息；切換時腳點不應突然上跳。記錄 FPS、警告、角色消失／飛離框等異常。
6. 預設 F5 仍跑 G1 三物種動畫場，校準 `scenes/calibration_lab.tscn`、圖鑑 `scenes/roster_lab.tscn` 應保持未回歸。

## 已知限制 / 下一 Gate
- G2.0 為最小可行的生態迴圈，未正式驗收前不宣稱「151 物種已有自主 AI」。
- G2.1 下一階段：加入共享 SpeciesProfile 資料表、以 PMD BodyCenter 輔助視覺座標、局部障礙／接近回避，以及每隻個體的簡單習性與記憶。
- 切勿把完整原始 Pokémon/PMD PNG、下載資源或作者版權素材推送到公開 GitHub；資料留在 `data/raw/pmdcollab/`。候選 ZIP 不含原始圖片。
