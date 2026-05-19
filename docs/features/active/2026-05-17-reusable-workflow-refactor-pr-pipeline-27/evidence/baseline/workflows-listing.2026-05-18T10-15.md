# Baseline — .github/workflows/ listing

Timestamp: 2026-05-18T10-15
Command: Get-ChildItem .github/workflows/ -File | Select-Object Name, Length, LastWriteTime
EXIT_CODE: 0

```
Name                               Length LastWriteTime
----                               ------ -------------
benchmark-baseline-refresh.yml       2672 5/18/2026 9:47:05 AM
benchmark-gate-self-validation.yml   1989 5/18/2026 9:47:05 AM
pr-pipeline.yml                      7284 5/18/2026 9:47:05 AM
pre-merge-pipeline.yml               2910 5/18/2026 9:47:05 AM
stage-10-benchmark-regression.yml    1958 5/18/2026 9:47:05 AM
```

Output Summary: 5 workflow files present pre-refactor. Two of them (benchmark-gate-self-validation.yml, stage-10-benchmark-regression.yml) are the duplicate mirrors slated for deletion in Phase 4.
