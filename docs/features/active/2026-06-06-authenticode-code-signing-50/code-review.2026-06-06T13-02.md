# Code Review — authenticode-code-signing (Issue #50)

- Timestamp: 2026-06-06T13-02
- Feature folder: `docs/features/active/2026-06-06-authenticode-code-signing-50/`
- Files reviewed:
  - `scripts/powershell/Invoke-AuthenticodeSigning.ps1` (449 lines)
  - `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1` (483 lines)
- Reviewer: feature-review agent

## Executive Summary

The signing tool is well-structured. Pure logic (config parsing, the exclusion predicate)
is separated from host-bound surface (cert-store access, `Set-/Get-AuthenticodeSignature`,
filesystem enumeration), and every external boundary is reachable through an injectable
scriptblock seam with a named production default. Fail-fast behavior is correct and ordered
before any side effect. Error messages are actionable. Naming, file size, and the toolchain
are clean.

One non-blocking correctness gap was found: the production sign wrapper does not surface a
`TimestampWarning` flag on the timestamp-unreachable fallback path, so the run summary's
`Warnings` counter remains 0 in production even when a file is signed without a timestamp.
This is an accuracy gap in the summary count, not a behavioral defect — the wrapper itself
emits `Write-Warning` and continues, so the warn-not-fail contract (AC-9) holds.

Verdict: PASS with one PARTIAL (non-blocking) finding. Blocking findings: 0.

## Findings Table

| # | Location | Finding | Severity | Verdict |
|---|---|---|---|---|
| C-1 | `Invoke-SetAuthenticodeSignature` (lines 296-303) vs orchestrator (line 401) | Production wrapper does not set `TimestampWarning` on the fallback path, so the summary `Warnings` count is always 0 in production even when a timestamp is skipped | Low | PARTIAL |
| C-2 | `Invoke-AuthenticodeSigning` (lines 423-425, 446-448) | Dual exit-signaling (`$global:LASTEXITCODE = 1` in the function plus `exit 1` at the entry point) | Low | PASS (acceptable) |
| C-3 | Config/cert resolution ordering (lines 368-379) | Resolve-before-side-effect is correct: config and cert resolve and may throw before any sign call | — | PASS |
| C-4 | `Test-IsExcludedRelativePath` (lines 156-180) | Pure, separator-agnostic predicate; correctly anchored to path roots | — | PASS |
| C-5 | Seam design (param block lines 102-111) | Four seams with named-helper defaults; minimal DI per `.claude/rules/powershell.md` | — | PASS |
| C-6 | Error handling throughout | Fail-fast with `throw`; no broad silent catch-alls; the one `catch` re-raises context via `Write-Warning` then retries without timestamp | — | PASS |
| C-7 | `Resolve-SigningCert` EKU check (lines 257-270) | Correctly inspects `X509EnhancedKeyUsageExtension` for OID 1.3.6.1.5.5.7.3.3 | — | PASS |
| C-8 | Logging (Write-Information / Write-Warning) | Per-file outcome plus summary line; appropriate levels | — | PASS |

## Detailed Observations

### C-1 (PARTIAL, non-blocking): TimestampWarning never produced in production

The orchestrator increments the `Warnings` counter and emits a "signed without a timestamp"
message only when the sign result carries a truthy `TimestampWarning` property:

```powershell
# line 401
if ($null -ne $result -and $result.PSObject.Properties.Name -contains 'TimestampWarning' -and $result.TimestampWarning) {
```

The production wrapper `Invoke-SetAuthenticodeSignature`, on the timestamp-unreachable
fallback (lines 300-303), re-signs without a timestamp and returns the raw
`Set-AuthenticodeSignature` result, which does not have a `TimestampWarning` property. As a
result, in a real run the summary `Warnings` count stays 0 even when timestamping was
skipped; the only signal is the `Write-Warning` emitted inside the wrapper.

The test suite exercises the `Warnings`-counting branch by injecting a sign seam that
returns `TimestampWarning = $true` (test "continues past a timestamp-unreachable warning
without hard failure", expecting `Warnings = 2`). The branch is therefore covered, but the
test fixture supplies a flag the production wrapper never sets, so the summary-count path is
not exercised end-to-end against the real wrapper.

Impact: low. The warn-not-fail behavior (AC-9) is satisfied because the wrapper warns and
continues; only the aggregate `Warnings` count in the returned summary object is inaccurate
on the real path. Recommended (non-blocking) remediation: have the production wrapper return
a result object carrying `TimestampWarning = $true` on the fallback path, so the summary
count reflects reality and the end-to-end count path is exercisable.

### C-2 (PASS, acceptable): dual exit signaling

The function sets `$global:LASTEXITCODE = 1` on failure (line 424) and the entry point also
calls `exit 1` when the summary indicates failure (line 447). Setting a global from inside a
function is mild global-state use, but it is bounded to the process exit signal and the
entry-point `exit 1` is the authoritative non-zero termination. This satisfies the spec's
exit-code contract (0 on full success, non-zero on any fail-fast or per-file failure). No
change required.

### C-3 (PASS): resolve-before-side-effect

Configuration resolution (`& $ReadSecretsAction`) and certificate resolution
(`& $ResolveCertAction`) both execute before file selection and the sign loop. Because
`$ErrorActionPreference = 'Stop'` and the helpers `throw`, any config or cert failure aborts
the run before a single file is signed. This is verified by the tests that assert
`SignCalls.Count -eq 0` on cert-absent / no-private-key / wrong-EKU paths.

### C-4 (PASS): exclusion predicate

`Test-IsExcludedRelativePath` normalizes separators, trims a leading slash, and matches an
excluded root only at a path boundary (`-eq $root` or `StartsWith($root + '/')`), which
avoids false positives such as `artifacts-foo/`. It is pure and has no filesystem access.

### Separation of concerns

The host-bound surface is confined to `Resolve-SigningCert` (cert store),
`Invoke-SetAuthenticodeSignature` / `Test-AuthenticodeSignature` (native signing cmdlets),
and `Get-FirstPartySignableFileList` (filesystem). These are kept thin and remain in the
coverage denominator. The orchestrator and the pure helpers (`Read-SigningThumbprint`,
`Test-IsExcludedRelativePath`) contain the testable logic. This matches the design
principles in `.claude/rules/general-code-change.md`.

### Test quality

Tests follow Arrange-Act-Assert with descriptive `It` names, one behavior per test. Seams
are injected via `.GetNewClosure()` with capture containers that allow precise assertions on
what each seam received. Negative paths (missing secrets, parse failure, empty key, absent
cert, no private key, wrong EKU, non-`Valid` status both thrown and returned) and edge cases
(empty enumeration, `-WhatIf`, `-FilePaths` bypass, idempotent re-sign) are covered. No
mocking of the seam contract is weakened to pass.

## Recommendation

**GO.** Total blocking findings: **0.** One low-severity PARTIAL finding (C-1) is recorded
for a follow-up but does not block merge.
