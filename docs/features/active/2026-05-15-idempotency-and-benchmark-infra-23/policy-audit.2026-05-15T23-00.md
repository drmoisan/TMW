# Policy Audit — idempotency-and-benchmark-infra (Issue #23)

- Timestamp: 2026-05-15T23-00
- Feature folder: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/`
- Base branch: `main`
- Merge-base: `0134bbfcd9a89f9439bb7d8645515d74ecc5b403`
- Head: `feature/idempotency-and-benchmark-infra-23 @ 54f3f7e3ea8c5de707ccebb62074444223252bdc`
- Work mode (from `issue.md`): `full-feature`
- PR context artifacts: `artifacts/pr_context.summary.txt`, `artifacts/pr_context.appendix.txt`

## Scope Confirmation

Audit scope is the full branch diff against the resolved base branch (76 files changed, +5819 / -0 insertions per `git diff --stat`). No caller narrowing was applied. Languages with changed files in the branch diff:

- C# (production project changes: none; new test/benchmark projects under `tests/`; build infrastructure: `Directory.Packages.props`, `TaskMaster.sln`)
- PowerShell (new scripts under `scripts/benchmarks/`)
- YAML (CI workflow `.github/workflows/pr-pipeline.yml`)
- JSON (benchmark baseline + synthetic fixtures)
- Markdown (feature scoping + evidence)

## Rejected Scope Narrowing

None observed. The orchestrator prompt explicitly directs a full feature-vs-base audit.

## Policy Reading Order Applied

1. `CLAUDE.md` (standing instructions)
2. `.claude/rules/general-code-change.md`
3. `.claude/rules/general-unit-test.md`
4. `.claude/rules/quality-tiers.md`
5. `.claude/rules/csharp.md` (C# changes in scope)
6. `.claude/rules/powershell.md` (new PowerShell scripts in scope)
7. `.claude/rules/architecture-boundaries.md`
8. `.claude/rules/tonality.md`

No policy documents were modified by this PR (verified via `git diff --name-only` filtered to `.claude/rules/` and `.github/instructions/` — zero hits).

## Evidence Location Compliance

Scan of branch diff against non-canonical evidence paths (`artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, `artifacts/coverage/`): **0 violations**.

All feature evidence is written under `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/<kind>/` per the Evidence Location Invariant. Canonical evidence files observed across `baseline/`, `qa-gates/`, `regression-testing/`, `issue-updates/`, and `other/` subfolders.

Benchmark artifacts under `artifacts/benchmarks/` are committed runtime/baseline data (`baseline.json`, run logs, BDN reports), not feature-review evidence; this is the documented home for the committed baseline per `spec.md` and is consistent with the scope of `artifacts/benchmarks/README.md`.

Verdict: **PASS**.

## Toolchain Loop (per `.claude/rules/general-code-change.md`)

Verified from existing per-phase evidence (no re-execution):

| Stage | Tool | Evidence | Verdict |
|---|---|---|---|
| 1. Format | CSharpier (`dotnet csharpier check .`) | `evidence/qa-gates/p7-format.md` exit 0 | PASS |
| 2. Lint | .NET analyzers via `dotnet build -warnaserror` | `evidence/qa-gates/p7-lint.md` exit 0 | PASS |
| 3. Type-check | Nullable analysis via `dotnet build -warnaserror` | `evidence/qa-gates/p7-typecheck.md` exit 0 | PASS |
| 4. Architecture | `tests/TaskMaster.ArchitectureTests` (NetArchTest.Rules) | `evidence/qa-gates/p7-architecture.md` exit 0 | PASS |
| 5. Unit / property | `dotnet test TaskMaster.sln` (Worker.Tests incl. CsCheck) | `evidence/qa-gates/p7-test.md` exit 0; `evidence/regression-testing/p5-property-tests-pass.md` exit 0 | PASS |
| 6. Contract / schema | OpenAPI baseline (no API surface change in this PR) | `artifacts/openapi/current.json` present; no API source change in diff | PASS |
| 7. Integration | Stage-10 dry-run + self-validation | `evidence/qa-gates/p7-stage10-local.md` exit 0; `evidence/qa-gates/p7-self-validation.md` exit 0 | PASS |

PowerShell sub-toolchain (per `.claude/rules/powershell.md`): four new scripts under `scripts/benchmarks/` (`compare-benchmarks.ps1`, `enrich-bdn-report.ps1`, `make-synthetic-fixtures.ps1`, `parse-cobertura.ps1`).

