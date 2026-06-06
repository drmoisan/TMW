namespace TaskMaster.Application.IFile;

/// <summary>
/// The content bytes of a single attachment.
/// </summary>
/// <param name="Name">The attachment file name.</param>
/// <param name="Content">The raw attachment bytes.</param>
public sealed record AttachmentContent(string Name, ReadOnlyMemory<byte> Content);
