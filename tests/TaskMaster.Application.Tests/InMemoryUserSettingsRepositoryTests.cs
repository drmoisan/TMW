using FluentAssertions;
using Microsoft.Extensions.Time.Testing;
using TaskMaster.Application;
using TaskMaster.Infrastructure;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Unit tests for <see cref="InMemoryUserSettingsRepository"/>.
/// All tests use <see cref="FakeTimeProvider"/> for clock injection.
/// No real I/O is performed.
/// </summary>
public sealed class InMemoryUserSettingsRepositoryTests
{
    private static InMemoryUserSettingsRepository CreateSut(FakeTimeProvider? clock = null) =>
        new(clock ?? new FakeTimeProvider());

    private static UserSettings MakeSettings(string userId = "user1") =>
        new(userId, NotificationsEnabled: true, TriageEnabled: false, LastModifiedAt: default);

    [Fact]
    public async Task GetAsync_WhenKeyAbsent_ReturnsNull()
    {
        // Arrange
        var sut = CreateSut();

        // Act
        var result = await sut.GetAsync("nonexistent").ConfigureAwait(true);

        // Assert
        result.Should().BeNull();
    }

    [Fact]
    public async Task SaveAsync_NewUser_CanBeRetrievedByGetAsync()
    {
        // Arrange
        var sut = CreateSut();
        var settings = MakeSettings("user2");

        // Act
        await sut.SaveAsync(settings).ConfigureAwait(true);
        var retrieved = await sut.GetAsync("user2").ConfigureAwait(true);

        // Assert
        retrieved.Should().NotBeNull();
        retrieved!.UserId.Should().Be("user2");
        retrieved.NotificationsEnabled.Should().BeTrue();
        retrieved.TriageEnabled.Should().BeFalse();
    }

    [Fact]
    public async Task SaveAsync_ExistingUser_OverwritesPreviousRecord()
    {
        // Arrange
        var sut = CreateSut();
        var original = MakeSettings("user3");
        await sut.SaveAsync(original).ConfigureAwait(true);
        var updated = original with { NotificationsEnabled = false };

        // Act
        await sut.SaveAsync(updated).ConfigureAwait(true);
        var retrieved = await sut.GetAsync("user3").ConfigureAwait(true);

        // Assert
        retrieved.Should().NotBeNull();
        retrieved!.NotificationsEnabled.Should().BeFalse();
    }

    [Fact]
    public async Task SaveAsync_SetsLastModifiedAt_ViaTimeProvider()
    {
        // Arrange
        var clock = new FakeTimeProvider();
        var expectedTime = new DateTimeOffset(2026, 1, 15, 12, 0, 0, TimeSpan.Zero);
        clock.SetUtcNow(expectedTime);
        var sut = CreateSut(clock);
        var settings = MakeSettings("user4");

        // Act
        await sut.SaveAsync(settings).ConfigureAwait(true);
        var retrieved = await sut.GetAsync("user4").ConfigureAwait(true);

        // Assert
        retrieved.Should().NotBeNull();
        retrieved!.LastModifiedAt.Should().Be(expectedTime);
    }

    [Fact]
    public async Task DeleteAsync_ExistingUser_RemovesRecord()
    {
        // Arrange
        var sut = CreateSut();
        var settings = MakeSettings("user5");
        await sut.SaveAsync(settings).ConfigureAwait(true);

        // Act
        await sut.DeleteAsync("user5").ConfigureAwait(true);
        var retrieved = await sut.GetAsync("user5").ConfigureAwait(true);

        // Assert
        retrieved.Should().BeNull();
    }

    [Fact]
    public Task DeleteAsync_AbsentUser_DoesNotThrow()
    {
        // Arrange
        var sut = CreateSut();

        // Act
        Func<Task> act = () => sut.DeleteAsync("nonexistent");

        // Assert
        return act.Should().NotThrowAsync();
    }
}
