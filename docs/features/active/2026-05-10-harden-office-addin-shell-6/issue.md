## Goal

Convert the scaffold into a TaskMaster task pane shell with selected-message lifecycle handling.

## Files to read first

- `manifest.json`
- `src/taskpane/taskpane.ts`
- `src/taskpane/taskpane.html`
- `src/taskpane/taskpane.css`
- `src/commands/commands.ts`

## Required outcome

- Task pane is TaskMaster-specific (branding, copy, IDs renamed away from Contoso template defaults).
- Task pane can remain open while processing messages where supported (declare `SupportsPinning` / pinnable equivalent in manifest; ensure runtime stays alive).
- Item changes update task pane state (subscribe to `Office.EventType.ItemChanged`; re-render selected-message context).
- Template labels and placeholder actions are removed (no "Welcome", "Run", "Discover what Office Add-ins can do for you today", placeholder `action` notification stub).
- No desktop Outlook automation APIs are introduced (No-COM rules per `.claude/rules/architecture-boundaries.md`).

## Acceptance criteria

1. Manifest `name.short`, `name.full`, `description.short`, `description.full`, group `label`, button `label`/supertip strings reflect TaskMaster branding (no "Contoso", "Perform an action", "Show Task Pane" template defaults).
2. Manifest declares pinnable task pane for `mailRead` context where the unified manifest supports it (`pinnable: true` on `openPage` action).
3. `src/taskpane/taskpane.html` removes the welcome list, "Run" button, "Modify the source files" copy, and uses TaskMaster-specific copy and DOM IDs.
4. `src/taskpane/taskpane.ts` registers an `Office.EventType.ItemChanged` handler that updates the displayed selected-message context (subject + sender at minimum).
5. `src/commands/commands.ts` retains only Office.onReady wiring required by the manifest CommandsRuntime; the placeholder `action` notification stub and its manifest button are removed (manifest no longer references `ActionButton`/`actionId: "action"`).
6. `src/taskpane/taskpane.css` is updated to drop welcome-template-only class rules that are no longer referenced; remaining selectors compile without orphaned references.
7. Production code contains no references to `Microsoft.Office.Interop.Outlook`, `Microsoft.Office.Tools`, COM-visible attributes, or Ribbon XML callbacks (per architecture-boundaries.md).
8. `npm run build` succeeds (webpack production build, no errors).
9. `npm run validate` succeeds (office-addin-manifest validation against `manifest.json`).
10. All Prompt B1 PR pipeline gates pass on the branch: tier-classification, secret-scan, stage-1-format, stage-2-lint, stage-3-typecheck, stage-4-architecture, stage-5-unit-tests, stage-6-contract, stage-7-integration.
11. Unit tests cover the new ItemChanged handler logic (lifecycle re-render behavior) and the `requireElement` DOM helper if retained.
12. Line coverage >= 85% and branch coverage >= 75% on changed files per `.claude/rules/quality-tiers.md`.
