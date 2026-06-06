namespace TaskMaster.Application.IFile;

/// <summary>
/// Creates OneDrive folders (create-if-missing) and uploads attachment content
/// beneath a mapped Archive root. Implemented in TaskMaster.Infrastructure.
/// Satisfies AC-13, AC-15.
/// </summary>
public interface IOneDriveFolderWriter
{
    /// <summary>
    /// Resolves the drive-item id of the folder at <paramref name="relativePath"/> beneath
    /// <paramref name="archiveRootDriveItemId"/>, creating intermediate folders with
    /// create-if-missing semantics (<c>@microsoft.graph.conflictBehavior: "fail"</c>, treating
    /// <c>409 Conflict</c> as already-present). An empty relative path resolves to the Archive
    /// root itself. Returns the resolved leaf-folder drive-item id.
    /// </summary>
    Task<string> EnsureFolderPathAsync(
        string archiveRootDriveItemId,
        string relativePath,
        CancellationToken ct = default
    );

    /// <summary>
    /// Uploads attachment content into the folder identified by
    /// <paramref name="parentFolderDriveItemId"/>. Implementations use a simple PUT at or
    /// below 10 MiB and an upload session above 10 MiB (AC-15).
    /// </summary>
    Task UploadFileAsync(
        string parentFolderDriveItemId,
        AttachmentContent attachment,
        CancellationToken ct = default
    );
}
