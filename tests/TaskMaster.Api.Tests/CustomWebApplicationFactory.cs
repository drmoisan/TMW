using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Graph;
using Microsoft.Identity.Abstractions;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.TokenCacheProviders;
using Microsoft.Kiota.Abstractions.Authentication;
using NSubstitute;
using TaskMaster.Application;

namespace TaskMaster.Api.Tests;

// CA1515 suppressed: must be public because it is used as an IClassFixture<T> type
// parameter in public xUnit test classes (xUnit1000 requires public test classes).
#pragma warning disable CA1515
/// <summary>
/// Custom <see cref="WebApplicationFactory{TEntryPoint}"/> that replaces real Azure AD
/// authentication and Graph SDK with test doubles, so API tests run without real credentials.
/// </summary>
public sealed class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    /// <inheritdoc/>
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        builder.ConfigureServices(services =>
        {
            // Replace the authentication stack with TestAuthHandler so that
            // MicrosoftIdentityWebApi options validation (which requires a real ClientId)
            // is bypassed. Tests that need an anonymous request still pass because
            // /health is mapped with .AllowAnonymous().
            services
                .AddAuthentication(TestAuthHandler.SchemeName)
                .AddScheme<TestAuthHandlerOptions, TestAuthHandler>(
                    TestAuthHandler.SchemeName,
                    _ => { }
                );

            // Remove all services registered by AddMicrosoftIdentityWebApi / AddMicrosoftGraph
            // that require real AAD configuration, then replace with stubs.
            RemoveService<ITokenAcquisition>(services);
            RemoveService<IAuthorizationHeaderProvider>(services);
            RemoveService<IMsalTokenCacheProvider>(services);
            RemoveService<GraphServiceClient>(services);
            RemoveService<IGraphClientFactory>(services);

            // Register stubs.
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
