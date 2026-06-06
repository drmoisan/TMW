# TMW

TaskMaster — a No-COM Outlook task pane add-in. The runtime is implemented in
TypeScript using the Office.js API and (in later phases) Microsoft Graph; the
project deliberately avoids VSTO, Outlook PIA / COM interop, and any
dependence on the desktop object model. See
[`docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md`](docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md)
for the architecture decision record and
[`.claude/rules/architecture-boundaries.md`](.claude/rules/architecture-boundaries.md)
for the enforceable boundary assertions.

The current codebase is an Office Add-in TaskPane scaffold with quality gates,
CI pipeline, and supporting infrastructure in place. Feature work targeting
TaskMaster behavior lands in subsequent prompts.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/taskpane/` | Office.js task pane UI entry point and supporting modules. |
| `src/taskpane/ifile/` | iFile message-filing feature (Issue #43): pure host-neutral search/compose/path modules, a presentation-agnostic controller, and dialog/inline host wiring. Renders as a desktop Office Dialog and a mobile inline task pane from one shared bundle. |
| `src/commands/` | Function-file command handlers invoked by ribbon controls. |
| `src/test-support/` | Vitest setup, Office.js fake module, MSW server. Not shipped to production. |
| `tests/violations/` | Disabled fixtures used to demonstrate that each CI gate rejects the matching violation. |
| `.github/actions/` | Composite actions for the seven-stage CI pipeline (format, lint, typecheck, architecture, test, contract, integration). |
| `.github/workflows/` | Workflow definitions that orchestrate the composite actions. |
| `.github/scripts/` | PowerShell helpers used by hooks and workflows (e.g. branch protection, gitleaks install). |
| `.claude/rules/` | Authoritative policy files for code change, testing, suppressions, architecture, and tonality. |
| `.claude/skills/` | Workflow definitions consumed by automation agents. |
| `docs/` | Architecture notes, governance documents, and feature-folder evidence. |
| `assets/` | Static assets referenced by the add-in manifest. |
| `manifest.json` | Office Add-in manifest. |

## Prerequisites

- Node.js 20.x (matches the version pinned in CI).
- npm 10.x.
- PowerShell 7+ for local script invocation. The repository's shell-bound
  tooling (lefthook, gitleaks helper, branch-protection script) targets pwsh.

## Getting started

```powershell
git clone https://github.com/drmoisan/TMW.git
cd TMW
npm ci
npx lefthook install
```

## Quality gates

The project enforces a seven-stage CI toolchain that mirrors the local
toolchain commands. Run the gates locally before pushing:

```powershell
npm run format:check    # stage 1 — Prettier
npm run lint            # stage 2 — ESLint flat config (type-aware)
npm run typecheck       # stage 3 — tsc --noEmit
npm run depcruise       # stage 4 — dependency-cruiser architecture rules
npm run test:coverage   # stage 5 — Vitest with coverage thresholds 85/75/85/85
```

Auto-fix scripts: `npm run format`, `npm run lint:fix`. The full reference,
including configuration paths, CI action mapping, coverage thresholds, and
troubleshooting, is in [`docs/quality-gates.md`](docs/quality-gates.md).

## Local development

| Command | Purpose |
| --- | --- |
| `npm run build` | Production webpack build. |
| `npm run build:dev` | Development webpack build. |
| `npm run dev-server` | Run the webpack dev server over HTTPS. |
| `npm run watch` | Webpack in watch mode. |
| `npm run start` | Side-load the add-in into the configured Office host. |
| `npm run stop` | Stop a running side-load session. |
| `npm run validate` | Validate `manifest.json`. |
| `npm run validate:xml` | Validate `manifest.xml`. |
| `npm run mobile:start` | Start the local static server and Microsoft Dev Tunnel host used for Outlook Mobile iOS verification. |
| `npm run mobile:stop` | Stop the mobile connectivity processes recorded by `npm run mobile:start`. |
| `npm run signin` / `npm run signout` | Manage the dev M365 account used by `office-addin-dev-settings`. |

## Loading the mobile add-in for testing

Outlook Mobile (iOS) loads the add-in from a publicly reachable HTTPS endpoint
with a trusted (non-self-signed) certificate. iFile requires the .NET API
backend to be reachable from the device as well as the static bundle. Three
layers must be running simultaneously: the .NET API, the static bundle server,
and two Dev Tunnels (one per layer).

### Prerequisites

- The base prerequisites under [Prerequisites](#prerequisites) (Node.js 20.x,
  npm 10.x, PowerShell 7+).
- .NET 10 SDK (`dotnet --version` should report `10.x`).
- The Microsoft Dev Tunnels CLI on `PATH`
  (`winget install Microsoft.devtunnel`). `npm run mobile:start` also resolves
  the WinGet Links shim and Packages path if `devtunnel` is not on `PATH`.
- An Azure AD app registration with the required delegated permissions
  (`Mail.ReadWrite`, `Files.ReadWrite`, `Mail.ReadBasic`). Record its
  `TenantId`, `ClientId`, and the `api://<ClientId>` Application ID URI.
