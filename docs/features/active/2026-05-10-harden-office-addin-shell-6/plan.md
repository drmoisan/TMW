# Plan — Harden The Office Add-in Shell (Issue 6)

**Feature folder:** `docs/features/active/2026-05-10-harden-office-addin-shell-6`
**Canonical issue:** 6
**Work Mode:** full-feature
**Source of truth for ACs:** `docs/features/active/2026-05-10-harden-office-addin-shell-6/issue.md` (12 acceptance criteria)
**Authoritative research:** `artifacts/research/2026-05-10-prompt-b2-office-addin-shell-hardening.md`

## Evidence Location Invariant

All evidence artifacts produced by this plan MUST be written under:

```
docs/features/active/2026-05-10-harden-office-addin-shell-6/evidence/<kind>/
```

Canonical sub-paths used:
- `evidence/baseline/`
- `evidence/qa-gates/`
- `evidence/regression-testing/`
- `evidence/other/`
- `evidence/issue-updates/`

Writing evidence under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, or any other non-canonical path is a policy violation. Any caller instruction to use a non-canonical path MUST be rejected and recorded as `EVIDENCE_LOCATION_OVERRIDE_REJECTED`.

Timestamp format for all evidence files: `yyyy-MM-ddTHH-mm` (ISO-8601).

---

### Phase 0 — Baseline Capture and Policy Reading

