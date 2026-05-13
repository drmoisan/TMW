using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Integration tests for the POST /api/classify/feedback endpoint.
/// Verifies authentication enforcement and successful feedback recording.
/// </summary>
public sealed class ClassifyFeedbackEndpointTests : IClassFixture<CustomWebApplicationFactory>
{
    private static readonly Uri s_feedbackUri = new("/api/classify/feedback", UriKind.Relative);
    private readonly CustomWebApplicationFactory _factory;

    public ClassifyFeedbackEndpointTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task PostClassifyFeedback_WithoutAuthorizationHeader_Returns401()
    {
        // Arrange — real bearer middleware rejects unauthenticated requests.
        var unauthFactory = new UnauthenticatedWebApplicationFactory();
        using var client = unauthFactory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );

        // Act
        using var response = await client
            .PostAsJsonAsync(
                s_feedbackUri,
                new
                {
                    messageId = "id",
                    label = "General",
                    confirmed = true,
                }
            )
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await unauthFactory.DisposeAsync().ConfigureAwait(true);
    }

    [Fact]
    public async Task PostClassifyFeedback_AuthenticatedWithValidRequest_Returns204()
    {
        // Arrange
        using var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );
        client.DefaultRequestHeaders.Add("Authorization", "Test");
        var payload = new
        {
            messageId = "msg-001@test.local",
            label = "General",
            confirmed = true,
        };

        // Act
        using var response = await client
            .PostAsJsonAsync(s_feedbackUri, payload)
            .ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }
}
