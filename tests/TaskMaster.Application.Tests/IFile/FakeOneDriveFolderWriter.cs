using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Stateful in-memory fake of <see cref="IOneDriveFolderWriter"/> with create-if-missing
/// semantics, used to verify idempotent retries create no duplicate folders or files (AC-18).
/// Optionally fails the first <see cref="EnsureFolderPathAsync"/> call to simulate a pre-move
/// OneDrive failure.
/// </summary>
internal sealed class FakeOneDriveFolderWriter : IOneDriveFolderWriter
{
    private readonly Dictionary<string, string> _folders = new(StringComparer.Ordinal);
    private int _ensureCalls;

    public FakeOneDriveFolderWriter(int failFirstEnsureCalls = 0)
    {
        FailFirstEnsureCalls = failFirstEnsureCalls;
    }

    public int FailFirstEnsureCalls { get; }

    public List<string> UploadedFiles { get; } = [];

    public int DistinctFolderCount => _folders.Count;

    public Task<string> EnsureFolderPathAsync(
        string archiveRootDriveItemId,
        string relativePath,
        CancellationToken ct = default
    )
    {
        _ensureCalls++;
        if (_ensureCalls <= FailFirstEnsureCalls)
        {
            throw new InvalidOperationException("Simulated OneDrive folder-resolve failure.");
        }

        var key = $"{archiveRootDriveItemId}/{relativePath}";
        if (!_folders.TryGetValue(key, out var driveId))
        {
            driveId = $"drive-{_folders.Count}";
            _folders[key] = driveId; // create-if-missing: only first call creates.
        }

        return Task.FromResult(driveId);
    }

    public Task UploadFileAsync(
        string parentFolderDriveItemId,
        AttachmentContent attachment,
        CancellationToken ct = default
    )
    {
        var key = $"{parentFolderDriveItemId}/{attachment.Name}";
        if (!UploadedFiles.Contains(key, StringComparer.Ordinal))
        {
            UploadedFiles.Add(key);
        }

        return Task.CompletedTask;
    }
}
