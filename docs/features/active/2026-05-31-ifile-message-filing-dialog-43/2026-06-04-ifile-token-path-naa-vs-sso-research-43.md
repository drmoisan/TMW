# iFile Token Path: NAA vs Legacy SSO for Outlook iOS — Research

- **Issue:** #43
- **Date:** 2026-06-04
- **Prepared by:** Task Researcher Agent
- **Branch:** feature/ifile-message-filing-dialog-43
- **Scope:** Determine the current (2026) recommended token-acquisition approach for Outlook on iOS; produce Entra app-configuration steps and manifest requirements for the chosen approach.

---

## Sources Consulted (with capture dates)

All third-party configuration steps below are sourced from current official Microsoft documentation fetched on 2026-06-04.

| URL | Page title | ms.date in page metadata |
|---|---|---|
| https://learn.microsoft.com/en-us/office/dev/add-ins/develop/enable-nested-app-authentication-in-your-add-in | Enable SSO in an Office add-in with nested app authentication | 2025-12-15 (updated_at 2026-01-23) |
| https://learn.microsoft.com/en-us/javascript/api/requirement-sets/common/nested-app-auth-requirement-sets | Nested app auth requirement sets | 2026-03-31 (updated_at 2026-04-01) |
| https://learn.microsoft.com/en-us/javascript/api/requirement-sets/outlook/outlook-api-requirement-sets | Outlook JavaScript API requirement sets | 2025-11-07 (updated_at 2026-02-06) |
| https://learn.microsoft.com/en-us/office/dev/add-ins/develop/sso-in-office-add-ins | Enable legacy Office SSO in an Office Add-in | 2026-02-02 (updated_at 2026-02-12) |
| https://learn.microsoft.com/en-us/office/dev/add-ins/develop/register-sso-add-in-aad-v2 | Register an Office Add-in that uses legacy Office SSO | 2025-05-25 (updated_at 2026-01-23) |
| https://learn.microsoft.com/en-us/office/dev/add-ins/develop/overview-authn-authz | Overview of authentication and authorization in Office Add-ins | 2025-12-25 (updated_at 2026-01-23) |
| https://learn.microsoft.com/en-us/office/dev/add-ins/develop/authorize-to-microsoft-graph | Authorize to Microsoft Graph with legacy Office SSO | 2026-02-02 (updated_at 2026-02-12) |

---

## 1. Recommendation: NAA (nested app auth) is the correct primary path

### 1.1 Current platform support status

**Legacy Office SSO (`Office.auth.getAccessToken` / `OfficeRuntime.auth.getAccessToken`)**

The legacy SSO page (fetched 2026-06-04, ms.date 2026-02-02) carries this banner at the top:

> "This article describes legacy Office single sign-on (SSO). For a modern authentication experience with support across a wider range of platforms, use the Microsoft Authentication Library (MSAL) with nested app authentication (NAA)."

The overview page (ms.date 2025-12-25) confirms the same framing: legacy SSO is described under `getAccessToken` and is explicitly labeled "legacy but still supported."

The Outlook API requirement-set page (updated_at 2026-02-06) confirms that `IdentityAPI 1.3` (the requirement set that backs `getAccessToken`) is present for Outlook on iOS and Android in the table footnote, but its presence is noted as requiring a runtime check (`isSetSupported('IdentityAPI', '1.3')`) — declaring it in the manifest is not supported. Crucially, the iOS and Android rows show Mailbox 1.1–1.5 and `NestedAppAuth 1.1`, but they do NOT list `IdentityAPI 1.3` in the platform row for iOS or Android. `IdentityAPI 1.3` appears only for Outlook on the web, Windows, and Mac clients. The iOS/Android platform rows list only: Mailbox 1.1–1.5 and `NestedAppAuth 1.1`.

This means that on Outlook iOS, `Office.auth.getAccessToken` (which requires `IdentityAPI 1.3`) is not listed as a supported API in the requirement-set support table. The iOS and Android rows in that table contain `NestedAppAuth 1.1` but not `IdentityAPI 1.3`. The documentation does not make an explicit "getAccessToken will fail on iOS" statement, but the absence from the iOS support matrix combined with the NAA recommendation for "wider range of platforms" is a strong practical indicator.

**NAA (`@azure/msal-browser` with `createNestablePublicClientApplication`)**

