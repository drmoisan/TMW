using FluentAssertions;
using TaskMaster.Application.IFile;

namespace TaskMaster.Application.Tests.IFile;

/// <summary>
/// Unit tests for <see cref="AttachmentFilter.SelectSavable"/> (AC-13, AC-16, OD-4).
/// </summary>
public sealed class AttachmentFilterTests
{
    private static AttachmentMetadata Attachment(
        string name,
        string type,
        bool isInline,
        long size = 1024
    ) => new(Id: $"id-{name}", Name: name, AttachmentType: type, IsInline: isInline, Size: size);

    [Fact]
    public void SelectSavable_SkipsInlineFileAttachments()
    {
        // Arrange
        var attachments = new[] { Attachment("logo.png", "file", isInline: true) };

        // Act
        var result = AttachmentFilter.SelectSavable(attachments);

        // Assert
        result.Should().BeEmpty();
    }

    [Fact]
    public void SelectSavable_SkipsItemAttachments()
    {
        var attachments = new[] { Attachment("embedded.eml", "item", isInline: false) };
        AttachmentFilter.SelectSavable(attachments).Should().BeEmpty();
    }

    [Fact]
    public void SelectSavable_IncludesNonInlineFileAttachments()
    {
        // Arrange
        var attachments = new[]
        {
            Attachment("report.pdf", "file", isInline: false),
            Attachment("logo.png", "file", isInline: true),
            Attachment("embedded.eml", "item", isInline: false),
        };

        // Act
        var result = AttachmentFilter.SelectSavable(attachments);

        // Assert
        result.Should().ContainSingle();
        result[0].Name.Should().Be("report.pdf");
    }

    [Fact]
    public void SelectSavable_NoAttachments_ReturnsEmpty()
    {
        AttachmentFilter.SelectSavable(Array.Empty<AttachmentMetadata>()).Should().BeEmpty();
    }
}
