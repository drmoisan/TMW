using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Time.Testing;
using NSubstitute;
using TaskMaster.Application;
using TaskMaster.Application.IFile;
using TaskMaster.Infrastructure;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Archive-root mapping persistence and reuse tests (AC-21, AC-22, AC-23). Uses the real
/// <see cref="InMemoryUserSettingsRepository"/> through the <see cref="IUserSettingsRepository"/>
/// abstraction.
/// </summary>
public sealed class ArchiveRootMappingTests
{
    private const string UserId = "user-1";
    private const string ChosenRootId = "drive-chosen-root";

    private static readonly IReadOnlyList<MailFolderNode> Folders = new[]
    {
        new MailFolderNode("acme", "Acme", "Archive/Clients/Acme", "clients", 0),
    };

    private static (
        IFolderTreeReader Folders,
        IAttachmentSource Attachments,
        IOneDriveFolderWriter Writer,
        IMessageMover Mover
    ) CreateGraphFakes()
    {
        var folders = Substitute.For<IFolderTreeReader>();
        folders.GetFoldersAsync(Arg.Any<CancellationToken>()).Returns(Folders);

        var attachments = Substitute.For<IAttachmentSource>();
        attachments
            .ListAttachmentsAsync("msg-1", Arg.Any<CancellationToken>())
            .Returns(Array.Empty<AttachmentMetadata>());

        var writer = Substitute.For<IOneDriveFolderWriter>();
        writer
            .EnsureFolderPathAsync(
                Arg.Any<string>(),
                Arg.Any<string>(),
                Arg.Any<CancellationToken>()
            )
            .Returns("drive-acme");

        var mover = Substitute.For<IMessageMover>();
        return (folders, attachments, writer, mover);
    }

    private static FileMessageCommandHandler CreateHandler(
        IUserSettingsRepository settings,
        out IMessageMover mover,
        out IOneDriveFolderWriter writer
    )
    {
        var (folders, attachments, w, m) = CreateGraphFakes();
        mover = m;
        writer = w;
        return new FileMessageCommandHandler(
            folders,
            attachments,
            w,
            m,
            settings,
            NullLogger<FileMessageCommandHandler>.Instance
        );
    }

    [Fact]
    public async Task FirstFiling_NoStoredMapping_NoSelection_SurfacesSelectOrCreate()
    {
        // Arrange — empty store, command carries no first-use selection.
        var settings = new InMemoryUserSettingsRepository(new FakeTimeProvider());
        var handler = CreateHandler(settings, out var mover, out _);
        var command = new FileMessageCommand("msg-1", "acme", ArchiveRootDriveItemId: null, UserId);

        // Act
        await handler.HandleAsync(command).ConfigureAwait(true);
        var result = await command.ResultSink.Task.ConfigureAwait(true);

        // Assert: select-or-create surfaced; no Archive folder auto-created; no move.
        result.Outcome.Should().Be(FileMessageOutcome.ArchiveRootRequired);
        (await settings.GetAsync(UserId).ConfigureAwait(true))
            ?.ArchiveRootDriveItemId.Should()
            .BeNull();
        await mover
            .DidNotReceive()
            .MoveAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
    }

    [Fact]
    public async Task FirstFiling_WithSelection_PersistsMapping_AndReadsBackThroughNewInstance()
    {
        // Arrange — shared backing store read through two repository instances.
        var clock = new FakeTimeProvider();
        var writeStore = new InMemoryUserSettingsRepository(clock);
        var handler = CreateHandler(writeStore, out _, out _);
        var command = new FileMessageCommand("msg-1", "acme", ChosenRootId, UserId);

        // Act
        await handler.HandleAsync(command).ConfigureAwait(true);
        var result = await command.ResultSink.Task.ConfigureAwait(true);

        // Assert — mapping persisted and readable through the same abstraction.
        result.Outcome.Should().Be(FileMessageOutcome.Success);
        var readBack = await writeStore.GetAsync(UserId).ConfigureAwait(true);
        readBack.Should().NotBeNull();
        readBack!.ArchiveRootDriveItemId.Should().Be(ChosenRootId);
    }

    [Fact]
    public async Task SecondFiling_ReusesStoredMapping_NoPicker_AndMoves()
    {
        // Arrange — store already has the mapping.
        var clock = new FakeTimeProvider();
        var settings = new InMemoryUserSettingsRepository(clock);
        await settings
            .SaveAsync(new UserSettings(UserId, false, false, default, ChosenRootId))
            .ConfigureAwait(true);
        var handler = CreateHandler(settings, out var mover, out _);

        // Command carries no first-use selection; the stored mapping must be reused.
        var command = new FileMessageCommand("msg-1", "acme", ArchiveRootDriveItemId: null, UserId);

        // Act
        await handler.HandleAsync(command).ConfigureAwait(true);
        var result = await command.ResultSink.Task.ConfigureAwait(true);

        // Assert — no picker (success, not ArchiveRootRequired); message moved.
        result.Outcome.Should().Be(FileMessageOutcome.Success);
        await mover
            .Received(1)
            .MoveAsync("msg-1", "acme", Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
    }
}
