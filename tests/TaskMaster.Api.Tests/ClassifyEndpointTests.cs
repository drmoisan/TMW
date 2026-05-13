using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Integration tests for the POST /api/classify endpoint.
/// Verifies authentication enforcement, successful classification, and input validation.
/// </summary>
public sealed class ClassifyEndpointTests : IClassFixture<CustomWebApplicationFactory>
{
    private static readonly Uri s_classifyUri = new("/api/classify", UriKind.Relative);
    private readonly CustomWebApplicationFactory _factory;

    public ClassifyEndpointTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task PostClassify_WithoutAuthorizationHeader_Returns401()
    {
        // Arrange — use the unauthenticated factory so real bearer middleware is active.
        var unauthFactory = new UnauthenticatedWebApplicationFactory();
        using var client = unauthFactory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );

        // Act
        using var response = await client
            .PostAsJsonAsync(s_classifyUri, new { messageId = "id", subject = "urgent test" })
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await unauthFactory.DisposeAsync().ConfigureAwait(true);
    }

    [Fact]
    public async Task PostClassify_AuthenticatedWithValidRequest_Returns200WithLabelAndConfidence()
    {
        // Arrange
        using var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );
        client.DefaultRequestHeaders.Add("Authorization", "Test");
        var payload = new { messageId = "msg-001@test.local", subject = "urgent test message" };

        // Act
        using var response = await client
            .PostAsJsonAsync(s_classifyUri, payload)
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>().ConfigureAwait(true);
        body.TryGetProperty("label", out _).Should().BeTrue("response must contain 'label' key");
        body.TryGetProperty("confidence", out _)
            .Should()
            .BeTrue("response must contain 'confidence' key");
    }

    [Fact]
    public async Task PostClassify_AuthenticatedWithEmptySubject_Returns422()
    {
        // Arrange
        using var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );
        client.DefaultRequestHeaders.Add("Authorization", "Test");
        var payload = new { messageId = "msg-001@test.local", subject = "" };

        // Act
        using var response = await client
            .PostAsJsonAsync(s_classifyUri, payload)
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.UnprocessableEntity);
    }
}
