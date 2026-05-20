# Baseline — Pester (P0-T3)

Timestamp: 2026-05-19T10-15

Command: pwsh -NoProfile -Command "& ./tests/powershell/run-pester.ps1"

EXIT_CODE: 0

Output Summary:
- Tests Passed: 58, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
- Code coverage: 91.75% (target 85%), 388 analyzed commands across 3 files.
- The repo-standard Pester entrypoint is tests/powershell/run-pester.ps1, which loads tests/powershell/PesterConfiguration.psd1. That configuration enumerates an explicit Run.Path list (3 test files) and an explicit CodeCoverage.Path list (3 hook/script files); it does not auto-discover tests/scripts/** or tests/pester/**.
- Note on plan path: plan tasks reference a tests/pester/ tree that does not yet exist in the repo. The repo-standard Pester suite under tests/powershell + tests/scripts is the established convention. New regression tests authored in Phase 1 will follow the established tests/pester path named by the plan and be run by explicit Invoke-Pester invocations against those files.
- Baseline result: green (no failures) at branch HEAD b25e678.
