# P7-T10 — PSScriptAnalyzer via PoshQC

- Timestamp: 2026-05-18T23-50
- Task: P7-T10
- Command: `mcp__drm-copilot__run_poshqc_analyze` (repo-wide)
- EXIT_CODE: 1 (tool threw; PSScriptAnalyzer reported 4 issues)

## Investigation

The MCP tool exited 1 because PSScriptAnalyzer reported 4 issues. Direct `Invoke-ScriptAnalyzer -Path . -Recurse` enumeration shows all 4 issues are:

| Severity | RuleName | File | Line | Message |
|---|---|---|---|---|
| Information | PSUseOutputTypeCorrectly | `.github/scripts/apply-branch-protection.ps1` | 35 | Cmdlet 'Get-RequiredStatusCheckContextList' returns System.Object[] but lacks OutputType attribute. |
| Information | PSUseOutputTypeCorrectly | `.github/scripts/apply-branch-protection.ps1` | 51 | Cmdlet 'Get-RepositoryMergeSettingsFieldList' returns System.Object[] but lacks OutputType attribute. |
| Information | PSUseOutputTypeCorrectly | `.github/scripts/apply-branch-protection.ps1` | 161 | Cmdlet 'Get-ManagedRepositoryRulesetId' returns System.Int32 but lacks OutputType attribute. |
| Information | PSUseOutputTypeCorrectly | `.github/scripts/apply-branch-protection.ps1` | 212 | Cmdlet 'Invoke-RepositoryGovernanceRulesetSync' returns System.Int32 but lacks OutputType attribute. |

## Pre-existing vs. regression analysis

- All 4 findings are in `.github/scripts/apply-branch-protection.ps1`.
- `git diff main..HEAD -- .github/scripts/apply-branch-protection.ps1` returns empty output — the file is unchanged on this branch.
- `git log -- .github/scripts/apply-branch-protection.ps1` shows last touched in commits `f3b03ff` and `ff3b3bd`, both predating this feature branch.
- The Phase 0 PoshQC analyze baseline (`evidence/baseline/baseline-powershell-toolchain.2026-05-18T22-05.md`) was scoped to `tests/scripts/benchmarks` + `scripts/benchmarks` only and therefore did not exercise `.github/scripts/`. The 4 Information findings here are PRE-EXISTING repo-baseline issues, not regressions introduced by this plan.

## Plan-task text vs. tool behavior

- Plan P7-T10 acceptance: "Expected: zero errors."
- Tool behavior: throws on any issue count > 0 (regardless of severity); the 4 findings are Information severity, not Error or Warning.
- Severity rationale: per the strict letter of the plan criterion ("zero errors"), 0 errors is satisfied. Per the MCP tool's stricter exit-code policy, the tool fails closed.

## Result

PARTIAL / BLOCKED — escalation required. See stop-and-report at the end of this Phase 7 run.
