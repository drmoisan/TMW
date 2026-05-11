# P4-T10 — Refactor validate-quality-tiers.ps1: format + analyze

Timestamp: 2026-05-10T00-00
Command: mcp__drm-copilot__run_poshqc_format then mcp__drm-copilot__run_poshqc_analyze (scope: .github/scripts)
EXIT_CODE: 0
Output Summary:
- Refactored .github/scripts/validate-quality-tiers.ps1 to expose top-level advanced function `Invoke-QualityTiersValidation` containing the full original logic.
- Added optional `-RepoRoot` parameter to the function only (not exposed at script-level `param()` block), preserving the CLI signature and lefthook/CI invocation contract.
- Script body invokes the function only when not dot-sourced (`if ($MyInvocation.InvocationName -ne '.') { exit ... }`); CLI contract (parameter `ConfigPath`, exit codes 0/2/3/4/5/6, stderr/stdout text) is unchanged.
- PoshQC format: exit 0; no diagnostics.
- PoshQC analyze: exit 0; no diagnostics. (Note: `[OutputType([int])]` was added to the function attributes as a minimum mechanical adjustment to clear `PSUseOutputTypeCorrectly` Information findings, preserving the CLI contract and all other behavior verbatim.)
