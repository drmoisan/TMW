# P7-T4 — Tracked-file grep sweep for `compare-benchmarks.ps1`

- Timestamp: 2026-05-18T23-50
- Task: P7-T4
- Command (logical): `git ls-files | rg --files-from=- -n "compare-benchmarks\.ps1"`
- Tool used: Grep (ripgrep) over working tree; untracked files cross-checked against `git status --porcelain`.

## Result

EXIT_CODE: 0 (pass — all tracked-file hits in allowlist).

Total raw hits across working tree: 102 occurrences across 44 files.

Note: `testResults.xml` shows 25 hits for this pattern, but `testResults.xml` is an UNTRACKED file (`?? testResults.xml` in `git status --porcelain`); the tracked-file scoping rule (P7 grep scoping via `git ls-files`) excludes it by construction. All remaining 43 hit files are under `docs/features/**`.

P6-T15 (just completed) removed the previously-blocking XML doc-comment hit in `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`. That file is not in the current hit list.

## Allowlist verification

All 43 tracked-file matches are under `docs/features/**` (allowlist item 4). Zero tracked matches outside the allowlist.

## Output Summary

PASS. Zero residual tracked-file references to `compare-benchmarks.ps1` outside the historical-evidence allowlist. Previously-blocking hit in `BenchmarkConfig.cs` discharged by P6-T15.
