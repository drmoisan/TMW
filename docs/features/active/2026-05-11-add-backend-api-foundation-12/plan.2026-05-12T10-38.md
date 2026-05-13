# 2026-05-11-add-backend-api-foundation — Implementation Plan

- **Issue:** #12
- **Parent (optional):** #7 (C1 .NET Foundation)
- **Owner:** drmoisan
- **Last Updated:** 2026-05-12T10-38
- **Work Mode:** full-feature
- **Status:** Draft
- **Version:** 1.0

## Required References (read before implementation)

- `.claude/rules/general-code-change.md`
- `.claude/rules/general-unit-test.md`
- `.claude/rules/csharp.md`
- `.claude/rules/architecture-boundaries.md`
- `.claude/rules/quality-tiers.md`

**All work must comply with these policies.**

## Acceptance Criteria Traceability

The following eleven acceptance criteria from `issue.md` are mapped to plan tasks:

| AC | Task(s) |
|---|---|
| AC-1: `TaskMaster.Application` project exists with command bus and `IUserSettingsRepository` | P1-T3, P2-T1–P2-T6 |
| AC-2: `TaskMaster.Infrastructure` project exists with Graph adapter and repository impl | P1-T4, P3-T1–P3-T5 |
| AC-3: Bearer token validation wired via `Microsoft.Identity.Web` | P4-T2, P4-T3 |
| AC-4: Correlation ID middleware propagates `X-Correlation-Id` | P4-T1, P5-T7, P5-T8 |
| AC-5: `/health` returns `{"status":"ok"}` | P5-T9 (existing tests remain passing) |
| AC-6: `dotnet build` passes with zero warnings and analyzer errors | P6-T2 |
| AC-7: All new projects pass `dotnet csharpier check .`, arch tests, `dotnet test` | P6-T1, P6-T3, P6-T4 |
| AC-8: `quality-tiers.yml` updated for all new projects | P1-T9 |
| AC-9: Coverage >= 85% line / >= 75% branch on new projects | P6-T5 |
| AC-10: Auth and Graph token flow covered by integration test or documented manual test | P5-T5, P5-T6, P5-T10 |
| AC-11: No `Microsoft.Office.Interop.Outlook` or VSTO references | P5-T11, P6-T4 |

---

### Phase 0 — Compliance and Baseline

- [x] [P0-T1] Read `.claude/rules/general-code-change.md` and record confirmation in `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t1-policy-read.md` (fields: Timestamp, Policy Order, files read).
  - Acceptance: artifact exists at `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t1-policy-read.md` with all required fields populated.

- [x] [P0-T2] Read `.claude/rules/general-unit-test.md` and add its entry to the policy-read artifact `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t1-policy-read.md`.
  - Acceptance: policy-read artifact lists both `general-code-change.md` and `general-unit-test.md` as read.

- [x] [P0-T3] Read `.claude/rules/csharp.md` and add its entry to the policy-read artifact `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t1-policy-read.md`.
  - Acceptance: policy-read artifact lists `csharp.md` as read.

- [x] [P0-T4] Read `.claude/rules/architecture-boundaries.md` and add its entry to the policy-read artifact `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t1-policy-read.md`.
  - Acceptance: policy-read artifact lists `architecture-boundaries.md` as read.

- [x] [P0-T5] Read `.claude/rules/quality-tiers.md` and add its entry to the policy-read artifact `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t1-policy-read.md`. Mark policy-read artifact as complete.
  - Acceptance: policy-read artifact lists `quality-tiers.md` as read and is marked complete.

- [x] [P0-T6] Run `dotnet tool restore` and then `dotnet csharpier check .` from the solution root; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t6-csharpier-baseline.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (pass/fail + file count).
  - Acceptance: artifact exists with all four required fields; EXIT_CODE is 0 (baseline must be clean before changes begin).

- [x] [P0-T7] Run `dotnet build` from the solution root; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t7-build-baseline.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (warning count, error count).
  - Acceptance: artifact exists; EXIT_CODE is 0 with zero warnings and zero errors.

- [x] [P0-T8] Run `dotnet test --collect:"XPlat Code Coverage"` from the solution root; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t8-test-coverage-baseline.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (test count passed/failed, line coverage %, branch coverage %).
  - Acceptance: artifact exists; numeric coverage values recorded; all existing tests pass.

- [x] [P0-T9] Run `dotnet test --project tests/TaskMaster.ArchitectureTests` from the solution root; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/baseline/p0-t9-architecture-baseline.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (test count, pass/fail).
  - Acceptance: artifact exists; EXIT_CODE is 0; all architecture tests pass.

---

### Phase 1 — Package and Project Scaffold

