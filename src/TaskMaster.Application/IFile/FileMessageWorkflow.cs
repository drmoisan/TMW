using Microsoft.Extensions.Logging;

namespace TaskMaster.Application.IFile;

/// <summary>
/// Pure/stateless helpers and source-generated log messages for
/// <see cref="FileMessageCommandHandler"/>. Kept in a partner file to hold the
/// handler under the 500-line file cap.
/// </summary>
internal static partial class FileMessageWorkflow
{
    /// <summary>
    /// Finds the destination folder node by id, throwing a clear error when it is
    /// not present in the enumerated tree (a pre-move failure surfaced to the user).
    /// </summary>
    public static MailFolderNode FindDestination(
        IReadOnlyList<MailFolderNode> folders,
        string destinationFolderId
    )
    {
        var destination = folders.FirstOrDefault(f =>
            string.Equals(f.Id, destinationFolderId, StringComparison.Ordinal)
        );
        return destination
            ?? throw new InvalidOperationException(
                $"Destination folder '{destinationFolderId}' was not found in the mailbox folder tree."
            );
    }

    /// <summary>Creates a fresh <see cref="UserSettings"/> for a user with no prior settings.</summary>
    public static UserSettings NewSettings(string userId) =>
        new(
            UserId: userId,
            NotificationsEnabled: false,
            TriageEnabled: false,
            LastModifiedAt: default
        );

    [LoggerMessage(
        EventId = 4301,
        Level = LogLevel.Information,
        Message = "iFile filing succeeded: message {MessageRestId} moved to folder {DestinationFolderId}."
    )]
    public static partial void LogSuccess(
        ILogger logger,
        string messageRestId,
        string destinationFolderId
    );

    [LoggerMessage(
        EventId = 4302,
        Level = LogLevel.Error,
        Message = "iFile filing failed before the move; the message was not moved."
    )]
    public static partial void LogPreMoveFailure(ILogger logger, Exception exception);

    [LoggerMessage(
        EventId = 4303,
        Level = LogLevel.Debug,
        Message = "iFile filing: message {MessageRestId} has no non-inline file attachments; proceeding to move."
    )]
    public static partial void LogNoAttachments(ILogger logger, string messageRestId);

    [LoggerMessage(
        EventId = 4304,
        Level = LogLevel.Information,
        Message = "iFile filing requires an Archive-root selection for user {UserId}; surfacing select-or-create."
    )]
    public static partial void LogArchiveRootRequired(ILogger logger, string userId);
}
