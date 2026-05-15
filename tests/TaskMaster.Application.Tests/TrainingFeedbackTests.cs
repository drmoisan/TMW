using FluentAssertions;
using TaskMaster.Application;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Unit tests for <see cref="TrainingFeedback"/>.
/// Verifies construction and positional deconstruction.
/// </summary>
public sealed class TrainingFeedbackTests
{
    [Fact]
    public void Constructor_WithAllParameters_StoresValuesCorrectly()
    {
        // Arrange
        var recordedAt = new DateTimeOffset(2026, 5, 13, 10, 0, 0, TimeSpan.Zero);

        // Act
        var feedback = new TrainingFeedback(
            "msg-001",
            ClassificationLabel.General,
            true,
            recordedAt
        );

        // Assert
        feedback.MessageId.Should().Be("msg-001");
        feedback.Label.Should().Be(ClassificationLabel.General);
        feedback.Confirmed.Should().BeTrue();
        feedback.RecordedAt.Should().Be(recordedAt);
    }

    [Fact]
    public void With_UpdatesRecordedAt_LeavesOtherPropertiesUnchanged()
    {
        // Arrange
        var original = new TrainingFeedback(
            "msg-002",
            ClassificationLabel.HighPriority,
            false,
            DateTimeOffset.MinValue
        );
        var newTime = new DateTimeOffset(2026, 5, 13, 12, 0, 0, TimeSpan.Zero);

        // Act
        var updated = original with
        {
            RecordedAt = newTime,
        };

        // Assert
        updated.MessageId.Should().Be("msg-002");
        updated.Label.Should().Be(ClassificationLabel.HighPriority);
        updated.Confirmed.Should().BeFalse();
        updated.RecordedAt.Should().Be(newTime);
    }
}
