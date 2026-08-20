# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS source. Current Formal baseline: **v1.06.66 — Gate 3 Integrated Seal Convergence I**.
- `develop`: current development / diagnostics / candidate branch; must remain based on latest Formal `main` and preserve Shared Map Layered Generation Authority v2.5.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Formal Source
Canonical `exported_scripts/` currently contains **651 Scripts, indices 0..650**:
- 646: v1.06.63 Completion Incentive
- 647: v1.06.64 Run Accounting
- 648: v1.06.66 Integrated Seal Convergence
- 649: Main
- 650: terminator

v1.06.65 was rejected and never promoted to Formal Source.

`SCRIPT_INDEX.tsv` and `SCRIPT_ORDER.md` are current. PR #10 refreshed the 651-script manifest and merged as `5c8d419bac03552b79ac4ea21982a6ed49f1331a` without Runtime changes.

## Formal PASS / Seals
- Gate 1 Random Hunt structural runtime: SEALED.
- Gate 2 script/runtime authorities including Map091, Route Safety, Loading and A1 liquid semantics: accepted/sealed; dedicated biome art remains parallel work.
- Gate 3 Risk / Reward: **SEALED / issue-driven only** at v1.06.66.
  - floor-depth Rare/Elite risk curve.
  - full-clear Completion Bonus 2/2/3/4/5.
  - total/immediate/completion run accounting and persistence.
  - Windows integrated acceptance with Reward/RNG/Map/Session mutation = 0.

## Current development
Linear **SHO-55 — P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I**.

User shortcut policy: stop allocating new permanent test hotkeys. Retire/reuse obsolete QA shortcuts and converge on one current TEST dispatcher, while preserving real player inputs. In particular, F8 has both old QA uses and real production navigation, so cleanup is hook-specific rather than a global key ban.

Battle Tempo P4 remains blocked by Motion completion. Generated Runtime Asset Expansion remains end-of-development bulk work per prior Authority. Gate 2 dedicated Landmark art remains parallel/secondary while script/runtime work is prioritized.

Automatic B/C/D/E map stamping remains prohibited; v1.06.44 Landmark runtime IDs remain revoked.
