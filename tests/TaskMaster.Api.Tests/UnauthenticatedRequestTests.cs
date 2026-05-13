using System.Net;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Integration tests that verify the real bearer-token middleware rejects requests
/// that carry no <c>Authorization</c> header with <c>401 Unauthorized</c>.
/// </summary>
public sealed class UnauthenticatedRequestTests
    : IClassFixture<UnauthenticatedWebApplicationFactory>
{
    private readonly UnauthenticatedWebApplicationFactory _factory;

    public UnauthenticatedRequestTests(UnauthenticatedWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetPing_WithoutAuthorizationHeader_Returns401Unauthorized()
    {
        // Arrange — client sends no Authorization header; real bearer middleware is active.
        using var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );

        // Act
        using var response = await client
            .GetAsync(new Uri("/api/ping", UriKind.Relative))
            .ConfigureAwait(true);

        // Assert — JWT middleware rejects the unauthenticated request before the handler runs.
        response
            .StatusCode.Should()
            .Be(
                HttpStatusCode.Unauthorized,
                "the /api/ping endpoint requires a valid bearer token"
            );
    }
}
