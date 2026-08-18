# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 17:46 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Version State
- Current Formal Baseline: **v1.06.56 — VXRD Random Hunt Real Loading Overlay I — FORMAL PASS**.
- Active unpassed Candidate: **v1.06.57 — VXRD Landmark Vegetation / Wetland Coverage Expansion I**.
- v1.06.56 Windows Loading acceptance PASS: `RESULT=PASS`, `FINAL_PERCENT=100`, `REAL_CHECKPOINTS=1`, `FAKE_TIMER=0`, `INPUT_PASSTHROUGH=0`.
- SHO-35 Loading Overlay = Done / SEALED.
- SHO-22 Landmark Route Safety = Done / SEALED after 840 production-like + 11 adversarial cases, failures 0, adversarial removed total 10, topology rewrite 0.
- Active acceptance issue: **SHO-36**.

## v1.06.57 Candidate Scope
Enable existing-art-compatible soft/passable 32×32 Landmark coverage only for:
- H02 — 苔溪濕岸, `forest_green_a`, min 1 max 2.
- H03 — 風鳴草痕, green + flower, min 2 max 3.
- H06 — 深蔭密叢, green + flower, min 2 max 3.
- H07 — 霧澤泥痕, `forest_green_a`, min 1 max 2.
- H16 — 原始樹海, `forest_green_a`, min 2 max 3.

Existing accepted H01/H04/H09/H14/H19 remain unchanged.
Deferred pending dedicated art: H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.
Do not fake biome identity with unrelated forest/rock/crystal props.

## Binary Authority
v1.06.57 Current Development ZIP:
- Drive ID `1OSHRyT1WCaYzWwT011Lqjm3y76kR5Ik0`.

v1.06.57 Test Build:
- Drive ID `1LyFebyMWoMiojgHGAnYwVJIB-zTMOlYM`.

Binary validation:
- 645 Scripts, indices 0..644.
- v1.06.57 index 642 / ID 1065700.
- Main 643; terminator 644.
- v1.06.57 source SHA256 `be91725e395e87bb79553d11d0bb125f913d7e8f2aabf164609e688e4e820ede`.
- `Data/Scripts.rvdata` SHA256 `0a76471dc85f8e8a95492468e5615c238b0694a02e4638a2e706e050cd89fe09`.
- Baseline entries 0..641 preservation PASS / failures 0.
- Static validation 23/23 PASS; Ruby syntax PASS.
- Map091 unchanged, SHA256 `206349b314be757aca7aabc338434f2ba6da93d59ee49f0394a47f62a3e46ec8`.
- Traditional Chinese tutorial synchronized.

## GitHub Branch Authority
### main
- v1.06.56 formal PASS source.
- 644 scripts, indices 0..643.
- v1.06.56 index 641 / ID 1065600.
- Main 642; terminator 643.

### develop
- Contains v1.06.57 runtime source and active SHO-36 work.
- Known Source-only blocker: `SCRIPT_INDEX.tsv / SCRIPT_ORDER.md` tail has not yet converged from the v1.06.56 644-entry layout to the validated 645-entry v1.06.57 layout.
- Expected tail independently regenerated from validated Binary:
  - 642 / ID 1065700 / v1.06.57
  - 643 / ID 250 / Main
  - 644 / ID 251 / terminator
- PR #1 corrected the stale one-shot finalizer SHA gate to the actual v1.06.57 source hash, but no follow-up finalizer run was observed.
- This blocker does **not** invalidate Binary visual testing, but v1.06.57 MUST NOT be promoted to Formal Baseline until GitHub Source Authority converges and Windows acceptance passes.

## Windows/RMVX Acceptance for v1.06.57
Test only H02/H03/H06/H07/H16.
Accept when each shows its minimum single 32×32 prop, ecology is plausible, all new props are soft/passable, scrolling/floor/Hunt refresh are normal, v1.06.56 Loading remains normal, and there is no automatic B/C/D/E scatter or giant fragment regression.
Runtime evidence: `PMD_VXRD_LandmarkCoverage_Audit_LATEST.log`.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains H01–H21 shared Event Template Library.
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or progression for this work.

## Editor / Documentation Rule
Any functional delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires: completely close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must include synchronized Traditional Chinese tutorial/usage documentation.
