namespace TaskMaster.Application;

/// <summary>
/// Classifies a mail message snapshot into a labeled category with a confidence score.
/// </summary>
public interface IMessageClassifier
{
    /// <summary>
    /// Classifies the given mail message snapshot.
    /// </summary>
    /// <param name="snapshot">The mail message snapshot to classify. Must not be null.</param>
    /// <returns>A <see cref="ClassificationResult"/> containing the predicted label and confidence.</returns>
    ClassificationResult Classify(MailMessageSnapshot snapshot);
}
