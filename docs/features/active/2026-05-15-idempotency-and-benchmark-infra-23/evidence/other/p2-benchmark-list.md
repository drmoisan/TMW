# [P2-T1] Classifier Benchmarks Listing

Timestamp: 2026-05-15T21-58
Command (full): `dotnet run -c Release --project tests/TaskMaster.Benchmarks --no-build -- --list flat`
Output (full):
- TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command
- TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath
- TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update
- TaskMaster.Benchmarks.DeltaReconciliationBenchmarks.DeltaReconciliation_Apply (placeholder; throws NotSupportedException when invoked)

Command (filtered to ClassifierBenchmarks per the stage-10 run pattern from [P6-T1]):
`dotnet run -c Release --project tests/TaskMaster.Benchmarks --no-build -- --list flat --filter "*ClassifierBenchmarks*"`
EXIT_CODE: 0
Output:
- TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command
- TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath
- TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update

Output Summary: Exactly three classifier benchmark IDs are exposed under `*ClassifierBenchmarks*`, matching the Prompt D2 hot paths in the spec. The disabled `DeltaReconciliationBenchmarks` is registered for discoverability but is filtered out of the stage-10 run by the same filter that selects classifier benchmarks.
