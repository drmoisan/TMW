namespace TaskMaster.Worker.Tests.Subscriptions;

/// <summary>
/// Deterministic in-memory notification record used by the sample idempotent
/// and non-idempotent handler test classes.
/// </summary>
public sealed record SampleNotification(string MessageId, string Operation);
