using FluentAssertions;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Unit tests for <see cref="ArchiveRootResolver.Resolve"/> (AC-14, OD-5): the mailbox
/// Archive root is identified by display name "Archive" directly under the mailbox root,
/// not the Graph well-known mailbox name "archive".
/// </summary>
public sealed class ArchiveRootResolutionTests
{
    private static MailFolderNode Folder(
        string id,
        string displayName,
        string path,
        string? parentId,
        int childCount = 0
    ) => new(id, displayName, path, parentId, childCount);

    [Fact]
    public void Resolve_TopLevelArchiveByDisplayName_IsFound()
    {
        // Arrange
        var folders = new[]
        {
            Folder("inbox", "Inbox", "Inbox", parentId: null, childCount: 0),
            Folder("archive", "Archive", "Archive", parentId: null, childCount: 2),
        };

        // Act
        var result = ArchiveRootResolver.Resolve(folders);

        // Assert
        result.Should().NotBeNull();
        result!.Id.Should().Be("archive");
    }

    [Fact]
    public void Resolve_WellKnownLowercaseArchiveName_IsRejected()
    {
        // Arrange — only a lowercase 'archive' (Graph well-known name) exists; not a match.
        var folders = new[] { Folder("wk", "archive", "archive", parentId: null, childCount: 0) };

        // Act
        var result = ArchiveRootResolver.Resolve(folders);

        // Assert
        result.Should().BeNull("the Graph well-known lowercase 'archive' name must not match");
    }

    [Fact]
    public void Resolve_ArchiveNotAtMailboxRoot_IsRejected()
    {
        // Arrange — an "Archive" folder that is nested (has a parent) must not match.
        var folders = new[]
        {
            Folder("nested", "Archive", "Inbox/Archive", parentId: "inbox", childCount: 0),
        };

        ArchiveRootResolver.Resolve(folders).Should().BeNull();
    }

    [Fact]
    public void Resolve_NoArchiveFolder_ReturnsNull()
    {
        var folders = new[] { Folder("inbox", "Inbox", "Inbox", parentId: null) };
        ArchiveRootResolver.Resolve(folders).Should().BeNull();
    }
}
