# idempotency-and-benchmark-infra — Spec

- **Issue:** #23
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-15
- **Status:** Draft
- **Version:** 1.0

## Overview

Phase G of the No-COM architecture migration replaces local event-driven processing with service-side Graph subscription processing. Two classes of silent regression must be gated before any Phase G handler or worker code lands:

1. Non-idempotent Graph subscription handlers that double-apply state when a notification is redelivered, retried, or replayed.
2. Performance regressions on T1 classifier hot paths and (later) the delta-reconciliation hot path that are invisible to functional tests.

This feature delivers gate-only infrastructure required by Prompt G1 of `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` (lines 1007–1029). It must merge before the Phase G implementation prompts (G2 and later) begin.

Production handler code, the background worker, and any subscription-lifecycle implementation are explicitly out of scope.

## Behavior

The feature stands up two independent gates plus their validation scenarios.

### Benchmark regression gate

- A new dedicated `*.Benchmarks` C# project references BenchmarkDotNet and exercises the classifier hot paths identified in Prompt D2 (`docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` lines 905–926): the classify-command path, input-normalization edge paths covered by the property tests, and the training-state update path.
- A versioned baseline file at `artifacts/benchmarks/baseline.json` records the reference benchmark results for those hot paths.
- Pre-merge pipeline stage 10 (benchmark regression) runs the benchmark project for every PR, compares the run to `artifacts/benchmarks/baseline.json`, and blocks the PR when p99 latency on a T1 hot path regresses by more than 5% or allocation on any benchmarked path regresses by more than 10%.
- A documented placeholder benchmark for the delta-reconciliation hot path is registered (skipped/disabled) in the Benchmarks project, with a `TODO(G2)` comment that points to Prompt G2 as the trigger to enable it once handler code exists.

### Idempotency gate

- A reusable idempotency test fixture replays the same Graph-subscription notification through a worker handler N times (N >= 3, configurable on the fixture) and asserts that the post-state after N executions equals the post-state after a single execution.
- The fixture uses `FakeTimeProvider` for all time reads and a deterministic message-id seed so that retries produce identical notification identities.
- Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences using a seeded property-test runner. On failure the seed is reported so the failing sequence is reproducible.
- An assertion hook on the subscription-handler test base class invokes the idempotency property check on every derived handler test class so the gate is inherited by default.

### Validation scenarios

- A scripted scenario introduces a synthetic 10% latency regression on a benchmarked T1 hot path and confirms that stage 10 fails the PR.
- A scripted scenario substitutes a deliberately non-idempotent handler and confirms that the inherited base-class property check fails on its first run.

## Inputs / Outputs

- Inputs:
  - `artifacts/benchmarks/baseline.json` — committed reference baseline consumed by stage 10.
  - Property-test seed and N replay count — fixture constructor arguments with documented defaults.
  - `FakeTimeProvider` instance — injected into every handler-under-test.
- Outputs:
  - Stage 10 PR-pipeline status (pass/block) and a diff report listing each benchmarked path with delta vs. baseline.
  - Property-test seed printed on every failing assertion.
- Config keys and defaults:
  - p99 latency regression threshold: 5% (T1 hot paths).
  - Allocation regression threshold: 10% (all benchmarked paths).
  - Default idempotency replay count N: 3.
- Versioning / backward-compatibility constraints:
  - `artifacts/benchmarks/baseline.json` is versioned via git history. Rebaselining requires an explicit PR that updates the file and records the justification in the PR description.

## API / CLI Surface

This feature ships test infrastructure and pipeline configuration; it does not introduce a user-facing CLI or HTTP surface.

- Benchmark execution: `dotnet run -c Release --project <repo>/<project-root>.Benchmarks` produces a BenchmarkDotNet results file that stage 10 consumes.
- Fixture surface: a public test base class exposing `RunIdempotencyProperty(handlerFactory, notification, replayCount)` and a derivable `SubscriptionHandlerTestBase<THandler>` that auto-invokes the property check.
- No public production-code API is added or modified by this feature.

## Data & State

- The benchmark baseline is the only persistent artifact introduced. It is committed under `artifacts/benchmarks/baseline.json` and updated by deliberate baseline PRs only.
- Test fixtures hold no persistent state between runs; all in-memory state is reset per test per the determinism rules in `.claude/rules/general-unit-test.md`.
- No database, file-system, or network state is created by this feature. The no-temporary-files rule from `.claude/rules/general-unit-test.md` applies to every fixture and property-test harness introduced here.
- No migration or backfill is required.

## Constraints & Risks

