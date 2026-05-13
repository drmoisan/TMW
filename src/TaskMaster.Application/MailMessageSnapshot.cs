namespace TaskMaster.Application;

/// <summary>
/// Immutable snapshot of a mail message used as classifier input.
/// </summary>
/// <param name="MessageId">The unique identifier of the mail message.</param>
/// <param name="Subject">The subject line of the mail message.</param>
/// <param name="BodyPreview">Optional short preview of the message body.</param>
public sealed record MailMessageSnapshot(string MessageId, string Subject, string? BodyPreview)
{
    /// <summary>
    /// Creates a validated and trimmed <see cref="MailMessageSnapshot"/>.
    /// </summary>
    /// <param name="messageId">The message identifier. Must not be null or whitespace.</param>
    /// <param name="subject">The subject line. Must not be null or whitespace.</param>
    /// <param name="bodyPreview">Optional body preview. May be null.</param>
    /// <returns>A new <see cref="MailMessageSnapshot"/> with trimmed fields.</returns>
    /// <exception cref="ArgumentException">Thrown when <paramref name="messageId"/> or <paramref name="subject"/> is null or whitespace.</exception>
    public static MailMessageSnapshot Create(string messageId, string subject, string? bodyPreview)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(messageId);
        ArgumentException.ThrowIfNullOrWhiteSpace(subject);
        return new MailMessageSnapshot(messageId.Trim(), subject.Trim(), bodyPreview?.Trim());
    }
}
