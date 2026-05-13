namespace TaskMaster.Application;

/// <summary>
/// Persistence contract for <see cref="UserSettings"/>.
/// Implementations must be thread-safe for concurrent access.
/// </summary>
public interface IUserSettingsRepository
{
    /// <summary>
    /// Retrieves settings for the specified user, or <c>null</c> if no settings exist.
    /// </summary>
    Task<UserSettings?> GetAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Persists (creates or replaces) the given settings.
    /// Implementations must set <see cref="UserSettings.LastModifiedAt"/> to the current UTC time.
    /// </summary>
    Task SaveAsync(UserSettings settings, CancellationToken ct = default);

    /// <summary>
    /// Removes settings for the specified user. A no-op if the user has no saved settings.
    /// </summary>
    Task DeleteAsync(string userId, CancellationToken ct = default);
}
