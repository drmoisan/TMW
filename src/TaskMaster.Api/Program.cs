using Microsoft.Identity.Web;
using TaskMaster.Api;
using TaskMaster.Application;
using TaskMaster.Classifier;
using TaskMaster.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

// Register Correlation ID middleware as a transient factory-based middleware.
builder.Services.AddTransient<CorrelationIdMiddleware>();

// Wire bearer token validation via Microsoft.Identity.Web.
builder
    .Services.AddAuthentication()
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// Register Microsoft Graph with OBO token acquisition.
builder.Services.AddMicrosoftGraph();

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
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => new HealthResponse(Status: "ok")).WithName("Health").AllowAnonymous();

app.MapGet("/api/ping", () => Results.Ok(new { status = "pong" }))
    .WithName("Ping")
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
    .RequireAuthorization();

await app.RunAsync().ConfigureAwait(false);
