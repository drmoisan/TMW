using Microsoft.Graph;
using Microsoft.Kiota.Abstractions.Authentication;
using Microsoft.Kiota.Http.HttpClientLibrary;
using NSubstitute;
using TaskMaster.Application;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// Disposable test helper that builds an <see cref="IGraphClientFactory"/> whose
/// <see cref="GraphServiceClient"/> request adapter targets a WireMock base URL with an
/// anonymous auth provider, so the iFile Graph adapters issue real HTTP against the mock.
/// Owns the underlying <see cref="HttpClient"/>, adapter, and client and disposes them.
/// </summary>
internal sealed class GraphTestClient : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly GraphServiceClient _graphClient;

    private GraphTestClient(
        HttpClient httpClient,
        GraphServiceClient graphClient,
        IGraphClientFactory factory
    )
    {
        _httpClient = httpClient;
        _graphClient = graphClient;
        Factory = factory;
    }

    /// <summary>The substitute factory returning the WireMock-targeted Graph client.</summary>
    public IGraphClientFactory Factory { get; }

    /// <summary>Creates a helper bound to <paramref name="baseUrl"/>.</summary>
    public static GraphTestClient Create(string baseUrl)
    {
        var httpClient = new HttpClient();
#pragma warning disable CA2000 // Ownership of the adapter transfers to GraphServiceClient, which disposes it in Dispose().
        var adapter = new HttpClientRequestAdapter(
            new AnonymousAuthenticationProvider(),
            httpClient: httpClient
        )
        {
            BaseUrl = baseUrl,
        };
#pragma warning restore CA2000
        var graphClient = new GraphServiceClient(adapter);
        var factory = Substitute.For<IGraphClientFactory>();
        factory.CreateClient().Returns(graphClient);
        return new GraphTestClient(httpClient, graphClient, factory);
    }

    public void Dispose()
    {
        _graphClient.Dispose();
        _httpClient.Dispose();
    }
}
