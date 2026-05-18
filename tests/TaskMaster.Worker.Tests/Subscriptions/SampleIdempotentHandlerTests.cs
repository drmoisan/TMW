namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Positive scenario: a deliberately idempotent handler. The inherited
/// <see cref="SubscriptionHandlerTestBase{THandler, TNotification, TState}.Idempotency_RepeatedDelivery_ProducesSinglePostState"/>
/// must pass for this class, demonstrating that the base-class hook does not
/// falsely flag well-behaved handlers as non-idempotent.
/// </summary>
public sealed class SampleIdempotentHandlerTests
    : SubscriptionHandlerTestBase<
        SampleIdempotentHandler,
        SampleNotification,
        IReadOnlyDictionary<string, int>
    >
{
    private InMemoryStateStore _store = new();
    private SampleIdempotentHandler _handler;

    public SampleIdempotentHandlerTests()
    {
        _handler = new SampleIdempotentHandler(_store);
    }

    protected override Task<SampleNotification> ArrangeAsync()
    {
        // Deterministic message-id seed.
        return Task.FromResult(new SampleNotification("msg-fixed-0001", "increment-counter"));
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
        _handler = new SampleIdempotentHandler(_store);
        return Task.CompletedTask;
    }
}
