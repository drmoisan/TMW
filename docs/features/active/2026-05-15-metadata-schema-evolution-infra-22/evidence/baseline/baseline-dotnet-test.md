---
Timestamp: 2026-05-15T21-01
Command: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build
EXIT_CODE: 0
Output Summary: 68 tests total, 68 passed, 0 failed, 0 skipped.
Per-project coverage (line-rate / branch-rate):
  TaskMaster.Api.Tests: 26.22% / 7.69%
  TaskMaster.Application.Tests: 32.75% / 36.36%
  TaskMaster.ArchitectureTests: 0% / 0% (tests themselves are the coverage, not production code)
  TaskMaster.Classifier.Tests: 59.42% / 83.33%
  TaskMaster.Infrastructure.Tests: 56.89% / 54.54%
  TaskMaster.PlaceholderGolden.Tests: 0% / 0% (no production lines in scope)
Note: Baseline coverage is below 85%/75% policy thresholds in several projects. This is a pre-existing condition.
---
