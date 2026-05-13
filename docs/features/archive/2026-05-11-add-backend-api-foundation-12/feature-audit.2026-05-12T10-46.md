# Feature Audit — Issue #12: Add Backend API Foundation

- **Artifact type:** feature-audit
- **Timestamp:** 2026-05-12T10-46
- **Feature folder:** docs/features/active/2026-05-11-add-backend-api-foundation-12/
- **Branch:** feature/add-backend-api-foundation-12
- **Merge base:** d166efc803e0c3c849770a90360726486f941050
- **Reviewer:** Feature Review Agent (claude-sonnet-4-6)
- **Work mode:** full-feature
- **AC sources:** `spec.md` and `user-story.md`

---

## Baseline

- Pre-feature: `TaskMaster.Api` (health-only, unauthenticated) + `TaskMaster.Domain` (empty placeholder).
- Post-feature: `TaskMaster.Application`, `TaskMaster.Infrastructure`, `TaskMaster.Api` (extended), plus corresponding test projects.
- CI baseline evidence: `evidence/baseline/p0-t7-build-baseline.md`, `p0-t8-test-coverage-baseline.md`, `p0-t9-architecture-baseline.md`.
- CI final evidence: `evidence/qa-gates/p6-t1-csharpier-final.md` through `p6-t5-coverage-delta.md`.

---

## Acceptance Criteria Evaluation

AC source: `user-story.md` § "Acceptance Criteria" (canonical per `full-feature` work mode). The 11-item list matches `issue.md` § "Acceptance Criteria" verbatim.

| # | Acceptance Criterion | Source File | Verdict | Evidence / Notes |
|---|---|---|---|---|
| AC-1 | `TaskMaster.Application` project exists; contains command bus abstraction and `IUserSettingsRepository` interface. | user-story.md, spec.md | **PASS** | `src/TaskMaster.Application/` contains `ICommandBus.cs`, `ICommandHandler.cs`, `ServiceProviderCommandBus.cs`, `IUserSettingsRepository.cs`, `UserSettings.cs`, `IGraphClientFactory.cs`. Build passes. Architecture tests pass. |
| AC-2 | `TaskMaster.Infrastructure` project exists; contains Graph adapter and at least one `IUserSettingsRepository` implementation. | user-story.md, spec.md | **PASS** | `src/TaskMaster.Infrastructure/` contains `GraphClientFactory.cs`, `InMemoryUserSettingsRepository.cs`, `JsonFileUserSettingsRepository.cs`. Both repository implementations present. `p6-t2-build-final.md` EXIT_CODE: 0. |
| AC-3 | Bearer token validation is wired in `TaskMaster.Api` via `Microsoft.Identity.Web`. | user-story.md, spec.md | **PARTIAL** | `Program.cs` correctly calls `AddAuthentication().AddMicrosoftIdentityWebApi(...)`, `UseAuthentication()`, `UseAuthorization()`. Middleware pipeline order is correct. **Gap:** No integration test demonstrates `401 Unauthorized` on a protected endpoint (spec "Definition of Done" requires this). The authentication is wired but its rejection behavior has not been verified by automated test. |
| AC-4 | Correlation ID middleware propagates `X-Correlation-Id` through all requests. | user-story.md, spec.md | **PASS** | `CorrelationIdMiddleware.cs` implemented and registered before `UseAuthentication()`. `CorrelationIdMiddlewareTests` (2 tests): absent header → generates GUID; present header → preserves value. `AuthIntegrationTests.AllResponses_IncludeXCorrelationIdHeader` confirms header present on live HTTP responses. |
| AC-5 | `/health` endpoint returns `{"status":"ok"}`. | user-story.md, spec.md | **PASS** | `HealthEndpointTests.GetHealth_ReturnsOkAndStatusOk` verifies `{"status":"ok"}` shape and `200 OK`. `HealthEndpointTests.GetHealth_ReturnsJsonContentType` verifies `application/json`. Both pass in `p6-t3-test-coverage-final.md`. |
| AC-6 | `dotnet build` passes with zero warnings and zero analyzer errors. | user-story.md, spec.md | **PASS** | `p6-t2-build-final.md`: EXIT_CODE: 0, 8 projects built, warning count: 0, error count: 0. `TreatWarningsAsErrors=true` confirmed. |
| AC-7 | All new projects pass `dotnet csharpier check .`, architecture tests, and `dotnet test`. | user-story.md, spec.md | **PASS** | CSharpier: `p6-t1-csharpier-final.md` (EXIT_CODE: 0). Architecture tests: `p6-t4-architecture-final.md` (6/6 pass). Unit tests: `p6-t3-test-coverage-final.md` (32/32 pass). |
| AC-8 | `quality-tiers.yml` updated for all new projects. | user-story.md, spec.md | **PASS** | Four new entries in `quality-tiers.yml`: `TaskMaster.Application` (T2), `TaskMaster.Infrastructure` (T3), `TaskMaster.Application.Tests` (T4), `TaskMaster.Infrastructure.Tests` (T4). All entries have required fields. |
| AC-9 | Unit tests cover settings CRUD and command routing at >= 85% line / >= 75% branch. | user-story.md, spec.md | **PASS** | `InMemoryUserSettingsRepositoryTests` (6 tests): CRUD operations fully covered. `CommandBusTests` (2 tests): dispatch and handler-not-found covered. Coverage: Application 100%/100%, Infrastructure ~93%/~100%. `p6-t5-coverage-delta.md` confirms all above 85%/75% thresholds. |
| AC-10 | Auth and Graph token flow covered by integration test or documented manual test plan. | user-story.md, spec.md | **PASS** | `AuthIntegrationTests` uses `TestAuthHandler` + `CustomWebApplicationFactory` for automated auth coverage. Graph OBO flow documented in `evidence/other/graph-token-flow-manual-test-plan.md` (138 lines). The spec explicitly states "documented manual test plan" is an acceptable alternative. |
| AC-11 | No `Microsoft.Office.Interop.Outlook` or VSTO references anywhere. | user-story.md, spec.md | **PASS** | Architecture tests `NoComArchitectureTests.NoProjectDependsOnOutlookInterop` and `NoProjectDependsOnForbiddenLegacyNamespaces` pass. Source scan confirms no COM/VSTO assembly references. |

