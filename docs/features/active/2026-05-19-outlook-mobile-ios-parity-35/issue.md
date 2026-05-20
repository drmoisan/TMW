# outlook-mobile-ios-parity (Issue #35)

- Date captured: 2026-05-19
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/outlook-mobile-ios-parity/ (Issue #35)

- Issue: #35
- Issue URL: https://github.com/drmoisan/TMW/issues/35
- Last Updated: 2026-05-20
- Work Mode: full-feature

## Problem / Why

The TaskMaster for Outlook add-in (`manifest.json`, manifest version 1.17, Mailbox
requirement set 1.5) currently targets the desktop/web task-pane form factor only. It
declares no `mobileFormFactor`, so the add-in is not surfaced in Outlook for iOS. Users
who triage mail on their iPhones cannot reach the classify/triage/ToDo workflows that
desktop users rely on, forcing them to defer triage to a desktop session.

## Proposed Behavior

Add Outlook Mobile (iOS) support to the add-in with full desktop feature parity. All
desktop functionality — selected-message context capture and the classify/triage/ToDo
workflows — must be reachable and usable in Outlook for iOS. At a high level this requires:

- Manifest changes: declare a `mobileFormFactor` with mobile-capable runtime(s) and the
  appropriate Mailbox requirement set / capability version for the commands used on mobile.
- Responsive task-pane UI so the existing TaskMaster surface is usable on small (phone)
  screens without losing any command.
- Office.js capability and version guards so functionality degrades safely where a mobile
  host lacks a given API, while still meeting the full-parity goal.
- Manifest validation/side-load verification for the mobile form factor.

## Acceptance Criteria (early draft)

- [ ] `manifest.json` declares a valid `mobileFormFactor` and passes Office add-in
      manifest validation.
- [ ] All desktop commands/workflows are present and operable in the iOS mobile surface.
- [ ] Task-pane UI renders usably on phone-class viewport widths (no clipped/unreachable
      controls).
- [ ] Office.js capability/version requirements for mobile are explicitly declared and
      guarded in code.
- [ ] No regression to existing desktop/web task-pane behavior.

## Constraints & Risks

- No-COM, Office.js-only architecture boundary holds (per `quality-tiers.md`).
- Outlook Mobile (iOS) supports a narrower Office.js API surface than desktop/web; some
  desktop APIs may be unavailable, which could constrain how "full parity" is achieved.
- Minimum Outlook/Mailbox requirement set for mobile commands may exceed the current 1.5
  pin; raising it could affect desktop eligibility and must be verified.
- Mobile manifest changes affect store/side-load validation; needs explicit verification.

## Test Conditions to Consider

- [ ] Unit coverage for any new responsive-layout / capability-guard logic.
- [ ] Contract/schema validation of the updated `manifest.json` against the manifest schema.
- [ ] Integration/host-boundary checks for Office.js capability detection on a mobile-like host.
- [ ] Manifest side-load/validation verification for the mobile form factor.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/outlook-mobile-ios-parity/` folder from the template