using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using NSubstitute;
using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Integration tests for <see cref="FileMessageCommandHandler"/> against faked adapters
/// (AC-13, AC-16, AC-17). Verifies attachments-first, move-last ordering, the no-attachment
/// fast path, and mirrored subfolder creation.
/// </summary>
public sealed class FileMessageCommandHandlerTests
{
    private const string UserId = "user-1";
    private const string ArchiveRootId = "drive-archive-root";

    private static readonly IReadOnlyList<MailFolderNode> Folders = new[]
    {
        new MailFolderNode("archive", "Archive", "Archive", null, 1),
        new MailFolderNode("acme", "Acme", "Archive/Clients/Acme", "clients", 0),
    };

    private static FileMessageCommand Command() =>
        new(
            MessageRestId: "msg-1",
            DestinationFolderId: "acme",
            ArchiveRootDriveItemId: ArchiveRootId,
            UserId: UserId
        );

    private static FileMessageCommandHandler CreateHandler(
        IFolderTreeReader folders,
        IAttachmentSource attachments,
        IOneDriveFolderWriter writer,
        IMessageMover mover,
        IUserSettingsRepository settings
    ) =>
        new(
            folders,
            attachments,
            writer,
            mover,
            settings,
            NullLogger<FileMessageCommandHandler>.Instance
        );

    [Fact]
    public async Task HandleAsync_UploadsBeforeMove_AndMovesLast()
    {
        // Arrange
        var calls = new List<string>();
        var folders = Substitute.For<IFolderTreeReader>();
        folders.GetFoldersAsync(Arg.Any<CancellationToken>()).Returns(Folders);

        var attachments = Substitute.For<IAttachmentSource>();
        attachments
            .ListAttachmentsAsync("msg-1", Arg.Any<CancellationToken>())
            .Returns(new[] { new AttachmentMetadata("a1", "report.pdf", "file", false, 1024) });
        attachments
            .GetAttachmentContentAsync("msg-1", "a1", Arg.Any<CancellationToken>())
            .Returns(new AttachmentContent("report.pdf", new byte[] { 1, 2, 3 }));

        var writer = Substitute.For<IOneDriveFolderWriter>();
        writer
            .EnsureFolderPathAsync(ArchiveRootId, "Clients/Acme", Arg.Any<CancellationToken>())
            .Returns(ci =>
            {
                calls.Add("ensure");
                return "drive-acme";
            });
        writer
            .UploadFileAsync(
                "drive-acme",
                Arg.Any<AttachmentContent>(),
                Arg.Any<CancellationToken>()
            )
            .Returns(ci =>
            {
                calls.Add("upload");
                return Task.CompletedTask;
            });

        var mover = Substitute.For<IMessageMover>();
        mover
            .MoveAsync("msg-1", "acme", Arg.Any<CancellationToken>())
            .Returns(ci =>
            {
                calls.Add("move");
                return Task.CompletedTask;
            });

        var settings = Substitute.For<IUserSettingsRepository>();
        var command = Command();
        var handler = CreateHandler(folders, attachments, writer, mover, settings);

        // Act
        await handler.HandleAsync(command).ConfigureAwait(true);
        var result = await command.ResultSink.Task.ConfigureAwait(true);

        // Assert: ordering is ensure -> upload -> move; move is last.
        result.Outcome.Should().Be(FileMessageOutcome.Success);
        calls.Should().Equal("ensure", "upload", "move");
    }

    [Fact]
    public async Task HandleAsync_NoAttachments_SkipsUploadAndMoves()
    {
        // Arrange
        var folders = Substitute.For<IFolderTreeReader>();
        folders.GetFoldersAsync(Arg.Any<CancellationToken>()).Returns(Folders);

        var attachments = Substitute.For<IAttachmentSource>();
        attachments
            .ListAttachmentsAsync("msg-1", Arg.Any<CancellationToken>())
            .Returns(Array.Empty<AttachmentMetadata>());

        var writer = Substitute.For<IOneDriveFolderWriter>();
        writer
            .EnsureFolderPathAsync(ArchiveRootId, "Clients/Acme", Arg.Any<CancellationToken>())
            .Returns("drive-acme");

        var mover = Substitute.For<IMessageMover>();
        var settings = Substitute.For<IUserSettingsRepository>();
        var command = Command();
        var handler = CreateHandler(folders, attachments, writer, mover, settings);

        // Act
        await handler.HandleAsync(command).ConfigureAwait(true);
        var result = await command.ResultSink.Task.ConfigureAwait(true);

        // Assert
        result.Outcome.Should().Be(FileMessageOutcome.Success);
        await writer
            .DidNotReceive()
            .UploadFileAsync(
                Arg.Any<string>(),
                Arg.Any<AttachmentContent>(),
                Arg.Any<CancellationToken>()
            )
            .ConfigureAwait(true);
        await mover
            .Received(1)
            .MoveAsync("msg-1", "acme", Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
    }

    [Fact]
    public async Task HandleAsync_CreatesMirroredSubfolderPath()
    {
        // Arrange
        var folders = Substitute.For<IFolderTreeReader>();
        folders.GetFoldersAsync(Arg.Any<CancellationToken>()).Returns(Folders);

        var attachments = Substitute.For<IAttachmentSource>();
        attachments
            .ListAttachmentsAsync("msg-1", Arg.Any<CancellationToken>())
            .Returns(Array.Empty<AttachmentMetadata>());

        var writer = Substitute.For<IOneDriveFolderWriter>();
        writer
            .EnsureFolderPathAsync(ArchiveRootId, "Clients/Acme", Arg.Any<CancellationToken>())
            .Returns("drive-acme");

        var mover = Substitute.For<IMessageMover>();
        var settings = Substitute.For<IUserSettingsRepository>();
        var handler = CreateHandler(folders, attachments, writer, mover, settings);

        // Act
        var command = Command();
        await handler.HandleAsync(command).ConfigureAwait(true);
        await command.ResultSink.Task.ConfigureAwait(true);

        // Assert: the mirrored relative path under the Archive root is created.
        await writer
            .Received(1)
            .EnsureFolderPathAsync(ArchiveRootId, "Clients/Acme", Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
    }
}
