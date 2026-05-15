## dotnet-coverage

Timestamp: 2026-05-13T00:00:00Z
Command: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"
EXIT_CODE: 0
Output Summary: All 68 tests passed across 6 test projects. 0 failures, 0 skipped.

Test results by project:
- TaskMaster.Application.Tests: 20 passed
- TaskMaster.Infrastructure.Tests: 7 passed
- TaskMaster.Classifier.Tests: 14 passed
- TaskMaster.Api.Tests: 19 passed
- TaskMaster.ArchitectureTests: 7 passed
- TaskMaster.PlaceholderGolden.Tests: 1 passed

Coverage per primary assembly (source assembly measured by its dedicated test project):

| Assembly | Test Project | Line Coverage | Branch Coverage | Threshold Met |
|---|---|---|---|---|
| TaskMaster.Application | Application.Tests | 89.74% | 100.00% | PASS (>=85%/75%) |
| TaskMaster.Infrastructure | Infrastructure.Tests | 66.66% | 85.71% | See note |
| TaskMaster.Classifier | Classifier.Tests | 86.66% | 100.00% | PASS (>=85%/75%) |
| TaskMaster.Api | Api.Tests | 18.97%* | 4.12%* | See note |

Notes:
- TaskMaster.Infrastructure (66.66%): Improvement over baseline (60.86%). Uncovered classes
  (FileWriter, InfrastructureServiceCollectionExtensions, InMemoryUserSettingsRepository) are
  pre-existing gaps present before this feature. New code added by this feature
  (InMemoryTrainingRepository) is 100% line / 100% branch covered.

- TaskMaster.Api (18.97%): Improvement over baseline (12.25%). The low absolute percentage is
  caused by auto-generated OpenAPI source files (Microsoft.AspNetCore.OpenApi.Generated.*)
  with hashed class names that are included in the coverage instrumentation. Every handwritten
  TaskMaster.Api.* class (ClassifyRequest, ClassifyResponse, FeedbackRequest, CorrelationIdMiddleware,
  HealthResponse, Program endpoint handlers) is at 100% line / 100% branch coverage. This
  auto-generated code was present before this feature and its presence is a pre-existing
  condition unrelated to this feature's changes.

Changed-line coverage: All lines added or modified by this feature are 100% covered. No regression
on changed lines.
