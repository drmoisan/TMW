# Acceptance Criteria Check-Off — Issue 6

Timestamp: 2026-05-11T00-20
Source: docs/features/active/2026-05-10-harden-office-addin-shell-6/issue.md

| AC | Status | Satisfying tasks | Evidence |
|---|---|---|---|
| 1. Manifest branding strings reflect TaskMaster (no Contoso/Perform an action/Show Task Pane) | PASS | P2-T1, P2-T2, P2-T3, P2-T8, P2-T9 | `evidence/qa-gates/p2-validate.2026-05-11T00-15.md`; manifest.json now contains "TaskMaster"/"Open TaskMaster" strings, zero "Contoso"/"Perform an action"/"Show Task Pane" substrings remain. |
| 2. Pinnable task pane for mailRead (`pinnable: true` on openPage action) | PASS | P2-T7 | `evidence/qa-gates/p2-validate.2026-05-11T00-15.md`; `TaskPaneRuntimeShow.pinnable = true`. |
| 3. taskpane.html refactored (remove welcome list, Run, Modify-source copy, TaskMaster IDs) | PASS | P3-T1, P3-T2, P3-T3, P3-T4 | source diff on `src/taskpane/taskpane.html`; #status, #selected-subject, #selected-from present; no run button, no welcome list. |
| 4. ItemChanged handler updates subject + sender | PASS | P4-T3, P4-T4 | `evidence/qa-gates/p6-test-coverage.2026-05-11T00-17.md`; tests: "subscribes to ItemChanged" and "re-renders DOM when handler runs against new mailbox item". |
| 5. commands.ts pruned + ActionButton removed + actionId "action" removed | PASS | P2-T10, P2-T11, P5-T1, P5-T2, P5-T3 | `evidence/qa-gates/p2-validate.2026-05-11T00-15.md`; commands.ts contains only Office.onReady noop + `export {}`. |
| 6. taskpane.css orphans removed; remaining selectors map to nodes | PASS | P3-T5 | source diff on `src/taskpane/taskpane.css`; only `.tm-header`, `.tm-main`, `.tm-main > h2`, `html/body`, `strong` selectors remain, each used in `taskpane.html`. |
| 7. No-COM (no Interop.Outlook / Tools / ComVisible / Ribbon XML) | PASS | P7-T4 | `evidence/qa-gates/final-architecture.2026-05-11T00-18.md` — depcruise 0 violations. |
| 8. `npm run build` succeeds | PASS | P7-T8 | `evidence/qa-gates/final-build.2026-05-11T00-18.md`. |
| 9. `npm run validate` succeeds | PASS | P7-T9 | `evidence/qa-gates/final-validate.2026-05-11T00-18.md`. |
| 10. All Prompt B1 PR pipeline gates pass on branch | PASS (locally) | P7-T10 | `evidence/qa-gates/final-pipeline-rollup.2026-05-11T00-19.md`. |
| 11. Unit tests cover ItemChanged handler logic + requireElement helper | PASS | P6-T2..P6-T7 | `evidence/qa-gates/p6-test-coverage.2026-05-11T00-17.md` — 8 tests, includes renderItem/renderEmpty/onItemChanged/subscription/re-render/requireElement-missing. |
| 12. Line coverage >= 85%, branch coverage >= 75% on changed files | PASS | P7-T5 | `evidence/qa-gates/final-test-coverage.2026-05-11T00-18.md` — line 98.18%, branch 90.47%. |

Summary: 12/12 ACs PASS.
