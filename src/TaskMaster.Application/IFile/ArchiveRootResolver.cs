namespace TaskMaster.Application.IFile;

/// <summary>
/// Pure helper resolving the mailbox <c>Archive</c> root folder from an enumerated
/// folder list. Satisfies AC-14 (OD-5): the Archive root is identified by the folder
/// whose <c>DisplayName</c> is exactly <c>Archive</c> directly under the mailbox root
/// (a null parent), NOT the Graph well-known mailbox name <c>archive</c>. No I/O.
/// </summary>
public static class ArchiveRootResolver
{
    private const string ArchiveDisplayName = "Archive";

    /// <summary>
    /// Returns the <see cref="MailFolderNode"/> for the mailbox <c>Archive</c> root, or
    /// <c>null</c> when no top-level folder named <c>Archive</c> exists. The match is
    /// case-sensitive on the display name and requires a null parent (top level).
    /// </summary>
    public static MailFolderNode? Resolve(IReadOnlyList<MailFolderNode> folders)
    {
        ArgumentNullException.ThrowIfNull(folders);
        return folders.FirstOrDefault(f =>
            f.ParentFolderId is null
            && string.Equals(f.DisplayName, ArchiveDisplayName, StringComparison.Ordinal)
        );
    }
}
