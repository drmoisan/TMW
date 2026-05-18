namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Minimal deterministic in-memory store used by sample handler tests. The
/// store records the set of message ids it has observed; idempotent handlers
/// produce the same snapshot regardless of how many times they observe the
/// same id, while non-idempotent handlers diverge.
/// </summary>
public sealed class InMemoryStateStore
{
    private readonly HashSet<string> _appliedIds = new(StringComparer.Ordinal);
    private readonly Dictionary<string, int> _counters = new(StringComparer.Ordinal);

    public void MarkApplied(string messageId)
    {
        _appliedIds.Add(messageId);
    }

    public void Increment(string messageId)
    {
        if (_counters.TryGetValue(messageId, out var count))
        {
            _counters[messageId] = count + 1;
        }
        else
        {
            _counters[messageId] = 1;
        }
    }

    public IReadOnlyDictionary<string, int> Snapshot()
    {
        var snapshot = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (var id in _appliedIds)
        {
            snapshot[id] = 1;
        }
        foreach (var kvp in _counters)
        {
            snapshot[kvp.Key] = kvp.Value;
        }
        return snapshot;
    }
}
