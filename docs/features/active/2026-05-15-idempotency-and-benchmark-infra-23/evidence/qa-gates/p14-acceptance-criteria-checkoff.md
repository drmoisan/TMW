# [P7-T10] Acceptance Criteria Checkoff Map

Timestamp: 2026-05-15T22-31

Sources: `spec.md` § Acceptance Criteria and `user-story.md` § Acceptance Criteria.

| AC  | Statement (abbreviated) | Evidence Artifact(s) |
|-----|--------------------------|----------------------|
| AC1 | `*.Benchmarks` C# project exists, references BenchmarkDotNet, exercises classifier hot paths from Prompt D2. | `evidence/other/p1-pkg-version-add.md`, `evidence/other/p1-benchmarks-build.md`, `evidence/other/p1-benchmarks-list.md`, `evidence/other/p2-benchmark-list.md` |
| AC2 | `artifacts/benchmarks/baseline.json` committed and contains recorded baseline runs. | `evidence/other/p2-baseline-capture.md`, `evidence/other/p2-schema-readme.md` |
| AC3 | Pre-merge stage 10 compares PR results to baseline and blocks on p99 > 5% on T1 or allocation > 10%. | `evidence/other/p3-comparator-self.md`, `evidence/other/p3-comparator-self-rows.md`, `evidence/other/p6-stage10-yaml.md` |
| AC4 | Idempotency test fixture using `FakeTimeProvider` and deterministic message-id seed asserts post-state equivalence after N replays. | `evidence/other/p4-base-build.md`, `evidence/other/p4-base-fact-marker.md`, `evidence/regression-testing/p4-sample-idempotent-pass.md` |
| AC5 | Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences. | `evidence/regression-testing/p5-property-tests-pass.md` |
| AC6 | Subscription-handler test base class inherits idempotency property check by default. | `evidence/other/p4-base-fact-marker.md`, `evidence/regression-testing/p4-sample-idempotent-pass.md` (derived class inherits and passes), `evidence/regression-testing/p5-self-validation-failing-as-expected.md` (derived non-idempotent class inherits and fails) |
| AC7 | Synthetic 10% latency regression on a benchmarked T1 hot path blocks the PR (validation scenario). | `evidence/regression-testing/p3-comparator-synthetic-fail.md`, `evidence/regression-testing/p5-latency-gate-self-test.md`, `evidence/qa-gates/p7-self-validation.md`, `evidence/other/p6-self-validation-job.md` |
| AC8 | Deliberately non-idempotent handler is detected by the property test on its first run (validation scenario). | `evidence/regression-testing/p5-self-validation-failing-as-expected.md`, `evidence/qa-gates/p7-self-validation.md`, `evidence/other/p6-self-validation-job.md` |

All eight ACs are mapped to evidence artifacts that exist under `<FEATURE>/evidence/` and have non-empty `Output Summary:` blocks.