- [x] [P0-T1] Read `.claude/rules/general-code-change.md` and record it in the Phase 0 evidence index at `docs/features/active/2026-05-10-harden-office-addin-shell-6/evidence/baseline/phase0-instructions-read.md` (include `Timestamp:`, `Policy Order:`, and the explicit list of files read).
- [x] [P0-T2] Read `.claude/rules/general-unit-test.md` and append it to `evidence/baseline/phase0-instructions-read.md`.
- [x] [P0-T3] Read `.claude/rules/typescript.md` and append it to `evidence/baseline/phase0-instructions-read.md`.
- [x] [P0-T4] Read `.claude/rules/typescript-suppressions.md` and append it to `evidence/baseline/phase0-instructions-read.md`.
- [x] [P0-T5] Read `.claude/rules/architecture-boundaries.md` and append it to `evidence/baseline/phase0-instructions-read.md`.
- [x] [P0-T6] Read `.claude/rules/quality-tiers.md` and append it to `evidence/baseline/phase0-instructions-read.md`.
- [x] [P0-T7] Read `.claude/rules/tonality.md` and append it to `evidence/baseline/phase0-instructions-read.md`.
- [x] [P0-T8] Run `npm run format -- --check` and write artifact `evidence/baseline/baseline-format.<timestamp>.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
- [x] [P0-T9] Run `npm run lint` and write artifact `evidence/baseline/baseline-lint.<timestamp>.md` with required fields.
- [x] [P0-T10] Run `npm run typecheck` and write artifact `evidence/baseline/baseline-typecheck.<timestamp>.md` with required fields.
- [x] [P0-T11] Run `npm run depcruise` (architecture boundaries) and write artifact `evidence/baseline/baseline-architecture.<timestamp>.md` with required fields.
- [x] [P0-T12] Run `npm run test:coverage` and write artifact `evidence/baseline/baseline-test-coverage.<timestamp>.md` with required fields, including baseline line% and branch% numbers in `Output Summary:`.
- [x] [P0-T13] Run `npm run build` and write artifact `evidence/baseline/baseline-build.<timestamp>.md` with required fields.
- [x] [P0-T14] Run `npm run validate` (office-addin-manifest) and write artifact `evidence/baseline/baseline-validate.<timestamp>.md` with required fields.

### Phase 1 — Office.js Test Fake Extension

- [x] [P1-T1] Edit `src/test-support/office-fake.ts` to add `EventType: { ItemChanged: "olkItemSelectedChanged" }` to the exported fake. Acceptance: the symbol resolves at compile time in test code referencing `Office.EventType.ItemChanged`.
- [x] [P1-T2] Edit `src/test-support/office-fake.ts` to add `addHandlerAsync(eventType, handler, callback?)` stub on `context.mailbox`. Acceptance: `Office.context.mailbox.addHandlerAsync` is callable in tests without throwing.
- [x] [P1-T3] Edit `src/test-support/office-fake.ts` to add `removeHandlerAsync(eventType, callback?)` stub on `context.mailbox`. Acceptance: `Office.context.mailbox.removeHandlerAsync` is callable in tests without throwing.
- [x] [P1-T4] Run `npm run typecheck` to confirm the extended fake type-checks; capture artifact `evidence/qa-gates/p1-typecheck.<timestamp>.md`. Restart Phase 1 task chain if any edit changes other files.

### Phase 2 — Manifest Hardening

- [x] [P2-T1] Edit `manifest.json` `developer` block: replace `name`, `websiteUrl`, `privacyUrl`, `termsOfUseUrl` with TaskMaster-branded values. Acceptance: no `Contoso` substring remains in the `developer` block.
- [x] [P2-T2] Edit `manifest.json` `name.full` to `"TaskMaster for Outlook"`. Acceptance: `name.full` no longer equals `"Contoso Task Pane Add-in"`.
- [x] [P2-T3] Edit `manifest.json` `description.short` and `description.full` to TaskMaster-specific copy. Acceptance: neither equals the template default `"A template to get started."` or `"This is the template to get started."`.
- [x] [P2-T4] Edit `manifest.json` `validDomains[0]` to a TaskMaster-appropriate domain (or `localhost`). Acceptance: no `contoso.com` substring remains in `validDomains`.
- [x] [P2-T5] Edit `manifest.json` extension-level `requirements.capabilities[0].minVersion` from `"1.3"` to `"1.5"`. Acceptance: the extension-level capability requires Mailbox 1.5.
- [x] [P2-T6] Edit `manifest.json` TaskPaneRuntime `requirements.capabilities[0].minVersion` from `"1.3"` to `"1.5"`. Acceptance: TaskPaneRuntime requires Mailbox 1.5.
- [x] [P2-T7] Edit `manifest.json` TaskPaneRuntime action `TaskPaneRuntimeShow.pinnable` from `false` to `true`. Acceptance: `pinnable` is `true` on `TaskPaneRuntimeShow`.
- [x] [P2-T8] Edit `manifest.json` group `label` from `"Contoso Add-in"` to `"TaskMaster"`. Acceptance: group label is TaskMaster-branded.
- [x] [P2-T9] Edit `manifest.json` `msgReadOpenPaneButton.label` and `supertip.title`/`supertip.description` to TaskMaster-branded values. Acceptance: no `"Show Task Pane"` or `"Opens a pane displaying all available properties."` substrings remain on this control.
- [x] [P2-T10] Edit `manifest.json` to remove the entire `ActionButton` control object from `controls`. Acceptance: only the `msgReadOpenPaneButton` control remains in `controls`.
- [x] [P2-T11] Edit `manifest.json` to remove the `{ "id": "action", "type": "executeFunction" }` entry from `CommandsRuntime.actions` (leaving an empty array, or remove the array per schema). Acceptance: no `"actionId": "action"` reference remains anywhere in the manifest.
- [x] [P2-T12] Run `npm run validate` to confirm the manifest validates against the v1.17 unified schema; capture artifact `evidence/qa-gates/p2-validate.<timestamp>.md` with required fields.

### Phase 3 — taskpane.html / taskpane.css Refactor

- [x] [P3-T1] Edit `src/taskpane/taskpane.html` `<title>` to `"TaskMaster"` (remove Contoso). Acceptance: title is TaskMaster-branded.
- [x] [P3-T2] Edit `src/taskpane/taskpane.html` to remove the welcome list (`ms-welcome__features`), the "Run" button, and the "Modify the source files" copy. Acceptance: none of the substrings "Discover what Office Add-ins can do for you today", "Modify the source files", or `id="run"` remain in the file.
- [x] [P3-T3] Edit `src/taskpane/taskpane.html` to add the TaskMaster shell DOM: `#status`, `#selected-subject`, `#selected-from` elements inside `#app-body`. Acceptance: all three IDs exist exactly once in the file.
- [x] [P3-T4] Edit `src/taskpane/taskpane.html` logo `alt`/`title` attributes to TaskMaster strings. Acceptance: no `Contoso` substring remains in the file.
- [x] [P3-T5] Edit `src/taskpane/taskpane.css` to remove orphaned welcome-template-only selectors (`ms-welcome__features`, `ms-welcome__action`, `.ms-welcome__main` hero/button rules) that are no longer referenced in the updated HTML. Acceptance: every remaining selector has at least one matching node in `taskpane.html`.

### Phase 4 — taskpane.ts Hardening

