using Microsoft.Extensions.DependencyInjection;
using TaskMaster.Application;

namespace TaskMaster.Classifier;

/// <summary>
/// Extension methods for registering classifier services with the dependency injection container.
/// </summary>
public static class ClassifierServiceCollectionExtensions
{
    /// <summary>
    /// Registers the classifier services required by the TaskMaster.Classifier module.
    /// </summary>
    /// <param name="services">The <see cref="IServiceCollection"/> to register services into.</param>
    /// <returns>The same <see cref="IServiceCollection"/> for chaining.</returns>
    public static IServiceCollection AddClassifierServices(this IServiceCollection services)
    {
        services.AddSingleton<IMessageClassifier, KeywordClassifier>();
        return services;
    }
}
