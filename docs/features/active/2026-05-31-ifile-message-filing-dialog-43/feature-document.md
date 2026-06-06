# iFile Message-Filing — Feature Document

- **Issue:** #43
- **Issue URL:** https://github.com/drmoisan/TMW/issues/43
- **Owner:** drmoisan
- **Status:** Draft
- **Last Updated:** 2026-05-31
- **Work Mode:** full-feature
- **Target platforms:** Outlook desktop and Outlook mobile (parity)

This consolidated feature document references the companion artifacts:

- Spec: `spec.md`
- User story: `user-story.md`
- Promoted issue: `issue.md`
- Research (authoritative for constraints):
  `artifacts/research/2026-05-31-ifile-message-filing-dialog-research-43.md`

## Summary

iFile adds a command on the Outlook message-read surface that opens a search container for selecting a
destination folder. Selecting a destination saves the message's non-inline file attachments to a
parallel OneDrive location beneath a user-chosen `Archive` root and then moves the opened message to
that Outlook folder (attachments first, move last). On first use the user selects or creates the
OneDrive folder that serves as the Archive root, and that mapping is persisted and reused. The
destination list is built behind a documented, ordered input contract (classifier results, recent
choices, search results); only the search source is implemented this iteration. The command and search
UI work on both Outlook desktop and Outlook mobile from a single shared implementation.

## Motivation

Filing an opened email into the correct folder is a frequent, high-friction action. Users need a fast
way to choose a destination from a large folder tree, with attachments archived in a predictable
parallel OneDrive location. The entry surface is designed for additional ranked sources from the
outset so the classifier and recent-choices sources can be added later without rework.

## Feature behavior

1. The `iFile` command is the first button on the message-read surface on both desktop and mobile
   (manifest declaration order).
2. Activating `iFile` presents a search container with a search textbox and a results list:
   - Desktop: an Office Dialog (`displayDialogAsync`).
   - Mobile: the same search UI inline in the full-screen task pane (the Office Dialog API is
     unsupported on mobile, HC-1). Both presentations share one UI/logic implementation.
3. The results list is composed from ordered sources: classifier results, recent choices, then search
   results. Only search results are populated this iteration; the other sources are wired to the
   contract but receive no data.
4. While the search textbox is empty, the list contains no search-sourced results.
5. Typing prepends live folder-leaf matches; clearing the textbox removes them.
6. Search returns leaf folders whose name/path matches the pattern with glob wildcards (`*`, `?`),
   case-insensitive, against both leaf name and full path. The folder tree loads once on open and is
   filtered in memory per keystroke.
7. Selecting a result saves the message's non-inline file attachments to the mirrored OneDrive
   structure beneath the chosen Archive root (creating intermediate OneDrive folders as needed) and
   then moves the message to the chosen Outlook folder. The command executes attachments-first,
   move-last, so a failure before the move leaves the message in place (OD-7).
8. On the first filing for which no Archive-root mapping exists, the user selects an existing OneDrive
   folder or creates a new one to serve as the Archive root. The mapping (mailbox `Archive` folder →
   chosen OneDrive folder/drive-item id) is persisted via the settings-store abstraction
   (`IUserSettingsRepository` in `TaskMaster.Application`) and reused on later filings without
   re-prompting (OD-6). The picker is presented as a desktop dialog (or in-pane step) on desktop and
   inline in the full-screen task pane on mobile.

## Architecture (client/server split)

Per No-COM architecture rule 8 (HC-6), privileged operations run server-side.

- **Client (dialog/task-pane HTML + TypeScript):** render search UI; read `item.itemId` and
  `item.attachments` metadata via Office.js; resolve the message REST id per platform (already-REST on
  mobile, `convertToRestId` on non-mobile, HC-3); run pure host-neutral wildcard matching and
  result-list composition; call two backend endpoints.
- **Server (`TaskMaster.Application` command + `TaskMaster.Infrastructure` Graph adapter):** enumerate
  the folder tree via Graph (`/me/mailFolders` + recursive `/childFolders`); on filing, run
  attachments-first, move-last — resolve or create the mirrored OneDrive folders beneath the persisted
  Archive root, fetch attachment content via Graph, upload attachments, then move the message
  (`POST /me/messages/{id}/move`) behind the existing OBO token flow. Read and persist the OneDrive
  Archive-root mapping through the settings-store abstraction (`IUserSettingsRepository`). The client
  passes the message REST id, the chosen destination folder id, and (on first use) the chosen OneDrive
  Archive-root drive-item id.

