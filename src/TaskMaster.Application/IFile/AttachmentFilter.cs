namespace TaskMaster.Application.IFile;

/// <summary>
/// Pure helper selecting which attachments are saved to OneDrive (OD-4). Satisfies AC-13.
/// Only non-inline file attachments are saved; inline body-embedded content and
/// item/reference attachments are skipped. No I/O.
/// </summary>
public static class AttachmentFilter
{
    private const string FileAttachmentType = "file";

    /// <summary>
    /// Returns the attachments that must be saved: <c>AttachmentType == "file"</c> and
    /// <c>IsInline == false</c>. The input order is preserved.
    /// </summary>
    public static IReadOnlyList<AttachmentMetadata> SelectSavable(
        IReadOnlyList<AttachmentMetadata> attachments
    )
    {
        ArgumentNullException.ThrowIfNull(attachments);
        return attachments
            .Where(a =>
                !a.IsInline
                && string.Equals(
                    a.AttachmentType,
                    FileAttachmentType,
                    StringComparison.OrdinalIgnoreCase
                )
            )
            .ToList();
    }
}
