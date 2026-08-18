# PMD AutoChess — VXRD Draft Asset Intake / Approval Flow

Authority baseline: **v1.06.58 FORMAL PASS**

## Storage authority
Formal/draft raster assets stay on Google Drive, not GitHub.

- Draft generation output → `08_Assets/02_AI_Drafts`
- Hunt-specific working context → `08_Assets/11_Biomes/VXRD_Random_Hunt/<Hunt>`
- Approved production PNG → `08_Assets/12_Approved`
- Rejected/superseded drafts → `08_Assets/99_Archive`
- GitHub stores only specification, manifest, validator, evidence logs and runtime source.

## Draft naming
Use:
`<target_file_stem>__draft_<tool>_<NN>.png`

Examples:
- `relic_moonstone_a__draft_pixellab_01.png`
- `ice_shard_a__draft_retro_03.png`

Never overwrite another draft. Approved output uses the canonical target file name exactly, for example `relic_moonstone_a.png`.

## Mandatory machine gate
Run:
`python tools/asset_validator/validate_vxrd_landmark_atlas.py <file.png>`

Must satisfy before visual QA:
- exact 64×64;
- RGBA;
- all four 32×32 cells contain visible content;
- sufficient transparent padding;
- no fatal structural error.

A seam warning is not automatic failure, but requires visual inspection for one object accidentally crossing cell boundaries.

GitHub workflow `.github/workflows/vxrd_asset_validator_contract.yml` tests the validator contract with synthetic fixtures only. It intentionally does not store or upload production PNG assets to GitHub.

## Human QA gate
Check at native 1× first, then enlarged nearest-neighbor view.

1. Every cell reads as one complete prop.
2. Four variants belong to the same material/biome family.
3. Silhouettes are meaningfully different.
4. Hard/blocking art looks physically solid.
5. No unrelated biome motif.
6. No giant tile fragment, cropped architecture or half-object.
7. Pixel density and outline weight are compatible with the accepted v1.06.58 Landmark corpus.

## Approval mutation
Only after human PASS:
1. copy canonical PNG to Drive `12_Approved`;
2. calculate SHA256;
3. update `assets/ASSET_MANIFEST.csv`: `status=APPROVED`, SHA256, Drive location;
4. create the Runtime integration candidate;
5. update Traditional Chinese documentation;
6. Windows/RMVX in-game acceptance remains mandatory before Formal Baseline promotion.

## Rejection
Rejected output must not be silently edited into Approved status. Either create a new numbered draft or explicitly archive the old one with rejection notes. This preserves traceability and stops the usual creative-production ritual where nobody remembers which `final_final2_reallyfinal.png` was actually used.
