namespace TaskMaster.Application;

/// <summary>
/// Defines the set of classification labels assigned to mail messages.
/// </summary>
public static class ClassificationLabel
{
    /// <summary>High-priority mail requiring prompt attention.</summary>
    public const string HighPriority = "HighPriority";

    /// <summary>Promotional or marketing mail.</summary>
    public const string Promotional = "Promotional";

    /// <summary>General mail that does not match any priority rule.</summary>
    public const string General = "General";
}
