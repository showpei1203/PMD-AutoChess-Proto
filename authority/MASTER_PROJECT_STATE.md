# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-20 17:37 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## User Direction
Prioritize script/runtime progression. Gate 2 dedicated-art work remains parallel/secondary unless explicitly requested.

### QA Shortcut Governance — accepted in v1.06.67
- Do not keep allocating new permanent test hotkeys.
- Historical unused QA/test launchers may be retired or reused.
- Current consolidated TEST-only entry point = plain **F5 on Scene_Map**.
- Cleanup is hook-specific, never a global key-symbol ban.
- Production/player F8 behavior is preserved, including Vertical Slice return-to-camp and PMD menu return routing.
- Fixture-internal F8 finding controls remain callable inside their historical fixture methods, but those fixtures no longer own permanent launcher hotkeys.

## Current Formal Baseline
**v1.06.67 — P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I — FORMAL WINDOWS PASS / SEALED.**

Formal Binary Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_67_FORMAL_PASS_P8_CROSS_GATE_REGRESSION_QA_SHORTCUT_CONSOLIDATION_I_20260820.zip`
Drive ID `19pEv3PldwLNuD2G8RnSJunDfekZfOaam`.
Formal ZIP SHA256 `183112304b9a6e546b183a273576bba89df1fc4060350f3f8f34f6d4e7024c9a`.
Formal `Data/Scripts.rvdata` SHA256 `91495233cd3d38572a9bcd5091e8d1076ea1260c5126a0a99cca9edfdb9c3c4b`.

Windows P8 Fast Seal acceptance:
- RESULT=PASS.
- GATE1=PASS / GATE2=PASS / GATE3=PASS.
- BLOCKERS=0.
- HARNESS_EXTRA_RNG_CALLS=0.
- REWARD_GRANT=0.
- MAP_MUTATION=0, including Map090/091 file mutation=0 and live Map090 table mutation=0.
- VXRD_STATE_MUTATION=0 / SESSION_MUTATION=0 / PARTY_MUTATION=0.
- BATTLE_LAUNCH=0.
- Production F8 preserved.
- stale v1.06.10 aggregate audit intentionally not used as a P8 blocker.

Linear SHO-55 = Done / SEALED after Windows acceptance and Authority promotion.

## GitHub Formal Source
`main` canonical source = **652 Scripts, indices 0..651**:
- 645 / ID1066200 / v1.06.62.
- 646 / ID1066300 / v1.06.63.
- 647 / ID1066400 / v1.06.64.
- 648 / ID1066600 / v1.06.66.
- 649 / ID1066700 / v1.06.67 P8 Cross-Gate Regression + QA Shortcut Consolidation.
- 650 / ID250 / Main.
- 651 / ID251 / terminator.

v1.06.65 remains REJECTED and never entered canonical Formal Source.
Formal promotion evidence:
- `tests/STATIC_VALIDATION_v1.06.67.log` = PASS.
- `tests/P8_CROSS_GATE_WINDOWS_ACCEPTANCE_v1.06.67.log` = PASS.
- `tests/FORMAL_PROMOTION_v1.06.67.log` = PASS.

P8 source delta is intentionally narrow:
- historical launcher hooks retired at indices 401, 503, 519, 521, 522, 523;
- Gate 3 sealed tail 645..648 remains byte-exact from v1.06.66;
- production F8 source rows remain byte-exact;
- new consolidated harness is index 649 only.

## Accepted Gate 3 Runtime
### v1.06.62 — Floor-Depth Risk Curve
- deepest-floor Rare bonus +12pp; Elite +15pp; cap85.
- Tier endpoints: T1 R18→30/E0→0; T2 R28→40/E30→45; T3 R40→52/E42→57; T4 R52→64/E55→70; T5 R65→77/E70→85.
- deterministic seed-derived promotion; no extra RNG.

### v1.06.63 — Completion Incentive
- full-clear completion rolls by Tier = 2 / 2 / 3 / 4 / 5.
- retreat / defeat / partial-clear Completion Bonus = 0.
- normal loot policy unchanged.

### v1.06.64 — Run Accounting
- `loot_results` = legacy-compatible total.
- `immediate_loot_results` = in-run results excluding Completion Bonus.
- `completion_bonus_results` = Completion-only actual results.
- active legacy migration / completed-result fallback / Marshal persistence SEALED.

### v1.06.66 — Integrated Gate 3 Seal
- current semantic contract integrates v1.06.62/.63/.64.
- historical v1.06.63 text-only audit is nonblocking after accepted v1.06.64 settlement copy change.
- active/QA/vxrd-state context acceptance was validated on Windows.

## P8 Cross-Gate Regression — accepted v1.06.67
Gate 1 current structural coverage:
- wall geometry.
- regular water shape.
- visual style scope.
- current tileset semantic.
- room runtime API.
- node lifecycle API.
- save/resume API.
- current room visual state.
- live Map090 context.

Gate 2 current coverage:
- Map091 authoring/source audit.
- 49-source-event / 126 Hunt×Floor content matrix.
- current materialization state.
- Landmark semantic audit.
- Route Safety static + read-only live audit.
- Loading contract.
- current A1 liquid semantics.
- automatic B/C/D/E stamping = 0.

Gate 3 current coverage:
- direct reuse of v1.06.66 integrated seal contract.
- floor-depth risk curve.
- completion 2/2/3/4/5.
- total/immediate/completion accounting.
- read-only summary/persistence semantics.

Fast Seal mutation contract:
- extra RNG=0.
- Reward=0.
- Map090/091 mutation=0.
- Battle launch=0.
- Session/VXRD/Party mutation=0.

## Shortcut Consolidation — SEALED
Retired permanent QA launchers:
- F7 v1.01.4 Boss retest.
- F6 v1.05.19 Important/Boss Focus fixture.
- F7 v1.05.34 Representative Visual fixture.
- F9 v1.05.36 Sandshrew Focused Review.
- SHIFT+F7 v1.05.37 Transition fixture.
- SHIFT+F9 v1.05.38 Important Species fixture.

Preserved:
- Production F8 Vertical Slice / PMD menu return paths.
- Fixture-scoped F8 finding controls.
- Historical QA methods remain available for issue-driven/API diagnosis even though permanent launcher hooks are retired.

## Parallel / Deferred Work
- Gate 2 dedicated visual work remains active in SHO-7 / SHO-42 and is parallel/secondary to script work.
- Generated Runtime Asset Expansion batches remain end-of-development bulk completion; do not restore them as sequential blockers.
- Battle Tempo P4 remains blocked until Motion completion.
- SHO-47 stale `Game.ini` title is low-priority UI/metadata debt.
- P8 opens no new gameplay authority. Any next script/runtime change must be issue-driven and start from v1.06.67 Formal.

## Sealed Runtime / No Regression
- Gate 1 structural Random Hunt SEALED.
- Battle Presentation SEALED / issue-driven only.
- Map091 H01–H21 Event Template Library FORMAL PASS / SEALED.
- v1.06.54 Landmark semantic/collision PASS.
- v1.06.55 Route Safety SEALED.
- v1.06.56 Loading overlay SEALED.
- v1.06.57 vegetation visual PASS.
- v1.06.58 visible-bottom water PASS.
- v1.06.61 A1 liquid semantic PASS.
- Gate 3 v1.06.62/.63/.64/.66 SEALED.
- v1.06.67 P8 validation/shortcut consolidation SEALED.
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt Runtime; Map091 = shared Event Template Library.

## Editor / Documentation Rule
Any functional delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires completely closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.
