# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS source. Current formal source baseline: **v1.06.54**.
- `develop`: current unpassed development candidate. Current candidate: **v1.06.55 — Landmark Route Safety Audit I**.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Script export
`exported_scripts/` preserves exact RPG Maker VX `Scripts.rvdata` execution order.
- `SCRIPT_INDEX.tsv`: numeric index, Script ID, Script Name, file, byte count, SHA-256.
- `SCRIPT_ORDER.md`: human-readable order.
- each `.rb`: exact decompressed script body. Do not reorder for repository aesthetics.

## Formal PASS
**v1.06.54** received Windows/RMVX real-machine Visual + Semantic PASS on 2026-08-18.

## Current develop
**v1.06.55 — VXRD Landmark Route Safety Audit I — UNPASSED**
- 643 scripts, indices 0..642.
- v1.06.55 is Script index 640 / ID 1065500; Main is 641; terminator is 642.
- Adds entrance→exit and Map091 semantic-event route gates around hard Landmark blockers.
- Unsafe hard Landmark placement is rejected rather than modifying sealed Gate 1 topology.
- Static validation PASS 31/31.
- Offline deterministic regression: 40/40 PASS across H01/H04/H09/H14/H19 × 8 seeds.
- Real-machine acceptance remains required before any `main` promotion.

Automatic B/C/D/E map stamping remains prohibited and v1.06.44 Landmark runtime IDs remain revoked.
