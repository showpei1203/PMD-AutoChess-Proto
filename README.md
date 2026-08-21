# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS source. Current Formal baseline: **v1.06.68a — P8-II Deterministic Battle Regression Consolidation I**.
- `develop`: current development / diagnostics / candidate branch; must remain based on latest Formal `main` and preserve Shared Map Layered Generation Authority v2.5.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Formal Source
Canonical `exported_scripts/` contains **653 Scripts, indices 0..652**:
- 646: v1.06.63 Completion Incentive
- 647: v1.06.64 Run Accounting
- 648: v1.06.66 Integrated Seal Convergence
- 649: v1.06.67 P8 Cross-Gate Regression + QA Shortcut Consolidation
- 650: v1.06.68a P8-II Deterministic Battle Regression Consolidation
- 651: Main
- 652: terminator

v1.06.65 was rejected and never promoted to Formal Source. v1.06.68 first TEST candidate failed due TEST-harness assumptions only and was not promoted.

## Formal PASS / Seals
- Gate 1 Random Hunt structural runtime: SEALED.
- Gate 2 script/runtime authorities including Map091, Route Safety, Loading and A1 liquid semantics: accepted/sealed; dedicated biome art remains parallel work.
- Gate 3 Risk / Reward: SEALED / issue-driven only at v1.06.66.
- P8 Cross-Gate + QA shortcut consolidation: FORMAL WINDOWS PASS / SEALED at v1.06.67.
- **P8-II deterministic battle regression: FORMAL WINDOWS PASS / SEALED at v1.06.68a.**

P8-II Windows evidence:
- 10/10 audits PASS; blockers=0.
- detached normal Knockback=9 frames; Suction Cups Knockback/Pull=0 frames.
- species semantic route sample=6/6; profile ready=6/6.
- extra RNG=0, Reward=0, Party mutation=0, Battle Request mutation=0, Live Unit mutation=0, Scene mutation=0, Battle launch=0.
- module cache restored=1.
- representative assets ready=0/56 and species asset admitted=0/6 are explicitly deferred/nonblocking under current Asset Expansion Authority.

## QA Shortcut Policy
Current TEST-only F5 dispatch:
- F5 on `Scene_Map`: v1.06.67 P8 Fast Cross-Gate Regression.
- F5 in normal `Scene_PMD_AutoChess` battle: v1.06.68a P8-II Deterministic Battle Regression.

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
Linear **SHO-56 is accepted for Done / SEALED after Authority convergence**.

Known remaining work:
- Gate 2 dedicated Landmark art remains parallel/secondary (SHO-7 / SHO-42).
- Battle Tempo P4 remains blocked by Motion completion.
- Generated Runtime Asset Expansion remains end-of-development bulk work.
- Game.ini stale title is tracked separately as low-priority metadata debt (SHO-47).
- Any next script/runtime candidate must start from v1.06.68a Formal and remain issue-driven.

Automatic B/C/D/E map stamping remains prohibited; v1.06.44 Landmark runtime IDs remain revoked.
