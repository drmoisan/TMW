---
Timestamp: 2026-05-12T21-39
Command: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"
EXIT_CODE: 0
---

# .NET Test Baseline

## Output Summary

All tests passed. 4 test projects, 33 tests total.

| Project | Tests Passed | Tests Failed |
|---------|-------------|-------------|
| TaskMaster.ArchitectureTests | 6 | 0 |
| TaskMaster.Application.Tests | 9 | 0 |
| TaskMaster.Infrastructure.Tests | 4 | 0 |
| TaskMaster.Api.Tests | 14 | 0 |
| **Total** | **33** | **0** |

## Coverage (Cobertura, most recent run artifacts)

| Project | Line Coverage | Branch Coverage |
|---------|--------------|----------------|
| TaskMaster.Infrastructure.Tests (vs Infrastructure src) | 60.9% | 85.7% |
| TaskMaster.Application.Tests (vs Application src) | 26.1% | 0.0% |
| TaskMaster.Api.Tests (vs Api src) | 12.2% | 1.8% |
| TaskMaster.ArchitectureTests (vs Architecture src) | 0.0% | 0.0% |

Note: Each Cobertura XML covers only the production assembly under test. The low per-project
line coverage reflects the scope of what each test project exercises of its corresponding
production project. No pre-existing failures.

## Notes

- dotnet SDK / net10.0
- xUnit test framework
- All 33 tests pass with no skipped tests
