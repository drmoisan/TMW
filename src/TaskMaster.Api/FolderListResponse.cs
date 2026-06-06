namespace TaskMaster.Api;

/// <summary>
/// Response body for <c>GET /api/ifile/folders</c>: the flat list of leaf folders
/// (<c>childFolderCount == 0</c>) the client filters in-memory per keystroke (AC-8).
/// </summary>
/// <param name="Folders">The flat leaf-folder list.</param>
internal sealed record FolderListResponse(IReadOnlyList<FolderListItem> Folders);
