# authenticode-code-signing - Plan

- **Issue:** #50
- **Issue URL:** https://github.com/drmoisan/TMW/issues/50
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-06-06T11-21
- **Status:** Draft
- **Version:** 1.0
- **Work Mode:** full-feature

## Required References (authoritative)

- Spec (AC-1..AC-18): `docs/features/active/2026-06-06-authenticode-code-signing-50/spec.md`
- Feature document: `docs/features/active/2026-06-06-authenticode-code-signing-50/feature-document.md`
- Research design: `artifacts/research/2026-06-06-authenticode-code-signing-50.md`
- Policy: `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`,
  `.claude/rules/quality-tiers.md`, `.claude/rules/powershell.md`, `.claude/rules/tonality.md`
- Seam reference: `scripts/powershell/Start-MobileConnectivity.ps1` (injectable scriptblock seams)
- Test reference: `tests/pester/powershell/Start-MobileConnectivity.Tests.ps1` (capture-closure pattern)

**All work must comply with these policies; do not duplicate their content here.**

## Scope and Constraints Encoded by This Plan

- **Single tool:** `scripts/powershell/Invoke-AuthenticodeSigning.ps1` (Model B build/release-time signing).
- **Test file:** `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1` (location verified against
  existing `Start-MobileConnectivity.Tests.ps1` / `Stop-MobileConnectivity.Tests.ps1` siblings).
- **Toolchain per change:** PoshQC format (`mcp__drm-copilot__run_poshqc_format`) ->
  PSScriptAnalyzer (`mcp__drm-copilot__run_poshqc_analyze`) -> Pester
  (`mcp__drm-copilot__run_poshqc_test`), repeated until a clean single pass. Type-check stage is N/A for
  PowerShell.
- **Change budget:** PowerShell direct-mode = up to 2 production files; per-batch cap = 3 production + 3 test
  files. This feature creates 1 production file + 1 test file, within direct-mode budget. No batching split
  required unless a module split (P3) is triggered.
- **500-line limit:** applies to the tool and the test file. If the tool approaches the limit, perform the
  planned module split in Phase 3 (extract logic to a `.psm1`, leave the `.ps1` as a thin entry).
- **Coverage:** uniform line >= 85%, branch >= 75%. No production file excluded from coverage. Host-bound
  surface (`Invoke-SetAuthenticodeSignature`, `Resolve-SigningCert`) kept minimal and left in the denominator.
- **Evidence location (non-overridable):** all evidence under
  `docs/features/active/2026-06-06-authenticode-code-signing-50/evidence/<kind>/` per
  `evidence-and-timestamp-conventions`. `artifacts/...` evidence paths are forbidden.
- **Out of scope (do not implement):** CI-runner signing, `.github/workflows/**` changes,
  `quality-tiers.yml` changes, any `.csproj`/`Directory.Build.props` changes, signing of TypeScript/web
  bundles or vendored binaries.
- **Deviation guard:** No new .NET project and no `quality-tiers.yml` entry are expected. If implementation
  finds either is required, stop and record it as an explicit deviation with rationale in
  `evidence/other/`; do not silently add a project or tier entry.

`<FEATURE>` below denotes `docs/features/active/2026-06-06-authenticode-code-signing-50`.

---

## Implementation Plan (Atomic Tasks)

### Phase 0 — Baseline Capture and Policy Read

- [x] [P0-T1] Read the policy files in required order (`CLAUDE.md`, `.claude/rules/general-code-change.md`,
  `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/powershell.md`,
  `.claude/rules/tonality.md`) and record the read.
  - Files: `<FEATURE>/evidence/baseline/phase0-instructions-read.md`
  - Acceptance: artifact exists with `Timestamp:`, `Policy Order:`, and an explicit list of files read.
  - AC: enabling gate for AC-1..AC-18.

- [x] [P0-T2] Capture baseline PowerShell format state by running `mcp__drm-copilot__run_poshqc_format`
  scoped to `scripts/powershell/` and `tests/pester/powershell/` (no new files yet; records starting state).
  - Files: `<FEATURE>/evidence/baseline/baseline-poshqc-format.md`
  - Acceptance: artifact records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (files-changed
    count and pass/fail).
  - AC: AC-16 (baseline for formatting gate).

- [x] [P0-T3] Capture baseline PSScriptAnalyzer state by running `mcp__drm-copilot__run_poshqc_analyze`
  scoped to the same paths.
  - Files: `<FEATURE>/evidence/baseline/baseline-poshqc-analyze.md`
  - Acceptance: artifact records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (error/warning
    counts).
  - AC: AC-16 (baseline for lint gate).

