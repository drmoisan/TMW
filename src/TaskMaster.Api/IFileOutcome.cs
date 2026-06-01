using TaskMaster.Application.IFile;

namespace TaskMaster.Api;

/// <summary>
/// Maps the Application <see cref="FileMessageOutcome"/> enum to the wire string used in
/// <see cref="FileMessageEndpointResponse"/>.
/// </summary>
internal static class IFileOutcome
{
    /// <summary>Converts a <see cref="FileMessageOutcome"/> to its wire representation.</summary>
    public static string ToWire(FileMessageOutcome outcome) =>
        outcome switch
        {
            FileMessageOutcome.Success => "success",
            FileMessageOutcome.PreMoveFailure => "preMoveFailure",
            FileMessageOutcome.ArchiveRootRequired => "archiveRootRequired",
            _ => "unknown",
        };
}
