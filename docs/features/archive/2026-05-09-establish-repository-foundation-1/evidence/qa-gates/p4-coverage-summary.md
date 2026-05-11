# P4-T8 — Coverage summary (consolidated)

Timestamp: 2026-05-10T00-00
Source: evidence/qa-gates/p4-pester-coverage.md

## Per-script line coverage

| Script | line% |
|---|---|
| .claude/hooks/validate-feature-review-coverage.ps1 | 90.00 |
| .githooks/check-conventional-commit.ps1 | 94.44 |
| .github/scripts/validate-quality-tiers.ps1 | 95.35 |

## Branch-coverage policy

branch coverage emission deferred per Pester JaCoCo writer limitation; line coverage at >= 85% is the enforceable floor for this toolchain (consistent with Get-JacocoBranchCoverage returning $null when no BRANCH element is present at line 191 of .claude/hooks/validate-feature-review-coverage.ps1)

## In-process refactor note

All three scripts are exercised in-process via dot-sourced advanced functions; the previous subprocess pattern (`pwsh -NoProfile -File`) was removed in `[P4-T11]` / `[P4-T12]`.

## Pass / fail

PASS. All three per-script line% values are >= 85.0; no branch% claim is made beyond the deferred-branch policy line.