- A Microsoft 365 account that can install custom add-ins in Outlook on the
  web, signed in on the iPhone's Outlook app. Use `npm run signin` to register
  the dev account with `office-addin-dev-settings` when needed.

### One-time tunnel setup

Two named tunnels are required: `taskmaster-ios` for the static bundle (port
3000) and `taskmaster-api` for the .NET API (port 7287). Create each once:

```powershell
devtunnel user login

# Static bundle tunnel
devtunnel create taskmaster-ios
devtunnel port create taskmaster-ios -p 3000
devtunnel access create taskmaster-ios -p 3000 --anonymous

# API tunnel
devtunnel create taskmaster-api --allow-anonymous
devtunnel port create taskmaster-api -p 7287 --protocol https
```

Record both tunnel URLs — they are stable for their tunnel ids. Each forwarded
port is exposed at a host of the form `https://<id>-<port>.<cluster>.devtunnels.ms`,
where `<id>` is the service-assigned tunnel id and `<port>` is the forwarded port.
The host is not `taskmaster-ios.<cluster>.devtunnels.ms`; it includes the
`-<port>` segment. Copy the printed port-forwarding URL exactly:

```powershell
devtunnel show taskmaster-ios   # copy the port-3000 URL, e.g. https://<id>-3000.<cluster>.devtunnels.ms
devtunnel show taskmaster-api   # copy the port-7287 URL, e.g. https://<id>-7287.<cluster>.devtunnels.ms
```

### One-time API configuration (user secrets)

The .NET API authenticates with Azure AD and enforces CORS for the mobile
origin. Configure both via `dotnet user-secrets`. If the `--project` flag
produces a `DotNetMuxer` error in your terminal, use `--id` with the project's
`UserSecretsId` instead (see below).

Set these once for the session, then reuse them below.

```powershell
$tenantId  = "<your-tenant-id>"   # Azure AD app registration tenant id
```

```powershell
$clientId  = "<your-client-id>"   # Azure AD app registration client id
```

```powershell
$secretsId = "b3c44e17-fca8-45e2-a550-80f2d481007e"   # project UserSecretsId (from TaskMaster.Api.csproj)
```

```powershell
# Build the iOS tunnel origin from the Tunnel ID. `devtunnel show` prints no URL;
# the Tunnel ID is "<name>.<cluster>" and the port-3000 host that serves the
# bundle is "<name>-3000.<cluster>.devtunnels.ms" (note the -3000 segment).
$iosId = (devtunnel show taskmaster-ios |
  Select-String -Pattern 'Tunnel ID\s*:\s*(\S+)').Matches.Groups[1].Value
if (-not $iosId) { throw "Could not read the taskmaster-ios Tunnel ID from 'devtunnel show'." }
$iosCluster = ($iosId -split '\.')[-1]
$iosName    = $iosId.Substring(0, $iosId.Length - $iosCluster.Length - 1)
$iosOrigin  = "https://$iosName-3000.$iosCluster.devtunnels.ms"

# Azure AD
dotnet user-secrets set "AzureAd:Instance"  "https://login.microsoftonline.com/" --id $secretsId
dotnet user-secrets set "AzureAd:TenantId"  "$tenantId"                           --id $secretsId
dotnet user-secrets set "AzureAd:ClientId"  "$clientId"                           --id $secretsId
dotnet user-secrets set "AzureAd:Audience"  "api://$clientId"                     --id $secretsId

# CORS — the iOS tunnel origin (no trailing slash)
dotnet user-secrets set "MobileDev:AllowedOrigin" "$iosOrigin" --id $secretsId
```

