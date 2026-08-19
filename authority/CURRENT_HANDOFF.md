# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-19 22:20 +08:00

## Persistent Authority
- Drive = Binary / Asset Authority.
- GitHub = Source / Spec / Validator / diagnostic-text Authority.
- Linear = Development Authority.
- ChatGPT = workspace only.

## User Direction
**Prioritize script/runtime progression.** Do not drift into image generation unless explicitly requested.

## Formal Baseline
**v1.06.62 — Gate 3 Floor-Depth Risk Curve + Settlement Visibility I — FORMAL PASS.**
Drive Baseline ID `1BIccvXgLp2Deu_RPYfT_dmEm43S5NXCW`.
Formal Scripts.rvdata SHA256 `61030225160f7ba2e1c12390183c841bcf038644c7b49fc2eb5069217129f190`.

GitHub `main` canonical = 648 Scripts, 0..647:
- 642 v1.06.57
- 643 v1.06.58
- 644 / ID1066100 v1.06.61
- 645 / ID1066200 v1.06.62
- 646 Main
- 647 terminator
v1.06.62 source SHA256 `bed1c3410378944656ff5f4a6b62615942bc02e27e74ef39bae8e4c42a1ee980`.
Main also preserves latest v2.4 map placement authority. `develop` is behind main by 0 and retains diagnostics/assets.

## v1.06.62 Windows Seal
SHO-51 Done.
Windows v1.06.62b:
- RESULT=PASS / STATIC_CURVE=PASS / CURRENT_FLOOR=PASS.
- H02 Style Preview correctly resolves canonical Floor1/3 while preview session max remains1.
- ProjectState schema43 / version1.06.62 PASS.
- Extra RNG=0 / map regen=0 / reward grant=0 / session mutation=0.
- Accepted floor-depth curves are sealed.

## Active Candidate — v1.06.63 / SHO-52
**Gate 3 Completion Incentive + Retreat Clarity I — UNPASSED.**

Production Candidate Drive ID `1rcFIdAHDQnnl8CcgsPX_8AcgHfpFkJVt`.
ZIP SHA256 `d68dc37c9f2977ef9c4892e13afff1fcbc2a6460659da8dd7f1324b58ddcdb3c`.
Scripts.rvdata SHA256 `c78066713e8a96822c7f89ec200a8d1f341d3c1edb452dc4932a86ac5d481205`.
Source SHA256 `bf3ed879de7ab6f6a435040311c32a418c155a28ea03e307643e63dee5a78aa8`.

Production = 649 Scripts:
- Formal v1.06.62 indices 0..645 byte-exact preserved.
- index646 / ID1066300 = v1.06.63.
- Main647 / terminator648.

Candidate rules:
- Full-clear Completion rolls = **2 / 2 / 3 / 4 / 5**.
- Only Tier5 changes 4→5.
- Completion remains full-clear only.
- Retreat / defeat Completion Bonus remains0; immediate rewards remain retained.
- No partial-clear bonus; no new items/materials/currency.
- Normal Battle/Treasure/Rare/Elite loot policy unchanged. Tier5 5-roll override is completion-context-only.
- Settlement text explicitly states Completion roll count or no-completion-bonus on retreat/defeat.

## Current Test Build — v1.06.63a
Drive ID `1vHRvjamHZhp9pqY43j1OZqmuBW5HzhD5`.
ZIP SHA256 `06f72f1018c5bfd0b0f13f98d9734101ae6d0770d484787c344d60c799a62f28`.
650 Scripts: Production index646, TEST index647 / ID1066310, Main648, terminator649.

User action:
1. Completely close RPG Maker VX.
2. Overwrite v1.06.63a and reopen RMVX.
3. Enter any active Random Hunt / Map090.
4. Press **plain F5**.
5. Return `PMD_GATE3_CompletionIncentive_LATEST.log`.

Expected PASS proves target curve2/2/3/4/5, normal loot policy unchanged, completion-only override5, retreat/defeat/partial bonus0, ProjectState schema44/version1.06.63, RNG0/reward grant0/map regen0/session mutation0.

## Sealed Context
- Gate1 structure and Battle Presentation sealed.
- Gate2 script/runtime sealed; Map091 sealed.
- v1.06.62 floor-depth Rare/Elite curve sealed.
- Gate2 art SHO-42 remains parallel/secondary.
- v2.4 map placement authority is preserved and must not be overwritten by Runtime branch work.

## Metadata Debt
SHO-47 Low: Game.ini title remains v1.05.40; metadata only.

## Install / Documentation Rule
Whenever a delivered build changes `Data/Scripts.rvdata` or another Data file: **fully close RPG Maker VX before overwrite, then reopen it.** Functional deliveries include synchronized Traditional Chinese documentation.