namespace TaskMaster.Api;

/// <summary>
/// Response body for <c>POST /api/ifile/file</c>, mapping the Application
/// <c>FileMessageResult</c> discriminated outcome to a wire shape.
/// </summary>
/// <param name="Outcome">
/// One of <c>success</c>, <c>preMoveFailure</c>, or <c>archiveRootRequired</c>.
/// </param>
/// <param name="Error">A user-facing error message when the outcome is a pre-move failure.</param>
internal sealed record FileMessageEndpointResponse(string Outcome, string? Error);
