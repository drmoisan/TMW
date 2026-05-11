# P4-T14 — CLI contract verification (lefthook + GitHub workflows)

Timestamp: 2026-05-10T00-00
Command: <Read> + Grep over lefthook.yml and .github/workflows/*.yml
EXIT_CODE: 0

## Call sites discovered

| File | Line | Invocation | Conclusion |
|---|---|---|---|
| lefthook.yml | 17 | `pwsh -NoProfile -File .githooks/check-conventional-commit.ps1 -MessageFile {1}` | no edit required |
| .github/workflows/pr-pipeline.yml | 15 | `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1` | no edit required |

## Output Summary

- `check-conventional-commit.ps1` is invoked by lefthook with the `-MessageFile {1}` parameter. After the [P4-T9] refactor, the script's outer `param()` block still declares `[Parameter(Mandatory = $true)] [string]$MessageFile`, and the body propagates `Invoke-ConventionalCommitCheck`'s integer return value as the process exit code via the `if ($MyInvocation.InvocationName -ne '.') { exit ... }` guard. Exit codes (0/2/3/4) and stderr text are unchanged. No edit required.
- `validate-quality-tiers.ps1` is invoked by `.github/workflows/pr-pipeline.yml` with no positional or named arguments (it relies on the `ConfigPath` parameter default). After the [P4-T10] refactor, the script's outer `param()` block still declares the same `ConfigPath` default (`Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', 'quality-tiers.yml'`), and the body propagates `Invoke-QualityTiersValidation`'s integer return value as the process exit code via the same guard. Exit codes (0/2/3/4/5/6), stderr text, and the success line on stdout are unchanged. The optional function-level `RepoRoot` parameter is not exposed at the script-level `param()` block, so this call site is unaffected. No edit required.

## Pass

Every call site listed; conclusion `no edit required` for every site.
