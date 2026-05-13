// CA1724 suppressed: the name 'UserSettings' conflicts with Microsoft.Graph.DeviceManagement.VirtualEndpoint.UserSettings
// (a namespace, not a type). Our type lives in TaskMaster.Application and there is no ambiguity at call sites.
#pragma warning disable CA1724

namespace TaskMaster.Application;

/// <summary>
/// Immutable record representing a user's TaskMaster settings.
/// </summary>
/// <param name="UserId">The unique identifier for the user (e.g. OID from Azure AD).</param>
/// <param name="NotificationsEnabled">Whether push notifications are enabled for this user.</param>
/// <param name="TriageEnabled">Whether the AI triage feature is enabled for this user.</param>
/// <param name="LastModifiedAt">
/// The UTC timestamp at which these settings were last persisted.
/// This value is set by <see cref="IUserSettingsRepository.SaveAsync"/> and must not be
/// supplied by callers.
/// </param>
public sealed record UserSettings(
    string UserId,
    bool NotificationsEnabled,
    bool TriageEnabled,
    DateTimeOffset LastModifiedAt
);
