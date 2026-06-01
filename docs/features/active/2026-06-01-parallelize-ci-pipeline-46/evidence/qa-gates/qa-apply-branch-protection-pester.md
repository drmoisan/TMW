# QA Pester — apply-branch-protection.Tests.ps1 (regression anchor for invariant #2)

Timestamp: 2026-06-01T14-06
Command: pwsh -NoProfile -Command "Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI"
EXIT_CODE: 0

Output Summary: Discovery found 5 tests; Tests Passed: 5, Failed: 0, Skipped: 0,
Inconclusive: 0, NotRun: 0. Completed in ~673ms. The result matches the Phase 0
baseline (5/5 pass), confirming no status-check-context-name drift (invariant #2).

Untouched-files confirmation (git diff --name-only):
- .github/workflows/README.md
- .github/workflows/pr-pipeline.yml

Neither `tests/powershell/apply-branch-protection.Tests.ps1` nor
`.github/scripts/apply-branch-protection.ps1` appears in the change set. Both
branch-protection files are unmodified.
