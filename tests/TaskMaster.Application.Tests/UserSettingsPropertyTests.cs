using System.Text.Json;
using CsCheck;
using FluentAssertions;
using TaskMaster.Application;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Property-based tests for <see cref="UserSettings"/> using CsCheck.
/// Required by T2 policy: at least one property test per pure function.
/// </summary>
public sealed class UserSettingsPropertyTests
{
    private static readonly JsonSerializerOptions s_jsonOptions = new(JsonSerializerDefaults.Web);

    /// <summary>
    /// Property: round-trip serialization of any valid <see cref="UserSettings"/> instance
    /// preserves all fields exactly.
    /// </summary>
    [Fact]
    public void UserSettings_RoundTripSerialization_PreservesAllFields()
    {
        Gen.Select(Gen.String, Gen.Bool, Gen.Bool, Gen.DateTimeOffset)
            .Sample(
                (userId, notif, triage, ts) =>
                {
                    // Arrange
                    var original = new UserSettings(
                        UserId: userId ?? string.Empty,
                        NotificationsEnabled: notif,
                        TriageEnabled: triage,
                        LastModifiedAt: ts
                    );

                    // Act
                    var json = JsonSerializer.Serialize(original, s_jsonOptions);
                    var deserialized = JsonSerializer.Deserialize<UserSettings>(
                        json,
                        s_jsonOptions
                    );

                    // Assert
                    deserialized.Should().NotBeNull();
                    deserialized!.UserId.Should().Be(original.UserId);
                    deserialized.NotificationsEnabled.Should().Be(original.NotificationsEnabled);
                    deserialized.TriageEnabled.Should().Be(original.TriageEnabled);
                    deserialized.LastModifiedAt.Should().Be(original.LastModifiedAt);
                }
            );
    }
}
