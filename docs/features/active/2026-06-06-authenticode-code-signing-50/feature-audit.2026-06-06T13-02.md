# Feature Audit — authenticode-code-signing (Issue #50)

- Timestamp: 2026-06-06T13-02
- Feature folder: `docs/features/active/2026-06-06-authenticode-code-signing-50/`
- Work Mode: `full-feature`
- AC sources: `spec.md` (AC-1..AC-18), `user-story.md` (10 story-level criteria)
- Reviewer: feature-review agent

## Executive Summary

All 18 acceptance criteria in `spec.md` and all 10 story-level criteria in `user-story.md`
are genuinely satisfied. The reviewer spot-checked each AC against the production code and
the corresponding test rather than accepting the executor's verification matrix at face
value; each claim mapped to a real implementation path and a passing test or a verified
working-tree fact. The two declared non-goals (CI-runner signing deferral; TS/web and
vendored-script exclusion) and all five documented risks are handled in the runbook and
feature documentation.

Verdict: PASS. Blocking findings: 0.

## Acceptance Criteria Check-off

### spec.md (AC-1..AC-18)

| AC | Spot-check | Verdict |
|---|---|---|
| AC-1 thumbprint from config, not hardcoded | `Read-SigningThumbprint` reads `secrets.json`; orchestrator resolves config first; grep confirmed no thumbprint literal in script/tests; test "returns the thumbprint when the key is present" | PASS |
| AC-2 missing secrets/key -> fail-fast w/ remediation, no file signed | Three throw branches in `Read-SigningThumbprint` (missing file with remediation command, parse failure, empty/whitespace key); tests assert each, including the `dotnet user-secrets set ... --id 3716a8f0-...` message | PASS |
| AC-3 no cert w/ private key -> fail-fast naming thumbprint | `Resolve-SigningCert` filters `HasPrivateKey` and throws naming the thumbprint; orchestrator tests assert `SignCalls.Count -eq 0`; seam-internals test mocks empty cert store | PASS |
| AC-4 cert lacks Code Signing EKU -> fail-fast | `Resolve-SigningCert` inspects EKU OID 1.3.6.1.5.5.7.3.3 and throws; seam-internals test with private key but no EKU asserts the throw | PASS |
| AC-5 include globs, exclude node_modules/artifacts, missing subtree skipped | `Get-FirstPartySignableFileList` iterates the eight include globs, skips missing containers, applies `Test-IsExcludedRelativePath`; predicate tests cover both separators; seam-internals tests cover the keep/drop and empty cases | PASS |
| AC-6 `-FilePaths` signs exactly those, no enumeration | Orchestrator branch at `FilePaths.Count -gt 0`; test "signs exactly the provided paths and does not enumerate" asserts `EnumerateCalls.Count -eq 0` | PASS |
| AC-7 vendor DLLs never signed; only TaskMaster.* eligible | `-FilePaths` mode signs exactly the caller-supplied list; enumeration is first-party-only; runbook section 1 documents the rule. The tool relies on the caller passing only `TaskMaster.*` paths — the spec's intended contract — and never re-enumerates vendor binaries | PASS |
| AC-8 SHA256 + RFC3161 timestamp | `Invoke-SetAuthenticodeSignature` passes `-HashAlgorithm SHA256 -TimestampServer`; seam-internals test asserts both via `-ParameterFilter` | PASS |
| AC-9 timestamp unreachable -> warn, not hard-fail | Wrapper `try`/`catch` re-signs without timestamp and `Write-Warning`s; seam-internals test "warns and signs without a timestamp" returns Valid. (See code-review C-1: the summary `Warnings` counter is not incremented on the real path, a non-blocking accuracy gap; warn-not-fail itself holds) | PASS |
| AC-10 verify Valid; non-Valid is per-file failure | `Invoke-SetAuthenticodeSignature` throws on non-Valid; `Test-AuthenticodeSignature` returns bool; orchestrator status-check branch; tests cover thrown and returned non-Valid status | PASS |
| AC-11 Model B; no committed signature blocks | Working-tree scan across all tracked `.ps1`/`.psm1`/`.psd1` found zero `# SIG # Begin signature block` occurrences | PASS |
| AC-12 `-WhatIf` reports without modifying | `ShouldProcess` gate increments `Skipped` and emits "WhatIf: would sign"; test asserts `Signed=0, Skipped=2, SignCalls.Count=0` | PASS |
| AC-13 idempotent re-sign succeeds | Spec idempotency note; test runs twice over one path, both `Success=$true`, two sign calls | PASS |
| AC-14 seam-injected tests, no real cert, no temp files | All four seams injected; reviewer scan confirmed no `TestDrive:`, no file writes, no real cert access, no network | PASS |
| AC-15 coverage line>=85%/branch>=75%, no production file excluded | `final-pester-coverage.md` line 92.31%; `coverage-delta.md`; reviewer re-ran Pester (ok); production file measured directly, not excluded | PASS |
| AC-16 PSScriptAnalyzer 0 errors, formatter no changes, files <500 | Reviewer re-ran format (no change) and analyze (0 errors); 449 / 483 lines | PASS |
| AC-17 docs record self-signed trust limit + CI-deferral rationale | `runbook.md` section 3 (trust limitation) and section 4 (CI deferral); `.NOTES` synopsis; `feature-document.md` risks 1 and non-goals | PASS |
| AC-18 synopsis documents bootstrap execution-policy step | `.NOTES` BOOTSTRAP EXECUTION POLICY section with `-ExecutionPolicy Bypass` and `Set-ExecutionPolicy -Scope Process`; runbook section 2 | PASS |