- [x] [P1-T1] Update `Directory.Packages.props`: add `<PackageVersion Include="Microsoft.Identity.Web" Version="4.9.0" />`, `<PackageVersion Include="Microsoft.Identity.Web.GraphServiceClient" Version="4.9.0" />`, `<PackageVersion Include="Microsoft.Graph" Version="5.105.0" />`, and `<PackageVersion Include="CsCheck" Version="4.6.2" />` within the existing `<ItemGroup>` block; upgrade the existing `Microsoft.AspNetCore.Mvc.Testing` entry from `9.0.10` to `10.0.7`.
  - File: `Directory.Packages.props`
  - Acceptance: file contains all five entries with stated versions; no duplicate `PackageVersion` elements exist for any of these packages.

- [x] [P1-T2] Create `src/TaskMaster.Application/TaskMaster.Application.csproj` with `<TargetFramework>net10.0</TargetFramework>`, `<ImplicitUsings>enable</ImplicitUsings>`, and a `<ProjectReference>` to `../../src/TaskMaster.Domain/TaskMaster.Domain.csproj`. No package references except those inherited from `Directory.Build.props` (analyzer stack is applied automatically).
  - File: `src/TaskMaster.Application/TaskMaster.Application.csproj`
  - Acceptance: file is well-formed XML; `dotnet build src/TaskMaster.Application/TaskMaster.Application.csproj` succeeds.

- [x] [P1-T3] Create `src/TaskMaster.Infrastructure/TaskMaster.Infrastructure.csproj` with `<TargetFramework>net10.0</TargetFramework>`, `<ImplicitUsings>enable</ImplicitUsings>`, project references to `TaskMaster.Application.csproj` and `TaskMaster.Domain.csproj`, and package references: `<PackageReference Include="Microsoft.Graph" />`, `<PackageReference Include="Microsoft.Identity.Web.GraphServiceClient" />`.
  - File: `src/TaskMaster.Infrastructure/TaskMaster.Infrastructure.csproj`
  - Acceptance: file is well-formed XML; referenced package versions are resolved from `Directory.Packages.props`.

- [x] [P1-T4] Create `tests/TaskMaster.Application.Tests/TaskMaster.Application.Tests.csproj` with `<TargetFramework>net10.0</TargetFramework>`, `<ImplicitUsings>enable</ImplicitUsings>`, `<IsPackable>false</IsPackable>`, package references: `coverlet.collector`, `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio`, `FluentAssertions`, `NSubstitute`, `Microsoft.Extensions.TimeProvider.Testing`, `CsCheck`; project references to `TaskMaster.Application.csproj` and `TaskMaster.Infrastructure.csproj` (for in-memory impl tests).
  - File: `tests/TaskMaster.Application.Tests/TaskMaster.Application.Tests.csproj`
  - Acceptance: file is well-formed XML; all referenced packages are in `Directory.Packages.props`.

- [x] [P1-T5] Create `tests/TaskMaster.Infrastructure.Tests/TaskMaster.Infrastructure.Tests.csproj` with `<TargetFramework>net10.0</TargetFramework>`, `<ImplicitUsings>enable</ImplicitUsings>`, `<IsPackable>false</IsPackable>`, package references: `coverlet.collector`, `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio`, `FluentAssertions`, `NSubstitute`, `Microsoft.Extensions.TimeProvider.Testing`, `WireMock.Net`; project reference to `TaskMaster.Infrastructure.csproj`.
  - File: `tests/TaskMaster.Infrastructure.Tests/TaskMaster.Infrastructure.Tests.csproj`
  - Acceptance: file is well-formed XML; all referenced packages are in `Directory.Packages.props`.

- [x] [P1-T6] Add `src/TaskMaster.Application/TaskMaster.Application.csproj`, `src/TaskMaster.Infrastructure/TaskMaster.Infrastructure.csproj`, `tests/TaskMaster.Application.Tests/TaskMaster.Application.Tests.csproj`, and `tests/TaskMaster.Infrastructure.Tests/TaskMaster.Infrastructure.Tests.csproj` to the solution file (`TaskMaster.sln`) using `dotnet sln add` for each.
  - Acceptance: `dotnet sln list` shows all four new projects; command exits 0.

- [x] [P1-T7] Add project references to `src/TaskMaster.Api/TaskMaster.Api.csproj`: `<ProjectReference>` to `TaskMaster.Application.csproj` and `TaskMaster.Infrastructure.csproj`; add package reference `<PackageReference Include="Microsoft.Identity.Web" />`.
  - File: `src/TaskMaster.Api/TaskMaster.Api.csproj`
  - Acceptance: file contains both new project references and the `Microsoft.Identity.Web` package reference; `dotnet build src/TaskMaster.Api` succeeds after this change alone (may error on missing types — acceptable until Phase 2 implementation).

- [x] [P1-T8] Add `<InternalsVisibleTo Include="TaskMaster.Application.Tests" />` to `src/TaskMaster.Application/TaskMaster.Application.csproj` and `<InternalsVisibleTo Include="TaskMaster.Infrastructure.Tests" />` to `src/TaskMaster.Infrastructure/TaskMaster.Infrastructure.csproj`.
  - Files: `src/TaskMaster.Application/TaskMaster.Application.csproj`, `src/TaskMaster.Infrastructure/TaskMaster.Infrastructure.csproj`
  - Acceptance: each csproj contains the corresponding `InternalsVisibleTo` entry.

