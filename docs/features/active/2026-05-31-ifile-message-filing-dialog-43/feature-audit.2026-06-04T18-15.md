# Feature Audit: iFile Message-Filing Dialog — Remediation Cycle 1 (#43)

**Audit Date:** 2026-06-04
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main`
**Head Branch:** `feature/ifile-message-filing-dialog-43` (working tree, cycle 1 changes)
**Work Mode:** `full-feature`
**Audit Type:** Post-remediation acceptance verification

---

## Scope and Baseline

- **Base branch:** `main`
- **Head branch/commit:** `feature/ifile-message-filing-dialog-43` (working tree at exit 2026-06-04T18-15)
- **Merge base:** N/A (working-tree validation against `main`)
- **Evidence sources:**
  - Primary: `remediation-inputs.2026-06-04T17-50.md` (section 6 cycle exit criteria), `remediation-plan.2026-06-04T17-50.md` (24/24 tasks checked)
  - Secondary baseline diff: `git diff` of changed production/test files (cycle 1)
  - Feature evidence: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/` and `.../evidence/regression-testing/`
  - Additional evidence: reviewer-run `npm run test:coverage` (EXIT 0, 117/117)
- **Feature folder used:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- **Requirements source:** `spec.md` and `user-story.md` (full-feature work mode)
- **Work mode resolution note:** `issue.md` records `- Work Mode: full-feature`; AC sources are `spec.md` (AC-1..AC-24) and the mirrored `user-story.md` list.
- **Scope note:** This is a working-tree validation of remediation cycle 1. Cycle 1 changed only TypeScript production/test files, `webpack.config.js` (build config), and Markdown docs. The host-neutral search modules and the C# backend were unchanged and reviewed for regression only.

---

## Acceptance Criteria Inventory

**Authoritative AC source files for this run:**
- `spec.md` — primary (authoritative for CI-verifiable vs. manual)
- `user-story.md` — secondary (mirrors the spec ACs from the user perspective)

### Acceptance criteria (from spec.md)

The defect remediated this cycle most directly affects AC-4, AC-5, and AC-8, whose CI-verifiable behavior was restored on the real runtime/wiring path (the host-bootstrap seam was previously uncovered and could fail silently on device). The full inventory (AC-1..AC-24) is unchanged from `spec.md` and is not re-transcribed here; the evaluation table below reports the ACs material to this cycle and the device-gated ACs that remain pending.

---

## Acceptance Criteria Evaluation

| # | Criterion | Status | Evidence | Verification command(s) | Notes |
|---|-----------|--------|----------|--------------------------|-------|
| AC-4 | Empty textbox yields no search-sourced results | PASS | `inline-host.test.ts` / `ifile-controller.ts` empty-input path; seam now covered | `npm run test:coverage` | CI-verifiable; restored on the runtime path this cycle |
| AC-5 | Typing prepends matching leaf results, live; clearing removes them | PASS | `inline-host.test.ts` positive path; `ifile.bootstrap.test.ts` results render on input | `npm run test:coverage` | CI-verifiable; the silent-inert-box defect that broke this on device is fixed |
| AC-8 | Folder tree loaded once per open; no per-keystroke Graph call | PASS | `ifile-controller.ts` `open()` uses `??=`; `bootstrap` test asserts `loadLeaves` called once | `npm run test:coverage` | CI-verifiable; retry-safe (no partial cache on failed load) |
| AC-2 | Activating iFile on desktop opens an Office Dialog with search box + list | PARTIAL | CI dialog-open path covered; visual confirmation requires desktop host | `npm run test:coverage` | Device/host-gated under HI-2; pending |
| AC-3 | Activating iFile on mobile opens the same UI inline (no dialog) | PARTIAL | host-detection branch unit-tested; shared bundle | `npm run test:coverage` | Device-gated under HI-2; pending |
| AC-20 | Behavior verified on both desktop and mobile form factors | UNVERIFIED | No CI mechanism; manual runbook only | n/a | Device-gated under HI-2; pending |
| AC-24 | Archive-root picker presented per host (desktop dialog / mobile inline) | PARTIAL | host-detection branch + shared-flow tested | `npm run test:coverage` | Device-gated under HI-2; pending |

Other manual-gated ACs (AC-11, AC-12, AC-13, AC-19, AC-21) remain PARTIAL/UNVERIFIED pending on-device/host confirmation per `spec.md`; they are unchanged by this cycle and are not re-evaluated here. The CI-verifiable ACs already delivered in prior cycles (AC-1, AC-6, AC-7, AC-9, AC-10, AC-14..AC-18, AC-22, AC-23) remain PASS and were checked for regression (suite green).

---

