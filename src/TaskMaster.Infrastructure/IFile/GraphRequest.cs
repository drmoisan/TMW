using System.Text.Json;
using Microsoft.Kiota.Abstractions;

namespace TaskMaster.Infrastructure.IFile;

/// <summary>
/// Small helpers shared by the iFile Graph adapters for issuing raw
/// <see cref="RequestInformation"/> calls through the Kiota request adapter.
/// </summary>
internal static class GraphRequest
{
    /// <summary>
    /// Returns the request adapter base URL, defaulting to the Microsoft Graph v1.0
    /// endpoint when the adapter has not set one.
    /// </summary>
    public static string BaseUrl(IRequestAdapter adapter)
    {
        ArgumentNullException.ThrowIfNull(adapter);
        var baseUrl = adapter.BaseUrl;
        return string.IsNullOrEmpty(baseUrl) ? "https://graph.microsoft.com/v1.0" : baseUrl;
    }

    /// <summary>Serializes a string as a JSON string literal (including quotes and escaping).</summary>
    public static string JsonString(string value) => JsonSerializer.Serialize(value);
}
