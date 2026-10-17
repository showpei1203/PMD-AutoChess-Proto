# Pokémon Living World | Append-only Handoff History

## 2026-10-17 G0 / G1 accepted baselines
Godot 4.7.2; user verified 151/151 PMDCollab ZIP sources, 3/3 G1 animated sprites and successful G1.1 gallery controls. G1.2.1 anchor scan process user-accepted, actual full 151 anchor details not independently checked. Existing scenes preserved.

## 2026-10-17 G2.0 + G2.0.1 failure
Surface user reported little movement, no apparent change on N/D; then G2.0.1 tick not increasing, M/D/N no effect. **G2 acceptance FAIL / BLOCKED**. Root cause unknown, no file-based runtime logs existed.

## 2026-10-17 G2.0.2 v0.3.9 diagnostic candidate
New independent CanvasLayer observer, fixed `reports/PLW_G2_RUNTIME_LAST.log`, keyboard and clickable diagnostics, Windows open + zip collector, seven regression tests. **98/98 offline PASS**; Surface F6 NOT YET VERIFIED. F5 still launches accepted G1 main; G2 requires opening `scenes/ecology_lab.tscn` and F6. No copyrighted raw sprite art touched or added. Next: user attaches `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`; diagnose root cause and update both GitHub and Drive handoffs before further feature work.

2026-10-17 v0.3.9 連線恢復交付核對：GitHub 程式和 CURRENT_HANDOFF/HISTORY 已存在；完整 107 檔 ZIP 成功補傳 Google Drive（https://drive.google.com/file/d/1X5ZbpBvCPVTZqYrWzNFrtxBA1BADI6f7/view），SHA256 42aa22571846afb0b733c31ddcde05523579fe3cbd56b2bee03f62fbf35ac522；Issue #15 同步；G2 Surface LOG 尚未取得，狀態仍 FAIL/PENDING，不得宣稱修復完成。

2026-10-17 G2.0.2 Surface LOG 收集診斷：使用者截圖中 Godot 活動分頁 calibration_lab.tscn、場景樹 CalibrationLab，ecology_lab.tscn 僅在檔案系統反白選取；CMD 的 LOG NOT FOUND / exit 2 因 G2 診斷場景未被確認啟動，不能視為 logger 壞掉。指導雙擊 ecology_lab.tscn、確認 EcologyLab > Diagnostics，F6 後再收集 reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip。G2 驗收 PENDING，程式未更動。

2026-10-17 v0.3.9 G2 Surface 正式 LOG 驗收：使用者上傳 PLW_G2_DIAGNOSTICS_TO_SHARE.zip（SHA256 f63900f4a76bdef98724818044aa355e4508c6b6ed654b47ae00a6a6b7ae9ba6），Godot LOGGER_READY 確認 scenes/ecology_lab.tscn，171 行／約60秒／58 心跳／6 鍵盤事件；tick 4→333，UI 13→3434，physics 28→3452，N 種子 20261017→20365746，皮卡丘約673px／耿鬼約367px，卡比獸0px（未見ROAM），未記錄按鈕回呼。診斷工具 PASS、自主生態 2/3 PARTIAL PASS，完整 G2 仍待驗收；程式未修改，沿用 v0.3.9 ZIP。詳細見 docs/G202_SURFACE_RUNTIME_ACCEPTANCE_20261017.md。GitHub/Drive Handoff 與 Issue #15 待同步記錄。

2026-10-17 G2.1 v0.4.0 Candidate: stand-alone ecology_behavior_lab scene with Snorlax maximum 18 simulated sec no-roam interval, short natural walk, per-agent roam count/heading vector, independent G21 runtime LOG and ZIP collector. 108/108 offline PASS; Surface F6 PENDING. Source commit f9f08ce2ab423ed8e5a23dab5da100244b3c2d73; complete 118-file ZIP https://drive.google.com/file/d/1boS_9l6F4z3Jf4j1JD7CkH3ISJAu-46w/view SHA256 dca1c5a41aeff77bec2b84f6375e8c10e25f9567580079409e17bc87b860c1f3. Existing G1/G2.0.2 scenes untouched. Next collect PLW_G21_DIAGNOSTICS_TO_SHARE.zip.
