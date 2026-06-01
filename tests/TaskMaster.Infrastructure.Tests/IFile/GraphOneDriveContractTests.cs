using System.Text.Json;
using FluentAssertions;
using TaskMaster.Application.IFile;
using TaskMaster.Infrastructure.IFile;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// Graph drive folder-create + upload contract test (AC-13, AC-15, CI portion): asserts the
/// create-folder body (<c>folder</c> facet + <c>@microsoft.graph.conflictBehavior: "fail"</c>)
/// and the simple-PUT vs. upload-session selection at the 10 MiB threshold.
/// </summary>
public sealed class GraphOneDriveContractTests : IDisposable
{
    private readonly WireMockServer _server = WireMockServer.Start();

    [Fact]
    public async Task EnsureFolderPath_CreateBodyMatchesDriveFolderContract()
    {
        // Arrange
        _server
            .Given(Request.Create().WithPath("/me/drive/items/root/children").UsingPost())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(201)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody("{\"id\":\"new-folder\"}")
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);

        // Act
        await writer.EnsureFolderPathAsync("root", "Clients").ConfigureAwait(true);

        // Assert — create body carries the folder facet and conflictBehavior "fail".
        var entries = _server
            .FindLogEntries(Request.Create().WithPath("/me/drive/items/root/children").UsingPost())
            .ToList();
        entries.Should().ContainSingle();
        using var doc = JsonDocument.Parse(entries[0].RequestMessage.Body ?? "{}");
        doc.RootElement.GetProperty("name").GetString().Should().Be("Clients");
        doc.RootElement.GetProperty("folder").ValueKind.Should().Be(JsonValueKind.Object);
        doc.RootElement.GetProperty("@microsoft.graph.conflictBehavior")
            .GetString()
            .Should()
            .Be("fail");
    }

    [Fact]
    public async Task Upload_AtThreshold_UsesSimplePut()
    {
        // Arrange — exactly 10 MiB is at the threshold → simple PUT (not an upload session).
        _server
            .Given(Request.Create().WithPath("/me/drive/items/f1:/at.bin:/content").UsingPut())
            .RespondWith(Response.Create().WithStatusCode(201).WithBody("{\"id\":\"f\"}"));
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);
        var content = new AttachmentContent(
            "at.bin",
            new byte[GraphOneDriveFolderWriter.SimpleUploadMaxBytes]
        );

        // Act
        await writer.UploadFileAsync("f1", content).ConfigureAwait(true);

        // Assert
        _server
            .FindLogEntries(
                Request.Create().WithPath("/me/drive/items/f1:/at.bin:/content").UsingPut()
            )
            .Should()
            .ContainSingle();
    }

    [Fact]
    public async Task Upload_AboveThreshold_UsesUploadSession()
    {
        // Arrange — one byte over 10 MiB → upload session.
        _server
            .Given(
                Request
                    .Create()
                    .WithPath("/me/drive/items/f1:/over.bin:/createUploadSession")
                    .UsingPost()
            )
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody($"{{\"uploadUrl\":\"{_server.Url}/session/1\"}}")
            );
        _server
            .Given(Request.Create().WithPath("/session/1").UsingPut())
            .RespondWith(Response.Create().WithStatusCode(201).WithBody("{\"id\":\"f\"}"));
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);
        var content = new AttachmentContent(
            "over.bin",
            new byte[GraphOneDriveFolderWriter.SimpleUploadMaxBytes + 1]
        );

        // Act
        await writer.UploadFileAsync("f1", content).ConfigureAwait(true);

        // Assert
        _server
            .FindLogEntries(
                Request
                    .Create()
                    .WithPath("/me/drive/items/f1:/over.bin:/createUploadSession")
                    .UsingPost()
            )
            .Should()
            .ContainSingle();
    }

    public void Dispose() => _server.Dispose();
}
