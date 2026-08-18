# PMD AutoChess Proto — Background Execution Authority

Version: 2026-08-19

This repository inherits the shared Google Drive authority `SHARED_BACKGROUND_EXECUTION_AUTHORITY` (Drive file ID `1OMLXIcw9MU0Vi3RW4THN0nHQ7ZiDt16LjpODMjq5V7M`).

## Permanent rule
- Runtime, Random Hunt generation, Map091 acceptance, battle simulations, validators, generators/compilers and long-running diagnostics must be background-capable: losing foreground focus must not unnecessarily stop progression.
- Hotkeys may start a diagnostic, but automated progression should continue without foreground keyboard focus and should emit LOG/status evidence.
- Foreground-only work is allowed only for explicitly visual/manual acceptance.
- Background execution does **not** authorize unsafe thread-based mutation of RMVX game-state/UI.
- Prefer normal-loop state machines, staged jobs, detached/offline validators and external tooling.
- Accepted Battle Presentation and SEALED runtime are not reopened merely by this policy; new/touched infrastructure must comply without regression.

## Acceptance
A new infrastructure/harness path is not acceptance-complete if it unnecessarily stops just because another application becomes active.
