# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS source. Current Formal baseline: **v1.06.67 — P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I**.
- `develop`: current development / diagnostics / candidate branch; must remain based on latest Formal `main` and preserve Shared Map Layered Generation Authority v2.5.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Formal Source
Canonical `exported_scripts/` contains **652 Scripts, indices 0..651**:
- 646: v1.06.63 Completion Incentive
- 647: v1.06.64 Run Accounting
- 648: v1.06.66 Integrated Seal Convergence
- 649: v1.06.67 P8 Cross-Gate Regression + QA Shortcut Consolidation
- 650: Main
- 651: terminator

v1.06.65 was rejected and never promoted to Formal Source.

## Formal PASS / Seals
- Gate 1 Random Hunt structural runtime: SEALED.
- Gate 2 script/runtime authorities including Map091, Route Safety, Loading and A1 liquid semantics: accepted/sealed; dedicated biome art remains parallel work.
- Gate 3 Risk / Reward: SEALED / issue-driven only at v1.06.66.
- P8 cross-gate regression + QA shortcut consolidation: **FORMAL WINDOWS PASS / SEALED at v1.06.67**.

P8 Windows evidence:
- Gate1/2/3 PASS.
- blockers=0.
- extra RNG=0, Reward=0, Map mutation=0, Battle launch=0.
- VXRD state / Hunt session / Party mutation=0.

## QA Shortcut Policy
Current TEST-only launcher:
- F5 on Scene_Map: P8 Fast Cross-Gate Regression.

Historical permanent QA launchers retired:
- F7 v1.01.4 Boss retest.
- F6 v1.05.19 Focus fixture.
- F7 v1.05.34 Representative Visual.
- F9 v1.05.36 Sandshrew focused review.
- SHIFT+F7 v1.05.37 Transition fixture.
- SHIFT+F9 v1.05.38 Important Species fixture.

Production F8 navigation remains preserved. Cleanup is hook-specific, not a global key ban.

## Current development
Linear **SHO-55 is Done / SEALED**.

Known remaining work:
- Gate 2 dedicated Landmark art remains parallel/secondary (SHO-7 / SHO-42).
- Battle Tempo P4 remains blocked by Motion completion.
- Generated Runtime Asset Expansion remains end-of-development bulk work.
- Game.ini stale title is tracked separately as low-priority metadata debt (SHO-47).

Automatic B/C/D/E map stamping remains prohibited; v1.06.44 Landmark runtime IDs remain revoked.
