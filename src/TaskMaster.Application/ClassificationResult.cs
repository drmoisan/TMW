namespace TaskMaster.Application;

/// <summary>
/// The result of classifying a mail message, combining a label and a confidence score.
/// </summary>
/// <param name="Label">The classification label (see <see cref="ClassificationLabel"/>).</param>
/// <param name="Confidence">The confidence score in the range [0.0, 1.0].</param>
public sealed record ClassificationResult(string Label, double Confidence)
{
    /// <summary>
    /// Gets the confidence score in the range [0.0, 1.0].
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when value is less than 0.0 or greater than 1.0.</exception>
    public double Confidence { get; init; } =
        Confidence is < 0.0 or > 1.0
            ? throw new ArgumentOutOfRangeException(
                nameof(Confidence),
                Confidence,
                "Confidence must be in the range [0.0, 1.0]."
            )
            : Confidence;
}
