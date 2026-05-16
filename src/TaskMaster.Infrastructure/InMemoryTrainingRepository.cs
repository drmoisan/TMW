using System.Collections.Concurrent;
using TaskMaster.Application;
using TaskMaster.Infrastructure.Validation;

namespace TaskMaster.Infrastructure;

/// <summary>
/// In-memory implementation of <see cref="ITrainingRepository"/>.
/// Stores training feedback in a thread-safe queue for the lifetime of the process.
/// </summary>
internal sealed class InMemoryTrainingRepository : ITrainingRepository
{
    private readonly ConcurrentQueue<TrainingFeedback> _queue = new();
    private readonly TimeProvider _timeProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="InMemoryTrainingRepository"/>.
    /// </summary>
    /// <param name="timeProvider">The time provider used to stamp feedback with the current UTC time.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="timeProvider"/> is null.</exception>
    public InMemoryTrainingRepository(TimeProvider timeProvider)
    {
        ArgumentNullException.ThrowIfNull(timeProvider);
        _timeProvider = timeProvider;
    }

    /// <inheritdoc />
    public Task RecordAsync(TrainingFeedback feedback, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(feedback);
        PayloadSchemaValidator.Validate(feedback, GetSchemaPath("training-feedback.schema.json"));
        var stamped = feedback with { RecordedAt = _timeProvider.GetUtcNow() };
        _queue.Enqueue(stamped);
        return Task.CompletedTask;
    }

    private static string GetSchemaPath(string schemaFileName) =>
        Path.GetFullPath(
            Path.Combine(
                AppContext.BaseDirectory,
                "..",
                "..",
                "..",
                "..",
                "..",
                "schemas",
                "v1",
                schemaFileName
            )
        );
}
