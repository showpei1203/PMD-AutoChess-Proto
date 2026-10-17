# Pokémon Living World | Append-only Handoff History

## 2026-10-17 G0 / G1 accepted baselines
Godot 4.7.2; user verified 151/151 PMDCollab ZIP sources, 3/3 G1 animated sprites and successful G1.1 gallery controls. G1.2.1 anchor scan process user-accepted, actual full 151 anchor details not independently checked. Existing scenes preserved.

## 2026-10-17 G2.0 + G2.0.1 failure
Surface user reported little movement, no apparent change on N/D; then G2.0.1 tick not increasing, M/D/N no effect. **G2 acceptance FAIL / BLOCKED**. Root cause unknown, no file-based runtime logs existed.

## 2026-10-17 G2.0.2 v0.3.9 diagnostic candidate
New independent CanvasLayer observer, fixed `reports/PLW_G2_RUNTIME_LAST.log`, keyboard and clickable diagnostics, Windows open + zip collector, seven regression tests. **98/98 offline PASS**; Surface F6 NOT YET VERIFIED. F5 still launches accepted G1 main; G2 requires opening `scenes/ecology_lab.tscn` and F6. No copyrighted raw sprite art touched or added. Next: user attaches `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`; diagnose root cause and update both GitHub and Drive handoffs before further feature work.

2026-10-17 G2.1 v0.4.0 候選：依上次 Surface 真實 LOG，皮卡丘673px／耿鬼367px、卡比獸0px，新增完全獨立 ecology_behavior_lab.gd/tscn，#143 最大18秒未散步則自動短走，保留慢速與小半徑；新增探索次數、倒數與移動向量箭頭，新 G21 獨立 LOG／ZIP；108/108 Python 離線測試 PASS，Godot Surface F6 PENDING。舊 G1/G2.0.2 不更動；見 docs/G21_BOUNDED_BEHAVIOUR_20261017.md。

2026-10-17 G2.1 Surface LOG followup: user-provided `a450cf80889287a00cdc8f275507dfc0efa83479f9fc9dc38870ca1951c51fe1` (95 lines, 33sec), Snorlax automatic ROAM ~19sec, moved 41.6px then 3+M further to 80px; Pikachu 785px, Gengar 441px. G2.1 bounded-stroll/motion PASS by observed runtime, but animation facing and native looping Idle contradicted species personality.
2026-10-17 G2.2 v0.4.1 CANDIDATE: new isolated scene `ecology_animation_lab.tscn`, visual policy with PMD native 8-direction mapping, standing Walk frame0, intermittent nonlooping Idle, individualized speeds and preemption, updated per-row shadow/feet anchoring; 122/122 synthetic/offline tests PASS, Godot F6 PENDING. Full ZIP/hash in reports/release notes. No raw PMD art; G2.1 sealed source unchanged. Drive/GitHub Handoff, Issue #15 updated when released.

2026-10-17 G2.2 Handoff correction: archive originally included stale G2.1 handoff as latest due to header mismatch; replaced status and inserted CURRENT G2.2 summary, marked previous sections historical. No code changes, 122/122 offline tests remain PASS, full corrected ZIP supersedes initial archive.

2026-10-17 G2.2.1 v0.4.1.1 解析器修正：使用者 Surface 截圖 ecology_animation_diagnostics.gd:104 roams／since_roam 未宣告、無法載入腳本；同時目前打開 ecology_lab.tscn 而不是新 ecology_animation_lab.tscn。G2.2 v0.4.1 實機 FAIL。修正兩變數取值、畫面版號、telemetry key；新增3個 parser 回歸測試，Python離線125/125 PASS；Surface Godot 4.7.2 F6 待複測。原G1/G2.1保留；全量ZIP與 logs SHA 文檔正式交付。