**AC Summary:**
- Total AC items: 11
- PASS: 10
- PARTIAL: 1 (AC-3)
- FAIL: 0

---

## Spec Behavior Verification

The spec (§ Behavior) defines 6 required outcomes:

| Spec Behavior | Verdict | Evidence |
|---|---|---|
| 1. Authenticated API — all endpoints except `/health` require JWT; `/health` uses `.AllowAnonymous()`. | PARTIAL | Middleware wired correctly; no protected endpoint exists yet to test `401` rejection. |
| 2. Graph access path — `IGraphClientFactory` in Application; `GraphClientFactory` in Infrastructure. | PASS | Both types present; architecture tests pass; `GraphClientFactoryTests` pass. |
| 3. User settings storage — `GetAsync`/`SaveAsync`/`DeleteAsync`; `InMemoryUserSettingsRepository` + `JsonFileUserSettingsRepository`. | PASS | Both implementations present and tested. |
| 4. Correlation ID middleware — `IMiddleware`; generate or preserve header; structured logging scope. | PASS | Implemented and unit tested. |
| 5. Health endpoint — returns `{"status":"ok"}`. | PASS | Integration test confirms. |
| 6. No desktop Outlook automation. | PASS | Architecture tests and source scan confirm. |

---

## Spec Inputs/Outputs Verification

- `AzureAd` configuration section present in `appsettings.json` with all required keys (`Instance`, `TenantId`, `ClientId`, `Audience`). Values are empty placeholders — correct for committed source.
- `X-Correlation-Id` request/response header behavior: verified by `CorrelationIdMiddlewareTests` and `AuthIntegrationTests.AllResponses_IncludeXCorrelationIdHeader`.
- `UserSettings` record fields (`UserId`, `NotificationsEnabled`, `TriageEnabled`, `LastModifiedAt`): all four present as specified in spec § Data & State.

---

## Spec API Surface Verification

| Type | Project | Kind | Present | Tested |
|---|---|---|---|---|
| `ICommandBus` | `TaskMaster.Application` | Interface | Yes | Yes (CommandBusTests) |
| `ICommandHandler<TCommand>` | `TaskMaster.Application` | Generic interface | Yes | Yes (CommandBusTests) |
| `ServiceProviderCommandBus` | `TaskMaster.Application` | Class | Yes | Yes (CommandBusTests) |
| `IUserSettingsRepository` | `TaskMaster.Application` | Interface | Yes | Yes (InMemoryUserSettingsRepositoryTests, JsonFileUserSettingsRepositoryTests) |
| `UserSettings` | `TaskMaster.Application` | Record | Yes | Yes (UserSettingsPropertyTests, InMemoryUserSettingsRepositoryTests) |
| `IGraphClientFactory` | `TaskMaster.Application` | Interface | Yes | Yes (GraphClientFactoryTests, CustomWebApplicationFactory) |
| `InMemoryUserSettingsRepository` | `TaskMaster.Infrastructure` | Class | Yes | Yes (6 CRUD tests) |
| `JsonFileUserSettingsRepository` | `TaskMaster.Infrastructure` | Class | Yes | Yes (3 tests via IFileWriter seam) |
| `IFileWriter` | `TaskMaster.Infrastructure` | Interface | Yes | Indirectly (JsonFileUserSettingsRepositoryTests stubs it) |
| `GraphClientFactory` | `TaskMaster.Infrastructure` | Class | Yes | Yes (GraphClientFactoryTests) |
| `CorrelationIdMiddleware` | `TaskMaster.Api` | Class | Yes | Yes (CorrelationIdMiddlewareTests, AuthIntegrationTests) |

