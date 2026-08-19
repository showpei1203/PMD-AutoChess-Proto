# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-19 19:05 +08:00

## Persistent Authority
- Drive = Binary / Asset Authority.
- GitHub = Source / Spec / Validator / diagnostic-text Authority.
- Linear = Development Authority.
- ChatGPT = workspace only.

## User Direction
**Prioritize script/runtime progression.** SHO-42 art pipeline stays prepared but secondary unless art work is explicitly requested.

## Formal Baseline
**v1.06.61 — VXRD A1 Liquid Surface Semantic Authority II + ProjectState Convergence — FORMAL PASS.**
Drive Baseline ID `1VBidko6cYYcOAwTONmDe1p1lK_hTN3VU`.
Formal Scripts.rvdata SHA256 `eb5be92748d998bdf90540cba80bd6c3a280493fa874d5bba15fca127ab8ad00`.

GitHub `main` = 647 Scripts, 0..646:
- 642 v1.06.57
- 643 v1.06.58
- 644 / ID1066100 v1.06.61
- 645 Main
- 646 terminator
v1.06.61 source SHA256 `a07d64dafa83d30958edd6045281f820c9e08831ea56757d0e977e8b58461d7d`.
main merge commit `49f966b548b8e2e4d485cf55839bd03c1c7598cb`.

## Accepted v1.06.61 Water Semantics
- kind4/base2240 natural grass-ground clear water.
- kind6/base2336 castle/stone artificial clear water.
- kind8/base2432 rough dirt/cave clear water.
- kind10/base2528 other artificial clear water.
- kind14/base2720 lava.

Formal assignments: H02=2240, H07=2432, H12=2240, H17=2240.
User explicitly accepted H07 kind8/base2432 on Windows (`h07水正常`). SHO-41 Done.

## Map091 Seal
SHO-21 = Done / FORMAL PASS / SEALED.
Windows v1.06.61a evidence: 49/49 source/pages/graphics/triggers/lists, 49/49 semantic deep clones, parser12/12, FIXED/CONTROL/SHARED PASS, 126/126 Hunt/Floor matrix, runtime 9/9, Game_Map + Hunt-session Marshal PASS, no Map090/Map091 mutation.

## Gate 2 Script Seal
SHO-46 = Done.
v1.06.61b aggregate FAIL was TEST-only: only `map091_harness_missing` because it called the wrong method name. All Production-facing gates passed. Corrected v1.06.61c changes no Production byte and requires no rerun.
Gate 2 script/runtime work is sealed. Gate 2 overall remains In Progress only for dedicated visual/content asset coverage.

## Active Next Script Work — SHO-50 Gate 3 Baseline Audit I
Roadmap Gate 3 = Hunt Risk / Reward Curve.
Audit before tuning:
1. Rare / Elite room rates by tier and floor depth.
2. Completion bonus rolls/value and eligibility.
3. Retreat/defeat retained rewards versus completion-only bonus.
4. Run accounting fields: battles/wins/losses/escapes/recruits/treasures/recoveries/Rare/Elite/loot/floor wins/floors cleared.
5. What settlement UI currently shows versus what is only stored internally.
6. Mid-run Marshal/save-load preservation of accounting state.
7. Deterministic seed remains unchanged.

Known current source areas:
- v1.06.01 Room Type Authority.
- v1.05.78 Hunt Region Economy + v0.94 Loot Context Bonus Rolls.
- v1.06.04 Run Entry / stats initialization.
- v1.06.05 Floor Progression / Settlement.
- v1.06.06 Node lifecycle Treasure/Recovery accounting.
- v1.06.08 Battle/Recruit/Loot Accounting.
- v1.06.09 Save/Load Resume Safety.
- v1.06.29 sequential clear + retreat UX.

Phase I is TEST-only instrumentation, no balance changes. Only after the baseline log is proven may Phase II tune risk/reward.

## Known Metadata Debt
SHO-47 Low: `Game.ini` title still says v1.05.40. UI metadata only; not Runtime rollback.

## Immutable Rules
- No automatic B/C/D/E stamping.
- v1.06.44 Landmark IDs revoked.
- Map090 Runtime / Map091 Template Library roles unchanged.
- Gate1 + Battle Presentation sealed.
- Gate3 Audit I does not change Battle AI/damage/attack speed/Focus-C2/spatial endpoints/species acquisition.

## Install / Documentation
Whenever a delivered build changes `Data/Scripts.rvdata` or another Data file: **fully close RPG Maker VX before overwrite, then reopen it.** Functional deliveries include synchronized Traditional Chinese documentation.
