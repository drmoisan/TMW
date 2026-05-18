# Remediation — Final PoshQC Analyze (Phase 6, repo-wide)

Timestamp: 2026-05-15T23-25
Command:
1. Invoke-PoshQCAnalyze -Root . (repo-wide, all PowerShell files).
2. Invoke-PoshQCAnalyze -Root . -ScanFolders @('scripts/benchmarks','tests/scripts/benchmarks','scripts/powershell/PoshQC') (this remediation's full scope).

EXIT_CODE: 0 (within remediation scope); non-zero (4 Information-severity findings) at repo-wide scope, all pre-existing in `apply-branch-protection.ps1`.

Output Summary:
- Within the remediation scope (the four benchmark scripts, the four new Pester test files, the helper, and the new pester.runsettings.psd1): "PSScriptAnalyzer passed: no findings under ." — zero findings.
- Repo-wide scope reports 4 `PSUseOutputTypeCorrectly` Information findings in `.githooks/apply-branch-protection.ps1` at lines 35, 51, 161, 212. `git log -- '*apply-branch-protection.ps1'` shows the file's most recent change is commit f3b03ff `feat(branch-governance): manage main with repository rulesets`, prior to this remediation pass.
- No new analyzer findings are attributable to the four benchmark scripts, the four new Pester test files, the helper module, or the new `pester.runsettings.psd1`.

Acceptance: PASS for remediation scope (zero new analyzer findings introduced). The pre-existing apply-branch-protection.ps1 Information-severity findings are out of scope for this remediation pass.
