# QA Gate — Responsive Task-Pane Audit at 375 px (CI-side proxy)

- Timestamp: 2026-05-19T22-42
- Tasks: [P5-T1], [P5-T2]
- Method: Documented CSS/HTML rule analysis of the production-built `dist/taskpane.html`
  and its emitted stylesheet `dist/b50fe102eb4b9939e77e.css` at an emulated 375 px
  (iPhone SE) viewport width. (Outlook iOS provides no remote DevTools; the authoritative
  on-device render is the manual task P6-T3. This artifact is the CI-side proxy required by
  the user-story CI-AC "verified via build/CSS audit and DevTools mobile emulation as a
  CI-side proxy".)
- EXIT_CODE: 0 (build succeeded; audit artifacts present in dist)

## Inputs verified present in the production build

- `dist/taskpane.html` retains `<meta name="viewport" content="width=device-width,initial-scale=1">` (research §4.1 confirms correct).
- Stylesheet link rewritten to hashed asset `b50fe102eb4b9939e77e.css`; the `@media (max-width: 480px)` block is present in that emitted file (verified: 1 match).
- All controls present in `dist/taskpane.html`: `#classify-btn`, `#confirm-btn`, `#reject-btn`, and the new `#close-btn`.

## Applied responsive rules (effective at 375 px, under the 480 px breakpoint)

| Element | Default | At <= 480px (375px viewport) | Effect |
|---|---|---|---|
| `.tm-header` padding-top | 100px | 24px | Header footprint reduced |
| `.tm-header` padding-bottom | 30px | 16px | Header footprint reduced |
| header `<img>` | 90x90 | 48x48 (`max-width:100%`, fixed 48px) | Header image footprint reduced |
| `<h1 class="ms-font-su">` | large (ms-font-su) | font-size 20px | Title footprint reduced |
| `.tm-main` padding | 10px 20px | 8px 12px | More horizontal room |
| `#classification-panel` | block | flex with `flex-wrap: wrap` | Action buttons wrap instead of clipping |
| `.ms-Button` (in panel) | inline | `flex: 1 1 auto` | Buttons share width, none clipped off the right edge |

IE prefixes (`-ms-flexbox`, `-ms-flex-wrap`, `-ms-flex`) added alongside `-webkit-`
prefixes to satisfy the project browserslist (`ie 11`) and clear the analyzer diagnostics.

## Control visibility / reachability at 375 px

| Control | Visible | Reachable (not clipped) |
|---|---|---|
| Classify (`#classify-btn`) | yes | yes |
| Confirm (`#confirm-btn`) | yes | yes (wraps within panel) |
| Reject (`#reject-btn`) | yes | yes (wraps within panel) |
| Close (`#close-btn`) | yes | yes (block-level under panel) |

## Determination

At a 375 px emulated viewport the header footprint is materially reduced (padding-top
100px -> 24px; image 90px -> 48px; title font-size 20px) and the three action buttons plus
the Close button remain visible and reachable, wrapping rather than clipping. No control is
clipped or unreachable. Maps to spec CI-AC "renders without clipped or unreachable controls
at a 375 px viewport width" and DoD "header footprint reduced for narrow viewports". The
authoritative on-device render remains manual task P6-T3 (OUTSTANDING — physical device).
