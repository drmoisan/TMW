namespace TaskMaster.Application.IFile;

/// <summary>
/// Reads the mailbox folder tree via Graph and returns a flat leaf-folder list.
/// Implemented in TaskMaster.Infrastructure (Graph adapter). Satisfies AC-10 (server boundary).
/// </summary>
public interface IFolderTreeReader
{
    /// <summary>
    /// Enumerates the mailbox folder tree and returns a flat list of all folders
    /// (including their full paths and child-folder counts) so callers can filter to leaves.
    /// </summary>
    Task<IReadOnlyList<MailFolderNode>> GetFoldersAsync(CancellationToken ct = default);
}
