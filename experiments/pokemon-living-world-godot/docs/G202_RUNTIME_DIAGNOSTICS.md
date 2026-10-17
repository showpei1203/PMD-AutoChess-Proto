# G2.0.2 Surface Runtime Diagnostics v0.3.9

**Status: DIAGNOSTIC CANDIDATE, G2 NOT ACCEPTED.**

Godot G2 scene is `scenes/ecology_lab.tscn`, launched by **F6**. F5 runs G1. Green `G2.0.2 LOGGER ACTIVE` overlay confirms new G2 logger is loaded. Click M/D/N buttons and press the corresponding keyboard keys; wait 10-15 seconds.

**Runtime LOG**: project root `reports/PLW_G2_RUNTIME_LAST.log` (actual absolute path printed in Godot Output as `[PLW-G2-LOG] FILE`). On read-only builds fallback to `user://PLW_G2_RUNTIME_LAST.log` and use the printed absolute path. New run overwrites previous LAST.

**One-click open**: `RUN_G2_OPEN_LOG_WINDOWS.bat`. **One-click ZIP for ChatGPT**: `RUN_G2_COLLECT_LOG_WINDOWS.bat`; upload `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`. ZIP contains only text log + HOW_TO_READ, no Pokémon art.

**Meaning of log**: `LOGGER_READY`, `SESSION_START`, `HEARTBEAT` (UI frames, physics callbacks, root AI tick, pause status, scene name), `KEYBOARD`, `BUTTON`, `AGENT` state changes/positions/target, `SESSION_END`. Engine red debugger errors are not automatically captured: please provide screenshot if present. Detailed triage is in `docs/CURRENT_HANDOFF_PLW.md`.

**Verification**: Python 98/98 offline tests PASS, including generated ZIP contents; Godot 4.7.2 Surface F6 still pending. Source G2 AI/locomotion logic untouched except `_input` receiving key events earlier. G1/G1.1/G1.2 scenes and project main unchanged. This version does not claim to fix the original motion stall until the first user LOG is analyzed.

