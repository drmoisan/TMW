---
name: ifile-naa-signin-blocked-43
description: iFile (#43) on-device NAA sign-in on Outlook iOS is blocked by a NAA broker bridge rejection; resolution requires Entra app-registration verification, not more client instrumentation.
metadata:
  type: project
---

As of 2026-06-06, iFile (issue #43) sign-in on Outlook iOS fails at NAA token acquisition with an MSAL `ServerError` whose stack is `fromBridgeError@...` — a NAA broker bridge rejection carrying no Entra `AADSTS` code and no correlation id.

Diagnosis established over device builds diag-1..diag-7: the build, device cache, served bundle, code path, and network are all confirmed good (build stamp + content hash proved the device runs current code). The failure is a NAA registration/configuration problem at the Office-host broker, not a credential/build/network problem.

Key dead-end finding (saves future re-investigation): **MSAL does not surface a readable reason for this bridge error on-device at any log level — not even with `piiLoggingEnabled: true`.** The on-screen `msalLog` capture only yields an opaque MSAL telemetry token (`Warning - 1yb4fi`), identical across minified and unminified builds. Do not keep instrumenting the client for this class of failure; the reason lives in the Entra app registration / sign-in logs.

**Status 2026-06-06: fix applied in working tree (remediation cycle 4), pending on-device re-verify.** The in-repo chain was realigned to app `3592bf52-…` (code `CLIENT_ID`, both manifests' `webApplicationInfo` id/resource, test assertion) and the temporary PII diagnostic was reverted (`piiLoggingEnabled:false`, `containsPii` guard reinstated). Toolchain green, 0 blocking audit findings. Still gated on HI-1 (admin consent on the new app), HI-2 (on-device re-verify that NAA sign-in now succeeds), HI-3 (backend OBO user-secrets set to `3592bf52-…`). Changes not yet committed.

**Root cause identified 2026-06-06: client-ID / app-registration mismatch.** The iFile code (`src/taskpane/ifile/naa-token-acquirer.ts`, `CLIENT_ID`) authenticates against app **`2921bc0b-4518-4547-b8ca-f937713688ec`** ("Graph Mail Calendar PoC"). The user configured the `brk-multihub://taskmaster-ios-3000.use.devtunnels.ms` SPA redirect, the `api://…/3592bf52…` App ID URI, `access_as_user`, the `ea5a67f6` Office pre-authorization, and 9 Graph permissions on a DIFFERENT app, **`3592bf52-46f6-4eb0-835c-4f961058de97`** ("TaskMaster Web"). The broker rejects the token request for `2921bc0b…` because that app has no matching `brk-multihub` SPA redirect — producing the `fromBridgeError → ServerError` with no AADSTS code / no correlation id (pre-AAD broker rejection). Fix: make the whole chain (client `CLIENT_ID`, manifest App ID URI / `WebApplicationInfo`, backend `AzureAd:ClientId`/`Audience`) reference ONE app — either repoint code to `3592bf52…`, or configure `2921bc0b…`.

Secondary checks after the IDs match:
1. SPA redirect URI must be registered under the **Single-page application** platform (not Web / not Mobile-desktop) on the chosen app.
2. Signed-in Outlook account must be admitted by the app's supported account types (client uses `authority=common`).
3. Delegated Graph `Mail.ReadBasic`/`Mail.ReadWrite`/`Files.ReadWrite` granted.

**Why:** The user does not have Entra sign-in-log privileges and may lack app-registration access, so resolution likely requires handing the one-line diagnosis to the Entra app owner.

**How to apply:** If this resurfaces, skip client-side log instrumentation and go straight to verifying the SPA `brk-multihub` redirect URI. Also pending: a temporary PII-logging diagnostic in `src/taskpane/ifile/naa-token-acquirer.ts` (`piiLoggingEnabled: true` + removed containsPii skip) MUST be reverted before any PR/release. Relates to [[ios-addin-on-device-cache-iteration]] and [[feedback_ci_green_is_not_device_working]].
