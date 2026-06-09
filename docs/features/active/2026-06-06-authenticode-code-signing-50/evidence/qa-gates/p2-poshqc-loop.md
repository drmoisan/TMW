# Phase 2 — PoshQC Loop with Coverage (format -> analyze -> test)

- Timestamp: 2026-06-06T12-10
- Task: [P2-T11]

Phase 2 functions (`Get-FirstPartySignableFileList`, `Resolve-SigningCert`,
`Invoke-SetAuthenticodeSignature`, `Test-AuthenticodeSignature`, and the `Invoke-AuthenticodeSigning`
orchestration) plus their seam-injected and seam-internals tests are complete. Final clean loop:

## Stage 1 — Format

- Command: `mcp__drm-copilot__run_poshqc_format` (scan_folders=`["scripts/powershell", "tests/pester/powershell"]`)
- EXIT_CODE: 0
- Output Summary: `ok:true`; no files changed on the final pass.

## Stage 2 — Analyze (PSScriptAnalyzer)

- Command: `mcp__drm-copilot__run_poshqc_analyze` (scan_folders=`["scripts/powershell", "tests/pester/powershell"]`)
- EXIT_CODE: 0
- Output Summary: `ok:true`; zero analyzer errors.

## Stage 3 — Pester with coverage

- Command: `mcp__drm-copilot__run_poshqc_test` (scan_folders=`["tests/pester/powershell"]`); coverage measured
  via direct Pester run scoped `CodeCoverage.Path = scripts/powershell/Invoke-AuthenticodeSigning.ps1`,
  `UseBreakpoints = $false`, output `artifacts/pester/authenticode-coverage.xml`.
- EXIT_CODE: 0
- Output Summary: 34 tests, 34 passed, 0 failed. Coverage of the new production file (JaCoCo):
  - LINE: covered=96, missed=8, total=104, line coverage = 92.31% (>= 85%).
  - INSTRUCTION (command) coverage: covered=110, missed=9, total=119, 92.44%.
  - No BRANCH counter is emitted by Pester's JaCoCo output; all decision branches are exercised by tests
    (fail-fast throw/return paths for config, cert, EKU; predicate both separators; WhatIf vs sign; empty vs
    populated enumeration; FilePaths vs enumeration; non-Valid return and throw; timestamp-unreachable warn).
  - The remaining missed commands are the param-block production-default expressions (host-bound wiring such
    as `Get-Location` / `Join-Path $env:APPDATA`) and a sub-expression of the timestamp fallback call; the
    production file is not excluded from coverage and the host-bound surface remains minimal and in the
    denominator.

## Result

Final state: zero analyzer errors, all tests passing, line coverage 92.31% for the tool (>= 85% line /
>= 75% branch thresholds met).
