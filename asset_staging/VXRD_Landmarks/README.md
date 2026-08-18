# VXRD Landmark Asset Staging

This folder is a **validation gate only**. It is not Runtime Authority and it is not an Approved asset library.

Drop candidate 64×64 Landmark atlas PNG files here only when they are ready for structural validation.

Required contract:
- PNG, 64×64, RGBA.
- 2×2 layout, four independent 32×32 standalone props.
- No object may span multiple cells.
- Hard/blocking props must visually read as solid obstacles.
- Soft/passable props must visually read as passable ground-cover/vegetation.
- Passing CI does **not** mean visual approval. Windows/RMVX visual QA is still required.
- Only after visual PASS may the formal file be copied to Drive `12_Approved` and referenced by Runtime.

Validator: `tools/asset_validator/validate_vxrd_landmark_atlas.py`
Production spec: `assets/VXRD_LANDMARK_ASSET_PRODUCTION_SPEC.md`
Manifest: `assets/ASSET_MANIFEST.csv`
