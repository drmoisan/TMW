# outlook-mobile-ios-parity — Plan

- **Issue:** #35
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-19T21-40
- **Status:** Draft
- **Version:** 1.0
- **Work Mode:** full-feature

## Required References

- General code change policy: `.claude/rules/general-code-change.md`
- General unit test policy: `.claude/rules/general-unit-test.md`
- Quality tiers: `.claude/rules/quality-tiers.md`
- TypeScript standards: `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`
- Architecture boundaries: `.claude/rules/architecture-boundaries.md`
- Tonality: `.claude/rules/tonality.md`
- Evidence + timestamp conventions: `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`

**All work must comply with these policies; do not duplicate their content here.**

## Scope Anchors (do not re-derive)

- Authoritative spec: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/spec.md`
- User story: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/user-story.md`
- Research: `artifacts/research/2026-05-19-outlook-ios-mobile-support-research.md`
- Issue: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/issue.md`

Fixed scope facts honored by this plan:

- iOS only; full Message-Read parity via a NEW parallel add-in only `manifest.xml`
  (`VersionOverridesV1_1`) carrying BOTH `<DesktopFormFactor>` and `<MobileFormFactor>`.
- The existing unified `manifest.json` is UNCHANGED and remains the desktop/web artifact.
- No Office.js / `src/*.ts` logic changes are required. The only `src/` touch is a
  responsive CSS/HTML audit of `src/taskpane/taskpane.html` plus an optional mobile
  "Close" button calling `Office.context.ui.closeContainer()`.
- Concrete work items: new `manifest.xml`; nine mobile icon assets (25/32/48 px ×
  scales 1/2/3); `package.json` `validate:xml` script + CI wiring; webpack icon-copy
  verification to `dist`; responsive `taskpane.html` audit + optional close button;
  HTTPS hosting with trusted TLS for on-device reachability.
- On-device acceptance criteria CANNOT be CI-gated. They are explicit MANUAL evidence
  tasks (Phase 6) producing dated artifacts under
  `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/<kind>/`.

## Evidence Location Invariant

All evidence artifacts produced by this plan MUST be written under
`docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/<kind>/`
(canonical sub-paths: `baseline/`, `qa-gates/`, `regression-testing/`, `issue-updates/`,
`screenshots/`, `recordings/`, `notes/`, `other/`). Writing baselines/QA/coverage under
`artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, or `artifacts/evidence/`
is a policy violation and is rejected by the `enforce-evidence-locations` PreToolUse hook.

## Coverage Note (full-feature, no new testable units expected)

The spec and research state the `taskpane.html` change is a CSS/HTML audit plus an
optional close button; no new `src/` logic units are introduced (spec "Seeded Test
Conditions"; research §6.3). Coverage policy (line >= 85%, branch >= 75%) is therefore
satisfied by holding existing coverage steady with `manifest.json` and `src/*.ts` logic
unchanged. Baseline (P0) and final-QC (P5) coverage tasks capture numeric values so a
no-regression delta can be reconciled (P7). If implementation introduces any new
testable `src/` logic, the executor MUST add unit tests meeting thresholds before the
final QA loop can pass; otherwise the outcome is remediation-required, not PASS.

---

### Phase 0 — Baseline Capture & Policy Read

- [x] [P0-T1] Read repository policy files in the required order and record an evidence artifact
  - Files to read (in order): `CLAUDE.md`, `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`, `.claude/rules/architecture-boundaries.md`, `.claude/rules/tonality.md`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/phase0-instructions-read.md`
  - Artifact MUST contain: `Timestamp:`, `Policy Order:`, explicit list of files read
  - Acceptance: artifact exists with all required fields populated (maps to general-code-change "Mandatory Toolchain Loop" precondition)

- [x] [P0-T2] Capture baseline Prettier format-check state
  - Command: `npm run format:check`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-format.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: artifact records exit code and pass/fail summary

- [x] [P0-T3] Capture baseline ESLint state
  - Command: `npm run lint`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-lint.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (error/warning counts)
  - Acceptance: artifact records exit code and counts

- [x] [P0-T4] Capture baseline TypeScript type-check state
  - Command: `npm run typecheck`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-typecheck.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: artifact records exit code and error count

- [x] [P0-T5] Capture baseline architecture-boundary state
  - Command: `npm run depcruise`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-architecture.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (violation count)
  - Acceptance: artifact records exit code and violation count

- [x] [P0-T6] Capture baseline unit-test + coverage state (numeric headline)
  - Command: `npm run test:coverage`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-test-coverage.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric baseline line-coverage % and branch-coverage % and pass count
  - Acceptance: artifact records numeric coverage headline values (not placeholders)

- [x] [P0-T7] Capture baseline unified-manifest validation state (no-regression reference)
  - Command: `npm run validate`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-validate-json.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: artifact records exit code and validation result for `manifest.json`

- [x] [P0-T8] Record baseline `manifest.json` content fingerprint for the no-regression check
  - Command (PowerShell): `Get-FileHash manifest.json -Algorithm SHA256`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/baseline/baseline-manifest-json-hash.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (the SHA-256 hash)
  - Acceptance: artifact records the pre-change `manifest.json` hash (used by P7 to prove `manifest.json` is unchanged — spec/user-story no-regression AC)

---

### Phase 1 — Mobile Icon Assets (CI-verifiable)

- [x] [P1-T1] Create the nine mobile icon source files under `assets/`
  - File targets: `assets/icon-25.png`, `assets/icon-25@2x.png`, `assets/icon-25@3x.png`, `assets/icon-32-mobile.png`, `assets/icon-32-mobile@2x.png`, `assets/icon-32-mobile@3x.png`, `assets/icon-48.png`, `assets/icon-48@2x.png`, `assets/icon-48@3x.png` (final filenames MUST exactly match the `<bt:Image>` URLs declared in P2-T4; if the implementer chooses different names the manifest URLs must match 1:1)
  - Dimensions: 25×25, 32×32, 48×48 logical px at scales 1/2/3 → physical px 25/50/75, 32/64/96, 48/96/144
  - Note: physical dimensions MUST match the scale declarations; existing 16/32/80 px assets cannot be reused for these size declarations (research §4.3)
  - Acceptance: nine PNG files exist at the declared paths with the correct physical pixel dimensions (maps to spec CI-AC "Nine mobile icon files … are present in the source tree")

- [x] [P1-T2] Verify each new icon file is a valid PNG at its declared physical dimensions
  - Command (PowerShell, per file): `Add-Type -AssemblyName System.Drawing; (New-Object System.Drawing.Bitmap "<path>").Size`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/icon-dimensions.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` listing each file and its measured dimensions
  - Acceptance: all nine files report the expected physical pixel dimensions (maps to spec CI-AC icon presence)

---

### Phase 2 — Parallel `manifest.xml` (CI-verifiable)

- [x] [P2-T1] Create `manifest.xml` skeleton: add-in only manifest using `OfficeApp` with `VersionOverridesV1_1`
  - File target: `manifest.xml` (new, at repo root)
  - Content: `OfficeApp` root with `xsi:type="MailApp"`, `Id` (a NEW GUID distinct from `manifest.json` id `fcf3e6aa-39e0-4da3-a47a-a21eead908a1`), `Version 1.0.0.0`, `ProviderName`, `DisplayName "TaskMaster for Outlook"`, `Description`, `Hosts`/`Host Name="Mailbox"`, `Requirements`/`Sets`/`Set Name="Mailbox" MinVersion="1.5"`, `SourceLocation` pointing at `https://localhost:3000/taskpane.html`, `Permissions ReadItem`
  - Acceptance: file parses as well-formed XML; declares `Mailbox` requirement set `MinVersion="1.5"` (maps to spec CI-AC "manifest.xml declares Mailbox requirement set minVersion=1.5")

- [x] [P2-T2] Add the `<VersionOverrides xsi:type="VersionOverridesV1_1">` block with shared `<Resources>` and a desktop `<FunctionFile>`/`SourceLocation` reference to `taskpane.html`
  - File target: `manifest.xml`
  - Content: `VersionOverrides` (`xmlns:xsi`, `xsi:type="VersionOverridesV1_1"`), `Hosts`/`Host xsi:type="MailHost"`, `DesktopFormFactor` and `MobileFormFactor` children (populated in P2-T3/P2-T4), `Resources` block stub
  - Acceptance: the `VersionOverrides` node exists and is well-formed; both form-factor child nodes are present (maps to spec/user-story CI-AC "manifest.xml … with `<DesktopFormFactor>` and `<MobileFormFactor>`")

- [x] [P2-T3] Populate `<DesktopFormFactor>` translated from the unified manifest desktop config
  - File target: `manifest.xml`
  - Content: `ExtensionPoint xsi:type="MessageReadCommandSurface"` → `OfficeTab id="TabDefault"` → `Group id="msgReadGroup" label="TaskMaster"` → one `Control xsi:type="Button"` with `Action xsi:type="ShowTaskpane"` opening the `taskpane.html` SourceLocation, `Supertip` ("Open TaskMaster"), and 16/32/80 px `<bt:Image>` icon references in `<Resources>`
  - Acceptance: desktop form factor uses `MessageReadCommandSurface`, a `Button` control, and a `ShowTaskpane` action pointing at `taskpane.html`; 16/32/80 icons referenced (maps to spec "Behavior → DesktopFormFactor")

- [x] [P2-T4] Populate `<MobileFormFactor>` with the mobile message-read surface
  - File target: `manifest.xml`
  - Content: `ExtensionPoint xsi:type="MobileMessageReadCommandSurface"` → `Group id="…"` → one `Control xsi:type="MobileButton"` with `Action xsi:type="ShowTaskpane"` opening the same `taskpane.html` SourceLocation; NO `<OfficeTab>`, NO `<Supertip>`, NO `Menu`; reference the nine mobile icons (25/32/48 px at scales 1/2/3) via `<Icon>`/`<bt:Image>` resource IDs whose URLs match the P1-T1 filenames
  - Acceptance: mobile form factor declares `MobileMessageReadCommandSurface`, a `MobileButton`, and a `ShowTaskpane` action referencing `taskpane.html`, with nine mobile icon resource references (maps to spec/user-story CI-AC "MobileFormFactor … MobileMessageReadCommandSurface … MobileButton … ShowTaskpane … taskpane.html")

- [x] [P2-T5] Add the nine mobile-icon `<bt:Image>` entries (and 16/32/80 desktop entries) to `<Resources>` with `https://localhost:3000/assets/...` URLs
  - File target: `manifest.xml` (`<Resources><bt:Images>` block)
  - Content: resource IDs referenced by P2-T3 and P2-T4, each `<bt:Image>` URL pointing at the corresponding `assets/<file>.png` under `https://localhost:3000/`
  - Acceptance: every icon resource ID referenced by either form factor resolves to a `<bt:Image>` with a concrete URL matching a file produced in Phase 1 (maps to spec CI-AC "referenced from the manifest.xml `<Resources>` block")

---

### Phase 3 — Validation Tooling & CI Wiring (CI-verifiable)

- [x] [P3-T1] Add the `validate:xml` script to `package.json`
  - File target: `package.json` (`scripts` block)
  - Content: `"validate:xml": "office-addin-manifest validate manifest.xml"` (no new dependency; `office-addin-manifest ^2.0.3` already present)
  - Acceptance: `package.json` contains the `validate:xml` script verbatim (maps to spec CI-AC "package.json has a validate:xml script")

- [x] [P3-T2] Run `npm run validate:xml` and confirm zero schema errors
  - Command: `npm run validate:xml`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/validate-xml.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: `EXIT_CODE: 0` and "manifest is valid" (or equivalent) in summary; zero schema errors (maps to spec CI-AC "npm run validate:xml passes with zero schema errors"). If validation fails, loop back to Phase 2 and re-run before proceeding.

- [x] [P3-T3] Wire `validate:xml` into the CI contract/schema stage
  - File target: `.github/actions/contract/action.yml` (add a composite step `npm run validate:xml` after "Install npm dependencies", failing the stage on non-zero exit)
  - Rationale: stage 6 (`_stage-6-contract.yml`) is the contract/schema-compatibility stage per `.claude/rules/general-code-change.md` step 6; XML manifest schema validation belongs there
  - Acceptance: the contract action invokes `npm run validate:xml` and propagates a non-zero exit as a stage failure (maps to spec CI-AC "The CI validation stage invokes validate:xml and fails the build on schema errors")

- [x] [P3-T4] Verify the unified-manifest validation script is unchanged and still passes (no-regression)
  - Command: `npm run validate`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/regression-testing/validate-json-post.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: `EXIT_CODE: 0`; result matches P0-T7 baseline (maps to spec CI-AC "manifest.json is unchanged and npm run validate still passes")

---

### Phase 4 — Webpack Icon-Copy & Build-Output Verification (CI-verifiable)

- [x] [P4-T1] Confirm the webpack `CopyWebpackPlugin` `assets/*` pattern includes the nine new icons; extend the config only if any new icon is excluded
  - File target: `webpack.config.js` (inspect; edit `CopyWebpackPlugin` patterns ONLY if the existing `assets/*` glob does not capture the new files)
  - Acceptance: a documented determination that the build copies all nine mobile icons to `dist/assets/`; any required config change is minimal and preserves the existing `manifest*.json` copy/transform behavior

- [x] [P4-T2] Add `manifest.xml` to the webpack output so the `urlProd` substitution applies to the XML manifest for device builds
  - File target: `webpack.config.js` (`CopyWebpackPlugin` patterns — extend the existing `manifest*.json` pattern, or add a parallel `manifest.xml` pattern, so the `urlDev`→`urlProd` replacement runs against `manifest.xml` in production mode)
  - Rationale: spec "Config keys and defaults" — `urlProd` substitution must apply to the device build manifest so `https://localhost:3000/` is replaced with the trusted-TLS endpoint
  - Acceptance: a production build emits `manifest.xml` to `dist/` with `urlDev` replaced by `urlProd`; a dev build emits it unchanged

- [x] [P4-T3] Run a production build and verify the nine mobile icons are emitted to `dist` at the manifest-declared paths
  - Command: `npm run build` then enumerate `dist/assets/` (PowerShell: `Get-ChildItem dist/assets`)
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/dist-icon-emission.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` listing each of the nine icon files found in `dist/assets/` and confirming each matches a `<bt:Image>` URL path in `dist/manifest.xml`
  - Acceptance: all nine mobile icons present in `dist/assets/` at the URLs declared in `manifest.xml` (maps to spec CI-AC "emitted to the dist bundle at the URLs declared in manifest.xml" and Seeded Test Condition "Build-output verification")

---

### Phase 5 — Responsive `taskpane.html` Audit & Optional Close Button (CI-verifiable subset)

- [x] [P5-T1] Audit `src/taskpane/taskpane.html` layout at a 375 px viewport and apply responsive CSS adjustments
  - File target: `src/taskpane/taskpane.html` (and any associated `taskpane.css`/inline styles it references)
  - Scope: confirm usable rendering at 375 px (iPhone SE) minimum width with no clipped or unreachable controls; reduce the 90×90 header image and `<h1>` footprint for narrow viewports (e.g., responsive width/`max-width` or a media query). Keep the existing `<meta name="viewport" content="width=device-width, initial-scale=1">` (research §4.1 confirms it is correct).
  - Constraint: CSS/HTML only; no `src/*.ts` logic change; do not exceed the 500-line file limit
  - Acceptance: at a 375 px emulated viewport every control (Classify/Confirm/Reject) is visible and reachable and the header footprint is reduced (maps to spec CI-AC "renders without clipped or unreachable controls at a 375 px viewport width (verified via build/CSS audit and DevTools mobile emulation as a CI-side proxy)" and DoD "header footprint reduced")

- [x] [P5-T2] Record the 375 px CI-side responsive-audit proxy evidence
  - Method: capture a DevTools/headless mobile-emulation screenshot or a documented manual measurement of `dist/taskpane.html` at 375 px width
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/responsive-audit-375.md` (with the screenshot under `evidence/screenshots/` if captured)
  - Artifact MUST contain: `Timestamp:`, `Method:`, `Output Summary:` listing each control's visibility/reachability at 375 px
  - Acceptance: artifact demonstrates no clipped/unreachable controls at 375 px (CI-side proxy for the on-device render; the authoritative on-device render is P6-T3)

- [x] [P5-T3] Add an optional mobile "Close" button that calls `Office.context.ui.closeContainer()`
  - File targets: `src/taskpane/taskpane.html` (button markup) and `src/taskpane/taskpane.ts` (event wiring only — the single permitted `src/*.ts` touch, limited to attaching a click handler that calls `Office.context.ui.closeContainer()`)
  - Constraint: this is the only Office.js addition permitted by scope (spec "Behavior"); guard the call so it is a no-op when `Office.context.ui.closeContainer` is unavailable; if any new pure helper is extracted, it MUST receive a unit test meeting coverage thresholds (general-unit-test policy)
  - Acceptance: a "Close" control exists and invokes `Office.context.ui.closeContainer()`; existing tests still pass (maps to spec DoD "Optional Office.context.ui.closeContainer() close button present for mobile UX")

---

### Phase 6 — Manual On-Device Verification (NOT CI-gatable — dated evidence required)

> These criteria cannot be CI-gated: Outlook iOS provides no remote DevTools and the
> runtime cannot be emulated by CI (research §5.3). Each task is performed by hand on a
> physical iOS device and produces dated evidence. These tasks are NOT executed by the
> automated executor and MUST NOT be marked complete on the basis of CI output.

- [x] [P6-T1] Provision an HTTPS staging/production endpoint with a trusted (non-self-signed) TLS certificate reachable by the iOS device, set `urlProd` in `webpack.config.js` to that endpoint, build, and host the bundle
  - File target (build-time): `webpack.config.js` `urlProd` (set to the real trusted-TLS endpoint; replaces the placeholder `https://www.contoso.com/`)
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/notes/hosting-endpoint.md`
  - Artifact MUST contain: `Timestamp:`, the HTTPS endpoint URL, the TLS trust basis (issuer/that it is not self-signed), and confirmation the bundle (`taskpane.html`, `taskpane.js`, `assets/*`, `manifest.xml`) is reachable over HTTPS
  - Acceptance: a trusted-TLS HTTPS endpoint serving the bundle is documented (maps to spec "HTTPS hosting / deployment for device reachability"; precondition for P6-T2..T5)

- [x] [P6-T2] Sideload `manifest.xml` via Outlook on the web, sync to the iOS device, and confirm the add-in appears in the message "More options" (three-dot) menu in read mode
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/screenshots/more-options-menu.<timestamp>.png` plus a note artifact `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/notes/sideload.<timestamp>.md` recording the sideload procedure and account used
  - Acceptance: dated screenshot shows the TaskMaster entry in the iOS More-options menu (maps to spec/user-story manual AC "appears in the Outlook iOS message More options menu")

- [x] [P6-T3] Verify the task pane renders usably on the iPhone viewport (full-screen, no clipped/unreachable controls, acceptable header footprint)
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/screenshots/taskpane-render.<timestamp>.png`
  - Acceptance: dated device screenshot shows the rendered pane with all controls reachable (maps to spec/user-story manual AC "renders usably on an iPhone viewport")

- [x] [P6-T4] Verify `Office.EventType.ItemChanged` fires on message navigation and re-renders selected-message context (subject/from)
  - Evidence: dated before/after screenshots `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/screenshots/itemchanged-before.<timestamp>.png` and `itemchanged-after.<timestamp>.png` (or a recording under `evidence/recordings/`)
  - Acceptance: evidence shows subject/from updating after navigating between two messages (maps to spec/user-story manual AC "ItemChanged fires on message navigation and re-renders context")

- [~] [P6-T5] N/A — Verify the classifier backend is reachable over HTTPS from the device and a classification succeeds (label/confidence shown)
  - Status: N/A (user decision 2026-05-20, "Option A"). The classify/feedback workflow is not wired into the product on ANY platform — `classify-btn` has no click handler, `ClassifierClient` is never instantiated in product code, and no bearer token is obtained (see `src/taskpane/taskpane.ts`, `src/taskpane/taskpane.html`). Tapping Classify is inert on desktop and mobile alike, so mobile parity holds and this AC cannot be satisfied within issue #35's mobile-enablement scope. The gap is tracked separately as GitHub issue #37 (wire-classify-feedback-workflow).
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/notes/sideload-and-render.2026-05-20T09-45.md` (records the wiring gap and the N/A rationale)
  - Acceptance: recorded N/A with rationale and a tracking issue (#37); not counted as a failing/unverified AC.

---

### Phase 7 — Final QA Loop & Acceptance-Criteria Reconciliation

> Run the full TypeScript toolchain in order: format → lint → type-check →
> architecture → test (coverage). Per `.claude/rules/general-code-change.md`, if any
> step fails or changes files, restart from format until a single clean pass completes.
> Each command task below is unconditional: it MUST be executed and recorded. `SKIPPED`
> is not a valid passing outcome.

- [x] [P7-T1] Run Prettier format check and record evidence
  - Command: `npm run format:check`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/final-format.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: `EXIT_CODE: 0`. If files change, run `npm run format` then restart the loop at P7-T1.

- [x] [P7-T2] Run ESLint and record evidence
  - Command: `npm run lint`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/final-lint.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (0 errors)
  - Acceptance: `EXIT_CODE: 0`, 0 errors. If it fails or autofixes files, restart at P7-T1.

- [x] [P7-T3] Run TypeScript type-check and record evidence
  - Command: `npm run typecheck`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/final-typecheck.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
  - Acceptance: `EXIT_CODE: 0`, 0 type errors.

- [x] [P7-T4] Run architecture-boundary check and record evidence
  - Command: `npm run depcruise`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/final-architecture.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (violation count)
  - Acceptance: `EXIT_CODE: 0`, 0 violations.

- [x] [P7-T5] Run unit tests with coverage and record numeric post-change coverage
  - Command: `npm run test:coverage`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/final-test-coverage.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric post-change line-coverage % and branch-coverage % and pass count
  - Acceptance: `EXIT_CODE: 0`; line >= 85%, branch >= 75% (per `.claude/rules/general-unit-test.md`).

- [x] [P7-T6] Run `validate:xml` and `validate` together as the final manifest gate
  - Commands: `npm run validate:xml` and `npm run validate`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/final-manifest-validation.md`
  - Artifact MUST contain: `Timestamp:`, both `Command:` lines, both `EXIT_CODE:` values, `Output Summary:`
  - Acceptance: both `EXIT_CODE: 0`; XML schema-valid and unified manifest still valid.

- [x] [P7-T7] Verify `manifest.json` is byte-for-byte unchanged versus the P0-T8 baseline hash
  - Command (PowerShell): `Get-FileHash manifest.json -Algorithm SHA256`
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/regression-testing/manifest-json-unchanged.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` showing the post-change hash equals the P0-T8 baseline hash
  - Acceptance: hashes match → `manifest.json` unchanged (maps to spec/user-story CI-AC "manifest.json is unchanged"). If hashes differ, the outcome is remediation-required, not PASS.

- [x] [P7-T8] Compute and record the coverage delta (baseline vs. post-change vs. changed-code)
  - Inputs: P0-T6 baseline coverage, P7-T5 post-change coverage
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/qa-gates/coverage-delta.md`
  - Artifact MUST report: baseline line/branch %, post-change line/branch %, and changed-code coverage; assert no regression on changed lines
  - Acceptance: post-change line >= 85% and branch >= 75% and no regression on changed lines; if any new `src/` logic was introduced without adequate coverage, mark remediation-required (not PASS)

- [x] [P7-T9] Reconcile every spec acceptance criterion to the task(s) that satisfy it
  - Evidence: `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/other/ac-traceability.md`
  - Artifact MUST contain the table below, each row marked SATISFIED (with the evidence artifact path) or OUTSTANDING:
    - spec CI-AC "manifest.xml exists and npm run validate:xml passes, zero schema errors" → P2-T1..T5, P3-T2, P7-T6
    - spec CI-AC "MobileFormFactor … MobileMessageReadCommandSurface, MobileButton, ShowTaskpane → taskpane.html" → P2-T4
    - spec CI-AC "manifest.xml declares Mailbox minVersion=1.5" → P2-T1
    - spec CI-AC "Nine mobile icon files present and emitted to dist at declared URLs" → P1-T1, P1-T2, P4-T3
    - spec CI-AC "CI validation stage invokes validate:xml and fails on schema errors" → P3-T1, P3-T3
    - spec CI-AC "No regression: manifest.json unchanged and npm run validate still passes" → P3-T4, P7-T6, P7-T7
    - spec CI-AC "Full toolchain passes in a single pass" → P7-T1..T6
    - user-story CI-AC "DesktopFormFactor + MobileFormFactor referencing same hosted bundle" → P2-T2, P2-T3, P2-T4
    - user-story CI-AC "renders without clipped/unreachable controls at 375 px (CSS audit / DevTools emulation proxy)" → P5-T1, P5-T2
    - spec/user-story manual AC "appears in iOS More options menu" → P6-T2
    - spec/user-story manual AC "renders usably on iPhone viewport" → P6-T3
    - spec/user-story manual AC "ItemChanged fires on navigation, re-renders context" → P6-T4
    - spec/user-story manual AC "classifier reachable over HTTPS, classification succeeds" → P6-T1, P6-T5
    - spec DoD "optional closeContainer() close button present" → P5-T3
  - Acceptance: every CI-verifiable AC is SATISFIED with a cited evidence artifact; each manual AC is either SATISFIED with dated device evidence (Phase 6) or explicitly marked OUTSTANDING with the reason (e.g., device verification pending). The CI-verifiable subset may be reported PASS independently; overall feature completion requires the Phase 6 manual evidence.

## Test Plan

- Unit: existing Vitest suite (`npm run test:coverage`) re-run unchanged; no new `src/` logic units are expected (spec Seeded Test Conditions). Any new pure helper introduced by P5-T3 requires a `*.test.ts` meeting coverage thresholds.
- Contract/schema: `npm run validate:xml` (new) + `npm run validate` (unchanged), wired into CI stage 6 (P3-T3).
- Build-output: `npm run build` + `dist/assets` enumeration (P4-T3).
- Responsive (CI-side proxy): 375 px DevTools/headless emulation of `dist/taskpane.html` (P5-T2).
- Manual/on-device: Phase 6 (P6-T1..T5) — dated screenshots/recordings/notes under `evidence/`; not CI-gatable.
- Coverage evidence: baseline `evidence/baseline/baseline-test-coverage.md` (P0-T6); post-change `evidence/qa-gates/final-test-coverage.md` (P7-T5); delta `evidence/qa-gates/coverage-delta.md` (P7-T8).

## Open Questions / Notes

- Final mobile-icon filenames in `assets/` must match the `<bt:Image>` URLs in `manifest.xml` exactly; P1-T1 and P2-T5 must agree on the names.
- `manifest.xml` requires a NEW GUID `Id` distinct from the unified manifest id; a fresh GUID must be generated during P2-T1.
- `urlProd` in `webpack.config.js` is a placeholder (`https://www.contoso.com/`); P6-T1 sets it to the real trusted-TLS endpoint for device builds. The CI-verifiable phases (1–5, 7) do not depend on a real endpoint.