- Formatting / Analyze: No per-script PSScriptAnalyzer / Invoke-Formatter evidence artifact was produced for these new scripts. The scripts use `#Requires -Version 7.0`, `[CmdletBinding()]`, named parameters, `param([Parameter(Mandatory)]...)`, and `$ErrorActionPreference = 'Stop'`, which are consistent with the standards in `.claude/rules/powershell.md`. Verdict: **PARTIAL** — toolchain artifacts (`mcp__drm-copilot__run_poshqc_format`, `mcp__drm-copilot__run_poshqc_analyze`) were not captured under `evidence/qa-gates/`.
- Pester tests for the four new PowerShell scripts: not present in the diff. The comparator script is exercised end-to-end via the C# `LatencyRegressionGateTests` self-validation (positive negative path) and the manual fixtures in `evidence/regression-testing/p3-comparator-*.md` (pass and synthetic-fail rows). No dedicated Pester unit tests exist for the four scripts. Verdict: **PARTIAL** — behavior is exercised by integration-style C# tests; pure unit Pester coverage for the script internals (`Get-PercentDelta`, `Read-BenchmarkReport` failure modes beyond the success path) is not present.

Verdict (combined toolchain loop): **PARTIAL** — C# loop is clean; PowerShell formal toolchain evidence is incomplete.

## File Size Limit

All new files under 500 lines:
- Largest C# file: `tests/TaskMaster.Worker.Tests/Subscriptions/SubscriptionHandlerTestBase.cs` = 92 lines.
- Largest PowerShell file: `scripts/benchmarks/compare-benchmarks.ps1` = 127 lines.
- All Markdown scoping/evidence files exempt per policy.

Verdict: **PASS**.

## Determinism / Banned APIs

`evidence/qa-gates/p5-banned-api-scan.md` (exit 0) reports zero hits for `Thread.Sleep|Task.Delay|DateTime.UtcNow|TimeProvider.System` in `tests/TaskMaster.Worker.Tests`.

Independent inspection of new test files (`SubscriptionHandlerTestBase.cs`, `DeltaReconciliationPropertyTests.cs`, `LatencyRegressionGateTests.cs`, sample/non-idempotent handlers): no banned-API call site observed. `FakeTimeProvider` is the only clock substitute (constructed in `SubscriptionHandlerTestBase` with a fixed UTC 2026-05-15 instant). CsCheck property tests carry explicit seed strings ("OutOfOrder_ProducesSameState", "Duplicates_AreIdempotent", "Missing_EventsAreDetected") so failures are reproducible.

One observation: `LatencyRegressionGateTests.cs` calls `process!.WaitForExit(60_000)`. This is a process-completion timeout, not a wall-clock wait or sleep, and is required to bound a child-process invocation of a real PowerShell script in a self-validation test. It is acceptable under the banned-API list but worth recording.

Verdict: **PASS**.

## Tier Classification

`evidence/qa-gates/p7-tier-validate.md` (exit 0) confirms `pwsh -File .github/scripts/validate-quality-tiers.ps1` passes. The diff to `quality-tiers.yml` adds `TaskMaster.Benchmarks` (T4) and the existing `TaskMaster.Worker.Tests` classification covers the new test project.

Verdict: **PASS**.

## Architecture Boundaries

`.claude/rules/architecture-boundaries.md` defines runtime/production constraints. This PR introduces no new production code; all changes live in `tests/`, `scripts/`, `artifacts/`, `.github/`, `docs/`, plus `Directory.Packages.props`, `TaskMaster.sln`, and `quality-tiers.yml`. `tests/TaskMaster.ArchitectureTests` runs green (`evidence/qa-gates/p7-architecture.md` exit 0).

- VSTO references: none in new code.
- `Microsoft.Office.Interop.Outlook`: none.
- `[ComVisible(true)]`: none.
- Ribbon callbacks: none.
- Outlook event streams / UDF state store: none.
- Mailbox access: none.

Verdict: **PASS**.

## Coverage Verification

Languages with changed files in branch:

| Language | Coverage Artifact | Status |
|---|---|---|
| C# | Cobertura under `artifacts/csharp/post-change-2/` aggregated by `scripts/benchmarks/parse-cobertura.ps1` and recorded in `evidence/qa-gates/p7-coverage-comparison.md` | Available; line 32.70% / branch 15.82% repo-wide |
| PowerShell | `artifacts/pester/powershell-coverage.xml` | **Absent** (no Pester run; no `.Tests.ps1` for the new scripts) |
| TypeScript | n/a — no TS changes in branch | n/a |
| Python | n/a — no Python changes in branch | n/a |

### C# coverage analysis

`evidence/qa-gates/p7-coverage-comparison.md` documents that:
- The PR introduces **no production code lines**; every changed source file lives under `tests/`, `scripts/`, or `artifacts/` (verified against the changed-files list from `pr_context.summary.txt`).
- Production-code coverage delta is 0/945 lines and 0/354 branches.
- Repo-wide absolute line coverage (32.70%) and branch coverage (15.82%) are below the uniform 85%/75% thresholds, but this is a **pre-existing condition not changed or regressed by this PR**.
- "No regression on changed lines" criterion is satisfied because no production lines were changed.

