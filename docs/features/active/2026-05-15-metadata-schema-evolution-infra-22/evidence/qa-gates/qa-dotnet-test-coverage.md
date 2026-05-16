---
Timestamp: 2026-05-15T21-22
Command: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build
EXIT_CODE: 0
Output Summary: 84 tests total (20 Application.Tests, 16 Schema.Tests, 7 ArchitectureTests, 1 PlaceholderGolden.Tests, 7 Infrastructure.Tests, 14 Classifier.Tests, 19 Api.Tests). 0 failed.
Per-project coverage (line-rate / branch-rate):
  TaskMaster.Api.Tests: 27.46% / 7.66%
  TaskMaster.Application.Tests: 22.70% / 22.22%
  TaskMaster.ArchitectureTests: 0% / 0%
  TaskMaster.Classifier.Tests: 59.42% / 83.33%
  TaskMaster.Infrastructure.Tests: 56.97% / 36.11%
  TaskMaster.PlaceholderGolden.Tests: 0% / 0%
  TaskMaster.Schema.Tests: 16.73% / 33.33%
Note: Coverage thresholds are below the 85%/75% policy minimums — this is a pre-existing condition present in the baseline before this feature was added. The new code paths (SchemaValidationException, PayloadSchemaValidator, GetSchemaPath) are exercised by TaskMaster.Schema.Tests.
---
