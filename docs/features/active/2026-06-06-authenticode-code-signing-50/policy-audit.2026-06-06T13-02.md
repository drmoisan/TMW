# Policy Audit — authenticode-code-signing (Issue #50)

- Timestamp: 2026-06-06T13-02
- Feature folder: `docs/features/active/2026-06-06-authenticode-code-signing-50/`
- Branch: `feature/authenticode-code-signing-50`
- Diff base: `origin/main` (working-tree + staged changes reviewed)
- Work Mode: `full-feature` (AC sources: `spec.md`, `user-story.md`)
- Reviewer: feature-review agent

## Executive Summary

The feature adds two new files only — `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
(449 lines) and `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1` (483 lines)
— plus feature documentation and evidence. PowerShell is the only language with changed
files in the branch diff. The PowerShell toolchain was re-run independently during this
review and passed in a single clean pass (format, analyze, test all reported `ok:true`).
Coverage for the new production file is 92.31% line, exceeding the uniform thresholds. No
secret, private key, or committed signature block was found. `.github/workflows/**` and
`quality-tiers.yml` are unmodified, consistent with the documented CI-signing deferral.

Verdict: PASS. Blocking findings: 0.

## Rejected Scope Narrowing

None. The caller prompt requested a full review of the working-tree and staged changes
against `origin/main` and did not attempt to narrow scope to a subset of files, a plan,
a task, or a phase. No language with changed files was marked out of scope.

## Evidence Location Compliance

The branch diff was scanned for evidence files written under the non-canonical roots
`artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, and `artifacts/coverage/`.
No such files were found. All feature evidence is under the canonical location
`docs/features/active/2026-06-06-authenticode-code-signing-50/evidence/` (`baseline/` and
`qa-gates/`). The coverage XML at `artifacts/pester/authenticode-coverage.xml` is a
tool-emitted coverage artifact under the language-conventional Pester path, not a
feature-evidence document, and is not a violation of the evidence-location invariant.

Verdict: PASS.

## 1. Language Scope and Coverage Verdicts

Languages with changed files in the branch diff: **PowerShell only.**

- TypeScript: zero changed files. Coverage N/A (no changed files).
- Python: zero changed files. Coverage N/A (no changed files).
- C#: zero changed files. Coverage N/A (no changed files).
- PowerShell: two changed files (one production, one test). Coverage verdict below.

### PowerShell coverage

The reviewer verified coverage from the pre-existing artifact rather than rerunning
generation, per the evidence-verification model.

- Artifact: `artifacts/pester/authenticode-coverage.xml` (present, JaCoCo format).
- Reported by executor and recorded in `evidence/qa-gates/final-pester-coverage.md`:
  - LINE: covered=96, missed=8, total=104 -> 92.31% (>= 85% threshold). PASS.
  - INSTRUCTION/command: covered=110, missed=9, total=119 -> 92.44%.
  - METHOD: covered=7, missed=1, total=8 (uncovered method is the host-bound auto-invoke
    entry wiring).

Baseline -> Post-change comparison (new file):
- Baseline: 0% (the file did not exist before this feature; no PowerShell coverage was
  measured for `tests/pester/powershell` scope at P0) -> Post-change: 92.31% line.
  Change: +92.31%. New/changed-code coverage: 92.31% line. Disposition: PASS.
  Evidence: `evidence/qa-gates/coverage-delta.md`, `evidence/qa-gates/final-pester-coverage.md`,
  `artifacts/pester/authenticode-coverage.xml`.

Branch coverage note: Pester's JaCoCo output does not emit a BRANCH counter, so a direct
branch percentage is unavailable from the artifact. The executor's documented position is
that branch behavior is fully exercised (every fail-fast branch, both path separators in
the exclusion predicate, `-WhatIf` vs sign, empty vs populated enumeration, `-FilePaths`
vs enumeration, non-`Valid` returned and thrown, and the timestamp-unreachable path) and
that command coverage (92.44%) serves as the branch proxy above the 75% threshold. The
reviewer independently confirmed by inspection of the test file that each branch named is
covered by a corresponding `It` block. Disposition: PASS, with the documented limitation
that the JaCoCo emitter does not produce a numeric branch counter; the branch threshold is
satisfied by demonstrated branch-path coverage rather than a single emitted percentage.

PowerShell coverage verdict: **PASS** (line 92.31% >= 85%; branch paths demonstrated; no
production file excluded from coverage).

No production file is excluded from coverage. `Invoke-AuthenticodeSigning.ps1` is measured
directly and remains in the denominator; the host-bound wrappers are counted. This complies
with the coverage exclusion policy in `.claude/rules/general-unit-test.md`.

## 2. Toolchain Compliance (PoshQC + Pester)

The PowerShell toolchain was re-run independently during this review (not taken from
executor evidence at face value).

| Stage | Command | Result |
|---|---|---|
| Format | `mcp__drm-copilot__run_poshqc_format` (scan_folders: scripts/powershell, tests/pester/powershell) | `ok:true`, no changes |
| Analyze (PSScriptAnalyzer) | `mcp__drm-copilot__run_poshqc_analyze` (same scan folders) | `ok:true`, zero errors |
| Test (Pester) | `mcp__drm-copilot__run_poshqc_test` (scan_folders: tests/pester/powershell) | `ok:true` |

Type-checking is not applicable to PowerShell per `.claude/rules/powershell.md`. The
toolchain order (format -> analyze -> test) was followed. Executor evidence
(`evidence/qa-gates/final-clean-pass.md`) reports 34 passing tests, 0 failed; the reviewer
counted 34 `It` blocks in the test file, consistent with that count.

Verdict: PASS.

## 3. File-Size and Naming Policy

- `Invoke-AuthenticodeSigning.ps1`: 449 lines (<= 500). PASS.
- `Invoke-AuthenticodeSigning.Tests.ps1`: 483 lines (<= 500). PASS.
- Function names use approved verbs and descriptive nouns (`Read-SigningThumbprint`,
  `Resolve-SigningCert`, `Get-FirstPartySignableFileList`, `Invoke-SetAuthenticodeSignature`,
  `Test-AuthenticodeSignature`, `Invoke-AuthenticodeSigning`, `Test-IsExcludedRelativePath`).
  PSScriptAnalyzer (which enforces approved verbs) reported zero errors.

Verdict: PASS.

## 4. Determinism (No Temp Files, No Real Cert, No Banned Timing APIs)

The reviewer scanned the test file for banned constructs:

- Banned timing APIs (`Start-Sleep`, `Thread.Sleep`, `Task.Delay`): none found.
- Temp-file usage (`TestDrive:`, `New-TemporaryFile`, `GetTempFileName`, `Out-File`,
  `Set-Content`, `New-Item`): none found.
- Network calls (`Invoke-WebRequest`, `Invoke-RestMethod`, `System.Net`): none found.
- Real certificate access: every external boundary is exercised through injected seam
  scriptblocks or framework-cmdlet mocks (`Test-Path`, `Get-Content`, `Get-ChildItem` on
  `Cert:`, `Set-AuthenticodeSignature`, `Get-AuthenticodeSignature`). No real cert is read;
  the fake cert objects carry a constructed `X509EnhancedKeyUsageExtension` to satisfy the
  production EKU type check.

Tests satisfy independence, isolation, determinism, and the no-temp-file prohibition in
`.claude/rules/general-unit-test.md`.

Verdict: PASS.

## 5. Secret and Signature-Block Hygiene

- No `.pfx`, `.p12`, `.pem`, or `.key` file is tracked in the repository (`git ls-files`
  scan returned none).
- The certificate thumbprint `6461584F8CB3A2A384F575918E17D4B4AD8EE733` does NOT appear in
  the production script, the test file, or the runbook. It appears only in documentation
  (`spec.md`, `feature-document.md`, `user-story.md`, `issue.md`). A certificate thumbprint
  is a public identifier (the SHA-1 hash of the public certificate), not a secret; its
  presence in design docs is acceptable. The script resolves the thumbprint from
  configuration (`Signing:CertThumbprint` in user-secrets) and does not hardcode it.
- No `# SIG # Begin signature block` content was found in any tracked `.ps1`/`.psm1`/`.psd1`
  file (scan across `scripts`, `tests`, `.githooks`, `.github`, `.claude`). Model B is
  verified: signatures are not committed to source.

Verdict: PASS.

## 6. CI-Workflow and quality-tiers.yml Change Control

- `.github/workflows/**`: no changes in the branch diff (tracked or untracked).
- `quality-tiers.yml`: no change in the branch diff.

Because no workflow file was changed, the `modified-workflow-needs-green-run` rule does not
apply to this feature. The CI-runner signing deferral is documented with rationale in
`runbook.md` section 4, `feature-document.md`, `spec.md`, and `user-story.md`. The deferral
is the correct handling: provisioning a signing key into CI would touch `.github/workflows/**`
and is a human-gated security-sensitive change.

Verdict: PASS.

## 7. Findings Summary

| # | Finding | Severity | Verdict |
|---|---|---|---|
| P-1 | PowerShell toolchain (format/analyze/test) clean in a single independent pass | — | PASS |
| P-2 | New-file line coverage 92.31% (>= 85%); branch paths demonstrated (>= 75% proxy) | — | PASS |
| P-3 | No production file excluded from coverage; host-bound wrappers in denominator | — | PASS |
| P-4 | Tests deterministic: no temp files, no real cert, no banned timing/network APIs | — | PASS |
| P-5 | No secret, private key, or `.pfx` committed; thumbprint is a config reference | — | PASS |
| P-6 | Model B verified: no committed signature blocks in tracked source | — | PASS |
| P-7 | `.github/workflows/**` and `quality-tiers.yml` unchanged; CI signing deferred | — | PASS |
| P-8 | Evidence written to canonical `<FEATURE>/evidence/` location | — | PASS |
| P-9 | File sizes within 500-line limit (449 / 483) | — | PASS |
| P-10 | JaCoCo emitter produces no numeric branch counter; branch threshold met via demonstrated path coverage rather than a single emitted percentage | Informational | PASS |

## Recommendation

**GO.** Total blocking findings: **0.**
