# Baseline — dotnet test (coverage)

Timestamp: 2026-05-15T21-48
Command: `dotnet test TaskMaster.sln -c Release --collect:"XPlat Code Coverage" --results-directory artifacts/csharp/baseline --nologo`
EXIT_CODE: 0
Output Summary:
- Test results per assembly (passed/total):
  - TaskMaster.PlaceholderGolden.Tests: 1/1
  - TaskMaster.Application.Tests: 20/20
  - TaskMaster.ArchitectureTests: 7/7
  - TaskMaster.Infrastructure.Tests: 7/7
  - TaskMaster.Classifier.Tests: 14/14
  - TaskMaster.Api.Tests: 19/19
- Total passed: 68, failed: 0, skipped: 0.
- Coverage (aggregate across all per-assembly Cobertura outputs):
  - line=32.70% (309/945)
  - branch=15.82% (56/354)
- Per-file headline figures recorded by `scripts/benchmarks/parse-cobertura.ps1`.
- Note: Cobertura files are emitted per test-run process, so the aggregate sums production-code lines counted once per test project that exercises them. The headline values are recorded for delta tracking; the comparison in P7-T9 will use the same aggregator on the post-change set so deltas are computed consistently. The change set in this PR is gate-only test infrastructure and should not regress production-code coverage.
