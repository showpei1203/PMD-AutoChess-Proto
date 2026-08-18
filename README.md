# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository seed.

## Authority
- `main`: latest formal Windows/RMVX PASS / SEALED source only.
- `develop`: next unpassed development candidate.
- Binary `.rvdata`, large Graphics/Audio, and complete game ZIPs belong in Google Drive, not GitHub.

## Script export
`exported_scripts/` preserves the exact RPG Maker VX `Scripts.rvdata` execution order.
- `SCRIPT_INDEX.tsv`: numeric index, Script ID, Script Name, file, byte count, SHA-256.
- `SCRIPT_ORDER.md`: human-readable order.
- each `.rb`: exact decompressed script body. Do not reorder merely for repository aesthetics.

Formal main seed version: v1.06.35.
