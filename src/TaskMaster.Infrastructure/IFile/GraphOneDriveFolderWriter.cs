using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Kiota.Abstractions;
using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Infrastructure.IFile;

/// <summary>
/// Graph adapter that creates OneDrive folders (create-if-missing) and uploads attachment
/// content beneath a mapped Archive root. Implements <see cref="IOneDriveFolderWriter"/>
/// (AC-13, AC-15). No business orchestration lives here.
/// </summary>
/// <remarks>
/// Folder creation posts to <c>/me/drive/items/{parentId}/children</c> with body
/// <c>{ "name": ..., "folder": {}, "@microsoft.graph.conflictBehavior": "fail" }</c>; a
/// <c>409 Conflict</c> is treated as already-present and the existing child is resolved.
/// Uploads use a simple PUT to <c>/me/drive/items/{parentId}:/{name}:/content</c> at or below
/// 10 MiB and an upload session above 10 MiB.
/// </remarks>
public sealed class GraphOneDriveFolderWriter : IOneDriveFolderWriter
{
    /// <summary>The simple-PUT vs. upload-session threshold: 10 MiB.</summary>
    public const long SimpleUploadMaxBytes = 10L * 1024 * 1024;

    private readonly IGraphClientFactory _clientFactory;

    public GraphOneDriveFolderWriter(IGraphClientFactory clientFactory)
    {
        ArgumentNullException.ThrowIfNull(clientFactory);
        _clientFactory = clientFactory;
    }

    /// <inheritdoc/>
    public async Task<string> EnsureFolderPathAsync(
        string archiveRootDriveItemId,
        string relativePath,
        CancellationToken ct = default
    )
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(archiveRootDriveItemId);
        ArgumentNullException.ThrowIfNull(relativePath);

        var adapter = _clientFactory.CreateClient().RequestAdapter;
        var baseUrl = GraphRequest.BaseUrl(adapter);
        var currentId = archiveRootDriveItemId;

        var segments = relativePath.Split('/', StringSplitOptions.RemoveEmptyEntries);
        foreach (var segment in segments)
        {
            currentId = await EnsureChildFolderAsync(adapter, baseUrl, currentId, segment, ct)
                .ConfigureAwait(false);
        }

