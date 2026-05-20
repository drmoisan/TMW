# outlook-mobile-ios-parity — Spec

- **Issue:** #35
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-19
- **Status:** Draft
- **Version:** 1.0
- **Work Mode:** full-feature

## Overview

The TaskMaster for Outlook add-in currently ships a single unified app manifest for
Microsoft 365 (`manifest.json`, `manifestVersion` 1.17, Mailbox requirement set 1.5)
targeting the desktop/web task-pane form factor only. Users who triage mail on iPhones
cannot reach the classify/triage/feedback workflow that desktop users rely on.

The early issue framing proposed declaring a `mobileFormFactor` inside the existing
unified `manifest.json`. That approach is not viable. Per the authoritative research
(`artifacts/research/2026-05-19-outlook-ios-mobile-support-research.md`, section 1.1),
Microsoft documents the unified manifest for Microsoft 365 as **not supported on Outlook
mobile devices**. Adding syntactically valid mobile stanzas to `manifest.json` would not
cause the add-in to surface on iOS.

The only viable path to Outlook iOS today is a **separate, parallel add-in only manifest**
(`manifest.xml`, `VersionOverridesV1_1`) authored alongside the existing unified manifest.
The new manifest declares both a `<DesktopFormFactor>` and a `<MobileFormFactor>`, both
referencing the same hosted bundle endpoints (`taskpane.html` / `taskpane.js`). The
repository will carry two manifest files until Microsoft ships unified-manifest mobile
support (no committed timeline; research section 1.1 and 3.3).

The research confirms full functional parity with the desktop Message-Read workflow is
achievable on iOS with **no Office.js or `src/` code changes**: all four production Office.js
APIs the add-in uses are within Mailbox requirement set 1.5, which is the ceiling Outlook
mobile supports (research sections 2.1–2.2).

## Behavior

Add Outlook Mobile (iOS) support with full desktop feature parity for the Message-Read
classify/triage/feedback workflow, delivered via a parallel add-in only manifest.

- **Parallel `manifest.xml` (new file).** An add-in only manifest using `VersionOverridesV1_1`.
  It contains:
  - A `<DesktopFormFactor>` translated from the current unified manifest's desktop
    configuration (`MessageReadCommandSurface`, `Button` control, `ShowTaskpane` action,
    16/32/80 px icons), pointing at the same `taskpane.html` URL.
  - A `<MobileFormFactor>` with a `MobileMessageReadCommandSurface` extension point
    containing a `<Group>` wrapping a single `xsi:type="MobileButton"` control whose
    `ShowTaskpane` action opens the same `taskpane.html` URL. No `<OfficeTab>`, no
    `<Supertip>`, no `Menu` controls (research section 1.2).
  - `Mailbox` requirement set `minVersion="1.5"`, matching current API usage (research
    sections 1.2, 2.2).
- **No Office.js / `src/` code changes.** `src/taskpane/taskpane.ts`,
  `src/commands/commands.ts`, and `src/taskpane/classifier-client.ts` remain unchanged. The
  same build artifact serves both surfaces (research sections 2.1, 6.3). The existing
  `manifest.json` remains unchanged for desktop/web deployments.
- **Responsive CSS audit of `taskpane.html`.** On iOS the task pane is full-screen (not a
  side panel). The current layout uses Fabric CSS and a flex layout and already declares
  `<meta name="viewport" content="width=device-width, initial-scale=1">` (correct; research
  sections 3.1, 4.1). The audit must confirm usable rendering at a 375 px (iPhone SE)
  minimum width with no clipped or unreachable controls, reduce the 90×90 header image and
  `<h1>` footprint for narrow viewports, and add an optional "Close" button that calls
  `Office.context.ui.closeContainer()` so a mobile user is not stranded in the full-screen
  pane after completing the workflow (research section 4.2).
- **Nine mobile icon assets.** Add icons at 25×25, 32×32, and 48×48 logical px, each at
  scales 1, 2, and 3 (nine files total), referenced from the `manifest.xml` `<Resources>`
  block via `<bt:Image>` resource IDs. The existing 16/32/80 px assets cannot be reused for
  the mobile icon-size declarations (research section 4.3).
- **Manifest validation tooling.** Add a `package.json` script
  `"validate:xml": "office-addin-manifest validate manifest.xml"` and wire it into the CI
  validation stage. `office-addin-manifest` (`^2.0.3`, already a devDependency) validates
  add-in only manifests against the XML schema (research section 5.1).
- **Webpack icon-copy verification.** Confirm the nine mobile icon assets are emitted to the
  `dist` bundle at the paths declared in `manifest.xml`. The current `CopyWebpackPlugin`
  configuration copies `assets/*`; verify the new icons are included and reachable at their
  declared URLs (research sections 5.2, 6.2).
