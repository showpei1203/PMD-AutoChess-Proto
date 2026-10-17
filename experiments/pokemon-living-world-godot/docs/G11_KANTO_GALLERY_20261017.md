# G1.1 ｜151 寶可夢動畫巡覽場（v0.3.4）
日期：2026-10-17｜開發基準：Godot 4.7.2 Standard / GDScript。

## 當前驗收與範圍
- G0 151 PMDCollab 來源 ZIP：**Surface screenshot observed PASS (151/151, exit 0)**。
- G1 v0.3.3 皮卡丘/耿鬼/卡比獸動畫：**Surface observed PASS**。使用者確認顯示與 I/W/A/方向操作正常，Godot 0 error, 0 warning。
- G1.1 新「151 隻巡覽場」：**CODE CANDIDATE / USER SURFACE TEST PENDING**。此場景與三隻正式驗收畫面獨立，`project.godot` 主場景維持 `scenes/animation_lab.tscn` 不變。
- 目前無自主 AI、無戰鬥功能；八方向中文/方位對應及地面偏移量、陰影/尺寸比例仍未驗收。

## 新增內容
- `scenes/roster_lab.tscn` + `scripts/lab/roster_lab.gd`：獨立 Godot 場景。初始播放 #025、#094、#143 基準三隻；一次只載入目前頁面三隻。支援第 001～151 號，最後一頁只有 #151。
- `tools/pmd_roster_report.py`：以既有 `pmd_g1_preflight.examine_species` 為單一檢查核心，輸出 151 隻 Idle、Walk、Attack 的 READY/UNSUPPORTED/UNVALIDATED、CopyOf 實際動作來源、credits 狀態及失敗原因。輸出 `reports/pmd_roster_report.csv`（UTF-8 BOM，可用 Excel 開啟）與 `reports/pmd_roster_report.json`。
- `RUN_G11_ROSTER_PREFLIGHT_WINDOWS.bat`：Windows 一鍵檢查本機 151 隻。**若 FAIL > 0 會回傳 exit 2，這是預檢缺口，不代表既有 G0 ZIP 下載失敗**。
- `tests/test_g11_roster.py`：翻頁邊界、CopyOf 路徑、輸出格式與場景相容性的離線測試。

## Surface 測試操作（不需要重新下載）
1. 關閉 Godot，GitHub Desktop 切到 `planning/pokemon-living-world-godot`，按 Fetch origin → Pull origin；若遇到 Godot 自動修改導致衝突，先 Stash，不把舊修改覆蓋最新版。
2. 在專案根資料夾先執行 `RUN_G11_ROSTER_PREFLIGHT_WINDOWS.bat`。查看最後 PASS/WARN/FAIL，`reports/pmd_roster_report.csv` 和 JSON 的失敗編號；上傳/回報統計即可，**不要把原始 PNG 上傳公開 GitHub**。
3. Godot 檔案系統打開 `scenes/roster_lab.tscn`，按 **F6 執行目前場景**（不是 F5；F5 仍跑通過的三隻正式展示）。
4. `E` / `PageDown` 下一頁；`Q` / `PageUp` 上一頁；`T` 回到 025/094/143 原始基準；`1/2/3` 選取當頁角色；`I/W/A` 播放待機/行走/攻擊；`←/→` 切換來源 0–7 動作方向列；`Space` 開/關自動輪播。
5. 測頁：按 E 出現 #001～003、繼續 E 可翻到 #004～006；先在原基準 T 確認 3/3，然後測接近 #148、最後一頁 #151。
6. 觀察動畫是否卡在第一格、方向列是否缺圖、角色尺寸跳動、地面腳點/陰影是否一致。若遇錯誤，以 Godot Output `[PLW-G11]` 確認物種 ID 與錯誤字串。

## 安全與驗收門檻
- 不移動、覆寫、重新下載或提交 `data/raw/pmdcollab/` 的任何寶可夢素材。
- `G1.1 PASS` 須 Surface 實際通過：入口 F6 正常、翻頁到首尾、基準 T 回復、3 種動作、8 方向列、不出現 Godot 致命錯誤；各物種素材缺口必須呈現在報表，不能不告而別。
- 維持三隻已通過的 `scenes/animation_lab.tscn` 不變；可用 F5 隨時回到穩定版本。
- 當前開發環境無 Godot 可執行檔。Python 靜態/合成測試不能替代 Surface 的 GDScript 編譯及視覺審查。

## 下個階段
G1.2 採用巡覽報表處理缺失/繼承動作，建立物種尺寸分類、腳點位置與 8 方向列的正式對應表；G2 生態自主移動使用此動畫共用層。
