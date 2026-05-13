using Microsoft.Extensions.DependencyInjection;

namespace TaskMaster.Application;

/// <summary>
/// Extension methods for registering Application-layer services in the DI container.
/// </summary>
public static class ApplicationServiceCollectionExtensions
{
    /// <summary>
    /// Registers all Application-layer services: <see cref="ICommandBus"/> → <see cref="ServiceProviderCommandBus"/> (Scoped).
    /// </summary>
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<ICommandBus, ServiceProviderCommandBus>();
        return services;
    }
}
