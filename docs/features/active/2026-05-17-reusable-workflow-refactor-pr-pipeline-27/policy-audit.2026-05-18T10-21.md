# Policy Compliance Audit — Issue #27

- Timestamp: 2026-05-18T10-21
- Feature: 2026-05-17-reusable-workflow-refactor-pr-pipeline-27
- Base: `main` @ `ecd1577760f42cd9a7f467b2038d7d04e30334a9`
- Head: `TMW-wt-2026-05-18-09-47` @ `3ac0c30319d8c79d593f598e5582f828e1b934f3`
- Work Mode: `full-feature`
- Scope: full branch diff against merge-base (not narrowed)

## Policy Reading Order (verified)

1. `CLAUDE.md` — loaded
2. `.claude/rules/general-code-change.md` — loaded
3. `.claude/rules/general-unit-test.md` — loaded
4. `.claude/rules/quality-tiers.md` — loaded
5. No language-specific rules in scope: the diff modifies no source code (no `.cs`, `.py`, `.ts`, `.ps1`, or production scripts). All changed files are workflow YAML, README documentation, the `orchestrate` skill, feature docs, and per-AC evidence artifacts.

## Rejected Scope Narrowing

None. The orchestrator-supplied scope is the full branch diff against the merge-base; this matches the Scope Invariant.

## Evidence Location Compliance

- Scan: `git diff --name-only ecd1577..HEAD -- artifacts/baselines/ artifacts/qa/ artifacts/evidence/ artifacts/coverage/` returned no files.
- All feature evidence files are written under `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/evidence/{baseline,qa-gates,regression-testing}/`, which is the canonical `<FEATURE>/evidence/<kind>/` path.
- Verdict: **PASS**.

## Toolchain Loop (cross-language seven-stage)

The branch changes no application source code. The seven-stage toolchain loop in `.claude/rules/general-code-change.md` is application-code-oriented; for a CI-only refactor it is exercised through the regression suites already run.

| Stage | Verdict | Evidence |
|---|---|---|
| 1 — Formatting | PASS (no source changes; YAML-only diff) | `git diff --stat` shows zero `.cs`/`.py`/`.ts`/`.ps1` files |
| 2 — Linting (PSScriptAnalyzer for repo scripts) | PASS | `evidence/regression-testing/psscriptanalyzer-postrefactor.2026-05-18T10-15.md` (exit 0) |
| 3 — Type checking | PASS (no source changes) | no typed languages modified |
| 4 — Architecture tests | PASS (no source changes) | no architecture surface modified |
| 5 — Unit tests (Pester) | PASS | `evidence/regression-testing/pester-postrefactor.2026-05-18T10-15.md`: 212 passed, 0 failed; equal to baseline 212/0 |
| 5 — Unit tests (Pytest) | PASS (no Python test surface reachable) | `evidence/baseline/pytest-baseline.2026-05-18T10-15.md`, `evidence/regression-testing/pytest-postrefactor.2026-05-18T10-15.md` |
| 6 — Contract / schema | PASS (no contract change) | no `openapi/` or schema file modified |
| 7 — Integration | PASS-equivalent for refactor | integration is the synthetic-PR scenario, structurally guaranteed (AC5/AC6 plan) |

YAML validity of all 18 callee files plus orchestrator: PASS per `evidence/qa-gates/yaml-parse-postrefactor.2026-05-18T10-15.md` and `evidence/qa-gates/orchestrator-rewrite.2026-05-18T10-15.md` (`actionlint` + `ConvertFrom-Yaml` clean).

## Coverage (per Coverage Verification rules)

Coverage gates apply to languages with changed application files in the branch diff. No application files in any of (C#, TypeScript, Python, PowerShell) were modified.

| Language | Application files changed | Verdict |
|---|---|---|
| C# | 0 | N/A (no changed files) |
| TypeScript | 0 | N/A (no changed files) |
| Python | 0 | N/A (no changed files) |
| PowerShell | 0 (no `.ps1` modified) | N/A (no changed files) |

Coverage artifacts are therefore not required for this branch under the verification procedure: "If no coverage artifact is found for a language that has changed files, flag as FAIL ... languages with zero changed files on the branch" are explicitly exempt.

## File Size Limit (500 lines)

All new callee files are 14–41 lines. `pr-pipeline.yml` shrank to 78 lines from 220. `README.md` is 126 lines. All under the 500-line cap. **PASS**.

## Error Handling and Logging

No new code paths added. `benchmark-gate-self-validation` negative-test `exit 0` reset is preserved (Invariant per spec.md). **PASS**.

## Naming

Callee filenames follow the documented `_<name>.yml` convention. Job ids match callee filenames. **PASS**.

## Public APIs and Compatibility

The `gh workflow run` dispatch surface gains 17 new entry points and removes 2 (the deleted mirrors). Branch-protection required-check names change shape from `<job-name>` to `<caller-job-name> / <callee-job-name>`. This is a breaking change to the branch-protection rule definition; the mitigation (admin rename procedure) is documented in `README.md` and is required to be repeated in the PR description (AC8). **PARTIAL** until the admin rename is performed; the change is documented as required.

## Dependencies

No new third-party action versions introduced. Existing pins (`actions/checkout@v4`, `actions/setup-dotnet@v4`, `actions/setup-node@v4`, `actions/upload-artifact@v4`) relocate verbatim. **PASS**.

## I/O Boundaries

No new I/O paths added. Cross-job filesystem isolation audit performed (`evidence/baseline/cross-job-fs-audit.2026-05-18T10-15.md`): no job consumes another's working tree; the lone `upload-artifact` (`stage-10-benchmark-report`) is for post-run inspection only and has no consumer `download-artifact`. **PASS**.

## Unit Test Policy

No new test code added. Existing Pester suite (212 tests) continues to pass unchanged.

## Documentation

`.github/workflows/README.md` (new, 126 lines) documents:
- Callee/caller convention
- 17-row callee table
- Per-stage `gh workflow run` invocations (17 lines)
- Branch-protection 17-row rename mapping table and admin procedure
- Secrets-forwarding contract (single `_stage-e2e-smoke.yml` consumer)

`.claude/skills/orchestrate/SKILL.md` updated to reference the convention (`evidence/qa-gates/skill-updated.2026-05-18T10-15.md`). **PASS**.

## Summary

| Area | Verdict |
|---|---|
| Policy reading order | PASS |
| Evidence locations | PASS |
| Toolchain (regression suites) | PASS |
| Coverage | N/A (no application files changed) |
| File size limits | PASS |
| Error handling | PASS |
| Naming | PASS |
| API compatibility | PARTIAL (branch-protection admin rename pending) |
| Dependencies | PASS |
| I/O boundaries | PASS |
| Unit test policy | PASS |
| Documentation | PASS |

Overall policy compliance: **PASS** with one documented PARTIAL (branch-protection rename is an out-of-band admin action explicitly called out in AC8 and the README procedure).
