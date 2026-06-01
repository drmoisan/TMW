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
using TaskMaster.Application.IFile;

namespace TaskMaster.Api.Tests.IFile;

// CA1515 suppressed: must be public because it is used as an IClassFixture<T> type parameter.
#pragma warning disable CA1515
/// <summary>
/// Authenticated <see cref="WebApplicationFactory{TEntryPoint}"/> (TestAuthHandler scheme) with
/// substituted iFile server dependencies — a faked <see cref="IFolderTreeReader"/> and a stub
/// filing command handler — so the iFile endpoints exercise the dispatch/response seam without
/// real Graph access.
/// </summary>
public sealed class FilingWebApplicationFactory : WebApplicationFactory<Program>
{
    /// <summary>Result the substituted filing handler publishes; defaults to success.</summary>
    public FileMessageResult HandlerResult { get; set; } = FileMessageResult.Success();

    /// <inheritdoc/>
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        builder.ConfigureServices(services =>
        {
            services
                .AddAuthentication(TestAuthHandler.SchemeName)
                .AddScheme<TestAuthHandlerOptions, TestAuthHandler>(
                    TestAuthHandler.SchemeName,
                    _ => { }
                );
            RemoveAll<ITokenAcquisition>(services);
            RemoveAll<IAuthorizationHeaderProvider>(services);
            RemoveAll<IMsalTokenCacheProvider>(services);
            RemoveAll<GraphServiceClient>(services);
            RemoveAll<IGraphClientFactory>(services);
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

            Replace<IFolderTreeReader>(
                services,
                _ =>
                {
                    var reader = Substitute.For<IFolderTreeReader>();
                    reader
                        .GetFoldersAsync(Arg.Any<CancellationToken>())
                        .Returns(
                            new[]
                            {
                                new MailFolderNode("archive", "Archive", "Archive", null, 1),
                                new MailFolderNode(
                                    "acme",
                                    "Acme",
                                    "Archive/Clients/Acme",
                                    "clients",
                                    0
                                ),
                            }
                        );
                    return reader;
                }
            );

            Replace<ICommandHandler<FileMessageCommand>>(
                services,
                _ => new StubFilingHandler(() => HandlerResult)
            );
        });
    }

    private static void Replace<T>(IServiceCollection services, Func<IServiceProvider, T> factory)
        where T : class
    {
        RemoveAll<T>(services);
        services.AddScoped(factory);
    }

    private static void RemoveAll<T>(IServiceCollection services)
    {
        var descriptors = services.Where(d => d.ServiceType == typeof(T)).ToList();
        foreach (var descriptor in descriptors)
        {
            services.Remove(descriptor);
        }
    }
}
#pragma warning restore CA1515
