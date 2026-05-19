# Baseline — YAML parse and actionlint of .github/workflows/

Timestamp: 2026-05-18T10-15
Commands:
- Get-ChildItem .github/workflows/*.yml | ForEach-Object { ConvertFrom-Yaml (Get-Content -Raw $_) }
- actionlint .github/workflows/*.yml
EXIT_CODE: 0

ConvertFrom-Yaml results:
```
OK: benchmark-baseline-refresh.yml
OK: benchmark-gate-self-validation.yml
OK: pr-pipeline.yml
OK: pre-merge-pipeline.yml
OK: stage-10-benchmark-regression.yml
```

actionlint: available at C:\Users\DanMoisan\AppData\Local\Microsoft\WinGet\Packages\rhysd.actionlint_Microsoft.Winget.Source_8wekyb3d8bbwe\actionlint.exe — exit 0 (no diagnostics) across all 5 files.

Output Summary: 5/5 files parse OK; actionlint clean (exit 0); baseline YAML state is healthy and a clean reference for Phase 6 post-refactor comparison.
