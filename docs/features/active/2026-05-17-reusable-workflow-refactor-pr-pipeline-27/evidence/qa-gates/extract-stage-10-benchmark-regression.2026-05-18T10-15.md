# Phase 2 extraction - stage-10-benchmark-regression

Timestamp: 2026-05-18T10-15
Command: ConvertFrom-Yaml .github/workflows/_stage-10-benchmark-regression.yml + structural diff of jobs.stage-10-benchmark-regression.steps vs evidence/baseline/pr-pipeline.pre-refactor.yml; actionlint .github/workflows/_stage-10-benchmark-regression.yml
EXIT_CODE: 0

Output Summary: callee .github/workflows/_stage-10-benchmark-regression.yml parses OK; actionlint clean; steps block byte-identical to baseline jobs.stage-10-benchmark-regression.steps (verified by powershell-yaml round-trip equality). needs: relocated to caller (Phase 3).
