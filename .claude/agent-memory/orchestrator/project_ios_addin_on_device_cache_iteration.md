---
name: ios-addin-on-device-cache-iteration
description: On-device iOS Outlook add-in iteration requires content-hashed bundles + a visible build stamp; the web-view cache only flushes on a full Outlook reinstall, not re-sideload.
metadata:
  type: project
---

For Outlook-on-iOS add-in verification in this repo (iFile / issue #43, mobile-parity #35 lineage), the device runs the bundle served from `dist/` via `scripts/powershell/Start-MobileConnectivity.ps1` (http-server `-c-1` no-cache behind a named Dev Tunnel `taskmaster-ios` → stable host `taskmaster-ios-3000.use.devtunnels.ms`).

Validated operational facts (confirmed live 2026-06-05):
- The iOS Outlook WKWebView caches the add-in bundle inside the app container and ignores the host's no-cache headers. Removing and re-sideloading the add-in does NOT flush it. The only documented reliable flush is deleting and reinstalling Outlook, then signing back in (the add-in reappears automatically because it is registered in the mailbox). See `artifacts/research/2026-06-05-ios-addin-cache-clear-procedure.md`.
- Content-hashed output filenames for `ifile`/`taskpane` (in `webpack.config.js`; `commands.js`/`polyfill.js` stay unhashed because the manifest references `commands.js` by fixed name) bust the JS layer so later rebuilds do not require a reinstall.
- An always-visible build stamp (`#ifile-build-stamp`, fed by `__BUILD_ID__`, set with `$env:BUILD_ID`) renders before token acquisition, so the loaded build is readable on the device even on the sign-in error screen. Use it to confirm the device is on the latest bundle before trusting any other on-device diagnostic.

**Why:** A full debugging session was lost to the device silently running a cached bundle while the host served the new one; rebuilds appeared to have "no effect" on the device. Build correctness was provable in `dist/` but not on the phone.

**How to apply:** When an on-device change "doesn't appear," first read the build stamp. If it is stale, the cache is the cause — reinstall Outlook once, then rely on the content hash thereafter. Do not assume a rebuild reached the device without the stamp confirming it. Relates to [[feedback_ci_green_is_not_device_working]].
