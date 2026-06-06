namespace TaskMaster.Application.IFile;

/// <summary>
/// A single mailbox folder node returned by folder enumeration.
/// </summary>
/// <param name="Id">The Graph mail-folder id.</param>
/// <param name="DisplayName">The folder display name.</param>
/// <param name="Path">The full folder path (for example <c>Archive/Clients/Acme</c>).</param>
/// <param name="ParentFolderId">The parent folder id, or <c>null</c> for a root-level folder.</param>
/// <param name="ChildFolderCount">The number of child folders; <c>0</c> identifies a leaf.</param>
public sealed record MailFolderNode(
    string Id,
    string DisplayName,
    string Path,
    string? ParentFolderId,
    int ChildFolderCount
);