The NestedAppAuth requirement-set page (ms.date 2026-03-31, updated_at 2026-04-01) states:

> "Outlook on iOS: GA (iOS), Build v4.2433.0"

The "Supported accounts and hosts" table explicitly marks Outlook on iOS as **GA**. The minimum build required is `v4.2433.0`.

The requirement-set page also explicitly notes that NAA cannot be declared in the Outlook add-in manifest; a runtime check is required:

```javascript
Office.context.requirements.isSetSupported("NestedAppAuth", "1.1");
```

**Conclusion:** NAA via MSAL.js is GA on Outlook iOS from build v4.2433.0, and is the current Microsoft-recommended approach. Legacy SSO (`getAccessToken`) is not listed in the Outlook iOS support matrix; NAA was introduced specifically to cover platforms where legacy SSO is limited or unsupported.

### 1.2 Revision to OD-8

OD-8 reads: "NAA (nested app auth) primary token acquisition; fall back to backend on-behalf-of (OBO) via getAccessTokenAsync SSO."

This research supports and refines OD-8 as follows:

- **NAA primary is correct.** NAA is GA on Outlook iOS and is Microsoft's recommended path. Implement `createNestablePublicClientApplication` from `@azure/msal-browser`.
- **The fallback description requires clarification.** OD-8's fallback phrase "via getAccessTokenAsync SSO" is imprecise. For NAA, the fallback when NAA is not supported (i.e., `NestedAppAuth 1.1` is absent at runtime) should be the Office dialog API authentication flow (interactive MSAL in a dialog), not `getAccessToken`. `getAccessToken` is itself not guaranteed to work on the platforms where NAA is absent. The backend OBO flow is still required to exchange whatever client token arrives for a Graph token, and the backend is already wired for it.
- **The current code (`Office.auth.getAccessToken`)** is the legacy SSO path, not NAA. It is not confirmed to fail on the test device (the confirmed root causes were the unreachable URL and silent-failure amplifier, per `od8-token-path-investigation.2026-06-04T17-50.md`), but it is not the recommended path and may not be supported on iOS per the requirement-set matrix.

**Recommended OD-8 revision:** NAA primary (MSAL.js `createNestablePublicClientApplication`, `acquireTokenSilent` then `acquireTokenPopup`); fall back to Office dialog API interactive MSAL when `NestedAppAuth 1.1` is not supported; all Graph access remains server-side via OBO.

### 1.3 Mailbox / NestedAppAuth requirement minimums

- **Mailbox minimum for mobile:** The manifest.xml already declares `Mailbox MinVersion="1.5"`, which is the ceiling for Outlook mobile. This is consistent with using NAA (which is a separate requirement set, not part of Mailbox).
- **NestedAppAuth 1.1:** Must be checked at runtime with `isSetSupported`. It cannot be declared in the manifest for Outlook add-ins. If not supported, fall back to the Office dialog API flow.
- **Outlook iOS minimum build for NAA:** v4.2433.0 (per requirement-set table).

---

## 2. Entra App Configuration Steps (for the existing "Graph Mail Calendar PoC" app)

**Existing app:** client ID `2921bc0b-4518-4547-b8ca-f937713688ec`, tenant ID `d80d0ee6-3e37-43d7-9974-0ae662873253`.
**Current state confirmed:** No Application ID URI, no exposed API scope, no pre-authorized clients, one public-client redirect URI, no SPA redirect URI, no client secret.

