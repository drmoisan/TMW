using System.Text.Json;
using TaskMaster.Application;
using TaskMaster.Classifier;

namespace TaskMaster.Classifier.Tests;

/// <summary>
/// Golden tests for <see cref="KeywordClassifier"/> against versioned corpus fixtures.
/// Each fixture is loaded from the corpus directory and classified; results are compared
/// against committed <c>.verified.json</c> snapshots.
/// </summary>
public sealed class KeywordClassifierGoldenTests
{
    private static readonly KeywordClassifier s_classifier = new();

    private static readonly JsonSerializerOptions s_options = new(JsonSerializerDefaults.Web)
    {
        PropertyNameCaseInsensitive = true,
    };

    [Theory]
    [InlineData("urgent-meeting-001.json")]
    [InlineData("newsletter-promo-001.json")]
    [InlineData("team-update-001.json")]
    public async Task Classify_CorpusFixture_MatchesVerifiedOutput(string filename)
    {
        // Arrange
        var corpusPath = Path.Combine(
            AppContext.BaseDirectory,
            "..",
            "..",
            "..",
            "..",
            "..",
            "corpus",
            "classifiers",
            "keyword",
            filename
        );
        var json = await File.ReadAllTextAsync(corpusPath, TestContext.Current.CancellationToken)
            .ConfigureAwait(true);
        var fixture =
            JsonSerializer.Deserialize<CorpusFixture>(json, s_options)
            ?? throw new InvalidOperationException(
                $"Failed to deserialize corpus fixture: {filename}"
            );

        var snapshot = MailMessageSnapshot.Create(
            fixture.MessageId,
            fixture.Subject,
            fixture.BodyPreview
        );

        // Act
        var result = s_classifier.Classify(snapshot);

        // Assert (golden)
        await Verify(result).UseParameters(filename).ConfigureAwait(true);
    }
}
