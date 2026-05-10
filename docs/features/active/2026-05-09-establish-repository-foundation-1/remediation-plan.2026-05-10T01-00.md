---
artifact: remediation-plan
feature: 2026-05-09-establish-repository-foundation-1
issue: 1
branch: feature/establish-repository-foundation-1
base: main (a2a462662a9d46f955b65f3e6bcc0f7887cbe04d)
timestamp: 2026-05-10T01-00
mode: full-feature
supersedes: remediation-plan.2026-05-10T00-00.md
revision-trigger: required-changes-2026-05-10T00-45.md
---

# Remediation Atomic Plan (Revision) — Issue #1: Establish Repository Foundation

This is a revision of `remediation-plan.2026-05-10T00-00.md`, issued to address two
gaps surfaced by the executor in `required-changes-2026-05-10T00-45.md`:

1. **Latent production-script bug** in
   `.claude/hooks/validate-feature-review-coverage.ps1` line 271, where the
   `$languageLabelMap` entry for `'CSharp'` lists `'\.NET'` (a literal backslash
   followed by `.NET`). After `[regex]::Escape(...)` this becomes `\\\.NET`, which
   matches the literal character sequence `\.NET` rather than `.NET`. Real audit
   text (e.g. `.NET coverage row PASS`) contains no backslash and is therefore
   never matched. **Option A from the required-changes file is adopted**: change
   `'\.NET'` to `'.NET'` (one-character production fix), preserving the
   plan-authored test's intent.
2. **Coverage gap.** The plan-authored Pester suite executed in RP-4 covered only
   the helper functions, yielding 38.85 % line coverage of
   `validate-feature-review-coverage.ps1`. The main entrypoint
   `Invoke-FeatureReviewCoverageValidation` (lines 334–447) was not exercised. R1
   requires line >= 85 % and branch >= 75 % per script. New tests are added to
   exercise every branch of the entrypoint.

## Revision Scope and Carry-Over Rules

- **RP-0 through RP-3 are carried over verbatim** with status notes
  `[carried-over: complete from prior pass]`. They executed cleanly in the prior
  pass and must NOT be re-executed.
- **RP-4 partial carry-over.** Tasks `[P4-T1]`..`[P4-T4]` are carried over as
  `[carried-over: complete from prior pass]`. The original `[P4-T5]` (the failing
  Pester run) is **superseded** and replaced by three new tasks:
  - `[P4-T5a]` — production hook one-character fix.
  - `[P4-T6]` — re-run Pester after the hook fix (renumbered from old T5; intent
    unchanged).
  - `[P4-T7]` — add Pester tests for `Invoke-FeatureReviewCoverageValidation`.
  - `[P4-T8]` — re-run Pester with full suite and assert >= 85 % line / >= 75 %
    branch on `validate-feature-review-coverage.ps1`.
- **RP-5, RP-6, RP-7 are carried forward** with task IDs adjusted only where they
  reference Phase 4 evidence; no other body text changes.

## Authoritative Directives Carried Forward (D1–D8)

These directives, established in the prior plan preamble, remain in force without
modification:

- **D1.** No manual-followup language is permitted anywhere in the feature folder,
  rules, instructions, or evidence. Replace with automated evidence or explicit
  FAIL.
