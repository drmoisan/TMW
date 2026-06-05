# Runbook: Outlook On-Device Verification (iFile, Issue #43)

This runbook is a human-execution exception artifact produced under the autonomous-execution
mandate (issue #45). It covers the iFile acceptance criteria that require visual confirmation on
real Outlook clients — there is no programmatic rendering-assertion path for the Office.js add-in
surface, and Outlook on iOS verification inherently requires a physical device and a signed-in
user.

- Feature: iFile message-filing (issue #43, PR #44)
- Requirement id: HI-2 (response: exception)
- Classification: human-gated (no CI mechanism can confirm on-device rendering). See the
  automation-feasibility assessment in
  `artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md`.
- Covers manual acceptance criteria: AC-2, AC-3, AC-11, AC-12, AC-13, AC-20, AC-21, AC-24
  (and the visible-ordering confirmation noted for AC-1). The CI-verifiable portions of each are
  already green; this runbook records only the on-device confirmation.

## Cue

Perform these steps after `entra-admin-consent.runbook.md` (HI-1, Graph scopes consented) and
`entra-app-sso-config.runbook.md` (HI-3, the Entra app configured for NAA + OBO: SPA redirect,
Application ID URI, exposed scope, token version, client secret) are both complete, and after the
iFile build is hosted at a reachable HTTPS endpoint. The trigger is: the iFile branch (PR #44) is
ready for sign-off and the nine manual acceptance criteria in
`../evidence/other/manual-verification.md` are still marked `PENDING-DEVICE`.

## Prerequisites

- An **Exchange Administrator** or **Global Administrator** account to deploy the add-in (for
  Centralized Deployment / Integrated Apps), or a single test account for sideloading.
- The iFile add-in manifest: `manifest.xml` (add-in-only manifest, used for mobile) and/or the
  unified `manifest.json`.
- The iFile bundle hosted over **HTTPS** at the domain configured in the manifest (the production
  domain must replace the `localhost` placeholder; see `../evidence/other/aad-scope-changes.md`).
- A physical **iOS** device with the Outlook app installed and signed in with the test account, and
  access to **Outlook on the web** (and/or new Outlook for Windows) for the desktop checks.
- A test message in the mailbox that has at least one non-inline file attachment, plus a second
  message with no attachments.
- The Entra app registration configured for NAA + OBO per `entra-app-sso-config.runbook.md` (HI-3)
  and admin consent granted per `entra-admin-consent.runbook.md` (HI-1). The NAA SPA redirect host
  and the Application ID URI host must match the Dev Tunnel host used for the build.

## Client token path (NAA)

The active client-side token mechanism is **NAA (nested app authentication)**, not the legacy
`Office.auth.getAccessToken` SSO path. At runtime the host shell gates on
`isSetSupported("NestedAppAuth", "1.1")` and, when supported, acquires the token through MSAL.js
via `createNestablePublicClientApplication` + `acquireTokenSilent`, falling back to
`acquireTokenPopup` on an interaction-required error
(`src/taskpane/ifile/naa-token-acquirer.ts`). When NAA is not supported in the environment, the
shell renders a visible sign-in-stage error rather than failing silently.

Requirement — the Entra Application ID URI and the NAA SPA redirect host MUST match the active Dev
Tunnel host used for the build. For the page host `taskmaster-ios-3000.use.devtunnels.ms`, the
Application ID URI is
`api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec` and the SPA
redirect is `brk-multihub://taskmaster-ios-3000.use.devtunnels.ms`. If the build uses a different
tunnel host, these MUST be updated to match (see `entra-app-sso-config.runbook.md`, HI-3) or NAA
token acquisition will fail.

## Step-by-step Instructions

### 0. Build the bundle with a reachable backend URL (mobile build)

A physical iOS device cannot reach `https://localhost:3000`; that host resolves to the device
itself, so `GET /api/ifile/folders` never reaches the backend. A mobile build MUST inject a
reachable Dev-Tunnel or deployed backend host as `API_BASE_URL` and set the mobile-build flag
before building. The runtime guard `assertReachableApiBaseUrl`
(`src/taskpane/ifile/api-base-url.ts`, wired in `webpack.config.js` and consumed in
`src/taskpane/ifile/ifile.ts`) fails fast and renders a visible error if a mobile build is left
pointed at localhost.

1. Start the backend Dev Tunnel (or confirm the deployed backend host) and note its HTTPS URL,
   for example `https://taskmaster-api.<cluster>.devtunnels.ms`. Do not commit this URL; it is a
   per-environment value supplied at build time.
2. Set the build-time variables, then build (PowerShell):

   ```powershell
   $env:API_BASE_URL = "https://taskmaster-api.<cluster>.devtunnels.ms"
   $env:IFILE_MOBILE_BUILD = "1"
   npm run build
   ```

   `API_BASE_URL` is injected as `__API_BASE_URL__`; `IFILE_MOBILE_BUILD=1` is injected as
   `__IS_MOBILE_BUILD__ = true`. A mobile build that omits `API_BASE_URL` (leaving the localhost
   default) is rejected at runtime by the guard, which is the intended fail-fast behavior.
3. Host the built bundle over HTTPS at the domain configured in the manifest, then proceed to
   deploy/sideload below. After sideloading, confirm on the device that typing a known folder name
   in the iFile search returns matching folders (not an empty or error state); an error row means
   the injected `API_BASE_URL` is not reachable from the device.

### 1. Deploy or sideload the add-in

Centralized Deployment (organization or specific users):

1. Sign in to the Microsoft 365 admin center.
2. Select **Settings** > **Integrated apps**.
3. Select **Upload custom apps**.
4. In the wizard: for the add-in-only manifest choose **App type = Office Add-in** and upload
   `manifest.xml`; for the unified manifest choose **App type = Teams app** and upload the ZIP.
5. Select **Next**, choose the audience (**Just me** is sufficient for verification), select
   **Next**, accept the permission request (**Accept permissions**, Global Admin), then
   **Finish deployment**. Allow up to 24 hours for propagation.

Sideload (single user, faster):

1. Open https://aka.ms/olksideload in a browser (opens the **Add-Ins for Outlook** dialog).
2. Select **My add-ins**.
3. Under **Custom Addins**, select **Add a custom add-in** > **Add from File**, choose
   `manifest.xml`, and accept the prompts.

### 2. Desktop verification (Outlook on the web / new Outlook)

4. Open a message in **Read** mode.
5. Confirm **`iFile` is the first command** in the TaskMaster group on the message-read surface
   (AC-1 visible ordering).
6. Activate **`iFile`**. Confirm a dialog opens containing a **search textbox and a results list**
   (AC-2).
7. With the textbox empty, confirm the list shows **no search results**; type a pattern (including
   a wildcard such as `Proj*`) and confirm matching **leaf folders are prepended** and update live
   (covered by CI, confirm visually).
8. On first filing (no stored mapping), confirm you are offered to **select an existing OneDrive
   folder or create a new one** as the Archive root, and that no folder named `Archive` is
   auto-created (AC-21, AC-24 desktop).
9. Select a destination. Confirm the message **moves** to that Outlook folder (AC-12) and that the
   message's **non-inline attachments appear** in the mirrored OneDrive folder beneath the chosen
   Archive root, with intermediate folders created (AC-13). Confirm a no-attachment message files
   with no OneDrive writes.

### 3. iOS device verification

10. On the iOS device, open the **Outlook** app signed in with the same account.
11. Open a message in Read mode.
12. Tap **More options** (the three-dots overflow) in the message toolbar.
13. Select **`iFile`** from the list. Confirm the search UI opens **inline in the full-screen task
    pane** (not a dialog) with the same search box and results list (AC-3, AC-24 mobile).
14. Repeat the search, first-use picker, move, and attachment-mirror checks (AC-11 mobile REST-id
    acceptance, AC-12, AC-13, AC-21) on the device.

## Verification

You have completed this correctly when, in `../evidence/other/manual-verification.md`, every row
(AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24) has the device/build fields filled in
and an **Observed result** plus a **Pass** mark replacing each `PENDING-DEVICE` marker, specifically:

1. Desktop: `iFile` first; dialog with search box + list; live search; first-use select-or-create
   picker; message moved; attachments mirrored to OneDrive; no-attachment message filed cleanly.
2. iOS: `iFile` reachable via **More options**; the same UI inline in the full-screen pane; move and
   attachment-mirror succeed on the device.
3. Record the Outlook desktop and iOS build/version strings used.

If any step fails, capture the observed behavior in the dossier as the Observed result with a Fail
mark; that becomes a blocking finding for PR #44.

## Declared Exception (HI-2)

HI-2 remains the single remaining declared human-interaction exception for this feature. No CI
mechanism can confirm on-device rendering or the live device folder-load, so the final on-device
visual/end-to-end confirmation — including the build-with-reachable-URL step in Section 0 above and
the live folder-search check — is performed manually per this runbook. HI-2 **gates feature DONE
but not cycle exit**: the code-and-test changes for the backend-URL guard and the load-failure
resilience are fully automatable and CI-verified, and the remediation cycle exits on a green
toolchain plus zero blocking re-audit findings. Feature DONE is reached only after this on-device
confirmation is completed and recorded in `../evidence/other/manual-verification.md`.

## Source and Citation

- Deploy and manage Office Add-ins (Microsoft 365 admin center / Integrated Apps):
  https://learn.microsoft.com/en-us/microsoft-365/admin/manage/office-addins
  (Microsoft Learn, updated 2026-05-28; accessed 2026-06-01).
- Sideload Outlook add-ins for testing:
  https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/sideload-outlook-add-ins-for-testing
  (Microsoft Learn, updated 2026-04-29; accessed 2026-06-01).
- Test your Outlook add-in on mobile devices:
  https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/test-mobile-add-ins
  (Microsoft Learn, updated 2026-04-29; accessed 2026-06-01).

Sourcing note: UI navigation above was obtained via web retrieval of the current Microsoft Learn
documentation on 2026-06-01, not from model training data, per the human-exception-runbook contract
(MCP-first, web-second).
