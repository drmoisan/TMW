using FluentAssertions;
using Json.Schema;
using TaskMaster.Infrastructure.Validation;

namespace TaskMaster.Schema.Tests;

/// <summary>
/// Tests that the training-feedback JSON Schema is well-formed and that fixtures and write-path
/// validation behave correctly.
/// </summary>
public sealed class TrainingFeedbackSchemaTests
{
    private static string SchemaPath(string relativePath) =>
        Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", relativePath)
        );

    [Fact]
    public void SchemaFile_IsWellFormed()
    {
        // Arrange
        var path = SchemaPath("schemas/v1/training-feedback.schema.json");

        // Act
        var act = () => JsonSchema.FromText(File.ReadAllText(path));

        // Assert
        act.Should().NotThrow();
    }

    [Fact]
    public void ValidFixture_PassesSchema()
    {
        // Arrange
        var schemaPath = SchemaPath("schemas/v1/training-feedback.schema.json");
        var fixturePath = SchemaPath("schemas/v1/fixtures/training-feedback.valid.json");
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
    public void InvalidFixture_MissingMessageId_FailsSchema()
    {
        // Arrange
        var schemaPath = SchemaPath("schemas/v1/training-feedback.schema.json");
        var fixturePath = SchemaPath(
            "schemas/v1/fixtures/invalid/training-feedback.missing-messageId.json"
        );
        var schema = JsonSchema.FromText(File.ReadAllText(schemaPath));
        var node = System.Text.Json.Nodes.JsonNode.Parse(File.ReadAllText(fixturePath));

        // Act
        var result = schema.Evaluate(
            node,
            new EvaluationOptions { OutputFormat = OutputFormat.List }
        );

        // Assert
        result.IsValid.Should().BeFalse("the fixture omits the required 'messageId' property");
    }

    [Fact]
    public void Validate_ThrowsSchemaValidationException_WhenPayloadMissingMessageId()
    {
        // Arrange — test the schema validator directly with a payload missing messageId.
        // TrainingFeedback is a C# record that always serialises messageId, so we use an
        // anonymous object matching the schema shape but without messageId to demonstrate
        // the schema rejection path.
        var schemaPath = SchemaPath("schemas/v1/training-feedback.schema.json");
        var payloadMissingMessageId = new
        {
            label = "General",
            confirmed = true,
            recordedAt = "2026-05-15T20:44:00Z",
        };

        // Act
        var act = () => PayloadSchemaValidator.Validate(payloadMissingMessageId, schemaPath);

        // Assert
        act.Should()
            .Throw<SchemaValidationException>(
                "because the payload is missing the required 'messageId' property"
            );
    }
}