- [x] [P1-T9] Update `quality-tiers.yml`: add four new project entries — `TaskMaster.Application` (T2, `src/TaskMaster.Application`), `TaskMaster.Infrastructure` (T3, `src/TaskMaster.Infrastructure`), `TaskMaster.Application.Tests` (T4, `tests/TaskMaster.Application.Tests`), `TaskMaster.Infrastructure.Tests` (T4, `tests/TaskMaster.Infrastructure.Tests`) — each with `name`, `path`, `language: csharp`, `tier`, and `rationale` fields.
  - File: `quality-tiers.yml`
  - Acceptance: file contains all four new entries; `dotnet run --project .github/scripts/validate-quality-tiers.ps1` (or equivalent CI script) reports no missing tiers.

- [x] [P1-T10] Run `dotnet restore` followed by `dotnet build` from the solution root after all scaffold changes (P1-T1 through P1-T9) are complete; verify EXIT_CODE is 0.
  - Acceptance: both commands exit 0; zero new warnings or errors introduced by scaffold changes alone (compile errors from missing implementation bodies are acceptable at this stage only if they are the sole failures).

---

### Phase 2 — Application Layer Implementation

- [x] [P2-T1] Create `src/TaskMaster.Application/UserSettings.cs`: define `public sealed record UserSettings(string UserId, bool NotificationsEnabled, bool TriageEnabled, DateTimeOffset LastModifiedAt)` using file-scoped namespace `TaskMaster.Application`. Include XML doc comments on the record and each property.
  - File: `src/TaskMaster.Application/UserSettings.cs`
  - Acceptance: file compiles; `UserSettings` is a `record` with the four specified properties; `DateTimeOffset LastModifiedAt` is not set by callers (enforced by documentation/convention; set by repository `SaveAsync`).

- [x] [P2-T2] Create `src/TaskMaster.Application/IUserSettingsRepository.cs`: define `public interface IUserSettingsRepository` with three async methods: `Task<UserSettings?> GetAsync(string userId, CancellationToken ct = default)`, `Task SaveAsync(UserSettings settings, CancellationToken ct = default)`, `Task DeleteAsync(string userId, CancellationToken ct = default)`. File-scoped namespace `TaskMaster.Application`.
  - File: `src/TaskMaster.Application/IUserSettingsRepository.cs`
  - Acceptance: file compiles; interface declares exactly the three methods with the specified signatures.

- [x] [P2-T3] Create `src/TaskMaster.Application/ICommandHandler.cs`: define `public interface ICommandHandler<TCommand>` with one method: `Task HandleAsync(TCommand command, CancellationToken ct = default)`. File-scoped namespace `TaskMaster.Application`.
  - File: `src/TaskMaster.Application/ICommandHandler.cs`
  - Acceptance: file compiles; interface is generic over `TCommand`.

- [x] [P2-T4] Create `src/TaskMaster.Application/ICommandBus.cs`: define `public interface ICommandBus` with one method: `Task DispatchAsync<TCommand>(TCommand command, CancellationToken ct = default)`. File-scoped namespace `TaskMaster.Application`.
  - File: `src/TaskMaster.Application/ICommandBus.cs`
  - Acceptance: file compiles; interface is non-generic with a generic method `DispatchAsync<TCommand>`.

- [x] [P2-T5] Create `src/TaskMaster.Application/ServiceProviderCommandBus.cs`: define `internal sealed class ServiceProviderCommandBus : ICommandBus` with a constructor accepting `IServiceProvider` and a `DispatchAsync<TCommand>` implementation that calls `_serviceProvider.GetRequiredService<ICommandHandler<TCommand>>()` then `handler.HandleAsync(command, ct)`. File-scoped namespace `TaskMaster.Application`. Do not use `DateTime.Now`, `DateTime.UtcNow`, or any banned API.
  - File: `src/TaskMaster.Application/ServiceProviderCommandBus.cs`
  - Acceptance: file compiles; class is `internal sealed`; resolves handler via `GetRequiredService` (fail-fast when no handler registered).

- [x] [P2-T6] Create `src/TaskMaster.Application/IGraphClientFactory.cs`: define `public interface IGraphClientFactory` with method `Microsoft.Graph.GraphServiceClient CreateClient()`. File-scoped namespace `TaskMaster.Application`. Add `<PackageReference Include="Microsoft.Graph" />` to `TaskMaster.Application.csproj` only if required for the return type to compile; if the return type causes an unacceptable application-layer dependency, use `object` as the return type and add a comment. (Preferred: define the interface in Application with the Graph return type since Graph SDK is a Microsoft-published abstraction with no VSTO/COM dependency.)
  - File: `src/TaskMaster.Application/IGraphClientFactory.cs`
  - Acceptance: file compiles; interface is in `TaskMaster.Application` namespace; the architecture boundary (`TaskMaster.Application` depends on `TaskMaster.Domain` only) is satisfied — if `Microsoft.Graph` must be added to Application.csproj, document this as a known pragmatic exception in the csproj comment.

