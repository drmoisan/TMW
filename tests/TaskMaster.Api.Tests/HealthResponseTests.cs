using FluentAssertions;
using TaskMaster.Api;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Direct unit tests for the <see cref="HealthResponse"/> record. Exercises
/// the property accessor, value-equality semantics, inequality on differing
/// status values, and ToString shape so the compiler-generated record members
/// receive measurable line and branch coverage.
/// </summary>
public class HealthResponseTests
{
    [Fact]
    public void Constructor_AssignsStatusProperty()
    {
        // Arrange / Act
        var response = new HealthResponse("ok");

        // Assert
        response.Status.Should().Be("ok");
    }

    [Fact]
    public void RecordEquality_TwoInstancesWithSameStatus_AreEqual()
    {
        // Arrange
        var a = new HealthResponse("ok");
        var b = new HealthResponse("ok");

        // Act / Assert
        a.Should().Be(b);
        (a == b).Should().BeTrue();
        a.GetHashCode().Should().Be(b.GetHashCode());
    }

    [Fact]
    public void RecordEquality_DifferentStatus_AreNotEqual()
    {
        // Arrange
        var ok = new HealthResponse("ok");
        var down = new HealthResponse("down");

        // Act / Assert
        ok.Should().NotBe(down);
        (ok != down).Should().BeTrue();
    }

    [Fact]
    public void ToString_IncludesStatusValue()
    {
        // Arrange
        var response = new HealthResponse("ok");

        // Act
        var text = response.ToString();

        // Assert
        text.Should().Contain("Status").And.Contain("ok");
    }
}
