using CsCheck;
using TaskMaster.Application;

namespace TaskMaster.Classifier.Tests.Generators;

/// <summary>
/// Provides a reusable CsCheck arbitrary generator for <see cref="MailMessageSnapshot"/>.
/// </summary>
internal static class MailMessageSnapshotGen
{
    /// <summary>
    /// Generates non-empty, non-whitespace strings that satisfy
    /// <see cref="MailMessageSnapshot.Create"/>'s precondition. Alphanumeric characters keep
    /// every generated value valid while still exercising varied keyword and non-keyword text.
    /// </summary>
    private static readonly Gen<string> NonWhitespaceText = Gen.String[
        Gen.Char.AlphaNumeric,
        1,
        50
    ];

    /// <summary>
    /// A CsCheck <see cref="Gen{T}"/> that produces arbitrary valid <see cref="MailMessageSnapshot"/> instances.
    /// </summary>
    public static Gen<MailMessageSnapshot> Arbitrary =>
        Gen.Select(
            NonWhitespaceText,
            NonWhitespaceText,
            (messageId, subject) => MailMessageSnapshot.Create(messageId, subject, null)
        );
}
