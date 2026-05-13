using FluentAssertions;
using TaskMaster.Application;

namespace TaskMaster.Application.Tests;

/// <summary>
/// Unit tests for <see cref="MailMessageSnapshot.Create"/>.
/// Verifies guard clauses and field trimming behavior.
/// </summary>
public sealed class MailMessageSnapshotTests
{
    [Fact]
    public void Create_NullMessageId_ThrowsArgumentException()
    {
        // Arrange / Act
        var act = () => MailMessageSnapshot.Create(null!, "subject", null);

        // Assert
        act.Should().Throw<ArgumentException>().WithParameterName("messageId");
    }

    [Fact]
    public void Create_WhitespaceOnlySubject_ThrowsArgumentException()
    {
        // Arrange / Act
        var act = () => MailMessageSnapshot.Create("id", "   ", null);

        // Assert
        act.Should().Throw<ArgumentException>().WithParameterName("subject");
    }

    [Fact]
    public void Create_PaddedMessageIdAndSubject_ReturnsTrimmedFields()
    {
        // Arrange / Act
        var snapshot = MailMessageSnapshot.Create("  id  ", "  s  ", null);

        // Assert
        snapshot.MessageId.Should().Be("id");
        snapshot.Subject.Should().Be("s");
        snapshot.BodyPreview.Should().BeNull();
    }

    [Fact]
    public void Create_PaddedBodyPreview_TrimsBodyPreview()
    {
        // Arrange / Act
        var snapshot = MailMessageSnapshot.Create("id", "s", "  body  ");

        // Assert
        snapshot.BodyPreview.Should().Be("body");
    }
}
