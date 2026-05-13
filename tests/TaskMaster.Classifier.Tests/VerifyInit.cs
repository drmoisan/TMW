using System.Runtime.CompilerServices;
using VerifyTests;

namespace TaskMaster.Classifier.Tests;

/// <summary>
/// Module initializer that configures Verify to use strict JSON serialization.
/// </summary>
internal static class VerifyInit
{
    /// <summary>
    /// Initializes Verify settings for this assembly.
    /// Uses strict JSON so that serialized output uses standard JSON formatting.
    /// </summary>
    [ModuleInitializer]
    public static void Initialize() => VerifierSettings.UseStrictJson();
}
