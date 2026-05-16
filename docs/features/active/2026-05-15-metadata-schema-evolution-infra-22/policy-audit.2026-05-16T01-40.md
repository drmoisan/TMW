# Policy Audit — Issue #22: metadata-schema-evolution-infra

- **Timestamp:** 2026-05-16T01-40
- **Branch:** claude/youthful-banzai-a1dff3
- **Base:** origin/main @ 0134bbfcd9a89f9439bb7d8645515d74ecc5b403
- **Auditor:** Feature Review Agent
- **Work Mode:** full-feature

---

## Summary

| Gate | Verdict |
|---|---|
| Formatting (CSharpier) | PASS |
| Lint / Build (dotnet analyzers) | PASS |
| Type check (nullable analysis) | PASS |
| Architecture boundaries | PASS |
| Unit tests | PASS |
| Contract / schema compatibility | PASS |
| Integration tests | PASS (evidence provided) |
| C# line coverage >= 85% | FAIL |
| C# branch coverage >= 75% | FAIL |
| File size limit (<= 500 lines) | PASS |
| Quality-tiers.yml classification | PASS |
| Evidence location compliance | PASS |
| No banned APIs introduced | PASS |
| No COM-visible interfaces | PASS |
| Architecture boundary assertions | PASS |

**Overall verdict: FAIL** — Coverage thresholds not met; remediation required.

---

## Rejected Scope Narrowing

None detected. No caller prompt attempted to narrow the audit scope.

---

## Policy Reading Order (Confirmed)

Per the policy-compliance-order skill, the following rules govern this audit:

1. `CLAUDE.md`
2. `.claude/rules/general-code-change.md`
3. `.claude/rules/general-unit-test.md`
4. `.claude/rules/quality-tiers.md`
5. `.claude/rules/csharp.md`
6. `.claude/rules/architecture-boundaries.md`

---

## Gate Detail

### 1. Formatting (CSharpier) — PASS

Evidence: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/qa-gates/qa-csharpier.md`

- Command: `dotnet csharpier check .`
- EXIT_CODE: 0
- Timestamp: 2026-05-15T21-20
- Verdict: All C# files on the branch pass CSharpier formatting.

### 2. Lint / Build — PASS

Evidence: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/qa-gates/qa-dotnet-build.md`

- Command: `dotnet build TaskMaster.sln --no-incremental`
- EXIT_CODE: 0
- Timestamp: 2026-05-15T21-21
- `TreatWarningsAsErrors=true` is configured via `Directory.Build.props`; a zero exit code confirms zero analyzer diagnostics on the branch.

### 3. Type Check (Nullable Analysis) — PASS

Nullable analysis runs inside `dotnet build`. Build passed with exit code 0. All new C# files (`PayloadSchemaValidator.cs`, `SchemaValidationException.cs`, modified `InMemoryTrainingRepository.cs`, `JsonFileUserSettingsRepository.cs`, `Program.cs` in schema-diff) use `<Nullable>enable</Nullable>` and nullable annotations throughout. No unguarded nullable dereferences observed in code review.

### 4. Architecture Boundary Tests — PASS

Evidence: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/qa-gates/qa-architecture-tests.md` and `architecture-tests-verification.md`

- Command: `dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj --no-build`
- EXIT_CODE: 0 (both artifacts)
- No COM-visible interfaces, VSTO references, or Interop.Outlook references are introduced. `PayloadSchemaValidator` is placed in `TaskMaster.Infrastructure.Validation`, which is within the infrastructure adapter layer. `SchemaValidationException` is also in `TaskMaster.Infrastructure.Validation`. No domain-layer code references infrastructure directly.

### 5. Unit Tests — PASS

Evidence: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/qa-gates/qa-dotnet-test-coverage.md`

- Command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build`
- EXIT_CODE: 0
- 84 tests total; 0 failed. 16 new schema tests pass.

Schema-diff smoke tests:
- `schema-diff-smoke-no-change.md`: EXIT_CODE 0 for identical schema (correct).
- `schema-diff-smoke-breaking-detected.md`: EXIT_CODE 1 for breaking change (correct).
- `schema-tests-initial-run.md`: EXIT_CODE 0 for the full schema test project.

### 6. Contract / Schema Compatibility — PASS

Evidence: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/qa-gates/qa-schema-diff-no-break.md`

