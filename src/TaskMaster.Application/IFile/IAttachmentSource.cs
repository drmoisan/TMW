namespace TaskMaster.Application.IFile;

/// <summary>
/// Reads attachment metadata and content for a message via Graph. Attachment content
/// is always fetched server-side (HC-5). Implemented in TaskMaster.Infrastructure.
/// Satisfies AC-13.
/// </summary>
public interface IAttachmentSource
{
    /// <summary>Lists attachment metadata for the given message.</summary>
    Task<IReadOnlyList<AttachmentMetadata>> ListAttachmentsAsync(
        string messageRestId,
        CancellationToken ct = default
    );

    /// <summary>Fetches the content bytes for a single attachment.</summary>
    Task<AttachmentContent> GetAttachmentContentAsync(
        string messageRestId,
        string attachmentId,
        CancellationToken ct = default
    );
}
