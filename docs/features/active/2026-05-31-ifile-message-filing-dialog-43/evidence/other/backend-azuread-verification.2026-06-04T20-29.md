# Backend AzureAd OBO Config Verification (no C# code change)

Timestamp: 2026-06-04T20-29
Command: READ-ONLY INSPECTION (Read + Grep)
EXIT_CODE: 0

This is a verification + documentation task per inputs section 4 item 5 and research section 4.
No C# source was modified.

## (a) Program.cs reads GetSection("AzureAd") and enables OBO

`src/TaskMaster.Api/Program.cs` (lines 50-56), guarded by `if (!isDocumentEmission)`:

```csharp
builder
    .Services.AddAuthentication()
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))
    .EnableTokenAcquisitionToCallDownstreamApi()
    .AddMicrosoftGraph()
    .AddInMemoryTokenCaches();
```

- `AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))` reads the `AzureAd`
  configuration section (confirmed).
- `EnableTokenAcquisitionToCallDownstreamApi()` enables the on-behalf-of (OBO) token-exchange
  path (confirmed).

## (b) appsettings.json declares the OBO keys

`src/TaskMaster.Api/appsettings.json` (lines 9-14):

```json
"AzureAd": {
  "Instance": "",
  "TenantId": "",
  "ClientId": "",
  "Audience": ""
}
```

- The keys `Instance`, `TenantId`, `ClientId`, `Audience` are declared with empty values
  (confirmed). Non-secret identifiers may be populated in non-secret config; values are
  environment-supplied at deploy/dev time.

## (c) ClientSecret is NOT committed

- `appsettings.json` does not declare `ClientSecret` (confirmed — keys end at `Audience`).
- `appsettings.Development.json` contains only a `Logging` section; no `AzureAd` section and no
  `ClientSecret` (confirmed).
- Grep for `ClientSecret` across `src/TaskMaster.Api` returned no files (confirmed).
- The secret MUST be supplied via `dotnet user-secrets set "AzureAd:ClientSecret" <value>` or
  environment injection per research section 4. It must never be committed.

## (d) Expected non-secret values (for dev/deploy-time injection; not committed here)

| Key | Value |
|---|---|
| `AzureAd:Instance` | `https://login.microsoftonline.com/` |
| `AzureAd:TenantId` | `d80d0ee6-3e37-43d7-9974-0ae662873253` |
| `AzureAd:ClientId` | `2921bc0b-4518-4547-b8ca-f937713688ec` |
| `AzureAd:Audience` | `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec` |
| `AzureAd:ClientSecret` | secret from portal — inject via user-secrets or environment, never commit |

## Conclusion

The backend already reads the `AzureAd` OBO keys from configuration, enables OBO via
`EnableTokenAcquisitionToCallDownstreamApi()`, and does not commit `ClientSecret`. No C# source
change is required this cycle. The keys ARE read from configuration, so no scope-change escalation
is triggered.
