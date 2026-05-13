using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace TaskMaster.Api.Tests;

/// <summary>
/// Test authentication handler that always succeeds, producing a synthetic
/// <see cref="ClaimsPrincipal"/> so tests can exercise authenticated endpoints
/// without real Azure AD token issuance.
/// Registered via <c>services.AddAuthentication(TestAuthHandler.SchemeName).AddScheme&lt;TestAuthHandlerOptions, TestAuthHandler&gt;(...)</c>.
/// </summary>
// CA1812 suppressed: this class is instantiated by the ASP.NET Core authentication framework
// via reflection when the scheme is registered with AddScheme<TestAuthHandlerOptions, TestAuthHandler>.
#pragma warning disable CA1812
internal sealed class TestAuthHandler : AuthenticationHandler<TestAuthHandlerOptions>
{
    public const string SchemeName = "Test";

    public TestAuthHandler(
        IOptionsMonitor<TestAuthHandlerOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder
    )
        : base(options, logger, encoder) { }

    /// <inheritdoc/>
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "test-user-id"),
            new Claim(ClaimTypes.Name, "Test User"),
        };
        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
#pragma warning restore CA1812
