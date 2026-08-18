# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 13:12 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent source is genuinely inaccessible.

Read order:
1. Google Drive `00_Project_Authority/MASTER_PROJECT_STATE.md`
2. Google Drive `05_Handoff/CURRENT_HANDOFF.md`
3. Google Drive `01_Current_Baseline`
4. GitHub `main` / `develop`
5. Linear Team `Showpei` → Project `PMD AutoChess Proto`
6. Google Drive `02_Current_Development`

Authority split:
- Google Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = development workspace only

## Version State
- Formal Baseline: **v1.06.35 — VXRD Acceptance Non-Combat Fixture**
- Current Candidate: **v1.06.53 — VXRD Landmark PNG Authority Foundation I — UNPASSED**
- Gate 1 Windows Final Acceptance is PASS and structural runtime remains SEALED / issue-driven only.

## GitHub
Repository: `showpei1203/PMD-AutoChess-Proto`
- `main`: v1.06.35 formal PASS source, import commit `7fa9e9f9adf16f7c68bbd1596b55a125e732ff74`, 623 scripts, indices 0..622.
- `develop`: v1.06.53 unpassed candidate source, import commit `ba7802d749d58b6a2e1dd9f7c4d18eb842b36cb8`, 641 scripts, indices 0..640.
- Script Index / ID / Name / exact decompressed Content / execution order are preserved through `SCRIPT_INDEX.tsv` and `SCRIPT_ORDER.md`.
- GitHub stores text Source / Ruby / RGSS / Tools / Tests / Docs / Authority only. ZIP, rvdata, Graphics, Audio, builds and runtime logs stay in Drive.

## Current Binary Files
Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_35_CUMULATIVE_OVERWRITE_VXRD_ACCEPTANCE_NONCOMBAT_20260817.zip`

Candidate:
`02_Current_Development/PMD_AutoChess_v1_06_53_CUMULATIVE_OVERWRITE_VXRD_LANDMARK_PNG_AUTHORITY_FOUNDATION_I_20260818.zip`

Captured Windows live project:
`02_Current_Development/PMD_AutoChess_WINDOWS_LIVE_FULL_PROJECT_SNAPSHOT_NEEDS_REVIEW_20260818.zip`
Drive ID `1Aqn2pCP9zdl6BXWyCQTE3nLIK4gbA8Oz`, 254,617,103 bytes. Version alignment remains NEEDS_REVIEW; do not silently promote it.

## Immediate Next Acceptance
Test v1.06.53 visually on **H01 / H04 / H09 / H14 / H19 only**.
- Primary evidence: actual screen appearance and screenshots.
- No Battle LOG unless Runtime or battle behavior itself fails.
- No automatic B/C/D/E map-tile stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.

Only after all five visually PASS: proceed to Landmark collision + route audit (SHO-22).

## Delivery Rule
If `Data/Map091.rvdata` or other Data files are updated, close RPG Maker VX before overwrite and reopen it afterward. Every functional update must also update the Traditional Chinese tutorial / usage documentation.

## Linear Rule
Use shared Team `Showpei`, Project `PMD AutoChess Proto`. Create only current/future actionable, verifiable issues; do not bulk-create historical PASS/Candidate/Script/Ability/Skill issues.
