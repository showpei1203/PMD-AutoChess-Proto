# G1.2.1 ｜PMD 自動腳點與原生陰影座標修正 ｜ 2026-10-17

**Status:** CODE CANDIDATE / 74 OFFLINE TESTS PASS / SURFACE GODOT F6 PENDING.

## 症狀與直接原因
舊版 `scripts/lab/calibration_lab.gd::_align_sprite()` 將 
`GROUND + foot_shift - Vector2(0, frame_height * visual_scale * 0.5)`
用作精靈定位。這等同把 **frame 的最下緣**硬貼地面。若 PNG 下方有較大透明留白，實際角色不透明像素就會留在地面上方，巨大體型（例如 #130 暴鯉龍）或動作使用不同尺寸 frame 更明顯；這是程式設計缺陷，不代表下載素材壞掉。

## PMD 正式來源規格
PMDCollab Sprite Format 說明同一動作由 `Anim.png`、`Offsets.png`、`Shadow.png` 構成。`-Shadow.png` 的**白色像素為陰影中心**，其中紅、綠、藍標記是陰影尺寸，不是站立座標。`-Offsets.png` 的綠色像素標記身體中心，其餘標記部位，並不是腳底。正確作法需要用這些原生錨點與圖片，而不只看 frame 長寬。
來源：https://wiki.pmdo.pmdcollab.org/PMD_Sprite_Format
其他編輯指南：https://wiki.pmdo.pmdcollab.org/Sprite_Tool

## v0.3.6 修正策略
1. `pmd_sprite_source.gd` 的 `get_frame_alignment(action,row,index)` 讀取已匯入的實際 `-Anim.png` 與 `-Shadow.png`，遵循 `CopyOf` 指向來源動作。用逐格的白色陰影標記當 **ground_point**，動畫的物件高度與跳躍相對於地面不會被 frame 長度改寫。
2. 若 `-Shadow.png` 無可辨識白色標記，使用 `-Anim.png` **不透明像素最底行**作為視覺回退（`ALPHA_BOTTOM_FALLBACK`）；空 frame 才退回原 frame 邊界。**飛行、跳躍類動畫使用 alpha 底部可能抹平原始高度差，故此類 fallback 必須人工確認**。不把本次動作回退誤認為完整物理座標校準。
3. 動畫各個 frame 的參考點依 `AnimData.xml` 的 `FrameWidth` / `FrameHeight` 裁切，而不是整張 Sheet 或最大 Frame。正規化時：`sprite.position = GROUND + foot_shift + (frame_size/2 - measured_anchor) * scale`。
4. 只分析當前顯示角色的動作與 frame，按動作來源、方向與 frame 做快取，避免每幀重新掃描。切換物種會清空。
5. 校準場快捷鍵 **N** 切換 `NATIVE (Shadow→Alpha 回退)` / `ALPHA` / `FRAME (舊版)`，**Z/X** 尺寸、**↑↓ J/L** 人工微調、**S** 保存本機草稿 v2，不改已驗收的展示與巡覽場。
6. 青綠色框線標示實際的不透明像素範圍；畫面顯示 `PMD_SHADOW_CENTER` / `ALPHA_BOTTOM_FALLBACK` / `EMPTY_FRAME_FALLBACK`，方便找出有問題的物種與動作。

## 151 隻自動實物素材檢查（不需額外 Python 套件）
在 Surface 專案根目錄執行 `RUN_G12_ANCHOR_AUDIT_WINDOWS.bat`，它使用 Python 標準函式庫，逐隻讀取本機 001–151 號的 Idle/Walk/Attack 動作 `AnimData.xml`、首格 `-Anim.png` 和 `-Shadow.png`，計算相對於 Frame 底部的實際位置差。

產物：
- `reports/pmd_anchor_audit.csv`：依原本錯位距離遞減排序，欄含 species/action/frame_height/alpha_bottom/native_shadow_y/delta/method/status。
- `reports/pmd_anchor_audit.json`：同樣數值與 PASS / REVIEW / UNAVAILABLE / ERROR 計數。

**解讀：** `PASS` 僅代表該筆找到原生陰影白色定位點，並非目視遊戲已通過；`REVIEW` 表示退到 alpha pixels，飛行物種特別需要人工看；`ERROR` 則是來源 XML 或 PNG 資料問題，程式 exit code 2。此工具**只取 raw direction row 0 的 frame 0**，不能取代每格完整八方向驗收，也不會將受版權保護的 PNG 複製至報表。

## 本輪驗證與限制
- Python source + reference mirror + 真正 PNG 位元組解碼的假資料整合測試，**74/74 PASS**。
- 合成的 80x120 大 frame，角色只占 y18–51：alpha anchor y=51，而不是 frame bottom y=120；同一物件 native Shadow 白色座標 y105.5 時優先使用該值。另一合成測試檢查 sprite 在空中跳躍時地面原生基準不變。
- 上述 74 項測試均在編譯環境執行。**目前無法直接讀取使用者 Surface 本機 151 隻 PNG 或啟動其 Godot 編輯器**。實際暴鯉龍的像素位置、Shadow 白點可用性、八方向順序、動畫偏移尚需使用者在 Surface 執行報表/F6 確認；不聲稱全部 151 隻已校正。
- 本版只更新 `calibration_lab.gd`、共用讀取器新增查詢 API 和獨立診斷工具，不改 G1 已驗收的 `animation_lab.tscn`、`roster_lab.tscn`、`project.godot` 入口。
- 私有受版權圖片維持 `data/raw/pmdcollab` 並受 `.gitignore` 排除。

## Surface 三分鐘回歸
1. 關閉 Godot，在 GitHub Desktop 切到 `planning/pokemon-living-world-godot`，Fetch / Pull，**不要還原舊 stash 蓋回已修正版**。
2. 先執行 `RUN_G12_ANCHOR_AUDIT_WINDOWS.bat`，看 `reports/pmd_anchor_audit.csv` 最上方 20 筆，記錄 #130 的 Idle/Walk/Attack；若 `ERROR` 非零保留 JSON/CSV 訊息。
3. Godot 開 `scenes/calibration_lab.tscn` 按 F6；直接按 **G** 一鍵跳到 #130 暴鯉龍（也可用 Q/E 慢慢換），不用更動原始碼。
4. 在暴鯉龍切換 **N** 比較 `NATIVE`、`ALPHA`、`FRAME`。確認 `NATIVE(PMD_SHADOW_CENTER)` 不會隨 Idle / Walk / Attack 切換而突然跳位，且陰影中心落在黃色基準。若顯示 `ALPHA_BOTTOM_FALLBACK`，應檢查浮空高度是否被壓低。
5. **F5** 再跑原本三隻動畫（應不受影響）；**F6** 另測巡覽場 `roster_lab.tscn`，確保回歸。

### 後續優化
P1：可從 PMD `Offsets.png` 讀取身體中心和部位，用於身體軀幹、投射物發射點、武器、受擊特效，而不是當地面腳點；運動邏輯還需要自己的實體碰撞半徑/腳底標準。後續分別驗收逐格 `Shadow`、方向映射與高度語意，再升級正式生態 AI。
