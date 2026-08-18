# VXRD Gravel-Bottom Clear Water Palette Probe v1.06.59

Status: **TEST-ONLY diagnostic**. Formal baseline remains **v1.06.58**.

## User-authoritative locator
The desired gravel/pebble clear-bottom water is **two editor palette cells to the right of the currently accepted H07/H12/H17 clear-bottom water**.

## Candidate under test
A1 base `2336` is used only as a falsifiable palette-mapping hypothesis.

The diagnostic applies candidate 2336 to **H07 only when `$TEST == true`**:
- H02 stays 2048.
- H12/H17 stay 2240.
- non-Test Play stays on formal v1.06.58 mapping.

No production Water Authority is changed by this probe.

## Diagnostic binary layout
The test-only binary contains 647 Scripts:
- canonical v1.06.57 remains index 642 / ID 1065700;
- canonical v1.06.58 remains index 643 / ID 1065800;
- diagnostic probe = index 644 / ID 1065900;
- Main = 645;
- terminator = 646.

The formal GitHub `exported_scripts` manifest intentionally remains the accepted v1.06.58 646-entry layout. Probe source lives under `diagnostics/`, not canonical runtime Source Authority.

## Acceptance
Enter H07 in RMVX Test Play and visually inspect one water pool.
- If it is the requested visible gravel/pebble bottom: candidate 2336 is visually confirmed and may be proposed for a later production semantic mapping candidate.
- If it is not: reject 2336 and keep v1.06.58 unchanged.

Expected diagnostic log: `PMD_VXRD_GravelWaterProbe_LATEST.log`.
