using FluentAssertions;
using Json.Schema;
using Microsoft.Extensions.Options;
using NSubstitute;
using TaskMaster.Infrastructure;
using TaskMaster.Infrastructure.Validation;

namespace TaskMaster.Schema.Tests;

/// <summary>
/// Tests that the user-settings JSON Schema is well-formed and that fixtures and write-path
/// validation behave correctly.
/// </summary>
public sealed class UserSettingsSchemaTests
{
    private static string SchemaPath(string relativePath) =>
        Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", relativePath)
        );

    [Fact]
    public void SchemaFile_IsWellFormed()
    {
        // Arrange
        var path = SchemaPath("schemas/v1/user-settings.schema.json");

        // Act
        var act = () => JsonSchema.FromText(File.ReadAllText(path));

        // Assert
        act.Should().NotThrow();
    }

    [Fact]
    public void ValidFixture_PassesSchema()
    {
        // Arrange
        var schemaPath = SchemaPath("schemas/v1/user-settings.schema.json");
        var fixturePath = SchemaPath("schemas/v1/fixtures/user-settings.valid.json");
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
    public void InvalidFixture_MissingUserId_FailsSchema()
    {
        // Arrange
        var schemaPath = SchemaPath("schemas/v1/user-settings.schema.json");
        var fixturePath = SchemaPath(
            "schemas/v1/fixtures/invalid/user-settings.missing-userId.json"
        );
        var schema = JsonSchema.FromText(File.ReadAllText(schemaPath));
        var node = System.Text.Json.Nodes.JsonNode.Parse(File.ReadAllText(fixturePath));

        // Act
        var result = schema.Evaluate(
            node,
            new EvaluationOptions { OutputFormat = OutputFormat.List }
        );

        // Assert
        result.IsValid.Should().BeFalse("the fixture omits the required 'userId' property");
    }

    [Fact]
    public void Validate_ThrowsSchemaValidationException_WhenRequiredFieldMissing()
    {
        // Arrange — create a raw object missing userId to directly exercise the validator.
        // A UserSettings C# record always has UserId, so we test via the static validator
        // directly with a dictionary that omits the required field.
        var schemaPath = SchemaPath("schemas/v1/user-settings.schema.json");
        var payloadMissingUserId = new
        {
            notificationsEnabled = true,
            triageEnabled = false,
            lastModifiedAt = "2026-05-15T20:44:00Z",
        };

        // Act
        var act = () => PayloadSchemaValidator.Validate(payloadMissingUserId, schemaPath);

        // Assert
        act.Should()
            .Throw<SchemaValidationException>(
                "because the payload is missing the required 'userId' property"
            );
    }
}
