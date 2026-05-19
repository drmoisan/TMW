# `remove-classifier-benchmark-gate` — User Story

- Issue: #32
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-18

## Story Statement

- As a maintainer of the TMW repository, I want the `stage-10-benchmark-regression` PR gate and all of its supporting CI infrastructure removed, so that PR runs are no longer blocked by the least-deterministic test in the pipeline while I retain the ability to run `tests/TaskMaster.Benchmarks` manually for on-demand perf investigations.

## Problem / Why

`stage-10-benchmark-regression` runs BenchmarkDotNet against `*ClassifierBenchmarks*` on a shared `windows-latest` runner and compares the results to a committed baseline under `artifacts/benchmarks/baseline.json`. Shared GitHub-hosted runners do not provide stable thermal or CPU conditions, so the gate's variance is dominated by runner noise rather than by code changes. The signal-to-noise ratio is low enough that the gate produces intermittent failures on commits that did not modify classifier code.

Project direction has changed: the classifier will be substantially rewritten in the near term, and classifier latency is not a meaningful contributor to user-perceived performance. Continuing to maintain the gate, its baseline, its comparator scripts (`scripts/benchmarks/compare-benchmarks.ps1`, `scripts/benchmarks/enrich-bdn-report.ps1`), its self-validation companion (`_benchmark-gate-self-validation.yml`), and its baseline-refresh workflow (`benchmark-baseline-refresh.yml`) consumes maintenance effort for a signal that no longer matches our priorities.

The `tests/TaskMaster.Benchmarks` project itself remains useful as an on-demand perf-investigation tool. It must continue to build and run manually after this change so that ad hoc perf work remains possible.

## Personas & Scenarios

- Persona: Repository maintainer.
  - Who they are: the engineer who owns PR-time merge gates, branch-protection rules on `main`, and the quality-tier policy in `.claude/rules/`.
  - What they care about: that the noisy gate is gone, that no orphan references to it remain in any workflow or rule file, that bundled mirrors stay in sync, and that the manual perf-investigation path via `tests/TaskMaster.Benchmarks` continues to work.
  - Constraints: must not delete the benchmarks project itself; must not introduce a replacement perf gate; must keep the rule set internally consistent by editing `.claude/rules/quality-tiers.md` and `.claude/rules/general-code-change.md` in the same change.
  - Goals and frustrations: wants to stop investigating intermittent stage-10 failures that turn out to be runner noise. Past frustration: a stage-10 failure on a commit touching only documentation that required a baseline-refresh dance to clear.

- Scenario (primary): PR opened after the gate is removed.
  - Trigger: a contributor opens a PR against `main` from any branch.
  - Steps: the `pr-pipeline.yml` orchestrator runs. The job list no longer contains `stage-10-benchmark-regression` or `benchmark-gate-self-validation`. No downstream job has a dangling `needs:` reference to either.
  - Expected outcome: every remaining stage produces a result (pass or fail on its own merits). No skipped or errored job references a deleted callee. Branch-protection rules on `main` continue to pass because none of them required the removed checks.

- Scenario (secondary): Engineer runs the benchmarks manually for an on-demand perf investigation.
  - Trigger: an engineer wants to measure classifier latency locally after a code change.
  - Steps: from a clean checkout, the engineer runs `dotnet build tests/TaskMaster.Benchmarks` (succeeds), then `dotnet run -c Release --project tests/TaskMaster.Benchmarks`.
  - Expected outcome: BenchmarkDotNet executes and emits its standard report (console output and BDN's own artifact folder). No CI workflow, no comparator script, and no baseline JSON file is required to obtain the report.

## Acceptance Criteria

- [ ] AC1: `.github/workflows/_stage-10-benchmark-regression.yml` is deleted.
- [ ] AC2: `.github/workflows/_benchmark-gate-self-validation.yml` is deleted.
- [ ] AC3: `.github/workflows/benchmark-baseline-refresh.yml` is deleted.
- [ ] AC4: `.github/workflows/pr-pipeline.yml` no longer references the deleted callees.
- [ ] AC5: `scripts/benchmarks/compare-benchmarks.ps1` and `scripts/benchmarks/enrich-bdn-report.ps1` are deleted.
- [ ] AC6: `artifacts/benchmarks/baseline.json` and the rest of the `artifacts/benchmarks/` tree are deleted.
- [ ] AC7: `tests/TaskMaster.Benchmarks` is retained and still builds; it can be run manually.
- [ ] AC8: `.claude/rules/quality-tiers.md` no longer lists "Benchmark p99 regression" as a required tier-dependent gate.
- [ ] AC9: `.claude/rules/general-code-change.md` no longer references benchmark regression in the nightly-pipeline sentence.
- [ ] AC10: Bundled mirrors under `.codex/`, `.agents/`, `.github/` for any modified `.claude/` and `.github/` files are resynchronized so the python + pester contract tests pass.
- [ ] AC11: Full CI loop passes on the change branch (no perf gate present, no orphan references).

## Non-Goals

- No changes to classifier source code (SpamBayes engine, Triage engine, or any production logic under `src/`).
- No replacement performance gate is introduced (no soft benchmark job, no statistical-stability gate, no nightly perf workflow).
- No deletion of the `tests/TaskMaster.Benchmarks` project. The project remains compilable and manually runnable.
- No changes to coverage thresholds, tier classifications in `quality-tiers.yml`, or other unrelated quality gates.
- No branch-protection automation. Confirmed that no current rule on `main` references the removed checks, so no admin action is required.
- No changes to `pre-merge-pipeline.yml` beyond removing benchmark-specific references if any exist (to be verified at edit time).
