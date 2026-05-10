---
artifact: p3-commit-msg-bad
---

Timestamp: 2026-05-10T02-41
Command: pwsh -NoProfile -File .githooks/check-conventional-commit.ps1 -MessageFile .commit-msg-test  (with `fix stuff` content)
EXIT_CODE: 4
Output Summary: PASS. Hook returned exit 4 and stderr contains "Conventional Commits format" along with first line, expected pattern, allowed types, and example.

Note: The script as originally written per the plan body had `$ErrorActionPreference = 'Stop'` combined with `Write-Error` followed by `exit 4`. PowerShell semantics cause `Write-Error` under ErrorActionPreference=Stop to throw a terminating exception before `exit` runs, returning exit 1 instead of 4. The script was adjusted to write directly to `[Console]::Error` so that `exit 4` runs as intended. This adjustment preserves the plan's documented behavior contract (non-zero with the specified message).
