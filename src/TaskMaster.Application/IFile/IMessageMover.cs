namespace TaskMaster.Application.IFile;

/// <summary>
/// Moves a message to a destination Outlook folder via Graph
/// (<c>POST /me/messages/{id}/move</c>). Implemented in TaskMaster.Infrastructure.
/// Satisfies AC-12.
/// </summary>
public interface IMessageMover
{
    /// <summary>
    /// Moves the message identified by <paramref name="messageRestId"/> to
    /// <paramref name="destinationFolderId"/>. Implementations treat a message already
    /// in the destination as satisfied (idempotent move).
    /// </summary>
    Task MoveAsync(
        string messageRestId,
        string destinationFolderId,
        CancellationToken ct = default
    );
}
