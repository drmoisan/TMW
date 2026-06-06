using System.Text;
using FluentAssertions;
using TaskMaster.Infrastructure.IFile;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;

namespace TaskMaster.Infrastructure.Tests.IFile;

/// <summary>
/// WireMock.Net tests for <see cref="GraphAttachmentSource"/>: attachment-metadata listing
/// (file vs. item, inline flag) and content fetch (base64 contentBytes decoding).
/// </summary>
public sealed class GraphAttachmentSourceTests : IDisposable
{
    private readonly WireMockServer _server = WireMockServer.Start();

    [Fact]
    public async Task ListAttachmentsAsync_MapsFileAndItemTypesAndInlineFlag()
    {
        // Arrange
        _server
            .Given(Request.Create().WithPath("/me/messages/msg-1/attachments").UsingGet())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody(
                        "{\"value\":["
                            + "{\"@odata.type\":\"#microsoft.graph.fileAttachment\",\"id\":\"a1\",\"name\":\"r.pdf\",\"isInline\":false,\"size\":10},"
                            + "{\"@odata.type\":\"#microsoft.graph.itemAttachment\",\"id\":\"a2\",\"name\":\"e.eml\",\"isInline\":false,\"size\":20}"
                            + "]}"
                    )
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var source = new GraphAttachmentSource(graph.Factory);

        // Act
        var attachments = await source.ListAttachmentsAsync("msg-1").ConfigureAwait(true);

        // Assert
        attachments.Should().HaveCount(2);
        attachments
            .Single(a => string.Equals(a.Id, "a1", StringComparison.Ordinal))
            .AttachmentType.Should()
            .Be("file");
        attachments
            .Single(a => string.Equals(a.Id, "a2", StringComparison.Ordinal))
            .AttachmentType.Should()
            .Be("item");
        attachments
            .Single(a => string.Equals(a.Id, "a1", StringComparison.Ordinal))
            .Size.Should()
            .Be(10);
    }

    [Fact]
    public async Task GetAttachmentContentAsync_DecodesBase64ContentBytes()
    {
        // Arrange
        var bytes = Encoding.UTF8.GetBytes("hello");
        var base64 = Convert.ToBase64String(bytes);
        _server
            .Given(Request.Create().WithPath("/me/messages/msg-1/attachments/a1").UsingGet())
            .RespondWith(
                Response
                    .Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody($"{{\"name\":\"r.pdf\",\"contentBytes\":\"{base64}\"}}")
            );
        using var graph = GraphTestClient.Create(_server.Url!);
        var source = new GraphAttachmentSource(graph.Factory);

        // Act
        var content = await source.GetAttachmentContentAsync("msg-1", "a1").ConfigureAwait(true);

        // Assert
        content.Name.Should().Be("r.pdf");
        Encoding.UTF8.GetString(content.Content.ToArray()).Should().Be("hello");
    }

    public void Dispose() => _server.Dispose();
}
