using System.Collections.Concurrent;
using TaskMaster.Application;

namespace TaskMaster.Infrastructure;

/// <summary>
/// In-memory implementation of <see cref="IUserSettingsRepository"/>.
/// Thread-safe via <see cref="ConcurrentDictionary{TKey,TValue}"/>.
/// Suitable for testing and local development scenarios where persistence is not required.
/// </summary>
public sealed class InMemoryUserSettingsRepository : IUserSettingsRepository
{
    private readonly ConcurrentDictionary<string, UserSettings> _store = new(
        StringComparer.Ordinal
    );
    private readonly TimeProvider _timeProvider;

    /// <param name="timeProvider">Clock used to set <see cref="UserSettings.LastModifiedAt"/>.</param>
    public InMemoryUserSettingsRepository(TimeProvider timeProvider)
    {
        ArgumentNullException.ThrowIfNull(timeProvider);
        _timeProvider = timeProvider;
    }

    /// <inheritdoc/>
    public Task<UserSettings?> GetAsync(string userId, CancellationToken ct = default)
    {
        _store.TryGetValue(userId, out var settings);
        return Task.FromResult<UserSettings?>(settings);
    }

    /// <inheritdoc/>
    public Task SaveAsync(UserSettings settings, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(settings);
        var timestamped = settings with { LastModifiedAt = _timeProvider.GetUtcNow() };
        _store[settings.UserId] = timestamped;
        return Task.CompletedTask;
    }

    /// <inheritdoc/>
    public Task DeleteAsync(string userId, CancellationToken ct = default)
    {
        _store.TryRemove(userId, out _);
        return Task.CompletedTask;
    }
}
