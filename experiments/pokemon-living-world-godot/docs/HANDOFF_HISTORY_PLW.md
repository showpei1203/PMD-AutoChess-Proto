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

2026-10-17 G2.2.1 v0.4.1.1 Surface compiler hotfix: user screenshot `ecology_animation_diagnostics.gd:104` undeclared locals roams and since_roam -> v0.4.1 Godot FAIL; active ecology_lab.tscn instead of highlighted ecology_animation_lab.tscn separately observed. Patched logger two variables, version label G2.2.1 and telemetry transition key. 3 Python tests added, total 125/125 offline PASS, **Godot F6 still pending**. G1/G2.1 untouched. Complete 137-file CRC-PASS ZIP https://drive.google.com/file/d/1RnSscBaWJtnrUKEQjpdk05M0Byx0WUKv/view, SHA256 60553d0c99e80f0ab7138d7ea6daeba2063338637f3cec051d582fd098f5e49a. Next double-click correct scene, F6, upload G22 runtime log ZIP. Updated GitHub/Drive Handoff and Issue #15.

2026-10-17 G2.2.2 v0.4.1.2 缺少 LOG 診斷修正：使用者回報 G22 Collector 沒輸出、Idle/朝向無變化；實際附上的是舊版 G21 v0.4.0 ecology_behavior_lab LOG（約33秒），不足以證明真正執行 G22，更不能判定 G22 動畫失效。只修改 G22 收集程式與 BAT：G22 LOG 不在時仍會產生含 G22_MISSING_LOG_DIAGNOSIS.txt 的 ZIP，標示舊版 LOG 及啟動正確場景操作，退出碼2仍代表無 G22 LOG；新增4項測試，129/129 Python 離線 PASS。142檔完整 ZIP https://drive.google.com/file/d/1i05CXH67MhM308K0XIzlTkAimutbN4bT/view SHA256 c81ae597e592ad3ec91f9a8fe20e3acdf727c14bbc68d8f4526190009e562a80。G2.2 Surface F6 尚待驗收，GDScript未修改。
