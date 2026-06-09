# Phase 3 — File-Size Check

- Timestamp: 2026-06-06T12-12
- Task: [P3-T1]
- Command: `(Get-Content <file>).Count` for each file

## Output Summary

- `scripts/powershell/Invoke-AuthenticodeSigning.ps1`: 449 lines (< 500).
- `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`: 481 lines (< 500).

Both files are under the 500-line limit. The conditional module split in [P3-T2] is therefore not required.
