using Xunit;

namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Negative scenario for AC8: a deliberately non-idempotent handler. The
/// inherited <see cref="SubscriptionHandlerTestBase{THandler, TNotification, TState}.Idempotency_RepeatedDelivery_ProducesSinglePostState"/>
/// is expected to fail when this test class is exercised through the
/// benchmark-gate-self-validation lane. The class is decorated with
/// <c>[Trait("Category","benchmark-gate-self-validation")]</c> so the default
/// test lane (which filters <c>Category!=benchmark-gate-self-validation</c>)
/// excludes it; only the dedicated self-validation job invokes it.
/// </summary>
[Trait("Category", "benchmark-gate-self-validation")]
public sealed class NonIdempotentHandlerNegativeTests
    : SubscriptionHandlerTestBase<
        NonIdempotentHandler,
        SampleNotification,
        IReadOnlyDictionary<string, int>
    >
{
    private InMemoryStateStore _store = new();
    private NonIdempotentHandler _handler;

    public NonIdempotentHandlerNegativeTests()
    {
        _handler = new NonIdempotentHandler(_store);
    }

    protected override Task<SampleNotification> ArrangeAsync()
    {
        return Task.FromResult(new SampleNotification("msg-fixed-0002", "increment-counter"));
    }

    protected override Task ActAsync(SampleNotification notification)
    {
        _handler.Handle(notification);
        return Task.CompletedTask;
    }

    protected override Task<IReadOnlyDictionary<string, int>> CaptureStateAsync()
    {
        return Task.FromResult<IReadOnlyDictionary<string, int>>(_store.Snapshot());
    }

    protected override Task ResetStateAsync()
    {
        _store = new InMemoryStateStore();
        _handler = new NonIdempotentHandler(_store);
        return Task.CompletedTask;
    }
}
