using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Api.Tests.IFile;

/// <summary>
/// Test stub for <see cref="ICommandHandler{TCommand}"/> over <see cref="FileMessageCommand"/>
/// that completes the command's result sink with a fixed result supplied by the factory.
/// </summary>
internal sealed class StubFilingHandler : ICommandHandler<FileMessageCommand>
{
    private readonly Func<FileMessageResult> _result;

    public StubFilingHandler(Func<FileMessageResult> result)
    {
        _result = result;
    }

    public Task HandleAsync(FileMessageCommand command, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(command);
        command.ResultSink.TrySetResult(_result());
        return Task.CompletedTask;
    }
}
