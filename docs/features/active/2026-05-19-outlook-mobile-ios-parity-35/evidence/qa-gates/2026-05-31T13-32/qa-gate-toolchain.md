# QA Gate Toolchain — Start-MobileConnectivity npx resolver fix

Timestamp: 2026-05-31T13-32
Scope: scripts/powershell/Start-MobileConnectivity.ps1 + tests/pester/powershell/Start-MobileConnectivity.Tests.ps1
Toolchain channel: direct repo engines (Invoke-Formatter, PSScriptAnalyzer 1.24.0, Pester 5.6.1). MCP drm-copilot tools were not exposed in this session.

## Format

Command: Invoke-Formatter -ScriptDefinition <file content> for each in-scope file
EXIT_CODE: 0
Output Summary: FORMAT clean for both files (no rewrite required).

## Analyze

Command: Invoke-ScriptAnalyzer -Path <each in-scope file>
EXIT_CODE: 0
Output Summary: ANALYZE 0 findings across both files.

## Test + Coverage

Command: Invoke-Pester (Run.Path=tests/pester/powershell/Start-MobileConnectivity.Tests.ps1; CodeCoverage on scripts/powershell/Start-MobileConnectivity.ps1; UseBreakpoints=false)
EXIT_CODE: 0
Output Summary: Tests total=16 passed=16 failed=0 skipped=0. Line coverage 87.95% (73/83 commands); Pester reported "Covered 87.95% / 75%" (branch target met).

## Delta vs Baseline (2026-05-31T13-32 baseline)

- PSScriptAnalyzer delta: 0 new findings (0 -> 0).
- Failing-tests delta: 0 (0 -> 0). Test count 10 -> 16 (+6 new tests; all prior tests preserved and passing).
- Per-file / overall coverage delta: 86.96% -> 87.95% (+0.99 pp). No regression on changed lines.

## File Sizes

- scripts/powershell/Start-MobileConnectivity.ps1: 309 lines (< 500).
- tests/pester/powershell/Start-MobileConnectivity.Tests.ps1: 372 lines (< 500).

## Noted Limitation

The runtime failure mode (ShellExecute opening a .ps1 or extension-less target in an editor instead of executing it) is not observable through these seam-mocked unit tests, because Start-Process and Get-Command are mocked. The tests verify the Resolve-NpxPath contract (prefer npx.cmd; fallback selects only .cmd/.exe/.bat; exclude .ps1 and extension-less; throw when nothing launchable resolves) and that the resolved path is threaded through to the StartProcessAction FilePath. They cannot verify actual ShellExecute behavior on a real host.
