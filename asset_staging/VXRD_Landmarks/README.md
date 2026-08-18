# VXRD Landmark Asset Staging Policy

This directory is **documentation-only**. Do **not** commit PNG, ZIP, RVData, Graphics, Audio, or other binary asset files here.

PMD AutoChess GitHub remains text/source/spec/test Authority only.

## Candidate asset flow
1. Draft/candidate PNG lives in Google Drive `08_Assets`, normally `02_AI_Drafts` and/or the matching `11_Biomes/VXRD_Random_Hunt/Hxx_*` folder.
2. Run `tools/asset_validator/validate_vxrd_landmark_atlas.py` against the local/downloaded PNG.
3. Commit only the resulting text/JSON/LOG evidence and manifest update to GitHub.
4. Perform Windows/RMVX visual QA.
5. After PASS, move/copy the approved PNG to Drive `12_Approved` and include it in the next Runtime binary delivery.

Required atlas contract:
- PNG, 64×64, RGBA.
- 2×2 layout, four independent 32×32 standalone props.
- No object may span multiple cells.
- Hard/blocking props must visually read as solid obstacles.
- Soft/passable props must visually read as passable ground-cover/vegetation.
- Structural validator PASS does **not** equal visual approval.

GitHub Actions tests the validator itself using synthetic fixtures; it does not ingest production PNGs.

Validator: `tools/asset_validator/validate_vxrd_landmark_atlas.py`
Production spec: `assets/VXRD_LANDMARK_ASSET_PRODUCTION_SPEC.md`
Manifest: `assets/ASSET_MANIFEST.csv`
