# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 13:55 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Version State
- Formal Baseline: **v1.06.35 — VXRD Acceptance Non-Combat Fixture**.
- Gate 1 Windows Final Acceptance: PASS; Random Hunt structural runtime SEALED / issue-driven only.
- v1.06.53 Landmark PNG Authority Foundation I: **REAL-MACHINE VISUAL FAIL**.
- Current Candidate: **v1.06.54 — Landmark Single-Prop Semantic / Presence / Collision Fix I — UNPASSED**.
- v1.06.54 static validation: PASS 23/23; real-machine acceptance pending.

## GitHub Branch Authority
### main
- v1.06.35 formal PASS source.
- 623 scripts, indices `0..622`.
- Formal source import commit: `7fa9e9f9adf16f7c68bbd1596b55a125e732ff74`.

### develop
- v1.06.54 unpassed Candidate source.
- 642 scripts, indices `0..641`.
- New Script index `639`, ID `1065400`.
- Main index `640`; terminator index `641`.
- v1.06.54 finalization commit: `a8f55d96807e7c4e09bddab95900ca60bb887bbc`.
- `SCRIPT_INDEX.tsv` blob SHA: `09ee459a307d63acf0ddb33ca1f0eda8a92f9adc`.
- Index / ID / Name / exact decompressed Content / execution order remain preserved.
- Do not promote `develop` to `main` without Windows/RMVX PASS.

## Drive Binary Authority
- Baseline: `01_Current_Baseline/PMD_AutoChess_v1_06_35_CUMULATIVE_OVERWRITE_VXRD_ACCEPTANCE_NONCOMBAT_20260817.zip`.
- Current Candidate: `02_Current_Development/PMD_AutoChess_v1_06_54_CUMULATIVE_OVERWRITE_LANDMARK_SINGLE_PROP_SEMANTIC_PRESENCE_COLLISION_I_20260818.zip`, Drive ID `1B3flf23qcLhGqLjNSlwKZnCULjGcYLC0`.
- Test Build: `03_Test_Builds/PMD_AutoChess_v1_06_54_TEST_BUILD_UNPASSED_20260818.zip`, Drive ID `1PtdkPqo64OzUTxLHi2jdm-gE9MPxG8nw`.
- Windows live snapshot remains NEEDS_REVIEW for internal version alignment and is not Baseline.

## v1.06.53 Failure Authority
User real-machine evidence:
- H01/H04/H09/H14: no visible Landmark.
- H19: four unrelated 32×32 props appeared as one tight 2×2 object block.
- H19 hard rock/ore visuals were pass-through.

Confirmed root cause:
- Existing 64×64 Landmark PNGs are 2×2 atlases of four independent 32×32 props.
- v1.06.53 rendered the full atlas as one sprite.
- Placement was probabilistic and reused the old 2×2 footprint, permitting zero placements.
- v1.06.53 forced `blocking=false` and deferred collision.

## v1.06.54 Candidate Authority
- Render one 32×32 atlas cell per Landmark via `Sprite#src_rect`.
- Logical footprint = 1×1.
- H01/H04/H09/H14/H19 have a minimum-presence gate with safe non-entrance/non-exit fallback rooms.
- Hard props use conservative spacing; no tight 2×2 pile.
- H01 foliage/flowers = passable.
- H04 dry rock, H09 cave crystal/rock, H14 mine ore, H19 volcanic rock/ore = blocking.
- This is local semantic collision only; full collision + route audit remains deferred until five-Hunt acceptance.
- Map091 and the six PNG atlas files are unchanged from v1.06.53.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains the H01–H21 Event Template Library.
- Gate 1 Battle/Random Hunt structural runtime remains SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints in current visual work.

## Immediate Acceptance
Test only **H01 / H04 / H09 / H14 / H19**.
Required:
1. at least one Landmark in every Hunt;
2. one Landmark = one 32×32 prop, never a four-object 2×2 collage;
3. natural spacing;
4. H01 soft plants passable;
5. H04/H09/H14/H19 hard props impassable;
6. correct scrolling and refresh between Hunt/floor changes;
7. no B/C/D/E stamping or Gate 1 regression.

Primary evidence is screenshots + movement interaction. Battle LOG only if Runtime/battle fails. Only after all five pass may SHO-22 full Landmark collision + route audit begin.

## Editor / Documentation Rule
Any delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or other Data files requires: close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must also update the Traditional Chinese tutorial/usage documentation.
