namespace TaskMaster.Application;

/// <summary>
/// Persists user feedback on classification results for future classifier training.
/// </summary>
public interface ITrainingRepository
{
    /// <summary>
    /// Records a single piece of training feedback asynchronously.
    /// </summary>
    /// <param name="feedback">The training feedback to persist. Must not be null.</param>
    /// <param name="ct">A <see cref="CancellationToken"/> to observe.</param>
    /// <returns>A <see cref="Task"/> that completes when the feedback has been recorded.</returns>
    Task RecordAsync(TrainingFeedback feedback, CancellationToken ct = default);
}
