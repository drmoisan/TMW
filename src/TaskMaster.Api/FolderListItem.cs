namespace TaskMaster.Api;

/// <summary>A single leaf-folder entry in the iFile folder-list response.</summary>
/// <param name="FolderId">The Outlook mail-folder id.</param>
/// <param name="DisplayName">The leaf folder display name.</param>
/// <param name="Path">The full folder path (for example <c>Archive/Clients/Acme</c>).</param>
internal sealed record FolderListItem(string FolderId, string DisplayName, string Path);
