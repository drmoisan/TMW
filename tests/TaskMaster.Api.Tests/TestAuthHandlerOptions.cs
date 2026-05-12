using Microsoft.AspNetCore.Authentication;

namespace TaskMaster.Api.Tests;

// S2094 suppressed: this class intentionally inherits AuthenticationSchemeOptions with no
// additional properties. Its purpose is solely to satisfy the generic constraint on
// AuthenticationHandler<TOptions> when registering TestAuthHandler in tests.
#pragma warning disable S2094
/// <summary>
/// Authentication scheme options for <see cref="TestAuthHandler"/>.
/// No additional configuration is required beyond what <see cref="AuthenticationSchemeOptions"/> provides.
/// </summary>
internal sealed class TestAuthHandlerOptions : AuthenticationSchemeOptions { }
#pragma warning restore S2094
