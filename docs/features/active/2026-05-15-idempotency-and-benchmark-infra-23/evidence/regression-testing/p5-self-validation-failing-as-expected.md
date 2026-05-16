# [P5-T2] Self-Validation Lane — NonIdempotentHandlerNegativeTests FAILS (expect-fail)

Timestamp: 2026-05-15T22-16
Command: `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "Category=benchmark-gate-self-validation" --nologo`
EXIT_CODE: 1 (failing test exit; expected for [expect-fail] task per plan)

Output Summary: 1 failed, 0 passed.
- Test: `TaskMaster.Worker.Tests.Subscriptions.NonIdempotentHandlerNegativeTests.Idempotency_RepeatedDelivery_ProducesSinglePostState`
- Failure: `Expected property root[0].Value to be 1, but found 5.`
- Cause: `NonIdempotentHandler.Handle` invokes `_store.Increment(messageId)`, so after 5 replays the counter is 5 while the single-run reference is 1. The inherited idempotency property check correctly flags the divergence.

This is the expected outcome that demonstrates AC8 (a deliberately non-idempotent handler is detected by the property test on its first run when invoked through the self-validation lane). The outer self-validation job in `[P6-T2]` will invert this exit so the job succeeds when the inner test fails as expected.

[expect-fail] evidence: a failing inner test is the intended signal here. Both default-lane exclusion ([P5-T2] sibling artifact) and explicit-lane failure are captured.
