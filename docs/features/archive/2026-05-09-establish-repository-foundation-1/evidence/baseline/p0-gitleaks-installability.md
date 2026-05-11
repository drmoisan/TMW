# P0-T7 Gitleaks Installability Baseline

Timestamp: 2026-05-10T00-09

Command: gh release list -R gitleaks/gitleaks --limit 1
EXIT_CODE: 0
Output:
```
v8.30.1	Latest	v8.30.1	2026-03-21T02:17:58Z
```

Command: winget search --id gitleaks.gitleaks --source winget
EXIT_CODE: 0
Output:
```
Name     Id                Version
----------------------------------
Gitleaks Gitleaks.Gitleaks 8.30.1
```

Output Summary: Both installation channels are reachable. GitHub release feed reports latest tag `v8.30.1` (2026-03-21). Winget feed reports package id `Gitleaks.Gitleaks` version `8.30.1`. The install script in P3-T1 can use either channel; primary path is winget on Windows with gh-release fallback. Note: winget package id casing is `Gitleaks.Gitleaks` (capitalized) — install script uses `gitleaks.gitleaks` which winget treats case-insensitively for `--id` lookups.
