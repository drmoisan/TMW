# Feature Audit — outlook-mobile-ios-parity (Issue #35)

- Issue: #35
- Date: 2026-05-20
- Work Mode: full-feature → AC sources: `spec.md` (`## Acceptance Criteria`,
  `## Definition of Done`, `## Seeded Test Conditions`) and `user-story.md`
  (`## Acceptance Criteria`).

> Template provenance: the MCP `feature-audit-template` asset is not exposed as a callable
> tool in this environment and no repository feature-audit template file exists. This artifact
> was authored directly with the five required major sections.

## Scope and Baseline

- Resolved base branch: `main` @ `b25e678bd82312301eaad971b1a04173915e2314`.
- Head SHA under review: `de298e6705f16131993a0f231bf5a1b2a356dc37`.
- Range: `b25e678..de298e6` (50 files, +1564 / -1; 2 commits).
- Baseline diff evidence: `artifacts/pr_context.summary.txt`, `artifacts/pr_context.appendix.txt`.
- Audit scope is the full feature branch versus base, not any plan/task subset.

This is a re-review. Since the prior review, production source changed (the `manifest.xml`
`<AppDomain>` trailing-slash production-build fix in commit `de298e6`) and on-device
acceptance evidence for Outlook iOS was added (Dev Tunnel hosting note, sideload/render note,
and four device screenshots dated 2026-05-20).

## Acceptance Criteria Inventory

CI-verifiable acceptance criteria (spec + user-story, all `[x]` in source):

1. (spec) `manifest.xml` exists and `npm run validate:xml` passes with zero schema errors.
2. (spec) `<MobileFormFactor>` declares `MobileMessageReadCommandSurface` + `MobileButton` +
   `ShowTaskpane` → `taskpane.html`.
3. (spec) `manifest.xml` declares `Mailbox` requirement set `minVersion="1.5"`.
4. (spec) Nine mobile icon files (25/32/48 px at scales 1/2/3) present and emitted to `dist`.
5. (spec) CI validation stage invokes `validate:xml` and fails on schema errors.
6. (spec) No regression: `manifest.json` unchanged and `npm run validate` still passes.
7. (spec) Full toolchain passes in a single pass.
8. (user-story) Parallel add-in only `manifest.xml` with `<DesktopFormFactor>` +
   `<MobileFormFactor>` referencing same hosted bundle; `validate:xml` passes.
9. (user-story) `<MobileFormFactor>` declares `MobileMessageReadCommandSurface`,
   `MobileButton`, `ShowTaskpane` → `taskpane.html`, `Mailbox` `minVersion="1.5"`.
10. (user-story) Nine mobile icon files present and emitted to `dist`.
11. (user-story) CI validation stage runs `validate:xml` and fails on schema errors.
12. (user-story) Renders without clipped/unreachable controls at 375 px (CSS audit / DevTools
    emulation CI-side proxy).
13. (user-story) No regression to desktop/web behavior; full toolchain passes single-pass.

Manual on-device acceptance criteria (spec + user-story):

14. (P6-T2) Add-in appears in iOS "More options" menu after sideload-and-sync.
15. (P6-T3) Task pane renders usably on an iPhone viewport.
16. (P6-T4) `Office.EventType.ItemChanged` fires on navigation and re-renders context.
17. (P6-T5) Classifier backend reachable over HTTPS from device; classification succeeds.

Definition of Done items (spec, abbreviated): manifest existence and structure, nine icons,
`validate:xml` + CI, dist emission, responsive audit, close button, no regression, toolchain
pass, on-device verification, docs.

Seeded Test Conditions (spec): contract/schema validation of `manifest.xml`; dist icon
emission; `manifest.json` unchanged and validates; new responsive-layout logic (if any) has
unit coverage.

## Acceptance Criteria Evaluation

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | manifest.xml exists; validate:xml zero errors | PASS | Live `npm run validate:xml` EXIT 0 "The manifest is valid."; `manifest.xml` at repo root |
| 2 | MobileFormFactor: surface+button+ShowTaskpane→taskpane.html | PASS | `manifest.xml` L75-98 (`MobileMessageReadCommandSurface`, `MobileButton`, `ShowTaskpane` → `Taskpane.Url`=taskpane.html) |
| 3 | Mailbox minVersion 1.5 | PASS | `manifest.xml` L25 `<Set Name="Mailbox" MinVersion="1.5"/>`; L44 `DefaultMinVersion="1.5"` |
| 4 | Nine mobile icons present + emitted to dist | PASS | nine `assets/icon-25*/icon-32-mobile*/icon-48*` PNGs in diff; `evidence/qa-gates/dist-icon-emission.md`, `icon-dimensions.md` |
| 5 | CI invokes validate:xml; fails on schema errors | PASS | `.github/actions/contract/action.yml` step "Validate add-in only manifest.xml schema" (`npm run validate:xml`); package.json script present |
| 6 | No regression: manifest.json unchanged, validate passes | PASS | Live `npm run validate` EXIT 0; `evidence/regression-testing/manifest-json-unchanged.md` (SHA-256 equal) |
| 7 | Full toolchain single-pass | PASS | Live: format/lint/typecheck/depcruise/test:coverage/validate/validate:xml all EXIT 0 |
| 8 | Parallel manifest, both form factors, same bundle | PASS | `manifest.xml` L50-98 both form factors reference `Taskpane.Url` |
| 9 | MobileFormFactor full declaration | PASS | `manifest.xml` L75-98, L44 |
| 10 | Nine icons present + emitted | PASS | Same as #4 |
| 11 | CI runs validate:xml; fails on errors | PASS | Same as #5 |
| 12 | Renders without clipping at 375 px (CI-side proxy) | PASS | `evidence/qa-gates/responsive-audit-375.md`; `src/taskpane/taskpane.css` `@media (max-width:480px)` block reviewed |
| 13 | No regression; full toolchain single-pass | PASS | Same as #6 and #7 |
| 14 | Add-in appears in iOS More-options menu | PASS | `evidence/screenshots/more-options-menu.2026-05-20T09-45.jpeg`; `evidence/notes/sideload-and-render.2026-05-20T09-45.md` (opened pane on device supersedes menu shot) |
| 15 | Renders usably on iPhone viewport | PASS | `evidence/screenshots/taskpane-render.2026-05-20T09-45.jpeg`; full-screen, controls reachable, subject/from rendered |
| 16 | ItemChanged fires; re-renders context | PASS | `evidence/screenshots/itemchanged-before…jpeg` (Subject "Test 2") and `itemchanged-after…jpeg` (Subject "Test 1"); distinct context per message |
| 17 | Classifier reachable over HTTPS; classification succeeds | N/A | User decision 2026-05-20 ("Option A"); see rationale below. Tracked as issue #37. HTTPS-hosting precondition (P6-T1) independently SATISFIED |