2026-10-17 G2.2.2 v0.4.1.2：使用者回報 G22 LOG 收集失敗、朝向／待機無變化，附檔實際為舊 G21 v0.4.0 ecology_behavior_lab LOG（約33秒）。不能證明 G22 原型已執行或其動畫演算法壞掉。收集器改為即使找不到 PLW_G22_RUNTIME_LAST.log 也輸出含 G22_MISSING_LOG_DIAGNOSIS.txt 的診斷 ZIP，明列舊版 LOG、正確雙擊開啟 G22 場景＋F6、user:// fallback，保持 GDScript 不變。新增4個 Python 回歸測試，129/129 PASS；G22 實機待驗收。

2026-10-17 G2.2.3 v0.4.1.3：使用者回報仍未改善，所附 PLW_G22_DIAGNOSTICS_TO_SHARE.zip 只含 G22_MISSING_LOG_DIAGNOSIS.txt/說明，沒有 G22 runtime log，僅偵測到 G21 與 G2.0.2 舊紀錄；無法得知 G22 場景是否實際啟動、亦不能推斷方向動畫根因。新增 RUN_G22_DIRECT_SCENE_WINDOWS.bat 和 tools/g22_direct_launch.py 直接呼叫 Godot 執行 G22 指定場景，收集 boot/console/runtime LOG，連 Godot 啟動或解析失敗也產生診斷 ZIP。新增5項離線測試，134/134 PASS，無 GDScript 功能變更，Godot Surface 驗收 PENDING。下一個 Gate：取得 reports/PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip 再依 log 修真正確元件。

2026-10-17 G2.3 v0.4.2：使用者回報 G22 Direct Launcher 實測成功，附上實際 G22 direct 日誌 ZIP（場景 ecology_animation_lab.tscn，Godot Exit 0；tick472／約48秒；皮卡丘~975px、耿鬼~790px、卡比獸~46px）。新的需求為待機 Walk 動作不再凍結且播放更慢，依物種設計不同節奏與動作組合。新設獨立 ecology_ambient_lab.tscn，繼承 G22 行為/八方向/腳點；慢速 Walk 0.26/0.17/0.09，依物種間隔穿插 Idle／安全的 Float/Pose/Nod，移動優先，原生陰影 anchor<=5px 安全檢查，缺乏圖片退回 Idle。G2.3 Python OFFLINE 146/146 PASS，Godot Surface 候選未驗收。獨立 G23 Direct Launcher 會產生 PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip，未改舊 G22/G21。詳見 G23_SPECIES_CADENCE_20261017.md。

2026-10-17 G2.3 v0.4.2 最終 GitHub/Drive 交付：本輪 zip 161 檔案（CRC PASS）Google Drive https://drive.google.com/file/d/1VYom0ipsFG0i3KCuA3jxCrv0andzO5pd/view SHA256 9a21d6afa67f5cfc9030071d509f7fad23df480cc426d3074e231360fb74ecc0；獨立場景 ecology_ambient_lab.tscn、物種慢速 Walk/偶發安全動作、G23 直接啟動/LOG，146/146 離線測試 PASS，Surface G2.3 尚待驗收。原 G2.2 實機 PASS 保留；勿混淆為 G23 PASS。GitHub/Drive handoff 更新。

2026-10-17 G2.3 真正 Surface Direct Launcher LOG 確認：使用者上傳 G23 ZIP SHA256 8b22e798ba4c2a63551d124c9ca320b2be801aca5bebe7edb5e5cc634b4c835d，ZIP CRC PASS，Godot 4.7.2 正確啟動 ecology_ambient_lab.tscn，exit 0；60秒／173行LOG／59心跳／tick583、無 Godot boot/console 錯誤。皮卡丘 STANCE Walk 0.26x + Idle偶發1次，累積1134.65px；耿鬼 STANCE Walk 0.17x + Idle1次／Float1次，423.68px；卡比獸 STANCE Walk 0.09x，160px，60秒中未觀察到微動作。G2.3 實機啟動／排程 PASS，節奏觀感及卡比獸偶發動作、151物種擴充仍待正式視覺驗收；無新程式，v0.4.2完整ZIP沿用。GitHub報告 docs/G23_SURFACE_RUNTIME_ACCEPTANCE_20261017.md；Current/History + Issue15 + Drive同步。
