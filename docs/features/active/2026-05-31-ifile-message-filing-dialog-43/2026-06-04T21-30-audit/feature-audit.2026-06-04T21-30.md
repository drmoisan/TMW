# Feature Audit: iFile Message-Filing Dialog (#43) — Cycle 2 Reaudit (POL-1 re-evaluation)

**Audit Date:** 2026-06-04
**Exit Timestamp:** 2026-06-04T21-30
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main` (merge-base `0eb035f`)
**Head Branch:** `feature/ifile-message-filing-dialog-43` (cycle-2 working-tree scope, uncommitted)
**Work Mode:** `full-feature`
**Audit Type:** Post-remediation acceptance verification (cycle 2)
**Supersedes:** `feature-audit.2026-06-04T21-02.md` (left in place for the audit trail). Re-issued to
reflect the POL-1 re-evaluation. All acceptance-criteria evaluations are carried forward unchanged;
the only change is cycle exit criterion #6, which now reports aggregate `blocking_count == 0` because
POL-1 is downgraded from FAIL to Info.

---

## Scope and Baseline

- **Base branch:** `main` (commit `0eb035f`)
- **Head branch/commit:** `feature/ifile-message-filing-dialog-43` (5 commits ahead + cycle-2 working-tree changes)
- **Merge base:** `0eb035f28297f483a958a4511e8541a7b8d3fa32`
- **Evidence sources:**
  - Primary: re-run toolchain output (format/lint/typecheck/depcruise/test:coverage/manifest validate)
  - Cycle inputs: `remediation-inputs.2026-06-04T20-29.md` (section 7 exit criteria)
  - Feature evidence: `<feature>/evidence/**`, `coverage/lcov.info`
  - C# ground truth: `evidence/qa-gates/2026-06-04T21-23/csharp-coverage-methodology.md` (full backend suite)
  - Companion artifacts: `policy-audit.2026-06-04T21-30.md`, `code-review.2026-06-04T21-30.md`
- **Feature folder used:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- **Requirements source:** `spec.md` and `user-story.md` (resolved from `full-feature` work mode in `issue.md`)
- **Work mode resolution note:** `issue.md` line 13 persists `- Work Mode: full-feature`; AC sources are `spec.md` (AC-1..AC-24) and `user-story.md` (prose checkboxes).
- **Scope note:** Cycle-2 changes were applied to the working tree (uncommitted) and validated by re-running the toolchain rather than trusting the executor report. Audit scope is the full branch diff vs `main`, not the plan subset.

---

## Acceptance Criteria Inventory

**Authoritative AC source files for this run:**
- `spec.md` — primary checkbox source (AC-1..AC-24)
- `user-story.md` — secondary checkbox source (prose)

### Acceptance criteria (spec.md, abbreviated; wording preserved in source)

1. AC-1 iFile first control on the message-read surface (desktop + mobile).
2. AC-2 Desktop: Office Dialog with search textbox + results list.
3. AC-3 Mobile: same search UI inline in the full-screen task pane.
4. AC-4..AC-10 Empty-state, prepend-on-type, leaf-folder matching, wildcards, load-once, input contract, single filing command.
5. AC-11 Per-platform message REST id resolution.
6. AC-12 Move opened message to selected Outlook folder via Graph.
7. AC-13 Save non-inline attachments to the mirrored OneDrive folder.
8. AC-14..AC-18 Path mapping, create-if-missing, no-attachment case, attachments-first ordering, partial-failure safety.
9. AC-19 Manifest + AAD scope changes present.
10. AC-20 Verified on desktop + mobile form factors.
11. AC-21 First-use Archive-root prompt.
12. AC-22, AC-23 Mapping persisted and reused without re-prompting.
13. AC-24 Per-host Archive-root picker.

### From user-story.md (prose checkboxes)
- First-command, desktop dialog, mobile inline, empty-state, prepend-on-type, leaf matching,
  wildcards, fast load, input contract, OneDrive mirror, no-attachment case, partial-failure
  safety, first-use picker, remembered Archive root, per-host picker, clear failure reporting,
  desktop+mobile verification.

---

## Acceptance Criteria Evaluation

| # | Criterion | Status | Evidence | Verification command(s) | Notes |
|---|-----------|--------|----------|--------------------------|-------|
| AC-1 | iFile first control on read surface | PASS | manifest-declared (prior cycle) | `npm run validate` | unchanged this cycle |
| AC-2 | Desktop Office Dialog UI | PARTIAL | UI implemented; closure needs on-device/host verification | n/a | gated on HI-2 |
| AC-3 | Mobile inline UI | PARTIAL | `inline-host.ts` + host detection implemented | n/a | gated on HI-2 |
| AC-4..AC-10 | search/compose/select behavior | PASS | existing pure-module tests pass in the 132-test suite | `npm run test:coverage` | unchanged this cycle |
| AC-11 | per-platform REST id resolution | PARTIAL | `message-id-resolver.ts` present | n/a | manual device verification (HI-2) |
| AC-12 | move via Graph | PARTIAL | `GraphMessageMover` present | n/a | requires HI-1 consent + HI-2 |
| AC-13 | mirrored OneDrive attachment save | PARTIAL | `GraphOneDriveFolderWriter` present | n/a | requires HI-1 consent + HI-2 |
| AC-14..AC-18 | mapping/ordering/partial-failure | PASS | existing tests pass | `npm run test:coverage` | unchanged this cycle |
| AC-19 | manifest + AAD scope changes present | PARTIAL | `webApplicationInfo`/`<WebApplicationInfo>` + Dev Tunnel domains added this cycle; both manifests validate | `npm run validate` / `validate:xml` (EXIT 0) | spec lists AC-19 in the manual-verification set; closure gated on HI-2 |
| AC-20 | verified on desktop + mobile | PARTIAL | not device-verified this cycle | n/a | gated on HI-2 re-verification |
| AC-21 | first-use Archive-root prompt | PARTIAL | `archive-root-picker.ts` present | n/a | manual host verification |
| AC-22, AC-23 | mapping persisted/reused | PASS | existing tests pass | `npm run test:coverage` | unchanged this cycle |
| AC-24 | per-host Archive-root picker | PARTIAL | per-host picker implemented | n/a | manual host verification |

### Cycle exit criteria (remediation-inputs.2026-06-04T20-29 section 7)

| # | Exit criterion | Status | Evidence |
|---|---|---|---|
| 1 | NAA token when supported + runtime guard + documented fallback; `getAccessToken` no longer sole/primary | MET | `naa-token-acquirer.ts` silent→popup + `isSetSupported` guard + deterministic unsupported rejection; grep confirms `getAccessToken` removed from `src/`. |
| 2 | Manifests declare SSO app info + Dev Tunnel domains | MET | `manifest.json` + `manifest.xml` diffs; both validate EXIT 0. |
| 3 | Stage-specific configuration/sign-in/connection messages, tested | MET | three message constants routed and asserted (incl. distinctness) in bootstrap + host-shell tests. |
| 4 | Full toolchain green; changed-line coverage meets thresholds; token/bootstrap seam in coverage | MET (TS) | format/lint/typecheck clean; depcruise 0 errors; 132/132; repo-wide 96.48%/95.47%; seams in coverage. C#: full backend suite 145 tests pass; no cycle-2 C# changed lines; pre-existing Program.cs edit 87% covered, no regression. |
| 5 | HI-3 Entra runbook exists, declared exception; HI-1/HI-2 updated | MET | `runbooks/entra-app-sso-config.runbook.md` present; on-device runbook updated. |
| 6 | Three reaudit artifacts report `blocking_count == 0` | MET | aggregate blocking_count = 0 across the three T21-30 artifacts. POL-1 (previously the sole FAIL) is re-evaluated against ground-truth evidence (T21-23) and downgraded to Info: cycle 2 changed no C# production lines; the "repo-wide 21.99%" figure was a single-project coverage artifact, not a merged repo-wide measure; the one pre-existing C# edit's changed lines are 87% covered with no regression. |
| 7 | Feature DONE remains gated on human HI-3 + HI-1 + HI-2 | CONFIRMED | Entra config, consent, on-device re-verification correctly human-gated and not committed. |

---

## Summary

**Overall Feature Readiness:** CYCLE-2 EXIT READY (feature DONE remains human-gated)

**Criteria summary (spec.md AC-1..AC-24):**
- **PASS:** 15 (AC-1, AC-4..AC-10, AC-14..AC-18, AC-22, AC-23)
- **PARTIAL:** 9 (AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24)
- **UNVERIFIED:** 0
- **FAIL:** 0

**Top gaps preventing full feature PASS:**
1. Nine PARTIAL acceptance criteria are gated on human-executed HI-1 (admin consent) + HI-3 (Entra config) + HI-2 (mobile build + on-device re-verification). These gate feature DONE, not cycle exit, and are declared exceptions, not code defects.

**Cycle-2 blocking items:** None. The T21-02 blocking item (POL-1, repo-wide C# coverage) is
re-evaluated against ground-truth evidence and is not a cycle-2 defect — it was a single-project
coverage-artifact misread plus mis-attribution of pre-existing out-of-cycle working-tree C# edits.
A separate, pre-existing, out-of-iFile-scope follow-up is recorded for the CI coverage-pick
methodology (touches `.github/actions/**`; would trigger `modified-workflow-needs-green-run`).

**Regression posture:** PASS. The unchanged host-neutral search modules and the C# filing workflow
retain their tests; the full 132-test TS suite passes; the full 145-test backend suite passes
(ground-truth run); depcruise reports 0 errors; the bootstrap seam refactor preserves the cycle-1
resilient-wiring behavior.

**Recommended follow-up verification steps:**
1. Execute HI-3 (Entra config) + HI-1 (consent) + HI-2 (mobile build + on-device re-verification) to close AC-2/3/11/12/13/19/20/21/24.
2. (Separate work item) Fix the CI canonical C# coverage step to merge per-project files with ReportGenerator so the artifact is a true repo-wide figure.

---

## Acceptance Criteria Check-off

Per the acceptance-criteria tracking rules, only PASS criteria represented as markdown checkboxes
may be checked off. The 15 PASS criteria above (AC-1, AC-4..AC-10, AC-14..AC-18, AC-22, AC-23) were
already checked `[x]` in `spec.md` from prior cycles; this audit confirms they remain satisfied and
makes no change. The 9 PARTIAL criteria remain unchecked, consistent with their human-gated status.
No source-file checkbox change was made by this audit.

### AC Status Summary

- Source: `spec.md`, `user-story.md`
- Total AC items (spec.md): 24
- Checked off (delivered): 15
- Remaining (unchecked): 9
- Items remaining: AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24 (all gated on human HI-1/HI-2/HI-3)

| Source File | Total AC | Checked (PASS) | Unchecked | Notes |
|-------------|----------|----------------|-----------|-------|
| `spec.md` | 24 | 15 | 9 | Checkbox-backed; unchecked items are human-gated |
| `user-story.md` | 18 | ~9 | ~9 | Checkbox-backed; "clear failure reporting" reinforced by cycle-2 stage-specific messages |

### Verdict Counts
- FAIL findings (new to this artifact): **0**
- Blocking-PARTIAL findings: **0** (the 9 PARTIAL ACs are declared human exceptions, not blocking)
- feature-audit blocking_count = **0**
