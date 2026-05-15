using CsCheck;
using TaskMaster.Application;

namespace TaskMaster.Classifier.Tests.Generators;

/// <summary>
/// Provides a reusable CsCheck arbitrary generator for <see cref="MailMessageSnapshot"/>.
/// </summary>
internal static class MailMessageSnapshotGen
{
    /// <summary>
    /// A CsCheck <see cref="Gen{T}"/> that produces arbitrary valid <see cref="MailMessageSnapshot"/> instances.
    /// </summary>
    public static Gen<MailMessageSnapshot> Arbitrary =>
        Gen.Select(
            Gen.String[1, 50],
            Gen.String[1, 50],
            (messageId, subject) => MailMessageSnapshot.Create(messageId, subject, null)
        );
}
