using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NSubstitute;
using TaskMaster.Application;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Unit tests for <see cref="ServiceProviderCommandBus"/>.
/// Verifies that <see cref="ICommandBus.DispatchAsync{TCommand}"/> resolves and invokes
/// the registered handler, and fails fast when no handler is registered.
/// </summary>
public sealed class CommandBusTests
{
    [Fact]
    public async Task DispatchAsync_WithRegisteredHandler_CallsHandleAsync()
    {
        // Arrange
        var handler = Substitute.For<ICommandHandler<TestCommand>>();
        var services = new ServiceCollection();
        services.AddScoped<ICommandHandler<TestCommand>>(_ => handler);
        services.AddScoped<ICommandBus, ServiceProviderCommandBus>();
        await using var sp = services.BuildServiceProvider();
        var bus = sp.GetRequiredService<ICommandBus>();
        var command = new TestCommand("hello");

        // Act
        await bus.DispatchAsync(command).ConfigureAwait(true);

        // Assert
        await handler.Received(1).HandleAsync(command, default).ConfigureAwait(true);
    }

    [Fact]
    public async Task DispatchAsync_WithNoRegisteredHandler_ThrowsInvalidOperationException()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddScoped<ICommandBus, ServiceProviderCommandBus>();
        await using var sp = services.BuildServiceProvider();
        var bus = sp.GetRequiredService<ICommandBus>();
        var command = new TestCommand("no-handler");

        // Act
        Func<Task> act = () => bus.DispatchAsync(command);

        // Assert
        await act.Should().ThrowAsync<InvalidOperationException>().ConfigureAwait(true);
    }
}
