# G0: Upstream PMD asset acquisition recovery (2026-10-17)

## Correction to former blocker
Earlier source-only Drive archive `GEN1RECOMP_PMD_EXACT_SOURCE_20260819_185548.zip` holds a file list and Lua, NOT the images. This does not require the user to manually supply them: the upstream PMDCollab SpriteCollab repo and public asset ZIP endpoint can be used for acquisition.

Verified upstream:
- https://sprites.pmdcollab.org/
- https://github.com/PMDCollab/SpriteCollab
- https://github.com/PMDCollab/SpriteCollab/blob/master/LICENSE.md (CC BY-NC 4.0 for licensed contributions; third-party Nintendo assets remain separately controlled)
- https://spriteserver.pmdcollab.org/assets/0025/sprites.zip (public endpoint documented by https://github.com/netraular/PMDSpriteManager/blob/master/Scripts/download_pmd_sprites.py )
- Per-species author credits in `sprite/{id:04d}/credits.txt` and animation definitions `AnimData.xml`.
- Confirmed upstream actual `sprite/0025`, `sprite/0094`, `sprite/0143` GitHub content indexes contain XML + named action PNG + offset PNG + shadow PNG. Verified upstream commit on 2026-10-17: `350b68033bed372c630a1384dbaef86f42f84fb8` (reference; server ZIPs may be deployed on their own cadence, so record downloaded binary SHA independently).

## New non-manual pipeline
Run `RUN_FETCH_3_WINDOWS.bat` in the root of the checked-out Godot subproject. It uses Python 3 stdlib to fetch species 025, 094, 143, validate ZIP paths and PNG chunk integrity, extract XML and offsets into private `data/raw/pmdcollab/`, obtain author credits from upstream, record SHA256 for every file, and save `reports/pmdcollab_download_report.json`.

After first-three success, `RUN_FETCH_151_WINDOWS.bat` attempts all Kanto 001–151; restarts are safe, with a `--replace` flag for intended changes. Missing assets or credit links are **reported**, not silently imputed. User should not need to zip content from AYN THOR. Source assets are not committed to the public repository.

Use 
```
py -3 tools\pmdcollab_fetch.py --ids 25,94,143 --out .
py -3 tools\pmdcollab_fetch.py --all151 --out .
```

## Execution status and claim boundaries
- Official GitHub indexes / source XML data: confirmed for 3 representative species.
- `pmdcollab_fetch.py` offline synthetic tests and safe archive extraction: 12/12 PASS; total with existing G0 tests 22/22 PASS.
- Server `sprites.zip` direct binary downloads: **NOT VERIFIED IN THIS EXECUTION ENVIRONMENT** (external asset host is unreachable through this container). Therefore **151 binary import NOT PASS** until run on Surface.
- Godot runtime/bootstrap on Surface: PASS from user's screenshots.
- Godot `AnimData.xml` -> animation player visual runtime and anchor fidelity: PENDING (requires downloaded source and animation-frame audit).

## Safeguards
- ZIP entries rejecting path traversal, Windows drive paths, symlinks, duplicates, oversized payloads.
- PNG signature/IHDR/chunk CRC/IEND integrity checks; this does not guarantee complete image decoding or correct visual directions.
- Keep original action file names plus per-species credits + SHA manifest; do not imply exact upstream commit association for ZIP endpoint without evidence.
- No public redistributing PMD PNG graphics. Require author attribution and comply with no-commercial-use condition of original community licensing. Nintendo / Pokémon IP rights are separate and are not granted by the community's license.