namespace TaskMaster.Application.IFile;

/// <summary>
/// Metadata for a single message attachment, used by the inline-vs-file filter.
/// </summary>
/// <param name="Id">The Graph attachment id.</param>
/// <param name="Name">The attachment file name.</param>
/// <param name="AttachmentType">
/// The Graph <c>@odata.type</c>-derived kind: <c>file</c>, <c>item</c>, or <c>reference</c>.
/// </param>
/// <param name="IsInline">Whether the attachment is inline (body-embedded).</param>
/// <param name="Size">The attachment size in bytes.</param>
public sealed record AttachmentMetadata(
    string Id,
    string Name,
    string AttachmentType,
    bool IsInline,
    long Size
);
