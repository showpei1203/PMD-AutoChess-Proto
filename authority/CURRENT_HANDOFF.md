# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-19 17:18 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub = Source / Spec / Validator / diagnostic-text Authority.
- Linear = Development Authority.
- ChatGPT = workspace only.

## User Direction
**Prioritize script/runtime progression.** SHO-42 art pipeline is prepared but remains secondary unless explicitly requested.

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**
Formal Baseline Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.
GitHub `main` remains Formal v1.06.58 until v1.06.61 completes Windows visual/runtime acceptance.

## Current Production Candidate
**v1.06.61 — VXRD A1 Liquid Surface Semantic Authority II + ProjectState Convergence — UNPASSED.**
Drive Current Development ID `17wBUxbCF9A6Fqi0v1YX3CjEenqHhFCkp`.
ZIP SHA256 `f48603074cb21b6fd31e01b48807f9d6eb69ad2c5e397274e95b612c4b912ad7`.
Scripts.rvdata SHA256 `eb5be92748d998bdf90540cba80bd6c3a280493fa874d5bba15fca127ab8ad00`.

GitHub `develop` canonical Production tail:
- 642 / ID 1065700 / v1.06.57
- 643 / ID 1065800 / v1.06.58
- 644 / ID 1066100 / v1.06.61
- 645 / ID 250 / Main
- 646 / ID 251 / terminator
Total 647 Scripts, indices 0..646.
v1.06.61 source SHA256 `a07d64dafa83d30958edd6045281f820c9e08831ea56757d0e977e8b58461d7d`.
PR #5 exact finalizer PASS. `develop` includes current main Agent/background rules and is behind main by 0 at the v1.06.61 finalization point.

## User-Confirmed A1 Liquid Semantic Authority
- kind4 / base2240 = natural grass-ground visible-bottom water.
- kind6 / base2336 = castle / stone artificial-floor visible-bottom water.
- kind8 / base2432 = rough dirt / cave-ground visible-bottom water.
- kind10 / base2528 = other non-natural/artificial-floor visible-bottom water.
- kind14 / base2720 = lava.
Kinds 4/6/8/10 are valid clear-water choices selected by environment.

v1.06.61 current Hunt allocation:
- H02 -> kind4 / 2240 natural wetland.
- H07 -> kind8 / 2432 rough mud/marsh.
- H12 -> kind4 / 2240 retained natural presentation.
- H17 -> kind4 / 2240 retained natural presentation.
- kind6/kind10 registered for later artificial-floor use.
- kind14 registered as lava only; no H19 lava/water-scope expansion.
Water scope remains H02/H07/H12/H17, native A1, rectangle-only, non-walkable, A2 shoreline, no rivers/bridges.

## SHO-21 — Map091 Acceptance — FORMAL PASS / SEALED
Windows/RMVX corrected v1.06.61a acceptance completed 2026-08-19.
Evidence:
- RESULT=PASS
- CURRENT_TEMPLATE_AUTHORITY=PASS
- SOURCE_AUTHORING_V10651=PASS
- CONTENTIZATION_V10652=PASS
- source/pages/graphics/triggers/lists = 49/49
- semantic deep clone = 49/49
- parser = 12/12 PASS
- FIXED/CONTROL/SHARED contract PASS
- Hunt/Floor content matrix = 126/126
- H07 Floor1 runtime template events = 9; runtime plan = 9
- Game_Map Marshal roundtrip PASS with 9 template events
- Hunt session Marshal roundtrip PASS
- RUNTIME_MUTATION=0; MAP091_MUTATION=0
- Battle/Reward/Progression changed = 0

Legacy v1.06.49 audit still reports missing Encounter/Rare/Elite/Info when called with Hunt code=nil, but is explicitly accepted as historical non-blocking behavior after v1.06.52 Hunt-filtered contentization (`LEGACY_V10649_EXPECTED_NONBLOCKING=1`).
The previous v1.06.60 FAIL was a TEST Harness defect; Map091 itself was not modified to obtain PASS.
SHO-21 is Done / future changes issue-driven only.

