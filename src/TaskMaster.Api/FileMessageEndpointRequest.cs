namespace TaskMaster.Api;

/// <summary>
/// Request body for <c>POST /api/ifile/file</c>. The client sends only the message REST id,
/// the chosen destination folder id, and (on first use) the chosen OneDrive Archive-root
/// drive-item id. No Graph write logic runs on the client (AC-10).
/// </summary>
internal sealed record FileMessageEndpointRequest(
    string? MessageRestId,
    string? DestinationFolderId,
    string? ArchiveRootDriveItemId
);
