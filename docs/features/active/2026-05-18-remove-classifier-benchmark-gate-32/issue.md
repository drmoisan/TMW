# remove-classifier-benchmark-gate (Issue #31)

- Date captured: 2026-05-18
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/remove-classifier-benchmark-gate/ (Issue #31)

- Issue: #31
- Issue URL: https://github.com/drmoisan/TMW/issues/31
- Last Updated: 2026-05-19
- Work Mode: full-feature

## Problem / Why

The `stage-10-benchmark-regression` PR gate runs BenchmarkDotNet against `*ClassifierBenchmarks*` on a shared `windows-latest` runner and compares results to a committed baseline. The shared runner cannot provide a stable thermal/CPU environment, so the gate is the least deterministic test in the pipeline. Project direction has changed: the classifier will be substantially rewritten in the near term and classifier latency is not a meaningful contributor to user-perceived performance. Continuing to maintain the gate, its baseline, its comparator, its self-validation companion, and its baseline-refresh workflow consumes effort for a signal we no longer want.

## Proposed Behavior

Remove `stage-10-benchmark-regression` and its supporting infrastructure from CI. Retain the `tests/TaskMaster.Benchmarks` project as an on-demand manual perf-investigation tool. Update the repository quality-tier rules so the deletion is consistent with policy.

## Acceptance Criteria (early draft)

- [ ] `.github/workflows/_stage-10-benchmark-regression.yml` is deleted.
- [ ] `.github/workflows/_benchmark-gate-self-validation.yml` is deleted.
- [ ] `.github/workflows/benchmark-baseline-refresh.yml` is deleted.
- [ ] `.github/workflows/pr-pipeline.yml` no longer references the deleted callees.
- [ ] `scripts/benchmarks/compare-benchmarks.ps1` and `scripts/benchmarks/enrich-bdn-report.ps1` are deleted.
- [ ] `artifacts/benchmarks/baseline.json` and the rest of the `artifacts/benchmarks/` tree are deleted.
- [ ] `tests/TaskMaster.Benchmarks` is retained and still builds; it can be run manually.
- [ ] `.claude/rules/quality-tiers.md` no longer lists "Benchmark p99 regression" as a required tier-dependent gate.
- [ ] `.claude/rules/general-code-change.md` no longer references benchmark regression in the nightly-pipeline sentence.
- [ ] Bundled mirrors under `.codex/`, `.agents/`, `.github/` for any modified `.claude/` and `.github/` files are resynchronized so the python + pester contract tests pass.
- [ ] Full CI loop passes on the change branch (no perf gate present, no orphan references).

## Constraints & Risks

- No active branch-protection rule on `main` currently lists the gate as a required check (confirmed by repo owner). No admin coordination needed.
- The `TaskMaster.Benchmarks` project must remain compilable so manual perf work is still possible.
- Bundled-mirror contract tests enforce parity between live `.claude/` / `.github/` files and their bundled copies; every edit to a runtime file requires an immediate mirror update.
- After deletion there is no automated regression signal for classifier latency. This is an accepted trade given the planned classifier rewrite.

## Test Conditions to Consider

- [ ] Repo-wide grep for residual references to the deleted files, jobs, scripts, baselines, and tier-matrix row.
- [ ] `dotnet build` of `tests/TaskMaster.Benchmarks` to confirm the manual-run path still compiles.
- [ ] Python + Pester contract tests that enforce bundled-mirror parity.
- [ ] Full PR pipeline run on the change branch: every remaining stage green; no skipped job referencing a deleted callee.

## Next Step

- [x] Promote to GitHub issue (refactor template)
- [x] Create `docs/features/active/remove-classifier-benchmark-gate/` folder from the template