All 11 key types specified in the spec are present and tested.

---

## Middleware Pipeline Order Verification

Spec requires:
```
CorrelationIdMiddleware → UseAuthentication() → UseAuthorization() → endpoint routing
```

Actual `Program.cs` order:
```csharp
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseAuthentication();
app.UseAuthorization();
app.MapGet("/health", ...).AllowAnonymous();
```

Verdict: **PASS** — Order matches spec exactly.

---

## DI Registrations Verification

Spec (§ API / CLI Surface — New DI Registrations):

| Service | Lifetime | Spec | Actual | Verdict |
|---|---|---|---|---|
| `CorrelationIdMiddleware` | Transient | Transient | `AddTransient<CorrelationIdMiddleware>()` | PASS |
| `AddAuthentication` + `AddMicrosoftIdentityWebApi` | (token validation) | Singleton | `.AddMicrosoftIdentityWebApi(...)` | PASS |
| `AddMicrosoftGraphServiceClient` | Scoped | Scoped | `builder.Services.AddMicrosoftGraph()` | PASS |
| `ICommandBus` → `ServiceProviderCommandBus` | Scoped | Scoped | `AddScoped<ICommandBus, ServiceProviderCommandBus>()` | PASS |
| `IUserSettingsRepository` → `InMemoryUserSettingsRepository` | Singleton (dev) | Singleton | `AddSingleton<IUserSettingsRepository>(_ => new InMemoryUserSettingsRepository(TimeProvider.System))` | PASS |
| `IGraphClientFactory` → concrete | Scoped | Scoped | `AddScoped<IGraphClientFactory, GraphClientFactory>()` | PASS |

---

## Seeded Test Conditions (from issue.md)

| Test Condition | Status | Evidence |
|---|---|---|
| Unit: `IUserSettingsRepository` in-memory CRUD operations | PASS | `InMemoryUserSettingsRepositoryTests` (6 tests) |
| Unit: command bus dispatches to correct handler | PASS | `CommandBusTests.DispatchAsync_WithRegisteredHandler_CallsHandleAsync` |
| Unit: correlation ID middleware sets header (absent → generated; present → preserved) | PASS | `CorrelationIdMiddlewareTests` (2 tests) |
| Integration: bearer token validation rejects unauthenticated requests (401) | PARTIAL | No 401 test exists; no protected endpoint exists in MVP scope |
| Integration or documented manual: Graph token acquisition flow | PASS | Manual test plan at `evidence/other/graph-token-flow-manual-test-plan.md` |

---

## Coverage Regression Check

| Project | Baseline Line | Post-change Line | Regression? |
|---|---|---|---|
| TaskMaster.Api | 3.79% (excl. generated) | 100% | No (improvement) |
| TaskMaster.Application | N/A (new project) | 100% | N/A |
| TaskMaster.Infrastructure | N/A (new project) | ~93% | N/A |

No regression on changed lines. All coverage improvements from baseline.

---

## AC Check-Off Actions

Per the acceptance criteria tracking skill, the reviewer checks off AC items evaluated as PASS.

The following AC items in `user-story.md` are confirmed PASS and should be checked off:
- AC-1, AC-2, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11 (10 of 11)

AC-3 remains unchecked (PARTIAL) pending:
1. Addition of at least one protected endpoint in a subsequent issue, AND
2. An integration test demonstrating `HTTP 401 Unauthorized` on that endpoint without a bearer token.

AC items in `user-story.md` are already marked `[x]` for all 11 items in the current branch (the executor pre-checked them). The reviewer's assessment is that AC-3 should be reverted to `[ ]` in `user-story.md` and `issue.md` pending the remediation. The `issue.md` still shows `- [ ]` for all AC items (the GitHub issue body was not updated during plan execution). Remediation inputs document this gap.

---

### Acceptance Criteria Status

- Source: `user-story.md`, `spec.md`
- Total AC items: 11
- Checked off (PASS in this review): 10
- Remaining (PARTIAL/not fully verifiable): 1
- Items remaining: AC-3 — "Bearer token validation is wired in `TaskMaster.Api` via `Microsoft.Identity.Web`." Wiring is present but the `HTTP 401` integration test is absent.

---

## Overall Feature Audit Verdict

**PARTIAL** — The feature delivers all specified types, wiring, and passing tests for 10 of 11 AC items. AC-3 is partially met: the authentication middleware is correctly registered but no automated integration test demonstrates the `401 Unauthorized` rejection behavior, as no protected endpoint exists in the current MVP scope. This is a structural gap that requires a follow-on action in the next issue introducing a protected endpoint.
