# remove-classifier-benchmark-gate - Refactor Spec

- **Issue:** #32
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-18T21-11
- **Status:** Draft
- **Version:** 0.2

## Intent & Outcomes

The `stage-10-benchmark-regression` PR gate runs BenchmarkDotNet against `*ClassifierBenchmarks*` on a shared `windows-latest` runner and compares results to a committed baseline. The shared runner cannot provide a stable thermal/CPU environment, so the gate is the least deterministic test in the pipeline. Project direction has changed: the classifier will be substantially rewritten in the near term and classifier latency is not a meaningful contributor to user-perceived performance. Continuing to maintain the gate, its baseline, its comparator, its self-validation companion, and its baseline-refresh workflow consumes effort for a signal we no longer want.

Outcomes:
- The `stage-10-benchmark-regression` gate and every supporting CI artifact are removed from the repository.
- The `tests/TaskMaster.Benchmarks` project is retained as an on-demand manual perf-investigation tool and still compiles.
- `.claude/rules/quality-tiers.md` and `.claude/rules/general-code-change.md` no longer reference benchmark-regression gating, so the rule set is internally consistent with the deletion.
- All bundled mirrors (`.codex/`, `.agents/`, `.github/`) remain byte-consistent with their live source files; the python + pester mirror-contract tests pass.

## Invariants (must not change)