- [x] [P2-T7] Create `src/TaskMaster.Application/DependencyInjection.cs`: define `public static class ApplicationServiceCollectionExtensions` with `AddApplicationServices(this IServiceCollection services)` extension method that registers `ICommandBus` → `ServiceProviderCommandBus` as Scoped. File-scoped namespace `TaskMaster.Application`. Use `using Microsoft.Extensions.DependencyInjection;`.
  - File: `src/TaskMaster.Application/DependencyInjection.cs`
  - Acceptance: file compiles; `AddApplicationServices` registers `ICommandBus` with Scoped lifetime.

- [x] [P2-T8] Verify `dotnet build src/TaskMaster.Application` exits 0 with zero warnings after all Phase 2 tasks are complete.
  - Acceptance: EXIT_CODE is 0; no new build warnings in `TaskMaster.Application`.

---

### Phase 3 — Infrastructure Layer Implementation

- [x] [P3-T1] Create `src/TaskMaster.Infrastructure/IFileWriter.cs`: define `public interface IFileWriter` with method `void Replace(string sourceFileName, string destinationFileName, string? destinationBackupFileName)`. File-scoped namespace `TaskMaster.Infrastructure`. This is the testability seam over `System.IO.File.Replace`.
  - File: `src/TaskMaster.Infrastructure/IFileWriter.cs`
  - Acceptance: file compiles; interface exposes exactly the `Replace` method signature matching `File.Replace`.

- [x] [P3-T2] Create `src/TaskMaster.Infrastructure/FileWriter.cs`: define `internal sealed class FileWriter : IFileWriter` that delegates `Replace` directly to `System.IO.File.Replace`. File-scoped namespace `TaskMaster.Infrastructure`.
  - File: `src/TaskMaster.Infrastructure/FileWriter.cs`
  - Acceptance: file compiles; `FileWriter.Replace` calls `File.Replace(sourceFileName, destinationFileName, destinationBackupFileName)`.

- [x] [P3-T3] Create `src/TaskMaster.Infrastructure/InMemoryUserSettingsRepository.cs`: define `public sealed class InMemoryUserSettingsRepository : IUserSettingsRepository` backed by `ConcurrentDictionary<string, UserSettings>`. Implement `GetAsync` (returns entry or `null`), `SaveAsync` (upserts; sets `LastModifiedAt` via injected `TimeProvider`), `DeleteAsync` (no-ops silently if key missing). Accept `TimeProvider` as constructor parameter. File-scoped namespace `TaskMaster.Infrastructure`. Do not use `DateTime.UtcNow` or `DateTime.Now`.
  - File: `src/TaskMaster.Infrastructure/InMemoryUserSettingsRepository.cs`
  - Acceptance: file compiles; `TimeProvider` is injected; `SaveAsync` uses `_timeProvider.GetUtcNow()` to populate `LastModifiedAt` on the saved record.

- [x] [P3-T4] Create `src/TaskMaster.Infrastructure/UserSettingsFileOptions.cs`: define `public sealed class UserSettingsFileOptions` with property `string FilePath { get; set; } = string.Empty;`. File-scoped namespace `TaskMaster.Infrastructure`.
  - File: `src/TaskMaster.Infrastructure/UserSettingsFileOptions.cs`
  - Acceptance: file compiles; class has the `FilePath` property.

- [x] [P3-T5] Create `src/TaskMaster.Infrastructure/JsonFileUserSettingsRepository.cs`: define `public sealed class JsonFileUserSettingsRepository : IUserSettingsRepository` using `System.Text.Json`. Constructor accepts `IOptions<UserSettingsFileOptions>`, `IFileWriter`, and `TimeProvider`. `GetAsync` reads and deserializes the JSON file (returns `null` if file not found or entry absent). `SaveAsync` reads current file, upserts the entry, writes to a temp file, then calls `IFileWriter.Replace` for atomic replacement; sets `LastModifiedAt` via `TimeProvider.GetUtcNow()`. `DeleteAsync` removes entry and writes back. File-scoped namespace `TaskMaster.Infrastructure`. Do not use `DateTime.UtcNow`, `DateTime.Now`, or `File.Replace` directly.
  - File: `src/TaskMaster.Infrastructure/JsonFileUserSettingsRepository.cs`
  - Acceptance: file compiles; no direct `File.*` calls except through `IFileWriter`; `TimeProvider` used for `LastModifiedAt`.

- [x] [P3-T6] Create `src/TaskMaster.Infrastructure/GraphClientFactory.cs`: define `public sealed class GraphClientFactory : IGraphClientFactory` with constructor accepting `Microsoft.Graph.GraphServiceClient` (DI-injected, pre-configured by `Microsoft.Identity.Web.GraphServiceClient`). Implement `CreateClient()` returning the injected `GraphServiceClient`. File-scoped namespace `TaskMaster.Infrastructure`.
  - File: `src/TaskMaster.Infrastructure/GraphClientFactory.cs`
  - Acceptance: file compiles; `GraphClientFactory` wraps the DI-resolved `GraphServiceClient`; class is `public sealed`.