Secrets are stored outside the repository at
`%APPDATA%\Microsoft\UserSecrets\b3c44e17-fca8-45e2-a550-80f2d481007e\secrets.json`
and are never committed. Verify with:

```powershell
dotnet user-secrets list --id $secretsId
```

### Build

Supply both tunnel URLs as environment variables before building. The webpack
`DefinePlugin` injects `API_BASE_URL` into the bundle and rewrites static asset
URLs to `ADDIN_URL_PROD`; no source file edits are required or committed.

```powershell
# `devtunnel show` prints no URL. Build each from its Tunnel ID ("<name>.<cluster>");
# the per-port host is "<name>-<port>.<cluster>.devtunnels.ms" (note the -<port>
# segment). ADDIN_URL_PROD needs a trailing slash; API_BASE_URL does not.
function Get-DevTunnelPortUrl {
  param([Parameter(Mandatory)][string]$TunnelName, [Parameter(Mandatory)][int]$Port)
  $id = (devtunnel show $TunnelName |
    Select-String -Pattern 'Tunnel ID\s*:\s*(\S+)').Matches.Groups[1].Value
  if (-not $id) { throw "Could not read the $TunnelName Tunnel ID from 'devtunnel show'." }
  $cluster = ($id -split '\.')[-1]
  $name    = $id.Substring(0, $id.Length - $cluster.Length - 1)
  "https://$name-$Port.$cluster.devtunnels.ms"
}

$iosUrl = Get-DevTunnelPortUrl -TunnelName taskmaster-ios -Port 3000
$apiUrl = Get-DevTunnelPortUrl -TunnelName taskmaster-api -Port 7287

$env:API_BASE_URL    = $apiUrl
$env:ADDIN_URL_PROD  = "$iosUrl/"
npm run build
```

The build must complete before starting the servers. Rebuild whenever the
tunnel URLs change or the source changes.

### Start all three layers

Open three separate terminals and start each layer. All three must be running
before opening the add-in on the device.

**Terminal 1 — .NET API backend:**

```powershell
Start-Process pwsh -ArgumentList '-NoExit', '-Command', 'dotnet run --project src\TaskMaster.Api --launch-profile https'
```

Listens on `https://localhost:7287`. User secrets are loaded automatically
when `ASPNETCORE_ENVIRONMENT` is `Development` (set in `launchSettings.json`).

**Terminal 2 — Static bundle server and iOS tunnel:**

```powershell
Start-Process pwsh -ArgumentList '-NoExit', '-Command', 'npm run mobile:start'
```

Serves `dist/` through `http-server` on port 3000 and hosts the
`taskmaster-ios` Dev Tunnel in the background. Process ids and state are
recorded so `npm run mobile:stop` can stop the same processes.

**Terminal 3 — API tunnel:**

```powershell
Start-Process pwsh -ArgumentList '-NoExit', '-Command', 'devtunnel host taskmaster-api'
```

Forwards traffic from the `taskmaster-api` tunnel URL to the local API on port
7287.


**Combined Launch Commands:**

```powershell
Start-Process pwsh -ArgumentList '-NoExit', '-Command', 'dotnet run --project src\TaskMaster.Api --launch-profile https'
Start-Process pwsh -ArgumentList '-NoExit', '-Command', 'npm run mobile:start'
Start-Process pwsh -ArgumentList '-NoExit', '-Command', 'devtunnel host taskmaster-api'
echo "Complete"
```

### Sideload and launch

Steps 1–4 are the current Outlook on the web sideload flow (verified against
Microsoft Learn, 2026-04-29). The legacy "Get Add-ins" entry point is no longer
used; the `aka.ms/olksideload` deep link opens the sideload dialog directly.

1. In a browser signed into the Microsoft 365 account, navigate to
   <https://aka.ms/olksideload>. Outlook on the web opens and the **Add-Ins for
   Outlook** dialog appears after a few seconds.
2. Select **My add-ins** in the dialog, scroll to the **Custom Addins** section,
   then select **Add a custom add-in → Add from File**.
3. Select the built `dist/manifest.xml` and accept the prompts.
4. Open the Outlook app on the iPhone signed into the same account and wait for
   the add-in to sync to the device. No separate mobile sideload step is
   required.