        return currentId;
    }

    /// <inheritdoc/>
    public async Task UploadFileAsync(
        string parentFolderDriveItemId,
        AttachmentContent attachment,
        CancellationToken ct = default
    )
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(parentFolderDriveItemId);
        ArgumentNullException.ThrowIfNull(attachment);

        var adapter = _clientFactory.CreateClient().RequestAdapter;
        var baseUrl = GraphRequest.BaseUrl(adapter);
        var escapedParent = Uri.EscapeDataString(parentFolderDriveItemId);
        var escapedName = Uri.EscapeDataString(attachment.Name);

        if (attachment.Content.Length <= SimpleUploadMaxBytes)
        {
            var url = $"{baseUrl}/me/drive/items/{escapedParent}:/{escapedName}:/content";
            var request = new RequestInformation { HttpMethod = Method.PUT, URI = new Uri(url) };
            request.SetStreamContent(
                new MemoryStream(attachment.Content.ToArray()),
                "application/octet-stream"
            );
            await adapter.SendNoContentAsync(request, cancellationToken: ct).ConfigureAwait(false);
            return;
        }

        await UploadViaSessionAsync(adapter, baseUrl, escapedParent, escapedName, attachment, ct)
            .ConfigureAwait(false);
    }

    private static async Task<string> EnsureChildFolderAsync(
        IRequestAdapter adapter,
        string baseUrl,
        string parentId,
        string folderName,
        CancellationToken ct
    )
    {
        var escapedParent = Uri.EscapeDataString(parentId);
        var createUrl = $"{baseUrl}/me/drive/items/{escapedParent}/children";
        var body =
            "{"
            + $"\"name\":{GraphRequest.JsonString(folderName)},"
            + "\"folder\":{},"
            + "\"@microsoft.graph.conflictBehavior\":\"fail\""
            + "}";

        var request = new RequestInformation { HttpMethod = Method.POST, URI = new Uri(createUrl) };
        request.SetStreamContent(
            new MemoryStream(Encoding.UTF8.GetBytes(body)),
            "application/json"
        );

        try
        {
            var stream = await adapter
                .SendPrimitiveAsync<Stream>(request, cancellationToken: ct)
                .ConfigureAwait(false);
            return await ReadDriveItemIdAsync(stream, ct).ConfigureAwait(false)
                ?? throw new InvalidOperationException(
                    $"Created folder '{folderName}' returned no id."
                );
        }
        catch (ApiException ex) when (ex.ResponseStatusCode == (int)HttpStatusCode.Conflict)
        {
            // Create-if-missing: the folder already exists; resolve the existing child by name.
            return await GetExistingChildIdAsync(adapter, baseUrl, parentId, folderName, ct)
                .ConfigureAwait(false);
        }
    }

    private static async Task<string> GetExistingChildIdAsync(
        IRequestAdapter adapter,
        string baseUrl,
        string parentId,
        string folderName,
        CancellationToken ct
    )
    {
        var escapedParent = Uri.EscapeDataString(parentId);
        var escapedName = Uri.EscapeDataString(folderName);
        var url = $"{baseUrl}/me/drive/items/{escapedParent}:/{escapedName}";
        var request = new RequestInformation { HttpMethod = Method.GET, URI = new Uri(url) };
        var stream = await adapter
            .SendPrimitiveAsync<Stream>(request, cancellationToken: ct)
            .ConfigureAwait(false);
        return await ReadDriveItemIdAsync(stream, ct).ConfigureAwait(false)
            ?? throw new InvalidOperationException(
                $"Existing folder '{folderName}' could not be resolved after a 409 conflict."
            );
    }

    private static async Task UploadViaSessionAsync(
        IRequestAdapter adapter,
        string baseUrl,
        string escapedParent,
        string escapedName,
        AttachmentContent attachment,
        CancellationToken ct
    )
    {
        var sessionUrl =
            $"{baseUrl}/me/drive/items/{escapedParent}:/{escapedName}:/createUploadSession";
        var sessionRequest = new RequestInformation
        {
            HttpMethod = Method.POST,
            URI = new Uri(sessionUrl),
        };
        sessionRequest.SetStreamContent(
            new MemoryStream(
                Encoding.UTF8.GetBytes(
                    "{\"item\":{\"@microsoft.graph.conflictBehavior\":\"replace\"}}"
                )
            ),
            "application/json"
        );
        var sessionStream = await adapter
            .SendPrimitiveAsync<Stream>(sessionRequest, cancellationToken: ct)
            .ConfigureAwait(false);

        var uploadUrl =
            await ReadUploadUrlAsync(sessionStream, ct).ConfigureAwait(false)
            ?? throw new InvalidOperationException("Upload session returned no uploadUrl.");

        var total = attachment.Content.Length;
        var putRequest = new RequestInformation
        {
            HttpMethod = Method.PUT,
            URI = new Uri(uploadUrl),
        };
        putRequest.Headers.Add("Content-Range", $"bytes 0-{total - 1}/{total}");
        putRequest.SetStreamContent(
            new MemoryStream(attachment.Content.ToArray()),
            "application/octet-stream"
        );
        await adapter.SendNoContentAsync(putRequest, cancellationToken: ct).ConfigureAwait(false);
    }

    private static async Task<string?> ReadDriveItemIdAsync(Stream? stream, CancellationToken ct)
    {
        if (stream is null)
        {
            return null;
        }

        await using (stream.ConfigureAwait(false))
        {
            using var document = await JsonDocument
                .ParseAsync(stream, cancellationToken: ct)
                .ConfigureAwait(false);
            return document.RootElement.TryGetProperty("id", out var idEl)
                ? idEl.GetString()
                : null;
        }
    }

    private static async Task<string?> ReadUploadUrlAsync(Stream? stream, CancellationToken ct)
    {
        if (stream is null)
        {
            return null;
        }

        await using (stream.ConfigureAwait(false))
        {
            using var document = await JsonDocument
                .ParseAsync(stream, cancellationToken: ct)
                .ConfigureAwait(false);
            return document.RootElement.TryGetProperty("uploadUrl", out var urlEl)
                ? urlEl.GetString()
                : null;
        }
    }
}