Per the uniform tier rule and the "no regression on changed lines" criterion: this PR does not regress coverage and adds no production code that would require new coverage. The absolute floor remains unmet repo-wide and is owned by Domain / Application / Classifier / Infrastructure / Api projects (out of scope per `spec.md` § Non-Goals).

C# coverage verdict: **PARTIAL** — no regression and no new production-code uncovered surface, but the absolute repo-wide line/branch coverage is below the uniform 85%/75% floor (pre-existing). Flagging this as `PARTIAL` (not `FAIL`) because (a) the per-tier policy uniform floor applies repo-wide; (b) this PR cannot remediate that floor without scope creep into production projects explicitly excluded by `spec.md`; (c) the relevant gate this PR can affect (no regression on changed lines) is satisfied.

### PowerShell coverage analysis

Four new PowerShell scripts (`scripts/benchmarks/compare-benchmarks.ps1`, `enrich-bdn-report.ps1`, `make-synthetic-fixtures.ps1`, `parse-cobertura.ps1`, total ~305 added lines) have no Pester unit tests in the diff. No `artifacts/pester/powershell-coverage.xml` exists. The comparator is exercised end-to-end via `LatencyRegressionGateTests` (positive failure path) and a manual self-comparison row (positive pass path); `parse-cobertura.ps1` is exercised as part of `p7-coverage-comparison.md` generation; `make-synthetic-fixtures.ps1` and `enrich-bdn-report.ps1` are exercised by their consuming evidence/workflow steps.

Per the Coverage Verification section of this skill, "If no coverage artifact is found for a language that has changed files, flag as **FAIL** with reason: 'coverage artifact absent for [language]; coverage verification is mandatory for all languages with changed files.'"

PowerShell coverage verdict: **FAIL** — `artifacts/pester/powershell-coverage.xml` is absent and the four scripts (~305 lines) have no Pester unit coverage. Added to remediation triggers.

### Combined coverage verdict

**FAIL** (PowerShell coverage artifact absent).

## Tonality

Spot-checked the new scripts, test files, scoping docs, and evidence files. Language is professional and factual; no humor, hyperbole, or decorative metaphor observed. The evidence files match the measured-tone requirement.

Verdict: **PASS**.

## Constraint Compliance (from `spec.md` § Constraints & Risks)

| Constraint | Verdict | Evidence |
|---|---|---|
| Benchmarks deterministic / fixed-config job, no wall-clock waits or shared mutable state | PASS | `BenchmarkConfig.cs` (single `Job.ShortRun.WithId("short-deterministic")`); benchmark inputs constructed once in `GlobalSetup` |
| Property-test corpus seedable with seed printed on failure | PASS | CsCheck `seed:` strings on every property test in `DeltaReconciliationPropertyTests.cs` |
| `FakeTimeProvider` is the only clock substitute; banned APIs absent in new test code | PASS | `evidence/qa-gates/p5-banned-api-scan.md` exit 0; manual file inspection confirms |
| No production handler code in scope | PASS | All changes under `tests/`, `scripts/`, `artifacts/`, `.github/`, `docs/`, build infrastructure files |
| Delta-reconciliation benchmark is a documented disabled placeholder pending Prompt G2 | PASS | `DeltaReconciliationBenchmarks.cs` throws `NotSupportedException` outside `ENABLE_G2_BENCHMARK`; `evidence/other/p2-todo-g2-marker.md` exit 0 |
| No temporary files in tests | PASS | No `Path.GetTempFileName` / `Path.GetTempPath` usage in new test code; fixtures committed under `tests/TaskMaster.Benchmarks/Fixtures/` |

Verdict: **PASS**.

## Overall Policy Verdict

**PARTIAL** with one **FAIL** finding (remediation required):

1. **FAIL** — PowerShell coverage artifact `artifacts/pester/powershell-coverage.xml` is absent. Four new scripts under `scripts/benchmarks/` have no Pester unit tests in the diff, and the PowerShell sub-toolchain (Invoke-Formatter / PSScriptAnalyzer / Pester) has no captured evidence artifact.
2. **PARTIAL** — C# repo-wide absolute coverage is below the uniform 85% / 75% floor (pre-existing, not regressed). Acknowledged as a documented baseline gap outside the explicit non-goals of this feature.

Other gates (format, lint, type-check, architecture, unit, contract, integration, banned APIs, file size, evidence location, scope, tier classification, tonality, spec constraints) all PASS.
