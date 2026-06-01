using System.Text.Json;
using FluentAssertions;
using TaskMaster.Application.IFile;
using TaskMaster.Infrastructure.IFile;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// WireMock.Net tests for <see cref="GraphMessageMover"/> (AC-12): verifies the
/// <c>POST /me/messages/{id}/move</c> request path and the <c>{ destinationId }</c> body.
/// </summary>
public sealed class GraphMessageMoverTests : IDisposable
{
    private readonly WireMockServer _server = WireMockServer.Start();

    [Fact]
    public async Task MoveAsync_PostsMoveWithDestinationIdBody()
    {
        // Arrange
        _server
            .Given(Request.Create().WithPath("/me/messages/msg-1/move").UsingPost())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(201)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody("{\"id\":\"msg-1\"}")
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var mover = new GraphMessageMover(graph.Factory);

        // Act
        await mover.MoveAsync("msg-1", "folder-acme").ConfigureAwait(true);

        // Assert — exactly one move POST with the documented body shape.
        var requests = _server
            .FindLogEntries(Request.Create().WithPath("/me/messages/msg-1/move").UsingPost())
            .ToList();
        requests.Should().ContainSingle();
        var bodyJson = requests[0].RequestMessage.Body ?? "{}";
        using var doc = JsonDocument.Parse(bodyJson);
        doc.RootElement.GetProperty("destinationId").GetString().Should().Be("folder-acme");
    }

    public void Dispose() => _server.Dispose();
}
