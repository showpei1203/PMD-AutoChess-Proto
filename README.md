# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS / SEALED source only. Current formal source baseline: **v1.06.54**.
- `develop`: continuation branch for the next unpassed development candidate, based on the latest formal PASS.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Script export
`exported_scripts/` preserves the exact RPG Maker VX `Scripts.rvdata` execution order.
- `SCRIPT_INDEX.tsv`: numeric index, Script ID, Script Name, file, byte count, SHA-256.
- `SCRIPT_ORDER.md`: human-readable order.
- each `.rb`: exact decompressed script body. Do not reorder merely for repository aesthetics.

## Current formal PASS
**v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I** received Windows/RMVX real-machine PASS on 2026-08-18.
- H01/H04/H09/H14/H19 Landmark presence and 32×32 single-prop rendering accepted.
- H01 soft decoration passability accepted.
- H04/H09/H14/H19 hard Landmark collision accepted.
- scrolling / Hunt-floor refresh accepted.
- automatic B/C/D/E map stamping remains prohibited; v1.06.44 Landmark runtime IDs remain revoked.

Next development gate: **SHO-22 Landmark II — Collision / Route Audit**.
