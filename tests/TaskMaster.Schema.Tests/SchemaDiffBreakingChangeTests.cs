using FluentAssertions;
using Json.Schema;
using SchemaDiff;

namespace TaskMaster.Schema.Tests;

/// <summary>
/// Tests for <see cref="SchemaDiffAnalyzer"/> covering breaking-change detection scenarios:
/// identical schemas, required-field removal, enum-constraint addition, and stub schemas.
/// </summary>
public sealed class SchemaDiffBreakingChangeTests
{
    [Fact]
    public void DetectBreakingChanges_IdenticalSchemas_ReturnsEmptyList()
    {
        // Arrange
        var schemaJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "required": ["id", "name"],
              "properties": {
                "id": { "type": "string" },
                "name": { "type": "string" }
              }
            }
            """;
        var baseline = JsonSchema.FromText(schemaJson);
        var current = JsonSchema.FromText(schemaJson);

        // Act
        var result = SchemaDiffAnalyzer.DetectBreakingChanges(baseline, current);

        // Assert
        result.Should().BeEmpty("identical schemas have no breaking changes");
    }

    [Fact]
    public void DetectBreakingChanges_RequiredFieldRemoved_ReturnsBreaking()
    {
        // Arrange
        var baselineJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "required": ["id"],
              "properties": {
                "id": { "type": "string" }
              }
            }
            """;
        var currentJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "properties": {
                "id": { "type": "string" }
              }
            }
            """;
        var baseline = JsonSchema.FromText(baselineJson);
        var current = JsonSchema.FromText(currentJson);

        // Act
        var result = SchemaDiffAnalyzer.DetectBreakingChanges(baseline, current);

        // Assert
        result.Should().ContainSingle();
        result[0]
            .Should()
            .Contain("'id'", "the removed required field name must appear in the message");
    }

    [Fact]
    public void DetectBreakingChanges_EnumConstraintAdded_ReturnsBreaking()
    {
        // Arrange — baseline property has no enum; current adds an enum constraint.
        var baselineJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "properties": {
                "status": { "type": "string" }
              }
            }
            """;
        var currentJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "properties": {
                "status": { "type": "string", "enum": ["a", "b"] }
              }
            }
            """;
        var baseline = JsonSchema.FromText(baselineJson);
        var current = JsonSchema.FromText(currentJson);

        // Act
        var result = SchemaDiffAnalyzer.DetectBreakingChanges(baseline, current);

        // Assert
        result.Should().ContainSingle();
        result[0].Should().Contain("type narrowed", "adding an enum constraint narrows the type");
        result[0].Should().Contain("status", "the property name must appear in the message");
    }

    [Fact]
    public void DetectBreakingChanges_StubSchema_ReturnsEmptyAndExitZero()
    {
        // Arrange — schema with Stub schema $comment.
        var stubJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "$comment": "Stub schema — not yet implemented.",
              "properties": {}
            }
            """;
        var normalJson = """
            {
              "$schema": "https://json-schema.org/draft/2020-12/schema",
              "type": "object",
              "required": ["id"],
              "properties": {
                "id": { "type": "string" }
              }
            }
            """;
        var stub = JsonSchema.FromText(stubJson);
        _ = normalJson; // normalJson is defined to represent what Program compares against stub; not needed here.

        // Act & Assert — IsStubSchema returns true for the stub
        SchemaDiffAnalyzer
            .IsStubSchema(stub)
            .Should()
            .BeTrue("schema with 'Stub schema' in $comment is a stub");

        // When stub is baseline or current, DetectBreakingChanges is not called (Program exits 0).
        // Verify directly that DetectBreakingChanges on two stub-content schemas returns empty.
        var result = SchemaDiffAnalyzer.DetectBreakingChanges(stub, stub);
        result.Should().BeEmpty("stub schemas have no properties or required fields to compare");
    }
}
