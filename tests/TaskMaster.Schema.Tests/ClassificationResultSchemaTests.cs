using FluentAssertions;
using Json.Schema;

namespace TaskMaster.Schema.Tests;

/// <summary>
/// Tests that the classification-result JSON Schema is well-formed and that fixtures
/// pass or fail validation as expected.
/// </summary>
public sealed class ClassificationResultSchemaTests
{
    private static string SchemaPath(string relativePath) =>
        Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", relativePath)
        );

    [Fact]
    public void SchemaFile_IsWellFormed()
    {
        // Arrange
        var path = SchemaPath("schemas/v1/classification-result.schema.json");

        // Act
        var act = () => JsonSchema.FromText(File.ReadAllText(path));

        // Assert — no exception thrown means the schema parses successfully.
        act.Should().NotThrow();
    }

    [Fact]
    public void ValidFixture_PassesSchema()
    {
        // Arrange
        var schemaPath = SchemaPath("schemas/v1/classification-result.schema.json");
        var fixturePath = SchemaPath("schemas/v1/fixtures/classification-result.valid.json");
        var schema = JsonSchema.FromText(File.ReadAllText(schemaPath));
        var node = System.Text.Json.Nodes.JsonNode.Parse(File.ReadAllText(fixturePath));

        // Act
        var result = schema.Evaluate(
            node,
            new EvaluationOptions { OutputFormat = OutputFormat.List }
        );

        // Assert
        result.IsValid.Should().BeTrue("the valid fixture must satisfy the schema");
    }

    [Fact]
    public void InvalidFixture_MissingConfidence_FailsSchema()
    {
        // Arrange
        var schemaPath = SchemaPath("schemas/v1/classification-result.schema.json");
        var fixturePath = SchemaPath(
            "schemas/v1/fixtures/invalid/classification-result.missing-confidence.json"
        );
        var schema = JsonSchema.FromText(File.ReadAllText(schemaPath));
        var node = System.Text.Json.Nodes.JsonNode.Parse(File.ReadAllText(fixturePath));

        // Act
        var result = schema.Evaluate(
            node,
            new EvaluationOptions { OutputFormat = OutputFormat.List }
        );

        // Assert
        result.IsValid.Should().BeFalse("the fixture omits the required 'confidence' property");
    }
}
