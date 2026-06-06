namespace TaskMaster.Application.IFile;

/// <summary>
/// Immutable result of a filing command.
/// </summary>
/// <param name="Outcome">The discriminated outcome.</param>
/// <param name="Error">
/// A specific, user-facing error message when <see cref="Outcome"/> is
/// <see cref="FileMessageOutcome.PreMoveFailure"/>; otherwise <c>null</c>.
/// </param>
public sealed record FileMessageResult(FileMessageOutcome Outcome, string? Error)
{
    /// <summary>Creates a success result.</summary>
    public static FileMessageResult Success() => new(FileMessageOutcome.Success, Error: null);

    /// <summary>Creates a pre-move-failure result carrying a specific error message.</summary>
    public static FileMessageResult PreMoveFailure(string error) =>
        new(FileMessageOutcome.PreMoveFailure, error);

    /// <summary>Creates an Archive-root-required result.</summary>
    public static FileMessageResult ArchiveRootRequired() =>
        new(FileMessageOutcome.ArchiveRootRequired, Error: null);
}
