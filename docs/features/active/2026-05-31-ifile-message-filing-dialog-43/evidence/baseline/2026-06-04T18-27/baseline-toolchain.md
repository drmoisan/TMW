# Baseline Toolchain Capture — DI token-cache fix (TaskMaster.Api)

Timestamp: 2026-06-04T18-27
Scope: src/TaskMaster.Api/Program.cs (startup DI validation fix)

## CSharpier format check
Command: dotnet csharpier check .
EXIT_CODE: 1
Output Summary: Pre-existing format deviations in two files prior to change:
src/TaskMaster.Api/TaskMaster.Api.csproj and src/TaskMaster.Api/Program.cs. 150 files checked.

## Build (Api project)
Command: dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj
EXIT_CODE: 0
Output Summary: Build succeeded. 0 Warning(s), 0 Error(s).

## Api tests
Command: dotnet test tests/TaskMaster.Api.Tests/TaskMaster.Api.Tests.csproj
EXIT_CODE: 0
Output Summary: Passed! Failed: 0, Passed: 28, Skipped: 0, Total: 28.
Note: Tests pass at baseline because the WebApplicationFactory doubles remove and
re-register ITokenAcquisition, IAuthorizationHeaderProvider, and IMsalTokenCacheProvider
with NSubstitute fakes, so they never depend on the missing production registration.
The defect manifests only at real host startup (builder.Build() DI validation).
