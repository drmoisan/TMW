using System.Text;
using Microsoft.Kiota.Abstractions;
using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Infrastructure.IFile;

/// <summary>
/// Graph adapter that moves a message via <c>POST /me/messages/{id}/move</c> with body
/// <c>{ "destinationId": "..." }</c>. Implements <see cref="IMessageMover"/> (AC-12).
/// </summary>
/// <remarks>
/// The request is issued through the <see cref="GraphServiceClient"/> request adapter so the
/// OBO-configured token flow and base address are reused. No business orchestration lives here.
/// </remarks>
public sealed class GraphMessageMover : IMessageMover
{
    private readonly IGraphClientFactory _clientFactory;

    public GraphMessageMover(IGraphClientFactory clientFactory)
    {
        ArgumentNullException.ThrowIfNull(clientFactory);
        _clientFactory = clientFactory;
    }

    /// <inheritdoc/>
    public Task MoveAsync(
        string messageRestId,
        string destinationFolderId,
        CancellationToken ct = default
    )
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(messageRestId);
        ArgumentException.ThrowIfNullOrWhiteSpace(destinationFolderId);

        var adapter = _clientFactory.CreateClient().RequestAdapter;
        var escapedId = Uri.EscapeDataString(messageRestId);
        var url = $"{GraphRequest.BaseUrl(adapter)}/me/messages/{escapedId}/move";
        var request = new RequestInformation { HttpMethod = Method.POST, URI = new Uri(url) };
        var body = $"{{\"destinationId\":{GraphRequest.JsonString(destinationFolderId)}}}";
        request.SetStreamContent(
            new MemoryStream(Encoding.UTF8.GetBytes(body)),
            "application/json"
        );

        return adapter.SendNoContentAsync(request, cancellationToken: ct);
    }
}
