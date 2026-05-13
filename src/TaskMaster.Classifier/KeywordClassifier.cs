using TaskMaster.Application;

namespace TaskMaster.Classifier;

/// <summary>
/// Classifies mail messages by matching keywords in the subject line and body preview.
/// </summary>
public sealed class KeywordClassifier : IMessageClassifier
{
    private static readonly (string Keyword, string Label, double Confidence)[] Rules =
    [
        ("urgent", ClassificationLabel.HighPriority, 0.90),
        ("action required", ClassificationLabel.HighPriority, 0.85),
        ("unsubscribe", ClassificationLabel.Promotional, 0.90),
        ("newsletter", ClassificationLabel.Promotional, 0.85),
    ];

    /// <inheritdoc />
    public ClassificationResult Classify(MailMessageSnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(snapshot);

        foreach (var (keyword, label, confidence) in Rules)
        {
            if (snapshot.Subject.Contains(keyword, StringComparison.OrdinalIgnoreCase))
            {
                return new ClassificationResult(label, confidence);
            }
        }

        if (snapshot.BodyPreview is not null)
        {
            foreach (var (keyword, label, confidence) in Rules)
            {
                if (snapshot.BodyPreview.Contains(keyword, StringComparison.OrdinalIgnoreCase))
                {
                    return new ClassificationResult(label, confidence - 0.10);
                }
            }
        }

        return new ClassificationResult(ClassificationLabel.General, 0.50);
    }
}
