namespace TaskMaster.Infrastructure;

/// <summary>
/// Options for <see cref="JsonFileUserSettingsRepository"/>.
/// Bind from <c>UserSettings</c> configuration section.
/// </summary>
public sealed class UserSettingsFileOptions
{
    /// <summary>
    /// Path to the JSON file that stores user settings.
    /// Defaults to <c>settings.json</c> in the working directory.
    /// </summary>
    public string FilePath { get; set; } = string.Empty;
}
