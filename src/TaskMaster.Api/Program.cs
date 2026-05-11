using TaskMaster.Api;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.MapGet("/health", () => new HealthResponse(Status: "ok")).WithName("Health");

await app.RunAsync().ConfigureAwait(false);
