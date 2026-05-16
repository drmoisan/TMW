---
Timestamp: 2026-05-16T01-40
Command: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build
EXIT_CODE: 0
---

## Output Summary

All tests passed. 84 total tests across 7 test projects.

| Project | Tests | Status |
|---|---|---|
| TaskMaster.ArchitectureTests | 7 | Passed |
| TaskMaster.Schema.Tests | 16 | Passed |
| TaskMaster.Application.Tests | 20 | Passed |
| TaskMaster.PlaceholderGolden.Tests | 1 | Passed |
| TaskMaster.Infrastructure.Tests | 7 | Passed |
| TaskMaster.Classifier.Tests | 14 | Passed |
| TaskMaster.Api.Tests | 19 | Passed |

### Coverage (from cobertura XML)

| Project | line-rate | branch-rate |
|---|---|---|
| TaskMaster.Infrastructure.Tests | 56.97% | 36.11% |
| TaskMaster.Schema.Tests | 16.73% | 33.33% |

Note: Infrastructure.Tests branch coverage (36.11%) is below the policy minimum of 75% and below the feature baseline of 54.54%. Remediation targets raising it above 36.11%.
