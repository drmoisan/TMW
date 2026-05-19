# Policy Audit — remove-classifier-benchmark-gate (Issue #32)

- Timestamp (UTC): 2026-05-19T01-00
- Branch: TMW-wt-2026-05-18-09-47
- Base: main
- Work mode: full-feature (`spec.md` + `user-story.md` are AC sources)
- Reviewer: feature-review agent
- Scope: full branch diff against `main` (no caller-supplied narrowing observed; none would have been honored)

## Policy Reading Order Applied

1. `CLAUDE.md` (standing instructions)
2. `.claude/rules/general-code-change.md`
3. `.claude/rules/general-unit-test.md`
4. `.claude/rules/quality-tiers.md`
5. `.claude/rules/tonality.md`
6. Language-specific rules in scope: `.claude/rules/powershell.md` (PSScriptAnalyzer attribute edits) and `.claude/rules/csharp.md` (XML doc-comment edit)

## Rejected Scope Narrowing

None. The caller prompt described the audit as full-branch and that is what was performed.

## Coverage Evidence Checklist

- TypeScript baseline coverage artifact: N/A — no TypeScript files changed on this branch.
- TypeScript post-change coverage artifact: N/A — no TypeScript files changed on this branch.
- PowerShell baseline coverage artifact: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/baseline/baseline-powershell-toolchain.2026-05-18T22-05.md`
- PowerShell post-change coverage artifact: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md` (Pester step 6, 178 passed). PSScriptAnalyzer-only edits; `[OutputType]` attributes are non-executing metadata.
- C# baseline coverage artifact: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/baseline/baseline-dotnet-toolchain.2026-05-18T22-05.md`
- C# post-change coverage artifact: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md` (step 7, `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`, 98 passed). Only an XML doc-comment edited in `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`; no executable C# lines added or modified.
- Python baseline coverage artifact: N/A — no Python files changed on this branch.
- Python post-change coverage artifact: N/A — no Python files changed on this branch.
- Per-language comparison summary: see Section 5 (Test Coverage Detail) below.

## Executive Summary

Overall verdict: **PASS-with-pending-remote-CI**. The change is a removal-first refactor of the classifier benchmark gate, with mirrored rule and instruction edits kept in lockstep across `.claude/rules/`, `.github/instructions/`, and `docs/ci.research.md`. The seven-stage toolchain achieved a single clean pass (zero restarts; nine sub-stages exit 0). No T1 obligation is silently dropped — only the explicitly authorized `Benchmark p99 regression` matrix row is removed. No evidence-location violations and no residual references outside the documented allowlist. AC1..AC10 PASS; AC11 (full CI loop passes on the change branch) is deferred to the post-push remote PR pipeline run, which is scoped out of local execution by plan task P8-T11.

## 1. General Unit Test Policy Compliance

| Rule | Verdict | Evidence |
|---|---|---|
| Five-property core (independence, isolation, fast, deterministic, readable) | PASS — no test source added; deletions remove non-deterministic gate tests | `LatencyRegressionGateTests.cs`, `NonIdempotentHandler.cs`, `NonIdempotentHandlerNegativeTests.cs`, and three Pester scripts (`compare-benchmarks.Tests.ps1`, `enrich-bdn-report.Tests.ps1`, `make-synthetic-fixtures.Tests.ps1`) are deleted in lockstep with the gate they validated. No orphan test references remain (verified by the seven grep sweeps under `evidence/regression-testing/`). |
| Coverage thresholds (line >= 85%, branch >= 75%) | PASS (repo-wide) | `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` returned 98 passed in `toolchain-loop-clean-pass.2026-05-18T22-05.md` step 7. No production source file was added or modified on this branch (only an XML doc-comment in `BenchmarkConfig.cs` which is a benchmark-project file, not production). No new code files therefore exist that require new tests. |
| Determinism infrastructure (clocks, RNG, banned APIs) | PASS | No new test code added. Deletions remove the only non-deterministic CI assertion in the pipeline (the BDN-on-shared-runner comparator), which is a determinism improvement. |

