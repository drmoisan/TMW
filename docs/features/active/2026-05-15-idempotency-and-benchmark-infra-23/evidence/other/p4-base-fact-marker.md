# [P4-T4] Idempotency Fact Method Marker

Timestamp: 2026-05-15T22-09
Command: `pwsh -NoProfile -Command "Select-String -Path 'tests/TaskMaster.Worker.Tests/Subscriptions/SubscriptionHandlerTestBase.cs' -Pattern 'Idempotency_RepeatedDelivery_ProducesSinglePostState'"`
EXIT_CODE: 0
Output:
- Line 10 (XML doc reference)
- Line 68: `public async Task Idempotency_RepeatedDelivery_ProducesSinglePostState()`
Output Summary: The `[Fact] public async Task Idempotency_RepeatedDelivery_ProducesSinglePostState()` method is present on the base class. It invokes ArrangeAsync, ActAsync (single run + N replays under FakeTimeProvider), CaptureStateAsync, and asserts equivalence via `FluentAssertions.BeEquivalentTo`.
