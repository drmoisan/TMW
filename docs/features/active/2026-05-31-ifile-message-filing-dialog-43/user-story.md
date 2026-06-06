# `ifile-message-filing-dialog` — User Story

- Issue: #43
- Issue URL: https://github.com/drmoisan/TMW/issues/43
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-31
- Work Mode: full-feature

## Story Statement

- As an Outlook user reading an email, I want a fast iFile command that is the first button on the
  message-read surface, so that I can begin filing the message without hunting through menus.
- As an Outlook user, I want to search my mailbox folder tree by typing a pattern (including
  wildcards) and see matching leaf folders update as I type, so that I can find the correct
  destination in a large folder tree quickly.
- As an Outlook user, I want selecting a destination to move the message to that folder and save its
  attachments to a matching OneDrive location under `Archive`, so that my mail and my archived files
  stay organized in parallel without manual copying.
- As an Outlook user filing for the first time, I want to choose which OneDrive folder serves as my
  Archive root — selecting an existing folder or creating a new one — and have that choice remembered,
  so that later filings reuse it without asking me again.
- As an Outlook mobile user, I want the same iFile search and filing experience on my phone as on the
  desktop, so that I can file messages wherever I read them.
- As the product owner, I want the destination list built behind a documented input contract for
  classifier results and recent choices, so that those ranked sources can be added later without
  reworking the search container.

## Problem / Why

Filing an opened email into the correct folder is a frequent, high-friction action. Users need a fast
way to choose a destination folder from a large folder tree and have the message filed there, with any
attachments archived in a parallel OneDrive location. The destination list will eventually be
assembled from multiple ranked sources (a classifier, the user's recent choices, and on-demand
search), so the entry surface is designed to accept those sources from the outset even though only
search is implemented in this iteration.

## Personas & Scenarios

### Persona: Desktop knowledge worker

- Who: An information worker who reads and triages email throughout the day on Outlook for Windows
  or the web, with a deep folder tree built up over years.
- Cares about: speed of filing, putting messages in the correct folder, keeping attachments
  organized.
- Constraints: a large folder tree where scrolling to find a destination is slow; cannot install
  desktop COM add-ins under current architecture.
- Goals and frustrations: wants to file in a few keystrokes; frustrated by repetitive drag-and-drop
  and by attachments scattered outside a predictable location.
- Context and motivations: files dozens of messages per day; values consistency between mail folders
  and archived files.

#### Scenario: File a message with attachments on desktop

1. The user opens an email that has two file attachments.
2. The user activates `iFile`, the first button on the message-read surface. An Office Dialog opens
   with a search textbox and an empty results list.
3. The user types `*acme*`. Matching leaf folders (for example `Archive/Clients/Acme`) appear and
   update as the pattern changes.
4. The user selects `Archive/Clients/Acme`.
5. The two attachments are saved to the mapped OneDrive Archive root under `Clients/Acme` (with
   intermediate OneDrive folders created if they did not exist), and then the message is moved to the
   Outlook folder. Attachments are saved before the move, so if the OneDrive step fails the message
   stays in place.
6. The user expects a clear success indication, and an explicit error if any part fails; on a failure
   before the move the message remains where it was and retrying is safe.

#### Scenario: First-time setup of the OneDrive Archive root

1. The user files a message for the first time and no OneDrive Archive root has been chosen yet.
2. iFile presents a way to either select an existing OneDrive folder or create a new OneDrive folder
   to serve as the Archive root (it does not silently auto-create a folder named `Archive`).
3. The user picks or creates a folder.
4. The choice is saved. On every later filing, iFile reuses the saved Archive root without asking
   again, and creates any missing subfolders beneath it to mirror the Outlook structure under
   `Archive`.

### Persona: Mobile triager

- Who: The same kind of user working from Outlook on iOS or Android between meetings.
- Cares about: parity with the desktop experience; not losing functionality on mobile.
- Constraints: the Office Dialog API is unavailable on mobile; smaller screen.
- Goals and frustrations: wants to file on the phone with the same search behavior as on desktop;
  frustrated when mobile add-ins behave differently from desktop.