- [x] [P0-T4] Capture baseline Pester state with coverage by running `mcp__drm-copilot__run_poshqc_test`
  using `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`.
  - Files: `<FEATURE>/evidence/baseline/baseline-pester-coverage.md`
  - Acceptance: artifact records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` with numeric
    baseline line-coverage and branch-coverage headline values and passed/failed test counts.
  - AC: AC-15 (baseline coverage reference for the no-regression delta check in Phase 4).

### Phase 1 — Production Tool: Pure-Logic and Config-Resolution Units

- [x] [P1-T1] Create the tool scaffold with `#Requires -Version 7.0`,
  `[CmdletBinding(SupportsShouldProcess = $true)]`, and the full parameter block (`-RepoRoot`, `-ConfigKey`,
  `-SecretsJsonPath`, `-TimestampServer`, `-FilePaths`, and the four seam scriptblock parameters
  `ReadSecretsAction`, `ResolveCertAction`, `EnumerateFilesAction`, `SignFileAction` with production
  defaults), plus the dot-source guard `if ($MyInvocation.InvocationName -ne '.')`.
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: file parses; `param` block matches the spec API surface; seam defaults call the named helpers;
    no thumbprint literal present in the file.
  - AC: AC-1 (no hardcoded thumbprint), AC-14 (seam parameters present).

- [x] [P1-T2] Author the comment-based help synopsis documenting the bootstrap execution-policy step
  (`-ExecutionPolicy Bypass`/`Unrestricted` for the first run of the unsigned signer).
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: `.SYNOPSIS`/`.DESCRIPTION`/`.NOTES` block states the bootstrap execution-policy requirement
    verbatim enough to satisfy AC-18.
  - AC: AC-18.

- [x] [P1-T3] Implement `Read-SigningThumbprint -JsonPath -Key`: fail fast with the actionable
  remediation command when `secrets.json` is missing; fail fast on JSON parse failure naming the path;
  fail fast when the value at `-Key` is null/empty/whitespace naming path and key; otherwise return the
  thumbprint.
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: function present with the three distinct fail-fast branches and the success return; the
    missing-file error string includes the `dotnet user-secrets set ... --id 3716a8f0-...` remediation.
  - AC: AC-1, AC-2.

- [x] [P1-T4] Implement the exclusion predicate as a pure function (relative path starts with
  `node_modules/` or `artifacts/`, separator-agnostic) usable by enumeration and unit-testable with fixed
  strings.
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: pure function present taking a relative path string and returning a boolean; no filesystem
    access inside it.
  - AC: AC-5 (exclusion logic).

- [x] [P1-T5] Add the seam-injected Pester test file scaffold and config-resolution unit tests covering:
  thumbprint present (returns value), missing file (throws with remediation), missing/empty key (throws),
  and JSON parse failure (throws). Tests dot-source the script and inject `ReadSecretsAction` or call
  `Read-SigningThumbprint` with fixed string inputs; no temp files, no `%APPDATA%` access.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: four `It` blocks pass; no `TestDrive:` or filesystem writes; assertions check error text for
    the missing-file remediation case.
  - AC: AC-2, AC-14.

