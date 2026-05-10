---
artifact: remediation-inputs
feature: 2026-05-09-establish-repository-foundation-1
issue: 1
base: main (a2a462662a9d46f955b65f3e6bcc0f7887cbe04d)
branch: feature/establish-repository-foundation-1
timestamp: 2026-05-09T18-00
---

# Remediation Inputs — Issue #1: Establish Repository Foundation

This document lists findings from the policy audit and code review that require remediation. AC-permitted "PASS-WITH-MANUAL-FOLLOWUP" items are listed here for visibility but are not blocking under the AC contract.

## Remediation-Required Findings

### R1 — PowerShell Pester test coverage absent for new and modified .ps1 scripts (Severity: high)

Source: policy-audit `## Coverage Verification` (PowerShell row FAIL); code-review F1.

Affected files:

- `.claude/hooks/validate-feature-review-coverage.ps1` (modified — substantial additions: `Get-LcovBranchCoverage`, `Get-JacocoBranchCoverage`, `Get-LanguageBranchCoverage`, branch-coverage threshold logic).
- `.githooks/check-conventional-commit.ps1` (new).
- `.github/scripts/validate-quality-tiers.ps1` (new).

Required action: deliver Pester (v5.x) tests for these scripts achieving line coverage >=85% and branch coverage >=75% per the uniform tier rule established by this same branch (`.claude/rules/powershell.md` lines 63-65). Tests must follow `general-unit-test.md` Determinism Infrastructure rules (no real wall-clock waits, banned APIs).

Suggested test scope:

- `check-conventional-commit.ps1`: missing-file path (exit 2), empty-message path (exit 3), invalid format (exit 4), valid `feat`/`fix`/`feat(scope)`/`feat!:` (exit 0), comment-only message handling.
- `validate-quality-tiers.ps1`: missing config (exit 2), empty config (exit 3), missing `projects:` key (exit 4), invalid tier value (exit 5), inventory mismatch (exit 6), happy path (exit 0).
- `validate-feature-review-coverage.ps1`: `Get-LcovRepoCoverage`, `Get-LcovBranchCoverage`, `Get-JacocoRepoCoverage`, `Get-JacocoBranchCoverage`, `Get-LanguageBranchCoverage`, `Test-LanguageCoverageRow` — including the new branch-coverage threshold path that returns FAIL when branch coverage is below 75%.

Owner: TBD (post-A0 ticket per `evidence/qa-gates/p3-coverage-gap-followup.md`).

Tracking: link to be added to `issue.md` Manual follow-ups section.

## AC-Permitted Manual Follow-ups (recorded for visibility, not remediation-blocking)

### M1 — AC #19: gitleaks functional fake-secret demonstration

Status: PASS-WITH-MANUAL-FOLLOWUP.

Static configuration verified (`evidence/qa-gates/p3-gitleaks-fake-secret.md`). The functional rejection demonstration could not be performed in the executor session because the gitleaks binary is not installed.

Required action: install gitleaks (`winget install gitleaks` or equivalent), then run `gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml` against a staged commit containing a literal matching the `graph-client-secret` regex (e.g., `graph_client_secret = "AKIAABCDEFGHIJKLMNOP"`). Confirm non-zero exit and capture output.

Owner: developer running the next environment-setup pass.

### M2 — AC #23: branch protection rule application via gh API

Status: PASS-WITH-MANUAL-FOLLOWUP.

Documentation complete in `docs/branch-protection.md` including the exact `gh api -X PUT` command. Programmatic application from the executor session was not possible because authenticated `gh` CLI access was not available.

Required action: repository administrator runs the documented `gh api -X PUT repos/{owner}/{repo}/branches/main/protection ...` command after `gh auth login`. Verification: `gh api -X GET .../branches/main/protection` and confirm each of the eight contexts is listed.

Owner: repository administrator.

## Summary

- Remediation-required findings: 1 (R1 — PowerShell test coverage).
- AC-permitted manual follow-ups: 2 (M1 gitleaks demo; M2 branch protection application).
- Overall feature-audit verdict (`feature-audit.2026-05-09T18-00.md`): PASS (23/23 AC checked off).
- Overall policy-audit verdict (`policy-audit.2026-05-09T18-00.md`): PARTIAL (PowerShell coverage gate FAIL).
- Overall code-review verdict (`code-review.2026-05-09T18-00.md`): PARTIAL (F1 — same coverage gap).
