# P4-T9 — Refactor check-conventional-commit.ps1: format + analyze

Timestamp: 2026-05-10T00-00
Command: mcp__drm-copilot__run_poshqc_format then mcp__drm-copilot__run_poshqc_analyze (scope: .githooks)
EXIT_CODE: 0
Output Summary:
- Refactored .githooks/check-conventional-commit.ps1 to expose top-level advanced function `Invoke-ConventionalCommitCheck` containing the full original logic.
- Script body invokes the function only when not dot-sourced (`if ($MyInvocation.InvocationName -ne '.') { exit ... }`); CLI contract (parameter `MessageFile`, exit codes 0/2/3/4, stderr messages) is unchanged.
- PoshQC format: exit 0; no diagnostics.
- PoshQC analyze: exit 0; no diagnostics. (Note: the analyzer flagged `PSUseOutputTypeCorrectly` Information findings on the bare verbatim body; the minimum mechanical adjustment of adding `[OutputType([int])]` to the function attributes was applied to clear them while preserving the CLI contract and all other behavior verbatim.)
