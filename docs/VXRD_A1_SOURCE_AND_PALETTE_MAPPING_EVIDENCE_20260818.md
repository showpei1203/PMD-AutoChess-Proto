# VXRD A1 Source / Palette Mapping Evidence — 2026-08-18

Status: diagnostic evidence only. Formal Water Authority remains **v1.06.58**.

## 1. Live project source audit
Captured Windows live project snapshot:
`PMD_AutoChess_WINDOWS_LIVE_FULL_PROJECT_SNAPSHOT_NEEDS_REVIEW_20260818.zip`
Drive ID `1Aqn2pCP9zdl6BXWyCQTE3nLIK4gbA8Oz`.

Direct ZIP audit found seven `Graphics/System` files and **zero** project-embedded `Graphics/System/TileA1.*` files.
Evidence: `tests/VXRD_LIVE_A1_SOURCE_AUDIT_20260818.log`.

Conclusion: current Random Hunt water lookup is constrained to the standard RPG Maker VX / RTP A1 family unless a separate runtime override is later proven.

## 2. Existing Formal runtime mapping
v1.06.58 Authority already establishes:
- A1 tile-ID start = `2048`.
- one autotile kind stride = `48` IDs.
- current H07/H12/H17 base `2240` = kind `(2240 - 2048) / 48 = 4`.
- v1.06.59 diagnostic candidate `2336` = kind `(2336 - 2048) / 48 = 6`.

Formal mapping remains:
- H02 = 2048.
- H07 = 2240.
- H12 = 2240.
- H17 = 2240.

## 3. Official VX A1 material structure
Official RPG Maker VX material specifications describe `TileA1` as a 512×384 animated autotile sheet assembled from five block types. The water-related structure includes water autotiles and waterfall blocks; water-family visual palette layout is therefore not safely reducible to a single linear left-to-right kind sequence without checking the editor palette arrangement.

Official reference:
`https://rpgmakerofficial.com/product/products/rpgvx/material/index.html`

## 4. User-authoritative locator
Desired gravel/pebble clear-bottom water:
**two editor palette cells to the right of the currently accepted H07/H12/H17 water**.

Important interpretation rule:
`two palette cells to the right` MUST NOT automatically be translated into `autotile kind + 2` unless palette-cell-to-kind ordering is demonstrated.

Therefore `2336 / kind 6` remains a falsifiable diagnostic candidate, not Formal Authority.

## 5. Current acceptance method
v1.06.59 TEST-only probe changes H07 only while `$TEST == true`:
- H07 candidate = 2336.
- H02 = 2048 unchanged.
- H12/H17 = 2240 unchanged.
- non-Test Play = v1.06.58 unchanged.

A single Windows/RMVX H07 screenshot or user visual confirmation is sufficient to accept/reject candidate 2336. If rejected, the next probe must be based on demonstrated palette ordering rather than arithmetic proximity alone.
