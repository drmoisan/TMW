using FluentAssertions;
using Microsoft.Graph;
using Microsoft.Kiota.Abstractions.Authentication;
using NSubstitute;
using TaskMaster.Infrastructure;

namespace TaskMaster.Infrastructure.Tests;

/// <summary>
/// Unit tests for <see cref="GraphClientFactory"/>.
/// Verifies that <see cref="GraphClientFactory.CreateClient"/> returns the injected client.
/// </summary>
public sealed class GraphClientFactoryTests
{
    [Fact]
    public void CreateClient_ReturnsInjectedGraphServiceClient()
    {
        // Arrange
        var authProvider = Substitute.For<IAuthenticationProvider>();
        using var client = new GraphServiceClient(authProvider);
        var factory = new GraphClientFactory(client);

        // Act
        var result = factory.CreateClient();

        // Assert
        result.Should().BeSameAs(client);
    }
}
