# Asset provenance / 151-first audit — DO NOT ASSUME COMPLETENESS
Source inspected: Gen1recomp `pmd_idle_battle_sprites_v0.1.95c_20260819` source snapshot, path list in `FILE_LIST.txt` (2026-08-19). The inventory is a PATH LIST; file existence/PNG parse/frame mapping still requires checking against a complete binary archive.

## Observed existing path inventory
- 151 `dex/001.png … dex/151.png`
- 151 `dex70` path records
- 302 `sprites/<NNN>_{player,enemy}.png` path records (151 × 2)
- 302 `static/<NNN>_{player,enemy}.png` path records
- 5,134 `motion/` PNG path records, differing by species/action/view
- 5,436 `shadow/` PNG path records
- 11,477 total .png path entries in this indexed MOD folder
- `motion_data.lua`, `data.lua`, `main.lua`, plus Motion Design Guide v1.0–v1.9 path records.

**Not confirmed:** that all the original image bytes are in the connected Drive, that all 151 species support each action, that each sheet is true 8-direction art, or that each PNG is licensed to redistribute.

## Authoritative old-project references
- PMD snapshot: https://drive.google.com/drive/folders/1m-L1WvQk7aoCz3qLswIBOZBaONyJs6nn
- Gen1recomp Master Project State: https://docs.google.com/document/d/1IWiFQJvBGlxmVAyFVKtoWb5s7SneA--iCFWJ8hRakF4/edit
- Gen1recomp PMD Source ZIP ID 19kcezsRaMtTHQQtA5PoUi0JnonOJJ5Ln
- Other project: PMD Species Personality Rich Ambient v2.8.5b (Ruby, distinct project). Use ideas, not direct drop-in engine code: https://drive.google.com/file/d/1qFhXUQA-NiRd12xvBKaD9Z_M7EHtiyMJ/view

## G0 import preflight required
1. Materialize exact source ZIP privately; record SHA-256 on ZIP and all extracted source art.
2. Reject path traversal/duplicate case-folded names; verify PNG signature, decode, dimensions and alpha.
3. Inventory (species 001–151) × (action enum) × (player/enemy) with status PRESENT/INVALID/MISSING/FALLBACK. Emit CSV/JSON.
4. Validate frame count, number of directions, per-frame anchors and hit-frame metadata by inspecting original `motion_data.lua` and actual sheets.
5. Record source license/provenance for each asset family and preserve credits; **do not commit copyrighted game assets into this public GitHub repo**.
6. Migration script must be idempotent and produce same manifest from identical inputs (hash gate).
7. Treat orientation suffix `player/enemy` as visual pose selection; do **not** assume they encode 8 directions.

Rights boundary: personal prototype/research first; publicly releasing Pokémon intellectual property or derivative PMD sprite sheets needs permission / an appropriate original or licensed asset strategy.
