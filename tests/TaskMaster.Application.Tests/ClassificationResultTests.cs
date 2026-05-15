using CsCheck;
using FluentAssertions;
using TaskMaster.Application;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Unit and property tests for <see cref="ClassificationResult"/>.
/// Verifies construction with valid confidence values and positional deconstruction.
/// </summary>
public sealed class ClassificationResultTests
{
    [Fact]
    public void Constructor_ConfidenceAtLowerBound_Succeeds()
    {
        // Arrange / Act
        var result = new ClassificationResult(ClassificationLabel.General, 0.0);

        // Assert
        result.Label.Should().Be(ClassificationLabel.General);
        result.Confidence.Should().Be(0.0);
    }

    [Fact]
    public void Constructor_ConfidenceAtUpperBound_Succeeds()
    {
        // Arrange / Act
        var result = new ClassificationResult(ClassificationLabel.HighPriority, 1.0);

        // Assert
        result.Label.Should().Be(ClassificationLabel.HighPriority);
        result.Confidence.Should().Be(1.0);
    }

    [Fact]
    public void Constructor_ConfidenceBelowZero_ThrowsArgumentOutOfRangeException()
    {
        // Arrange / Act
        var act = () => new ClassificationResult(ClassificationLabel.General, -0.01);

        // Assert
        act.Should().Throw<ArgumentOutOfRangeException>().WithParameterName("Confidence");
    }

    [Fact]
    public void Constructor_ConfidenceAboveOne_ThrowsArgumentOutOfRangeException()
    {
        // Arrange / Act
        var act = () => new ClassificationResult(ClassificationLabel.General, 1.01);

        // Assert
        act.Should().Throw<ArgumentOutOfRangeException>().WithParameterName("Confidence");
    }

    /// <summary>
    /// Property: any confidence in [0.0, 1.0] round-trips correctly through the record
    /// positional deconstruction.
    /// </summary>
    [Fact]
    public void ClassificationResult_AnyValidConfidence_RoundTripsDeconstruction()
    {
        Gen.Double[0.0, 1.0]
            .Sample(confidence =>
            {
                // Arrange
                var result = new ClassificationResult(ClassificationLabel.General, confidence);

                // Act
                var (label, actualConfidence) = result;

                // Assert
                label.Should().Be(ClassificationLabel.General);
                actualConfidence.Should().Be(confidence);
            });
    }
}
