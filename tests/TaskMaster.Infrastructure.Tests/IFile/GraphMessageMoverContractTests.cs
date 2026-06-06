using System.Text.Json;
using FluentAssertions;
using TaskMaster.Infrastructure.IFile;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// Graph move-request contract test (AC-12, CI portion): asserts the
/// <c>POST /me/messages/{id}/move</c> request path and the exact <c>{ "destinationId": ... }</c>
/// body shape via WireMock.Net.
/// </summary>
public sealed class GraphMessageMoverContractTests : IDisposable
{
    private readonly WireMockServer _server = WireMockServer.Start();

    [Fact]
    public async Task MoveAsync_RequestMatchesGraphMoveContract()
    {
        // Arrange
        _server
            .Given(Request.Create().WithPath("/me/messages/AAMkAGI/move").UsingPost())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(201)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody("{\"id\":\"AAMkAGI\"}")
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var mover = new GraphMessageMover(graph.Factory);

        // Act
        await mover.MoveAsync("AAMkAGI", "destination-folder").ConfigureAwait(true);

        // Assert — exactly one POST to the move path with a body of only { destinationId }.
        var entries = _server
            .FindLogEntries(Request.Create().WithPath("/me/messages/AAMkAGI/move").UsingPost())
            .ToList();
        entries.Should().ContainSingle();
        using var doc = JsonDocument.Parse(entries[0].RequestMessage.Body ?? "{}");
        doc.RootElement.EnumerateObject().Select(p => p.Name).Should().Equal("destinationId");
        doc.RootElement.GetProperty("destinationId").GetString().Should().Be("destination-folder");
    }

    public void Dispose() => _server.Dispose();
}