- The schema-contract composite action exists at `.github/actions/schema-contract/action.yml`.
- Smoke tests confirm the `schema-diff` tool correctly identifies breaking vs. non-breaking changes.
- Stage 6 in `pr-pipeline.yml` invokes both `.github/actions/contract` and `.github/actions/schema-contract`.

### 7. Integration Tests — PASS (evidence provided)

Stage 7 integration tests are handled by the existing pipeline action `.github/actions/integration`. No changes are made to integration test infrastructure. The schema test project exercised against real schema files from disk constitutes functional integration verification for this feature.

---

## Coverage Verification (C# — Changed Files)

### Coverage Artifact Assessment

The canonical coverage artifact for C# is `artifacts/csharp/coverage.xml`. This file does **not exist** in the repository. Coverage figures are available only via the evidence document `evidence/qa-gates/qa-dotnet-test-coverage.md`, which records per-project coverage from the `dotnet test` output.

**Coverage artifact path `artifacts/csharp/coverage.xml`: ABSENT.**

Per coverage verification procedure, an absent artifact for a language with changed files is a **FAIL** finding. However, the evidence document records per-project line and branch rates from a successful `dotnet test` run, which is used as secondary evidence. The absence of the canonical coverage artifact is noted as a process gap.

### Coverage Results (from evidence document)

Post-feature coverage (from `qa-dotnet-test-coverage.md`, timestamp 2026-05-15T21-22, 84 tests):

| Project | Line Rate | Branch Rate | Status |
|---|---|---|---|
| TaskMaster.Api.Tests | 27.46% | 7.66% | FAIL |
| TaskMaster.Application.Tests | 22.70% | 22.22% | FAIL |
| TaskMaster.ArchitectureTests | 0% | 0% | N/A (no production code under test) |
| TaskMaster.Classifier.Tests | 59.42% | 83.33% | FAIL (line) |
| TaskMaster.Infrastructure.Tests | 56.97% | 36.11% | FAIL |
| TaskMaster.PlaceholderGolden.Tests | 0% | 0% | N/A (no production code under test) |
| TaskMaster.Schema.Tests | 16.73% | 33.33% | FAIL |

### Pre-Existing Condition

The evidence document explicitly states: "Coverage thresholds are below the 85%/75% policy minimums — this is a pre-existing condition present in the baseline before this feature was added." The baseline evidence (`baseline-dotnet-test.md`, 2026-05-15T21-01) confirms the same projects were below threshold before this feature.

### Regression Assessment for Changed Files

Changed production files in this branch:

| File | New or Modified | Coverage Assessment |
|---|---|---|
| `src/TaskMaster.Infrastructure/Validation/PayloadSchemaValidator.cs` | New | Exercised by `UserSettingsSchemaTests.Validate_ThrowsSchemaValidationException_WhenRequiredFieldMissing` and `TrainingFeedbackSchemaTests.Validate_ThrowsSchemaValidationException_WhenPayloadMissingMessageId`; the happy path is covered by indirect calls from write-path tests. |
| `src/TaskMaster.Infrastructure/Validation/SchemaValidationException.cs` | New | Four constructors; the two-argument domain constructor is directly exercised. Parameterless, string, and string+inner constructors are exercised only by xUnit serialization paths (not explicitly). |
| `src/TaskMaster.Infrastructure/InMemoryTrainingRepository.cs` | Modified | `RecordAsync` with schema validation exercised by `TrainingFeedbackSchemaTests`. |
| `src/TaskMaster.Infrastructure/JsonFileUserSettingsRepository.cs` | Modified | `SaveAsync` with schema validation exercised by `UserSettingsSchemaTests`. |
| `tools/schema-diff/Program.cs` | New | Exercised via smoke tests in evidence; not exercised by the Schema.Tests project's unit tests. |

**Infrastructure.Tests project line coverage is 56.97% / branch 36.11% — both below threshold.** This project covers `TaskMaster.Infrastructure` production code. The coverage did not regress relative to baseline (56.89% / 54.54% baseline — note branch actually regressed from 54.54% to 36.11%).