- [x] [P4-T1] Edit `src/taskpane/taskpane.ts` to add a pure `renderItem(item, dom)` function that accepts a typed selected-item shape plus DOM-element references and writes subject + sender into the target elements. Acceptance: `renderItem` has no direct reference to `Office.context` or `document.getElementById`.
- [x] [P4-T2] Edit `src/taskpane/taskpane.ts` to add a pure `renderEmpty(dom)` function that clears subject/from and sets a placeholder status. Acceptance: `renderEmpty` has no direct reference to `Office.context` or `document.getElementById`.
- [x] [P4-T3] Edit `src/taskpane/taskpane.ts` to add `onItemChanged` handler that re-reads `Office.context.mailbox.item` each call, null-checks it, and dispatches to `renderItem` or `renderEmpty`. Acceptance: handler does not cache the item between invocations.
- [x] [P4-T4] Edit `src/taskpane/taskpane.ts` `Office.onReady` block to call `Office.context.mailbox.addHandlerAsync(Office.EventType.ItemChanged, onItemChanged)` and invoke `onItemChanged` once for the initial item. Acceptance: subscription occurs inside `Office.onReady` only.
- [x] [P4-T5] Edit `src/taskpane/taskpane.ts` to remove the exported `run()` function and the `requireElement("run").onclick = run` wiring. Acceptance: no symbol `run` is exported or referenced in the file.
- [x] [P4-T6] Edit `src/taskpane/taskpane.ts` to retain `requireElement` as an internal helper. Acceptance: `requireElement` remains in the file and is referenced only by the Office.onReady wiring.

### Phase 5 — commands.ts Pruning

- [x] [P5-T1] Edit `src/commands/commands.ts` to remove the `action` function body. Acceptance: no symbol `action` is declared in the file.
- [x] [P5-T2] Edit `src/commands/commands.ts` to remove the `Office.actions.associate("action", action)` registration call. Acceptance: no `Office.actions.associate` reference remains in the file.
- [x] [P5-T3] Confirm `src/commands/commands.ts` retains only the `Office.onReady(() => { /* noop */ })` wiring plus `export {};`. Acceptance: file body consists only of these two elements plus the file header comment.

### Phase 6 — Unit Tests (Vitest)

