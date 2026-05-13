using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TaskMaster.Application;

namespace TaskMaster.Infrastructure;

/// <summary>
/// Extension methods for registering Infrastructure-layer services in the DI container.
/// </summary>
public static class InfrastructureServiceCollectionExtensions
{
    /// <summary>
    /// Registers all Infrastructure-layer services:
    /// <list type="bullet">
    ///   <item><see cref="IFileWriter"/> → <see cref="FileWriter"/> (Singleton)</item>
    ///   <item><see cref="IUserSettingsRepository"/> → <see cref="InMemoryUserSettingsRepository"/> (Singleton)</item>
    ///   <item><see cref="IGraphClientFactory"/> → <see cref="GraphClientFactory"/> (Scoped)</item>
    ///   <item><see cref="UserSettingsFileOptions"/> bound from <c>UserSettings</c> config section</item>
    /// </list>
    /// </summary>
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services,
        IConfiguration configuration
    )
    {
        ArgumentNullException.ThrowIfNull(services);
        ArgumentNullException.ThrowIfNull(configuration);
        services.AddSingleton<IFileWriter, FileWriter>();
        services.AddSingleton<IUserSettingsRepository>(_ => new InMemoryUserSettingsRepository(
            TimeProvider.System
        ));
        services.AddScoped<IGraphClientFactory, GraphClientFactory>();
        services
            .AddOptions<UserSettingsFileOptions>()
            .Bind(configuration.GetSection("UserSettings"));
        return services;
    }
}
