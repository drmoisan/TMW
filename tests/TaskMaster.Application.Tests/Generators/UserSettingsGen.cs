using CsCheck;
using TaskMaster.Application;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Provides a reusable CsCheck arbitrary generator for <see cref="UserSettings"/>.
/// </summary>
internal static class UserSettingsGen
{
    /// <summary>
    /// A CsCheck <see cref="Gen{T}"/> that produces random <see cref="UserSettings"/> instances.
    /// </summary>
    public static Gen<UserSettings> Arbitrary =>
        Gen.Select(
            Gen.String,
            Gen.Bool,
            Gen.Bool,
            Gen.DateTimeOffset,
            (userId, notif, triage, ts) =>
                new UserSettings(
                    UserId: userId ?? string.Empty,
                    NotificationsEnabled: notif,
                    TriageEnabled: triage,
                    LastModifiedAt: ts
                )
        );
}