- Benchmarks must be deterministic and stable. Flaky benchmarks would erode trust in stage 10. The Benchmarks project must run on a fixed-config job and must not exercise wall-clock waits, real I/O, or shared mutable state.
- The property-test corpus must be seedable so any failure is reproducible. Seeds are printed on failure per the determinism rules in `.claude/rules/general-unit-test.md`.
- `FakeTimeProvider` is the only sanctioned clock substitute per `.claude/rules/general-unit-test.md`. Banned APIs (`Thread.Sleep`, `Task.Delay`, real `DateTime.UtcNow`, real `TimeProvider.System`) must not appear in any test code introduced by this feature.
- No production handler code is in scope. The Benchmarks project must not reference any handler code that does not yet exist; the delta-reconciliation benchmark is a documented placeholder pending Prompt G2.
- The no-temporary-files rule from `.claude/rules/general-unit-test.md` applies. Fixtures must not create temp files on disk.
- T1 hot path source of truth: Prompt D2 in `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` (lines 905–926). If Prompt D2 introduces new classifier code paths, the Benchmarks project must be extended to cover them before this feature is considered complete.

## Implementation Strategy

- Implementation scope:
  - Add one new `*.Benchmarks` C# project under the existing solution layout and classify it in `quality-tiers.yml` as T4 (test/scaffolding).
  - Add the idempotency fixture, property tests, and `SubscriptionHandlerTestBase` to the existing test project that targets worker-handler tests (or create one if none exists, classified T4).
  - Add pipeline stage 10 to the pre-merge workflow in the existing CI configuration.
  - Commit `artifacts/benchmarks/baseline.json` as part of this feature's merge.
- New classes/functions to add:
  - `<repo>.Benchmarks` project root with `ClassifierBenchmarks.cs` and a placeholder `DeltaReconciliationBenchmarks.cs` (disabled).
  - `SubscriptionHandlerTestBase<THandler>` with built-in idempotency property check.
  - `IdempotencyReplayFixture` exposing `RunIdempotencyProperty(...)`.
  - `DeltaReconciliationPropertyTests` covering out-of-order, duplicate, and missing-event sequences.
- Dependency changes:
  - Add `BenchmarkDotNet` package reference (test/benchmark tooling, established and widely used).
  - Add a property-based testing package consistent with the existing .NET test stack (e.g., `FsCheck.Xunit` or `CsCheck`). The selection must match whatever the existing `.NET` test infrastructure already uses; do not introduce a second property-test framework.
  - `Microsoft.Extensions.TimeProvider.Testing` for `FakeTimeProvider`.
- Logging / telemetry:
  - No production telemetry is added. Stage 10's diff report is the only operational output.
- Rollout plan:
  - Single merge. Stage 10 is enabled in PR pipeline immediately on merge. No feature flag.

## Acceptance Criteria

- [x] AC1: A new `*.Benchmarks` C# project exists, references BenchmarkDotNet, and exercises the classifier hot paths from Prompt D2.
- [x] AC2: `artifacts/benchmarks/baseline.json` is committed and contains the recorded baseline runs.
- [x] AC3: Pre-merge pipeline stage 10 compares PR results to the baseline and blocks on p99 latency regression > 5% on T1 hot paths or allocation regression > 10%.
- [x] AC4: An idempotency test fixture using `FakeTimeProvider` and a deterministic message-id seed asserts that running the same Graph-subscription notification N times produces the same post-state as a single execution.
- [x] AC5: Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences.
- [x] AC6: The subscription-handler test base class inherits an idempotency property check by default.
- [x] AC7: A 10% latency regression introduced on a benchmarked T1 hot path blocks the PR (validation scenario).
- [x] AC8: A deliberately non-idempotent handler is detected by the property test on its first run (validation scenario).

## Definition of Done

- [ ] Acceptance criteria documented and mapped to tests or demos
- [ ] Behavior matches acceptance criteria in all documented environments
- [ ] Tests updated/added (unit/property/integration as applicable)
- [ ] Edge cases and error handling covered by tests
- [ ] Docs updated (README, docs/features/active/... links)
- [ ] Telemetry/logging added or updated (if applicable — N/A here)
- [ ] Toolchain pass completed (format → lint → type-check → arch → unit → contract → integration)

## Seeded Test Conditions

- [ ] Unit/property tests for delta-reconciliation event sequence variations
- [ ] Integration test for the idempotency base-class hook detecting a non-idempotent handler
- [ ] Benchmark stage-10 validation by injecting a synthetic 10% latency regression on a benchmarked hot path

## Non-Goals

- No Phase G production handler code (subscription lifecycle, delta-reconciliation handler, background classification policies, retry handling, automation rule store).
- No live benchmark of the delta-reconciliation hot path until Prompt G2 introduces the underlying handler; a disabled placeholder benchmark is registered instead.
- No introduction of mutation testing, golden tests, or new contract gates as part of this feature (those are governed by other prompts).
