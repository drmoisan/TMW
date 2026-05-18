# Phase 2 extraction - stage-3-dotnet-typecheck

Timestamp: 2026-05-18T10-15
Command: ConvertFrom-Yaml .github/workflows/_stage-3-dotnet-typecheck.yml + structural diff of jobs.stage-3-dotnet-typecheck.steps vs evidence/baseline/pr-pipeline.pre-refactor.yml; actionlint .github/workflows/_stage-3-dotnet-typecheck.yml
EXIT_CODE: 0

Output Summary: callee .github/workflows/_stage-3-dotnet-typecheck.yml parses OK; actionlint clean; steps block byte-identical to baseline jobs.stage-3-dotnet-typecheck.steps (verified by powershell-yaml round-trip equality). needs: relocated to caller (Phase 3).
