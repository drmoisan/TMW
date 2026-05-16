using FluentAssertions;
using TaskMaster.Infrastructure.Validation;

namespace TaskMaster.Infrastructure.Tests;

/// <summary>
/// Tests that <see cref="PayloadSchemaValidator.Validate"/> throws <see cref="SchemaValidationException"/>
/// when given a payload that fails validation, and verifies the exception carries non-empty errors.
/// These tests exercise the CollectErrors branch inside <see cref="PayloadSchemaValidator"/>.
/// </summary>
public sealed class SchemaValidationPropagationTests
{
    private static string SchemaPath(string relativePath) =>
        Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", relativePath)
        );

    [Fact]
    public void SaveAsync_WhenSchemaValidationFails_PropagatesSchemaValidationException()
    {
        // Arrange — payload missing the required 'userId' field per user-settings schema.
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
        var exception = act.Should()
            .Throw<SchemaValidationException>(
                "because the payload is missing the required 'userId' property"
            )
            .Which;

        exception.PayloadType.Should().NotBeNullOrEmpty("PayloadType must be set by the validator");
        exception
            .ValidationErrors.Should()
            .NotBeEmpty(
                "CollectErrors must populate at least one error when schema validation fails"
            );
    }

    [Fact]
    public void RecordAsync_WhenSchemaValidationFails_PropagatesSchemaValidationException()
    {
        // Arrange — payload missing the required 'messageId' field per training-feedback schema.
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
        var exception = act.Should()
            .Throw<SchemaValidationException>(
                "because the payload is missing the required 'messageId' property"
            )
            .Which;

        exception.PayloadType.Should().NotBeNullOrEmpty("PayloadType must be set by the validator");
        exception
            .ValidationErrors.Should()
            .NotBeEmpty(
                "CollectErrors must populate at least one error when schema validation fails"
            );
    }
}