- [x] [P3-T7] Create `src/TaskMaster.Infrastructure/DependencyInjection.cs`: define `public static class InfrastructureServiceCollectionExtensions` with `AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)` extension method. Register: `IFileWriter` → `FileWriter` (Singleton), `IUserSettingsRepository` → `InMemoryUserSettingsRepository` (Singleton, injecting `TimeProvider.System`), `IGraphClientFactory` → `GraphClientFactory` (Scoped), `services.AddOptions<UserSettingsFileOptions>().Bind(configuration.GetSection("UserSettings"))`. File-scoped namespace `TaskMaster.Infrastructure`. Use `using Microsoft.Extensions.DependencyInjection;` and `using Microsoft.Extensions.Configuration;`.
  - File: `src/TaskMaster.Infrastructure/DependencyInjection.cs`
  - Acceptance: file compiles; `AddInfrastructureServices` registers all four services with stated lifetimes; `TimeProvider.System` is passed to `InMemoryUserSettingsRepository`.

- [x] [P3-T8] Verify `dotnet build src/TaskMaster.Infrastructure` exits 0 with zero warnings after all Phase 3 tasks are complete.
  - Acceptance: EXIT_CODE is 0; no new build warnings in `TaskMaster.Infrastructure`.

---

### Phase 4 — API Layer Updates

