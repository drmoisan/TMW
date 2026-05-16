# Phase 0 — Inputs Read

Timestamp: 2026-05-15T21-46

Files Read:
- docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/issue.md (lines 1-59)
- docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/spec.md (lines 1-137)
- docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/user-story.md (lines 1-65)
- src/TaskMaster.Classifier/KeywordClassifier.cs (Prompt D2 hot-path reference)
- src/TaskMaster.Classifier/TaskMaster.Classifier.csproj (target framework alignment)

Acceptance Criteria (transcribed verbatim from spec.md `## Acceptance Criteria`):

- AC1: A new `*.Benchmarks` C# project exists, references BenchmarkDotNet, and exercises the classifier hot paths from Prompt D2.
- AC2: `artifacts/benchmarks/baseline.json` is committed and contains the recorded baseline runs.
- AC3: Pre-merge pipeline stage 10 compares PR results to the baseline and blocks on p99 latency regression > 5% on T1 hot paths or allocation regression > 10%.
- AC4: An idempotency test fixture using `FakeTimeProvider` and a deterministic message-id seed asserts that running the same Graph-subscription notification N times produces the same post-state as a single execution.
- AC5: Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences.
- AC6: The subscription-handler test base class inherits an idempotency property check by default.
- AC7: A 10% latency regression introduced on a benchmarked T1 hot path blocks the PR (validation scenario).
- AC8: A deliberately non-idempotent handler is detected by the property test on its first run (validation scenario).

EXIT_CODE: 0
Output Summary: All input docs read; AC1–AC8 transcribed for traceability.
