# VXRD A1 Interactive Water Matrix Probe v1.06.59a

Status: **TEST-ONLY diagnostic**. Formal baseline remains **v1.06.58**.

This supersedes the one-candidate v1.06.59 H07=2336 probe for identification work. Do not require the old probe once v1.06.59a is available.

## Purpose
Use RGSS2's real `Tilemap` renderer to compare native A1 autotile bases without mutating Map090 or any Hunt profile.

## Controls
RMVX Test Play, H07 / Map090 only:
- press **F5** to open the matrix;
- press **F5** again to advance pages;
- after page 4, F5 closes it.

Page 1: `2240 / 2288 / 2336 / 2384`.
Page 2: `2048 / 2096 / 2144 / 2192`.
Page 3: `2432 / 2480 / 2528 / 2576`.
Page 4: `2624 / 2672 / 2720 / 2768`.

`2240` is visibly marked CURRENT because it is the accepted v1.06.58 H07 base.

## Safety
- no Map090 regeneration;
- no map-table mutation;
- no Hunt `water_base` mutation;
- no Map091 event materialization/relocation;
- no Route Safety rewrite;
- no Landmark changes;
- no B/C/D/E stamping;
- formal canonical `exported_scripts` manifest remains v1.06.58.

## Diagnostic binary
647 Scripts:
- 0..643 = Formal v1.06.58 preserved;
- 644 / ID `1065910` = this TEST-only probe;
- 645 = Main;
- 646 = terminator.

`Scripts.rvdata` SHA256: `b599ca4b7ba94e7c0e3844b53575d1d3e006be158d3da7245cc342d68c0a82b3`.
ZIP SHA256: `819b17b5ef5d7f143aea07ef07b74ae8907bfb2f822637c46c9daa2acb466ffc`.

Drive Test Build ID: `1C_GQw9a8NoOL2_C5Km848GUcE2cjMnzZ`.

## Acceptance
The user only needs to report the `base` label whose panel visually matches the requested clear water with gravel/pebble bottom. A screenshot is useful only if no panel matches.
