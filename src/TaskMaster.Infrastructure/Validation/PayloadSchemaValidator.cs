using System.Text.Json;
using System.Text.Json.Nodes;
using Json.Schema;

namespace TaskMaster.Infrastructure.Validation;

/// <summary>
/// Validates a payload object against a JSON Schema file before storage writes.
/// </summary>
public static class PayloadSchemaValidator
{
    private static readonly JsonSerializerOptions s_serializerOptions = new(
        JsonSerializerDefaults.Web
    );

    /// <summary>
    /// Validates <paramref name="payload"/> against the JSON Schema at <paramref name="schemaFilePath"/>.
    /// </summary>
    /// <param name="payload">The object to validate.</param>
    /// <param name="schemaFilePath">Absolute path to the JSON Schema file.</param>
    /// <exception cref="SchemaValidationException">
    /// Thrown when the payload does not conform to the schema.
    /// </exception>
    public static void Validate(object payload, string schemaFilePath)
    {
        ArgumentNullException.ThrowIfNull(payload);
        ArgumentException.ThrowIfNullOrWhiteSpace(schemaFilePath);

        var schemaText = File.ReadAllText(schemaFilePath);
        var schema = JsonSchema.FromText(schemaText);
        var node = JsonSerializer.SerializeToNode(payload, s_serializerOptions);

        var options = new EvaluationOptions { OutputFormat = OutputFormat.List };
        var result = schema.Evaluate(node, options);

        if (!result.IsValid)
        {
            var errors = CollectErrors(result);
            throw new SchemaValidationException(payload.GetType().Name, errors);
        }
    }

    private static List<string> CollectErrors(EvaluationResults result)
    {
        var errors = new List<string>();

        if (result.Details is not null)
        {
            foreach (var detail in result.Details)
            {
                if (!detail.IsValid && detail.Errors is not null)
                {
                    foreach (var error in detail.Errors)
                    {
                        errors.Add($"{detail.InstanceLocation}: {error.Value}");
                    }
                }
            }
        }

        if (errors.Count == 0)
        {
            errors.Add("Schema validation failed with no detailed errors reported.");
        }

        return errors;
    }
}