## Cycle Exit Criteria (remediation-inputs section 6)

| # | Exit criterion | Status | Evidence |
|---|---|---|---|
| 1 | On-device folder-load path reaches a reachable backend (resolved + documented) | MET | `assertReachableApiBaseUrl` + `__IS_MOBILE_BUILD__` (api-base-url.ts, webpack.config.js, ifile.ts); runbook Section 0 documents the `API_BASE_URL` + `IFILE_MOBILE_BUILD` build step |
| 2 | One-time load failure no longer disables the keystroke handler; surfaced visibly (deterministic, testable) | MET | `mountInline` binds the handler before `open()`; failure renders a distinct `data-ifile-error`/`role="alert"` row; covered by `inline-host.test.ts` and `ifile.bootstrap.test.ts` |
| 3 | New tests cover the host-bootstrap/wiring seam and load-failure path; seam no longer coverage-excluded; changed-line coverage meets thresholds | MET | `ifile.bootstrap.test.ts`, `ifile.host-shell.test.ts` added; `ifile.ts` 0% -> 85.48% lines / 94.11% branches; no production file excluded (vitest.config.ts verified) |
| 4 | Full toolchain green; the three reaudit artifacts report `blocking_count == 0` | MET | Reviewer reproduced format/lint/typecheck/depcruise/test:coverage all green (117/117); this audit set reports 0 FAIL + 0 blocking-PARTIAL |
| 5 | HI-2 restated as remaining declared exception with runbook updated for the backend-URL build step; gates feature DONE not cycle exit | MET | Runbook "Declared Exception (HI-2)" + Section 0 restate the exception and the "gates feature DONE but not cycle exit" wording |

All five cycle exit criteria are MET.

---

## Summary

**Overall Feature Readiness:** PASS (for cycle exit). Feature DONE is not yet reached because device-gated ACs remain pending the HI-2 on-device confirmation, which gates feature DONE but not cycle exit.

**Criteria summary (cycle-material ACs evaluated above):**
- **PASS:** 3 (AC-4, AC-5, AC-8)
- **PARTIAL:** 3 (AC-2, AC-3, AC-24)
- **UNVERIFIED:** 1 (AC-20)
- **FAIL:** 0

**Regression posture:** No regression. The confirmed-correct host-neutral search modules and the C# backend were not modified; the full suite is green (117/117, +17 new tests over a 100-test baseline), repo-wide line coverage rose to 96.25%, and `inline-host.ts` reached 100% line/branch. The positive search path is explicitly preserved by tests in both `inline-host.test.ts` and `ifile.bootstrap.test.ts`.

**Top gaps preventing feature DONE (not cycle exit):**

1. Device-gated ACs (AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24) require the HI-2 on-device confirmation recorded in `evidence/other/manual-verification.md`.
2. None blocking cycle exit.

**Recommended follow-up verification steps:**

1. Execute the HI-2 runbook (`runbooks/outlook-on-device-verification.runbook.md`) including the Section 0 build-with-reachable-URL step, and record results in `evidence/other/manual-verification.md`.
2. (Non-blocking) Bind the real `update` handler on the `bootstrap` token-failure branch for behavioral parity (carried from code-review).

---

## Acceptance Criteria Check-off

Per the acceptance-criteria tracking rules: PARTIAL/UNVERIFIED criteria remain unchecked. The CI-verifiable ACs material to this cycle (AC-4, AC-5, AC-8) were already checked off in prior cycles and remain checked; this cycle restored their runtime behavior rather than delivering a previously-unmet criterion to a newly fully-verified state. No new checkbox is flipped by this audit.

### AC Status Summary

- Source: `spec.md` and `user-story.md`
- Total AC items (spec.md): 24
- Checked off (delivered, per spec.md current state): 15 (AC-1, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-14, AC-15, AC-16, AC-17, AC-18, AC-22, AC-23)
- Remaining (unchecked, device/host-gated under HI-2): 9 (AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24)
- Items remaining: device/host on-device confirmation for the listed ACs (gated by HI-2)

| Source File | Total AC | Checked (PASS) | Unchecked | Notes |
|-------------|----------|----------------|-----------|-------|
| `spec.md` | 24 | 15 | 9 | Checkbox-backed; unchecked items are device/host-gated under HI-2 |
| `user-story.md` | 17 | 11 | 6 | Checkbox-backed mirror of spec ACs from the user perspective |

No source-file checkbox change was made by this cycle's audit: the cycle restored already-delivered CI-verifiable runtime behavior, and the remaining unchecked ACs are device-gated under the HI-2 declared exception.

**FAIL findings: 0. Blocking-PARTIAL findings: 0.**
