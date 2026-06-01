# ifile-message-filing-dialog (Issue #43)

- Date captured: 2026-05-31
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/ifile-message-filing-dialog/ (Issue #43)
- Promotion type: feature
- Work mode: full-feature
- Target platforms: Outlook desktop and Outlook mobile (parity)

- Issue: #43
- Issue URL: https://github.com/drmoisan/TMW/issues/43
- Last Updated: 2026-06-01
- Work Mode: full-feature

## Problem / Why

Filing an opened email into the correct folder is a frequent, high-friction action. Users
need a fast way to choose a destination folder from a large folder tree and have the message
filed there, with any attachments archived in a parallel OneDrive location. The destination
list will eventually be assembled from multiple ranked sources (a classifier, the user's
recent choices, and on-demand search), so the entry surface must be designed to accept those
sources from the outset even though only search is implemented in this iteration.

## Proposed Behavior

1. When an email is opened (message read surface), an `iFile` command is the first available
   button in the command list, on both desktop and mobile.
2. Activating `iFile` opens a dialog container. The dialog contains a search textbox and a
   results list.
3. The results list is composed from multiple ordered input sources. In this iteration:
   - Classifier results: not yet built; the container exposes the input contract but receives
     nothing.
   - Recent choices: not yet built; the container exposes the input contract but receives
     nothing.
   - Search results: implemented in this iteration.
4. While the search textbox is empty, the list shows no search results.
5. When the user types, search results are prepended to the list and update as input changes.
6. Search returns leaf folders of the mailbox folder tree whose path/name matches the entered
   pattern. Matching must support wildcards. Search should return quickly.
7. Selecting a result:
   - Moves the opened message to the selected Outlook folder.
   - Saves any attachments to a OneDrive directory. The Outlook root `Archive` folder maps to
     a OneDrive `Archive` folder; the destination subfolder is created on OneDrive if needed so
     the OneDrive structure mirrors the Outlook folder structure beneath `Archive`.

## Acceptance Criteria (early draft)

- [ ] `iFile` appears as the first command on the message-read surface on desktop and mobile.
- [ ] Activating `iFile` opens a dialog with a search textbox and a results list.
- [ ] With an empty search textbox, the results list contains no search-sourced results.
- [ ] Typing in the textbox prepends matching folder-leaf results to the list; clearing it
      removes them.
- [ ] Search matches leaf folders of the mailbox folder tree by pattern and supports wildcards.
- [ ] The dialog container exposes a documented input contract for classifier results and
      recent choices (no live data this iteration) without code changes required to add them.
- [ ] Selecting a result moves the opened message to that Outlook folder.
- [ ] Selecting a result saves the message attachments to the mirrored OneDrive folder under
      `Archive`, creating intermediate OneDrive folders as needed.
- [ ] Behavior is verified on desktop and mobile form factors.

## Constraints & Risks

- No-COM architecture: mailbox/folder/drive access only via Office.js or Microsoft Graph;
  business logic in host-neutral modules; UI as web UI (see `.claude/rules/architecture-boundaries.md`).
- Mobile manifest: unified manifest.json is not currently supported on Outlook mobile; mobile
  support has historically required a parallel manifest.xml (see Issue #35 research). The exact
  mechanism for surfacing a command + dialog on mobile must be confirmed against current docs.
- Office.js dialog vs. Graph drive operations: API surface, version/capability requirements,
  and host differences must be confirmed against current Microsoft documentation.
- Wildcard search over potentially large folder trees: performance and enumeration strategy.
- Idempotency of move + attachment save (partial-failure handling, duplicate runs).

## Test Conditions to Consider

- [ ] Unit coverage: host-neutral wildcard matcher (positive, negative, wildcard, edge cases);
      result-list composition/ordering with multiple sources including empty sources.
- [ ] Contract tests at the Office.js / Microsoft Graph boundary (dialog messaging, move,
      drive folder create + upload).
- [ ] Integration scenarios: move + mirrored attachment save; missing `Archive`; nested
      subfolder mirroring; message with no attachments.
- [ ] Form-factor verification on desktop and mobile.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/ifile-message-filing-dialog/` folder from the template