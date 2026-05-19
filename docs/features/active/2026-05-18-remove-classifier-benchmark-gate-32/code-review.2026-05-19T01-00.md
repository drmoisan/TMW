# Code Review — remove-classifier-benchmark-gate (Issue #32)

- Timestamp (UTC): 2026-05-19T01-00
- Branch: TMW-wt-2026-05-18-09-47
- Base: main
- Diff command: `git diff main..HEAD`

## Executive Summary

Overall verdict: **PASS**. The branch is a well-contained removal-first refactor of the classifier benchmark gate. No production source code is modified — the only edits to surviving non-deleted files are (a) four `[OutputType(...)]` PowerShell attribute additions whose declared types match each function's actual return expression, (b) an XML doc-comment edit in `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`, and (c) lockstep wording removals across `.claude/rules/`, `.github/instructions/`, and `docs/ci.research.md`. The seven-stage toolchain achieved a single clean pass (zero restarts, all stages exit 0). No findings of any severity are reported; no remediation is required. Net diff: 185 files changed, 4,060 insertions, 10,168 deletions; insertions are dominated by feature-folder evidence and the predecessor callee/caller workflow extraction.

## Change Set Summary

The branch is a removal-first refactor. Two source-only categories:

1. Pure deletions (workflows, scripts, baseline JSON, gate-coupled test files, gate-coupled fixtures).
2. Small targeted edits to surviving files: two `.claude/rules/*.md` files; their two `.github/instructions/*.instructions.md` mirrors; `docs/ci.research.md`; `.github/workflows/pr-pipeline.yml`; `.github/actions/dotnet-test/action.yml`; `.github/scripts/apply-branch-protection.ps1`; `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs` (XML doc-comment only); `.gitignore`; `.github/workflows/README.md`; `.claude/settings.local.json`; `.claude/skills/orchestrate/SKILL.md`; `docs/.tmw-Outlook-Modern-Architecture-Migrationresearch-NoCOM.md`.

Net diff stat: 185 files changed, 4,060 insertions(+), 10,168 deletions(-). The insertion total is dominated by feature-folder evidence (plan + 100+ qa-gate markdowns) and the callee/caller workflow extraction that was already merged via the predecessor commit chain.

## Scope Containment

