# Policy Audit — Issue #12: Add Backend API Foundation

- **Artifact type:** policy-audit
- **Timestamp:** 2026-05-12T10-58
- **Feature folder:** docs/features/active/2026-05-11-add-backend-api-foundation-12/
- **Branch:** feature/add-backend-api-foundation-12
- **Merge base:** d166efc803e0c3c849770a90360726486f941050
- **Head:** 9bbe21172c269e40c5df9b166e5cb4c116e17bc1
- **Reviewer:** Feature Review Agent (claude-sonnet-4-6)
- **Re-audit scope:** Full branch diff against main; targeted remediation of REM-1 (AC-3 401 integration test) was applied after the prior review (T10-46).

---

## Rejected Scope Narrowing

None detected. The caller prompt did not attempt to narrow audit scope to a phase, task subset, or language category. Full branch diff is used.

---

## Policy Reading Order Confirmed

Policies read and applied in required order:

1. `CLAUDE.md` (standing instructions)
2. `.claude/rules/general-code-change.md` (cross-language code change policy)
3. `.claude/rules/general-unit-test.md` (cross-language unit test policy)
4. `.claude/rules/csharp.md` (C#-specific standards)
5. `.claude/rules/architecture-boundaries.md` (architecture boundary enforcement)
6. `.claude/rules/quality-tiers.md` (module rigor tier definitions)

---

## Branch Diff Summary

75 files changed (+3593 / -6) across 2 commits:
- `feat(backend-api)`: Application, Infrastructure, auth wiring (commit 50f8090)
- `test(backend-api)`: 401 integration test for AC-3 remediation (commit 9bbe211)

Languages with changed files: **C#** (32 .cs files), **YAML** (1 .yml), **JSON** (1 .json), **XML** (.csproj, .props, .runsettings, .sln), **Markdown** (25 .md files).

Changed C# production files (new unless noted):
- `src/TaskMaster.Api/CorrelationIdMiddleware.cs` (new)
- `src/TaskMaster.Api/Program.cs` (modified)
- `src/TaskMaster.Application/` — 7 new files
- `src/TaskMaster.Infrastructure/` — 7 new files
- `tests/TaskMaster.Api.Tests/` — 6 new, 2 modified
- `tests/TaskMaster.Application.Tests/` — 6 new
- `tests/TaskMaster.Infrastructure.Tests/` — 3 new
- `tests/TaskMaster.ArchitectureTests/LayerBoundaryTests.cs` (new)

---

## Gate 1 — Formatting (CSharpier)

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t1-csharpier-final.md`

- Command: `dotnet tool restore && dotnet csharpier check .`
- EXIT_CODE: 0
- Output: 45 files checked, 0 unformatted files.

AC-3 remediation run: `dotnet csharpier check .` — EXIT_CODE 0, 47 files checked (2 new files from remediation commit), 0 unformatted. Evidence: `evidence/qa-gates/ac3-toolchain-2026-05-12T10-55.md`.

---

## Gate 2 — Build / Linting / Nullable Analysis

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t2-build-final.md`

- Command: `dotnet build TaskMaster.sln`
- EXIT_CODE: 0
- 8 projects built, 0 warnings, 0 errors.
- `TreatWarningsAsErrors=true` enforced via `Directory.Build.props`.

AC-3 remediation build: EXIT_CODE 0, 0 warnings, 0 errors. Evidence: `ac3-toolchain-2026-05-12T10-55.md`.

---

## Gate 3 — Architecture Tests

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t4-architecture-final.md`

- Command: `dotnet test tests/TaskMaster.ArchitectureTests`
- EXIT_CODE: 0
- 6 tests passed, 0 failed.

Passing facts:
1. `ApplicationProjectDoesNotDependOnInfrastructure` — PASS
2. `ApplicationProjectDoesNotDependOnMicrosoftIdentityWeb` — PASS
3. `DomainProjectDoesNotDependOnApplicationOrInfrastructure` — PASS
4. `NoComArchitectureTests.NoProjectDependsOnOutlookInterop` — PASS
5. `NoComArchitectureTests.NoProjectDependsOnForbiddenLegacyNamespaces` — PASS
6. `NoComArchitectureTests.DomainProjectDoesNotDependOnInfrastructure` — PASS

No architecture violations detected.

Note on `IGraphClientFactory` referencing `Microsoft.Graph` in Application layer: This is an approved pragmatic exception, documented inline in `TaskMaster.Application.csproj`. The architecture test confirms `Microsoft.Identity` is not pulled into Application. The `NotHaveDependencyOn("Microsoft.Identity")` assertion passes; the `Microsoft.Graph` SDK reference does not carry the auth stack.

---

## Gate 4 — Unit Tests

**Verdict: PASS**

Evidence: `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/qa-gates/p6-t3-test-coverage-final.md` and `evidence/qa-gates/ac3-toolchain-2026-05-12T10-55.md`.

Post-AC-3-remediation test totals:
- `TaskMaster.Application.Tests`: 9 passed
- `TaskMaster.ArchitectureTests`: 6 passed
- `TaskMaster.Infrastructure.Tests`: 4 passed
- `TaskMaster.Api.Tests`: 14 passed (13 pre-remediation + 1 new `GetPing_WithoutAuthorizationHeader_Returns401Unauthorized`)
- **Total: 33 passed, 0 failed, 0 skipped**

Command: `dotnet test --collect:"XPlat Code Coverage"` — EXIT_CODE: 0.

---

## Gate 5 — Coverage (C# — Mandatory)

**Verdict: PASS**

Coverage artifact (`coverage/lcov.info`): absent. Coverage was reported by Coverlet per test project as documented in `evidence/qa-gates/p6-t3-test-coverage-final.md` and `evidence/qa-gates/p6-t5-coverage-delta.md`. The canonical LCOV artifact was not merged; coverage values are derived from the per-project Coverlet reports recorded in those evidence files.

Policy thresholds (uniform T1–T4): line >= 85%, branch >= 75%.

| Project | Line Rate | Branch Rate | Threshold | Verdict |
|---|---|---|---|---|
| TaskMaster.Api | 100% | 100% | line>=85%, branch>=75% | PASS |
| TaskMaster.Application | 100% | 100% | line>=85%, branch>=75% | PASS |
| TaskMaster.Infrastructure | ~93% (FileWriter exempt) | ~100% | line>=85%, branch>=75% | PASS |

**FileWriter exemption:** `FileWriter.cs` wraps `System.IO.File` static methods with zero branching logic. The test policy (`.claude/rules/general-unit-test.md`) prohibits temporary file creation in tests. All callers of `IFileWriter` are covered at 100% via NSubstitute stubs. The overall Infrastructure line rate excluding FileWriter's 4 lines remains ~93%, above the 85% threshold. This is a documented limitation, not a FAIL finding.

Coverage delta vs baseline: pre-feature `TaskMaster.Api` line rate was 3.79% (OpenAPI-generated code included). Post-feature rate is 100% with generated code excluded via `test.runsettings`. `TaskMaster.Application` and `TaskMaster.Infrastructure` are new projects with no baseline. No regression.

---

## Gate 6 — Property-Based Tests (T2 policy)

**Verdict: PASS**

`TaskMaster.Application` is classified T2 in `quality-tiers.yml`. T2 policy requires at least one property-based test per pure function.

`tests/TaskMaster.Application.Tests/UserSettingsPropertyTests.cs` contains one CsCheck property test: `UserSettings_RoundTripSerialization_PreservesAllFields`, exercising `UserSettings` serialization round-trip with generated inputs. This satisfies the T2 minimum.

`CsCheck` 4.6.2 is pinned in `Directory.Packages.props`.

---

## Gate 7 — No Banned APIs

**Verdict: PASS**

`DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, and `Task.Delay` are banned per `.claude/rules/csharp.md`. Enforcement via `Microsoft.CodeAnalysis.BannedApiAnalyzers` with `BannedSymbols.txt`.

Clock usage in all production code uses `TimeProvider.GetUtcNow()` (injected `TimeProvider`). Test code uses `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing`. Evidence: `dotnet build` EXIT_CODE 0 with `TreatWarningsAsErrors=true` — no banned-API violations reported.

One anomaly: `JsonFileUserSettingsRepositoryTests.cs` line 82 uses `DateTimeOffset.UtcNow` in test arrange code for a stub input (`existingSettings`). `DateTimeOffset.UtcNow` is not in the banned list (only `DateTime.UtcNow` is banned). No violation.

---

## Gate 8 — File Size Limit (500 lines)

**Verdict: PASS**

All new production files reviewed are well below 500 lines. Largest production file observed: `JsonFileUserSettingsRepository.cs` at 124 lines. Test files likewise below limit. No file exceeds the policy ceiling.

---

## Gate 9 — No COM / VSTO References

**Verdict: PASS**

Architecture tests `NoProjectDependsOnOutlookInterop` and `NoProjectDependsOnForbiddenLegacyNamespaces` both pass (evidence: `p6-t4-architecture-final.md`). No `Microsoft.Office.Interop.Outlook`, VSTO, or COM-visible attribute references were found in the branch diff.

---

## Gate 10 — Secrets in Source

**Verdict: PASS**

`appsettings.json` contains placeholder empty strings for `AzureAd:Instance`, `TenantId`, `ClientId`, `Audience`. `AzureAd:ClientSecret` is not present in any committed file. The spec and manual test plan explicitly note that `ClientSecret` must be supplied via environment variable only. No secrets detected in the branch diff.

---

## Gate 11 — quality-tiers.yml Completeness

**Verdict: PASS**

`quality-tiers.yml` registers all projects introduced in this branch:

| Project | Tier | Source |
|---|---|---|
| TaskMaster.Application | T2 | quality-tiers.yml line 54 |
| TaskMaster.Infrastructure | T3 | quality-tiers.yml line 65 |
| TaskMaster.Application.Tests | T4 | quality-tiers.yml line 74 |
| TaskMaster.Infrastructure.Tests | T4 | quality-tiers.yml line 81 |

All projects previously registered (TaskMaster.Domain T2, TaskMaster.Api T3, TaskMaster.ArchitectureTests T4, TaskMaster.Api.Tests T4, tmw-taskpane-scaffold T4) remain correctly classified.

---

## Gate 12 — Package Pinning

**Verdict: PASS**

`Directory.Packages.props` contains:
- `Microsoft.Identity.Web` 4.9.0
- `Microsoft.Identity.Web.GraphServiceClient` 4.9.0
- `Microsoft.Graph` 5.105.0
- `CsCheck` 4.6.2
- `Microsoft.AspNetCore.Mvc.Testing` upgraded to 10.0.7 (was 9.0.10)
- `Microsoft.Kiota.Abstractions` 1.22.2 (pinned to address GHSA-7j59-v9qr-6fq9 vulnerability — appropriate security hardening)

All required pinning per spec constraints is present.

---

## Evidence Location Compliance

The `validate_evidence_locations.py` script is absent from the repo root. Manual scan performed.

Branch diff was searched for files under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, or `artifacts/coverage/`. Result: zero matches. All evidence artifacts are written under the canonical `docs/features/active/2026-05-11-add-backend-api-foundation-12/evidence/` path. No evidence location violations detected.

---

## Summary

| Gate | Verdict |
|---|---|
| 1 — Formatting (CSharpier) | PASS |
| 2 — Build / Lint / Nullable | PASS |
| 3 — Architecture tests | PASS |
| 4 — Unit tests | PASS |
| 5 — Coverage (C#) | PASS |
| 6 — Property-based tests (T2) | PASS |
| 7 — Banned APIs | PASS |
| 8 — File size limit | PASS |
| 9 — No COM/VSTO | PASS |
| 10 — Secrets in source | PASS |
| 11 — quality-tiers.yml | PASS |
| 12 — Package pinning | PASS |
| Evidence location compliance | PASS |

**Overall policy verdict: PASS.** All policy gates pass. No remediation inputs required.
