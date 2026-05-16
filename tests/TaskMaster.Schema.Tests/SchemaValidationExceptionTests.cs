using FluentAssertions;
using TaskMaster.Infrastructure.Validation;

namespace TaskMaster.Schema.Tests;

/// <summary>
/// Tests for all four constructors of <see cref="SchemaValidationException"/>.
/// </summary>
public sealed class SchemaValidationExceptionTests
{
    [Fact]
    public void Constructor_Default_CreatesInstanceWithEmptyPayloadTypeAndErrors()
    {
        // Arrange / Act
        var exception = new SchemaValidationException();

        // Assert
        exception.PayloadType.Should().Be(string.Empty);
        exception.ValidationErrors.Should().BeEmpty();
    }

    [Fact]
    public void Constructor_Message_SetsExceptionMessage()
    {
        // Arrange / Act
        var exception = new SchemaValidationException("test message");

        // Assert
        exception.Message.Should().Contain("test message");
    }

    [Fact]
    public void Constructor_MessageAndInner_SetsMessageAndInnerException()
    {
        // Arrange
        var inner = new InvalidOperationException("inner");

        // Act
        var exception = new SchemaValidationException("msg", inner);

        // Assert
        exception.Message.Should().Contain("msg");
        exception.InnerException.Should().NotBeNull();
    }

    [Fact]
    public void Constructor_PayloadTypeAndErrors_SetsPropertiesAndMessage()
    {
        // Arrange
        var errors = new[] { "err1", "err2" };

        // Act
        var exception = new SchemaValidationException("MyType", errors);

        // Assert
        exception.PayloadType.Should().Be("MyType");
        exception.ValidationErrors.Should().HaveCount(2);
        exception.Message.Should().Contain("MyType");
    }
}
