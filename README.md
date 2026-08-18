# PMD AutoChess Proto

RPG Maker VX / RGSS2 source-control repository.

## Authority
- `main`: latest formal Windows/RMVX PASS source. Current formal source baseline: **v1.06.55** after the accepted five-Hunt Route Safety Audit I scope is promoted.
- `develop`: continuation branch for broader SHO-22 route stress and the separate SHO-35 Random Hunt Loading UI work.
- Binary `.rvdata`, Graphics/Audio, complete game ZIPs, builds and runtime logs belong in Google Drive, not GitHub.

## Script export
`exported_scripts/` preserves exact RPG Maker VX `Scripts.rvdata` execution order.
- `SCRIPT_INDEX.tsv`: numeric index, Script ID, Script Name, file, byte count, SHA-256.
- `SCRIPT_ORDER.md`: human-readable order.
- each `.rb`: exact decompressed script body. Do not reorder for repository aesthetics.

## Formal PASS
**v1.06.55 — VXRD Landmark Route Safety Audit I** received Windows/RMVX Phase-I real-machine PASS on 2026-08-18 for H01/H04/H09/H14/H19.
- Every recorded run reports `RESULT=PASS`, `EXIT_REACHABLE=1`, and empty `BAD=`.
- H04/H09/H14/H19 had active hard Landmark blockers without breaking required routes.
- Static validation PASS 31/31.
- Offline deterministic regression PASS 40/40 across the five accepted Hunts × 8 seeds.

This PASS is scoped to the accepted five-Hunt Route Safety Audit I. SHO-22 remains open for broader Hunt / multi-seed stress before Landmark coverage expands.

## Next development
- SHO-22: broader route-safety stress / unsafe-placement rejection coverage.
- SHO-35: Random Hunt black-screen LOADING overlay using the existing battle Loading UI authority and real map-generation checkpoints.

Automatic B/C/D/E map stamping remains prohibited and v1.06.44 Landmark runtime IDs remain revoked.
