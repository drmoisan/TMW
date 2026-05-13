# Remediation Inputs — Issue #12: Add Backend API Foundation

- **Artifact type:** remediation-inputs
- **Timestamp:** 2026-05-12T10-46
- **Feature folder:** docs/features/active/2026-05-11-add-backend-api-foundation-12/
- **Branch:** feature/add-backend-api-foundation-12
- **Reviewer:** Feature Review Agent (claude-sonnet-4-6)

---

## Remediation Trigger Summary

| ID | Severity | Gate Failed | Description |
|---|---|---|---|
| REM-1 | PARTIAL (blocking for AC-3 completion) | Integration Tests / Feature Audit AC-3 | No integration test verifies `HTTP 401 Unauthorized` on a protected endpoint without a bearer token. |

No FAIL-level findings were identified. One PARTIAL finding is described below.

---

## REM-1 — Missing `HTTP 401` Integration Test

### Classification

- **Severity:** PARTIAL
- **AC affected:** AC-3 ("Bearer token validation is wired in `TaskMaster.Api` via `Microsoft.Identity.Web`")
- **Spec reference:** `spec.md` § Definition of Done, row 3: "Integration test in `TaskMaster.Api.Tests`: no bearer token → HTTP 401."
- **Policy reference:** `.claude/rules/general-unit-test.md` — Scenario Completeness; negative flows for invalid or missing inputs required.

### Description

`AuthIntegrationTests.cs` contains three integration tests, none of which verifies the `HTTP 401 Unauthorized` rejection path. The test named `UnauthenticatedRequest_ToProtectedEndpoint_Returns200OnAnonymousHealthEndpoint` tests the public `/health` endpoint (which always returns `200 OK`), not a protected endpoint.

The `CustomWebApplicationFactory` replaces the real Azure AD authentication stack with `TestAuthHandler` for all tests. This means the test host always succeeds at authentication — there is no configuration in the current test suite that allows an unauthenticated request to reach a protected resource and receive a `401`.

### Root Cause

The MVP does not introduce any protected endpoints (all routes other than `/health` are "TBD in subsequent issues" per `spec.md` § Endpoints). Without a protected endpoint, a `401` integration test cannot be written against the test host in a straightforward way.

There are two paths to remediation:

**Path A (Recommended — deferred to next issue):** When the next protected endpoint is introduced (e.g., `GET /settings`), add an integration test in `TaskMaster.Api.Tests` that:
1. Uses a `WebApplicationFactory` that does NOT register `TestAuthHandler` (i.e., restores the real `MicrosoftIdentityWebApi` authentication stack, or uses a `WebApplicationFactory` overriding only the Azure AD authority URL to a WireMock stub).
2. Sends a request to the protected endpoint without an `Authorization` header.
3. Asserts `HttpStatusCode.Unauthorized` (401).

**Path B (Current branch, before merge):** Add a minimal protected endpoint (e.g., `GET /ping` with `[Authorize]`) for the sole purpose of enabling this test. Remove or repurpose the endpoint in the next issue once a real protected endpoint exists. This avoids deferring the test but introduces a placeholder endpoint.

### Recommended Action

The reviewer recommends **Path A** — defer the `401` test to the next issue that introduces a protected endpoint. The authentication middleware is correctly wired and confirmed by code review. The spec's "Integration test or documented manual test plan" option for AC-10 (Graph flow) was accepted; a similar "deferred to next issue" acknowledgment should be recorded for AC-3.

**Explicit remediation-required condition:** AC-3 must be verified by an integration test demonstrating `HTTP 401 Unauthorized` before the feature can be marked fully complete. This test must be written no later than the first PR that introduces a protected endpoint.

### Artifact Paths

- Policy audit: `docs/features/active/2026-05-11-add-backend-api-foundation-12/policy-audit.2026-05-12T10-46.md`
- Code review: `docs/features/active/2026-05-11-add-backend-api-foundation-12/code-review.2026-05-12T10-46.md`
- Feature audit: `docs/features/active/2026-05-11-add-backend-api-foundation-12/feature-audit.2026-05-12T10-46.md`

### AC-3 Check-Off Condition

AC-3 in `user-story.md` and `issue.md` should remain `[ ]` (unchecked) until:

1. A protected endpoint is introduced in the solution.
2. An integration test is added in `TaskMaster.Api.Tests` that sends a request to that endpoint without a bearer token and asserts `HTTP 401 Unauthorized`.
3. The test passes in CI.

---

## Non-Blocking Observations (Informational)

The following items were noted during review but do not require remediation before merge. They are recorded for the next engineer's awareness.

### OBS-1 — `Guid.NewGuid()` in `CorrelationIdMiddleware` not injectable

`CorrelationIdMiddleware.cs` line 30 calls `Guid.NewGuid()` directly. This is not a banned API and the middleware tests pass. If future tests need to assert specific correlation ID values on responses, an `IGuidProvider` or `Func<Guid>` seam would be needed.

### OBS-2 — `IGraphClientFactory` references `GraphServiceClient` in Application layer

`TaskMaster.Application.csproj` references `Microsoft.Graph` to support `IGraphClientFactory.CreateClient()` returning `GraphServiceClient`. This is documented as an approved pragmatic exception in the csproj and the plan. The architecture tests confirm the auth stack (`Microsoft.Identity`) is not pulled in. No action required.

### OBS-3 — `InfrastructureServiceCollectionExtensions` hardcodes `TimeProvider.System`

The `InMemoryUserSettingsRepository` singleton is registered with `TimeProvider.System` rather than resolving `TimeProvider` from DI. For the current MVP this is acceptable. If integration tests ever need clock control over the in-memory repository via the full app factory, the registration will need to change to `services.AddSingleton<IUserSettingsRepository>(sp => new InMemoryUserSettingsRepository(sp.GetRequiredService<TimeProvider>()))`.
