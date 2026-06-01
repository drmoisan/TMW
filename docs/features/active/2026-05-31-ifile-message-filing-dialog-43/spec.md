# ifile-message-filing-dialog — Spec

- **Issue:** #43
- **Issue URL:** https://github.com/drmoisan/TMW/issues/43
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-31
- **Status:** Draft
- **Version:** 0.3
- **Work Mode:** full-feature
- **Target platforms:** Outlook desktop and Outlook mobile (parity)

## Overview

Filing an opened email into the correct folder is a frequent, high-friction action. The iFile
feature adds a command on the message-read surface that opens a search container for selecting a
destination folder. Selecting a destination moves the opened message to that Outlook folder and
saves the message's attachments to a parallel OneDrive location beneath an `Archive` root.

The destination list is designed to be assembled from multiple ordered sources (a classifier, the
user's recent choices, and on-demand search). Only the search source is implemented in this
iteration. The container exposes a documented input contract so the other sources can be added
later without rework.

This spec is derived from the promoted issue (`issue.md`), the potential feature description, and
the technical research at `artifacts/research/2026-05-31-ifile-message-filing-dialog-research-43.md`.
The research is authoritative for platform constraints; where a constraint is cited it is tagged
with the research identifier (for example HC-1).

## Scope

### In scope (this iteration)

1. An `iFile` command rendered as the first button on the message-read surface on both Outlook
   desktop and Outlook mobile.
2. A search container with a search textbox and a results list, presented as an Office Dialog on
   desktop and as an inline full-screen task pane on mobile, built from a single shared UI/logic
   implementation.
3. A documented, versioned input contract for the results list that accepts ordered result
   sources: classifier results, recent choices, and search results. Only the search-results source
   is populated this iteration; the classifier and recent-choices sources are wired to the contract
   but receive no data.
4. Wildcard folder search over the mailbox folder tree, returning leaf folders by name/path match,
   filtered in-memory per keystroke from a folder list loaded once when the container opens.
5. A server-side filing command that, on selection, resolves or creates the mirrored OneDrive folder,
   uploads non-inline file attachments, then moves the opened message to the chosen Outlook folder.
   The command executes attachments-first, move-last so that a failure before the move leaves the
   message in place (see Error handling and partial-failure behavior, OD-7).
6. A first-use OneDrive Archive-root mapping flow: when no stored mapping exists for the mailbox
   `Archive` folder, the user selects an existing OneDrive folder or creates a new one to serve as
   the Archive root. The resulting mapping is persisted in user settings and reused on subsequent
   filings without re-prompting (see Resolved Decisions, OD-6).
7. Host-neutral, testable modules for wildcard matching, multi-source result-list composition,
   folder-path construction, and Outlook-to-OneDrive path mapping.
8. Manifest and AAD scope changes required to perform the move and OneDrive operations.

### Out of scope (this iteration)

- The classifier result source as a live data producer. Only its input contract is in scope.
- The recent-choices result source as a live data producer. Only its input contract is in scope.
- Match-quality ranking of search results beyond the deterministic order resolved in OD-9 (see
  Resolved Decisions).
- Folder-change delta sync (`/me/mailFolders/delta`); the folder list is loaded per container open.
- Background or scheduled filing; iFile acts only on the currently opened message.
- User selection of which attachments to save; per OD-9 (resolved), all non-inline file attachments
  are saved and inline body-embedded content is skipped.
- Editing or relocating the persisted OneDrive Archive-root mapping after first use; this iteration
  persists the mapping on first use and reuses it without a re-mapping or settings-management UI.

## Behavior

### Command placement

1. When an email is opened (message-read surface), an `iFile` command is the first available button
   in the command group on both desktop and mobile. Button order follows manifest declaration order
   within the group, so `iFile` is declared first in its group in both `manifest.json` (desktop) and
   `manifest.xml` (desktop and mobile `MobileFormFactor`).
2. The mobile button label is `iFile` (5 characters), within the documented 16-character mobile
   label limit.

### Container presentation (dual presentation, single implementation)

3. Activating `iFile` opens a search container holding a search textbox and a results list.
4. On desktop (Outlook on Windows, Mac, Web), the container is presented as an Office Dialog opened
   via `Office.context.ui.displayDialogAsync`. The dialog URL shares the add-in origin (same full
   domain as the host page).
5. On Outlook mobile (iOS/Android), the Office Dialog API is not supported (HC-1). The same search
   UI renders inline in the full-screen task pane opened by the `ShowTaskpane` action. The mobile
   command uses `ShowTaskpane` because `ExecuteFunction` is not documented as supported on the
   mobile message-read command surface.
6. The desktop dialog and the mobile inline task pane render the same HTML/JS bundle and the same
   search UI and logic. The presentation difference (dialog window vs. inline task pane) is selected
   at runtime by host detection; the search behavior, result-list composition, and selection
   handling are identical across both presentations.

### Results list composition and search

7. The results list is composed by a host-neutral `ResultListComposer` from ordered input sources.
   The documented order is: classifier results first, then recent choices, then search results.
   Search results are prepended relative to a baseline empty list as the user types; classifier and
   recent-choices sources contribute no data this iteration.
8. While the search textbox is empty, the list contains no search-sourced results. Because classifier
   and recent-choices sources contribute nothing this iteration, the list is empty while the textbox
   is empty.
9. As the user types, folder-tree leaf matches are computed and the matching results update live.
   Clearing the textbox removes all search-sourced results. Within the search results the order is
   deterministic (OD-9, resolved): exact and prefix matches first, then alphabetical by full folder
   path. Search results are prepended ahead of the (currently empty) classifier and recent-choices
   sources.
10. Search returns leaf folders (folders with `childFolderCount == 0`) of the mailbox folder tree
    whose leaf display name or full folder path matches the entered pattern.
11. Matching supports glob wildcards: `*` matches zero or more characters, `?` matches exactly one
    character. Matching is case-insensitive. The pattern is matched against both the leaf
    `displayName` and the full folder path (for example `Archive/Clients/Acme`). Unicode NFC
    normalization is applied to pattern and target before matching. `\*` and `\?` match literal
    characters. A pattern of only `*` matches all leaf folders; an empty pattern returns no results.
12. Search returns quickly by loading the folder tree once when the container opens and filtering the
    cached in-memory leaf list per keystroke. No Graph call is issued per keystroke.

### Selection, move, and attachment save

13. Selecting a result triggers a single server-side filing command with the message REST id and the
    chosen destination folder id. The filing command executes in a fixed order: (1) resolve or create
    the mirrored OneDrive folder, (2) upload the non-inline file attachments, (3) move the message.
    This attachments-first, move-last order means that if any step before the move fails, the message
    stays in its original folder (OD-7, resolved).
14. The filing command moves the opened message to the selected Outlook folder via Graph
    `POST /me/messages/{id}/move` as the final step, only after OneDrive folder resolution and
    attachment upload have succeeded.
15. The filing command saves the message's non-inline file attachments to OneDrive. The Outlook root
    `Archive` folder is identified by the mail folder whose `displayName` is `Archive` directly under
    the mailbox root, not the Graph well-known mailbox name `archive` (OD-5, resolved). The mailbox
    `Archive` folder maps to a OneDrive folder chosen by the user on first use (the persisted Archive
    root, see Archive-root mapping below). Destination subfolders are created beneath the mapped
    OneDrive Archive root as needed so the OneDrive structure mirrors the Outlook folder structure
    beneath `Archive`. The OneDrive relative path is computed by stripping the leading `Archive`
    segment from the Outlook folder path.
16. OneDrive subfolders beneath the mapped Archive root are created with create-if-missing semantics
    (attempt create with `@microsoft.graph.conflictBehavior: "fail"`, treat `409 Conflict` as
    "already exists" and use the existing folder). Attachment upload uses simple PUT for attachments
    at or below 10 MiB and an upload session for attachments larger than 10 MiB. Only non-inline file
    attachments are saved; inline body-embedded content is skipped (OD-4, resolved).

### OneDrive Archive-root mapping (first use and reuse)

17. The OneDrive Archive root is not auto-named or auto-created by convention. On the first filing for
    which no stored Archive-root mapping exists, the user is presented with a way to either select an
    existing OneDrive folder or create a new OneDrive folder to serve as the Archive root.
18. The resulting mapping — the mailbox `Archive` folder associated with the chosen OneDrive folder or
    drive-item id — is persisted in user settings through the existing settings-store abstraction
    (`IUserSettingsRepository` in `TaskMaster.Application`). On subsequent filings the stored mapping
    is reused without re-prompting.
19. Subfolders beneath the mapped Archive root remain create-if-missing (per item 16) so the OneDrive
    structure beneath the Archive root continues to mirror the Outlook folder structure beneath
    `Archive` on every filing.
20. The Archive-root picker uses the same dual presentation as the search container: a desktop Office
    Dialog (or an in-pane step) on desktop, and an inline full-screen task-pane step on Outlook
    mobile. The selection-or-create capability and the resulting persisted mapping are identical
    across both presentations.

## Architecture: client/server split

Per No-COM architecture rule 8 (HC-6), privileged business behavior executes server-side. The split
is as follows.

### Client (dialog/task-pane HTML + TypeScript)

- Render the search UI (search textbox, results list); capture user input.
- Read `Office.context.mailbox.item.itemId` and `Office.context.mailbox.item.attachments` metadata
  via Office.js (mailbox data accessed only through Office.js, rule 7).
- Resolve the message REST id per platform: on Outlook mobile, `item.itemId` is already REST-formatted
  and `convertToRestId` is not supported (HC-3); on non-mobile clients, convert via
  `convertToRestId(itemId, RestVersion.v2_0)`. Platform is detected via
  `Office.context.mailbox.diagnostics.hostName`.
- Apply wildcard matching and result-list composition in-process (pure host-neutral modules).
- Present the OneDrive Archive-root picker on first use (select existing OR create new) when the
  backend reports no stored mapping, using the same dual presentation as the search container.
- Call the backend endpoints: a folder-list query, a filing command, and the Archive-root mapping
  read/write operations (or an equivalent first-use flow within the filing command).

### Server (TaskMaster.Application command + TaskMaster.Infrastructure Graph adapter)

- Enumerate the mailbox folder tree via Graph (`GET /me/mailFolders` plus recursive
  `/childFolders`), returning a flat leaf-folder list (`id`, `displayName`, `path`, `parentFolderId`).
- Execute the filing command in attachments-first, move-last order: resolve or create the mirrored
  OneDrive folder under the persisted Archive root, fetch attachment content via Graph, upload
  attachments, then move the message — all behind the existing OBO token flow in `TaskMaster.Api`.
  A failure before the move leaves the message in place (OD-7, resolved).
- Read and persist the OneDrive Archive-root mapping through the settings-store abstraction
  (`IUserSettingsRepository` in `TaskMaster.Application`); on first use, surface the need to pick or
  create the Archive root to the client and store the chosen drive-item id for reuse (OD-6, resolved).
- The client passes the message REST id and the chosen destination folder id (and, on first use, the
  chosen OneDrive Archive-root drive-item id); no Graph write logic runs on the client.

## Host-neutral modules and contracts

These modules are pure (no I/O) and testable in isolation. Property-based tests are required for the
pure functions per the quality tier (see Quality Tier below).

| Module | Language | Contract |
|---|---|---|
| `WildcardMatcher` | TypeScript | `match(pattern: string, target: string): boolean` — glob `*`/`?`, case-insensitive, NFC-normalized, `\*`/`\?` literal escapes. |
| `ResultListComposer` | TypeScript | `compose(classifierResults: FolderResult[], recentChoices: FolderResult[], searchResults: FolderResult[]): FolderResult[]` — preserves source order: classifier, then recent choices, then search results. Empty sources contribute nothing. |
| `FolderPathBuilder` | TypeScript | `buildPath(folderMap: Map<string, MailFolder>, leafId: string): string` — constructs the display path from the parent chain. |
| `OutlookToOneDrivePath` | C# (.NET) | `Map(outlookFolderPath: string): string` — strips the leading `Archive` segment and returns the relative OneDrive path. |

### Result-list input contract (extensibility requirement)

The container exposes a stable input contract so classifier and recent-choices sources can be added
without reworking the container or the composer:

- A `FolderResult` record shape: `{ folderId: string; displayName: string; path: string; source: "classifier" | "recent" | "search" }`.
- An ordered set of source inputs supplied to `ResultListComposer.compose`. Each source is an array
  of `FolderResult`. The classifier and recent-choices inputs are present in the signature and accept
  empty arrays this iteration.
- Adding a live classifier or recent-choices source means supplying a non-empty array to the existing
  parameter; no change to the composer signature, the container, or the search path is required.

## Manifest and scope changes

| Artifact | Current | Required change | Source |
|---|---|---|---|
| `manifest.json` `authorization.permissions.resourceSpecific` | `MailboxItem.Read.User` | Add `MailboxItem.ReadWrite.User` | HC-7, research §9 |
| `manifest.xml` `<Permissions>` | `ReadItem` | Change to `ReadWriteMailbox` | research §9 |
| AAD app registration delegated scopes | existing mail read scope | Add `Mail.ReadWrite`, `Files.ReadWrite`; ensure `Mail.ReadBasic` | research §9 |
| `manifest.json` `validDomains` / `manifest.xml` `<AppDomains>` | localhost | Extend to production HTTPS domain at deploy time | research §9 |

Scope rationale: `Mail.ReadBasic` enumerates the folder tree; `Mail.ReadWrite` is the minimum scope
for `message: move` and for reading full message/attachment content; `Files.ReadWrite` is the minimum
scope for OneDrive folder creation and upload.

Manifest and AAD changes are specified here but are NOT applied by the document-authoring step. They
are implemented during plan execution.

## Error handling and partial-failure behavior

The filing workflow performs writes to OneDrive (folder resolve/create + upload) and a write to the
mailbox (move). To bound the failure surface, the command runs attachments-first, move-last
(OD-7, resolved). The following behavior is specified:

- **Execution order (OD-7, resolved).** The command executes in three steps: (1) resolve or create
  the mirrored OneDrive folder beneath the persisted Archive root, (2) upload the non-inline file
  attachments, (3) move the message. The move is the last step. If step 1 or step 2 fails, the
  message is not moved; it stays in its original folder and the command returns a clear error to the
  user. This removes the "move succeeded but OneDrive failed" inconsistent state by construction:
  OneDrive work either completes before the move or the move does not occur.
- **Retry safety.** Because OneDrive folder creation is create-if-missing and attachment upload uses
  a defined conflict behavior (below), and because a pre-move failure leaves the message in place, a
  retry of a failed command is safe (idempotent): re-running resolves the same folder, re-uploads or
  reuses the same files, and then moves the message.
- **Idempotency of move.** A repeated filing command for a message already in the destination folder
  must not error fatally; the move is treated as satisfied if the message is already in the target
  folder. The exact detection mechanism (re-query vs. tolerate Graph error) is an implementation
  detail to be set in the plan.
- **Idempotency of attachment save.** OneDrive folder creation uses create-if-missing semantics
  (`409 Conflict` treated as already-present). Re-running the command must not create duplicate
  folders. Attachment upload conflict behavior must be defined so a repeat run does not silently
  produce duplicate files; the chosen conflict behavior (`replace` vs. detect-and-skip) is recorded
  in the plan.
- **No attachments.** A message with no non-inline file attachments performs no OneDrive writes and
  proceeds directly to the move, reporting success.
- **Failures are reported, not swallowed.** Errors surface to the user with a specific message and
  are logged at an appropriate level per the general code-change policy (fail fast, no silent
  catch-all).

## Quality tier

The filing command and the Graph/OneDrive adapter are classified **T2** (OD-10, resolved). A misfile
is recoverable rather than silent data loss: a message moved to the wrong folder can be moved again,
and attachments saved to the wrong OneDrive location can be relocated, so the failure mode is a
feature regression (T2) rather than the silent-data-loss / security profile that defines T1.

The host-neutral pure modules (`WildcardMatcher`, `ResultListComposer`, `OutlookToOneDrivePath`, and
`FolderPathBuilder`) still require at least one property-based test per pure function; per the gate
matrix, that density requirement applies at both T1 and T2.

The new projects and modules introduced by this feature must be added to `quality-tiers.yml` at the
appropriate tier (T2 for the filing command and the Graph/OneDrive adapter) during plan execution.
This document does not modify `quality-tiers.yml`. Coverage thresholds are uniform regardless of tier
(line >= 85%, branch >= 75%). Mutation score is trend-only at T2 (the >= 75% mutation gate applies
only at T1, per the gate matrix).

## Acceptance Criteria

Each criterion is individually verifiable. The verification column marks whether the criterion is
CI-verifiable (automated tests, lint/type/arch gates, contract tests) or requires manual device/host
verification (real Outlook desktop and mobile clients).

- [x] **AC-1** The `iFile` command is declared as the first control in its group on the message-read
  surface in `manifest.json` (desktop) and in both the `DesktopFormFactor` and `MobileFormFactor`
  groups of `manifest.xml`. *(CI-verifiable: manifest structure assertion. Manual: visible ordering
  on real desktop and mobile clients.)*
- [ ] **AC-2** Activating `iFile` on desktop opens an Office Dialog containing a search textbox and a
  results list. *(Manual: desktop host verification. CI-verifiable: the dialog-open code path and
  Office.js dialog contract test.)*
- [ ] **AC-3** Activating `iFile` on Outlook mobile opens the same search UI inline in the full-screen
  task pane (no Office Dialog), sharing one UI/logic implementation with desktop. *(Manual: mobile
  device verification. CI-verifiable: host-detection branch unit test and shared-bundle test.)*
- [x] **AC-4** With an empty search textbox, the results list contains no search-sourced results.
  *(CI-verifiable: unit test on `ResultListComposer` and search path with empty input.)*
- [x] **AC-5** Typing a pattern prepends matching folder-leaf results to the list and updates them
  live; clearing the textbox removes all search-sourced results. *(CI-verifiable: unit tests on the
  search/compose path.)*
- [x] **AC-6** Search returns only leaf folders (`childFolderCount == 0`) whose leaf display name or
  full path matches the pattern. *(CI-verifiable: unit tests over a fixture folder tree.)*
- [x] **AC-7** Wildcard matching supports `*` and `?`, is case-insensitive, matches against both leaf
  name and full path, applies NFC normalization, treats `\*`/`\?` as literals, treats a lone `*` as
  match-all, and an empty pattern as no-match. *(CI-verifiable: unit and property-based tests on
  `WildcardMatcher`.)*
- [x] **AC-8** The folder tree is loaded once when the container opens; per-keystroke filtering issues
  no Graph call. *(CI-verifiable: test that the folder query is invoked once per open and not per
  keystroke.)*
- [x] **AC-9** The container exposes a documented, versioned input contract for classifier results and
  recent choices; adding a live source requires supplying a non-empty array to the existing
  `ResultListComposer.compose` parameter with no change to the composer signature or container.
  *(CI-verifiable: contract/type test asserting the signature and ordering; documentation present in
  this spec.)*
- [x] **AC-10** Selecting a result issues a single server-side filing command carrying the message
  REST id and destination folder id; no Graph write executes on the client. *(CI-verifiable:
  architecture-boundary test that client modules do not perform Graph writes; contract test on the
  filing endpoint request shape.)*
- [ ] **AC-11** The message REST id is resolved per platform: already-REST `item.itemId` on mobile
  (no `convertToRestId`), converted via `convertToRestId` on non-mobile. *(CI-verifiable: unit test of
  the host-detection branch. Manual: real-device confirmation that the id is accepted by Graph.)*
- [ ] **AC-12** Selecting a result moves the opened message to the selected Outlook folder via Graph
  `POST /me/messages/{id}/move`. *(CI-verifiable: contract test against the Graph move request shape.
  Manual: end-to-end move on a real client.)*
- [ ] **AC-13** Selecting a result saves the message's non-inline file attachments to the mirrored
  OneDrive folder beneath the persisted Archive root, creating intermediate OneDrive folders as
  needed. Inline body-embedded content is skipped (OD-4). *(CI-verifiable: integration test with a
  faked Graph drive adapter, a unit test of the inline-vs-file attachment filter, and a unit test of
  `OutlookToOneDrivePath`. Manual: real OneDrive verification.)*
- [x] **AC-14** The Outlook-to-OneDrive path mapping strips the leading `Archive` segment and produces
  the relative OneDrive path beneath the mapped Archive root; the OneDrive structure mirrors the
  Outlook structure beneath `Archive`. The mailbox `Archive` folder is identified by `displayName`
  `Archive` under the mailbox root, not the Graph well-known `archive` name (OD-5). *(CI-verifiable:
  unit/property tests on `OutlookToOneDrivePath`; unit test of the display-name-based Archive root
  resolution.)*
- [x] **AC-15** OneDrive subfolder creation beneath the mapped Archive root is create-if-missing (no
  duplicate folders on repeat runs); attachment upload uses simple PUT at or below 10 MiB and an
  upload session above 10 MiB. *(CI-verifiable: integration test over the faked drive adapter covering
  create, conflict, and the size threshold.)*
- [x] **AC-16** A message with no non-inline file attachments performs no OneDrive writes, proceeds to
  the move, and reports success. *(CI-verifiable: integration test with an attachment-free message.)*
- [x] **AC-17** The filing command executes attachments-first, move-last: OneDrive folder resolution
  and attachment upload complete before the message is moved, and the move is the final step
  (OD-7). *(CI-verifiable: integration test asserting the move is not invoked until OneDrive folder
  resolution and upload have succeeded.)*
- [x] **AC-18** When an earlier step fails (OneDrive folder resolution or attachment upload), the
  message is not moved, the command returns a clear error, and a retry is idempotent: re-running
  resolves the same folder, does not create duplicate folders or files, and then moves the message
  (OD-7). *(CI-verifiable: integration test injecting an OneDrive failure before the move, asserting
  the message stays in place and that a subsequent retry succeeds without duplicates.)*
- [ ] **AC-19** Manifest and AAD scope changes are present: `manifest.json` adds
  `MailboxItem.ReadWrite.User`; `manifest.xml` uses `ReadWriteMailbox`; AAD delegated scopes include
  `Mail.ReadWrite`, `Files.ReadWrite`, and `Mail.ReadBasic`. *(CI-verifiable: manifest assertion.
  Manual: consent/token verification against the registered app.)*
- [ ] **AC-20** Behavior is verified on both Outlook desktop and Outlook mobile form factors.
  *(Manual: device/host verification on both form factors.)*
- [ ] **AC-21** On the first filing for which no stored Archive-root mapping exists, the user is
  presented with a way to either select an existing OneDrive folder or create a new OneDrive folder
  to serve as the Archive root. The OneDrive Archive root is not auto-named or auto-created by
  convention (OD-6). *(CI-verifiable: unit/contract test that, given no stored mapping, the filing
  flow surfaces the select-or-create step and does not auto-create a folder named `Archive`. Manual:
  real-host confirmation of the picker and the create path.)*
- [x] **AC-22** The chosen mapping (mailbox `Archive` folder associated with the selected or created
  OneDrive folder/drive-item id) is persisted through the settings-store abstraction
  (`IUserSettingsRepository`) and survives across sessions (OD-6). *(CI-verifiable: unit/integration
  test writing the mapping via the settings-store abstraction and reading it back through a new
  instance/fake store.)*
- [x] **AC-23** On subsequent filings, the stored Archive-root mapping is reused without re-prompting
  the user; subfolders beneath the mapped Archive root remain create-if-missing so the OneDrive
  structure continues to mirror the Outlook structure beneath `Archive` (OD-6). *(CI-verifiable:
  integration test that a second filing with a stored mapping issues no picker step and creates only
  the missing subfolders.)*
- [ ] **AC-24** The Archive-root picker is presented per host: a desktop Office Dialog (or in-pane
  step) on desktop and an inline full-screen task-pane step on Outlook mobile, with identical
  select-or-create capability and identical persisted-mapping result across both presentations
  (OD-6). *(CI-verifiable: host-detection branch unit test and shared-flow test. Manual: device/host
  verification of the picker presentation on desktop and mobile.)*

### Acceptance-criteria verification summary

- CI-verifiable (fully or partially automatable): AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8,
  AC-9, AC-10, AC-11, AC-12, AC-13, AC-14, AC-15, AC-16, AC-17, AC-18, AC-19, AC-21, AC-22, AC-23,
  AC-24.
- Require manual device/host verification (cannot be fully closed by CI): AC-2, AC-3, AC-11, AC-12,
  AC-13, AC-19, AC-20, AC-21, AC-24.

## Constraints & Risks

- **No-COM architecture (HC-6).** Mailbox/folder/drive access only via Office.js or Microsoft Graph;
  business behavior in the backend or host-neutral modules; UI as web UI. See
  `.claude/rules/architecture-boundaries.md` rules 7, 8, 9.
- **Office Dialog API not on mobile (HC-1).** The mobile presentation is the inline full-screen task
  pane, not a dialog.
- **Unified manifest not on mobile (HC-2).** The parallel `manifest.xml` with `<MobileFormFactor>` is
  required for the mobile command.
- **`convertToRestId` unsupported on iOS (HC-3).** The mobile `item.itemId` is already REST-formatted.
- **`getAttachmentContentAsync` requires Mailbox 1.8, above the mobile ceiling (HC-5).** Attachment
  content is fetched server-side via Graph on all platforms.
- **Folder-tree enumeration over large trees.** Mitigated by one-time load on open plus in-memory
  per-keystroke filtering.
- **Token acquisition on mobile (OD-8, resolved).** Nested App Authentication (NAA) is the primary
  client-side token-acquisition path. When NAA is unavailable on the host, the add-in falls back to
  backend on-behalf-of via the `getAccessTokenAsync` SSO token. All privileged operations remain
  server-side regardless of which client token path is used.

## Definition of Done

- [ ] Acceptance criteria documented and mapped to tests or manual verification
- [ ] Behavior matches acceptance criteria in all documented environments (desktop and mobile)
- [ ] Tests added/updated (unit, property-based for pure functions, contract, integration as applicable)
- [ ] Edge cases and error/partial-failure handling covered by tests
- [ ] Manifest and AAD scope changes applied
- [ ] Host-neutral modules implemented with documented contracts
- [ ] Docs updated (this spec, user-story, feature-document, README links)
- [ ] Telemetry/logging added for the filing workflow
- [ ] Toolchain pass completed (format → lint → type-check → arch → test → contract → integration)

## Resolved Decisions

The open decisions carried from the research (OD-1 through OD-10) are recorded here with their
resolutions so this document is self-contained. OD-1, OD-2, and OD-3 were resolved in earlier
iterations of this spec and are reflected in the Behavior and Architecture sections (desktop dialog +
mobile inline pane; client-side per-keystroke filtering of a once-loaded list; per-container-open
cache). The remaining decisions are resolved as follows.

- **OD-4 — Attachment save scope (resolved).** Save all non-inline file attachments; skip inline
  body-embedded content. Governs AC-13. No user attachment-selection UI this iteration.
- **OD-5 — Archive root identification (resolved).** The mailbox `Archive` root is identified by the
  mail folder whose `displayName` is `Archive` under the mailbox root, not the Graph well-known
  mailbox name `archive`. Governs AC-14.
- **OD-6 — OneDrive Archive-root mapping (resolved; scope expanded).** The OneDrive Archive root is
  not auto-named or auto-created by convention. On first use, when no stored mapping exists, the user
  selects an existing OneDrive folder or creates a new one to serve as the Archive root. The mapping
  (mailbox `Archive` folder → chosen OneDrive folder/drive-item id) is persisted in user settings via
  the existing settings-store abstraction (`IUserSettingsRepository` in `TaskMaster.Application`) and
  reused on subsequent filings without re-prompting. Subfolders beneath the mapped Archive root remain
  create-if-missing. Governs AC-21, AC-22, AC-23, AC-24 (new) and affects AC-13, AC-14, AC-15.
- **OD-7 — Partial-failure behavior (resolved).** Server-side filing executes attachments-first,
  move-last: (1) resolve or create the mirrored OneDrive folder, (2) upload attachments, (3) move the
  message. If an earlier step fails, the message stays in place and the operation returns a clear
  error; retries are safe (idempotent). Governs AC-17 and AC-18.
- **OD-8 — Mobile token acquisition (resolved).** NAA is the primary token path; the fallback is
  backend on-behalf-of via the `getAccessTokenAsync` SSO token. All privileged operations remain
  server-side. Reflected in Constraints & Risks.
- **OD-9 — Within-search ordering (resolved).** Ordering is deterministic: exact and prefix matches
  first, then alphabetical by full folder path. Search results are prepended ahead of the future
  classifier and recent-choices sources. Reflected in the Results-list composition and search
  behavior.
- **OD-10 — Quality tier (resolved).** Tier **T2** for the filing command and the Graph/OneDrive
  adapter (a misfile is recoverable, not silent data loss). The host-neutral pure modules still
  require >= 1 property-based test per pure function. The new projects/modules must be added to
  `quality-tiers.yml` at the appropriate tier during plan execution. Reflected in the Quality tier
  section.

## Seeded Test Conditions (from potential)

- [ ] Unit coverage: host-neutral wildcard matcher (positive, negative, wildcard, edge cases)
- [ ] Result-list composition/ordering with multiple sources including empty sources
- [ ] Contract tests at the Office.js / Microsoft Graph boundary (dialog messaging, move, drive folder
  create + upload)
- [ ] Integration scenarios: move + mirrored attachment save; nested subfolder mirroring; message
  with no attachments; first-use Archive-root select-or-create and mapping persistence; reuse of a
  stored mapping without re-prompt; pre-move OneDrive failure leaves the message in place and a retry
  succeeds without duplicates
- [ ] Form-factor verification on desktop and mobile
