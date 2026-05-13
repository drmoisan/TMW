---
name: project-tmw-context
description: TMW repo — C# No-COM .NET 10 backend, Issue #12 delivered Application+Infrastructure+Auth layers
metadata:
  type: project
---

TMW (TaskMaster) is a C# + TypeScript Office add-in project targeting .NET 10. The .NET backend uses xUnit, NSubstitute, FluentAssertions, CsCheck (property tests), CSharpier, and a full Roslyn analyzer stack. Coverage thresholds are uniform at line >=85% / branch >=75% across all tiers (T1-T4) per Authoritative Decision #2.

Issue #7 established the .NET skeleton. Issue #12 (feature/add-backend-api-foundation-12) delivered:
- `TaskMaster.Application` (T2): command bus, IUserSettingsRepository, IGraphClientFactory
- `TaskMaster.Infrastructure` (T3): InMemoryUserSettingsRepository, JsonFileUserSettingsRepository, GraphClientFactory, IFileWriter seam
- `TaskMaster.Api` extended: CorrelationIdMiddleware, Microsoft.Identity.Web bearer auth, DI wiring
- 32 tests passing, 0 failures

**Why:** No protected endpoints exist yet (MVP); the HTTP 401 integration test for auth rejection is deferred to the next issue introducing a protected endpoint (AC-3 PARTIAL).

**How to apply:** When reviewing subsequent issues, expect the 401 test gap to be closed in the first PR that introduces a protected endpoint.