- **HTTPS hosting / deployment for device reachability.** The task pane and commands HTML
  must be served over HTTPS from an endpoint reachable by the iOS device, using a TLS
  certificate trusted by iOS (not a self-signed development cert). `https://localhost:3000`
  is not reachable from a physical device; a cloud-hosted staging endpoint or a trusted
  tunneling endpoint is required (research sections 4.x, 5.2, 6.4).

## Inputs / Outputs

- **Inputs:** the existing hosted bundle (`taskpane.html`, `taskpane.js`, `commands.html`,
  `commands.js`); the new `manifest.xml`; nine mobile icon image files.
- **Outputs:** a validated `manifest.xml` artifact suitable for sideload via Outlook on the
  web; a `dist` bundle containing the mobile icon assets; CI validation results for the XML
  manifest.
- **Config keys and defaults:** no new application config. The HTTPS production endpoint
  replaces `https://localhost:3000/` at build time (existing `webpack.config.js` `urlProd`
  substitution); `urlProd` must be set to the real trusted-TLS staging/production endpoint
  for device builds.
- **Versioning / backward-compatibility constraints:** `manifest.json` (unified, desktop/web)
  is unchanged and remains the desktop/web deployment artifact. `manifest.xml` is additive.

## API / CLI Surface

- `npm run validate` — validates the unified `manifest.json` (unchanged).
- `npm run validate:xml` — new script; validates `manifest.xml` against the add-in only
  manifest schema via `office-addin-manifest validate manifest.xml`.
- No application API or CLI surface changes. No Office.js API additions (research section 2.1).

## Data & State

- No data-model, storage, caching, or persistence changes. The Message-Read workflow reads
  `Office.context.mailbox.item` (`subject`, `from.displayName`, `from.emailAddress`) and
  posts to the classifier backend over `fetch`; this is identical on iOS (research
  sections 2.1, 2.3).
- No migration or backfill.

## Constraints & Risks

- **Unified manifest not supported on mobile (hard blocker, no workaround).** The unified
  `manifest.json` cannot surface on Outlook iOS. A parallel add-in only `manifest.xml` is
  mandatory (research section 1.1).
- **Dual-manifest maintenance burden.** The repository carries two manifest files
  (`manifest.json` for desktop/web, `manifest.xml` for mobile) until Microsoft ships
  unified-manifest mobile support. Desktop-surface changes must be applied to both manifests
  to avoid drift (research sections 1.1, 6.1). This burden is accepted for this feature.
- **Localhost is not reachable from the device.** `https://localhost:3000` cannot be reached
  from a physical iOS device. Device verification requires an HTTPS endpoint reachable by the
  device, served with a TLS certificate trusted by iOS (not self-signed) (research
  sections 5.2, 6.4).
- **Direct iOS sideload is not possible.** The add-in must be sideloaded via Outlook on the
  web (or Outlook on Windows/Mac), which then syncs to the signed-in iOS device
  automatically (research sections 1.4, 5.3).
- **No remote DevTools on iOS.** Microsoft Edge DevTools cannot remotely debug add-ins
  running inside Outlook iOS. On-device verification is therefore a **manual evidence step
  that cannot be CI-gated** and must be performed and recorded by hand (research section 5.3).
- **Account prerequisites.** A Microsoft 365 business or Outlook.com account is required;
  on-premises Exchange is not supported (research section 1.4).
- **Surface differences (not functional gaps).** The unified manifest's `pinnable: true`
  task-pane action has no mobile equivalent; on mobile the pane is opened from the message
  "More options" menu. Pinch-to-zoom is enabled by default; the existing viewport meta tag is
  correct (research section 3.1).
- **No-COM, Office.js-only architecture boundary holds** (per `.claude/rules/quality-tiers.md`).

## Implementation Strategy

- **Scope of change:**
  - Add `manifest.xml` (add-in only, `VersionOverridesV1_1`) with `<DesktopFormFactor>` and
    `<MobileFormFactor>` sections referencing the same bundle endpoints.
  - Add nine mobile icon assets under `assets/` (25/32/48 px at scales 1/2/3).
  - Audit and adjust `src/taskpane/taskpane.html` (and associated CSS) for responsive,
    full-screen mobile rendering; add an optional `closeContainer()` close button.
  - Add `validate:xml` script to `package.json` and wire it into the CI validation stage.
  - Verify `webpack.config.js` emits the mobile icons to `dist` at the declared paths.
  - Provide an HTTPS staging/production endpoint with a trusted TLS certificate and set
    `urlProd` accordingly for device builds.
- **No new classes/functions in `src/`.** No Office.js API additions (research section 6.3).
- **Dependency changes:** none. `office-addin-manifest` (`^2.0.3`) and `copy-webpack-plugin`
  (`^12.0.2`) already exist as devDependencies.