DoD and Seeded Test Conditions: all CI-verifiable items map to the PASS criteria above; the
on-device DoD item is satisfied except for the classifier sub-item (N/A, #17); docs are
updated (spec, user-story, ac-traceability). No DoD item is FAIL.

### P6-T5 / Criterion 17 — N/A rationale (independently verified)

P6-T5 ("classification succeeds over HTTPS") is recorded as N/A for issue #35 per the product
owner decision on 2026-05-20 ("Option A"). The reviewer independently verified the root cause
in the source:

- `src/taskpane/taskpane.html` (L32-37) defines `classify-btn`, `confirm-btn`, `reject-btn`,
  and `classification-result`.
- `src/taskpane/taskpane.ts` `getRenderDom()` (L98-104) collects only `status`,
  `selected-subject`, and `selected-from`; `Office.onReady` (L135-143) attaches handlers only
  for `ItemChanged`, the Close button, and the initial render. No handler is attached to
  `classify-btn`.
- `ClassifierClient` (`src/taskpane/classifier-client.ts`) is referenced from `taskpane.ts`
  only as a type import (`ClassifyResponse`); it is instantiated only in
  `classifier-client.test.ts`, never in product code.
- No bearer token is obtained anywhere in the codebase (no SSO / `getAccessToken`).

Therefore tapping Classify is inert on every platform, desktop and mobile alike. Issue #35 is
scoped to mobile enablement with no `src` wiring changes, so this is a pre-existing functional
gap, out of scope for #35, and tracked separately as GitHub issue #37
(wire-classify-feedback-workflow). Mobile parity is preserved because classify is equally
inert on desktop and mobile. The HTTPS-hosting precondition (P6-T1) is independently SATISFIED
via a Microsoft Dev Tunnel with a Microsoft-issued (publicly-trusted, not self-signed) TLS
certificate (`evidence/notes/hosting-endpoint.md`). Per `acceptance-criteria-tracking` rule 4,
criterion 17's checkbox is left unchecked in both source files.

## Summary

- Criteria evaluated: 17 (13 CI-verifiable, 4 manual on-device).
- PASS: 16 (all 13 CI-verifiable + the three on-device criteria P6-T2/T3/T4).
- N/A (documented, out of scope, tracked as #37): 1 (criterion 17 / P6-T5).
- FAIL / PARTIAL / UNVERIFIED: 0.

The feature meets all in-scope acceptance criteria for issue #35 with cited CI and dated
on-device evidence. The single N/A criterion is documented with verified root cause and a
tracking issue, and its checkbox remains unchecked per skill rule. Recommendation: PR-ready
for issue #35.

## Acceptance Criteria Check-off

Newly checked off by this review (changed `- [ ]` → `- [x]`):

- `spec.md` `## Acceptance Criteria` (manual on-device): "add-in appears in More options menu"
  (criterion 14), "renders usably on an iPhone viewport" (criterion 15), "ItemChanged handler
  fires … re-renders context" (criterion 16).
- `user-story.md` `## Acceptance Criteria` (manual on-device): "add-in appears in the Outlook
  iOS More options menu" (14), "renders usably on an iPhone viewport" (15),
  "ItemChanged fires … re-renders context" (16).

Left unchecked (per rule 4):

- `spec.md` and `user-story.md`: "classifier backend reachable over HTTPS … classification
  succeeds" (criterion 17 / P6-T5) — N/A by user decision; tracked as issue #37.

Already `[x]` in source before this review (CI-verifiable criteria 1-13, DoD CI items, Seeded
Test Conditions); re-verified PASS this review and left checked.

### Acceptance Criteria Status

- Source: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/spec.md` and
  `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/user-story.md`
- Total AC items (spec `## Acceptance Criteria` + user-story `## Acceptance Criteria`): 22
  (spec: 7 CI-verifiable + 4 on-device = 11; user-story: 6 CI-verifiable + 4 on-device = 11)
- Checked off (delivered/verified): 21
- Remaining (unchecked): 1
- Items remaining: spec/user-story manual AC "classifier backend reachable over HTTPS … and a
  classification succeeds" (P6-T5) — N/A by product-owner decision 2026-05-20; root cause is
  the unwired classify workflow tracked as GitHub issue #37, not a #35 failure.
