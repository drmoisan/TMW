# Runbook: Entra App SSO/NAA Configuration (iFile, Issue #43)

This runbook is a human-execution exception artifact produced under the autonomous-execution
mandate (issue #45). It covers the Entra app-registration configuration required for the iFile
NAA (nested app authentication) client-side token path and the backend on-behalf-of (OBO) Graph
exchange. Several of these steps either require tenant-admin rights (admin consent) or are not
cleanly automatable via the standard `az ad app` CLI (exposing an API scope, creating a secret),
so they are recorded here for a human operator.

- Feature: iFile message-filing (issue #43, PR #44)
- Requirement id: HI-3 (response: exception)
- Classification: human-gated. The app-registration changes are partially automatable via
  `az`/`az rest`, but exposing the `access_as_user` scope, granting admin consent, and creating
  the client secret are manual portal / tenant-admin actions (research section 5). Admin consent
  is the existing HI-1 step; this runbook cross-references it.

## Cue

Perform these steps once, against the existing "Graph Mail Calendar PoC" app registration
(client ID `2921bc0b-4518-4547-b8ca-f937713688ec`, tenant ID
`d80d0ee6-3e37-43d7-9974-0ae662873253`), before on-device verification of iFile (PR #44) and
before the NAA token path or backend OBO exchange is exercised against a real mailbox. The trigger
is: the iFile branch is ready for on-device sign-off and the Entra app has not yet been configured
for NAA + OBO (no Application ID URI, no exposed scope, no SPA redirect, no client secret).

## Prerequisites

- An account with **App Registration owner** or tenant-admin permissions for steps 1-5, 7, 8.
- An account with the **Global Administrator** or **Privileged Role Administrator** role for
  step 6 (admin consent).
- Access to the [Azure portal](https://portal.azure.com) / [Microsoft Entra admin
  center](https://entra.microsoft.com).
- The active **Dev Tunnel host** used for the build. The values below use
  `taskmaster-ios-3000.use.devtunnels.ms` (add-in page host) and
  `taskmaster-api-7287.use.devtunnels.ms` (API host). Dev Tunnel hostnames are session-scoped;
  for production these must be replaced with the production domain (see the out-of-scope
  production-domain follow-up in the remediation plan).

## Step-by-step Instructions

### Step 1 — Add the SPA redirect URI for the NAA broker (required for NAA)

Location: App registrations > [app] > Authentication > Add a platform > Single-page application.

Add:

```
brk-multihub://taskmaster-ios-3000.use.devtunnels.ms
```

The NAA documentation specifies the scheme `brk-multihub://` followed by the add-in host origin
(domain only, no subpath). This registers the app as trustable to be brokered by the
`brk-multihub` group (Word, Excel, PowerPoint, Outlook, Teams). For Outlook-only add-ins running
in the native Outlook host, the `brk-multihub://` URI alone is sufficient for NAA. When a
production domain exists, add `brk-multihub://<production-add-in-domain>` as well.

Admin required: App Registration owner or tenant admin (not necessarily Global Administrator).

### Step 2 — Set the Application ID URI (required for OBO backend validation)

Location: App registrations > [app] > Expose an API > Set (Application ID URI).

Value:

```
api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec
```

Format: `api://<fully-qualified-add-in-host-domain>/<client-id>`. The domain MUST match the domain
used in the add-in manifest resource URLs and in `webApplicationInfo.resource` /
`<WebApplicationInfo><Resource>`. Required so the backend OBO flow validates the incoming token's
`aud` claim.

Admin required: App Registration owner or tenant admin.

### Step 3 — Expose the `access_as_user` scope (required for OBO)

Location: App registrations > [app] > Expose an API > Add a scope.

| Field | Value |
|---|---|
| Scope name | `access_as_user` |
| Who can consent | Admins and users (use Admins only if policy requires) |
| Admin consent display name | `Access TaskMaster on behalf of the signed-in user` |
| Admin consent description | `Allows Office to call the add-in's server-side APIs as the signed-in user.` |
| User consent display name | `Access TaskMaster on your behalf` |
| User consent description | `Allows Office to call the add-in's server-side APIs on your behalf.` |
| State | Enabled |

Resulting full scope URI:
`api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec/access_as_user`.

Admin required: App Registration owner or tenant admin. This step is a manual portal action (the
`az ad app` CLI has no clean single-command equivalent for the full scope definition).

### Step 4 — Pre-authorize the Office umbrella client (required for OBO; recommended for NAA)

Location: App registrations > [app] > Expose an API > Add a client application.

Add the Office umbrella client ID and authorize the `access_as_user` scope for it:

| Client ID | Description |
|---|---|
| `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e` | All Microsoft Office application endpoints (umbrella) |

The umbrella ID is sufficient and is what the documentation recommends for most add-ins. If
granular control is preferred, the individual platform IDs are
`d3590ed6-52b3-4102-aeff-aad2292ab01c` (Microsoft Office desktop),
`93d53678-613d-4013-afc1-62e9e444a0a5` (Office on the web), and
`bc59ab01-8403-45c6-8796-ac3ef710b3e3` (Outlook on the web). Select the `access_as_user` scope for
each entry.

Admin required: App Registration owner or tenant admin.

### Step 5 — Add the required Graph delegated API permissions

Location: App registrations > [app] > API permissions > Add a permission > Microsoft Graph >
Delegated.

Add:
- `Mail.ReadBasic` (folder tree enumeration)
- `Mail.ReadWrite` (message move and attachment fetch)
- `Files.ReadWrite` (OneDrive folder creation and file upload)
- `openid` (required for SSO flows)
- `profile` (required for SSO flows)

Adding the permissions does not require admin; granting consent (step 6) does.

### Step 6 — Grant admin consent

Location: App registrations > [app] > API permissions > Grant admin consent for [tenant name].

After adding the delegated permissions, an administrator must grant consent so the OBO token
exchange succeeds without per-user consent prompts.

This is the existing **HI-1** step. Use `entra-admin-consent.runbook.md` (HI-1) for the detailed
portal/CLI procedure and verification. Admin required: Global Administrator or Privileged Role
Administrator on tenant `d80d0ee6-3e37-43d7-9974-0ae662873253`.

### Step 7 — Set the access token version to v2

Location: App registrations > [app] > Manifest (JSON editor).

Set:

```json
"api": {
  "requestedAccessTokenVersion": 2
}
```

The token version must be 2 for Office SSO usage, and `AddMicrosoftIdentityWebApi` expects v2
tokens by default.

Admin required: App Registration owner or tenant admin.

### Step 8 — Create the client secret (required for OBO only; inject, never commit)

Location: App registrations > [app] > Certificates & secrets > New client secret.

A client secret is required for the backend OBO flow (`AddMicrosoftIdentityWebApi` +
`EnableTokenAcquisitionToCallDownstreamApi` uses it to exchange the incoming JWT for a downstream
Graph token). The secret is NOT required for NAA client-side token acquisition (a pure public
client flow).

The secret MUST NEVER be committed to the repository. Inject it via:

```powershell
dotnet user-secrets set "AzureAd:ClientSecret" "<value>"
```

for development, or via a secrets-management system (Azure Key Vault, environment variable, or
hosting-platform secrets) for production. See `../evidence/other/backend-azuread-verification.2026-06-04T20-29.md`
for the backend config keys.

Admin required: App Registration owner (creating a secret does not require tenant admin).

## Verification

You have completed this correctly when all of the following hold:

1. The SPA redirect `brk-multihub://taskmaster-ios-3000.use.devtunnels.ms` appears under
   Authentication > Single-page application.
2. The Application ID URI is set to
   `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec` and matches
   the manifest `webApplicationInfo.resource` / `<WebApplicationInfo><Resource>`.
3. The `access_as_user` scope is Enabled and the Office umbrella client
   `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e` is pre-authorized for it.
4. The five delegated Graph permissions are present and show Granted for the tenant (step 6 /
   HI-1).
5. `requestedAccessTokenVersion` is `2` in the app manifest.
6. A client secret exists and has been injected via user-secrets/environment (its value is not in
   any committed file).
7. A live NAA sign-in on the device acquires a token and a live iFile filing operation completes
   end-to-end without an `AADSTS65001` consent error.

## Declared Exception (HI-3)

HI-3 is a declared human-interaction exception for this feature: the Entra app-registration
configuration (SPA redirect, Application ID URI, exposed scope, pre-authorization, token version,
client secret) and the admin-consent grant cannot be completed agentically in this deployment.
HI-3 gates feature DONE but not cycle exit: the manifest and client/backend code changes are
automatable and CI-verified, and the remediation cycle exits on a green toolchain plus zero
blocking re-audit findings. Feature DONE is reached only after this configuration is completed and
the on-device verification (`outlook-on-device-verification.runbook.md`, HI-2) is recorded.

## Source and Citation

All third-party configuration steps are sourced from the research dossier
`artifacts/research/2026-06-04-ifile-token-path-naa-vs-sso-research-43.md` (section 2), which
fetched the current official Microsoft documentation on **2026-06-04**:

- Enable SSO in an Office add-in with nested app authentication:
  https://learn.microsoft.com/en-us/office/dev/add-ins/develop/enable-nested-app-authentication-in-your-add-in
  (Microsoft Learn, ms.date 2025-12-15 / updated 2026-01-23; captured 2026-06-04).
- Nested app auth requirement sets:
  https://learn.microsoft.com/en-us/javascript/api/requirement-sets/common/nested-app-auth-requirement-sets
  (Microsoft Learn, ms.date 2026-03-31 / updated 2026-04-01; captured 2026-06-04).
- Register an Office Add-in that uses legacy Office SSO (umbrella/platform client IDs, token
  version):
  https://learn.microsoft.com/en-us/office/dev/add-ins/develop/register-sso-add-in-aad-v2
  (Microsoft Learn, ms.date 2025-05-25 / updated 2026-01-23; captured 2026-06-04).
- Authorize to Microsoft Graph with legacy Office SSO:
  https://learn.microsoft.com/en-us/office/dev/add-ins/develop/authorize-to-microsoft-graph
  (Microsoft Learn, ms.date 2026-02-02 / updated 2026-02-12; captured 2026-06-04).

Sourcing note: the configuration steps above derive from web retrieval of current Microsoft Learn
documentation captured on 2026-06-04 in the cited research dossier, not from model training data,
per the human-exception-runbook contract.
