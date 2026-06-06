using System.Text.Json;
using FluentAssertions;
using TaskMaster.Application.IFile;
using TaskMaster.Infrastructure.IFile;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// WireMock.Net tests for <see cref="GraphOneDriveFolderWriter"/> (AC-13, AC-15): folder
/// create-if-missing (including 409 conflict resolution) and the simple-PUT vs.
/// upload-session selection at the 10 MiB threshold.
/// </summary>
public sealed class GraphOneDriveFolderWriterTests : IDisposable
{
    private readonly WireMockServer _server = WireMockServer.Start();

    [Fact]
    public async Task EnsureFolderPathAsync_CreatesFolderWithConflictBehaviorFail()
    {
        // Arrange
        _server
            .Given(Request.Create().WithPath("/me/drive/items/root/children").UsingPost())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(201)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody("{\"id\":\"folder-clients\"}")
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);

        // Act
        var id = await writer.EnsureFolderPathAsync("root", "Clients").ConfigureAwait(true);

        // Assert
        id.Should().Be("folder-clients");
        var requests = _server
            .FindLogEntries(Request.Create().WithPath("/me/drive/items/root/children").UsingPost())
            .ToList();
        requests.Should().ContainSingle();
        using var doc = JsonDocument.Parse(requests[0].RequestMessage.Body ?? "{}");
        doc.RootElement.GetProperty("name").GetString().Should().Be("Clients");
        doc.RootElement.TryGetProperty("folder", out _).Should().BeTrue();
        doc.RootElement.GetProperty("@microsoft.graph.conflictBehavior")
            .GetString()
            .Should()
            .Be("fail");
    }

    [Fact]
    public async Task EnsureFolderPathAsync_OnConflict_ResolvesExistingFolder()
    {
        // Arrange — create returns 409; the writer then GETs the existing child by name.
        _server
            .Given(Request.Create().WithPath("/me/drive/items/root/children").UsingPost())
            .RespondWith(Response.Create().WithStatusCode(409));
        _server
            .Given(Request.Create().WithPath("/me/drive/items/root:/Clients").UsingGet())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody("{\"id\":\"existing-clients\"}")
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);

        // Act
        var id = await writer.EnsureFolderPathAsync("root", "Clients").ConfigureAwait(true);

        // Assert
        id.Should().Be("existing-clients");
    }

    [Fact]
    public async Task UploadFileAsync_SmallFile_UsesSimplePut()
    {
        // Arrange — a 1 KiB file is below the 10 MiB threshold → simple PUT to /content.
        _server
            .Given(
                Request.Create().WithPath("/me/drive/items/folder1:/report.pdf:/content").UsingPut()
            )
            .RespondWith(Response.Create().WithStatusCode(201).WithBody("{\"id\":\"file-1\"}"));
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);
        var content = new AttachmentContent("report.pdf", new byte[1024]);

        // Act
        await writer.UploadFileAsync("folder1", content).ConfigureAwait(true);

        // Assert
        _server
            .FindLogEntries(
                Request.Create().WithPath("/me/drive/items/folder1:/report.pdf:/content").UsingPut()
            )
            .Should()
            .ContainSingle();
    }

    [Fact]
    public async Task UploadFileAsync_LargeFile_UsesUploadSession()
    {
        // Arrange — a file above 10 MiB triggers an upload session.
        _server
            .Given(
                Request
                    .Create()
                    .WithPath("/me/drive/items/folder1:/big.bin:/createUploadSession")
                    .UsingPost()
            )
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody($"{{\"uploadUrl\":\"{_server.Url}/upload-session/abc\"}}")
            );
        _server
            .Given(Request.Create().WithPath("/upload-session/abc").UsingPut())
            .RespondWith(Response.Create().WithStatusCode(201).WithBody("{\"id\":\"big-1\"}"));
        using var graph = GraphTestClient.Create(_server.Url!);
        var writer = new GraphOneDriveFolderWriter(graph.Factory);
        var large = new byte[GraphOneDriveFolderWriter.SimpleUploadMaxBytes + 1];
        var content = new AttachmentContent("big.bin", large);

        // Act
        await writer.UploadFileAsync("folder1", content).ConfigureAwait(true);

        // Assert — the upload session was created and the content PUT to the session URL.
        _server
            .FindLogEntries(
                Request
                    .Create()
                    .WithPath("/me/drive/items/folder1:/big.bin:/createUploadSession")
                    .UsingPost()
            )
            .Should()
            .ContainSingle();
        _server
            .FindLogEntries(Request.Create().WithPath("/upload-session/abc").UsingPut())
            .Should()
            .ContainSingle();
    }

    public void Dispose() => _server.Dispose();
}
