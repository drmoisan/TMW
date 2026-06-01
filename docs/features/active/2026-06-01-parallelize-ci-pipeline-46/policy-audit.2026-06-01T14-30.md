# Policy Compliance Audit: parallelize-ci-pipeline (Issue #46)

**Audit Date:** 2026-06-01
**Code Under Test:** Branch diff `ff6aa00..736b420` against base `main`. Non-doc changes:
- `.github/workflows/pr-pipeline.yml` (+11/-11 — `needs:` edges only)
- `.github/workflows/README.md` (+1/-1 — orchestrator topology description)

All other changed paths are feature scoping docs and evidence under `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/`.

**Coverage Metrics by Language:**

| Language | Files Changed | Tests | Test Result | Baseline Coverage | Post-Change Coverage | New Code Coverage |
|----------|--------------|-------|-------------|-------------------|---------------------|-------------------|
| YAML (workflow) | 1 file | N/A | N/A | N/A (not covered by line/branch tooling) | N/A | N/A |
| Markdown (docs) | 1 file | N/A | N/A | N/A (documentation) | N/A | N/A |

**Note:** No Python, PowerShell, TypeScript, C#, or Bash production/test files changed in the branch diff. Coverage tooling does not apply to YAML `needs:` edges or Markdown. See the per-language coverage determination below.

### Coverage Evidence Checklist

- TypeScript baseline coverage artifact: `N/A - zero TypeScript files changed in branch diff`
- TypeScript post-change coverage artifact: `N/A - zero TypeScript files changed in branch diff`
- PowerShell baseline coverage artifact: `N/A - zero PowerShell files changed in branch diff`
- PowerShell post-change coverage artifact: `N/A - zero PowerShell files changed in branch diff`
- Python baseline coverage artifact: `N/A - zero Python files changed in branch diff`
- Python post-change coverage artifact: `N/A - zero Python files changed in branch diff`
- C# baseline coverage artifact: `N/A - zero C# files changed in branch diff`
- C# post-change coverage artifact: `N/A - zero C# files changed in branch diff`
- Per-language comparison summary: see "Coverage Verdicts by Language" below and Section 1.2.1.

**Non-negotiable verdict rule:** Coverage verdicts are required only for languages with changed files in the branch diff. The branch diff contains zero source/test files in any coverage-bearing language; therefore `N/A` is the correct and permitted verdict for every coverage-bearing language.

---

## Coverage Verdicts by Language

Per the Scope Invariant, coverage verdicts must be explicit `PASS`/`FAIL` only for languages that have changed files in the branch diff. The branch diff (`ff6aa00..736b420`) was inspected with `git diff --name-only`. The complete changed-file set is:

```
.github/workflows/README.md
.github/workflows/pr-pipeline.yml
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/baseline-actionlint.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/baseline-apply-branch-protection-pester.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/baseline-needs-graph.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/phase0-instructions-read.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-actionlint.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-apply-branch-protection-pester.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-diff-scope.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-greenrun-handoff.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-needs-graph.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/issue.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/plan.2026-06-01T09-58.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/spec.md
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/user-story.md
```

| Language | Changed files in branch diff | Coverage verdict |
|----------|------------------------------|------------------|
| TypeScript | 0 | N/A (zero changed files — verdict permitted) |
| Python | 0 | N/A (zero changed files — verdict permitted) |
| PowerShell | 0 | N/A (zero changed files — verdict permitted) |
| C# | 0 | N/A (zero changed files — verdict permitted) |
| YAML (workflow) | 1 (`pr-pipeline.yml`) | N/A (not a coverage-bearing language; no line/branch tooling) |
| Markdown | 1 (`README.md`) + feature docs | N/A (not a coverage-bearing language) |

No coverage-bearing language has a changed file in this branch; coverage artifact inspection is therefore not required and no coverage FAIL is triggered.

---

## Rejected Scope Narrowing

The caller prompt included the following clarifying context (quoted verbatim):

> "Note for context (not a scope instruction): the branch diff is a `needs:`-graph-only change to `.github/workflows/pr-pipeline.yml` plus a documentation update to `.github/workflows/README.md`. The `modified-workflow-needs-green-run` policy applies to the workflow change; the authoritative green branch-head run of `pr-pipeline.yml` is produced by the orchestrator at the S9 gate after PR creation. Apply the full feature-review-workflow contract end-to-end without narrowing."

Justification: This statement was explicitly framed as context, not a scope-narrowing instruction, and it instructs the reviewer to apply the full contract without narrowing. The reviewer independently resolved scope as the full branch diff against `main` (merge-base `ff6aa00`) using `git diff` and the PR-context artifacts. No narrowing was applied; the context was confirmed against the diff rather than relied upon. No other narrowing attempt was detected.

