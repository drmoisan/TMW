# P0-T8 — Test Coverage Baseline

Timestamp: 2026-05-12T11-03
Command: dotnet test --collect:"XPlat Code Coverage"
EXIT_CODE: 0
Output Summary: PASS — 11 total tests (3 ArchitectureTests + 8 Api.Tests), 0 failed.

Coverage (pre-change baseline):
- TaskMaster.Api.Tests coverage.cobertura.xml (covering TaskMaster.Api + TaskMaster.Domain):
  - line-rate: 0.0379 (3.79%) — NOTE: Coverlet baseline over all valid lines includes large auto-generated/boilerplate code. Post-change coverage is what matters for new projects.
  - branch-rate: 0.0096 (0.96%)
  - lines-covered: 15 / 395
  - branches-covered: 2 / 208
- TaskMaster.ArchitectureTests: no production code covered (test-only project)

Note: Baseline coverage is very low because the existing production code (Program.cs, HealthResponse.cs, AssemblyMarker.cs) has minimal testable surface covered by health tests. New projects (Application, Infrastructure) will be added in subsequent phases with dedicated test projects targeting >= 85% line / >= 75% branch coverage.
