# Repository Agent Rules

For any image generation, image editing, game-art asset production, map/landmark visual generation, sprite generation, icon generation, or visual-asset prompt work in this repository, **read `ASSET_GENERATION_PRECHECK.md` before generating or editing any image**. Follow its required read order and the linked shared Google Drive authority.

For any runtime, Random Hunt/Map091 tooling, battle simulation, validator, generator/compiler, long-running diagnostic, automation, or test-harness design/change, **read `BACKGROUND_EXECUTION_AUTHORITY.md` before implementation**. Background-capable execution is a permanent project requirement; losing foreground focus must not unnecessarily stop automated progress. Do not use unsafe thread-based game-state/UI mutation as a shortcut, and preserve accepted/SEALED runtime authorities.

Pure documentation work that changes neither visual assets nor executable/runtime/test/tool behavior does not add extra preflight beyond the existing project authority.
