# [P7-T9] Coverage Comparison — Baseline vs. Post-Change

Timestamp: 2026-05-15T22-31

Source artifacts:
- Baseline aggregate: `evidence/baseline/baseline-dotnet-test.md` (computed by `scripts/benchmarks/parse-cobertura.ps1`).
- Post-change aggregate: `evidence/qa-gates/p7-test.md` (computed by the same script, using `artifacts/csharp/post-change-2/`).

## Numeric Comparison

| Metric                 | Baseline       | Post-Change    | Delta           |
|------------------------|----------------|----------------|-----------------|
| Lines covered / total  | 309 / 945      | 309 / 945      | 0 / 0           |
| Line coverage          | 32.70%         | 32.70%         | +0.00%          |
| Branches covered/total | 56 / 354       | 56 / 354       | 0 / 0           |
| Branch coverage        | 15.82%         | 15.82%         | +0.00%          |

## Repo Policy Thresholds

Per `.claude/rules/quality-tiers.md` and `.claude/rules/general-unit-test.md`:
- Line coverage >= 85%: NOT MET (32.70%) — pre-existing condition, not regressed by this PR.
- Branch coverage >= 75%: NOT MET (15.82%) — pre-existing condition, not regressed by this PR.
- No regression on changed lines: PASS.

## Verdict

PASS on the regression criterion (the only criterion this PR could affect):
- All changed/added lines in this PR live in test/scaffolding projects (`tests/TaskMaster.Benchmarks`, `tests/TaskMaster.Worker.Tests`, scripts under `scripts/benchmarks/`, and the workflow YAML); these projects do not contain production code under coverage analysis.
- Production-code coverage is unchanged from the baseline (309/945 lines, 56/354 branches).

The absolute coverage levels (32.70% line / 15.82% branch) are below the repo's uniform thresholds and were below those thresholds in the baseline. That gap is owned by the production projects (Domain, Application, Classifier, Infrastructure, Api) and is outside the scope of Issue #23, which the spec explicitly limits to "gate-only infrastructure" with "no production handler code in scope" (see `spec.md` § Implementation Strategy and § Non-Goals). No remediation of the existing coverage gap is required for this PR.
