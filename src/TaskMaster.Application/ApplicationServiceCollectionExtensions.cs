using Microsoft.Extensions.DependencyInjection;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application;

/// <summary>
/// Extension methods for registering Application-layer services in the DI container.
/// </summary>
public static class ApplicationServiceCollectionExtensions
{
    /// <summary>
    /// Registers all Application-layer services:
    /// <list type="bullet">
    ///   <item><see cref="ICommandBus"/> → <see cref="ServiceProviderCommandBus"/> (Scoped)</item>
    ///   <item><see cref="ICommandHandler{TCommand}"/> for <see cref="FileMessageCommand"/> →
    ///   <see cref="FileMessageCommandHandler"/> (Scoped)</item>
    /// </list>
    /// </summary>
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<ICommandBus, ServiceProviderCommandBus>();
        services.AddScoped<ICommandHandler<FileMessageCommand>, FileMessageCommandHandler>();
        return services;
    }
}
