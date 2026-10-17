# Pokémon Living World | Append-only Handoff History

## 2026-10-17 G0 / G1 accepted baselines
Godot 4.7.2; user verified 151/151 PMDCollab ZIP sources, 3/3 G1 animated sprites and successful G1.1 gallery controls. G1.2.1 anchor scan process user-accepted, actual full 151 anchor details not independently checked. Existing scenes preserved.

## 2026-10-17 G2.0 + G2.0.1 failure
Surface user reported little movement, no apparent change on N/D; then G2.0.1 tick not increasing, M/D/N no effect. **G2 acceptance FAIL / BLOCKED**. Root cause unknown, no file-based runtime logs existed.

## 2026-10-17 G2.0.2 v0.3.9 diagnostic candidate
New independent CanvasLayer observer, fixed `reports/PLW_G2_RUNTIME_LAST.log`, keyboard and clickable diagnostics, Windows open + zip collector, seven regression tests. **98/98 offline PASS**; Surface F6 NOT YET VERIFIED. F5 still launches accepted G1 main; G2 requires opening `scenes/ecology_lab.tscn` and F6. No copyrighted raw sprite art touched or added. Next: user attaches `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`; diagnose root cause and update both GitHub and Drive handoffs before further feature work.

2026-10-17 v0.3.9 連線恢復交付核對：GitHub 程式和 CURRENT_HANDOFF/HISTORY 已存在；完整 107 檔 ZIP 成功補傳 Google Drive（https://drive.google.com/file/d/1X5ZbpBvCPVTZqYrWzNFrtxBA1BADI6f7/view），SHA256 42aa22571846afb0b733c31ddcde05523579fe3cbd56b2bee03f62fbf35ac522；Issue #15 同步；G2 Surface LOG 尚未取得，狀態仍 FAIL/PENDING，不得宣稱修復完成。
