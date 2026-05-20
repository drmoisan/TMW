# `outlook-mobile-ios-parity` — User Story

- Issue: #35
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-19
- Work Mode: full-feature

## Story Statement

- As an Outlook user who triages mail on an iPhone, I want the TaskMaster add-in to appear
  and run in Outlook for iOS, so that I can classify and triage a selected message from my
  phone instead of deferring triage to a desktop session.
- As the add-in maintainer, I want a validated parallel add-in only `manifest.xml` that
  targets both desktop and mobile form factors from the same hosted bundle, so that iOS
  support ships without changing the desktop/web `manifest.json` or the Office.js code.

## Problem / Why

The TaskMaster for Outlook add-in ships a unified app manifest for Microsoft 365
(`manifest.json`, `manifestVersion` 1.17, Mailbox requirement set 1.5) that targets the
desktop/web task-pane form factor only. The add-in is not surfaced in Outlook for iOS, so
users who triage mail on iPhones cannot reach the classify/triage/feedback workflow.

The unified manifest cannot solve this. Per the authoritative research
(`artifacts/research/2026-05-19-outlook-ios-mobile-support-research.md`, section 1.1),
Microsoft documents the unified manifest as not supported on Outlook mobile devices. The
supported path is a separate, parallel add-in only manifest (`manifest.xml`,
`VersionOverridesV1_1`) declaring a `<MobileFormFactor>` and referencing the same hosted
bundle. Research confirms all four production Office.js APIs the add-in uses are within
Mailbox requirement set 1.5 (the iOS ceiling), so full Message-Read parity is achievable on
iOS with no `src/` code changes (research sections 2.1–2.2, 3.1).

## Personas & Scenarios

- **Persona: Mobile triager (primary).**
  - Who: an Outlook user with a Microsoft 365 business or Outlook.com account who reads and
    triages mail on an iPhone.
  - What they care about: clearing the inbox on the go; not having to re-do triage on a
    desktop later.
  - Constraints: small (full-screen) task-pane surface; the add-in is reached from the
    message "More options" menu, not a pinned button; the device must reach the classifier
    backend over HTTPS.
  - Goals and frustrations: wants the same classify/confirm/reject workflow available on
    desktop; is currently blocked because the add-in does not appear on iOS at all.
  - Context and motivation: triages mail in short sessions between other tasks.

- **Persona: Add-in maintainer (secondary).**
  - Who: the engineer responsible for the manifest, build, and CI.
  - What they care about: shipping iOS support without breaking the desktop/web surface and
    without taking on uncontrolled maintenance cost.
  - Constraints: must carry two manifest files (`manifest.json` for desktop/web,
    `manifest.xml` for mobile) until Microsoft ships unified-manifest mobile support; must
    keep desktop configuration consistent across both manifests.

- **Scenario: classify a message on iPhone.**
  - Who is acting: the mobile triager.
  - Trigger: a new message arrives and is opened in Outlook iOS read mode.
  - Steps: the user opens the message, taps the "More options" (three-dot) menu, selects the
    TaskMaster add-in, the full-screen task pane opens showing the selected message subject
    and sender, the user taps Classify, reviews the returned label and confidence, and taps
    Confirm or Reject; the user closes the pane (via the close button) and returns to the
    message.
  - Obstacles/decisions: the task pane must render usably on a narrow (375 px) viewport; the
    classifier must be reachable over HTTPS from the device with a trusted TLS certificate.
  - Expected outcome: the same classify/triage/feedback result the user would get on desktop.

- **Scenario: maintainer validates and sideloads.**
  - Who is acting: the add-in maintainer.
  - Trigger: preparing iOS support for verification.
  - Steps: authors `manifest.xml` with desktop and mobile form factors, runs
    `npm run validate:xml`, builds the bundle (confirming mobile icons reach `dist`), hosts
    the bundle on an HTTPS endpoint with a trusted certificate, sideloads `manifest.xml` via
    Outlook on the web, and signs into the same account in Outlook iOS so the add-in syncs to
    the device.
  - Obstacles/decisions: localhost is not reachable from the device; direct iOS sideload is
    not possible; no remote DevTools means on-device checks are manual.
  - Expected outcome: the add-in appears in the Outlook iOS More-options menu and runs the
    Message-Read workflow.

## Acceptance Criteria

### CI-verifiable

- [x] A parallel add-in only `manifest.xml` (`VersionOverridesV1_1`) exists with
      `<DesktopFormFactor>` and `<MobileFormFactor>` sections referencing the same hosted
      bundle endpoints, and `npm run validate:xml` passes with zero schema errors.
- [x] `<MobileFormFactor>` declares a `MobileMessageReadCommandSurface` extension point, a
      `MobileButton` control, a `ShowTaskpane` action opening `taskpane.html`, and `Mailbox`
      requirement set `minVersion="1.5"`.
- [x] Nine mobile icon files (25/32/48 px at scales 1/2/3) are present and emitted to `dist`
      at the URLs declared in `manifest.xml`.
- [x] The CI validation stage runs `validate:xml` and fails on schema errors.
- [x] The task pane renders without clipped or unreachable controls at a 375 px viewport
      width (verified via build/CSS audit and DevTools mobile emulation as a CI-side proxy).
- [x] No regression to desktop/web behavior: `manifest.json` is unchanged and the full
      toolchain (format, lint, type-check, architecture, unit, contract, integration) passes
      in a single pass.

### Manual on-device (cannot be CI-gated; evidence required)

Outlook iOS provides no remote DevTools and cannot be emulated by CI; each item is verified
by hand on a physical device, with evidence stored under
`docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/<kind>/`.

- [x] The add-in appears in the Outlook iOS message "More options" menu after sideload-and-
      sync. **Evidence:** dated screenshot (`evidence/screenshots/`).
- [x] The task pane renders usably on an iPhone viewport. **Evidence:** dated device
      screenshot (`evidence/screenshots/`).
- [x] `Office.EventType.ItemChanged` fires on message navigation and re-renders context.
      **Evidence:** dated before/after screenshots or a recorded session
      (`evidence/screenshots/` or `evidence/recordings/`).
- [ ] The classifier backend is reachable over HTTPS from the device and a classification
      succeeds. **Evidence:** dated screenshot of a successful classification plus the HTTPS
      endpoint used (`evidence/screenshots/` and `evidence/notes/`).

## Non-Goals

- Outlook for Android. This feature targets Outlook Mobile on iOS specifically.
- Adding a `mobileFormFactor` to the unified `manifest.json`. The unified manifest is not
  supported on mobile and this approach is explicitly rejected (research sections 1.1, 3.3).
- Compose-mode mobile support. Outlook mobile does not support compose-mode task-pane
  add-ins; the feature is Message-Read only (research section 1.3).
- Any Office.js or `src/` code changes. The existing bundle serves both surfaces unchanged
  (research section 6.3).
- Removing or replacing `manifest.json`. The unified manifest remains the desktop/web
  deployment artifact until Microsoft ships unified-manifest mobile support.
- Migrating off the dual-manifest arrangement; that is a future change gated on Microsoft
  shipping mobile support for the unified manifest.
