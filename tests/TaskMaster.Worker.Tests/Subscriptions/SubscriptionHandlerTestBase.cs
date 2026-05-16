using FluentAssertions;
using Microsoft.Extensions.Time.Testing;
using Xunit;

namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Base class for Graph-subscription handler tests. Derived test classes
/// inherit the idempotency property check
/// <see cref="Idempotency_RepeatedDelivery_ProducesSinglePostState"/> by
/// default. The check arranges the handler under a deterministic
/// <see cref="FakeTimeProvider"/>, runs <see cref="ActAsync"/> once to
/// capture the reference state, then re-runs the same notification N times
/// and asserts the post-state is equivalent to the single-execution state.
/// </summary>
/// <typeparam name="THandler">The handler type under test.</typeparam>
/// <typeparam name="TNotification">The notification type the handler receives.</typeparam>
/// <typeparam name="TState">The captured post-state type used for equivalence comparison.</typeparam>
public abstract class SubscriptionHandlerTestBase<THandler, TNotification, TState>
{
    /// <summary>
    /// Deterministic time provider injected into the handler under test.
    /// Initialized at construction to UTC 2026-05-15T00:00:00Z. Derived tests
    /// may advance simulated time by calling <c>Clock.Advance(...)</c>.
    /// </summary>
    protected FakeTimeProvider Clock { get; } =
        new FakeTimeProvider(new DateTimeOffset(2026, 5, 15, 0, 0, 0, TimeSpan.Zero));

    /// <summary>
    /// Number of replay invocations performed by the idempotency property.
    /// Defaults to 5 per the plan's stronger-detection default; derived
    /// fixtures may reduce this to the spec minimum of 3 by overriding the
    /// property.
    /// </summary>
    protected virtual int ReplayCount => 5;

    /// <summary>
    /// Arranges the test scenario: constructs the handler, seeds any
    /// in-memory state stores, and prepares the deterministic notification
    /// identity. Returns the notification under test.
    /// </summary>
    protected abstract Task<TNotification> ArrangeAsync();

    /// <summary>
    /// Executes a single delivery of the notification through the handler.
    /// </summary>
    protected abstract Task ActAsync(TNotification notification);

    /// <summary>
    /// Captures the post-state that must be equivalent after one execution
    /// and after N replays for the handler to be considered idempotent.
    /// </summary>
    protected abstract Task<TState> CaptureStateAsync();

    /// <summary>
    /// Resets the handler state between the single-run and replay-run
    /// passes. Derived classes typically rebuild any in-memory store so the
    /// replay run starts from the same initial state as the single run.
    /// </summary>
    protected abstract Task ResetStateAsync();

    /// <summary>
    /// Inherited idempotency property: a single delivery and N replays of
    /// the same notification must produce equivalent post-state.
    /// </summary>
    [Fact]
    public async Task Idempotency_RepeatedDelivery_ProducesSinglePostState()
    {
        var notification = await ArrangeAsync();

        await ActAsync(notification);
        var singleRunState = await CaptureStateAsync();

        await ResetStateAsync();

        var replayCount = ReplayCount;
        if (replayCount < 3)
        {
            throw new InvalidOperationException(
                "ReplayCount must be at least 3 per the idempotency spec."
            );
        }

        for (var i = 0; i < replayCount; i++)
        {
            await ActAsync(notification);
        }
        var replayState = await CaptureStateAsync();

        replayState.Should().BeEquivalentTo(singleRunState);
    }
}
