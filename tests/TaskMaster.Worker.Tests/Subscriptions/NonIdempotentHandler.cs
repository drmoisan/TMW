namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Deliberately non-idempotent sample handler used by
/// <see cref="NonIdempotentHandlerNegativeTests"/>. Each delivery increments a
/// counter keyed by MessageId, so repeated delivery of the same notification
/// produces divergent state from a single delivery. The inherited idempotency
/// property check is expected to FAIL on this handler when invoked through
/// the benchmark-gate-self-validation lane, proving the gate detects
/// non-idempotent handlers (AC8).
/// </summary>
public sealed class NonIdempotentHandler
{
    private readonly InMemoryStateStore _store;

    public NonIdempotentHandler(InMemoryStateStore store)
    {
        ArgumentNullException.ThrowIfNull(store);
        _store = store;
    }

    public void Handle(SampleNotification notification)
    {
        ArgumentNullException.ThrowIfNull(notification);
        _store.Increment(notification.MessageId);
    }
}
