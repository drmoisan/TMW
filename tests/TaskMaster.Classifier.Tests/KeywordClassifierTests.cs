using CsCheck;
using FluentAssertions;
using TaskMaster.Application;
using TaskMaster.Classifier.Tests.Generators;

namespace TaskMaster.Classifier.Tests;

/// <summary>
/// Unit and property tests for <see cref="KeywordClassifier"/>.
/// Covers each keyword rule, the General fallback, and confidence invariants.
/// </summary>
public sealed class KeywordClassifierTests
{
    private readonly KeywordClassifier _sut = new();

    [Fact]
    public void Classify_UrgentInSubject_ReturnsHighPriorityAt090()
    {
        // Arrange
        var snapshot = MailMessageSnapshot.Create("id", "URGENT: please respond", null);

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.HighPriority);
        result.Confidence.Should().Be(0.90);
    }

    [Fact]
    public void Classify_ActionRequiredInSubject_ReturnsHighPriorityAt085()
    {
        // Arrange
        var snapshot = MailMessageSnapshot.Create("id", "Action Required by Friday", null);

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.HighPriority);
        result.Confidence.Should().Be(0.85);
    }

    [Fact]
    public void Classify_UnsubscribeInSubject_ReturnsPromotionalAt090()
    {
        // Arrange
        var snapshot = MailMessageSnapshot.Create("id", "Click here to Unsubscribe", null);

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.Promotional);
        result.Confidence.Should().Be(0.90);
    }

    [Fact]
    public void Classify_NewsletterInSubject_ReturnsPromotionalAt085()
    {
        // Arrange
        var snapshot = MailMessageSnapshot.Create("id", "Monthly Newsletter — June 2026", null);

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.Promotional);
        result.Confidence.Should().Be(0.85);
    }

    [Fact]
    public void Classify_UnrecognizedSubject_ReturnsGeneralAt050()
    {
        // Arrange
        var snapshot = MailMessageSnapshot.Create("id", "Meeting notes from yesterday", null);

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.General);
        result.Confidence.Should().Be(0.50);
    }

    [Fact]
    public void Classify_NullSnapshot_ThrowsArgumentNullException()
    {
        // Arrange / Act
        var act = () => _sut.Classify(null!);

        // Assert
        act.Should().Throw<ArgumentNullException>().WithParameterName("snapshot");
    }

    [Fact]
    public void Classify_NullBodyPreview_DoesNotThrow()
    {
        // Arrange
        var snapshot = MailMessageSnapshot.Create("id", "Ordinary subject", null);

        // Act
        var act = () => _sut.Classify(snapshot);

        // Assert
        act.Should().NotThrow();
    }

    [Fact]
    public void Classify_UrgentInBodyPreviewNoSubjectMatch_ReturnsHighPriorityAt080()
    {
        // Arrange — keyword in body only; confidence is reduced by 0.10 versus subject match.
        var snapshot = MailMessageSnapshot.Create(
            "id",
            "FYI from the team",
            "This is URGENT, please review before EOD."
        );

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.HighPriority);
        result.Confidence.Should().Be(0.80);
    }

    [Fact]
    public void Classify_UnrecognizedSubjectAndBody_ReturnsGeneralAt050()
    {
        // Arrange — no keyword in either subject or body.
        var snapshot = MailMessageSnapshot.Create(
            "id",
            "Team sync tomorrow",
            "Looking forward to catching up with everyone."
        );

        // Act
        var result = _sut.Classify(snapshot);

        // Assert
        result.Label.Should().Be(ClassificationLabel.General);
        result.Confidence.Should().Be(0.50);
    }

    /// <summary>
    /// Property: for any valid snapshot the confidence is always in [0.0, 1.0].
    /// </summary>
    [Fact]
    public void Classify_AnyValidSnapshot_ConfidenceInRange()
    {
        Gen.Select(
                Gen.String[1, 50],
                Gen.String[1, 50],
                (messageId, subject) => MailMessageSnapshot.Create(messageId, subject, null)
            )
            .Sample(snapshot =>
            {
                var result = _sut.Classify(snapshot);
                result.Confidence.Should().BeGreaterThanOrEqualTo(0.0);
                result.Confidence.Should().BeLessThanOrEqualTo(1.0);
            });
    }

    /// <summary>
    /// Property: trimmed and untrimmed identical subjects produce identical results.
    /// </summary>
    [Fact]
    public void Classify_TrimmedVsUntrimmedSubject_ProduceIdenticalResults()
    {
        MailMessageSnapshotGen.Arbitrary.Sample(snapshot =>
        {
            var paddedSnapshot = MailMessageSnapshot.Create(
                snapshot.MessageId,
                $"  {snapshot.Subject}  ",
                snapshot.BodyPreview
            );

            var result = _sut.Classify(snapshot);
            var paddedResult = _sut.Classify(paddedSnapshot);

            result.Label.Should().Be(paddedResult.Label);
            result.Confidence.Should().Be(paddedResult.Confidence);
        });
    }
}
