# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-19 06:41 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub = Source / Spec / Validator / diagnostic-text Authority.
- Linear = Development Authority.
- ChatGPT = workspace only.

## User Direction
**Prioritize script/runtime progression.** SHO-42 art pipeline is prepared but should remain secondary unless the user explicitly requests art work.

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**
Formal Baseline Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.
`main` remains the Formal source baseline and must not be promoted until Windows/RMVX PASS.

## Current Production Candidate
**v1.06.61 — VXRD A1 Liquid Surface Semantic Authority II + ProjectState Convergence — UNPASSED.**
Drive Current Development ID `17wBUxbCF9A6Fqi0v1YX3CjEenqHhFCkp`.
ZIP SHA256 `f48603074cb21b6fd31e01b48807f9d6eb69ad2c5e397274e95b612c4b912ad7`.
Scripts.rvdata SHA256 `eb5be92748d998bdf90540cba80bd6c3a280493fa874d5bba15fca127ab8ad00`.

GitHub `develop` canonical tail:
- 642 / ID 1065700 / v1.06.57
- 643 / ID 1065800 / v1.06.58
- 644 / ID 1066100 / v1.06.61
- 645 / ID 250 / Main
- 646 / ID 251 / terminator
Total 647 Scripts, indices 0..646.
v1.06.61 source SHA256 `a07d64dafa83d30958edd6045281f820c9e08831ea56757d0e977e8b58461d7d`.
PR #5 exact finalizer PASS; manifests and source tail are canonical. `develop` is behind `main` by 0 after syncing new Agent/background rules via PR #4.

## User-Confirmed A1 Liquid Semantic Authority
- kind 4 / base 2240 = natural grass-ground visible-bottom water.
- kind 6 / base 2336 = castle / stone artificial-floor visible-bottom water.
- kind 8 / base 2432 = rough dirt / cave-ground visible-bottom water.
- kind 10 / base 2528 = other non-natural/artificial-floor visible-bottom water.
- kind 14 / base 2720 = lava.
Kinds 4/6/8/10 are valid clear-water choices selected by environment.

v1.06.61 current Hunt allocation:
- H02 -> kind4 / 2240 natural wetland.
- H07 -> kind8 / 2432 rough mud/marsh.
- H12 -> kind4 / 2240 retained natural presentation.
- H17 -> kind4 / 2240 retained natural presentation.
- kind6 and kind10 are registered but not forced into the current four water Hunts.
- kind14 is registered as lava only; no H19 lava/water-scope expansion.
Water scope stays H02/H07/H12/H17, native A1, rectangle-only, non-walkable, A2 shoreline, no rivers/bridges.

## ProjectState Convergence Fix
User Windows log from v1.06.60 reported `CURRENT_VERSION=1.06.56` while `SCRIPT_CONTAINER_ENTRIES=648`.
Root cause: v1.06.56 hardcodes CURRENT_VERSION inside the aliased `write_project_state_log`; v1.06.57/v1.06.58 did not re-converge the top-level version afterward.
v1.06.61 now rewrites ProjectState after the legacy writer chain:
- PROJECT_STATE_SCHEMA=42
- CURRENT_VERSION=1.06.61
- LATEST_FEATURE=A1_LIQUID_SURFACE_SEMANTIC_AUTHORITY_II+PROJECT_STATE_CONVERGENCE
- NEXT_TARGET=MAP091_FULL_ACCEPTANCE_WINDOWS+GATE2_SCRIPT_SEAL

## v1.06.60 Map091 FAIL Classification
**TEST HARNESS defect; current Runtime evidence healthy. Do not modify Map091 because of this FAIL.**
Windows evidence:
- source events/pages/graphics/triggers/lists = 49/49 healthy
- parser = 12/12 PASS
- content matrix = 126/126 PASS
- runtime materialization = 9 events / 9 plan events
- Game_Map Marshal roundtrip = PASS, 9 template events retained
- Hunt session Marshal roundtrip = PASS

False-fail causes:
1. Legacy v1.06.49 audit checks Floor1 with Hunt code=nil. After v1.06.52 Hunt-filtered contentization, Encounter/Rare/Elite/Info are intentionally filtered out, yielding exactly missing_encounter/missing_rare/missing_elite/missing_info.
2. v1.06.60 Harness incorrectly required Marshal re-dump byte identity for clones. Runtime contract is semantic deep independence.

Corrected semantic clone contract verifies equivalent canonical event state plus separate Event / Pages array / Page / command-list identities. Offline Formal Map091 result = **49/49 PASS**.

## Current Windows Test Build
**v1.06.61a — A1 Liquid + Map091 Acceptance Fix — TEST ONLY.**
Drive Test Build ID `13iAdnjkQmaacJ42TSs0OO_FDw5UIzZKv`.
ZIP SHA256 `782ddec5a6df6367433467f62beb7eeee7eaa0f91aa26284e331e6ba21fb1209`.
Scripts.rvdata SHA256 `f18e126746a50bd5f1eeb6c00bee46ccb8ac4f6dcc0a99c090df358894e92618`.

Test layout = 648 Scripts:
- 0..643 Formal v1.06.58 byte-exact preserved
- 644 / ID 1066100 = v1.06.61 Production
- 645 / ID 1066110 = corrected Map091 Acceptance Harness TEST-only
- 646 = Main
- 647 = terminator
Static validation = 31/31 PASS.
Map091 semantic clone offline = 49/49 PASS.

## Windows Acceptance Required
1. Fully close RMVX, overwrite v1.06.61a, reopen RMVX.
2. Visual water check: H02 kind4, H07 kind8, H12 kind4, H17 kind4. H07 is the material semantic change that most needs visual judgment.
3. On any active Map090 Hunt floor press **SHIFT+F5**.
4. Return `PMD_VXRD_Map091Acceptance_LATEST.log`.
Expected corrected result:
- RESULT=PASS
- CURRENT_TEMPLATE_AUTHORITY=PASS
- SOURCE_EVENTS=49/49
- DEEP_CLONES=49/49
- CONTENT_MATRIX=126/126
- runtime template events = runtime plan events
- GAME_MAP_MARSHAL_ROUNDTRIP=PASS
- SESSION_MARSHAL_ROUNDTRIP=PASS
Legacy v1.06.49 audit may remain FAIL only when `LEGACY_V10649_EXPECTED_NONBLOCKING=1`.
5. ProjectState top should now say CURRENT_VERSION=1.06.61. If it does not, return that log too.

## Accepted / Sealed Gate 2 Components
- v1.06.54 single-prop Landmark semantics/presence/collision PASS.
- v1.06.55 Route Safety SEALED.
- v1.06.56 real Loading overlay SEALED.
- v1.06.57 vegetation expansion visual PASS.
- v1.06.58 visible-bottom water baseline PASS.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / Battle Presentation SEALED / issue-driven only.
- No Battle AI, damage, attack speed, Focus-C2, rewards, progression, or spatial-endpoint changes for this work.

## Installation / Documentation Rule
Any delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires fully closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery must include synchronized Traditional Chinese tutorial/usage documentation.
