using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using TaskMaster.Api;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Integration-style HTTP tests for the /health endpoint mapped in Program.cs.
/// Uses Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactory to host the API
/// in-process so the endpoint, response shape, and content-type can be exercised
/// without binding a real network port.
/// </summary>
public class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public HealthEndpointTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetHealth_ReturnsOkAndStatusOk()
    {
        // Arrange
        using var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );

        // Act
        using var response = await client
            .GetAsync(new System.Uri("/health", System.UriKind.Relative))
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var payload = await response
            .Content.ReadFromJsonAsync<HealthResponse>()
            .ConfigureAwait(true);
        payload.Should().NotBeNull();
        payload!.Status.Should().Be("ok");
    }

    [Fact]
    public async Task GetHealth_ReturnsJsonContentType()
    {
        // Arrange
        using var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );

        // Act
        using var response = await client
            .GetAsync(new System.Uri("/health", System.UriKind.Relative))
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        response.Content.Headers.ContentType.Should().NotBeNull();
        response.Content.Headers.ContentType!.MediaType.Should().StartWith("application/json");
    }
}
