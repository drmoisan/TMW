namespace TaskMaster.Application;

/// <summary>
/// Dispatches commands to their registered <see cref="ICommandHandler{TCommand}"/> implementations.
/// </summary>
public interface ICommandBus
{
    /// <summary>
    /// Dispatches <paramref name="command"/> to its registered handler.
    /// Throws <see cref="InvalidOperationException"/> when no handler is registered.
    /// </summary>
    Task DispatchAsync<TCommand>(TCommand command, CancellationToken ct = default);
}
