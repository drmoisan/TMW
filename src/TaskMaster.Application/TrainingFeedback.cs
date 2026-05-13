namespace TaskMaster.Application;

/// <summary>
/// Represents user feedback on a classification result, used to improve classifier training.
/// </summary>
/// <param name="MessageId">The unique identifier of the mail message that was classified.</param>
/// <param name="Label">The classification label the user confirmed or rejected.</param>
/// <param name="Confirmed">
/// <see langword="true"/> when the user confirmed the classification is correct;
/// <see langword="false"/> when the user rejected it.
/// </param>
/// <param name="RecordedAt">The UTC timestamp at which this feedback was recorded.</param>
public sealed record TrainingFeedback(
    string MessageId,
    string Label,
    bool Confirmed,
    DateTimeOffset RecordedAt
);
