using Microsoft.Graph;
using TaskMaster.Application;

namespace TaskMaster.Infrastructure;

/// <summary>
/// Infrastructure implementation of <see cref="IGraphClientFactory"/>.
/// Wraps the DI-injected <see cref="GraphServiceClient"/> that is pre-configured
/// by <c>Microsoft.Identity.Web.GraphServiceClient</c> with OBO token acquisition.
/// </summary>
public sealed class GraphClientFactory : IGraphClientFactory
{
    private readonly GraphServiceClient _client;

    /// <param name="client">
    /// The DI-resolved <see cref="GraphServiceClient"/> configured by
    /// <c>services.AddMicrosoftGraph()</c> in the API host.
    /// </param>
    public GraphClientFactory(GraphServiceClient client)
    {
        _client = client;
    }

    /// <inheritdoc/>
    public GraphServiceClient CreateClient() => _client;
}
