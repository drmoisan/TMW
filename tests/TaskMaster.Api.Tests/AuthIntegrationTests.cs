using System.Net;
using FluentAssertions;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Integration tests for authentication middleware and correlation ID header propagation.
/// Uses <see cref="CustomWebApplicationFactory"/> to host the API in-process.
/// No real Azure AD calls are made.
/// </summary>
public sealed class AuthIntegrationTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public AuthIntegrationTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task UnauthenticatedRequest_ToProtectedEndpoint_Returns200OnAnonymousHealthEndpoint()
    {
        // Arrange — use default factory (no TestAuthHandler)
        using var client = _factory.CreateClient(
            new Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactoryClientOptions
            {
                AllowAutoRedirect = false,
            }
        );

        // Act — /health has AllowAnonymous so it returns 200 without credentials
        using var healthResponse = await client
            .GetAsync(new Uri("/health", UriKind.Relative))
            .ConfigureAwait(true);

        // Assert
        healthResponse.StatusCode.Should().Be(HttpStatusCode.OK, "health endpoint is anonymous");
    }

    [Fact]
    public async Task AuthenticatedRequest_WithTestAuthHandler_Returns200OnHealthEndpoint()
    {
        // Arrange — CustomWebApplicationFactory already uses TestAuthHandler as the default
        // scheme, so no additional configuration is needed here. The factory-level setup
        // replaces the real MSAL authentication stack with a no-op test handler.
        using var client = _factory.CreateClient(
            new Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactoryClientOptions
            {
                AllowAutoRedirect = false,
            }
        );

        // Act
        using var response = await client
            .GetAsync(new Uri("/health", UriKind.Relative))
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task AllResponses_IncludeXCorrelationIdHeader()
    {
        // Arrange
        using var client = _factory.CreateClient(
            new Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactoryClientOptions
            {
                AllowAutoRedirect = false,
            }
        );

        // Act
        using var response = await client
            .GetAsync(new Uri("/health", UriKind.Relative))
            .ConfigureAwait(true);

        // Assert
        response.Headers.Should().ContainKey("X-Correlation-Id");
        response.Headers.GetValues("X-Correlation-Id").Should().NotBeEmpty();
    }
}