- [x] [P1-T6] Add unit tests for the exclusion predicate covering included first-party relative paths and
  excluded `node_modules/...` and `artifacts/...` paths, using fixed strings only.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: positive and negative `It` blocks pass with both `/` and `\` separators.
  - AC: AC-5.

- [x] [P1-T7] Run the PoshQC loop (format -> analyze -> Pester) and repeat from format if any stage
  changes files or fails; capture the clean pass.
  - Files: `<FEATURE>/evidence/qa-gates/p1-poshqc-loop.md`
  - Acceptance: artifact records each stage `Command:`, `EXIT_CODE:`, `Output Summary:`; final state is zero
    analyzer errors and all Phase 1 tests passing.
  - AC: AC-16.

### Phase 2 — Production Tool: Enumeration, Cert Resolution, Signing, Verification, Orchestration

- [x] [P2-T1] Implement `Get-FirstPartySignableFiles -Root` applying the include globs
  (`.githooks/**/*.ps1`, `.github/scripts/**/*.ps1`, `scripts/**/*.ps1`, `scripts/**/*.psm1`,
  `scripts/**/*.psd1`, `tests/**/*.ps1`, `tests/**/*.psd1`, `.claude/hooks/**/*.ps1`) and the exclusion
  predicate; missing subtrees are skipped without error.
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: function present; uses the P1-T4 exclusion predicate; a missing include root is a `continue`,
    not an error.
  - AC: AC-5.

- [x] [P2-T2] Implement `Resolve-SigningCert -Thumbprint`: resolve from `Cert:\CurrentUser\My` matching
  thumbprint with `HasPrivateKey = True`; fail fast naming the thumbprint when none matches; validate the
  certificate carries the Code Signing EKU and fail fast when it does not. Keep this wrapper minimal
  (host-bound surface in the coverage denominator).
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: function present with the not-found fail-fast and the wrong-EKU fail-fast branches; no
    branching beyond resolution and the two validations.
  - AC: AC-3, AC-4.

- [x] [P2-T3] Implement `Invoke-SetAuthenticodeSignature -Path -Cert -TimestampServer`: call
  `Set-AuthenticodeSignature` with `-HashAlgorithm SHA256` and the timestamp server; treat a non-`Valid`
  signing-machine status as a per-file failure; emit a warning and continue when the timestamp server is
  unreachable (warn-not-fail). Keep this wrapper minimal (host-bound).
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: function present; SHA256 and timestamp server passed through; non-`Valid` status raises a
    per-file failure; timestamp-unreachable path warns rather than throws.
  - AC: AC-8, AC-9, AC-10.

- [x] [P2-T4] Implement `Test-AuthenticodeSignature -Path` verification wrapper returning whether
  `Get-AuthenticodeSignature` reports `Valid` on the signing machine.
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: function present; returns boolean from the cmdlet status check.
  - AC: AC-10.

- [x] [P2-T5] Implement the main orchestration body: resolve config via `ReadSecretsAction` and cert via
  `ResolveCertAction` before any side effect (config/cert failure aborts before signing); select files via
  `EnumerateFilesAction` when `-FilePaths` is empty, otherwise sign exactly `-FilePaths` and skip enumeration;
  dispatch each file through `SignFileAction`; honor `ShouldProcess`/`-WhatIf`; emit one log line per file and
  a summary count (signed/skipped/warnings); set a non-zero exit code on any fail-fast or per-file failure.
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
  - Acceptance: config and cert resolution precede enumeration/signing; `-FilePaths` branch bypasses
    enumeration; `-WhatIf` performs no signing; exit code is non-zero on failure and 0 on full success.
  - AC: AC-1, AC-2, AC-3, AC-4, AC-6, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13.

- [x] [P2-T6] Add cert-resolution unit tests via injected `ResolveCertAction`: valid cert (returns fake
  `[pscustomobject]`), absent (throws naming thumbprint), no private key (throws), wrong EKU (throws). No
  real cert store access.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: four `It` blocks pass; assertions confirm the run signs no file on each fail-fast path.
  - AC: AC-3, AC-4, AC-14.

- [x] [P2-T7] Add file-selection unit tests via injected `EnumerateFilesAction` returning fixed arrays:
  includes first-party script paths, excludes `node_modules/...` and `artifacts/...`, and handles a missing
  subtree (empty result) without error.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: `It` blocks pass using fixed string arrays only; no real directory scan.
  - AC: AC-5, AC-14.

- [x] [P2-T8] Add `-FilePaths` mode unit tests: when `-FilePaths` lists `TaskMaster.*.dll`/`.exe` entries,
  the tool dispatches sign calls for exactly those paths and `EnumerateFilesAction` is not invoked; assert
  via a captured-call list on `SignFileAction` and an invocation flag on the enumeration seam.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: captured `SignFileAction` calls equal the provided paths; enumeration seam recorded zero
    invocations.
  - AC: AC-6, AC-7, AC-14.

- [x] [P2-T9] Add sign-dispatch behavior unit tests via injected `SignFileAction` capture: one call per
  enumerated file (success path), per-file failure surfaced when the seam returns a non-`Valid` status,
  timestamp-unreachable warning path continues without hard failure, and `-WhatIf` records zero sign calls.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: `It` blocks pass; `-WhatIf` test asserts zero captured sign calls; failure test asserts a
    non-zero result is reported.
  - AC: AC-8, AC-9, AC-10, AC-12, AC-13, AC-14.

- [x] [P2-T10] Add an idempotent re-sign unit test via injected `SignFileAction`: invoking the tool twice
  over the same file list dispatches a successful sign call on each run and reports success both times (no
  error, non-failing exit), confirming re-sign is safe. Assert via the captured-call list that the second run
  signs the same path(s) without raising.
  - Files: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
  - Acceptance: `It` block passes; second invocation over already-"signed" inputs yields a success result and
    a captured sign call; no error is thrown.
  - AC: AC-13, AC-14.

- [x] [P2-T11] Run the PoshQC loop (format -> analyze -> Pester with coverage) and repeat from format on
  any change/failure; capture the clean pass with coverage headline.
  - Files: `<FEATURE>/evidence/qa-gates/p2-poshqc-loop.md`
  - Acceptance: artifact records each stage `Command:`, `EXIT_CODE:`, `Output Summary:`; final state is zero
    analyzer errors, all tests passing, and numeric line/branch coverage for the tool >= 85%/75%.
  - AC: AC-15, AC-16.

### Phase 3 — File-Size Guard and Conditional Module Split

- [x] [P3-T1] Verify the production tool and the test file are each under 500 lines.
  - Files: `<FEATURE>/evidence/qa-gates/p3-file-size-check.md`
  - Acceptance: artifact records the line count of `scripts/powershell/Invoke-AuthenticodeSigning.ps1` and
    `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`; both < 500.
  - AC: AC-16.

- [x] [P3-T2] [conditional] If P3-T1 shows the tool at or above 500 lines, extract the logic functions into
  `scripts/powershell/Invoke-AuthenticodeSigning.psm1` and reduce the `.ps1` to a thin entry that imports the
  module and invokes the orchestrator; keep all functions in the coverage denominator and update the test
  file's dot-source/import target accordingly. If P3-T1 shows both files under 500 lines, mark this task
  complete with `EXIT_CODE: SKIPPED` and record "split not required" (this skip branch is explicitly
  authorized by the conditional task text).
  - Files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`,
    `scripts/powershell/Invoke-AuthenticodeSigning.psm1` (created only if the split is triggered),
    `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`,
    `<FEATURE>/evidence/qa-gates/p3-module-split.md`
  - Acceptance: either the split is performed with all files < 500 lines and the PoshQC loop re-run clean,
    or the artifact records the authorized skip with both line counts.
  - AC: AC-16. Respects the 3-production/3-test per-batch cap (a split adds 1 production file, total 2
    production + 1 test, within cap).

