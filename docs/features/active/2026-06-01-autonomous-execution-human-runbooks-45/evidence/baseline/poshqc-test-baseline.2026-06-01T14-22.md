# PoshQC Pester Test + Coverage Baseline (Issue #45)

Timestamp: 2026-06-01T14-22

Command: `mcp__drm-copilot__run_poshqc_test` (workspace_root=C:\Users\DanMoisan\repos\TMW, repo config `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`)

EXIT_CODE: 4

Output Summary:
- Pester suite: 178 tests, 4 failures, 0 errors, 0 skipped (JUnit `artifacts/pester/pester-junit.xml`).
- The 4 failures are pre-existing and OUT OF SCOPE for #45: all four are in `tests/scripts/dev-tools/enforce-pr-author-skill.Tests.ps1` (PR-author bypass cases — `gh pr create/edit --body-file`, `Get-PrAuthorBypassReason`, `Test-PrAuthorBypassRequired`). None of these are files this feature touches.
- Exit code 4 reflects those pre-existing failures. This is the recorded baseline failure set; #45 must not increase it.
- Coverage (JaCoCo `artifacts/pester/powershell-coverage.xml`): the report scopes coverage to the `.claude/hooks` package. The two in-scope hook files (`validate-orchestrator-output.ps1`, `validate-task-researcher-output.ps1`) are NOT present in the baseline coverage report because no Pester test files for them exist yet; their baseline line coverage = 0% and branch coverage = 0% (no tests). Other hook files reported in the baseline report show 0% line coverage as well (no dedicated tests in the executed set).
- Numeric baseline for the two in-scope files: LINE 0.00%, BRANCH 0.00% (no existing tests). These are the no-regression reference values for P5-T2; the post-change run must add the new test files and bring the two in-scope files to line >= 85% / branch >= 75%.
