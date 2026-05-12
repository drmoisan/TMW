# `2026-05-11-add-backend-api-foundation` — User Story

- Issue: #12
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-12

## Story Statement

- As a **developer building the TaskMaster Office add-in**, I want an authenticated backend API with a working command bus, user-settings repository, and Graph access path, so that I can wire the add-in's startup sequence to acquire a token, persist user preferences, and retrieve mailbox data without touching Outlook desktop automation.

- As an **Office add-in user**, I want my notification and triage preferences stored securely on the server and associated with my identity, so that my settings persist across sessions and devices without requiring me to reconfigure the add-in each time I open Outlook.

## Problem / Why

The C1 .NET foundation (Issue #7) established the solution skeleton, CI gates, and an unauthenticated health-only API. There is no backend service that owns user settings, classifier state, Graph access, or audit logging. The add-in cannot persist user preferences, route commands, or reach Microsoft Graph without this foundation.

Concretely:

- Any request to the API today proceeds without any identity check. A protected multi-user settings API cannot be built on top of an unauthenticated host.
- There is no command bus, so there is no structured way to route operations from the API layer to application logic.
- There is no user-settings repository, so preferences cannot be stored or retrieved.
- There is no Graph adapter, so the backend cannot call Microsoft Graph on behalf of the authenticated user.
- All of these gaps must be closed before any feature work that involves user identity or mailbox data can proceed.

## Personas & Scenarios

### Persona 1 — Developer (add-in integrator)

- **Who:** A .NET developer extending the TaskMaster add-in, working in Visual Studio or VS Code against the `main` branch.
- **What they care about:** A stable, testable backend they can call from the add-in's JavaScript layer. Clean DI registrations. No magic or heavy frameworks. Fast test feedback.
- **Constraints:** Must work on net10.0. Cannot introduce COM or VSTO references. Must pass the CI gate (format, lint, type-check, arch tests, unit tests, coverage) before merging.
- **Goals:** Wire the add-in startup to call `/settings` with a token and get back user preferences. Write a unit test for a new command handler without needing to spin up Azure AD.
- **Frustrations:** Losing time debugging version mismatches (`Mvc.Testing` 9 vs net10 host). Unclear where interfaces vs. implementations belong in the project structure.

### Persona 2 — End user (Office add-in consumer)

- **Who:** A knowledge worker who has installed the TaskMaster add-in in Outlook on one or more devices.
- **What they care about:** The add-in behaves consistently. Preferences set on one device are available on another. Notifications and triage settings do not reset after a restart.
- **Constraints:** Uses Microsoft 365 with a work or school account (Azure AD-backed). Has no visibility into the backend architecture.
- **Goals:** Enable triage classification once and have it remain enabled. Disable notifications without being asked again.
- **Frustrations:** Having to reconfigure the add-in after signing out or switching devices.

### Scenario 1 — Add-in startup: token acquisition and settings retrieval

1. The user opens Outlook. The TaskMaster add-in task pane loads.
2. The add-in's JavaScript layer calls `Office.auth.getAccessToken()` to acquire an SSO token.
3. The add-in sends `GET /settings` to `TaskMaster.Api` with `Authorization: Bearer <sso_token>`.
4. `CorrelationIdMiddleware` runs first: no `X-Correlation-Id` is in the request, so the middleware generates `guid-abc123`, sets it on the response header, and adds it to the logging scope.
5. `UseAuthentication()` validates the bearer token against Azure AD (tenant ID and client ID from `AzureAd` config). The token is valid; `HttpContext.User` is populated with the user's OID claim.
6. The endpoint handler dispatches `GetUserSettingsCommand` via `ICommandBus`.
7. `GetUserSettingsCommandHandler` calls `IUserSettingsRepository.GetAsync(userId)`. The in-memory repository finds the settings and returns them.
8. The API responds `200 OK` with the user's `UserSettings` JSON. The response includes `X-Correlation-Id: guid-abc123`.
9. The add-in task pane renders the user's saved preferences.

### Scenario 2 — First-time user: settings not found, defaults applied

1. A user opens the add-in for the first time. No settings record exists for their OID.
2. The add-in calls `GET /settings`. `IUserSettingsRepository.GetAsync(userId)` returns `null`.
3. The handler returns a default `UserSettings` object (`NotificationsEnabled: true`, `TriageEnabled: false`).
4. The add-in displays the defaults. The user enables triage and saves.
5. The add-in calls `PUT /settings` (or equivalent command endpoint). The handler dispatches `SaveUserSettingsCommand`. `IUserSettingsRepository.SaveAsync(settings)` stores the record. `LastModifiedAt` is set via `TimeProvider`.
6. On the next startup, step 1 of Scenario 1 applies and the saved preferences are returned.

### Scenario 3 — Unauthenticated request rejected

1. An automated scanner or misconfigured client sends `GET /settings` without an `Authorization` header.
2. `CorrelationIdMiddleware` runs and sets `X-Correlation-Id` on the response.
3. `UseAuthentication()` finds no bearer token; the JwtBearer scheme challenges.
4. The API returns `401 Unauthorized`. The response includes `X-Correlation-Id` so the request can be traced in logs.
5. No user data is accessed or returned.

## Acceptance Criteria

- [x] `TaskMaster.Application` project exists; contains command bus abstraction and `IUserSettingsRepository` interface.
- [x] `TaskMaster.Infrastructure` project exists; contains Graph adapter and at least one `IUserSettingsRepository` implementation.
- [x] Bearer token validation is wired in `TaskMaster.Api` via `Microsoft.Identity.Web`.
- [x] Correlation ID middleware propagates `X-Correlation-Id` through all requests.
- [x] `/health` endpoint returns `{"status":"ok"}`.
- [x] `dotnet build` passes with zero warnings and zero analyzer errors.
- [x] All new projects pass `dotnet csharpier check .`, architecture tests, and `dotnet test`.
- [x] `quality-tiers.yml` updated for all new projects.
- [x] Unit tests cover settings CRUD and command routing at >= 85% line / >= 75% branch.
- [x] Auth and Graph token flow covered by integration test or documented manual test plan.
- [x] No `Microsoft.Office.Interop.Outlook` or VSTO references anywhere.

## Non-Goals

The following items are explicitly excluded from this feature:

- **Production database.** Neither a relational database nor a document store is introduced. The MVP implementations are in-memory and JSON-file. A production-grade persistence layer is deferred to a subsequent issue.
- **SMTP or email delivery.** No outbound email capability is added. Notification delivery channels (email, webhooks) are deferred.
- **Outlook desktop automation.** No `Microsoft.Office.Interop.Outlook`, VSTO, or COM-based Office reference is introduced. The backend is add-in-agnostic; it does not interact with the Outlook desktop process.
- **User interface changes.** No changes to the Office task pane UI or add-in manifest are in scope. The API is built to be called by the add-in, but the add-in's UI integration is deferred.
- **OpenAPI document generation via NSwag CLI.** The NSwag net10 launcher gap carried from C1 remains. The OpenAPI JSON file continues to be hand-authored.
- **Multi-tenant or guest-account scenarios.** The MVP targets a single Azure AD tenant. Multi-tenant and B2B guest scenarios are deferred.
- **Classifier state or audit logging.** `TaskMaster.Application` introduces the command bus and settings repository. Classifier state management and audit log infrastructure are separate features.
- **Certificate-based confidential-client credentials.** `ClientSecret` is used for the MVP OBO flow. Certificate-based credentials are a hardening step for a later issue.