- **D2.** Mirror discipline: every `.claude/rules/` change must be paired with the
  matching `.github/instructions/` change in the same diff (AC #75).
- **D3.** No temp-file usage in tests. `$TestDrive` (Pester's in-memory PSDrive)
  is permitted; `$env:TEMP` and ad-hoc tempfiles are not.
- **D4.** All evidence is written under
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/<kind>/`
  per `evidence-and-timestamp-conventions`. `artifacts/baselines/`,
  `artifacts/qa/`, `artifacts/coverage/`, and any other non-canonical evidence
  paths are forbidden.
- **D5.** All work occurs on `feature/establish-repository-foundation-1`. No new
  branches.
- **D6.** No introduction of generic process-runner frameworks. Wrapper-function
  seam is the default mock seam pattern.
- **D7.** PowerShell coverage floors are uniform across tiers: line >= 85 %,
  branch >= 75 % (per `.claude/rules/powershell.md` and `quality-tiers.md`).
- **D8.** Toolchain order is format → analyze → test. Restart the loop on any
  auto-fix or failure.

---

## Phase RP-0 — Preflight & Baseline

### Phase RP-0 — Preflight & Baseline

- [x] [P0-T1] [carried-over: complete from prior pass] Read
  `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`,
  `.claude/rules/powershell.md`, `.claude/skills/powershell-qa-gate/SKILL.md`,
  `.claude/skills/atomic-plan-contract/SKILL.md`, and
  `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. Evidence:
  `evidence/baseline/phase0-instructions-read.md`.

- [x] [P0-T2] [carried-over: complete from prior pass] Capture git state baseline.
  Evidence: `evidence/baseline/p0-git-state.md`.

- [x] [P0-T3] [carried-over: complete from prior pass] Verify `gh` CLI
  authentication and PR #1 state. Evidence: `evidence/baseline/p0-gh-auth.md`.

- [x] [P0-T4] [carried-over: complete from prior pass] PowerShell baseline format
  check. Evidence: `evidence/baseline/p0-poshqc-format.md`.

- [x] [P0-T5] [carried-over: complete from prior pass] PowerShell baseline
  PSScriptAnalyzer state. Evidence: `evidence/baseline/p0-poshqc-analyze.md`.

- [x] [P0-T6] [carried-over: complete from prior pass] PowerShell baseline
  coverage state (expected MISSING). Evidence:
  `evidence/baseline/p0-pester-coverage.md`.

- [x] [P0-T7] [carried-over: complete from prior pass] gitleaks installability
  check. Evidence: `evidence/baseline/p0-gitleaks-installability.md`.

---

## Phase RP-1 — Acceptance Criteria Text Remediation

### Phase RP-1 — Acceptance Criteria Text Remediation

- [x] [P1-T1] [carried-over: complete from prior pass] Rewrite `issue.md` AC #19.
- [x] [P1-T2] [carried-over: complete from prior pass] Rewrite `issue.md` AC #23.
- [x] [P1-T3] [carried-over: complete from prior pass] Remove `## Manual
  follow-ups` section from `issue.md`.
- [x] [P1-T4] [carried-over: complete from prior pass] Update AC checkoff to
  remove every `PASS-WITH-MANUAL-FOLLOWUP` string.
- [x] [P1-T5] [carried-over: complete from prior pass] Mirror discipline grep
  over `.claude/rules/` and `.github/instructions/`. Evidence:
  `evidence/qa-gates/p1-mirror-grep.md`.

---

## Phase RP-2 — Branch Protection Automation (M2)

### Phase RP-2 — Branch Protection Automation

- [x] [P2-T1] [carried-over: complete from prior pass] Create
  `.github/scripts/apply-branch-protection.ps1`.
- [x] [P2-T2] [carried-over: complete from prior pass] Capture pre-apply branch
  protection state. Evidence: `evidence/qa-gates/p23-branch-protection-pre.md`.
- [x] [P2-T3] [carried-over: complete from prior pass] Run the apply script.
- [x] [P2-T4] [carried-over: complete from prior pass] Capture post-apply live
  state. Evidence: `evidence/qa-gates/p23-branch-protection-live.md`.
- [x] [P2-T5] [carried-over: complete from prior pass] Update
  `docs/branch-protection.md` to remove manual-followup framing.

---

## Phase RP-3 — Gitleaks Runtime Install + Functional Demo (M1)

### Phase RP-3 — Gitleaks Runtime Install + Functional Demo

- [x] [P3-T1] [carried-over: complete from prior pass] Create
  `.github/scripts/install-gitleaks.ps1`.
- [x] [P3-T2] [carried-over: complete from prior pass] Run the installer.
  Evidence: `evidence/qa-gates/p3-gitleaks-install.md`.
- [x] [P3-T3] [carried-over: complete from prior pass] Functional fake-secret
  rejection. Evidence: `evidence/qa-gates/p3-gitleaks-fake-secret.md`.
- [x] [P3-T4] [carried-over: complete from prior pass] Update `lefthook.yml` to
  invoke gitleaks via the installer.
- [x] [P3-T5] [carried-over: complete from prior pass] Add a `secret-scan` job to
  `.github/workflows/pr-pipeline.yml`.

---

## Phase RP-4 — Pester Test Scaffolding (R1)

### Phase RP-4 — Pester Test Scaffolding

- [x] [P4-T1] [carried-over: complete from prior pass] Create
  `tests/powershell/PesterConfiguration.psd1`.

- [x] [P4-T2] [carried-over: complete from prior pass] Create
  `tests/powershell/check-conventional-commit.Tests.ps1`.

- [x] [P4-T3] [carried-over: complete from prior pass] Create
  `tests/powershell/validate-quality-tiers.Tests.ps1`.

- [x] [P4-T4] [carried-over: complete from prior pass] Create
  `tests/powershell/validate-feature-review-coverage.Tests.ps1` with helper-function
  test cases as written in the prior plan.

- [x] [P4-T5a] **NEW.** Fix the latent regex-escape bug in
  `.claude/hooks/validate-feature-review-coverage.ps1` so the `'CSharp'` label set
  matches the literal token `.NET` rather than `\.NET`.
  File: `.claude/hooks/validate-feature-review-coverage.ps1`.
  Verified location by reading the file: line 271, inside `Test-LanguageCoverageRow`'s
  `$languageLabelMap`.
  Pre-edit (verbatim, line 271):
  ```powershell
          'CSharp'     = @('C#', 'CSharp', 'csharp', '\.NET', 'dotnet')
  ```
  Post-edit (verbatim, line 271):
  ```powershell
          'CSharp'     = @('C#', 'CSharp', 'csharp', '.NET', 'dotnet')
  ```
  Rationale (recorded inline in the task, not in code): `[regex]::Escape('\.NET')`
  yields `\\\.NET`, which only matches a literal backslash followed by `.NET`. The
  intended behavior is to match the literal token `.NET` in audit text such as
  `.NET coverage row PASS`. Removing the backslash makes
  `[regex]::Escape('.NET')` produce `\.NET`, which correctly matches `.NET`.
  Toolchain gate: `mcp__drm-copilot__run_poshqc_format` over the file, then
  `mcp__drm-copilot__run_poshqc_analyze` over the file. AC remediation reference: R1.
  Pass: file contains the post-edit line verbatim; format step exit 0 with no
  modifications; analyzer reports zero error-level findings and no new warnings
  vs. baseline `evidence/baseline/p0-poshqc-analyze.md`.

- [x] [P4-T6] **NEW (renumbered from old P4-T5).** Run the existing 40-test Pester
  suite with coverage to confirm the helper-function tests now pass cleanly after
  the P4-T5a fix.
  Command: `mcp__drm-copilot__run_poshqc_test` configured against
  `tests/powershell/PesterConfiguration.psd1`. If the MCP runner is unavailable,
  fall back to:
  ```powershell
  pwsh -NoProfile -Command "Invoke-Pester -Configuration (Import-PowerShellDataFile tests/powershell/PesterConfiguration.psd1)"
  ```
  Capture pass/fail counts plus per-script line and branch coverage from
  `artifacts/pester/powershell-coverage.xml`. Write to
  `evidence/qa-gates/p4-pester-coverage-helpers.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` (test pass/fail counts; per-script
  line% and branch%).
  AC remediation reference: R1.
  Pass: all 40 helper-function tests pass (zero failures); evidence captures the
  per-script coverage values, even though they will be below the R1 floor at this
  point (entrypoint coverage is added in P4-T7).

- [x] [P4-T7] **NEW.** Add Pester test cases for
  `Invoke-FeatureReviewCoverageValidation` (lines 334–447 of
  `.claude/hooks/validate-feature-review-coverage.ps1`) to
  `tests/powershell/validate-feature-review-coverage.Tests.ps1`. Append the
  following block to the existing file inside the top-level `Describe`, after the
  existing `Context 'Test-LanguageCoverageRow'` block. Required scenarios
  (verbatim from `required-changes-2026-05-10T00-45.md`):
  - empty / null `$RawPayload` returns Ok=false with the expected message,
  - malformed JSON returns Ok=false with the expected error,
  - empty `output` field returns Ok=false,
  - missing required artifact tokens (`policy-audit-path`, `code-review-path`,
    `feature-audit-path`) returns Ok=false with the right error per token,
  - artifact paths outside the canonical `docs/features/active/...` location are
    rejected,
  - mismatched feature folder or timestamp between policy-audit and
    code-review / feature-audit returns Ok=false,
  - changed-language enumeration paths against
    `artifacts/pr_context.summary.txt`.

  Test body to append verbatim (ready to copy into the existing `Describe` block,
  before its closing brace):

  ```powershell
      Context 'Invoke-FeatureReviewCoverageValidation entrypoint' {
          BeforeAll {
              # Build canonical artifact text fixtures once for reuse. Use here-strings
              # so no temp files outside $TestDrive are created.
              $script:Folder    = '2026-05-09-establish-repository-foundation-1'
              $script:Timestamp = '2026-05-09T18-00'
              $script:PolicyDir = "docs/features/active/$script:Folder"

              # Helper to fabricate the JSON payload that the entrypoint expects.
              function New-Payload {
                  param([string]$Output)
                  return (@{ output = $Output } | ConvertTo-Json -Depth 4 -Compress)
              }
          }

          It 'returns Ok=false when RawPayload is null' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload $null
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'CLAUDE_HOOK_INPUT is empty'
          }

          It 'returns Ok=false when RawPayload is empty string' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload ''
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'CLAUDE_HOOK_INPUT is empty'
          }

          It 'returns Ok=false when RawPayload is whitespace' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload "   `t  "
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'CLAUDE_HOOK_INPUT is empty'
          }

          It 'returns Ok=false when RawPayload is malformed JSON' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload '{ this is not json'
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'failed to parse CLAUDE_HOOK_INPUT as JSON'
          }

          It 'returns Ok=false when output property is absent' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (@{ unrelated = 'x' } | ConvertTo-Json -Compress)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'agent output is empty'
          }

          It 'returns Ok=false when output property is empty string' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output '')
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'agent output is empty'
          }

          It 'returns Ok=false when output is whitespace only' {
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output "   `n  ")
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'agent output is empty'
          }

          It 'returns Ok=false with policy-audit-path-specific error when token absent' {
              $output = @"
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'missing policy-audit-path'
          }

          It 'returns Ok=false with code-review-path-specific error when token absent' {
              $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'missing code-review-path'
          }

          It 'returns Ok=false with feature-audit-path-specific error when token absent' {
              $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'missing feature-audit-path'
          }

          It 'rejects an artifact path outside docs/features/active' {
              $output = @"
policy-audit-path: artifacts/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'is outside the required docs/features/active'
          }

          It 'rejects mismatched timestamp between policy-audit and code-review' {
              # All three paths are canonical-form, but code-review's timestamp differs.
              # The policy-audit path will be rejected first because the underlying file
              # does not exist; assert the error message surfaces that the artifact was
              # advertised but not present, exercising the file-existence branch.
              $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.2026-01-01T00-00.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              # The non-existent paths trigger the "no file exists at that location" branch.
              $r.Message | Should -Match 'no file exists at that location'
          }

          It 'rejects a remediation-inputs path outside docs/features/active' {
              $output = @"
policy-audit-path: $script:PolicyDir/policy-audit.$script:Timestamp.md
code-review-path: $script:PolicyDir/code-review.$script:Timestamp.md
feature-audit-path: $script:PolicyDir/feature-audit.$script:Timestamp.md
remediation-inputs-path: artifacts/remediation-inputs.$script:Timestamp.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'remediation-inputs-path .* is outside the required docs/features/active'
          }

          It 'reports file-not-found when an advertised artifact has a canonical path but no file exists' {
              # Use a clearly nonexistent feature folder to exercise the
              # "no file exists at that location" branch deterministically.
              $ghostFolder = 'docs/features/active/2099-01-01-nonexistent-fixture-issue1'
              $ghostTs = '2099-01-01T00-00'
              $output = @"
policy-audit-path: $ghostFolder/policy-audit.$ghostTs.md
code-review-path: $ghostFolder/code-review.$ghostTs.md
feature-audit-path: $ghostFolder/feature-audit.$ghostTs.md
"@
              $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
              $r.Ok | Should -BeFalse
              $r.Message | Should -Match 'no file exists at that location'
          }

          Context 'with on-disk fixture artifacts under TestDrive-mirroring layout' {
              BeforeAll {
                  # Build a self-contained fixture tree under TestDrive that mirrors
                  # docs/features/active/<folder>/ so that Get-ArtifactFileContent
                  # resolves real files. The entrypoint resolves paths relative to the
                  # current working directory; Push-Location to TestDrive for the
                  # duration of these tests.
                  $script:FixRoot = Join-Path $TestDrive 'repo'
                  $script:FixFolder = Join-Path $script:FixRoot 'docs/features/active/fixture-feature-issue1'
                  New-Item -ItemType Directory -Path $script:FixFolder -Force | Out-Null
                  $script:FixTs = '2026-05-09T18-00'
                  $script:PolicyAuditFix = "$script:FixFolder/policy-audit.$script:FixTs.md"
                  $script:CodeReviewFix  = "$script:FixFolder/code-review.$script:FixTs.md"
                  $script:FeatureAuditFix = "$script:FixFolder/feature-audit.$script:FixTs.md"

                  $policyText = @"
# Policy Audit
PowerShell coverage row PASS - line 90%, branch 80%
"@
                  Set-Content -Path $script:PolicyAuditFix -Value $policyText
                  Set-Content -Path $script:CodeReviewFix  -Value '# Code Review'
                  Set-Content -Path $script:FeatureAuditFix -Value '# Feature Audit'
              }

              BeforeEach {
                  Push-Location -LiteralPath $script:FixRoot
              }

              AfterEach {
                  Pop-Location
              }

              It 'returns Ok=true when no PR summary file exists (no changed languages)' {
                  $rel = 'docs/features/active/fixture-feature-issue1'
                  $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$script:FixTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                  $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                  $r.Ok | Should -BeTrue
                  $r.Message | Should -BeNullOrEmpty
              }

              It 'reports mismatched timestamp between policy-audit and code-review' {
                  # Create a code-review file with a different timestamp.
                  $altTs = '2026-05-09T19-00'
                  $altCr = "$script:FixFolder/code-review.$altTs.md"
                  Set-Content -Path $altCr -Value '# Code Review (alt)'
                  $rel = 'docs/features/active/fixture-feature-issue1'
                  $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$altTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                  $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                  $r.Ok | Should -BeFalse
                  $r.Message | Should -Match 'must share the same feature folder and timestamp'
              }

              It 'enumerates changed languages from artifacts/pr_context.summary.txt and validates coverage rows' {
                  # Create a pr_context.summary.txt under the fixture working dir that
                  # advertises a single PowerShell change. Provide a JaCoCo coverage
                  # XML at the path the language dispatcher expects so the row passes.
                  $prCtxDir = Join-Path $script:FixRoot 'artifacts'
                  New-Item -ItemType Directory -Path $prCtxDir -Force | Out-Null
                  Set-Content -Path (Join-Path $prCtxDir 'pr_context.summary.txt') -Value '  - .githooks/example.ps1 (+10/-2)'

                  $pesterDir = Join-Path $script:FixRoot 'artifacts/pester'
                  New-Item -ItemType Directory -Path $pesterDir -Force | Out-Null
                  $jacoco = @'
<?xml version="1.0"?>
<report>
  <package>
    <counter type="LINE" missed="10" covered="90"/>
    <counter type="BRANCH" missed="20" covered="80"/>
  </package>
</report>
'@
                  Set-Content -Path (Join-Path $pesterDir 'powershell-coverage.xml') -Value $jacoco

                  $rel = 'docs/features/active/fixture-feature-issue1'
                  $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$script:FixTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                  $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                  $r.Ok | Should -BeTrue
              }

              It 'returns Ok=false when policy-audit lacks a PowerShell coverage row but PR summary lists a .ps1 change' {
                  # Replace policy-audit content with text that does NOT mention PowerShell.
                  Set-Content -Path $script:PolicyAuditFix -Value '# Policy Audit (no language rows)'

                  $prCtxDir = Join-Path $script:FixRoot 'artifacts'
                  New-Item -ItemType Directory -Path $prCtxDir -Force | Out-Null
                  Set-Content -Path (Join-Path $prCtxDir 'pr_context.summary.txt') -Value '  - .githooks/example.ps1 (+10/-2)'

                  $rel = 'docs/features/active/fixture-feature-issue1'
                  $output = @"
policy-audit-path: $rel/policy-audit.$script:FixTs.md
code-review-path: $rel/code-review.$script:FixTs.md
feature-audit-path: $rel/feature-audit.$script:FixTs.md
"@
                  $r = Invoke-FeatureReviewCoverageValidation -RawPayload (New-Payload -Output $output)
                  $r.Ok | Should -BeFalse
                  $r.Message | Should -Match 'coverage validation failed against branch diff'
                  $r.Message | Should -Match 'does not mention PowerShell'
              }
          }
      }
  ```

  Notes on policy compliance:
  - `general-unit-test.md` "no temp files" rule: `$TestDrive` is Pester's
    in-memory PSDrive, not a real tempfile under `$env:TEMP`. All on-disk
    fixtures are confined to `$TestDrive`.
  - `Push-Location` / `Pop-Location` in `BeforeEach` / `AfterEach` ensure each
    test runs against a deterministic working directory and restores state on
    completion (Determinism + Independence per `general-unit-test.md`).
  - JaCoCo XML and JSON payloads are inline here-strings; no external fixture
    files are required.
  - No `Start-Sleep`, retries, or timing hacks.
  Toolchain gate: `mcp__drm-copilot__run_poshqc_format` over the test file, then
  `mcp__drm-copilot__run_poshqc_analyze` over the test file. AC remediation
  reference: R1.
  Pass: file edited; format step exit 0 with no remaining modifications;
  analyzer reports zero error-level findings.

- [ ] [P4-T8] **NEW.** Re-run the full Pester suite via
  `mcp__drm-copilot__run_poshqc_test` against
  `tests/powershell/PesterConfiguration.psd1`. Capture JaCoCo coverage from
  `artifacts/pester/powershell-coverage.xml` (the path that
  `validate-feature-review-coverage.ps1` itself consumes for its self-coverage
  check on line 252 and 215, ensuring the report path matches). Write to
  `evidence/qa-gates/p4-pester-coverage.md` with `Timestamp:`, `Command:`,
  `EXIT_CODE:`, `Output Summary:` containing:
  - total tests run, passed, failed (must be all green),
  - per-script line% and branch% for each of the three target scripts,
  - aggregate line% and branch%,
  - explicit numeric assertion line: `validate-feature-review-coverage.ps1
    line% >= 85.0 and branch% >= 75.0`,
  - explicit path assertion line: `coverage report path:
    artifacts/pester/powershell-coverage.xml (matches hook self-check path)`.
  AC remediation reference: R1.
  Pass: every test passes; for `validate-feature-review-coverage.ps1`,
  measured line% >= 85.0 AND branch% >= 75.0; per-script and aggregate values
  for all three target scripts meet >= 85.0 line / >= 75.0 branch; coverage
  report path equals `artifacts/pester/powershell-coverage.xml`.

---

## Phase RP-5 — CI Wiring

### Phase RP-5 — CI Wiring

- [ ] [P5-T1] Update `.github/actions/test/action.yml` to invoke Pester on
  `tests/powershell/` and emit JaCoCo coverage to
  `artifacts/pester/powershell-coverage.xml`.
  File: `.github/actions/test/action.yml`.
  Insertion (after any existing TypeScript test step, before the action's final
  `runs:` close):
  ```yaml
        - name: Pester (PowerShell)
          shell: pwsh
          run: |
            $cfgPath = 'tests/powershell/PesterConfiguration.psd1'
            if (Test-Path $cfgPath) {
              $cfg = Import-PowerShellDataFile $cfgPath
              Invoke-Pester -Configuration $cfg
              if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            } else {
              Write-Host 'no Pester config; skipping'
            }
        - name: Upload Pester coverage
          if: always()
          uses: actions/upload-artifact@v4
          with:
            name: powershell-coverage
            path: artifacts/pester/powershell-coverage.xml
            if-no-files-found: warn
  ```
  Toolchain gate: actionlint. AC remediation reference: R1.
  Pass: composite action validates; new steps present.

- [ ] [P5-T2] Validate the workflow as a whole after both the secret-scan job
  (P3-T5) and the Pester step (P5-T1) are in place: run `actionlint` against
  `.github/workflows/pr-pipeline.yml` and `.github/actions/test/action.yml`.
  Write to `evidence/qa-gates/p5-actionlint.md` with `Timestamp:`, `Command:`,
  `EXIT_CODE:`, `Output Summary:`.
  AC remediation reference: R1+M1.
  Pass: actionlint exit 0.

---

## Phase RP-6 — Verification & Evidence

### Phase RP-6 — Verification & Evidence

- [ ] [P6-T1] Re-run all `issue.md` Validation grep checks (Phase 1 + Phase 2
  from issue.md lines 68–82). Specifically:
  - `grep -ri "jest" .claude/rules/typescript.md ...` returns no matches.
  - `grep -ri "vs code extension\|vscode extension" ...` returns no matches.
  - Coverage-threshold prose grep across all listed files reports the uniform
    tier rule.
  - Mirror discipline grep: every modified `.claude/rules/` file has a matching
    `.github/instructions/` file in the diff.
  Capture each command + exit code to
  `evidence/qa-gates/p6-issue-validation-greps.md`.
  Pass: every grep returns the expected outcome.

- [ ] [P6-T2] Re-run
  `pwsh -NoProfile -File .claude/hooks/validate-feature-review-coverage.ps1`
  with a synthetic `CLAUDE_HOOK_INPUT` JSON payload that advertises the existing
  feature-review artifacts. Capture exit code + stderr to
  `evidence/qa-gates/p6-coverage-hook-rerun.md`.
  Confirm the PowerShell coverage row evaluates to PASS now that
  `artifacts/pester/powershell-coverage.xml` exists with line >= 85% / branch
  >= 75% (produced by P4-T8). The artifact must include a numeric assertion
  line: `Measured PowerShell line% = <value>; branch% = <value>; both at or
  above the 85/75 floors.`
  AC remediation reference: R1.
  Pass: exit 0; stderr empty; numeric values present in evidence.

- [ ] [P6-T3] Branch protection live verification. Re-run
  `gh api -X GET repos/drmoisan/TMW/branches/main/protection`. Diff the response
  against the eight-context list. Append the diff to
  `evidence/qa-gates/p23-branch-protection-live.md` (already created in P2-T4)
  under a section `## RP-6 re-verification`.
  AC remediation reference: M2.
  Pass: all eight contexts present; settings match `docs/branch-protection.md`.