- [x] [P4-T1] Create `src/TaskMaster.Api/CorrelationIdMiddleware.cs`: define `public sealed class CorrelationIdMiddleware : IMiddleware`. In `InvokeAsync`: read `X-Correlation-Id` from `context.Request.Headers`; if absent generate `Guid.NewGuid().ToString()`; set `context.Response.Headers["X-Correlation-Id"]` to the value; push to structured logging scope via `ILogger.BeginScope(new Dictionary<string, object> { ["CorrelationId"] = correlationId })`; call `await _next(context)`. Accept `ILogger<CorrelationIdMiddleware>` as constructor parameter. File-scoped namespace `TaskMaster.Api`. Do not use `DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, or any banned API.
  - File: `src/TaskMaster.Api/CorrelationIdMiddleware.cs`
  - Acceptance: file compiles; `CorrelationIdMiddleware` implements `IMiddleware`; uses injected `ILogger`; sets response header before calling `_next`.

- [x] [P4-T2] Update `src/TaskMaster.Api/Program.cs`: add `builder.Services.AddTransient<CorrelationIdMiddleware>()`, `builder.Services.AddAuthentication().AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))`, `builder.Services.AddMicrosoftGraph()` (from `Microsoft.Identity.Web.GraphServiceClient`), `builder.Services.AddApplicationServices()`, `builder.Services.AddInfrastructureServices(builder.Configuration)`. Add required `using` directives for `TaskMaster.Application`, `TaskMaster.Infrastructure`, `Microsoft.Identity.AspNetCore.AccessTokenManagement`, and `Microsoft.Identity.Web`.
  - File: `src/TaskMaster.Api/Program.cs`
  - Acceptance: file compiles; all five service registrations are present in the correct builder phase (before `builder.Build()`).

- [x] [P4-T3] Update `src/TaskMaster.Api/Program.cs`: add middleware pipeline calls in order: `app.UseMiddleware<CorrelationIdMiddleware>()`, `app.UseAuthentication()`, `app.UseAuthorization()`. Ensure these lines appear after `app.UseHttpsRedirection()` and before `app.MapGet("/health", ...)`. Add `.AllowAnonymous()` to the `/health` endpoint mapping to exempt it from the authorization requirement.
  - File: `src/TaskMaster.Api/Program.cs`
  - Acceptance: middleware order in source is CorrelationId → Authentication → Authorization; `/health` has `.AllowAnonymous()`; file compiles.

- [x] [P4-T4] Create or update `src/TaskMaster.Api/appsettings.json`: add an `AzureAd` section with placeholder keys `Instance`, `TenantId`, `ClientId`, `Audience` set to empty strings or placeholder comments. Do not add `ClientSecret` to any committed configuration file.
  - File: `src/TaskMaster.Api/appsettings.json`
  - Acceptance: file contains `"AzureAd"` section with `Instance`, `TenantId`, `ClientId`, `Audience` keys; no `ClientSecret` value is present in the committed file.

- [x] [P4-T5] Verify `dotnet build src/TaskMaster.Api` exits 0 with zero warnings after all Phase 4 tasks are complete.
  - Acceptance: EXIT_CODE is 0; zero new warnings in `TaskMaster.Api`.

---

### Phase 5 — Test Implementation

#### TaskMaster.Application.Tests

- [x] [P5-T1] Create `tests/TaskMaster.Application.Tests/CommandBusTests.cs`: implement `[Fact]` tests for `ServiceProviderCommandBus.DispatchAsync<TCommand>`:
  - `DispatchAsync_WithRegisteredHandler_CallsHandleAsync`: build a `ServiceProvider` with a NSubstitute `ICommandHandler<TestCommand>` registered; dispatch; verify handler was called.
  - `DispatchAsync_WithNoRegisteredHandler_ThrowsInvalidOperationException`: build a `ServiceProvider` with no handler registered; assert `InvalidOperationException` is thrown.
  - File-scoped namespace `TaskMaster.Application.Tests`.
  - File: `tests/TaskMaster.Application.Tests/CommandBusTests.cs`
  - Acceptance: two `[Fact]` tests; AAA structure; no real I/O; tests compile and pass.

- [x] [P5-T2] Create `tests/TaskMaster.Application.Tests/InMemoryUserSettingsRepositoryTests.cs`: implement `[Fact]` and `[Theory]` tests for `InMemoryUserSettingsRepository`:
  - `GetAsync_WhenKeyAbsent_ReturnsNull`
  - `SaveAsync_NewUser_CanBeRetrievedByGetAsync`
  - `SaveAsync_ExistingUser_OverwritesPreviousRecord`
  - `SaveAsync_SetsLastModifiedAt_ViaTimeProvider` (uses `FakeTimeProvider`)
  - `DeleteAsync_ExistingUser_RemovesRecord`
  - `DeleteAsync_AbsentUser_DoesNotThrow`
  - File-scoped namespace `TaskMaster.Application.Tests`.
  - File: `tests/TaskMaster.Application.Tests/InMemoryUserSettingsRepositoryTests.cs`
  - Acceptance: six `[Fact]` tests; `FakeTimeProvider` used for clock; no real I/O; all pass.

- [x] [P5-T3] Create `tests/TaskMaster.Application.Tests/UserSettingsPropertyTests.cs`: implement at least one CsCheck property-based test for `UserSettings` construction invariants:
  - `UserSettings_RoundTripSerialization_PreservesAllFields`: generate `UserSettings` with arbitrary `UserId`, `NotificationsEnabled`, `TriageEnabled`, `LastModifiedAt`; serialize with `System.Text.Json`; deserialize; assert all fields match original.
  - Add any additional property tests for pure functions in `TaskMaster.Application` (at minimum one per T2 policy requirement).
  - File-scoped namespace `TaskMaster.Application.Tests`.
  - File: `tests/TaskMaster.Application.Tests/UserSettingsPropertyTests.cs`
  - Acceptance: at least one CsCheck `[Fact]` property test; test passes deterministically; no real I/O.

#### TaskMaster.Infrastructure.Tests

- [x] [P5-T4] Create `tests/TaskMaster.Infrastructure.Tests/JsonFileUserSettingsRepositoryTests.cs`: implement `[Fact]` tests for `JsonFileUserSettingsRepository` using NSubstitute for `IFileWriter` (no real filesystem access):
  - `GetAsync_WhenFileNotFound_ReturnsNull`: `IFileWriter` seam unused; simulate missing file via a custom read path or by configuring the repository to read from a path that does not exist — if read is via `File.ReadAllText`, inject a read seam as well (extend `IFileWriter` or use a separate `IFileReader` seam as needed). If the read path cannot be seamed via `IFileWriter` alone, create a second interface `IFileReader` with `string? ReadAllText(string path)` and inject it.
  - `SaveAsync_WritesToTempFileAndCallsReplace`: mock `IFileWriter`; assert `IFileWriter.Replace` is called with expected temp and target paths.
  - `DeleteAsync_RemovesEntryAndWritesBack`: verify the written-back content does not contain the deleted entry.
  - File-scoped namespace `TaskMaster.Infrastructure.Tests`.
  - File: `tests/TaskMaster.Infrastructure.Tests/JsonFileUserSettingsRepositoryTests.cs`
  - Acceptance: tests compile; no real filesystem access (no `File.*` calls except via injected seam); all pass.

- [x] [P5-T5] Create `tests/TaskMaster.Infrastructure.Tests/GraphClientFactoryTests.cs`: implement `[Fact]` test for `GraphClientFactory`:
  - `CreateClient_ReturnsInjectedGraphServiceClient`: construct `GraphClientFactory` with a `GraphServiceClient` built pointing to a WireMock.Net stub server; assert `CreateClient()` returns a non-null client and a basic stubbed endpoint call succeeds.
  - File-scoped namespace `TaskMaster.Infrastructure.Tests`.
  - File: `tests/TaskMaster.Infrastructure.Tests/GraphClientFactoryTests.cs`
  - Acceptance: test uses WireMock.Net (already in `Directory.Packages.props` at 1.7.2); no real AAD calls; test passes.

#### TaskMaster.Api.Tests additions

- [x] [P5-T6] Create `tests/TaskMaster.Api.Tests/TestAuthHandler.cs`: implement `internal sealed class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>` that always authenticates successfully with a synthetic `ClaimsPrincipal`. Include a `TestAuthHandlerOptions` class if needed. File-scoped namespace `TaskMaster.Api.Tests`.
  - File: `tests/TaskMaster.Api.Tests/TestAuthHandler.cs`
  - Acceptance: class compiles; implements `AuthenticationHandler<AuthenticationSchemeOptions>`; auto-authenticates any request.

- [x] [P5-T7] Create `tests/TaskMaster.Api.Tests/CorrelationIdMiddlewareTests.cs` with direct unit tests for `CorrelationIdMiddleware`:
  - `InvokeAsync_RequestWithoutCorrelationIdHeader_SetsNewGuidOnResponse`: build a `DefaultHttpContext` with no `X-Correlation-Id` header; invoke middleware; assert response header `X-Correlation-Id` is a non-empty, parseable GUID string.
  - `InvokeAsync_RequestWithExistingCorrelationIdHeader_PreservesValueOnResponse`: build a `DefaultHttpContext` with `X-Correlation-Id: test-id-123`; invoke middleware; assert response header equals `test-id-123`.
  - File-scoped namespace `TaskMaster.Api.Tests`.
  - File: `tests/TaskMaster.Api.Tests/CorrelationIdMiddlewareTests.cs`
  - Acceptance: two `[Fact]` tests; no network calls; use `DefaultHttpContext` and a mock `ILogger<CorrelationIdMiddleware>`; both pass.

- [x] [P5-T8] Create `tests/TaskMaster.Api.Tests/AuthIntegrationTests.cs`: use `WebApplicationFactory<Program>` to test auth integration:
  - `UnauthenticatedRequest_ToProtectedEndpoint_Returns401`: send a request without `Authorization` header to a protected endpoint (or to any non-health route); assert `HttpStatusCode.Unauthorized`. Use a `WebApplicationFactory` that does NOT register `TestAuthHandler`.
  - `AuthenticatedRequest_WithTestAuthHandler_Returns200OrExpectedCode`: register `TestAuthHandler`; send a request with a synthetic bearer token; assert response is not 401.
  - `AllResponses_IncludeXCorrelationIdHeader`: send any request; assert response contains `X-Correlation-Id` header.
  - File-scoped namespace `TaskMaster.Api.Tests`.
  - File: `tests/TaskMaster.Api.Tests/AuthIntegrationTests.cs`
  - Acceptance: three `[Fact]` tests using `WebApplicationFactory<Program>`; no real AAD calls; all pass.

- [x] [P5-T9] Verify that the existing health endpoint tests in `tests/TaskMaster.Api.Tests/HealthEndpointTests.cs` continue to pass after the middleware additions. Run `dotnet test --project tests/TaskMaster.Api.Tests` and confirm `HealthEndpointTests` are still green.
  - Acceptance: all pre-existing health endpoint tests pass; `/health` returns `{"status":"ok"}` and HTTP 200.

#### TaskMaster.ArchitectureTests additions

- [x] [P5-T10] Create `tests/TaskMaster.ArchitectureTests/LayerBoundaryTests.cs`: add three `[Fact]` methods in `internal sealed class LayerBoundaryTests`:
  - `ApplicationProjectDoesNotDependOnInfrastructure`: use `Types.InAssembly(typeof(TaskMaster.Application.ICommandBus).Assembly)` that do not have dependency on `"TaskMaster.Infrastructure"`.
  - `ApplicationProjectDoesNotDependOnMicrosoftIdentityWeb`: types in `TaskMaster.Application.*` do not have dependency on `"Microsoft.Identity"`.
  - `DomainProjectDoesNotDependOnApplicationOrInfrastructure`: types in `TaskMaster.Domain.*` do not depend on `"TaskMaster.Application"` or `"TaskMaster.Infrastructure"`. (Note: a `DomainProjectDoesNotDependOnInfrastructure` fact already exists in `NoComArchitectureTests.cs`; add the Application dependency check here as the new assertion.)
  - File-scoped namespace `TaskMaster.ArchitectureTests`. Add `<ProjectReference>` to `TaskMaster.Application.csproj` in `TaskMaster.ArchitectureTests.csproj` if not already present.
  - File: `tests/TaskMaster.ArchitectureTests/LayerBoundaryTests.cs`
  - Acceptance: three `[Fact]` tests compile; all pass when architecture is correct.

- [x] [P5-T11] Update `tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj`: add `<ProjectReference>` entries for `TaskMaster.Application.csproj` and `TaskMaster.Infrastructure.csproj` so their assemblies are loaded into the AppDomain during architecture tests.
  - File: `tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj`
  - Acceptance: csproj includes both new project references; `dotnet build tests/TaskMaster.ArchitectureTests` exits 0.

- [x] [P5-T12] Run `dotnet test` for all four test projects individually to confirm all tests pass before final QA phase:
  - `dotnet test tests/TaskMaster.Application.Tests`
  - `dotnet test tests/TaskMaster.Infrastructure.Tests`
  - `dotnet test tests/TaskMaster.Api.Tests`
  - `dotnet test tests/TaskMaster.ArchitectureTests`
  - Acceptance: all four commands exit 0; no test failures.

#### Graph Token Flow Documentation

- [x] [P5-T13] Create `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/other/graph-token-flow-manual-test-plan.md`: document the manual test procedure for the Graph OBO token flow, including: prerequisites (Azure AD app registration, `AzureAd__ClientSecret` environment variable), steps to acquire a token and call a Graph endpoint via the API, expected outcomes, and notes on the known MVP limitation (`ClientSecret` vs. certificate). This satisfies AC-10 for the Graph flow portion.
  - File: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/other/graph-token-flow-manual-test-plan.md`
  - Acceptance: file exists; contains prerequisites, steps, expected outcomes, and limitation notes.

