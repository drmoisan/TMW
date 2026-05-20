# QA Gate — Mobile Connectivity PowerShell Scripts

Timestamp: 2026-05-20T16-05
Scope:
- scripts/powershell/Start-MobileConnectivity.ps1 (production; no change required, verified complete)
- scripts/powershell/Stop-MobileConnectivity.ps1 (production; added SupportsShouldProcess + ShouldProcess guard to the Remove-ConnectivityState helper to clear PSUseShouldProcessForStateChangingFunctions)
- tests/pester/powershell/Start-MobileConnectivity.Tests.ps1 (new)
- tests/pester/powershell/Stop-MobileConnectivity.Tests.ps1 (new)

## Canonical MCP Toolchain Status

The repository policy designates the PoshQC MCP tools as the canonical toolchain:
`mcp__drm-copilot__run_poshqc_format`, `mcp__drm-copilot__run_poshqc_analyze`,
`mcp__drm-copilot__run_poshqc_test`.

These MCP tools were NOT available in the executing agent session (not present in the
available tool set). The equivalent underlying operations were run locally with the same
engines PoshQC wraps (Invoke-Formatter, Invoke-ScriptAnalyzer, Pester 5.6.1). Treat the
canonical MCP-run as PENDING re-execution by an environment with the MCP tools available.

## Format (Invoke-Formatter)

Command: `Invoke-Formatter -ScriptDefinition (Get-Content -Raw <file>)` per file, idempotency check
EXIT_CODE: 0
Output Summary: format diffs: 0 across all four files (already formatter-clean).

## Analyze (Invoke-ScriptAnalyzer, default rules)

Command: `Invoke-ScriptAnalyzer -Path <file>` for each of the four files
EXIT_CODE: 0
Output Summary: 0 findings across all four files (production + tests).

## Test (Pester 5.6.1, coverage enabled)

Command: `Invoke-Pester` with Run.Path = the two test files, CodeCoverage.Path = the two
production scripts, UseBreakpoints = $false, Should.ErrorAction = Stop.
EXIT_CODE: 0
Output Summary:
- Tests Passed: 25, Failed: 0, Skipped: 0
- Code coverage: 113/131 commands = 86.26% (threshold: line >= 85%, branch >= 75%; Pester reported "86.26% / 75%").
- Missed commands are param-block default expressions (GetTempPath/Join-Path), the
  default seam scriptblock bodies (whose delegated targets Invoke-StartProcess,
  Resolve-DevTunnelPath, Invoke-StopProcess, Remove-ConnectivityState, Read-ConnectivityState
  are individually covered), and the two unavoidable raw I/O lines
  (Set-Content -Encoding utf8, Get-Content -Raw) whose JSON transforms are exercised
  end-to-end via the positive start/stop flows.

## Determinism

- No real processes started or stopped; Start-Process/Get-Process/Stop-Process are mocked
  (framework cmdlets) or routed through injected seam scriptblocks.
- No real devtunnel resolution; Get-Command/Test-Path mocked.
- No temp files created; state-file path injected as in-memory strings; no real read/write.
- No network or PATH dependency; fixed clock injected via NowProvider for StartedAt.

## Deltas vs Baseline

- PSScriptAnalyzer delta: 0 new findings.
- Failing-tests delta: 0.
- New-file coverage: 86.26% line (>= 85%) and branch >= 75% per Pester report.
