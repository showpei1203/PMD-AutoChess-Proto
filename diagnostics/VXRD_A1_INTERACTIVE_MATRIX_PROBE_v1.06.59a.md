# VXRD A1 Interactive Water Matrix Probe v1.06.59a

Status: **TEST-ONLY diagnostic**. Formal baseline remains **v1.06.58**.

The old one-candidate v1.06.59 H07=2336 probe is deprecated. The former standalone v1.06.59a package is also superseded operationally by the combined **v1.06.60 TEST SUITE**, so the user only needs one `Scripts.rvdata` for both water identification and Map091 acceptance.

## Current Binary Authority
`PMD_AutoChess_v1_06_60_TEST_SUITE_MAP091_A1_MATRIX_20260818.zip`
Drive Test Build ID `1KAk9KBZmZXWOmiL2tCGQ64aJHhM56Azl`.

Combined binary uses 648 Scripts:
- 0..643 = Formal v1.06.58 preserved;
- 644 / ID 1065910 = A1 Interactive Matrix Probe;
- 645 / ID 1066000 = Map091 Full Acceptance Harness;
- 646 = Main;
- 647 = terminator.

## Purpose
Use RGSS2's real `Tilemap` renderer to compare native A1 autotile bases without mutating Map090 or any Hunt profile.

## Controls in v1.06.60 suite
RMVX Test Play, H07 / Map090 only:
- press **plain F5** to open the matrix;
- press **plain F5** again to advance pages;
- after page 4, F5 closes it;
- Shift/Ctrl/Alt are excluded from this shortcut so **SHIFT+F5** belongs exclusively to the Map091 harness.

Page 1: `2240 / 2288 / 2336 / 2384`.
Page 2: `2048 / 2096 / 2144 / 2192`.
Page 3: `2432 / 2480 / 2528 / 2576`.
Page 4: `2624 / 2672 / 2720 / 2768`.

`2240` is marked CURRENT because it is the accepted v1.06.58 H07 base.

## Safety
- no Map090 regeneration or map-table mutation;
- no Hunt `water_base` mutation;
- no Map091 materialization/relocation;
- no Route Safety or Landmark changes;
- no B/C/D/E stamping;
- Formal canonical `exported_scripts` manifest remains v1.06.58.

## Acceptance
Report the `base` label whose panel visually matches the requested clear water with gravel/pebble bottom. If none matches, one screenshot is sufficient.

Output log: `PMD_VXRD_A1MatrixProbe_LATEST.log`.