---

### Phase 6 — Final QA Gate

- [x] [P6-T1] Run `dotnet tool restore` followed by `dotnet csharpier check .` from the solution root; if any files are reported as unformatted, run `dotnet csharpier .` to auto-format, then re-run `dotnet csharpier check .`. Capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t1-csharpier-final.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (pass/fail + file count checked).
  - Acceptance: artifact exists; final `dotnet csharpier check .` EXIT_CODE is 0; all C# files are properly formatted.

- [x] [P6-T2] Run `dotnet build` from the solution root with no additional flags; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t2-build-final.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (project count built, warning count = 0, error count = 0).
  - Acceptance: artifact exists; EXIT_CODE is 0; zero warnings; zero errors; `TreatWarningsAsErrors=true` enforced.

- [x] [P6-T3] Run `dotnet test --collect:"XPlat Code Coverage"` from the solution root; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t3-test-coverage-final.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (total tests passed/failed, line coverage % for each new production project, branch coverage % for each new production project).
  - Acceptance: artifact exists; EXIT_CODE is 0; all tests pass; numeric per-project coverage values are recorded.

- [x] [P6-T4] Run `dotnet test --project tests/TaskMaster.ArchitectureTests` from the solution root; capture output to `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t4-architecture-final.md` with fields: Timestamp, Command, EXIT_CODE, Output Summary (test count, pass/fail, names of passing architecture facts).
  - Acceptance: artifact exists; EXIT_CODE is 0; all architecture tests pass including the three new `LayerBoundaryTests` facts.

