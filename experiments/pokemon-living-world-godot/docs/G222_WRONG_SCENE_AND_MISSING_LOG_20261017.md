# G2.2.2 | Missing G22 log / actual scene unverified | 2026-10-17

## Evidence
User reports G22 collector created no file and idle/facing did not visibly change. Uploaded ZIP `PLW_G21_DIAGNOSTICS_TO_SHARE(1).zip` contains **PLW_G21_RUNTIME_LAST.log** and HOW_TO_READ.txt, and `LOGGER_READY build=G2.1-v0.4.0 scene=res://scenes/ecology_behavior_lab.tscn`. The recording is ~33 seconds. **This is G2.1 evidence, not G2.2.** It may be a past log, so it is not conclusive proof which scene was active on the user's latest attempt. Neither successful G22 startup nor failure of G22 visual algorithms has been established.

## Modification
- `tools/g22_collect_logs.py`: always create `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip`. On valid G22 log, package G22 log + HOW_TO_READ. On missing G22 log, package G22_MISSING_LOG_DIAGNOSIS.txt + HOW_TO_READ, and identify older G21/G2 log from its LOGGER_READY header. Do not package old log as if it were new, or package copyrighted images. Missing-log collector still exits 2 to indicate incomplete runtime test, **but ZIP is created**.
- Windows BAT echoes the distinction between exit code 2 and ZIP creation.
- `tests/test_g222_missing_log_diagnostics.py` adds four checks.
- G2.2.1 Godot scene/scripts, G2.1 accepted baseline, existing G1 scenes and all PMD sprites unchanged.

## Tests and status
- Local Python regression **129/129 PASS** (previous 125 + 4), but **Godot Surface G2.2 still UNVERIFIED**. No Godot executable available in build environment.
- Full 142-file candidate ZIP on Drive: https://drive.google.com/file/d/1i05CXH67MhM308K0XIzlTkAimutbN4bT/view
- ZIP SHA256: `c81ae597e592ad3ec91f9a8fe20e3acdf727c14bbc68d8f4526190009e562a80`, ZIP CRC PASS, no PMD art.
- Original uploaded user LOG is not republished in this public repository. Future versions must update GitHub/Drive Handoffs and Issue #15.

## Surface next steps
1. Close game windows; GitHub Desktop on `planning/pokemon-living-world-godot` Fetch/Pull.
2. In Godot **double click** `scenes/ecology_animation_lab.tscn`. Verify active tab `ecology_animation_lab` and Scene tree `EcologyAnimationLab > Diagnostics`. Selecting in FileSystem is NOT opening the scene.
3. Press **F6**. Confirm displayed `G2.2.1 | tick=` progresses and Output has `[PLW-G2-LOG] FILE` absolute path.
4. Observe 20-30 seconds, including Snorlax stationary pose and traveling Pokémon facing directions. Stop F6. Run `RUN_G22_COLLECT_LOG_WINDOWS.bat`.
5. Upload `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip` regardless of collector exit status. If missing, ZIP contains reasons; also provide first Godot red error and Output screenshot. If Output FILE points to `user://` fallback, send the exact log from that absolute path.