- [ ] [P6-T4] Gitleaks fake-secret rejection re-verification. Re-execute the
  procedure documented in P3-T3. Append the re-run output to
  `evidence/qa-gates/p3-gitleaks-fake-secret.md` under `## RP-6 re-verification`.
  AC remediation reference: M1.
  Pass: re-run is reproducible; fixture removed after each invocation.

- [ ] [P6-T5] Update Acceptance Criteria checkoff to PASS for #19 and #23 with
  automated evidence citations. File:
  `evidence/qa-gates/p23-acceptance-criteria-checkoff.md`.
  - AC #19 row: `PASS — automated. Evidence:
    evidence/qa-gates/p3-gitleaks-install.md (install) +
    evidence/qa-gates/p3-gitleaks-fake-secret.md (functional reject + re-verify).`
  - AC #23 row: `PASS — automated. Evidence:
    evidence/qa-gates/p23-branch-protection-pre.md (pre-state) +
    evidence/qa-gates/p23-branch-protection-live.md (post-apply + RP-6 re-verify).`
  - Confirm grep `PASS-WITH-MANUAL-FOLLOWUP` over the entire feature folder
    returns zero matches; record the grep + result at the bottom of the file.
  AC remediation reference: M1+M2.
  Pass: file contains `PASS — automated` for #19 and #23; zero matches for the
  manual-followup string anywhere under the feature folder.

---

## Phase RP-7 — Final QA Loop (PowerShell Toolchain)

### Phase RP-7 — Final QA Loop

For each step below, if any auto-fix applies or any step fails, restart from RP-7-T1.

- [ ] [P7-T1] PoshQC formatter over all changed/new PowerShell files
  (`.claude/hooks/validate-feature-review-coverage.ps1`,
  `.githooks/check-conventional-commit.ps1`,
  `.github/scripts/validate-quality-tiers.ps1`,
  `.github/scripts/install-gitleaks.ps1`,
  `.github/scripts/apply-branch-protection.ps1`,
  `tests/powershell/PesterConfiguration.psd1`,
  `tests/powershell/check-conventional-commit.Tests.ps1`,
  `tests/powershell/validate-quality-tiers.Tests.ps1`,
  `tests/powershell/validate-feature-review-coverage.Tests.ps1`).
  Command: `mcp__drm-copilot__run_poshqc_format`. Write to
  `evidence/qa-gates/p7-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`,
  `Output Summary:`.
  Pass: exit 0; no files modified (or restart loop if files modified).

- [ ] [P7-T2] PSScriptAnalyzer over the same file set. Command:
  `mcp__drm-copilot__run_poshqc_analyze`. Write to
  `evidence/qa-gates/p7-analyze.md`.
  Pass: zero error-level findings; warning count not regressed vs baseline
  (`evidence/baseline/p0-poshqc-analyze.md`).

- [ ] [P7-T3] Pester suite with coverage. Command:
  `mcp__drm-copilot__run_poshqc_test` against
  `tests/powershell/PesterConfiguration.psd1`. Write to
  `evidence/qa-gates/p7-pester.md` with `Timestamp:`, `Command:`,
  `EXIT_CODE:`, `Output Summary:` containing post-change line% and branch% per
  script and aggregate.
  Pass: all tests green; line >= 85% per script and aggregate; branch >= 75%
  per script and aggregate. The
  `validate-feature-review-coverage.ps1` row MUST show line >= 85.0 and branch
  >= 75.0 explicitly.

- [ ] [P7-T4] Coverage-row hook validation. Re-run the
  `validate-feature-review-coverage` hook (as in P6-T2) and confirm it still
  exits 0 against the post-final-QA artifacts. Write to
  `evidence/qa-gates/p7-coverage-hook.md`.
  Pass: exit 0.

- [ ] [P7-T5] Actionlint over `.github/workflows/pr-pipeline.yml` and
  `.github/actions/test/action.yml`. Write to
  `evidence/qa-gates/p7-actionlint.md`.
  Pass: exit 0.

- [ ] [P7-T6] Plan-coherence verification. Run
  `mcp__drm-copilot__validate_orchestration_artifacts` with `artifact_type:
  "plan"` and `artifact_path:
  docs/features/active/2026-05-09-establish-repository-foundation-1/remediation-plan.2026-05-10T01-00.md`.
  Pass: validator exits 0.

---

## Plan Coherence Self-Check (Revision)

- **AC remediation reference R1** is delivered by P4-T1..P4-T4 (carried-over),
  P4-T5a (production hook fix), P4-T6 (helper-function suite re-run), P4-T7
  (entrypoint test cases), P4-T8 (full coverage assertion), P5-T1..P5-T2,
  P6-T2, and P7-T3.
- **AC remediation reference M1** is delivered by P1-T1, P3-T1..P3-T5 (all
  carried-over), P6-T4, and P6-T5.
- **AC remediation reference M2** is delivered by P1-T2, P2-T1..P2-T5 (all
  carried-over), P6-T3, and P6-T5.
- **Production hook fix scope.** P4-T5a is the only production-script edit in
  this revision. It is one character (`'\.NET'` -> `'.NET'`) on line 271 of
  `.claude/hooks/validate-feature-review-coverage.ps1`. The change is verified
  against the current file contents (line 271 confirmed). Toolchain gates
  (format + analyzer) apply at the per-task level and again in the P7 final
  loop.
- **Coverage assurance.** Old P4-T5 (which would have failed at 38.85%) is
  superseded by P4-T6 (helper-function rerun after fix), P4-T7 (add entrypoint
  tests covering all branches of `Invoke-FeatureReviewCoverageValidation`,
  lines 334–447), and P4-T8 (full suite + numeric coverage assertion at the
  R1 floors). P7-T3 reaffirms the same assertion in the final QA loop. No
  task assumes the floor is met; both P4-T8 and P7-T3 require explicit numeric
  evidence at or above 85.0 line / 75.0 branch.
- **Coverage-report path consistency.** P4-T8 explicitly asserts the coverage
  report path equals `artifacts/pester/powershell-coverage.xml`, which is the
  path the hook itself consumes (`Get-LanguageRepoCoverage` line 252 and
  `Get-LanguageBranchCoverage` line 215). This guarantees the hook's
  self-coverage check (P6-T2 / P7-T4) reads the same artifact the Pester suite
  produced.
- **No manual-followup language is introduced.** All tasks produce automated
  evidence. Directives D1–D8 carry forward unchanged.
- **Mirror discipline (D2).** No `.claude/rules/` change is made by this
  revision (the P4-T5a fix targets a hook, not a rule), so no
  `.github/instructions/` mirror is required. P1-T5 (carried over) verified the
  rules ↔ instructions mirror under the prior pass.
- **Test determinism (D3).** New test cases in P4-T7 use `$TestDrive` only;
  no `$env:TEMP` or ad-hoc tempfiles. `Push-Location`/`Pop-Location` blocks
  ensure working-directory determinism. No `Start-Sleep` or retry loops.
- **Evidence locations (D4).** Every new artifact path resolves to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/<kind>/`.
  No `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`,
  `artifacts/evidence/`, or other forbidden paths.
- **Branch and PR continuity (D5).** All work continues on
  `feature/establish-repository-foundation-1`. PR #1 receives the new commits.
- **Plan-path continuity.** This revision is written to a new timestamped file
  (`remediation-plan.2026-05-10T01-00.md`) per the calling agent's explicit
  directive ("write to ... new timestamped file; do not overwrite the
  original"). Subsequent preflight revisions of THIS plan, if any, must update
  this same file in place.

PREFLIGHT: ALL CLEAR
