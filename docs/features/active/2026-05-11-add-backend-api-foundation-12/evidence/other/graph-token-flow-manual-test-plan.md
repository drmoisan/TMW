# Graph OBO Token Flow — Manual Test Plan

Timestamp: 2026-05-12
Feature: 2026-05-11-add-backend-api-foundation-12
AC: AC-10 (Auth and Graph token flow covered by integration test or documented manual test)

---

## Purpose

This document describes the manual procedure for verifying that the Microsoft Graph
On-Behalf-Of (OBO) token flow works end-to-end once Azure AD app registration credentials
are available. Automated integration tests in `TaskMaster.Api.Tests` use `TestAuthHandler`
to bypass AAD validation; this plan covers the real-credential path.

---

## Prerequisites

1. **Azure AD app registration** with the following configuration:
   - Application (client) ID — record as `{CLIENT_ID}`
   - Tenant ID — record as `{TENANT_ID}`
   - Redirect URI: `https://localhost:5001` (for manual token acquisition)
   - API permissions: `User.Read` (Microsoft Graph, Delegated)
   - Client secret generated and noted as `{CLIENT_SECRET}` (never committed to source)
   - Audience set to `api://{CLIENT_ID}` or the application ID URI

2. **Environment variables** set before running the API:
   ```
   AzureAd__Instance=https://login.microsoftonline.com/
   AzureAd__TenantId={TENANT_ID}
   AzureAd__ClientId={CLIENT_ID}
   AzureAd__Audience=api://{CLIENT_ID}
   AzureAd__ClientSecret={CLIENT_SECRET}
   ```
   Note: `AzureAd__ClientSecret` must never be added to `appsettings.json` or any committed file.

3. **.NET 10 SDK** and the API project built: `dotnet build src/TaskMaster.Api`.

4. A tool to acquire OAuth 2.0 tokens, such as:
   - [MSAL browser flow via PowerShell](https://github.com/AzureAD/microsoft-authentication-library-for-dotnet)
   - [Postman](https://www.postman.com/) with OAuth 2.0 authorization
   - Azure CLI: `az account get-access-token --resource api://{CLIENT_ID}`

---

## Steps

### Step 1 — Start the API

```
dotnet run --project src/TaskMaster.Api
```

Confirm the API starts on `https://localhost:5001` (or the configured HTTPS port).

### Step 2 — Acquire a User Bearer Token

Use your preferred tool to obtain a delegated access token for `api://{CLIENT_ID}` with
scope `api://{CLIENT_ID}/.default` (or a specific scope defined in the app registration).

Using Azure CLI (requires user to be in the tenant):
```
az account get-access-token --resource api://{CLIENT_ID} --query accessToken -o tsv
```

Record the token as `{USER_TOKEN}`.

### Step 3 — Call the Health Endpoint (No Auth Required)

```
curl -k https://localhost:5001/health
```

Expected response:
```json
{"status":"ok"}
```

Verify `X-Correlation-Id` header is present in the response.

### Step 4 — Call the Health Endpoint With Bearer Token

```
curl -k -H "Authorization: Bearer {USER_TOKEN}" https://localhost:5001/health
```

Expected response: HTTP 200 with `{"status":"ok"}`.
The token is validated by `Microsoft.Identity.Web`; the `CorrelationIdMiddleware` runs
and populates the `X-Correlation-Id` response header.

### Step 5 — Verify OBO Token Acquisition (Graph Downstream Call)

Once a protected endpoint exists that calls `IGraphClientFactory.CreateClient()` and
makes a downstream Graph request, perform the following:

1. Call the protected endpoint with `{USER_TOKEN}` in the `Authorization` header.
2. The API performs OBO exchange: it uses `{USER_TOKEN}` to acquire a new token scoped
   to Microsoft Graph on behalf of the user.
3. The Graph SDK call (`GraphServiceClient.Me.GetAsync()` or equivalent) succeeds.

Expected outcome: the protected endpoint returns a 200 response with user-specific data
from Graph, confirming the OBO flow exchanged the inbound user token for a Graph token.

---

## Expected Outcomes

| Check | Expected Result |
|---|---|
| API starts without error | No startup exceptions; `Program.cs` DI wiring resolves |
| Health endpoint responds | HTTP 200, `{"status":"ok"}` |
| `X-Correlation-Id` header present | Non-empty GUID on every response |
| JWT validation passes | Token signed by `{TENANT_ID}` accepted; invalid token → 401 |
| OBO exchange succeeds | Graph call returns user profile data; no `ClientId` errors |

---

## Known MVP Limitation

The current implementation uses a client secret (`AzureAd__ClientSecret`) for the OBO
token exchange. This is acceptable for development and non-production environments.
For production deployment, replace the client secret with a certificate
(`AzureAd__ClientCertificates` configuration) per Microsoft's security guidance:
https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials

The `ClientSecret` value must be supplied exclusively via environment variable or
Azure Key Vault reference injection — never committed to source control.

---

## Notes

- The `CustomWebApplicationFactory` used by `TaskMaster.Api.Tests` stubs `ITokenAcquisition`
  and `GraphServiceClient` so no real AAD calls are made in automated tests.
- This manual test plan covers the real-credential path that automated tests bypass.
- Re-run this plan after any change to `Program.cs` auth registration, `appsettings.json`
  AzureAd section, or `GraphClientFactory`.