| Check | Verdict | Evidence |
|---|---|---|
| No production code outside the documented edit set was changed | PASS | `git diff main..HEAD --stat` lists no files under `src/` or under `tests/TaskMaster.*.Tests/` except the deletion of `LatencyRegressionGateTests.cs`, `NonIdempotentHandler.cs`, and `NonIdempotentHandlerNegativeTests.cs` (all gate-coupled, all named in the plan's deletion ledger). |
| `tests/TaskMaster.Benchmarks` source is untouched and still compiles | PASS | Only `BenchmarkConfig.cs` XML doc-comment edited (3-line, comment-only). `dotnet build tests/TaskMaster.Benchmarks -c Release` returned exit 0 with 0 warnings — see `evidence/qa-gates/dotnet-build-benchmarks.2026-05-18T23-50.md`. |
| `Fixtures/` deletions do not break the Benchmarks `.csproj` | PASS | Pre-check (`evidence/qa-gates/check-benchmarks-csproj-fixtures.2026-05-18T23-10.md`) confirmed no `<EmbeddedResource>`, `<None Include>`, or `<Content Include>` reference to `Fixtures/`; the runtime build (above) confirms it. |
| No secrets, `.env`, or large binaries staged | PASS | Diff contains no `.env`, no key material, no compiled binaries. Two large deletions (`baseline.json`, the two synthetic fixture JSONs) total ~8,130 lines removed; their content was synthetic BenchmarkDotNet output, not credentials. |

## Edit-Quality Review

### `.github/actions/dotnet-test/action.yml`

Removed the `--filter "Category!=benchmark-gate-self-validation"` argument and the five-line explanatory comment block above the test step.

- Contract preservation: the action's input/output surface (none declared) and its required `pwsh` shell are unchanged. The behavioral contract — "build and run all tests under `TaskMaster.sln` with coverage" — now applies without a category exclusion that no longer has a corresponding gated suite (its three test classes were deleted on this branch).
- Risk: a stale caller that still relied on the filtered behavior would now run additional tests. Verified zero such callers exist: the deleted `Category=benchmark-gate-self-validation` xUnit traits no longer exist on any test class on this branch.

Verdict: PASS.

### `.github/scripts/apply-branch-protection.ps1`

Four `[OutputType(...)]` attribute additions on functions `Get-RequiredStatusCheckContextList`, `Get-RepositoryMergeSettingsFieldList`, `Get-ManagedRepositoryRulesetId`, `Invoke-RepositoryGovernanceRulesetSync`.

- Type-correctness verification (per `evidence/qa-gates/edit-apply-branch-protection-outputtype.2026-05-19T00-30.md`):
  - `Get-RequiredStatusCheckContextList` body is `return @('tier-classification', ...)` — PSScriptAnalyzer infers `System.Object[]`. Declared `[OutputType([object[]])]`. Accurate.
  - `Get-RepositoryMergeSettingsFieldList` body is `return @('allow_merge_commit=true')` — same inference. `[OutputType([object[]])]`. Accurate.
  - `Get-ManagedRepositoryRulesetId` returns `[int]$ruleset.id` or `$null`. Declared `[OutputType([int], [object])]` to cover the int path and the null sentinel without overconstraining. Accurate.
  - `Invoke-RepositoryGovernanceRulesetSync` final statement is `return 0`. Declared `[OutputType([int])]`. Accurate.
- Repo-baseline justification: the file is unchanged on this branch in any other respect (`git diff` shows only the four new attribute lines). The four `PSUseOutputTypeCorrectly` findings predated the branch and were silenced to allow `toolchain-2-analyze` to pass after the analyzer's scope expanded to include `.github/scripts/`. Justification recorded in the same evidence file.

Verdict: PASS.

### `.github/workflows/pr-pipeline.yml`

Refactored from inline-jobs to the callee/caller pattern. The two job entries `stage-10-benchmark-regression` and `benchmark-gate-self-validation` and their `needs:` references are absent from the post-change file. No downstream job retains a dangling `needs:` to them.

Verdict: PASS.

### `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`

Two-line XML doc-comment edit: replaces the sentence that referenced the deleted `scripts/benchmarks/compare-benchmarks.ps1` with "for downstream analysis". The change is comment-only; no executable code modified. Build still passes (see above).

Verdict: PASS.

### Rule and instruction files

- `.claude/rules/quality-tiers.md` and `.github/instructions/quality-tiers.instructions.md` each delete the single `Benchmark p99 regression` matrix row. Tables remain well-formed.
- `.claude/rules/general-code-change.md` and `.github/instructions/general-code-change.instructions.md` each drop "and benchmark regression" from the nightly-pipeline sentence; "Mutation testing and golden tests" is preserved.
- `docs/ci.research.md` deletes the same row from its tier-gate table (kept in lockstep).

Verdict: PASS — all four documents change in lockstep with the matching wording.

## Deleted-File Inventory (spot-check)

| Path | Deleted | Plan task |
|---|---|---|
| `.github/workflows/_stage-10-benchmark-regression.yml` | yes | P3-T1 |
| `.github/workflows/_benchmark-gate-self-validation.yml` | yes | P3-T2 |
| `.github/workflows/benchmark-baseline-refresh.yml` | yes | P3-T3 |
| `scripts/benchmarks/compare-benchmarks.ps1` | yes | P4 |
| `scripts/benchmarks/enrich-bdn-report.ps1` | yes | P4 |
| `scripts/benchmarks/make-synthetic-fixtures.ps1` | yes | P4 |
| `artifacts/benchmarks/baseline.json` + tree | yes | P4 |
| `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs` | yes | P5 |
| `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandler.cs` | yes | P5 |
| `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs` | yes | P5 |
| `tests/scripts/benchmarks/compare-benchmarks.Tests.ps1` | yes | P5 |
| `tests/scripts/benchmarks/enrich-bdn-report.Tests.ps1` | yes | P5 |
| `tests/scripts/benchmarks/make-synthetic-fixtures.Tests.ps1` | yes | P5 |
| `tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json` | yes | P6-T8 |
| `tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json` | yes | P6-T9 |

All deletions match the documented plan deletion ledger; no out-of-scope files deleted.

## Lint and Build Posture

- PowerShell formatting (PoshQC): clean.
- PSScriptAnalyzer: zero findings repo-wide after the `[OutputType]` additions.
- .NET build (Release, TreatWarningsAsErrors=true): 0 warnings, 0 errors.
- Architecture tests: 7/7 pass.
- Pester: 178 passed, 0 failed.
- `dotnet test TaskMaster.sln`: 98 passed, 0 failed.

Source: `evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md`.

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Info | — | n/a | No findings. The diff is well-contained, comment- and metadata-only on surviving production files, and the four PowerShell attribute additions accurately describe each function's return type. | No action required. | The branch makes no executable changes to surviving production files; deletions match the documented plan ledger; toolchain achieved a single clean pass. | `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/qa-gates/toolchain-loop-clean-pass.2026-05-18T22-05.md`; `docs/features/active/2026-05-18-remove-classifier-benchmark-gate-32/evidence/qa-gates/edit-apply-branch-protection-outputtype.2026-05-19T00-30.md` |

No Blocker or Major findings.

## Overall Verdict

PASS.
