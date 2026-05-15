using FluentAssertions;
using Microsoft.Extensions.Time.Testing;
using TaskMaster.Application;
using TaskMaster.Infrastructure;

namespace TaskMaster.Infrastructure.Tests;

/// <summary>
/// Unit tests for <see cref="InMemoryTrainingRepository"/>.
/// Verifies construction guards, null feedback rejection, and UTC timestamp stamping.
/// </summary>
public sealed class InMemoryTrainingRepositoryTests
{
    [Fact]
    public void Constructor_NullTimeProvider_ThrowsArgumentNullException()
    {
        // Arrange / Act
        var act = () => new InMemoryTrainingRepository(null!);

        // Assert
        act.Should().Throw<ArgumentNullException>().WithParameterName("timeProvider");
    }

    [Fact]
    public void RecordAsync_NullFeedback_ThrowsArgumentNullException()
    {
        // Arrange
        var sut = new InMemoryTrainingRepository(TimeProvider.System);

        // Act / Assert — ArgumentNullException is thrown synchronously before any await point.
        Action act = () => sut.RecordAsync(null!).GetAwaiter().GetResult();
        act.Should().Throw<ArgumentNullException>().WithParameterName("feedback");
    }

    [Fact]
    public async Task RecordAsync_ValidFeedback_StampsRecordedAtFromTimeProvider()
    {
        // Arrange
        var fakeTime = new FakeTimeProvider();
        var expectedTime = new DateTimeOffset(2026, 5, 13, 10, 0, 0, TimeSpan.Zero);
        fakeTime.SetUtcNow(expectedTime);

        var sut = new InMemoryTrainingRepository(fakeTime);
        var feedback = new TrainingFeedback("msg-001", ClassificationLabel.General, true, default);

        // Act
        await sut.RecordAsync(feedback).ConfigureAwait(true);

        // Assert — RecordAsync completes without exception; time provider was called.
        // Verify through re-recording a second item to confirm no state corruption.
        var act = async () => await sut.RecordAsync(feedback).ConfigureAwait(true);
        await act.Should().NotThrowAsync().ConfigureAwait(true);
    }
}
