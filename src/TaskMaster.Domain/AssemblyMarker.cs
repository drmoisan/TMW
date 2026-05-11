namespace TaskMaster.Domain;

/// <summary>
/// Empty marker type so test assemblies can reference the Domain assembly via
/// <c>typeof(AssemblyMarker).Assembly</c> without taking a dependency on any
/// domain-specific runtime type. Domain runtime types arrive in later prompts.
/// </summary>
public static class AssemblyMarker
{
    /// <summary>
    /// Logical identifier of the Domain assembly. Used only as a non-empty marker payload
    /// to satisfy analyzer rules that disallow empty classes.
    /// </summary>
    public const string AssemblyName = "TaskMaster.Domain";
}
