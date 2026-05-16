# `idempotency-and-benchmark-infra` — User Story

- Issue: #23
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-15

## Story Statement

- As the platform maintainer responsible for the No-COM migration, I want idempotency property tests and a benchmark regression gate in place before Phase G handler code is written, so that the first Graph-subscription handler PR is evaluated against gates that are already proven to catch double-application and silent latency or allocation regressions.
- As a future Phase G contributor, I want a subscription-handler test base class that automatically applies an idempotency property check, so that I cannot accidentally merge a non-idempotent handler even if I forget to write a dedicated idempotency test.

## Problem / Why

Phase G of the No-COM architecture migration (`docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` lines 522–542) replaces local event-driven processing with service-side Graph subscription processing. Without two gates in place before that code lands, two silent regression classes are possible:

1. Non-idempotent Graph subscription handlers that re-process or double-apply state when a notification is redelivered, retried, or replayed.
2. Performance regressions on T1 classifier hot paths and the delta-reconciliation hot path that functional tests will not detect.

Prompt G1 (`docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` lines 1007–1029) requires that idempotency property tests and benchmark regression gates exist before any Phase G handler or worker code is authored. This feature delivers those gates as infrastructure-only changes; no production handler code is in scope.

## Personas & Scenarios

- Persona: Platform maintainer (the No-COM migration owner).
  - Who they are: the engineer responsible for sequencing the Phase G prompts and approving the architecture migration milestones.
  - What they care about: that quality gates land before the implementation they are meant to gate, so that downstream PRs are measured against gates from the first commit rather than retrofitted later.
  - Constraints: must follow the prompt sequencing in the No-COM migration document; cannot introduce production handler code in this feature; must respect the determinism rules in `.claude/rules/general-unit-test.md` and the uniform coverage thresholds in `.claude/rules/quality-tiers.md`.
  - Goals and frustrations: wants a single merge that turns on stage 10 and the idempotency base-class hook. Past frustration: gates added after the implementation they were meant to protect often surface regressions in older commits, complicating bisection.
  - Context and motivations: this feature is the precondition for Prompt G2; without it, Phase G is blocked.

- Persona: Future Phase G contributor.
  - Who they are: the engineer who will write the first Graph-subscription handler under Prompt G2.
  - What they care about: that they can author a handler test by deriving from `SubscriptionHandlerTestBase<THandler>` and inherit the idempotency property check without having to remember to add it.
  - Constraints: must not introduce wall-clock waits, real I/O, or temporary files in tests; must use `FakeTimeProvider`.
  - Goals and frustrations: wants the gate to be hard to bypass accidentally; wants reproducible seeds on failure so that an out-of-order delta failure is fixable without manual reproduction work.

- Scenario: A Phase G handler PR is opened.
  - Trigger: the future contributor opens a PR adding a new Graph-subscription handler and its test class derived from `SubscriptionHandlerTestBase<THandler>`.
  - Steps: CI runs the standard toolchain. The base class's inherited idempotency property check runs the handler under the `IdempotencyReplayFixture` with N >= 3 replays, a deterministic message-id seed, and `FakeTimeProvider`. Stage 10 runs the `*.Benchmarks` project and diffs the result against `artifacts/benchmarks/baseline.json`.
  - Obstacles or decisions: if the handler is non-idempotent, the property check fails and the seed is printed. If the handler change inadvertently regresses a classifier hot path by more than 5% p99 or more than 10% allocation, stage 10 blocks the PR.
  - Expected outcome: the PR merges only when both gates pass. The contributor did not need to write a separate idempotency test; the base class supplied it.

- Scenario: Validating the gates before they protect real code.
  - Trigger: this feature's own PR seeds two validation runs in CI.
  - Steps: one CI job injects a synthetic 10% latency regression on a benchmarked T1 hot path and confirms stage 10 blocks the PR. A second CI job substitutes a deliberately non-idempotent handler and confirms the inherited property check fails on its first run.
  - Expected outcome: both gates are demonstrated to fire before any Phase G implementation depends on them.

## Acceptance Criteria

- [x] AC1: A new `*.Benchmarks` C# project exists, references BenchmarkDotNet, and exercises the classifier hot paths from Prompt D2.
- [x] AC2: `artifacts/benchmarks/baseline.json` is committed and contains the recorded baseline runs.
- [x] AC3: Pre-merge pipeline stage 10 compares PR results to the baseline and blocks on p99 latency regression > 5% on T1 hot paths or allocation regression > 10%.
- [x] AC4: An idempotency test fixture using `FakeTimeProvider` and a deterministic message-id seed asserts that running the same Graph-subscription notification N times produces the same post-state as a single execution.
- [x] AC5: Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences.
- [x] AC6: The subscription-handler test base class inherits an idempotency property check by default.
- [x] AC7: A 10% latency regression introduced on a benchmarked T1 hot path blocks the PR (validation scenario).
- [x] AC8: A deliberately non-idempotent handler is detected by the property test on its first run (validation scenario).

## Non-Goals

- No Phase G production handler code (subscription lifecycle, delta-reconciliation handler, background classification, retry handling, automation rule store).
- No live benchmark of the delta-reconciliation hot path until Prompt G2 introduces the underlying handler; a disabled placeholder benchmark is registered with a `TODO(G2)` marker instead.
- No new mutation, golden, or contract-test infrastructure; those gates are governed by other prompts.
- No re-baselining workflow automation; baseline updates are deliberate, human-approved PRs.
