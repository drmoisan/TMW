namespace TaskMaster.Classifier.Tests;

/// <summary>
/// Represents a classifier corpus fixture file used by golden tests.
/// </summary>
internal sealed record CorpusFixture(string MessageId, string Subject, string? BodyPreview);
