namespace TaskMaster.Infrastructure;

/// <summary>
/// Production implementation of <see cref="IFileWriter"/> that delegates to
/// <see cref="System.IO.File"/> static methods.
/// </summary>
internal sealed class FileWriter : IFileWriter
{
    /// <inheritdoc/>
    public bool Exists(string path) => File.Exists(path);

    /// <inheritdoc/>
    public Task<string> ReadAllTextAsync(string path, CancellationToken ct = default) =>
        File.ReadAllTextAsync(path, ct);

    /// <inheritdoc/>
    public Task WriteAllTextAsync(string path, string contents, CancellationToken ct = default) =>
        File.WriteAllTextAsync(path, contents, ct);

    /// <inheritdoc/>
    public void Replace(
        string sourceFileName,
        string destinationFileName,
        string? destinationBackupFileName
    ) => File.Replace(sourceFileName, destinationFileName, destinationBackupFileName);
}
