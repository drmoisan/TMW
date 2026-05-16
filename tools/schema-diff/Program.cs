using System.Text.Json;
using Json.Schema;

namespace SchemaDiff;

/// <summary>
/// CLI tool that detects breaking changes between two JSON Schema versions.
/// Exit code 0 = no breaking changes, 1 = breaking changes detected, 2 = usage/parse error.
/// </summary>
internal static class Program
{
#pragma warning disable CA1303 // CLI output strings are not localised; tool is dev-internal only.
    private static int Main(string[] args)
    {
        if (!TryParseArgs(args, out var currentPath, out var baselinePath))
        {
            Console.Error.WriteLine("Usage: schema-diff --current <path> --baseline <path>");
            return 2;
        }

        if (!TryLoadSchema(currentPath!, out var current))
        {
            return 2;
        }

        if (!TryLoadSchema(baselinePath!, out var baseline))
        {
            return 2;
        }

        if (IsStubSchema(baseline!) || IsStubSchema(current!))
        {
            Console.WriteLine("Schema is a stub — skipping comparison.");
            return 0;
        }

        var breakingChanges = DetectBreakingChanges(baseline!, current!);

        if (breakingChanges.Count == 0)
        {
            return 0;
        }

        foreach (var change in breakingChanges)
        {
            Console.WriteLine($"BREAKING: {change}");
        }

        return 1;
    }
#pragma warning restore CA1303

    private static bool TryLoadSchema(string path, out JsonSchema? schema)
    {
        try
        {
            schema = JsonSchema.FromText(File.ReadAllText(path));
            return true;
        }
        catch (IOException ex)
        {
#pragma warning disable CA1303
            Console.Error.WriteLine($"Failed to read schema '{path}': {ex.Message}");
#pragma warning restore CA1303
            schema = null;
            return false;
        }
        catch (JsonException ex)
        {
#pragma warning disable CA1303
            Console.Error.WriteLine($"Failed to parse schema '{path}': {ex.Message}");
#pragma warning restore CA1303
            schema = null;
            return false;
        }
    }

    private static bool TryParseArgs(
        string[] args,
        out string? currentPath,
        out string? baselinePath
    )
    {
        currentPath = null;
        baselinePath = null;

        for (var i = 0; i < args.Length - 1; i++)
        {
            if (string.Equals(args[i], "--current", StringComparison.Ordinal))
            {
                currentPath = args[i + 1];
            }
            else if (string.Equals(args[i], "--baseline", StringComparison.Ordinal))
            {
                baselinePath = args[i + 1];
            }
        }

        return currentPath is not null && baselinePath is not null;
    }

    private static bool IsStubSchema(JsonSchema schema)
    {
        var comment = schema.GetComment();
        return comment is not null
            && comment.Contains("Stub schema", StringComparison.OrdinalIgnoreCase);
    }

    private static List<string> DetectBreakingChanges(JsonSchema baseline, JsonSchema current)
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

        return changes;
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
