using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using NSubstitute;
using TaskMaster.Application;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Partial-failure and idempotency tests for <see cref="FileMessageCommandHandler"/>
/// (AC-18). A pre-move OneDrive failure leaves the message in place and returns a clear
/// error; a retry resolves the same folder, creates no duplicate folders/files, then moves.
/// </summary>
public sealed class FileMessageFailureTests
{
    private const string ArchiveRootId = "drive-archive-root";

    private static readonly IReadOnlyList<MailFolderNode> Folders = new[]
    {
        new MailFolderNode("acme", "Acme", "Archive/Clients/Acme", "clients", 0),
    };

    private static (
        IFolderTreeReader Folders,
        IAttachmentSource Attachments,
        IMessageMover Mover,
        IUserSettingsRepository Settings
    ) CreateDependencies()
    {
        var folders = Substitute.For<IFolderTreeReader>();
        folders.GetFoldersAsync(Arg.Any<CancellationToken>()).Returns(Folders);

        var attachments = Substitute.For<IAttachmentSource>();
        attachments
            .ListAttachmentsAsync("msg-1", Arg.Any<CancellationToken>())
            .Returns(new[] { new AttachmentMetadata("a1", "report.pdf", "file", false, 1024) });
        attachments
            .GetAttachmentContentAsync("msg-1", "a1", Arg.Any<CancellationToken>())
            .Returns(new AttachmentContent("report.pdf", new byte[] { 1, 2, 3 }));

        var mover = Substitute.For<IMessageMover>();
        var settings = Substitute.For<IUserSettingsRepository>();
        return (folders, attachments, mover, settings);
    }

    private static FileMessageCommand Command() => new("msg-1", "acme", ArchiveRootId, "user-1");

    [Fact]
    public async Task HandleAsync_PreMoveFailure_DoesNotMove_AndReturnsError()
    {
        // Arrange — writer fails the first EnsureFolderPath call (a pre-move failure).
        var (folders, attachments, mover, settings) = CreateDependencies();
        var writer = new FakeOneDriveFolderWriter(failFirstEnsureCalls: 1);
        var handler = new FileMessageCommandHandler(
            folders,
            attachments,
            writer,
            mover,
            settings,
            NullLogger<FileMessageCommandHandler>.Instance
        );
        var command = Command();

        // Act
        await handler.HandleAsync(command).ConfigureAwait(true);
        var result = await command.ResultSink.Task.ConfigureAwait(true);

        // Assert: pre-move failure; message not moved; clear error returned.
        result.Outcome.Should().Be(FileMessageOutcome.PreMoveFailure);
        result.Error.Should().NotBeNullOrEmpty();
        await mover
            .DidNotReceive()
            .MoveAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
    }

    [Fact]
    public async Task HandleAsync_RetryAfterFailure_IsIdempotent_NoDuplicates_ThenMoves()
    {
        // Arrange — one shared stateful writer across both runs; first ensure fails.
        var (folders, attachments, mover, settings) = CreateDependencies();
        var writer = new FakeOneDriveFolderWriter(failFirstEnsureCalls: 1);
        var handler = new FileMessageCommandHandler(
            folders,
            attachments,
            writer,
            mover,
            settings,
            NullLogger<FileMessageCommandHandler>.Instance
        );

        // Act — first run fails before move.
        var first = Command();
        await handler.HandleAsync(first).ConfigureAwait(true);
        (await first.ResultSink.Task.ConfigureAwait(true))
            .Outcome.Should()
            .Be(FileMessageOutcome.PreMoveFailure);

        // Act — retry succeeds.
        var retry = Command();
        await handler.HandleAsync(retry).ConfigureAwait(true);
        var retryResult = await retry.ResultSink.Task.ConfigureAwait(true);

        // Assert: retry succeeds, exactly one folder and one file (no duplicates), move happens.
        retryResult.Outcome.Should().Be(FileMessageOutcome.Success);
        writer.DistinctFolderCount.Should().Be(1, "create-if-missing must not duplicate folders");
        writer
            .UploadedFiles.Should()
            .ContainSingle("the same file must not be duplicated on retry");
        await mover
            .Received(1)
            .MoveAsync("msg-1", "acme", Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
    }
}
