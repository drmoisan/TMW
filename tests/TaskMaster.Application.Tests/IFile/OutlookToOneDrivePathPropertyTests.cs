using CsCheck;
using FluentAssertions;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Property-based tests for <see cref="OutlookToOneDrivePath.Map"/> (AC-14, T2 property gate).
/// CsCheck prints the failing seed on failure for reproducibility.
/// </summary>
public sealed class OutlookToOneDrivePathPropertyTests
{
    /// <summary>
    /// Generates a forward-slash relative path of non-empty segments that contain
    /// no slashes and are not themselves empty/whitespace.
    /// </summary>
    private static Gen<string> RelativePath =>
        Gen.String[Gen.Char.AlphaNumeric, 1, 8]
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Array[1, 5]
            .Select(segments => string.Join('/', segments));

    [Fact]
    public void Map_ArchivePrefixedPath_RemovesExactlyTheFirstSegment()
    {
        RelativePath.Sample(relative =>
        {
            // Arrange
            var outlookPath = "Archive/" + relative;

            // Act
            var mapped = OutlookToOneDrivePath.Map(outlookPath);

            // Assert: mapping equals the original relative path (first 'Archive' segment removed).
            mapped.Should().Be(relative);
        });
    }
}
