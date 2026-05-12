using Microsoft.Extensions.DependencyInjection;

namespace TaskMaster.Application;

/// <summary>
/// <see cref="ICommandBus"/> implementation that resolves command handlers
/// from the DI container at dispatch time.
/// Fails fast with <see cref="InvalidOperationException"/> when no handler is registered.
/// </summary>
internal sealed class ServiceProviderCommandBus : ICommandBus
{
    private readonly IServiceProvider _serviceProvider;

    public ServiceProviderCommandBus(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    /// <inheritdoc/>
    public Task DispatchAsync<TCommand>(TCommand command, CancellationToken ct = default)
    {
        var handler = _serviceProvider.GetRequiredService<ICommandHandler<TCommand>>();
        return handler.HandleAsync(command, ct);
    }
}
