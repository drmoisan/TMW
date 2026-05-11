# Issue 6 — Update Mirror

Timestamp: 2026-05-11T00-20
PostedAs: unknown (orchestrator will post the pre-review commit; this mirror records the intended update text)

## Intended Update Text

**Prompt B2 — Harden The Office Add-in Shell — implementation complete.**

All 12 acceptance criteria verified locally on branch `feature/harden-office-addin-shell-6`:

| AC | Status |
|---|---|
| 1. Manifest branding strings reflect TaskMaster | PASS |
| 2. `pinnable: true` on openPage action | PASS |
| 3. taskpane.html refactored (no welcome list / Run / Modify-source copy) | PASS |
| 4. ItemChanged handler updates subject + sender | PASS |
| 5. commands.ts pruned; ActionButton + actionId "action" removed | PASS |
| 6. taskpane.css orphans removed | PASS |
| 7. No-COM (depcruise 0 violations) | PASS |
| 8. `npm run build` | PASS |
| 9. `npm run validate` | PASS |
| 10. PR pipeline gates (tier-classification, secret-scan, stage-1..7) locally green | PASS |
| 11. Unit tests cover ItemChanged + requireElement | PASS |
| 12. Coverage line 98.18% / branch 90.47% on changed files | PASS |

Manifest changes:
- developer/branding strings replaced; validDomains -> `localhost`
- Mailbox capability raised to 1.5 (extension + TaskPaneRuntime)
- `TaskPaneRuntimeShow.pinnable: true`
- ActionButton control removed; CommandsRuntime.actions array removed (empty array fails the v1.17 schema's min-items=1 rule, so the optional array was removed)

Source changes:
- `src/taskpane/taskpane.ts` — pure `renderItem`/`renderEmpty` functions, `onItemChanged` re-reads `Office.context.mailbox.item` and dispatches; `Office.onReady` subscribes via `addHandlerAsync(Office.EventType.ItemChanged, onItemChanged)` and invokes once for the initial item.
- `src/taskpane/taskpane.html` — TaskMaster shell with `#status`, `#selected-subject`, `#selected-from`.
- `src/taskpane/taskpane.css` — removed welcome-template selectors.
- `src/commands/commands.ts` — reduced to `Office.onReady(() => { /* noop */ }); export {}`.
- `src/test-support/office-fake.ts` — added `EventType.ItemChanged`, `addHandlerAsync`, `removeHandlerAsync`.

Evidence under `docs/features/active/2026-05-10-harden-office-addin-shell-6/evidence/`.