---

## Evidence Location Compliance

The branch diff was scanned for evidence written to non-canonical paths (`artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, `artifacts/coverage/`).

- No `validate_evidence_locations.py` script exists in this repository; evidence-location enforcement is implemented by the PreToolUse hook `.claude/hooks/enforce-evidence-locations.ps1`.
- All feature evidence is written under the canonical `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/<kind>/` path (`baseline/` and `qa-gates/` subfolders).
- A grep for `artifacts/(baselines|qa|coverage|evidence)/` across the feature folder matched only `plan.2026-06-01T09-58.md` lines 46-47, which are prose explicitly **prohibiting** non-canonical evidence paths, not an evidence write. This is not a violation.

**Verdict: PASS.** No evidence file is written to a non-canonical path. No `EVIDENCE_LOCATION_OVERRIDE_REJECTED` event occurred.

---

## Executive Summary

This branch is a refactor of the PR CI orchestrator `.github/workflows/pr-pipeline.yml`. It re-parents every non-root gate stage from its prior serial-lane predecessor to `needs: [tier-classification]`, converting two serial per-language lanes (7-job TypeScript lane, 5-job .NET lane) into a fan-out where independent stages are schedulable concurrently after the single root gate. `stage-e2e-smoke` is re-parented to the root gate while retaining its `e2e:run` label guard and `secrets: inherit`. `secret-scan` and `tier-classification` are unchanged. `.github/workflows/README.md` is updated to describe the fan-out topology and the accepted fail-fast / runner-minute tradeoff.

The change touches no production code, no test code, and no `_*.yml` callee in any language. The general code-change and unit-test toolchain loops do not apply because no coverage-bearing source changed. The applicable checks are static workflow validation (`actionlint` / YAML validity), the unchanged Pester regression anchor `apply-branch-protection.Tests.ps1`, structural `needs:`-graph verification, diff-scope confirmation, and the authoritative green branch-head run of `pr-pipeline.yml`.

**Policy documents evaluated:**
- ✅ `CLAUDE.md` (standing instructions)
- ✅ `.claude/rules/general-code-change.md` — applies at the file-scope / change-discipline level; the seven-stage code loop does not apply to a YAML-only `needs:` change (no compilable/coverable source).
- N/A `.claude/rules/general-unit-test.md` — no test code changed; no new unit tests are required for a `needs:`-graph change (graph is evaluated only at GitHub Actions runtime).
- ✅ `.claude/rules/ci-workflows.md` — evaluated; does not apply because no inline `pwsh` step with a deliberately-failing nested command was added or modified.
- ✅ `.claude/rules/benchmark-baselines.md` — evaluated; does not apply because no benchmark baseline under `scripts/benchmarks/**` is touched.
- ✅ `.claude/skills/feature-review-workflow` policy `modified-workflow-needs-green-run` — fires (diff touches `.github/workflows/**`); see finding below.
- ✅ `.claude/rules/tonality.md` — applied to this artifact.

**Language-specific policies evaluated:**
- N/A Python — zero changed files.
- N/A PowerShell — zero changed files (`apply-branch-protection.ps1` is a read-only touchpoint and is unchanged).
- N/A TypeScript — zero changed files.
- N/A C# — zero changed files.

**Temporary artifacts cleanup:**
- ✅ No temporary or one-time scripts were created during this review.
- N/A No ongoing tooling scripts were created.

---

## modified-workflow-needs-green-run (Policy Rule)

The branch diff modifies `.github/workflows/pr-pipeline.yml` and `.github/workflows/README.md`, both matching the trigger glob `.github/workflows/**`. The supporting validator `scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1` was executed:

```
Command: ./scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 \
  -ChangedFiles @('.github/workflows/pr-pipeline.yml','.github/workflows/README.md') \
  -GreenRunEvidencePresent $false
Result: {"IsBlocking":true,"MatchedPaths":[".github/workflows/pr-pipeline.yml",".github/workflows/README.md"]}
```

A search for an existing green run against the branch head returned none:

```
Command: gh run list --workflow=pr-pipeline.yml --branch TMW-wt-2026-06-01-09-51 --limit 5 --json headSha,conclusion,status,event
Result: []  (no runs)
```

**Finding (Blocking, expected): no green `pr-pipeline.yml` run against branch head `736b420` is present.** This is the second, independent line of defense the policy defines. The authoritative green branch-head run is produced by the orchestrator at the S9 gate after PR creation (documented in `evidence/qa-gates/qa-greenrun-handoff.md` and in spec.md Test Strategy as the chicken-and-egg case the policy explicitly anticipates). This Blocking finding is routed through the remediation handoff in `remediation-inputs.2026-06-01T14-30.md`. It is a pre-merge gate item, not a defect in the change as authored; all locally verifiable prerequisites (actionlint clean, structural graph match, branch-protection anchor green, diff scope confined) are satisfied.

---

## 1. General Unit Test Policy Compliance

No test code changed in the branch diff, and the change is a `needs:`-graph edit evaluated only at GitHub Actions runtime, which no local unit test exercises (spec.md Test Strategy). No new unit tests are required.

| Requirement | Status | Evidence |
|------------|--------|----------|
| New/changed unit tests required | N/A PASS | YAML `needs:` graph is not exercised by any local unit test; spec.md Test Strategy explicitly states "no new unit tests." |
| Coverage thresholds (85% line / 75% branch) | N/A | No coverage-bearing language has changed files; coverage tooling does not measure YAML edges. |
| Regression anchor (existing test stays green) | ✅ PASS | `apply-branch-protection.Tests.ps1` Pester run recorded green and unchanged; see Section 4B and evidence `qa-apply-branch-protection-pester.md` (EXIT_CODE 0). |

### 1.2.1 Per-Language Coverage Comparison

No coverage-bearing language has a changed file in the branch diff; coverage comparison is not applicable for any language. The checklist below is retained per template requirement with `N/A - out of scope` (zero changed files) artifact dispositions.

- TypeScript: Baseline: N/A -> Post-change: N/A. Change: N/A. New/changed-code coverage: `N/A - zero changed files`. Disposition: N/A. Evidence: `N/A - zero changed files`.
- Python: Baseline: N/A -> Post-change: N/A. Change: N/A. New/changed-code coverage: `N/A - zero changed files`. Disposition: N/A. Evidence: `N/A - zero changed files`.
- PowerShell: Baseline: N/A -> Post-change: N/A. Change: N/A. New/changed-code coverage: `N/A - zero changed production files` (regression anchor test unchanged). Disposition: N/A. Evidence: `N/A - zero changed files`.
- C#: Baseline: N/A -> Post-change: N/A. Change: N/A. New/changed-code coverage: `N/A - zero changed files`. Disposition: N/A. Evidence: `N/A - zero changed files`.

---

## 2. General Code Change Policy Compliance

### 2.1 Before Making Changes

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Clarify the objective** | ✅ PASS | Objective is documented in issue.md, spec.md, and user-story.md (Issue #46): reduce PR-pipeline wall-clock time by fanning out independent gates after the root gate. |
| **Read existing change plans** | ✅ PASS | `plan.2026-06-01T09-58.md` present and followed; Phase 0 read-evidence recorded in `evidence/baseline/phase0-instructions-read.md`. |
| **Document the plan** | ✅ PASS | Plan and spec document the target `needs:` graph and invariants. |

### 2.2 Design Principles

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Simplicity first** | ✅ PASS | The change is the minimal edit that achieves the goal: only `needs:` values change; no jobs added/removed, no inline steps, no callee edits. |
| **Reusability** | N/A | No reusable code introduced; callees remain referenced via `uses:`. |
| **Extensibility** | ✅ PASS | Fan-out preserves the ability to re-add a justified genuine `needs:` edge to any stage if a real data dependency is later found (documented in spec.md). |
| **Separation of concerns** | ✅ PASS | Orchestrator remains pure orchestration (`uses:`/`needs:`/`if:`/`secrets:`); no inline `steps:` added (invariant #8 preserved). |

### 2.3 Module & File Structure

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Cohesive modules** | ✅ PASS | `pr-pipeline.yml` remains a single orchestrator file with one job per gate. |
| **Under 500 lines** | ✅ PASS | `pr-pipeline.yml` is 70 lines; `README.md` change is a single-line description edit. |
| **Public vs internal** | ✅ PASS | Job keys (status-check contexts) unchanged — invariant #1/#2 preserved. |
| **No circular dependencies** | ✅ PASS | All gates depend only on `tier-classification` (the single root with no `needs:`); `secret-scan` has no `needs:`. No cycle is possible; confirmed by actionlint clean run. |

### 2.4 Naming, Docs, and Comments

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Descriptive names** | ✅ PASS | No names changed; existing descriptive job keys retained. |
| **Docs/docstrings** | ✅ PASS | `README.md` updated to describe the fan-out topology and the accepted runner-minute tradeoff. |
| **Comment why, not what** | N/A | No inline comments added or required. |

### 2.5 After Making Changes — Toolchain Execution

The seven-stage code-change loop (format → lint → type → architecture → unit → contract → integration) is keyed to compilable/coverable source. This change edits only YAML `needs:` edges and one Markdown line; the applicable substitute checks are static workflow validation plus the regression anchor.

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Static workflow validation (actionlint / YAML)** | ✅ PASS | `actionlint .github/workflows/pr-pipeline.yml` recorded EXIT_CODE 0 in `evidence/qa-gates/qa-actionlint.md` (2026-06-01T14-06). Confirms `needs:` references resolve to defined jobs and no cycle is introduced. |
| **Regression anchor (Pester)** | ✅ PASS | `Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI` recorded EXIT_CODE 0 in `evidence/qa-gates/qa-apply-branch-protection-pester.md`. |
| **Structural graph verification** | ✅ PASS | Post-change `needs:` graph matches the required end-state; recorded in `evidence/qa-gates/qa-needs-graph.md` and independently re-verified by reading `pr-pipeline.yml` (all gates `needs: [tier-classification]`; `tier-classification` root; `secret-scan` no `needs:`). |
| **Diff-scope confinement** | ✅ PASS | `evidence/qa-gates/qa-diff-scope.md` (EXIT_CODE 0); branch-protection files confirmed untouched via `git diff --name-only` (empty). |
| **Full code-change loop** | N/A | Not applicable to a YAML-`needs:`-only change with no coverable source. |

### 2.6 Summarize and Document

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Summarize changes** | ✅ PASS | spec.md Technical Specifications and the current/target graph sections describe the change precisely. |
| **Design choices explained** | ✅ PASS | Fail-fast vs wall-clock tradeoff documented in user-story.md "Acknowledged Tradeoff" and README.md. |
| **Update supporting documents** | ✅ PASS | `README.md` updated to match the new topology. |
| **Provide next steps** | ✅ PASS | Green branch-head run identified as the remaining S9 acceptance step. |

---

## 3. Language-Specific Code Change Policy Compliance

No Python, PowerShell, TypeScript, or C# source files changed in the branch diff. All language-specific code-change sections are **N/A** (zero changed files in each language). The branch-protection PowerShell script `.github/scripts/apply-branch-protection.ps1` is a read-only touchpoint and was confirmed unchanged.

---

## 4. Language-Specific Unit Test Policy Compliance

### Section 4B: PowerShell Unit Test Policy Compliance (regression anchor only)

No PowerShell test files were modified. The existing test `tests/powershell/apply-branch-protection.Tests.ps1` is the regression anchor for invariant #2 (no status-check-name drift) and was run unchanged.

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Use Pester v5.x** | ✅ PASS | `Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI`, EXIT_CODE 0, recorded `evidence/qa-gates/qa-apply-branch-protection-pester.md` (2026-06-01T14-06). |
| **Test unchanged** | ✅ PASS | `git diff --name-only ff6aa00..736b420 -- tests/powershell/apply-branch-protection.Tests.ps1 .github/scripts/apply-branch-protection.ps1` returned empty (both files untouched). |

All Python and TypeScript unit-test sections are **N/A** (zero changed test files).

---

## 5. Test Coverage Detail

No coverage-bearing source code changed in the branch diff. There is no new or modified function/class/module to report line-by-line coverage for. The changed lines are YAML `needs:` edges in `pr-pipeline.yml` and one Markdown description line in `README.md`, neither of which is measured by line/branch coverage tooling.

**Not covered:** N/A — no coverable source changed.

---

## 6. Test Execution Metrics

| Metric | Value | Status |
|--------|-------|--------|
| New unit tests added | 0 (none required for `needs:`-graph change) | N/A |
| Regression anchor (Pester) | EXIT_CODE 0 | ✅ PASS |
| actionlint | EXIT_CODE 0 | ✅ PASS |
| Coverage (any coverage-bearing language) | No changed files | N/A |

---

## 7. Code Quality Checks

The applicable checks for a YAML-`needs:`-only change plus a Markdown doc edit are static workflow validation and the unchanged regression anchor.

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Workflow static validation | `actionlint .github/workflows/pr-pipeline.yml` | EXIT_CODE 0 (recorded `evidence/qa-gates/qa-actionlint.md`) | ✅ |
| Pester regression anchor | `Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI` | EXIT_CODE 0 (recorded `evidence/qa-gates/qa-apply-branch-protection-pester.md`) | ✅ |
| Diff-scope confinement | `git diff --name-only ff6aa00..736b420` | Two permitted non-doc files + feature docs only | ✅ |
| Structural `needs:` graph | Read `pr-pipeline.yml`; verify each job key's `needs:` | Matches required end-state | ✅ |
| Green branch-head run | `gh run list --workflow=pr-pipeline.yml --branch TMW-wt-2026-06-01-09-51` | `[]` (none yet — S9 gate) | ❌ pending |

**Notes:** No pre-existing failures unrelated to this work were observed. The seven-stage code loop, format, lint, and type-check do not apply (no compilable/coverable source changed).

---

## 8. Gaps and Exceptions

### Identified Gaps

- **modified-workflow-needs-green-run:** No green `pr-pipeline.yml` run against branch head `736b420` is present locally. This is the single Blocking gap. It is closed by the orchestrator S9 green branch-head run after PR creation. Routed to remediation inputs.

### Approved Exceptions

- **No new unit tests:** Permitted by spec.md Test Strategy and the nature of a `needs:`-graph change (evaluated only at GitHub Actions runtime; not exercised by any local unit test).
- **Seven-stage code loop not run:** Permitted because no compilable/coverable source changed.

### Removed/Skipped Tests

- **None.** No tests were removed or skipped.

---

## 9. Summary of Changes

### Files Modified (non-doc)

1. **`.github/workflows/pr-pipeline.yml`** (MODIFIED) — `needs:` edges only. Eleven gate stages re-parented to `needs: [tier-classification]`; `stage-e2e-smoke` re-parented to root with its `e2e:run` guard and `secrets: inherit` retained. `tier-classification` and `secret-scan` unchanged. Job keys unchanged.
2. **`.github/workflows/README.md`** (MODIFIED) — orchestrator description updated to fan-out topology with the runner-minute tradeoff noted.

Feature scoping docs and evidence under `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/` were also added/updated (issue.md, spec.md, user-story.md, plan, baseline and qa-gate evidence).

---

## 10. Compliance Verdict

### Overall Status: ⚠️ PARTIALLY COMPLIANT (one Blocking pre-merge gate item)

The change as authored is policy-compliant: scope is confined to two permitted files, invariants #1–#8 are preserved, static and structural validations pass, and the branch-protection regression anchor is green and unchanged. The single Blocking item is the `modified-workflow-needs-green-run` green branch-head run, which is, by policy design, produced at the orchestrator S9 gate after PR creation. The audit cannot be marked fully PASS until that green run exists.

### Metrics Summary

- ✅ actionlint clean (EXIT_CODE 0)
- ✅ Pester regression anchor green and unchanged (EXIT_CODE 0)
- ✅ Diff scope confined to two permitted files; branch-protection files untouched
- ✅ Structural `needs:` graph matches required end-state (independently re-verified)
- ✅ Evidence-location compliance: all evidence under canonical path
- ❌ Green `pr-pipeline.yml` run against branch head: not yet present (S9 gate)

### Recommendation

**Conditional Go.** Ready for PR creation. Merge is gated on the orchestrator S9 green branch-head run of `pr-pipeline.yml` satisfying `modified-workflow-needs-green-run`, with the run timeline showing post-root concurrent scheduling.

---

## Appendix A: Test Inventory

No new tests were added by this change. The only test exercised is the unchanged regression anchor:

- `tests/powershell/apply-branch-protection.Tests.ps1` — asserts the required status-check context set (invariant #2: no job-name / required-check drift). Run unchanged, EXIT_CODE 0.

No Python, TypeScript, or C# tests were added or modified.

---

## Appendix B: Toolchain Commands Reference

```bash
# Scope / diff
git diff --name-only ff6aa007fefcd24ff18b96240525d7c9bafd7d18..736b4202d118eb326f8a21f9456b4527c69f967b
git diff ff6aa00..736b420 -- .github/workflows/pr-pipeline.yml .github/workflows/README.md
git diff --name-only ff6aa00..736b420 -- .github/scripts/apply-branch-protection.ps1 tests/powershell/apply-branch-protection.Tests.ps1   # empty => untouched

# Workflow static validation (recorded in evidence)
actionlint .github/workflows/pr-pipeline.yml

# Regression anchor (recorded in evidence)
pwsh -NoProfile -Command "Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI"

# modified-workflow-needs-green-run rule
pwsh -NoProfile -File ./scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 \
  -ChangedFiles @('.github/workflows/pr-pipeline.yml','.github/workflows/README.md') -GreenRunEvidencePresent $false

# Green branch-head run lookup
gh run list --workflow=pr-pipeline.yml --branch TMW-wt-2026-06-01-09-51 --limit 5 --json headSha,conclusion,status,event
```

---

**Audit Completed By:** feature-review agent
**Audit Date:** 2026-06-01
**Policy Version:** Current (as of audit date)
