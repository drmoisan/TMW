# Acceptance-Criteria Traceability — Issue #35

- Timestamp: 2026-05-19T22-50
- Task: [P7-T9]
- Work Mode: full-feature (AC sources: `spec.md` and `user-story.md`)

## Reconciliation table

| Acceptance criterion | Satisfying task(s) | Status | Evidence |
|---|---|---|---|
| spec CI-AC: manifest.xml exists and `npm run validate:xml` passes, zero schema errors | P2-T1..T5, P3-T2, P7-T6 | SATISFIED | `evidence/qa-gates/validate-xml.md`, `evidence/qa-gates/final-manifest-validation.md`; `manifest.xml` at repo root |
| spec CI-AC: MobileFormFactor uses MobileMessageReadCommandSurface, MobileButton, ShowTaskpane -> taskpane.html | P2-T4 | SATISFIED | `manifest.xml` `<MobileFormFactor>`; validator pass `evidence/qa-gates/validate-xml.md` |
| spec CI-AC: manifest.xml declares Mailbox minVersion=1.5 | P2-T1 | SATISFIED | `manifest.xml` `<Requirements><Set Name="Mailbox" MinVersion="1.5"/>` and VersionOverrides `DefaultMinVersion="1.5"`; validator pass |
| spec CI-AC: Nine mobile icon files present and emitted to dist at declared URLs | P1-T1, P1-T2, P4-T3 | SATISFIED | `evidence/qa-gates/icon-dimensions.md`, `evidence/qa-gates/dist-icon-emission.md` |
| spec CI-AC: CI validation stage invokes validate:xml and fails on schema errors | P3-T1, P3-T3 | SATISFIED | `package.json` `validate:xml` script; `.github/actions/contract/action.yml` step "Validate add-in only manifest.xml schema" (non-zero exit fails the stage) |
| spec CI-AC: No regression — manifest.json unchanged and `npm run validate` still passes | P3-T4, P7-T6, P7-T7 | SATISFIED | `evidence/regression-testing/validate-json-post.md`, `evidence/qa-gates/final-manifest-validation.md`, `evidence/regression-testing/manifest-json-unchanged.md` (SHA-256 equal) |
| spec CI-AC: Full toolchain passes in a single pass | P7-T1..T6 | SATISFIED | `evidence/qa-gates/final-format.md`, `final-lint.md`, `final-typecheck.md`, `final-architecture.md`, `final-test-coverage.md`, `final-manifest-validation.md` |
| user-story CI-AC: DesktopFormFactor + MobileFormFactor referencing same hosted bundle | P2-T2, P2-T3, P2-T4 | SATISFIED | `manifest.xml` both form factors point at `Taskpane.Url` (taskpane.html); validator pass |
| user-story CI-AC: renders without clipped/unreachable controls at 375 px (CSS audit / DevTools emulation proxy) | P5-T1, P5-T2 | SATISFIED (CI-side proxy) | `evidence/qa-gates/responsive-audit-375.md`; authoritative on-device render is manual P6-T3 |
| spec DoD: optional closeContainer() close button present | P5-T3 | SATISFIED | `src/taskpane/taskpane.html` `#close-btn`; `src/taskpane/taskpane.ts` `closeTaskpane()`; tests in `taskpane.test.ts` |
| spec/user-story manual AC: appears in iOS More options menu | P6-T2 | SATISFIED (device, 2026-05-20) | `evidence/screenshots/more-options-menu.2026-05-20T09-45.jpeg`, `evidence/notes/sideload-and-render.2026-05-20T09-45.md`. Opened pane on device supersedes the menu shot (pane cannot open unless the add-in appeared and was launchable). |
| spec/user-story manual AC: renders usably on iPhone viewport | P6-T3 | SATISFIED (device, 2026-05-20) | `evidence/screenshots/taskpane-render.2026-05-20T09-45.jpeg`; full-screen, all controls reachable, no clipping; subject/from rendered. |
| spec/user-story manual AC: ItemChanged fires on navigation, re-renders context | P6-T4 | SATISFIED (device, 2026-05-20) | `evidence/screenshots/itemchanged-before.2026-05-20T09-45.jpeg` (Subject "Test 2") and `itemchanged-after.2026-05-20T09-45.jpeg` (Subject "Test 1"); context re-renders on message change. |
| spec/user-story manual AC: classifier reachable over HTTPS, classification succeeds | P6-T1 (hosting), P6-T5 | P6-T1 SATISFIED; P6-T5 N/A (user decision 2026-05-20, "Option A") | Hosting verified: `evidence/notes/hosting-endpoint.md` (Dev Tunnel, Microsoft-issued TLS). P6-T5 N/A: the classify/feedback workflow is not wired into the product on ANY platform (no `classify-btn` handler; `ClassifierClient` never instantiated in product code; no bearer token). Mobile parity holds; the gap is tracked as GitHub issue #37. |

## Summary

- CI-verifiable acceptance criteria: all SATISFIED with cited evidence.
- Manual on-device acceptance criteria: P6-T1 (hosting), P6-T2 (launchable), P6-T3 (render),
  and P6-T4 (ItemChanged) are SATISFIED with dated device evidence captured 2026-05-20 over a
  trusted-TLS Dev Tunnel endpoint.
- P6-T5 (classification succeeds over HTTPS) is **N/A** by user decision (2026-05-20, "Option A").
  Root cause: the classify/confirm/reject workflow is not wired into the product on any platform
  (button has no handler; `ClassifierClient` is instantiated only in tests; no bearer-token source).
  Issue #35 is scoped to mobile enablement with no `src` logic changes, so this pre-existing
  functional gap is out of scope and tracked separately as GitHub issue #37
  (wire-classify-feedback-workflow). Mobile parity is preserved (classify is equally inert on
  desktop and mobile).

All acceptance criteria are now resolved: SATISFIED with evidence, or N/A with documented
rationale and a tracking issue. No AC remains failing or unverified-without-justification.
