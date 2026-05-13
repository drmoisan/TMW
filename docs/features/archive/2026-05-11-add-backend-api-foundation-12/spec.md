# 2026-05-11-add-backend-api-foundation — Spec

- **Issue:** #12
- **Parent (optional):** #7 (C1 .NET Foundation)
- **Owner:** drmoisan
- **Last Updated:** 2026-05-12
- **Status:** Draft
- **Version:** 0.2

## Overview

The C1 .NET foundation (Issue #7) established the solution skeleton, CI gates, and an unauthenticated health-only API in `TaskMaster.Api`. The solution currently has no application layer, no authentication, no user-settings storage, and no path to Microsoft Graph. As a result, the Office add-in cannot authenticate users, persist preferences, route commands to handlers, or retrieve mailbox data from Graph. Issue #12 introduces the `TaskMaster.Application` and `TaskMaster.Infrastructure` projects and extends `TaskMaster.Api` to close all four gaps.

## Behavior

The following outcomes are required on completion of this feature:

1. **Authenticated API.** All endpoints except `/health` require a valid JWT bearer token issued by the configured Azure AD tenant. Requests without a valid token receive `HTTP 401 Unauthorized`. The `/health` endpoint remains public via `.AllowAnonymous()`.

2. **Graph access path.** `IGraphClientFactory` (interface in `TaskMaster.Application`) and its concrete implementation in `TaskMaster.Infrastructure` provide a testable, DI-resolved wrapper around `GraphServiceClient`. The implementation delegates token acquisition to `Microsoft.Identity.Web.GraphServiceClient` (`AddMicrosoftGraphServiceClient()`), which uses the MSAL token cache established by `AddMicrosoftIdentityWebApi`.

3. **User settings storage.** `IUserSettingsRepository` (interface in `TaskMaster.Application`) exposes `GetAsync`, `SaveAsync`, and `DeleteAsync` operations. `TaskMaster.Infrastructure` ships two implementations: an in-memory implementation backed by `ConcurrentDictionary<string, UserSettings>` (for development and testing) and a JSON-file implementation using `System.Text.Json` with atomic writes via `File.Replace`.

4. **Correlation ID middleware.** Hand-rolled `CorrelationIdMiddleware` (`IMiddleware`) runs first in the ASP.NET Core pipeline. If the incoming request contains `X-Correlation-Id`, that value is preserved and echoed on the response. If the header is absent, a new `Guid.NewGuid().ToString()` is generated. The value is added to the structured logging scope via `ILogger.BeginScope` so that it appears in every log entry for the request.

5. **Health endpoint.** The existing `/health` endpoint continues to return `{"status":"ok"}`. Dependency probes (e.g., `Microsoft.Extensions.Diagnostics.HealthChecks` registrations) may be added as a follow-on; the MVP contract is the existing JSON shape.

6. **No desktop Outlook automation.** No project in the solution may reference `Microsoft.Office.Interop.Outlook`, VSTO, or any COM-based Office assembly. The existing architecture tests enforce this; new architecture test assertions for Application-layer isolation are added in this feature.

## Inputs / Outputs

### Configuration Keys (`appsettings.json` — `AzureAd` section)

| Key | Required | Default / Notes |
|---|---|---|
| `AzureAd:Instance` | No | `https://login.microsoftonline.com/` |
| `AzureAd:TenantId` | Yes | GUID, `common`, `organizations`, or `consumers` |
| `AzureAd:ClientId` | Yes | App registration client ID (GUID) |
| `AzureAd:Audience` | Conditional | Required when the App ID URI differs from `api://{ClientId}` |
| `AzureAd:ClientSecret` | Yes (OBO flow) | Confidential-client credential for On-Behalf-Of token acquisition; supply via environment variable or Key Vault reference in production. Do not commit to source. |

### Environment Variables

| Variable | Purpose |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | Controls which `appsettings.{env}.json` file is loaded. Set to `Development` locally. |
| `AzureAd__ClientSecret` | Overrides `AzureAd:ClientSecret` at runtime (ASP.NET Core environment-variable config provider). |

### Health Endpoint Response Shape

```
GET /health
→ 200 OK
Content-Type: application/json

{"status":"ok"}
```

### Request / Response Headers (all endpoints)

| Header | Direction | Behavior |
|---|---|---|
| `X-Correlation-Id` | Request → Response | Preserved from request if present; generated (`Guid.NewGuid()`) if absent. Always echoed in response. |
| `Authorization: Bearer <token>` | Request | Required on all endpoints except `/health`. Absence or invalidity returns `401 Unauthorized`. |

## API / CLI Surface

### Endpoints

| Method | Path | Auth Required | Description |
|---|---|---|---|
| `GET` | `/health` | No (`.AllowAnonymous()`) | Returns `{"status":"ok"}`. |
| All other routes | TBD in subsequent issues | Yes | Require a valid bearer token; return `401` if missing or invalid. |

### Middleware Pipeline Order (relevant excerpt)

```
CorrelationIdMiddleware   ← runs first; sets X-Correlation-Id on every request
UseAuthentication()
UseAuthorization()
MapHealthChecks / endpoint routing
```

`CorrelationIdMiddleware` is placed before `UseAuthentication()` so the correlation ID is present on `401` responses.

### New DI Registrations (`TaskMaster.Api` — `Program.cs`)

| Service | Lifetime | Implementation |
|---|---|---|
| `CorrelationIdMiddleware` | Transient | Hand-rolled `IMiddleware` |
| `AddAuthentication` + `AddMicrosoftIdentityWebApi` | Singleton (token validation) | `Microsoft.Identity.Web` 4.9.0 |
| `AddMicrosoftGraphServiceClient` | Scoped | `Microsoft.Identity.Web.GraphServiceClient` 4.9.0 |
| `ICommandBus` → `ServiceProviderCommandBus` | Scoped | `TaskMaster.Application` |
| `IUserSettingsRepository` → `InMemoryUserSettingsRepository` | Singleton (dev) | `TaskMaster.Infrastructure` |
| `IGraphClientFactory` → concrete implementation | Scoped | `TaskMaster.Infrastructure` |

### Key Types Added

| Type | Project | Kind | Purpose |
|---|---|---|---|
| `ICommandBus` | `TaskMaster.Application` | Interface | Dispatches commands to registered handlers |
| `ICommandHandler<TCommand>` | `TaskMaster.Application` | Generic interface | Handles a specific command type |
| `ServiceProviderCommandBus` | `TaskMaster.Application` | Class | Resolves `ICommandHandler<TCommand>` from `IServiceProvider` at dispatch time |
| `IUserSettingsRepository` | `TaskMaster.Application` | Interface | CRUD interface for `UserSettings` |
| `UserSettings` | `TaskMaster.Application` | Record | Domain model; keyed by `UserId` |
| `IGraphClientFactory` | `TaskMaster.Application` | Interface | Returns a configured `GraphServiceClient` |
| `InMemoryUserSettingsRepository` | `TaskMaster.Infrastructure` | Class | `ConcurrentDictionary`-backed implementation |
| `JsonFileUserSettingsRepository` | `TaskMaster.Infrastructure` | Class | JSON-file implementation with atomic writes |
| `IFileWriter` | `TaskMaster.Infrastructure` | Interface | Seam over `File.Replace` for testability |
| `GraphClientFactory` | `TaskMaster.Infrastructure` | Class | Thin wrapper around DI-resolved `GraphServiceClient` |
| `CorrelationIdMiddleware` | `TaskMaster.Api` | Class | Generates or propagates `X-Correlation-Id` |

## Data & State

### `UserSettings` Record (MVP fields)

| Field | Type | Notes |
|---|---|---|
| `UserId` | `string` | Primary key; matches the OID claim from the JWT. |
| `NotificationsEnabled` | `bool` | Whether the add-in should surface in-app notifications. Default `true`. |
| `TriageEnabled` | `bool` | Whether automatic triage classification is active. Default `false`. |
| `LastModifiedAt` | `DateTimeOffset` | Populated via injected `TimeProvider`. Not set by callers; set by `SaveAsync`. |

The `UserSettings` record lives in `TaskMaster.Application`. Its fields are intentionally minimal for the MVP; additional preference fields are deferred to subsequent issues.

### Persistence Strategy

| Implementation | Storage | Concurrency | When to Use |
|---|---|---|---|
| `InMemoryUserSettingsRepository` | `ConcurrentDictionary<string, UserSettings>` in process memory | Thread-safe reads and writes via `ConcurrentDictionary` API | Development, automated tests, demo environment |
| `JsonFileUserSettingsRepository` | Single JSON file on disk; path configured via `IOptions<UserSettingsFileOptions>` | Atomic write via `File.Replace` (temp file, then replace); concurrent write races are a known MVP limitation | Local development with persistence across restarts |

The active implementation is selected via DI registration in `Program.cs`. No database migration is required for either MVP implementation.

### Data Flow

```
Client request
  → CorrelationIdMiddleware (sets X-Correlation-Id in scope)
  → Authentication middleware (validates JWT, populates HttpContext.User)
  → Endpoint handler
      → ICommandBus.DispatchAsync<TCommand>
          → ICommandHandler<TCommand> (e.g., SaveUserSettingsCommandHandler)
              → IUserSettingsRepository.SaveAsync(settings, ct)
```

## Constraints & Risks

1. **No COM or Outlook desktop automation.** No reference to `Microsoft.Office.Interop.Outlook`, VSTO, or any COM-based Office assembly is permitted in any project. This is enforced by existing `TaskMaster.ArchitectureTests` and extended by new assertions for the Application layer.

2. **NSwag net10 launcher gap (carried from C1).** OpenAPI JSON remains hand-authored until the upstream NSwag net10 launcher issue is resolved. `AddOpenApi()` is already in place; the gap is in the NSwag CLI launcher, not the runtime.

3. **Package pinning required.** `Microsoft.Identity.Web` 4.9.0, `Microsoft.Identity.Web.GraphServiceClient` 4.9.0, `Microsoft.Graph` 5.105.0, and `CsCheck` 4.6.2 must be added to `Directory.Packages.props`. `Microsoft.AspNetCore.Mvc.Testing` must be upgraded from 9.0.10 to 10.0.7 to align with the net10.0 host.

4. **Uniform coverage thresholds.** Line coverage >= 85% and branch coverage >= 75% apply to all tiers (T1–T4). There are no tier-specific lower floors.

5. **`ClientSecret` credential type.** The OBO flow requires a confidential-client credential. For the MVP, `ClientSecret` is used. Certificate-based credentials are deferred. The secret must not be committed to source; it must be supplied via environment variable (`AzureAd__ClientSecret`) or a Key Vault reference.

6. **`UserSettings` concurrent write race (JSON-file implementation).** The JSON-file implementation uses `File.Replace` for atomic writes but does not serialize concurrent write operations. If two requests attempt `SaveAsync` simultaneously, the last write wins and no error is raised. This is a documented limitation of the MVP; a locking mechanism or a proper database are deferred.

## Implementation Strategy

### Project-Level Changes

1. **New: `src/TaskMaster.Application`** (T2, net10.0)
   - Add to solution.
   - References: `TaskMaster.Domain` only. No infrastructure or auth packages.
   - Contains: `ICommandBus`, `ICommandHandler<TCommand>`, `ServiceProviderCommandBus`, `IUserSettingsRepository`, `UserSettings` record, `IGraphClientFactory`.

2. **New: `src/TaskMaster.Infrastructure`** (T3, net10.0)
   - Add to solution.
   - References: `TaskMaster.Application`, `TaskMaster.Domain`, `Microsoft.Graph` 5.105.0, `Microsoft.Identity.Web.GraphServiceClient` 4.9.0.
   - Contains: `InMemoryUserSettingsRepository`, `JsonFileUserSettingsRepository`, `IFileWriter`, `GraphClientFactory`.

3. **Update: `src/TaskMaster.Api`**
   - Add package references: `Microsoft.Identity.Web` 4.9.0, project references to `TaskMaster.Application` and `TaskMaster.Infrastructure`.
   - `Program.cs`: add `CorrelationIdMiddleware` registration, `AddMicrosoftIdentityWebApi`, `AddMicrosoftGraphServiceClient`, `UseAuthentication`, `UseAuthorization`, DI registrations for `ICommandBus` and `IUserSettingsRepository`.

4. **New: `tests/TaskMaster.Application.Tests`** (T4, net10.0)
   - xUnit + NSubstitute + FluentAssertions + CsCheck.
   - Unit tests: `ServiceProviderCommandBus` dispatch, handler-not-found path, `InMemoryUserSettingsRepository` CRUD.
   - Property-based tests (CsCheck): at least one test per pure function in `TaskMaster.Application`.

5. **New: `tests/TaskMaster.Infrastructure.Tests`** (T4, net10.0)
   - xUnit + NSubstitute + FluentAssertions + WireMock.Net.
   - Unit tests: `JsonFileUserSettingsRepository` via `IFileWriter` seam (no real filesystem access).
   - Integration tests: `GraphClientFactory` via WireMock.Net stub.

6. **Update: `tests/TaskMaster.Api.Tests`**
   - Upgrade `Microsoft.AspNetCore.Mvc.Testing` from 9.0.10 to 10.0.7.
   - Add `TestAuthHandler` and a `WebApplicationFactory` variant that registers it.
   - Add test: no bearer token → `401 Unauthorized`.
   - Add test: `TestAuthHandler` registered, request sent → `200 OK`.
   - Add test: `X-Correlation-Id` present on all responses including `401`.

7. **Update: `tests/TaskMaster.ArchitectureTests`**
   - New `[Fact]`: `ApplicationProjectDoesNotDependOnInfrastructure`.
   - New `[Fact]`: `ApplicationProjectDoesNotDependOnMicrosoftIdentityWeb`.
   - New `[Fact]`: `DomainProjectDoesNotDependOnApplicationOrInfrastructure`.

### Package Additions to `Directory.Packages.props`

| Package | Version | Reason |
|---|---|---|
| `Microsoft.Identity.Web` | 4.9.0 | Bearer token validation in `TaskMaster.Api` |
| `Microsoft.Identity.Web.GraphServiceClient` | 4.9.0 | DI-registered `GraphServiceClient` wired to MSAL token cache |
| `Microsoft.Graph` | 5.105.0 | Graph SDK |
| `CsCheck` | 4.6.2 | Property-based tests for T2 `TaskMaster.Application` |

| Package | Current | New | Reason |
|---|---|---|---|
| `Microsoft.AspNetCore.Mvc.Testing` | 9.0.10 | 10.0.7 | Align major version with net10.0 host |

### `quality-tiers.yml` Additions

Four new entries: `TaskMaster.Application` (T2), `TaskMaster.Infrastructure` (T3), `TaskMaster.Application.Tests` (T4), `TaskMaster.Infrastructure.Tests` (T4).

### Logging and Telemetry

- `CorrelationIdMiddleware` adds `CorrelationId` to the structured logging scope via `ILogger.BeginScope` on every request.
- All command handler and repository methods should log at `Debug` level on entry and `Information` level on successful completion of a state-changing operation.
- No new telemetry packages are introduced in this feature; the existing logging pipeline is extended.

### Rollout

No feature flags are required. The changes are additive (new projects, new middleware, new registrations). The existing unauthenticated `/health` endpoint remains public; all other endpoints—none of which exist yet—will require auth when introduced in subsequent issues.

## Definition of Done

| Acceptance Criterion | Verification Method |
|---|---|
| `TaskMaster.Application` project exists; contains command bus abstraction and `IUserSettingsRepository` interface. | `dotnet build` succeeds; `TaskMaster.Application.Tests` unit tests pass; architecture tests pass. |
| `TaskMaster.Infrastructure` project exists; contains Graph adapter and at least one `IUserSettingsRepository` implementation. | `dotnet build` succeeds; `TaskMaster.Infrastructure.Tests` pass. |
| Bearer token validation is wired in `TaskMaster.Api` via `Microsoft.Identity.Web`. | Integration test in `TaskMaster.Api.Tests`: no bearer token → `HTTP 401`. |
| Correlation ID middleware propagates `X-Correlation-Id` through all requests. | Unit test: header absent → generated GUID echoed; header present → value preserved. |
| `/health` endpoint returns `{"status":"ok"}`. | Existing `HealthEndpointTests` pass (extended to assert on new pipeline). |
| `dotnet build` passes with zero warnings and zero analyzer errors. | CI `dotnet build` gate with `TreatWarningsAsErrors=true`. |
| All new projects pass `dotnet csharpier check .`, architecture tests, and `dotnet test`. | CI format, architecture, and test stages. |
| `quality-tiers.yml` updated for all new projects. | CI `tier-classification` stage validates all projects have a tier entry. |
| Unit tests cover settings CRUD and command routing at >= 85% line / >= 75% branch. | CI coverage gate (Coverlet + ReportGenerator). |
| Auth and Graph token flow covered by integration test or documented manual test plan. | `TestAuthHandler`-based integration test in `TaskMaster.Api.Tests`; Graph flow documented in `docs/features/active/2026-05-11-add-backend-api-foundation-12/` if automated coverage is deferred. |
| No `Microsoft.Office.Interop.Outlook` or VSTO references anywhere. | `TaskMaster.ArchitectureTests` no-COM assertions pass; `dotnet build` with no such references. |

## Seeded Test Conditions (from issue)

- [x] Unit: `IUserSettingsRepository` in-memory implementation CRUD operations.
- [x] Unit: command bus dispatches to correct handler.
- [x] Unit: correlation ID middleware sets header on requests without existing header; preserves header when present.
- [x] Integration: bearer token validation rejects unauthenticated requests (401).
- [x] Integration or documented manual: Graph token acquisition flow.
