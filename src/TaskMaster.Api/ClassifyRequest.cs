namespace TaskMaster.Api;

internal sealed record ClassifyRequest(string? MessageId, string? Subject, string? Body);
