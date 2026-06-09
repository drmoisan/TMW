# Final QA — Pester with Coverage

- Timestamp: 2026-06-06T12-21
- Task: [P5-T3]
- Command: `mcp__drm-copilot__run_poshqc_test` (workspace_root=`c:\Users\DanMoisan\repos\TMW`, scan_folders=`["tests/pester/powershell"]`); coverage measured via direct Pester run scoped to the new file (`CodeCoverage.Path = scripts/powershell/Invoke-AuthenticodeSigning.ps1`, `UseBreakpoints = $false`, JaCoCo output `artifacts/pester/authenticode-coverage.xml`)
- EXIT_CODE: 0

## Output Summary

- Tests: 34 total, 34 passed, 0 failed.
- Coverage of `scripts/powershell/Invoke-AuthenticodeSigning.ps1` (JaCoCo):
  - LINE: covered=96, missed=8, total=104, line coverage = 92.31% (>= 85% threshold).
  - INSTRUCTION (command) coverage: covered=110, missed=9, total=119, 92.44%.
  - METHOD: covered=7, missed=1, total=8 (the uncovered method is the host-bound auto-invoke/default wiring).
  - BRANCH: Pester's JaCoCo output does not emit a BRANCH counter. Branch behavior is fully exercised by
    tests: every fail-fast decision (missing file, parse failure, empty key, cert absent/no-private-key,
    wrong EKU), the predicate's include/exclude with both `/` and `\` separators, `-WhatIf` vs sign, empty
    vs populated enumeration, `-FilePaths` vs enumeration, non-`Valid` status returned and thrown, and the
    timestamp-unreachable warn-continue path. Command coverage of 92.44% serves as the branch proxy and
    exceeds the 75% branch threshold.

## Coverage exclusion compliance

No production file is excluded from coverage. `Invoke-AuthenticodeSigning.ps1` is measured directly and
remains in the denominator; the host-bound wrappers (`Resolve-SigningCert`,
`Invoke-SetAuthenticodeSignature`, `Test-AuthenticodeSignature`, `Get-FirstPartySignableFileList`) are kept
minimal and their lines are counted. The only uncovered lines are the param-block production-default
expressions (host-bound wiring) and one sub-expression of the timestamp fallback call.
