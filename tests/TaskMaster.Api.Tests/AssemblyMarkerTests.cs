using FluentAssertions;
using TaskMaster.Domain;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Direct unit tests for <see cref="AssemblyMarker"/>. Verifies the constant
/// matches the Domain assembly name and is non-empty so the const initializer
/// receives measurable coverage.
/// </summary>
public class AssemblyMarkerTests
{
    [Fact]
    public void AssemblyName_EqualsDomainAssemblyName()
    {
        // Arrange
        var actualName = typeof(AssemblyMarker).Assembly.GetName().Name;

        // Act / Assert
        AssemblyMarker.AssemblyName.Should().Be(actualName);
    }

    [Fact]
    public void AssemblyName_IsNonEmpty()
    {
        // Act / Assert
        AssemblyMarker.AssemblyName.Should().NotBeNullOrWhiteSpace();
        AssemblyMarker.AssemblyName.Should().Be("TaskMaster.Domain");
    }
}