5. Open a message in read mode, tap the **More options** (•••) menu, and select
   **TaskMaster**. The task pane opens full-screen.

Notes:

- The **Custom Addins** controls are visible only if the account holds the
  Exchange **My Custom Apps** role (on by default) and the organization has
  add-ins enabled.
- Mobile availability requires the XML add-in manifest with a
  `<MobileFormFactor>` section (the repo's `manifest.xml`). The unified (JSON)
  app manifest is not supported on Outlook mobile.
- If the iOS WebView is blocked by the Dev Tunnels one-time anti-phishing
  interstitial, accept the tunnel origin once in mobile Safari, then reopen the
  add-in.

### Stop and clean up

Stop the static server and iOS tunnel:

```powershell
npm run mobile:stop
```

Stop the API tunnel by pressing `Ctrl+C` in Terminal 3. Stop the .NET API by
pressing `Ctrl+C` in Terminal 1. The `$env:API_BASE_URL` and
`$env:ADDIN_URL_PROD` environment variables are session-scoped and do not
persist after the terminal closes.

## Outlook Mobile iOS validation

Issue #35 verified the add-in on Outlook for iOS using a production webpack
bundle served through a Microsoft Dev Tunnel endpoint with publicly trusted TLS.
The evidence is recorded under
[`docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/notes`](docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/notes).

The verified iOS flow sideloads the built `dist/manifest.xml` through Outlook on
the web, waits for the add-in to sync to Outlook on the iPhone, opens a message,
and launches TaskMaster from the message "More options" menu. The 2026-05-20
evidence confirms that the pane opens full-screen on iPhone, renders the
selected message Subject/From context using Office.js read APIs, exposes the
Close button wired to `Office.context.ui.closeContainer()`, and re-renders when
`Office.EventType.ItemChanged` fires during message navigation.

The Classify / Confirm / Reject controls are present, but the classify and
feedback workflow is not currently wired in product code on any platform.
Mobile parity for issue #35 therefore excludes classification success; that gap
is tracked separately as GitHub issue #37.

## Testing

Unit tests use Vitest with jsdom, MSW v2 for HTTP stubbing, and an Office.js
fake module wired via `resolve.alias` and `globalThis`. Coverage thresholds
are uniform across all rigor tiers per
[`.claude/rules/quality-tiers.md`](.claude/rules/quality-tiers.md). Test
conventions (Arrange–Act–Assert, controlled clock, seeded RNG, no temp files)
are defined in
[`.claude/rules/general-unit-test.md`](.claude/rules/general-unit-test.md).

## Contributing

1. Branch from `main` using the `feature/<short-name>-<issue-number>` naming
   convention.
2. Make small, focused commits that follow
   [Conventional Commits](https://www.conventionalcommits.org/). The
   `commit-msg` lefthook hook enforces this locally; CI does not.
3. Run the local gate sweep (see [Quality gates](#quality-gates)) before
   pushing.
4. Open a pull request against `main`. Branch protection requires every CI
   check to pass before merge; the required checks are documented in
   [`docs/branch-protection.md`](docs/branch-protection.md).

Policy files referenced by reviewers and automation:

- [`.claude/rules/general-code-change.md`](.claude/rules/general-code-change.md)
  — design principles, toolchain order, file-size limit, error handling.
- [`.claude/rules/general-unit-test.md`](.claude/rules/general-unit-test.md)
  — test independence, isolation, determinism, coverage requirements.
- [`.claude/rules/typescript.md`](.claude/rules/typescript.md) — TypeScript
  coding standards, ESLint stack, testing standards.
- [`.claude/rules/typescript-suppressions.md`](.claude/rules/typescript-suppressions.md)
  — authorized suppression patterns and escalation path.
- [`.claude/rules/architecture-boundaries.md`](.claude/rules/architecture-boundaries.md)
  — No-COM architecture assertions and layer boundaries.
- [`.claude/rules/quality-tiers.md`](.claude/rules/quality-tiers.md) — module
  rigor tier definitions and gate matrix.
- [`.claude/rules/tonality.md`](.claude/rules/tonality.md) — required tone
  for agent-authored content.

## License

MIT, per the `"license"` field in [`package.json`](package.json).
