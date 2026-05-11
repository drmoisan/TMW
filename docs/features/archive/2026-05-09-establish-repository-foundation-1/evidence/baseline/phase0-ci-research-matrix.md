---
artifact: phase0-ci-research-matrix
---

Timestamp: 2026-05-10T02-41
Command: Read docs/ci.research.md lines 109-123
EXIT_CODE: 0
Output Summary: tier-specific source matrix copied below. Note: AD-2 overrides tier-specific coverage floors — line >=85% and branch >=75% apply uniformly across T1-T4 in this repository.

```
| Gate | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Format | 100% | 100% | 100% | 100% |
| Lint errors | 0 | 0 | 0 | 0 |
| Type errors | 0 | 0 | 0 | 0 |
| Untyped escape hatches (`any`/`dynamic`) | 0 | 0 | <= 5 per file, justified | unlimited |
| Architecture violations | 0 | 0 | 0 | 0 |
| Line coverage | >= 85% | >= 75% | >= 50% (integration) | none |
| Branch coverage | >= 75% | >= 65% | none | none |
| Property test count | >= 1 per pure function | >= 1 per pure function | none | none |
| Mutation score | >= 75% | trend-only | none | none |
| Contract breaking changes | major-bump required | major-bump required | n/a | n/a |
| Benchmark p99 regression | < 5% | < 10% | none | none |
| Determinism (no flaky tests) | retry rate < 0.5% | < 1% | < 2% | n/a |
```

AD-2 override note: per the plan's Authoritative Decision #2, line coverage >=85% and branch coverage >=75% apply uniformly across T1-T4. Tier-specific lower coverage floors are not used in this repository.