### 1.2.1 Per-Language Coverage Comparison

Baseline source: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/baseline/baseline-powershell-toolchain.2026-05-18T22-05.md`.
Post-change source: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/qa-gates/toolchain-6-pester.2026-05-18T22-05.md`.

PowerShell coverage figures are reported in JaCoCo absolute counts (LINE covered=0 missed=284; INSTRUCTION covered=0 missed=433). The 0% absolute reading is a pre-existing artifact of PoshQC's bundled `CodeCoverage.Path` scope, not introduced by this branch. Percentages below are derived as `covered / (covered + missed)`; branch coverage is not emitted by the PoshQC JaCoCo profile and is shown as N/E (not emitted). The four other languages either have no changed files on this branch or no executable changes (C# is XML-doc-only), so per-language baseline-vs-post coverage comparison is N/A for those languages.

| Language | Files Changed | Tests | Test Result | Baseline Coverage | Post-Change Coverage | New Code Coverage |
|---|---|---|---|---|---|---|
| C# | 1 (XML-doc-only edit in `BenchmarkConfig.cs`) | 98 | PASS | N/A — no executable C# lines changed | N/A — no executable C# lines changed | N/A — no executable C# lines changed |
| PowerShell | 1 (`apply-branch-protection.ps1`: 4 `[OutputType]` attribute additions, no executable lines) | 178 | PASS | N/A — no executable PowerShell lines changed | N/A — no executable PowerShell lines changed | N/A — no executable PowerShell lines changed |
| TypeScript | 0 | N/A | N/A | N/A — no language files changed | N/A — no language files changed | N/A — no language files changed |
| Python | 0 | N/A | N/A | N/A — no language files changed | N/A — no language files changed | N/A — no language files changed |

Coverage interpretation: the only executable-file edits on this branch are four `[OutputType(...)]` attribute additions in `apply-branch-protection.ps1`, which are non-executing metadata. No new executable lines were added in any language; the baseline-vs-post comparison shows zero delta in absolute counts for PowerShell and N/A for the other three languages. Per Authoritative Decision #2, uniform thresholds (line >= 85%, branch >= 75%) apply, and no file-level coverage regression is possible from this branch's changes.

## 2. General Code Change Policy Compliance

| Rule | Verdict | Evidence |
|---|---|---|
| Simplicity-first design | PASS | The change is a removal-only refactor; no new abstractions introduced. The four `[OutputType(...)]` additions in `apply-branch-protection.ps1` are the minimum edits required to silence pre-existing analyzer findings — no behavior changes. |
| Mandatory seven-stage toolchain (single clean pass) | PASS | `evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md` shows all nine sub-stages green in a single chronological pass with zero restarts. |
| File size limit (<=500 lines) | PASS | No production file in the branch diff exceeds 500 lines after the changes. Deletions reduce file counts; the only edits to existing files are small (1-line, 4-line, single-attribute additions). |
| Error handling — fail fast | PASS | No new error paths introduced. Removed scripts (`compare-benchmarks.ps1`, `enrich-bdn-report.ps1`) contained their own throw-fast logic; their removal cannot weaken existing handling. |
| Public API / breaking-change call-out | PASS | The only externally visible surface change is the removal of CI job names. The spec and issue body explicitly authorize this and confirm no branch-protection rule on `main` lists the removed jobs as required checks. |
| Dependencies | PASS | No new package or dependency added. The `BenchmarkDotNet` package reference in `tests/TaskMaster.Benchmarks` is retained unchanged. |
| I/O isolation | PASS | No production source touched. The `.csproj` for `TaskMaster.Benchmarks` is unchanged; only `BenchmarkConfig.cs` had an XML doc-comment edited. |

### Internal consistency of rule amendments

The plan amends three near-duplicate documents and one upstream research file. All four are kept in lockstep on this branch:

