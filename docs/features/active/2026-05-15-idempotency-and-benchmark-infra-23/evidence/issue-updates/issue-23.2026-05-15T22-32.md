# Issue #23 — PR-Context Update Mirror

Timestamp: 2026-05-15T22-32
PostedAs: body (placeholder; orchestrator will post to GitHub)
IssueUpdatedAt: pending

## Intended Issue Body Update

This PR (`feature/idempotency-and-benchmark-infra-23`) delivers the gate-only infrastructure required by Prompt G1 of the No-COM architecture migration. Phase G handler code (Prompt G2 and later) is NOT in scope; the delta-reconciliation benchmark slot is registered but disabled with a `TODO(G2)` marker.

### Change Set

Production / infrastructure projects added:
- `tests/TaskMaster.Benchmarks/` — BenchmarkDotNet project (T4) covering classifier hot paths (`Classify_Command`, `InputNormalization_EdgePath`, `TrainingState_Update`) plus a disabled `DeltaReconciliationBenchmarks` placeholder gated behind `ENABLE_G2_BENCHMARK`.
- `tests/TaskMaster.Worker.Tests/` — xunit.v3 + CsCheck + FluentAssertions test project (T4) hosting `SubscriptionHandlerTestBase`, the sample idempotent and non-idempotent handlers, `DeltaReconciliationPropertyTests`, and the `LatencyRegressionGateTests` self-validation.

Tooling / pipeline:
- `scripts/benchmarks/compare-benchmarks.ps1` — PR-pipeline stage 10 comparator (p99 > 5% on T1; allocation > 10% on any benchmarked id).
- `scripts/benchmarks/enrich-bdn-report.ps1` — Injects `P99` into BDN `*-report-full.json` (BDN's default percentile set omits P99).
- `scripts/benchmarks/make-synthetic-fixtures.ps1` — Generates the committed `SyntheticLatencyRegressionFixture.json` and `SyntheticAllocationRegressionFixture.json` used by the self-validation suite.
- `scripts/benchmarks/parse-cobertura.ps1` — Coverage aggregation helper.
- `.github/workflows/pr-pipeline.yml` — Adds `stage-10-benchmark-regression` and `benchmark-gate-self-validation` jobs.
- `Directory.Packages.props` — Adds `BenchmarkDotNet 0.14.0` under CPM.
- `quality-tiers.yml` — Registers both new projects as tier t4.
- `artifacts/benchmarks/baseline.json` and `artifacts/benchmarks/README.md` — Committed baseline plus schema documentation.

### Evidence Artifacts (canonical evidence root)

- Phase 0 baseline: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/baseline/`
- Phase 1–6 task evidence: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/other/`
- Regression / self-validation evidence: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/regression-testing/`
- Phase 7 QA gates: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/qa-gates/`
- AC checkoff map: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/qa-gates/p14-acceptance-criteria-checkoff.md`
- This update mirror: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/issue-updates/issue-23.2026-05-15T22-32.md`

### Pre-Existing Findings

- `TaskMaster.Classifier.Tests.KeywordClassifierTests.Classify_AnyValidSnapshot_ConfidenceInRange` is flaky under CsCheck seed `ekxz7tIqea92` (and other seeds that produce whitespace-only random subjects). Not modified by this PR; documented in `evidence/qa-gates/p7-test.md` for separate triage.

### Acceptance Criteria Status

AC1–AC8 satisfied. See `evidence/qa-gates/p14-acceptance-criteria-checkoff.md` for per-AC evidence map. Both `spec.md` and `user-story.md` AC checklists have been updated to `[x]`.

### Post-Merge Action Required (Branch Protection)

`stage-10-benchmark-regression` and `benchmark-gate-self-validation` must be added to the required-status-checks list on `main` branch protection. The job definitions are in place; the protection-rule change is administrative and not part of this PR (see `evidence/other/p6-required-checks.md`).
