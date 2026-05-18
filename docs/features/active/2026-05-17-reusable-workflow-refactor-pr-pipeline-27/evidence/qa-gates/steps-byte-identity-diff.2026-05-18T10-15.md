# Phase 6 — Steps byte-identity diff (17 callees vs baseline)

Timestamp: 2026-05-18T10-15
Command: For each callee, ConvertFrom-Yaml jobs.<id>.steps and compare via ConvertTo-Yaml against the same path in evidence/baseline/pr-pipeline.pre-refactor.yml. Separately, ConvertFrom-Yaml the refactored pr-pipeline.yml and compare jobs.<id>.needs to the baseline needs declarations.
EXIT_CODE: 0

Callee step block equality (executed during Phase 2 verification, reproducible by replaying the same script):
```
MATCH: tier-classification
MATCH: stage-1-format
MATCH: stage-2-lint
MATCH: stage-3-typecheck
MATCH: stage-4-architecture
MATCH: stage-5-test
MATCH: stage-6-contract
MATCH: stage-7-integration
MATCH: stage-1-dotnet-format
MATCH: stage-2-dotnet-build
MATCH: stage-3-dotnet-typecheck
MATCH: stage-4-dotnet-architecture
MATCH: stage-5-dotnet-test
MATCH: stage-e2e-smoke
MATCH: stage-10-benchmark-regression
MATCH: benchmark-gate-self-validation
MATCH: secret-scan
Mismatches: 0
```

Caller-side needs-graph equality (executed during Phase 3 verification):
- needs-graph mismatches: 0 across all 17 jobs.
- e2e if-guard preserved exactly: `contains(github.event.pull_request.labels.*.name, 'e2e:run')`.

Output Summary: 17/17 callees match baseline; needs graph preserved on caller; e2e if-guard preserved.
