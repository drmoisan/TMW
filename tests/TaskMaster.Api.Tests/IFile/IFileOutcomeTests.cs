using FluentAssertions;
using TaskMaster.Application.IFile;

namespace TaskMaster.Api.Tests.IFile;

/// <summary>
/// Unit tests for <see cref="IFileOutcome.ToWire"/>, mapping each
/// <see cref="FileMessageOutcome"/> value to its wire string.
/// </summary>
public sealed class IFileOutcomeTests
{
    [Theory]
    [InlineData(FileMessageOutcome.Success, "success")]
    [InlineData(FileMessageOutcome.PreMoveFailure, "preMoveFailure")]
    [InlineData(FileMessageOutcome.ArchiveRootRequired, "archiveRootRequired")]
    public void ToWire_MapsKnownOutcomes(FileMessageOutcome outcome, string expected)
    {
        IFileOutcome.ToWire(outcome).Should().Be(expected);
    }

    [Fact]
    public void ToWire_UnknownEnumValue_ReturnsUnknown()
    {
        IFileOutcome.ToWire((FileMessageOutcome)999).Should().Be("unknown");
    }
}
