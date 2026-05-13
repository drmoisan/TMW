using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using NSubstitute;
using TaskMaster.Api;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Unit tests for <see cref="CorrelationIdMiddleware"/>.
/// Uses <see cref="DefaultHttpContext"/> and a mock <see cref="ILogger{T}"/>; no network calls.
/// </summary>
public sealed class CorrelationIdMiddlewareTests
{
    private const string HeaderName = "X-Correlation-Id";

    private static CorrelationIdMiddleware CreateSut() =>
        new(Substitute.For<ILogger<CorrelationIdMiddleware>>());

    [Fact]
    public async Task InvokeAsync_RequestWithoutCorrelationIdHeader_SetsNewGuidOnResponse()
    {
        // Arrange
        var context = new DefaultHttpContext();
        var middleware = CreateSut();
        var nextCalled = false;
        RequestDelegate next = _ =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        };

        // Act
        await middleware.InvokeAsync(context, next).ConfigureAwait(true);

        // Assert
        nextCalled.Should().BeTrue();
        var responseHeader = context.Response.Headers[HeaderName].ToString();
        responseHeader.Should().NotBeNullOrEmpty();
        Guid.TryParse(responseHeader, out _)
            .Should()
            .BeTrue("response header should be a valid GUID");
    }

    [Fact]
    public async Task InvokeAsync_RequestWithExistingCorrelationIdHeader_PreservesValueOnResponse()
    {
        // Arrange
        const string CorrelationId = "test-id-123";
        var context = new DefaultHttpContext();
        context.Request.Headers[HeaderName] = CorrelationId;
        var middleware = CreateSut();
        RequestDelegate next = _ => Task.CompletedTask;

        // Act
        await middleware.InvokeAsync(context, next).ConfigureAwait(true);

        // Assert
        context.Response.Headers[HeaderName].ToString().Should().Be(CorrelationId);
    }
}
