namespace TaskMaster.Api;

/// <summary>Named response payload for the authenticated <c>/api/ping</c> probe endpoint.</summary>
internal sealed record PingResponse(string Status);
