# Pre-Change Grep Inventory

Timestamp: 2026-05-18T22-05
Command: ripgrep / Grep tool (one pass per pattern); search root = repo root
EXIT_CODE: 0 (informational baseline)
Output Summary: Pre-change live-file hits per pattern enumerated below. Matches inside `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/` (this plan + evidence) and prior feature folders under `docs/features/active/` and `docs/features/archive/` are recorded but excluded from the Phase 6 zero-hit target.

## Pattern: `stage-10-benchmark-regression`
Live (in-scope or to-be-deleted) hits:
- `.github/workflows/_stage-10-benchmark-regression.yml` (1, 10) — will be deleted (P1-T1)
- `.github/workflows/pr-pipeline.yml` (68, 70) — will be edited (P4-T1)
- `.github/workflows/README.md` (39, 67, 102) — workflow inventory references; NOT in plan scope. See "Out-of-plan references" below.
- `.github/workflows/benchmark-baseline-refresh.yml` (3, comment) — will be deleted (P1-T3)
Feature/historic doc hits (allowed): user-story.md, spec.md, plan, issue.md, evidence baselines, prior feature folder evidence under archive/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/.

## Pattern: `benchmark-gate-self-validation`
Live in-scope or to-be-deleted hits:
- `.github/workflows/_benchmark-gate-self-validation.yml` (1, 10, 21, 25, 28) — will be deleted (P1-T2)
- `.github/workflows/pr-pipeline.yml` (72, 74) — will be edited (P4-T1)
- `.github/workflows/README.md` (40, 68, 103) — NOT in plan scope; see "Out-of-plan references".
Pre-existing test-category strings (declared out of plan scope per Open Questions / Notes):
- `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs` (9, 10, 11, 14) — `[Trait("Category","benchmark-gate-self-validation")]` is an independent xUnit category trait unrelated to the deleted workflow.
- `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs` (per plan Open Questions note) — same trait pattern, out of scope.

## Pattern: `benchmark-baseline-refresh`
Live in-scope or to-be-deleted hits:
- `.github/workflows/benchmark-baseline-refresh.yml` (header comment) — will be deleted (P1-T3)
- `.github/workflows/README.md` (46) — NOT in plan scope; see "Out-of-plan references".
Feature/historic doc hits (allowed): plan, spec, user-story, issue, evidence baselines, prior feature folders.

## Pattern: `compare-benchmarks.ps1`
Live in-scope or to-be-deleted hits:
- `scripts/benchmarks/compare-benchmarks.ps1` — will be deleted (P2-T1)
- `scripts/benchmarks/make-synthetic-fixtures.ps1` (line 7, comment referencing comparator)
- `scripts/benchmarks/enrich-bdn-report.ps1` (line 8, comment)
- `scripts/powershell/PoshQC/settings/pester.runsettings.psd1` (22) — will be edited (P4-T5)
- `tests/scripts/benchmarks/compare-benchmarks.Tests.ps1` — will be deleted (P2-T3)
- `.github/workflows/_stage-10-benchmark-regression.yml` — will be deleted (P1-T1)
- `artifacts/benchmarks/README.md` (9) — file will be deleted (P3-T2)
Comment-only references in `make-synthetic-fixtures.ps1` and `enrich-bdn-report.ps1` will be addressed: `enrich-bdn-report.ps1` is being deleted (P2-T2). `make-synthetic-fixtures.ps1` retains a stale comment — see "Out-of-plan references".

## Pattern: `enrich-bdn-report.ps1`
Live in-scope or to-be-deleted hits:
- `scripts/benchmarks/enrich-bdn-report.ps1` — will be deleted (P2-T2)
- `tests/scripts/benchmarks/enrich-bdn-report.Tests.ps1` — will be deleted (P2-T4)
- `scripts/powershell/PoshQC/settings/pester.runsettings.psd1` (23) — will be edited (P4-T5)
- `.github/workflows/_stage-10-benchmark-regression.yml` (27) — will be deleted (P1-T1)
- `.github/workflows/benchmark-baseline-refresh.yml` (42) — will be deleted (P1-T3)
- `artifacts/benchmarks/README.md` (22) — file will be deleted (P3-T2)
- `testResults.xml` — untracked file (working-tree leftover); not committed; will not be edited.

## Pattern: `artifacts/benchmarks`
Live in-scope or to-be-deleted hits:
- `artifacts/benchmarks/README.md`, `artifacts/benchmarks/baseline.json` — will be deleted (P3-T1/T2/T3)
- `.github/workflows/_stage-10-benchmark-regression.yml` (21, 25, 33, 37, 38) — deleted P1-T1
- `.github/workflows/benchmark-baseline-refresh.yml` — deleted P1-T3
- `.gitignore` (63–67) — `.gitignore` entries reference `artifacts/benchmarks/`. NOT in plan scope; see "Out-of-plan references".
- `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` (1020) — historic architecture doc. Not in plan scope.

## Pattern: `Benchmark p99 regression`
Live in-scope or to-be-edited hits:
- `.claude/rules/quality-tiers.md` (45) — will be edited (P4-T3)
- `.github/instructions/quality-tiers.instructions.md` (45) — mirror; will be resynced (P5-T1)
- `docs/ci.research.md` (121) — research source-of-truth doc. Not in plan scope; see "Out-of-plan references".
Feature/historic doc hits (allowed): plan, spec, user-story, issue, prior feature folder.

## Out-of-plan references (NOT scheduled for edit by this plan)
The following live-file hits exist today but are NOT named in the plan's edit list. They are recorded here so the Phase 6 grep verification can recognize them as pre-existing residuals rather than block on them. Per plan rules, if any blocks Phase 6 zero-hit expectation, executor must stop and report back to orchestrator rather than self-extend scope.

1. `.github/workflows/README.md` — references all three deleted workflows in its inventory table.
2. `.gitignore` — has `!artifacts/benchmarks/`, `artifacts/benchmarks/*`, `!artifacts/benchmarks/baseline.json`, `!artifacts/benchmarks/README.md` entries.
3. `docs/ci.research.md` — research source-of-truth doc has the same tier-matrix table including "Benchmark p99 regression".
4. `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` — historic architecture doc references `artifacts/benchmarks/baseline.json`.
5. `scripts/benchmarks/make-synthetic-fixtures.ps1` — comment references `compare-benchmarks.ps1` (script being deleted).
6. `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs` and `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs` — `[Trait("Category","benchmark-gate-self-validation")]` xUnit traits, independent of the deleted workflow per plan Open Questions / Notes.
7. `testResults.xml` (untracked working-tree file).

These items will be flagged as blocking findings during Phase 6 if they cause grep sweeps to fail the zero-hit target. The plan requires the executor to stop and report rather than edit beyond scope.