### user-story.md (story-level criteria)

All 10 story-level criteria map to the spec ACs above and are verified PASS: config-driven
thumbprint, fail-fast on missing secrets/key, fail-fast on missing cert/private-key/EKU,
first-party script include + exclude, `-FilePaths` assembly signing without vendor DLLs,
RFC3161 timestamp warn-not-fail, verification path, Model B (no committed signatures),
`-WhatIf`, toolchain + coverage gates, and documented trust/CI-deferral.

## Non-Goals Verification

- **CI-runner signing deferred.** Confirmed: `.github/workflows/**` is unmodified; the
  deferral and its rationale (key-as-CI-secret is security-sensitive; touches workflows;
  triggers `modified-workflow-needs-green-run`) are documented in `runbook.md` section 4,
  `feature-document.md` non-goals, `spec.md`, and `user-story.md`. PASS.
- **TS/web bundles and vendored/third-party scripts excluded.** Confirmed: the include globs
  cover only first-party PowerShell subtrees; `node_modules/**` and `artifacts/**` are
  excluded by `Test-IsExcludedRelativePath`; scope (b) is limited to `TaskMaster.*` via the
  `-FilePaths` contract. Documented in `feature-document.md` non-goals and `spec.md`. PASS.

## Documented Risks Verification

| Risk | Handling | Verdict |
|---|---|---|
| Self-signed trust scope | `runbook.md` section 3, `.NOTES` SELF-SIGNED TRUST LIMITATION, `feature-document.md` risk 1 | PASS |
| Timestamp-server availability | Warn-not-fail behavior in `Invoke-SetAuthenticodeSignature`; documented in spec, runbook, `feature-document.md` risk 2 | PASS |
| Bootstrap execution policy | `.NOTES` BOOTSTRAP section, `runbook.md` section 2, `feature-document.md` risk 3 | PASS |
| Private-key handling | No key tracked (verified); `feature-document.md` risk 4 | PASS |
| `artifacts/` mirror scripts | `artifacts/**` excluded; `feature-document.md` risk 5 documents the revisit condition | PASS |

## Acceptance Criteria Status

- Source: `docs/features/active/2026-06-06-authenticode-code-signing-50/spec.md` and
  `docs/features/active/2026-06-06-authenticode-code-signing-50/user-story.md`
- Total AC items: 18 (spec) + 10 (user-story) = 28
- Checked off (delivered): 28
- Remaining (unchecked): 0
- Items remaining: none

All AC checkboxes in `spec.md` and `user-story.md` were already marked `[x]` by the executor;
the reviewer independently verified each and confirms the check-offs are warranted. No
checkbox state changes were required.

## Recommendation

**GO.** Total blocking findings: **0.**
