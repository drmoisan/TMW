namespace TaskMaster.Infrastructure.Validation;

/// <summary>
/// Thrown when a payload fails JSON Schema validation before being written to storage.
/// </summary>
public sealed class SchemaValidationException : Exception
{
    /// <summary>
    /// Gets the name of the payload type that failed validation.
    /// </summary>
    public string PayloadType { get; } = string.Empty;

    /// <summary>
    /// Gets the list of validation error messages reported by the schema evaluator.
    /// </summary>
    public IReadOnlyList<string> ValidationErrors { get; } = [];

    /// <summary>
    /// Initializes a new instance of <see cref="SchemaValidationException"/> with no message.
    /// </summary>
    public SchemaValidationException() { }

    /// <summary>
    /// Initializes a new instance of <see cref="SchemaValidationException"/> with a message.
    /// </summary>
    /// <param name="message">The exception message.</param>
    public SchemaValidationException(string message)
        : base(message) { }

    /// <summary>
    /// Initializes a new instance of <see cref="SchemaValidationException"/> with a message and inner exception.
    /// </summary>
    /// <param name="message">The exception message.</param>
    /// <param name="innerException">The inner exception.</param>
    public SchemaValidationException(string message, Exception innerException)
        : base(message, innerException) { }

    /// <summary>
    /// Initializes a new instance of <see cref="SchemaValidationException"/> with full validation details.
    /// </summary>
    /// <param name="payloadType">The name of the payload type that failed validation.</param>
    /// <param name="validationErrors">The validation error messages.</param>
    public SchemaValidationException(string payloadType, IReadOnlyList<string> validationErrors)
        : base(
            $"Payload '{payloadType}' failed schema validation: {string.Join("; ", validationErrors)}"
        )
    {
        PayloadType = payloadType;
        ValidationErrors = validationErrors;
    }
}