The following steps are ordered for execution against the Entra portal (https://portal.azure.com). Source: NAA enable guide (fetched 2026-06-04) and legacy SSO registration guide (fetched 2026-06-04).

### Step 1 — Add SPA redirect URI for NAA broker (required for NAA)

**Location:** App registrations > [app] > Authentication > Add a platform > Single-page application

**Value to add:**
```
brk-multihub://taskmaster-ios-3000.use.devtunnels.ms
```

The NAA documentation specifies the scheme `brk-multihub://` followed by the add-in host origin (domain only, no subpath). This registers the app as trustable to be brokered by the `brk-multihub` group, which currently includes Word, Excel, PowerPoint, Outlook, and Teams.

For the deployed production host, an additional entry will be required once the production domain is known:
```
brk-multihub://<production-add-in-domain>
```

Note: For Word, Excel, and PowerPoint on the web, an additional SPA redirect URI pointing to the HTML page is required. For Outlook-only add-ins running exclusively in the native Outlook host (desktop and mobile), the `brk-multihub://` URI alone is documented as sufficient for NAA. The add-in does not run in Teams; there is no requirement to add Teams-specific URIs at this time.

**Admin required:** An account with App Registration owner or tenant admin permissions must perform this. It does not require a Global Administrator if the account owns the app registration.

### Step 2 — Set Application ID URI (required for OBO backend validation)

**Location:** App registrations > [app] > Expose an API > Set (Application ID URI)

The Application ID URI is required for the backend OBO flow so that incoming JWT tokens have the correct `aud` claim. It is also used in legacy SSO and serves as the `resource` value in webApplicationInfo (if that is added for legacy SSO fallback).

**Value:**
```
api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec
```

Format: `api://<fully-qualified-add-in-host-domain>/<client-id>`

The domain in the URI must match the domain used in the add-in's manifest resource URLs. For the Dev Tunnel development environment this is `taskmaster-ios-3000.use.devtunnels.ms`. For production it will need to be updated to the production domain.

**Note on NAA vs legacy SSO:** The NAA guide (fetched 2026-06-04) does not require an Application ID URI for the NAA client-side token acquisition itself. However, the Application ID URI is required for the backend OBO exchange (the server validates the incoming token's audience and uses it in the OBO request). Since this repo already has an OBO-wired backend, the Application ID URI must be set.

**Admin required:** App Registration owner or tenant admin permissions suffice.

### Step 3 — Expose `access_as_user` scope (required for OBO)

**Location:** App registrations > [app] > Expose an API > Add a scope

| Field | Value |
|---|---|
| Scope name | `access_as_user` |
| Who can consent | Admins and users (adjust to Admins only if policy requires) |
| Admin consent display name | `Access TaskMaster on behalf of the signed-in user` |
| Admin consent description | `Allows Office to call the add-in's server-side APIs as the signed-in user.` |
| User consent display name | `Access TaskMaster on your behalf` |
| User consent description | `Allows Office to call the add-in's server-side APIs on your behalf.` |
| State | Enabled |

Resulting full scope URI:
```
api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec/access_as_user
```

**Admin required:** App Registration owner or tenant admin.

### Step 4 — Pre-authorize Office client applications (required for OBO/legacy SSO; recommended for NAA)

**Location:** App registrations > [app] > Expose an API > Add a client application

Add the following client IDs and authorize the `access_as_user` scope for each. These are the well-known Microsoft Office client application IDs documented on the legacy SSO registration page (fetched 2026-06-04):

| Client ID | Description |
|---|---|
| `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e` | All Microsoft Office application endpoints (umbrella ID that covers the platforms below) |

If granular control is preferred, the individual platform IDs documented on the same page are:

| Client ID | Platform |
|---|---|
| `d3590ed6-52b3-4102-aeff-aad2292ab01c` | Microsoft Office (desktop) |
| `93d53678-613d-4013-afc1-62e9e444a0a5` | Office on the web |
| `bc59ab01-8403-45c6-8796-ac3ef710b3e3` | Outlook on the web |

The umbrella ID `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e` is sufficient and is what the documentation recommends for most add-ins.

For each entry, select the `access_as_user` scope when prompted.

**Admin required:** App Registration owner or tenant admin.

### Step 5 — Add required Graph delegated API permissions

**Location:** App registrations > [app] > API permissions > Add a permission > Microsoft Graph > Delegated

Add:
- `Mail.ReadBasic` (folder tree enumeration)
- `Mail.ReadWrite` (message move and attachment fetch)
- `Files.ReadWrite` (OneDrive folder creation and file upload)
- `openid` (required for SSO flows)
- `profile` (required for SSO flows)

These are documented in `evidence/other/aad-scope-changes.md` and in the feature document.

**Admin required:** Adding permissions does not require admin; however, granting admin consent (step 6) does.

### Step 6 — Grant admin consent

**Location:** App registrations > [app] > API permissions > Grant admin consent for [tenant name]

After adding the delegated permissions above, an administrator must grant consent so the OBO token exchange can succeed without per-user consent prompts. This is the existing HI-1 step already declared in the feature.

**Admin required:** Yes — this requires a Global Administrator or Privileged Role Administrator on the tenant.

### Step 7 — Set access token version to v2

**Location:** App registrations > [app] > Manifest (JSON editor)

Set:
```json
"api": {
  "requestedAccessTokenVersion": 2
}
```

The legacy SSO registration guide (fetched 2026-06-04) states that the token version must be 2 for Office SSO usage. The `AddMicrosoftIdentityWebApi` backend also expects v2 tokens by default. This is documented under the Manifest section of the registration guide.

**Admin required:** App Registration owner or tenant admin.

### Step 8 — Client secret (required for OBO only; not required for NAA client-side)

**Location:** App registrations > [app] > Certificates & secrets > New client secret

A client secret is required for the backend OBO flow. The server (`AddMicrosoftIdentityWebApi` + `EnableTokenAcquisitionToCallDownstreamApi`) uses the client secret when exchanging the incoming JWT for a downstream Graph token via OBO. The secret is NOT required for NAA client-side token acquisition, which is a pure public client flow.

The secret must NOT be committed to the repository. It belongs in user-secrets (development) or a secrets-management system (production). See section 4 for placement details.

**Admin required:** App Registration owner. Creating a secret does not require tenant admin.

---

## 3. Manifest Requirements

### 3.1 NAA does NOT require `webApplicationInfo` / `WebApplicationInfo`

The NAA documentation (fetched 2026-06-04) does not mention `webApplicationInfo` as a requirement for NAA. NAA uses MSAL.js configured with only the `clientId` and `authority` in the JavaScript code. There is no manifest-level registration of the Application ID URI for NAA.

`webApplicationInfo` (unified manifest) and `<WebApplicationInfo>` (XML manifest) are requirements for **legacy Office SSO** (`getAccessToken`). They tell the Office host what App ID URI to use when issuing the legacy SSO token.

**Decision for this repo:**

- If NAA is implemented as the sole client-side path (primary path), `webApplicationInfo` / `<WebApplicationInfo>` is not strictly required for NAA itself.
- However, if the legacy SSO `getAccessToken` path is retained as a fallback for environments where `NestedAppAuth 1.1` is not supported, then `webApplicationInfo` / `<WebApplicationInfo>` IS required for that fallback path.
- Given OD-8's architecture (NAA primary, fallback for unsupported environments), adding `webApplicationInfo` / `<WebApplicationInfo>` is advisable to support the legacy SSO fallback and to ensure the backend OBO flow can validate tokens from both paths.

### 3.2 `webApplicationInfo` shape for unified manifest.json

Source: legacy SSO configuration page (fetched 2026-06-04), unified manifest tab.

Add at the root of `manifest.json`:

```json
"webApplicationInfo": {
    "id": "2921bc0b-4518-4547-b8ca-f937713688ec",
    "resource": "api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec"
}
```

- `id`: the application (client) ID GUID.
- `resource`: the Application ID URI set in step 2. Must include the `api://` scheme. Must end with the client ID GUID. The domain portion must match the domain used in the manifest's extension URLs.

Note: In the unified manifest, there is no `<Scopes>` equivalent; Graph permissions are requested at runtime in code.

**Important caveat:** The unified manifest is not supported on Outlook mobile (verified in prior research, `2026-05-19-outlook-ios-mobile-support-research.md`). The `webApplicationInfo` field in the unified manifest therefore affects only the desktop/web experience. For iOS, the XML manifest is the operative manifest.

### 3.3 `<WebApplicationInfo>` shape for manifest.xml

Source: legacy SSO configuration page (fetched 2026-06-04), XML manifest tab.

Add inside the `<VersionOverrides xsi:type="VersionOverridesV1_1">` block, after the last `</Hosts>` close tag (before the `</VersionOverrides>` close):

```xml
<WebApplicationInfo>
    <Id>2921bc0b-4518-4547-b8ca-f937713688ec</Id>
    <Resource>api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec</Resource>
    <Scopes>
        <Scope>openid</Scope>
        <Scope>profile</Scope>
        <Scope>Mail.ReadBasic</Scope>
        <Scope>Mail.ReadWrite</Scope>
        <Scope>Files.ReadWrite</Scope>
    </Scopes>
</WebApplicationInfo>
```

- `<Id>`: client ID GUID.
- `<Resource>`: Application ID URI (same as `resource` in unified manifest).
- `<Scopes>`: lists the delegated Graph permissions required. These are declared for the legacy SSO path and for manifest-store consent; NAA requests scopes at runtime in code.

Placement note: the documentation states that for Outlook add-ins, `<WebApplicationInfo>` is placed at the end of the `<VersionOverrides xsi:type="VersionOverridesV1_1">` section. The current `manifest.xml` has a nested structure: outer `VersionOverridesV1_0` containing inner `VersionOverridesV1_1`. `<WebApplicationInfo>` belongs at the end of the inner `VersionOverridesV1_1` block.

### 3.4 MSAL configuration for NAA (code, not manifest)

The NAA path requires no manifest changes beyond the SPA redirect URI and (for fallback) the `<WebApplicationInfo>` element. The client-side configuration is in code:

```typescript
import { createNestablePublicClientApplication, InteractionRequiredAuthError } from "@azure/msal-browser";

const msalConfig = {
  auth: {
    clientId: "2921bc0b-4518-4547-b8ca-f937713688ec",
    authority: "https://login.microsoftonline.com/common"
  },
  cache: {
    cacheLocation: "localStorage"
  }
};

const msalInstance = await createNestablePublicClientApplication(msalConfig);
```

The `clientId` is a non-secret identifier. It may be embedded in client-side code (it is the Application ID / Client ID, not a secret). The `authority` uses `common` to support work/school accounts; the tenant ID `d80d0ee6-3e37-43d7-9974-0ae662873253` may also be used for a single-tenant configuration.

Token acquisition pattern (per Outlook add-in tab in the NAA guide):

```typescript
const tokenRequest = { scopes: ["Mail.ReadBasic", "Mail.ReadWrite", "Files.ReadWrite"] };

try {
  const result = await msalInstance.acquireTokenSilent(tokenRequest);
  // send result.accessToken to backend
} catch (silentError) {
  if (silentError instanceof InteractionRequiredAuthError) {
    const result = await msalInstance.acquireTokenPopup(tokenRequest);
    // send result.accessToken to backend
  }
}
```

### 3.5 `validDomains` / `<AppDomains>` additions for Dev Tunnel hosts

**manifest.json `validDomains`:**

```json
"validDomains": [
    "localhost",
    "https://www.contoso.com",
    "taskmaster-ios-3000.use.devtunnels.ms",
    "taskmaster-api-7287.use.devtunnels.ms"
]
```

**manifest.xml `<AppDomains>`:**

```xml
<AppDomains>
    <AppDomain>https://localhost:3000/</AppDomain>
    <AppDomain>https://www.contoso.com/</AppDomain>
    <AppDomain>https://taskmaster-ios-3000.use.devtunnels.ms/</AppDomain>
    <AppDomain>https://taskmaster-api-7287.use.devtunnels.ms/</AppDomain>
</AppDomains>
```

The API host (`taskmaster-api-7287`) must be listed because the add-in makes cross-origin fetch calls to it. The page host (`taskmaster-ios-3000`) must be listed because it hosts the add-in HTML pages and because the Application ID URI's domain must match the domain in the manifest resource URLs.

Note on format: the existing manifest.xml `<AppDomain>` entries include a trailing slash and `https://` scheme. The existing manifest.json `validDomains` entries do not include scheme or trailing slash for `localhost` but do include `https://` for the contoso placeholder. The current format is inconsistent; for Dev Tunnel entries, use scheme + domain without trailing path (e.g., `taskmaster-ios-3000.use.devtunnels.ms` without scheme for the JSON manifest, consistent with the existing `localhost` entry format, and `https://taskmaster-ios-3000.use.devtunnels.ms/` for the XML manifest consistent with the existing AppDomain format). The doc does not prescribe exact format for `validDomains` in the JSON manifest beyond domain-level granularity; align with the existing convention in each file.

---

## 4. Secret Handling

### Identifiers (non-secret, may appear in committed files and client-side code)

| Value | Where it belongs |
|---|---|
| Client ID `2921bc0b-4518-4547-b8ca-f937713688ec` | manifest.json `webApplicationInfo.id`, manifest.xml `<Id>`, MSAL `clientId` in TypeScript source. Not a secret. |
| Tenant ID `d80d0ee6-3e37-43d7-9974-0ae662873253` | Backend appsettings.json `AzureAd.TenantId` (non-secret configuration), or MSAL authority in TypeScript source. Not a secret. |
| Application ID URI `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-...` | manifest.json `webApplicationInfo.resource`, manifest.xml `<Resource>`, backend appsettings.json `AzureAd.Audience` (for token audience validation). Not a secret. |

### Secrets (must never be committed)

| Value | Where it belongs |
|---|---|
| Client secret (Certificates & secrets > Client secrets) | Development: `dotnet user-secrets set "AzureAd:ClientSecret" "<value>"`. Production: Azure Key Vault, environment variable, or hosting platform secrets. Never in appsettings.json or any committed file. |

### Backend `AzureAd` config section keys (Microsoft.Identity.Web)

`AddMicrosoftIdentityWebApi` and `EnableTokenAcquisitionToCallDownstreamApi` read from the `AzureAd` configuration section. The documented expected keys for the OBO path are:

| Key | Description | Source |
|---|---|---|
| `AzureAd:Instance` | Authority base URL, e.g. `https://login.microsoftonline.com/` | Required |
| `AzureAd:TenantId` | Tenant ID GUID or `common`. For single-tenant OBO, use the tenant ID. | Required |
| `AzureAd:ClientId` | Application (client) ID GUID | Required |
| `AzureAd:Audience` | Application ID URI, e.g. `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-...` | Required for token audience validation |
| `AzureAd:ClientSecret` | Client secret for OBO exchange | Required for OBO; stored in user-secrets, never committed |

The current `appsettings.json` has empty values for `Instance`, `TenantId`, `ClientId`, and `Audience`. It does not have a `ClientSecret` key, which is correct — the secret is supplied only via user-secrets or production environment injection.

---

## 5. Automatable vs Human Classification

| Action | Classification | Notes |
|---|---|---|
| Add `webApplicationInfo` to manifest.json | (a) Automatable from repo | Manifest is a committed repo file; a code change. |
| Add `<WebApplicationInfo>` to manifest.xml | (a) Automatable from repo | Same as above. |
| Add Dev Tunnel hosts to validDomains / AppDomains | (a) Automatable from repo | Manifest edit. Note: Dev Tunnel hostnames are session-specific; production domains differ. |
| Add `@azure/msal-browser` dependency | (a) Automatable from repo | `npm install @azure/msal-browser`; package.json change. |
| Add NAA MSAL client-side code | (a) Automatable from repo | TypeScript source change in host-wiring modules. |
| Runtime NAA support check in bootstrap | (a) Automatable from repo | `isSetSupported("NestedAppAuth", "1.1")` guard in ifile.ts. |
| Add SPA redirect URI `brk-multihub://...` to Entra app | (b) Automatable via CLI | `az ad app update --id 2921bc0b-... --web-redirect-uris <existing> --public-client-redirect-uris <existing>` — note: SPA redirects use `--spa-redirect-uris` in az cli. Exact command: `az ad app update --id 2921bc0b-4518-4547-b8ca-f937713688ec --web-redirect-uris "brk-multihub://taskmaster-ios-3000.use.devtunnels.ms"` (or use the `az rest` approach for SPA URIs specifically). Requires caller with app owner or admin rights. |
| Set Application ID URI | (b) Automatable via CLI | `az ad app update --id 2921bc0b-... --identifier-uris "api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-..."`. Requires app owner or admin. |
| Add `access_as_user` scope | (c) Manual portal action | Exposing an API scope (with display names, consent settings, state) is not easily done via basic az CLI commands; the `az ad app` CLI does not have a clean single-command equivalent for the full scope definition. Doable via `az rest` POST to the Graph API, but complex; classify as manual portal for a human operator. |
| Pre-authorize Office client IDs | (b) Automatable via CLI | Can be done via `az rest --method PATCH` against the application's `api.preAuthorizedApplications` property in the Graph API. Requires app owner or admin. |
| Add Graph delegated permissions | (b) Automatable via CLI | `az ad app permission add --id 2921bc0b-... --api 00000003-0000-0000-c000-000000000000 --api-permissions <scope-guid>=Scope`. The Graph API scope GUIDs for Mail.ReadBasic, Mail.ReadWrite, Files.ReadWrite are stable and can be looked up. Requires caller with app owner permissions. |
| Grant admin consent | (c) Manual tenant-admin action | Requires a Global Administrator or Privileged Role Administrator on the tenant `d80d0ee6-...`. No non-admin automation path exists. This is the existing HI-1 runbook step. |
| Set access token version to v2 in manifest | (b) Automatable via CLI | `az ad app update --id 2921bc0b-... --set api.requestedAccessTokenVersion=2` via `az rest`. |
| Create client secret | (c) Manual action (or pipeline secret injection) | Creating a secret in the portal is a one-time human step; the resulting value must be injected into user-secrets or a secrets store by a human operator. Cannot be automated without a pre-existing secrets-management system. |
| Populate user-secrets on dev machine | (c) Human operator action | `dotnet user-secrets set "AzureAd:ClientSecret" "<value>"` must be run by the developer who holds the secret value. |

---

## 6. Key Gaps and Ambiguities in Documentation

1. **NAA and `webApplicationInfo` relationship:** The NAA guide does not explicitly state whether `webApplicationInfo` is required or optional when NAA is the primary path. It describes NAA configuration purely through MSAL code and the SPA redirect URI. The conclusion that `webApplicationInfo` is required for the legacy SSO fallback (but not for NAA itself) is inferred from the documentation structure and confirmed by the fact that the NAA guide makes no mention of it. This inference is well-supported but not an explicit statement.

2. **`IdentityAPI 1.3` on iOS:** The requirement-set table does not list `IdentityAPI 1.3` in the iOS row. The documentation does not make an explicit statement that `getAccessToken` fails on iOS; it only shows that `IdentityAPI 1.3` is not in the iOS platform support row. The practical consequence — that `getAccessToken` is unreliable on iOS — is implied by the table but not stated directly.

3. **Dev Tunnel hostnames:** The Dev Tunnel hostnames (`taskmaster-ios-3000.use.devtunnels.ms`, `taskmaster-api-7287.use.devtunnels.ms`) used throughout this document are taken from the context provided by the user and confirmed in the repo's remediation inputs. Dev Tunnel hostnames can be session-scoped; production deployment will require updating the Application ID URI and SPA redirect URI to stable production domains.

4. **`az ad app` CLI for SPA redirects:** The exact az CLI command syntax for adding a SPA redirect URI of type `brk-multihub://` (a non-HTTPS scheme) may require `az rest` rather than the standard `az ad app update` because the CLI may validate or reject non-HTTPS SPA redirect URIs. This should be tested by an operator before scripting. Classified as (b) automatable-via-CLI with the caveat that exact command syntax requires operator validation.

---

## 7. Summary of Recommended Changes

**Entra app (existing "Graph Mail Calendar PoC"):**
1. Add SPA redirect URI: `brk-multihub://taskmaster-ios-3000.use.devtunnels.ms`
2. Set Application ID URI: `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec`
3. Expose `access_as_user` scope
4. Pre-authorize `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e` (Office umbrella) for `access_as_user`
5. Add delegated Graph permissions: `Mail.ReadBasic`, `Mail.ReadWrite`, `Files.ReadWrite`, `openid`, `profile`
6. Grant admin consent (HI-1, already declared)
7. Set manifest `requestedAccessTokenVersion: 2`
8. Create client secret (inject into user-secrets, never commit)

**manifest.json (unified manifest — desktop/web only):**
- Add `webApplicationInfo.id` and `webApplicationInfo.resource`
- Add Dev Tunnel domains to `validDomains`

**manifest.xml (add-in only manifest — mobile operative):**
- Add `<WebApplicationInfo>` block with `<Id>`, `<Resource>`, `<Scopes>`
- Add Dev Tunnel domains to `<AppDomains>`

**Client TypeScript:**
- Add `@azure/msal-browser` package
- Replace `Office.auth.getAccessToken` with `createNestablePublicClientApplication` + `acquireTokenSilent` / `acquireTokenPopup` in the NAA-primary path
- Add `isSetSupported("NestedAppAuth", "1.1")` runtime guard; retain legacy-SSO or dialog-API fallback for unsupported environments

**Backend config (user-secrets only, never appsettings.json):**
- `AzureAd:Instance` = `https://login.microsoftonline.com/`
- `AzureAd:TenantId` = `d80d0ee6-3e37-43d7-9974-0ae662873253`
- `AzureAd:ClientId` = `2921bc0b-4518-4547-b8ca-f937713688ec`
- `AzureAd:Audience` = `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec`
- `AzureAd:ClientSecret` = `<secret from portal — inject via user-secrets or environment>`
