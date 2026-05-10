---
artifact: remediation-plan
feature: 2026-05-09-establish-repository-foundation-1
issue: 1
branch: feature/establish-repository-foundation-1
base: main (a2a462662a9d46f955b65f3e6bcc0f7887cbe04d)
timestamp: 2026-05-10T00-00
mode: full-feature
---

# Remediation Atomic Plan — Issue #1: Establish Repository Foundation

This plan resolves the three remediation drivers from
`remediation-inputs.2026-05-09T18-00.md`:

- **R1** — Pester v5 test coverage for the three new/modified PowerShell scripts
  (line >= 85%, branch >= 75% per the uniform tier rule established by this branch).
- **M1** — Replace AC #19 "PASS-WITH-MANUAL-FOLLOWUP" with an automated, deterministic
  gitleaks runtime install + functional fake-secret demonstration.
- **M2** — Replace AC #23 "PASS-WITH-MANUAL-FOLLOWUP" with automated branch-protection
  rule application via `gh api -X PUT` and verification via `gh api -X GET`.

All evidence is written under
`docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/<kind>/`
per `evidence-and-timestamp-conventions`. No `artifacts/baselines/`,
`artifacts/qa/`, `artifacts/coverage/`, or other non-canonical paths are used.

The plan executes on the existing branch `feature/establish-repository-foundation-1`
(PR #1). No new branches are created.

---

## Phase RP-0 — Preflight & Baseline

### Phase RP-0 — Preflight & Baseline

- [x] [P0-T1] Read `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`,
  `.claude/rules/powershell.md`, `.claude/skills/powershell-qa-gate/SKILL.md`,
  `.claude/skills/atomic-plan-contract/SKILL.md`, and
  `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. Record file paths and
  timestamps to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/phase0-instructions-read.md`
  with `Timestamp:`, `Policy Order:`, and the explicit list of files read.
  Pass: artifact exists with all six files listed.

- [x] [P0-T2] Capture git state baseline. Run `git status --porcelain` and
  `git rev-parse --abbrev-ref HEAD` and `git log -1 --pretty=oneline`. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/p0-git-state.md`
  with `Timestamp:`, `Command:` (one entry per command), `EXIT_CODE:`, and
  `Output Summary:` (must show branch == `feature/establish-repository-foundation-1`).
  Pass: branch matches; working tree clean or only contains the in-progress remediation files.

- [x] [P0-T3] Verify `gh` CLI authentication. Run `gh auth status` and
  `gh api repos/drmoisan/TMW/pulls/1 --jq '{number,state,head:.head.ref}'`. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/p0-gh-auth.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (must show
  `Logged in to github.com account drmoisan` and PR #1 `state == OPEN`,
  `head.ref == feature/establish-repository-foundation-1`).
  Pass: gh authenticated; PR #1 open; head matches branch.

- [x] [P0-T4] Capture PowerShell baseline format check (no test scope yet — tests do not exist).
  Run `mcp__drm-copilot__run_poshqc_format` over `.claude/hooks/validate-feature-review-coverage.ps1`,
  `.githooks/check-conventional-commit.ps1`, `.github/scripts/validate-quality-tiers.ps1`. Write
  to `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/p0-poshqc-format.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  Pass: format check exit 0 (no auto-fix changes) — if changes occur, restart loop after committing.

- [x] [P0-T5] Capture PowerShell baseline analyzer state. Run
  `mcp__drm-copilot__run_poshqc_analyze` over the three target scripts. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/p0-poshqc-analyze.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (rule violation count + severity).
  Pass: zero error-level findings; warning count recorded for delta comparison in final QA.

- [x] [P0-T6] Capture PowerShell baseline coverage state (expected MISSING). Confirm absence of
  `tests/powershell/` and absence of `artifacts/pester/powershell-coverage.xml` by running
  `Test-Path tests/powershell` and `Test-Path artifacts/pester/powershell-coverage.xml`. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/p0-pester-coverage.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` recording `LineCoverage: UNAVAILABLE`,
  `BranchCoverage: UNAVAILABLE`, `Reason: no Pester suite exists at baseline (R1)`.
  Pass: artifact records the baseline gap explicitly so the remediation delta is auditable.

- [x] [P0-T7] Verify gitleaks installability path is reachable. Run
  `gh release list -R gitleaks/gitleaks --limit 1` to confirm release feed accessibility, and
  `winget search --id gitleaks.gitleaks --source winget` to confirm winget fallback. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/p0-gitleaks-installability.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (latest release tag and
  winget package id).
  Pass: at least one of the two channels returns a usable result; both recorded.

---

## Phase RP-1 — Acceptance Criteria Text Remediation

### Phase RP-1 — Acceptance Criteria Text Remediation

- [x] [P1-T1] Rewrite `issue.md` Acceptance Criterion #19 to remove manual-followup framing.
  File: `docs/features/active/2026-05-09-establish-repository-foundation-1/issue.md`.
  Pre-edit (line 50):
  ```
  19. Secret scanning (gitleaks or equivalent) runs on every commit and blocks commits containing credentials. A test commit containing a fake secret is rejected (verifiable in evidence).
  ```
  Post-edit:
  ```
  19. Secret scanning (gitleaks) runs on every commit and blocks commits containing credentials. Verification is automated: `.github/scripts/install-gitleaks.ps1` provisions the gitleaks binary deterministically; a synthetic-secret fixture matching the `graph-client-secret` rule is staged; `gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml` is invoked against it; the run exits non-zero and emits a redacted match. Exit code, redacted finding, and the install script invocation are captured in `evidence/qa-gates/p3-gitleaks-fake-secret.md`. The CI workflow runs the same install script and a `gitleaks detect` step on PR diffs.
  ```
  Toolchain gate: none (Markdown). AC remediation reference: M1.
  Pass: post-edit text present verbatim; no occurrence of `manual follow-up` or `MANUAL-FOLLOWUP`
  remains in AC #19.

- [x] [P1-T2] Rewrite `issue.md` Acceptance Criterion #23 to remove manual-followup framing.
  File: `docs/features/active/2026-05-09-establish-repository-foundation-1/issue.md`.
  Pre-edit (line 54):
  ```
  23. Branch protection requirements that the PR pipeline must pass are documented (configuration of the actual protection rule via `gh` CLI is recorded as a manual follow-up step in the feature folder if it cannot be applied programmatically).
  ```
  Post-edit:
  ```
  23. Branch protection requirements that the PR pipeline must pass are documented in `docs/branch-protection.md` and applied programmatically via `.github/scripts/apply-branch-protection.ps1`, which calls `gh api -X PUT repos/drmoisan/TMW/branches/main/protection` with the eight required contexts (`tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration`), `enforce_admins=true`, `required_pull_request_reviews.required_approving_review_count=1`, `required_pull_request_reviews.dismiss_stale_reviews=true`, `required_linear_history=true`, and `restrictions=null`. Verification: `gh api -X GET repos/drmoisan/TMW/branches/main/protection` returns each of the eight contexts and the live JSON is captured in `evidence/qa-gates/p23-branch-protection-live.md`.
  ```
  Toolchain gate: none. AC remediation reference: M2.
  Pass: post-edit text present verbatim; no `manual follow-up` / `PENDING (manual)` text remains in AC #23.

- [x] [P1-T3] Remove the `## Manual follow-ups` section from `issue.md`.
  File: `docs/features/active/2026-05-09-establish-repository-foundation-1/issue.md`.
  Pre-edit (lines 90-93):
  ```
  ## Manual follow-ups

  - **Branch protection rule application** — Status: PENDING. Owner: repository administrator. The GitHub API call to apply the branch-protection rule could not be issued from the executor session (no authenticated `gh` CLI). The rule definition and the exact `gh api` command are recorded in `docs/branch-protection.md`. AC #23 is satisfied here by documentation; the manual application step must be executed by a repository administrator before the rule is active on `main`.
  ```
  Post-edit:
  ```
  ```
  (section removed entirely; preceding `## References` section ends the file).
  Toolchain gate: none. AC remediation reference: M1+M2.
  Pass: `grep -n "Manual follow-ups" docs/features/active/2026-05-09-establish-repository-foundation-1/issue.md`
  returns zero matches.

- [x] [P1-T4] Update Acceptance Criteria checkoff artifact to remove every
  "PASS-WITH-MANUAL-FOLLOWUP" string. File:
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p23-acceptance-criteria-checkoff.md`.
  Operation: replace every occurrence of `PASS-WITH-MANUAL-FOLLOWUP` with either
  `PASS` (citing the new automated evidence path produced in Phase RP-2 / RP-3) or
  `FAIL — pending automated remediation in this plan` for any AC whose evidence
  is not yet on disk at the time of the edit.
  - AC #19 row: replace verdict text with `FAIL — pending P3 (gitleaks runtime functional demo). Evidence will be at evidence/qa-gates/p3-gitleaks-fake-secret.md after RP-3.`
  - AC #23 row: replace verdict text with `FAIL — pending P2 (branch protection automated apply). Evidence will be at evidence/qa-gates/p23-branch-protection-live.md after RP-2.`
  - Append a note: `These rows will be updated to PASS in RP-6e after automated evidence is captured.`
  Toolchain gate: none. AC remediation reference: M1+M2.
  Pass: `grep -ri "PASS-WITH-MANUAL-FOLLOWUP" docs/features/active/2026-05-09-establish-repository-foundation-1/`
  returns zero matches.

- [x] [P1-T5] Mirror discipline check for AC text edits. Confirm `.claude/rules/` and
  `.github/instructions/` files do not contain `PASS-WITH-MANUAL-FOLLOWUP` or
  manual-followup framing tied to AC #19 / AC #23. Run `grep -ri "PASS-WITH-MANUAL-FOLLOWUP\|manual follow-up" .claude/rules/ .github/instructions/`.
  If any matches exist, edit them in lockstep (rule + mirror) per AC #75 mirror discipline.
  Write evidence to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p1-mirror-grep.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  Pass: zero matches in `.claude/rules/` and `.github/instructions/`.

---

## Phase RP-2 — Branch Protection Automation (M2)

### Phase RP-2 — Branch Protection Automation

- [x] [P2-T1] Create `.github/scripts/apply-branch-protection.ps1`. New file body:

  ```powershell
  #Requires -Version 7.0
  <#
  .SYNOPSIS
    Applies the documented branch protection rule on main via the gh CLI.
  .DESCRIPTION
    Calls `gh api -X PUT repos/<owner>/<repo>/branches/<branch>/protection` with the
    eight required status check contexts and supporting protection settings defined
    in docs/branch-protection.md. Idempotent: re-applying yields the same final state.
  .PARAMETER Owner
    Repository owner (default: drmoisan).
  .PARAMETER Repo
    Repository name (default: TMW).
  .PARAMETER Branch
    Protected branch name (default: main).
  .EXAMPLE
    pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1
  #>
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
      [string]$Owner = 'drmoisan',
      [string]$Repo = 'TMW',
      [string]$Branch = 'main'
  )

  $ErrorActionPreference = 'Stop'

  $contexts = @(
      'tier-classification',
      'stage-1-format',
      'stage-2-lint',
      'stage-3-typecheck',
      'stage-4-architecture',
      'stage-5-test',
      'stage-6-contract',
      'stage-7-integration'
  )

  $endpoint = "repos/$Owner/$Repo/branches/$Branch/protection"

  $ghArgs = @('api', '-X', 'PUT', $endpoint,
      '-F', 'required_status_checks.strict=true')
  foreach ($ctx in $contexts) {
      $ghArgs += @('-F', "required_status_checks.contexts[]=$ctx")
  }
  $ghArgs += @(
      '-F', 'enforce_admins=true',
      '-F', 'required_pull_request_reviews.required_approving_review_count=1',
      '-F', 'required_pull_request_reviews.dismiss_stale_reviews=true',
      '-F', 'required_linear_history=true',
      '-f', 'restrictions='
  )

  if ($PSCmdlet.ShouldProcess($endpoint, 'PUT branch protection')) {
      & gh @ghArgs
      if ($LASTEXITCODE -ne 0) {
          throw "gh api PUT $endpoint failed with exit code $LASTEXITCODE"
      }
      Write-Output "Branch protection applied: $endpoint"
  }
  ```
  Toolchain gate: PowerShell formatter + analyzer. AC remediation reference: M2.
  Pass: file present at `.github/scripts/apply-branch-protection.ps1`; PSScriptAnalyzer
  reports zero error-level findings.

- [x] [P2-T2] Capture pre-apply branch protection state. Run
  `gh api -X GET repos/drmoisan/TMW/branches/main/protection 2>&1` (acceptable to be
  non-zero if no protection is set; capture either way). Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p23-branch-protection-pre.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (full JSON body or
  the 404 / "Branch not protected" message).
  AC remediation reference: M2.
  Pass: artifact records the pre-state (any exit code is acceptable).

- [x] [P2-T3] Run `pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1`.
  Capture stdout/stderr.
  AC remediation reference: M2.
  Pass: exit 0; stdout contains `Branch protection applied`.

- [x] [P2-T4] Capture post-apply live branch protection state. Run
  `gh api -X GET repos/drmoisan/TMW/branches/main/protection`. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p23-branch-protection-live.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. The full response JSON
  must be appended verbatim. The summary must explicitly assert that each of the eight
  contexts is present in `required_status_checks.contexts`.
  AC remediation reference: M2.
  Pass: exit 0; all eight contexts present in the JSON response.

- [x] [P2-T5] Update `docs/branch-protection.md` to remove manual-followup framing and
  reference the apply script.
  File: `docs/branch-protection.md`.
  Pre-edit (lines 1-6):
  ```
  # Branch Protection Requirements

  This document records the branch protection rule that must be active on the `main` branch.
  Application of the rule via the GitHub API is recorded as a manual follow-up because the
  executor session does not have authenticated `gh` CLI access.
  ```
  Post-edit:
  ```
  # Branch Protection Requirements

  This document records the branch protection rule that is active on the `main` branch.
  The rule is applied programmatically by `.github/scripts/apply-branch-protection.ps1`
  and verified by `gh api -X GET repos/drmoisan/TMW/branches/main/protection`.
  ```
  Pre-edit (lines 51-55):
  ```
  ## Manual follow-up record

  Status: PENDING (manual). Owner: repo administrator. Apply once authenticated `gh` CLI
  access is available. Verification: re-run the command with `-X GET` and confirm each
  context appears in the response payload.
  ```
  Post-edit:
  ```
  ## Application record

  Status: AUTOMATED. Apply: `pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1`.
  Verify: `gh api -X GET repos/drmoisan/TMW/branches/main/protection` and confirm each of
  the eight contexts is present in `required_status_checks.contexts`.
  ```
  Toolchain gate: none (Markdown). AC remediation reference: M2.
  Pass: `grep -i "manual follow-up\|PENDING (manual)" docs/branch-protection.md` returns
  zero matches.

---

## Phase RP-3 — Gitleaks Runtime Install + Functional Demo (M1)

### Phase RP-3 — Gitleaks Runtime Install + Functional Demo

- [x] [P3-T1] Create `.github/scripts/install-gitleaks.ps1`. New file body:

  ```powershell
  #Requires -Version 7.0
  <#
  .SYNOPSIS
    Idempotent gitleaks installer (Windows-first, with linux/macos branches for CI).
  .DESCRIPTION
    Resolves the gitleaks binary via two channels in this order:
      1. winget install --id gitleaks.gitleaks --silent (Windows interactive/CI).
      2. gh release download from gitleaks/gitleaks (asset matching the host OS+arch),
         extracted into <repo>/.tools/gitleaks/.
    Writes the resolved binary path to stdout. Idempotent: if the binary already
    resolves on PATH or under .tools/gitleaks/, exits 0 without re-installing.
  .PARAMETER Version
    Optional pinned release tag (e.g. v8.18.4). Default: latest.
  .PARAMETER ToolsDir
    Local install directory. Default: <repo>/.tools/gitleaks.
  #>
  [CmdletBinding()]
  param(
      [string]$Version = 'latest',
      [string]$ToolsDir = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', '.tools', 'gitleaks')
  )

  $ErrorActionPreference = 'Stop'

  function Resolve-GitleaksOnPath {
      $cmd = Get-Command -Name gitleaks -ErrorAction SilentlyContinue
      if ($cmd) { return $cmd.Source }
      return $null
  }

  function Resolve-GitleaksInToolsDir {
      param([string]$Dir)
      $exe = if ($IsWindows) { 'gitleaks.exe' } else { 'gitleaks' }
      $candidate = Join-Path -Path $Dir -ChildPath $exe
      if (Test-Path -LiteralPath $candidate) { return (Resolve-Path $candidate).Path }
      return $null
  }

  $existing = Resolve-GitleaksOnPath
  if ($existing) {
      Write-Output $existing
      exit 0
  }
  $existing = Resolve-GitleaksInToolsDir -Dir $ToolsDir
  if ($existing) {
      Write-Output $existing
      exit 0
  }

  if ($IsWindows) {
      $winget = Get-Command -Name winget -ErrorAction SilentlyContinue
      if ($winget) {
          & winget install --id gitleaks.gitleaks --silent --accept-package-agreements --accept-source-agreements
          $resolved = Resolve-GitleaksOnPath
          if ($resolved) {
              Write-Output $resolved
              exit 0
          }
      }
  }

  if (-not (Test-Path -LiteralPath $ToolsDir)) {
      New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
  }

  $assetPattern = if ($IsWindows) { 'gitleaks_*_windows_x64.zip' }
                  elseif ($IsMacOS) { 'gitleaks_*_darwin_x64.tar.gz' }
                  else { 'gitleaks_*_linux_x64.tar.gz' }

  $ghArgs = @('release', 'download')
  if ($Version -ne 'latest') { $ghArgs += @($Version) }
  $ghArgs += @('-R', 'gitleaks/gitleaks', '-p', $assetPattern, '-D', $ToolsDir, '--clobber')
  & gh @ghArgs
  if ($LASTEXITCODE -ne 0) {
      throw "gh release download failed with exit $LASTEXITCODE"
  }

  $archive = Get-ChildItem -Path $ToolsDir -Filter $assetPattern | Select-Object -First 1
  if (-not $archive) { throw "No gitleaks archive matched $assetPattern under $ToolsDir" }

  if ($archive.Extension -eq '.zip') {
      Expand-Archive -Path $archive.FullName -DestinationPath $ToolsDir -Force
  } else {
      tar -xzf $archive.FullName -C $ToolsDir
      if ($LASTEXITCODE -ne 0) { throw "tar extract failed with exit $LASTEXITCODE" }
  }

  $resolved = Resolve-GitleaksInToolsDir -Dir $ToolsDir
  if (-not $resolved) { throw "gitleaks binary not found in $ToolsDir after extraction" }
  Write-Output $resolved
  exit 0
  ```
  Toolchain gate: PowerShell formatter + analyzer. AC remediation reference: M1.
  Pass: file present; analyzer error-level findings == 0.

- [x] [P3-T2] Run `pwsh -NoProfile -File .github/scripts/install-gitleaks.ps1` and capture
  stdout (resolved binary path) + exit code. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p3-gitleaks-install.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (resolved path,
  installer channel used, version reported by `<resolved> version`).
  AC remediation reference: M1.
  Pass: exit 0; resolved path exists; `<resolved> version` returns a semver tag.

- [x] [P3-T3] Functional fake-secret demonstration. Replace the deferred placeholder file
  at `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p3-gitleaks-fake-secret.md`.
  Procedure (executed in the executor session, not in this plan):
  1. Create a temporary fixture file at the repo root (path:
     `tmp-secret-fixture-issue1.txt`, NOT under `docs/`, since `docs/` is allowlisted in
     `.gitleaks.toml`). Content: `graph_client_secret = "AKIAABCDEFGHIJKLMNOP1234567890"`.
  2. `git add tmp-secret-fixture-issue1.txt`.
  3. Run `& <resolved-gitleaks> protect --staged --no-banner --redact --config=.gitleaks.toml`
     and capture stdout/stderr/exit code.
  4. `git restore --staged tmp-secret-fixture-issue1.txt` then
     `Remove-Item tmp-secret-fixture-issue1.txt -Force`.
  5. Write evidence with `Timestamp:`, `Command:`, `EXIT_CODE:` (must be non-zero),
     `Output Summary:` containing the redacted match line and rule id `graph-client-secret`,
     and a closing line `WorkingTreeRestored: true`.
  AC remediation reference: M1.
  Pass: exit code non-zero; stdout contains `graph-client-secret`; redacted match present;
  `tmp-secret-fixture-issue1.txt` no longer exists in the working tree after step 4.

- [x] [P3-T4] Update `lefthook.yml` to invoke gitleaks via a path that the install script
  provisions when not on PATH. File: `lefthook.yml`.
  Pre-edit (lines 8-12):
  ```yaml
  pre-commit:
    parallel: true
    commands:
      gitleaks-staged:
        run: gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml
  ```
  Post-edit:
  ```yaml
  pre-commit:
    parallel: true
    commands:
      gitleaks-staged:
        run: pwsh -NoProfile -Command "$bin = & .github/scripts/install-gitleaks.ps1; & $bin protect --staged --no-banner --redact --config=.gitleaks.toml"
  ```
  Toolchain gate: none (YAML; CI lints later). AC remediation reference: M1.
  Pass: post-edit text present; subsequent `lefthook run pre-commit` resolves the binary
  via the installer.

- [x] [P3-T5] Add a `secret-scan` job to `.github/workflows/pr-pipeline.yml` that calls
  the install script and runs `gitleaks detect` over the PR diff.
  File: `.github/workflows/pr-pipeline.yml`.
  Insertion: a new job named `secret-scan` parallel to existing stage jobs. Job body:
  ```yaml
    secret-scan:
      runs-on: windows-latest
      steps:
        - uses: actions/checkout@v4
          with:
            fetch-depth: 0
        - name: Install gitleaks
          shell: pwsh
          run: |
            $bin = & .github/scripts/install-gitleaks.ps1
            "GITLEAKS_BIN=$bin" | Out-File -FilePath $env:GITHUB_ENV -Append
        - name: Scan PR diff
          shell: pwsh
          run: |
            & $env:GITLEAKS_BIN detect --no-banner --redact --config=.gitleaks.toml --log-opts="origin/${{ github.base_ref }}..HEAD"
  ```
  Toolchain gate: workflow lint (actionlint). AC remediation reference: M1.
  Pass: job present; actionlint reports zero errors against the file (capture in final QA).

---

## Phase RP-4 — Pester Test Scaffolding (R1)

### Phase RP-4 — Pester Test Scaffolding

- [ ] [P4-T1] Create `tests/powershell/PesterConfiguration.psd1`. New file body:

  ```powershell
  @{
      Run        = @{
          Path = @(
              'tests/powershell/check-conventional-commit.Tests.ps1',
              'tests/powershell/validate-quality-tiers.Tests.ps1',
              'tests/powershell/validate-feature-review-coverage.Tests.ps1'
          )
          Exit = $true
      }
      CodeCoverage = @{
          Enabled              = $true
          Path                 = @(
              '.githooks/check-conventional-commit.ps1',
              '.github/scripts/validate-quality-tiers.ps1',
              '.claude/hooks/validate-feature-review-coverage.ps1'
          )
          OutputFormat         = 'JaCoCo'
          OutputPath           = 'artifacts/pester/powershell-coverage.xml'
          CoveragePercentTarget = 85
          UseBreakpoints       = $false
      }
      TestResult = @{
          Enabled    = $true
          OutputPath = 'artifacts/pester/powershell-tests.xml'
          OutputFormat = 'NUnitXml'
      }
      Output     = @{
          Verbosity = 'Detailed'
      }
  }
  ```
  Note: emits JaCoCo XML to the path that `Get-LanguageRepoCoverage` /
  `Get-LanguageBranchCoverage` already expect (`artifacts/pester/powershell-coverage.xml`,
  per `.claude/hooks/validate-feature-review-coverage.ps1` lines 215, 252).
  Toolchain gate: format + analyzer. AC remediation reference: R1.
  Pass: file present; analyzer clean.

- [ ] [P4-T2] Create `tests/powershell/check-conventional-commit.Tests.ps1`. New file body:

  ```powershell
  #Requires -Version 7.0
  #Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

  Describe 'check-conventional-commit.ps1' {
      BeforeAll {
          $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../.githooks/check-conventional-commit.ps1").Path
          $script:Fixtures = Join-Path -Path $TestDrive -ChildPath 'fixtures'
          New-Item -ItemType Directory -Path $script:Fixtures -Force | Out-Null

          function Invoke-Hook {
              param([string]$MessageFile)
              $output = & pwsh -NoProfile -File $script:UnderTest -MessageFile $MessageFile 2>&1
              return @{ Output = ($output -join [Environment]::NewLine); ExitCode = $LASTEXITCODE }
          }
      }

      Context 'missing message file' {
          It 'exits 2 when the file does not exist' {
              $result = Invoke-Hook -MessageFile (Join-Path -Path $script:Fixtures -ChildPath 'does-not-exist.txt')
              $result.ExitCode | Should -Be 2
              $result.Output | Should -Match 'Commit message file not found'
          }
      }

      Context 'empty / comment-only message' {
          It 'exits 3 when message is empty' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'empty.txt'
              Set-Content -Path $f -Value ''
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 3
          }

          It 'exits 3 when message contains only comment lines' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'comments.txt'
              Set-Content -Path $f -Value "# just a comment`n# another"
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 3
          }

          It 'exits 3 when first non-comment line is whitespace' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'whitespace.txt'
              Set-Content -Path $f -Value "# header`n   `n# trailing"
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 3
          }
      }

      Context 'invalid format' {
          It 'exits 4 for "WIP fix things"' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'wip.txt'
              Set-Content -Path $f -Value 'WIP fix things'
              $r = Invoke-Hook -MessageFile $f
              $r.ExitCode | Should -Be 4
              $r.Output | Should -Match 'Conventional Commits'
          }

          It 'exits 4 for unknown type "thing: do stuff"' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'unknown-type.txt'
              Set-Content -Path $f -Value 'thing: do stuff'
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 4
          }
      }

      Context 'valid format' {
          It 'exits 0 for "feat: add foo"' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'feat.txt'
              Set-Content -Path $f -Value 'feat: add foo'
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
          }

          It 'exits 0 for scoped "feat(taskpane): add classifier seam"' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'scoped.txt'
              Set-Content -Path $f -Value 'feat(taskpane): add classifier seam'
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
          }

          It 'exits 0 for breaking-change "feat!: rewrite API"' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'breaking.txt'
              Set-Content -Path $f -Value 'feat!: rewrite API'
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
          }

          It 'exits 0 for scoped breaking "fix(api)!: rename endpoint"' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'scoped-breaking.txt'
              Set-Content -Path $f -Value 'fix(api)!: rename endpoint'
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
          }

          It 'exits 0 when comment lines precede a valid first line' {
              $f = Join-Path -Path $script:Fixtures -ChildPath 'comments-then-valid.txt'
              Set-Content -Path $f -Value "# template`nfeat: x"
              (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
          }

          It 'exits 0 for each allowed type' {
              foreach ($t in 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert') {
                  $f = Join-Path -Path $script:Fixtures -ChildPath "$t.txt"
                  Set-Content -Path $f -Value "${t}: ok"
                  (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0 -Because "type '$t' must be allowed"
              }
          }
      }
  }
  ```
  Note on `general-unit-test.md` "no tempfile" rule: `$TestDrive` is Pester's
  in-memory PSDrive, NOT a real tempfile under `$env:TEMP`. Pester documents `$TestDrive`
  as the policy-compliant fixture location. If repo policy disallows `$TestDrive`, the
  alternative is to invoke the script with `-MessageFile` pointing at a string-content
  PSDrive entry created via `New-PSDrive`. Use `$TestDrive` unless the executor session
  flags it.
  Toolchain gate: format + analyzer + Pester. AC remediation reference: R1.
  Pass: analyzer clean; tests run green when Pester executes them.

- [ ] [P4-T3] Create `tests/powershell/validate-quality-tiers.Tests.ps1`. New file body:

  ```powershell
  #Requires -Version 7.0
  #Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

  Describe 'validate-quality-tiers.ps1' {
      BeforeAll {
          $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../.github/scripts/validate-quality-tiers.ps1").Path
          $script:Fix = Join-Path -Path $TestDrive -ChildPath 'cfg'
          New-Item -ItemType Directory -Path $script:Fix -Force | Out-Null

          function Invoke-Validator {
              param([string]$ConfigPath)
              $output = & pwsh -NoProfile -File $script:UnderTest -ConfigPath $ConfigPath 2>&1
              return @{ Output = ($output -join [Environment]::NewLine); ExitCode = $LASTEXITCODE }
          }
      }

      It 'exits 2 when config is missing' {
          $r = Invoke-Validator -ConfigPath (Join-Path -Path $script:Fix -ChildPath 'absent.yml')
          $r.ExitCode | Should -Be 2
          $r.Output | Should -Match 'not found'
      }

      It 'exits 3 when config is empty' {
          $p = Join-Path -Path $script:Fix -ChildPath 'empty.yml'
          Set-Content -Path $p -Value ''
          (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 3
      }

      It 'exits 4 when projects: key is missing' {
          $p = Join-Path -Path $script:Fix -ChildPath 'no-projects.yml'
          Set-Content -Path $p -Value "version: 1`nfoo: bar"
          (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 4
      }

      It 'exits 5 on invalid tier value' {
          $p = Join-Path -Path $script:Fix -ChildPath 'bad-tier.yml'
          Set-Content -Path $p -Value @"
  projects:
    - path: ./
      tier: t9
  "@
          (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 5
      }

      It 'exits 6 when an existing project directory is not declared' {
          # Repo-root validation needed; the live repo currently contains a project
          # directory (at minimum the TS scaffold). A cfg listing only an unrelated path
          # must trigger inventory mismatch.
          $p = Join-Path -Path $script:Fix -ChildPath 'mismatch.yml'
          Set-Content -Path $p -Value @"
  projects:
    - path: nonexistent-elsewhere
      tier: t1
  "@
          (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 6
      }

      It 'exits 0 against the live repo quality-tiers.yml' {
          $live = (Resolve-Path "$PSScriptRoot/../../quality-tiers.yml").Path
          (Invoke-Validator -ConfigPath $live).ExitCode | Should -Be 0
      }

      It 'accepts each valid tier value t1..t4' {
          foreach ($t in 't1', 't2', 't3', 't4') {
              $p = Join-Path -Path $script:Fix -ChildPath "tier-$t.yml"
              # Use the live repo project paths so inventory check passes; cheapest path
              # is to copy the live file's projects: block. For determinism, emulate by
              # symlinking would be wrong; instead, validate via re-reading the live file.
              $liveRaw = Get-Content -Raw -Path (Resolve-Path "$PSScriptRoot/../../quality-tiers.yml").Path
              $rewritten = $liveRaw -replace 'tier:\s*t\d', "tier: $t"
              Set-Content -Path $p -Value $rewritten
              (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 0 -Because "tier '$t' must be accepted"
          }
      }
  }
  ```
  Toolchain gate: format + analyzer + Pester. AC remediation reference: R1.
  Pass: analyzer clean; all `It` blocks pass.

- [ ] [P4-T4] Create `tests/powershell/validate-feature-review-coverage.Tests.ps1`.
  New file body:

  ```powershell
  #Requires -Version 7.0
  #Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

  Describe 'validate-feature-review-coverage.ps1' {
      BeforeAll {
          # Dot-source the script in dot-import mode so its functions are available
          # without executing the bottom-of-file invocation block.
          $scriptPath = (Resolve-Path "$PSScriptRoot/../../.claude/hooks/validate-feature-review-coverage.ps1").Path
          . $scriptPath
      }

      Context 'Get-LcovRepoCoverage' {
          It 'returns null when the file does not exist' {
              Get-LcovRepoCoverage -Path (Join-Path -Path $TestDrive -ChildPath 'absent.info') | Should -BeNullOrEmpty
          }

          It 'computes percent from LF/LH counters' {
              $p = Join-Path -Path $TestDrive -ChildPath 'lcov-line.info'
              Set-Content -Path $p -Value @"
  TN:
  SF:src/a.ts
  LF:100
  LH:90
  end_of_record
  SF:src/b.ts
  LF:100
  LH:80
  end_of_record
  "@
              Get-LcovRepoCoverage -Path $p | Should -Be 85.0
          }

          It 'returns null when LF total is 0' {
              $p = Join-Path -Path $TestDrive -ChildPath 'lcov-zero.info'
              Set-Content -Path $p -Value "SF:x`nLF:0`nLH:0`nend_of_record"
              Get-LcovRepoCoverage -Path $p | Should -BeNullOrEmpty
          }
      }

      Context 'Get-LcovBranchCoverage' {
          It 'returns null when the file does not exist' {
              Get-LcovBranchCoverage -Path (Join-Path -Path $TestDrive -ChildPath 'absent.info') | Should -BeNullOrEmpty
          }

          It 'computes percent from BRF/BRH counters' {
              $p = Join-Path -Path $TestDrive -ChildPath 'lcov-branch.info'
              Set-Content -Path $p -Value @"
  SF:src/a.ts
  BRF:40
  BRH:30
  end_of_record
  SF:src/b.ts
  BRF:60
  BRH:45
  end_of_record
  "@
              Get-LcovBranchCoverage -Path $p | Should -Be 75.0
          }

          It 'returns null when BRF total is 0' {
              $p = Join-Path -Path $TestDrive -ChildPath 'lcov-branch-zero.info'
              Set-Content -Path $p -Value "SF:x`nBRF:0`nBRH:0`nend_of_record"
              Get-LcovBranchCoverage -Path $p | Should -BeNullOrEmpty
          }
      }

      Context 'Get-JacocoRepoCoverage' {
          It 'computes line percent from JaCoCo counters' {
              $p = Join-Path -Path $TestDrive -ChildPath 'jacoco.xml'
              Set-Content -Path $p -Value @'
  <?xml version="1.0"?>
  <report>
    <package>
      <counter type="LINE" missed="15" covered="85"/>
      <counter type="BRANCH" missed="25" covered="75"/>
    </package>
  </report>
  '@
              Get-JacocoRepoCoverage -Path $p | Should -Be 85.0
          }

          It 'returns null on missing file' {
              Get-JacocoRepoCoverage -Path (Join-Path -Path $TestDrive -ChildPath 'absent.xml') | Should -BeNullOrEmpty
          }
      }

      Context 'Get-JacocoBranchCoverage' {
          It 'computes branch percent from JaCoCo counters' {
              $p = Join-Path -Path $TestDrive -ChildPath 'jacoco-branch.xml'
              Set-Content -Path $p -Value @'
  <?xml version="1.0"?>
  <report>
    <package>
      <counter type="LINE" missed="10" covered="90"/>
      <counter type="BRANCH" missed="25" covered="75"/>
    </package>
  </report>
  '@
              Get-JacocoBranchCoverage -Path $p | Should -Be 75.0
          }

          It 'returns null when BRANCH counter is absent' {
              $p = Join-Path -Path $TestDrive -ChildPath 'jacoco-noblanch.xml'
              Set-Content -Path $p -Value '<?xml version="1.0"?><report><package><counter type="LINE" missed="0" covered="10"/></package></report>'
              Get-JacocoBranchCoverage -Path $p | Should -BeNullOrEmpty
          }
      }

      Context 'Get-LanguageBranchCoverage dispatch' {
          It 'returns null for an unknown language' {
              Get-LanguageBranchCoverage -Language 'Rust' | Should -BeNullOrEmpty
          }
      }

      Context 'Test-LanguageCoverageRow' {
          It 'returns Ok=true when language line at exactly 85% and branch at exactly 75%' {
              $audit = "PowerShell coverage row PASS — line 85.00%, branch 75.00%"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 85.0 -BranchPct 75.0
              $r.Ok | Should -BeTrue
          }

          It 'returns Ok=false when language is not mentioned' {
              $audit = "TypeScript coverage row PASS"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
              $r.Ok | Should -BeFalse
              $r.Reason | Should -Match 'does not mention PowerShell'
          }

          It 'returns Ok=false when language is mentioned but no coverage row exists' {
              $audit = "PowerShell scripts have been added"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
              $r.Ok | Should -BeFalse
              $r.Reason | Should -Match 'no coverage-scoped row'
          }

          It 'rejects scope-narrowing language on coverage rows' {
              $audit = "PowerShell coverage informational only"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
              $r.Ok | Should -BeFalse
              $r.Reason | Should -Match 'narrows scope'
          }

          It 'returns Ok=false when no PASS/FAIL on coverage row' {
              $audit = "PowerShell coverage row noted"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 80.0
              $r.Ok | Should -BeFalse
              $r.Reason | Should -Match 'PASS nor a FAIL'
          }

          It 'returns Ok=false when repo-wide line coverage 84% but no FAIL on row' {
              $audit = "PowerShell coverage row PASS — line 84%"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 84.0 -BranchPct 80.0
              $r.Ok | Should -BeFalse
              $r.Reason | Should -Match '85% line coverage floor'
          }

          It 'accepts repo-wide line 84% when FAIL is present on coverage row' {
              $audit = "PowerShell coverage row FAIL — line 84%"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 84.0 -BranchPct 80.0
              $r.Ok | Should -BeTrue
          }

          It 'returns Ok=false when branch coverage is 74% (below 75% floor)' {
              $audit = "PowerShell coverage row PASS — line 90%, branch 74%"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 74.0
              $r.Ok | Should -BeFalse
              $r.Reason | Should -Match '75% branch coverage floor'
          }

          It 'accepts branch coverage at exactly 75% (boundary)' {
              $audit = "PowerShell coverage row PASS — line 90%, branch 75%"
              $r = Test-LanguageCoverageRow -AuditText $audit -Language 'PowerShell' -RepoWidePct 90.0 -BranchPct 75.0
              $r.Ok | Should -BeTrue
          }

          It 'works for each language label set' {
              foreach ($pair in @(
                  @{ L = 'TypeScript'; T = 'TypeScript coverage row PASS' },
                  @{ L = 'Python';     T = 'pytest coverage row PASS' },
                  @{ L = 'CSharp';     T = '.NET coverage row PASS' }
              )) {
                  $r = Test-LanguageCoverageRow -AuditText $pair.T -Language $pair.L -RepoWidePct 90.0 -BranchPct 80.0
                  $r.Ok | Should -BeTrue -Because "language $($pair.L) label set must match"
              }
          }
      }
  }
  ```
  Note on dot-source guard: the script's bottom block `if ($MyInvocation.InvocationName -eq '.') { return }`
  ensures dot-sourcing returns early and exposes functions without running the hook entrypoint.
  Toolchain gate: format + analyzer + Pester. AC remediation reference: R1.
  Pass: every `It` passes; coverage closure (P4-T5) confirms thresholds.

- [ ] [P4-T5] Run the full Pester suite with coverage. Command:
  `mcp__drm-copilot__run_poshqc_test` configured against
  `tests/powershell/PesterConfiguration.psd1`. If MCP runner is unavailable, fall back to
  `pwsh -NoProfile -Command "Invoke-Pester -Configuration (Import-PowerShellDataFile tests/powershell/PesterConfiguration.psd1)"`.
  Capture pass/fail counts plus per-script line and branch coverage from
  `artifacts/pester/powershell-coverage.xml`. Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p4-pester-coverage.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (test pass/fail counts;
  per-script line% and branch%; aggregate line% and branch%).
  AC remediation reference: R1.
  Pass: tests all green; per-script line >= 85%; per-script branch >= 75%; aggregate >= 85% / >= 75%.

---

## Phase RP-5 — CI Wiring

### Phase RP-5 — CI Wiring

- [ ] [P5-T1] Update `.github/actions/test/action.yml` to invoke Pester on
  `tests/powershell/` and emit JaCoCo coverage to `artifacts/pester/powershell-coverage.xml`.
  File: `.github/actions/test/action.yml`.
  Insertion (after any existing TypeScript test step, before the action's final
  `runs:` close): a step that runs
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

- [ ] [P5-T2] Add the `secret-scan` job (defined in P3-T5) to
  `.github/workflows/pr-pipeline.yml`. (Note: P3-T5 already inserts the job. This task
  validates the workflow as a whole after both the secret-scan and Pester steps are in
  place: run `actionlint` against `.github/workflows/pr-pipeline.yml` and
  `.github/actions/test/action.yml`.) Write to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p5-actionlint.md`
  with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  AC remediation reference: R1+M1.
  Pass: actionlint exit 0.

---

## Phase RP-6 — Verification & Evidence

### Phase RP-6 — Verification & Evidence

- [ ] [P6-T1] Re-run all issue.md Validation grep checks (Phase 1 + Phase 2 from issue.md
  lines 68-82). Specifically:
  - `grep -ri "jest" .claude/rules/typescript.md ...` returns no matches.
  - `grep -ri "vs code extension\|vscode extension" ...` returns no matches.
  - Coverage-threshold prose grep across all listed files reports the uniform tier rule.
  - Mirror discipline grep: every modified `.claude/rules/` file has a matching
    `.github/instructions/` file in the diff.
  Capture each command + exit code to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p6-issue-validation-greps.md`
  with `Timestamp:`, `Command:` (one per check), `EXIT_CODE:`, `Output Summary:`.
  Pass: every grep returns the expected outcome (zero matches where required; the
  uniform rule wording where required).

- [ ] [P6-T2] Re-run `pwsh -NoProfile -File .claude/hooks/validate-feature-review-coverage.ps1`
  with a synthetic CLAUDE_HOOK_INPUT JSON payload that advertises the existing
  feature-review artifacts (policy-audit, code-review, feature-audit). Capture exit code
  + stderr to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p6-coverage-hook-rerun.md`.
  Confirm the PowerShell coverage row evaluates to PASS now that
  `artifacts/pester/powershell-coverage.xml` exists with line >= 85% / branch >= 75%.
  AC remediation reference: R1.
  Pass: exit 0; stderr empty.

- [ ] [P6-T3] Branch protection live verification. Re-run
  `gh api -X GET repos/drmoisan/TMW/branches/main/protection`. Diff the response against
  the eight-context list. Append the diff to
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p23-branch-protection-live.md`
  (already created in P2-T4) under a section `## RP-6 re-verification` with
  `Timestamp:` and `Output Summary:` confirming the eight contexts.
  AC remediation reference: M2.
  Pass: all eight contexts present; no extra contexts; PR-review and linear-history
  settings match `docs/branch-protection.md`.

- [ ] [P6-T4] Gitleaks fake-secret rejection re-verification. Re-execute the procedure
  documented in P3-T3 (synthetic-secret fixture, stage, scan, restore). Append the
  re-run output to `evidence/qa-gates/p3-gitleaks-fake-secret.md` under
  `## RP-6 re-verification` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero),
  `Output Summary:` showing the redacted match.
  AC remediation reference: M1.
  Pass: re-run is reproducible; fixture removed after each invocation.

- [ ] [P6-T5] Update Acceptance Criteria checkoff to PASS for #19 and #23 with automated
  evidence citations. File:
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/qa-gates/p23-acceptance-criteria-checkoff.md`.
  - AC #19 row: `PASS — automated. Evidence: evidence/qa-gates/p3-gitleaks-install.md (install) + evidence/qa-gates/p3-gitleaks-fake-secret.md (functional reject + re-verify).`
  - AC #23 row: `PASS — automated. Evidence: evidence/qa-gates/p23-branch-protection-pre.md (pre-state) + evidence/qa-gates/p23-branch-protection-live.md (post-apply + RP-6 re-verify).`
  - Confirm grep `PASS-WITH-MANUAL-FOLLOWUP` over the entire feature folder returns
    zero matches; record the grep + result at the bottom of the checkoff file.
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
  Pass: zero error-level findings; warning count not regressed vs baseline (P0-T5).

- [ ] [P7-T3] Pester suite with coverage. Command:
  `mcp__drm-copilot__run_poshqc_test` against
  `tests/powershell/PesterConfiguration.psd1`. Write to
  `evidence/qa-gates/p7-pester.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`,
  `Output Summary:` containing post-change line% and branch% per script and aggregate.
  Pass: all tests green; line >= 85% per script and aggregate; branch >= 75% per script
  and aggregate.

- [ ] [P7-T4] Coverage-row hook validation. Re-run the validate-feature-review-coverage
  hook (as in P6-T2) and confirm it still exits 0 against the post-final-QA artifacts.
  Write to `evidence/qa-gates/p7-coverage-hook.md`.
  Pass: exit 0.

- [ ] [P7-T5] Actionlint over `.github/workflows/pr-pipeline.yml` and
  `.github/actions/test/action.yml`. Write to `evidence/qa-gates/p7-actionlint.md`.
  Pass: exit 0.

- [ ] [P7-T6] Plan-coherence verification. Run `mcp__drm-copilot__validate_orchestration_artifacts`
  with `artifact_type: "plan"` and
  `artifact_path: docs/features/active/2026-05-09-establish-repository-foundation-1/remediation-plan.2026-05-10T00-00.md`.
  Pass: validator exits 0.

---

## Plan Coherence Self-Check

- AC remediation reference R1 is delivered by P4-T1..P4-T5, P5-T1..P5-T2, P6-T2, and P7-T3.
- AC remediation reference M1 is delivered by P1-T1, P3-T1..P3-T5, P6-T4, and P6-T5.
- AC remediation reference M2 is delivered by P1-T2, P2-T1..P2-T5, P6-T3, and P6-T5.
- Every new PowerShell script (`apply-branch-protection.ps1`, `install-gitleaks.ps1`)
  ships in tasks that precede the final QA loop, where format+analyzer gates apply
  (P7-T1, P7-T2). Pester coverage at P4 targets the three scripts named in R1; the two
  newly created scripts (`apply-branch-protection.ps1`, `install-gitleaks.ps1`) are
  smoke-tested by their own runtime invocation in P2-T3 and P3-T2 (their primary
  functional contract is integration with `gh` / `winget` / `gh release`, which is
  exercised live; unit-mocking those external CLIs would defer to follow-up work and is
  recorded as out of scope for this remediation cycle, matching the powershell.md rule
  that wrapper-mocking should be introduced only when needed).
- Mirror discipline (P1-T5) checks `.claude/rules/` ↔ `.github/instructions/` for any
  manual-followup language; AC #19 / AC #23 prose lives only in `issue.md` and
  `docs/branch-protection.md` (not in `.claude/rules/`), so no rule-mirror edits are
  expected.
- No task introduces or relies on a manual follow-up. Every AC has automated evidence.
- All evidence paths are under
  `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/<kind>/`
  per `evidence-and-timestamp-conventions`.
- All work occurs on `feature/establish-repository-foundation-1`; PR #1 receives the
  new commits.

PREFLIGHT: ALL CLEAR
