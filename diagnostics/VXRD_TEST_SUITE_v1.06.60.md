# PMD AutoChess v1.06.60 TEST SUITE — Map091 + A1 Matrix

Status: **TEST-ONLY**. Formal baseline remains **v1.06.58 FORMAL PASS**.

## Binary Authority
Drive Test Build:
`PMD_AutoChess_v1_06_60_TEST_SUITE_MAP091_A1_MATRIX_20260818.zip`
Drive ID `1KAk9KBZmZXWOmiL2tCGQ64aJHhM56Azl`.

ZIP SHA256: `5f256363aafedd7458fb5b31828ad58a5637c1374c987810d8527b4f65e93d08`
Scripts.rvdata SHA256: `6430d0f7b65923396a1676f968b6c381a3721542a881f8daa174efbdeb48bd3c`

## Script layout
Total = 648 Scripts.
- 0..643: Formal v1.06.58 byte-exact preserved.
- 644 / ID 1065910: A1 Interactive Matrix Probe v1.06.59a.
- 645 / ID 1066000: Map091 Full Acceptance Harness v1.06.60.
- 646 / ID 250: Main.
- 647 / ID 251: terminator.

This diagnostic layout is intentionally outside canonical Formal `exported_scripts` ordering and must not be promoted directly.

## Test A — H07 A1 Water Matrix
Context: RMVX Test Play, active H07 / Map090.
Control: **plain F5** only; Shift/Ctrl/Alt are excluded in the combined binary.

Pages:
1. 2240 / 2288 / 2336 / 2384
2. 2048 / 2096 / 2144 / 2192
3. 2432 / 2480 / 2528 / 2576
4. 2624 / 2672 / 2720 / 2768

The panels use RGSS2's real Tilemap + `Cache.system('TileA1')`. Map090 and Formal H07 base 2240 remain unchanged.
Output: `PMD_VXRD_A1MatrixProbe_LATEST.log`.

## Test B — Map091 Full Acceptance
Context: any active Random Hunt floor on Map090.
Control: **SHIFT+F5**.

Checks:
- v1.06.49 Template Authority audit;
- actual Map091 source event/page/graphic/trigger/list integrity;
- 49/49 deep Marshal clones;
- HUNT/FLOOR/WEIGHT/MAX/UNIQUE/NO_REPEAT parser contract;
- synthetic FIXED/CONTROL/SHARED + runtime-ID contract;
- v1.06.52 49-event / 126 Hunt-floor content matrix;
- current materialized template-event source metadata;
- runtime event-plan count alignment;
- non-destructive `Marshal.dump/load($game_map)` template-event preservation;
- Hunt-session Marshal roundtrip.

Output: `PMD_VXRD_Map091Acceptance_LATEST.log` plus temporary PASS/FAIL overlay.

Independent offline evidence is stored at `tests/MAP091_OFFLINE_SOURCE_AUDIT_v1.06.60.log` and already passes 49/49 source events, 49/49 deep clones and 126/126 Hunt-floor matrix.

## Safety / no regression
- Map090 mutation = 0.
- Map091 mutation = 0.
- Event relocation = 0.
- Route/topology rewrite = 0.
- Landmark mutation = 0.
- B/C/D/E auto-stamping = 0.
- Battle / reward / progression changes = 0.

## Installation
This test suite changes `Data/Scripts.rvdata`. Completely close RPG Maker VX before overwrite, then reopen RMVX. `Data/Map091.rvdata` is unchanged.
