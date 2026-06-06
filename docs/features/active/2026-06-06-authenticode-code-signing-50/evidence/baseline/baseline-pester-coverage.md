# Baseline — Pester with Coverage

- Timestamp: 2026-06-06T11-45
- Task: [P0-T4]
- Command: `mcp__drm-copilot__run_poshqc_test` (workspace_root=`c:\Users\DanMoisan\repos\TMW`, scan_folders=`["tests/pester/powershell"]`); coverage config `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`
- EXIT_CODE: 0

## Output Summary

- Tests: 28 total, 0 failures, 0 errors, 0 skipped (all passing).
- Coverage (JaCoCo aggregate from `artifacts/pester/powershell-coverage.xml`):
  - LINE: covered=0, missed=284, total=284, line coverage = 0.00%
  - BRANCH: covered=0, missed=0, total=0, branch coverage = n/a (no branch counters emitted)

### Coverage scoping note (baseline reference)

The baseline coverage instrumentation targeted production files under `.claude/hooks/` (the harness's
configured global coverage set: `check-powershell-test-purity.ps1`, `check-python-test-purity.ps1`,
`enforce-powershell-batch-budget.ps1`, `enforce-python-batch-budget.ps1`, `validate-bash.ps1`), which are
not exercised by the `tests/pester/powershell` test scope used here. The 0.00% baseline therefore reflects
the harness's instrumented-file set, not the feature's target file (which does not yet exist). This baseline
value is the reference point for the no-regression delta check in Phase 4; the feature's own coverage is
measured at post-change in [P5-T3] against the new `Invoke-AuthenticodeSigning.ps1`, whose coverage will be
computed directly from the post-change JaCoCo report for that file.
