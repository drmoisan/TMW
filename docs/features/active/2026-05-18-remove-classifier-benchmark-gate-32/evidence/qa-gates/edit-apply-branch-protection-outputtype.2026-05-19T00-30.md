# [P6-T16] Add [OutputType(...)] to .github/scripts/apply-branch-protection.ps1

Timestamp: 2026-05-19T00-30
Command: Invoke-ScriptAnalyzer -Path .github/scripts/apply-branch-protection.ps1
EXIT_CODE: 0

## Functions Modified (per directive: lines 35, 51, 161, 212)

### Function 1: `Get-RequiredStatusCheckContextList` (line 31)
- Body returns `@('tier-classification', 'stage-1-format', ...)` — array of literal strings.
- PSScriptAnalyzer infers the literal array expression as `System.Object[]` (PowerShell does not auto-narrow `@(...)` of strings to `string[]` at AST analysis time).
- Inferred return type: `[object[]]`.
- Edit: added `[OutputType([object[]])]` between `[CmdletBinding()]` and `param()`.
- Rationale: matches the analyzer's inferred return type exactly, eliminating the `PSUseOutputTypeCorrectly` finding.

### Function 2: `Get-RepositoryMergeSettingsFieldList` (line 47)
- Body returns `@('allow_merge_commit=true')` — array literal of one string.
- Analyzer infers `System.Object[]`.
- Inferred return type: `[object[]]`.
- Edit: added `[OutputType([object[]])]`.

### Function 3: `Get-ManagedRepositoryRulesetId` (line 145)
- Body either returns `[int]$ruleset.id` from the loop or `return $null` after the loop.
- Inferred return type: `[int]` (with `$null` as the absence sentinel). Declared both: `[OutputType([int], [object])]` so the null path is also covered without overconstraining.
- Edit: added `[OutputType([int], [object])]`.

### Function 4: `Invoke-RepositoryGovernanceRulesetSync` (line 167)
- Body's final statement is `return 0` (literal integer).
- Inferred return type: `[int]`.
- Edit: added `[OutputType([int])]`.

## Verification

Command: `Invoke-ScriptAnalyzer -Path .github/scripts/apply-branch-protection.ps1`
Result: zero findings (no output).

Repo-wide `mcp__drm-copilot__run_poshqc_analyze` result: ok = true (zero findings repo-wide).

## Output Summary
- PSUseOutputTypeCorrectly findings on `apply-branch-protection.ps1`: 0 (was 4 pre-edit, then 2 after initial `[string[]]` attempt, then 0 after switching to `[object[]]` for the two array-literal returns).
- Repo-wide PoshQC analyze: PASS.
- No behavior changes; only `[OutputType(...)]` attribute additions.