- `.claude/rules/quality-tiers.md` — `Benchmark p99 regression` row removed. Confirmed by `git diff main..HEAD -- .claude/rules/quality-tiers.md`.
- `.github/instructions/quality-tiers.instructions.md` (mirror) — same row removed.
- `docs/ci.research.md` — same row removed from the tier-gate table.
- `.claude/rules/general-code-change.md` and `.github/instructions/general-code-change.instructions.md` — both updated identically to drop "and benchmark regression" from the nightly-pipeline sentence; "Mutation testing and golden tests" retained.

Verdict: PASS. The rule set is internally consistent post-change.

### T1 obligation review

`Benchmark p99 regression` was a T1 row (T1 < 5%, T2 < 10%, T3/T4 none). Its removal is explicitly authorized by:

- `issue.md` Acceptance Criteria AC8 (verbatim list of the row to delete)
- `spec.md` "Intent & Outcomes" paragraph and "Non-Goals" item 2 ("No replacement performance gate is introduced (no new \"soft\" benchmark job, no statistical-stability gate).")

No other T1 obligation in the matrix is dropped. Property test density, mutation score, contract breaking changes, determinism (retry rate), golden tests, and full E2E suite scope remain. Verdict: PASS — silent T1 obligation drop ruled out.

### Quality-tiers compliance

| Rule | Verdict | Evidence |
|---|---|---|
| Uniform thresholds preserved (line 85%, branch 75%) | PASS | No threshold changed; only the `Benchmark p99 regression` row removed. |
| Tier classification source-of-truth (`quality-tiers.yml`) | PASS | `quality-tiers.yml` at repo root unchanged on this branch (`git diff main..HEAD -- quality-tiers.yml` empty). |

### Tonality compliance

Reviewer-authored artifacts in this audit (`policy-audit`, `code-review`, `feature-audit`) use restrained, evidence-first language: no jokes, no hyperbole, no decorative metaphors, no emojis. Verdict: PASS.

### Evidence Location Compliance

The reviewer scanned the branch diff for any files written under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, or `artifacts/coverage/`.