- [x] [P6-T1] Edit `src/taskpane/taskpane.test.ts` to remove tests that exercise the deleted `run()` function. Acceptance: no test references the `run` symbol.
- [x] [P6-T2] Edit `src/taskpane/taskpane.test.ts` to add a positive-path test that `renderItem` writes the subject and sender into supplied DOM elements for a well-formed item. Acceptance: test exists and asserts both DOM mutations.
- [x] [P6-T3] Edit `src/taskpane/taskpane.test.ts` to add a null-item test that `onItemChanged` calls `renderEmpty` when `Office.context.mailbox.item` is `null`. Acceptance: test exists and asserts the empty-state DOM.
- [x] [P6-T4] Edit `src/taskpane/taskpane.test.ts` to add a missing-subject test confirming `renderItem` renders an empty string for a missing/undefined subject without throwing. Acceptance: test passes without exceptions.
- [x] [P6-T5] Edit `src/taskpane/taskpane.test.ts` to add a subscription test asserting `Office.context.mailbox.addHandlerAsync` is invoked with `Office.EventType.ItemChanged` and a function from inside `Office.onReady`. Acceptance: spy is called exactly once with the expected arguments.
- [x] [P6-T6] Edit `src/taskpane/taskpane.test.ts` to add a re-render test that captures the handler passed to `addHandlerAsync`, updates `Office.context.mailbox.item`, invokes the handler, and asserts the DOM reflects the new item. Acceptance: subject and sender DOM elements show the second item's values.
- [x] [P6-T7] Edit `src/taskpane/taskpane.test.ts` to add a `requireElement` test for the missing-id error path. Acceptance: test asserts `requireElement` throws with the expected message.
- [x] [P6-T8] Edit `src/commands/commands.test.ts` to remove tests for the deleted `action` function. Acceptance: no test references the `action` symbol.
- [x] [P6-T9] Edit `src/commands/commands.test.ts` to add a test that importing the module completes without throwing and registers no `Office.actions.associate` calls. Acceptance: spy on `Office.actions.associate` is called zero times.
- [x] [P6-T10] Run `npm run test:coverage` and write artifact `evidence/qa-gates/p6-test-coverage.<timestamp>.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including post-change line% and branch% for the changed files. Acceptance: line coverage >= 85% and branch coverage >= 75% on changed files (AC 12).

### Phase 7 — Final QA Loop

- [x] [P7-T1] Run `npm run format` and write artifact `evidence/qa-gates/final-format.<timestamp>.md` with required fields. If files change, restart this phase from P7-T1.
- [x] [P7-T2] Run `npm run lint` and write artifact `evidence/qa-gates/final-lint.<timestamp>.md` with required fields. If files change or errors are reported, restart from P7-T1.
- [x] [P7-T3] Run `npm run typecheck` and write artifact `evidence/qa-gates/final-typecheck.<timestamp>.md` with required fields. If errors are reported, restart from P7-T1.
- [x] [P7-T4] Run `npm run depcruise` (architecture boundaries) and write artifact `evidence/qa-gates/final-architecture.<timestamp>.md` with required fields. Acceptance: zero violations (AC 7).
- [x] [P7-T5] Run `npm run test:coverage` and write artifact `evidence/qa-gates/final-test-coverage.<timestamp>.md` with required fields including post-change line% and branch% headline values. Acceptance: thresholds per AC 12.
- [x] [P7-T6] Run `npm run contract` (or repo-equivalent contract/schema check stage) and write artifact `evidence/qa-gates/final-contract.<timestamp>.md` with required fields.
- [x] [P7-T7] Run `npm run test:integration` (or repo-equivalent integration stage) and write artifact `evidence/qa-gates/final-integration.<timestamp>.md` with required fields.
- [x] [P7-T8] Run `npm run build` and write artifact `evidence/qa-gates/final-build.<timestamp>.md` with required fields. Acceptance: webpack production build succeeds (AC 8).
- [x] [P7-T9] Run `npm run validate` and write artifact `evidence/qa-gates/final-validate.<timestamp>.md` with required fields. Acceptance: office-addin-manifest validation succeeds (AC 9).
- [x] [P7-T10] Confirm Prompt B1 PR pipeline checks (tier-classification, secret-scan, stage-1 through stage-7) all pass locally by reviewing the artifacts captured in P7-T1..P7-T9 plus the tier-classification and secret-scan stages. Write rollup artifact `evidence/qa-gates/final-pipeline-rollup.<timestamp>.md` enumerating each stage and its EXIT_CODE. Acceptance: every stage exit code is zero (AC 10).

### Phase 8 — Acceptance Criteria Check-Off and Evidence Capture

- [x] [P8-T1] Create `evidence/other/acceptance-criteria-checkoff.<timestamp>.md` enumerating ACs 1-12 from `issue.md`, with one row per AC referencing the task IDs that satisfy it and the evidence artifact paths that prove it:
  - AC 1 (branding strings): P2-T1, P2-T2, P2-T3, P2-T8, P2-T9 + `evidence/qa-gates/p2-validate.*`
  - AC 2 (pinnable): P2-T7 + `evidence/qa-gates/p2-validate.*`
  - AC 3 (taskpane.html refactor): P3-T1, P3-T2, P3-T3, P3-T4
  - AC 4 (ItemChanged handler): P4-T3, P4-T4 + `evidence/qa-gates/p6-test-coverage.*`
  - AC 5 (commands.ts pruning + ActionButton removed): P2-T10, P2-T11, P5-T1, P5-T2, P5-T3
  - AC 6 (taskpane.css orphans removed): P3-T5
  - AC 7 (No-COM): P7-T4 (`final-architecture.*`)
  - AC 8 (build): P7-T8 (`final-build.*`)
  - AC 9 (validate): P7-T9 (`final-validate.*`)
  - AC 10 (PR pipeline gates): P7-T10 (`final-pipeline-rollup.*`)
  - AC 11 (unit tests cover ItemChanged + requireElement): P6-T2..P6-T7
  - AC 12 (coverage thresholds): P7-T5 (`final-test-coverage.*`)
- [x] [P8-T2] Create `evidence/issue-updates/issue-6.<timestamp>.md` containing the intended GitHub issue update text plus `PostedAs:` field, mirroring the AC checkoff summary.
- [x] [P8-T3] Confirm no production source file exceeds 500 lines by inspecting `manifest.json`, `src/taskpane/taskpane.ts`, `src/taskpane/taskpane.html`, `src/taskpane/taskpane.css`, `src/commands/commands.ts`, and `src/test-support/office-fake.ts`; record the line counts in `evidence/other/file-size-check.<timestamp>.md`. Acceptance: every file has at most 500 lines.
- [x] [P8-T4] Confirm no new ESLint or TypeScript suppressions outside the `.claude/rules/typescript-suppressions.md` pre-authorized patterns were introduced; grep for `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck` in the changed files and record the result in `evidence/other/suppression-audit.<timestamp>.md`. Acceptance: every suppression matches the pre-authorized single-line patterns with mandatory `-- <reason>` suffixes.
- [x] [P8-T5] Prepare pre-review commit by listing all changed files in `evidence/other/changed-files.<timestamp>.md` and confirming each is covered by at least one task ID above. Acceptance: every changed file maps to a task ID.
