using Microsoft.Graph;

namespace TaskMaster.Application;

/// <summary>
/// Factory that produces a pre-configured <see cref="GraphServiceClient"/>.
/// Implementations live in TaskMaster.Infrastructure and wire up the Graph SDK
/// with the bearer token sourced from the current request context.
/// </summary>
public interface IGraphClientFactory
{
    /// <summary>Returns a <see cref="GraphServiceClient"/> ready to make Graph API calls.</summary>
    GraphServiceClient CreateClient();
}