## Host-neutral modules

| Module | Language | Contract |
|---|---|---|
| `WildcardMatcher` | TypeScript | `match(pattern, target): boolean` (glob, case-insensitive, NFC, `\*`/`\?` literals) |
| `ResultListComposer` | TypeScript | `compose(classifierResults, recentChoices, searchResults): FolderResult[]` (ordered, empty sources contribute nothing) |
| `FolderPathBuilder` | TypeScript | `buildPath(folderMap, leafId): string` (path from parent chain) |
| `OutlookToOneDrivePath` | C# | `Map(outlookFolderPath): string` (strips `Archive` prefix, returns relative OneDrive path) |

The result-list input contract (`FolderResult` shape and the ordered `compose` parameters) is the
extensibility surface: adding a live classifier or recent-choices source means supplying a non-empty
array to the existing parameter with no signature, container, or search-path change.

## Manifest and scope changes

- `manifest.json`: add `MailboxItem.ReadWrite.User`.
- `manifest.xml`: `ReadItem` → `ReadWriteMailbox`.
- AAD delegated scopes: add `Mail.ReadWrite`, `Files.ReadWrite`; ensure `Mail.ReadBasic`.
- Extend `validDomains` / `<AppDomains>` to the production HTTPS domain at deploy time.

These changes are specified here and applied during plan execution, not during document authoring.

## Error and partial-failure handling

- The command runs attachments-first, move-last (OD-7, resolved): resolve/create the OneDrive folder,
  upload attachments, then move the message. A failure before the move leaves the message in its
  original folder and returns a clear error; this removes the "move succeeded but OneDrive failed"
  inconsistent state by construction.
- Retries are safe (idempotent): create-if-missing on folders and a defined upload conflict behavior
  mean a re-run resolves the same folder, reuses or replaces the same files, and then moves the
  message without producing duplicates.
- A message with no non-inline file attachments performs no OneDrive writes and proceeds to the move.
- Errors are reported and logged, never silently swallowed.

## Scope boundaries

- In scope: command placement, dual-presentation search container, the result-list input contract,
  wildcard folder search, the server-side filing command (attachments-first OneDrive mirroring + move),
  the first-use OneDrive Archive-root select-or-create flow with persisted mapping, the host-neutral
  modules, and the manifest/scope changes.
- Out of scope: live classifier and recent-choices data sources (contract only), match-quality
  ranking beyond the deterministic order (exact/prefix first, then alphabetical by path), delta sync,
  background/bulk filing, user attachment selection (all non-inline file attachments are saved, inline
  content skipped), and editing/relocating the Archive-root mapping after first use.

## Acceptance criteria

The authoritative, individually verifiable acceptance criteria are in `spec.md` (AC-1 through AC-24),
with each marked CI-verifiable or manual. AC-21 through AC-24 cover the OD-6 first-use Archive-root
select-or-create flow, mapping persistence, reuse without re-prompt, and the per-host picker
presentation. `user-story.md` restates them from the user's perspective. Criteria requiring manual
device/host verification: AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24.

## Quality tier and testing

- Tier is **T2** (OD-10, resolved) for the filing command and the Graph/OneDrive adapter; a misfile is
  recoverable rather than silent data loss. The new projects/modules must be added to
  `quality-tiers.yml` at the appropriate tier during plan execution (not in document authoring).
- Coverage thresholds are uniform: line >= 85%, branch >= 75%.
- Property-based tests are required for the host-neutral pure functions (>= 1 per pure function),
  which applies at both T1 and T2. Mutation score is trend-only at T2 (the >= 75% gate applies at T1).
  Contract tests are required at the Office.js and Microsoft Graph boundaries. Integration tests cover
  attachments-first mirrored save + move, nested mirroring, attachment-free messages, the first-use
  Archive-root select-or-create + mapping persistence, reuse without re-prompt, and a pre-move OneDrive
  failure that leaves the message in place with a safe retry.

## Resolved decisions

All previously open decisions are resolved; see `spec.md` Resolved Decisions for the full record.

- OD-4: save all non-inline file attachments; skip inline body-embedded content.
- OD-5: identify the mailbox `Archive` root by `displayName` `Archive` under the mailbox root, not the
  Graph well-known `archive` name.
