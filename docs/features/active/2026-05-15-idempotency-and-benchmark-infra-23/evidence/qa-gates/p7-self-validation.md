# [P7-T8] Self-Validation Suite Execution

Timestamp: 2026-05-15T22-30
Commands and results:

1. `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "Category=benchmark-gate-self-validation&FullyQualifiedName~LatencyRegressionGateTests" --nologo`
   - dotnet test exit code: 0
   - Inner result: 1 passed, 0 failed.
   - Assertion: `LatencyRegressionGateTests.Comparator_OnSyntheticLatencyRegressionFixture_ExitsNonZero` confirms the comparator returns non-zero on the synthetic +10% p99 fixture (AC7).

2. `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "Category=benchmark-gate-self-validation&FullyQualifiedName~NonIdempotentHandlerNegativeTests" --nologo`
   - dotnet test exit code: 1 (expected; inverted by the self-validation job)
   - Inner result: 1 FAILED, 0 passed.
   - Failure message: `Expected property root[0].Value to be 1, but found 5.` (5 replays through `NonIdempotentHandler.Increment(messageId)` produced count=5 vs single-run count=1).
   - This proves AC8: the inherited idempotency check on `SubscriptionHandlerTestBase` detects a deliberately non-idempotent handler on its first run.

EXIT_CODE: 0 (both inner assertions match expectations; the benchmark-gate-self-validation job in pr-pipeline.yml inverts NonIdempotentHandlerNegativeTests' exit so the CI job succeeds when the gate fires as designed)

Output Summary: Both self-validation negative paths are confirmed locally. AC7 and AC8 are satisfied by the evidence above.