Result: zero violations. All execution evidence for this feature lives under `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/{baseline,qa-gates,regression-testing,post-refactor}/`, which is the canonical location per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`.

Verdict: PASS.

### Bundled-Mirror Contract

The change touches `.claude/rules/{quality-tiers.md, general-code-change.md}` and `.github/workflows/{_stage-10-benchmark-regression.yml, _benchmark-gate-self-validation.yml, benchmark-baseline-refresh.yml, pr-pipeline.yml}` plus `.github/actions/dotnet-test/action.yml` and `.github/scripts/apply-branch-protection.ps1`.

- `.github/instructions/` mirrors of the two `.claude/rules/` files are resynced (see diffs above).
- `.codex/` and `.agents/` mirror roots do not exist in this worktree (recorded in `evidence/baseline/phase0-instructions-read.md`); no orphan mirror to resync.
- `.github/actions/dotnet-test/action.yml` has no content mirror — only a `uses:` caller workflow (`_stage-5-dotnet-test.yml`). See `evidence/qa-gates/mirror-resync-dotnet-test-action.2026-05-18T23-10.md`.
- The Pester mirror-contract suite ran in toolchain step 6 with 178 passed.

Verdict: PASS.

### Residual-Reference Audit

Seven grep sweeps documented under `evidence/regression-testing/`:

| Pattern | Live-code hits | Status |
|---|---|---|
| `stage-10-benchmark-regression` | 0 outside allowlist | PASS |
| `benchmark-gate-self-validation` | 0 outside allowlist | PASS |
| `benchmark-baseline-refresh` | 0 outside allowlist | PASS |
| `compare-benchmarks.ps1` | 0 outside allowlist | PASS |
| `enrich-bdn-report.ps1` | 0 outside allowlist | PASS |
| `artifacts/benchmarks` | 0 outside allowlist | PASS |
| `Benchmark p99 regression` | 0 outside allowlist | PASS |

Allowlist scope is documented in each sweep file: this feature's `evidence/**`, the promoted potential entry, and historical evidence in `docs/features/archive/**` and other `docs/features/active/**` folders. The historical-docs carve-out is the standard one and does not represent a residual live reference.

Verdict: PASS.

## 3. Language-Specific Code Change Policy Compliance

### PowerShell (`.claude/rules/powershell.md`)

Four `[OutputType(...)]` attribute additions in `.github/scripts/apply-branch-protection.ps1`. Each declared type matches the function's actual return expression (verified per `evidence/qa-gates/edit-apply-branch-protection-outputtype.2026-05-19T00-30.md`). PSScriptAnalyzer reports zero findings repo-wide after the additions (toolchain step 2). Verdict: PASS.

### C# (`.claude/rules/csharp.md`)

Only XML doc-comment text edited in `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`. No executable C# lines added or modified. `dotnet csharpier check .` clean across 104 files; `dotnet build -c Release -p:TreatWarningsAsErrors=true` returns 0 warnings, 0 errors. Verdict: PASS.

### Python / TypeScript

No `.py`, `.ts`, or `.tsx` files changed in the branch diff. Verdict: N/A (no changed files).

## 4. Language-Specific Unit Test Policy Compliance

### PowerShell

No Pester test source added or modified by this branch other than deletions of gate-coupled suites (`compare-benchmarks.Tests.ps1`, `enrich-bdn-report.Tests.ps1`, `make-synthetic-fixtures.Tests.ps1`). Remaining Pester suite: 178 passed, 0 failed (toolchain step 6). Verdict: PASS.

### C#

No xUnit test source added or modified other than deletions of gate-coupled tests (`LatencyRegressionGateTests.cs`, `NonIdempotentHandler.cs`, `NonIdempotentHandlerNegativeTests.cs`). Remaining `dotnet test TaskMaster.sln`: 98 passed, 0 failed (toolchain step 7). Verdict: PASS.

### Python / TypeScript

No test files changed in the branch diff. Verdict: N/A (no changed files).

## 5. Test Coverage Detail

Languages with changed files in this branch diff:

- **C#** — one XML-doc-only edit in `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`. No executable C# lines added or modified. No coverage artifact regeneration is required for a comment-only edit; repo-wide `dotnet test ... --collect:"XPlat Code Coverage"` returned 98/0 passed (toolchain step 7). Verdict: **PASS**.
- **PowerShell** — four attribute additions to `.github/scripts/apply-branch-protection.ps1`. `[OutputType(...)]` attributes are non-executing metadata. Pester suite: 178 passed, 0 failed (toolchain step 6). Verdict: **PASS**.
- **YAML / Markdown** — not executable; coverage gate not applicable.
- **Python** — no `.py` files changed in the branch diff. N/A.
- **TypeScript** — no `.ts`/`.tsx` files changed. N/A.

Per Authoritative Decision #2, uniform thresholds (line >= 85%, branch >= 75%) apply. The branch adds no new executable code that would shift repo-wide coverage; the only edits to executable files are non-executing metadata (PowerShell attributes) or comment-only (C# XML doc). No file-level coverage regression is therefore possible from this branch's changes.

## 6. Test Execution Metrics

| Suite | Command | Passed | Failed | Skipped | Source |
|---|---|---|---|---|---|
| Pester (PowerShell) | `mcp__drm-copilot__run_poshqc_test` | 178 | 0 | 0 | toolchain step 6 |
| Architecture tests (.NET) | `dotnet test --filter "FullyQualifiedName~Architecture"` | 7 | 0 | 0 | toolchain step 5 |
| .NET unit + coverage | `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` | 98 | 0 | 0 | toolchain step 7 |
| Contract filter | `dotnet test --filter "Category=Contract"` | 0 | 0 | 0 (no matches) | toolchain step 8 |
| Integration filter | `dotnet test --filter "Category=Integration"` | 0 | 0 | 0 (no matches) | toolchain step 9 |

All metrics drawn from `evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md`. Total restarts in the toolchain loop: 0.

## 7. Code Quality Checks

| Check | Result | Source |
|---|---|---|
| PowerShell formatting (PoshQC) | Clean — no files reformatted | toolchain step 1 |
| PSScriptAnalyzer | 0 findings repo-wide | toolchain step 2 |
| .NET format (`dotnet csharpier check .`) | 104 files clean | toolchain step 3 |
| .NET build (Release, TreatWarningsAsErrors=true) | 0 warnings, 0 errors | toolchain step 4 |
| Architecture tests | 7/7 pass | toolchain step 5 |
| Evidence-location validator | 0 violations | branch-diff scan documented above |
| Residual-reference grep sweeps | 7/7 clean outside allowlist | `evidence/regression-testing/grep-*.2026-05-18T23-50.md` |

## Overall Verdict

PASS-with-pending-remote-CI. The change conforms to all repository policies; the four amended documents (two `.claude/rules/`, two `.github/instructions/` mirrors, and `docs/ci.research.md`) are internally consistent; no T1 obligation is silently dropped; no evidence-location violations.

## Acceptance Criteria Status

- Source: `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/spec.md` (AC1..AC11 verbatim)
- Total AC items: 11
- Checked off (delivered) at audit time: 10 (AC1..AC10)
- Remaining (unchecked): 1 (AC11 — full PR pipeline pass; deferred to post-push remote CI)
- Items remaining: `AC11: Full CI loop passes on the change branch (no perf gate present, no orphan references).`

## 8. Gaps and Exceptions

### Identified Gaps

- AC11 (`Full CI loop passes on the change branch (no perf gate present, no orphan references).`) cannot be verified locally; it is structurally deferred to the post-push remote PR pipeline run. This is the only outstanding gap and is explicitly scoped out of local execution by plan task P8-T11.

### Approved Exceptions

- None. No exceptions to policy were taken on this branch.

### Removed/Skipped Tests

The plan's deletion ledger explicitly removed three gate-coupled xUnit classes and three gate-coupled Pester suites because their production gate is removed:

1. `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs` — removed (plan task P5). Reason: validated the deleted `_stage-10-benchmark-regression.yml` gate. Impact: none on remaining code paths (no surviving caller). Justification: deletion authorized by issue.md AC and spec.md non-goals.
2. `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandler.cs` and `NonIdempotentHandlerNegativeTests.cs` — removed (plan task P5). Reason: existed only to exercise the benchmark-gate self-validation negative path. Impact: none (no surviving caller). Justification: same as above.
3. `tests/scripts/benchmarks/{compare-benchmarks,enrich-bdn-report,make-synthetic-fixtures}.Tests.ps1` — removed (plan task P5). Reason: covered scripts deleted in plan task P4. Impact: none (no surviving caller). Justification: same as above.

Seven residual-reference grep sweeps (`evidence/regression-testing/grep-*.2026-05-18T23-50.md`) confirm no orphan references to the removed tests or scripts remain outside the documented historical-docs allowlist.

## 9. Summary of Changes

### Commits in This PR/Branch

Per `git log main..HEAD --oneline`:

1. `3064bbd` — docs(ci-refactor): record feature-review audit artifacts for #27
2. `3ac0c30` — docs(ci-refactor): Phase 7 - AC1-AC10 sign-off
3. `21b6ba2` — test(ci-refactor): Phase 6 - post-refactor verification artifacts
4. `750b598` — docs(ci): Phase 5 - document callee/caller convention and dispatch usage
5. `8884f4c` — refactor(ci): Phase 4 - remove duplicate mirror workflow files
6. Predecessor commits in the same branch implement the classifier-benchmark-gate removal that this audit covers; the full list is available via `git log main..HEAD`.

### Files Modified

Net diff stat: 185 files changed, 4,060 insertions(+), 10,168 deletions(-). Deletions dominate; insertions are dominated by feature-folder evidence and the predecessor callee/caller workflow extraction.

Surviving-file edits on this branch:

1. `.claude/rules/quality-tiers.md` (MODIFIED) — removed the `Benchmark p99 regression` tier-gate row.
2. `.github/instructions/quality-tiers.instructions.md` (MODIFIED) — same row removed (mirror).
3. `.claude/rules/general-code-change.md` (MODIFIED) — dropped "and benchmark regression" from the nightly-pipeline sentence.
4. `.github/instructions/general-code-change.instructions.md` (MODIFIED) — same edit (mirror).
5. `docs/ci.research.md` (MODIFIED) — same tier-gate row removed.
6. `.github/workflows/pr-pipeline.yml` (MODIFIED) — removed `stage-10-benchmark-regression` and `benchmark-gate-self-validation` job entries and their `needs:` references.
7. `.github/actions/dotnet-test/action.yml` (MODIFIED) — removed `--filter "Category!=benchmark-gate-self-validation"` argument and its explanatory comment block.
8. `.github/scripts/apply-branch-protection.ps1` (MODIFIED) — added four `[OutputType(...)]` attributes to silence pre-existing `PSUseOutputTypeCorrectly` findings.
9. `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs` (MODIFIED) — XML doc-comment edit only; no executable C# lines changed.
10. `.gitignore`, `.github/workflows/README.md`, `.claude/settings.local.json`, `.claude/skills/orchestrate/SKILL.md`, `docs/.tmw-Outlook-Modern-Architecture-Migrationresearch-NoCOM.md` (MODIFIED) — minor support edits.

Deletion ledger (per `git diff --diff-filter=D --name-only main..HEAD`):

- Workflows: `.github/workflows/_stage-10-benchmark-regression.yml`, `.github/workflows/_benchmark-gate-self-validation.yml`, `.github/workflows/benchmark-baseline-refresh.yml`.
- Scripts: `scripts/benchmarks/{compare-benchmarks,enrich-bdn-report,make-synthetic-fixtures}.ps1`.
- Tests (C#): `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs`, `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandler.cs`, `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs`.
- Tests (Pester): `tests/scripts/benchmarks/{compare-benchmarks,enrich-bdn-report,make-synthetic-fixtures}.Tests.ps1`.
- Fixtures: `tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json`, `tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json`.
- Baselines: `artifacts/benchmarks/baseline.json` and tree.

## 10. Compliance Verdict

### Overall Status: PARTIALLY COMPLIANT (PASS-with-pending-remote-CI)

Verdict: PARTIALLY COMPLIANT only because AC11 (full PR pipeline pass) is structurally observable only from the remote runner after push; every other AC and policy requirement is verified as PASS by local evidence. No fail-closed condition is tripped: required coverage artifacts are present for every language with changed executable code (none on this branch had executable changes; comment-only and metadata-only edits are documented above), and the toolchain achieved a single clean pass with zero restarts.

**Fail-closed reminder:** This audit does not mark the change "ready for merge" until AC11 passes on the post-push remote PR pipeline.

### Policy-by-Policy Summary

#### General Code Change Policy (Section 2)
- PASS Design Principles
- PASS Module & File Structure (no file exceeds 500 lines)
- PASS Naming, Docs, Comments
- PASS Toolchain Execution (single clean pass; nine sub-stages exit 0)
- PASS Summarize & Document

#### Language-Specific Code Change Policy (Section 3)

**For PowerShell:**
- PASS Tooling & Baseline (PSScriptAnalyzer 0 findings repo-wide)
- PASS Design & Safety
- PASS Structure & Naming

**For C#:**
- PASS Tooling & Baseline (`dotnet csharpier check .` clean; build 0 warnings, 0 errors)
- PASS Type safety (no nullable changes; no `dynamic` introduced)

**For Python / TypeScript:**
- N/A — no changed files on this branch.

#### General Unit Test Policy (Section 1)
- PASS Core Principles
- PASS Coverage & Scenarios (no executable code added)
- PASS Test Structure
- PASS External Dependencies
- PASS Policy Audit (this document)

#### Language-Specific Unit Test Policy (Section 4)

**For PowerShell:**
- PASS Framework & Scope (Pester v5 via PoshQC)
- PASS Toolchain (178 passed)

**For C#:**
- PASS Framework & Scope (xUnit)
- PASS Toolchain (98 passed)

### Metrics Summary

- PASS 178/178 Pester tests passing (100%)
- PASS 98/98 xUnit tests passing (100%)
- PASS 7/7 architecture tests passing (100%)
- PASS 0 PSScriptAnalyzer findings repo-wide
- PASS 0 csharpier formatting findings (104 files)
- PASS 0 evidence-location violations
- PASS 0 residual-reference findings outside the documented allowlist (7 grep sweeps clean)
- PASS Single-pass toolchain (0 restarts)

### Recommendation

Conditional Go — ready for merge after AC11 (the remote PR pipeline) passes on the change branch. Every locally verifiable AC (AC1..AC10) and every policy requirement covered by local evidence has passed.

## Appendix A: Test Inventory

The branch adds no new tests. Remaining executed test inventory after the deletion ledger:

- Pester (PowerShell), via `Invoke-PoshQCTest -Root .`: 178 tests passed, 0 failed, 0 skipped. Full Pester run output is captured in `evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md` (step 6) and in `evidence/baseline/baseline-powershell-toolchain.2026-05-18T22-05.md` for the pre-change baseline.
- xUnit (.NET), via `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`: 98 tests passed, 0 failed, 0 skipped. Captured in `evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md` (step 7).
- Architecture tests (.NET), via `dotnet test --filter "FullyQualifiedName~Architecture"`: 7 tests passed, 0 failed. Captured in same toolchain step 5.
- Contract filter (.NET), via `dotnet test --filter "Category=Contract"`: 0 matches (no failures). Captured in toolchain step 8.
- Integration filter (.NET), via `dotnet test --filter "Category=Integration"`: 0 matches (no failures). Captured in toolchain step 9.

Deleted tests are enumerated in Section 8 ("Removed/Skipped Tests") and Section 9 ("Files Modified") above.

## Appendix B: Toolchain Commands Reference

Commands used in this audit (per `evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md`):

**For PowerShell:**

```powershell
# Formatting (step 1)
Import-Module ./scripts/powershell/PoshQC; Invoke-PoshQCFormat -Root .

# Linting (step 2)
Import-Module ./scripts/powershell/PoshQC; Invoke-PoshQCAnalyze -Root .

# Testing (step 6)
Import-Module ./scripts/powershell/PoshQC; Invoke-PoshQCTest -Root .
```

**For C# (.NET):**

```powershell
# Formatting (step 3)
dotnet csharpier check .

# Build (step 4)
dotnet build TaskMaster.sln -c Release -p:TreatWarningsAsErrors=true

# Architecture tests (step 5)
dotnet test TaskMaster.sln --filter "FullyQualifiedName~Architecture"

# Unit tests + coverage (step 7)
dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"

# Contract filter (step 8)
dotnet test TaskMaster.sln --filter "Category=Contract"

# Integration filter (step 9)
dotnet test TaskMaster.sln --filter "Category=Integration"
```

**Residual-reference grep sweeps:**

```bash
git grep -nE "stage-10-benchmark-regression|benchmark-gate-self-validation|benchmark-baseline-refresh|compare-benchmarks\\.ps1|enrich-bdn-report\\.ps1|artifacts/benchmarks|Benchmark p99 regression"
```

All seven sweep results are captured under `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/regression-testing/grep-*.2026-05-18T23-50.md`.
