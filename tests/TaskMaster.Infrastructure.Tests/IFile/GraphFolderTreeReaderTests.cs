using FluentAssertions;
using TaskMaster.Infrastructure.IFile;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// WireMock.Net tests for <see cref="GraphFolderTreeReader"/>: top-level enumeration,
/// recursive child enumeration, and full-path construction.
/// </summary>
public sealed class GraphFolderTreeReaderTests : IDisposable
{
    private readonly WireMockServer _server = WireMockServer.Start();

    [Fact]
    public async Task GetFoldersAsync_EnumeratesTopLevelAndChildren_WithPaths()
    {
        // Arrange — top-level "Archive" with one child "Clients" which itself has a leaf "Acme".
        _server
            .Given(Request.Create().WithPath("/me/mailFolders").UsingGet())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody(
                        "{\"value\":[{\"id\":\"archive\",\"displayName\":\"Archive\",\"childFolderCount\":1}]}"
                    )
            );
        _server
            .Given(Request.Create().WithPath("/me/mailFolders/archive/childFolders").UsingGet())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody(
                        "{\"value\":[{\"id\":\"clients\",\"displayName\":\"Clients\",\"childFolderCount\":1}]}"
                    )
            );
        _server
            .Given(Request.Create().WithPath("/me/mailFolders/clients/childFolders").UsingGet())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody(
                        "{\"value\":[{\"id\":\"acme\",\"displayName\":\"Acme\",\"childFolderCount\":0}]}"
                    )
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var reader = new GraphFolderTreeReader(graph.Factory);

        // Act
        var folders = await reader.GetFoldersAsync().ConfigureAwait(true);

        // Assert
        folders.Should().HaveCount(3);
        var acme = folders.Single(f => string.Equals(f.Id, "acme", StringComparison.Ordinal));
        acme.Path.Should().Be("Archive/Clients/Acme");
        acme.ParentFolderId.Should().Be("clients");
        acme.ChildFolderCount.Should().Be(0);
        folders
            .Single(f => string.Equals(f.Id, "archive", StringComparison.Ordinal))
            .ParentFolderId.Should()
            .BeNull();
    }

    public void Dispose() => _server.Dispose();
}
