# QA Gate — DI token-cache fix (TaskMaster.Api)

Timestamp: 2026-06-04T18-31
Scope: src/TaskMaster.Api/Program.cs (+ CSharpier-normalized src/TaskMaster.Api/TaskMaster.Api.csproj)

## 1. CSharpier format check
Command: dotnet csharpier check .
EXIT_CODE: 0
Output Summary: Checked 150 files. All formatted (pre-existing deviations resolved by format pass).

## 2. Build (full solution, analyzers + nullable, TreatWarningsAsErrors)
Command: dotnet build
EXIT_CODE: 0
Output Summary: Build succeeded. 0 Warning(s), 0 Error(s).

## 3. Architecture tests
Command: dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj --no-build
EXIT_CODE: 0
Output Summary: Passed! Failed: 0, Passed: 10, Total: 10.

## 4. Full test suite with coverage
Command: dotnet test --collect:"XPlat Code Coverage"
EXIT_CODE: 0
Output Summary: All projects passed.
- TaskMaster.Api.Tests: 28/28
- TaskMaster.Application.Tests: 43/43
- TaskMaster.Schema.Tests: 24/24
- TaskMaster.ArchitectureTests: 10/10
- TaskMaster.Classifier.Tests: 14/14
- TaskMaster.Infrastructure.Tests: 21/21
- TaskMaster.PlaceholderGolden.Tests: 4/4
Touched-file coverage (Program.cs entry-point class): line-rate 0.87, exercised via
WebApplicationFactory<Program> host startup. No per-file regression vs baseline.

## Canonical coverage artifact
artifacts/csharp/coverage.xml (copied from newest TestResults/*/coverage.cobertura.xml).

## Delta vs baseline
- Analyzer delta: 0 new findings.
- Compiler/nullable delta: 0 new diagnostics.
- xUnit delta: 0 new failing tests.
- Architecture-test delta: 0 new failing facts.
- Per-file coverage delta: >= baseline for Program.cs.

## Original failure resolution
The build of the Api project succeeds and the identity wiring now chains
EnableTokenAcquisitionToCallDownstreamApi().AddMicrosoftGraph().AddInMemoryTokenCaches(),
which registers IMsalTokenCacheProvider. This is the dependency whose absence caused
TokenAcquisitionAspNetCore to fail build-time DI validation at builder.Build().
Startup DI validation requires real AzureAd configuration and is not executed in this
environment; build success plus passing tests are the primary gates per the task.
