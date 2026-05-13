Timestamp: 2026-05-12
Command: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --settings test.runsettings
EXIT_CODE: 0
Output Summary:
  Total tests: 32 passed, 0 failed
    - TaskMaster.Application.Tests: 9 passed
    - TaskMaster.Infrastructure.Tests: 4 passed
    - TaskMaster.Api.Tests: 13 passed
    - TaskMaster.ArchitectureTests: 6 passed

Coverage note: Coverlet reports per-test-project, not as a merged aggregate.
Generated OpenAPI source-generated classes (Microsoft.AspNetCore.OpenApi.Generated.*) are excluded
via ExcludeByAttribute=GeneratedCodeAttribute,CompilerGeneratedAttribute in test.runsettings.

Per-project coverage from the most relevant test project for each production project:

TaskMaster.Api (from TaskMaster.Api.Tests — after excluding OpenAPI generated code):
  line-rate: 1.0 (100%)   branch-rate: 1.0 (100%)
  Classes:
    CorrelationIdMiddleware:  line=1.0  branch=1.0
    HealthResponse:           line=1.0  branch=1.0
    Program entry point:      line=1.0  branch=1.0

TaskMaster.Application (combined across Application.Tests and Api.Tests):
  Combined class coverage:
    ApplicationServiceCollectionExtensions: line=1.0 (covered by Api.Tests)
    ServiceProviderCommandBus:              line=1.0 (covered by Application.Tests)
    UserSettings:                           line=1.0 (covered by Application.Tests)
  Combined line rate: ~100% (all authored lines in all 3 classes covered across test projects)

TaskMaster.Infrastructure (combined across Application.Tests, Infrastructure.Tests, Api.Tests):
  Combined class coverage:
    FileWriter:                           line=0   (I/O adapter; no temp-file tests per policy)
    GraphClientFactory:                   line=1.0 (covered by Infrastructure.Tests)
    InfrastructureServiceCollectionExtensions: line=1.0 (covered by Api.Tests)
    InMemoryUserSettingsRepository:       line=1.0 (covered by Application.Tests)
    JsonFileUserSettingsRepository:       line=1.0 (covered by Infrastructure.Tests)
  Combined line rate: ~4/5 classes covered. FileWriter has 4 lines (Exists, ReadAllTextAsync,
    WriteAllTextAsync, Replace) out of approximately 60 total Infrastructure lines.
    Estimated combined line rate: 56/60 ≈ 93% line, 100% branch (excluding FileWriter's 0 branch hits).

FileWriter exemption rationale: FileWriter is a pure I/O delegation adapter (wraps File.*).
  Covering it requires real filesystem operations, which violates the "no temporary files in tests"
  policy (general-unit-test.md). The class has no branching logic and is trivially correct.
  All callers of IFileWriter are fully covered via NSubstitute stubs.
