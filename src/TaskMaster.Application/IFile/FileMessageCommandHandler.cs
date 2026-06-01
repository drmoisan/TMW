using Microsoft.Extensions.Logging;

namespace TaskMaster.Application.IFile;

/// <summary>
/// Orchestrates the iFile filing workflow attachments-first, move-last (OD-7).
/// Satisfies AC-13, AC-16, AC-17, AC-18, AC-21, AC-22, AC-23.
/// </summary>
/// <remarks>
/// Execution order: (1) resolve the Archive-root mapping (stored, or supplied on first
/// use, otherwise surface <see cref="FileMessageOutcome.ArchiveRootRequired"/>);
/// (2) resolve/create the mirrored OneDrive folder via <see cref="OutlookToOneDrivePath"/>
/// and <see cref="IOneDriveFolderWriter"/>; (3) upload non-inline file attachments;
/// (4) move the message via <see cref="IMessageMover"/>. Any failure before the move
/// returns a <see cref="FileMessageOutcome.PreMoveFailure"/> and does not move the message.
/// The result is published through the command's <see cref="FileMessageCommand.ResultSink"/>.
/// </remarks>
public sealed class FileMessageCommandHandler : ICommandHandler<FileMessageCommand>
{
    private readonly IFolderTreeReader _folderTreeReader;
    private readonly IAttachmentSource _attachmentSource;
    private readonly IOneDriveFolderWriter _oneDriveWriter;
    private readonly IMessageMover _messageMover;
    private readonly IUserSettingsRepository _userSettings;
    private readonly ILogger<FileMessageCommandHandler> _logger;

    public FileMessageCommandHandler(
        IFolderTreeReader folderTreeReader,
        IAttachmentSource attachmentSource,
        IOneDriveFolderWriter oneDriveWriter,
        IMessageMover messageMover,
        IUserSettingsRepository userSettings,
        ILogger<FileMessageCommandHandler> logger
    )
    {
        ArgumentNullException.ThrowIfNull(folderTreeReader);
        ArgumentNullException.ThrowIfNull(attachmentSource);
        ArgumentNullException.ThrowIfNull(oneDriveWriter);
        ArgumentNullException.ThrowIfNull(messageMover);
        ArgumentNullException.ThrowIfNull(userSettings);
        ArgumentNullException.ThrowIfNull(logger);
        _folderTreeReader = folderTreeReader;
        _attachmentSource = attachmentSource;
        _oneDriveWriter = oneDriveWriter;
        _messageMover = messageMover;
        _userSettings = userSettings;
        _logger = logger;
    }

    /// <inheritdoc/>
    public async Task HandleAsync(FileMessageCommand command, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(command);
        try
        {
            var result = await ExecuteAsync(command, ct).ConfigureAwait(false);
            command.ResultSink.TrySetResult(result);
        }
        catch (OperationCanceledException)
        {
            command.ResultSink.TrySetCanceled(ct);
            throw;
        }
#pragma warning disable CA1031 // The filing workflow boundary converts failures into a user-facing pre-move-failure result; the message is not moved.
        catch (Exception ex)
#pragma warning restore CA1031
        {
            FileMessageWorkflow.LogPreMoveFailure(_logger, ex);
            command.ResultSink.TrySetResult(FileMessageResult.PreMoveFailure(ex.Message));
        }
    }

    private async Task<FileMessageResult> ExecuteAsync(
        FileMessageCommand command,
        CancellationToken ct
    )
    {
        // Step 0 — resolve the Archive-root mapping (stored or first-use supplied).
        var archiveRootDriveItemId = await ResolveArchiveRootAsync(command, ct)
            .ConfigureAwait(false);
        if (archiveRootDriveItemId is null)
        {
            FileMessageWorkflow.LogArchiveRootRequired(_logger, command.UserId);
            return FileMessageResult.ArchiveRootRequired();
        }

        // Resolve the destination folder path so it can be mirrored to OneDrive.
        var folders = await _folderTreeReader.GetFoldersAsync(ct).ConfigureAwait(false);
        var destination = FileMessageWorkflow.FindDestination(folders, command.DestinationFolderId);
        var relativePath = OutlookToOneDrivePath.Map(destination.Path);

        // Step 1 — resolve/create the mirrored OneDrive folder.
        var targetFolderId = await _oneDriveWriter
            .EnsureFolderPathAsync(archiveRootDriveItemId, relativePath, ct)
            .ConfigureAwait(false);

        // Step 2 — upload non-inline file attachments.
        await UploadAttachmentsAsync(command.MessageRestId, targetFolderId, ct)
            .ConfigureAwait(false);

        // Step 3 — move the message (the final step).
        await _messageMover
            .MoveAsync(command.MessageRestId, command.DestinationFolderId, ct)
            .ConfigureAwait(false);

        FileMessageWorkflow.LogSuccess(_logger, command.MessageRestId, command.DestinationFolderId);
        return FileMessageResult.Success();
    }

    private async Task<string?> ResolveArchiveRootAsync(
        FileMessageCommand command,
        CancellationToken ct
    )
    {
        var settings = await _userSettings.GetAsync(command.UserId, ct).ConfigureAwait(false);
        var stored = settings?.ArchiveRootDriveItemId;

        if (!string.IsNullOrEmpty(stored))
        {
            return stored;
        }

        if (string.IsNullOrEmpty(command.ArchiveRootDriveItemId))
        {
            // No stored mapping and no first-use selection: surface select-or-create.
            return null;
        }

        // First use: persist the chosen mapping for reuse (AC-22).
        var updated = (settings ?? FileMessageWorkflow.NewSettings(command.UserId)) with
        {
            ArchiveRootDriveItemId = command.ArchiveRootDriveItemId,
        };
        await _userSettings.SaveAsync(updated, ct).ConfigureAwait(false);
        return command.ArchiveRootDriveItemId;
    }

    private async Task UploadAttachmentsAsync(
        string messageRestId,
        string targetFolderId,
        CancellationToken ct
    )
    {
        var attachments = await _attachmentSource
            .ListAttachmentsAsync(messageRestId, ct)
            .ConfigureAwait(false);
        var savable = AttachmentFilter.SelectSavable(attachments);
        if (savable.Count == 0)
        {
            // No attachments — no OneDrive writes; proceed to move (AC-16).
            FileMessageWorkflow.LogNoAttachments(_logger, messageRestId);
            return;
        }

        foreach (var attachment in savable)
        {
            var content = await _attachmentSource
                .GetAttachmentContentAsync(messageRestId, attachment.Id, ct)
                .ConfigureAwait(false);
            await _oneDriveWriter
                .UploadFileAsync(targetFolderId, content, ct)
                .ConfigureAwait(false);
        }
    }
}
