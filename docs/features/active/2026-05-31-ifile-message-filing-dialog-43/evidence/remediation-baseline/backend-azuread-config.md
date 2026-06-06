# Backend AzureAd Config-Wiring Baseline (read-only)

Timestamp: 2026-06-04T20-29
Command: READ-ONLY INSPECTION
EXIT_CODE: 0

Output Summary:

Source: `src/TaskMaster.Api/Program.cs` (lines 50-56):

```csharp
builder
    .Services.AddAuthentication()
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))
    .EnableTokenAcquisitionToCallDownstreamApi()
    .AddMicrosoftGraph()
    .AddInMemoryTokenCaches();
```

- `AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))` reads the `AzureAd` section from configuration (confirmed).
- `EnableTokenAcquisitionToCallDownstreamApi()` enables the on-behalf-of (OBO) token-acquisition path (confirmed).
- This wiring is guarded by `if (!isDocumentEmission)` so build-time OpenAPI emission (which lacks AzureAd config) is skipped; runtime hosting executes the identity wiring.

Source: `src/TaskMaster.Api/appsettings.json` (lines 9-14):

```json
"AzureAd": {
  "Instance": "",
  "TenantId": "",
  "ClientId": "",
  "Audience": ""
}
```

- The `AzureAd` section declares the keys `Instance`, `TenantId`, `ClientId`, `Audience` with empty string values (confirmed). Empty values are populated via environment / user-secrets at dev/deploy time.
- `ClientSecret` is NOT present in `appsettings.json` (confirmed). This is correct: the secret is supplied only via `dotnet user-secrets set "AzureAd:ClientSecret" <value>` or environment injection per research section 4.

Conclusion: The OBO-path keys are read from configuration via `GetSection("AzureAd")`, OBO is enabled via `EnableTokenAcquisitionToCallDownstreamApi()`, and `ClientSecret` is not committed. No C# code change is required this cycle. If any later task would require a C# source change, stop and escalate as a scope change.