GitHub Windows evidence:
`tests/MAP091_WINDOWS_ACCEPTANCE_PASS_20260819.log`.

## ProjectState Convergence Fix
The v1.06.60 user log showed `CURRENT_VERSION=1.06.56` despite 648 loaded scripts. Root cause was the v1.06.56 aliased writer hardcoding CURRENT_VERSION after later `project_version` overrides.
v1.06.61 converges after the legacy writer chain:
- PROJECT_STATE_SCHEMA=42
- CURRENT_VERSION=1.06.61
- LATEST_FEATURE=A1_LIQUID_SURFACE_SEMANTIC_AUTHORITY_II+PROJECT_STATE_CONVERGENCE
Windows confirmation is part of the current Gate 2 Script Seal.

## Current Windows Test Build — v1.06.61b TEST ONLY
**v1.06.61b — Gate 2 Script Seal Harness.**
Drive Test Build ID `1Ed-ofSepkC7xG4g6D4jcTXguadgM6O5P`.
ZIP SHA256 `bddcbb3d2aa5ecfd84b5dc108470fb99c46b5a7f02bd0ae1c088b666bf3940db`.
Scripts.rvdata SHA256 `1930c302508c0a61b0249934781893683d89c357d8bf92a08f7c39d84eab9d1f`.

649 Scripts:
- 0..643 = Formal v1.06.58 byte-exact preserved
- 644 / ID1066100 = v1.06.61 Production
- 645 / ID1066110 = corrected Map091 Harness v1.06.61a TEST
- 646 / ID1066120 = Gate 2 Script Seal Harness v1.06.61b TEST
- 647 = Main
- 648 = terminator
Static/build validation PASS; 0..645 preserved from v1.06.61a; Harness Ruby syntax PASS.

Linear: SHO-46 `v1.06.61b — Gate 2 Script Seal Acceptance` In Progress.

### v1.06.61b User Action
1. Completely close RPG Maker VX before overwrite.
2. Install v1.06.61b, reopen RMVX and Test Play.
3. Enter any active Random Hunt floor on Map090.
4. Press **plain F5** only.
5. Return `PMD_VXRD_Gate2ScriptSeal_LATEST.log` if FAIL; PASS screenshot/log is sufficient to seal script gate.

Harness validates:
- v1.06.61 A1 semantic authority and four current water bases
- corrected/sealed Map091 contract
- Route Safety static 4/4 + current Hunt route/exit reachability
- Loading static contract
- ProjectState schema42 / CURRENT_VERSION=1.06.61 / test script count 649
- build-gated Formal 0..643 preservation
- B/C/D/E automatic stamping=0
- Map091 mutation=0; topology rewrite=0; no battle/reward/progression change

## Remaining Human Visual Gate — SHO-41
Machine checks cannot decide whether H07 kind8/base2432 looks aesthetically right for `霧澤泥地`.
Still need human visual judgment:
- H07 kind8/base2432 should suit rough mud/marsh.
- H02/H12/H17 kind4/base2240 should show no visual regression.
Do not mark SHO-41 Done until this visual acceptance is explicit.

## Accepted / Sealed Gate 2 Components
- v1.06.54 single-prop Landmark semantics/presence/collision PASS.
- v1.06.55 Route Safety SEALED.
- v1.06.56 real Loading overlay SEALED.
- v1.06.57 vegetation expansion visual PASS.
- v1.06.58 visible-bottom water baseline PASS.
- Map091 shared H01–H21 Event Template Library PASS / SEALED (SHO-21).

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / Battle Presentation SEALED / issue-driven only.
- No Battle AI, damage, attack speed, Focus-C2, rewards, progression, or spatial-endpoint changes for this work.

## Installation / Documentation Rule
Any delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires fully closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery must include synchronized Traditional Chinese tutorial/usage documentation.
