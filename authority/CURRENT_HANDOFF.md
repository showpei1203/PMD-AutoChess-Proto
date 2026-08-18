# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 17:46 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Formal Baseline
**v1.06.56 — VXRD Random Hunt Real Loading Overlay I — FORMAL PASS.**
SHO-35 is Done / SEALED.

## Route Safety
**SHO-22 is Done / SEALED.**
Evidence:
- 840 production-like cases = 21 Hunts × 40 seeds.
- 11 adversarial cases.
- 10 unsafe hard Landmarks actually removed.
- failures 0.
- topology rewrite 0.
- automatic B/C/D/E stamping 0.

## Active Candidate
**v1.06.57 — VXRD Landmark Vegetation / Wetland Coverage Expansion I — UNPASSED.**
Linear: SHO-36 In Progress.

Expansion only:
- H02 — soft/passable green vegetation, min 1 max 2.
- H03 — soft/passable vegetation + flowers, min 2 max 3.
- H06 — soft/passable dense vegetation + flowers, min 2 max 3.
- H07 — soft/passable low vegetation, min 1 max 2.
- H16 — soft/passable primordial forest vegetation, min 2 max 3.

Existing H01/H04/H09/H14/H19 stay accepted.
Deferred for dedicated art: H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.

## v1.06.57 Binary Authority
Current Development Drive ID: `1OSHRyT1WCaYzWwT011Lqjm3y76kR5Ik0`.
Test Build Drive ID: `1LyFebyMWoMiojgHGAnYwVJIB-zTMOlYM`.

Validated Binary:
- 645 Scripts, 0..644.
- v1.06.57 = index 642 / ID 1065700.
- Main 643; terminator 644.
- source SHA256 `be91725e395e87bb79553d11d0bb125f913d7e8f2aabf164609e688e4e820ede`.
- Scripts.rvdata SHA256 `0a76471dc85f8e8a95492468e5615c238b0694a02e4638a2e706e050cd89fe09`.
- baseline 0..641 preserved PASS.
- static 23/23 PASS; Ruby syntax PASS.
- Map091 unchanged.
- Traditional Chinese tutorial updated.

## GitHub Source-only Blocker
`develop` contains v1.06.57 runtime source, but `SCRIPT_INDEX.tsv / SCRIPT_ORDER.md` tail remains at the older 644-entry v1.06.56 layout.
Expected validated tail:
- 642 / 1065700 / v1.06.57
- 643 / 250 / Main
- 644 / 251 / terminator

PR #1 corrected the stale exact-source SHA gate, but the one-shot finalizer did not produce a follow-up commit. Do not promote v1.06.57 to Formal Baseline until this Source Authority tail converges and Windows acceptance passes. Binary visual testing may proceed because the delivered Scripts.rvdata was independently rebuilt and validated.

## Immediate Windows Test
Completely close RPG Maker VX before overwrite because `Data/Scripts.rvdata` changes; overwrite, then reopen RMVX.
Test only H02/H03/H06/H07/H16.
Confirm minimum presence, single 32×32 rendering, ecological plausibility, soft passability, normal scrolling / floor-Hunt refresh, Loading overlay still normal, and no automatic B/C/D/E scatter or giant fragments.
Expected log: `PMD_VXRD_LandmarkCoverage_Audit_LATEST.log`.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or progression.
