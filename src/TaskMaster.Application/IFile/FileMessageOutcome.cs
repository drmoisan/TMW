namespace TaskMaster.Application.IFile;

/// <summary>
/// Discriminated outcome of a <see cref="FileMessageCommand"/>. Satisfies AC-17, AC-18.
/// </summary>
/// <remarks>
/// The command runs attachments-first, move-last (OD-7). A failure before the move
/// leaves the message in place and is reported as <see cref="PreMoveFailure"/>.
/// When the backend has no stored Archive-root mapping, the result is
/// <see cref="ArchiveRootRequired"/> so the client can surface the select-or-create
/// step (AC-21).
/// </remarks>
public enum FileMessageOutcome
{
    /// <summary>The message was filed: attachments uploaded (if any) and the message moved.</summary>
    Success = 0,

    /// <summary>
    /// A step before the move failed (Archive-root resolution, OneDrive folder
    /// resolution, or attachment upload); the message was not moved.
    /// </summary>
    PreMoveFailure = 1,

    /// <summary>
    /// No stored OneDrive Archive-root mapping exists; the client must present the
    /// select-or-create step and retry with the chosen drive-item id (AC-21).
    /// </summary>
    ArchiveRootRequired = 2,
}
