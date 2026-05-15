namespace TaskMaster.Api;

internal sealed record FeedbackRequest(string? MessageId, string? Label, bool Confirmed);
