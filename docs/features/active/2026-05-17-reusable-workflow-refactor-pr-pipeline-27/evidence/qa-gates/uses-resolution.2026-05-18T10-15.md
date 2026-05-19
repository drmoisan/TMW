# Phase 6 — orchestrator uses: target resolution

Timestamp: 2026-05-18T10-15
Command: ConvertFrom-Yaml .github/workflows/pr-pipeline.yml; for each jobs.<id>.uses, Test-Path the resolved relative path.
EXIT_CODE: 0

All 17 `uses:` targets resolve to existing files on disk:
- ./.github/workflows/_tier-classification.yml
- ./.github/workflows/_stage-1-format.yml
- ./.github/workflows/_stage-2-lint.yml
- ./.github/workflows/_stage-3-typecheck.yml
- ./.github/workflows/_stage-4-architecture.yml
- ./.github/workflows/_stage-5-test.yml
- ./.github/workflows/_stage-6-contract.yml
- ./.github/workflows/_stage-7-integration.yml
- ./.github/workflows/_stage-1-dotnet-format.yml
- ./.github/workflows/_stage-2-dotnet-build.yml
- ./.github/workflows/_stage-3-dotnet-typecheck.yml
- ./.github/workflows/_stage-4-dotnet-architecture.yml
- ./.github/workflows/_stage-5-dotnet-test.yml
- ./.github/workflows/_stage-e2e-smoke.yml
- ./.github/workflows/_stage-10-benchmark-regression.yml
- ./.github/workflows/_benchmark-gate-self-validation.yml
- ./.github/workflows/_secret-scan.yml

Output Summary: 17/17 uses targets exist; missing-uses count = 0.
