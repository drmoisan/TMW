namespace TaskMaster.Api;

/// <summary>
/// Middleware that propagates a correlation ID through the request pipeline.
/// Reads <c>X-Correlation-Id</c> from the request header; if absent, generates a new GUID.
/// Sets the same value on the response header and pushes it into the structured logging scope.
/// Register before <c>UseAuthentication()</c>.
/// </summary>
internal sealed class CorrelationIdMiddleware : IMiddleware
{
    private const string HeaderName = "X-Correlation-Id";

    private readonly ILogger<CorrelationIdMiddleware> _logger;

    /// <param name="logger">Logger used to push the correlation ID into structured log scope.</param>
    public CorrelationIdMiddleware(ILogger<CorrelationIdMiddleware> logger)
    {
        _logger = logger;
    }

    /// <inheritdoc/>
    public async Task InvokeAsync(HttpContext context, RequestDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        var correlationId = context.Request.Headers[HeaderName].FirstOrDefault();
        if (string.IsNullOrEmpty(correlationId))
        {
            correlationId = Guid.NewGuid().ToString();
        }

        context.Response.Headers[HeaderName] = correlationId;

        using (
            _logger.BeginScope(
                new Dictionary<string, object>(StringComparer.Ordinal)
                {
                    ["CorrelationId"] = correlationId,
                }
            )
        )
        {
            await next(context).ConfigureAwait(false);
        }
    }
}