- [x] [P6-T5] Review coverage values from P6-T3 against policy thresholds: for each of `TaskMaster.Application`, `TaskMaster.Infrastructure`, `TaskMaster.Api` — confirm line coverage >= 85% and branch coverage >= 75%. Record coverage delta (P0-T8 baseline vs P6-T3 post-change) in `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t5-coverage-delta.md` with fields: Timestamp, per-project baseline coverage, per-project post-change coverage, policy threshold, PASS/FAIL verdict per project.
  - Acceptance: artifact exists; all three production projects meet or exceed policy thresholds; FAIL verdict for any project is a blocking finding requiring remediation before the plan can be reported as complete.

- [x] [P6-T6] If any step in P6-T1 through P6-T5 failed or auto-fixed files, restart the QA loop from P6-T1 and repeat until all five steps pass in a single sequential run.
  - Acceptance: the most recent artifacts for P6-T1 through P6-T5 all show EXIT_CODE 0 and PASS verdicts from a single uninterrupted run.

---

## Open Questions / Notes

1. **`IGraphClientFactory` in Application layer:** The interface returns `GraphServiceClient` (from `Microsoft.Graph`), which creates an implicit package dependency in `TaskMaster.Application`. The architecture rule states Application may depend on Domain only. Pragmatic resolution: add `Microsoft.Graph` as a package reference to `TaskMaster.Application.csproj` with a csproj-level comment documenting this as an approved exception (Graph SDK has no COM/VSTO/Office dependency and is a Microsoft-owned stable contract). This is noted in P2-T6 with an option to reconsider at implementation time.

2. **`InMemoryUserSettingsRepository` test location:** Tests for this class are placed in `TaskMaster.Application.Tests` (P5-T2) rather than `TaskMaster.Infrastructure.Tests` because the Application-Tests project has access to both the interface and the in-memory implementation, and locating these tests alongside the interface contract is more natural for T2 contract validation.

3. **`ClientSecret` in OBO flow:** The secret must be supplied via `AzureAd__ClientSecret` environment variable; it must not be committed to source. `appsettings.json` contains only a structural placeholder (P4-T4).

4. **NSwag net10 gap:** Carried from Issue #7; no change in this feature. `EnableNSwagEmission=false` remains the default in `TaskMaster.Api.csproj`.

5. **Health endpoint dependency probes:** Issue #12 mentions expanding to dependency probes as a follow-on. This plan does not add `Microsoft.Extensions.Diagnostics.HealthChecks` registrations; the MVP contract (existing `{"status":"ok"}` shape) is preserved.

6. **`IFileReader` seam:** If `JsonFileUserSettingsRepository.GetAsync` reads via `System.IO.File.ReadAllText` directly, the test in P5-T4 may need a second seam. The `IFileWriter` interface may be extended to include `ReadAllText` (renaming to `IFileSystem` or keeping as `IFileWriter` with dual read/write methods). This decision is deferred to implementation; the plan tasks accommodate either approach.
