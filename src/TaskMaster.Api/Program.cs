using Microsoft.Identity.Web;
using TaskMaster.Api;
using TaskMaster.Application;
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

await app.RunAsync().ConfigureAwait(false);