- OD-6 (scope expanded): no auto-create by convention; on first use the user selects an existing
  OneDrive folder or creates a new one as the Archive root, the mapping is persisted via
  `IUserSettingsRepository`, and it is reused without re-prompting. Subfolders remain create-if-missing.
  Adds AC-21 through AC-24.
- OD-7: server-side filing runs attachments-first, move-last; a failure before the move leaves the
  message in place and retries are idempotent. Governs AC-17 and AC-18.
- OD-8: NAA primary; fall back to backend on-behalf-of via the `getAccessTokenAsync` SSO token; all
  privileged operations remain server-side.
- OD-9: deterministic search ordering — exact/prefix matches first, then alphabetical by full folder
  path; search results prepended ahead of the future classifier and recent-choices sources.
- OD-10: tier T2 for the filing command and the Graph/OneDrive adapter; pure modules keep the >= 1
  property-test-per-function obligation; new projects/modules added to `quality-tiers.yml` in plan
  execution.

## Constraints (from research, authoritative)

- HC-1: Office Dialog API not supported on Outlook mobile; mobile uses the inline task pane.
- HC-2: Unified `manifest.json` not supported on mobile; `manifest.xml` `<MobileFormFactor>` required.
- HC-3: `convertToRestId` unsupported on iOS; mobile `item.itemId` is already REST-formatted.
- HC-5: `getAttachmentContentAsync` requires Mailbox 1.8 (above mobile ceiling); attachment content is
  fetched server-side via Graph.
- HC-6: No-COM rule 8 requires server-side execution of business behavior.

## Implemented module layout

The feature is implemented as a dual-presentation (desktop Office Dialog + mobile inline task pane)
client over a single shared, host-neutral logic core, plus a server-side filing command and Graph
adapters. A runtime host check (`selectPresentation`) chooses the presentation; the search behavior,
result-list composition, and selection handling are identical across both.

### Client (TypeScript) — `src/taskpane/ifile/`

- Pure host-neutral modules (T2; >= 1 fast-check property test each where pure):
  `wildcard-matcher.ts` (glob `*`/`?`, case-insensitive, NFC, `\*`/`\?` escapes),
  `result-list-composer.ts` (ordered classifier→recent→search composition),
  `search-result-ordering.ts` (OD-9 exact/prefix-then-alphabetical), `folder-path-builder.ts`
  (parent-chain path), `folder-search.ts` (leaf filter + match + order), `folder-result.ts` (the
  versioned `FolderResult` input contract), `message-id-resolver.ts` (HC-3 mobile branch), and
  `host-presentation.ts` (dialog vs. inline).
- Presentation-agnostic controller and picker: `ifile-controller.ts` (once-loaded leaf list,
  per-keystroke in-memory filtering — no Graph call per keystroke), `archive-root-picker.ts`
  (first-use select-or-create).
- Host-wiring modules (the only client modules importing Office.js / the generated API client):
  `dialog-host.ts` (desktop `displayDialogAsync` + `messageParent` round-trip), `inline-host.ts`
  (mobile inline rendering), `ifile-api-client.ts` (typed calls to the backend), and the
  `ifile.ts` bootstrap entry. Shared bundle entry: `ifile.html` (webpack `ifile` entry).

### Server (.NET)

- `TaskMaster.Application/IFile/` (T2): `FileMessageCommand` + `FileMessageCommandHandler`
  (attachments-first, move-last orchestration with telemetry), `FileMessageResult`/`FileMessageOutcome`,
  pure helpers `OutlookToOneDrivePath`, `AttachmentFilter`, `ArchiveRootResolver`, and the adapter
  interfaces `IFolderTreeReader`, `IMessageMover`, `IAttachmentSource`, `IOneDriveFolderWriter`.
- `TaskMaster.Infrastructure/IFile/` (T3 adapter glue): `GraphFolderTreeReader`, `GraphMessageMover`,
  `GraphAttachmentSource`, `GraphOneDriveFolderWriter` over the OBO-configured Graph client.
- `TaskMaster.Api` host seam: `GET /api/ifile/folders` and `POST /api/ifile/file` (dispatch-only,
  behind OBO auth), surfaced in `artifacts/openapi/current.json` and the generated
  `src/api-client/v1.ts`.

The Archive-root mapping is persisted on `UserSettings.ArchiveRootDriveItemId` through the existing
`IUserSettingsRepository` abstraction and reused without re-prompting (OD-6).