#### Scenario: File a message on mobile

1. The user opens an email in Outlook mobile.
2. The user taps `iFile`, the first command on the message-read surface. The same search UI appears
   inline in the full-screen task pane (not a dialog).
3. The user types a pattern and selects a matching leaf folder.
4. Attachments are saved to the mirrored OneDrive location and then the message is moved, identically
   to desktop. If no Archive root has been chosen yet, the select-or-create step appears inline in the
   full-screen task pane rather than in a desktop dialog.

### Persona: Product owner (extensibility stakeholder)

- Who: The owner planning later iterations that add classifier-ranked and recent-choice destinations.
- Cares about: being able to add ranked sources without reworking the search container.
- Goals: a documented, stable input contract for the results list this iteration.

#### Scenario: Add a ranked source later

1. In a future iteration, a classifier produces ranked destination folders.
2. The new source supplies a non-empty array to the existing `ResultListComposer.compose` parameter.
3. The classifier results appear ahead of search results in the documented order, with no change to
   the composer signature, the container, or the search path.

## Acceptance Criteria

These mirror the numbered acceptance criteria in `spec.md` from the user's perspective. The spec is
authoritative for CI-verifiable vs. manual verification.

- [ ] `iFile` appears as the first command on the message-read surface on both desktop and mobile.
- [ ] On desktop, activating `iFile` opens an Office Dialog with a search textbox and a results list.
- [ ] On mobile, activating `iFile` opens the same search UI inline in the full-screen task pane, not
  a dialog, using one shared UI/logic implementation.
- [x] With an empty search textbox, the results list contains no search-sourced results.
- [x] Typing a pattern prepends matching folder-leaf results to the list and updates them live;
  clearing the textbox removes them.
- [x] Search returns only leaf folders of the mailbox folder tree whose name or path matches the
  pattern.
- [x] Search supports glob wildcards (`*`, `?`), is case-insensitive, and matches against both leaf
  name and full path.
- [x] Search returns quickly: the folder tree loads once when the container opens and filtering is
  in-memory per keystroke.
- [x] The container exposes a documented input contract for classifier results and recent choices (no
  live data this iteration) so they can be added later without reworking the container.
- [ ] Selecting a result saves the message's non-inline file attachments to the mirrored OneDrive
  folder beneath the chosen Archive root, creating intermediate OneDrive folders as needed, and then
  moves the message to the Outlook folder (attachments first, move last).
- [x] A message with no attachments is filed (moved) successfully with no OneDrive writes.
- [x] If the OneDrive step fails before the move, the message stays in its original folder, the
  failure is reported, and retrying is safe (no duplicate folders or files).
- [ ] On first use, iFile lets the user select an existing OneDrive folder or create a new one as the
  Archive root, rather than auto-creating one by convention.
- [x] The chosen Archive root is remembered across sessions and reused on later filings without
  re-prompting.
- [ ] The Archive-root picker appears as a desktop dialog (or in-pane step) on desktop and inline in
  the full-screen task pane on mobile.
- [x] Failures are reported clearly to the user rather than failing silently.
- [ ] The experience is verified on both Outlook desktop and Outlook mobile form factors.

## Non-Goals

- Building the classifier result source as a live data producer (only its input contract is in scope).
- Building the recent-choices result source as a live data producer (only its input contract is in
  scope).
- Match-quality ranking of search results beyond the deterministic ordering (exact/prefix first, then
  alphabetical by full folder path).
- Background, scheduled, or bulk filing; iFile acts only on the currently opened message.
- User selection of which attachments to save; iFile saves all non-inline file attachments and skips
  inline body-embedded content.
- Editing or relocating the OneDrive Archive-root mapping after first use; this iteration persists the
  first-use choice and reuses it without a settings-management UI.
