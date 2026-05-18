# [P5-T2] Default Lane Excludes Self-Validation Tests

Timestamp: 2026-05-15T22-16
Command: `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "Category!=benchmark-gate-self-validation" --nologo`
EXIT_CODE: 0
Output Summary: 4 passed, 0 failed. The default lane runs only:
- SampleIdempotentHandlerTests.Idempotency_RepeatedDelivery_ProducesSinglePostState
- DeltaReconciliationPropertyTests.OutOfOrder_ProducesSameState
- DeltaReconciliationPropertyTests.Duplicates_AreIdempotent
- DeltaReconciliationPropertyTests.Missing_EventsAreDetected

`NonIdempotentHandlerNegativeTests` is decorated with `[Trait("Category","benchmark-gate-self-validation")]` and is excluded by the filter; default-lane CI does not see it as a failure.
