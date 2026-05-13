using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Graph;
using Microsoft.Identity.Abstractions;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.TokenCacheProviders;
using Microsoft.Kiota.Abstractions.Authentication;
using NSubstitute;
using TaskMaster.Application;

namespace TaskMaster.Api.Tests;

/// <summary>
/// <see cref="WebApplicationFactory{TEntryPoint}"/> that does NOT override the authentication
/// scheme. The real <c>AddMicrosoftIdentityWebApi</c> bearer middleware is left active so that
/// requests without a valid <c>Authorization</c> header receive 401 Unauthorized before the
/// endpoint handler runs. Graph/token services are replaced with stubs to avoid runtime failures
/// when no real Azure AD tenant is available.
/// </summary>
// CA1515 suppressed: must be public because it is used as an IClassFixture<T> type
// parameter in public xUnit test classes (xUnit1000 requires public test classes).
#pragma warning disable CA1515
public sealed class UnauthenticatedWebApplicationFactory : WebApplicationFactory<Program>
{
    /// <inheritdoc/>
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        builder.ConfigureAppConfiguration(
            (_, config) =>
            {
                // Provide minimal AzureAd configuration so that AddMicrosoftIdentityWebApi
                // options validation does not throw at startup. The values are syntactically
                // valid but do not correspond to a real tenant; no outbound AAD calls are made
                // because requests are rejected before token validation occurs.
                var inMemoryConfig = new Dictionary<string, string?>(StringComparer.Ordinal)
                {
                    ["AzureAd:Instance"] = "https://login.microsoftonline.com/",
                    ["AzureAd:TenantId"] = "00000000-0000-0000-0000-000000000001",
                    ["AzureAd:ClientId"] = "00000000-0000-0000-0000-000000000002",
                };
                config.AddInMemoryCollection(inMemoryConfig);
            }
        );

        builder.ConfigureServices(services =>
        {
            // Stub out Graph/token services so the DI container can resolve them without
            // real AAD credentials. Authentication is intentionally left as the real
            // MicrosoftIdentityWebApi bearer middleware.
            RemoveService<ITokenAcquisition>(services);
            RemoveService<IAuthorizationHeaderProvider>(services);
            RemoveService<IMsalTokenCacheProvider>(services);
            RemoveService<GraphServiceClient>(services);
            RemoveService<IGraphClientFactory>(services);

            var authProvider = Substitute.For<IAuthenticationProvider>();
            services.AddScoped<GraphServiceClient>(_ => new GraphServiceClient(authProvider));
            services.AddScoped<IGraphClientFactory>(_ => Substitute.For<IGraphClientFactory>());
            services.AddScoped<ITokenAcquisition>(_ => Substitute.For<ITokenAcquisition>());
            services.AddScoped<IAuthorizationHeaderProvider>(_ =>
                Substitute.For<IAuthorizationHeaderProvider>()
            );
            services.AddScoped<IMsalTokenCacheProvider>(_ =>
                Substitute.For<IMsalTokenCacheProvider>()
            );
        });
    }

    private static void RemoveService<T>(IServiceCollection services)
    {
        var descriptors = services.Where(d => d.ServiceType == typeof(T)).ToList();
        foreach (var descriptor in descriptors)
        {
            services.Remove(descriptor);
        }
    }
}
#pragma warning restore CA1515
