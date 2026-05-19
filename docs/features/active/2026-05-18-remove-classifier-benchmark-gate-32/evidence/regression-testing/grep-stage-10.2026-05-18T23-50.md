# P7-T1 — Tracked-file grep sweep for `stage-10-benchmark-regression`

- Timestamp: 2026-05-18T23-50
- Task: P7-T1
- Command (logical): `git ls-files | rg --files-from=- -n "stage-10-benchmark-regression"`
- Tool used: Grep (ripgrep) over working tree; untracked files cross-checked against `git status --porcelain` to ensure exclusion.

## Result

EXIT_CODE: 0 (treated as pass — all hits in allowlist).

Total hits across the working tree: 133 occurrences across 41 files.

Untracked working-tree files in the repo per `git status --porcelain`: only `testResults.xml` and the feature folder `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/` itself. No `testResults.xml` hits for this pattern.

## Allowlist verification

Allowlist (per Phase 7 scoping rule):
1. this plan file
2. `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/**`
3. `docs/features/potential/promoted/2026-05-18-remove-classifier-benchmark-gate.md`
4. anything under `docs/features/**` (historical-evidence carve-out)

Every one of the 41 matching files is located under `docs/features/**`. Zero matches outside the allowlist.

## Output Summary

PASS. Zero residual references outside the allowlist. The previously deleted live workflow `_stage-10-benchmark-regression.yml` and all live-code references to it have been removed.
