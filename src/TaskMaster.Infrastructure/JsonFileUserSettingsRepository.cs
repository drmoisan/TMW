using System.Text.Json;
using Microsoft.Extensions.Options;
using TaskMaster.Application;

namespace TaskMaster.Infrastructure;

/// <summary>
/// File-backed implementation of <see cref="IUserSettingsRepository"/> that serialises
/// all user settings as a JSON dictionary keyed by user ID.
/// Writes are atomic: the payload is written to a temporary file first, then
/// <see cref="IFileWriter.Replace"/> swaps it in.
/// </summary>
public sealed class JsonFileUserSettingsRepository : IUserSettingsRepository, IDisposable
{
    private static readonly JsonSerializerOptions s_jsonOptions = new(JsonSerializerDefaults.Web)
    {
        WriteIndented = false,
    };

    private readonly IFileWriter _fileWriter;
    private readonly string _filePath;
    private readonly TimeProvider _timeProvider;
    private readonly SemaphoreSlim _lock = new(1, 1);
    private bool _disposed;

    /// <param name="options">Options carrying the settings file path.</param>
    /// <param name="fileWriter">Seam for file I/O to allow unit testing without real disk access.</param>
    /// <param name="timeProvider">Clock used to set <see cref="UserSettings.LastModifiedAt"/>.</param>
    public JsonFileUserSettingsRepository(
        IOptions<UserSettingsFileOptions> options,
        IFileWriter fileWriter,
        TimeProvider timeProvider
    )
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentNullException.ThrowIfNull(fileWriter);
        ArgumentNullException.ThrowIfNull(timeProvider);
        _fileWriter = fileWriter;
        _filePath = options.Value.FilePath;
        _timeProvider = timeProvider;
    }

    /// <inheritdoc/>
    public async Task<UserSettings?> GetAsync(string userId, CancellationToken ct = default)
    {
        var store = await ReadStoreAsync(ct).ConfigureAwait(false);
        store.TryGetValue(userId, out var settings);
        return settings;
    }

    /// <inheritdoc/>
    public async Task SaveAsync(UserSettings settings, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(settings);
        await _lock.WaitAsync(ct).ConfigureAwait(false);
        try
        {
            var store = await ReadStoreAsync(ct).ConfigureAwait(false);
            store[settings.UserId] = settings with { LastModifiedAt = _timeProvider.GetUtcNow() };
            await WriteStoreAsync(store, ct).ConfigureAwait(false);
        }
        finally
        {
            _lock.Release();
        }
    }

    /// <inheritdoc/>
    public async Task DeleteAsync(string userId, CancellationToken ct = default)
    {
        await _lock.WaitAsync(ct).ConfigureAwait(false);
        try
        {
            var store = await ReadStoreAsync(ct).ConfigureAwait(false);
            if (store.Remove(userId))
            {
                await WriteStoreAsync(store, ct).ConfigureAwait(false);
            }
        }
        finally
        {
            _lock.Release();
        }
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (!_disposed)
        {
            _lock.Dispose();
            _disposed = true;
        }
    }

    private async Task<Dictionary<string, UserSettings>> ReadStoreAsync(CancellationToken ct)
    {
        if (!_fileWriter.Exists(_filePath))
        {
            return [];
        }

        var json = await _fileWriter.ReadAllTextAsync(_filePath, ct).ConfigureAwait(false);
        return JsonSerializer.Deserialize<Dictionary<string, UserSettings>>(json, s_jsonOptions)
            ?? [];
    }

    private async Task WriteStoreAsync(Dictionary<string, UserSettings> store, CancellationToken ct)
    {
        var json = JsonSerializer.Serialize(store, s_jsonOptions);
        var tempPath = _filePath + ".tmp";
        await _fileWriter.WriteAllTextAsync(tempPath, json, ct).ConfigureAwait(false);

        if (_fileWriter.Exists(_filePath))
        {
            _fileWriter.Replace(tempPath, _filePath, null);
        }
        else
        {
            // First write — no existing file to replace; write directly to target.
            await _fileWriter.WriteAllTextAsync(_filePath, json, ct).ConfigureAwait(false);
        }
    }
}
