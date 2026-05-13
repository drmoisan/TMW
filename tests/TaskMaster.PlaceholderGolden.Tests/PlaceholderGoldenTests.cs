namespace TaskMaster.PlaceholderGolden.Tests;

/// <summary>
/// Placeholder golden tests demonstrating Verify.XunitV3 infrastructure.
/// Uses static Verify() methods from VerifyXunit.Verifier (auto-imported via project props).
/// </summary>
public sealed class PlaceholderGoldenTests
{
    /// <summary>
    /// Verifies that a simple anonymous object serializes to the committed snapshot.
    /// </summary>
    [Fact]
    public Task VerifyPlaceholder()
    {
        return Verify(new { Name = "test", Value = 42 });
    }
}
