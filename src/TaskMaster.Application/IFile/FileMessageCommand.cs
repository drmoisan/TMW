namespace TaskMaster.Application.IFile;

/// <summary>
/// Command requesting that the opened message be filed into the chosen Outlook
/// folder, with its non-inline file attachments mirrored to OneDrive beneath the
/// persisted Archive root. Satisfies AC-10, AC-17, AC-18.
/// </summary>
/// <remarks>
/// The command carries a <see cref="ResultSink"/> so the result of the handler can
/// be observed by the dispatcher (the existing <see cref="ICommandBus"/> returns a
/// non-generic <see cref="Task"/>). The handler completes the sink exactly once; the
/// API host awaits <see cref="ResultSink"/>.<c>Task</c> to obtain the
/// <see cref="FileMessageResult"/>.
/// </remarks>
/// <param name="MessageRestId">The Graph REST id of the message to file.</param>
/// <param name="DestinationFolderId">The Outlook destination folder id.</param>
/// <param name="ArchiveRootDriveItemId">
/// The OneDrive drive-item id of the Archive root chosen by the user on first use.
/// When <c>null</c>, the handler uses the persisted mapping if present, or reports
/// <see cref="FileMessageOutcome.ArchiveRootRequired"/> when no mapping exists (AC-21).
/// </param>
/// <param name="UserId">The id of the acting user, used to read/persist the mapping.</param>
public sealed record FileMessageCommand(
    string MessageRestId,
    string DestinationFolderId,
    string? ArchiveRootDriveItemId,
    string UserId
)
{
    /// <summary>
    /// Completion source the handler completes with the filing outcome. The dispatcher
    /// awaits its <see cref="TaskCompletionSource{TResult}.Task"/>.
    /// </summary>
    public TaskCompletionSource<FileMessageResult> ResultSink { get; } =
        new(TaskCreationOptions.RunContinuationsAsynchronously);
}