**FAIL: Infrastructure.Tests branch coverage regressed from 54.54% to 36.11%.** This is a direct regression on a project whose production files were modified in this branch.

### Coverage Summary for Policy Audit

- **Repo-wide line coverage:** Below 85% threshold — FAIL (pre-existing; no regression introduced).
- **Repo-wide branch coverage:** Below 75% threshold — FAIL (pre-existing; branch regression noted for Infrastructure.Tests).
- **New file coverage (PayloadSchemaValidator, SchemaValidationException):** Below 85% line coverage — FAIL.
- **Coverage artifact `artifacts/csharp/coverage.xml`:** Absent — FAIL (process gap).

---

## File Size Limit — PASS

All new production and test files inspected:

| File | Lines | Status |
|---|---|---|
| `tools/schema-diff/Program.cs` | 165 | PASS |
| `src/TaskMaster.Infrastructure/Validation/PayloadSchemaValidator.cs` | 68 | PASS |
| `src/TaskMaster.Infrastructure/Validation/SchemaValidationException.cs` | 52 | PASS |
| `tests/TaskMaster.Schema.Tests/UserSettingsSchemaTests.cs` | 97 | PASS |
| `tests/TaskMaster.Schema.Tests/TrainingFeedbackSchemaTests.cs` | 95 | PASS |
| `tests/TaskMaster.Schema.Tests/SchemaCompatibilityTests.cs` | 73 | PASS |
| `tests/TaskMaster.Schema.Tests/ClassificationResultSchemaTests.cs` | 69 | PASS |

No file exceeds 500 lines.

---

## Quality-Tiers Classification — PASS

Evidence: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/qa-gates/qa-quality-tiers-validation.md`

- Command: `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1`
- EXIT_CODE: 0
- Timestamp: 2026-05-15T21-23

New entries in `quality-tiers.yml`:
- `TaskMaster.Schema.Tests`: `t4` — correct (test scaffolding).
- `schema-diff`: `t4` — correct (CI tooling, not production).

---

## Evidence Location Compliance — PASS

Evidence artifacts for this feature are written under `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/evidence/`, which is the canonical `<FEATURE>/evidence/<kind>/` path. No artifacts were found under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, or `artifacts/evidence/`.

The `validate_evidence_locations.py` script is not present in the repository; manual inspection of the `artifacts/` directory confirms it contains only `openapi/current.json`, `orchestration/orchestrator-state.json`, `pr_context.appendix.txt`, `pr_context.summary.txt`, and `research/2026-05-15-metadata-schema-evolution-infra-22.md` — none of which are evidence artifacts that belong under the canonical feature evidence path.

---

## Banned APIs — PASS

No use of `DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, or `Task.Delay` was observed in new or modified production code. `PayloadSchemaValidator.cs` uses `File.ReadAllText` (acceptable in infrastructure; isolated from domain logic). `InMemoryTrainingRepository.cs` uses the injected `_timeProvider.GetUtcNow()` — compliant.

---

## Dependency Addition — PASS

`JsonSchema.Net` Version 7.3.1 added to `Directory.Packages.props`. Version is pinned. Justification is documented in `spec.md` (constraint C1) and in the `Directory.Packages.props` comment. The version selection (7.3.1 rather than 9.x) is specifically justified to avoid a transitive `Humanizer.Core` conflict. The package is MIT-licensed.

---

## FAIL Findings Summary

| # | Finding | Severity |
|---|---|---|
| F1 | C# branch coverage regressed in TaskMaster.Infrastructure.Tests from 54.54% to 36.11% | FAIL |
| F2 | Repo-wide line coverage below 85% threshold across multiple projects | FAIL (pre-existing) |
| F3 | Repo-wide branch coverage below 75% threshold across multiple projects | FAIL (pre-existing) |
| F4 | New files (PayloadSchemaValidator, SchemaValidationException, tools/schema-diff/Program.cs) do not achieve 85% line coverage | FAIL |
| F5 | Canonical coverage artifact `artifacts/csharp/coverage.xml` is absent | FAIL (process gap) |