- **Logging/telemetry:** none added.
- **Rollout:** `manifest.xml` is sideloaded for verification via Outlook on the web; desktop
  `manifest.json` deployment is unaffected. Fallback: if mobile verification fails, the
  desktop/web surface is unchanged and unblocked.

## Definition of Done

- [x] `manifest.xml` (add-in only, `VersionOverridesV1_1`) exists with `<DesktopFormFactor>`
      and `<MobileFormFactor>` sections referencing the same bundle endpoints.
- [x] `<MobileFormFactor>` uses a `MobileMessageReadCommandSurface` extension point with a
      `MobileButton` control and a `ShowTaskpane` action opening `taskpane.html`.
- [x] Nine mobile icon assets (25/32/48 px at scales 1/2/3) exist and are referenced from the
      `manifest.xml` `<Resources>` block.
- [x] `package.json` has a `validate:xml` script and CI runs it.
- [x] `npm run validate:xml` passes (XML manifest schema validation).
- [x] The nine mobile icon assets are emitted to `dist` at the paths declared in `manifest.xml`.
- [x] Responsive CSS audit of `taskpane.html` completed; no clipped/unreachable controls at
      375 px width; header footprint reduced for narrow viewports.
- [x] Optional `Office.context.ui.closeContainer()` close button present for mobile UX.
- [x] No regression to existing desktop/web task-pane behavior (`manifest.json` unchanged).
- [x] Toolchain pass completed (format → lint → type-check → architecture → unit → contract →
      integration) per `.claude/rules/general-code-change.md`.
- [ ] On-device manual verification performed and evidence recorded (see manual ACs below).
- [ ] Docs updated (this spec, user-story, and feature folder links).

## Acceptance Criteria

### CI-verifiable acceptance criteria

- [x] `manifest.xml` exists and `npm run validate:xml`
      (`office-addin-manifest validate manifest.xml`) passes with zero schema errors.
- [x] `manifest.xml` declares a `<MobileFormFactor>` containing a
      `MobileMessageReadCommandSurface` extension point, a `MobileButton` control, and a
      `ShowTaskpane` action referencing `taskpane.html`.
- [x] `manifest.xml` declares `Mailbox` requirement set `minVersion="1.5"`.
- [x] Nine mobile icon files (25/32/48 px at scales 1/2/3) are present in the source tree and
      are emitted to the `dist` bundle at the URLs declared in `manifest.xml`.
- [x] The CI validation stage invokes `validate:xml` and fails the build on schema errors.
- [x] No regression to existing desktop/web behavior: `manifest.json` is unchanged and
      `npm run validate` (unified manifest) still passes.
- [x] Full toolchain passes in a single pass (format, lint, type-check, architecture, unit,
      contract, integration).

### Manual on-device acceptance criteria (cannot be CI-gated)

Each item below requires manual verification on a physical iOS device because Outlook iOS
provides no remote DevTools and the runtime cannot be emulated by CI (research section 5.3).
Each names the required evidence artifact, written to
`docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/<kind>/` per the
evidence-and-timestamp conventions.

- [x] After sideloading `manifest.xml` via Outlook on the web and syncing to the iOS device,
      the TaskMaster add-in appears in the message "More options" (three-dot) menu in Outlook
      iOS read mode. **Evidence:** dated screenshot of the More-options menu showing the
      add-in entry (`evidence/screenshots/`).
- [x] The task pane renders usably on an iPhone viewport (full-screen, no clipped or
      unreachable controls; header footprint acceptable). **Evidence:** dated screenshot of
      the rendered task pane on the device (`evidence/screenshots/`).
- [x] The `Office.EventType.ItemChanged` handler fires on message navigation in iOS and
      re-renders the selected-message context (subject/from). **Evidence:** dated screenshots
      before/after navigation, or a recorded device session, showing context updating
      (`evidence/screenshots/` or `evidence/recordings/`).
- [ ] The classifier backend is reachable over HTTPS from the iOS device (trusted TLS,
      classify request succeeds and a label/confidence is shown). **Evidence:** dated
      screenshot of a successful classification on the device plus a note of the HTTPS
      endpoint used (`evidence/screenshots/` and `evidence/notes/`).

## Seeded Test Conditions

- [x] Contract/schema validation of `manifest.xml` (add-in only manifest) passes via
      `office-addin-manifest validate manifest.xml`.
- [x] Build-output verification that the nine mobile icon assets are present in `dist` at the
      paths declared in `manifest.xml`.
- [x] Regression check that `manifest.json` (unified) is unchanged and still validates.
- [x] Any new responsive-layout helper logic, if introduced, has unit coverage meeting the
      repository coverage thresholds. (Research indicates no `src/` logic changes are required;
      a CSS-only audit introduces no testable units.)
