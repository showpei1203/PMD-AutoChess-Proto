# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS / SEALED source only. Current formal source baseline: **v1.06.35**.
- `develop`: current unpassed development candidate. Current candidate: **v1.06.54**.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Script export
`exported_scripts/` preserves the exact RPG Maker VX `Scripts.rvdata` execution order.
- `SCRIPT_INDEX.tsv`: numeric index, Script ID, Script Name, file, byte count, SHA-256.
- `SCRIPT_ORDER.md`: human-readable order.
- each `.rb`: exact decompressed script body. Do not reorder merely for repository aesthetics.

## Current develop state
- v1.06.53 failed real-machine Landmark visual acceptance.
- v1.06.54 repairs single-prop rendering, guaranteed presence and local hard/soft Landmark collision semantics.
- `main` is not promoted; v1.06.35 remains formal PASS.
