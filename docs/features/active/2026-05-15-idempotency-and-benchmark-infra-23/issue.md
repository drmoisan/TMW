# idempotency-and-benchmark-infra (Issue #23)

- Date captured: 2026-05-15
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/idempotency-and-benchmark-infra/ (Issue #23)

- Issue: #23
- Issue URL: https://github.com/drmoisan/TMW/issues/23
- Last Updated: 2026-05-16
- Work Mode: full-feature

## Problem / Why

Phase G of the No-COM architecture migration replaces local event-driven processing with service-side Graph subscription processing. Without two specific quality gates in place before Phase G code lands, the resulting background-automation code is at risk of two classes of silent regression:

1. Non-idempotent Graph subscription handlers that re-process or double-apply state when a notification is redelivered, retried, or replayed.
2. Performance regressions on T1 classifier hot paths and the delta-reconciliation hot path that are invisible to functional tests.

Prompt G1 of the architecture migration (see `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md`) requires that idempotency property tests and benchmark regression gates be in place before any Phase G handler or worker code is written.

## Proposed Behavior

Stand up the two gates that protect Graph-subscription processing before background-automation code lands:

- A dedicated `*.Benchmarks` C# project that references BenchmarkDotNet and exercises the classifier hot paths identified in Prompt D2.
- A versioned baseline file at `artifacts/benchmarks/baseline.json` recording the reference benchmark results.
- Pre-merge pipeline stage 10 (benchmark regression) that compares each PR's benchmark run against the baseline and blocks the PR when p99 latency on T1 hot paths regresses by more than 5% or allocation regresses by more than 10%.
- A reusable idempotency test fixture that runs the same Graph-subscription notification through a worker handler N times and asserts the post-state equals the post-state after a single execution. The fixture uses `FakeTimeProvider` and a deterministic message-id seed.
- Property tests for delta-reconciliation covering out-of-order, duplicate, and missing-event sequences.
- An assertion hook on the subscription-handler test base class so any handler test inherits the idempotency property check.

## Acceptance Criteria (early draft)

- [ ] AC1: A new `*.Benchmarks` C# project exists, references BenchmarkDotNet, and exercises the classifier hot paths from Prompt D2.
- [ ] AC2: `artifacts/benchmarks/baseline.json` is committed and contains the recorded baseline runs.
- [ ] AC3: Pre-merge pipeline stage 10 compares PR results to the baseline and blocks on p99 latency regression > 5% on T1 hot paths or allocation regression > 10%.
- [ ] AC4: An idempotency test fixture using `FakeTimeProvider` and a deterministic message-id seed asserts that running the same Graph-subscription notification N times produces the same post-state as a single execution.
- [ ] AC5: Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences.
- [ ] AC6: The subscription-handler test base class inherits an idempotency property check by default.
- [ ] AC7: A 10% latency regression introduced on a benchmarked T1 hot path blocks the PR (validation scenario).
- [ ] AC8: A deliberately non-idempotent handler is detected by the property test on its first run (validation scenario).

## Constraints & Risks

- Benchmarks must be deterministic and stable; flaky benchmarks would erode trust in stage 10.
- Property test corpus must be seedable so failures are reproducible.
- `FakeTimeProvider` is the only sanctioned clock substitute per `.claude/rules/general-unit-test.md`.
- No production handler code is in scope for this prompt; this is gate-only infrastructure that lands ahead of Phase G implementation.

## Test Conditions to Consider

- [ ] Unit/property tests for delta-reconciliation event sequence variations
- [ ] Integration test for the idempotency base-class hook detecting a non-idempotent handler
- [ ] Benchmark stage-10 validation by injecting a synthetic 10% latency regression on a benchmarked hot path

## Next Step

- [x] Promote to GitHub issue (feature request template)
- [x] Create `docs/features/active/idempotency-and-benchmark-infra/` folder from the template