### Phase 4 — Documentation (Runbook)

- [x] [P4-T1] Create a usage/runbook document covering: invocation examples (default script signing, `-WhatIf`
  preview, post-publish `-FilePaths` .NET assembly signing), the bootstrap execution-policy step for the
  first run of the unsigned signer, the self-signed-certificate trust limitation (non-trusting machines see a
  non-`Valid` status), and the CI-runner-signing deferral with its rationale.
  - Files: `<FEATURE>/runbook.md`
  - Acceptance: document contains the four sections above; the trust-limitation and CI-deferral text satisfy
    AC-17 and the bootstrap text aligns with the tool synopsis (AC-18).
  - AC: AC-17, AC-18.

### Phase 5 — Final QA Loop and AC Verification

- [x] [P5-T1] Run PoshQC formatting (`mcp__drm-copilot__run_poshqc_format`) on the new tool and test file;
  if it changes any file, restart the final loop from this step.
  - Files: `<FEATURE>/evidence/qa-gates/final-poshqc-format.md`
  - Acceptance: artifact records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`; zero files changed.
  - AC: AC-16.

- [x] [P5-T2] Run PSScriptAnalyzer (`mcp__drm-copilot__run_poshqc_analyze`); zero errors required.
  - Files: `<FEATURE>/evidence/qa-gates/final-poshqc-analyze.md`
  - Acceptance: artifact records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`; zero analyzer
    errors.
  - AC: AC-16.

