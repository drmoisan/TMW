namespace TaskMaster.Application.IFile;

/// <summary>
/// Pure mapper from an Outlook mail-folder path to the relative OneDrive path
/// beneath the mapped Archive root. No I/O. Satisfies AC-14.
/// </summary>
/// <remarks>
/// The mailbox <c>Archive</c> root is identified elsewhere by display name (OD-5);
/// this mapper assumes the supplied path is rooted at the <c>Archive</c> segment and
/// strips that leading segment, returning the remaining relative path. For example
/// <c>Archive/Clients/Acme</c> maps to <c>Clients/Acme</c>; the bare <c>Archive</c>
/// root maps to the empty string (the Archive root itself).
/// </remarks>
public static class OutlookToOneDrivePath
{
    private const char Separator = '/';
    private const string ArchiveSegment = "Archive";

    /// <summary>
    /// Strips the leading <c>Archive</c> segment from <paramref name="outlookFolderPath"/>
    /// and returns the relative OneDrive path. Returns the empty string for the bare
    /// <c>Archive</c> root.
    /// </summary>
    /// <param name="outlookFolderPath">
    /// A forward-slash-separated Outlook folder path rooted at <c>Archive</c>
    /// (for example <c>Archive/Clients/Acme</c>).
    /// </param>
    /// <exception cref="ArgumentException">
    /// Thrown when the path is null/whitespace or is not rooted at the <c>Archive</c> segment.
    /// </exception>
    public static string Map(string outlookFolderPath)
    {
        if (string.IsNullOrWhiteSpace(outlookFolderPath))
        {
            throw new ArgumentException(
                "Outlook folder path must be non-empty.",
                nameof(outlookFolderPath)
            );
        }

        var segments = outlookFolderPath
            .Split(Separator, StringSplitOptions.RemoveEmptyEntries)
            .ToArray();

        if (
            segments.Length == 0
            || !string.Equals(segments[0], ArchiveSegment, StringComparison.Ordinal)
        )
        {
            throw new ArgumentException(
                $"Outlook folder path must be rooted at the '{ArchiveSegment}' segment; got '{outlookFolderPath}'.",
                nameof(outlookFolderPath)
            );
        }

        return string.Join(Separator, segments.Skip(1));
    }
}
