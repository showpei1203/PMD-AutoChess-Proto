# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-20 17:12 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## User Direction
Prioritize script/runtime progression. Gate 2 dedicated-art work remains parallel/secondary unless explicitly requested.

### QA Shortcut Governance — user-authoritative 2026-08-20
- Do not keep allocating new test hotkeys.
- Old unused **QA/test** shortcuts may be retired or reused.
- Prefer one current TEST-only entry point, initially plain F5 where scene-appropriate.
- Cleanup must target historical QA launcher/hook paths, not key symbols globally.
- Preserve real player/production controls. F8 in particular is also used by production navigation such as Vertical Slice return-to-camp and PMD menu return routing.

## Current Formal Baseline
**v1.06.66 — Gate 3 Integrated Seal Convergence I — FORMAL WINDOWS PASS / SEALED.**

Formal Binary Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_66_FORMAL_PASS_BASELINE_GATE3_INTEGRATED_SEAL_CONVERGENCE_I_20260820.zip`
Drive ID `1lZr0qjt6oCsH-G3UXBmsK_HHaeXbngwC`.
Formal ZIP SHA256 `2b97bdf14712627172bb9039603ef2a7d4359e21fc59894277b6bfb665ecfe61`.
Formal `Data/Scripts.rvdata` SHA256 `28986114dbb53abb9c3941e94ffc7b5607d1db7cc87b406cb922c1377adb7a16`.

Windows Gate 3 integrated acceptance:
- RESULT=PASS.
- Static v1.06.62 / v1.06.63-current / v1.06.64 PASS.
- Risk curve monotonic + exact endpoints PASS.
- H02 live context PASS; Tier1 Rare 18→30, Elite 0→0.
- Completion curve 2/2/3/4/5 PASS.
- Run accounting balanced PASS.
- ProjectState schema47 / v1.06.66 PASS.
- RNG_CALLS=0 / REWARD_GRANT=0 / MAP_REGEN=0 / SESSION_MUTATION=0.
- Gate 3 Risk / Reward core = SEALED / issue-driven only.

Linear SHO-54 = Done / SEALED.

## GitHub Formal Source
`main` canonical source = **651 Scripts, indices 0..650**:
- 645 / ID1066200 / v1.06.62.
- 646 / ID1066300 / v1.06.63.
- 647 / ID1066400 / v1.06.64.
- 648 / ID1066600 / v1.06.66.
- 649 / ID250 / Main.
- 650 / ID251 / terminator.

v1.06.65 was REJECTED and never entered canonical Formal Source.
Formal promotion evidence: `tests/FORMAL_PROMOTION_v1.06.66.log` = PASS.
Formal source promotion preserves Shared Map Layered Generation Authority v2.5.

### Canonical manifest debt — CLEARED
PR #10 `Refresh v1.06.66 canonical script manifests` merged successfully.
Merge commit `5c8d419bac03552b79ac4ea21982a6ed49f1331a`.
`SCRIPT_INDEX.tsv` / `SCRIPT_ORDER.md` now describe all 651 scripts and the v1.06.66 tail.
`tests/MANIFEST_REFRESH_v1.06.66.log` = PASS.
Runtime source was unchanged by this maintenance PR.

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

## Current Script Work — P8 / SHO-55
**SHO-55 — P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I — In Progress.**

No new production candidate has been created yet. Planned next candidate should start from v1.06.66 Formal and should not modify sealed gameplay merely to make a tester pass.

### P8 goals
- One consolidated cross-gate regression using existing accepted audit APIs rather than duplicating old rules.
- Gate 1: structural Random Hunt/VXRD invariants.
- Gate 2: Map091 semantics, Route Safety, A1 liquid semantic, Loading contract, no B/C/D/E automatic stamping, no Map090/Map091 mutation.
- Gate 3: v1.06.66 integrated risk/completion/accounting contract.
- Fast mode should be read-only/detached wherever possible and report exact blocker names.
- Reward/RNG/Map/Battle/Session mutation = 0 for the fast seal path.

### Shortcut audit already performed against Formal v1.06.66
Historical QA launchers still present include:
- F6 Important/Boss Focus deterministic fixture v1.05.19.
- F7 Vertical Slice Boss retest v1.01.4.
- F7 Representative Visual fixture v1.05.34.
- F8 Representative finding capture v1.05.35 (fixture-scoped).
- SHIFT+F7 Representative Transition fixture v1.05.37.
- SHIFT+F9 Important Species Manual QA v1.05.38.
- related historical visual/focused QA F8/F9 controls.

These are candidates for QA-launcher retirement/consolidation. Do not globally delete F8/F9 behavior; inspect whether a hook is test-only vs production first.

## Parallel / Deferred Work
- Gate 2 dedicated Landmark art SHO-42 remains parallel/secondary.
- Generated Runtime Asset Expansion batches remain end-of-development bulk work per prior authority; do not reintroduce them as sequential blockers.
- Battle Tempo P4 remains blocked until Motion completion.
- Game.ini title still shows `PMD AutoChess Proto v1.05.40`; tracked as low-priority UI/metadata debt (SHO-47), not Runtime rollback.

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
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt Runtime; Map091 = shared Event Template Library.

## Editor / Documentation Rule
Any functional delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires completely closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.
