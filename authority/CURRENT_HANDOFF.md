# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 16:03 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Formal Baseline
**v1.06.55 — VXRD Landmark Route Safety Audit I — FORMAL PASS for H01/H04/H09/H14/H19 Phase-I scope.**
SHO-22 remains In Progress only for broader route stress / future remaining-Hunt expansion.

## Current Candidate
**v1.06.56 — VXRD Random Hunt Real Loading Overlay I — UNPASSED.**
- Implements SHO-35 using Battle Loading visual authority.
- 644 Scripts, indices `0..643`.
- New Script index `641` / ID `1065600`.
- Main index `642`; terminator `643`.
- Exact new source SHA256 `029c0a557ac44677d24110f8ca7be2933aa0c9296f5dc440e989f551d64f7d28`.
- Ruby syntax PASS; static validation **26/26 PASS**.

Drive Candidate ID: `1dts6xH3ozPwVTfjIUOfIawPulOY8qYQh`.
Drive Test Build ID: `1LUuIRCYZBszUEOBkZYd8esJpzyWkOZ1s`.

## v1.06.56 UX Rules
- Reuse battle Loading layout, blue progress bar, percentage, stage/detail text and running Pokémon mascot.
- Real checkpoints only; no fake timer and no artificial delay.
- Loading input passthrough remains disabled.
- 100% is shown only when reveal can happen immediately.
- Error path must dispose the overlay instead of leaving a permanent black screen.
- Map091 is unchanged.

## Immediate Test
1. **Completely close RPG Maker VX before overwriting v1.06.56**, because `Data/Scripts.rvdata` changes.
2. Overwrite the project and reopen RMVX.
3. Test first Hunt entry, next-floor generation, and leaving/re-entering another Hunt.
4. Confirm Loading visual matches Battle Loading; percent is monotonic; stage text changes; mascot runs; 100% reveals immediately; no white flash / stale previous-map residue / premature reveal / input passthrough.
5. Send one Loading screenshot and `PMD_VXRD_MapLoading_LATEST.log`.
6. Battle LOG is unnecessary unless Runtime/battle itself fails.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for Loading work.

## Documentation Rule
v1.06.56 includes synchronized `教學_v1.06.56.txt`.
