using System.Reflection;
using Microsoft.Identity.Web;
using TaskMaster.Api;
using TaskMaster.Application;
using TaskMaster.Classifier;
using TaskMaster.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// When the OpenAPI document is emitted at build time, the host is started by the
// GetDocument.Insider tool rather than a normal run. Identity/Graph registration
// requires AzureAd configuration that is absent in that context, so it is skipped.
var isDocumentEmission = string.Equals(
    Assembly.GetEntryAssembly()?.GetName().Name,
    "GetDocument.Insider",
    StringComparison.Ordinal
);

builder.Services.AddOpenApi(options =>
    options.AddDocumentTransformer(
        (document, _, _) =>
        {
            var assemblyVersion =
                typeof(PingResponse).Assembly.GetName().Version?.ToString(3) ?? "1.0.0";
            document.Info.Version = assemblyVersion;
            return Task.CompletedTask;
        }
    )
);

// Register Correlation ID middleware as a transient factory-based middleware.
builder.Services.AddTransient<CorrelationIdMiddleware>();

// Authorization services are required by the UseAuthorization middleware in all
// hosting contexts, including build-time document emission. They were previously
// registered transitively by AddMicrosoftIdentityWebApi; register them explicitly
// so the pipeline resolves even when identity wiring is skipped during emission.
builder.Services.AddAuthorization();

if (!isDocumentEmission)
{
    // Wire bearer token validation via Microsoft.Identity.Web.
    builder
        .Services.AddAuthentication()
        .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

    // Register Microsoft Graph with OBO token acquisition.
    builder.Services.AddMicrosoftGraph();
}

// Register Application and Infrastructure layers.
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddClassifierServices();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

// Middleware order: Correlation ID → Authentication → Authorization.
app.UseMiddleware<CorrelationIdMiddleware>();

if (!isDocumentEmission)
{
    // Authentication/authorization middleware depend on the identity services that
    // are skipped during build-time document emission. The emission tool only
    // enumerates API descriptions and never executes the request pipeline.
    app.UseAuthentication();
    app.UseAuthorization();
}

app.MapGet("/health", () => new HealthResponse(Status: "ok"))
    .WithName("Health")
    .WithDescription("Returns the service health status. Anonymous; used by infrastructure probes.")
    .AllowAnonymous();

app.MapGet("/api/ping", () => Results.Ok(new PingResponse("pong")))
    .WithName("Ping")
    .WithDescription("Authenticated connectivity probe. Returns a fixed PingResponse payload.")
    .Produces<PingResponse>(StatusCodes.Status200OK)
    .RequireAuthorization();

app.MapPost(
        "/api/classify",
        (ClassifyRequest req, IMessageClassifier classifier) =>
        {
            if (string.IsNullOrWhiteSpace(req.MessageId) || string.IsNullOrWhiteSpace(req.Subject))
            {
                return Results.UnprocessableEntity();
            }

            var snapshot = MailMessageSnapshot.Create(req.MessageId, req.Subject, req.Body);
            var result = classifier.Classify(snapshot);
            return Results.Ok(new ClassifyResponse(result.Label, result.Confidence));
        }
    )
    .WithName("Classify")
    .WithDescription(
        "Classifies a mail message and returns a label with a confidence score. "
            + "Returns 422 when the request is missing a message id or subject."
    )
    .Produces<ClassifyResponse>(StatusCodes.Status200OK)
    .Produces(StatusCodes.Status422UnprocessableEntity)
    .RequireAuthorization();

app.MapPost(
        "/api/classify/feedback",
        async (FeedbackRequest req, ITrainingRepository repo, CancellationToken ct) =>
        {
            var feedback = new TrainingFeedback(
                req.MessageId ?? string.Empty,
                req.Label ?? string.Empty,
                req.Confirmed,
                default
            );
            await repo.RecordAsync(feedback, ct).ConfigureAwait(false);
            return Results.NoContent();
        }
    )
    .WithName("ClassifyFeedback")
    .WithDescription(
        "Records user feedback for a prior classification to inform future training. "
            + "Returns 204 No Content on success."
    )
    .Produces(StatusCodes.Status204NoContent)
    .RequireAuthorization();

await app.RunAsync().ConfigureAwait(false);
