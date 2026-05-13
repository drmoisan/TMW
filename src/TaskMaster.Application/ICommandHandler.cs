namespace TaskMaster.Application;

/// <summary>
/// Handles a command of type <typeparamref name="TCommand"/>.
/// Register one implementation per command type in the DI container.
/// </summary>
/// <typeparam name="TCommand">The command type this handler processes.</typeparam>
public interface ICommandHandler<in TCommand>
{
    /// <summary>Executes the given command asynchronously.</summary>
    Task HandleAsync(TCommand command, CancellationToken ct = default);
}
