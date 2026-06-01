using FluentAssertions;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Unit tests for <see cref="OutlookToOneDrivePath.Map"/> (AC-14).
/// </summary>
public sealed class OutlookToOneDrivePathTests
{
    [Fact]
    public void Map_NestedArchivePath_StripsLeadingArchiveSegment()
    {
        // Arrange / Act
        var result = OutlookToOneDrivePath.Map("Archive/Clients/Acme");

        // Assert
        result.Should().Be("Clients/Acme");
    }

    [Fact]
    public void Map_BareArchiveRoot_ReturnsEmptyRelativePath()
    {
        // Arrange / Act
        var result = OutlookToOneDrivePath.Map("Archive");

        // Assert
        result.Should().BeEmpty();
    }

    [Fact]
    public void Map_SingleLevelBeneathArchive_ReturnsThatSegment()
    {
        OutlookToOneDrivePath.Map("Archive/Finance").Should().Be("Finance");
    }

    [Fact]
    public void Map_NonArchiveRootedPath_Throws()
    {
        // Arrange
        var act = () => OutlookToOneDrivePath.Map("Inbox/Clients/Acme");

        // Act / Assert
        act.Should().Throw<ArgumentException>().WithMessage("*Archive*");
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Map_EmptyOrWhitespace_Throws(string path)
    {
        var act = () => OutlookToOneDrivePath.Map(path);
        act.Should().Throw<ArgumentException>();
    }
}
