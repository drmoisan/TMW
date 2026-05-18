namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Deliberately idempotent sample handler used by
/// <see cref="SampleIdempotentHandlerTests"/>. The handler keys application by
/// MessageId so repeated delivery of the same notification produces the same
/// state as a single delivery.
/// </summary>
public sealed class SampleIdempotentHandler
{
    private readonly InMemoryStateStore _store;

    public SampleIdempotentHandler(InMemoryStateStore store)
    {
        ArgumentNullException.ThrowIfNull(store);
        _store = store;
    }

    public void Handle(SampleNotification notification)
    {
        ArgumentNullException.ThrowIfNull(notification);
        _store.MarkApplied(notification.MessageId);
    }
}
