# add-backend-api-foundation (Issue #12)

- Date captured: 2026-05-11
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/add-backend-api-foundation/ (Issue #12)

- Issue: #12
- Issue URL: https://github.com/drmoisan/TMW/issues/12
- Last Updated: 2026-05-12
- Work Mode: full-feature

## Problem / Why

The C1 .NET foundation (Issue #7) established the solution skeleton, CI gates, and an unauthenticated health-only API. There is no backend service that owns user settings, classifier state, Graph access, or audit logging. The add-in cannot persist user preferences, route commands, or reach Microsoft Graph without this foundation.

## Proposed Behavior

Extend `TaskMaster.Api` and introduce `TaskMaster.Application` and `TaskMaster.Infrastructure` projects to deliver:

- Authenticated API (JWT/MSAL bearer token validation).
- Graph access path (a `IGraphClientFactory` adapter wrapping the Microsoft Graph SDK).
- User settings storage (an `IUserSettingsRepository` with an in-memory and a JSON-file implementation).
- Correlation ID middleware (propagates `X-Correlation-Id` request header through all log entries).
- Health endpoint (already exists; expand to include dependency probes).
- No dependency on desktop Outlook automation anywhere in the new code.
- Unit tests for settings operations and command routing.
- Integration test or documented manual test for authentication and Graph token flow.

## Acceptance Criteria (early draft)

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

## Constraints & Risks

- Must not introduce COM or Outlook desktop automation dependencies.
- NSwag net10 launcher gap (from C1) still applies; OpenAPI JSON remains hand-authored until upstream fix lands.
- Microsoft.Identity.Web and Graph SDK versions must be pinned in `Directory.Packages.props`.
- Coverage thresholds are uniform: line >= 85%, branch >= 75% across all tiers.

## Test Conditions to Consider

- [ ] Unit: `IUserSettingsRepository` in-memory implementation CRUD operations.
- [ ] Unit: command bus dispatches to correct handler.
- [ ] Unit: correlation ID middleware sets header on requests without existing header; preserves header when present.
- [ ] Integration: bearer token validation rejects unauthenticated requests (401).
- [ ] Integration or documented manual: Graph token acquisition flow.

## Next Step

- [x] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/add-backend-api-foundation/` folder from the template