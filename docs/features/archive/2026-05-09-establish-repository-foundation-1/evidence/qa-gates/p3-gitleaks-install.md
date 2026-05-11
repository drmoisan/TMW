# P3-T2 Gitleaks Install — Runtime

Timestamp: 2026-05-10T00-19

Command: pwsh -NoProfile -File .github/scripts/install-gitleaks.ps1
EXIT_CODE: 0
Channel: winget (Windows primary)
Resolved Path: C:\Users\DanMoisan\AppData\Local\Microsoft\WinGet\Packages\Gitleaks.Gitleaks_Microsoft.Winget.Source_8wekyb3d8bbwe\gitleaks.exe

Command: <resolved> version
EXIT_CODE: 0
Output: 8.30.1

Output Summary: Installer ran successfully. Winget channel resolved package `Gitleaks.Gitleaks` version 8.30.1, downloaded `gitleaks_8.30.1_windows_x64.zip` from the GitHub release URL with verified installer hash, and extracted/installed the binary. The script wrote the resolved binary path to stdout. `<resolved> version` returns `8.30.1` (semver). Subsequent runs will short-circuit via `Resolve-GitleaksOnPath` once PATH refresh propagates, otherwise via the explicit resolver.
