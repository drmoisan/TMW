namespace TaskMaster.Application.Tests;

/// <summary>Test command used in <see cref="CommandBusTests"/>.</summary>
internal sealed record TestCommand(string Payload);
