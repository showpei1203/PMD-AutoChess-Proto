# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 13:55 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Formal Baseline
**v1.06.35 — VXRD Acceptance Non-Combat Fixture** remains the formal Windows/RMVX PASS baseline. Gate 1 structural runtime and accepted Battle Presentation remain SEALED / issue-driven only.

## Current Candidate
**v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I — UNPASSED**.
- Scripts.rvdata: 642 entries.
- New Script index 639 / ID 1065400.
- Main index 640; terminator index 641.
- Static validation PASS 23/23.
- Map091 unchanged from v1.06.53.
- Six Landmark PNG atlas files unchanged.

Drive Candidate:
`02_Current_Development/PMD_AutoChess_v1_06_54_CUMULATIVE_OVERWRITE_LANDMARK_SINGLE_PROP_SEMANTIC_PRESENCE_COLLISION_I_20260818.zip`
Drive ID `1B3flf23qcLhGqLjNSlwKZnCULjGcYLC0`.

Test Build:
`03_Test_Builds/PMD_AutoChess_v1_06_54_TEST_BUILD_UNPASSED_20260818.zip`
Drive ID `1PtdkPqo64OzUTxLHi2jdm-gE9MPxG8nw`.

## GitHub
- `main` = v1.06.35 formal PASS source, 623 scripts.
- `develop` = v1.06.54 unpassed candidate source, 642 scripts.
- v1.06.54 finalization commit: `a8f55d96807e7c4e09bddab95900ca60bb887bbc`.
- `SCRIPT_INDEX.tsv` blob SHA: `09ee459a307d63acf0ddb33ca1f0eda8a92f9adc`.
- Script order / ID / name / exact decompressed content are preserved.

## v1.06.53 Real-Machine FAIL
- H01/H04/H09/H14 showed no Landmark.
- H19 showed four unrelated 32×32 props together because the full 64×64 2×2 atlas was rendered as one object.
- H19 hard rock/ore visuals were pass-through.

Root cause: probabilistic placement + old 2×2 footprint + full-atlas rendering + `blocking=false` collision defer.
Do not promote v1.06.53.

## v1.06.54 Repair
- One Landmark = one 32×32 atlas cell.
- Logical footprint = 1×1.
- H01/H04/H09/H14/H19 minimum presence gate.
- H01 foliage/flowers = passable.
- H04 rock / H09 crystal-rock / H14 ore / H19 volcanic rock-ore = blocking.
- Hard props use conservative spacing; no tight 2×2 pile.
- Local semantic collision only. Full route audit remains SHO-22 after acceptance.
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt runtime map; Map091 remains H01–H21 Event Template Library.

## Immediate Test
Test only **H01 / H04 / H09 / H14 / H19**.
For each Hunt verify:
1. at least one Landmark is visible;
2. each Landmark is one 32×32 object, not four objects in one 2×2 square;
3. placement looks natural and not tightly piled;
4. H01 plant decoration is passable;
5. H04/H09/H14/H19 hard objects are impassable;
6. scrolling and Hunt/floor refresh are correct;
7. no TileB/TileD giant fragments or B/C/D/E automatic stamping returns.

Primary evidence: screenshots + movement interaction. No Battle LOG unless Runtime/battle fails. Only after all five pass: SHO-22 full Landmark collision + route audit.

## Install / Editor Rule
**This build updates `Data/Scripts.rvdata`.** Completely close RPG Maker VX before overwrite, then reopen RMVX afterward. Traditional Chinese tutorial `教學_v1.06.54.txt` is included and synchronized.
