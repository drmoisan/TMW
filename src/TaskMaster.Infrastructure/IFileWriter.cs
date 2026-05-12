namespace TaskMaster.Infrastructure;

/// <summary>
/// Testability seam over <see cref="System.IO.File"/> static methods.
/// Provides read, write, existence check, and atomic-replace operations.
/// </summary>
public interface IFileWriter
{
    /// <summary>Returns <c>true</c> if the file at <paramref name="path"/> exists.</summary>
    bool Exists(string path);

    /// <summary>Reads all text from <paramref name="path"/>.</summary>
    Task<string> ReadAllTextAsync(string path, CancellationToken ct = default);

    /// <summary>Writes <paramref name="contents"/> to <paramref name="path"/>, creating or overwriting the file.</summary>
    Task WriteAllTextAsync(string path, string contents, CancellationToken ct = default);

    /// <summary>
    /// Atomically replaces <paramref name="destinationFileName"/> with
    /// <paramref name="sourceFileName"/>, optionally backing up the original.
    /// Delegates to <see cref="System.IO.File.Replace(string, string, string?)"/>.
    /// </summary>
    void Replace(
        string sourceFileName,
        string destinationFileName,
        string? destinationBackupFileName
    );
}
