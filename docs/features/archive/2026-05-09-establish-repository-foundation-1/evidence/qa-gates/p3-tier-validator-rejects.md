---
artifact: p3-tier-validator-rejects
---

Timestamp: 2026-05-10T02-41
Command: pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1 (with temp-unclassified-project/package.json present)
EXIT_CODE: 6
Output Summary: PASS. Validator returned exit 6. Stderr message: "Unclassified project directories not present in quality-tiers.yml: temp-unclassified-project". Cleanup performed (Remove-Item -Recurse -Force temp-unclassified-project).

Note: The script as authored per the plan body used `Write-Error` with `$ErrorActionPreference = 'Stop'`, which causes a terminating exception that returns exit 1 instead of 6. The script was adjusted to write directly to `[Console]::Error` so explicit exit codes (2, 3, 4, 5, 6) are preserved through the script's exit statements. Behavior contract is unchanged.
