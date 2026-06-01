# Feature Audit: iFile Message-Filing Dialog (Issue #43)

**Audit Date:** 2026-06-01
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main`
**Head Branch:** `feature/ifile-message-filing-dialog-43`
**Work Mode:** `full-feature`
**Audit Type:** Initial acceptance review

---

## Scope and Baseline

- **Base branch:** `main` (commit `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
- **Head branch/commit:** `feature/ifile-message-filing-dialog-43` (commit `0357d88d13b1efdc0ee9d29999623fe2bf61bd72`)
- **Merge base:** `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`
- **Evidence sources:**
  - Primary: `artifacts/pr_context.summary.txt`
  - Secondary baseline diff: `artifacts/pr_context.appendix.txt`
  - Feature evidence: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/**`
  - Additional evidence: re-computed coverage from `coverage/lcov.info` and `tests/**/TestResults/**/coverage.cobertura.xml`; direct source inspection of the branch diff.
- **Feature folder used:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- **Requirements source:** `spec.md` (AC-1..AC-24) and `user-story.md` (full-feature work mode).
- **Work mode resolution note:** `issue.md` carries an explicit `- Work Mode: full-feature` marker; AC sources resolved to `spec.md` and `user-story.md`.
- **Scope note:** Audit is the full feature-vs-base diff. AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24 carry manual device/tenant verification dimensions that CI cannot close; their CI-verifiable portions are evaluated here and the manual dimensions remain PENDING per `evidence/other/manual-verification.md`.

---

## Acceptance Criteria Inventory

**Authoritative AC source files for this run:**
- `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/spec.md` — primary (AC-1..AC-24, checkbox-backed).
- `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/user-story.md` — secondary (checkbox-backed mirror, no AC numbering).

### From spec.md (AC-1..AC-24)

1. AC-1 `iFile` declared as the first control in its group on the message-read surface in `manifest.json` and in both the `DesktopFormFactor` and `MobileFormFactor` groups of `manifest.xml`.
2. AC-2 Activating `iFile` on desktop opens an Office Dialog containing a search textbox and a results list.
3. AC-3 Activating `iFile` on Outlook mobile opens the same search UI inline in the full-screen task pane, sharing one UI/logic implementation with desktop.
4. AC-4 With an empty search textbox, the results list contains no search-sourced results.
5. AC-5 Typing a pattern prepends matching folder-leaf results live; clearing the textbox removes all search-sourced results.
6. AC-6 Search returns only leaf folders (`childFolderCount == 0`) whose leaf display name or full path matches the pattern.
7. AC-7 Wildcard matching supports `*`/`?`, case-insensitive, matches leaf name and full path, NFC-normalized, `\*`/`\?` literal, lone `*` match-all, empty pattern no-match.
8. AC-8 Folder tree loaded once on open; per-keystroke filtering issues no Graph call.
9. AC-9 Container exposes a documented, versioned input contract for classifier/recent sources; adding a live source needs only a non-empty array, no signature/container change.
10. AC-10 Selecting a result issues a single server-side filing command with message REST id and destination folder id; no Graph write on the client.
11. AC-11 Message REST id resolved per platform: already-REST `item.itemId` on mobile (no `convertToRestId`), converted on non-mobile.
12. AC-12 Selecting a result moves the message via Graph `POST /me/messages/{id}/move`.
13. AC-13 Non-inline file attachments saved to the mirrored OneDrive folder beneath the persisted Archive root, intermediate folders created; inline content skipped.
14. AC-14 Outlook-to-OneDrive path mapping strips the leading `Archive` segment; Archive root identified by `displayName` `Archive` under the mailbox root.
15. AC-15 OneDrive subfolder creation is create-if-missing; upload uses simple PUT at/below 10 MiB and an upload session above 10 MiB.
16. AC-16 A message with no non-inline file attachments performs no OneDrive writes, proceeds to the move, reports success.
17. AC-17 Filing command executes attachments-first, move-last; the move is the final step.
18. AC-18 On an earlier-step failure the message is not moved, a clear error is returned, and retry is idempotent.
19. AC-19 Manifest and AAD scope changes present: `manifest.json` adds `MailboxItem.ReadWrite.User`; `manifest.xml` uses `ReadWriteMailbox`; AAD scopes include `Mail.ReadWrite`, `Files.ReadWrite`, `Mail.ReadBasic`.
20. AC-20 Behavior verified on both Outlook desktop and Outlook mobile form factors.
21. AC-21 On first filing with no stored mapping, the user can select an existing OneDrive folder or create a new one as the Archive root; no auto-create by convention.
22. AC-22 The chosen mapping is persisted through `IUserSettingsRepository` and survives across sessions.
23. AC-23 On subsequent filings the stored mapping is reused without re-prompting; subfolders remain create-if-missing.
24. AC-24 The Archive-root picker is presented per host (desktop dialog/in-pane vs. mobile inline) with identical capability and persisted-mapping result.

### From user-story.md (checkbox mirror, no numbering)

The 17 user-story checkboxes mirror the spec ACs from the user perspective. They are evaluated collectively against the corresponding spec ACs in the check-off section below.

---

## Acceptance Criteria Evaluation

| # | Criterion | Status | Evidence | Verification command(s) | Notes |
|---|-----------|--------|----------|--------------------------|-------|
| AC-1 | iFile first control on desktop + mobile | PASS | `manifest.json` `msgReadIFileButton` is the first control in `msgReadGroup` (before `msgReadOpenPaneButton`); `manifest.xml` declares the button in `DesktopFormFactor` and `MobileFormFactor`. | `Select-String manifest.json/xml` | On-device visible ordering remains a manual confirmation (AC-20). |
| AC-2 | Desktop dialog with textbox + results list | PASS (CI) / PENDING (device) | `dialog-host.contract.test.ts` verifies the Office.js dialog options shape and `messageParent` round trip; `ifile.html` renders textbox + results list. | `phase6-contract-ts.md` | Real-desktop dialog open is PENDING-DEVICE. |
| AC-3 | Mobile inline same UI, shared implementation | PASS (CI) / PENDING (device) | `selectPresentation` returns `inline` for `OutlookIOS`, `dialog` otherwise; `host-presentation.test.ts`; shared bundle. | `npm run test:coverage` | Real-mobile inline render is PENDING-DEVICE. |
| AC-4 | Empty textbox -> no search results | PASS | `IFileController.search("")` composes `[], [], searchLeafFolders(leaves,"")`; empty pattern returns no results; `ifile-controller.test.ts`, `result-list-composer.test.ts`. | `npm run test:coverage` | |
| AC-5 | Typing prepends; clearing removes | PASS | Controller recomputes per keystroke from the cached list; composer prepends search results; tests on the search/compose path. | `npm run test:coverage` | |
| AC-6 | Leaf-only, name/path match | PASS | `folder-search.test.ts` over a fixture folder tree restricts to `childFolderCount == 0` and matches name/path. | `npm run test:coverage` | |
| AC-7 | Wildcard semantics + property tests | PASS | `wildcard-matcher.test.ts` + `wildcard-matcher.property.test.ts` cover `*`/`?`, case-insensitive, NFC, escapes, lone `*`, empty. | `npm run test:coverage` | |
| AC-8 | Load once, no per-keystroke Graph call | PASS | `IFileController.open` uses `this.leaves ??= await this.loadLeaves()`; `search` never re-fetches; `ifile-controller.test.ts`. | `npm run test:coverage` | Direct source inspection confirms single load. |
| AC-9 | Documented versioned input contract | PASS | `ResultListComposer.compose(classifier, recent, search)` fixed signature; `result-list-composer.contract.test.ts`; documented in `spec.md`. | `phase6-contract-ts.md` | |
| AC-10 | Single server-side command; no client Graph write | PASS | `IFileBoundaryTests` asserts `Application.IFile` has no `Microsoft.Graph` dependency and adapters live only in Infrastructure; api-client contract test on request shape. | `dotnet test tests/TaskMaster.ArchitectureTests` | |
| AC-11 | Per-platform REST-id resolution | PASS (CI) / PENDING (device) | `resolveMessageRestId` returns `itemId` for `OutlookIOS`, otherwise injected `convert`; `message-id-resolver.test.ts`. | `npm run test:coverage` | Real-device Graph acceptance is PENDING-DEVICE. |
| AC-12 | Move via Graph move endpoint | PASS (CI) / PENDING (device) | `GraphMessageMoverContractTests` asserts `POST /me/messages/{id}/move` body `{ destinationId }`. | `phase6-contract-dotnet.md` | End-to-end move is PENDING-DEVICE. |
| AC-13 | Save non-inline attachments to mirrored OneDrive; skip inline | PASS (CI) / PENDING (device) | `AttachmentFilterTests`, `OutlookToOneDrivePath` unit/property tests, handler upload integration, `GraphOneDriveContractTests`. | `dotnet test` | Real OneDrive write is PENDING-DEVICE. |
| AC-14 | Path mapping strips `Archive`; display-name root | PASS | `OutlookToOneDrivePathTests` + `OutlookToOneDrivePathPropertyTests`; `ArchiveRootResolver` resolves by `displayName`. | `dotnet test` | |
| AC-15 | Create-if-missing; PUT vs upload session at 10 MiB | PASS | `GraphOneDriveFolderWriterTests` / `GraphOneDriveContractTests` cover create, 409 conflict, and the size threshold. | `dotnet test` | |
| AC-16 | No-attachment message moves, no OneDrive writes | PASS | `UploadAttachmentsAsync` early-returns when `savable.Count == 0`; `FileMessageCommandHandlerTests` no-attachment case. | `dotnet test` | |
| AC-17 | Attachments-first, move-last | PASS | `FileMessageCommandHandler.ExecuteAsync` orders steps 1-3 with move last; integration test asserts move not invoked until prior steps succeed. | `dotnet test` | Verified by source inspection (handler lines 78-104). |
| AC-18 | Pre-move failure leaves message; idempotent retry | PASS | `FileMessageFailureTests` injects a pre-move failure; handler returns `PreMoveFailure` without moving; create-if-missing makes retry safe. | `dotnet test` | |
| AC-19 | Manifest + AAD scope changes | PARTIAL | Manifest CI portion done: `manifest.json` `MailboxItem.ReadWrite.User`, `manifest.xml` `ReadWriteMailbox`. AAD scope grant/consent is out-of-repo and PENDING-TENANT. | `Select-String manifest.json/xml` | AAD consent cannot be verified by CI; see `aad-scope-changes.md`. |
| AC-20 | Verified on desktop + mobile | UNVERIFIED | Manual-only; no device evidence (correctly not fabricated). | n/a | PENDING-DEVICE on both form factors. |
| AC-21 | First-use select-or-create; no auto-create | PASS (CI) / PENDING (device) | `archive-root-picker.test.ts`; handler returns `ArchiveRootRequired` when no stored mapping and no first-use selection; no auto-create of an `Archive` folder. | `dotnet test`, `npm run test:coverage` | Real-host picker is PENDING-DEVICE. |
| AC-22 | Mapping persisted via settings store, survives sessions | PASS | `ArchiveRootMappingTests` writes via `IUserSettingsRepository` and reads back; `UserSettings.ArchiveRootDriveItemId` added; schema extended. | `dotnet test` | |
| AC-23 | Stored mapping reused, no re-prompt; create-if-missing subfolders | PASS | `ResolveArchiveRootAsync` returns the stored id without prompting; integration test of a second filing issues no picker step. | `dotnet test` | |
| AC-24 | Per-host Archive-root picker presentation | PASS (CI) / PENDING (device) | `selectPresentation` reused for the picker; host-detection branch + shared-flow tests. | `npm run test:coverage` | Real-host picker presentation is PENDING-DEVICE. |

---

## Summary

**Overall Feature Readiness:** NEEDS REVISION (manual verification outstanding) — the CI-verifiable scope is complete and PASS; the feature cannot be declared fully verified until the manual device/tenant criteria are exercised.

**Criteria summary:**
- **PASS:** 22 criteria (AC-1, AC-4–AC-18, AC-21, AC-22, AC-23, AC-24 on their CI-verifiable dimension; AC-2, AC-3, AC-11, AC-12, AC-13, AC-21, AC-24 carry a PENDING device dimension but their CI portion is PASS).
- **PARTIAL:** 1 criterion (AC-19 — manifest done, AAD consent PENDING-TENANT).
- **UNVERIFIED:** 1 criterion (AC-20 — manual-only, no device evidence by design).
- **FAIL:** 0 criteria.

**Top gaps preventing full PASS:**
1. AC-20 is manual-only and unverified; nine ACs total carry PENDING device/tenant dimensions recorded in `evidence/other/manual-verification.md`.
2. AC-19 AAD scope grant/consent is an out-of-repo tenant action (PENDING-TENANT).
3. Manifest production-domain placeholder must be configured at deploy time for the same-origin dialog.

**Recommended follow-up verification steps:**
1. Execute the manual-verification dossier on a real Outlook desktop client and a real Outlook mobile client; record build/version and observed results.
2. Grant and consent the three AAD delegated scopes in the app registration; confirm a live end-to-end filing (move + OneDrive mirror) with the consented OBO token.

---

## Acceptance Criteria Check-off

Per the acceptance-criteria tracking rules, only criteria evaluated as PASS on all required dimensions are checked off in the source files. Criteria with a PENDING manual/device dimension (AC-2, AC-3, AC-11, AC-12, AC-13, AC-21, AC-24), PARTIAL (AC-19), or UNVERIFIED (AC-20) remain unchecked because the spec marks them as requiring manual verification to fully close.

Newly checked off in `spec.md` (were `[ ]`, now `[x]` after this audit): none additional beyond those already checked by the executor. The fully-CI-closable criteria (AC-1, AC-4..AC-10, AC-14..AC-18, AC-22, AC-23) were already checked `[x]` in `spec.md` by the executor and are confirmed PASS here; no text was modified. AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24 remain `[ ]` consistent with their manual-verification requirement.

### AC Status Summary

- Source: `spec.md` (AC-1..AC-24) and `user-story.md` (17-item mirror)
- Total AC items: 24 (spec) / 17 (user-story)
- Checked off (delivered) in spec.md: 15 (AC-1, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-14, AC-15, AC-16, AC-17, AC-18, AC-22, AC-23)
- Remaining (unchecked) in spec.md: 9 (AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24)
- Items remaining: AC-2, AC-3, AC-11, AC-12, AC-13 (CI portion PASS, device PENDING); AC-19 (manifest PASS, AAD PENDING-TENANT); AC-20 (manual-only UNVERIFIED); AC-21, AC-24 (CI portion PASS, device PENDING).

| Source File | Total AC | Checked (PASS) | Unchecked | Notes |
|-------------|----------|----------------|-----------|-------|
| `spec.md` | 24 | 15 | 9 | Checkbox-backed; unchecked items require manual device/tenant verification. No text modified by this audit. |
| `user-story.md` | 17 | 11 | 6 | Checkbox-backed mirror; the 6 unchecked items correspond to the manual-verification ACs (first-command ordering on-device, desktop dialog, mobile inline, attachment-save end-to-end, first-use picker, per-host picker, form-factor verification). No text modified. |