- Every CI stage that survives (`stage-1-format` through `stage-9-coverage`, `stage-e2e-smoke`, `secret-scan`, `tier-classification`, the .NET stages, `benchmark-gate-self-validation` insofar as it is the gate's own self-test and is being deleted with the gate, etc.) must continue to pass on the change branch.
- `tests/TaskMaster.Benchmarks` must still build with `dotnet build` and remain runnable manually via `dotnet run -c Release --project tests/TaskMaster.Benchmarks`.
- Bundled-mirror contract tests under `tests/` (python + pester) must continue to pass; every modified `.claude/` or `.github/` file has a synchronized mirror under `.codex/`, `.agents/`, and `.github/` as enforced by those contract tests.
- Branch-protection rules on `main`: no change required (confirmed that no protection rule currently lists `stage-10-benchmark-regression` or `benchmark-gate-self-validation` as required checks).
- Performance characteristics to preserve (latency/throughput/memory): none. This refactor removes a CI gate; it does not touch production classifier code.
- Compatibility guarantees (CLI flags, config schemas, versions): the `dotnet run` command line for `tests/TaskMaster.Benchmarks` continues to behave as it does today.

## Scope (structural changes)

Deletions:
- `.github/workflows/_stage-10-benchmark-regression.yml`
- `.github/workflows/_benchmark-gate-self-validation.yml`
- `.github/workflows/benchmark-baseline-refresh.yml`
- `scripts/benchmarks/compare-benchmarks.ps1`
- `scripts/benchmarks/enrich-bdn-report.ps1`
- `artifacts/benchmarks/baseline.json` and the rest of the `artifacts/benchmarks/` tree

Edits:
- `.github/workflows/pr-pipeline.yml` — remove the `stage-10-benchmark-regression` and `benchmark-gate-self-validation` job entries (currently around lines 68–74; verify exact lines at edit time) and any `needs:` references to them from downstream jobs.
- `.claude/rules/quality-tiers.md` — remove the "Benchmark p99 regression" row from the tier-dependent gate matrix; remove or revise any prose paragraph that cites the row.
- `.claude/rules/general-code-change.md` — in the line that reads "Mutation testing, golden tests, and benchmark regression run in pre-merge or nightly pipelines, not the per-commit loop.", drop "and benchmark regression" (or rewrite to "Mutation testing and golden tests run in pre-merge or nightly pipelines, not the per-commit loop."). Mutation testing and golden tests remain.

Bundled-mirror resync:
- For every `.claude/` and `.github/` file edited above, regenerate the corresponding bundled copies under `.codex/`, `.agents/`, and `.github/` so the mirror-contract tests pass.

Retained, untouched:
- `tests/TaskMaster.Benchmarks` source tree. The project remains compilable and manually runnable.

## Non-Goals

- No changes to classifier source code (SpamBayes engine, Triage engine, or any production logic under `src/`).
- No replacement performance gate is introduced (no new "soft" benchmark job, no statistical-stability gate).
- No new nightly workflow to compensate for the removed PR-time gate.
- No removal of the `tests/TaskMaster.Benchmarks` project itself.
- No changes to coverage thresholds, tier classifications, or other unrelated quality gates.
- No edits to `pre-merge-pipeline.yml` beyond the benchmark-specific references (if any). Verify and document at edit time.

## Dependencies / Touchpoints

- `.github/workflows/pr-pipeline.yml` orchestrator structure (callee/caller refactor from issue #27 is already merged; this change removes two callee references).
- Bundled-mirror sync skill (`.claude/skills/bundled-mirror-sync` or equivalent) and the python + pester contract tests that enforce mirror parity.
- `quality-tiers.yml` at repo root — verify no benchmark-specific entry needs updating (expected: no change, but inspect before completing).
- `.claude/rules/quality-tiers.md` and `.claude/rules/general-code-change.md` — both must be edited in the same change.
- Required coordination (other teams, CI/CD, release tooling): none. Confirmed no branch-protection rule on `main` references the gate; no admin coordination required.

## Risks & Mitigations

- Risk: a `.github/` or `.claude/` mirror under `.codex/`, `.agents/`, or `.github/` is missed during resync. Mitigation: rely on the python + pester mirror-contract tests in the toolchain loop; they fail the build on any drift.
- Risk: `pr-pipeline.yml` retains a dangling `needs: stage-10-benchmark-regression` reference on a downstream job. Mitigation: repo-wide grep for `stage-10-benchmark-regression` and `benchmark-gate-self-validation` after edits; the orchestrator workflow lints itself when GitHub parses it.
- Risk: `tests/TaskMaster.Benchmarks` no longer compiles because it depended on a deleted helper script. Mitigation: the deleted artifacts are CI-only (workflows, comparator scripts, baseline JSON); none are referenced from the benchmark project's `.csproj` or source. Verify with `dotnet build tests/TaskMaster.Benchmarks` as part of acceptance.
- Risk: removal of the gate leaves no automated signal for classifier latency. Accepted trade given the planned classifier rewrite.

## Technical Specifications

- Files/modules expected to change: listed in full under "Scope (structural changes)" above.
- Public interfaces/contracts affected (even if behavior is unchanged): none. The deleted workflows and scripts were internal CI artifacts. The `tests/TaskMaster.Benchmarks` CLI surface is unchanged.
- Data flow or validation adjustments: removal of the BDN baseline comparator and its JSON baseline. No remaining consumer reads `artifacts/benchmarks/`.
- Logging/telemetry updates (if any): none.
- Migration or backfill needs (if any): none. The deleted baseline JSON is not referenced after the change.

## Test Strategy

- Regression tests to add or update: none new. Existing python + pester mirror-contract tests must continue to pass.
- Invariant validation tests (ensuring outputs/behavior unchanged):
  - Repo-wide grep for residual references to `stage-10-benchmark-regression`, `benchmark-gate-self-validation`, `compare-benchmarks.ps1`, `enrich-bdn-report.ps1`, `artifacts/benchmarks/`, and `Benchmark p99 regression`. Expected: zero hits in live files (mirrors must also be clean).
  - `dotnet build tests/TaskMaster.Benchmarks` returns success.
  - Full pytest + pester contract suites pass.
- Edge cases and negative scenarios: confirm that no other workflow file (`pre-merge-pipeline.yml`, nightly workflows, etc.) imports or `needs:` the removed callees.
- Error handling and logging verification: not applicable — no production code changes.
- Coverage impact and targets for changed lines/modules: no production source modified; coverage unchanged.
- Toolchain commands to run (format → lint → type-check → architecture → unit tests → contract → integration):
  1. Formatting (CSharpier, Invoke-Formatter as applicable).
  2. Linting (PSScriptAnalyzer on remaining scripts, .NET analyzers).
  3. Type checking (where applicable).
  4. Architecture-boundary tests.
  5. Unit tests (python + pester contract tests included).
  6. Contract / schema compatibility checks.
  7. Integration tests.
- Manual validation steps: open a PR from the change branch and confirm the GitHub Actions run lists no `stage-10-benchmark-regression` and no `benchmark-gate-self-validation` jobs; all remaining stages green.

## Definition of Done

- [ ] All deletions listed in Scope are applied; the files are absent from the working tree and the index.
- [ ] `pr-pipeline.yml` no longer references the removed callees.
- [ ] `.claude/rules/quality-tiers.md` and `.claude/rules/general-code-change.md` edits are applied.
- [ ] Bundled mirrors under `.codex/`, `.agents/`, `.github/` for every modified `.claude/` and `.github/` file are resynchronized.
- [ ] `dotnet build tests/TaskMaster.Benchmarks` succeeds.
- [ ] Repo-wide grep returns zero hits for the deleted gate names, scripts, and baseline path.
- [ ] Full toolchain loop (format → lint → type-check → architecture → unit tests → contract → integration) passes in a single pass.
- [ ] Full PR pipeline runs on the change branch: every remaining stage green, no orphan references.

## Acceptance Criteria (verbatim from Issue #32)

- [x] AC1: `.github/workflows/_stage-10-benchmark-regression.yml` is deleted.
- [x] AC2: `.github/workflows/_benchmark-gate-self-validation.yml` is deleted.
- [x] AC3: `.github/workflows/benchmark-baseline-refresh.yml` is deleted.
- [x] AC4: `.github/workflows/pr-pipeline.yml` no longer references the deleted callees.
- [x] AC5: `scripts/benchmarks/compare-benchmarks.ps1` and `scripts/benchmarks/enrich-bdn-report.ps1` are deleted.
- [x] AC6: `artifacts/benchmarks/baseline.json` and the rest of the `artifacts/benchmarks/` tree are deleted.
- [x] AC7: `tests/TaskMaster.Benchmarks` is retained and still builds; it can be run manually.
- [x] AC8: `.claude/rules/quality-tiers.md` no longer lists "Benchmark p99 regression" as a required tier-dependent gate.
- [x] AC9: `.claude/rules/general-code-change.md` no longer references benchmark regression in the nightly-pipeline sentence.
- [x] AC10: Bundled mirrors under `.codex/`, `.agents/`, `.github/` for any modified `.claude/` and `.github/` files are resynchronized so the python + pester contract tests pass.
- [ ] AC11: Full CI loop passes on the change branch (no perf gate present, no orphan references).

## Seeded Test Conditions (from potential)
- [ ] Repo-wide grep for residual references to the deleted files, jobs, scripts, baselines, and tier-matrix row.
- [ ] `dotnet build` of `tests/TaskMaster.Benchmarks` to confirm the manual-run path still compiles.
- [ ] Python + Pester contract tests that enforce bundled-mirror parity.
- [ ] Full PR pipeline run on the change branch: every remaining stage green; no skipped job referencing a deleted callee.
