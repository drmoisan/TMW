using Json.Schema;

[assembly: System.Runtime.CompilerServices.InternalsVisibleTo("TaskMaster.Schema.Tests")]

namespace SchemaDiff;

/// <summary>
/// Provides schema-diff analysis logic for detecting breaking changes between two JSON schemas.
/// Extracted from <see cref="Program"/> to enable direct unit testing.
/// </summary>
internal static class SchemaDiffAnalyzer
{
    /// <summary>
    /// Returns true if the schema is a stub (contains "Stub schema" in its $comment).
    /// </summary>
    internal static bool IsStubSchema(JsonSchema schema)
    {
        var comment = schema.GetComment();
        return comment is not null
            && comment.Contains("Stub schema", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Detects breaking changes between a baseline and a current schema.
    /// </summary>
    /// <param name="baseline">The previous version of the schema.</param>
    /// <param name="current">The new version of the schema.</param>
    /// <returns>List of breaking-change descriptions, empty when no breaking changes exist.</returns>
    internal static List<string> DetectBreakingChanges(JsonSchema baseline, JsonSchema current)
    {
        var changes = new List<string>();
        var baselineRequired = GetRequired(baseline);
        var currentRequired = GetRequired(current);
        var baselineProperties = GetProperties(baseline);
        var currentProperties = GetProperties(current);

        changes.AddRange(
            baselineRequired
                .Where(f => !currentRequired.Contains(f))
                .Select(f => $"Required field '{f}' was removed from the 'required' array.")
        );

        changes.AddRange(
            currentRequired
                .Where(f => !baselineRequired.Contains(f) && !baselineProperties.Contains(f))
                .Select(f =>
                    $"New required field '{f}' added without a baseline property definition."
                )
        );

        if (!GetAdditionalPropertiesFalse(baseline) && GetAdditionalPropertiesFalse(current))
        {
            changes.Add(
                "'additionalProperties' changed to false — existing payloads with extra properties would be rejected."
            );
        }

        changes.AddRange(
            baselineProperties
                .Where(p => !currentProperties.Contains(p))
                .Select(p => $"Property '{p}' was removed from the schema definition.")
        );

        foreach (
            var propertyName in baselineProperties.Intersect(
                currentProperties,
                StringComparer.Ordinal
            )
        )
        {
            var baselineEnum = GetPropertyEnum(baseline, propertyName);
            var currentEnum = GetPropertyEnum(current, propertyName);

            if (baselineEnum is null && currentEnum is not null)
            {
                changes.Add($"Property '{propertyName}' type narrowed: enum constraint added.");
            }
        }

        return changes;
    }

    /// <summary>
    /// Gets the <see cref="EnumKeyword"/> for a named property within a schema, or null if absent.
    /// </summary>
    internal static EnumKeyword? GetPropertyEnum(JsonSchema schema, string propertyName)
    {
        var properties = schema.GetKeyword<PropertiesKeyword>()?.Properties;
        if (properties is null || !properties.TryGetValue(propertyName, out var propertySchema))
        {
            return null;
        }

        return propertySchema.GetKeyword<EnumKeyword>();
    }

    private static HashSet<string> GetRequired(JsonSchema schema)
    {
        var keyword = schema.GetRequired();
        return keyword is null ? [] : [.. keyword];
    }

    private static HashSet<string> GetProperties(JsonSchema schema)
    {
        var keyword = schema.GetProperties();
        return keyword is null ? [] : [.. keyword.Keys];
    }

    private static bool GetAdditionalPropertiesFalse(JsonSchema schema)
    {
        var keyword = schema.GetAdditionalProperties();
        return keyword == JsonSchema.False;
    }
}
