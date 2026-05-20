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
| spec/user-story manual AC: appears in iOS More options menu | P6-T2 | OUTSTANDING (manual) | Requires physical iOS device, HTTPS-hosted bundle, sideload-and-sync; cannot be CI-gated (research §5.3). No fabricated evidence. |
| spec/user-story manual AC: renders usably on iPhone viewport | P6-T3 | OUTSTANDING (manual) | Requires physical iOS device. CI-side proxy provided by P5-T2; authoritative device render pending. |
| spec/user-story manual AC: ItemChanged fires on navigation, re-renders context | P6-T4 | OUTSTANDING (manual) | Requires physical iOS device with two messages; no remote DevTools (research §5.3). |
| spec/user-story manual AC: classifier reachable over HTTPS, classification succeeds | P6-T1, P6-T5 | OUTSTANDING (manual) | Requires trusted-TLS HTTPS endpoint reachable by device + on-device classification. |

## Summary

- CI-verifiable acceptance criteria: all SATISFIED with cited evidence.
- Manual on-device acceptance criteria (Phase 6, P6-T1..T5): OUTSTANDING. These require a
  physical iOS device, an HTTPS endpoint with a trusted (non-self-signed) TLS certificate,
  sideload-and-sync via Outlook on the web, and manual on-device evidence capture. They
  cannot be executed or CI-gated in this environment (research §5.3) and were intentionally
  not executed; no evidence was fabricated.

The CI-verifiable subset is reported PASS. Overall feature completion requires the Phase 6
manual on-device evidence, which remains outstanding.
