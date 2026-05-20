# P6-T2 / P6-T3 — Sideload, Launch, and Render on Outlook iOS

- Timestamp: 2026-05-20T09-45 (device local); recorded 2026-05-20
- Issue: #35
- Device: iPhone (Outlook for iOS), status bar 8:42, battery 97%
- Hosting endpoint: `https://3zmjztsc-3000.use.devtunnels.ms/` (see `hosting-endpoint.md`)

## Procedure

1. Sideloaded the built `dist/manifest.xml` (tunnel-host URLs) via Outlook on the web ("My add-ins" → "Add a custom add-in" → "Add from file").
2. Signed into Outlook on the iPhone with the same account; the add-in synced to the device.
3. Opened a message in read mode, tapped the "More options" (•••) menu, and selected TaskMaster. The full-screen task pane opened.

## Evidence

- `evidence/screenshots/more-options-menu.2026-05-20T09-45.jpeg` — original capture (content shows the opened pane).
- `evidence/screenshots/taskpane-render.2026-05-20T09-45.jpeg` — same image, named for the render criterion.

## What the screenshot demonstrates

- **P6-T2 (add-in present and launchable):** The TaskMaster pane opened on the device, which requires the add-in to have appeared in the iOS "More options" menu and been launchable. The literal menu screenshot was not captured separately; the opened pane is stronger, superseding evidence that the add-in is installed, synced, and reachable on iOS.
- **P6-T3 (renders usably on iPhone viewport):** The pane renders full-screen with all controls visible and unclipped — header "TaskMaster for Outlook" with an X, the TaskMaster logo/title, the "Selected message" section, and the Classify / Confirm / Reject / Close controls. Header footprint is acceptable; ample free space below; no horizontal clipping.
- **Office.js read APIs functioning on iOS:** The pane displays live selected-message context — `Subject: Re: Gross to Net Call Follow Ups.` and `From: Dan Moisan <dmoisan@realgoodfoods.com>` — confirming `Office.context.mailbox.item.subject` and `item.from` resolve on the device.
- **Added Close button (P5-T3) present:** The `Close` button (wired to `Office.context.ui.closeContainer()`) renders.

## P6-T4 — ItemChanged on navigation (verified 2026-05-20)

Navigating between two different selected messages re-rendered the pane's Subject/From context, confirming the `Office.EventType.ItemChanged` handler fires on iOS:

- `evidence/screenshots/itemchanged-before.2026-05-20T09-45.jpeg` — `Subject: Test 2`, `From: Dan Moisan <dan@danmoisan.org>`.
- `evidence/screenshots/itemchanged-after.2026-05-20T09-45.jpeg` — `Subject: Test 1`, `From: Dan Moisan <dan@danmoisan.org>`.

The Subject changes between the two captures within the same pane session, demonstrating live re-render on message change. Note: device capture timestamps are inverted relative to the before/after labels (the "after" file was taken at 8:50, "before" at 8:51); this does not affect the conclusion, which only requires that two distinct messages render distinct context.

## P6-T5 — N/A (user decision 2026-05-20, "Option A")

P6-T5 ("classification succeeds over HTTPS") cannot be satisfied within issue #35's scope because the classify/feedback workflow is not wired into the product on any platform:

- `src/taskpane/taskpane.html` defines `classify-btn` / `confirm-btn` / `reject-btn`, but `src/taskpane/taskpane.ts` attaches no click handler to `classify-btn` (`getRenderDom()` collects only status/subject/from; `Office.onReady` wires only `ItemChanged` and the Close button).
- `ClassifierClient` is instantiated only in its unit test, never in product code; the `renderClassifying` / `renderClassificationResult` helpers are never called from product wiring.
- `ClassifierClient.classify` requires a bearer token; nothing in the codebase obtains one.

Tapping Classify is therefore inert on desktop and mobile alike — mobile parity holds. Issue #35 is mobile enablement with no `src` logic changes, so this pre-existing functional gap is out of scope and is tracked separately as GitHub issue #37 (wire-classify-feedback-workflow). The HTTPS-hosting precondition (P6-T1) is independently verified in `hosting-endpoint.md`.
