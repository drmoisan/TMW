# Policy Audit — Issue #12: Add Backend API Foundation

- **Artifact type:** policy-audit
- **Timestamp:** 2026-05-12T10-46
- **Feature folder:** docs/features/active/2026-05-11-add-backend-api-foundation-12/
- **Branch:** feature/add-backend-api-foundation-12
- **Merge base:** d166efc803e0c3c849770a90360726486f941050
- **Reviewer:** Feature Review Agent (claude-sonnet-4-6)
- **Scope:** Full branch diff — 66 files changed, 2624 insertions, 6 deletions

---

## Rejected Scope Narrowing

None detected. No caller instruction attempted to narrow scope for this review.

---

## Policy Reading Order Applied

1. `CLAUDE.md` (standing instructions)
2. `.claude/rules/general-code-change.md` (cross-language code change policy)
3. `.claude/rules/general-unit-test.md` (cross-language unit test policy)
4. `.claude/rules/csharp.md` (C# code standards)
5. `.claude/rules/architecture-boundaries.md` (architecture boundary enforcement)
6. `.claude/rules/quality-tiers.md` (module rigor tiers)

All policy documents were read from the branch at HEAD. No policy documents were modified.

---

## Gate 1 — Formatting (CSharpier)

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t1-csharpier-final.md`

- Command: `dotnet tool restore && dotnet csharpier check .`
- EXIT_CODE: 0
- Result: 45 files checked, 0 unformatted files.

---

## Gate 2 — Linting / Build (dotnet build with TreatWarningsAsErrors)

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t2-build-final.md`

- Command: `dotnet build TaskMaster.sln`
- EXIT_CODE: 0
- 8 projects built: TaskMaster.Domain, TaskMaster.Application, TaskMaster.Infrastructure, TaskMaster.Api, TaskMaster.Application.Tests, TaskMaster.Infrastructure.Tests, TaskMaster.ArchitectureTests, TaskMaster.Api.Tests.
- Warning count: 0. Error count: 0. `TreatWarningsAsErrors=true` enforced.

---

## Gate 3 — Type Checking (Nullable Analysis)

**Verdict: PASS**

Nullable reference types are enforced solution-wide via `Directory.Build.props` (`Nullable=enable`, `TreatWarningsAsErrors=true`). The `dotnet build` evidence (EXIT_CODE: 0, 0 warnings) confirms zero nullable violations.

All new source files reviewed use nullable annotations correctly:
- `IUserSettingsRepository.GetAsync` returns `Task<UserSettings?>` with correct nullability annotation.
- `UserSettings` is a non-nullable record; all parameters are non-nullable by declaration.
- `CorrelationIdMiddleware` guards against null `context` and `next` parameters via `ArgumentNullException.ThrowIfNull`.

---

## Gate 4 — Architecture Boundary Tests

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t4-architecture-final.md`

- Command: `dotnet test tests/TaskMaster.ArchitectureTests --settings tests/TaskMaster.ArchitectureTests/test.runsettings`
- EXIT_CODE: 0
- 6 tests passed, 0 failed.

Assertions verified:
1. `LayerBoundaryTests.ApplicationProjectDoesNotDependOnInfrastructure` — PASS
2. `LayerBoundaryTests.ApplicationProjectDoesNotDependOnMicrosoftIdentityWeb` — PASS
3. `LayerBoundaryTests.DomainProjectDoesNotDependOnApplicationOrInfrastructure` — PASS
4. `NoComArchitectureTests.NoProjectDependsOnOutlookInterop` — PASS
5. `NoComArchitectureTests.NoProjectDependsOnForbiddenLegacyNamespaces` — PASS
6. `NoComArchitectureTests.DomainProjectDoesNotDependOnInfrastructure` — PASS

No-COM architecture rules from `.claude/rules/architecture-boundaries.md`: all enforced and passing.

---

## Gate 5 — Unit Tests

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t3-test-coverage-final.md`

- Command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --settings test.runsettings`
- EXIT_CODE: 0
- Total: 32 tests passed, 0 failed.
  - TaskMaster.Application.Tests: 9 passed
  - TaskMaster.Infrastructure.Tests: 4 passed
  - TaskMaster.Api.Tests: 13 passed
  - TaskMaster.ArchitectureTests: 6 passed

---

## Gate 6 — Contract / Schema Compatibility

**Verdict: PASS (with note)**

No new public API contracts are introduced in this feature. The only external-facing interface is the `/health` endpoint (existing shape `{"status":"ok"}`) and the `X-Correlation-Id` header behavior. The existing `HealthEndpointTests` verify the contract. No `oasdiff` check is required as no OpenAPI document changed (NSwag net10 launcher gap is a documented carry-forward constraint).

---

## Gate 7 — Integration Tests

**Verdict: PARTIAL**

`CustomWebApplicationFactory` + `TestAuthHandler` integration tests run in `TaskMaster.Api.Tests`. These cover:
- Anonymous `/health` endpoint returns `200 OK`.
- Authenticated request (via `TestAuthHandler`) returns `200 OK` on `/health`.
- `X-Correlation-Id` header is present on all responses.

**Gap:** No integration test verifies that a request to a protected endpoint without a valid bearer token returns `HTTP 401 Unauthorized`. The spec (§ Behavior item 1) and AC item 3 require this behavior. The `CustomWebApplicationFactory` replaces the real authentication stack with `TestAuthHandler` in all tests, meaning there is no test path in which `UseAuthentication()` rejects an unauthenticated request. All current tests use the anonymous `/health` endpoint.

This gap is partially mitigated by the architecture (the bearer token middleware is registered correctly in `Program.cs`, and the `BannedApiAnalyzers` and analyzer stack would flag drift). However, the spec's "Definition of Done" explicitly states: "Integration test in TaskMaster.Api.Tests: no bearer token → HTTP 401."

**Finding:** INTEGRATION-TEST-401-MISSING — No test demonstrates `401 Unauthorized` on a protected endpoint. See remediation inputs.

---

## Coverage Verification — C# (Changed Files)

**Coverage artifact path:** `artifacts/csharp/coverage.xml`
**Artifact present:** No — no merged coverage XML artifact at the canonical path.

Coverage data is available via the plan's QA gate evidence artifacts at
`docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t3-test-coverage-final.md` and `p6-t5-coverage-delta.md`. These are feature-canonical paths and contain the required coverage breakdown.

Per the coverage verification procedure: coverage data is evaluated from pre-existing artifacts rather than re-running coverage. The QA gate evidence constitutes the available coverage record for this audit.

**Coverage results from QA gate evidence:**

| Project | Line Coverage | Branch Coverage | Threshold (line/branch) | Verdict |
|---|---|---|---|---|
| TaskMaster.Api | 100% | 100% | >=85% / >=75% | PASS |
| TaskMaster.Application | 100% | 100% | >=85% / >=75% | PASS |
| TaskMaster.Infrastructure | ~93% | ~100% | >=85% / >=75% | PASS |

**FileWriter exemption note:** `FileWriter.cs` (4 lines) is a pure I/O delegation adapter wrapping `System.IO.File` static methods with no branching logic. Testing it requires real filesystem operations, which violates the "no temporary files in tests" prohibition in `general-unit-test.md`. The 0% coverage on this class is justified and documented. All callers of `IFileWriter` are fully covered via `NSubstitute` stubs.

Excluding `FileWriter`, all authored lines in all three production projects are covered. The ~93% Infrastructure line rate including `FileWriter` still exceeds the 85% threshold.

**Formal coverage artifact absence note:** The canonical `artifacts/csharp/coverage.xml` artifact is absent. Coverage evidence is sourced from the feature's canonical QA gate evidence folder. This is acceptable per the reviewer's evidence discovery procedure, but the absence of a merged coverage XML is noted for CI pipeline completeness tracking.

---

## Banned APIs Check

**Verdict: PASS**

- `DateTime.Now` — not present in any `.cs` file under `src/`.
- `DateTime.UtcNow` — not present in any `.cs` file under `src/`.
- `Random.Shared` — not present in any `.cs` file under `src/`.
- `Thread.Sleep` — not present.
- `Task.Delay` — not present.

`BannedSymbols.txt` is present at repo root and bans all five APIs. `Directory.Build.props` references it as an `<AdditionalFiles>` entry; `dotnet build` EXIT_CODE: 0 confirms no violations.

**Note:** `Guid.NewGuid()` is used in `CorrelationIdMiddleware.cs` line 30. This is not a banned API. However, it makes the correlation ID generation non-injectable and non-deterministic (see code review for the associated quality finding).

**Note:** `DateTimeOffset.UtcNow` appears in `tests/TaskMaster.Infrastructure.Tests/JsonFileUserSettingsRepositoryTests.cs` line 80 as a static test-data value (not a production code call path). `DateTimeOffset.UtcNow` is not listed in `BannedSymbols.txt`. Not a violation.

---

## No-COM Architecture

**Verdict: PASS**

- No references to `Microsoft.Office.Interop.Outlook`, VSTO, or COM-based Office assemblies are present in any source file.
- The only match for "VSTO" in `src/` appears as a comment in `TaskMaster.Application.csproj` explaining why `Microsoft.Graph` is a pragmatic exception (comment text: "with no COM/VSTO/Office dependency").
- Architecture tests `NoComArchitectureTests` pass (evidenced above).

---

## Quality Tiers Compliance

**Verdict: PASS**

`quality-tiers.yml` is updated with four new entries from Issue #12:
- `TaskMaster.Application` → T2 (Core application layer)
- `TaskMaster.Infrastructure` → T3 (Infrastructure adapter layer)
- `TaskMaster.Application.Tests` → T4 (Test scaffolding)
- `TaskMaster.Infrastructure.Tests` → T4 (Test scaffolding)

All entries have `name`, `path`, `language`, and `tier` fields. Tier values are valid (`t2`, `t3`, `t4`). The rationale for `TaskMaster.Application` as T2 aligns with `.claude/rules/quality-tiers.md` (core layer; bugs cause feature regressions).

**T2 property-based testing requirement:** `TaskMaster.Application` is classified T2, which requires at least one property-based test per pure function. The `UserSettingsPropertyTests.cs` provides a CsCheck property test covering `UserSettings` round-trip serialization. `ServiceProviderCommandBus.DispatchAsync` is a side-effecting dispatch operation (not a pure function) and does not require a property test. This satisfies the T2 property test density requirement.

---

## Package Pinning Compliance

**Verdict: PASS**

`Directory.Packages.props` contains:
- `Microsoft.Identity.Web` 4.9.0
- `Microsoft.Identity.Web.GraphServiceClient` 4.9.0
- `Microsoft.Graph` 5.105.0
- `CsCheck` 4.6.2
- `Microsoft.AspNetCore.Mvc.Testing` 10.0.7 (upgraded from 9.0.10)
- `Microsoft.Kiota.Abstractions` 1.22.2 (transitive pin for GHSA-7j59-v9qr-6fq9 vulnerability)

All pinned versions match the spec's requirements. The `Microsoft.Kiota.Abstractions` pin is a security-relevant addition not specified in the original spec but is a legitimate and prudent addition.

---

## Secret Management

**Verdict: PASS**

- `appsettings.json` contains empty `AzureAd` section fields (`Instance`, `TenantId`, `ClientId`, `Audience`). No `ClientSecret` value is present.
- No secrets are committed anywhere in the diff.
- The graph token flow manual test plan correctly documents that `AzureAd__ClientSecret` must be supplied via environment variable or Key Vault reference only.

---

## Evidence Location Compliance

**Verdict: PASS**

Scan of branch diff for files under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, or `artifacts/coverage/`:
- No files in the diff match these forbidden paths.
- All evidence artifacts in the diff are under `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/` (canonical location).

The `validate_evidence_locations.py` script was not found in the repository (no such file exists). The `enforce-evidence-locations.ps1` hook exists at `.claude/hooks/enforce-evidence-locations.ps1`. Manual scan of changed files confirms compliance.

---

## File Size Compliance

**Verdict: PASS**

No production code, test code, or reusable script file exceeds 500 lines. The largest file in the diff is `plan.2026-05-12T10-38.md` (339 lines), which is a Markdown documentation file (exempt). All `.cs` files are well under 500 lines; the largest is `JsonFileUserSettingsRepository.cs` (124 lines).

---

## Summary Table

| Gate | Verdict | Notes |
|---|---|---|
| Formatting (CSharpier) | PASS | 45 files, 0 unformatted |
| Linting / Build | PASS | 0 warnings, 0 errors |
| Type checking (Nullable) | PASS | `TreatWarningsAsErrors=true` confirmed |
| Architecture boundaries | PASS | 6 architecture tests pass |
| Unit tests | PASS | 32/32 pass |
| Contract / schema | PASS | No contract changes |
| Integration tests | PARTIAL | 401 test gap (see remediation) |
| C# coverage (line) | PASS | Api: 100%, App: 100%, Infra: ~93% |
| C# coverage (branch) | PASS | All ≥75% |
| Banned APIs | PASS | No violations |
| No-COM architecture | PASS | Architecture tests confirm |
| Quality tiers | PASS | 4 new entries, correctly classified |
| Package pinning | PASS | All versions per spec |
| Secret management | PASS | No secrets committed |
| Evidence locations | PASS | All artifacts in canonical paths |
| File size | PASS | No file exceeds 500 lines |

**Overall policy verdict: PARTIAL** — one blocking finding (missing 401 integration test). All other gates pass.
