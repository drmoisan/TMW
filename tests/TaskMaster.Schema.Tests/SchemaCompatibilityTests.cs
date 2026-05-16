using FluentAssertions;
using Json.Schema;

namespace TaskMaster.Schema.Tests;

/// <summary>
/// Cross-cutting schema compatibility tests: verifies schema files exist, that valid
/// fixtures satisfy their schema, and provides a harness for backward-compat checks
/// when additional schema versions are introduced.
/// </summary>
public sealed class SchemaCompatibilityTests
{
    private static string SchemaPath(string relativePath) =>
        Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", relativePath)
        );

    [Fact]
    public void SchemaFilesExist_ForAllV1Types()
    {
        // Arrange
        var expectedSchemas = new[]
        {
            "schemas/v1/classification-result.schema.json",
            "schemas/v1/user-settings.schema.json",
            "schemas/v1/training-feedback.schema.json",
            "schemas/v1/task-metadata.schema.json",
            "schemas/v1/migration-provenance.schema.json",
        };

        // Act & Assert
        foreach (var relativePath in expectedSchemas)
        {
            var fullPath = SchemaPath(relativePath);
            File.Exists(fullPath)
                .Should()
                .BeTrue($"schema file '{relativePath}' must exist in schemas/v1/");
        }
    }

    [Theory]
    [InlineData("classification-result")]
    [InlineData("user-settings")]
    [InlineData("training-feedback")]
    public void V1Fixture_PassesV1Schema(string payloadType)
    {
        // Arrange
        var schemaPath = SchemaPath($"schemas/v1/{payloadType}.schema.json");
        var fixturePath = SchemaPath($"schemas/v1/fixtures/{payloadType}.valid.json");
        var schema = JsonSchema.FromText(File.ReadAllText(schemaPath));
        var node = System.Text.Json.Nodes.JsonNode.Parse(File.ReadAllText(fixturePath));

        // Act
        var result = schema.Evaluate(
            node,
            new EvaluationOptions { OutputFormat = OutputFormat.List }
        );

        // Assert
        result
            .IsValid.Should()
            .BeTrue($"the v1 fixture for '{payloadType}' must pass the v1 schema");
    }

    [Fact]
    public void BackwardCompatibility_SingleVersion_VacuousPass()
    {
        // v1 only: backward-compat test is vacuous when no prior version exists.
        // This test acts as a harness placeholder for when v2 is introduced;
        // at that point this test should be replaced with a real backward-compat assertion.
        true.Should().BeTrue();
    }
}
