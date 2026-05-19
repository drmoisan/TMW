# Scope-Discovery Report — Phase 6 Halt

Timestamp: 2026-05-18T22-40
Command: Multiple `git grep` invocations against tracked files for the seven Phase 6 grep patterns.
EXIT_CODE: 0

## Why execution halted at P6-T1

The Phase 6 grep sweeps surfaced residual references outside the plan's documented allowlist (this plan file, this feature's `evidence/**`, the promoted potential entry, and the two waived xUnit `Trait` strings). Per the plan's stop-and-report triggers:

> Any grep sweep finds residual references outside the documented allowlist (a new scope-discovery event).

Per the executor anti-replanning rules, I do not invent additional tasks. I am halting and reporting.

## New scope-discovery findings (out-of-allowlist hits)

### Category A — historical evidence in other feature folders (likely benign, but unallowlisted)
Counted via `git grep -l` per pattern:

| Pattern | Total files matched | Live code/config (non-docs) | Other feature folders under `docs/features/**` |
|---|---|---|---|
| `stage-10-benchmark-regression` | 26 | 0 | ~24 (in archived and other active features) |
| `benchmark-gate-self-validation` | 34 | 7 (see Category B and C) | ~25 |
| `benchmark-baseline-refresh` | 6 | 0 | ~5 |
| `compare-benchmarks.ps1` | 32 | 0 | ~30 |
| `enrich-bdn-report.ps1` | 17 | 0 | ~15 |
| `artifacts/benchmarks` | 29 | 1 (Category D) | ~26 |
| `Benchmark p99 regression` | 3 | 0 | 3 (all in `docs/features/archive/2026-05-09-establish-repository-foundation-1/**`) |

These are records of prior completed work; they reference deleted infrastructure historically. The plan's allowlist names only this feature's `evidence/**`, this plan file, and the promoted potential entry. It does not allowlist other features' archived/active evidence.

### Category B — waived xUnit `Trait` strings (from plan; in scope as waivers)
- `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs:17` — `[Trait("Category", "benchmark-gate-self-validation")]`
- `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs:14` — `[Trait("Category", "benchmark-gate-self-validation")]`

These two hits are explicitly waived by the plan (P6-T2 allowlist item 4).

### Category C — additional live code/config hits NOT in any allowlist
1. `.github/actions/dotnet-test/action.yml` (lines 17, 20, 23): excludes tests with `Category=benchmark-gate-self-validation` from the main test lane via `--filter "Category!=benchmark-gate-self-validation"`. The workflow that ran those excluded tests is now deleted (P1-T2). The filter is dead code; it does no harm (the trait-tagged tests would simply run if the filter were removed), but it still references the deleted gate by name.
2. `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs` (lines 9-11): XML doc-comment text describing the `benchmark-gate-self-validation lane`.
3. `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandler.cs:9`: XML doc-comment text mentioning `benchmark-gate-self-validation lane`.

### Category D — make-synthetic-fixtures.ps1 residual reference to `artifacts/benchmarks`
- `scripts/benchmarks/make-synthetic-fixtures.ps1` still contains:
  - DESCRIPTION sentence: "Reads a BenchmarkDotNet baseline JSON report..." (after P4-T10 edit, no longer names `artifacts/benchmarks`)
  - But the parameter default `param([string]$BaselinePath = 'artifacts/benchmarks/baseline.json', ...)` still references the deleted path.

The plan's P4-T10 scoped only the `compare-benchmarks` comment edit, not the `artifacts/benchmarks` parameter default. P6-T6 expects zero hits on `artifacts/benchmarks` outside the allowlist; this hit is not allowlisted.

## What I will NOT do without an explicit plan revision

- Edit `.github/actions/dotnet-test/action.yml` (Category C item 1) — not in the plan.
- Edit `NonIdempotentHandler.cs` or `NonIdempotentHandlerNegativeTests.cs` doc comments (Category C items 2 and 3) — not in the plan; only their `Trait` strings are waived, not their doc comments.
- Edit the parameter default in `make-synthetic-fixtures.ps1` (Category D) — outside P4-T10's scope.
- Edit any of the historical evidence files in other feature folders (Category A) — they are completed-work records; editing them retroactively is a non-trivial scope decision that requires an explicit allowlist or task.
- Continue Phase 6 grep sweeps P6-T2 through P6-T7 — the plan's stop-and-report trigger fired at P6-T1.
- Continue Phase 6 toolchain loop (P6-T8 through P6-T18) — the grep sweep cannot pass per the plan's verification text, so the toolchain loop cannot satisfy completion criteria either.
- Continue Phase 7 acceptance-criteria mapping — depends on Phase 6 passing.

## Recommended plan revision (for the planner)

The plan needs an additional allowlist entry and/or additional Phase 4 tasks. Suggested deltas (planner's choice):

Option 1 — Expand the Phase 6 allowlist:
- Allowlist all files under `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/**` and `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/**` and `docs/features/archive/**` as historical evidence of prior completed work.
- Add explicit P6-T2 waivers for the three Category C live-code references (or add new Phase 4 tasks to clean them up).
- Add explicit waiver for the parameter default in `make-synthetic-fixtures.ps1` OR add a new P4 task to also update that default.

Option 2 — Expand Phase 4 to clean every live-code residual reference, and limit the allowlist expansion to historical evidence in other feature folders only:
- New `[P4-T11]`: edit `.github/actions/dotnet-test/action.yml` to remove the `--filter "Category!=benchmark-gate-self-validation"` clause and the two related comment lines.
- New `[P4-T12]`: edit `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandler.cs` and `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs` to scrub `benchmark-gate-self-validation lane` from doc comments (keeping `[Trait]` strings per existing waiver).
- New `[P4-T13]`: edit `scripts/benchmarks/make-synthetic-fixtures.ps1` parameter default from `artifacts/benchmarks/baseline.json` to a different default OR remove the default and require the caller to pass it.
- Update Phase 6 allowlist to also cover `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/**`, `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/**`, and `docs/features/archive/**`.

## Phase status at halt

- Phase 0: COMPLETE (14/14 from prior session)
- Phase 1: COMPLETE (3/3 this session)
- Phase 2: COMPLETE (4/4)
- Phase 3: COMPLETE (3/3)
- Phase 4: COMPLETE (10/10) — P4-T10 made the minimum change in scope (comment); P4-T9 made the minimum change in scope (path reference in bullet)
- Phase 5: COMPLETE (4/4) — mirrors resynced and absences recorded
- Phase 6: HALTED at P6-T1 (1 partial grep evidence recorded); P6-T2 through P6-T18 not started
- Phase 7: NOT STARTED

## Toolchain status
Final-pass toolchain (P6-T9 through P6-T18) was not executed because the halt occurred at P6-T1.

## dotnet build status
`dotnet build tests/TaskMaster.Benchmarks` (P6-T8) was not executed because the halt occurred at P6-T1.

## Seven grep-sweep counts (preliminary — only P6-T1 ran in full)
| Pattern | Files matched (preliminary; not all allowlist-classified) |
|---|---|
| `stage-10-benchmark-regression` | 26 |
| `benchmark-gate-self-validation` | 34 |
| `benchmark-baseline-refresh` | 6 |
| `compare-benchmarks.ps1` | 32 |
| `enrich-bdn-report.ps1` | 17 |
| `artifacts/benchmarks` | 29 |
| `Benchmark p99 regression` | 3 |
