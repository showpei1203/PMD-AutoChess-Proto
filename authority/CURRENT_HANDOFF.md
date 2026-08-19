# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-19 22:40 +08:00

## Persistent Authority
- Drive = Binary / Asset Authority.
- GitHub = Source / Spec / Validator / diagnostic-text Authority.
- Linear = Development Authority.
- ChatGPT = workspace only.

## Formal Baseline
**v1.06.63 — Gate 3 Completion Incentive + Retreat Clarity I — FORMAL WINDOWS PASS.**

Drive Formal Baseline ID `1ge_N7CxmLjLoMqfVz66yVNnF40w9kJFD`.
Formal Scripts.rvdata SHA256 `c78066713e8a96822c7f89ec200a8d1f341d3c1edb452dc4932a86ac5d481205`.

Accepted v1.06.63 evidence:
- RESULT=PASS.
- completion rolls 2/2/3/4/5.
- normal loot policy unchanged.
- retreat/defeat/partial bonus0.
- ProjectState schema44/version1.06.63 PASS.
- RNG / reward grant / map regen / session mutation = 0.
- SHO-52 Done.

GitHub actual Formal tail = 649 Scripts:
- 645 v1.06.62.
- 646 / ID1066300 v1.06.63.
- 647 Main.
- 648 terminator.
Formal promotion commit `435b758f4b7cb4024e7c87b9bcc0ba5d22446fbe`.

Known metadata debt: `SCRIPT_INDEX.tsv` / `SCRIPT_ORDER.md` still have the old v1.06.62 tail because GitHub Actions did not execute the refresh workflow. Actual script files and Binary Formal are correct; refresh manifests at next Formal source promotion. Inactive workflow/trigger have been removed. Preserve concurrent map-authority v2.5 work on `main`.

## Current Work — SHO-53 / v1.06.64
**Gate 3 Run Accounting Semantic / Persistence I — WINDOWS CANDIDATE.**

Root cause:
- v1.06.08 legacy `loot_results` counts every matching Hunt loot result.
- Completion Bonus uses the same Hunt loot pool and resolves before final stats snapshot.
- Therefore completed-run `loot_results` contains Completion Bonus while settlement also describes Bonus separately.
- Reward is not duplicated; accounting semantics are mixed.

Candidate behavior:
- keep `loot_results` as total compatibility field.
- add `immediate_loot_results` and `completion_bonus_results`.
- classify using existing completion Context marker.
- active v1.06.63 legacy run migration is safe.
- old completed result fallback derives split from `completion_bonus[:results]`.
- first post-upgrade result migration order fixed to prevent double count.
- Marshal persistence verified in static fixture.
- settlement complete: `途中掉落 X｜通關 Bonus Y抽→Z項`.
- retreat/defeat: `途中掉落 X｜成果保留｜通關 Bonus 0`.
- no reward/RNG/Battle/Map/Item change.

Production Candidate Drive ID `1ew90l2THkDqtURm3gDv6gkyelUhbwCUF`.
Production ZIP SHA256 `274e0d348942c089a399c6fcc4f1496160557f03ed69f1fc3085c88ed1d02a8b`.
Production Scripts SHA256 `d1abb3249c54b55703fc05991a11da10090db625f9ca3176e60cb4dfda82fda8`.
650 Scripts; Formal0..646 preserved; v1.06.64 index647/ID1066400; Main648; terminator649.

Windows Test Build Drive ID `1dSaI1hH2ZTGzAl1tWPL-OXoSzaD05EMl`.
Test ZIP SHA256 `2f4eda23db0b38b5557738208b472c0538e46adb24bf2795a9f591468fac183b`.
Test Scripts SHA256 `a41e0ac0a89c0a5cbe2a2f5d061d16712e65d9cd28e34b0317bdb8d6ae8f2340`.
651 Scripts; TEST index648/ID1066410.

## User Acceptance Action
1. Fully close RPG Maker VX.
2. Overwrite with v1.06.64a TEST build.
3. Reopen RMVX.
4. Enter any active Random Hunt / Map090.
5. Press plain F5.
6. Expected overlay `Gate 3 Run Accounting PASS`.
7. Return `PMD_GATE3_RunAccounting_LATEST.log`.

TEST is read-only: RNG_CALLS=0 / REWARD_GRANT=0 / MAP_REGEN=0 / SESSION_MUTATION=0.

## Immutable / Sealed
- Gate1 structural Random Hunt and Battle Presentation sealed.
- Map091 sealed.
- v1.06.62 floor-depth curve sealed.
- v1.06.63 completion curve sealed.
- no automatic B/C/D/E stamping.
- v1.06.44 Landmark IDs revoked.
- no Battle AI/damage/attack-speed/Focus-C2/spatial endpoint/species acquisition changes in SHO-53.

## Install / Documentation
Any build changing `Data/Scripts.rvdata` or other Data files requires fully closing RPG Maker VX before overwrite and reopening afterward. Functional deliveries include synchronized Traditional Chinese documentation.
