using System.Text.Json;
using Microsoft.Kiota.Abstractions;
using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Infrastructure.IFile;

/// <summary>
/// Graph adapter that enumerates the mailbox folder tree via <c>GET /me/mailFolders</c> and
/// recursive <c>/childFolders</c>, returning a flat list of <see cref="MailFolderNode"/> with
/// full paths. Implements <see cref="IFolderTreeReader"/> (AC-12, server boundary).
/// </summary>
/// <remarks>
/// Requests are issued through the OBO-configured <see cref="GraphServiceClient"/> request
/// adapter and parsed with <see cref="System.Text.Json"/>. No business orchestration lives here.
/// </remarks>
public sealed class GraphFolderTreeReader : IFolderTreeReader
{
    private const int PageSize = 100;
    private readonly IGraphClientFactory _clientFactory;

    public GraphFolderTreeReader(IGraphClientFactory clientFactory)
    {
        ArgumentNullException.ThrowIfNull(clientFactory);
        _clientFactory = clientFactory;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<MailFolderNode>> GetFoldersAsync(CancellationToken ct = default)
    {
        var adapter = _clientFactory.CreateClient().RequestAdapter;
        var baseUrl = GraphRequest.BaseUrl(adapter);
        var results = new List<MailFolderNode>();

        var topLevel = await GetFolderPageAsync(
                adapter,
                $"{baseUrl}/me/mailFolders?$top={PageSize}",
                ct
            )
            .ConfigureAwait(false);

        foreach (var folder in topLevel)
        {
            await AppendFolderAndChildrenAsync(
                    adapter,
                    baseUrl,
                    folder,
                    folder.DisplayName,
                    null,
                    results,
                    ct
                )
                .ConfigureAwait(false);
        }

        return results;
    }

    private static async Task AppendFolderAndChildrenAsync(
        IRequestAdapter adapter,
        string baseUrl,
        RawFolder folder,
        string path,
        string? parentId,
        List<MailFolderNode> results,
        CancellationToken ct
    )
    {
        results.Add(
            new MailFolderNode(
                folder.Id,
                folder.DisplayName,
                path,
                parentId,
                folder.ChildFolderCount
            )
        );

        if (folder.ChildFolderCount <= 0)
        {
            return;
        }

        var escapedId = Uri.EscapeDataString(folder.Id);
        var children = await GetFolderPageAsync(
                adapter,
                $"{baseUrl}/me/mailFolders/{escapedId}/childFolders?$top={PageSize}",
                ct
            )
            .ConfigureAwait(false);

        foreach (var child in children)
        {
            await AppendFolderAndChildrenAsync(
                    adapter,
                    baseUrl,
                    child,
                    $"{path}/{child.DisplayName}",
                    folder.Id,
                    results,
                    ct
                )
                .ConfigureAwait(false);
        }
    }

    private static async Task<IReadOnlyList<RawFolder>> GetFolderPageAsync(
        IRequestAdapter adapter,
        string url,
        CancellationToken ct
    )
    {
        var folders = new List<RawFolder>();
        var nextUrl = url;

        while (!string.IsNullOrEmpty(nextUrl))
        {
            var request = new RequestInformation
            {
                HttpMethod = Method.GET,
                URI = new Uri(nextUrl),
            };
            var stream = await adapter
                .SendPrimitiveAsync<Stream>(request, cancellationToken: ct)
                .ConfigureAwait(false);
            if (stream is null)
            {
                break;
            }

            await using (stream.ConfigureAwait(false))
            {
                nextUrl = await ParseFolderPageAsync(stream, folders, ct).ConfigureAwait(false);
            }
        }

        return folders;
    }

    private static async Task<string?> ParseFolderPageAsync(
        Stream stream,
        List<RawFolder> folders,
        CancellationToken ct
    )
    {
        using var document = await JsonDocument
            .ParseAsync(stream, cancellationToken: ct)
            .ConfigureAwait(false);
        var root = document.RootElement;
        if (root.TryGetProperty("value", out var value) && value.ValueKind == JsonValueKind.Array)
        {
            foreach (var element in value.EnumerateArray())
            {
                folders.Add(RawFolder.From(element));
            }
        }

        return
            root.TryGetProperty("@odata.nextLink", out var next)
            && next.ValueKind == JsonValueKind.String
            ? next.GetString()
            : null;
    }

    private sealed record RawFolder(string Id, string DisplayName, int ChildFolderCount)
    {
        public static RawFolder From(JsonElement element)
        {
            var id = element.TryGetProperty("id", out var idEl) ? idEl.GetString() : null;
            var name = element.TryGetProperty("displayName", out var nameEl)
                ? nameEl.GetString()
                : null;
            var count =
                element.TryGetProperty("childFolderCount", out var countEl)
                && countEl.TryGetInt32(out var c)
                    ? c
                    : 0;
            return new RawFolder(id ?? string.Empty, name ?? string.Empty, count);
        }
    }
}
