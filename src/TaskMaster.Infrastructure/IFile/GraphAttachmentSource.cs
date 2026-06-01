using System.Text.Json;
using Microsoft.Kiota.Abstractions;
using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Infrastructure.IFile;

/// <summary>
/// Graph adapter that lists attachment metadata and fetches attachment content for a message
/// via <c>GET /me/messages/{id}/attachments</c>. Implements <see cref="IAttachmentSource"/>.
/// Attachment content is always fetched server-side (HC-5). No business orchestration here.
/// </summary>
public sealed class GraphAttachmentSource : IAttachmentSource
{
    private const string FileAttachmentOdataType = "#microsoft.graph.fileAttachment";
    private readonly IGraphClientFactory _clientFactory;

    public GraphAttachmentSource(IGraphClientFactory clientFactory)
    {
        ArgumentNullException.ThrowIfNull(clientFactory);
        _clientFactory = clientFactory;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<AttachmentMetadata>> ListAttachmentsAsync(
        string messageRestId,
        CancellationToken ct = default
    )
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(messageRestId);
        var adapter = _clientFactory.CreateClient().RequestAdapter;
        var escapedId = Uri.EscapeDataString(messageRestId);
        var url =
            $"{GraphRequest.BaseUrl(adapter)}/me/messages/{escapedId}/attachments"
            + "?$select=id,name,contentType,size,isInline";

        var request = new RequestInformation { HttpMethod = Method.GET, URI = new Uri(url) };
        var stream = await adapter
            .SendPrimitiveAsync<Stream>(request, cancellationToken: ct)
            .ConfigureAwait(false);
        if (stream is null)
        {
            return [];
        }

        await using (stream.ConfigureAwait(false))
        {
            return await ParseAttachmentsAsync(stream, ct).ConfigureAwait(false);
        }
    }

    /// <inheritdoc/>
    public async Task<AttachmentContent> GetAttachmentContentAsync(
        string messageRestId,
        string attachmentId,
        CancellationToken ct = default
    )
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(messageRestId);
        ArgumentException.ThrowIfNullOrWhiteSpace(attachmentId);
        var adapter = _clientFactory.CreateClient().RequestAdapter;
        var escapedMessage = Uri.EscapeDataString(messageRestId);
        var escapedAttachment = Uri.EscapeDataString(attachmentId);
        var url =
            $"{GraphRequest.BaseUrl(adapter)}/me/messages/{escapedMessage}/attachments/{escapedAttachment}";

        var request = new RequestInformation { HttpMethod = Method.GET, URI = new Uri(url) };
        var stream = await adapter
            .SendPrimitiveAsync<Stream>(request, cancellationToken: ct)
            .ConfigureAwait(false);
        if (stream is null)
        {
            throw new InvalidOperationException(
                $"Attachment '{attachmentId}' returned no content."
            );
        }

        await using (stream.ConfigureAwait(false))
        {
            using var document = await JsonDocument
                .ParseAsync(stream, cancellationToken: ct)
                .ConfigureAwait(false);
            var root = document.RootElement;
            var name = root.TryGetProperty("name", out var nameEl)
                ? nameEl.GetString() ?? attachmentId
                : attachmentId;
            var bytes =
                root.TryGetProperty("contentBytes", out var contentEl)
                && contentEl.ValueKind == JsonValueKind.String
                    ? Convert.FromBase64String(contentEl.GetString() ?? string.Empty)
                    : [];
            return new AttachmentContent(name, bytes);
        }
    }

    private static async Task<List<AttachmentMetadata>> ParseAttachmentsAsync(
        Stream stream,
        CancellationToken ct
    )
    {
        var results = new List<AttachmentMetadata>();
        using var document = await JsonDocument
            .ParseAsync(stream, cancellationToken: ct)
            .ConfigureAwait(false);
        if (
            !document.RootElement.TryGetProperty("value", out var value)
            || value.ValueKind != JsonValueKind.Array
        )
        {
            return results;
        }

        foreach (var element in value.EnumerateArray())
        {
            var odataType = element.TryGetProperty("@odata.type", out var typeEl)
                ? typeEl.GetString()
                : null;
            var attachmentType = string.Equals(
                odataType,
                FileAttachmentOdataType,
                StringComparison.Ordinal
            )
                ? "file"
                : "item";
            var id = element.TryGetProperty("id", out var idEl) ? idEl.GetString() : null;
            var name = element.TryGetProperty("name", out var nameEl) ? nameEl.GetString() : null;
            var isInline =
                element.TryGetProperty("isInline", out var inlineEl)
                && inlineEl.ValueKind is JsonValueKind.True or JsonValueKind.False
                && inlineEl.GetBoolean();
            var size =
                element.TryGetProperty("size", out var sizeEl) && sizeEl.TryGetInt64(out var s)
                    ? s
                    : 0;
            results.Add(
                new AttachmentMetadata(
                    id ?? string.Empty,
                    name ?? string.Empty,
                    attachmentType,
                    isInline,
                    size
                )
            );
        }

        return results;
    }
}