- [x] [P5-T3] Run Pester with coverage (`mcp__drm-copilot__run_poshqc_test` using
  `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`); all tests pass and coverage meets thresholds.
  - Files: `<FEATURE>/evidence/qa-gates/final-pester-coverage.md`
  - Acceptance: artifact records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` with numeric
    post-change line coverage >= 85% and branch coverage >= 75% and all-tests-passing count; no production
    file excluded from coverage.
  - AC: AC-14, AC-15.

- [x] [P5-T4] Record the coverage delta/threshold verification comparing baseline (P0-T4) to post-change
  (P5-T3): report baseline coverage, post-change coverage, and new/changed-code coverage; confirm no
  regression on changed lines.
  - Files: `<FEATURE>/evidence/qa-gates/coverage-delta.md`
  - Acceptance: artifact reports the three numeric values and a no-regression determination; if any required
    value is unavailable the outcome is remediation-required, not PASS.
  - AC: AC-15.

- [x] [P5-T5] Verify each acceptance criterion AC-1..AC-18 maps to a passing test or to a documentation
  section, and confirm Model B is satisfied (no `# SIG # Begin signature block` content committed in any
  source file and no signature blocks added to tracked `.ps1`/`.psm1`/`.psd1`).
  - Files: `<FEATURE>/evidence/qa-gates/ac-verification-matrix.md`
  - Acceptance: artifact contains an AC-1..AC-18 table with each AC linked to its covering test ID or doc
    section and a verdict; AC-11 is verified by a working-tree check showing no committed signature blocks.
  - AC: AC-1..AC-18 (AC-7, AC-11 verified here in aggregate).

- [x] [P5-T6] If any final-QA stage failed or changed files, restart the loop at P5-T1 and repeat until a
  single clean pass of format -> analyze -> test completes; record the final clean-pass confirmation.
  - Files: `<FEATURE>/evidence/qa-gates/final-clean-pass.md`
  - Acceptance: artifact records the clean single-pass sequence with each stage `EXIT_CODE: 0` and tests
    passing.
  - AC: AC-15, AC-16.

---

## Acceptance Criteria Coverage Map

| AC | Covered by tasks |
|---|---|
| AC-1 | P1-T1, P1-T3, P2-T5 |
| AC-2 | P1-T3, P1-T5, P2-T5 |
| AC-3 | P2-T2, P2-T5, P2-T6 |
| AC-4 | P2-T2, P2-T5, P2-T6 |
| AC-5 | P1-T4, P1-T6, P2-T1, P2-T7 |
| AC-6 | P2-T5, P2-T8 |
| AC-7 | P2-T8, P5-T5 |
| AC-8 | P2-T3, P2-T5, P2-T9 |
| AC-9 | P2-T3, P2-T5, P2-T9 |
| AC-10 | P2-T3, P2-T4, P2-T5, P2-T9 |
| AC-11 | P2-T5, P5-T5 |
| AC-12 | P2-T5, P2-T9 |
| AC-13 | P2-T5, P2-T9, P2-T10 |
| AC-14 | P1-T1, P1-T5, P2-T6, P2-T7, P2-T8, P2-T9, P5-T3 |
| AC-15 | P0-T4, P2-T11, P5-T3, P5-T4, P5-T6 |
| AC-16 | P0-T2, P0-T3, P1-T7, P2-T11, P3-T1, P3-T2, P5-T1, P5-T2, P5-T6 |
| AC-17 | P4-T1 |
| AC-18 | P1-T2, P4-T1 |

## Test Plan

- **Unit (Pester, seam-injected, no temp files, no real cert):** config resolution (present/missing
  file/missing key/parse failure), exclusion predicate (include/exclude, both separators), cert resolution
  (valid/absent/no-private-key/wrong-EKU), file selection (includes first-party, excludes
  `node_modules`/`artifacts`, missing subtree), `-FilePaths` mode (signs exactly listed files, no
  enumeration), sign dispatch (one call per file, per-file failure, timestamp-unreachable warn-continue,
  `-WhatIf` no-op).
- **Integration:** none in scope (live `Set-AuthenticodeSignature`/cert store is host-bound and exercised
  only through seams in tests; real signing is a manual/release operation documented in the runbook).
- **Manual/CLI:** runbook examples (default script signing, `-WhatIf`, post-publish `-FilePaths`).
- **Coverage evidence:**
  - Baseline: `<FEATURE>/evidence/baseline/baseline-pester-coverage.md` (P0-T4)
  - Post-change: `<FEATURE>/evidence/qa-gates/final-pester-coverage.md` (P5-T3)
  - Comparison: `<FEATURE>/evidence/qa-gates/coverage-delta.md` (P5-T4)

## Open Questions / Notes

- Test location `tests/pester/powershell/` verified against existing sibling tests
  (`Start-MobileConnectivity.Tests.ps1`, `Stop-MobileConnectivity.Tests.ps1`); this is the correct mirrored
  path.
- Module split (Phase 3) is conditional; the research estimate is ~200–280 lines, comfortably under 500, so
  the split is expected to be skipped, but the guard remains in the plan.
- No `quality-tiers.yml` entry is required for a PowerShell script (no .NET project added). Any finding to
  the contrary is a deviation to be recorded, not silently actioned.
</content>
</invoke>
